// Save data. Node uses JSON files (src/node/fileStore.ts); the in-page build
// uses IndexedDB (src/browser/idbStore.ts). Game code only sees this interface.

export interface Store {
  get<T>(key: string): Promise<T | undefined>;
  set<T>(key: string, value: T): Promise<void>;
  /** A value already made JSON (LiveRecordStore measures a record by it): written as it is. */
  setText?(key: string, json: string): Promise<void>;
  delete(key: string): Promise<void>;
  keys(prefix?: string): Promise<string[]>;
}

export class MemoryStore implements Store {
  private readonly map = new Map<string, string>();

  async get<T>(key: string): Promise<T | undefined> {
    const v = this.map.get(key);
    return v === undefined ? undefined : (JSON.parse(v) as T);
  }

  async set<T>(key: string, value: T): Promise<void> {
    this.map.set(key, JSON.stringify(value));
  }

  async setText(key: string, json: string): Promise<void> {
    this.map.set(key, json);
  }

  async delete(key: string): Promise<void> {
    this.map.delete(key);
  }

  async keys(prefix = ""): Promise<string[]> {
    return [...this.map.keys()].filter((k) => k.startsWith(prefix)).sort();
  }
}

/**
 * A Store that keeps the records under some prefixes live: every get of such a key returns the
 * same object, so handlers running at once for different players (a visitor picking fruit from
 * one's tree while one fights a battle, both changing one's record) change one object, and the
 * last save holds both changes; reading a copy each, the later save would undo the earlier.
 * Writes go through at once. At most `max` records stay (the least recently used go).
 */
export class LiveRecordStore implements Store {
  private readonly live = new Map<string, unknown>();
  private readonly inner: Store;
  private readonly prefixes: string[];
  private readonly max: number;
  private readonly pinned: (key: string) => boolean;
  private readonly maxBytes: number;
  private readonly log: (msg: string) => void;
  /**
   * pinned: records never let go (the players in the game: their handlers hold them). maxBytes: a
   * kept record larger than this as JSON is not written (0: no limit; a Durable Object value is
   * at most 2 MB).
   */
  constructor(inner: Store, prefixes: string[], max = 1000, pinned: (key: string) => boolean = () => false, maxBytes = 0, log: (msg: string) => void = (m) => console.error(m)) {
    this.inner = inner;
    this.prefixes = prefixes;
    this.max = max;
    this.pinned = pinned;
    this.maxBytes = maxBytes;
    this.log = log;
  }

  private kept(key: string): boolean {
    return this.prefixes.some((p) => key.startsWith(p));
  }

  private remember(key: string, value: unknown): void {
    this.live.delete(key);
    this.live.set(key, value);
    if (this.live.size <= this.max) return;
    for (const k of this.live.keys()) {
      if (this.live.size <= this.max) break;
      if (k !== key && !this.pinned(k)) this.live.delete(k);
    }
  }

  async get<T>(key: string): Promise<T | undefined> {
    if (!this.kept(key)) return this.inner.get<T>(key);
    if (this.live.has(key)) {
      const v = this.live.get(key) as T;
      this.remember(key, v);
      return v;
    }
    const before = this.changes.get(key) ?? 0;
    const v = await this.inner.get<T>(key);
    // Loaded by another get meanwhile: that one is the live one.
    if (this.live.has(key)) return this.live.get(key) as T;
    // Written or deleted meanwhile: what was read is old (a deleted record must not come back).
    if ((this.changes.get(key) ?? 0) !== before) return this.get<T>(key);
    if (v !== undefined) this.remember(key, v);
    return v;
  }

  /** Writes and deletes of each kept key so far (a get in flight then reads again). */
  private readonly changes = new Map<string, number>();

  private changed(key: string): void {
    this.changes.set(key, (this.changes.get(key) ?? 0) + 1);
    if (this.changes.size > this.max * 4) this.changes.clear();
  }

  async set<T>(key: string, value: T): Promise<void> {
    if (!this.kept(key)) return this.inner.set(key, value);
    this.remember(key, value);
    this.changed(key);
    // Written as it is now; a write that fails (the disk full, the record over the limit) leaves
    // the live copy out, so the next get reads what storage last kept: memory and storage agree
    // (the change since the last good write is lost, and logged), rather than a game going on
    // from a record that is never saved.
    // Made JSON once: measured, and written as that text where the store takes it.
    let err: unknown;
    const json = this.maxBytes ? JSON.stringify(value) : undefined;
    if (json !== undefined && utf8Length(json) > this.maxBytes) err = new Error(`record over ${this.maxBytes} bytes`);
    else {
      for (let tries = 0; tries < 3; tries++) {
        try {
          if (json !== undefined && this.inner.setText) await this.inner.setText(key, json);
          else await this.inner.set(key, value);
          return;
        } catch (e) {
          err = e;
          await new Promise((r) => setTimeout(r, 50 * (tries + 1)));
        }
      }
    }
    if (this.live.get(key) === value) {
      this.live.delete(key);
      this.changed(key);
    }
    this.log(`[aola] save of ${key} failed, its last saved state is kept: ${(err as Error)?.message ?? String(err)}`);
    throw err;
  }

  async delete(key: string): Promise<void> {
    this.live.delete(key);
    this.changed(key);
    await this.inner.delete(key);
  }

  keys(prefix = ""): Promise<string[]> {
    return this.inner.keys(prefix);
  }
}

/** The UTF-8 bytes of a string, counted (no copy made). */
export function utf8Length(s: string): number {
  let n = 0;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c < 0x80) n += 1;
    else if (c < 0x800) n += 2;
    else if (c >= 0xd800 && c <= 0xdbff && i + 1 < s.length) {
      n += 4;
      i++;
    } else n += 3;
  }
  return n;
}
