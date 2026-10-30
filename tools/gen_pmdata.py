#!/usr/bin/env python3
"""Generate the battle data of the revival from the later pet/pmservice.

The 2013 client reads its 亚比 numbers through mmo.interfaces.pet.pm.data
(PMCustomData: PMDataMap, PMExpMap, PMAttDefMap, PMSkillMap), whose column
titles are in the 2013 PMExcelMap; the 2013 tables themselves (in the lost
pet/pmservice v130124) are gone. The later pmservice still carries the same
tables in mmo.pm.data.PMDataList, a superset. FFDec only writes that class's
static data with a long decompile timeout:

  java -jar ffdec.jar -config decompilationTimeoutSingleMethod=1200,decompilationTimeoutFile=2400 \\
      -selectclass mmo.pm.data.PMDataList -export script out pet/pmservice.swf

This keeps the species of the era cut (revival/pets.json from gen_pets.py) and
the two the story quests fight that are in no 亚比 list (--story), the skills
they learn, the attribute table and the experience curves, and writes
(百田's data, so into the rebuilt root, not git):

  <rebuilt>/www.9aola.com/revival/pmdata.json
    {"species": {"<id>": {"n": name, "s": [hp, atk, def, satk, sdef, spd],
                          "ev": [6 effort yields], "t": [attr1, attr2], "bx": base exp,
                          "xt": exp curve, "c": [catch1, catch2] ("NA" = cannot be caught),
                          "evo": "lv-id#lv-id", "learn": [[level, skill id], …]}},
     "skills": {"<id>": {"n": name, "old": original name, "p": power, "p1": single power,
                         "acc": accuracy %, "pp": PP, "pri": priority, "t": attribute,
                         "k": 0 physical / 1 special / 2 status, "d": description}},
     "chart": {"<atk attr>": {"<def attr>": multiplier, … only non-1 entries}},
     "exp": {"<curve>": [total exp at level 1, 2, …]}}

  tools/gen_pmdata.py --pmdata out/scripts/mmo/pm/data/PMDataList.as \\
      --pets rebuilt/www.9aola.com/revival/pets.json --out rebuilt/www.9aola.com/revival/pmdata.json
"""
from __future__ import annotations

import argparse
import json
import re

ROW = re.compile(r'^\s*"(\d+)":new (PM\w+)\((.*)\),?\s*$')
STR = re.compile(r'"((?:[^"\\]|\\.)*)"')


def rows(path: str):
    section = None
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"\s*public static const (\w+):Object", line)
            if m:
                section = m.group(1)
                continue
            m = ROW.match(line)
            if m and section:
                yield section, m.group(1), m.group(2), [s.encode().decode("unicode_escape") if "\\u" in s else s for s in STR.findall(m.group(3))]


def num(s: str, default: float = 0) -> float:
    try:
        return float(s)
    except ValueError:
        return default


MULT = {"": 1, "1": 1, "1/2": 0.5, "2": 2, "3": 3, "-1": 0}


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pmdata", required=True)
    ap.add_argument("--pets", required=True, help="revival/pets.json (era species)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--story", default="869,998",
                    help="species fought only in story quests, not in the era's 亚比 list: the 通灵巫师 (869, tasks 2451–2583, "
                         "2681–2764) and the 黑化病毒 (998, task 1294); they cannot be caught")
    a = ap.parse_args(argv)
    era = set(json.load(open(a.pets, encoding="utf-8")).keys()) | {x for x in a.story.split(",") if x}

    species, skills, chart, exp = {}, {}, {}, {}
    for section, key, cls, p in rows(a.pmdata):
        if cls == "PMData" and section == "pmDataMap" and key in era:
            p += [""] * (40 - len(p))
            learn = []
            for part in p[29].split("#"):
                m = re.match(r"(\d+)-(\d+)$", part)
                if m:
                    learn.append([int(m.group(1)), int(m.group(2))])
            species[key] = {
                "n": p[1],
                "s": [int(num(x)) for x in p[4:10]],
                "ev": [int(num(x)) for x in p[10:16]],
                "t": [int(num(p[16])), int(num(p[17], num(p[16])))],
                "bx": int(num(p[20])),
                "xt": p[21] or "0",
                "c": [p[24], p[25]],
                "evo": p[26],
                "learn": learn,
            }
        elif cls == "PMSkill" and section in ("pmSkillMap", "pmSkillMap1"):
            p += [""] * (30 - len(p))
            skills[key] = {
                "n": p[3] or p[2],
                "old": p[2],
                "p": int(num(p[7])),
                "p1": int(num(p[26], num(p[7]))),
                "acc": int(num(p[8], 100)) or 100,
                "pp": int(num(p[9], 20)) or 20,
                "pri": int(num(p[10])),
                "t": int(num(p[11])),
                "k": int(num(p[12])),
                "d": p[6] or p[5] or p[4],
            }
        elif cls == "PMAttDef":
            row = {}
            for i, v in enumerate(p):
                if v in ("超克制", "克制", "正常", "微弱", "无效"):
                    break
                if v in MULT and MULT[v] != 1:
                    row[str(i)] = MULT[v]
            chart[key] = row
        elif cls == "PMExp":
            exp[key] = [int(num(x)) for x in p]

    used = {str(s) for sp in species.values() for _, s in sp["learn"]}
    skills = {k: v for k, v in skills.items() if k in used}
    out = {"species": species, "skills": skills, "chart": chart, "exp": exp}
    json.dump(out, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(f"{len(species)} species, {len(skills)} skills, {len(chart)} attributes, {len(exp)} curves -> {a.out}")


if __name__ == "__main__":
    main()
