// 泽时进化 of 时钟大殿 (scene/clockstar3, an era scene: EvolutionFight, and its panel
// activityres/clockstar/fixclockevolution, YiShiEvolutionPanel). The three 钟 (btnClock0–2) stay
// unclickable until the server says which are fixed:
//
//   PeriodicActiveExtension zb-1 {} -> {fl}      fl: the clocks fixed, one bit each (1, 2, 4)
//   zb-2 {id}                                    clock id fixed: after a win over the 通灵巫师 the
//                                                clock calls (fightWithTaskPet 30869, Lv30/45/60)
//   zb-3 {} -> {res, pid, raceId}                the three fixed: the first 亚比, a 泽秒 (913), becomes
//                                                泽时 (915) at Lv1, its 学习力 cleared ("泽秒进化为泽时后，
//                                                等级会变成1，学习力也会清零"); the clocks start again
//                                                (the scene's YimiaoEvolution makes them clickable)
//
// The 2013 server is lost: the commands are the scene's and the panel's, the rules their words
// (RECONSTRUCTED: the fix counts only on a win of the session's own, wins.ts).

import { inFight } from "./fighting.ts";
import type { World, XtContext } from "./server.ts";
import { detailOf, followVar, learntFor, skillOf, speciesOf, statsOf, type PetOwner, type PetTables } from "./pets.ts";
import { skillsAt } from "./pmdata.ts";
import { takeWin } from "./wins.ts";

export const ZEMIAO = 913;
export const ZESHI = 915;
/** The 通灵巫师 each clock calls. */
export const CLOCK_FOE = 30869;
export const CLOCKS = 3;
const ALL = (1 << CLOCKS) - 1;
const EXT = "PeriodicActiveExtension";

export interface ClockOwner extends PetOwner {
  /** 时钟大殿's clocks fixed (bits). */
  clockFix?: number;
  followPet?: number;
}

export interface ClockDeps<O extends ClockOwner> {
  load: (ctx: XtContext) => Promise<O>;
  save: (o: O) => Promise<void>;
  tables: () => Promise<PetTables>;
}

export function installClockStar<O extends ClockOwner>(world: World, deps: ClockDeps<O>): void {
  world.xt(`${EXT}.zb-1`, async (ctx) => {
    const o = await deps.load(ctx);
    ctx.reply({ fl: (o.clockFix ?? 0) & ALL });
  });
  world.xt(`${EXT}.zb-2`, async (ctx) => {
    const id = Number(ctx.params.id);
    const o = await deps.load(ctx);
    if (!Number.isInteger(id) || id < 0 || id >= CLOCKS) return ctx.reply({ res: 0, fl: o.clockFix ?? 0 });
    // A win over the clock's 通灵巫师 in 时钟大殿, fresh, taken.
    if (!takeWin(ctx.session, (w) => w.id === CLOCK_FOE && w.scene === "clockstar3")) return ctx.reply({ res: 0, fl: o.clockFix ?? 0 });
    o.clockFix = ((o.clockFix ?? 0) | (1 << id)) & ALL;
    await deps.save(o);
    ctx.reply({ res: 1, fl: o.clockFix });
  });
  world.xt(`${EXT}.zb-3`, async (ctx) => {
    const o = await deps.load(ctx);
    const pet = o.pets?.[0];
    if (((o.clockFix ?? 0) & ALL) !== ALL || !pet || pet.race !== ZEMIAO || inFight(world, o.id ?? -1)) return ctx.reply({ res: 1 });
    const t = await deps.tables();
    const sp = speciesOf(t, ZESHI);
    if (!sp) return ctx.reply({ res: 1 });
    pet.race = ZESHI;
    pet.level = 1;
    pet.exp = 0;
    pet.ev = [0, 0, 0, 0, 0, 0];
    pet.fixed = undefined;
    pet.buff = undefined;
    if (sp.learn.length) {
      pet.skills = skillsAt(sp, 1).map((id) => skillOf(t, id));
      pet.learned = learntFor(t, ZESHI, 1, pet.skills);
    }
    pet.hp = statsOf(pet, t)[0];
    o.clockFix = 0;
    await deps.save(o);
    if (o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
    ctx.reply({ pm: detailOf(pet, o, t) }, "2211");
    ctx.reply({ res: 0, pid: pet.id, raceId: pet.race });
  });
}
