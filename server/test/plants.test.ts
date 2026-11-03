import assert from "node:assert/strict";
import { test } from "node:test";
import { CARE_PER_DAY, GROWTH_PER_CARE, PLANTS, installPlants, nextFruitAt, type PlantOwner } from "../src/game/sfs2013/plants.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup(start = Date.UTC(2013, 0, 20, 2, 0, 0)) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const owner: PlantOwner = { name: "小奥拉", score: 5000, items: {} };
  const clock = { now: start };
  installPlants(world, { me: async () => owner, find: async (n) => (n === owner.name ? owner : undefined), save: async () => {}, now: () => clock.now });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: owner.name }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  return { owner, call, clock };
}

test("planting a tree in the 植树盆 costs its PlantData price and tells the PlantService", async () => {
  const { owner, call } = setup();
  const r = await call("SundriesExtension.revival_garden", { op: "buy", plantId: 1 });
  assert.equal(owner.score, 5000 - PLANTS[1].price);
  assert.deepEqual(r.find(([c]) => c === "onAmountUpdated")![1], { amount: "9_1_0_1_1" });
  assert.equal(r.at(-1)![1].plant.plantId, 1);
  // One tree in the pot.
  const again = await call("SundriesExtension.revival_garden", { op: "buy", plantId: 2 });
  assert.equal(again.at(-1)![1].result, -21);
  const mine = await call("PlantExtension.80_1");
  assert.equal(mine[0][1].userPlants.length, 1);
  assert.equal(mine[0][1].userPlants[0].houseId, 247);
});

test("雨露 and 养料 grow the tree; twice a day each; it bears fruit from its mature level", async () => {
  const { owner, call, clock } = setup();
  await call("SundriesExtension.revival_garden", { op: "buy", plantId: 5 });
  const tree = owner.plants![0];
  const care = async (cmd: string) => (await call(`PlantExtension.${cmd}`, { owner: owner.name, userPlantId: tree.id })).at(-1)![1].result.result;
  // Level 0 needs 10 + 10: one of each.
  assert.equal(await care("80_3"), 0);
  assert.equal(await care("80_3"), -17); // health full until the next level
  assert.equal(await care("80_4"), 1); // grown a level
  assert.equal(tree.level, 1);
  // Level 1 needs 20 + 20; care is counted by the day (two 雨露 today already after this one).
  assert.equal(await care("80_3"), 0);
  assert.equal(await care("80_3"), -5);
  clock.now += 24 * 3600_000;
  assert.equal(await care("80_3"), 0);
  assert.equal(await care("80_4"), 0);
  assert.equal(await care("80_4"), 1);
  assert.equal(tree.level, 2); // 月亮树 is mature at 2: 2 fruitings, 10 fruit
  assert.equal(tree.remainProductTime, 2);
  assert.equal(tree.nextFruitTime, nextFruitAt(clock.now));
  // Nothing to pick yet; an hour or more later, to the whole hour, there is.
  assert.equal((await call("PlantExtension.80_5", { owner: owner.name, userPlantId: tree.id })).at(-1)![1].result.result, -1);
  clock.now = tree.nextFruitTime;
  const picked = await call("PlantExtension.80_5", { owner: owner.name, userPlantId: tree.id });
  assert.equal(picked.at(-1)![1].result.result, 0);
  assert.equal(picked.at(-1)![1].result.extData, 5);
  assert.deepEqual(picked[0], ["onAmountUpdated", { amount: "2_449_0_5" }]);
  assert.equal(owner.items!["2"]["449"], 5);
  assert.equal(tree.remainProductTime, 1);
  assert.equal(GROWTH_PER_CARE * CARE_PER_DAY, 20);
});

test("digging the tree up empties the pot", async () => {
  const { owner, call } = setup();
  await call("SundriesExtension.revival_garden", { op: "buy", plantId: 3 });
  const r = await call("SundriesExtension.revival_garden", { op: "dig", userPlantId: owner.plants![0].id });
  assert.deepEqual(r[0], ["onAmountUpdated", { amount: "9_3_0_-1_1" }]);
  assert.equal(owner.plants!.length, 0);
});

test("摘果子 at a friend's: one fruit a visitor a fruiting, the last left to the owner", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const owner: PlantOwner = { id: 1, name: "主人", score: 5000, items: {} };
  const guests: PlantOwner[] = [{ id: 2, name: "客人", items: {} }, { id: 3, name: "客人二", items: {} }];
  const all = [owner, ...guests];
  let now = Date.UTC(2013, 0, 20, 2, 0, 0);
  installPlants(world, { me: async (ctx) => all.find((o) => o.name === ctx.player.name)!, find: async (n) => all.find((o) => o.name === n), save: async () => {}, now: () => now });
  const call = async (who: string, key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: who }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  await call("主人", "SundriesExtension.revival_garden", { op: "buy", plantId: 5 });
  const tree = owner.plants![0];
  // Grown to bear: 2 fruit on the tree now.
  Object.assign(tree, { level: 2, remainFruit: 0, remainProductTime: 2, fruitLeft: 4, nextFruitTime: now });
  const pick = async (who: string) => (await call(who, "PlantExtension.80_5", { owner: "主人", userPlantId: tree.id })).at(-1)![1].result;
  assert.equal((await pick("客人")).extData, 1);
  assert.equal(guests[0].items!["2"]["449"], 1);
  assert.equal(await pick("客人").then((r) => r.result), -22, "once a fruiting");
  assert.equal(await pick("客人二").then((r) => r.result), -22, "the last is the owner's");
  assert.equal((await pick("主人")).extData, 1);
  assert.equal(tree.remainFruit, 0);
  // The next fruiting: the guest may pick again.
  now = tree.nextFruitTime;
  assert.equal((await pick("客人")).result, 0);
});
