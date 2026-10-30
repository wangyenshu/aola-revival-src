import assert from "node:assert/strict";
import { test } from "node:test";
import { cardsOf, installShoot, type CardRow, type ShootOwner } from "../src/game/sfs2013/shoot.ts";
import { decryptScore } from "../src/game/sfs2013/game.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const CARDS: Record<string, CardRow> = {
  "1": [0, 0, 0, 1, 0, "光能射线", 2003, 5],
  "4": [40, 20, 0, 9999, 0, "朵朵射击卡", 3, 15],
};

function setup() {
  const handlers = new Map<string, XtHandler>();
  const vars: Record<string, unknown>[] = [];
  const target = { name: "小红" };
  const session = { tag: "target" };
  const world = {
    xt: (k: string, h: XtHandler) => (handlers.set(k, h), world),
    rooms: new Map([["starland", { members: new Set([session]) }]]),
    player: (s: unknown) => (s === session ? target : undefined),
    setUserVars: (_s: unknown, v: Record<string, unknown>) => vars.push(v),
  } as unknown as World;
  const owner: ShootOwner = { name: "小奥拉", items: {} };
  const timers: (() => void)[] = [];
  installShoot(world, { me: async () => owner, save: async () => {}, cards: async () => CARDS, later: (_ms, fn) => timers.push(fn) });
  const call = async (key: string, params: Record<string, unknown>) => {
    const replies: [string | undefined, Record<string, unknown>][] = [];
    const broadcasts: [string, Record<string, unknown>][] = [];
    const ctx = {
      params,
      player: { name: owner.name, room: { id: 3, name: "starland" } },
      reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]),
      broadcast: (o: Record<string, unknown>, c: string) => broadcasts.push([c, o]),
    } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return { replies, broadcasts };
  };
  return { owner, call, vars, timers };
}

test("everyone has 光能射线 and 冰冻射线, and they are never used up", async () => {
  const { owner, call } = setup();
  const r = await call("ShootExtension.64_5", {});
  assert.deepEqual(r.replies[0][1], { cards: [{ i: 1, q: 1 }, { i: 2, q: 1 }] });
  const shot = await call("ShootExtension.64_1", { cardId: 1, target: "shoot_basescene", targetType: 0, x: 300, y: 420 });
  assert.equal(shot.broadcasts[0][0], "64_2");
  assert.deepEqual(shot.broadcasts[0][1].hit, true);
  assert.equal((shot.broadcasts[0][1].info as Record<string, unknown>).cardId, 1);
  assert.equal(cardsOf(owner)["1"], 1);
});

test("a bought 射击卡 goes one per shot, and a player hit wears its effect for its seconds", async () => {
  const { owner, call, vars, timers } = setup();
  cardsOf(owner)["4"] = 2;
  const shot = await call("ShootExtension.64_1", { cardId: 4, target: "小红", targetType: 2, x: 500, y: 400 });
  assert.deepEqual(shot.replies[0], ["onAmountUpdated", { amount: "4_4_0_-1" }]);
  assert.equal(cardsOf(owner)["4"], 1);
  assert.deepEqual(vars[0], { shoot_effect: "小红;3;3;" });
  timers[0]();
  assert.deepEqual(vars[1], { shoot_effect: "小红;;0;3" });
  // A card not owned does nothing.
  delete cardsOf(owner)["4"];
  const none = await call("ShootExtension.64_1", { cardId: 4, target: "小红", targetType: 2, x: 0, y: 0 });
  assert.equal(none.broadcasts.length, 0);
});

test("mini game scores are read back from the 2013 client's Encrypt.encryptCode", () => {
  // Codes the client's encryptCode gives for these scores.
  assert.equal(decryptScore(721212121), 0);
  assert.equal(decryptScore(726418971), 123);
  assert.equal(decryptScore(722290631), 4567);
  assert.equal(decryptScore(838259605), 1234567);
});
