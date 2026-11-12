// 亚比研究中心's 亚比融合 and the 天赋启迪 of January 2013, for the 2013 server. The 2013 server
// is lost; the commands and reply fields are the ones the panels send and read.
//
// 亚比融合 (pet/petmixnew's PetMixService and petmixnewinit/petmixnewinitservice; PetExtension2,
// PetEggExtension): two 亚比 and a material make a 元生体, which hatches in one place of the
// galaxy (its 孵化器 there: HatchLocationConfig) into a new 亚比.
//   54e_13 {mId, sId, ss}    -> {succ, id}       mix: the main and the second 亚比 (both are
//                                                used up) and one of the formula's material; id
//                                                the 元生体 got (a material, type 2)
//   54e_14 {id}              -> nothing          put the 元生体 id into the 孵化器 of its place
//   PetEggExtension 1-2 {st: 3–9} (the fuse kinds, UserPetEgg.STATE_OFFLINE_FUSE_HATCH…6)
//                            -> "1-2" {os: st, st: 4}                    empty
//                               "1-2" {os, st: 2, es: [{ri, lt}]}        hatching: the race, seconds to go
//                               "1-2" {os, st: 3, pmList: [{pmPView: {i, r}}]}   hatched (GetPetPanel)
//   PocketMonsterExtension 1223 recyclePm {id, loc: 7}   the hatched 亚比 leaves the 孵化器
//   The formulas, levels, 元生体, places and hatching times are the panels' own tables
//   (MixFormula, HatchPanelData, HatchLocationConfig). RECONSTRUCTED: which of two forms one
//   formula gives (the 变异 one, VARIATION, one time in ten), the hatched 亚比's level.
//
// 天赋启迪 (activityres/activity130117/geniusedification, ActGeniusMainPanel; HolidayExtension):
//   0118genius_panel {pId}   -> {ba, energy}     the 亚比's 天赋 "hp#攻击#防御#特攻#特防#速度"
//   0118genius_power {pId}   -> {result, index, diff, energy}   天赋启迪: 10 启迪能量; result 2
//                                                done (天赋 index rose by diff), -1 too little energy
//   0118genius_buy {pId}     -> {res, result, index, diff}      星币启迪: 10 星币; res 1 done
//   0118genius_top {}        -> {top}            "user:nick:race;…", the 亚比 raised to 王者无敌 (kept,
//                                                not a mod's; answered empty: GENIUS_TOP_SHOWN)
//   revival_genius_energy {} -> {energy}         (the revival's: the energy, for the panel)
//   The panel's own words give the rules: 10 energy a time, 1 back for every minute online, 30 at
//   most; 天赋启迪 not for 万众瞩目 (25 stars) and above; 星币启迪 10 星币, up to 王者无敌.
//   RECONSTRUCTED: how much one 启迪 adds (GENIUS_COMMON, GENIUS_MONEY) and to which 天赋 (one
//   not full, at random); the minutes counted online are those since the panel was first asked
//   for in this session.

import { serial } from "../../core/locks.ts";
import type { PlayerState, World, XtContext } from "./server.ts";
import { isModRace } from "./mods.ts";
import { inFight } from "./fighting.ts";
import { MAX_IV } from "./pmdata.ts";
import { NO_FOLLOW, newPet, type PetRecord, type PetTables } from "./pets.ts";

export interface MixFormula {
  a: number[];
  b: number[];
  item: number;
  lva: number;
  lvb: number;
  /** The races made (first forms): [usual, 变异]. */
  makes: number[];
}

/** MixFormula._formula (pet/petmixnew), by the race made. */
export const FORMULAS: MixFormula[] = [
  { a: [37, 38, 39], b: [142, 143, 144], item: 38, lva: 50, lvb: 40, makes: [431] },
  { a: [282, 283, 284], b: [70, 71, 72], item: 41, lva: 50, lvb: 40, makes: [458] },
  { a: [422, 423, 424], b: [392, 393, 394], item: 133, lva: 40, lvb: 20, makes: [531] },
  { a: [437, 438, 439], b: [392, 393, 394], item: 133, lva: 50, lvb: 40, makes: [440] },
  { a: [82, 83, 84], b: [58, 59, 60], item: 42, lva: 40, lvb: 20, makes: [549] },
  { a: [73, 74, 75], b: [16, 17, 18], item: 90, lva: 40, lvb: 20, makes: [555] },
  { a: [256, 257, 258], b: [67, 68, 69], item: 90, lva: 40, lvb: 20, makes: [350, 353] },
  { a: [13, 14, 15], b: [46, 47, 48], item: 40, lva: 30, lvb: 30, makes: [596, 599] },
];
/** HatchPanelData.RACE_ID_2_EGG_ITEM_ID: race -> 元生体. */
export const EGG_OF: Record<number, number> = { 431: 395, 458: 398, 531: 399, 440: 396, 549: 405, 555: 406, 350: 412, 353: 413, 596: 421, 599: 422 };
/** HatchPanelData.HATCH_TOTAL_TIMES: race -> hours. */
export const HATCH_HOURS: Record<number, number> = { 431: 72, 458: 72, 531: 24, 440: 72, 549: 24, 555: 24, 350: 24, 353: 24, 596: 24, 599: 24 };
/** HatchLocationConfig: 元生体 -> the 孵化器's kind (cmdStatus), one per place. */
export const FUSE_STATE: Record<number, number> = { 395: 3, 398: 4, 399: 6, 396: 5, 405: 7, 406: 8, 412: 8, 413: 8, 421: 9, 422: 9 };
/** The 变异 form one time in VARIATION (RECONSTRUCTED). */
export const VARIATION = 10;
/** A hatched 亚比's level (RECONSTRUCTED, as the 家园's 孵化器). */
export const FUSE_LEVEL = 1;
/** PetClient.recyclePm's loc for the 融合 孵化器 (GetPetPanel). */
export const FUSE_LOC = 7;

export const GENIUS_ENERGY_MAX = 30;
export const GENIUS_ENERGY_COST = 10;
export const GENIUS_XINGBI = 10;
/** How much one 天赋启迪 and one 星币启迪 add to a 天赋: [least, most] (RECONSTRUCTED). */
export const GENIUS_COMMON: [number, number] = [1, 3];
export const GENIUS_MONEY: [number, number] = [3, 8];
export const GENIUS_TOP_KEEP = 20;
/** Whether 0118genius_top answers the list (the panel showed no rows from it yet). */
export const GENIUS_TOP_SHOWN = false;

export interface FuseRec {
  race: number;
  end: number;
  /** The 亚比 hatched (already in the 仓库), waiting to be taken. */
  pet?: number;
}

export interface LabRec {
  id: number;
  name: string;
  xingbi?: number;
  items?: Record<string, Record<string, number>>;
  pets?: PetRecord[];
  storage?: PetRecord[];
  nextPetId?: number;
  followPet?: number;
  /** The 融合 孵化器, by kind (3–9). */
  fuse?: Record<string, FuseRec>;
  /** 天赋启迪's energy and when it was last counted (ms). */
  genius?: { energy: number; t: number };
}

export interface LabDeps<R extends LabRec> {
  load: (ctx: XtContext) => Promise<R>;
  save: (rec: R) => Promise<void>;
  now: () => number;
  today: () => string;
  tables: () => Promise<PetTables>;
  get: <T>(key: string) => Promise<T | undefined>;
  set: (key: string, value: unknown) => Promise<void>;
  /** Shared state read, changed and written one change at a time (game.ts updateShared). */
  update?: <T>(key: string, f: (v: T | undefined) => T) => Promise<unknown>;
  /** The random source (tests). */
  random?: () => number;
}

/** GeniusHelper.getStarNumber and the total that makes 万众瞩目 (frame 5) and 王者无敌 (frame 6). */
export const geniusStars = (iv: number[]) =>
  iv.reduce((n, v) => n + (v <= 10 ? 1 : v <= 20 ? 2 : v <= 30 ? 3 : v <= 50 ? 4 : 5), 0);
export const STARS_WANZHONG = 25;
export const STARS_WANGZHE = 30;

const bag = (rec: LabRec, type = "2") => ((rec.items ??= {})[type] ??= {});

export function formulaFor(a: number, b: number): MixFormula | undefined {
  return FORMULAS.find((f) => f.a.includes(a) && f.b.includes(b));
}

/** The state of a 融合 孵化器 as "1-2" gives it (os added by the caller). */
export async function fuseState<R extends LabRec>(rec: R, st: number, deps: LabDeps<R>): Promise<Record<string, unknown>> {
  const f = rec.fuse?.[String(st)];
  if (!f) return { st: 4, es: [] };
  const now = deps.now();
  if (now < f.end) return { st: 2, es: [{ ri: f.race, lt: Math.max(1, Math.ceil((f.end - now) / 1000)) }] };
  if (f.pet == null) {
    const pet = newPet(rec, await deps.tables(), f.race, FUSE_LEVEL, deps.today());
    (rec.storage ??= []).push(pet);
    f.pet = pet.id;
    await deps.save(rec);
  }
  return { st: 3, pmList: [{ pmPView: { i: f.pet, r: f.race } }] };
}

/** recyclePm {id, loc: 7}: the hatched 亚比 leaves its 孵化器 (it is in the 仓库 already). */
export function fuseCollect(rec: LabRec, id: number): boolean {
  for (const [k, f] of Object.entries(rec.fuse ?? {})) {
    if (f.pet === id) {
      delete rec.fuse![k];
      return true;
    }
  }
  return false;
}

export function installYabiStudy<R extends LabRec>(world: World, deps: LabDeps<R>): void {
  // 天才榜, everyone's: one change at a time.
  const topTurn = serial();
  const rnd = deps.random ?? Math.random;
  const pick = <T>(xs: T[]) => xs[Math.floor(rnd() * xs.length)];
  const between = ([lo, hi]: [number, number]) => lo + Math.floor(rnd() * (hi - lo + 1));
  const findPet = (rec: LabRec, id: number) => rec.pets?.find((p) => p.id === id) ?? rec.storage?.find((p) => p.id === id);
  const removePet = (rec: LabRec, id: number) => {
    for (const list of [rec.pets, rec.storage]) {
      const i = list?.findIndex((p) => p.id === id) ?? -1;
      if (list && i >= 0) list.splice(i, 1);
    }
  };

  // ------------------------------------------------------------ 亚比融合
  world.xt("PetExtension2.54e_13", async (ctx) => {
    const rec = await deps.load(ctx);
    const mId = Number(ctx.params.mId) | 0;
    const sId = Number(ctx.params.sId) | 0;
    const a = findPet(rec, mId);
    const b = findPet(rec, sId);
    const f = a && b && mId !== sId ? formulaFor(a.race, b.race) : undefined;
    const items = bag(rec);
    if (!a || !b || !f || a.level < f.lva || b.level < f.lvb || (items[f.item] ?? 0) < 1) return ctx.reply({ succ: false });
    // As 放生's (pets.ts): not in a fight, not the bag's last 亚比, not one a mod's party keeps.
    const inBag = (id: number) => (rec.pets ?? []).some((p) => p.id === id);
    const bagLeft = (rec.pets ?? []).length - (inBag(mId) ? 1 : 0) - (inBag(sId) ? 1 : 0);
    const kept = (rec as { modParty?: { keep?: number } }).modParty?.keep;
    if (inFight(world, rec.id) || bagLeft < 1 || kept === mId || kept === sId) return ctx.reply({ succ: false });
    const race = f.makes.length > 1 && Math.floor(rnd() * VARIATION) === 0 ? f.makes[1] : f.makes[0];
    const egg = EGG_OF[race];
    items[f.item] -= 1;
    if (items[f.item] <= 0) delete items[f.item];
    items[egg] = (items[egg] ?? 0) + 1;
    const followed = rec.followPet === mId || rec.followPet === sId;
    removePet(rec, mId);
    removePet(rec, sId);
    if (followed) {
      delete rec.followPet;
      world.setUserVars(ctx.session, { p: NO_FOLLOW });
    }
    const shown = rec as { showPet?: number };
    if (shown.showPet === mId || shown.showPet === sId) shown.showPet = 0;
    await deps.save(rec);
    ctx.reply({ amount: `2_${f.item}_0_-1` }, "onAmountUpdated");
    ctx.reply({ amount: `2_${egg}_0_1` }, "onAmountUpdated");
    ctx.reply({ succ: true, id: egg });
  });

  world.xt("PetExtension2.54e_14", async (ctx) => {
    const rec = await deps.load(ctx);
    const egg = Number(ctx.params.id) | 0;
    const st = FUSE_STATE[egg];
    const race = Number(Object.keys(EGG_OF).find((r) => EGG_OF[Number(r)] === egg));
    const items = bag(rec);
    if (!st || !race || (items[egg] ?? 0) < 1 || rec.fuse?.[String(st)]) return;
    items[egg] -= 1;
    if (items[egg] <= 0) delete items[egg];
    (rec.fuse ??= {})[String(st)] = { race, end: deps.now() + HATCH_HOURS[race] * 3600 * 1000 };
    await deps.save(rec);
    ctx.reply({ amount: `2_${egg}_0_-1` }, "onAmountUpdated");
  });

  // ------------------------------------------------------------ 天赋启迪
  const HE = "HolidayExtension";
  const since = new WeakMap<PlayerState, number>();
  const energy = (ctx: XtContext, rec: LabRec) => {
    const now = deps.now();
    if (!since.has(ctx.player)) since.set(ctx.player, now);
    const g = (rec.genius ??= { energy: GENIUS_ENERGY_MAX, t: now });
    const from = Math.max(g.t, since.get(ctx.player)!);
    const minutes = Math.floor((now - from) / 60000);
    if (g.energy >= GENIUS_ENERGY_MAX) g.t = now;
    else if (minutes > 0) {
      g.energy = Math.min(GENIUS_ENERGY_MAX, g.energy + minutes);
      g.t = from + minutes * 60000;
    }
    return g;
  };
  const ivOf = (p: PetRecord) => (p.iv ??= [31, 31, 31, 31, 31, 31]);
  const raise = async (rec: R, p: PetRecord, amount: [number, number]) => {
    const iv = ivOf(p);
    const open = iv.map((v, i) => (v < MAX_IV ? i : -1)).filter((i) => i >= 0);
    const index = pick(open);
    const before = geniusStars(iv);
    const diff = Math.min(MAX_IV - iv[index], between(amount));
    iv[index] += diff;
    if (before < STARS_WANGZHE && geniusStars(iv) >= STARS_WANGZHE && !isModRace(p.race)) {
      const line = `${rec.name}:${rec.name}:${p.race}`;
      const change = (top: string[] | undefined) => [...(top ?? []), line].slice(-GENIUS_TOP_KEEP);
      if (deps.update) await deps.update<string[]>("area/geniusTop", change);
      else await topTurn(async () => deps.set("area/geniusTop", change(await deps.get<string[]>("area/geniusTop"))));
    }
    return { index, diff };
  };
  world.xt(`${HE}.revival_genius_energy`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = energy(ctx, rec);
    await deps.save(rec);
    ctx.reply({ energy: g.energy });
  });
  world.xt(`${HE}.0118genius_panel`, async (ctx) => {
    const rec = await deps.load(ctx);
    const p = findPet(rec, Number(ctx.params.pId) | 0);
    const g = energy(ctx, rec);
    await deps.save(rec);
    ctx.reply({ ba: p ? ivOf(p).join("#") : "0#0#0#0#0#0", energy: g.energy });
  });
  world.xt(`${HE}.0118genius_power`, async (ctx) => {
    const rec = await deps.load(ctx);
    const p = findPet(rec, Number(ctx.params.pId) | 0);
    const g = energy(ctx, rec);
    if (!p) return ctx.reply({ result: 0, energy: g.energy });
    const iv = ivOf(p);
    if (g.energy < GENIUS_ENERGY_COST) return ctx.reply({ result: -1, energy: g.energy });
    if (geniusStars(iv) >= STARS_WANZHONG || iv.every((v) => v >= MAX_IV)) return ctx.reply({ result: 0, energy: g.energy });
    g.energy -= GENIUS_ENERGY_COST;
    const r = await raise(rec, p, GENIUS_COMMON);
    await deps.save(rec);
    ctx.reply({ result: 2, ...r, energy: g.energy });
  });
  world.xt(`${HE}.0118genius_buy`, async (ctx) => {
    const rec = await deps.load(ctx);
    const p = findPet(rec, Number(ctx.params.pId) | 0);
    if (!p || ivOf(p).every((v) => v >= MAX_IV)) return ctx.reply({ res: 0, result: 0 });
    if ((rec.xingbi ?? 0) < GENIUS_XINGBI) return ctx.reply({ res: 0, result: 0 });
    rec.xingbi = (rec.xingbi ?? 0) - GENIUS_XINGBI;
    ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
    const r = await raise(rec, p, GENIUS_MONEY);
    await deps.save(rec);
    ctx.reply({ res: 1, result: 2, ...r });
  });
  world.xt(`${HE}.0118genius_top`, async (ctx) => {
    const kept = GENIUS_TOP_SHOWN ? (await deps.get<string[]>("area/geniusTop")) ?? [] : [];
    const top = kept.filter((row) => !isModRace(Number(row.split(":")[2])));
    ctx.reply({ top: top.join(";") });
  });
}
