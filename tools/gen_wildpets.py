#!/usr/bin/env python3
"""Generate the wild 亚比 of the revival: which 亚比 walk in which scene, where,
at what level, and which battle background each scene uses.

The 2013 server's list of wild 亚比 per scene (the reply to PetClient2 54_7
GetLocationPetInfo, {pms: [{raceId, min, max, common, rate}]}) is lost, and so
is the 2013 pet/wildpetservice with its table of places. What survives:

  pet/petdictionarydata  each species' 获得方式 text ("…可在费尔区的火山山口、
                         烈焰洞穴捕捉到。"), its scene field and its rarity flag
                         (gen_pets.py -> rebuild/gen/petdict/…/PetDictionaryData.as)
  config.xml (Jan 2013)  the era scenes and their names (<r nm=… desc=…/>)
  pmdata.json            catch values ("NA" = cannot be caught) and evolution
                         levels (gen_pmdata.py)
  later wildpetservice   WildPetLocationMap: four walking points per scene; the
                         era scenes are the same SWFs, so their points still fit
  later petfightnew      GetBackgroundUtil: scene -> battle background class and
                         file; only files of the era mirror are kept

The levels are RECONSTRUCTED (the 2013 numbers are lost): a base form appears
at about its 捕获度 (the catch value, which grows with the region), an evolved
form from a little below the level it evolves at, a rare one a little higher.

Written (百田's data, so into the rebuilt root and rebuild/gen, not git):

  <rebuilt>/www.9aola.com/revival/wildpets.json
      {"<scene>": [{"raceId", "min", "max", "common" (0 rare), "rate" (% for rares)}]}
  <gen>/wildpet/mmo/wildpet/WildPetLocationMap.as      scene -> [Point x4]
  <gen>/petfight/mmo/petfightnew/BackgroundMap.as      scene -> [class, file]

  tools/gen_wildpets.py --dict rebuild/gen/petdict/mmo/pet/petdictionarydata/PetDictionaryData.as \\
      --pmdata rebuilt/www.9aola.com/revival/pmdata.json --config mirror/www.9aola.com/config.xml%3F201301241 \\
      --locations livesrc/pet__wildpetservice/scripts/mmo/wildpet/WildPetLocationMap.as \\
      --backgrounds livesrc/pet__petfightnew/scripts/mmo/petfightnew/common/util/GetBackgroundUtil.as \\
      --mirror mirror --gen rebuild/gen --json rebuilt/www.9aola.com/revival/wildpets.json \\
      --map tools/data/map-places-2012.json --extra tools/data/wildpets-extra.json

  --config is the revival's config overlay (rebuild/static/www.9aola.com/config.xml%3F201301241),
  which has the January 2013 rooms and the 2011-12 story rooms tools/story_files.py added.
  --extra (tools/data/wildpets-extra.json) gives the 亚比 of rooms no surviving table covers
  (风暴星系; researched, see its _doc): applied last, an entry replaces the generated one, a room
  may bring its own walking points, and a room of scripted fights only is kept for their levels.
"""
from __future__ import annotations

import argparse
import json
import os
import re

STR = re.compile(r'"((?:[^"\\]|\\.)*)"')
RARE_RATE = 5


def rooms(config: str) -> dict[str, str]:
    text = open(config, encoding="utf-8").read()
    out = {}
    for r in re.findall(r"<r [^>]*/>", text):
        d = dict(re.findall(r'(\w+)="([^"]*)"', r))
        if d.get("nm"):
            out[d["nm"]] = d.get("desc", "")
    return out


def locations(path: str) -> dict[str, list[tuple[int, int]]]:
    out = {}
    for m in re.finditer(r'locations\["(\w+)"\]\s*=\s*\[(.*?)\];', open(path, encoding="utf-8").read()):
        out[m.group(1)] = [(int(x), int(y)) for x, y in re.findall(r"new Point\((-?\d+),\s*(-?\d+)\)", m.group(2))]
    return out


def backgrounds(path: str, mirror: str) -> dict[str, tuple[str, str]]:
    files = os.path.join(mirror, "FILES.jsonl")
    if os.path.exists(files):
        # game/: era files only (FILES.jsonl origin)
        have = set()
        for line in open(files, encoding="utf-8"):
            r = json.loads(line)
            m = re.match(r"www\.9aola\.com/petfightbackground/(\w+)\.swf", r["path"])
            if m and r["origin"] != "later":
                have.add(m.group(1))
    else:
        have = {f.split(".swf")[0] for f in os.listdir(os.path.join(mirror, "www.9aola.com", "petfightbackground"))}
    out = {}
    for scene, cls, f in re.findall(r'backs\["(\w+)"\]\s*=\s*\["([\w.]+)","petfightbackground/(\w+)"\]', open(path, encoding="utf-8").read()):
        if f in have:
            out[scene] = (cls, "petfightbackground/" + f)
    return out


def chain_levels(evo: str, race: str) -> tuple[int, int | None]:
    """(level it is reached at, level it evolves at) from "0-22#16-23#32-24"."""
    steps = [tuple(int(x) for x in s.split("-")) for s in evo.split("#") if re.match(r"^\d+-\d+$", s)]
    for i, (lv, rid) in enumerate(steps):
        if str(rid) == race:
            return lv, (steps[i + 1][0] if i + 1 < len(steps) else None)
    return 0, None


def level_range(sp: dict, race: str, rare: bool) -> tuple[int, int]:
    catch = int(sp["c"][0]) if str(sp["c"][0]).isdigit() else 1
    reached, evolves = chain_levels(sp.get("evo", ""), race)
    lo = max(1, catch)
    if reached > 0:
        lo = max(lo, reached - 2)
    if evolves:
        lo = min(lo, max(1, evolves - 6))
    if rare:
        lo = max(lo, 10)
    hi = lo + (3 if lo < 10 else 4)
    return lo, hi


def from_map(places: dict, wild: dict, era_rooms: dict, points: dict, species: dict, dict_path: str) -> int:
    """Every 亚比 and rare 亚比 the November 2012 world map names for a place
    walks in that place's scenes: in those its 获得方式 names, else in all of
    them (the place's rooms: <place><n>, and those the map lists under 场景)."""
    info = {}
    for line in open(dict_path, encoding="utf-8"):
        m = re.match(r'\s*"(\d+)":new PetDictionaryDataItem\((.*)\),?\s*$', line)
        if m:
            p = STR.findall(m.group(2))
            info.setdefault(p[1], (m.group(1), p[10] if len(p) > 10 else ""))
    added = 0
    for place, d in places.items():
        base = re.sub(r"\d+$", "", place)
        # (Scenes without walking points of the later client get points from their obstruction, WildPetService.)
        scenes = [n for n in era_rooms if re.match(re.escape(base) + r"\d*$", n)]
        scenes += [n for n, desc in era_rooms.items() if desc in d.get("scenes", []) and n not in scenes]
        if not scenes:
            continue
        for rare, names in ((False, d.get("pets", [])), (True, d.get("rare", []))):
            for name in names:
                if name not in info:
                    continue
                race, way = info[name]
                sp = species.get(race)
                if sp is None:
                    continue
                if any(race in wild.get(s, {}) for s in scenes):
                    continue
                named = [s for s in scenes if era_rooms[s] and era_rooms[s] in way]
                for s in named or scenes:
                    lo, hi = level_range(sp, race, rare)
                    wild.setdefault(s, {})[race] = {"raceId": int(race), "min": lo, "max": hi, "common": 0 if rare else 1,
                                                    "rate": RARE_RATE if rare else 0}
                added += 1
        # A scene with only rares shows nothing: the place's common 亚比 walk there too.
        for sc in scenes:
            here = wild.get(sc, {})
            if here and not any(e["common"] for e in here.values()):
                for name in d.get("pets", []):
                    race = info.get(name, (None,))[0]
                    sp = species.get(race) if race else None
                    if sp is not None:
                        lo, hi = level_range(sp, race, False)
                        here[race] = {"raceId": int(race), "min": lo, "max": hi, "common": 1, "rate": 0}
    return added


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    for a in ("dict", "pmdata", "config", "locations", "backgrounds", "mirror", "gen", "json"):
        ap.add_argument("--" + a, required=True)
    ap.add_argument("--map", help="the places of the November 2012 world map (tools/map_pets.py)")
    ap.add_argument("--extra", help="tools/data/wildpets-extra.json: researched 亚比 of rooms the tables miss")
    a = ap.parse_args(argv)
    era_rooms = rooms(a.config)
    points = {k: v for k, v in locations(a.locations).items() if k in era_rooms}
    species = json.load(open(a.pmdata, encoding="utf-8"))["species"]
    # Scene names long enough not to match by accident, longest first ("火山山口" before "火山").
    descs = sorted(((d, n) for n, d in era_rooms.items() if n in points and len(d) >= 3), key=lambda x: -len(x[0]))

    wild: dict[str, dict[str, dict]] = {}
    for line in open(a.dict, encoding="utf-8"):
        m = re.match(r'\s*"(\d+)":new PetDictionaryDataItem\((.*)\),?\s*$', line)
        if not m:
            continue
        race, p = m.group(1), STR.findall(m.group(2))
        sp = species.get(race)
        if sp is None or not sp["c"][0].isdigit():
            continue  # not an era species, or one that cannot be caught (bosses)
        way, where, rare = p[10] if len(p) > 10 else "", p[13] if len(p) > 13 else "", len(p) > 8 and p[8] == "1"
        scenes = {s for s in re.split(r"[,#;|]", where) if s in points}
        if "捕捉" in way or "出没" in way or "发现" in way:
            rest = way
            for d, n in descs:
                if d in rest:
                    scenes.add(n)
                    rest = rest.replace(d, "")
        for s in scenes:
            lo, hi = level_range(sp, race, rare)
            wild.setdefault(s, {})[race] = {"raceId": int(race), "min": lo, "max": hi, "common": 0 if rare else 1, "rate": RARE_RATE if rare else 0}

    if a.map:
        added = from_map(json.load(open(a.map, encoding="utf-8")), wild, era_rooms, points, species, a.dict)
        print(f"November 2012 map: {added} 亚比 added to the scenes of their place")

    keep: set[str] = set()
    if a.extra:
        extra = json.load(open(a.extra, encoding="utf-8"))["rooms"]
        for room, d in extra.items():
            for e in d.get("pets", []):
                wild.setdefault(room, {})[str(e["raceId"])] = {k: int(e[k]) for k in ("raceId", "min", "max", "common", "rate")}
            if d.get("points"):
                points[room] = [(int(x), int(y)) for x, y in d["points"]]
            keep.add(room)
        print(f"extra: {sum(len(d.get('pets', [])) for d in extra.values())} 亚比 in {len(extra)} rooms")

    out = {s: sorted(v.values(), key=lambda x: (x["common"] == 0, x["raceId"])) for s, v in sorted(wild.items())}
    # A scene of rares only would show nothing (the generator fills slots with common ones);
    # the extra table's are kept, for the levels of their scenes' own fights.
    out = {s: v for s, v in out.items() if any(x["common"] for x in v) or s in keep}
    os.makedirs(os.path.dirname(a.json), exist_ok=True)
    json.dump(out, open(a.json, "w", encoding="utf-8"), ensure_ascii=False, indent=0)

    d = os.path.join(a.gen, "wildpet", "mmo", "wildpet")
    os.makedirs(d, exist_ok=True)
    rows = "\n".join(
        f'         m["{s}"] = [{", ".join(f"new Point({x},{y})" for x, y in points[s])}];' for s in sorted(out) if s in points
    )
    open(os.path.join(d, "WildPetLocationMap.as"), "w", encoding="utf-8").write(f"""package mmo.wildpet
{{
   import flash.geom.Point;

   /**
    * GENERATED by tools/gen_wildpets.py: where wild 亚比 walk in each era scene
    * (points of the later WildPetLocationMap for the same scene SWFs).
    */
   public class WildPetLocationMap
   {{
      private static var m:Object;

      public static function getLocations(scene:String):Array
      {{
         if (m == null) init();
         var a:Array = m[scene] as Array;
         return a ? a.concat() : null;
      }}

      private static function init():void
      {{
         m = {{}};
{rows}
      }}
   }}
}}
""")

    bgs = backgrounds(a.backgrounds, a.mirror)
    d = os.path.join(a.gen, "petfight", "mmo", "petfightnew")
    os.makedirs(d, exist_ok=True)
    rows = "\n".join(f'         m["{s}"] = ["{c}", "{f}"];' for s, (c, f) in sorted(bgs.items()))
    open(os.path.join(d, "BackgroundMap.as"), "w", encoding="utf-8").write(f"""package mmo.petfightnew
{{
   /**
    * GENERATED by tools/gen_wildpets.py: the battle background of each scene
    * (the later GetBackgroundUtil, kept where the file is in the era mirror).
    */
   public class BackgroundMap
   {{
      private static var m:Object;

      /** [class name, file] of the scene's background, or null. */
      public static function get(scene:String):Array
      {{
         if (m == null) init();
         return m[scene] as Array;
      }}

      private static function init():void
      {{
         m = {{}};
{rows}
      }}
   }}
}}
""")
    n = sum(len(v) for v in out.values())
    print(f"{len(out)} scenes with wild 亚比 ({n} entries), {len(bgs)} backgrounds -> {a.json}, {a.gen}")


if __name__ == "__main__":
    main()
