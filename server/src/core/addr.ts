// A client's address as the limits count it (the password lock, the connections and sign-ups of
// an address): an IPv4 one as it is, an IPv6 one by its first four groups (its /64: one line,
// one home, has a whole /64, and could otherwise take a new address for every try).

export function addrKey(ip: string): string {
  const s = String(ip || "").trim();
  const v4 = /^::ffff:(\d+\.\d+\.\d+\.\d+)$/i.exec(s);
  if (v4) return v4[1];
  if (!s.includes(":")) return s;
  // A zone ("fe80::1%eth0") is the machine's own, not the address's.
  const bare = s.replace(/%.*$/, "").replace(/^\[|\]$/g, "");
  const [head, tail = ""] = bare.split("::");
  const a = head ? head.split(":") : [];
  const b = tail ? tail.split(":") : [];
  const full = [...a, ...Array(Math.max(0, 8 - a.length - b.length)).fill("0"), ...b];
  return full.slice(0, 4).map((g) => g.toLowerCase().replace(/^0+(?=.)/, "")).join(":") + "::/64";
}

/** Whether an address is the machine's own or a private network's (where a proxy would be). */
export function localAddr(ip: string): boolean {
  const s = String(ip || "").replace(/^::ffff:/i, "");
  return (
    s === "::1" ||
    /^127\./.test(s) ||
    /^10\./.test(s) ||
    /^192\.168\./.test(s) ||
    /^172\.(1[6-9]|2\d|3[01])\./.test(s) ||
    /^f[cd][0-9a-f]{2}:/i.test(s)
  );
}
