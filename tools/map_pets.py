#!/usr/bin/env python3
"""Read the wild 亚比, rare 亚比, mini games and scenes of each place on the
November 2012 world map (map/mapguide2012.swf, the map 百田 published on its
guide page): hovering a place shows them as text fields of its button.

  tools/map_pets.py --xml <ffdec -swf2xml of mapguide2012.swf> --dict <PetDictionaryData.as> --out <json>

The text fields are matched to their labels (亚比： 稀有亚比： 小游戏： 场景：
NPC： 功能：) by row; names run together in one field ("库多兽朵朵兔") are
split on the 亚比 names of the 2013 dictionary.
"""
from __future__ import annotations

import argparse
import html
import json
import re
import xml.etree.ElementTree as ET

LABELS = {"亚比：": "pets", "稀有亚比：": "rare", "小游戏：": "games", "场景：": "scenes", "NPC：": "npcs", "功能：": "functions", "资源：": "resources", "NEW：": "new"}


def read_swf(path):
    buttons, sprites, texts, tpos, named = {}, {}, {}, {}, []
    cur = None
    for ev, el in ET.iterparse(path, events=("start", "end")):
        t = el.get("type")
        if ev == "start":
            if t == "DefineButton2Tag":
                cur = ("b", int(el.get("buttonId")))
                buttons[cur[1]] = []
            elif t == "DefineSpriteTag":
                cur = ("s", int(el.get("spriteId")))
                sprites[cur[1]] = []
            continue
        if t == "DefineEditTextTag":
            txt = re.sub(r"<br\s*/?>|</p>", " ", el.get("initialText") or "")
            txt = html.unescape(re.sub(r"<[^>]+>", "", txt)).replace("\xa0", " ").strip()
            cid = int(el.get("characterID"))
            texts[cid] = txt
            b = el.find("bounds")
            tpos[cid] = (int(b.get("Xmin", 0)) / 20, int(b.get("Ymin", 0)) / 20) if b is not None else (0, 0)
        elif t == "BUTTONRECORD" and cur and cur[0] == "b":
            m = el.find("placeMatrix")
            x, y = (int(m.get("translateX", 0)) / 20, int(m.get("translateY", 0)) / 20) if m is not None else (0, 0)
            buttons[cur[1]].append((int(el.get("characterId")), el.get("buttonStateOver") == "true", x, y))
        elif t in ("PlaceObject2Tag", "PlaceObject3Tag") and cur and cur[0] == "s" and el.get("characterId"):
            m = el.find("matrix")
            x, y = (int(m.get("translateX", 0)) / 20, int(m.get("translateY", 0)) / 20) if m is not None else (0, 0)
            sprites[cur[1]].append((int(el.get("characterId")), x, y))
            if (el.get("name") or "").startswith("btn_"):
                named.append((el.get("name")[4:], int(el.get("characterId"))))
        if t in ("DefineButton2Tag", "DefineSpriteTag"):
            cur = None
        if t and t.endswith("Tag") and t not in ("PlaceObject2Tag", "PlaceObject3Tag"):
            el.clear()
    return buttons, sprites, texts, tpos, named


def fields_of(ch, x, y, swf, out, depth=0):
    buttons, sprites, texts, tpos, _ = swf
    if depth > 8:
        return
    if ch in texts:
        bx, by = tpos[ch]
        out.add((round(y + by), round(x + bx), texts[ch]))
        return
    for c, cx, cy in sprites.get(ch, []):
        fields_of(c, x + cx, y + cy, swf, out, depth + 1)
    for c, over, cx, cy in buttons.get(ch, []):
        if over:
            fields_of(c, x + cx, y + cy, swf, out, depth + 1)


def split_names(s, names):
    out = []
    for part in s.split():
        while part:
            m = max((n for n in names if part.startswith(n)), key=len, default=None)
            if m is None:
                out.append(part)
                break
            out.append(m)
            part = part[len(m):]
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--xml", required=True)
    ap.add_argument("--dict", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    names = set(re.findall(r'new PetDictionaryDataItem\("\d+","([^"]+)"', open(a.dict, encoding="utf-8").read()))
    swf = read_swf(a.xml)
    places = {}
    for place, ch in swf[4]:
        if place in places:
            continue
        fs = set()
        fields_of(ch, 0, 0, swf, fs)
        fs = sorted(fs)
        info = {"title": "", "fields": [list(f) for f in fs]}
        labels = [f for f in fs if any(f[2].startswith(l) for l in LABELS)]
        used = set()
        for ly, lx, lt in labels:
            lab = next(l for l in LABELS if lt.startswith(l))
            key = LABELS[lab]
            vals = [lt[len(lab):].strip()]
            for y, x, t in fs:
                if (y, x, t) in labels or (y, x, t) in used:
                    continue
                if abs(y - ly) <= 8 and x > lx:
                    vals.append(t)
                    used.add((y, x, t))
            value = " ".join(v for v in vals if v)
            if key in ("pets", "rare"):
                info[key] = split_names(value, names)
            elif key in ("games", "scenes", "npcs"):
                info[key] = value.split()
            else:
                info[key] = value
        rest = [t for y, x, t in fs if (y, x, t) not in used and (y, x, t) not in labels]
        info["title"] = rest[0] if rest else ""
        info["other"] = rest[1:]
        places[place] = info
    json.dump(places, open(a.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    for p, i in places.items():
        if i.get("pets") or i.get("rare") or i.get("games"):
            print(f"{p} {i['title']}: 亚比 {i.get('pets', [])} 稀有 {i.get('rare', [])} 小游戏 {i.get('games', [])} | other {i['other']}")


if __name__ == "__main__":
    main()
