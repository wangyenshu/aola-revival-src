#!/usr/bin/env python3
"""Fill the mirror/ and supplement/ roots from the live-CDN archive.

The archive (tools/live_archive.py, see docs/ARCHIVE.md) holds every file the
live CDN still serves from 2010-2013, plus later uploads that 2012/13 code
names. Each file is placed at the URL the January 2013 client asks for:
www.9aola.com/<path>%3F<version>, the version being the one in the
2013-01-25 manifest, or the loader's default "1210" for files the manifest
does not list.

  mirror/      the file was uploaded on or before the release date, so it is
               the very file the January 2013 client loaded (or an older,
               unchanged one)
  supplement/  uploaded after the release (later in 2013, or 2014 on): used
               only where nothing older exists

Existing files are never overwritten; a file already in mirror/ or
supplement/ (or rebuilt/) for that path is left alone.

  tools/fill_from_archive.py --archive aola_archive_2013 --manifest manifest-2013-01-25.xml \\
      --mirror mirror --supplement supplement [--rebuilt rebuilt] [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import xml.etree.ElementTree as ET
from collections import Counter

HOST = "www.9aola.com"
DEFAULT_VER = "1210"


def latest(index_path: str) -> dict:
    out = {}
    with open(index_path, encoding="utf-8") as f:
        for line in f:
            r = json.loads(line)
            out[r["path"]] = r
    return {p: r for p, r in out.items() if r.get("ok")}


def existing(roots: list[str]) -> set[str]:
    """Paths (without the %3F version) that some root already serves."""
    have = set()
    for root in roots:
        base = os.path.join(root, HOST)
        if not os.path.isdir(base):
            continue
        for d, _, names in os.walk(base):
            for n in names:
                rel = os.path.relpath(os.path.join(d, n), base).replace(os.sep, "/")
                have.add(re.sub(r"%3F.*$", "", rel))
    return have


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--archive", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--mirror", required=True)
    ap.add_argument("--supplement", required=True)
    ap.add_argument("--rebuilt")
    ap.add_argument("--release", default="2013-01-25")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--log", help="write the placed files here (jsonl)")
    a = ap.parse_args(argv)

    ver = {f.get("n"): f.get("v") for f in ET.parse(a.manifest).getroot().iter("f")}
    have = existing([r for r in (a.rebuilt, a.mirror, a.supplement) if r])
    cut = a.release + "T23:59:59Z"
    placed = Counter()
    log = open(a.log, "w", encoding="utf-8") if a.log else None
    sources = [(os.path.join(a.archive, "index.jsonl"), os.path.join(a.archive, "aola.100bt.com", "play")),
               (os.path.join(a.archive, "_later", "index.jsonl"), os.path.join(a.archive, "_later", "aola.100bt.com", "play"))]
    for index, root in sources:
        for path, r in sorted(latest(index).items()):
            if path in have:
                placed["already served"] += 1
                continue
            stem, ext = os.path.splitext(path)
            v = ver.get(stem, DEFAULT_VER) if ext == ".swf" else ver.get(stem)
            name = path + ("%3F" + v if v else "")
            era = r["lm"] <= cut
            dest_root = a.mirror if era else a.supplement
            dest = os.path.join(dest_root, HOST, *name.split("/"))
            placed[("mirror " if era else "supplement ") + ("listed" if stem in ver else "unlisted")] += 1
            if log:
                log.write(json.dumps({"path": path, "to": os.path.relpath(dest, os.path.dirname(dest_root.rstrip("/")) or "."), "lm": r["lm"], "xmp": r.get("xmp")}, ensure_ascii=False) + "\n")
            if not a.dry_run:
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                shutil.copyfile(os.path.join(root, *path.split("/")), dest)
            have.add(path)
    for k, n in sorted(placed.items()):
        print(f"{n:6d}  {k}")


if __name__ == "__main__":
    main()
