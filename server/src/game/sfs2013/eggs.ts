// The 亚比孵化器 of the 家园 for the 2013 server: PetEggExtension, the commands of
// the 2013 PetEggClient (library/socketclient) as the era panel pet/pethatchegg
// (PetHatchEggPanel, through PetDataService.onGetHatchEggss) sends and reads them.
//
//   1-2 getHatchEggs {st}       -> "1-2" {st: 4, es: [{ei, ri}]}            the eggs one may put in
//                                  "1-2" {st: 2, es: [{ei, ri, lt}]}        hatching, lt seconds to go
//                                  "1-2" {st: 3, pms: [{id}]}               hatched (PetHatchMessage
//                                                                           shows each by viewSinglePM)
//   1-4 hatchEggs {st, ids}     -> "1-4" {res}, then "1-2" {st: 2, …}       ids "ei,ei,…"
//   1-6 stopHatch {st}          -> "1-6" {res}, then "1-2" {st: 4, …}       the eggs come back
//   PocketMonsterExtension 1223 recyclePm {id, loc: 4} -> "2223" {res, id, loc}
//                                  放回仓库: a hatched 亚比 leaves the 孵化器
//
// The eggs are the 亚比蛋 materials (type 5, mmo.materialdata.PetEggData; bought
// from the 收费亚比蛋商品册), one entry per egg; an egg of material id N
// hatches the 亚比 of race N (沙麒麟亚比蛋 88 -> 圆角羊 88, which grows into
// 沙麒麟). The 2013 server is lost: the hatching time and the hatched 亚比's
// level are RECONSTRUCTED.

import type { World, XtContext } from "./server.ts";

export const EGG_EXT = "PetEggExtension";
export const EGG_TYPE = "5";
/** How long the eggs take (RECONSTRUCTED). */
export const HATCH_MS = 5 * 60 * 1000;
/** The 孵化器 takes fewer than 30 eggs at a time (PetHatchEggPanel). */
export const HATCH_MAX = 29;
/** A hatched 亚比's level (RECONSTRUCTED). */
export const HATCH_LEVEL = 1;

export interface HatchRec {
  eggs: { ei: number; mi: number }[];
  end: number;
  /** The 亚比 hatched and waiting in the 孵化器 (already in the 仓库). */
  pets?: number[];
}

export interface EggOwner {
  items?: Record<string, Record<string, number>>;
  hatch?: HatchRec;
}

export interface EggDeps<O extends EggOwner> {
  me: (ctx: XtContext) => Promise<O>;
  save: (o: O) => Promise<void>;
  now: () => number;
  /** Put a new 亚比 of this race into the owner's 仓库; its id. */
  hatchPet: (o: O, race: number, level: number) => Promise<number>;
}

/** Each egg the player has, with an id of its own (material id * 1000 + n). */
export function eggList(o: EggOwner): { ei: number; ri: number }[] {
  const out: { ei: number; ri: number }[] = [];
  for (const [mi, n] of Object.entries(o.items?.[EGG_TYPE] ?? {})) {
    for (let k = 0; k < Math.min(n, 999); k++) out.push({ ei: Number(mi) * 1000 + k, ri: Number(mi) });
  }
  return out;
}

export function installEggs<O extends EggOwner>(world: World, deps: EggDeps<O>): void {
  const state = async (o: O): Promise<Record<string, unknown>> => {
    const h = o.hatch;
    if (!h) return { st: 4, es: eggList(o) };
    const now = deps.now();
    if (now < h.end) {
      const lt = Math.max(1, Math.ceil((h.end - now) / 1000));
      return { st: 2, es: h.eggs.map((e) => ({ ei: e.ei, ri: e.mi, lt })) };
    }
    if (!h.pets) {
      h.pets = [];
      for (const e of h.eggs) h.pets.push(await deps.hatchPet(o, e.mi, HATCH_LEVEL));
      await deps.save(o);
    }
    if (h.pets.length === 0) {
      delete o.hatch;
      await deps.save(o);
      return { st: 4, es: eggList(o) };
    }
    return { st: 3, pms: h.pets.map((id) => ({ id })) };
  };

  world.xt(`${EGG_EXT}.1-2`, async (ctx) => {
    const o = await deps.me(ctx);
    ctx.reply(await state(o), "1-2");
  });

  world.xt(`${EGG_EXT}.1-4`, async (ctx) => {
    const o = await deps.me(ctx);
    if (o.hatch) return ctx.reply({ res: -1 }, "1-4");
    const owned = ((o.items ??= {})[EGG_TYPE] ??= {});
    const want = String(ctx.params.ids ?? "")
      .split(",")
      .map((s) => Number(s) | 0)
      .filter((x) => x > 0);
    const eggs: { ei: number; mi: number }[] = [];
    const used: Record<string, number> = {};
    for (const ei of want) {
      const mi = String(Math.floor(ei / 1000));
      if ((owned[mi] ?? 0) - (used[mi] ?? 0) <= 0 || eggs.length >= HATCH_MAX) continue;
      used[mi] = (used[mi] ?? 0) + 1;
      eggs.push({ ei, mi: Number(mi) });
    }
    if (eggs.length === 0) return ctx.reply({ res: -2 }, "1-4");
    for (const [mi, n] of Object.entries(used)) {
      owned[mi] -= n;
      if (owned[mi] <= 0) delete owned[mi];
      ctx.reply({ amount: `${EGG_TYPE}_${mi}_0_${-n}` }, "onAmountUpdated");
    }
    o.hatch = { eggs, end: deps.now() + HATCH_MS };
    await deps.save(o);
    ctx.reply({ res: 1 }, "1-4");
    ctx.reply(await state(o), "1-2");
  });

  world.xt(`${EGG_EXT}.1-6`, async (ctx) => {
    const o = await deps.me(ctx);
    const h = o.hatch;
    if (!h || h.pets) return ctx.reply({ res: -1 }, "1-6");
    const owned = ((o.items ??= {})[EGG_TYPE] ??= {});
    const back: Record<string, number> = {};
    for (const e of h.eggs) back[e.mi] = (back[e.mi] ?? 0) + 1;
    for (const [mi, n] of Object.entries(back)) {
      owned[mi] = (owned[mi] ?? 0) + n;
      ctx.reply({ amount: `${EGG_TYPE}_${mi}_0_${n}` }, "onAmountUpdated");
    }
    delete o.hatch;
    await deps.save(o);
    ctx.reply({ res: 1 }, "1-6");
    ctx.reply(await state(o), "1-2");
  });

  world.xt("PocketMonsterExtension.1223", async (ctx) => {
    const o = await deps.me(ctx);
    const id = Number(ctx.params.id) | 0;
    const loc = Number(ctx.params.loc) | 0;
    const h = o.hatch;
    const i = h?.pets?.indexOf(id) ?? -1;
    if (!h || !h.pets || i < 0) return ctx.reply({ res: -1, id, loc }, "2223");
    h.pets.splice(i, 1);
    if (h.pets.length === 0) delete o.hatch;
    await deps.save(o);
    ctx.reply({ res: 1, id, loc }, "2223");
  });
}
