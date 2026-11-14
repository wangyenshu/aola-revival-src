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

Quest opponents fought in the story (邪恶霹雳 332 and 组合机器人 334 of 神奇的霹雳, 苹果智能炮
360 and 风筝雷电射线 361 of the 发明岛 quests) were fought as their battle rows, 10000, 20000
or 30000 plus their number (pmDataMap2, 10332 …): those carry the skills they fought with.
Their own rows do not: 360 and 361 list none, and 332 and 334 the 16 of the 烈火鸟 line (whose
numbers 332 copies too), so for these (--battle-skills) the skills are their battle rows', in
the rows' order, all from level 1.
"""
from __future__ import annotations

import argparse
import json
import os
import re

ROW = re.compile(r'^\s*"(\w+)":new (PM\w+)\((.*)\),?\s*$')
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


def load_original(path: str) -> dict:
    """The 2013–14 numbers of the 亚比 the later table changed: race -> {s, t, learn, n}."""
    if not path or not os.path.exists(path):
        return {}
    return {k: v for k, v in json.load(open(path, encoding="utf-8")).items() if k.isdigit()}


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pmdata", required=True)
    ap.add_argument("--pets", required=True, help="revival/pets.json (era species)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--story", default="869,998",
                    help="species fought only in story quests, not in the era's 亚比 list: the 通灵巫师 (869, tasks 2451–2583, "
                         "2681–2764) and the 黑化病毒 (998, task 1294); they cannot be caught")
    ap.add_argument("--battle-skills", default="332,334,360,361",
                    help="species whose skills are those of their battle rows (10000/20000/30000 + id)")
    ap.add_argument("--original", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "data", "pets-original.json"),
                    help="亚比 the later table changed, as they were in 2013–14 (\"\" for none)")
    ap.add_argument("--upto", type=int, default=0,
                    help="also keep every species of the table up to this id, the 超系 forms of those "
                         "(pmChaoxiMap) and their 究极 forms (pmJiujiMap): the 工具箱's 亚比")
    a = ap.parse_args(argv)
    battle = {x for x in a.battle_skills.split(",") if x}
    era = set(json.load(open(a.pets, encoding="utf-8")).keys()) | {x for x in a.story.split(",") if x}
    jiuji_rows: list[list[str]] = []
    qiyue_rows: list[list[str]] = []
    weather_rows: dict[str, list[str]] = {}
    if a.upto:
        chao_src: dict[str, set[str]] = {}
        for section, key, cls, p in rows(a.pmdata):
            if cls == "PMData" and section == "pmDataMap" and key.isdigit() and int(key) <= a.upto:
                era.add(key)
            elif cls == "PMChaoxiData":
                chao_src.setdefault(p[0], set()).add(p[1])
            elif cls == "PMJiujiData" and p[0].isdigit() and int(p[0]) < 10000:
                jiuji_rows.append(p)
            elif cls == "PMJiujiQiyueData" and p[0].isdigit():
                qiyue_rows.append(p)
            elif cls == "PMWeather":
                weather_rows[key] = p
        era |= {c for c, srcs in chao_src.items() if any(int(x) <= a.upto for x in srcs)}
        # The 究极 forms of the lines kept (2395 虎烈张飞's is 2396).
        era |= {p[1] for p in jiuji_rows if p[0] in era}

    species, skills, chart, exp = {}, {}, {}, {}
    forms: dict[str, str] = {}
    for section, key, cls, p in rows(a.pmdata):
        if cls == "PMData" and len(p) > 29 and key.isdigit() and int(key) > 10000:
            forms[key] = p[29]
    for section, key, cls, p in rows(a.pmdata):
        if cls == "PMData" and section == "pmDataMap" and key in era:
            p += [""] * (40 - len(p))
            learn = []
            for part in p[29].split("#"):
                m = re.match(r"(\d+)-(\d+)$", part)
                if m:
                    learn.append([int(m.group(1)), int(m.group(2))])
            # A level whose first digit the table lost (月鸟's line: …, 20, 4, 28 …; 宝宝星's: 16, 0,
            # 24 …): the one between its neighbours, else that skill came at Lv4 / at once.
            for i in range(1, len(learn) - 1):
                if learn[i][0] < learn[i - 1][0] and learn[i - 1][0] < learn[i + 1][0]:
                    learn[i][0] = (learn[i - 1][0] + learn[i + 1][0]) // 2
            if key in battle:
                learn = []
                for f in (str(10000 + int(key)), str(20000 + int(key)), str(30000 + int(key))):
                    for part in forms.get(f, "").split("#"):
                        m = re.match(r"(\d+)-(\d+)$", part)
                        if m and [0, int(m.group(2))] not in learn:
                            learn.append([0, int(m.group(2))])
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
            if a.upto:
                # 特性 (column 18) that makes a 圣域 (PMWeather of type 2–4), and the 圣域技能 (column 39,
                # "level-weather id") learnt at that level.
                if p[18] and p[18] != "-1" and any(weather_rows.get(w, ["", "", "0"])[2] in ("2", "3", "4") for w in p[18].split("#")):
                    species[key]["f"] = p[18]
                if p[39] and p[39] not in ("0", "-1"):
                    species[key]["sy"] = p[39]
                # 超奥义 (column 40: its skill; the later AoYiConfig.getAoYiSkillId), once a battle.
                p += [""] * (41 - len(p))
                if p[40] and p[40] not in ("0", "-1"):
                    species[key]["ao"] = int(p[40])
        elif cls == "PMSkill" and section in ("pmSkillMap", "pmSkillMap1"):
            p += [""] * (40 - len(p))
            aoyi = {"ao": int(num(p[19]))} if p[19] not in ("", "-1") else {}
            # The later client's generic animation for a skill with none of its own (SkillMap.
            # getSkillAttributeEffectId): by its range, else by 属性 and kind of blow (column 39,
            # else 12); none for a status skill.
            kind, attr, hit = int(num(p[12])), int(num(p[11])), int(num(p[13]))
            if kind != 2:
                aoyi["ge"] = 20000001 if hit in (2, 6) else 20000002 if hit in (8, 9) else 10000000 + attr * 100 + int(num(p[39] or p[12]))
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
                # 超奥义 type (column 19, PMSkill.aoyiType): 0 强袭, 1 潜能, 2 战界, 3 神化, 4 BOSS克星.
                **aoyi,
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

    # 亚比 the later table changed (伊乐, 圣·天伊): their 2013–14 numbers (tools/data/pets-original.json).
    for key, orig in load_original(a.original).items():
        if key in species:
            species[key].update({k: v for k, v in orig.items() if k in ("s", "t", "learn")})
    used = {str(s) for sp in species.values() for _, s in sp["learn"]} | {str(sp["ao"]) for sp in species.values() if "ao" in sp}
    # The skills a kept skill sets off by name (触发技能X: 万里雪飘, 不朽圣体 …), and theirs in turn:
    # kept too, with a name index for the battle engine.
    by_name: dict[str, str] = {}
    for k, v in skills.items():
        by_name.setdefault(v["n"], k)
    named: dict[str, int] = {}
    todo = list(used)
    while todo:
        k = todo.pop()
        for name in re.findall(r"触发(?:技能)?([^，。；、\s【】]+?)(?=[，。；、]|且|并|$)", skills.get(k, {}).get("d", "")):
            # As the reader writes them (skilltext.ts normalise): 灵兽之域•南 is the table's 灵兽之域·南,
            # 超·磁暴 its 超·磁爆.
            name = name.replace("•", "·").replace("超·磁暴", "超·磁爆")
            hit = by_name.get(name)
            if hit and name not in named:
                named[name] = int(hit)
                if hit not in used:
                    used.add(hit)
                    todo.append(hit)
    skills = {k: v for k, v in skills.items() if k in used}
    out = {"species": species, "skills": skills, "chart": chart, "exp": exp}
    if named:
        out["named"] = dict(sorted(named.items()))
    if a.upto:
        # 究极 (PMJiujiData: from, to, name, 究极等级, 聚能回合数, 持续回合数, HP, 攻击, 防御, 特攻, 特防, 速度 up,
        # text, …): each line at its top 等级 (三阶; the two 战骑 二阶).
        top: dict[str, list[str]] = {}
        for p in jiuji_rows:
            if p[0] in species and p[1] in species and (p[0] not in top or int(num(p[3])) > int(num(top[p[0]][3]))):
                top[p[0]] = p
        out["jiuji"] = {k: {"to": int(p[1]), "lv": int(num(p[3])), "store": int(num(p[4])), "keep": int(num(p[5])),
                            "up": [int(num(x)) for x in p[6:12]], "d": p[12]} for k, p in sorted(top.items(), key=lambda kv: int(kv[0]))}
        # 契约 (究极 type 2, jiujiType: 零夜战骑, 辉月战骑): no points, the whole battle; their 坐骑召唤 at
        # the same 等级 (PMJiujiQiyueData: from, to, name, 契约等级, 回复最大体力值%, 伤害抗性%, 速度等级,
        # text, …, 契约技能 name and words).
        for k, p in top.items():
            if len(p) > 23 and p[23] == "2":
                q = next((x for x in qiyue_rows if x[0] == k and x[3] == p[3]), None)
                if q:
                    out["jiuji"][k].update({"k": 2, "qy": {"hp": int(num(q[4])), "res": int(num(q[5])), "spd": int(num(q[6])),
                                                           "d": q[7], "sn": q[10], "sd": q[11]}})
        # 圣域 (PMWeather: id, name, type 1 圣域技能 / 2 圣域 / 3 自动循环激活圣域 / 4 特性, text, BuffXML).
        out["weather"] = {k: {"n": p[1], "k": int(num(p[2])), "d": p[4] or p[3], "b": p[5] if len(p) > 5 else ""}
                          for k, p in weather_rows.items() if p[2] in ("1", "2", "3", "4")}
    json.dump(out, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(f"{len(species)} species, {len(skills)} skills, {len(chart)} attributes, {len(exp)} curves -> {a.out}")


if __name__ == "__main__":
    main()
