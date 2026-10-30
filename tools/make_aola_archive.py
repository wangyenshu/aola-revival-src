#!/usr/bin/env python3
"""Rebuild the 奥拉星 2010-2013 archive (taken 28 Oct 2026) from the live CDN.

Reads the archive's two indexes (index.jsonl and _later/index.jsonl, both in
archive-meta.zip), downloads every listed file from its original URL on
http://aola.100bt.com/play/, and keeps it only if its SHA-1 matches the copy
archived on 28 October 2026. Python 3.8+, standard library only.

    python3 make_aola_archive.py --index archive-meta.zip --out aola_archive_2013
    python3 make_aola_archive.py --index archive-meta.zip --out aola_archive_2013 --tar

--index   archive-meta.zip, or a folder that holds index.jsonl and _later/index.jsonl
--out     folder to build; re-running skips files already there and correct
--tar     afterwards also write <out>.tar.gz (only if every file checked out)
--workers parallel downloads (default 16)
--limit   only the first N files (for a quick test)

Result:
    <out>/aola.100bt.com/play/...          18,368 files uploaded 2010-2013
    <out>/_later/aola.100bt.com/play/...   7,213 later uploads that 2012/13 code refers to
                                           (among them the 1,483 battle sprites fightassets/pet<n>)
    <out>/index.jsonl, _later/index.jsonl, _meta/, ARCHIVE.md
    <out>/_changed-on-cdn.txt              files the operator has replaced since 28 Oct 2026

A file in _changed-on-cdn.txt can no longer be fetched as archived; its
28 Oct 2026 copy exists only in the original archive, so keep that list.
These are 百田's files, for private preservation. Do not redistribute.
"""
import argparse
import hashlib
import io
import json
import os
import sys
import tarfile
import threading
import time
import urllib.request
import zipfile
from concurrent.futures import ThreadPoolExecutor

INDEXES = (("index.jsonl", "aola.100bt.com/play"),
           ("_later/index.jsonl", "_later/aola.100bt.com/play"))
UA = {"User-Agent": "Mozilla/5.0 aola-revival archive"}


def read_meta(src):
    """Return {relative name: bytes} for the indexes, _meta/ and ARCHIVE.md."""
    files = {}
    if zipfile.is_zipfile(src):
        with zipfile.ZipFile(src) as z:
            for name in z.namelist():
                if not name.endswith("/") and ".." not in name.split("/") and not name.startswith("/"):
                    files[name] = z.read(name)
    else:
        for root, _, names in os.walk(src):
            for n in names:
                rel = os.path.relpath(os.path.join(root, n), src).replace(os.sep, "/")
                if rel in ("index.jsonl", "_later/index.jsonl", "ARCHIVE.md") or rel.startswith("_meta/"):
                    with open(os.path.join(root, n), "rb") as f:
                        files[rel] = f.read()
    for index, _ in INDEXES:
        if index not in files:
            sys.exit(f"{src} has no {index}")
    return files


def records(meta):
    jobs = []
    for index, root in INDEXES:
        latest = {}
        for line in io.TextIOWrapper(io.BytesIO(meta[index]), encoding="utf-8"):
            if line.strip():
                r = json.loads(line)
                latest[r["path"]] = r  # a retried download appends a newer line
        jobs += [(root, r) for r in latest.values() if r.get("ok")]
    return jobs


def sha1_file(path):
    h = hashlib.sha1()
    try:
        with open(path, "rb") as f:
            for b in iter(lambda: f.read(1 << 20), b""):
                h.update(b)
    except OSError:
        return None
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--index", required=True)
    ap.add_argument("--out", default="aola_archive_2013")
    ap.add_argument("--workers", type=int, default=16)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--tar", action="store_true")
    a = ap.parse_args()

    meta = read_meta(a.index)
    out = a.out
    os.makedirs(out, exist_ok=True)
    for name, data in meta.items():
        dest = os.path.join(out, *name.split("/"))
        os.makedirs(os.path.dirname(dest) or out, exist_ok=True)
        with open(dest, "wb") as f:
            f.write(data)

    jobs = records(meta)
    if a.limit:
        jobs = jobs[:a.limit]
    total_bytes = sum(r["size"] for _, r in jobs)
    print(f"{len(jobs)} files, {total_bytes / 1e6:.0f} MB -> {out}", flush=True)

    lock = threading.Lock()
    counts = {"had": 0, "downloaded": 0, "changed": 0, "failed": 0}
    changed, failed = [], []
    got_bytes = [0]
    t0 = time.monotonic()

    def work(job):
        root, r = job
        dest = os.path.join(out, *root.split("/"), *r["path"].split("/"))
        if os.path.exists(dest) and os.path.getsize(dest) == r["size"] and sha1_file(dest) == r["sha1"]:
            kind = "had"
        else:
            kind, err = "failed", ""
            for attempt in range(4):
                try:
                    req = urllib.request.Request(r["url"], headers=UA)
                    with urllib.request.urlopen(req, timeout=60) as resp:
                        body = resp.read()
                    if hashlib.sha1(body).hexdigest() != r["sha1"]:
                        kind = "changed"
                        break
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    tmp = dest + ".part"
                    with open(tmp, "wb") as f:
                        f.write(body)
                    os.replace(tmp, dest)
                    kind = "downloaded"
                    break
                except Exception as e:  # noqa: BLE001
                    err = repr(e)[:120]
                    time.sleep(2 * (attempt + 1))
        with lock:
            counts[kind] += 1
            if kind == "changed":
                changed.append(f"{root}/{r['path']}\t{r['etag']}\t{r['sha1']}")
            elif kind == "failed":
                failed.append(f"{root}/{r['path']}\t{err}")
            if kind in ("had", "downloaded"):
                got_bytes[0] += r["size"]
            n = sum(counts.values())
            if n % 500 == 0 or n == len(jobs):
                rate = got_bytes[0] / 1e6 / max(time.monotonic() - t0, 1e-6)
                print(f"  {n}/{len(jobs)} {counts} {rate:.1f} MB/s", flush=True)

    with ThreadPoolExecutor(max_workers=a.workers) as pool:
        list(pool.map(work, jobs))

    with open(os.path.join(out, "_changed-on-cdn.txt"), "w", encoding="utf-8") as f:
        f.write("# path\tarchived etag\tarchived sha1 (the CDN now serves a different file)\n")
        f.write("".join(x + "\n" for x in sorted(changed)))
    if failed:
        with open(os.path.join(out, "_failed.txt"), "w", encoding="utf-8") as f:
            f.write("".join(x + "\n" for x in sorted(failed)))
    print(f"done: {counts}")
    if changed:
        print(f"{len(changed)} files were replaced on the CDN since 28 Oct 2026: see _changed-on-cdn.txt")
    if failed:
        print(f"{len(failed)} downloads failed (network): run the same command again to retry them")

    if a.tar:
        if failed:
            print("not writing the tar while downloads are missing")
            return 1
        tar_path = out.rstrip("/\\") + ".tar.gz"
        print(f"writing {tar_path} ...", flush=True)
        with tarfile.open(tar_path, "w:gz", compresslevel=6) as t:
            t.add(out, arcname=os.path.basename(out.rstrip("/\\")))
        print(f"wrote {tar_path} ({os.path.getsize(tar_path) / 1e6:.0f} MB)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
