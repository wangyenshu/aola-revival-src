// Small byte helpers shared by Node and browser builds (no Buffer here).

const enc = new TextEncoder();
const dec = new TextDecoder("utf-8", { fatal: false });

export function utf8(s: string): Uint8Array {
  return enc.encode(s);
}

export function fromUtf8(b: Uint8Array): string {
  return dec.decode(b);
}

export function concat(...parts: Uint8Array[]): Uint8Array {
  const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let o = 0;
  for (const p of parts) {
    out.set(p, o);
    o += p.length;
  }
  return out;
}

export function toHex(b: Uint8Array, max = Infinity): string {
  const n = Math.min(b.length, max);
  let s = "";
  for (let i = 0; i < n; i++) s += b[i].toString(16).padStart(2, "0");
  return n < b.length ? s + "…" : s;
}

/** Printable-ASCII preview; other bytes become "." (UTF-8 text is shown separately). */
export function asciiPreview(b: Uint8Array, max = 256): string {
  let s = "";
  for (let i = 0; i < Math.min(b.length, max); i++) {
    const c = b[i];
    s += c >= 0x20 && c < 0x7f ? String.fromCharCode(c) : ".";
  }
  return s;
}

/** True when the bytes decode as mostly-printable UTF-8 (JSON, XML, text protocols). */
export function looksLikeText(b: Uint8Array): boolean {
  if (b.length === 0) return false;
  const s = fromUtf8(b);
  let bad = 0;
  for (const ch of s) {
    const c = ch.codePointAt(0)!;
    if (c === 0xfffd || (c < 0x20 && c !== 9 && c !== 10 && c !== 13 && c !== 0)) bad++;
  }
  return bad / s.length < 0.05;
}
