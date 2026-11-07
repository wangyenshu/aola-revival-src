#!/usr/bin/env python3
"""Write a SWF of empty sprites, as the art for tools/swf_transplant.py --bind.

Some original modules load a film that is lost (an activity's win film, played
before its panel shows what was got). A panel that waits for the film's last
frame then waits for ever. This writes the art of a stand-in: COUNT sprites
(character IDs 1 … COUNT), each FRAMES empty frames long, which swf_transplant
binds to the classes the panel asks for:

  tools/blank_sprites.py --count 2 --frames 2 --out out/blank2.swf
  tools/swf_transplant.py --art out/blank2.swf --code out/films-code.swf \\
      --bind 1=mmo.some.WinMovie --bind 2=mmo.some.BuyMovie --note "REBUILT …" --out films.swf
"""

from __future__ import annotations

import argparse
import struct
from pathlib import Path


def tag(code: int, data: bytes = b"") -> bytes:
    if len(data) < 0x3F:
        return struct.pack("<H", (code << 6) | len(data)) + data
    return struct.pack("<HI", (code << 6) | 0x3F, len(data)) + data


def rect(xmin: int, xmax: int, ymin: int, ymax: int) -> bytes:
    vals = [xmin, xmax, ymin, ymax]
    nbits = max(max(v.bit_length() for v in vals) + 1, 1)
    bits = format(nbits, "05b") + "".join(format(v & ((1 << nbits) - 1), f"0{nbits}b") for v in vals)
    bits += "0" * (-len(bits) % 8)
    return bytes(int(bits[i : i + 8], 2) for i in range(0, len(bits), 8))


def blank_sprites(count: int, frames: int) -> bytes:
    tags = tag(69, struct.pack("<I", 0x08))  # FileAttributes: ActionScript 3
    tags += tag(9, b"\xff\xff\xff")  # SetBackgroundColor
    for cid in range(1, count + 1):
        inner = tag(1) * frames + tag(0)
        tags += tag(39, struct.pack("<HH", cid, frames) + inner)
    tags += tag(76, struct.pack("<H", 0))  # SymbolClass (empty: swf_transplant fills it)
    tags += tag(1) + tag(0)
    header = rect(0, 960 * 20, 0, 560 * 20) + struct.pack("<HH", 25 << 8, 1)
    body = header + tags
    return b"FWS" + bytes([10]) + struct.pack("<I", 8 + len(body)) + body


def main(argv=None) -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--count", type=int, default=1)
    p.add_argument("--frames", type=int, default=2)
    p.add_argument("--out", required=True)
    a = p.parse_args(argv)
    Path(a.out).write_bytes(blank_sprites(a.count, max(1, a.frames)))


if __name__ == "__main__":
    main()
