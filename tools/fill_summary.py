#!/usr/bin/env python3
"""Summarize a fill-manifest log (work/fill-live.jsonl) into a coverage table.

Adds two splits the raw outcomes hide:
  newer    by <=3 days: modified within days of the manifest stamp, probably the
           same build re-saved or stamped at deploy time (kept unverified)
  undated  by SWF format: v<=11 matches the 2012/13 originals (Flash CS4 era);
           v>=13 or LZMA (ZWS) means the file was rebuilt with a later toolchain

  python tools/fill_summary.py work/fill-live.jsonl [--markdown out.md]
"""

from __future__ import annotations

import argparse
import collections
import datetime as dt
import json
from pathlib import Path


def days_between(a: str, b: str) -> int | None:
    try:
        return (dt.datetime.strptime(a, "%y%m%d") - dt.datetime.strptime(b, "%y%m%d")).days
    except (TypeError, ValueError):
        return None


def load(path: Path) -> list[dict]:
    latest: dict[str, dict] = {}
    for line in path.read_text("utf-8").splitlines():
        if line.strip():
            r = json.loads(line)
            latest[r["url"]] = r
    return list(latest.values())


def bucket(r: dict) -> str:
    o = r["outcome"]
    if o == "newer":
        d = days_between(r.get("xmp_modify"), r["v"][:6])
        return "newer-near" if d is not None and d <= 3 else "newer"
    if o == "undated":
        swf = r.get("swf") or ""
        if swf.startswith("ZWS"):
            return "undated-rebuilt"
        try:
            ver = int(swf.split("v")[-1])
        except ValueError:
            return "undated-rebuilt"
        return "undated-era" if ver <= 11 else "undated-rebuilt"
    if o.startswith("http-"):
        return "missing"
    if o in ("verified", "verified-older"):
        return "verified"
    return "other"


COLS = ["verified", "newer-near", "newer", "undated-era", "undated-rebuilt", "missing", "other"]
LABELS = {
    "verified": "verified 2012/13",
    "newer-near": "newer by ≤3 days",
    "newer": "changed later",
    "undated-era": "undated, 2012-era format",
    "undated-rebuilt": "undated, rebuilt",
    "missing": "not on CDN",
    "other": "error",
}


def table(rows: list[dict]) -> tuple[str, collections.Counter, int]:
    by = collections.defaultdict(collections.Counter)
    for r in rows:
        by[r["name"].split("/")[0]][bucket(r)] += 1
    big = sorted(by, key=lambda k: -sum(by[k].values()))
    head, rest = big[:10], big[10:]
    lines = ["| Folder | Files | " + " | ".join(LABELS[c] for c in COLS) + " |",
             "| --- | ---: | " + " | ".join("---:" for _ in COLS) + " |"]
    tot = collections.Counter()
    for k in head:
        c = by[k]
        tot.update(c)
        lines.append(f"| {k} | {sum(c.values())} | " + " | ".join(str(c[x]) for x in COLS) + " |")
    if rest:
        c = collections.Counter()
        for k in rest:
            c.update(by[k])
        tot.update(c)
        lines.append(f"| other {len(rest)} folders | {sum(c.values())} | " + " | ".join(str(c[x]) for x in COLS) + " |")
    n = sum(tot.values())
    lines.append(f"| **all** | **{n}** | " + " | ".join(f"**{tot[x]}**" for x in COLS) + " |")
    size = sum(r.get("size", 0) for r in rows if bucket(r) == "verified")
    return "\n".join(lines), tot, size


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("log", type=Path)
    p.add_argument("--markdown", type=Path)
    a = p.parse_args()
    rows = load(a.log)
    md, tot, size = table(rows)
    n = sum(tot.values()) or 1
    summary = (f"{tot['verified']} of {n} files ({100 * tot['verified'] / n:.0f}%) verified as the 2012/13 version, "
               f"{size / 1e6:.0f} MB; {tot['newer-near']} more within 3 days of their stamp.")
    print(md)
    print("\n" + summary)
    if a.markdown:
        a.markdown.write_text(md + "\n\n" + summary + "\n", "utf-8")


if __name__ == "__main__":
    main()
