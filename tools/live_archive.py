#!/usr/bin/env python3
"""Archive what is left of the 2012/13 game on the live CDN.

The live server (aola.100bt.com/play/) still serves many files exactly as
they were uploaded in 2010-2013, and its Last-Modified header keeps the
original upload date (skin/a000002.swf: 27 Dec 2011, the same day as the
SWF's own XMP date). Nothing lists those files: the live manifest names only
files changed since its baseline, so an old unchanged scene such as
scene/restaurant appears nowhere. This tool therefore:

  candidates  gathers every path that may exist, from manifests (live and
              captured), config files, Wayback URLs, string literals in
              decompiled code, raw strings inside SWFs, the 2013 material
              data (clothes, furniture, items, cards, eggs by id) and numbered
              name patterns (petcard/view{n}) enumerated over the 2013 range;
  head        asks the CDN for each one (HEAD: status, Last-Modified, size,
              ETag) and logs it, resumably;
  fetch       downloads every file last modified before the cutoff
              (default 2014-01-01) to <out>/<host>/<path>, checks the size,
              and records the SWF's own XMP date beside the header date;
  report      counts and sizes per folder and year.

  python tools/live_archive.py candidates --out work/live/candidates.txt \\
      --manifest-swf mirror/aola.100bt.com/play/versiondata.swf%3F20140523 … \\
      --config work/live/config.xml --decompiled ../aola-work/src --swf-root mirror --material ../aola-work/src/materialdata
  python tools/live_archive.py head --candidates work/live/candidates.txt --log work/live/head.jsonl
  python tools/live_archive.py fetch --log work/live/head.jsonl --out archive
  python tools/live_archive.py report --log work/live/head.jsonl --index archive/index.jsonl
"""

from __future__ import annotations

import argparse
import collections
import datetime as dt
import email.utils
import hashlib
import json
import os
import re
import sys
import threading
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import swfinfo  # noqa: E402

BASE = "http://aola.100bt.com/play/"
ENTRY_RE = re.compile(rb'<f\s+n="([^"]+)"\s+v="([^"]+)"')
PATH_RE = re.compile(r"(?<![A-Za-z0-9_./])([a-z][a-z0-9_]{1,40}(?:/[A-Za-z0-9_\-]{1,80}){1,6})(\.(?:swf|mp3|xml|png|jpg|gif|txt|json|bin))?(?![A-Za-z0-9_/])")
EXT_DEFAULT = ".swf"
EXTS = (".swf", ".mp3", ".xml", ".png", ".jpg", ".gif", ".txt", ".json", ".bin", ".html", ".js", ".css")


# ───────────────────────── helpers ─────────────────────────

def read_jsonl(p: Path):
    if not p.exists():
        return
    with p.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield json.loads(line)


def with_ext(path: str) -> str:
    path = path.strip().lstrip("/")
    return path if path.lower().endswith(EXTS) else path + EXT_DEFAULT


def manifest_entries(swf: Path) -> dict[str, str]:
    data = swf.read_bytes()
    try:
        body = swfinfo._body(data) if data[:3] in (b"FWS", b"CWS", b"ZWS") else data
    except Exception:  # noqa: BLE001
        body = data
    return {n.decode("utf-8", "ignore"): v.decode() for n, v in ENTRY_RE.findall(body)}


def stamp_year(v: str) -> int | None:
    """Manifest version -> year (yymmdd…, yyyymmdd…, or the yymm baseline)."""
    if re.match(r"20[12]\d[01]\d[0-3]\d", v):
        return int(v[:4])
    if re.match(r"1\d[01]\d", v) or re.match(r"2[0-6][01]\d[0-3]\d", v):
        return 2000 + int(v[:2])
    return None


# ───────────────────────── candidates ─────────────────────────

def cmd_candidates(a) -> None:
    names: dict[str, set[str]] = collections.defaultdict(set)  # path -> sources
    era_names: set[str] = set()  # names seen in a 2013-or-earlier source

    def add(path: str, src: str, era: bool = False) -> None:
        p = with_ext(path)
        if "//" in p or p.startswith(("http", "www.")):
            return
        names[p].add(src)
        if era:
            era_names.add(p)

    folders: set[str] = set()
    for m in a.manifest_swf or []:
        ents = manifest_entries(Path(m))
        for n, v in ents.items():
            y = stamp_year(v)
            add(n, f"manifest:{Path(m).name}", era=(y is not None and y <= a.era_year))
            folders.add(n.split("/")[0])
        print(f"  manifest {Path(m).name}: {len(ents)}")

    for c in (a.config or []) + (a.era_config or []):
        text = Path(c).read_text(encoding="utf-8", errors="ignore")
        era = c in (a.era_config or [])
        n0 = len(names)
        for attr in re.findall(r'(?:swf|mf|mu|f|url|path|src|res|file)="([^"]+)"', text):
            if "/" in attr and not attr.startswith("http"):
                add(attr, f"config:{Path(c).name}", era=era)
        for m in PATH_RE.finditer(text):
            add(m.group(1) + (m.group(2) or ""), f"config:{Path(c).name}", era=era)
        print(f"  config {Path(c).name}: +{len(names) - n0}")

    for cdx in a.cdx or []:
        n0 = len(names)
        for r in read_jsonl(Path(cdx)):
            u = r.get("url", "")
            m = re.match(r"https?://(?:www\.9aola\.com|aola\.100bt\.com/play)/([^?#]+)", u)
            if m and "." in m.group(1).rsplit("/", 1)[-1]:
                add(m.group(1), "cdx", era=True)
        print(f"  cdx: +{len(names) - n0}")

    known = folders | {p.split("/")[0] for p in names}

    def scan_text(text: str, src: str, era: bool) -> None:
        for m in PATH_RE.finditer(text):
            p = m.group(1)
            if p.split("/")[0] in known:
                add(p + (m.group(2) or ""), src, era)

    for d in a.decompiled or []:
        n0 = len(names)
        era = not any(k in d for k in ("livesrc", "livecode"))
        for f in Path(d).rglob("*.as"):
            scan_text(f.read_text(encoding="utf-8", errors="ignore"), f"code:{Path(d).name}", era)
        print(f"  decompiled {d}: +{len(names) - n0}")

    for root in (a.swf_root or []) + (a.era_swf_root or []):
        n0 = len(names)
        for f in Path(root).rglob("*"):
            if not f.is_file() or ".swf" not in f.name:
                continue
            try:
                body = swfinfo._body(f.read_bytes())
            except Exception:  # noqa: BLE001
                continue
            text = body.decode("latin-1")
            scan_text(text, f"swf:{Path(root).name}", root in (a.era_swf_root or []))
        print(f"  swf strings {root}: +{len(names) - n0}")

    if a.material:
        n0 = len(names)
        md = Path(a.material)
        def ids(fname: str, ctor: str) -> list[int]:
            f = next(md.rglob(fname), None)
            if f is None:
                return []
            return sorted({int(x) for x in re.findall(rf"new {ctor}\((\d+),", f.read_text(encoding="utf-8", errors="ignore"))})
        patterns = {
            ("ClothesData.as", "Clothes"): ["skin/a{:06d}", "skinview/a{:06d}", "skinicon/a{:06d}"],
            ("FurnitureData.as", "Furniture"): ["furniture/b{:06d}", "furnitureview/b{:06d}"],
            ("ItemData.as", "Item"): ["item/view{}"],
            ("PetCardData.as", "PetCard"): ["petcard/view{}"],
            ("PetCard2Data.as", "PetCard2"): ["petcard2/view{}", "petcard/view{}"],
            ("PetEggData.as", "PetEgg"): ["petegg/egg{}"],
            ("PlantData.as", "Plant"): ["plant/plant{}", "plant/view{}"],
            ("BadgeData.as", "Badge"): ["badge/view{}", "badge/badge{}"],
            ("RobotItemData.as", "RobotItem"): ["robot/item{}", "robotitem/view{}"],
            ("ZooAnimalData.as", "Animal"): ["zoo/animal{}", "zoopeticon/view{}", "zoopeticon/{}"],
        }
        for (fname, ctor), pats in patterns.items():
            got = ids(fname, ctor)
            for i in got:
                for pat in pats:
                    add(pat.format(i), f"material:{ctor}", era=True)
            print(f"    {ctor}: {len(got)} ids")
        # A clothes item's file is named in ClothesPartsDatas ("<id>":[[parts…],"a000123"]),
        # which differs from a0<id> for the 亚比 follow skins (20123 -> a000123).
        parts = next(md.rglob("ClothesPartsDatas.as"), None)
        if parts is not None:
            files = sorted(set(re.findall(r'\],"(a\d+)"\]', parts.read_text(encoding="utf-8", errors="ignore"))))
            for f in files:
                for d in ("skin", "skinview", "skinicon"):
                    add(f"{d}/{f}", "material:ClothesParts", era=True)
            print(f"    ClothesParts files: {len(files)}")
        print(f"  material: +{len(names) - n0}")

    # Numbered name patterns, enumerated over the range the 2013-era names use.
    tmpl: dict[tuple, list[int]] = collections.defaultdict(list)
    for p in list(era_names):
        runs = list(re.finditer(r"\d+", p.rsplit(".", 1)[0]))
        if len(runs) != 1:
            continue
        r = runs[0]
        digits = r.group()
        width = len(digits) if digits.startswith("0") and len(digits) > 1 else 0
        if (width == 0 and len(digits) > 5) or int(digits) > a.max_enum:
            continue  # dates and big ids are names, not a range to walk
        tmpl[(p[: r.start()], p[r.end():], width)].append(int(digits))
    n0 = len(names)
    for (pre, post, width), nums in tmpl.items():
        hi = int(max(nums) * 1.15) + 20
        if len(nums) < a.min_pattern or (hi > 2000 and len(nums) / hi < a.min_density):
            continue
        hi = min(hi, a.max_enum)
        for i in range(0, hi + 1):
            s = f"{i:0{width}d}" if width else str(i)
            add(pre + s + post, "pattern", era=False)
    print(f"  numbered patterns: +{len(names) - n0}")

    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as f:
        for p in sorted(names):
            f.write(f"{p}\t{','.join(sorted(names[p]))}\n")
    print(f"{len(names)} candidate paths -> {out}")


# ───────────────────────── head ─────────────────────────

def http_date(s: str | None) -> str | None:
    if not s:
        return None
    try:
        return email.utils.parsedate_to_datetime(s).astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except Exception:  # noqa: BLE001
        return None


def cmd_head(a) -> None:
    paths = [l.split("\t", 1)[0] for l in Path(a.candidates).read_text(encoding="utf-8").splitlines() if l.strip()]
    log = Path(a.log)
    done = {r["path"] for r in read_jsonl(log) if r.get("status") in (200, 404, 403, 410)}
    todo = [p for p in paths if p not in done]
    print(f"[head] {len(paths)} candidates, {len(todo)} to ask, {a.workers} workers")
    lock = threading.Lock()
    counts = collections.Counter()
    deadline = time.monotonic() + a.time_limit if a.time_limit else None
    t0 = time.monotonic()
    fh = log.open("a", encoding="utf-8")

    def work(p: str) -> None:
        if deadline and time.monotonic() > deadline:
            return
        rec = {"path": p}
        for attempt in range(3):
            req = urllib.request.Request(a.base + p, method="HEAD", headers={"User-Agent": "Mozilla/5.0 aola-revival archive"})
            try:
                with urllib.request.urlopen(req, timeout=15) as r:
                    h = r.headers
                    rec.update(status=r.status, lm=http_date(h.get("Last-Modified")), size=int(h.get("Content-Length") or -1),
                               etag=(h.get("ETag") or "").strip('"'), type=h.get("Content-Type"))
                break
            except urllib.error.HTTPError as e:
                rec.update(status=e.code)
                if e.code < 500:
                    break
            except Exception as e:  # noqa: BLE001
                rec.update(status="error", error=repr(e)[:120])
            time.sleep(1 + attempt)
        with lock:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
            counts[rec["status"]] += 1
            n = sum(counts.values())
            if n % 2000 == 0:
                fh.flush()
                print(f"  {n}/{len(todo)} {dict(counts)} {n / (time.monotonic() - t0):.0f}/s", flush=True)

    with ThreadPoolExecutor(max_workers=a.workers) as pool:
        list(pool.map(work, todo))
    fh.close()
    print(f"[head] done: {dict(counts)}")


# ───────────────────────── fetch ─────────────────────────

def cmd_fetch(a) -> None:
    latest: dict[str, dict] = {}
    for r in read_jsonl(Path(a.log)):
        latest[r["path"]] = r
    cutoff = a.before + "T00:00:00Z"
    only = set(Path(a.paths).read_text(encoding="utf-8").split()) if a.paths else None
    want = [r for r in latest.values() if r.get("status") == 200 and r.get("lm")
            and (a.all_dates or r["lm"] < cutoff) and (only is None or r["path"] in only)]
    host = re.sub(r"^https?://", "", a.base).rstrip("/")
    out = Path(a.out)
    index = out / "index.jsonl"
    have = {r["path"]: r for r in read_jsonl(index)}
    todo = [r for r in want if r["path"] not in have or not have[r["path"]].get("ok")
            or have[r["path"]].get("etag") != r.get("etag")]
    print(f"[fetch] {len(want)} files {'selected' if a.all_dates else 'dated before ' + a.before} ({sum(r.get('size', 0) for r in want) / 1e6:.0f} MB); {len(todo)} to download")
    lock = threading.Lock()
    fh = index.open("a", encoding="utf-8") if out.mkdir(parents=True, exist_ok=True) is None else None
    counts = collections.Counter()
    deadline = time.monotonic() + a.time_limit if a.time_limit else None

    def work(r: dict) -> None:
        if deadline and time.monotonic() > deadline:
            return
        p = r["path"]
        dest = out / host / p
        rec = {"path": p, "url": a.base + p, "lm": r["lm"], "etag": r.get("etag"), "size": r.get("size")}
        for attempt in range(4):
            try:
                req = urllib.request.Request(a.base + p, headers={"User-Agent": "Mozilla/5.0 aola-revival archive"})
                with urllib.request.urlopen(req, timeout=60) as resp:
                    body = resp.read()
                if r.get("size", -1) >= 0 and len(body) != rec["size"]:
                    # The file may have been replaced since the HEAD run: ask again
                    # and accept the body if it matches what the server says now.
                    head = urllib.request.Request(a.base + p, method="HEAD", headers={"User-Agent": "Mozilla/5.0 aola-revival archive"})
                    with urllib.request.urlopen(head, timeout=15) as hr:
                        now = int(hr.headers.get("Content-Length", -1))
                        if now != len(body):
                            raise IOError(f"short read {len(body)} of {rec['size']}")
                        lm = hr.headers.get("Last-Modified")
                        rec.update(size=now, etag=(hr.headers.get("ETag") or "").strip('"') or rec["etag"],
                                   lm=http_date(lm) if lm else rec["lm"],
                                   replaced_since_head=True)
                dest.parent.mkdir(parents=True, exist_ok=True)
                tmp = dest.with_name(dest.name + ".part")
                tmp.write_bytes(body)
                os.replace(tmp, dest)
                rec["sha1"] = hashlib.sha1(body).hexdigest()
                if p.endswith(".swf"):
                    info = swfinfo.inspect(body)
                    rec["swf"] = f"{info.compression} v{info.swf_version}" if info.ok else None
                    rec["xmp"] = info.modify_yymmdd
                rec["ok"] = True
                break
            except Exception as e:  # noqa: BLE001
                rec.update(ok=False, error=repr(e)[:160])
                time.sleep(2 * (attempt + 1))
        with lock:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
            counts["ok" if rec.get("ok") else "failed"] += 1
            n = sum(counts.values())
            if n % 500 == 0:
                fh.flush()
                print(f"  {n}/{len(todo)} {dict(counts)}", flush=True)

    with ThreadPoolExecutor(max_workers=a.workers) as pool:
        list(pool.map(work, todo))
    fh.close()
    print(f"[fetch] done: {dict(counts)}")


# ───────────────────────── report ─────────────────────────

def cmd_report(a) -> None:
    latest: dict[str, dict] = {}
    for r in read_jsonl(Path(a.log)):
        latest[r["path"]] = r
    ok = [r for r in latest.values() if r.get("status") == 200]
    years = collections.Counter((r.get("lm") or "????")[:4] for r in ok)
    print(f"candidates asked: {len(latest)}; on the server: {len(ok)}; missing: {sum(1 for r in latest.values() if r.get('status') == 404)}")
    print("by Last-Modified year:", dict(sorted(years.items())))
    cutoff = a.before + "T00:00:00Z"
    old = [r for r in ok if r.get("lm") and r["lm"] < cutoff]
    by = collections.defaultdict(lambda: [0, 0])
    for r in old:
        k = r["path"].split("/")[0]
        by[k][0] += 1
        by[k][1] += max(r.get("size", 0), 0)
    rows = sorted(by.items(), key=lambda kv: -kv[1][1])
    lines = [f"# Live CDN files last modified before {a.before}", "",
             f"{len(old)} files, {sum(v[1] for v in by.values()) / 1e6:.0f} MB, of {len(ok)} found on the server.", "",
             "| folder | files | MB |", "| --- | ---: | ---: |"]
    lines += [f"| {k} | {v[0]} | {v[1] / 1e6:.1f} |" for k, v in rows]
    if a.index and Path(a.index).exists():
        idx = {r["path"]: r for r in read_jsonl(Path(a.index)) if r.get("ok")}
        mism = [r for r in idx.values() if r.get("xmp") and r.get("lm") and r["xmp"] > r["lm"][2:4] + r["lm"][5:7] + r["lm"][8:10]]
        lines += ["", f"Downloaded: {len(idx)}. SWFs whose own XMP date is later than the header date: {len(mism)}."]
    text = "\n".join(lines) + "\n"
    if a.out:
        Path(a.out).write_text(text, encoding="utf-8")
    print(text[:3000])


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("candidates")
    s.add_argument("--out", required=True)
    s.add_argument("--manifest-swf", action="append")
    s.add_argument("--config", action="append")
    s.add_argument("--cdx", action="append")
    s.add_argument("--decompiled", action="append", help="dirs of FFDec script exports (livesrc/livecode count as non-era)")
    s.add_argument("--swf-root", action="append", help="dirs of SWFs whose raw strings are scanned")
    s.add_argument("--material", help="decompiled 2013 materialdata dir")
    s.add_argument("--era-year", type=int, default=2013)
    s.add_argument("--era-config", action="append", help="a 2013-or-earlier config (its paths seed numbered patterns)")
    s.add_argument("--era-swf-root", action="append", help="dir of era SWFs whose strings seed numbered patterns")
    s.add_argument("--min-density", type=float, default=0.01, help="share of a long numbered range the era names must cover")
    s.add_argument("--min-pattern", type=int, default=3, help="numbered pattern needs this many era names")
    s.add_argument("--max-enum", type=int, default=60000, help="highest number tried in a numbered pattern")
    s.set_defaults(fn=cmd_candidates)
    s = sub.add_parser("head")
    s.add_argument("--candidates", required=True)
    s.add_argument("--log", required=True)
    s.add_argument("--base", default=BASE)
    s.add_argument("--workers", type=int, default=24)
    s.add_argument("--time-limit", type=float)
    s.set_defaults(fn=cmd_head)
    s = sub.add_parser("fetch")
    s.add_argument("--log", required=True)
    s.add_argument("--out", required=True)
    s.add_argument("--base", default=BASE)
    s.add_argument("--before", default="2014-01-01")
    s.add_argument("--paths", help="file of paths: fetch only these")
    s.add_argument("--all-dates", action="store_true", help="ignore --before (e.g. era-referenced files re-uploaded later; their XMP date is recorded)")
    s.add_argument("--workers", type=int, default=8)
    s.add_argument("--time-limit", type=float)
    s.set_defaults(fn=cmd_fetch)
    s = sub.add_parser("report")
    s.add_argument("--log", required=True)
    s.add_argument("--index")
    s.add_argument("--before", default="2014-01-01")
    s.add_argument("--out")
    s.set_defaults(fn=cmd_report)
    a = p.parse_args(argv)
    a.fn(a)


if __name__ == "__main__":
    main()
