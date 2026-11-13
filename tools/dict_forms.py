#!/usr/bin/env python3
"""Add to the 亚比图鉴 the species the later dictionary table has no row for.

The later PetDictionaryData (gen_pets.py) lists the 亚比 a player gets; the pet table
(PMDataList, pmdata.json) also has those that only fight: the 究极 forms (神照修罗王's 2161 …),
图腾, 星石, the bosses' forms (龙态炎王, 太古冰罗皇 …) and a few more. This writes a row for each,
after gen_pets.py and gen_pmdata.py:

  - name, 身高 and 体重 from the pet table (its columns 2 and 3);
  - the two 属性 lists (克制 and 被克制): a 究极 form its 亚比's, the others those of a
    图鉴 亚比 with the same 属性;
  - 获得方式: a 究极 form "由<its 亚比>究极变身而成。" (the 究极 table), the others
    "无法获得。", as the 2013 table writes it for the 亚比 no player gets;
  - 介绍: a 究极 form its 亚比's; the others none;
  - in revival/pets.json its name, 属性 and skill names, as the other rows.

  tools/dict_forms.py --dict rebuild/gen/petdict/mmo/pet/petdictionarydata/PetDictionaryData.as \\
      --pets rebuild/static/www.9aola.com/revival/pets.json \\
      --pmdata rebuild/static/www.9aola.com/revival/pmdata.json --table .../PMDataList.as
"""
from __future__ import annotations

import argparse
import json
import re


def q(s: str) -> str:
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dict", required=True, help="PetDictionaryData.as of gen_pets.py (written in place)")
    ap.add_argument("--pets", required=True, help="revival/pets.json (written in place)")
    ap.add_argument("--pmdata", required=True, help="revival/pmdata.json of gen_pmdata.py")
    ap.add_argument("--table", required=True, help="the later PMDataList.as (身高, 体重)")
    a = ap.parse_args(argv)

    src = open(a.dict, encoding="utf-8").read()
    rows: dict[int, str] = {}
    for m in re.finditer(r'^\s*"(\d+)":(new PetDictionaryDataItem\(.*\)),?\s*$', src, re.M):
        rows[int(m.group(1))] = m.group(2)
    pets = json.load(open(a.pets, encoding="utf-8"))
    pm = json.load(open(a.pmdata, encoding="utf-8"))
    table = open(a.table, encoding="utf-8").read()
    size: dict[int, tuple[str, str]] = {}
    for m in re.finditer(r'"(\d+)":new PMData\("\d+","[^"]*","([^"]*)","([^"]*)"', table):
        size[int(m.group(1))] = (m.group(2), m.group(3))

    def args(row: str) -> list[str]:
        return re.findall(r'"((?:[^"\\]|\\.)*)"', row)

    # The 克制 lists by the 属性 pair of the 图鉴's 亚比 (the same pair, or the first 属性 alone).
    by_pair: dict[tuple, tuple[str, str]] = {}
    for i, row in rows.items():
        sp = pm["species"].get(str(i))
        if not sp:
            continue
        x = args(row)
        t = tuple(sp["t"])
        by_pair.setdefault(t, (x[4], x[5]))
        if t[0] == t[1]:
            by_pair.setdefault((t[0],), (x[4], x[5]))
    base_of = {v["to"]: int(k) for k, v in pm.get("jiuji", {}).items()}

    added = []
    for k in sorted(pm["species"], key=int):
        i = int(k)
        if i in rows or k in pets:
            continue
        sp = pm["species"][k]
        t = tuple(sp["t"])
        att = by_pair.get(t) or by_pair.get((t[0],)) or ("", "")
        h, w = size.get(i, ("", ""))
        base = base_of.get(i)
        if base and base in rows:
            b = args(rows[base])
            way, intro, food = f"由{b[1]}究极变身而成。", b[12], b[11]
            att = (b[4], b[5])
        else:
            way, intro, food = "无法获得。", "", ""
        fields = [k, sp["n"], h, w, att[0], att[1], "-", "0", "0", "", way, food, intro, "—", "0", "0", "0", "0", "-1", "", "-1", ""]
        rows[i] = "new PetDictionaryDataItem(" + ",".join(q(f) for f in fields) + ")"
        names = [pm["skills"][str(s)]["n"] for _, s in sp.get("learn", []) if str(s) in pm["skills"]]
        pets[k] = {"n": sp["n"], "a": t[0], "e": 0, "next": 0, "sk": names[:12]}
        added.append(i)

    body = ",\n".join(f'         "{i}":{rows[i]}' for i in sorted(rows))
    head, _, rest = src.partition("public static const data:Object = {\n")
    tail = rest[rest.index("\n      };"):]
    open(a.dict, "w", encoding="utf-8").write(head + "public static const data:Object = {\n" + body + tail)
    pets = {k: pets[k] for k in sorted(pets, key=int)}
    json.dump(pets, open(a.pets, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print(f"{len(added)} rows added ({len(rows)} in the 图鉴)")


if __name__ == "__main__":
    main()
