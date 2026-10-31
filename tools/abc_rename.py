#!/usr/bin/env python3
"""Rename names in a SWF's bytecode (its ABC string pools).

Some games the revival runs as later copies call a method the January 2013
libraries do not have: SocketClient.startGame(name), which the later
SocketClient added (it told the server a game had begun) and nothing waits on.
The call throws in the 2013 client and the game never draws its board. This
writes a copy of the SWF where every string of the bytecode's string pools
equal to OLD is NEW instead, so the call goes to a method the 2013 class has
and that does nothing harmful (startGame -> hasEventListener: one String in,
a Boolean out, nothing sent). Use it only where OLD names nothing else in the
SWF (no method of the game's own of that name).

  tools/abc_rename.py --rename startGame=hasEventListener --note "…" in.swf out.swf
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from peticon_fill import _u30, _w30  # noqa: E402
from swf_transplant import parse, write_tag  # noqa: E402

T_DOABC1, T_DOABC, T_METADATA = 72, 82, 77


def rename_abc(abc: bytes, names: dict[str, str]) -> tuple[bytes, int]:
    p = 4  # minor, major
    n, p = _u30(abc, p)
    for _ in range(max(0, n - 1)):
        _, p = _u30(abc, p)
    n, p = _u30(abc, p)
    for _ in range(max(0, n - 1)):
        _, p = _u30(abc, p)
    n, p = _u30(abc, p)
    p += 8 * max(0, n - 1)
    head = abc[:p]
    n, p = _u30(abc, p)
    out, hits = [], 0
    for _ in range(max(0, n - 1)):
        ln, p = _u30(abc, p)
        s = abc[p:p + ln].decode("utf-8", "surrogatepass")
        p += ln
        if s in names:
            s = names[s]
            hits += 1
        out.append(s)
    pool = _w30(n) + b"".join(_w30(len(s.encode("utf-8", "surrogatepass"))) + s.encode("utf-8", "surrogatepass") for s in out)
    return head + pool + abc[p:], hits


def main(argv=None) -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rename", action="append", required=True, help="OLD=NEW")
    ap.add_argument("--note", default="", help="what was changed, put in the SWF's metadata")
    ap.add_argument("src")
    ap.add_argument("out")
    a = ap.parse_args(argv)
    names = dict(r.split("=", 1) for r in a.rename)
    version, header, tags = parse(Path(a.src))
    total = 0
    out = []
    for c, d in tags:
        if c == T_DOABC:
            end = d.index(b"\0", 4)
            abc, hits = rename_abc(d[end + 1:], names)
            d = d[:end + 1] + abc
            total += hits
        elif c == T_DOABC1:
            d, hits = rename_abc(d, names)
            total += hits
        elif c == T_METADATA and a.note:
            d = (
                '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
                '<rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">'
                f"<dc:description>{a.note}</dc:description></rdf:Description></rdf:RDF></x:xmpmeta>"
            ).encode("utf-8")
        out.append((c, d))
    if total == 0:
        raise SystemExit(f"{a.src}: none of {', '.join(names)} in its bytecode")
    body = header + b"".join(write_tag(c, d) for c, d in out)
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    Path(a.out).write_bytes(b"CWS" + bytes([version]) + struct.pack("<I", 8 + len(body)) + zlib.compress(body, 9))
    print(f"{a.out}: {total} names changed")


if __name__ == "__main__":
    main()
