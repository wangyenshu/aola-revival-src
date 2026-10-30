#!/usr/bin/env python3
"""Unpack the archive pieces (archive-NNN.zip) into an archive folder and verify them.

Writes every member in place (open for writing, never delete), so it works in
folders where deleting is not allowed and can be re-run after an interrupted
copy. Then checks each file listed in index.jsonl and _later/index.jsonl
against its recorded size and SHA-1.

    python tools/extract_archive.py --pieces <folder with archive-*.zip> --out <archive folder>
    python tools/extract_archive.py --out <archive folder> --verify-only
    python tools/extract_archive.py --out <archive folder> --from-cdn

--from-cdn rebuilds the archive on a computer that can reach the CDN itself:
it reads the two indexes already in <archive folder>, downloads each file from
its recorded URL and keeps it only if its SHA-1 matches the archived copy.
Files the operator has since replaced are listed in _restore-mismatch.txt;
copy those from the archive pieces instead.
"""
import argparse
import glob
import hashlib
import json
import os
import sys
import threading
import urllib.request
import zipfile
from concurrent.futures import ThreadPoolExecutor

ROOTS = (("index.jsonl", "aola.100bt.com/play"), ("_later/index.jsonl", "_later/aola.100bt.com/play"))


def extract(pieces, out):
    files = sorted(glob.glob(os.path.join(pieces, "archive-*.zip")))
    if not files:
        sys.exit(f"no archive-*.zip in {pieces}")
    n = 0
    for f in files:
        with zipfile.ZipFile(f) as z:
            for info in z.infolist():
                if info.is_dir():
                    continue
                name = info.filename.replace("\\", "/")
                if name.startswith("/") or ".." in name.split("/"):
                    sys.exit(f"unsafe member {name!r} in {f}")
                dest = os.path.join(out, *name.split("/"))
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                with z.open(info) as src, open(dest, "wb") as dst:
                    while True:
                        b = src.read(1 << 20)
                        if not b:
                            break
                        dst.write(b)
                n += 1
        print(f"  {os.path.basename(f)}: done ({n} files so far)", flush=True)
    return n


def load_index(out, index):
    latest = {}
    with open(os.path.join(out, *index.split("/")), encoding="utf-8") as fh:
        for line in fh:
            rec = json.loads(line)
            latest[rec["path"]] = rec  # a retried download appends a newer line
    return [r for r in latest.values() if r.get("ok")]


def sha1_of(path):
    try:
        with open(path, "rb") as f:
            return hashlib.sha1(f.read()).hexdigest()
    except OSError:
        return None


def from_cdn(out, workers, time_limit=0.0):
    """Download each indexed file from its URL; keep it only if its SHA-1 matches.

    Resumable: verified paths are appended to _restore-done.txt and skipped on
    the next run, and --time-limit stops starting new downloads after N seconds
    (for shells that cannot keep a long job running).
    """
    import time
    deadline = time.monotonic() + time_limit if time_limit else None
    done_path = os.path.join(out, "_restore-done.txt")
    done = set()
    if os.path.exists(done_path):
        with open(done_path, encoding="utf-8") as f:
            done = set(f.read().split())
    jobs = []
    for index, root in ROOTS:
        for rec in load_index(out, index):
            key = f"{root}/{rec['path']}"
            if key not in done:
                jobs.append((os.path.join(out, *root.split("/"), *rec["path"].split("/")), rec, key))
    total = len(jobs) + len(done)
    lock = threading.Lock()
    counts = {"had": 0, "got": 0, "mismatch": 0, "failed": 0, "left": 0}
    mism = []
    done_fh = open(done_path, "a", encoding="utf-8")

    def work(job):
        dest, rec, key = job
        if deadline and time.monotonic() > deadline:
            kind = "left"
        elif sha1_of(dest) == rec["sha1"]:
            kind = "had"
        else:
            kind = "failed"
            for attempt in range(3):
                try:
                    req = urllib.request.Request(rec["url"], headers={"User-Agent": "Mozilla/5.0 aola-revival archive"})
                    with urllib.request.urlopen(req, timeout=20) as r:
                        body = r.read()
                    if hashlib.sha1(body).hexdigest() != rec["sha1"]:
                        kind = "mismatch"
                        break
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, "wb") as f:
                        f.write(body)
                    kind = "got"
                    break
                except Exception:  # noqa: BLE001
                    if deadline and time.monotonic() > deadline:
                        break
        with lock:
            counts[kind] += 1
            if kind in ("had", "got"):
                done_fh.write(key + "\n")
            elif kind in ("mismatch", "failed"):
                mism.append(key)

    with ThreadPoolExecutor(max_workers=workers) as pool:
        list(pool.map(work, jobs))
    done_fh.close()
    if mism:
        with open(os.path.join(out, "_restore-mismatch.txt"), "a", encoding="utf-8") as f:
            f.write("\n".join(mism) + "\n")
    print(f"from-cdn: {len(done) + counts['had'] + counts['got']}/{total} done; this run {counts}")


def verify(out):
    bad, ok = [], 0
    for index, root in ROOTS:
        p = os.path.join(out, *index.split("/"))
        if not os.path.exists(p):
            bad.append((index, "index missing"))
            continue
        latest = {}
        with open(p, encoding="utf-8") as fh:
            for line in fh:
                rec = json.loads(line)
                latest[rec["path"]] = rec  # a retried download appends a newer line
        for rec in latest.values():
            if not rec.get("ok"):
                bad.append((rec["path"], "not downloaded"))
                continue
            path = os.path.join(out, *root.split("/"), *rec["path"].split("/"))
            try:
                with open(path, "rb") as f:
                    data = f.read()
            except OSError:
                bad.append((rec["path"], "missing"))
                continue
            if len(data) != rec["size"] or hashlib.sha1(data).hexdigest() != rec["sha1"]:
                bad.append((rec["path"], "size or sha1 differs"))
            else:
                ok += 1
    print(f"verified {ok} files, {len(bad)} problems")
    for path, why in bad[:50]:
        print(f"  {why}: {path}")
    return not bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pieces")
    ap.add_argument("--out", required=True)
    ap.add_argument("--verify-only", action="store_true")
    ap.add_argument("--from-cdn", action="store_true")
    ap.add_argument("--workers", type=int, default=16)
    ap.add_argument("--time-limit", type=float, default=0.0)
    a = ap.parse_args()
    if a.from_cdn:
        from_cdn(a.out, a.workers, a.time_limit)
        return
    elif not a.verify_only:
        if not a.pieces:
            ap.error("--pieces is required unless --verify-only")
        print(f"extracted {extract(a.pieces, a.out)} files")
    sys.exit(0 if verify(a.out) else 1)


if __name__ == "__main__":
    main()
