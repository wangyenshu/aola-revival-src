#!/usr/bin/env python3
"""Add to the live CDN archive's indexes the files game/ has and they lack.

The archive (docs/ARCHIVE.md's layout: index.jsonl for files uploaded
2010–2013, _later/index.jsonl for later uploads, under aola.100bt.com/play/)
was made on 28 October 2026. Curation tools have since taken more files from
the live CDN into game/ (tools/add_later.py, story_files.py, theatre.py, …),
each listed in game/FILES.jsonl with its CDN path, upload date and SHA-1.
This writes an index line for each of them that neither index has, with the
fields the archive keeps (path, url, lm, etag, size, sha1, swf, xmp, ok) and
the reason game/ took it ("added"), so tools/extract_archive.py --from-cdn
downloads and checks them like the rest. ETags come from the live
inventories, else from a HEAD request.

Files of the live server outside /play/ (the 百田大剧场 films) go to
_site/index.jsonl (paths from the host, under _site/); pictures game/ has
from the Wayback Machine with their capture URL go to _wayback/index.jsonl
(under _wayback/).

  tools/archive_additions.py --game game --meta <unpacked archive-meta folder> \\
      --live-head <inventory.jsonl> [--live-head …] [--head-missing]
"""
from __future__ import annotations

import argparse
import datetime as dt
import email.utils
import hashlib
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import swfinfo  # noqa: E402

CDN = "http://aola.100bt.com/play/"
UA = {"User-Agent": "Mozilla/5.0 aola-revival archive"}


def read(p: Path) -> list[dict]:
    return [json.loads(l) for l in p.read_text(encoding="utf-8").splitlines() if l.strip()] if p.exists() else []


def head(url: str) -> dict:
    req = urllib.request.Request(url, method="HEAD", headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        lm = r.headers.get("Last-Modified")
        return {"etag": (r.headers.get("ETag") or "").strip('"') or None,
                "lm": email.utils.parsedate_to_datetime(lm).astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ") if lm else None,
                "size": int(r.headers.get("Content-Length", -1))}


def facts(data: bytes, path: str) -> dict:
    out: dict = {}
    if path.split("?")[0].split("%3F")[0].endswith(".swf"):
        info = swfinfo.inspect(data)
        out["swf"] = f"{info.compression} v{info.swf_version}" if info.ok else None
        out["xmp"] = info.modify_yymmdd
    return out


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True)
    ap.add_argument("--meta", required=True, help="the unpacked archive-meta folder (index.jsonl, _later/index.jsonl)")
    ap.add_argument("--live-head", action="append", default=[], help="live inventories (path, status, lm, size, etag per line)")
    ap.add_argument("--head-missing", action="store_true", help="ask the CDN for the ETag of files no inventory has")
    ap.add_argument("--today", default=dt.date.today().isoformat())
    a = ap.parse_args(argv)

    game = Path(a.game)
    meta = Path(a.meta)
    era_ix, later_ix = meta / "index.jsonl", meta / "_later" / "index.jsonl"
    site_ix, way_ix = meta / "_site" / "index.jsonl", meta / "_wayback" / "index.jsonl"
    known: dict[str, dict] = {}
    for ix in (era_ix, later_ix):
        for r in read(ix):
            known[r["path"]] = r
    known_site = {r["path"] for r in read(site_ix)}
    known_way = {r["path"] for r in read(way_ix)}
    inv: dict[str, dict] = {}
    for f in a.live_head:
        for r in read(Path(f)):
            if r.get("status") == 200:
                inv[r["path"]] = r

    add: dict[Path, list[dict]] = {era_ix: [], later_ix: [], site_ix: [], way_ix: []}
    missing_etag = 0
    for row in read(game / "FILES.jsonl"):
        src = row.get("src") or ""
        origin = row.get("origin")
        file = game / row["path"]
        if not file.exists():
            continue
        if origin in ("era", "later") and src and not src.startswith("http"):
            if src in known:
                continue
            data = file.read_bytes()
            rec = {"path": src, "url": CDN + src, "lm": row.get("lm"), "etag": inv.get(src, {}).get("etag"), "size": len(data)}
            if rec["etag"] is None and a.head_missing:
                try:
                    h = head(CDN + src)
                    rec["etag"] = h["etag"]
                    if h["size"] != len(data):
                        rec["replaced_since_head"] = True
                except Exception as e:  # noqa: BLE001
                    print(f"  HEAD {src}: {e}", file=sys.stderr)
            missing_etag += rec["etag"] is None
            rec["sha1"] = hashlib.sha1(data).hexdigest()
            rec.update(facts(data, src))
            rec["ok"] = True
            rec["added"] = f"{a.today}: {row.get('added') or 'game/'}"
            target = era_ix if (rec["lm"] or "9999") < "2014-01-01" else later_ix
            add[target].append(rec)
            known[src] = rec
        elif src.startswith("http://aola.100bt.com/") and not src.startswith(CDN):
            path = src[len("http://"):]
            if path in known_site:
                continue
            data = file.read_bytes()
            rec = {"path": path, "url": src, "lm": row.get("lm"), "etag": None, "size": len(data), "sha1": hashlib.sha1(data).hexdigest()}
            if a.head_missing:
                try:
                    h = head(src)
                    rec["etag"] = h["etag"]
                    if h["size"] != len(data):
                        rec["replaced_since_head"] = True
                except Exception as e:  # noqa: BLE001
                    print(f"  HEAD {src}: {e}", file=sys.stderr)
            rec.update(ok=True, added=f"{a.today}: {row.get('added') or 'game/'}")
            add[site_ix].append(rec)
            known_site.add(path)
        elif origin == "capture" and re.match(r"https?://web\.archive\.org/web/\d+", src):
            path = row["path"]
            if path in known_way:
                continue
            data = file.read_bytes()
            # The raw capture (id_), not the page the Wayback Machine rewrites.
            raw = re.sub(r"^https?://web\.archive\.org/web/(\d+)(?:id_)?/", r"https://web.archive.org/web/\1id_/", src)
            add[way_ix].append({"path": path, "url": raw, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "ok": True,
                                "added": f"{a.today}: {row.get('added') or 'game/'}"})
            known_way.add(path)

    for ix, recs in add.items():
        if not recs:
            continue
        ix.parent.mkdir(parents=True, exist_ok=True)
        with ix.open("a", encoding="utf-8") as f:
            for r in sorted(recs, key=lambda r: r["path"]):
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
        size = sum(r["size"] for r in recs)
        print(f"{ix.relative_to(meta)}: +{len(recs)} files ({size / 1e6:.1f} MB)")
    if missing_etag:
        print(f"{missing_etag} without an ETag (not in the inventories; --head-missing asks the CDN)")


if __name__ == "__main__":
    main()
