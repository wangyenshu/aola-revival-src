#!/usr/bin/env python3
"""Where each client module of the January 2013 release can come from.

For every module path (from the manifest, the config's <play>/<libs> lists and
ServiceConfig), find the file the client would request (name.swf?<version>,
unlisted files at ?1210) in the layered roots and judge it:

  original  era build: SWF version <= 11 and no XMP date after the release
  late      only a later rebuild exists (ZWS/v18+, or XMP after the release)
  missing   no copy at all

Usage: tools/module_status.py --manifest work/manifest-2013-01-25.xml \\
          --roots mirror,supplement --modules list.txt --out status.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import swfinfo  # noqa: E402
from mirrorpath import url_to_relpath  # noqa: E402

RELEASE = "130125"


def judge(path: Path) -> dict:
    info = swfinfo.inspect(path.read_bytes())
    late = info.swf_version > 11 or (info.modify_yymmdd or "") > RELEASE
    return {"status": "late" if late else "original", "swf": f"{info.compression} v{info.swf_version}",
            "xmp": info.modify_yymmdd}


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--manifest", required=True)
    p.add_argument("--roots", required=True, help="comma list of mirror roots, in priority order")
    p.add_argument("--modules", required=True, help="text file, one module path per line")
    p.add_argument("--base", default="http://www.9aola.com/")
    p.add_argument("--out", required=True)
    a = p.parse_args(argv)
    versions = dict(re.findall(r'<f\s+n="([^"]+)"\s+v="([^"]+)"', Path(a.manifest).read_text(encoding="utf-8", errors="ignore")))
    roots = [Path(r) for r in a.roots.split(",")]
    out = {}
    for m in [l.strip() for l in Path(a.modules).read_text().splitlines() if l.strip()]:
        v = versions.get(m, "1210")
        rel = url_to_relpath(f"{a.base}{m}.swf?{v}")
        rec = {"version": v, "status": "missing"}
        for r in roots:
            f = r / rel
            if f.is_file():
                rec.update(judge(f), root=r.name)
                break
        out[m] = rec
    Path(a.out).write_text(json.dumps(out, indent=1), encoding="utf-8")
    from collections import Counter
    print(Counter(r["status"] for r in out.values()))


if __name__ == "__main__":
    main()
