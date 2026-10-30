#!/usr/bin/env python3
"""Add live CDN copies of files the 2013 client asks for to game/.

For files the January 2013 client names that are not in game/ (not in the
archive, docs/ARCHIVE.md) and that the live CDN still serves. Each goes to
game/ under the name the 2013 client asks for (<path>%3F1210 for SWFs, the
loader's default version) and into game/FILES.jsonl with the CDN upload date
and "added": the reason given; origin "era" when it was uploaded by 25 January
2013 (the archive's first pass had not asked for it), else "later". Building
never downloads anything; this is for curating game/.

  tools/add_later.py --game game --live-head <live inventory head.jsonl> \\
      --why "HELLO in scenes" skin/a000033.swf skin/a300000.swf
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import urllib.request

WWW = "www.9aola.com"
CDN = "http://aola.100bt.com/play/"
UA = {"User-Agent": "Mozilla/5.0 aola-revival add_later"}
# Uploaded before this (UTC) = what the January 2013 client could load.
ERA_END = "2013-01-26"


def game_name(path: str) -> str:
    return path + ("%3F1210" if path.endswith(".swf") else "")


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True)
    ap.add_argument("--live-head", required=True, action="append", help="a live CDN inventory (path, status, lm, size per line); may be given more than once")
    ap.add_argument("--why", required=True, help='what they are for, kept as "added" in FILES.jsonl')
    ap.add_argument("--cdn", default=CDN, help=argparse.SUPPRESS)
    ap.add_argument("paths", nargs="+", help="CDN paths, e.g. skin/a000033.swf")
    a = ap.parse_args(argv)

    head = {}
    for inv in a.live_head:
        for line in open(inv, encoding="utf-8"):
            r = json.loads(line)
            if r.get("status") == 200:
                head[r["path"]] = r
    files = os.path.join(a.game, "FILES.jsonl")
    rows = [json.loads(l) for l in open(files, encoding="utf-8")]
    known = {r["path"] for r in rows}
    added = 0
    for p in a.paths:
        rel = f"{WWW}/{game_name(p)}"
        if rel in known:
            print(f"  {p}: already in game/")
            continue
        if p not in head:
            print(f"  {p}: not on the live CDN", file=sys.stderr)
            continue
        req = urllib.request.Request(a.cdn + p, headers=UA)
        with urllib.request.urlopen(req, timeout=60) as r:
            data = r.read()
        if len(data) != head[p]["size"]:
            print(f"  {p}: size {len(data)} is not the inventory's {head[p]['size']}; replaced since", file=sys.stderr)
        dest = os.path.join(a.game, *rel.split("/"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as f:
            f.write(data)
        origin = "era" if head[p]["lm"] < ERA_END else "later"
        rows.append({"path": rel, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": origin,
                     "lm": head[p]["lm"], "src": p, "added": a.why})
        added += 1
        print(f"  {p}: {len(data)} bytes, uploaded {head[p]['lm'][:10]} ({origin})")
    with open(files, "w", encoding="utf-8") as f:
        for r in sorted(rows, key=lambda r: r["path"]):
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"added {added} files")


if __name__ == "__main__":
    main()
