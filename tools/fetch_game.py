#!/usr/bin/env python3
"""Download 百田's game files into game/, for a checkout that does not have them.

The revival's code can be published without 百田's files: this puts them back
from 百田's own servers and the Wayback Machine, using the list
tools/data/game-sources.jsonl (tools/game_sources.py keeps it). Every file is
checked against the SHA-1 of the copy the revival was made with.

  python3 tools/fetch_game.py                 download what is missing into game/
  python3 tools/fetch_game.py --verify-only   only check the files already there
  python3 tools/fetch_game.py --keep-changed  also keep files whose server copy
                                              has changed since (see below)

Then build as usual: npm ci && npm run build:swf && npm run build
(tools/bootstrap.sh runs all of it).

What it does:

  1. For each file, unless game/ already holds it with the right SHA-1, tries
     its URLs in order: the live CDN (http://aola.100bt.com/play/…), a raw
     Wayback Machine capture (https://web.archive.org/web/<ts>id_/…, one
     request at a time, with a pause), or another 百田 host. A file is kept
     only if its SHA-1 matches; it is written next to its place and renamed
     in, so an interrupted run leaves no broken file and can simply be run
     again.
  2. Makes the few files that were made here, not downloaded (the theatre
     films as MP4 and WebM, and a frame of each), with FFmpeg from the film
     it downloaded. Their bytes differ from the revival's copy (encoders
     differ), so they are not checked.
  3. Writes game/FILES.jsonl (the list of what game/ holds) if it is missing.
  4. Writes a report (default work/fetch-game-report.json) and prints a
     summary: files fetched, already there, made, changed, failed.

Changed files: 百田 replaces files on its CDN from time to time, and its edge
servers do not all hold the same version, so a copy that does not match is
asked for again a few times (--mismatch-retries). A file whose download still
does not match is not kept unless --keep-changed is given; then
it is kept and listed as changed (the game may behave differently there).
Files the list marks with a note (the revival does not serve them) only give
a warning. Files that cannot be had at all are listed with their URLs; the
archive (docs/ARCHIVE.md) still has them.

Python 3.8+, standard library only. Honours HTTP_PROXY / HTTPS_PROXY.
These are 百田's files, for private preservation and study: do not
redistribute them.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
UA = {"User-Agent": "Mozilla/5.0 aola-revival"}
FILES_KEYS = ("path", "size", "sha1", "origin", "lm", "src", "added", "from")


def read_jsonl(path: str) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def sha1_of(path: str) -> str:
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def local(out: str, rel: str) -> str:
    return os.path.join(out, *rel.split("/"))


def is_good(path: str, row: dict) -> bool:
    return os.path.isfile(path) and os.path.getsize(path) == row["size"] and sha1_of(path) == row["sha1"]


class Fetcher:
    def __init__(self, a: argparse.Namespace):
        self.a = a
        self.wayback_lock = threading.Lock()
        self.wayback_last = 0.0

    def get(self, url: str) -> bytes:
        """The bytes at url, with retries; raises on failure."""
        wayback = "web.archive.org" in url
        last: Exception | None = None
        for attempt in range(self.a.retries):
            if wayback:
                # The Wayback Machine throttles clients that hammer it: one request at a time, paced.
                with self.wayback_lock:
                    wait = self.wayback_last + self.a.wayback_delay - time.time()
                    if wait > 0:
                        time.sleep(wait)
                    self.wayback_last = time.time()
                    try:
                        return self._read(url)
                    except Exception as e:  # noqa: BLE001
                        last = e
            else:
                try:
                    return self._read(url)
                except Exception as e:  # noqa: BLE001
                    last = e
            if isinstance(last, urllib.error.HTTPError) and last.code in (403, 404, 410):
                break
            time.sleep(min(30, 2 ** attempt * (5 if wayback else 1)))
        raise last if last else RuntimeError("no attempt")

    def _read(self, url: str) -> bytes:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=self.a.timeout) as r:
            return r.read()

    def fetch(self, row: dict) -> dict:
        dest = local(self.a.out, row["path"])
        if is_good(dest, row):
            return {"path": row["path"], "status": "present"}
        tried, changed = [], None
        for url in row.get("urls", []):
            # The CDN's edge servers do not all hold the same version of a replaced
            # file: a copy that does not match is asked for again a few times.
            again = 0 if "web.archive.org" in url else self.a.mismatch_retries
            for attempt in range(again + 1):
                try:
                    data = self.get(url)
                except Exception as e:  # noqa: BLE001
                    tried.append(f"{url}: {e}")
                    break
                if hashlib.sha1(data).hexdigest() == row["sha1"]:
                    self.write(dest, data)
                    return {"path": row["path"], "status": "fetched", "url": url, "attempts": attempt + 1}
                if changed is None:
                    changed = (url, data)
                if attempt < again:
                    time.sleep(1 + attempt)
            else:
                tried.append(f"{url}: SHA-1 differs ({len(changed[1]) if changed else '?'} bytes, expected {row['size']}), "
                             f"{again + 1} tries")
        if changed is not None and self.a.keep_changed:
            self.write(dest, changed[1])
            return {"path": row["path"], "status": "changed", "url": changed[0], "tried": tried, "note": row.get("note")}
        status = "noted" if row.get("note") else ("changed-skipped" if changed is not None else "failed")
        return {"path": row["path"], "status": status, "tried": tried, "note": row.get("note")}

    @staticmethod
    def write(dest: str, data: bytes) -> None:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        part = dest + ".part"
        with open(part, "wb") as f:
            f.write(data)
        os.replace(part, dest)


def derive(a: argparse.Namespace, row: dict) -> dict:
    dest = local(a.out, row["path"])
    if os.path.isfile(dest) and os.path.getsize(dest) > 0:
        return {"path": row["path"], "status": "present"}
    d = row["derive"]
    src = local(a.out, d["from"])
    if not os.path.isfile(src):
        return {"path": row["path"], "status": "failed", "tried": [f"its source {d['from']} is missing"]}
    if a.no_derive or not shutil.which(a.ffmpeg):
        return {"path": row["path"], "status": "skipped", "tried": [f"needs FFmpeg ({a.ffmpeg})"]}
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    args = [x.replace("{in}", src).replace("{out}", dest) for x in d["args"]]
    try:
        subprocess.run([a.ffmpeg, *args], check=True)
    except subprocess.CalledProcessError as e:
        return {"path": row["path"], "status": "failed", "tried": [f"ffmpeg: {e}"]}
    return {"path": row["path"], "status": "made"}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sources", default=os.path.join(HERE, "data", "game-sources.jsonl"))
    ap.add_argument("--out", default=os.path.join(ROOT, "game"), help="the game folder (default game/)")
    ap.add_argument("--only", action="append", help="only paths starting with this (repeatable), e.g. www.9aola.com/scene/")
    ap.add_argument("--limit", type=int, default=0, help="only the first N files (a quick test)")
    ap.add_argument("--workers", type=int, default=8, help="parallel downloads from the CDN (default 8)")
    ap.add_argument("--retries", type=int, default=3, help="tries for a request that fails")
    ap.add_argument("--mismatch-retries", type=int, default=6,
                    help="extra tries for a CDN file whose copy does not match (default 6)")
    ap.add_argument("--timeout", type=int, default=120, help="seconds per request")
    ap.add_argument("--wayback-delay", type=float, default=1.5, help="seconds between Wayback Machine requests")
    ap.add_argument("--keep-changed", action="store_true", help="keep files whose server copy no longer matches")
    ap.add_argument("--verify-only", action="store_true", help="check the files already in game/, download nothing")
    ap.add_argument("--ffmpeg", default="ffmpeg")
    ap.add_argument("--no-derive", action="store_true", help="do not make the theatre's MP4, WebM and pictures")
    ap.add_argument("--report", default=os.path.join(ROOT, "work", "fetch-game-report.json"))
    a = ap.parse_args(argv)

    rows = read_jsonl(a.sources)
    if a.only:
        rows = [r for r in rows if any(r["path"].startswith(p) for p in a.only)]
    if a.limit:
        rows = rows[: a.limit]
    plain = [r for r in rows if not r.get("derive")]
    made = [r for r in rows if r.get("derive")]
    total = sum(r["size"] for r in plain)
    print(f"{len(plain)} files to check ({total / 1e6:.0f} MB), {len(made)} to make; into {a.out}")

    results: list[dict] = []
    if a.verify_only:
        for r in plain:
            ok = is_good(local(a.out, r["path"]), r)
            results.append({"path": r["path"], "status": "present" if ok else ("noted" if r.get("note") else "failed"),
                            "note": r.get("note")})
    else:
        f = Fetcher(a)
        # Wayback captures one at a time on their own thread; CDN files in parallel.
        cdn = [r for r in plain if not any("web.archive.org" in u for u in r.get("urls", [])[:1])]
        wb = [r for r in plain if r not in cdn]
        done = 0
        start = time.time()
        with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, a.workers)) as ex:
            futures = [ex.submit(f.fetch, r) for r in cdn]
            futures.append(ex.submit(lambda: [f.fetch(r) for r in wb]))
            for fut in concurrent.futures.as_completed(futures):
                res = fut.result()
                for one in res if isinstance(res, list) else [res]:
                    results.append(one)
                    done += 1
                    if one["status"] not in ("present", "fetched"):
                        print(f"  {one['status']}: {one['path']}")
                    if done % 500 == 0:
                        print(f"  {done}/{len(plain)} ({time.time() - start:.0f} s)")
    for r in made:
        res = {"path": r["path"], "status": "present"} if a.verify_only and os.path.isfile(local(a.out, r["path"])) else (
            {"path": r["path"], "status": "skipped"} if a.verify_only else derive(a, r))
        results.append(res)
        if res["status"] not in ("present", "made"):
            print(f"  {res['status']}: {r['path']}")

    files_jsonl = os.path.join(a.out, "FILES.jsonl")
    if not a.verify_only and not a.only and not a.limit and not os.path.exists(files_jsonl):
        os.makedirs(a.out, exist_ok=True)
        with open(files_jsonl, "w", encoding="utf-8") as fh:
            for r in sorted(read_jsonl(a.sources), key=lambda r: r["path"]):
                fh.write(json.dumps({k: r[k] for k in FILES_KEYS if k in r}, ensure_ascii=False) + "\n")
        print(f"wrote {files_jsonl}")

    counts: dict[str, int] = {}
    for r in results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    problems = [r for r in results if r["status"] not in ("present", "fetched", "made")]
    os.makedirs(os.path.dirname(os.path.abspath(a.report)), exist_ok=True)
    with open(a.report, "w", encoding="utf-8") as fh:
        json.dump({"counts": counts, "problems": problems}, fh, ensure_ascii=False, indent=1)
    print("summary: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))
    print(f"report: {a.report}")
    hard = [r for r in problems if r["status"] in ("failed", "changed-skipped")]
    if hard:
        print(f"{len(hard)} files could not be had as listed (see the report); "
              "--keep-changed keeps the changed ones, the archive has the rest.")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
