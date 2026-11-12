// AMF3 (Action Message Format 3), as written by flash.utils.ByteArray.writeObject.
// The 2013 client sends every extension request's params this way and expects
// every extension response as an AMF3 object.
//
// Supported: undefined, null, booleans, int (U29), double, string, date, array
// (dense + associative), anonymous and typed objects (sealed + dynamic traits),
// ByteArray, XML (as string). Externalizable objects are rejected.

export class Amf3TypedObject {
  readonly className: string;
  readonly values: Record<string, unknown>;
  constructor(className: string, values: Record<string, unknown>) {
    this.className = className;
    this.values = values;
  }
}

const INT_MIN = -(1 << 28);
const INT_MAX = (1 << 28) - 1;

interface Traits {
  className: string;
  dynamic: boolean;
  externalizable: boolean;
  members: string[];
}

/**
 * What one decoded value may cost (a frame comes from anyone): references make a small frame a
 * huge value (arrays that all point at each other, a long string named a million times), which
 * whatever walks it later (a log line, a record written) would take minutes over. Every value
 * counts 1, a string its length, and a reference what the value it names cost; a reference to a
 * value still being read (a cycle) and nesting deeper than MAX_DEPTH are refused.
 */
export const AMF3_MAX_COST = 2_000_000;
export const AMF3_MAX_DEPTH = 32;

export class Amf3Reader {
  private readonly view: DataView;
  private readonly bytes: Uint8Array;
  pos: number;
  private readonly strings: string[] = [];
  private readonly objects: unknown[] = [];
  private readonly traits: Traits[] = [];
  private static readonly dec = new TextDecoder("utf-8");
  /** The cost so far, each finished array/object's own, those being read, and the depth. */
  private cost = 0;
  private readonly costs = new WeakMap<object, number>();
  private readonly reading = new WeakSet<object>();
  private depth = 0;

  private spend(n: number): void {
    this.cost += n;
    if (this.cost > AMF3_MAX_COST) throw new RangeError("AMF3: value too large");
  }

  /** A reference to a value read before: what it cost, again; not one still being read. */
  private ref(v: unknown): unknown {
    if (v !== null && typeof v === "object") {
      if (this.reading.has(v)) throw new RangeError("AMF3: cyclic reference");
      this.spend(this.costs.get(v) ?? 1);
    } else if (typeof v === "string") this.spend(v.length + 1);
    else this.spend(1);
    return v;
  }

  /** An array or object: read as one more level, its cost kept for references to it. */
  private composite<T extends object>(v: T, fill: () => void): T {
    if (++this.depth > AMF3_MAX_DEPTH) throw new RangeError("AMF3: nested too deep");
    const start = this.cost;
    this.reading.add(v);
    try {
      fill();
    } finally {
      this.reading.delete(v);
      this.depth--;
    }
    this.costs.set(v, this.cost - start + 1);
    return v;
  }

  constructor(bytes: Uint8Array, pos = 0) {
    this.bytes = bytes;
    this.view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    this.pos = pos;
  }

  private u8(): number {
    if (this.pos >= this.bytes.length) throw new RangeError("AMF3: unexpected end of data");
    return this.bytes[this.pos++];
  }

  private u29(): number {
    let n = 0;
    for (let i = 0; i < 3; i++) {
      const b = this.u8();
      if (b < 0x80) return (n << 7) | b;
      n = (n << 7) | (b & 0x7f);
    }
    return (n << 8) | this.u8();
  }

  private str(): string {
    const h = this.u29();
    if ((h & 1) === 0) {
      const r = this.strings[h >> 1];
      this.spend((r?.length ?? 0) + 1);
      return r;
    }
    const len = h >> 1;
    if (len === 0) return "";
    const s = Amf3Reader.dec.decode(this.bytes.subarray(this.pos, this.pos + len));
    this.pos += len;
    this.spend(s.length + 1);
    this.strings.push(s);
    return s;
  }

  read(): unknown {
    const marker = this.u8();
    this.spend(1);
    switch (marker) {
      case 0x00:
        return undefined;
      case 0x01:
        return null;
      case 0x02:
        return false;
      case 0x03:
        return true;
      case 0x04: {
        const n = this.u29();
        return n & 0x10000000 ? n - 0x20000000 : n;
      }
      case 0x05: {
        const d = this.view.getFloat64(this.pos);
        this.pos += 8;
        return d;
      }
      case 0x06:
        return this.str();
      case 0x07:
      case 0x0b: {
        const h = this.u29();
        if ((h & 1) === 0) return this.ref(this.objects[h >> 1]);
        const s = Amf3Reader.dec.decode(this.bytes.subarray(this.pos, this.pos + (h >> 1)));
        this.pos += h >> 1;
        this.spend(s.length);
        this.objects.push(s);
        return s;
      }
      case 0x08: {
        const h = this.u29();
        if ((h & 1) === 0) return this.ref(this.objects[h >> 1]);
        const d = new Date(this.view.getFloat64(this.pos));
        this.pos += 8;
        this.objects.push(d);
        return d;
      }
      case 0x09:
        return this.array();
      case 0x0a:
        return this.object();
      case 0x0c: {
        const h = this.u29();
        if ((h & 1) === 0) return this.ref(this.objects[h >> 1]);
        const b = this.bytes.slice(this.pos, this.pos + (h >> 1));
        this.pos += h >> 1;
        this.spend(b.length);
        this.costs.set(b, b.length + 1);
        this.objects.push(b);
        return b;
      }
      default:
        throw new Error(`AMF3: unsupported marker 0x${marker.toString(16)} at ${this.pos - 1}`);
    }
  }

  private array(): unknown {
    const h = this.u29();
    if ((h & 1) === 0) return this.ref(this.objects[h >> 1]);
    const dense = h >> 1;
    const assoc: Record<string, unknown> = {};
    let hasAssoc = false;
    const out: unknown[] = [];
    this.objects.push(out);
    return this.composite(out, () => {
      for (;;) {
        const key = this.str();
        if (key === "") break;
        assoc[key] = this.read();
        hasAssoc = true;
      }
      for (let i = 0; i < dense; i++) out.push(this.read());
      if (hasAssoc) Object.assign(out, assoc);
    });
  }

  private object(): unknown {
    const h = this.u29();
    if ((h & 1) === 0) return this.ref(this.objects[h >> 1]);
    let t: Traits;
    if ((h & 2) === 0) {
      t = this.traits[h >> 2];
    } else {
      t = {
        externalizable: (h & 4) !== 0,
        dynamic: (h & 8) !== 0,
        className: this.str(),
        members: [],
      };
      const count = h >> 4;
      for (let i = 0; i < count; i++) t.members.push(this.str());
      this.traits.push(t);
    }
    if (t.externalizable) throw new Error(`AMF3: externalizable class ${t.className} not supported`);
    const values: Record<string, unknown> = {};
    const result = t.className ? new Amf3TypedObject(t.className, values) : values;
    this.objects.push(result);
    // A typed object's values are its own (references name the object, not them).
    if (result !== values) this.reading.add(values);
    try {
      return this.composite(result, () => {
        for (const m of t.members) values[m] = this.read();
        if (t.dynamic) {
          for (;;) {
            const key = this.str();
            if (key === "") break;
            values[key] = this.read();
          }
        }
      });
    } finally {
      if (result !== values) this.reading.delete(values);
    }
  }
}

export class Amf3Writer {
  private buf = new Uint8Array(256);
  private len = 0;
  private readonly strings = new Map<string, number>();
  private readonly objects = new Map<object, number>();
  private static readonly enc = new TextEncoder();

  private ensure(n: number): void {
    if (this.len + n <= this.buf.length) return;
    let size = this.buf.length * 2;
    while (size < this.len + n) size *= 2;
    const next = new Uint8Array(size);
    next.set(this.buf.subarray(0, this.len));
    this.buf = next;
  }

  private u8(b: number): void {
    this.ensure(1);
    this.buf[this.len++] = b & 0xff;
  }

  private u29(n: number): void {
    n &= 0x1fffffff;
    if (n < 0x80) this.u8(n);
    else if (n < 0x4000) {
      this.u8((n >> 7) | 0x80);
      this.u8(n & 0x7f);
    } else if (n < 0x200000) {
      this.u8((n >> 14) | 0x80);
      this.u8(((n >> 7) & 0x7f) | 0x80);
      this.u8(n & 0x7f);
    } else {
      this.u8((n >> 22) | 0x80);
      this.u8(((n >> 15) & 0x7f) | 0x80);
      this.u8(((n >> 8) & 0x7f) | 0x80);
      this.u8(n & 0xff);
    }
  }

  private f64(d: number): void {
    this.ensure(8);
    new DataView(this.buf.buffer).setFloat64(this.len, d);
    this.len += 8;
  }

  private str(s: string): void {
    if (s === "") {
      this.u29(1);
      return;
    }
    const ref = this.strings.get(s);
    if (ref !== undefined) {
      this.u29(ref << 1);
      return;
    }
    this.strings.set(s, this.strings.size);
    const b = Amf3Writer.enc.encode(s);
    this.u29((b.length << 1) | 1);
    this.ensure(b.length);
    this.buf.set(b, this.len);
    this.len += b.length;
  }

  private ref(o: object): boolean {
    const r = this.objects.get(o);
    if (r !== undefined) {
      this.u29(r << 1);
      return true;
    }
    this.objects.set(o, this.objects.size);
    return false;
  }

  write(v: unknown): this {
    if (v === undefined) this.u8(0x00);
    else if (v === null) this.u8(0x01);
    else if (v === false) this.u8(0x02);
    else if (v === true) this.u8(0x03);
    else if (typeof v === "number") {
      if (Number.isInteger(v) && v >= INT_MIN && v <= INT_MAX && !Object.is(v, -0)) {
        this.u8(0x04);
        this.u29(v);
      } else {
        this.u8(0x05);
        this.f64(v);
      }
    } else if (typeof v === "bigint") {
      this.u8(0x05);
      this.f64(Number(v));
    } else if (typeof v === "string") {
      this.u8(0x06);
      this.str(v);
    } else if (v instanceof Date) {
      this.u8(0x08);
      if (!this.ref(v)) {
        this.u29(1);
        this.f64(v.getTime());
      }
    } else if (v instanceof Uint8Array) {
      this.u8(0x0c);
      if (!this.ref(v)) {
        this.u29((v.length << 1) | 1);
        this.ensure(v.length);
        this.buf.set(v, this.len);
        this.len += v.length;
      }
    } else if (Array.isArray(v)) {
      this.u8(0x09);
      if (!this.ref(v)) {
        this.u29((v.length << 1) | 1);
        for (const k of Object.keys(v)) if (!/^\d+$/.test(k)) {
          this.str(k);
          this.write((v as unknown as Record<string, unknown>)[k]);
        }
        this.str("");
        for (const item of v) this.write(item);
      }
    } else if (v instanceof Amf3TypedObject) {
      this.u8(0x0a);
      if (!this.ref(v)) {
        const keys = Object.keys(v.values);
        this.u29((keys.length << 4) | 0x03); // inline traits, sealed members, not dynamic
        this.str(v.className);
        for (const k of keys) this.str(k);
        for (const k of keys) this.write(v.values[k]);
      }
    } else if (typeof v === "object") {
      this.u8(0x0a);
      if (!this.ref(v as object)) {
        this.u29(0x0b); // inline traits, dynamic, no sealed members, anonymous
        this.str("");
        for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
          if (val === undefined || typeof val === "function") continue;
          this.str(k);
          this.write(val);
        }
        this.str("");
      }
    } else {
      this.u8(0x00);
    }
    return this;
  }

  bytes(): Uint8Array {
    return this.buf.slice(0, this.len);
  }
}

export function amf3Encode(v: unknown): Uint8Array {
  return new Amf3Writer().write(v).bytes();
}

export function amf3Decode(bytes: Uint8Array, pos = 0): { value: unknown; end: number } {
  const r = new Amf3Reader(bytes, pos);
  const value = r.read();
  return { value, end: r.pos };
}
