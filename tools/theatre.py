#!/usr/bin/env python3
"""The films of the 百田大剧场 (scene/theatre), for game/.

In January 2013 the theatre scene, and two links of the client, opened pages
of 百田's video site in an overlay (js/aola.js: showVideoPlayer ->
v.100bt.com/video/gamevdo/aola/list.html, showAnniversaryVideo ->
v.100bt.com/video/aola/37591.html, showWarTeamVideo ->
aola.100bt.com/gwActivity/20121227/play.html). v.100bt.com is gone. The list
page (Wayback capture of April 2013) was mostly cartoons of other studios,
streamed from other sites, which are not kept here. What survives of
奥拉星's own films is on the game's CDN as Flash video (FLV, VP6 and MP3),
which the game plays itself (control/TheatrePanel): this downloads them into
game/ (their original URLs; FILES.jsonl with the CDN upload date) and writes
the list the panel reads (rebuild/static/www.9aola.com/revival/theatre.xml).

  tools/theatre.py --game game

Building never runs this (it downloads); the build only copies what it made.
"""
from __future__ import annotations

import argparse
import email.utils
import hashlib
import json
import os
import urllib.request
import xml.etree.ElementTree as ET

UA = {"User-Agent": "Mozilla/5.0 aola-revival theatre"}
ERA_END = "2013-01-26"
STATIC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "rebuild", "static", "www.9aola.com", "revival", "theatre.xml")

# id, title, original URL, where the client or the video site named it.
FILMS = [
    ("anniversary2", "奥拉星2周年", "http://aola.100bt.com/shipin/img/1343327424744_.flv",
     "js/aola.js showAnniversaryVideo; v.100bt.com/video/aola/37591.html (Wayback, 15 Oct 2012)"),
    ("warteam", "奥拉星战队", "http://aola.100bt.com/gwActivity/20121227/aola.flv",
     "js/aola.js showWarTeamVideo (aola.100bt.com/gwActivity/20121227/play.html)"),
]


def game_path(url: str) -> str:
    return url.split("://", 1)[1]


def fetch(url: str) -> tuple[bytes, str]:
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=300) as r:
        lm = r.headers.get("Last-Modified")
        data = r.read()
    when = email.utils.parsedate_to_datetime(lm).strftime("%Y-%m-%dT%H:%M:%SZ") if lm else ""
    return data, when


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True)
    a = ap.parse_args(argv)
    files = os.path.join(a.game, "FILES.jsonl")
    rows = [json.loads(l) for l in open(files, encoding="utf-8")]
    known = {r["path"]: r for r in rows}
    films = []
    for fid, title, url, where in FILMS:
        rel = game_path(url)
        dest = os.path.join(a.game, *rel.split("/"))
        if rel not in known:
            data, lm = fetch(url)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with open(dest, "wb") as f:
                f.write(data)
            origin = "era" if lm and lm < ERA_END else "later"
            known[rel] = {"path": rel, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": origin,
                          "lm": lm, "src": url, "added": "百田大剧场: " + title}
            print(f"  {url}: {len(data)} bytes, uploaded {lm[:10]} ({origin})")
        src = known[rel]
        films.append({"id": fid, "title": title, "url": url, "uploaded": src.get("lm", "")[:10], "origin": src.get("origin"), "where": where})
    with open(files, "w", encoding="utf-8") as f:
        for r in sorted(known.values(), key=lambda r: r["path"]):
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    os.makedirs(os.path.dirname(STATIC), exist_ok=True)
    root = ET.Element("films")
    for film in films:
        ET.SubElement(root, "film", {k: str(v) for k, v in film.items()})
    ET.indent(root, " ")
    with open(STATIC, "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n')
        f.write("<!-- The films of the 百田大剧场 (tools/theatre.py): the game's own FLVs, played by control/TheatrePanel. -->\n")
        f.write(ET.tostring(root, encoding="unicode") + "\n")
    print(f"{len(films)} films in {os.path.relpath(STATIC)}")


if __name__ == "__main__":
    main()
