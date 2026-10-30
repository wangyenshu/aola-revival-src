// The game clock starts at the anchor date (a day in 2012) and then runs at
// normal speed, so date-gated events open exactly as they did back then.

export class GameClock {
  readonly anchor: Date;
  private readonly startedAt: number;
  private readonly realNow: () => number;

  constructor(anchor: Date | string, realNow: () => number = Date.now) {
    this.anchor = typeof anchor === "string" ? parseAnchor(anchor) : anchor;
    this.realNow = realNow;
    this.startedAt = realNow();
  }

  now(): Date {
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
}

/** "2012-08-15" or "2012-08-15T10:00" in China time (UTC+8), like the original servers. */
export function parseAnchor(s: string): Date {
  const m = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?$/.exec(s.trim());
  if (!m) throw new Error(`anchor date must look like 2012-08-15 or 2012-08-15T10:00, got ${s}`);
  const [, y, mo, d, h = "10", mi = "00", se = "00"] = m;
  return new Date(Date.UTC(+y, +mo - 1, +d, +h - 8, +mi, +se));
}
