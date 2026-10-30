#!/usr/bin/env python3
"""Turn the client's version manifests and code into a list of wanted URLs.

The 2012 boot chain is not documented, so this tool is deliberately loose:

  version   parse manifest XML whose elements carry a path attribute (n=, path=,
            url=, src=) and optionally a version attribute (v=, ver=, version=).
            The 2025 client uses <… n="activityres/…/x_code" v="2025…"/> and
            loads {base}{n}.swf; the --naming option emits the candidate URL
            forms so `wayback.py coverage` can show which one existed in 2012.
  scan      pull every path-looking string (…/x.swf, x.xml, x.mp3 …) out of any
            files: exported AS3, binaryData dumps, HTML, XML. Good for the first
            pass before the manifest format is understood.

Both write one URL per line (sorted, de-duplicated), ready for coverage.

  python tools/manifest.py version work/export/version.xml --naming plain,tilde > work/wanted.txt
  python tools/manifest.py scan work/as3/ work/pages/ >> work/wanted.txt
"""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urljoin

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mirrorpath import normalize_url  # noqa: E402

BASE = "http://www.9aola.com/"  # 2010-2013 client root; aola.100bt.com/play/ from mid-2013
PATH_ATTRS = ("n", "path", "url", "src", "file", "name")
# The 2013 client loads {base}{n}.swf?{v} where v is the file's last-modified date (YYMMDD).
VER_ATTRS = ("v", "ver", "version")
EXTS = "swf|xml|mp3|png|jpg|jpeg|gif|json|txt|bin|dat|flv|wav|html|htm|css|js"
PATH_RE = re.compile(
    r"(?<![\w.~/-])((?:https?://[\w.-]+)?/?[\w~.\-%/]+\.(?:" + EXTS + r"))(?![\w])",
    re.IGNORECASE,
)


def candidates(base: str, path: str, ver: str | None, ext: str, namings: list[str]) -> list[str]:
    has_ext = re.search(r"\.\w{2,4}$", path) is not None
    stem = path if has_ext else path + ext
    out = []
    for naming in namings:
        if naming == "plain":
            out.append(urljoin(base, stem))
        elif naming == "tilde" and ver:
            root, dot, suffix = stem.rpartition(".")
            out.append(urljoin(base, f"{root}~{ver}.{suffix}" if dot else f"{stem}~{ver}"))
        elif naming == "query" and ver:
            out.append(urljoin(base, f"{stem}?{ver}"))  # 2013 client: name.swf?121206
        elif naming == "query-v" and ver:
            out.append(urljoin(base, f"{stem}?v={ver}"))
    return out


def cmd_version(a) -> list[str]:
    namings = [n.strip() for n in a.naming.split(",") if n.strip()]
    urls: list[str] = []
    for file in a.files:
        data = Path(file).read_bytes()
        try:
            root = ET.fromstring(data)
        except ET.ParseError as e:
            print(f"{file}: not XML ({e}); try `scan`", file=sys.stderr)
            continue
        for el in root.iter():
            attrs = {k.lower(): v for k, v in el.attrib.items()}
            path = next((attrs[k] for k in PATH_ATTRS if k in attrs), None)
            if not path or path.startswith("#"):
                continue
            ver = next((attrs[k] for k in VER_ATTRS if k in attrs), None)
            urls += candidates(a.base, path, ver, a.ext, namings)
    return urls


def cmd_scan(a) -> list[str]:
    urls: list[str] = []
    files: list[Path] = []
    for item in a.files:
        p = Path(item)
        files += [f for f in p.rglob("*") if f.is_file()] if p.is_dir() else [p]
    for f in files:
        text = f.read_bytes().decode("utf-8", "ignore")
        for m in PATH_RE.finditer(text):
            s = m.group(1)
            if s.startswith(("http://", "https://")):
                urls.append(s)
            elif not a.absolute_only:
                urls.append(urljoin(a.base, s))
    return urls


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--base", default=BASE, help=f"base for relative paths (default {BASE})")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("version", help="parse manifest XML")
    s.add_argument("files", nargs="+")
    s.add_argument("--naming", default="plain,query", help="plain,tilde,query,query-v")
    s.add_argument("--ext", default=".swf", help="extension added when a path has none")
    s.set_defaults(fn=cmd_version)
    s = sub.add_parser("scan", help="grep path-like strings from any files or folders")
    s.add_argument("files", nargs="+")
    s.add_argument("--absolute-only", action="store_true", help="keep only http(s):// URLs")
    s.set_defaults(fn=cmd_scan)
    a = p.parse_args(argv)
    urls = sorted({normalize_url(u) for u in a.fn(a)})
    sys.stdout.write("\n".join(urls) + ("\n" if urls else ""))


if __name__ == "__main__":
    main()
