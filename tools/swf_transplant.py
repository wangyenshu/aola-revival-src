#!/usr/bin/env python3
"""Put rebuilt ActionScript into an original SWF's artwork.

Some 2013 scenes survive only as later rebuilds, while an older original copy
of the same artwork exists (bigscene/starlandcopy.swf holds the July 2012
奥拉广场). This writes a new SWF that keeps every tag of the art SWF, its
shapes, sprites, sounds and its own bytecode, adds the DoABC tags of a SWF
compiled from rebuilt classes, and rebinds symbols to the rebuilt classes:

  tools/swf_transplant.py --art starlandcopy.swf --code out/starland-code.swf \\
      --bind 0=mmo.scene.starland.Docstarland --bind 225=mmo.scene.starland.Starland \\
      --note "REBUILT starland" --out scene/starland.swf

The art SWF's XMP metadata is replaced by a note saying what was rebuilt, so
the result can never be mistaken for an original by the date checks.

With --wrap-root ID the art SWF's first frame (what it places on its main
timeline) becomes a sprite with that character ID, which --bind can then name:
used with a frame JPEXS exported from an unnamed sprite of an original SWF
(ffdec -selectid N -format sprite:swf -export sprite), so one picture can be
taken out of a module whose code is not wanted.
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from swfinfo import _body  # noqa: E402

T_END, T_SHOWFRAME, T_FILEATTR, T_METADATA, T_SYMBOLCLASS, T_DOABC, T_DOABC1 = 0, 1, 69, 77, 76, 82, 72
T_DEFINESPRITE = 39
T_DISPLAY = (4, 5, 26, 28, 70)  # PlaceObject 1-3, RemoveObject 1-2


def rect_len(body: bytes) -> int:
    nbits = body[0] >> 3
    return (5 + 4 * nbits + 7) // 8


def read_tags(body: bytes, pos: int) -> list[tuple[int, bytes]]:
    tags = []
    while pos < len(body):
        code_len = struct.unpack_from("<H", body, pos)[0]
        pos += 2
        code, ln = code_len >> 6, code_len & 0x3F
        if ln == 0x3F:
            ln = struct.unpack_from("<I", body, pos)[0]
            pos += 4
        tags.append((code, body[pos:pos + ln]))
        pos += ln
        if code == T_END:
            break
    return tags


def write_tag(code: int, data: bytes) -> bytes:
    # Long form always for the tags Flash insists on (DoABC etc. are fine either way).
    if len(data) < 0x3F and code not in (T_DOABC, T_SYMBOLCLASS, T_METADATA):
        return struct.pack("<H", (code << 6) | len(data)) + data
    return struct.pack("<HI", (code << 6) | 0x3F, len(data)) + data


def parse(path: Path) -> tuple[int, bytes, list[tuple[int, bytes]]]:
    data = path.read_bytes()
    body = _body(data)
    rl = rect_len(body)
    header = body[: rl + 4]  # frame rect, rate, count
    return data[3], header, read_tags(body, rl + 4)


def symbol_class(binds: dict[int, str]) -> bytes:
    out = struct.pack("<H", len(binds))
    for cid, name in binds.items():
        out += struct.pack("<H", cid) + name.encode("utf-8") + b"\0"
    return out


def parse_symbol_class(data: bytes) -> dict[int, str]:
    n = struct.unpack_from("<H", data, 0)[0]
    pos, out = 2, {}
    for _ in range(n):
        cid = struct.unpack_from("<H", data, pos)[0]
        end = data.index(b"\0", pos + 2)
        out[cid] = data[pos + 2:end].decode("utf-8")
        pos = end + 1
    return out


def wrap_root(tags: list[tuple[int, bytes]], cid: int) -> list[tuple[int, bytes]]:
    """Move the main timeline's first frame into a new DefineSprite `cid`."""
    first = next(i for i, (c, _) in enumerate(tags) if c == T_SHOWFRAME)
    display = [(c, d) for c, d in tags[:first] if c in T_DISPLAY]
    inner = b"".join(write_tag(c, d) for c, d in display) + write_tag(T_SHOWFRAME, b"") + write_tag(T_END, b"")
    sprite = (T_DEFINESPRITE, struct.pack("<HH", cid, 1) + inner)
    rest = [(c, d) for c, d in tags[:first] if c not in T_DISPLAY]
    out = rest + [sprite] + tags[first:]
    if not any(c == T_SYMBOLCLASS for c, _ in out):
        last = max(i for i, (c, _) in enumerate(out) if c == T_SHOWFRAME)
        out.insert(last, (T_SYMBOLCLASS, symbol_class({})))
    return out


def transplant(art: Path, code: Path, binds: dict[int, str], note: str, drop_art_abc: bool = False, wrap: int = 0) -> bytes:
    version, header, tags = parse(art)
    if wrap:
        tags = wrap_root(tags, wrap)
    _, _, code_tags = parse(code)
    abc = [(c, d) for c, d in code_tags if c in (T_DOABC, T_DOABC1)]
    if not abc:
        raise SystemExit(f"{code}: no DoABC tag")
    xmp = (
        '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
        '<rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">'
        f"<dc:description>{note}</dc:description></rdf:Description></rdf:RDF></x:xmpmeta>"
    ).encode("utf-8")
    out, placed = [], False
    old_binds: dict[int, str] = {}
    for c, d in tags:
        if drop_art_abc and c in (T_DOABC, T_DOABC1):
            continue  # the rebuilt code defines every bound class itself
        if c == T_FILEATTR:
            out.append((c, bytes([d[0] | 0x18]) + d[1:]))  # AS3 + metadata (a JPEXS frame export leaves AS3 unset)
            if not any(t == T_METADATA for t, _ in tags):
                out.append((T_METADATA, xmp))
        elif c == T_METADATA:
            out.append((c, xmp))
        elif c == T_SYMBOLCLASS and not placed:
            old_binds = parse_symbol_class(d)
            merged = {**old_binds, **binds}
            out.extend(abc)
            out.append((c, symbol_class(merged)))
            placed = True
        elif c == T_SYMBOLCLASS:
            out.append((c, d))
        else:
            out.append((c, d))
    if not placed:
        raise SystemExit(f"{art}: no SymbolClass tag to rebind")
    body = header + b"".join(write_tag(c, d) for c, d in out)
    length = 8 + len(body)
    return b"CWS" + bytes([version]) + struct.pack("<I", length) + zlib.compress(body, 9)


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--art", required=True)
    p.add_argument("--code", required=True)
    p.add_argument("--bind", action="append", default=[], help="charId=fully.qualified.Class (0 = main timeline)")
    p.add_argument("--note", default="REBUILT")
    p.add_argument("--out", required=True)
    p.add_argument("--drop-art-abc", action="store_true", help="leave out the art SWF's own bytecode (the code SWF must define every bound class)")
    p.add_argument("--wrap-root", type=int, default=0, metavar="ID", help="make the art SWF's first frame a sprite with this character ID")
    a = p.parse_args(argv)
    binds = {int(k): v for k, v in (b.split("=", 1) for b in a.bind)}
    data = transplant(Path(a.art), Path(a.code), binds, a.note, a.drop_art_abc, a.wrap_root)
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    Path(a.out).write_bytes(data)
    print(f"wrote {a.out} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
