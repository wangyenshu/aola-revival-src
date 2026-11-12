// Later mini games whose buttons stand in the later copies of the scenes (UserGameExtension).
//
// 斑比向前冲 (game/ninja/ninjarush, the 2017 copy; 体育馆's btnNinjaRush):
//   89_bb1 {}               -> {suc}                    may a run start (always)
//   89_bb2 {score, money}   -> {s, m, i, st}            the run's end: score, 晶币 paid, 欢乐弹珠 (none),
//                                                       state (1: paid; the panel's other states are
//                                                       0 cheating, -1, -2, 2, 3)
// The server of those years is lost: what a run pays is RECONSTRUCTED as the coins the run
// picked up (its "money"), at most NINJA_PAY_CAP a run.
//
// 极限轰炸 (game/limitbomb, the 2017 copy of the June 2013 game; 指挥中心's btnlimitbomb; its 排行榜
// and 军衔奖励 are game/limitbombres of June 2013):
//   89_18 {}              -> {score}             the 轰炸分数 of all runs (LBPlayer.setExp: it sets the
//                                                军衔 the run starts at); a run begins
//   89_20 {score}         -> {suc}               each minute of a run, its points so far (false: the
//                                                外挂 panel)
//   89_19 {score}         -> {suc, money, type}  the run's end: its points are added, 晶豆 paid; type is
//                                                the end panel's line (messagemc frame type + 3: 1 none,
//                                                0 每局晶豆上限, 2 本周晶豆上限, -1 / -2 防沉迷)
//   89_21 {page 1–10}     -> {rank: [{rank, dd, nn, score}]}   the 排行榜, ten a page (dd user, nn nick)
//   89_23 {}              -> {flag, score}       军衔奖励: rows taken (bit i for row i), the 轰炸分数
//   89_22 {index}         -> {bn: [{type, id, num}] | null}    row index's reward, once, from 军衔
//                                                index + 2 (LBAwardPanel.getCanGet)
// From the client: the 军衔 (LBLevelConfig: 学员 up to 1999 points, 列兵 2000, 一等兵 8000, 特种兵
// 20000, 士官 50000, 军士长 100000, 校尉 300000) and the rewards the 军衔奖励 panel shows (经验 and
// 晶币 on each row). Each row from 一等兵 on shows a third thing as well, items and clothes of June
// 2013 (军士长指挥帽, 2169 in the later material data) the January 2013 client does not know: those
// are left out. The 晶豆 rates are lost: RECONSTRUCTED as one 晶豆 per LB_POINTS_PER_BEAN points, at
// most LB_BEANS_PER_RUN a run and LB_BEANS_PER_WEEK a week; a run's points count up to LB_RUN_MAX.

import { MONEY_MAX } from "./money.ts";
import { serial } from "../../core/locks.ts";
import { gainExp } from "./battle.ts";
import type { PetRecord, PetTables } from "./pets.ts";
import type { World, XtContext } from "./server.ts";

export const NINJA_PAY_CAP = 1000;
/**
 * 斑比向前冲's 晶币 count towards the day's 晶币 of the mini games (game.ts GAME_COINS_PER_DAY:
 * the same record, gameCoins): what the client says it won is paid only within it.
 */
export const NINJA_PAY_DAY = 1000;

export const LB_POINTS_PER_BEAN = 10;
export const LB_BEANS_PER_RUN = 50;
export const LB_BEANS_PER_WEEK = 500;
export const LB_RUN_MAX = 200_000;
export const LB_TOTAL_MAX = MONEY_MAX;
export const LB_BOARD_SIZE = 100;
/** LBLevelConfig.scoreConfig: the most points of 军衔 1 (学员) … 6; above the last, 7 (校尉). */
export const LB_LEVELS = [1999, 7999, 19999, 49999, 99999, 299999];
/** The 军衔奖励 rows (列兵 … 校尉): [经验, 晶币]. */
export const LB_REWARDS: [number, number][] = [
  [1888, 888],
  [3333, 1888],
  [6666, 3333],
  [10888, 6666],
  [21888, 10888],
  [36666, 21888],
];

export interface LimitBombRec {
  /** 轰炸分数 of all runs. */
  total: number;
  /** 军衔奖励 taken, bit i for row i. */
  flag: number;
  /** A run began (89_18) and has not ended. */
  run?: boolean;
  /** The week (days since 1970-01-05, a Monday, / 7) and the 晶豆 paid in it. */
  week?: number;
  beans?: number;
}

export interface MiniGameRec {
  name?: string;
  score?: number;
  jingdou?: number;
  pets?: PetRecord[];
  limitBomb?: LimitBombRec;
  /** 晶币 of the mini games today (game.ts payGame, 斑比向前冲). */
  gameCoins?: { day: string; n: number };
}

export interface LimitBombRow {
  dd: string;
  nn: string;
  score: number;
}

export interface MiniGameDeps {
  load: (ctx: XtContext) => Promise<MiniGameRec>;
  save: (record: MiniGameRec) => Promise<void>;
  /** The emulator clock (ms), for the week of the 晶豆 cap. */
  now?: () => number;
  /** The pet tables (经验 of the 军衔奖励). */
  pets?: () => Promise<PetTables>;
  /**
   * The 排行榜 of everyone (the emulator store); without it, the player alone. update reads,
   * changes and writes it one change at a time (game.ts updateShared).
   */
  board?: { get(): Promise<LimitBombRow[]>; set(rows: LimitBombRow[]): Promise<void>; update?(f: (rows: LimitBombRow[]) => LimitBombRow[]): Promise<unknown> };
}

export function lbLevel(points: number): number {
  const i = LB_LEVELS.findIndex((top) => points <= top);
  return i < 0 ? LB_LEVELS.length + 1 : i + 1;
}

const weekOf = (ms: number) => Math.floor((ms / 86_400_000 - 4) / 7);

export function installMiniGames(world: World, deps: MiniGameDeps): void {
  // The 排行榜 one change at a time (two games ending at once would lose one).
  const turn = serial();
  const updateBoard = (f: (rows: LimitBombRow[]) => LimitBombRow[]) => {
    const b = deps.board!;
    return b.update ? b.update(f) : turn(async () => b.set(f((await b.get()) ?? [])));
  };
  world.xt("UserGameExtension.89_bb1", (ctx) => ctx.reply({ suc: true }, "89_bb1"));
  world.xt("UserGameExtension.89_bb2", async (ctx) => {
    const rec = await deps.load(ctx);
    const score = Math.max(0, Number(ctx.params.score) | 0);
    const day = new Date(deps.now ? deps.now() : Date.now()).toISOString().slice(0, 10);
    if (rec.gameCoins?.day !== day) rec.gameCoins = { day, n: 0 };
    const pay = Math.min(NINJA_PAY_CAP, Math.max(0, Number(ctx.params.money) | 0), Math.max(0, NINJA_PAY_DAY - rec.gameCoins.n));
    if (pay > 0) {
      rec.gameCoins.n += pay;
      rec.score = Math.min(MONEY_MAX, (rec.score ?? 0) + pay);
      await deps.save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
    }
    ctx.reply({ s: score, m: pay, i: 0, st: 1 }, "89_bb2");
  });

  // ------------------------------------------------------------ 极限轰炸
  const lb = (rec: MiniGameRec) => (rec.limitBomb ??= { total: 0, flag: 0 });
  const points = (v: unknown) => Number(v) | 0;
  const board = async (rec: MiniGameRec): Promise<LimitBombRow[]> => {
    if (deps.board) return (await deps.board.get()) ?? [];
    const t = lb(rec).total;
    return t > 0 ? [{ dd: rec.name ?? "", nn: rec.name ?? "", score: t }] : [];
  };

  world.xt("UserGameExtension.89_18", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = lb(rec);
    g.run = true;
    await deps.save(rec);
    ctx.reply({ score: g.total }, "89_18");
  });
  world.xt("UserGameExtension.89_20", (ctx) => {
    const p = points(ctx.params.score);
    ctx.reply({ suc: p >= 0 && p <= LB_RUN_MAX }, "89_20");
  });
  world.xt("UserGameExtension.89_19", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = lb(rec);
    const p = points(ctx.params.score);
    if (p < 0 || p > LB_RUN_MAX) return ctx.reply({ suc: false, money: 0, type: 1 }, "89_19");
    // A run ends once: an end without a begun run adds and pays nothing.
    if (!g.run) return ctx.reply({ suc: true, money: 0, type: 1 }, "89_19");
    g.run = false;
    g.total = Math.min(LB_TOTAL_MAX, g.total + p);
    const week = weekOf(deps.now ? deps.now() : Date.now());
    if (g.week !== week) Object.assign(g, { week, beans: 0 });
    let money = Math.floor(p / LB_POINTS_PER_BEAN);
    let type = 1;
    if (money >= LB_BEANS_PER_RUN) {
      money = LB_BEANS_PER_RUN;
      type = 0;
    }
    if ((g.beans ?? 0) + money >= LB_BEANS_PER_WEEK) {
      money = Math.max(0, LB_BEANS_PER_WEEK - (g.beans ?? 0));
      type = 2;
    }
    g.beans = (g.beans ?? 0) + money;
    rec.jingdou = Math.min(MONEY_MAX, (rec.jingdou ?? 0) + money);
    await deps.save(rec);
    if (deps.board && p > 0) {
      const total = g.total;
      await updateBoard((all) => {
        const rows = all.filter((r) => r.dd !== rec.name);
        rows.push({ dd: rec.name ?? "", nn: rec.name ?? "", score: total });
        rows.sort((a, b) => b.score - a.score);
        return rows.slice(0, LB_BOARD_SIZE);
      });
    }
    ctx.reply({ suc: true, money, type }, "89_19");
  });
  world.xt("UserGameExtension.89_21", async (ctx) => {
    const rec = await deps.load(ctx);
    const page = Math.max(1, Math.min(10, points(ctx.params.page) || 1));
    const rows = await board(rec);
    const rank = rows.slice((page - 1) * 10, page * 10).map((r, i) => ({ rank: (page - 1) * 10 + i + 1, dd: r.dd, nn: r.nn, score: r.score }));
    ctx.reply({ rank }, "89_21");
  });
  world.xt("UserGameExtension.89_23", async (ctx) => {
    const g = lb(await deps.load(ctx));
    ctx.reply({ flag: g.flag, score: g.total }, "89_23");
  });
  world.xt("UserGameExtension.89_22", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = lb(rec);
    const i = points(ctx.params.index);
    const reward = LB_REWARDS[i];
    if (!reward || g.flag & (1 << i) || lbLevel(g.total) < i + 2) return ctx.reply({ bn: null }, "89_22");
    g.flag |= 1 << i;
    const [exp, coins] = reward;
    rec.score = (rec.score ?? 0) + coins;
    // 经验: for the first 亚比 of the bag, as the panels' other rewards of experience.
    const pet = rec.pets?.[0];
    const msgs = pet && deps.pets ? gainExp(await deps.pets(), pet, exp).msgs : [];
    await deps.save(rec);
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    for (const [c, b] of msgs) ctx.reply(b, c);
    ctx.reply({ bn: [{ type: 101, id: -1, num: exp }, { type: 100, id: -1, num: coins }] }, "89_22");
  });
}
