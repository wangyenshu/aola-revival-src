#!/usr/bin/env python3
"""What the surviving 2012/13 code expects from the lost engine classes.

The January 2013 control/control.swf (scene and player engine, package
mmo.play.*) is lost, and the rebuilt engine has to offer whatever the era
originals use. This scans decompiled era SWFs (one directory per SWF, FFDec
"scripts" layout) and reports, per lost class:

  - how many SWFs reference it,
  - members used on it: static (C.x), on the singleton (C.getInstance().x),
    on variables typed C (v.x), and, for classes that originals extend, the
    members subclasses call on themselves (this.x / super.x) or override
    (with the exact signature, which must match),
  - which of those the rebuilt sources do not define yet.

  tools/engine_census.py --decompiled eradec --libs src --rebuilt rebuild/src/control \\
      --package mmo.play --out census.md [--reference livesrc/control__control/scripts]
"""

from __future__ import annotations

import argparse
import collections
import re
from pathlib import Path

DISPLAY_MEMBERS = set("""
x y z width height scaleX scaleY rotation alpha visible name parent stage root mouseX mouseY
mask filters transform cacheAsBitmap blendMode scrollRect opaqueBackground loaderInfo
addChild addChildAt removeChild removeChildAt getChildAt getChildByName getChildIndex setChildIndex
numChildren contains swapChildren swapChildrenAt mouseChildren mouseEnabled tabChildren buttonMode
useHandCursor hitArea graphics dropTarget startDrag stopDrag hitTestObject hitTestPoint getBounds
getRect localToGlobal globalToLocal addEventListener removeEventListener dispatchEvent hasEventListener
willTrigger play stop gotoAndPlay gotoAndStop nextFrame prevFrame currentFrame totalFrames
currentLabel currentLabels framesLoaded addFrameScript doubleClickEnabled focusRect tabEnabled
tabIndex contextMenu soundTransform constructor toString hasOwnProperty enabled trackAsMenu
""".split())


def class_files(root: Path) -> dict[str, Path]:
    out = {}
    for f in root.glob("**/*.as"):
        rel = f.relative_to(root).with_suffix("").parts
        if "scripts" in rel:
            rel = rel[rel.index("scripts") + 1:]
        out[".".join(rel)] = f
    return out


def defined_members(text: str) -> set[str]:
    names = set(re.findall(r"function\s+(?:get\s+|set\s+)?(\w+)\s*\(", text))
    names |= set(re.findall(r"(?:var|const)\s+(\w+)\s*:", text))
    return names


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--decompiled", required=True)
    p.add_argument("--libs", required=True, help="surviving 2013 library decompiles (their classes are not lost)")
    p.add_argument("--rebuilt", required=True, help="rebuilt engine sources")
    p.add_argument("--package", default="mmo.play")
    p.add_argument("--reference", help="a later engine decompile, to quote signatures from")
    p.add_argument("--out", required=True)
    a = p.parse_args(argv)

    lib = set()
    for d in Path(a.libs).iterdir():
        lib |= set(class_files(d))
    rebuilt = class_files(Path(a.rebuilt))
    rebuilt_members = {c: defined_members(f.read_text(encoding="utf-8")) for c, f in rebuilt.items()}
    rebuilt_parent = {}
    for c, f in rebuilt.items():
        t = f.read_text(encoding="utf-8")
        m = re.search(r"class\s+\w+\s+extends\s+(\w+)", t)
        if m:
            imps = {i.split(".")[-1]: i for i in re.findall(r"^\s*import\s+([\w.]+);", t, re.M)}
            rebuilt_parent[c] = imps.get(m.group(1), c.rsplit(".", 1)[0] + "." + m.group(1))
    ref = class_files(Path(a.reference)) if a.reference else {}

    users = collections.defaultdict(set)
    used = collections.defaultdict(lambda: collections.defaultdict(set))  # class -> member -> swfs
    overrides = collections.defaultdict(dict)  # class -> name -> signature
    extended = collections.defaultdict(set)

    for swf in sorted(Path(a.decompiled).iterdir()):
        files = class_files(swf)
        own = set(files)
        for cls, f in files.items():
            text = f.read_text(encoding="utf-8", errors="ignore")
            imports = {i.split(".")[-1]: i for i in re.findall(r"^\s*import\s+([\w.]+);", text, re.M)}
            lost = {s: q for s, q in imports.items() if q.startswith(a.package + ".") and q not in lib and q not in own}
            if not lost:
                continue
            for s, q in lost.items():
                users[q].add(swf.name)
                for m in re.findall(rf"\b{s}\.getInstance\(\)\.(\w+)", text):
                    used[q][m].add(swf.name)
                for m in re.findall(rf"\b{s}\.(\w+)", text):
                    if m != "getInstance":
                        used[q][m].add(swf.name)
                for v in set(re.findall(rf"(\w+)\s*:\s*{s}\b", text)):
                    for m in re.findall(rf"\b{re.escape(v)}\.(\w+)", text):
                        used[q][m].add(swf.name)
            ext = re.search(r"class\s+\w+\s+extends\s+(\w+)", text)
            if ext and ext.group(1) in lost:
                base = lost[ext.group(1)]
                extended[base].add(swf.name)
                mine = defined_members(text)
                for m in set(re.findall(r"\b(?:this|super)\.(\w+)", text)):
                    if m not in mine and m not in DISPLAY_MEMBERS:
                        used[base][m].add(swf.name)
                for sig in re.findall(r"override\s+((?:protected|public|internal)\s+function\s+(?:get\s+|set\s+)?(\w+)\s*\([^)]*\)\s*:\s*[\w.*]+)", text):
                    overrides[base].setdefault(sig[1], re.sub(r"\s+", " ", sig[0]))
                    used[base][sig[1]].add(swf.name)

    lines = [f"# Engine census: {a.package}.* as used by {len(list(Path(a.decompiled).iterdir()))} era SWFs", ""]
    lines.append("| class | SWFs | extended by | members used | missing in rebuild |")
    lines.append("| --- | ---: | ---: | ---: | --- |")
    detail = []
    for q in sorted(users, key=lambda k: -len(users[k])):
        have = rebuilt_members.get(q)
        members = used[q]
        # members a subclass inherits from a rebuilt base count as present
        def present(m: str) -> bool:
            c = q
            while c in rebuilt_members:
                if m in rebuilt_members[c]:
                    return True
                c = rebuilt_parent.get(c)
            return m in DISPLAY_MEMBERS and have is not None
        missing = sorted((m for m in members if not present(m)), key=lambda m: -len(members[m]))
        status = "class missing" if have is None else (", ".join(missing[:12]) + (" …" if len(missing) > 12 else "") or "—")
        lines.append(f"| `{q}` | {len(users[q])} | {len(extended[q]) or ''} | {len(members)} | {status} |")
        if missing or have is None:
            detail.append(f"\n## {q}\n")
            for m in missing or sorted(members, key=lambda m: -len(members[m])):
                sig = overrides[q].get(m, "")
                refsig = ""
                if q in ref and not sig:
                    rt = ref[q].read_text(encoding="utf-8", errors="ignore")
                    mm = re.search(rf"((?:public|protected)\s+(?:static\s+)?(?:function\s+(?:get\s+|set\s+)?{m}\s*\([^)]*\)\s*:\s*[\w.*<>]+|(?:var|const)\s+{m}\s*:\s*[\w.*<>]+))", rt)
                    refsig = f" — later engine: `{re.sub(chr(10), ' ', mm.group(1))}`" if mm else ""
                detail.append(f"- `{m}` ×{len(members[m])}" + (f" — override: `{sig}`" if sig else refsig)
                              + f" ({', '.join(sorted(members[m])[:3])}{'…' if len(members[m]) > 3 else ''})")
    Path(a.out).write_text("\n".join(lines + detail) + "\n", encoding="utf-8")
    print(f"{len(users)} lost classes referenced; report in {a.out}")


if __name__ == "__main__":
    main()
