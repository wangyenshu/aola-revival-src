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
  * the NPC pictures (tasknpc/npc<id>) of the NPCs that talk in them;
  * resources the scripts name ("taskres/…", "taskpanel/…") that the live
    CDN has.

With --fetch it downloads them from http://aola.100bt.com/play/ into game/
(names as the 2013 client asks for them: <path>%3F1210 for SWFs), appends
them to game/FILES.jsonl (origin "later", the CDN upload date), and adds the
room rows to the config overlay. Building never downloads anything; this is
for curating game/.

  tools/story_files.py --game game --ffdec .toolchain/ffdec/ffdec.jar --config tools/data/live-config.swf \\
      --work <gen_tasks work dir> --live-config <live config.xml> --live-head <live inventory head.jsonl> \\
      --overlay rebuild/static/www.9aola.com/config.xml%3F201301241 [--fetch]

then tools/gen_tasks.py and tools/gen_npc_data.py again.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_tasks  # noqa: E402

WWW = "www.9aola.com"
CDN = "http://aola.100bt.com/play/"
UA = {"User-Agent": "Mozilla/5.0 aola-revival story files"}


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
    a = ap.parse_args(argv)

    t = gen_tasks.load_tables(a.ffdec, a.game, a.config, a.work)
    chosen = gen_tasks.choose(t, a.game, allow_later=True, require_scripts=False)
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

    want: dict[str, str] = {}

    def need(path: str, why: str) -> None:
        if path in have or path in want:
            return
        if path in head:
            want[path] = why

    ids = set()
    for task in chosen:
        ids |= {task, *gen_tasks.steps_of(t, task)}
    scripts = sorted({e["file"] for task in chosen for e in t["entries_of"].get(task, [])})
    for f in scripts:
        need(f + ".swf", "script")
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
            need(res + ".swf", "named by a script")
    new_rooms = sorted(r for r in rooms if r not in rooms_2013 and r in live_rooms)
    for r in new_rooms:
        m = re.search(r'swf="([^"]+)"', live_rooms[r])
        if m:
            need(m.group(1) + ".swf", "scene " + r)
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
        req = urllib.request.Request(CDN + p, headers=UA)
        with urllib.request.urlopen(req, timeout=60) as r:
            data = r.read()
        if len(data) != head[p]["size"]:
            print(f"  {p}: size {len(data)} is not the inventory's {head[p]['size']}; the operator has replaced it since", file=sys.stderr)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        open(dest, "wb").write(data)
        lines.append({"path": f"{WWW}/{name}", "size": len(data), "sha1": hashlib.sha1(data).hexdigest(), "origin": "later",
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
        overlay = overlay.replace(marker, note + rows + marker, 1)
        open(a.overlay, "w", encoding="utf-8").write(overlay)
    print(f"added {len(lines)} files and {len(new_rooms)} rooms")


if __name__ == "__main__":
    main()
