#!/usr/bin/env python3
"""Re-judge mirror/ and supplement/ files with the live CDN's upload dates.

A file's own XMP date proves its age only when Flash wrote one; files without
it were judged by format alone ("undated, era format"), and one such scene
turned out to be from 2015. The live CDN's Last-Modified header (logged by
tools/live_archive.py head) dates every file it still serves. This lists, for
the client's root (www.9aola.com), each file whose header date contradicts
where it sits:

  promote   in supplement/, but uploaded on or before the release date and
            byte-identical in size: an original after all
  demote    in mirror/ or counted as era, but uploaded after the release

  tools/reclassify.py --head work/live/head.jsonl --roots mirror,supplement --release 2013-01-25 --out reclass.json
"""
from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--head", required=True)
    p.add_argument("--roots", required=True)
    p.add_argument("--host", default="www.9aola.com")
    p.add_argument("--release", default="2013-01-25")
    p.add_argument("--out", required=True)
    a = p.parse_args(argv)
    lm = {}
    for line in open(a.head, encoding="utf-8"):
        r = json.loads(line)
        if r.get("status") == 200:
            lm[r["path"]] = r
    cut = a.release + "T23:59:59Z"
    out = {"promote": [], "demote": [], "unknown": 0, "checked": 0}
    for root in a.roots.split(","):
        base = Path(root) / a.host
        for dirpath, _, files in os.walk(base):
            for f in files:
                rel = os.path.relpath(os.path.join(dirpath, f), base)
                path = re.sub(r"%3F.*$", "", rel)  # drop the ?version
                r = lm.get(path)
                if r is None:
                    out["unknown"] += 1
                    continue
                out["checked"] += 1
                size = os.path.getsize(os.path.join(dirpath, f))
                old = r["lm"] <= cut
                if Path(root).name == "supplement" and old and size == r.get("size"):
                    out["promote"].append({"file": f"{root}/{a.host}/{rel}", "lm": r["lm"]})
                elif Path(root).name == "mirror" and not old and size == r.get("size"):
                    out["demote"].append({"file": f"{root}/{a.host}/{rel}", "lm": r["lm"]})
    Path(a.out).write_text(json.dumps(out, indent=1), encoding="utf-8")
    print(f"checked {out['checked']}, not on the CDN or not asked {out['unknown']}; "
          f"promote {len(out['promote'])}, demote {len(out['demote'])}")


if __name__ == "__main__":
    main()
