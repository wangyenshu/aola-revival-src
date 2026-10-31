import assert from "node:assert/strict";
import { test } from "node:test";
import { HATCH_MS, installEggs, type EggOwner } from "../src/game/sfs2013/eggs.ts";
import { installZoo, TD_WIN_SCORE, type ZooOwner } from "../src/game/sfs2013/zoo.ts";
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
  assert.deepEqual(owner.items!["12"], { "2": 1 });
  assert.equal(owner.items!["2"]["425"], 4);
});
