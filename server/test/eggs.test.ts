import assert from "node:assert/strict";
import { test } from "node:test";
import { HATCH_MS, installEggs, type EggOwner } from "../src/game/sfs2013/eggs.ts";
import { installZoo, TD_WIN_SCORE, zooLevel, type ZooOwner } from "../src/game/sfs2013/zoo.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function harness<O>(owner: O, install: (w: World) => void) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  install(world);
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: "小奥拉" }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  return call;
}

test("the 亚比孵化器 lists the eggs, hatches them in time, and lets the 亚比 go to the 仓库", async () => {
  const owner: EggOwner & { storage: { id: number; race: number }[] } = { items: { "5": { "88": 2, "91": 1 } }, storage: [] };
  const clock = { now: 1_000_000 };
  let next = 100;
  const call = harness(owner, (w) =>
    installEggs(w, {
      me: async () => owner,
      save: async () => {},
      now: () => clock.now,
      hatchPet: async (o, race) => {
        const id = ++next;
        o.storage.push({ id, race });
        return id;
      },
    }),
  );
  const list = (await call("PetEggExtension.1-2", { st: 0 }))[0];
  assert.equal(list[0], "1-2");
  assert.equal(list[1].st, 4);
  assert.deepEqual(list[1].es.map((e: { ri: number }) => e.ri), [88, 88, 91]);
  // Hatch one 圆角羊 egg and the 木面仔 egg.
  const r = await call("PetEggExtension.1-4", { st: 0, ids: `${list[1].es[0].ei},${list[1].es[2].ei}` });
  assert.deepEqual(r.filter(([c]) => c === "onAmountUpdated").map(([, b]) => b.amount).sort(), ["5_88_0_-1", "5_91_0_-1"]);
  assert.deepEqual(owner.items!["5"], { "88": 1 });
  const hatching = r.at(-1)!;
  assert.equal(hatching[1].st, 2);
  assert.equal(hatching[1].es[0].lt, HATCH_MS / 1000);
  clock.now += HATCH_MS;
  const done = (await call("PetEggExtension.1-2", { st: 0 }))[0][1];
  assert.equal(done.st, 3);
  assert.deepEqual(owner.storage.map((p) => p.race), [88, 91]);
  // 放回仓库 for each, then the 孵化器 is empty again.
  for (const { id } of done.pms) assert.equal((await call("PocketMonsterExtension.1223", { id, loc: 4 }))[0][1].res, 1);
  assert.equal(owner.hatch, undefined);
  assert.equal((await call("PetEggExtension.1-2", { st: 0 }))[0][1].st, 4);
});

test("stopping the 孵化器 gives the eggs back", async () => {
  const owner: EggOwner = { items: { "5": { "88": 1 } } };
  const call = harness(owner, (w) => installEggs(w, { me: async () => owner, save: async () => {}, now: () => 0, hatchPet: async () => 1 }));
  await call("PetEggExtension.1-4", { st: 0, ids: "88000" });
  assert.deepEqual(owner.items!["5"], {});
  const r = await call("PetEggExtension.1-6", { st: 0 });
  assert.deepEqual(owner.items!["5"], { "88": 1 });
  assert.equal(r.at(-1)![1].st, 4);
});

test("保卫战 stages are kept per place and pay 晶币; 动物捕捉 catches zoo animals", async () => {
  const owner: ZooOwner = { score: 0, items: {} };
  const call = harness(owner, (w) => installZoo(w, { me: async () => owner, save: async () => {}, random: () => 0.1 }));
  assert.equal((await call("ZooExtension.97_203", { place: 1 }))[0][1].gameInfo, "");
  await call("ZooExtension.97_201", { isWin: 1, zoneNum: 1, step: 1, place: 1 });
  await call("ZooExtension.97_201", { isWin: 1, zoneNum: 1, step: 3, place: 1 });
  await call("ZooExtension.97_201", { isWin: 0, zoneNum: 2, step: 1, place: 1 });
  assert.equal((await call("ZooExtension.97_203", { place: 1 }))[0][1].gameInfo, "1:3");
  assert.equal((await call("ZooExtension.97_203", { place: 2 }))[0][1].gameInfo, "");
  assert.equal(owner.score, 2 * TD_WIN_SCORE);
  const tools = (await call("ZooExtension.97_104")).at(-1)![1].items;
  assert.deepEqual(tools.map((t: { itemId: number }) => t.itemId), [424, 425]);
  const caught = (await call("ZooExtension.97_103", { raceId: 2, itemId: 425, rate: -1 })).at(-1)![1];
  assert.equal(caught.res, 1);
  assert.deepEqual(owner.items!["12"], { "10002": 1 });
  assert.equal(owner.items!["2"]["425"], 4);
});

test("the 动物园 grows the animals put in it, feeds them, and 收获 gives the zoo exp and a mature animal or its 亚比", async () => {
  // A save from before baby animals took 10000 + race: its 小狗 moves over.
  const owner: ZooOwner & { name: string; storage: number[] } = { name: "小奥拉", score: 5000, items: { "12": { "1": 2, "2": 1 } }, storage: [] };
  const clock = { now: 0 };
  let roll = 0.9;
  const call = harness(owner, (w) =>
    installZoo(w, {
      me: async () => owner,
      save: async () => {},
      now: () => clock.now,
      random: () => roll,
      givePet: async (o, race) => {
        (o as typeof owner).storage.push(race);
        return "蝴蝶伊奴";
      },
    }),
  );
  const babys = (await call("ZooExtension.97_9")).at(-1)![1].babys;
  assert.deepEqual(babys, [{ raceId: 1, type: 1, num: 2 }, { raceId: 2, type: 1, num: 1 }]);
  const put = (await call("ZooExtension.97_5", { raceId: 1 })).at(-1)![1];
  assert.equal(put.res, 1);
  assert.equal(put.animal.left, 2 * 3600); // 小狗: 2 hours
  assert.equal(owner.items!["12"]["10001"], 1);
  const id = put.animal.id;
  assert.equal((await call("ZooExtension.97_7", { id })).at(-1)![1].res, -2);
  // 喂食: an hour off, not again within half an hour.
  assert.equal((await call("ZooExtension.97_12", { id, itemId: 0 })).at(-1)![1].left, 3600);
  assert.equal((await call("ZooExtension.97_12", { id, itemId: 0 })).at(-1)![1].res, -3);
  // 初级加速饲料 (200 晶币) takes the last hour.
  const fed = (await call("ZooExtension.97_12", { id, itemId: 5 })).at(-1)![1];
  assert.equal(fed.mature, 1);
  assert.equal(owner.score, 4800);
  // No 变异 (25%) at this roll: the mature 卷毛狗.
  const got = (await call("ZooExtension.97_7", { id })).at(-1)![1];
  assert.deepEqual([got.res, got.petRace, got.exp], [1, 0, 4]);
  assert.equal(owner.items!["12"]["20001"], 1);
  assert.equal((await call("ZooExtension.97_10")).at(-1)![1].matrues[0].raceId, 1);
  // A certain 变异 with the 一星变异饲料: the 亚比 1009 goes to the 仓库.
  const second = (await call("ZooExtension.97_5", { raceId: 1 })).at(-1)![1].animal.id;
  assert.equal((await call("ZooExtension.97_12", { id: second, itemId: 2 })).at(-1)![1].rate, 100);
  clock.now += 2 * 3600 * 1000;
  const evo = (await call("ZooExtension.97_7", { id: second })).at(-1)![1];
  assert.deepEqual([evo.petRace, evo.petName], [1009, "蝴蝶伊奴"]);
  assert.deepEqual(owner.storage, [1009]);
  // Selling the mature animal: its price in 晶币.
  const sold = (await call("ZooExtension.97_21", { raceId: 1, num: 1 })).at(-1)![1];
  assert.deepEqual([sold.res, sold.got], [1, 500]);
  const info = (await call("ZooExtension.97_1", {})).at(-1)![1];
  assert.deepEqual([info.lv, info.exp, info.n], [zooLevel(8).lv, 8, 0]);
  roll = 0;
});
