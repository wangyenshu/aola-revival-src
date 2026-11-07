import assert from "node:assert/strict";
import { test } from "node:test";
import { BLESSING_MS, BW_PRICE, QILING, installKingBosses, qilingInfo, type KingOwner } from "../src/game/sfs2013/kingbosses.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const o: KingOwner = { id: 1, name: "小奥拉", xingbi: 300, items: {} };
  const clock = { now: Date.UTC(2013, 0, 20, 2) };
  installKingBosses(world, { me: async () => o, save: async () => {}, today: () => "2013-01-20", now: () => clock.now });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: o.name }, reply: (b: Record<string, unknown>, c?: string) => replies.push([c, b]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  return { o, call, clock };
}

test("修罗 and 凯撒: the day's blessing lasts 15 minutes; 星币 buy the 亚比蛋 once", async () => {
  const { o, call, clock } = setup();
  assert.deepEqual((await call("HolidayExtension.0118BW_whitePanel")).at(-1)![1], { buy: false, status: 0, buff: 0, use: false });
  assert.equal((await call("HolidayExtension.0118BW_buff", { index: 0 })).at(-1)![1].suc, true);
  assert.equal((await call("HolidayExtension.0118BW_buff", { index: 0 })).at(-1)![1].suc, false, "once a day");
  clock.now += 60_000;
  const p = (await call("HolidayExtension.0118BW_whitePanel")).at(-1)![1];
  assert.equal(p.buff, (BLESSING_MS - 60_000) / 1000);
  assert.equal(p.use, true);
  // 凯撒's blessing is its own.
  assert.equal((await call("HolidayExtension.0118BW_blackPanel")).at(-1)![1].use, false);
  assert.equal((await call("HolidayExtension.0118BW_buy", { index: 1 })).at(-1)![1].res, 1);
  assert.equal(o.xingbi, 300 - BW_PRICE);
  assert.equal(o.items!["5"]["727"], 1);
  assert.equal((await call("HolidayExtension.0118BW_buy", { index: 1 })).at(-1)![1].res, 0);
  assert.equal((await call("HolidayExtension.0118BW_blackPanel")).at(-1)![1].buy, true);
});

test("召唤奇灵王: three 奇灵玉 call it (小奇灵's 亚比蛋), then the 终极挑战", async () => {
  const { o, call } = setup();
  assert.equal((await call("HolidayExtension.0201qiling_panel")).at(-1)![1].info, "0:0:0:0");
  o.items!["2"] = { "494": 1, "496": 1 };
  assert.equal(qilingInfo(o), "1:0:1:0");
  assert.equal((await call("HolidayExtension.0201qiling_exchange")).at(-1)![1].suc, false);
  o.items!["2"]["495"] = 1;
  assert.equal(qilingInfo(o), "1:1:1:1");
  assert.equal((await call("HolidayExtension.0201qiling_exchange")).at(-1)![1].suc, true);
  assert.deepEqual(QILING.stones.map((id) => o.items!["2"][String(id)]), [0, 0, 0]);
  assert.equal(o.items!["5"][String(QILING.egg)], 1);
  assert.equal(qilingInfo(o), "1:1:1:2");
});
