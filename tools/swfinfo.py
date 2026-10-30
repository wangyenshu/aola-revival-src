"""Read the facts that date a SWF: compression, format version, AS3 or not,
and the XMP metadata Flash Professional embeds (CreateDate / ModifyDate).

The 2013 client's manifest stamps each file with its last-modified date
(v="121206" = 2012-12-06), and Flash CS keeps that date in the file's XMP
ModifyDate. A live file whose ModifyDate matches the stamp is the version the
2013 client used.

  python tools/swfinfo.py file.swf [more.swf …]
"""

from __future__ import annotations

import json
import lzma
import re
import struct
import sys
import zlib
from dataclasses import asdict, dataclass, field


@dataclass
class SwfInfo:
    ok: bool
    compression: str = ""          # FWS (none) | CWS (zlib) | ZWS (LZMA)
    swf_version: int = 0
    as3: bool = False
    xmp: dict = field(default_factory=dict)
    error: str = ""

    @property
    def modify_yymmdd(self) -> str | None:
        d = self.xmp.get("ModifyDate") or self.xmp.get("MetadataDate")
        m = re.match(r"(\d{4})-(\d{2})-(\d{2})", d or "")
        return f"{m.group(1)[2:]}{m.group(2)}{m.group(3)}" if m else None


def _body(data: bytes) -> bytes:
    sig = data[:3]
    if sig == b"FWS":
        return data[8:]
    if sig == b"CWS":
        return zlib.decompressobj().decompress(data[8:])
    if sig == b"ZWS":
        # ZWS: sig, ver, file length (4), compressed length (4), LZMA props (5), data.
        # Decoded as raw LZMA1 so streams with or without an end marker work on
        # every liblzma version (FORMAT_ALONE with a known size rejects end markers
        # on older ones).
        props, d = data[12], struct.unpack_from("<I", data, 13)[0]
        lc, rest = props % 9, props // 9
        lp, pb = rest % 5, rest // 5
        filt = [{"id": lzma.FILTER_LZMA1, "dict_size": max(d, 4096), "lc": lc, "lp": lp, "pb": pb}]
        size = struct.unpack_from("<I", data, 4)[0] - 8
        return lzma.LZMADecompressor(format=lzma.FORMAT_RAW, filters=filt).decompress(data[17:], max_length=size)
    raise ValueError(f"not a SWF (signature {sig!r})")


def _xmp_fields(xml: str) -> dict:
    out = {}
    for key in ("CreateDate", "ModifyDate", "MetadataDate", "CreatorTool"):
        m = re.search(key + r"""(?:>|=")([^<"]+)""", xml)
        if m:
            out[key] = m.group(1).strip()
    return out


def inspect(data: bytes) -> SwfInfo:
    try:
        body = _body(data)
    except Exception as e:  # noqa: BLE001
        return SwfInfo(ok=False, error=str(e))
    info = SwfInfo(ok=True, compression=data[:3].decode(), swf_version=data[3])
    try:
        nbits = body[0] >> 3
        off = (5 + 4 * nbits + 7) // 8 + 4  # RECT + frame rate + frame count
        while off + 2 <= len(body):
            code_len = struct.unpack_from("<H", body, off)[0]
            off += 2
            code, length = code_len >> 6, code_len & 0x3F
            if length == 0x3F:
                length = struct.unpack_from("<I", body, off)[0]
                off += 4
            if code == 77:  # Metadata (XMP)
                info.xmp = _xmp_fields(body[off:off + length].decode("utf-8", "ignore"))
            elif code in (72, 82):  # DoABC
                info.as3 = True
            elif code == 0:
                break
            off += length
    except (struct.error, IndexError) as e:
        info.error = f"tag walk stopped: {e}"
    return info


def stamp_yymmdd(version: str) -> str | None:
    """Manifest stamp -> YYMMDD ("121206" -> "121206", "1301251" -> "130125").

    A bare YYMM ("1210") is the baseline stamp the client puts on files its
    manifest does not list: the file has not changed since that month, so it
    stands for the month's last day ("1210" -> "121031")."""
    v = version or ""
    m = re.match(r"(\d{6})", v)
    if m:
        return m.group(1)
    m = re.fullmatch(r"(\d{2})(0[1-9]|1[0-2])", v)
    return m.group(1) + m.group(2) + "31" if m else None


if __name__ == "__main__":
    for path in sys.argv[1:]:
        with open(path, "rb") as f:
            i = inspect(f.read())
        print(path, json.dumps({**asdict(i), "modify_yymmdd": i.modify_yymmdd}, ensure_ascii=False))
