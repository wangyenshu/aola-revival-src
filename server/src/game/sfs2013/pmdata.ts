// 亚比 numbers for the 2013 server: species stats, skills, the attribute table
// and the experience curves, as tools/gen_pmdata.py writes them from the
// client's own PMDataList (revival/pmdata.json), and the arithmetic built on
// them.
//
// The 2013 server's formulas are lost. The client tables have the columns of
// the Pokémon games they were modelled on (base stats, effort yields, base
// exp, exp curve groups, catch values), so the formulas here are the classic
// ones those columns were made for: RECONSTRUCTED.

export interface PmSpecies {
  n: string;
  /** Base stats: hp, attack, defence, sp.attack, sp.defence, speed. */
  s: number[];
  /** Effort yields in the same order. */
  ev: number[];
  /** Attributes (属性1, 属性2; the same twice for one). */
  t: [number, number];
  /** Base experience. */
  bx: number;
  /** Experience curve group. */
  xt: string;
  /** 捕获度 1 and 2; "NA" = cannot be caught. */
  c: [string, string];
  /** Evolution chain "level-race#level-race…". */
  evo: string;
  /** Skills learnt: [level, skill id]. */
  learn: [number, number][];
}

export interface PmSkill {
  n: string;
  old?: string;
  /** Power as the client shows it (-1 for status skills). */
  p: number;
  p1?: number;
  acc: number;
  pp: number;
  pri: number;
  /** Attribute. */
  t: number;
  /** 0 physical, 1 special, 2 status. */
  k: number;
  /** Description; the effects are read from it (battle.ts). */
  d: string;
}

export interface PmData {
  species: Record<string, PmSpecies>;
  skills: Record<string, PmSkill>;
  /** chart[attacking attribute][defending attribute] = multiplier (only entries other than 1). */
  chart: Record<string, Record<string, number>>;
  /** exp[curve][level - 1] = total experience at that level. */
  exp: Record<string, number[]>;
}

export const EMPTY_PMDATA: PmData = { species: {}, skills: {}, chart: {}, exp: {} };

export const MAX_LEVEL = 100;

/**
 * 性格 (natures), as the official table of 12 January 2012 lists them
 * (aola.100bt.com/mijixinde/13841.html): the stat each raises and the one it
 * lowers (indexes into hp, attack, defence, sp.attack, sp.defence, speed);
 * 坦率 害羞 认真 实干 浮躁 are balanced. The size of the change (10%) is not
 * given there: RECONSTRUCTED after the Pokémon natures the table copies.
 */
export const NATURES: Record<string, [number, number]> = {
  孤僻: [1, 2], 固执: [1, 3], 调皮: [1, 4], 勇敢: [1, 5], 坦率: [0, 0],
  大胆: [2, 1], 淘气: [2, 3], 无虑: [2, 4], 悠闲: [2, 5], 害羞: [0, 0],
  保守: [3, 1], 稳重: [3, 2], 马虎: [3, 4], 冷静: [3, 5], 认真: [0, 0],
  沉着: [4, 1], 温顺: [4, 2], 慎重: [4, 3], 狂妄: [4, 5], 实干: [0, 0],
  胆小: [5, 1], 急躁: [5, 2], 开朗: [5, 3], 天真: [5, 4], 浮躁: [0, 0],
};
export const NATURE_NAMES = Object.keys(NATURES);

/** 天赋 (individual values) run 0–62 per stat (official guide 亚比强弱的影响因素, December 2012). */
export const MAX_IV = 62;

/**
 * Stats at a level: hp first. iv 天赋 0–62, ev 学习力 points, nature a 性格 name.
 * The classic formula with the 天赋 in place of the individual value.
 */
export function calcStats(sp: PmSpecies, level: number, iv: number[] = [], ev: number[] = [], nature?: string): number[] {
  const n = nature ? NATURES[nature] : undefined;
  return sp.s.map((base, i) => {
    const core = Math.floor(((2 * base + (iv[i] ?? 31) + Math.floor((ev[i] ?? 0) / 4)) * level) / 100);
    if (i === 0) return core + level + 10;
    const mod = n && n[0] !== n[1] ? (n[0] === i ? 1.1 : n[1] === i ? 0.9 : 1) : 1;
    return Math.floor((core + 5) * mod);
  });
}

function curve(pm: PmData, sp: PmSpecies | undefined): number[] | undefined {
  return pm.exp[sp?.xt ?? "0"] ?? pm.exp["0"];
}

/** Experience from `level` to the next one. */
export function expNeed(pm: PmData, sp: PmSpecies | undefined, level: number): number {
  const c = curve(pm, sp);
  if (!c || level >= c.length) return 20 + level * level * 4;
  return Math.max(1, c[level] - c[level - 1]);
}

/** Experience a win against a 亚比 of this species and level gives. */
export function expYield(sp: PmSpecies | undefined, level: number): number {
  return Math.max(1, Math.floor(((sp?.bx ?? 50) * level) / 7));
}

/** The (up to) four last skills learnt by `level`, oldest first. */
export function skillsAt(sp: PmSpecies, level: number): number[] {
  const ids: number[] = [];
  for (const [lv, id] of sp.learn) {
    if (lv > level) break;
    const at = ids.indexOf(id);
    if (at >= 0) ids.splice(at, 1);
    ids.push(id);
  }
  return ids.slice(-4);
}

/** Skills learnt exactly when reaching `level`. */
export function skillsLearntAt(sp: PmSpecies, level: number): number[] {
  return sp.learn.filter(([lv]) => lv === level && level > 0).map(([, id]) => id);
}

/** The race this one becomes at `level`, or 0. */
export function evolutionAt(sp: PmSpecies, race: number, level: number): number {
  const steps = sp.evo
    .split("#")
    .map((s) => s.split("-").map(Number))
    .filter((x) => x.length === 2 && !x.some(Number.isNaN));
  const i = steps.findIndex(([, r]) => r === race);
  if (i < 0 || i + 1 >= steps.length) return 0;
  const [lv, next] = steps[i + 1];
  return lv > 0 && level >= lv ? next : 0;
}

/** Attribute multiplier of a skill attribute against a defender's attributes. */
export function typeMultiplier(pm: PmData, atk: number, def: [number, number]): number {
  const row = pm.chart[String(atk)] ?? {};
  const m1 = row[String(def[0])] ?? 1;
  const m2 = def[1] !== def[0] ? (row[String(def[1])] ?? 1) : 1;
  return m1 * m2;
}

// ---------------------------------------------------------------- catch level

/**
 * The player's 捕捉等级: the 2013 pet/petcatchgiftservice builds the table
 * expLevel[n] = expLevel[n-1] + (n-1)*30 + round((n-1)/10)*(n-1)*15 and finds the
 * level whose span equals ccle + cnx (PlayerBriefInfo).
 */
const CATCH_TABLE: number[] = (() => {
  const t = [0, 0];
  for (let n = 2; n <= 101; n++) t.push(t[n - 1] + (n - 1) * 30 + Math.round((n - 1) / 10) * (n - 1) * 15);
  return t;
})();

export function catchLevel(total: number): { clv: number; ccle: number; cnx: number; pct: number } {
  let clv = 1;
  while (clv < 100 && CATCH_TABLE[clv + 1] <= total) clv++;
  const span = CATCH_TABLE[clv + 1] - CATCH_TABLE[clv];
  const ccle = Math.min(span, total - CATCH_TABLE[clv]);
  return { clv, ccle, cnx: span - ccle, pct: Math.floor((ccle / span) * 100) };
}
