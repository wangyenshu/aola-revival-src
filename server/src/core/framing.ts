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
  private buf = new Uint8Array(0);
  private readonly spec: FramingSpec | null;

  constructor(spec: FramingSpec | null) {
    this.spec = spec;
  }

  get pending(): number {
    return this.buf.length;
  }

  /** Feed received bytes; returns every complete frame (header included). */
  push(chunk: Uint8Array): Uint8Array[] {
    if (!this.spec) return chunk.length ? [chunk.slice()] : [];
    const merged = new Uint8Array(this.buf.length + chunk.length);
    merged.set(this.buf, 0);
    merged.set(chunk, this.buf.length);
    this.buf = merged;
    const { lengthOffset, lengthBytes, littleEndian, lengthIncludesHeader, headerBytes } = this.spec;
    const need = Math.max(lengthOffset + lengthBytes, headerBytes);
    const frames: Uint8Array[] = [];
    let off = 0;
    while (this.buf.length - off >= need) {
      const view = new DataView(this.buf.buffer, this.buf.byteOffset + off, need);
      let len =
        lengthBytes === 1 ? view.getUint8(lengthOffset)
        : lengthBytes === 2 ? view.getUint16(lengthOffset, littleEndian)
        : view.getUint32(lengthOffset, littleEndian);
      len += this.spec.adjust ?? 0;
      const total = lengthIncludesHeader ? len : headerBytes + len;
      if (total < need || total > (this.spec.maxFrame ?? 4 * 1024 * 1024)) {
        throw new FramingError(`implausible frame length ${total} at stream offset ${off}`);
      }
      if (this.buf.length - off < total) break;
      frames.push(this.buf.slice(off, off + total));
      off += total;
    }
    this.buf = this.buf.slice(off);
    return frames;
  }
}
