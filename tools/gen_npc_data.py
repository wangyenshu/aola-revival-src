#!/usr/bin/env python3
"""Generate the data classes of the rebuilt task/tasknpc from the later module.

The January 2013 TaskNpcService is lost. The later one (task/tasknpc.swf on the
live CDN, decompiled with FFDEC) still carries the two tables the rebuild
needs. Both go to rebuild/gen/ (committed, so building needs no decompiler):

  SceneNpcData   which NPC stands where in each scene (SceneNpcConfig), kept
                 for the rooms of the config.xml overlay: in the rooms of the
                 2013 config.xml only NPCs whose artwork tasknpc/npc<id>.swf
                 is an era file in game/ (and, as task NPCs shown only while
                 they have something to say, those a 2012 story quest talks
                 to there: TaskTalkData of tools/gen_tasks.py), in the rooms
                 the overlay adds for the 2012 story quests
                 (tools/story_files.py) every NPC whose artwork game/ has
  FreeTalkData   the named conversations scenes open with
                 showNpcPanelFreely(name, npcId) (npcFreeTaskTalkConfig)

  tools/gen_npc_data.py --later <gen_tasks.py --work dir>/tasknpc/scripts --game game \\
      --overlay rebuild/static/www.9aola.com/config.xml%3F201301241 \\
      --talks rebuild/gen/tasknpc/mmo/tasknpc/TaskTalkData.as --out rebuild/gen/tasknpc \\
      --extra tools/data/scene-npcs-2012.json

--extra adds task NPCs the later table no longer places (the 幻龙星系 quests' NPCs whose
start talks name a room: 飞灵 776 in 魔法羽林 …), at RECONSTRUCTED spots (see its _doc).
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import xml.dom.minidom
import xml.etree.ElementTree as ET


def scene_npcs(later: str) -> dict:
    src = open(os.path.join(later, "mmo/tasknpc/config/SceneNpcConfig.as"), encoding="utf-8").read()
    cut = src.find("if(!ActDateUtils")
    if cut > 0:
        src = src[:cut]
    out = {}
    for m in re.finditer(r'config\["([^"]+)"\]\s*=\s*\[(.*?)\];', src, re.S):
        lst = []
        for o in re.finditer(r"\{(.*?)\}", m.group(2), re.S):
            d = {}
            for k, v in re.findall(r'"(\w+)":([^,\n}]+)', o.group(1)):
                v = v.strip()
                if v == "NpcType.SCENE":
                    v = 0
                elif v == "NpcType.TASK":
                    v = 2
                else:
                    try:
                        v = float(v) if "." in v else int(v)
                    except ValueError:
                        v = v.strip('"')
                d[k] = v
            lst.append(d)
        out[m.group(1)] = lst
    return out


def free_talks(later: str) -> dict:
    items = {}
    for f in glob.glob(os.path.join(later, "mmo/tasknpc/config/**/*.as"), recursive=True):
        s = open(f, encoding="utf-8").read()
        for m in re.finditer(r'npcFreeTaskTalkConfig\["([^"]+)"\]\s*=\s*(<config\b.*?</config>)\s*;', s, re.S):
            x = m.group(2)
            try:
                xml.dom.minidom.parseString(x.encode("utf-8"))
            except Exception:
                continue
            items[m.group(1)] = x
    return items


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--later", required=True)
    ap.add_argument("--game", required=True)
    ap.add_argument("--overlay", required=True, help="the config.xml overlay (rebuild/static)")
    ap.add_argument("--talks", help="TaskTalkData.as of tools/gen_tasks.py: <npc>_<step>_<scene> conversations")
    ap.add_argument("--out", required=True)
    ap.add_argument("--extra", help="tools/data/scene-npcs-2012.json: task NPCs placed by hand")
    a = ap.parse_args(argv)
    talks_in = set()
    if a.talks:
        for npc, label in re.findall(r'"(\d+)_\d+_([a-z][a-z0-9]*)', open(a.talks, encoding="utf-8").read()):
            talks_in.add((int(npc), label))
    cfg = "config.xml%3F201301241"
    rooms_of = lambda f: {r.get("nm") for r in ET.parse(f).getroot().find("roomMap").iter("r")}
    rooms_2013 = rooms_of(os.path.join(a.game, "www.9aola.com", cfg))
    rooms = rooms_of(a.overlay)
    era, art = set(), set()
    for line in open(os.path.join(a.game, "FILES.jsonl"), encoding="utf-8"):
        r = json.loads(line)
        m = re.match(r"www\.9aola\.com/tasknpc/npc(\d+)\.swf", r["path"])
        if m:
            art.add(int(m.group(1)))
            if r["origin"] != "later":
                era.add(int(m.group(1)))
    scenes = {}
    for sc, lst in scene_npcs(a.later).items():
        if sc not in rooms:
            continue
        if sc not in rooms_2013:
            keep = [d for d in lst if d.get("npcId") in art]
        else:
            keep = [d for d in lst if d.get("npcId") in era]
            keep += [dict(d, type=2) for d in lst
                     if d.get("npcId") not in era and d.get("npcId") in art and (d.get("npcId"), sc) in talks_in]
        if keep:
            scenes[sc] = keep
    if a.extra:
        for sc, lst in json.load(open(a.extra, encoding="utf-8"))["scenes"].items():
            have = {d.get("npcId") for d in scenes.get(sc, [])}
            for npc, view, x, y in lst:
                if npc not in have and npc in art:
                    scenes.setdefault(sc, []).append({"npcId": npc, "viewId": view, "x": x, "y": y, "type": 2})
    pkg = os.path.join(a.out, "mmo", "tasknpc")
    os.makedirs(pkg, exist_ok=True)
    rows = ",\n".join(
        '         "%s":[%s]' % (sc, ",".join("[%d,%d,%s,%s,%d]" % (d["npcId"], d.get("viewId", 1), d.get("x", 0), d.get("y", 0), d.get("type", 0)) for d in lst))
        for sc, lst in sorted(scenes.items()))
    open(os.path.join(pkg, "SceneNpcData.as"), "w", encoding="utf-8").write(
        "package mmo.tasknpc\n{\n   /** GENERATED by tools/gen_npc_data.py from the later SceneNpcConfig: [npcId, viewId, x, y, type]. */\n"
        "   public class SceneNpcData\n   {\n      public static const SCENES:Object = {\n" + rows + "\n      };\n   }\n}\n")
    talks = free_talks(a.later)
    body = "\n".join('<t k="%s">%s</t>' % (k.replace('"', "&quot;"), x) for k, x in sorted(talks.items()))
    open(os.path.join(pkg, "FreeTalkData.as"), "w", encoding="utf-8").write(
        "package mmo.tasknpc\n{\n   /** GENERATED by tools/gen_npc_data.py from the later npcFreeTaskTalkConfig. */\n"
        "   public class FreeTalkData\n   {\n      public static const TALKS:XML = <talks>\n" + body + "\n</talks>;\n   }\n}\n")
    print(f"{len(scenes)} scenes, {sum(len(v) for v in scenes.values())} NPCs, {len(talks)} conversations -> {pkg}")


if __name__ == "__main__":
    main()
