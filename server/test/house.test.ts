import assert from "node:assert/strict";
import { test } from "node:test";
import { houseOf, installHouse, usedUp, type HouseOwner } from "../src/game/sfs2013/house.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), join: () => {} } as unknown as World;
  const owner: HouseOwner = { id: 10001, name: "小奥拉", items: {} };
  installHouse(world, { me: async () => owner, find: async (n) => (n === owner.name ? owner : undefined), save: async () => {} });
  const call = async (key: string, params: Record<string, unknown>) => {
    let out: Record<string, unknown> = {};
    const ctx = { params, player: { name: owner.name }, reply: (o: Record<string, unknown>) => (out = o) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { owner, call };
}

test("a new home is the 空间舱 with a 亚比仓库 in storage", async () => {
  const { owner, call } = setup();
  assert.deepEqual(await call("HouseExtension.62_1", { un: "小奥拉" }), { un: "小奥拉", hid: 1, nn: "小奥拉", count: 0 });
  assert.equal(owner.items!["1"]["7"], 1);
  assert.deepEqual(usedUp(owner), { "1": 1 });
  assert.deepEqual(await call("UserFurntitureInfoExtension.63_1", { un: "小奥拉", hid: 1 }), { un: "小奥拉", hid: 1, infos: [] });
});

test("placing, moving and storing furniture", async () => {
  const { owner, call } = setup();
  houseOf(owner);
  const add = { fid: 7, key: 1, x: 300, y: 420, a: 0, op: 1 };
  assert.deepEqual(await call("UserFurntitureInfoExtension.63_2", { hid: 1, changes: [add] }), { result: 1 });
  assert.equal(usedUp(owner)["7"], 1);
  // A second one is more than the player owns.
  assert.deepEqual(await call("UserFurntitureInfoExtension.63_2", { hid: 1, changes: [{ ...add, key: 2 }] }), { result: -4 });
  assert.deepEqual(await call("UserFurntitureInfoExtension.63_2", { hid: 1, changes: [{ ...add, x: 500, op: 2 }] }), { result: 1 });
  const infos = (await call("UserFurntitureInfoExtension.63_1", { un: "小奥拉", hid: 1 })).infos as Record<string, unknown>[];
  assert.deepEqual(infos, [{ fid: 7, key: 1, x: 500, y: 420, ag: 0, ex: null }]);
  assert.deepEqual(await call("UserFurntitureInfoExtension.63_2", { hid: 1, changes: [{ ...add, op: 3 }] }), { result: 1 });
  assert.equal(usedUp(owner)["7"], undefined);
});

test("another house type empties the room", async () => {
  const { owner, call } = setup();
  houseOf(owner);
  await call("UserFurntitureInfoExtension.63_2", { hid: 1, changes: [{ fid: 7, key: 1, x: 300, y: 420, a: 0, op: 1 }] });
  assert.equal((await call("UserFurntitureInfoExtension.63_3", { hid: 1, nid: 36 })).result, -2); // not owned
  owner.items!["1"]["36"] = 1;
  assert.deepEqual(await call("UserFurntitureInfoExtension.63_3", { hid: 1, nid: 36 }), { result: 1, nid: 36 });
  assert.equal(owner.house!.hid, 36);
  assert.deepEqual(usedUp(owner), { "36": 1 });
});
