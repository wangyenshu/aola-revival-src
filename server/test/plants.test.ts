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
