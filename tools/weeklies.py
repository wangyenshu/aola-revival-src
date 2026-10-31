#!/usr/bin/env python3
"""Take the 奥拉周刊 back issues from the live CDN into game/.

The January 2013 client opens the current 奥拉周刊 (config.xml <weekly>) as a
catalog book; the archive (docs/ARCHIVE.md) has the pages of only five issues
(116, 117, 118, 121, 126), the ones the 2013 manifests named. The CDN still
serves the pages of every issue from 1 (July 2010) on, at
weekly/aolaweekly<n>_<k>.swf (the first issues) or
weekly/weekly<n>/aolaweekly<n>_<k>.swf; most were uploaded again, unchanged,
on 17 October 2024 (their own embedded dates are of their week). This asks
the CDN for the pages of issues --first to --last (pages 1 to --max-pages,
stopping after --gap missing in a row), downloads those game/ lacks, and
lists each in game/FILES.jsonl with its upload date and "added": --why;
origin "era" when uploaded by 25 January 2013 or when the date Flash wrote in
it (XMP) is that early, else "later". Building never downloads anything; this
is for curating game/. tools/gen_bconfig.py then makes each issue a book.

  tools/weeklies.py --game game --first 1 --last 128 --why "奥拉周刊 back issues"
"""
from __future__ import annotations

import argparse
import concurrent.futures
import email.utils
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import swfinfo  # noqa: E402

CDN = "http://aola.100bt.com/play/"
WWW = "www.9aola.com"
UA = {"User-Agent": "Mozilla/5.0 aola-revival weeklies"}
ERA_END = "2013-01-26"


def retry(fn):
    def wrapped(*args):
        for attempt in range(4):
            try:
                return fn(*args)
            except urllib.error.HTTPError:
                raise
            except Exception:  # noqa: BLE001
                if attempt == 3:
                    raise
    return wrapped


@retry
def _head(path: str):
    req = urllib.request.Request(CDN + path, method="HEAD", headers=UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        lm = r.headers.get("Last-Modified")
        when = email.utils.parsedate_to_datetime(lm).strftime("%Y-%m-%dT%H:%M:%SZ") if lm else None
        return {"path": path, "status": 200, "lm": when, "size": int(r.headers.get("Content-Length", -1))}


def head(path: str):
    try:
        return _head(path)
    except urllib.error.HTTPError as e:
        return {"path": path, "status": e.code}
    except Exception:  # noqa: BLE001
        return {"path": path, "status": -1}


@retry
def get(path: str) -> bytes:
    req = urllib.request.Request(CDN + path, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True)
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--last", type=int, default=128)
    ap.add_argument("--max-pages", type=int, default=30)
    ap.add_argument("--gap", type=int, default=3)
    ap.add_argument("--why", default="奥拉周刊 back issues")
    ap.add_argument("--workers", type=int, default=16)
    a = ap.parse_args(argv)

    files = os.path.join(a.game, "FILES.jsonl")
    rows = [json.loads(l) for l in open(files, encoding="utf-8")]
    known = {r["path"].split("%3F")[0] for r in rows}

    # Which layout each issue uses: its first page under either name.
    forms = {}
    with concurrent.futures.ThreadPoolExecutor(a.workers) as ex:
        probes = {}
        for n in range(a.first, a.last + 1):
            probes[(n, "a")] = ex.submit(head, f"weekly/aolaweekly{n}_1.swf")
            probes[(n, "b")] = ex.submit(head, f"weekly/weekly{n}/aolaweekly{n}_1.swf")
        for n in range(a.first, a.last + 1):
            if probes[(n, "b")].result()["status"] == 200:
                forms[n] = f"weekly/weekly{n}/aolaweekly{n}_"
            elif probes[(n, "a")].result()["status"] == 200:
                forms[n] = f"weekly/aolaweekly{n}_"
    print(f"{len(forms)} issues on the CDN of {a.last - a.first + 1} asked")

    def pages_of(n: int) -> list[dict]:
        out, miss = [], 0
        for k in range(1, a.max_pages + 1):
            h = head(f"{forms[n]}{k}.swf")
            if h["status"] == 200:
                out.append(h)
                miss = 0
            else:
                miss += 1
                if miss >= a.gap:
                    break
        return out

    found: list[dict] = []
    with concurrent.futures.ThreadPoolExecutor(a.workers) as ex:
        for got in ex.map(pages_of, sorted(forms)):
            found += got
    todo = [h for h in found if f"{WWW}/{h['path']}" not in known]
    print(f"{len(found)} pages, {len(todo)} not in game/ ({sum(h['size'] for h in todo) / 1e6:.0f} MB)")

    def fetch(h: dict):
        data = get(h["path"])
        rel = f"{WWW}/{h['path']}%3F1210"
        dest = os.path.join(a.game, *rel.split("/"))
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as f:
            f.write(data)
        info = swfinfo.inspect(data)
        xmp = info.modify_yymmdd if info.ok else None
        era = (h["lm"] or "9999") < ERA_END or (xmp is not None and xmp <= "130125")
        row = {"path": rel, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": "era" if era else "later",
               "lm": h["lm"], "src": h["path"], "added": a.why + (f" (its own date {xmp})" if xmp and (h["lm"] or "") >= ERA_END else "")}
        return row

    added = []
    with concurrent.futures.ThreadPoolExecutor(a.workers) as ex:
        for row in ex.map(fetch, todo):
            added.append(row)
    rows += added
    with open(files, "w", encoding="utf-8") as f:
        for r in sorted(rows, key=lambda r: r["path"]):
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    era = sum(1 for r in added if r["origin"] == "era")
    print(f"added {len(added)} pages ({era} era by date), {sum(r['size'] for r in added) / 1e6:.0f} MB")


if __name__ == "__main__":
    main()
