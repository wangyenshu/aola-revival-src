import assert from "node:assert/strict";
import { test } from "node:test";
import { FLAG_COST, FLAG_GIFT, FLAG_WAIT_MS, GENERALS, WAR_SOUL, installFightKing, type WushenOwner } from "../src/game/sfs2013/fightking.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const o: WushenOwner = { id: 1, name: "小奥拉", xingbi: 500, score: 0, items: {}, pets: [] };
  const clock = { now: Date.UTC(2012, 8, 25, 2) };
  installFightKing(world, { me: async () => o, save: async () => {}, today: () => "2012-09-25", now: () => clock.now });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: o.name }, reply: (b: Record<string, unknown>, c?: string) => replies.push([c, b]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  return { o, call, clock };
}

test("黄巾军旗: the day's 战魂, 注入 with a wait, the wait cleared with 星币", async () => {
  const { o, call, clock } = setup();
  assert.deepEqual((await call("PeriodicActiveExtension.w_soul_2")).at(-1)![1], { lt: 0, left: 0, right: 0, doo: 0 });
  assert.equal((await call("PeriodicActiveExtension.w_soul_5")).at(-1)![1].r, true);
  assert.equal((await call("PeriodicActiveExtension.w_soul_5")).at(-1)![1].r, false, "once a day");
  assert.equal(o.items!["2"][String(WAR_SOUL)], FLAG_GIFT);
  assert.deepEqual((await call("PeriodicActiveExtension.w_soul_3", { t: 1 })).at(-1)![1], { res: 0, nx: 1 });
  assert.equal(o.items!["2"][String(WAR_SOUL)], FLAG_GIFT - FLAG_COST);
  assert.equal((await call("PeriodicActiveExtension.w_soul_3", { t: 1 })).at(-1)![1].res, 1, "waiting");
  clock.now += 60_000;
  assert.equal((await call("PeriodicActiveExtension.w_soul_1")).at(-1)![1].lt, (FLAG_WAIT_MS - 60_000) / 1000);
  assert.equal((await call("PeriodicActiveExtension.w_soul_4")).at(-1)![1].res, 1);
  assert.equal(o.xingbi, 500 - 30);
  assert.deepEqual((await call("PeriodicActiveExtension.w_soul_3", { t: 1 })).at(-1)![1], { res: 0, nx: 2 });
});

test("the generals: 关羽's seals and egg, 赵云 with 星币, 将军令 left, 将军榜", async () => {
  const { o, call } = setup();
  assert.equal((await call("PeriodicActiveExtension.w_soul_7")).at(-1)![1].res, "0,0,0,0");
  for (const id of [0, 1, 2]) assert.equal((await call("PeriodicActiveExtension.w_soul_8", { id })).at(-1)![1].res, 1);
  assert.equal(o.xingbi, 500 - 30 - 50 - 100);
  assert.equal((await call("PeriodicActiveExtension.w_soul_9")).at(-1)![1].res, 1);
  assert.equal(o.items!["5"][String(GENERALS.guanyu.egg)], 1);
  assert.equal((await call("PeriodicActiveExtension.w_soul_7")).at(-1)![1].res, "1,1,1,1");
  assert.equal((await call("PeriodicActiveExtension.w_soul_12")).at(-1)![1].suc, false, "两种兵器 first");
  assert.equal((await call("PeriodicActiveExtension.w_soul_11", { id: 0 })).at(-1)![1].res, 1);
  o.xingbi = 50;
  assert.equal((await call("PeriodicActiveExtension.w_soul_11", { id: 1 })).at(-1)![1].res, 101, "too few 星币");
  assert.deepEqual((await call("PeriodicActiveExtension.w_soul_10")).at(-1)![1], { times: 5, fight1: true, fight2: false, got: false });
  assert.equal((await call("HolidayExtension.20120921_warrior1")).at(-1)![1].times, 5);
  o.pets = [{ race: 931 } as never, { race: 854 } as never];
  assert.equal((await call("PetExtension2.54e_25")).at(-1)![1].res, "0:1:0:1:0:0:0:0");
});

test("刘备's 见面礼: once", async () => {
  const { o, call } = setup();
  assert.equal((await call("GiftBagExtension.68_4", { id: 544 })).at(-1)![1].res, 1);
  assert.equal((await call("GiftBagExtension.68_5", { id: 544 })).at(-1)![1].res, 1);
  assert.equal(o.score, 700);
  assert.equal((await call("GiftBagExtension.68_4", { id: 544 })).at(-1)![1].res, 0);
});
