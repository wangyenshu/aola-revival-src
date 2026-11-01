#!/usr/bin/env python3
"""Keep the list of where every file of game/ can be downloaded again.

game/ holds 百田's files. To publish the code without them, a checkout needs a
way to get them back: tools/data/game-sources.jsonl lists every file of
game/FILES.jsonl with the URLs it can be downloaded from, and how the few
files made here are made again. tools/fetch_game.py reads it.

Each line is the file's FILES.jsonl entry (path, size, sha1, origin, lm, src,
added, from) plus:

  urls     URLs to try in order: the live CDN (http://aola.100bt.com/play/…),
           a Wayback Machine capture in its raw form (https://web.archive.org/
           web/<timestamp>id_/<original URL>), or another 百田 host
  derive   for files made here (origin "derived"): {"tool": "ffmpeg", "from":
           <path of the source file>, "args": [...]} where the args are those
           tools/theatre.py used, with {in} and {out} for the two files
  note     why the file may not download as listed (its CDN copy was replaced
           and the revival does not need it); tools/fetch_game.py then warns
           instead of failing

Where a file's URL comes from:

  era, later   FILES.jsonl's src: a path under http://aola.100bt.com/play/,
               or a full URL
  capture      src when it is a Wayback URL; else a capture in a Wayback CDX
               scan whose digest (the base32 SHA-1 of the content) matches;
               else the live CDN URL of a fetch log (tools/wayback.py
               fill-live and fill-manifest write {"relpath", "original"});
               else --extra-url
  any          the list given with --previous, for a file whose SHA-1 is
               unchanged (so URLs found once are kept)

  build   write the list from game/FILES.jsonl and the sources above
  check   every file of FILES.jsonl is in the list with the same SHA-1 and a
          way to get it (run it after adding files to game/)

  tools/game_sources.py build --files game/FILES.jsonl \\
      --previous tools/data/game-sources.jsonl \\
      [--cdx work/cdx.jsonl …] [--fetch-log work/index.jsonl …] \\
      [--extra-url www.9aola.com/map/mapguide2012.swf=http://…] \\
      --out tools/data/game-sources.jsonl
  tools/game_sources.py check --files game/FILES.jsonl --sources tools/data/game-sources.jsonl

Standard library only.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mirrorpath import url_to_relpath  # noqa: E402
DEFAULT_SOURCES = os.path.join(HERE, "data", "game-sources.jsonl")
CDN = "http://aola.100bt.com/play/"

# The conversions tools/theatre.py made of the theatre films (FLV, VP6 and MP3),
# by the extension of the file made. {in} and {out} are the two paths.
DERIVE = {
    ".mp4": ["-v", "error", "-y", "-i", "{in}", "-map", "0:v:0", "-map", "0:a:0?",
             "-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p",
             "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", "{out}"],
    ".webm": ["-v", "error", "-y", "-i", "{in}", "-map", "0:v:0", "-map", "0:a:0?",
              "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "34", "-deadline", "realtime", "-cpu-used", "8", "-row-mt", "1",
              "-c:a", "libopus", "-b:a", "80k", "{out}"],
    ".jpg": ["-v", "error", "-y", "-ss", "12", "-i", "{in}", "-frames:v", "1", "-vf", "scale=240:-2", "-q:v", "4", "{out}"],
}

WAYBACK_RE = re.compile(r"^https?://web\.archive\.org/web/(\d+)(?:[a-z]{2}_)?/(.+)$")


def read_jsonl(path: str) -> list[dict]:
    out = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    out.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    return out


def raw_wayback(url: str) -> str:
    """A Wayback Machine URL in its raw form (id_: the bytes as captured, no toolbar)."""
    m = WAYBACK_RE.match(url)
    return f"https://web.archive.org/web/{m.group(1)}id_/{m.group(2)}" if m else url


def b32(sha1_hex: str) -> str:
    return base64.b32encode(bytes.fromhex(sha1_hex)).decode()


def url_of_src(src: str) -> str:
    if "://" in src:
        return raw_wayback(src) if "web.archive.org" in src else src
    return CDN + src


def build(a: argparse.Namespace) -> int:
    files = read_jsonl(a.files)
    previous = {r["path"]: r for r in read_jsonl(a.previous)} if a.previous and os.path.exists(a.previous) else {}
    by_digest: dict[str, str] = {}
    for cdx in a.cdx or []:
        for r in read_jsonl(cdx):
            d, ts, orig = r.get("digest"), r.get("ts") or r.get("timestamp"), r.get("original")
            if d and ts and orig and str(r.get("status", "200")) == "200":
                by_digest.setdefault(d, f"https://web.archive.org/web/{ts}id_/{orig}")
    by_relpath: dict[str, str] = {}
    for log in a.fetch_log or []:
        for r in read_jsonl(log):
            orig = r.get("original") or r.get("src")
            rel = r.get("relpath") or (url_to_relpath(r["url"]) if r.get("url") else None)
            if rel and orig and "://" in orig:
                by_relpath.setdefault(rel, orig)
    extra = {}
    for e in a.extra_url or []:
        path, _, url = e.partition("=")
        extra[path] = url
    notes = {}
    for e in a.note or []:
        path, _, text = e.partition("=")
        notes[path] = text
    out, unresolved = [], []
    for f in files:
        row = dict(f)
        prev = previous.get(f["path"])
        if prev and prev.get("sha1") == f["sha1"] and (prev.get("urls") or prev.get("derive")):
            if prev.get("urls"):
                row["urls"] = prev["urls"]
            if prev.get("derive"):
                row["derive"] = prev["derive"]
        elif f.get("origin") == "derived":
            ext = os.path.splitext(f["path"])[1]
            if f.get("from") and ext in DERIVE:
                row["derive"] = {"tool": "ffmpeg", "from": f["from"], "args": DERIVE[ext]}
        else:
            urls = []
            if f.get("src"):
                urls.append(url_of_src(f["src"]))
            if f.get("origin") == "capture" and not urls:
                for u in (by_digest.get(b32(f["sha1"])), by_relpath.get(f["path"])):
                    if u and u not in urls:
                        urls.append(u)
            if f["path"] in extra and extra[f["path"]] not in urls:
                urls.append(extra[f["path"]])
            if urls:
                row["urls"] = urls
        if f["path"] in notes:
            row["note"] = notes[f["path"]]
        elif prev and prev.get("sha1") == f["sha1"] and prev.get("note"):
            row["note"] = prev["note"]
        if not row.get("urls") and not row.get("derive"):
            unresolved.append(f["path"])
        out.append(row)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    tmp = a.out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        for r in sorted(out, key=lambda r: r["path"]):
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")
    os.replace(tmp, a.out)
    kinds: dict[str, int] = {}
    for r in out:
        k = "derive" if r.get("derive") else (r["urls"][0].split("/")[2] if r.get("urls") else "none")
        kinds[k] = kinds.get(k, 0) + 1
    print(f"{len(out)} files -> {a.out}")
    for k, n in sorted(kinds.items(), key=lambda kv: -kv[1]):
        print(f"  {n:6}  {k}")
    if unresolved:
        print(f"{len(unresolved)} files with no known source:", file=sys.stderr)
        for p in unresolved:
            print("  " + p, file=sys.stderr)
        return 0 if a.allow_missing else 1
    return 0


def check(a: argparse.Namespace) -> int:
    files = read_jsonl(a.files)
    sources = {r["path"]: r for r in read_jsonl(a.sources)}
    bad = []
    for f in files:
        s = sources.get(f["path"])
        if s is None:
            bad.append(f"not listed: {f['path']}")
        elif s.get("sha1") != f["sha1"]:
            bad.append(f"other SHA-1: {f['path']}")
        elif not s.get("urls") and not s.get("derive"):
            bad.append(f"no source: {f['path']}")
    gone = set(sources) - {f["path"] for f in files}
    bad += [f"listed but not in FILES.jsonl: {p}" for p in sorted(gone)]
    for b in bad:
        print(b)
    print(f"{len(files)} files checked, {len(bad)} problems")
    return 1 if bad else 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build", help="write the list")
    b.add_argument("--files", default=os.path.join(HERE, "..", "game", "FILES.jsonl"))
    b.add_argument("--previous", default=DEFAULT_SOURCES, help="an earlier list whose URLs are kept")
    b.add_argument("--cdx", action="append", help="Wayback CDX scan (tools/wayback.py scan)")
    b.add_argument("--fetch-log", action="append", help="a fetch index with relpath and original (tools/wayback.py)")
    b.add_argument("--extra-url", action="append", help="path=url for a file no other source names")
    b.add_argument("--note", action="append", help="path=text: why a file may fail to download as listed (tools/fetch_game.py then only warns)")
    b.add_argument("--allow-missing", action="store_true", help="write the list even if some files have no source")
    b.add_argument("--out", default=DEFAULT_SOURCES)
    c = sub.add_parser("check", help="check the list against FILES.jsonl")
    c.add_argument("--files", default=os.path.join(HERE, "..", "game", "FILES.jsonl"))
    c.add_argument("--sources", default=DEFAULT_SOURCES)
    a = ap.parse_args(argv)
    return build(a) if a.cmd == "build" else check(a)


if __name__ == "__main__":
    sys.exit(main())
