// Values from a client (a decoded frame), made safe to keep or to log: walked with a budget, so
// nothing larger than asked for is ever built or written out (core/amf3.ts bounds a frame's value;
// this bounds what is made of it).

/**
 * A plain copy (JSON's kinds: objects, arrays, strings, finite numbers, booleans, null) of at most
 * maxChars characters as JSON and maxDepth levels; undefined if it is larger, deeper or cyclic.
 */
export function plainCopy(v: unknown, maxChars = 2000, maxDepth = 8): unknown {
  let left = maxChars;
  const seen = new Set<object>();
  const walk = (x: unknown, depth: number): unknown => {
    if (left < 0) throw RangeError();
    if (x === null || typeof x === "boolean") return (left -= 5), x;
    if (typeof x === "number") return (left -= 8), Number.isFinite(x) ? x : null;
    if (typeof x === "string") {
      left -= x.length + 2;
      if (left < 0) throw RangeError();
      return x;
    }
    if (typeof x !== "object" || depth >= maxDepth || seen.has(x)) throw RangeError();
    seen.add(x);
    try {
      if (Array.isArray(x)) {
        const out: unknown[] = [];
        for (const e of x) out.push(e === undefined ? null : walk(e, depth + 1));
        left -= 2;
        return out;
      }
      const src = "values" in (x as object) && (x as { className?: unknown }).className !== undefined ? (x as { values: object }).values : x;
      const out: Record<string, unknown> = {};
      for (const k of Object.keys(src)) {
        const e = (src as Record<string, unknown>)[k];
        if (e === undefined || typeof e === "function") continue;
        left -= k.length + 4;
        out[k] = walk(e, depth + 1);
      }
      left -= 2;
      return out;
    } finally {
      seen.delete(x);
    }
  };
  try {
    const out = walk(v, 0);
    return left < 0 ? undefined : out;
  } catch {
    return undefined;
  }
}

/** A short text of a client's value for a log line: at most max characters, however large it is. */
export function brief(v: unknown, max = 300): string {
  let out = "";
  let left = max;
  const put = (s: string) => {
    if (left <= 0) throw RangeError();
    out += s.slice(0, left);
    left -= s.length;
    if (left <= 0) throw RangeError();
  };
  const seen = new Set<object>();
  const walk = (x: unknown, depth: number) => {
    if (x === undefined) return put("undefined");
    if (x === null || typeof x !== "object") return put(typeof x === "string" ? JSON.stringify(x.slice(0, left)) : String(x));
    if (seen.has(x) || depth > 6) return put("…");
    seen.add(x);
    if (Array.isArray(x)) {
      put("[");
      x.forEach((e, i) => (i && put(","), walk(e, depth + 1)));
      put("]");
    } else {
      put("{");
      Object.keys(x).forEach((k, i) => (i && put(","), put(`${k}:`), walk((x as Record<string, unknown>)[k], depth + 1)));
      put("}");
    }
    seen.delete(x);
  };
  try {
    walk(v, 0);
  } catch {
    return out + "…";
  }
  return out;
}
