#!/usr/bin/env python3
"""The cover of 蚁族的反击 (cover.jpg, shown while the exported game loads): 蚁神巨像 (fbsiwude9's
background), the 兵蚁 and the 工蚁 (their battle figures, drawn three times larger by FFDec),
the title, and whose the art is. The game's files are read from game/; nothing is downloaded.

  python3 art/make_cover.py --ffdec <ffdec.jar>
"""
import argparse
import glob
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[4] / "game" / "www.9aola.com"
OUT = HERE.parent / "cover.jpg"
W, H = 960, 560
# (what, file, sprite id): the background of 蚁神巨像, the 兵蚁's and the 工蚁's standing figures.
PARTS = [("f9", "scene/fbsiwude9.swf%3F1210", 95, 1), ("p216", "fightassets/pet216.swf%3F1210", 122, 3), ("p217", "fightassets/pet217.swf%3F1210", 110, 3)]

ap = argparse.ArgumentParser()
ap.add_argument("--ffdec", required=True)
args = ap.parse_args()
tmp = tempfile.TemporaryDirectory()
D = tmp.name + "/"
for name, rel, sid, zoom in PARTS:
    subprocess.run(["java", "-jar", args.ffdec, "-format", "sprite:png", "-zoom", str(zoom), "-selectid", str(sid), "-export", "sprite", D + name, str(GAME / rel)],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def font(weight, size):
    path = f"/usr/share/fonts/opentype/noto/NotoSansCJK-{weight}.ttc"
    # Index 2: the SC face in Noto's collections (JP, KR, SC, TC, HK…); found by name.
    for i in range(10):
        try:
            f = ImageFont.truetype(path, size, index=i)
        except OSError:
            break
        if "SC" in f.getname()[0]:
            return f
    return ImageFont.truetype(path, size)


bg = Image.open(glob.glob(D + "f9/*/1.png")[0]).convert("RGBA")
bg = bg.crop((0, 30, W, 30 + H))
# A little darker at the top and the bottom (the title, the statement), lighter in the middle.
shade = Image.new("RGBA", (W, H))
sd = ImageDraw.Draw(shade)
for y in range(H):
    a = int(150 * max(0, 1 - y / 220) ** 1.6 + 170 * max(0, (y - 400) / 160) ** 1.8)
    sd.line([(0, y), (W, y)], fill=(6, 14, 10, min(255, a)))
img = Image.alpha_composite(bg, shade)


def figure(path, height):
    im = Image.open(glob.glob(path)[0]).convert("RGBA")
    im = im.crop(im.getbbox())
    k = height / im.height
    return im.resize((max(1, int(im.width * k)), height), Image.LANCZOS)


def shadow(im):
    s = Image.new("RGBA", im.size, (0, 0, 0, 0))
    s.putalpha(im.split()[3].point(lambda v: int(v * 0.55)))
    return s.filter(ImageFilter.GaussianBlur(6))


ant = figure(D + "p216/*/1.png", 400)
worker = figure(D + "p217/*/1.png", 300)
# The 工蚁 a step behind on the right, the 兵蚁 in front on the left, both on the floor.
for im, x, y in [(worker, 600, 515 - 300), (ant, 120, 535 - 400)]:
    img.alpha_composite(shadow(im), (x + 10, y + 12))
    img.alpha_composite(im, (x, y))

d = ImageDraw.Draw(img)
title = "蚁族的反击"
tf = font("Black", 92)
tw = d.textlength(title, font=tf)
tx, ty = (W - tw) / 2 + 150, 34
for r in range(10, 0, -2):
    d.text((tx, ty), title, font=tf, fill=(58, 22, 6, 255), stroke_width=r, stroke_fill=(58, 22, 6, 255))
grad = Image.new("RGBA", (int(tw) + 20, 130))
gd = ImageDraw.Draw(grad)
for y in range(130):
    t = y / 129
    c = (255, int(246 - 120 * t), int(200 - 190 * t))
    gd.line([(0, y), (grad.width, y)], fill=c + (255,))
mask = Image.new("L", grad.size)
ImageDraw.Draw(mask).text((10, 0), title, font=tf, fill=255)
img.paste(grad, (int(tx) - 10, ty), mask)
sub = "兵蚁和工蚁，夺回蚁族王朝！"
sf = font("Bold", 24)
d.text(((W - d.textlength(sub, font=sf)) / 2 + 150, 150), sub, font=sf, fill=(236, 248, 222), stroke_width=3, stroke_fill=(20, 40, 20))

# Whose the game's art and music are.
d.rectangle([0, 508, W, H], fill=(4, 16, 10, 200))
l1 = "《奥拉星》及游戏中的美术、音乐、亚比形象等素材，版权归百田网所有。"
l2 = "本作是爱好者制作的非官方模组，仅供交流学习，与百田网无关。"
f1, f2 = font("Medium", 15), font("Regular", 13)
d.text(((W - d.textlength(l1, font=f1)) / 2, 514), l1, font=f1, fill=(226, 236, 218))
d.text(((W - d.textlength(l2, font=f2)) / 2, 536), l2, font=f2, fill=(170, 188, 160))
img.convert("RGB").save(OUT, quality=90, optimize=True)
tmp.cleanup()
print(OUT)
