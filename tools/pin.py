#!/usr/bin/env python3
"""Pin dynamic URLs to one archived capture.

The client asks for some files with a cache-busting query the archive can't
match, e.g. start.swf requests login.9aola.com/start.xml?<milliseconds>. Every
runtime falls back to the query-less path when the exact URL is missing, so
pinning = copying the chosen capture's original bytes to that query-less path.
Each pin is recorded in work/pins.jsonl so the mirror stays auditable.

  python tools/pin.py --mirror mirror login.9aola.com/start.xml=login.9aola.com/start.xml%3F1359612776359
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import shutil
from pathlib import Path


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("pins", nargs="+", help="QUERYLESS_RELPATH=CAPTURED_RELPATH")
    p.add_argument("--mirror", default="mirror")
    p.add_argument("--log", default="work/pins.jsonl")
    a = p.parse_args()
    mirror, log = Path(a.mirror), Path(a.log)
    log.parent.mkdir(parents=True, exist_ok=True)
    for spec in a.pins:
        target, source = spec.split("=", 1)
        src, dst = mirror / source, mirror / target
        if not src.is_file():
            raise SystemExit(f"capture not in mirror: {src}")
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        rec = {"pinned": target, "from": source, "sha1": hashlib.sha1(src.read_bytes()).hexdigest(),
               "t": dt.datetime.now().isoformat(timespec="seconds")}
        with log.open("a", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")
        print(f"pinned {target} <- {source}")


if __name__ == "__main__":
    main()
