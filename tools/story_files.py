#!/usr/bin/env python3
"""Find (and add to game/) the files the 2012 story quests need.

The 2012 story quests (巨人山脉, 幽暗冥州, 钻石岛 …, the tasks the later client
still defines with their NPC conversations) were taken off the map by late
2012, so the January 2013 client names neither their scenes nor most of
their scripts, and the CDN archive (docs/ARCHIVE.md) does not hold them.
The live CDN still serves them, as later uploads of the same quests (the
scripts and scenes were re-exported between 2015 and 2019). This lists, for
the quests tools/gen_tasks.py would take (see there), the files missing from
game/:

  * the task scripts the later scene table (config tconfig) names;
  * the scenes of the rooms they use that the 2013 config.xml does not have
    (with the room rows of the live config.xml, to add to the overlay);
  * their music (music/<name>.mp3, the rooms' mu);
  * the NPC pictures (tasknpc/npc<id>) of the NPCs that talk in them;
  * resources the scripts name ("taskres/…", "taskpanel/…") that the live
    CDN has.

With --fetch it downloads them from http://aola.100bt.com/play/ into game/
(names as the 2013 client asks for them: <path>%3F1210 for SWFs), appends
them to game/FILES.jsonl (origin "era" when the CDN's upload date is by 25
January 2013, "later" otherwise), and adds the
room rows to the config overlay. Building never downloads anything; this is
for curating game/.

  tools/story_files.py --game game --ffdec .toolchain/ffdec/ffdec.jar --config tools/data/live-config.swf \\
      --work <gen_tasks work dir> --live-config <live config.xml> --live-head <live inventory head.jsonl> \\
      --overlay rebuild/static/www.9aola.com/config.xml%3F201301241 [--fetch]

then tools/gen_tasks.py and tools/gen_npc_data.py again. The quests whose
scripts survive only as later uploads keep their conversations in the
scripts, so for them run it with --scripts-only --fetch first (the scripts
of every quest of the era), then without.
"""
from __future__ import annotations

import argparse
import email.utils
import hashlib
import http.client
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_tasks  # noqa: E402

WWW = "www.9aola.com"
CDN = "http://aola.100bt.com/play/"
UA = {"User-Agent": "Mozilla/5.0 aola-revival story files"}


def need_the_rest(a, t, chosen, ids, scripts, have, live_rooms, rooms_2013, added_rooms, need) -> list[str]:
    """Rooms, music, NPC pictures and resources of the quests; returns the rooms to add."""
    rooms = set()
    for task in chosen:
        for e in t["entries_of"].get(task, []):
            rooms.add(e["scene"])
    for k in list(t["talk"]) + list(t["start"]):
        npc, step, label = k.split("_", 2)
        if int(step) in ids and label in live_rooms:
            rooms.add(label)
    for i in ids:
        sc = t["panels"].get(i, {}).get("sc")
        if sc:
            rooms.add(sc)
    # Scripts send the player to rooms too (loadScene, showTransportPanel).
    texts = {}
    for f in scripts:
        local = gen_tasks.game_file(a.game, f + ".swf")
        if local is None:
            continue
        out = os.path.join(a.work, "scripts", os.path.basename(f))
        if not os.path.isdir(out):
            gen_tasks.decompile(a.ffdec, local, out)
        body = ""
        for d, _, ns in os.walk(out):
            for n in ns:
                if n.endswith(".as"):
                    body += open(os.path.join(d, n), encoding="utf-8", errors="replace").read()
        texts[f] = body
    for body in texts.values():
        for name in re.findall(r'"([a-z][a-z0-9_]*)"', body):
            if name in live_rooms:
                rooms.add(name)
        for res in re.findall(r'"((?:taskres|taskpanel|tasknpc|comic|movie|petfightbackground)/[A-Za-z0-9_/]+)"', body):
            need(res + ".swf", "named by a script", probe=True)
        # Names put together: "taskres/taskres2072" + map[cls], with "01", "02" … in the map.
        for res in re.findall(r'"((?:taskres|comic|movie)/[A-Za-z0-9_/]+)"\s*\+', body):
            for style in ("%02d", "_%d", "%d"):
                for n in range(1, 20):
                    if not need(res + style % n + ".swf", "named by a script", probe=True):
                        break
    new_rooms = sorted(r for r in rooms if r not in rooms_2013 and r in live_rooms)
    for r in new_rooms:
        m = re.search(r'swf="([^"]+)"', live_rooms[r])
        if m:
            need(m.group(1) + ".swf", "scene " + r)
    # The music of the added rooms (mu: one file or several), as the live config.xml gives it.
    for r in sorted(r for r in rooms if r not in rooms_2013 or r in added_rooms):
        m = re.search(r'\bmu="([^"]+)"', live_rooms.get(r, ""))
        for f in (m.group(1).split(",") if m else []):
            need(f.strip(), "music of " + r)
    for task in chosen:
        need(f"taskpanel/tp{task}.swf", "task panel")
        fn = t["panels"].get(task, {}).get("fn")
        if fn:
            need(fn + ".swf", "task panel")
    npcs = set()
    for k in list(t["talk"]) + list(t["start"]):
        npc, step, label = k.split("_", 2)
        if int(step) in ids:
            npcs.add(int(npc))
    for body in texts.values():
        for m in re.finditer(r"addNpcToScene\((\d+)", body):
            npcs.add(int(m.group(1)))
    for n in sorted(npcs):
        if n > 1:
            need(f"tasknpc/npc{n}.swf", "NPC")

    return new_rooms


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True)
    ap.add_argument("--work", required=True, help="the decompiled later sources (gen_tasks.py --work)")
    ap.add_argument("--ffdec", required=True)
    ap.add_argument("--config", required=True, help="the later config/config.swf (tconfig)")
    ap.add_argument("--live-config", required=True)
    ap.add_argument("--live-head", required=True)
    ap.add_argument("--overlay", required=True)
    ap.add_argument("--fetch", action="store_true")
    ap.add_argument("--probe", action="store_true", help="ask the CDN (HEAD) for files scripts name that the inventory lacks")
    ap.add_argument("--scripts-only", action="store_true",
                    help="only the scripts of every quest of the era, whether or not its conversations are known yet: "
                         "the later uploads carry them (run first, then again without this)")
    a = ap.parse_args(argv)

    t = gen_tasks.load_tables(a.ffdec, a.game, a.config, a.work)
    chosen = gen_tasks.choose(t, a.game, allow_later=True, require_scripts=False, require_talk=not a.scripts_only)
    have = gen_tasks.game_paths(a.game)
    head = {}
    for line in open(a.live_head, encoding="utf-8"):
        r = json.loads(line)
        if r.get("status") == 200:
            head[r["path"]] = r
    live_cfg = open(a.live_config, encoding="utf-8").read()
    live_rooms = {m.group(1): m.group(0) for m in re.finditer(r'<r [^>]*?nm="([^"]+)"[^>]*/>', live_cfg)}
    overlay = open(a.overlay, encoding="utf-8").read()
    rooms_2013 = set(re.findall(r'<r [^>]*nm="([^"]+)"', overlay))
    # Rooms an earlier run added to the overlay (after its note, up to </roomMap>).
    note = overlay.find("2012 story quests (tools/story_files.py)")
    added_rooms = set(re.findall(r'<r [^>]*nm="([^"]+)"', overlay[note:overlay.find("</roomMap>", note)])) if note >= 0 else set()

    want: dict[str, str] = {}

    # The live inventory was made from the names the clients give; files only
    # scripts name (taskres/…) may be missing from it: ask the CDN for those
    # (HEAD; the answers are kept in the work directory).
    probe_log = os.path.join(a.work, "story-probe-head.jsonl")
    probed = {}
    if os.path.isfile(probe_log):
        for line in open(probe_log, encoding="utf-8"):
            r = json.loads(line)
            probed[r["path"]] = r

    def probe_cdn(path: str) -> dict:
        if path not in probed:
            r = {"path": path, "status": 0}
            try:
                req = urllib.request.Request(CDN + path, headers=UA, method="HEAD")
                with urllib.request.urlopen(req, timeout=30) as resp:
                    lm = resp.headers.get("Last-Modified")
                    r = {"path": path, "status": resp.status, "size": int(resp.headers.get("Content-Length") or 0),
                         "lm": email.utils.parsedate_to_datetime(lm).strftime("%Y-%m-%dT%H:%M:%SZ") if lm else ""}
            except urllib.error.HTTPError as e:
                r["status"] = e.code
            except (urllib.error.URLError, OSError) as e:
                print(f"  {path}: {e}; not asked again until the next run", file=sys.stderr)
                return r
            probed[path] = r
            with open(probe_log, "a", encoding="utf-8") as f:
                f.write(json.dumps(r) + "\n")
        return probed[path]

    def need(path: str, why: str, probe: bool = False) -> bool:
        """Add the file when game/ lacks it and the CDN has it; whether it is there."""
        if path in have or path in want:
            return True
        if path not in head and probe and a.probe:
            r = probe_cdn(path)
            if r["status"] == 200 and r["size"] > 0:
                head[path] = r
        if path in head:
            want[path] = why
            return True
        return False

    ids = set()
    for task in chosen:
        ids |= {task, *gen_tasks.steps_of(t, task)}
    scripts = sorted({e["file"] for task in chosen for e in t["entries_of"].get(task, [])})
    for f in scripts:
        need(f + ".swf", "script")
    new_rooms = [] if a.scripts_only else need_the_rest(a, t, chosen, ids, scripts, have, live_rooms, rooms_2013, added_rooms, need)

    total = sum(head[p]["size"] for p in want)
    print(f"{len(chosen)} quests; {len(new_rooms)} rooms to add; {len(want)} files to add, {total / 1e6:.1f} MB")
    for p, why in sorted(want.items()):
        print(f"  {p}  ({why}, {head[p]['lm'][:10]}, {head[p]['size']} bytes)")
    print("rooms:", " ".join(new_rooms))
    if not a.fetch:
        return

    lines = []
    for p in sorted(want):
        stem, ext = os.path.splitext(p)
        name = p + ("%3F1210" if ext == ".swf" else "")
        dest = os.path.join(a.game, WWW, *name.split("/"))
        data = None
        for attempt in range(4):
            try:
                req = urllib.request.Request(CDN + p, headers=UA)
                with urllib.request.urlopen(req, timeout=60) as r:
                    data = r.read()
                break
            except (urllib.error.URLError, http.client.HTTPException, OSError) as e:
                # The CDN's front sometimes answers 503 or cuts a transfer short for a moment.
                if (isinstance(e, urllib.error.HTTPError) and e.code not in (502, 503, 504)) or attempt == 3:
                    raise
                time.sleep(3 * (attempt + 1))
        if len(data) != head[p]["size"]:
            print(f"  {p}: size {len(data)} is not the inventory's {head[p]['size']}; the operator has replaced it since", file=sys.stderr)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        open(dest, "wb").write(data)
        # Uploaded by 25 January 2013: a file of the era (as tools/add_later.py has it).
        origin = "era" if head[p]["lm"] < "2013-01-26" else "later"
        lines.append({"path": f"{WWW}/{name}", "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": origin,
                      "lm": head[p]["lm"], "src": p, "added": "story quests"})
    files = os.path.join(a.game, "FILES.jsonl")
    old = [json.loads(l) for l in open(files, encoding="utf-8")]
    known = {l["path"] for l in old}
    allrows = old + [l for l in lines if l["path"] not in known]
    with open(files, "w", encoding="utf-8") as f:
        for l in sorted(allrows, key=lambda l: l["path"]):
            f.write(json.dumps(l, ensure_ascii=False) + "\n")
    rows = "".join(f"      {live_rooms[r]}\n" for r in new_rooms)
    if rows:
        marker = "    </roomMap>"
        note = "      <!-- 2012 story quests (tools/story_files.py): rooms of the live config.xml -->\n"
        if "2012 story quests (tools/story_files.py)" in overlay:
            note = ""
        overlay = overlay.replace(marker, note + rows + marker, 1)
        open(a.overlay, "w", encoding="utf-8").write(overlay)
    print(f"added {len(lines)} files and {len(new_rooms)} rooms")


if __name__ == "__main__":
    main()
