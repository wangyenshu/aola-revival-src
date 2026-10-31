#!/usr/bin/env python3
"""The start screen without its advertising (REBUILT from the January 2013 art).

The start screen of the January 2013 client is user/yunyingstart.swf (the
frame: 开始, 注册多多号, 收藏奥拉星, 家长须知, and a row of links to 百田's other
games) over user/yunyingres.swf (the 运营 picture, changed with each
campaign: in January 2013 "100级绝版大回归" with captions selling 黑炎龙 and
神武月). No earlier picture survives: both are Wayback captures of the
January 2013 files, and every version the live CDN has is later still. This
keeps the art and takes out the campaign: the big title and the captions of
YunYingRes (their placements in sprite 154), and moves the links to the other
games out of sight (the start screen's code still finds the buttons by name).
Run by rebuild/build/all.sh with FFDec (swf2xml / xml2swf); nothing is
downloaded.

  tools/clean_start.py --ffdec ffdec.jar --res <yunyingres.swf> --start <yunyingstart.swf> --out-res <swf> --out-start <swf>
"""
from __future__ import annotations

import argparse
import os
import subprocess
import tempfile
import xml.etree.ElementTree as ET

# YunYingRes (sprite 154): depths of the campaign's title (100级绝版 / 大回归) and the
# flames behind it, and of the three captions with their bars and pictures.
RES_SPRITE = "154"
RES_DEPTHS = {"179", "193", "300", "302", "303", "305", "306", "349", "351", "352", "383"} | {str(d) for d in range(163, 178, 2)}
# ... and the shine that sweeps over the title (depth 293, sprite 153) and the burst it opens with (209, sprite 149).
RES_DEPTHS |= {"209", "293"}
# YunYing (the frame): the links to 奥比岛, 奥拉星's site, 龙斗士, 奥雅之光, 奥奇传说 and 百田.
START_HIDE = {"btnaobi", "btnaola", "btnlds", "btnaoya", "btnaoqi", "btnbt"}


def ffdec(jar: str, *args: str) -> None:
    subprocess.run(["java", "-jar", jar, *args], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def clean_res(tree: ET.ElementTree) -> int:
    n = 0
    for sprite in tree.iter("item"):
        if sprite.get("type") != "DefineSpriteTag" or sprite.get("spriteId") != RES_SPRITE:
            continue
        for sub in sprite.iter("subTags"):
            for item in list(sub):
                t = item.get("type", "")
                if (t.startswith("PlaceObject") or t.startswith("RemoveObject")) and item.get("depth") in RES_DEPTHS:
                    sub.remove(item)
                    n += 1
    return n


def clean_start(tree: ET.ElementTree) -> int:
    n = 0
    for item in tree.iter("item"):
        if item.get("type", "").startswith("PlaceObject") and item.get("name") in START_HIDE:
            m = item.find("matrix")
            if m is not None:
                m.set("translateX", "400000")
                m.set("nTranslateBits", "21")
                n += 1
    return n


def run(jar: str, src: str, dst: str, edit) -> int:
    with tempfile.TemporaryDirectory() as d:
        x = os.path.join(d, "swf.xml")
        ffdec(jar, "-swf2xml", src, x)
        tree = ET.parse(x)
        n = edit(tree)
        tree.write(x, encoding="utf-8", xml_declaration=True)
        os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
        ffdec(jar, "-xml2swf", x, dst)
    return n


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ffdec", required=True)
    ap.add_argument("--res", required=True)
    ap.add_argument("--start", required=True)
    ap.add_argument("--out-res", required=True)
    ap.add_argument("--out-start", required=True)
    a = ap.parse_args(argv)
    n1 = run(a.ffdec, a.res, a.out_res, clean_res)
    n2 = run(a.ffdec, a.start, a.out_start, clean_start)
    print(f"start screen: {n1} placements of the campaign taken out, {n2} links moved away")


if __name__ == "__main__":
    main()
