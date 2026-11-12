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

/**
 * A refused password, and a name the server does not have, alike: the answer says neither which
 * (and takes as long: game.ts checks a made-up hash for a name it does not have), so the names
 * of a server cannot be found by trying them. 注册 is where a name is told taken.
 */
export const WRONG = "名字或密码不对哦。";

/** A new password (注册, 改密码): PASS_MIN to PASS_MAX characters. */
export const PASS_MIN = 6;
export const PASS_MAX = 32;
export function passwordProblem(pass: string): string | null {
  if (!pass) return "请输入密码。";
  const n = [...pass].length;
  if (n < PASS_MIN) return `密码最少${PASS_MIN}个字。`;
  if (n > PASS_MAX) return `密码最多${PASS_MAX}个字。`;
  return null;
}

/**
 * 记住密码: the page keeps a token the server gave instead of the password (its hash is the
 * record's, as the password's is). It logs in, and does what the password does on the start
 * screen and in the 存档 panels, but 改密码 asks the password itself, and a new password ends
 * every token. A token lasts TOKEN_DAYS from when it was given; an 奥拉 has TOKENS_MAX at most
 * (a new one ends the oldest). One looks like TOKEN_MARK and 28 letters of base64url (168 bits).
 */
export interface TokenRec {
  h: string;
  made: number;
}
export const TOKEN_MARK = "~";
export const TOKEN_DAYS = 30;
export const TOKENS_MAX = 5;
const TOKEN_FORM = /^~[A-Za-z0-9_-]{28}$/;
export const looksLikeToken = (s: string) => TOKEN_FORM.test(s);

export function newToken(): string {
  const b = globalThis.crypto.getRandomValues(new Uint8Array(21));
  let s = "";
  for (const x of b) s += String.fromCharCode(x);
  return TOKEN_MARK + btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export async function tokenHash(token: string): Promise<string> {
  return hex(await globalThis.crypto.subtle.digest("SHA-256", new TextEncoder().encode(token)));
}

/** The tokens of a record still good at now (the others dropped). */
export function liveTokens(list: TokenRec[] | undefined, now: number): TokenRec[] {
  return (Array.isArray(list) ? list : []).filter((t) => t && typeof t.h === "string" && now - Number(t.made) < TOKEN_DAYS * 86400_000);
}

/** Whether a token is one of these (each compared whole). */
export async function tokenMatches(token: string, list: TokenRec[]): Promise<boolean> {
  if (!looksLikeToken(token) || !list.length) return false;
  const h = await tokenHash(token);
  let hit = false;
  for (const t of list) {
    let diff = h.length ^ t.h.length;
    for (let i = 0; i < h.length; i++) diff |= h.charCodeAt(i) ^ (t.h.charCodeAt(i) || 0);
    if (diff === 0) hit = true;
  }
  return hit;
}

export interface AccountOptions {
  /** Passwords are asked for (a shared server). */
  required: boolean;
  /** New names may sign up (注册; else only names the server has). */
  register: boolean;
  /** New 奥拉 an address may sign up a day (default SIGNUPS_PER_DAY; 0: no limit). */
  signupsPerDay?: number;
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

/** 注册 from one address: tries (a name taken counts) within SIGNUP_WINDOW_MS, and new 奥拉 a day. */
export const SIGNUP_TRIES_MAX = 10;
export const SIGNUP_WINDOW_MS = 10 * 60 * 1000;
export const SIGNUPS_PER_DAY = 5;
export const SIGNUP_TOO_FAST = "注册得太快了，请过一会儿再试。";
export const SIGNUP_TOO_MANY = "这里今天注册的奥拉太多了，请明天再来。";

/**
 * What 注册 an address has done lately. A try is counted before the name is looked at, so the
 * names a server has are found a few a minute at most; the new 奥拉 of a day are what one
 * address may fill the server with.
 */
export class SignupGuard {
  private readonly by = new Map<string, { tries: number[]; made: number[] }>();
  private readonly now: () => number;
  constructor(now: () => number = Date.now) {
    this.now = now;
  }
  private of(addr: string) {
    const t = this.now();
    let e = this.by.get(addr);
    if (!e) this.by.set(addr, (e = { tries: [], made: [] }));
    e.tries = e.tries.filter((x) => t - x < SIGNUP_WINDOW_MS);
    e.made = e.made.filter((x) => t - x < 86400_000);
    if (this.by.size > 10000) {
      for (const [k, v] of this.by) if (!v.made.some((x) => t - x < 86400_000) && !v.tries.some((x) => t - x < SIGNUP_WINDOW_MS)) this.by.delete(k);
    }
    return e;
  }
  /** null if this address may try now (the try counted), else why not. */
  tryNow(addr: string, perDay = SIGNUPS_PER_DAY): string | null {
    const e = this.of(addr);
    if (perDay > 0 && e.made.length >= perDay) return SIGNUP_TOO_MANY;
    if (e.tries.length >= SIGNUP_TRIES_MAX) return SIGNUP_TOO_FAST;
    e.tries.push(this.now());
    return null;
  }
  made(addr: string): void {
    this.of(addr).made.push(this.now());
  }
}
