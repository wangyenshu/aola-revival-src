#!/usr/bin/env python3
"""Give the peticon files without a small picture one made from their large one.

Every peticon/peticon<id>.swf holds three pictures of a 亚比: mmo.pet.peticon<id>_S
(small: the 亚比背包, the 仓库, the battle's list, the era modules' PetIconContainer),
_L (large) and _F (face). For the 亚比 one could not get in 2012 and 2013 (迅猛龙 400,
邪念 605's family and others, given now by the 工具箱) the small one is missing or an
empty sprite, so they showed no picture, and a module asking for the missing class
by name got nothing at all.

For each such file this writes a copy (same name, under --out) that keeps every tag
and adds a sprite placing the file's own _L, scaled to the size of a small picture
(about 40 by 44, feet on the origin like the others), bound to mmo.pet.peticon<id>_S.
Where the class itself is missing, its bytecode is that of a compiled template
(rebuild/src/peticonfill, class mmo.pet.peticon777777_S) with the name changed.
Nothing is downloaded; the files in game/ are left as they are.

  tools/peticon_fill.py --game game --template out/peticonfill-template.swf \\
      --out build/rebuilt/www.9aola.com
"""
from __future__ import annotations

import argparse
import os
import re
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from swf_transplant import parse, parse_symbol_class, read_tags, symbol_class, write_tag  # noqa: E402

T_SHOWFRAME, T_SYMBOLCLASS, T_DOABC, T_METADATA, T_FILEATTR = 1, 76, 82, 77, 69
TEMPLATE_ID = "777777"
# Tags whose first two bytes are the id of the character they define.
DEFINING = {2, 6, 7, 10, 11, 13, 14, 20, 21, 22, 32, 33, 34, 35, 36, 37, 39, 46, 48, 60, 62, 75, 83, 84, 87, 90, 91}
SMALL_W, SMALL_H = 40.0, 44.0


# --- bit-level reading and writing (RECT, MATRIX) ------------------------------------

class Bits:
    def __init__(self, data: bytes, pos: int = 0):
        self.d, self.p = data, pos * 8

    def u(self, n: int) -> int:
        v = 0
        for _ in range(n):
            v = (v << 1) | ((self.d[self.p >> 3] >> (7 - (self.p & 7))) & 1)
            self.p += 1
        return v

    def s(self, n: int) -> int:
        if n == 0:
            return 0
        v = self.u(n)
        return v - (1 << n) if v & (1 << (n - 1)) else v


def write_bits(fields: list[tuple[int, int]]) -> bytes:
    """[(value, nbits)] -> bytes, values written two's complement, padded to a byte."""
    acc, n = 0, 0
    for v, bits in fields:
        acc = (acc << bits) | (v & ((1 << bits) - 1))
        n += bits
    pad = (-n) % 8
    acc <<= pad
    return acc.to_bytes((n + pad) // 8, "big")


def sbits(*vals: int) -> int:
    return max(max(abs(v).bit_length() + 1 for v in vals), 1)


def matrix_bytes(sx: float, sy: float, tx: float, ty: float) -> bytes:
    fx, fy = round(sx * 65536), round(sy * 65536)
    twx, twy = round(tx * 20), round(ty * 20)
    ns, nt = sbits(fx, fy), sbits(twx, twy)
    return write_bits([(1, 1), (ns, 5), (fx, ns), (fy, ns), (0, 1), (nt, 5), (twx, nt), (twy, nt)])


def read_rect(data: bytes, pos: int) -> tuple[float, float, float, float]:
    b = Bits(data, pos)
    n = b.u(5)
    x0, x1, y0, y1 = (b.s(n) / 20 for _ in range(4))
    return x0, x1, y0, y1


def read_matrix(b: Bits) -> tuple[float, ...]:
    sx = sy = 1.0
    r0 = r1 = 0.0
    if b.u(1):
        n = b.u(5)
        sx, sy = b.s(n) / 65536, b.s(n) / 65536
    if b.u(1):
        n = b.u(5)
        r0, r1 = b.s(n) / 65536, b.s(n) / 65536
    n = b.u(5)
    return sx, r0, r1, sy, b.s(n) / 20, b.s(n) / 20


def placed(code: int, d: bytes):
    """(character id, matrix) of a PlaceObject2/3."""
    if code == 26:
        f, p = d[0], 3
    elif code == 70:
        f, f2, p = d[0], d[1], 4
        if f2 & 8 or (f2 & 16 and f & 2):
            p = d.index(b"\0", p) + 1
    else:
        return None, None
    cid = None
    if f & 2:
        cid = struct.unpack_from("<H", d, p)[0]
        p += 2
    m = read_matrix(Bits(d, p)) if f & 4 else None
    return cid, m


# --- bounds of a character's first frame ---------------------------------------------

def definitions(tags) -> dict:
    out = {}
    for c, d in tags:
        if c in (2, 22, 32, 83, 46, 84, 11, 33, 37):
            out[struct.unpack_from("<H", d, 0)[0]] = ("rect", read_rect(d, 2))
        elif c == 39:
            out[struct.unpack_from("<H", d, 0)[0]] = ("sprite", read_tags(d, 4))
    return out


def bounds(defs: dict, cid: int, m=(1, 0, 0, 1, 0, 0), depth: int = 0):
    if cid not in defs or depth > 24:
        return None
    kind, v = defs[cid]
    a, b, c, d, tx, ty = m
    if kind == "rect":
        x0, x1, y0, y1 = v
        pts = [(a * x + c * y + tx, b * x + d * y + ty) for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1))]
    else:
        pts = []
        for code, data in v:
            if code == T_SHOWFRAME:
                break
            ch, mm = placed(code, data)
            if ch is None:
                continue
            a2, b2, c2, d2, tx2, ty2 = mm or (1, 0, 0, 1, 0, 0)
            comp = (a * a2 + c * b2, b * a2 + d * b2, a * c2 + c * d2, b * c2 + d * d2,
                    a * tx2 + c * ty2 + tx, b * tx2 + d * ty2 + ty)
            r = bounds(defs, ch, comp, depth + 1)
            if r:
                pts += [(r[0], r[2]), (r[1], r[3])]
    if not pts:
        return None
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), max(xs), min(ys), max(ys)


# --- the template's bytecode under another name --------------------------------------

def _u30(data: bytes, p: int) -> tuple[int, int]:
    v = shift = 0
    while True:
        byte = data[p]
        p += 1
        v |= (byte & 0x7F) << shift
        shift += 7
        if not byte & 0x80 or shift >= 35:
            return v, p


def _w30(v: int) -> bytes:
    out = bytearray()
    while True:
        byte = v & 0x7F
        v >>= 7
        if v:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)


def renamed_abc(doabc: bytes, race: str) -> bytes:
    flags = doabc[:4]
    end = doabc.index(b"\0", 4)
    name = doabc[4:end].decode("utf-8").replace(TEMPLATE_ID, race)
    abc = doabc[end + 1:]
    p = 4  # minor, major
    n, p = _u30(abc, p)  # ints
    for _ in range(max(0, n - 1)):
        _, p = _u30(abc, p)
    n, p = _u30(abc, p)  # uints
    for _ in range(max(0, n - 1)):
        _, p = _u30(abc, p)
    n, p = _u30(abc, p)  # doubles
    p += 8 * max(0, n - 1)
    head = abc[:p]
    n, p = _u30(abc, p)
    strings = []
    for _ in range(max(0, n - 1)):
        ln, p = _u30(abc, p)
        strings.append(abc[p:p + ln].decode("utf-8"))
        p += ln
    pool = _w30(n) + b"".join(_w30(len(s.encode("utf-8"))) + s.encode("utf-8")
                             for s in (s.replace(TEMPLATE_ID, race) for s in strings))
    return flags + name.encode("utf-8") + b"\0" + head + pool + abc[p:]


# --- one file ----------------------------------------------------------------------

def fill(path: Path, race: str, template_abc: bytes | None):
    version, header, tags = parse(path)
    names: dict[int, str] = {}
    for c, d in tags:
        if c == T_SYMBOLCLASS:
            names.update(parse_symbol_class(d))
    by_name = {n: i for i, n in names.items()}
    small, large = f"mmo.pet.peticon{race}_S", f"mmo.pet.peticon{race}_L"
    defs = definitions(tags)
    if large not in by_name:
        return None
    if small in by_name and bounds(defs, by_name[small]) is not None:
        return None  # has its own small picture
    lb = bounds(defs, by_name[large])
    if lb is None:
        return None
    w, h = max(1.0, lb[1] - lb[0]), max(1.0, lb[3] - lb[2])
    k = min(1.0, SMALL_W / w, SMALL_H / h)
    tx, ty = -(lb[0] + w / 2) * k, 1.0 - lb[3] * k
    ids = [struct.unpack_from("<H", d, 0)[0] for c, d in tags if c in DEFINING and len(d) >= 2]
    new_id = max(ids + list(names)) + 1
    place = bytes([0x06]) + struct.pack("<HH", 1, by_name[large]) + matrix_bytes(k, k, tx, ty)
    sprite = struct.pack("<HH", new_id, 1) + write_tag(26, place) + write_tag(T_SHOWFRAME, b"") + write_tag(0, b"")
    need_class = small not in by_name
    if need_class and template_abc is None:
        raise SystemExit("--template is needed: " + path.name + " has no " + small)
    note = (
        '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
        '<rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">'
        f"<dc:description>REBUILT small picture {small}: the file's own _L, scaled (tools/peticon_fill.py)</dc:description>"
        "</rdf:Description></rdf:RDF></x:xmpmeta>"
    ).encode("utf-8")
    out, done = [], False
    for c, d in tags:
        if c == T_METADATA:
            out.append((c, note))
        elif c == T_SYMBOLCLASS and not done:
            out.append((39, sprite))
            if need_class:
                out.append((T_DOABC, renamed_abc(template_abc, race)))
            binds = {i: n for i, n in parse_symbol_class(d).items() if n != small}
            binds[new_id] = small
            out.append((c, symbol_class(binds)))
            done = True
        else:
            out.append((c, d))
    if not any(c == T_METADATA for c, _ in out):
        i = next((j for j, (c, _) in enumerate(out) if c == T_FILEATTR), -1)
        if i >= 0:
            out[i] = (T_FILEATTR, bytes([out[i][1][0] | 0x10]) + out[i][1][1:])
            out.insert(i + 1, (T_METADATA, note))
    body = header + b"".join(write_tag(c, d) for c, d in out)
    return b"CWS" + bytes([version]) + struct.pack("<I", 8 + len(body)) + zlib.compress(body, 9), need_class


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game", required=True, help="game/ (holding www.9aola.com/peticon)")
    ap.add_argument("--template", help="the compiled template SWF (class mmo.pet.peticon777777_S)")
    ap.add_argument("--out", required=True, help="where www.9aola.com/peticon/... go (e.g. build/rebuilt/www.9aola.com)")
    a = ap.parse_args(argv)
    template_abc = None
    if a.template:
        _, _, ttags = parse(Path(a.template))
        template_abc = next(d for c, d in ttags if c == T_DOABC)
    src = Path(a.game) / "www.9aola.com" / "peticon"
    dst = Path(a.out) / "peticon"
    dst.mkdir(parents=True, exist_ok=True)
    made = []
    for f in sorted(os.listdir(src)):
        m = re.match(r"peticon(\d+)\.swf", f)
        if not m:
            continue
        r = fill(src / f, m.group(1), template_abc)
        if r is None:
            continue
        data, new_class = r
        (dst / f).write_bytes(data)
        made.append(m.group(1) + ("+" if new_class else ""))
    print(f"peticon_fill: {len(made)} small pictures made (+ = class added): {' '.join(made)}")


if __name__ == "__main__":
    main()
