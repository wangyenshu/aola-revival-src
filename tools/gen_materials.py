#!/usr/bin/env python3
"""Write the server's price table from the 2013 material data.

The emulated server has to know what each item costs; the 2013 server's own
table is lost, but the client's library/materialdata (decompiled with FFDEC)
lists every material with its price, buy-back value, real-money price, how
many one may own, and whether it is for members. Output (JSON, 百田's data:
written next to the game files, not into git):

  {"<material type>": {"<id>": [price, buyback, rmb, maxQuantity, vip, name]}}

Clothes carry price 0 and only a buy-back value; config.xml's
<materialInfo><buyback percent="0.5"/> makes their price twice that (the
Halloween 2012 page shows 吞食南瓜帽 at 660 晶币, buy-back 330).

  tools/gen_materials.py --src <decompiled library/materialdata>/scripts \\
      --out rebuilt/www.9aola.com/revival/materials.json
"""
from __future__ import annotations

import argparse
import json
import os
import re

# class -> (material type, index of price, buyback(sale), rmb, maxQ, vip) in the constructor args
LAYOUT = {
    "Clothes": (0, 6, 3, 7, 5, 2),
    "Furniture": (1, 6, 3, 7, 5, 2),
    "Item": (2, 3, 6, 4, 9, 7),
    "PetEgg": (5, 6, 3, 7, 5, 2),
    "Plant": (9, 5, 4, 6, None, 3),
    "PlantItem": (10, 5, 3, 6, None, 2),
}
FILES = {"Clothes": "ClothesData.as", "Furniture": "FurnitureData.as", "Item": "ItemData.as",
         "PetEgg": "PetEggData.as", "Plant": "PlantData.as", "PlantItem": "PlantItemData.as"}


def split_args(s: str) -> list[str]:
    out, cur, q, depth = [], "", False, 0
    for ch in s:
        if ch == '"':
            q = not q
        if not q and ch in "([":
            depth += 1
        if not q and ch in ")]":
            depth -= 1
        if ch == "," and not q and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def num(v: str) -> int:
    v = v.strip()
    if v in ("true", "false"):
        return 1 if v == "true" else 0
    try:
        return int(float(v))
    except ValueError:
        return 0


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--buyback", type=float, default=0.5)
    a = ap.parse_args(argv)
    table: dict[str, dict[str, list]] = {}
    for cls, fn in FILES.items():
        path = os.path.join(a.src, "mmo", "materialdata", fn)
        if not os.path.exists(path):
            continue
        tp, ip, isale, irmb, imax, ivip = LAYOUT[cls]
        text = open(path, encoding="utf-8").read()
        for m in re.finditer(r'"(\d+)":new ' + cls + r"\((.*?)\)(?=,\s*\n|\s*\n\s*\})", text):
            args = split_args(m.group(2))
            try:
                price, sale, rmb = num(args[ip]), num(args[isale]), num(args[irmb])
                maxq = num(args[imax]) if imax is not None else 9999
                vip = num(args[ivip])
                name = args[1].strip('"') if cls != "Plant" else args[2].strip('"')
            except IndexError:
                continue
            if cls == "Clothes" and price == 0 and sale > 0:
                price = int(round(sale / a.buyback))
            table.setdefault(str(tp), {})[m.group(1)] = [price, sale, rmb, maxq, vip, name]
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    json.dump(table, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print({k: len(v) for k, v in table.items()}, "->", a.out)


if __name__ == "__main__":
    main()
