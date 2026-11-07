#!/usr/bin/env python3
"""Small fixes to era SWFs, made when the site is built.

Code: FFDec decompiles the classes named below, the lines quoted are
replaced, and FFDec compiles the classes back into a copy of the SWF
(-importScript); it can only where the class needs nothing from outside the
SWF. Each line quoted must be found once, or the build stops: nothing is
changed by guess. Pictures: a named child put into a symbol (FFDec swf2xml /
xml2swf). Nothing is downloaded; the files come from game/.

  library/common (January 2013), PanelProxy.dispose: a panel of
      FloatPanelManager that removes itself in its own dispose() (the 2010
      亚比特训 pet/pettraining and pet/petbetraining, the 亚比孵化器
      pet/pethatchegg) went round without end: removeFloatPanel disposes the
      proxy, the proxy disposes the panel, the panel asks removeFloatPanel
      again while the proxy still holds it. Flash stopped the call with a
      stack error; Ruffle stops altogether. The proxy now lets go of the
      panel before it disposes it.
  pet/pettraining (2010), PetWareCard (symbol 3): the card's picture has no
      "iconcontainer" for the 亚比's icon, which the card's code puts the icon
      into (the getChildByName fails, the icon never shows): an empty clip of
      that name at the middle of its frame (the icon is centred on it). The
      class declares no variable of that name: Ruffle says so and keeps the
      clip.

  tools/patch_scripts.py --ffdec ffdec.jar --game <game root> --out-root <site root> [name ...]
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

PROXY_DISPOSE = (
    '''         if(this._window != null)
         {
            this._window.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseClickWindow);
            this._window.removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStage);
            if(this._window is IDispose)
            {
               IDispose(this._window).dispose();
            }
            this._window = null;
         }''',
    '''         var w:DisplayObject = this._window;
         if(w != null)
         {
            w.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseClickWindow);
            w.removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStage);
            this._window = null;
            if(w is IDispose)
            {
               IDispose(w).dispose();
            }
         }''',
)

# name: (file in www.9aola.com/, {class: [(old, new), ...]}, [(sprite id, child name, x, y in twips, depth), ...])
PATCHES: dict[str, tuple[str, dict[str, list[tuple[str, str]]], list[tuple[int, str, int, int, int]]]] = {
    "common": ("library/common.swf%3F130124", {"mmo.common.utils.panel.PanelProxy": [PROXY_DISPOSE]}, []),
    # The frame (sprite 2 at 1.105 x 1.093) spans -20..980 x -14..984 twips: its middle.
    "pettraining": ("pet/pettraining.swf%3F1210", {}, [(3, "iconcontainer", 530, 530, 2)]),
}


def ffdec(jar: str, *args: str) -> None:
    subprocess.run(["java", "-jar", jar, *args], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def patch(jar: str, src: Path, dst: Path, classes: dict[str, list[tuple[str, str]]]) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "dec"
        ffdec(jar, "-selectclass", ",".join(classes), "-export", "script", str(out), str(src))
        imp = Path(tmp) / "imp"
        for cls, edits in classes.items():
            rel = Path("scripts", *cls.split(".")).with_suffix(".as")
            text = (out / rel).read_text(encoding="utf-8")
            for old, new in edits:
                if text.count(old) != 1:
                    sys.exit(f"patch_scripts: {cls} in {src.name}: the line to change is not there once")
                text = text.replace(old, new)
            (imp / rel).parent.mkdir(parents=True, exist_ok=True)
            (imp / rel).write_text(text, encoding="utf-8")
        tmp_out = Path(tmp) / "out.swf"
        ffdec(jar, "-importScript", str(src), str(tmp_out), str(imp))
        # FFDec writes the SWF unchanged when a class does not compile: check each change took.
        chk = Path(tmp) / "chk"
        ffdec(jar, "-selectclass", ",".join(classes), "-export", "script", str(chk), str(tmp_out))
        for cls, edits in classes.items():
            rel = Path("scripts", *cls.split(".")).with_suffix(".as")
            got = (chk / rel).read_text(encoding="utf-8")
            if any(old in got for old, _ in edits):
                sys.exit(f"patch_scripts: {cls} in {src.name} did not compile back")
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(tmp_out, dst)


def add_kids(jar: str, src: Path, dst: Path, kids: list[tuple[int, str, int, int, int]]) -> None:
    """Put an empty clip, named, into each sprite listed (above what it has at that depth)."""
    with tempfile.TemporaryDirectory() as tmp:
        x = Path(tmp) / "swf.xml"
        ffdec(jar, "-swf2xml", str(src), str(x))
        tree = ET.parse(x)
        root = tree.getroot()
        tags = root.find("tags")
        ids = [int(e.get(k)) for e in tree.iter("item") for k in ("spriteId", "shapeId", "characterID", "fontID", "buttonId", "characterId") if e.get(k, "").isdigit()]
        new_id = max(ids) + 1
        for sprite_id, name, tx, ty, depth in kids:
            at = next((i for i, e in enumerate(list(tags)) if e.get("type") == "DefineSpriteTag" and e.get("spriteId") == str(sprite_id)), None)
            if at is None:
                sys.exit(f"patch_scripts: no sprite {sprite_id} in {src.name}")
            host = tags[at]
            sub = host.find("subTags")
            if any(e.get("name") == name for e in sub):
                sys.exit(f"patch_scripts: sprite {sprite_id} of {src.name} has a {name} already")
            if any(e.get("depth") == str(depth) for e in sub):
                sys.exit(f"patch_scripts: depth {depth} of sprite {sprite_id} in {src.name} is taken")
            empty = ET.Element("item", {"type": "DefineSpriteTag", "forceWriteAsLong": "true", "frameCount": "1", "hasEndTag": "true", "spriteId": str(new_id)})
            ET.SubElement(ET.SubElement(empty, "subTags"), "item", {"type": "ShowFrameTag", "forceWriteAsLong": "false"})
            tags.insert(at, empty)
            place = ET.Element("item", {"type": "PlaceObject2Tag", "characterId": str(new_id), "depth": str(depth), "forceWriteAsLong": "true", "name": name,
                                        "placeFlagHasCharacter": "true", "placeFlagHasClipActions": "false", "placeFlagHasClipDepth": "false",
                                        "placeFlagHasColorTransform": "false", "placeFlagHasMatrix": "true", "placeFlagHasName": "true",
                                        "placeFlagHasRatio": "false", "placeFlagMove": "false"})
            ET.SubElement(place, "matrix", {"type": "MATRIX", "hasRotate": "false", "hasScale": "false", "nRotateBits": "0", "nScaleBits": "0",
                                            "nTranslateBits": "16", "translateX": str(tx), "translateY": str(ty)})
            first_show = next(i for i, e in enumerate(list(sub)) if e.get("type") == "ShowFrameTag")
            sub.insert(first_show, place)
            new_id += 1
        tree.write(x, encoding="utf-8", xml_declaration=True)
        dst.parent.mkdir(parents=True, exist_ok=True)
        ffdec(jar, "-xml2swf", str(x), str(dst))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ffdec", required=True)
    ap.add_argument("--game", required=True, help="game root (with www.9aola.com/)")
    ap.add_argument("--out-root", required=True, help="site root the patched copies go to (with www.9aola.com/)")
    ap.add_argument("names", nargs="*", help="which (default: all)")
    a = ap.parse_args()
    for name in a.names or list(PATCHES):
        rel, classes, kids = PATCHES[name]
        src = Path(a.game, "www.9aola.com", rel)
        dst = Path(a.out_root, "www.9aola.com", rel)
        if classes:
            patch(a.ffdec, src, dst, classes)
            src = dst
        if kids:
            add_kids(a.ffdec, src, dst, kids)
        print(f"patched {rel}")


if __name__ == "__main__":
    main()
