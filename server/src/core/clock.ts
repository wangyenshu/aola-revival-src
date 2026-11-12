// The game clock: the real time, as a live server's was. Its days are China days (UTC+8), as the
// original servers counted them (a "once a day" starts again at midnight China time).
//
// Given an anchor (--date, AOLA_DATE, the page's ?date=, a test's), it starts at that day at each
// start instead and runs on at normal speed: for trying a day of the era (its date-gated
// activities) or the automated walk-throughs, not for playing (it goes back at every start).

export const CHINA_MS = 8 * 3600_000;

/** The China day of a time: "YYYY-MM-DD". */
export const chinaDay = (ms: number): string => new Date(ms + CHINA_MS).toISOString().slice(0, 10);

export class GameClock {
  /** The anchor day, or null for the real time. */
  readonly anchor: Date | null;
  private readonly startedAt: number;
  private readonly realNow: () => number;

  constructor(anchor?: Date | string | null, realNow: () => number = Date.now) {
    this.anchor = !anchor ? null : typeof anchor === "string" ? parseAnchor(anchor) : anchor;
    this.realNow = realNow;
    this.startedAt = realNow();
  }

  /** The real time (no anchor). */
  get real(): boolean {
    return this.anchor === null;
  }

  now(): Date {
    if (!this.anchor) return new Date(this.realNow());
    return new Date(this.anchor.getTime() + (this.realNow() - this.startedAt));
  }

  /** Seconds since 1970, the usual on-the-wire form. */
  unix(): number {
    return Math.floor(this.now().getTime() / 1000);
  }

  /** Offset to add to the real clock, for clients that read local time. */
  offsetMs(): number {
    return this.now().getTime() - this.realNow();
  }

  /** Today, a China day. */
  today(): string {
    return chinaDay(this.now().getTime());
  }
}

/** "2012-08-15" or "2012-08-15T10:00" in China time (UTC+8), like the original servers. */
export function parseAnchor(s: string): Date {
  const m = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?$/.exec(s.trim());
  if (!m) throw new Error(`anchor date must look like 2012-08-15 or 2012-08-15T10:00, got ${s}`);
  const [, y, mo, d, h = "10", mi = "00", se = "00"] = m;
  return new Date(Date.UTC(+y, +mo - 1, +d, +h - 8, +mi, +se));
}

/**
 * A time the anchored clock gave (records saved before the clock was the real one): before 2015.
 * Such stamps are 14 years behind the real clock; userRecord (game.ts) moves the ones that would
 * otherwise lose something (a 亚比 let go, a 财富小管家 box, a timed quest) to now, once.
 */
export const ANCHORED_BEFORE = Date.UTC(2015, 0, 1);
