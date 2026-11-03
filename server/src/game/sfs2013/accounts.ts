// Accounts of a shared (multiplayer) server: an 奥拉 name and a password. The name is the
// player's key everywhere (the 2013 client finds players by name: scenes, cards, HELLOs),
// so it is unique; it can be changed (renameUser) while the password stays.
//
// Passwords are kept as PBKDF2-SHA256 hashes through WebCrypto (globalThis.crypto.subtle),
// which Node (18+), browsers and Cloudflare Workers all have: no host-specific module.

export interface PassRec {
  salt: string;
  hash: string;
  iter: number;
}

const ITERATIONS = 60_000;

const hex = (b: ArrayBuffer | Uint8Array) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("");

export async function hashPass(pass: string, salt?: string, iter = ITERATIONS): Promise<PassRec> {
  const subtle = globalThis.crypto.subtle;
  const s = salt ?? hex(globalThis.crypto.getRandomValues(new Uint8Array(16)));
  const key = await subtle.importKey("raw", new TextEncoder().encode(pass), "PBKDF2", false, ["deriveBits"]);
  const bits = await subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: new TextEncoder().encode(s), iterations: iter }, key, 256);
  return { salt: s, hash: hex(bits), iter };
}

export async function checkPass(pass: string, rec: PassRec): Promise<boolean> {
  const h = await hashPass(pass, rec.salt, rec.iter);
  // Same length always (hex of 32 bytes): compare all of it.
  let diff = 0;
  for (let i = 0; i < h.hash.length; i++) diff |= h.hash.charCodeAt(i) ^ rec.hash.charCodeAt(i);
  return diff === 0 && h.hash.length === rec.hash.length;
}

/**
 * Whether a name may be an 奥拉's: 1–12 characters, no spaces, quotes or symbols that the
 * 2013 client uses to separate fields ("#", ";", ",", "|", "_" in some lists). null if fine.
 */
export function nameProblem(name: string): string | null {
  const n = name.trim();
  if (!n) return "请输入奥拉的名字。";
  if ([...n].length > 12) return "名字最多12个字。";
  if (/[\s#;,|<>&"'\\/%_:=]/.test(n) || /[\u0000-\u001f]/.test(n)) return "名字里不能有空格和符号。";
  return null;
}

export interface AccountOptions {
  /** Passwords are asked for (a shared server). */
  required: boolean;
  /** New names may sign up (else only names the server has). */
  register: boolean;
  /**
   * A save without a password (copied in from elsewhere) takes the password of its first login.
   * Off: such a save cannot be logged in to (anyone could otherwise claim it).
   */
  adopt?: boolean;
}

/** Wrong passwords for one name before it is locked, within FAIL_WINDOW_MS. */
export const FAILS_MAX = 5;
export const FAIL_WINDOW_MS = 10 * 60 * 1000;
/** How long a name stays locked after FAILS_MAX wrong passwords. */
export const LOCK_MS = 60 * 1000;
export const LOCKED = "密码错了太多次，请过一分钟再试。";

/**
 * Wrong passwords per name and client address, for every way a password is checked (the login,
 * 改名字, 导出存档, 导入存档): after FAILS_MAX within FAIL_WINDOW_MS that name takes no password
 * from that address for LOCK_MS. Guessing is then a few tries a minute from an address, and
 * someone else's wrong tries do not lock the player out (his address is another).
 */
export class PassGuard {
  private readonly fails = new Map<string, { n: number; first: number; until: number }>();
  private readonly now: () => number;
  constructor(now: () => number = Date.now) {
    this.now = now;
  }
  /** The name takes no password now. */
  locked(name: string): boolean {
    const f = this.fails.get(name);
    return !!f && f.until > this.now();
  }
  failed(name: string): void {
    const t = this.now();
    let f = this.fails.get(name);
    if (!f || t - f.first > FAIL_WINDOW_MS) f = { n: 0, first: t, until: 0 };
    f.n++;
    if (f.n >= FAILS_MAX) {
      f.until = t + LOCK_MS;
      f.n = 0;
      f.first = t;
    }
    this.fails.set(name, f);
    // Names tried long ago go (no end of names kept).
    if (this.fails.size > 10000) {
      for (const [k, v] of this.fails) if (t - v.first > FAIL_WINDOW_MS && v.until <= t) this.fails.delete(k);
    }
  }
  passed(name: string): void {
    this.fails.delete(name);
  }
}
