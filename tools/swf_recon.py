#!/usr/bin/env python3
"""First-pass reverse engineering of the 2012 client: where is the network code?

Exports ActionScript from SWFs with JPEXS FFDec (or scans an existing export),
then reports, per category, every line that touches sockets, framing,
serialization, crypto, asset loading or domain checks, plus classes that look
like command-ID tables. The report is the to-do list for writing the protocol
spec (doc: Phase 2, steps 1-2).

  python tools/swf_recon.py --ffdec ~/ffdec/ffdec.jar mirror/aola.100bt.com/play/*.swf --out work/recon
  python tools/swf_recon.py --scripts work/recon/scripts --out work/recon     # re-scan only

Output: work/recon/recon.md (human report) and recon.json (machine-readable).
"""

from __future__ import annotations

import argparse
import collections
import json
import re
import subprocess
import sys
from pathlib import Path

CATEGORIES: dict[str, list[str]] = {
    "socket": [
        r"\bflash\.net\.(?:Socket|XMLSocket|SecureSocket)\b", r"\bnew\s+(?:XML)?Socket\s*\(",
        r"\.connect\s*\(", r"Security\.loadPolicyFile", r"ProgressEvent\.SOCKET_DATA",
        r"\bsocket\w*\b", r"\bport\b",
    ],
    "framing": [
        r"\.(?:read|write)(?:Unsigned)?(?:Int|Short|Byte)\s*\(", r"\.(?:read|write)UTF(?:Bytes)?\s*\(",
        r"\bbytesAvailable\b", r"\bendian\b", r"Endian\.(?:BIG|LITTLE)_ENDIAN",
        r"\b(?:head|header|packet|pkg|cmd|command|seq|msgId|msgid)\w*\b",
    ],
    "serialization": [
        r"\.(?:read|write)Object\s*\(", r"\bobjectEncoding\b", r"ObjectEncoding\.AMF[03]",
        r"\bJSON\.(?:parse|stringify|decode|encode)\b", r"com\.adobe\.serialization\.json",
        r"registerClassAlias", r"\bprotobuf\b",
    ],
    "crypto": [
        r"\b(?:encrypt|decrypt|cipher|crypt)\w*\b", r"\b(?:DES|AES|RC4|TEA|XXTEA|MD5|SHA1|Base64)\b",
        r"com\.hurlant\.", r"\^\s*(?:0x[0-9a-fA-F]+|\d+|\w+\[)", r"\.(?:un)?compress\s*\(",
        r"\b(?:secret|key|salt)\w*\s*[:=]",
    ],
    "loading": [
        r"\bnew\s+Loader\s*\(", r"\.loadBytes\s*\(", r"\bURLLoader\b", r"\bnew\s+URLRequest\s*\(",
        r"getDefinitionByName", r"ApplicationDomain", r"\bversion\w*\.xml\b", r"~\s*\+|\"~\"|'~'",
    ],
    "domain-guard": [
        r"loaderInfo\.(?:url|loaderURL|parameters)", r"\bnavigateToURL\b", r"ExternalInterface\.call",
        r"Security\.allowDomain", r"Capabilities\.\w+", r"100bt\.com",
    ],
    "time": [
        r"\bnew\s+Date\s*\(", r"getTimer\s*\(", r"\bserverTime\b|\bsvrTime\b|\bsysTime\b",
    ],
}
IP_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}(?::\d{2,5})?\b")
URL_RE = re.compile(r"""["'](https?://[^"'\s]+)["']""")
CONST_RE = re.compile(
    r"(?:public|internal|private)?\s*static\s+const\s+(\w+)\s*:\s*(?:int|uint|Number|String)\s*=\s*([^;]+);"
)
SKIP_DIRS = ("mx/", "spark/", "com/adobe/", "com/greensock/", "flash/")


def export_scripts(ffdec: str, swfs: list[Path], out: Path) -> Path:
    scripts = out / "scripts"
    for swf in swfs:
        dest = scripts / swf.stem
        if dest.exists() and any(dest.rglob("*.as")):
            print(f"[recon] {swf.name}: already exported")
            continue
        dest.mkdir(parents=True, exist_ok=True)
        cmd = ["java", "-jar", ffdec, "-export", "script", str(dest), str(swf)]
        print("[recon] " + " ".join(cmd))
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            print(f"[recon] FFDec failed on {swf}:\n{r.stderr[-2000:]}", file=sys.stderr)
    return scripts


def scan(scripts: Path, max_hits: int) -> dict:
    compiled = {c: [re.compile(p) for p in pats] for c, pats in CATEGORIES.items()}
    hits = collections.defaultdict(list)
    per_file = collections.Counter()
    const_tables = []
    urls, ips = collections.Counter(), collections.Counter()
    files = sorted(scripts.rglob("*.as"))
    for f in files:
        rel = f.relative_to(scripts).as_posix()
        lib = any(f"/{d}" in "/" + rel for d in SKIP_DIRS)
        text = f.read_text("utf-8", "ignore")
        for u in URL_RE.findall(text):
            urls[u] += 1
        for ip in IP_RE.findall(text):
            octets = [int(o) for o in ip.split(":")[0].split(".")]
            # Skip OIDs (2.5.4.3) and versions: real hosts have a first octet >= 10 and octets <= 255.
            if octets[0] >= 10 and max(octets) <= 255 and octets[0] not in (127, 255):
                ips[ip] += 1
        consts = CONST_RE.findall(text)
        numeric = [(n, v.strip()) for n, v in consts if re.fullmatch(r"-?(?:0x[0-9a-fA-F]+|\d+)", v.strip())]
        if len(numeric) >= 15:
            const_tables.append({"file": rel, "count": len(numeric), "sample": numeric[:12]})
        if lib:
            continue
        for ln, line in enumerate(text.splitlines(), 1):
            for cat, pats in compiled.items():
                if any(p.search(line) for p in pats):
                    per_file[(cat, rel)] += 1
                    if len(hits[cat]) < max_hits:
                        hits[cat].append({"file": rel, "line": ln, "text": line.strip()[:200]})
    top = {
        cat: [f for (c, f), _ in sorted(per_file.items(), key=lambda kv: -kv[1]) if c == cat][:15]
        for cat in CATEGORIES
    }
    const_tables.sort(key=lambda t: -t["count"])
    return {
        "files_scanned": len(files),
        "top_files": top,
        "hits": hits,
        "const_tables": const_tables[:30],
        "urls": urls.most_common(200),
        "ips": ips.most_common(50),
    }


def write_report(res: dict, out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    (out / "recon.json").write_text(json.dumps(res, ensure_ascii=False, indent=1), "utf-8")
    md = [f"# Client recon\n\n{res['files_scanned']} ActionScript files scanned.\n"]
    md.append("## Where to look first\n")
    for cat, files in res["top_files"].items():
        if files:
            md.append(f"- **{cat}**: " + ", ".join(f"`{f}`" for f in files[:6]))
    md.append("\n## Command-table candidates\n")
    md.append("Classes with 15+ numeric static constants; one of these is usually the command-ID list.\n")
    for t in res["const_tables"][:15]:
        sample = ", ".join(f"{n}={v}" for n, v in t["sample"][:6])
        md.append(f"- `{t['file']}` ({t['count']} consts): {sample}")
    md.append("\n## Hard-coded hosts\n")
    md += [f"- `{ip}` x{n}" for ip, n in res["ips"]] or ["- none"]
    md += [f"- `{u}` x{n}" for u, n in res["urls"][:60]]
    for cat, rows in res["hits"].items():
        md.append(f"\n## {cat} ({len(rows)} lines shown)\n")
        md += [f"- `{r['file']}:{r['line']}` {r['text'].replace('`', '´')}" for r in rows]
    (out / "recon.md").write_text("\n".join(md) + "\n", "utf-8")
    print(f"[recon] report: {out / 'recon.md'}")


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("swfs", nargs="*", type=Path)
    p.add_argument("--ffdec", help="path to ffdec.jar (JPEXS)")
    p.add_argument("--scripts", type=Path, help="scan an existing script export instead")
    p.add_argument("--out", type=Path, default=Path("work/recon"))
    p.add_argument("--max-hits", type=int, default=400, help="lines kept per category")
    a = p.parse_args(argv)
    if a.scripts:
        scripts = a.scripts
    else:
        if not a.ffdec or not a.swfs:
            p.error("give SWF files and --ffdec, or --scripts DIR")
        scripts = export_scripts(a.ffdec, a.swfs, a.out)
    write_report(scan(scripts, a.max_hits), a.out)


if __name__ == "__main__":
    main()
