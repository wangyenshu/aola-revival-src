#!/usr/bin/env python3
"""Put the game files the revival serves into one folder, game/, and list them.

The January 2013 client asks for www.9aola.com/<path>?<version>. Until now
three roots answered, searched in order: rebuilt/ (the revival's own
modules), mirror/ (files of the release date or older) and supplement/
(later uploads, used where nothing older survives). game/ holds the archived
files of the last two in one tree, with the same names
(www.9aola.com/<path>%3F<version>), so a static host can serve them.

  select    from the working roots: every file of the era roots, and of the
            later roots only what the 2013 client can ask for (listed in the
            2013-01-25 manifest or the config, the files it asks for by id
            within the 2013 ranges, files seen served in test runs, and
            explicit extras). A file a higher root already answers for is
            left out, as the old lookup would never reach it.
  assemble  rebuild the same game/ elsewhere from FILES.jsonl, taking each
            file from a local copy of the archive or from other folders and
            checking its SHA-1; nothing is downloaded.

    tools/make_game_root.py select --era mirror --later supplement \\
        --manifest tools/data/manifest-2013-01-25.xml \\
        --config rebuild/static/www.9aola.com/config.xml%3F201301241 \\
        --pmdata rebuild/static/www.9aola.com/revival/pmdata.json \\
        --served tools/data/game-served.txt --keep tools/data/game-keep.txt \\
        --drop tools/data/game-drop.txt --archive aola_archive_2013 --out game
    tools/make_game_root.py assemble --files game/FILES.jsonl --archive aola_archive_2013 \\
        --search old-release/mirror,old-release/supplement --out game

FILES.jsonl, one line per file: path (inside game/), size, sha1, origin
("era" uploaded on or before the release date, "later" uploaded after it,
"capture" not in the CDN archive: Wayback captures and guide pages), lm (the
CDN upload date, for archived files) and src (the file's path in the archive).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import xml.etree.ElementTree as ET

WWW = "www.9aola.com"
RELEASE = "2013-01-25T23:59:59Z"
# Folders whose files the client asks for by number (NPC 11, task 135, 亚比 4 …).
ID_FAMILIES = {"tasknpc", "taskpanel", "taskres", "taskext", "furniture", "peticon", "skin", "skinicon", "pet", "fightassets"}


def plain(rel: str) -> str:
    return re.sub(r"%3F.*$", "", rel)


def sha1_of(path: str) -> str:
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def walk(root: str):
    for d, _, names in os.walk(root):
        for n in sorted(names):
            full = os.path.join(d, n)
            yield os.path.relpath(full, root).replace(os.sep, "/"), full


def archive_index(archive: str | None) -> dict[str, dict]:
    """sha1 -> record (path, lm, later) over index.jsonl and _later/index.jsonl."""
    out: dict[str, dict] = {}
    if not archive:
        return out
    for sub, later in (("index.jsonl", False), (os.path.join("_later", "index.jsonl"), True)):
        p = os.path.join(archive, sub)
        if not os.path.exists(p):
            continue
        last = {}
        with open(p, encoding="utf-8") as f:
            for line in f:
                r = json.loads(line)
                last[r["path"]] = r
        for r in last.values():
            if r.get("ok") and r.get("sha1"):
                out.setdefault(r["sha1"], {"path": r["path"], "lm": r.get("lm"), "later": later})
    return out


def numbered(name: str):
    m = re.match(r"([a-z_]*?)(\d+)", name)
    return (m.group(1), int(m.group(2))) if m else None


def select(a) -> None:
    manifest = {f.get("n") for f in ET.parse(a.manifest).getroot().iter("f")}
    config = open(a.config, encoding="utf-8").read() if a.config else ""
    served = set()
    for s in a.served or []:
        served |= {l.strip() for l in open(s, encoding="utf-8") if l.strip()}
    pm = json.load(open(a.pmdata, encoding="utf-8")) if a.pmdata else {"species": {}, "skills": {}}
    races = {int(k) for k in pm["species"]}
    skills = {int(k) for k in pm["skills"]}
    keep_extra = set()
    for k in a.keep or []:
        keep_extra |= {l.strip() for l in open(k, encoding="utf-8") if l.strip() and not l.startswith("#")}
    drop = set()
    for k in a.drop or []:
        drop |= {l.strip() for l in open(k, encoding="utf-8") if l.strip() and not l.startswith("#")}
    era_roots = [r for r in a.era.split(",") if r]
    later_roots = [r for r in (a.later or "").split(",") if r]

    # The highest numbers of each numbered family among the era files: later
    # uploads above them belong to tasks, NPCs and furniture of 2013 or after.
    era_max: dict[tuple[str, str], int] = {}
    for root in era_roots:
        for rel, _ in walk(os.path.join(root, WWW)):
            top, _, rest = rel.partition("/")
            n = numbered(os.path.basename(rest))
            if top in ID_FAMILIES and n:
                key = (top, n[0])
                era_max[key] = max(era_max.get(key, -1), n[1])

    def wanted_later(rel: str) -> str | None:
        host, _, path = plain(rel).partition("/")
        if host != WWW:
            return "host"
        stem = re.sub(r"\.swf$", "", path)
        top = path.split("/")[0]
        if rel in keep_extra or plain(rel) in keep_extra:
            return "extra"
        if stem in manifest:
            return "manifest"
        if stem and stem in config:
            return "config"
        if any(s.endswith("/" + rel) for s in served):
            return "served"
        n = numbered(os.path.basename(path))
        if top == "fightassets" and n:
            if (n[0] == "pet" and n[1] in races) or (n[0] == "effect" and n[1] in skills):
                return "id"
            return None
        if top in ID_FAMILIES and n and n[1] <= era_max.get((top, n[0]), -1):
            return "id"
        return None

    index = archive_index(a.archive)
    have_plain: set[str] = set()
    have_exact: set[str] = set()
    out_lines = []
    os.makedirs(a.out, exist_ok=True)
    stats: dict[str, list[int]] = {}
    for root in a.shadow or []:
        for rel, _ in walk(root):
            have_exact.add(rel)
            if "%3F" not in rel:
                have_plain.add(rel)
    for root in era_roots + later_roots:
        era = root in era_roots
        for rel, full in walk(root):
            if rel in ("FILES.jsonl", "README.md") or rel in drop:
                continue
            p = plain(rel)
            if p in have_plain or rel in have_exact:
                continue
            why = "era" if era else wanted_later(rel)
            if not why:
                continue
            dest = os.path.join(a.out, *rel.split("/"))
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            if not a.dry_run:
                shutil.copyfile(full, dest)
            have_exact.add(rel)
            if "%3F" not in rel:
                have_plain.add(p)
            size = os.path.getsize(full)
            digest = sha1_of(full)
            rec = index.get(digest)
            line = {"path": rel, "size": size, "sha1": digest}
            if rec:
                line["origin"] = "later" if rec["later"] or (rec["lm"] or "") > RELEASE else "era"
                line["lm"] = rec["lm"]
                line["src"] = rec["path"]
            else:
                line["origin"] = "capture"
            out_lines.append(line)
            s = stats.setdefault(f"{os.path.basename(root.rstrip('/'))}:{why}", [0, 0])
            s[0] += 1
            s[1] += size
    with open(os.path.join(a.out, "FILES.jsonl"), "w", encoding="utf-8") as f:
        for line in sorted(out_lines, key=lambda l: l["path"]):
            f.write(json.dumps(line, ensure_ascii=False) + "\n")
    total = sum(l["size"] for l in out_lines)
    for k, (n, b) in sorted(stats.items()):
        print(f"{n:6d} files {b / 1e6:8.1f} MB  {k}")
    print(f"{len(out_lines):6d} files {total / 1e6:8.1f} MB  in {a.out}")


def assemble(a) -> None:
    files = [json.loads(l) for l in open(a.files, encoding="utf-8")]
    archive = a.archive
    search = [r for r in (a.search or "").split(",") if r]
    by_sha: dict[str, str] | None = None

    def scan() -> dict[str, str]:
        m: dict[str, str] = {}
        for root in search:
            for _, full in walk(root):
                try:
                    m.setdefault(sha1_of(full), full)
                except OSError:
                    pass
        return m

    missing = []
    done = 0
    import time
    stop = time.time() + a.max_seconds if a.max_seconds else None
    for i, e in enumerate(files):
        if stop and time.time() > stop:
            print(f"stopped after {a.max_seconds} s: {done} of {len(files)} in place; run again to go on")
            sys.exit(2)
        dest = os.path.join(a.out, *e["path"].split("/"))
        if os.path.exists(dest) and os.path.getsize(dest) == e["size"] and (not a.verify or sha1_of(dest) == e["sha1"]):
            done += 1
            continue
        cands = []
        if archive and e.get("src"):
            sub = "_later" if e.get("origin") == "later" else ""
            for s in (sub, "_later", ""):
                cands.append(os.path.join(archive, s, "aola.100bt.com", "play", *e["src"].split("/")))
        for root in search:
            cands.append(os.path.join(root, *e["path"].split("/")))
            cands.append(os.path.join(root, *plain(e["path"]).split("/")))
        src = next((c for c in cands if os.path.isfile(c) and os.path.getsize(c) == e["size"] and sha1_of(c) == e["sha1"]), None)
        if src is None:
            if by_sha is None:
                print("looking through the search folders by content …", file=sys.stderr)
                by_sha = scan()
            src = by_sha.get(e["sha1"])
        if src is None:
            missing.append(e)
            continue
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copyfile(src, dest)
        done += 1
    shutil.copyfile(a.files, os.path.join(a.out, "FILES.jsonl")) if os.path.abspath(a.files) != os.path.abspath(os.path.join(a.out, "FILES.jsonl")) else None
    print(f"{done} of {len(files)} files in place in {a.out}")
    if missing:
        with open(os.path.join(a.out, "..", "game-missing.txt"), "w", encoding="utf-8") as f:
            for e in missing:
                f.write(e["path"] + "\n")
        print(f"{len(missing)} missing, listed in game-missing.txt", file=sys.stderr)
        sys.exit(1)


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("select")
    s.add_argument("--era", required=True, help="roots of files from the release date or older (all kept), comma separated")
    s.add_argument("--later", help="roots of later uploads (only what the 2013 client asks for), comma separated")
    s.add_argument("--shadow", action="append", help="a root searched before these (rebuilt/): files it answers for are left out")
    s.add_argument("--manifest", required=True)
    s.add_argument("--config")
    s.add_argument("--pmdata")
    s.add_argument("--served", action="append", help="file of root/relpath lines served in test runs")
    s.add_argument("--keep", action="append", help="file of relpaths to keep in any case")
    s.add_argument("--drop", action="append", help="file of relpaths to leave out in any case")
    s.add_argument("--archive", help="the CDN archive, to date each file by its SHA-1")
    s.add_argument("--out", required=True)
    s.add_argument("--dry-run", action="store_true")
    s = sub.add_parser("assemble")
    s.add_argument("--files", required=True)
    s.add_argument("--archive")
    s.add_argument("--search", help="folders holding files at their game/ paths (an older release's mirror, supplement …)")
    s.add_argument("--out", required=True)
    s.add_argument("--verify", action="store_true", help="check the SHA-1 of files already in place too (else their size)")
    s.add_argument("--max-seconds", type=int, default=0, help="stop after this long (exit 2); a new run goes on")
    a = ap.parse_args(argv)
    (select if a.cmd == "select" else assemble)(a)


if __name__ == "__main__":
    main()
