import assert from "node:assert/strict";
import { test } from "node:test";
import {
  LB_BEANS_PER_RUN,
  LB_BEANS_PER_WEEK,
  LB_POINTS_PER_BEAN,
  LB_REWARDS,
  installMiniGames,
  lbLevel,
  type LimitBombRow,
  type MiniGameRec,
} from "../src/game/sfs2013/minigames.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup(rec: MiniGameRec, now = { ms: Date.UTC(2013, 0, 25) }) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  let rows: LimitBombRow[] = [{ dd: "其他人", nn: "其他人", score: 5000 }];
  installMiniGames(world, {
    load: async () => rec,
    save: async () => {},
    now: () => now.ms,
    board: { get: async () => rows, set: async (r) => void (rows = r) },
  });
  const call = async (cmd: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: rec.name }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    await handlers.get(`UserGameExtension.${cmd}`)!(ctx, cmd);
    return replies;
  };
  const last = async (cmd: string, params: Record<string, unknown> = {}) => (await call(cmd, params)).find(([c]) => c === cmd)![1];
  return { call, last, now, rows: () => rows };
}

test("极限轰炸: 军衔 from the client's LBLevelConfig", () => {
  assert.equal(lbLevel(0), 1);
  assert.equal(lbLevel(1999), 1);
  assert.equal(lbLevel(2000), 2);
  assert.equal(lbLevel(100000), 6);
  assert.equal(lbLevel(300000), 7);
});

test("极限轰炸: a run's points add up once, pay 晶豆 within the caps, go on the 排行榜", async () => {
  const rec: MiniGameRec = { name: "小奥拉" };
  const { last, now, rows } = setup(rec);
  assert.deepEqual(await last("89_18"), { score: 0 });
  assert.equal((await last("89_20", { score: 1200 })).suc, true);
  assert.equal((await last("89_20", { score: -1 })).suc, false);
  assert.deepEqual(await last("89_19", { score: 255 }), { suc: true, money: Math.floor(255 / LB_POINTS_PER_BEAN), type: 1 });
  assert.equal(rec.limitBomb!.total, 255);
  assert.equal(rec.jingdou, 25);
  // Ended already: nothing more.
  assert.deepEqual(await last("89_19", { score: 255 }), { suc: true, money: 0, type: 1 });
  assert.equal(rec.limitBomb!.total, 255);
  // The 排行榜: everyone's 轰炸分数, best first.
  assert.deepEqual((await last("89_21", { page: 1 })).rank, [
    { rank: 1, dd: "其他人", nn: "其他人", score: 5000 },
    { rank: 2, dd: "小奥拉", nn: "小奥拉", score: 255 },
  ]);
  assert.equal(rows().length, 2);
  // A big run: the cap of a run (type 0), then of the week (type 2).
  await last("89_18");
  assert.deepEqual(await last("89_19", { score: 100000 }), { suc: true, money: LB_BEANS_PER_RUN, type: 0 });
  for (let i = 0; i < LB_BEANS_PER_WEEK / LB_BEANS_PER_RUN; i++) {
    await last("89_18");
    await last("89_19", { score: 100000 });
  }
  assert.equal(rec.limitBomb!.beans, LB_BEANS_PER_WEEK);
  await last("89_18");
  assert.deepEqual(await last("89_19", { score: 100000 }), { suc: true, money: 0, type: 2 });
  // A new week.
  now.ms += 7 * 86_400_000;
  await last("89_18");
  assert.equal((await last("89_19", { score: 5000 })).money, 50);
});

test("极限轰炸: 军衔奖励 once each, from the 军衔 of its row", async () => {
  const rec: MiniGameRec = { name: "小奥拉", score: 0, limitBomb: { total: 8000, flag: 0 } };
  const { call, last } = setup(rec);
  assert.deepEqual(await last("89_23"), { flag: 0, score: 8000 });
  // 列兵 and 一等兵 (8000) yes, 特种兵 not yet.
  const r = await call("89_22", { index: 1 });
  assert.deepEqual(r.find(([c]) => c === "89_22")![1].bn, [
    { type: 101, id: -1, num: LB_REWARDS[1][0] },
    { type: 100, id: -1, num: LB_REWARDS[1][1] },
  ]);
  assert.deepEqual(r.find(([c]) => c === "onScoreUpdated")![1], { score: LB_REWARDS[1][1] });
  assert.equal((await last("89_22", { index: 1 })).bn, null);
  assert.equal((await last("89_22", { index: 2 })).bn, null);
  assert.equal((await last("89_22", { index: 6 })).bn, null);
  assert.ok((await last("89_22", { index: 0 })).bn);
  assert.deepEqual(await last("89_23"), { flag: 3, score: 8000 });
  assert.equal(rec.score, LB_REWARDS[0][1] + LB_REWARDS[1][1]);
});
