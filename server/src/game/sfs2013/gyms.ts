// The 道馆 of 幻灵之域 (November 2012): the masters' fights of the panels their menus open
// (activityres/activity121115 and 121122, era files; rebuilt control ScenePatches MENUS), on
// PetClient2.startFight (PetExtension 54_22, battle.ts) and PeriodicActiveExtension:
//
//   踢馆 (the challenge panels)
//     54_22 {type: 84}                    幻雷 (thunder/thunderchallenge)
//     54_22 {type: 86, id: 1, buff: 1}    幻炎 (activity_fire/huanyanchallenge)
//     54_22 {type: 87}                    幻流 (huanliu/huanliuchallenge)
//     54_22 {type: 88, id: 3}             幻·夜冥 (fate/huanmingchallenge), after its 命运 (Dark_7)
//     -> 54_22 {res}, then the battle (2303, 2401 …); the end's 2403 carries myFinalRaceId, the
//        player's 亚比 that ended it, which the panels check for the skill stone:
//     20121113_hlf {h}     -> {n}   幻雷: n 1 = 幻雷•迅雷闪 (619) given (h: 幻雷 ended it)
//     Fire_7 {suc}         -> {bn}  幻炎: bn 1 = 幻炎•爆炎斩 (617)   (suc: 灵炎 / 幻炎 ended it)
//     20121116water_c2 {fin} -> {res} 幻流: res 1 = 幻流•御流术 (618) (fin: 灵流 / 幻流)
//     Dark_7 {}            -> {s0 … s5}  幻冥's 命运: the player's 亚比's stats for the next 踢馆,
//                                         percent up or down (体力, 攻击, 防御, 特攻, 特防, 速度)
//     Dark_8 {suc}         -> {bn}  幻冥: bn 1 = 幻冥•虚冥印 (622)   (suc: 灵冥 / 幻冥)
//   命运玩偶 (fate/fatedoll)'s 亚比: 54_22 {type: 88, id, raceId}
//   雷霆之塔 (thunder/thundertower): ten floors against the clock
//     20121112_openthunder {} -> {suc}; then each floor IPetFight.timerFight({layer, min, sec}),
//       which the rebuilt pet/loginpetfightnew sends as 54_22 {type: 85, layer, min, sec};
//     20121112_ted (with the end of a won floor) {fl, ps, ra, p4}: floor passed, seconds since the
//       start, rank, the 4th (special) floor passed; 20121112_tel {} clears the run;
//     20121112_getmyrank {} -> {r: "rank:best seconds", p, c (runs finished)}
//   治疗 (every panel's 治疗 button, PetClient2.pmRevealAllHp): 54_4 {} -> 54_4 {res}, 50 晶币
//     (free for 蓝宝石).
//
// The 2013 server is lost: the masters' 亚比 and levels, the 雷霆之塔's floors, the odds of the
// stones and the 命运's range are RECONSTRUCTED. 幻光's 踢馆 takes a team of two (its panel says so)
// and 友情的试炼 (54_22 type 89) a friend's 亚比: neither is played here (refused with a message).

import type { World, XtContext } from "./server.ts";
import { normalisePet, statsOf, type PetOwner, type PetRecord, type PetTables } from "./pets.ts";

export const GYM_THUNDER = 84;
export const GYM_TOWER = 85;
export const GYM_FIRE = 86;
export const GYM_WATER = 87;
export const GYM_DARK = 88;
export const GYM_LIGHT = 89;

/** The masters' 亚比 in their 踢馆: their own kind at Lv100 (RECONSTRUCTED). */
export const GYM_MASTERS: Record<number, { race: number; level: number; name: string }> = {
  [GYM_THUNDER]: { race: 1300, level: 100, name: "幻雷" },
  [GYM_FIRE]: { race: 1296, level: 100, name: "幻炎" },
  [GYM_WATER]: { race: 1298, level: 100, name: "幻流" },
  [GYM_DARK]: { race: 1309, level: 100, name: "幻冥" },
};

/** The skill stones of the 踢馆 (materials type 2) and the 亚比 a panel asks to end the fight with. */
export const GYM_STONES: Record<number, { item: number; pets: number[]; cmd: string }> = {
  [GYM_THUNDER]: { item: 619, pets: [1300], cmd: "20121113_hlf" },
  [GYM_FIRE]: { item: 617, pets: [1295, 1296], cmd: "Fire_7" },
  [GYM_WATER]: { item: 618, pets: [1297, 1298], cmd: "20121116water_c2" },
  [GYM_DARK]: { item: 622, pets: [1308, 1309], cmd: "Dark_8" },
};

/** Odds of a stone when a won 踢馆 was not ended by the gym's own 亚比 (RECONSTRUCTED). */
export const STONE_CHANCE = 0.3;

/** 雷霆之塔's floors: 电 亚比 stronger floor by floor, 雷纳瑞 on the 4th (special) floor, 幻雷 on top (RECONSTRUCTED). */
export const TOWER_FLOORS: { race: number; level: number }[] = [
  { race: 1299, level: 30 }, // 灵雷
  { race: 339, level: 35 }, // 霹雳闪电狗
  { race: 1074, level: 40 }, // 超电流企鹅
  { race: 469, level: 50 }, // 雷纳瑞
  { race: 1078, level: 55 }, // 罗宾斯
  { race: 1036, level: 60 }, // 狂雷鸟
  { race: 589, level: 65 }, // 雷角兽
  { race: 236, level: 70 }, // 雷鸣女王
  { race: 891, level: 80 }, // 刀锋
  { race: 1300, level: 100 }, // 幻雷
];
export const TOWER_SPECIAL_FLOOR = 4;

/** 命运玩偶's 亚比 (FightPetAction: 10175 / 10697 and 20175 / 20697): variant 1 at Lv35, 2 at Lv55 (RECONSTRUCTED). */
export function dollLevel(raceId: number): number {
  return Math.floor(raceId / 10000) >= 2 ? 55 : 35;
}

/** 幻冥's 命运: six percentages, each up or down by 5 to 30 (RECONSTRUCTED; the panel shows them signed). */
export function rollFate(rng: () => number): number[] {
  return Array.from({ length: 6 }, () => (rng() < 0.5 ? -1 : 1) * (5 + Math.floor(rng() * 26)));
}

/** Stats (hp first) changed by a 命运's percentages. */
export function applyFate(stats: number[], fate: number[] | undefined): number[] {
  if (!fate) return stats;
  return stats.map((v, i) => Math.max(1, Math.round(v * (1 + (fate[i] ?? 0) / 100))));
}

export interface GymFightRec {
  /** The last won 踢馆 not yet paid, by type, with the 亚比 that ended it. */
  won?: Record<string, number>;
  /** Day a stone was last given, by type ("每天只能获得一个"). */
  stoneDay?: Record<string, string>;
  /** Types whose first stone (the one a win with the gym's own 亚比 always brings) was given. */
  firstStone?: number[];
  /** 幻冥's 命运 for the next 踢馆. */
  fate?: number[];
  /** 雷霆之塔: the run now (start on the game clock, floors passed, the special floor) and the records. */
  tower?: { start: number; floor: number; p4: boolean } | null;
  towerBest?: number;
  towerRuns?: number;
  /** 玩偶迷阵: the run now (start, dolls beaten, damage done, ended), the best 战斗力评价, the last run's. */
  maze?: { start: number; num: number; hurt: number; over: boolean } | null;
  mazeBest?: number;
  mazeLast?: { record: number; claimed: boolean };
  /** 最强防御PK战: the best rounds ever, today's best and the rewards taken today, the 防御祝福 kept. */
  waterMax?: number;
  waterDay?: { day: string; best: number; taken: number[] };
  waterBless?: number;
}

/**
 * 玩偶迷阵 (命运道馆; activity121122/dollmaze, the copy of 2015): 命运玩偶 one after another until the
 * player's 亚比 all fall, each with 幻冥's random 战斗祝福 on both sides ("幻冥会给你和对手随机战斗祝福");
 * a 战斗力评价 for the run ("挑战后按每场表现给出战斗力评价") and the rewards of its marks (2000, 5000,
 * 10000, 20000分). The 2012 server is lost: the dolls' levels (Lv30, five more for each), the 评价 (the
 * damage done and MAZE_PER_DOLL for each doll beaten) are RECONSTRUCTED.
 */
export const MAZE_DOLLS = [175, 697];
export const MAZE_PER_DOLL = 200;
export const MAZE_TIERS = [2000, 5000, 10000, 20000];
export function mazeDoll(num: number): { race: number; level: number } {
  return { race: MAZE_DOLLS[num % MAZE_DOLLS.length], level: Math.min(100, 30 + 5 * num) };
}
export function mazeRecord(run: { num: number; hurt: number }): number {
  return run.hurt + MAZE_PER_DOLL * run.num;
}

/**
 * 最强防御PK战 (御水道馆; activity121115/water/waterdefence, the copy of 2014): "考验首宠的防御最高极限",
 * 30 局 one after another, each won by standing WATER_ROUNDS[局] rounds (the panel's
 * WaterDefenceConfig.petsConfig) with the first 亚比 (no switching); a 防御祝福 (双防 +100, 体力 +200;
 * 3 星币 each) may be used for the run. The day's rewards (每天的进度奖励会清空) at 5, 10, 15, 20 局:
 * 2 摇摇果实, 幻流进化石 ("成功防御10局可获得幻流进化石"), 5 of a later item (RECONSTRUCTED: 防御强化药剂
 * 384), 8888 经验. The attackers (灵炎 then 幻炎, stronger 局 by 局) are RECONSTRUCTED.
 */
export const WATER_ROUNDS = [2, 2, 3, 3, 4, 4, 4, 5, 5, 5, 2, 3, 3, 3, 3, 4, 4, 5, 5, 6, 3, 3, 4, 5, 5, 5, 5, 6, 6, 6];
export const WATER_BLESS_PRICE = 3;
export const WATER_BLESS = { def: 100, hp: 200 };
export const WATER_TIERS: { at: number; bn: { type: number; id: number; num: number } }[] = [
  { at: 5, bn: { type: 2, id: 419, num: 2 } },
  { at: 10, bn: { type: 2, id: 615, num: 1 } },
  { at: 15, bn: { type: 2, id: 384, num: 5 } },
  { at: 20, bn: { type: 101, id: -1, num: 8888 } },
];
export function waterAttacker(stage: number): { race: number; level: number } {
  return { race: stage <= 15 ? 1295 : 1296, level: Math.min(100, 38 + 2 * stage) };
}
export function waterDay(g: GymFightRec, today: string): { day: string; best: number; taken: number[] } {
  if (g.waterDay?.day !== today) g.waterDay = { day: today, best: 0, taken: [] };
  return g.waterDay;
}
/** A run's end: the records, and the push the panel shows (20121116water_finBattle {r, isnew, max, min, rank}). */
export function waterRunEnd(g: GymFightRec, passed: number, today: string): [string, Record<string, unknown>] {
  const d = waterDay(g, today);
  d.best = Math.max(d.best, passed);
  const isnew = passed > (g.waterMax ?? 0);
  g.waterMax = Math.max(g.waterMax ?? 0, passed);
  return ["20121116water_finBattle", { r: passed, isnew, max: g.waterMax, min: 0, rank: 0 }];
}

export const gymOf = (o: object): GymFightRec => ((o as { gymFights?: GymFightRec }).gymFights ??= {});

export interface GymDeps {
  load: (ctx: XtContext) => Promise<PetOwner & { score?: number; vip?: boolean }>;
  save: (owner: PetOwner) => Promise<void>;
  tables: () => Promise<PetTables>;
  today: () => string;
  now: () => number;
  rng: () => number;
  /** Experience for a 亚比, with its levels and evolutions (battle.ts gainExp): the replies. */
  gainExp: (t: PetTables, pet: PetRecord, n: number) => [string, Record<string, unknown>][];
}

/** A won 踢馆 (the battle's onWin): remembered for its panel's bonus command. */
export function gymWon(o: object, type: number, finalRace: number): void {
  (gymOf(o).won ??= {})[String(type)] = finalRace;
}

/**
 * The bonus command of a won 踢馆: a stone when the fight was won (and not yet paid), at most one a
 * day; always the first time the gym's own 亚比 ended it, else at STONE_CHANCE. Returns the item
 * given, or 0.
 */
export function gymStone(o: PetOwner & { items?: Record<string, Record<string, number>> }, type: number, today: string, rng: () => number): number {
  const g = gymOf(o);
  const s = GYM_STONES[type];
  const fin = g.won?.[String(type)];
  if (!s || fin === undefined) return 0;
  delete g.won![String(type)];
  if ((g.stoneDay ??= {})[String(type)] === today) return 0;
  const own = s.pets.includes(fin);
  const first = own && !(g.firstStone ?? []).includes(type);
  if (!first && rng() >= STONE_CHANCE) return 0;
  if (first) (g.firstStone ??= []).push(type);
  g.stoneDay[String(type)] = today;
  const bag = ((o.items ??= {})["2"] ??= {});
  bag[String(s.item)] = (bag[String(s.item)] ?? 0) + 1;
  return s.item;
}

/** 雷霆之塔's rank (RECONSTRUCTED: the 2013 server's ranking is lost; one player, rank 1 once finished). */
export const towerRank = (g: GymFightRec) => (g.towerBest ? 1 : 0);

export function installGyms(world: World, deps: GymDeps): void {
  const PA = "PeriodicActiveExtension";
  // 玩偶迷阵: Dark_0 {} -> {max}; Dark_1 {hurt} after each fight -> {hurt, time, num, record, max, rank}
  // once the run has ended (the doll's fight lost; the panel then shows the run), else {res: 1};
  // Dark_2 {} -> {bn} the rewards of the marks the last run reached, once: 1000 经验, 5 摇摇果实 (419),
  // 10000 经验 (for the first 亚比 of the bag); the 20000分 one, the 2015 panel's "70级超暗精灵", is a
  // later 亚比 and is not given. (The hurt the client sends is not taken: the battle's own.)
  // 最强防御PK战: 20121116water_r1 {} -> {max, status}; _r2 {} -> {times, status} today's best and the
  // rewards (one character each: 0 to take, 1 taken, 2 not reached); _r3 {index} -> {res, bn}; _r4 {num}
  // -> {res} 防御祝福 for 星币 (1, 101 too few); _r5 {} -> {num} 防御祝福 kept. The fights: 54_22 {type: 85,
  // lv, buff} (the panel's IPetFight.insistFight; battle.ts), and the end of a run pushed with its last fight.
  const waterStatus = (g: GymFightRec) => {
    const d = waterDay(g, deps.today());
    return WATER_TIERS.map((w, i) => (d.taken.includes(i) ? 1 : d.best >= w.at ? 0 : 2)).join("");
  };
  world.xt(`${PA}.20121116water_r1`, async (ctx) => {
    const g = gymOf(await deps.load(ctx));
    ctx.reply({ max: g.waterMax ?? 0, status: waterStatus(g) }, "20121116water_r1");
  });
  world.xt(`${PA}.20121116water_r2`, async (ctx) => {
    const g = gymOf(await deps.load(ctx));
    ctx.reply({ times: waterDay(g, deps.today()).best, status: waterStatus(g) }, "20121116water_r2");
  });
  world.xt(`${PA}.20121116water_r3`, async (ctx) => {
    const o = (await deps.load(ctx)) as PetOwner & { items?: Record<string, Record<string, number>> };
    const g = gymOf(o);
    const i = Number(ctx.params.index) | 0;
    const tier = WATER_TIERS[i];
    const d = waterDay(g, deps.today());
    if (!tier || d.taken.includes(i) || d.best < tier.at) return ctx.reply({ res: 0 }, "20121116water_r3");
    d.taken.push(i);
    const { type, id, num } = tier.bn;
    if (type === 101) {
      const pet = o.pets?.[0];
      if (pet) for (const [c, b] of deps.gainExp(await deps.tables(), pet, num)) ctx.reply(b, c);
    } else {
      const bag = ((o.items ??= {})[String(type)] ??= {});
      bag[String(id)] = (bag[String(id)] ?? 0) + num;
      ctx.reply({ amount: `${type}_${id}_0_${num}` }, "onAmountUpdated");
    }
    await deps.save(o);
    ctx.reply({ res: 1, bn: [tier.bn] }, "20121116water_r3");
  });
  world.xt(`${PA}.20121116water_r4`, async (ctx) => {
    const o = (await deps.load(ctx)) as PetOwner & { xingbi?: number };
    const g = gymOf(o);
    const num = Math.max(1, Math.min(999, Number(ctx.params.num) | 0));
    const cost = num * WATER_BLESS_PRICE;
    if ((o.xingbi ?? 0) < cost) return ctx.reply({ res: 101 }, "20121116water_r4");
    o.xingbi = (o.xingbi ?? 0) - cost;
    g.waterBless = (g.waterBless ?? 0) + num;
    await deps.save(o);
    ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
    ctx.reply({ res: 1 }, "20121116water_r4");
  });
  world.xt(`${PA}.20121116water_r5`, async (ctx) => ctx.reply({ num: gymOf(await deps.load(ctx)).waterBless ?? 0 }, "20121116water_r5"));
  world.xt(`${PA}.Dark_0`, async (ctx) => ctx.reply({ max: gymOf(await deps.load(ctx)).mazeBest ?? 0 }, "Dark_0"));
  world.xt(`${PA}.Dark_1`, async (ctx) => {
    const o = await deps.load(ctx);
    const g = gymOf(o);
    const run = g.maze;
    if (!run || !run.over) return ctx.reply({ res: 1 }, "Dark_1");
    const record = mazeRecord(run);
    const old = g.mazeBest ?? 0;
    g.mazeBest = Math.max(old, record);
    g.mazeLast = { record, claimed: false };
    g.maze = null;
    await deps.save(o);
    const time = Math.max(0, Math.round((deps.now() - run.start) / 1000));
    ctx.reply({ hurt: run.hurt, time, num: run.num, record, max: g.mazeBest, rank: 0 }, "Dark_1");
  });
  world.xt(`${PA}.Dark_2`, async (ctx) => {
    const o = await deps.load(ctx) as PetOwner & { items?: Record<string, Record<string, number>> };
    const g = gymOf(o);
    const last = g.mazeLast;
    if (!last || last.claimed || last.record < MAZE_TIERS[0]) return ctx.reply({ bn: [] }, "Dark_2");
    last.claimed = true;
    const bn: { type: number; id: number; num: number }[] = [];
    let exp = 0;
    if (last.record >= MAZE_TIERS[0]) exp += 1000;
    if (last.record >= MAZE_TIERS[1]) {
      const bag = ((o.items ??= {})["2"] ??= {});
      bag["419"] = (bag["419"] ?? 0) + 5;
      ctx.reply({ amount: "2_419_0_5" }, "onAmountUpdated");
      bn.push({ type: 2, id: 419, num: 5 });
    }
    if (last.record >= MAZE_TIERS[2]) exp += 10000;
    const pet = o.pets?.[0];
    if (exp && pet) {
      for (const [c, b] of deps.gainExp(await deps.tables(), pet, exp)) ctx.reply(b, c);
      bn.unshift({ type: 101, id: -1, num: exp });
    }
    await deps.save(o);
    ctx.reply({ bn }, "Dark_2");
  });
  const amount = (ctx: XtContext, item: number) => ctx.reply({ amount: `2_${item}_0_1` }, "onAmountUpdated");
  // The stones of the 踢馆.
  world.xt(`${PA}.20121113_hlf`, async (ctx) => {
    const o = await deps.load(ctx);
    const item = gymStone(o, GYM_THUNDER, deps.today(), deps.rng);
    await deps.save(o);
    if (item) amount(ctx, item);
    ctx.reply({ n: item ? 1 : 0 });
  });
  world.xt(`${PA}.Fire_7`, async (ctx) => {
    const o = await deps.load(ctx);
    const item = gymStone(o, GYM_FIRE, deps.today(), deps.rng);
    await deps.save(o);
    if (item) amount(ctx, item);
    ctx.reply({ bn: item ? 1 : 0 });
  });
  world.xt(`${PA}.20121116water_c2`, async (ctx) => {
    const o = await deps.load(ctx);
    const item = gymStone(o, GYM_WATER, deps.today(), deps.rng);
    await deps.save(o);
    if (item) amount(ctx, item);
    ctx.reply({ res: item ? 1 : 0 });
  });
  world.xt(`${PA}.Dark_8`, async (ctx) => {
    const o = await deps.load(ctx);
    const item = gymStone(o, GYM_DARK, deps.today(), deps.rng);
    await deps.save(o);
    if (item) amount(ctx, item);
    ctx.reply({ bn: item ? 1 : 0 });
  });
  // 幻冥's 命运 for the next 踢馆.
  world.xt(`${PA}.Dark_7`, async (ctx) => {
    const o = await deps.load(ctx);
    const fate = rollFate(deps.rng);
    gymOf(o).fate = fate;
    await deps.save(o);
    ctx.reply(Object.fromEntries(fate.map((v, i) => [`s${i}`, v])));
  });
  // 雷霆之塔.
  world.xt(`${PA}.20121112_openthunder`, async (ctx) => {
    const o = await deps.load(ctx);
    gymOf(o).tower = { start: deps.now(), floor: 0, p4: false };
    await deps.save(o);
    ctx.reply({ suc: true });
  });
  world.xt(`${PA}.20121112_tel`, async (ctx) => {
    const o = await deps.load(ctx);
    gymOf(o).tower = null;
    await deps.save(o);
    ctx.reply({});
  });
  world.xt(`${PA}.20121112_getmyrank`, async (ctx) => {
    const g = gymOf(await deps.load(ctx));
    ctx.reply({ r: `${towerRank(g)}:${g.towerBest ?? 0}`, p: "0,0,0,0", c: g.towerRuns ?? 0 });
  });
  // 治疗: every 亚比 of the bag back to full, 50 晶币 (free for 蓝宝石).
  world.xt("PetExtension.54_4", async (ctx) => {
    const o = await deps.load(ctx);
    const t = await deps.tables();
    // nd: PetClient2.pmRevealAllHpFree, the free 恢复 of an activity's run (最强防御PK战 before each 局).
    const cost = o.vip || ctx.params.nd ? 0 : 50;
    // A mod's party out that heals nobody (mods.ts).
    if ((o as { modParty?: { noHeal?: string } }).modParty?.noHeal) return ctx.reply({ res: false }, "54_4");
    if ((o.score ?? 0) < cost) return ctx.reply({ res: false }, "54_4");
    o.score = (o.score ?? 0) - cost;
    for (const p of o.pets ?? []) {
      normalisePet(p, t);
      p.hp = statsOf(p, t)[0];
      for (const s of p.skills) s.pp = s.max;
    }
    await deps.save(o);
    if (cost) ctx.reply({ score: o.score }, "onScoreUpdated");
    ctx.reply({ res: true }, "54_4");
  });
}

/**
 * The 雷霆之塔 floor that ended (the battle's onWin): the run's state and its 20121112_ted.
 * A floor out of turn (no run, or not the next) counts nothing.
 */
export function towerFloorWon(o: object, layer: number, now: number): [string, Record<string, unknown>][] {
  const g = gymOf(o);
  const run = g.tower;
  if (!run || layer !== run.floor + 1) return [];
  run.floor = layer;
  if (layer === TOWER_SPECIAL_FLOOR) run.p4 = true;
  const ps = Math.max(1, Math.round((now - run.start) / 1000));
  if (layer === TOWER_FLOORS.length) {
    g.towerRuns = (g.towerRuns ?? 0) + 1;
    if (!g.towerBest || ps < g.towerBest) g.towerBest = ps;
  }
  return [["20121112_ted", { fl: layer, ps, ra: towerRank(g), p4: run.p4 }]];
}
