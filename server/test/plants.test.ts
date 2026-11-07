import assert from "node:assert/strict";
import { test } from "node:test";
import { CARE_PER_DAY, GROWTH_PER_CARE, PLANTS, SAPLING_MAX, buySapling, installPlants, nextFruitAt, type PlantOwner } from "../src/game/sfs2013/plants.ts";
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

test("树苗 bought are kept, and the owner chooses which to plant in the 植树盆", async () => {
  const { owner, call } = setup();
  owner.score = 100000;
  assert.equal(buySapling(owner, 3), 1);
  assert.equal(buySapling(owner, 3), 2);
  assert.equal(buySapling(owner, 5), 1);
  assert.equal(buySapling(owner, 999), -19);
  assert.equal(owner.score, 100000 - 2 * PLANTS[3].price - PLANTS[5].price);
  assert.equal(owner.plants, undefined); // nothing planted yet
  const info = await call("SundriesExtension.revival_garden", { op: "info", un: owner.name });
  assert.deepEqual(info.at(-1)![1].saplings, [{ id: 3, n: 2 }, { id: 5, n: 1 }]);
  // Someone else's garden does not show one's 树苗.
  assert.equal((await call("SundriesExtension.revival_garden", { op: "info", un: "别人" })).at(-1)![1].saplings.length, 0);
  assert.equal((await call("SundriesExtension.revival_garden", { op: "plant", plantId: 4 })).at(-1)![1].result, -3);
  const r = await call("SundriesExtension.revival_garden", { op: "plant", plantId: 5 });
  assert.equal(r.at(-1)![1].result, 0);
  assert.equal(r.at(-1)![1].plant.plantId, 5);
  assert.deepEqual(r.find(([c]) => c === "onAmountUpdated")![1], { amount: "9_5_0_1_1" });
  assert.deepEqual(r.at(-1)![1].saplings, [{ id: 3, n: 2 }]);
  // The pot is taken: the 树苗 stays.
  assert.equal((await call("SundriesExtension.revival_garden", { op: "plant", plantId: 3 })).at(-1)![1].result, -21);
  assert.equal(owner.saplings!["3"], 2);
  for (let i = 2; i < SAPLING_MAX; i++) buySapling(owner, 3);
  assert.equal(buySapling(owner, 3), -4);
  owner.score = 0;
  assert.equal(buySapling(owner, 1), -2);
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
    // The guests are in the owner's 家园 (a visitor's commands are about the home he is in).
    const ctx = { params, player: { name: who, room: { name: "主人_247_Home" } }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
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

test("摘果子 from afar: a visitor's commands are about the home he is in, not anyone's by name", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const owner: PlantOwner = { id: 1, name: "主人", score: 5000, items: {} };
  const guest: PlantOwner = { id: 2, name: "客人", items: {} };
  const all = [owner, guest];
  const now = Date.UTC(2013, 0, 20, 2, 0, 0);
  installPlants(world, { me: async (ctx) => all.find((o) => o.name === ctx.player.name)!, find: async (n) => all.find((o) => o.name === n), save: async () => {}, now: () => now });
  const call = async (who: string, room: string, key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: who, room: { name: room } }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  await call("主人", "主人_247_Home", "SundriesExtension.revival_garden", { op: "buy", plantId: 5 });
  const tree = owner.plants![0];
  Object.assign(tree, { level: 2, remainFruit: 0, remainProductTime: 2, fruitLeft: 4, nextFruitTime: now });
  const ask = { owner: "主人", userPlantId: tree.id };
  assert.equal((await call("客人", "maintown1", "PlantExtension.80_5", ask)).at(-1)![1].result.result, -19, "from a scene: no such tree");
  assert.equal((await call("客人", "客人_247_Home", "PlantExtension.80_3", ask)).at(-1)![1].result.result, -19, "from his own garden");
  assert.equal((await call("客人", "主人_247_Home", "PlantExtension.80_5", ask)).at(-1)![1].result.extData, 1, "in the owner's garden");
});

test("the owner's 雨露 and 养料 cost 50 晶币; a visitor's are free and remembered (植物心声)", async () => {
  const { owner, call } = setup();
  await call("SundriesExtension.revival_garden", { op: "buy", plantId: 5 });
  const tree = owner.plants![0];
  const before = owner.score!;
  const r = await call("PlantExtension.80_3", { owner: owner.name, userPlantId: tree.id });
  assert.equal(r.at(-1)![1].result.result, 0);
  assert.equal(owner.score, before - 50);
  assert.deepEqual(r[0], [ "onScoreUpdated", { score: before - 50 } ]);
  owner.score = 10;
  assert.equal((await call("PlantExtension.80_4", { owner: owner.name, userPlantId: tree.id })).at(-1)![1].result.result, -2);
});

test("盆栽道具: 极速雨露 outside the day's growth, 基因药剂 raise it, 增产养料 doubles a fruiting, 繁盛养料 adds two, 铲子 digs up", async () => {
  const { owner, call, clock } = setup();
  owner.items = { "10": { "1": 2, "3": 1, "5": 2, "6": 1, "7": 1 } };
  await call("SundriesExtension.revival_garden", { op: "buy", plantId: 5 });
  const tree = owner.plants![0];
  const use = async (itemId: number) => (await call("PlantItemExtension.81_1", { owner: owner.name, userPlantId: tree.id, itemId, quantity: 1 })).at(-1)![1].result;
  assert.deepEqual((await call("PlantItemExtension.81_2")).at(-1)![1].items.map((i: { id: number }) => i.id), [1, 3, 5, 6, 7]);
  // Level 0 (10/10): 极速雨露 fills the health, the day's growth untouched.
  assert.equal((await use(1)).result, 0);
  assert.equal(tree.health, 10);
  assert.equal(owner.items["10"]["1"], 1);
  assert.equal((await use(1)).result, -17);
  assert.equal(owner.items["10"]["1"], 1, "a refused 道具 is kept");
  // 健康基因药剂: the day's health growth 20 -> 25.
  assert.equal((await use(3)).userPlant.healthCeil, 25);
  assert.equal((await use(2)).result, -3, "none of it");
  // Not bearing fruit yet.
  assert.equal((await use(5)).result, -18);
  // Grow it to 月亮树's mature level 2 (10+10, 20+20).
  Object.assign(tree, { level: 2, health: 0, nutrition: 0, remainProductTime: 2, fruitLeft: 10, remainFruit: 0, nextFruitTime: clock.now + 3600_000 });
  assert.equal((await use(5)).result, 0);
  assert.equal((await use(5)).result, -5, "once a fruiting");
  assert.equal((await use(6)).result, 0);
  assert.deepEqual([tree.remainProductTime, tree.fruitLeft], [4, 20]);
  clock.now += 3600_000;
  const picked = (await call("PlantExtension.80_5", { owner: owner.name, userPlantId: tree.id })).at(-1)![1].result;
  assert.equal(picked.extData, 10, "a fruiting of 5, doubled");
  // 铲子.
  const dug = await call("PlantItemExtension.81_1", { owner: owner.name, userPlantId: tree.id, itemId: 7, quantity: 1 });
  assert.equal(dug.at(-1)![1].result.dug, 1);
  assert.equal(owner.plants!.length, 0);
});

test("守护亚比: one of the owner's 亚比, shown in the tree", async () => {
  const { owner, call } = setup();
  owner.pets = [{ id: 7 }];
  await call("SundriesExtension.revival_garden", { op: "buy", plantId: 1 });
  const tree = owner.plants![0];
  assert.equal((await call("PlantExtension.80_12", { userPlantId: tree.id, petId: 9 })).at(-1)![1].result.result, -8);
  const r = (await call("PlantExtension.80_12", { userPlantId: tree.id, petId: 7 })).at(-1)![1].result;
  assert.equal(r.result, 0);
  assert.equal(r.userPlant.petId, 7);
  assert.equal((await call("PlantExtension.80_12", { userPlantId: tree.id, petId: 0 })).at(-1)![1].result.userPlant.petId, 0);
});

test("收为家具: a grown tree with no fruit to come goes to the 小屋's storage and can stand in a room", async () => {
  const { owner, call } = setup();
  await call("SundriesExtension.revival_garden", { op: "buy", plantId: 5 });
  const tree = owner.plants![0];
  // Still growing: refused.
  assert.deepEqual((await call("PlantExtension.80_14", { pi: tree.id })).at(-1)![1], { res: false });
  Object.assign(tree, { level: PLANTS[5].levels.length - 1, remainFruit: 0, remainProductTime: 0, fruitLeft: 0 });
  const made = (await call("PlantExtension.80_14", { pi: tree.id })).at(-1)![1];
  assert.equal(made.res, true);
  assert.equal(made.userPlant.isFurniture, true);
  assert.equal(made.userPlant.houseId, 0);
  // The pot is free (a new tree may be planted), and a furniture tree is cared for no more.
  assert.equal((await call("SundriesExtension.revival_garden", { op: "info" })).at(-1)![1].plant, null);
  assert.equal((await call("PlantExtension.80_3", { owner: owner.name, userPlantId: tree.id })).at(-1)![1].result.result, -19);
  assert.equal((await call("SundriesExtension.revival_garden", { op: "buy", plantId: 1 })).at(-1)![1].result, 0);
  // Put down in the 空间舱 (house 1): someone visiting it sees it there, not in the garden.
  assert.deepEqual((await call("PlantExtension.80_10", { houseId: 1, changes: [{ id: tree.id, x: 400, y: 300, houseId: 1 }] })).at(-1)![1], { result: true });
  const room = (await call("PlantExtension.80_9", { owner: owner.name, houseId: 1 })).at(-1)![1].userPlants;
  assert.deepEqual(room.map((p: any) => [p.id, p.positionX, p.positionY, p.isFurniture]), [[tree.id, 400, 300, true]]);
  assert.deepEqual((await call("PlantExtension.80_9", { owner: owner.name, houseId: 247 })).at(-1)![1].userPlants.map((p: any) => p.plantId), [1]);
  // Not into another room than the one saved, nor off the room.
  assert.deepEqual((await call("PlantExtension.80_10", { houseId: 1, changes: [{ id: tree.id, x: 400, y: 300, houseId: 2 }] })).at(-1)![1], { result: false });
  assert.deepEqual((await call("PlantExtension.80_10", { houseId: 1, changes: [{ id: tree.id, x: 2000, y: 300, houseId: 1 }] })).at(-1)![1], { result: false });
  // Another house type: back in the storage.
  assert.deepEqual((await call("PlantExtension.80_11", { houseId: 1, newHouseId: 2 })).at(-1)![1], { result: true, nid: 2 });
  assert.deepEqual(tree.furniture, { houseId: 0, x: 0, y: 0 });
  // Taken up again.
  await call("PlantExtension.80_10", { houseId: 1, changes: [{ id: tree.id, x: 400, y: 300, houseId: 1 }] });
  await call("PlantExtension.80_10", { houseId: 1, changes: [{ id: tree.id, x: 0, y: 0, houseId: 0 }] });
  assert.deepEqual(tree.furniture, { houseId: 0, x: 0, y: 0 });
});

test("勋章 come from the 星辉任务 of the 徽章 of the same name, dated when the task was done", async () => {
  const { badges } = await import("../src/game/sfs2013/honour.ts");
  assert.deepEqual(badges({ name: "x", tasks: { "150": { st: 1, fd: 1234 }, "80": { st: 0, fd: 0 }, "352": { st: 1, fd: 99 } } }), [
    { bi: 3, gd: 1234 },
    { bi: 7, gd: 99 },
  ]);
  assert.deepEqual(badges({ name: "x" }), []);
});
