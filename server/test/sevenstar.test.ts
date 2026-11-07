import assert from "node:assert/strict";
import { test } from "node:test";
import { DARK_STARS, EVIL_GENERAL, SOUL_DRAW_COST, SOUL_PACKS, darkStarLevel, installSevenStar, type SevenStarOwner } from "../src/game/sfs2013/sevenstar.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup(rolls: number[] = [0]) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const o: SevenStarOwner = { id: 1, name: "小奥拉", xingbi: 200, items: {} };
  let i = 0;
  installSevenStar(world, { me: async () => o, save: async () => {}, today: () => "2013-01-25", now: () => Date.UTC(2013, 0, 25, 2), rng: () => rolls[i++ % rolls.length] });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: o.name }, reply: (b: Record<string, unknown>, c?: string) => replies.push([c, b]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  return { o, call };
}

test("黑暗三连星: 30 星魂 for the boss's 亚比蛋; the 星魂法阵 for 20 星币", async () => {
  const { o, call } = setup([0.6]);
  const luman = DARK_STARS[0];
  assert.equal((await call(`${luman.ext}.${luman.get}`)).at(-1)![1].res, 0, "too few 星魂");
  o.items!["2"] = { [luman.item]: 31 };
  const got = await call(`${luman.ext}.${luman.get}`);
  assert.equal(got.at(-1)![1].res, 1);
  assert.equal(o.items!["2"][luman.item], 1);
  assert.equal(o.items!["5"][luman.egg], 1, "the egg in the 孵化器");
  // 0.6 falls in the second pack (odds 0.5, 0.3, …): 5 星魂.
  const saiya = DARK_STARS[2];
  const drew = await call(`${saiya.ext}.${saiya.buy}`);
  assert.deepEqual(drew.at(-1)![1], { res: 1, index: 1 });
  assert.equal(o.items!["2"][saiya.item], SOUL_PACKS[1]);
  assert.equal(o.xingbi, 200 - SOUL_DRAW_COST);
  o.xingbi = 5;
  assert.equal((await call(`${saiya.ext}.${saiya.buy}`)).at(-1)![1].res, 0);
});

test("the bosses grow with each win, and are Lv60 from 12:00 to 14:00", () => {
  assert.equal(darkStarLevel(0, 9), 60);
  assert.equal(darkStarLevel(3, 9), 75);
  assert.equal(darkStarLevel(20, 20), 100);
  assert.equal(darkStarLevel(20, 12), 60);
});

test("魔将挑战: five tries a day; 星币的力量 once, for 160 星币", async () => {
  const { o, call } = setup();
  assert.deepEqual((await call("HolidayExtension.20121214_MJ1")).at(-1)![1], { bought: false, leftTimes: EVIL_GENERAL.tries, beat: false });
  assert.equal((await call("HolidayExtension.20121214_MJ2")).at(-1)![1].res, 1);
  assert.equal(o.xingbi, 200 - EVIL_GENERAL.price);
  assert.equal(o.items!["5"][EVIL_GENERAL.egg], 1);
  assert.equal((await call("HolidayExtension.20121214_MJ2")).at(-1)![1].res, -1);
  assert.equal((await call("HolidayExtension.20121214_MJ1")).at(-1)![1].bought, true);
});
