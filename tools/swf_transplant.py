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

With --add-art SWF=ID (repeatable) another frame exported from the same original SWF is added
the same way as sprite ID; the characters both exports hold are kept once (JPEXS keeps the
original ids), so pieces of one module can be put together.

With --add-sprite ORIG=ID=DIR (repeatable) the sprite ID of the original SWF is added whole, its
own timeline (all its frames) kept: the characters it places come from the frames JPEXS exported
of it into DIR (every *.swf there, original ids kept, each character once).

With --image-shapes every picture (lossless, or JPEG/PNG/GIF) a timeline places directly (PlaceObject3 with
its image flag, as later tools write) becomes a shape filled with that picture,
at the same place, depth and name: Ruffle draws such pictures in an AS3 movie as
a dot, Flash Player drew them.
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
T_PLACE3, T_DEFINESHAPE = 70, 2
T_LOSSLESS = (20, 36)  # DefineBitsLossless 1-2: id, format, width, height
T_JPEGS = (21, 35, 90)  # DefineBitsJPEG2-4: id, (alpha offset, deblock,) JPEG, PNG or GIF data


def jpeg_size(b: bytes) -> tuple[int, int] | None:
    """The width and height of the JPEG, PNG or GIF picture a DefineBitsJPEG2-4 holds."""
    if b[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", b[16:24])
    if b[:4] == b"GIF8":
        return struct.unpack("<HH", b[6:10])
    i = 0
    while i + 9 < len(b):
        # Start of frame (baseline, extended, progressive): FF C0/C1/C2, length, precision, height, width.
        if b[i] == 0xFF and b[i + 1] in (0xC0, 0xC1, 0xC2):
            h, w = struct.unpack(">HH", b[i + 5 : i + 9])
            return w, h
        i += 1
    return None


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


# Tags that define a character (its id first), and tags that only add to one already defined.
T_DEFINES = {2, 22, 32, 83, 6, 21, 35, 90, 20, 36, 10, 48, 75, 91, 11, 33, 37, 39, 7, 34, 46, 84, 60, 14, 87}
T_ABOUT = {73, 88, 74, 78, 13, 17, 23, 62}  # font zones / name, text settings, scaling grid, font / button info
T_SKIP = {T_FILEATTR, T_METADATA, T_SYMBOLCLASS, T_DOABC, T_DOABC1, 9, 65, 41, 43, 58, 64, 24, 8}


def add_art(tags: list[tuple[int, bytes]], extra: Path, cid: int) -> list[tuple[int, bytes]]:
    """
    Add another frame JPEXS exported from the same original SWF (whose character ids it keeps): its
    first frame becomes sprite `cid`, and the characters it needs that `tags` lacks come before the
    first frame of `tags` (a character both have is the same one, and is kept once).
    """
    _, _, more = parse(extra)
    more = wrap_root(more, cid)
    have = {struct.unpack_from("<H", d, 0)[0] for c, d in tags if c in T_DEFINES}
    first = next(i for i, (c, _) in enumerate(more) if c == T_SHOWFRAME)
    adds, added = [], set()
    for c, d in more[:first]:
        if c in T_SKIP or c in T_DISPLAY:
            continue
        ref = struct.unpack_from("<H", d, 0)[0] if len(d) >= 2 else -1
        if c in T_DEFINES:
            if ref in have:
                continue
            have.add(ref)
            added.add(ref)
        elif c in T_ABOUT and ref not in added:
            continue
        adds.append((c, d))
    at = next(i for i, (c, _) in enumerate(tags) if c == T_SHOWFRAME)
    return tags[:at] + adds + tags[at:]


def add_sprite(tags: list[tuple[int, bytes]], orig: Path, cid: int, frames: Path) -> list[tuple[int, bytes]]:
    """
    Add the original's DefineSprite `cid` as it is (all its frames), after the characters it needs
    that `tags` lacks: those of every frame JPEXS exported of it into `frames`.
    """
    have = {struct.unpack_from("<H", d, 0)[0] for c, d in tags if c in T_DEFINES}
    adds, added = [], set()
    for f in sorted(frames.glob("*.swf"), key=lambda x: int(x.stem) if x.stem.isdigit() else 0):
        _, _, more = parse(f)
        first = next(i for i, (c, _) in enumerate(more) if c == T_SHOWFRAME)
        for c, d in more[:first]:
            if c in T_SKIP or c in T_DISPLAY:
                continue
            ref = struct.unpack_from("<H", d, 0)[0] if len(d) >= 2 else -1
            if c in T_DEFINES:
                if ref in have:
                    continue
                have.add(ref)
                added.add(ref)
            elif c in T_ABOUT and ref not in added:
                continue
            adds.append((c, d))
    _, _, otags = parse(orig)
    sprite = next(((c, d) for c, d in otags if c == T_DEFINESPRITE and struct.unpack_from("<H", d, 0)[0] == cid), None)
    if sprite is None:
        raise SystemExit(f"{orig}: no sprite {cid}")
    if cid not in have:
        adds.append(sprite)
    at = next(i for i, (c, _) in enumerate(tags) if c == T_SHOWFRAME)
    return tags[:at] + adds + tags[at:]


class Bits:
    """A big-endian bit writer (RECT, MATRIX and shape records)."""

    def __init__(self) -> None:
        self.bits: list[int] = []

    def u(self, v: int, n: int) -> "Bits":
        self.bits += [(v >> (n - 1 - i)) & 1 for i in range(n)]
        return self

    def s(self, v: int, n: int) -> "Bits":
        return self.u(v & ((1 << n) - 1), n)

    def bytes(self) -> bytes:
        b = self.bits + [0] * (-len(self.bits) % 8)
        return bytes(int("".join(map(str, b[i:i + 8])), 2) for i in range(0, len(b), 8))


def sbits(*vals: int) -> int:
    """Bits a signed field needs to hold every value."""
    return max(max(abs(v) for v in vals).bit_length() + 1, 2)


def bitmap_shape(sid: int, bid: int, w: int, h: int) -> bytes:
    """DefineShape `sid`: a w x h pixel rectangle filled with bitmap `bid` (clipped, not smoothed), as Flash draws a placed picture."""
    W, H = w * 20, h * 20
    n = sbits(W, H)
    rect = Bits().u(n, 5).s(0, n).s(W, n).s(0, n).s(H, n).bytes()
    scale = 20 << 16
    sn = sbits(scale)
    matrix = Bits().u(1, 1).u(sn, 5).s(scale, sn).s(scale, sn).u(0, 1).u(0, 5).bytes()
    fills = bytes([1, 0x43]) + struct.pack("<H", bid) + matrix + bytes([0])  # one fill, no line styles
    r = Bits().u(1, 4).u(0, 4)  # NumFillBits 1, NumLineBits 0
    r.u(0, 1).u(0, 1).u(0, 1).u(1, 1).u(0, 1).u(1, 1)  # style change: fill style 1, move to
    r.u(1, 5).s(0, 1).s(0, 1).u(1, 1)  # move (0, 0); fill style 1 = 1
    eb = sbits(W, H)
    for dx, dy in ((W, 0), (0, H), (-W, 0), (0, -H)):
        r.u(1, 1).u(1, 1).u(eb - 2, 4).u(1, 1).s(dx, eb).s(dy, eb)  # straight edge, general line
    r.u(0, 6)  # end of shape
    return struct.pack("<H", sid) + rect + fills + r.bytes()


def image_shapes(tags: list[tuple[int, bytes]]) -> list[tuple[int, bytes]]:
    """Pictures placed directly (PlaceObject3 image flag) become shapes filled with them."""
    sizes: dict[int, tuple[int, int]] = {}
    top = 0

    def scan(ts: list[tuple[int, bytes]]) -> None:
        nonlocal top
        for c, d in ts:
            if len(d) >= 2 and c not in (T_END, T_SHOWFRAME, T_FILEATTR, T_METADATA, T_SYMBOLCLASS, T_DOABC, T_DOABC1, T_PLACE3, 4, 5, 26, 28, 9, 43):
                top = max(top, struct.unpack_from("<H", d, 0)[0])
            if c in T_LOSSLESS:
                cid, _fmt, w, h = struct.unpack_from("<HBHH", d, 0)
                sizes[cid] = (w, h)
            elif c in T_JPEGS:
                wh = jpeg_size(d[{21: 2, 35: 6, 90: 8}[c]:])
                if wh:
                    sizes[struct.unpack_from("<H", d, 0)[0]] = wh
            if c == T_DEFINESPRITE:
                scan(read_tags(d, 4))

    scan(tags)
    shapes: dict[int, int] = {}

    def fix(ts: list[tuple[int, bytes]]) -> list[tuple[int, bytes]]:
        nonlocal top
        out: list[tuple[int, bytes]] = []
        for c, d in ts:
            if c == T_DEFINESPRITE:
                inner = b"".join(write_tag(ic, idata) for ic, idata in fix(read_tags(d, 4)))
                out.append((c, d[:4] + inner))
                continue
            if c == T_PLACE3 and d[1] & 0x10 and d[0] & 0x02 and not d[1] & 0x08:
                bid = struct.unpack_from("<H", d, 4)[0]
                if bid not in sizes:
                    raise SystemExit(f"a placed picture {bid} is neither a DefineBitsLossless nor a DefineBitsJPEG2-4 (not handled)")
                if bid not in shapes:
                    top += 1
                    shapes[bid] = top
                    defs[bid] = (T_DEFINESHAPE, bitmap_shape(top, bid, *sizes[bid]))
                d = bytes([d[0], d[1] & ~0x10]) + d[2:4] + struct.pack("<H", shapes[bid]) + d[6:]
            out.append((c, d))
        return out

    defs: dict[int, tuple[int, bytes]] = {}
    fixed = fix(tags)
    # Each shape right after its picture (before anything can place it).
    out: list[tuple[int, bytes]] = []
    for c, d in fixed:
        out.append((c, d))
        if (c in T_LOSSLESS or c in T_JPEGS) and struct.unpack_from("<H", d, 0)[0] in defs:
            out.append(defs[struct.unpack_from("<H", d, 0)[0]])
    return out


def transplant(art: Path, code: Path, binds: dict[int, str], note: str, drop_art_abc: bool = False, wrap: int = 0, shapes: bool = False,
               only_binds: bool = False, more: list[tuple[Path, int]] | None = None,
               sprites: list[tuple[Path, int, Path]] | None = None) -> bytes:
    version, header, tags = parse(art)
    if wrap:
        tags = wrap_root(tags, wrap)
    for extra, cid in more or []:
        tags = add_art(tags, extra, cid)
    for orig, cid, frames in sprites or []:
        tags = add_sprite(tags, orig, cid, frames)
    # After the wrap: the new shapes are numbered after every character, the wrapping sprite too.
    if shapes:
        tags = image_shapes(tags)
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
            merged = dict(binds) if only_binds else {**old_binds, **binds}
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
    p.add_argument("--image-shapes", action="store_true", help="pictures placed directly (PlaceObject3 image flag) become shapes filled with them")
    p.add_argument("--only-binds", action="store_true", help="the SymbolClass names only the --bind classes (symbols left unused lose their art class names)")
    p.add_argument("--add-art", action="append", default=[], metavar="SWF=ID",
                   help="with --wrap-root: another frame JPEXS exported from the same original SWF, whose first frame becomes sprite ID")
    p.add_argument("--add-sprite", action="append", default=[], metavar="ORIG=ID=DIR",
                   help="the original SWF's sprite ID whole (all its frames), its characters from the frames JPEXS exported of it into DIR")
    a = p.parse_args(argv)
    binds = {int(k): v for k, v in (b.split("=", 1) for b in a.bind)}
    more = [(Path(x.rsplit("=", 1)[0]), int(x.rsplit("=", 1)[1])) for x in a.add_art]
    sprites = []
    for x in a.add_sprite:
        orig, rest = x.split("=", 1)
        cid, frames = rest.split("=", 1)
        sprites.append((Path(orig), int(cid), Path(frames)))
    data = transplant(Path(a.art), Path(a.code), binds, a.note, a.drop_art_abc, a.wrap_root, a.image_shapes, a.only_binds, more, sprites)
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    Path(a.out).write_bytes(data)
    print(f"wrote {a.out} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
