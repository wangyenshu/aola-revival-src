#!/usr/bin/env python3
"""Generate the catalog-book configuration of the January 2013 client.

The 2013 book list (which pages each shop catalog had) is lost. The live
client keeps the current one embedded in config/config.swf (mmo.config.
ConfigEmbed, binary "bconfig"), naming for each catalog its page files
(file prefix + number) and the classes inside them. This keeps every
catalog/book of that list, but builds its page list from the era page files
that are in mirror/ (uploaded by 25 Jan 2013): every page class each such
file defines (e.g. mmo.dress.Clothes51_1), newest file first as the live
list orders them; cover pages (file 1) are kept from the live list (with
--game, only when game/ has the cover's file). Pages
whose file is not an era file are left out, so later clothes are not sold.

  tools/gen_bconfig.py --bconfig tools/data/live-bconfig.xml --mirror mirror \\
      --game game --materials rebuild/static/www.9aola.com/revival/materials.json \\
      --pets build/rebuilt/www.9aola.com/revival/pets.json --out rebuild/gen/bconfig

With --game and --materials, page files that are in game/ but not in the
mirror (copies taken from the live server later, tools/add_later.py, for
books whose 2013 pages the archive lacks: the 道具, 家具, 种植 and 射击卡
books) count too, when every item they sell (buttons btnBuy_<type>_<id>) is
in the 2013 material data and they sell something: a page selling anything
newer than January 2013 is a later page and stays out. The guide books
(GUIDES, the 超进化手册) sell nothing: their pages from game/ count when every
道具 and 亚比 their tips name (tipsItem_<id>, tipsPet_<race>) is in the 2013
material data and, with --pets, in the 2013 亚比 list.
(tools/data/live-bconfig.xml is the live list: ConfigEmbed_bconfigClass.bin.)
"""
from __future__ import annotations

import argparse
import json
import glob
import lzma
import os
import re
import zlib
import xml.etree.ElementTree as ET

HOST = "www.9aola.com"

# Pages brought to the front of their book (behind its covers): the 家具店's
# 迷幻星域故事书 tells of the 迷幻星域 room, which the 家具商品册 sells on
# jiaju30 (1/173), the eighteenth page in the live list's order (REVIVAL choice).
FEATURED = {"catalog201003": [(30, 1)]}

# Books that only tell (no 购买): the 超进化手册 (超进化方程式, its 亚比 and 道具 as tips).
GUIDES = {"book201103"}


def swf_body(b: bytes) -> bytes:
    if b[:3] == b"FWS":
        return b
    if b[:3] == b"CWS":
        return zlib.decompress(b[8:])
    if b[:3] == b"ZWS":
        d = lzma.LZMADecompressor(lzma.FORMAT_RAW, filters=[{"id": lzma.FILTER_LZMA1, "dict_size": 1 << 24, "lc": 3, "lp": 0, "pb": 2}])
        return d.decompress(b[17:])
    return b""


def era_pages(mirror: str, file_prefix: str, class_prefix: str, accept=None) -> list[tuple[int, int]]:
    """(file number, page number) for each page class in era page files.
    accept(n, body): whether to take page file n (default: all)."""
    out = []
    base = os.path.join(mirror, HOST, *file_prefix.split("/"))
    pat = re.compile(re.escape(class_prefix).encode() + rb"(\d+)_(\d+)")
    for f in glob.glob(glob.escape(base) + "[0-9]*.swf*"):
        m = re.match(re.escape(os.path.basename(base)) + r"(\d+)\.swf", os.path.basename(f))
        if not m:
            continue
        n = int(m.group(1))
        try:
            body = swf_body(open(f, "rb").read())
        except Exception:
            continue
        if accept is not None and not accept(n, body):
            continue
        pages = sorted({int(p) for fn, p in pat.findall(body) if int(fn) == n})
        out += [(n, p) for p in pages]
    return out


def sells_2013(materials: dict):
    """accept() for page files taken later: they sell something, and only 2013 materials."""
    def accept(n: int, body: bytes) -> bool:
        ids = set(re.findall(rb"btnBuy_(\d+)_(\d+)", body))
        return bool(ids) and all(i.decode() in materials.get(t.decode(), {}) for t, i in ids)
    return accept


def names_2013(materials: dict, pets: dict | None):
    """accept() for guide pages taken later: no 购买, and every 道具 and 亚比 they name is of 2013."""
    def accept(n: int, body: bytes) -> bool:
        if b"btnBuy_" in body:
            return False
        items = {i.decode() for i in re.findall(rb"tipsItem_(\d+)", body)}
        races = {r.decode() for r in re.findall(rb"tipsPet_(\d+)", body)}
        return bool(items or races) and items <= set(materials.get("2", {})) and (pets is None or races <= set(pets))
    return accept


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--bconfig", required=True)
    ap.add_argument("--mirror", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--game", help="game/: page files added from the live server count too (with --materials)")
    ap.add_argument("--materials", help="revival/materials.json, the 2013 material data")
    ap.add_argument("--pets", help="revival/pets.json, the 2013 亚比 (for the guide books' pages)")
    a = ap.parse_args(argv)
    later = guide = None
    if a.game and a.materials:
        mats = json.load(open(a.materials, encoding="utf-8"))
        later = sells_2013(mats)
        guide = names_2013(mats, json.load(open(a.pets, encoding="utf-8")) if a.pets else None)
    text = open(a.bconfig, encoding="utf-8-sig").read()
    root = ET.fromstring(text)
    kept = dropped = 0
    for group in ("catalogs", "books", "doodles"):
        g = root.find(group)
        if g is None:
            continue
        for el in list(g):
            f, t = el.get("f", ""), el.get("t", "")
            live = [tuple(int(x) for x in p.split(",")) for p in el.get("p", "").split(";") if "," in p]
            era = era_pages(a.mirror, f, t) if t else []
            from_mirror = bool(era)
            if later is not None and t:
                have = {n for n, _ in era}
                era += [p for p in era_pages(a.game, f, t, guide if el.get("no") in GUIDES else later) if p[0] not in have]
            era_files = {n for n, _ in era}
            # The cover (file 1) from the live list, when game/ has its file at all.
            have_cover = not a.game or glob.glob(glob.escape(os.path.join(a.game, HOST, *f.split("/"))) + "1.swf*")
            covers = [p for p in live if p[0] == 1 and 1 not in era_files and have_cover]
            pages = covers + sorted(era, key=lambda p: (-p[0], p[1]))
            if era and not from_mirror:
                # A book only of pages taken later: in the live list's order (scenes open
                # its pages by index), pages it no longer lists after them.
                pages = [p for p in live if p in pages] + [p for p in pages if p not in live]
            # A page the shop's own scene points to, brought forward behind the covers.
            for fp in FEATURED.get(el.get("no", ""), []):
                if fp in pages:
                    pages.remove(fp)
                    pages.insert(len([p for p in pages if p[0] == 1]), fp)
            if not pages:
                g.remove(el)
                dropped += 1
                continue
            el.set("p", ";".join(f"{n},{p}" for n, p in pages))
            kept += 1
    # 奥拉周刊: WeeklyService opened the issue config.xml names (<weekly>) as a
    # catalog of this list, and the library shows the back issues. The live
    # list no longer has the weeklies, so each issue with page files in
    # mirror/ or game/ becomes one, from whichever of its forms holds the
    # most pages (tools/weeklies.py takes them from the live server):
    #   weekly/aolaweeklyN.swf, the whole issue in one file (issues 1–22),
    #     pages mmo.weekly._NPage_<p> ("p" entries alone, as the era CatalogInfo reads them);
    #   weekly/weeklyN/aolaweeklyN_<k>.swf, pages mmo.weekly.weeklyN._NPage<k>_<p>
    #     (or mmo.weekly._NPage<k>_<p>: issues 50, 51);
    #   weekly/aolaweeklyN_<k>.swf, pages mmo.weekly._NPage<k>_<p>, as config.xml's weekly1.
    # Every page of every file (a file may hold several: issues 5–8, 21–49);
    # but in issues 1–4 file 1 is the whole issue again, so one page a file
    # there. Its numbers also go to rebuild/gen/weekly for WeeklyService.
    issues = []
    cats = root.find("catalogs")
    roots = [a.mirror] + ([a.game] if a.game else [])
    numbers = set()
    for r in roots:
        for d in glob.glob(os.path.join(r, HOST, "weekly", "weekly[0-9]*")):
            if os.path.isdir(d):
                numbers.add(int(re.sub(r"\D", "", os.path.basename(d))))
        for f in glob.glob(os.path.join(r, HOST, "weekly", "aolaweekly[0-9]*.swf*")):
            numbers.add(int(re.match(r"aolaweekly(\d+)", os.path.basename(f)).group(1)))

    def whole_pages(n: int) -> list[int]:
        pat = re.compile(rf"mmo\.weekly\._{n}Page_(\d+)".encode())
        for r in roots:
            for f in glob.glob(glob.escape(os.path.join(r, HOST, "weekly", f"aolaweekly{n}")) + ".swf*"):
                try:
                    return sorted({int(p) for p in pat.findall(swf_body(open(f, "rb").read()))})
                except Exception:
                    continue
        return []

    for n in sorted(numbers):
        options = []
        whole = whole_pages(n)
        if whole:
            options.append((len(whole), f"weekly/aolaweekly{n}", f"mmo.weekly._{n}Page", ";".join(map(str, whole))))
        for f, t in ((f"weekly/weekly{n}/aolaweekly{n}_", f"mmo.weekly.weekly{n}._{n}Page"),
                     (f"weekly/weekly{n}/aolaweekly{n}_", f"mmo.weekly._{n}Page"),
                     (f"weekly/aolaweekly{n}_", f"mmo.weekly._{n}Page")):
            pages: set[tuple[int, int]] = set()
            for r in roots:
                pages.update(era_pages(r, f, t))
            if n <= 4:
                first: dict[int, int] = {}
                for k, m in pages:
                    first[k] = min(m, first.get(k, m))
                pages = set(first.items())
            if pages:
                options.append((len(pages), f, t, ";".join(f"{k},{m}" for k, m in sorted(pages))))
        if not options or cats is None:
            continue
        # The most pages; on a tie the paged files (listed after the whole issue).
        best = max(enumerate(options), key=lambda io: (io[1][0], io[0]))[1]
        ET.SubElement(cats, "catalog", {"no": f"weekly{n}", "n": f"奥拉周刊第{n}期", "f": best[1], "t": best[2], "p": best[3]})
        issues.append(n)
        kept += 1
    wpkg = os.path.join(a.out, "..", "weekly", "mmo", "weekly")
    os.makedirs(wpkg, exist_ok=True)
    open(os.path.join(wpkg, "WeeklyIssues.as"), "w", encoding="utf-8").write(
        "package mmo.weekly\n{\n   /** GENERATED by tools/gen_bconfig.py: the 奥拉周刊 issues with era pages (catalog books weekly<n>). */\n"
        "   public class WeeklyIssues\n   {\n      public static const ISSUES:Array = [" + ", ".join(map(str, issues)) + "];\n   }\n}\n")
    xml = ET.tostring(root, encoding="unicode")
    pkg = os.path.join(a.out, "mmo", "reader")
    os.makedirs(pkg, exist_ok=True)
    open(os.path.join(pkg, "BConfigData.as"), "w", encoding="utf-8").write(
        "package mmo.reader\n{\n   /** GENERATED by tools/gen_bconfig.py: catalog books with their era pages. */\n"
        "   public class BConfigData\n   {\n      public static const BCONFIG:XML = " + xml + ";\n   }\n}\n")
    print(f"{kept} books kept, {dropped} without era pages -> {pkg}")


if __name__ == "__main__":
    main()
