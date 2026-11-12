// The fights a session has won lately (battle.ts writes them), for the requests whose client
// says "I have beaten it" (念之塔's seals 98_1, 黑星堡垒's floors 84_4, 独角兽's 先哲 treasure
// 91_31): the server answers only on a win of its own that is fresh, and takes the win, so one
// win makes one claim.

import type { Session } from "../../core/emulator.ts";

export interface Win {
  /** What the client asked to fight (a boss's or task 亚比's number), else the species. */
  id: number;
  /** The scene the fight was in. */
  scene: string;
  t: number;
}

const WINS = "battle.wins";
/** A win counts for a claim this long. */
export const WIN_FRESH_MS = 10 * 60 * 1000;
/** Wins kept a session, the latest. */
export const WINS_KEPT = 8;

const listOf = (s: Session | undefined): Win[] | undefined => {
  const d = (s as { data?: Record<string, unknown> } | undefined)?.data;
  if (!d) return undefined;
  return ((d[WINS] as Win[] | undefined) ??= []);
};

export function recordWin(s: Session | undefined, id: number, scene: string, now = Date.now()): void {
  const l = listOf(s);
  if (!l) return;
  l.push({ id, scene, t: now });
  if (l.length > WINS_KEPT) l.splice(0, l.length - WINS_KEPT);
}

/** A fresh win that matches, taken (true), or none (false). */
export function takeWin(s: Session | undefined, match: (w: Win) => boolean, now = Date.now()): boolean {
  const l = listOf(s);
  if (!l) return false;
  const i = l.findIndex((w) => now - w.t <= WIN_FRESH_MS && match(w));
  if (i < 0) return false;
  l.splice(i, 1);
  return true;
}
