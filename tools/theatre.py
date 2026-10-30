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
which a page cannot play: this downloads them into game/ (their original
URLs; FILES.jsonl with the CDN upload date) and converts each to MP4 and
WebM next to the revival's other data (game/www.9aola.com/revival/theatre/,
origin "derived", with a frame of each for the list), and writes the list
web/theatre.js shows
(rebuild/static/www.9aola.com/revival/theatre.json).

  tools/theatre.py --game game [--ffmpeg ffmpeg]

Building never runs this (it downloads); the build only copies what it made.
"""
from __future__ import annotations

import argparse
import email.utils
import hashlib
import json
import os
import subprocess
import urllib.request

UA = {"User-Agent": "Mozilla/5.0 aola-revival theatre"}
ERA_END = "2013-01-26"
STATIC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "rebuild", "static", "www.9aola.com", "revival", "theatre.json")

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
    ap.add_argument("--ffmpeg", default="ffmpeg")
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
        mp4_rel = f"www.9aola.com/revival/theatre/{fid}.mp4"
        mp4 = os.path.join(a.game, *mp4_rel.split("/"))
        if mp4_rel not in known:
            os.makedirs(os.path.dirname(mp4), exist_ok=True)
            subprocess.run([a.ffmpeg, "-v", "error", "-y", "-i", dest, "-map", "0:v:0", "-map", "0:a:0?",
                            "-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p",
                            "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", mp4], check=True)
            data = open(mp4, "rb").read()
            known[mp4_rel] = {"path": mp4_rel, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": "derived",
                              "from": rel, "added": "百田大剧场: " + title + " (FLV converted to MP4 for the page)"}
            print(f"  {mp4_rel}: {len(data)} bytes")
        # WebM too: browsers without H.264 (Chromium builds, some Linux browsers) play it.
        webm_rel = f"www.9aola.com/revival/theatre/{fid}.webm"
        webm = os.path.join(a.game, *webm_rel.split("/"))
        if webm_rel not in known:
            subprocess.run([a.ffmpeg, "-v", "error", "-y", "-i", dest, "-map", "0:v:0", "-map", "0:a:0?",
                            "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "34", "-deadline", "realtime", "-cpu-used", "8", "-row-mt", "1",
                            "-c:a", "libopus", "-b:a", "80k", webm], check=True)
            data = open(webm, "rb").read()
            known[webm_rel] = {"path": webm_rel, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": "derived",
                               "from": rel, "added": "百田大剧场: " + title + " (FLV converted to WebM for the page)"}
            print(f"  {webm_rel}: {len(data)} bytes")
        poster_rel = f"www.9aola.com/revival/theatre/{fid}.jpg"
        poster = os.path.join(a.game, *poster_rel.split("/"))
        if poster_rel not in known:
            subprocess.run([a.ffmpeg, "-v", "error", "-y", "-ss", "12", "-i", dest, "-frames:v", "1", "-vf", "scale=240:-2", "-q:v", "4", poster], check=True)
            data = open(poster, "rb").read()
            known[poster_rel] = {"path": poster_rel, "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": "derived",
                                 "from": rel, "added": "百田大剧场: " + title + " (a frame of the film, for the list)"}
        src = known[rel]
        films.append({"id": fid, "title": title, "url": url, "mp4": "http://" + mp4_rel, "webm": "http://" + webm_rel, "poster": "http://" + poster_rel,
                      "uploaded": src.get("lm", "")[:10], "origin": src.get("origin"), "where": where})
    with open(files, "w", encoding="utf-8") as f:
        for r in sorted(known.values(), key=lambda r: r["path"]):
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    os.makedirs(os.path.dirname(STATIC), exist_ok=True)
    with open(STATIC, "w", encoding="utf-8") as f:
        json.dump({"films": films}, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"{len(films)} films in {os.path.relpath(STATIC)}")


if __name__ == "__main__":
    main()
