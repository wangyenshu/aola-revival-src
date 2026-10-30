#!/usr/bin/env python3
"""Generate the task tables for the 2012 story quests.

game/ holds the original task scripts of 2010 to January 2013
(taskext/task<id>.swf), but the January 2013 task tables are lost:
task/taskdefines (which tasks exist, their steps, how they start), the NPC
conversations of task/tasknpc, and the scene table (mmo.config.ConfigEmbed.
tconfig) that says which script loads in which scene. The later copies of all
three still carry the 2012 story quests with the same task and step ids and
the same conversation keys their scripts open, so this takes from them the
quests that can be played:

  * a task (TaskDefine type 0) with a starter, numbered within the 2013
    range (up to the newest era script), other than the newbie quest (135,
    140, 150, RECONSTRUCTED in rebuild/src/taskdefines);
  * NPC conversations for at least half of its steps;
  * every script the scene table names for it is in game/ (era files where
    they survive; later uploads of the same scripts otherwise, added by
    tools/story_files.py);
  * its pre-tasks are such tasks too, or the newbie quest.

Outputs (generated; commit them):

  rebuild/gen/taskdata/mmo/taskdefines/TaskData.as   defines, starters,
      panel art and scenes, and the scene table of the scripts
  rebuild/gen/tasknpc/mmo/tasknpc/TaskTalkData.as    the NPC conversations
      of those tasks (task talk "npc_step_scene", start talk "npc_task_scene")
  rebuild/static/www.9aola.com/revival/tasks.json    the same tables for the server

  tools/gen_tasks.py --ffdec .toolchain/ffdec/ffdec.jar --game game \\
      --config tools/data/live-config.swf --out-gen rebuild/gen --out-static rebuild/static
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

WWW = "www.9aola.com"
NEWBIE = {135, 140, 150}


def decompile(ffdec: str, swf: str, out: str, what: str = "script") -> None:
    subprocess.run(["java", "-jar", ffdec, "-export", what, out, swf], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def game_file(game: str, rel: str) -> str | None:
    """The file in game/ for www.9aola.com/<rel> (any version)."""
    d = os.path.join(game, WWW, os.path.dirname(rel))
    base = os.path.basename(rel)
    if not os.path.isdir(d):
        return None
    for n in sorted(os.listdir(d)):
        if n == base or n.startswith(base + "%3F"):
            return os.path.join(d, n)
    return None


def game_paths(game: str) -> set[str]:
    """Paths under www.9aola.com in game/, without the version."""
    out = set()
    for line in open(os.path.join(game, "FILES.jsonl"), encoding="utf-8"):
        p = json.loads(line)["path"]
        if p.startswith(WWW + "/"):
            out.add(re.sub(r"%3F.*$", "", p[len(WWW) + 1:]))
    return out


def load_tables(ffdec: str, game: str, config: str, work: str) -> dict:
    """The later tables: defines, starters, panels, scene table, conversations."""
    paths = {}
    for k, rel in (("defines", "task/taskdefines.swf"), ("tasknpc", "task/tasknpc.swf")):
        f = game_file(game, rel)
        if f is None:
            sys.exit(f"missing {WWW}/{rel} in game/")
        out = os.path.join(work, k)
        if not os.path.isdir(out):
            decompile(ffdec, f, out)
        paths[k] = out
    cfg_out = os.path.join(work, "config")
    if not os.path.isdir(cfg_out):
        decompile(ffdec, config, cfg_out, "binaryData")

    td = open(os.path.join(paths["defines"], "scripts/mmo/taskdefines/TaskDefines.as"), encoding="utf-8").read()
    defines = {int(m[1]): (int(m[2]), m[3]) for m in re.finditer(r'"(\d+)":new TaskDefine\(\d+,(\d+),"([^"]*)"\)', td)}
    starters = {}
    for m in re.finditer(r'"(\d+)":new TaskStarter\((\d+),(\d+),"([^"]*)","([^"]*)",(\d+),"([^"]*)",(\d+),(\d+)\)', td):
        starters[int(m[1])] = {"type": int(m[3]), "ext": m[4], "pre": [int(x) for x in m[5].split(",") if x], "online": int(m[6]),
                               "name": m[7], "line": int(m[8]), "area": int(m[9])}
    pr = open(os.path.join(paths["defines"], "scripts/mmo/taskdefines/TaskPanelResDefine.as"), encoding="utf-8").read()
    panels = {int(m[1]): dict(re.findall(r'"(\w+)":"([^"]*)"', m[2])) for m in re.finditer(r'"(\d+)":\{([^{}]*)\}', pr)}

    tbin = None
    for d, _, ns in os.walk(cfg_out):
        for n in ns:
            if "tconfig" in n:
                tbin = os.path.join(d, n)
    tconfig = ET.fromstring(open(tbin, encoding="utf-8").read())
    te = []
    for s in tconfig.iter("s"):
        for e in s.iter("te"):
            te.append({"scene": s.get("nm"), "file": e.get("file"), "cls": e.get("cls"),
                       "taskIds": [int(x) for x in re.findall(r"\d+", e.get("taskId") or "")],
                       "starterIds": [int(x) for x in re.findall(r"\d+", e.get("starterId") or "")]})

    talk, start = {}, {}
    cfgdir = os.path.join(paths["tasknpc"], "scripts/mmo/tasknpc/config")
    pat = re.compile(r'this\.(npcTaskTalkConfig|npcStarterTalkConfig)\["(\d+_\d+_[^"]+)"\]\s*=\s*(<config.*?</config>);', re.S)
    for d, _, ns in os.walk(cfgdir):
        for n in sorted(ns):
            if n.endswith(".as"):
                for kind, key, xml in pat.findall(open(os.path.join(d, n), encoding="utf-8").read()):
                    (talk if kind == "npcTaskTalkConfig" else start)[key] = xml

    t = {"defines": defines, "starters": starters, "panels": panels, "te": te, "talk": talk, "start": start}
    owner = {s: k for k in defines for s in steps_of(t, k)}
    entries_of: dict[int, list] = {}
    for e in te:
        tasks = {owner.get(i, i) for i in e["taskIds"] + e["starterIds"]}
        m = re.match(r"taskext/task(\d+)$", e["file"] or "")
        if m:
            tasks.add(owner.get(int(m[1]), int(m[1])))
        for k in tasks:
            entries_of.setdefault(k, []).append(e)
    t["entries_of"] = entries_of
    return t


def steps_of(t: dict, task: int) -> list[int]:
    d = t["defines"].get(task)
    return [int(x) for x in d[1].split(",") if x] if d and d[0] == 0 else []


def choose(t: dict, game: str, allow_later: bool = True, require_scripts: bool = True, why_not: dict | None = None) -> list[int]:
    why_not = {} if why_not is None else why_not
    origin = {}
    newest = 0
    for line in open(os.path.join(game, "FILES.jsonl"), encoding="utf-8"):
        r = json.loads(line)
        m = re.match(re.escape(WWW) + r"/taskext/task(\d+)\.swf", r["path"])
        if m:
            origin[f"taskext/task{m[1]}"] = r["origin"]
            if r["origin"] == "era":
                newest = max(newest, int(m[1]))
    talk_steps = set()
    for k in list(t["talk"]) + list(t["start"]):
        talk_steps.add(int(k.split("_")[1]))
    cand = set()
    for task, d in t["defines"].items():
        if d[0] != 0 or task not in t["starters"] or task in NEWBIE or task > newest:
            continue
        st = steps_of(t, task)
        talked = sum(1 for s in st if s in talk_steps)
        if not st or talked < max(1, len(st) // 2):
            why_not[task] = "no conversations"
            continue
        if require_scripts:
            files = {e["file"] for e in t["entries_of"].get(task, [])}
            bad = [f for f in files if f not in origin or (not allow_later and origin[f] != "era")]
            if bad:
                why_not[task] = "scripts not in game/: " + ",".join(sorted(bad))
                continue
        cand.add(task)
    changed = True
    while changed:
        changed = False
        for task in sorted(cand):
            pre = t["starters"][task]["pre"]
            if any(p not in cand and p not in NEWBIE for p in pre):
                cand.discard(task)
                why_not[task] = "pre-task missing: " + ",".join(str(p) for p in pre if p not in cand and p not in NEWBIE)
                changed = True
    return sorted(cand)


def write(t: dict, chosen: list[int], out_gen: str, out_static: str) -> dict:
    defines, starters, panels = t["defines"], t["starters"], t["panels"]
    step_ids = {s for k in chosen for s in steps_of(t, k)}
    ids = set(chosen) | step_ids
    scene_te: dict[str, list] = {}
    for k in chosen:
        for e in t["entries_of"].get(k, []):
            lst = scene_te.setdefault(e["scene"], [])
            if e not in lst:
                lst.append(e)
    talk_keys = sorted(k for k in t["talk"] if int(k.split("_")[1]) in ids)
    start_keys = sorted(k for k in t["start"] if int(k.split("_")[1]) in ids)

    def s(v) -> str:
        return json.dumps(v, ensure_ascii=False)

    os.makedirs(os.path.join(out_gen, "taskdata/mmo/taskdefines"), exist_ok=True)
    L = ["package mmo.taskdefines", "{", "   import mmo.interfaces.task.data.TaskDefine;", "   import mmo.interfaces.task.data.TaskStarter;", "",
         "   /**", "    * GENERATED by tools/gen_tasks.py from the later task/taskdefines and",
         "    * config/config.swf (tconfig): the 2012 story quests. Do not edit.", "    */",
         "   public class TaskData", "   {", "      public static const defines:Object = {"]
    L += [f'         "{i}": new TaskDefine({i}, {defines[i][0]}, {s(defines[i][1])}),' for i in sorted(ids) if i in defines]
    L[-1] = L[-1].rstrip(",")
    L += ["      };", "", "      public static const starters:Object = {"]
    for k in chosen:
        st = starters[k]
        L.append(f'         "{k}": new TaskStarter({k}, {st["type"]}, {s(st["ext"])}, {s(",".join(map(str, st["pre"])))}, {st["online"]}, '
                 f'{s(st["name"])}, {st["line"]}, {st["area"]}),')
    L[-1] = L[-1].rstrip(",")
    L += ["      };", "", "      /** Task panel art per task and step: {cn, fn, fincn, sc} (sc: the scene to go to). */", "      public static const panels:Object = {"]
    L += [f'         "{i}": {s(panels[i])},' for i in sorted(ids) if i in panels]
    L[-1] = L[-1].rstrip(",")
    L += ["      };", "", "      /** Scene -> scripts to load there: {file, cls, taskIds, starterIds}. */", "      public static const sceneExts:Object = {"]
    L += [f"         {s(sc)}: {s(scene_te[sc])}," for sc in sorted(scene_te)]
    L[-1] = L[-1].rstrip(",")
    L += ["      };", "", "      public function TaskData()", "      {", "         super();", "      }", "   }", "}", ""]
    open(os.path.join(out_gen, "taskdata/mmo/taskdefines/TaskData.as"), "w", encoding="utf-8").write("\n".join(L))

    os.makedirs(os.path.join(out_gen, "tasknpc/mmo/tasknpc"), exist_ok=True)
    T = ["package mmo.tasknpc", "{", "   /**", "    * GENERATED by tools/gen_tasks.py from the later task/tasknpc: the NPC",
         "    * conversations of the 2012 story quests (TaskData). Keys", '    * "npc_step_scene" (talk while a step is being done) and, in',
         '    * starts, "npc_task_scene" (talk that offers a task). Do not edit.', "    */",
         "   public class TaskTalkData", "   {", "      public static function fill(talk:Object, starts:Object):void", "      {"]
    T += [f"         talk[{s(k)}] = {t['talk'][k]};" for k in talk_keys]
    T += [f"         starts[{s(k)}] = {t['start'][k]};" for k in start_keys]
    T += ["      }", "   }", "}", ""]
    open(os.path.join(out_gen, "tasknpc/mmo/tasknpc/TaskTalkData.as"), "w", encoding="utf-8").write("\n".join(T))

    os.makedirs(os.path.join(out_static, WWW, "revival"), exist_ok=True)
    json.dump({"defines": {str(i): list(defines[i]) for i in sorted(ids) if i in defines}, "starters": {str(k): starters[k] for k in chosen}},
              open(os.path.join(out_static, WWW, "revival", "tasks.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=0)
    return {"steps": len(step_ids), "scripts": len({e["file"] for k in chosen for e in t["entries_of"].get(k, [])}),
            "talks": len(talk_keys), "starts": len(start_keys)}


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ffdec", required=True)
    ap.add_argument("--game", required=True)
    ap.add_argument("--config", required=True, help="the later config/config.swf (mmo.config.ConfigEmbed)")
    ap.add_argument("--out-gen", required=True)
    ap.add_argument("--out-static", required=True)
    ap.add_argument("--work", help="keep the decompiled sources here")
    a = ap.parse_args(argv)
    t = load_tables(a.ffdec, a.game, a.config, a.work or tempfile.mkdtemp(prefix="gen_tasks_"))
    why: dict[int, str] = {}
    chosen = choose(t, a.game, why_not=why)
    n = write(t, chosen, a.out_gen, a.out_static)
    print(f"{len(chosen)} tasks, {n['steps']} steps, {n['scripts']} scripts, {n['talks']} task talks, {n['starts']} start talks")
    for k in chosen:
        st = t["starters"][k]
        print(f"  {k:5d} {st['name']}  (pre {','.join(map(str, st['pre'])) or '-'}, area {st['area']})")
    for k in sorted(why):
        if why[k] != "no conversations":
            print(f"  left out {k} {t['starters'][k]['name']}: {why[k]}")


if __name__ == "__main__":
    main()
