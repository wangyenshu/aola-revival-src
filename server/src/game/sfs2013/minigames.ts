// Later mini games whose buttons stand in the later copies of the scenes (UserGameExtension).
//
// 斑比向前冲 (game/ninja/ninjarush, the 2017 copy; 体育馆's btnNinjaRush):
//   89_bb1 {}               -> {suc}                    may a run start (always)
//   89_bb2 {score, money}   -> {s, m, i, st}            the run's end: score, 晶币 paid, 欢乐弹珠 (none),
//                                                       state (1: paid; the panel's other states are
//                                                       0 cheating, -1, -2, 2, 3)
// The server of those years is lost: what a run pays is RECONSTRUCTED as the coins the run
// picked up (its "money"), at most NINJA_PAY_CAP a run.

import type { World, XtContext } from "./server.ts";

export const NINJA_PAY_CAP = 1000;

export interface MiniGameDeps {
  load: (ctx: XtContext) => Promise<{ score?: number }>;
  save: (record: { score?: number }) => Promise<void>;
}

export function installMiniGames(world: World, deps: MiniGameDeps): void {
  world.xt("UserGameExtension.89_bb1", (ctx) => ctx.reply({ suc: true }, "89_bb1"));
  world.xt("UserGameExtension.89_bb2", async (ctx) => {
    const rec = await deps.load(ctx);
    const score = Math.max(0, Number(ctx.params.score) | 0);
    const pay = Math.min(NINJA_PAY_CAP, Math.max(0, Number(ctx.params.money) | 0));
    if (pay > 0) {
      rec.score = (rec.score ?? 0) + pay;
      await deps.save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
    }
    ctx.reply({ s: score, m: pay, i: 0, st: 1 }, "89_bb2");
  });
}
