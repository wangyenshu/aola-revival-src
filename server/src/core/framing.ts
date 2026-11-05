// Splits a TCP byte stream into frames using a length field in the header.
// The 2012 奥拉星 header layout is unknown until the client is decompiled, so
// the layout is data, not code: pick a preset or pass a JSON spec on the CLI.

export interface FramingSpec {
  /** Byte offset of the length field inside the header. */
  lengthOffset: number;
  /** Width of the length field. */
  lengthBytes: 1 | 2 | 4;
  littleEndian: boolean;
  /** true: the length counts the whole frame; false: only the body after the header. */
  lengthIncludesHeader: boolean;
  /** Header size in bytes (needed when the length counts only the body). */
  headerBytes: number;
  /** Constant added to the length value (for formats that count oddly). */
  adjust?: number;
  /** Reject frames larger than this (protects against desynced streams). */
  maxFrame?: number;
}

export const FRAMING_PRESETS: Record<string, FramingSpec | null> = {
  /** No framing: each received chunk is one record. Use while learning the protocol. */
  raw: null,
  "u32be-total": { lengthOffset: 0, lengthBytes: 4, littleEndian: false, lengthIncludesHeader: true, headerBytes: 4 },
  "u32be-body": { lengthOffset: 0, lengthBytes: 4, littleEndian: false, lengthIncludesHeader: false, headerBytes: 4 },
  "u32le-total": { lengthOffset: 0, lengthBytes: 4, littleEndian: true, lengthIncludesHeader: true, headerBytes: 4 },
  "u16be-total": { lengthOffset: 0, lengthBytes: 2, littleEndian: false, lengthIncludesHeader: true, headerBytes: 2 },
  "u16be-body": { lengthOffset: 0, lengthBytes: 2, littleEndian: false, lengthIncludesHeader: false, headerBytes: 2 },
  /** Taomee web games (摩尔庄园 online): len u32 | ver u8 | cmd u32 | uid u32 | ret u32. Reference only. */
  taomee: { lengthOffset: 0, lengthBytes: 4, littleEndian: false, lengthIncludesHeader: true, headerBytes: 17 },
};

export function parseFraming(arg: string): FramingSpec | null {
  if (arg in FRAMING_PRESETS) return FRAMING_PRESETS[arg];
  const spec = JSON.parse(arg) as FramingSpec;
  for (const k of ["lengthOffset", "lengthBytes", "headerBytes"] as const) {
    if (typeof spec[k] !== "number") throw new Error(`framing spec needs numeric ${k}`);
  }
  return spec;
}

export class FramingError extends Error {}

export class FrameSplitter {
  // What has come and is not yet a whole frame, in the pieces it came in: joined only once a
  // frame is whole (piece by piece joining copies the whole pending frame for every piece).
  private parts: Uint8Array[] = [];
  private size = 0;
  /** The length of the frame at the front, once its header has come. */
  private want = 0;
  private readonly spec: FramingSpec | null;

  constructor(spec: FramingSpec | null) {
    this.spec = spec;
  }

  get pending(): number {
    return this.size;
  }

  /** Feed received bytes; returns every complete frame (header included). */
  push(chunk: Uint8Array): Uint8Array[] {
    if (!this.spec) return chunk.length ? [chunk.slice()] : [];
    if (chunk.length) {
      this.parts.push(chunk.slice());
      this.size += chunk.length;
    }
    const need = Math.max(this.spec.lengthOffset + this.spec.lengthBytes, this.spec.headerBytes);
    if (this.size < need) return [];
    if (!this.want) this.want = this.frameLength(this.head(need), 0);
    if (this.size < this.want) return [];
    // A whole frame (or more): join once and cut.
    const buf = this.parts.length === 1 ? this.parts[0] : concatParts(this.parts, this.size);
    const frames: Uint8Array[] = [];
    let off = 0;
    while (buf.length - off >= need) {
      const total = this.frameLength(buf.subarray(off, off + need), off);
      if (buf.length - off < total) break;
      frames.push(buf.slice(off, off + total));
      off += total;
    }
    const rest = buf.subarray(off);
    this.parts = rest.length ? [rest.slice()] : [];
    this.size = rest.length;
    this.want = rest.length >= need ? this.frameLength(rest.subarray(0, need), off) : 0;
    return frames;
  }

  /** The first n pending bytes (n is a header's few bytes). */
  private head(n: number): Uint8Array {
    if (this.parts[0].length >= n) return this.parts[0];
    const out = new Uint8Array(n);
    let at = 0;
    for (const p of this.parts) {
      const take = Math.min(p.length, n - at);
      out.set(p.subarray(0, take), at);
      at += take;
      if (at === n) break;
    }
    return out;
  }

  /** A frame's whole length from its header. */
  private frameLength(head: Uint8Array, off: number): number {
    const { lengthOffset, lengthBytes, littleEndian, lengthIncludesHeader, headerBytes } = this.spec!;
    const need = Math.max(lengthOffset + lengthBytes, headerBytes);
    const view = new DataView(head.buffer, head.byteOffset, need);
    let len =
      lengthBytes === 1 ? view.getUint8(lengthOffset)
      : lengthBytes === 2 ? view.getUint16(lengthOffset, littleEndian)
      : view.getUint32(lengthOffset, littleEndian);
    len += this.spec!.adjust ?? 0;
    const total = lengthIncludesHeader ? len : headerBytes + len;
    if (total < need || total > (this.spec!.maxFrame ?? 4 * 1024 * 1024)) {
      throw new FramingError(`implausible frame length ${total} at stream offset ${off}`);
    }
    return total;
  }
}

function concatParts(parts: Uint8Array[], size: number): Uint8Array {
  const out = new Uint8Array(size);
  let at = 0;
  for (const p of parts) {
    out.set(p, at);
    at += p.length;
  }
  return out;
}
