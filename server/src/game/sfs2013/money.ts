// The money of an 奥拉 (晶币 score, 星币 xingbi, 晶豆 jingdou, 奥币 aobi): whole numbers from 0 to
// MONEY_MAX, as the 2013 client shows them (seven digits). Every handler adds within it, and
// game.ts keeps a record within it whenever it is saved (a handler that forgot cannot go over).

export const MONEY_MAX = 9_999_999;
export const MONEY_FIELDS = ["score", "xingbi", "jingdou", "aobi"] as const;

/** n within 0 … MONEY_MAX (a whole number). */
export const capMoney = (n: unknown): number => {
  const v = Math.floor(Number(n) || 0);
  return v < 0 ? 0 : v > MONEY_MAX ? MONEY_MAX : v;
};

/** A record's money within its bounds (the fields it has). */
export function keepMoney(rec: Record<string, unknown>): void {
  for (const k of MONEY_FIELDS) if (rec[k] !== undefined) rec[k] = capMoney(rec[k]);
}
