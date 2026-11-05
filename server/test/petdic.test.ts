import assert from "node:assert/strict";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import type { PmData } from "../src/game/sfs2013/pmdata.ts";
import { dicMarks, installPetDic, markDic, LATEST_PETS, MET, OWNED, type DicOwner } from "../src/game/sfs2013/petdic.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const pm: PmData = {
  species: {
    "1": { n: "兔小子", s: [45, 45, 60, 45, 60, 45], ev: [0, 0, 0, 0, 1, 0], t: [11, 11], bx: 64, xt: "0", c: ["NA", "NA"], evo: "0-1", learn: [[0, 1016]] },
    "43": { n: "小冰犬", s: [50, 50, 40, 30, 30, 50], ev: [0, 1, 0, 0, 0, 0], t: [14, 14], bx: 64, xt: "0", c: ["1", "0"], evo: "0-43", learn: [[0, 1016]] },
  },
  skills: { "1016": { n: "噼啪乱击", p: 80, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "给对方单体造成伤害" } },
  chart: {},
  exp: { "0": Array.from({ length: 100 }, (_, i) => (i + 1) ** 3) },
};
const sp = (n: string) => ({ n, a: 1, e: 0, next: 0, sk: [] });
const tables: PetTables = { species: { "1": sp("兔小子"), "43": sp("小冰犬"), "50": sp("五十"), "1417": sp("小翼") }, pm };

function harness() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: DicOwner & { items: Record<string, Record<string, number>> } = { id: 10001, name: "小奥拉", items: { "2": { "64": 1 } } };
  owner.pets = [makePet(tables, 1, 12, "d", 1)];
  owner.nextPetId = 1;
  let saves = 0;
  const deps = { load: async () => owner, save: async () => void saves++, tables: async () => tables };
  installPetDic(world, deps);
  installBattles(world, { ...deps, wild: async () => ({ aixiscene1: [{ raceId: 43, min: 3, max: 3, common: 1, rate: 0 }] }), today: () => "2013-01-25", rng: () => 0.5 });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = {
      params,
      player: { name: owner.name, room: { name: "aixiscene1" } },
      reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]),
    } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { owner, call, saves: () => saves };
}

test("图鉴 marks: one per species after 10, owned above met, nothing outside the table", () => {
  const o: DicOwner = { id: 1, name: "a" };
  assert.equal(markDic(o, tables, 43, MET), true);
  assert.equal(markDic(o, tables, 43, MET), false, "already met");
  assert.equal(markDic(o, tables, 43, OWNED), true);
  assert.equal(markDic(o, tables, 43, MET), false, "owned stays owned");
  assert.equal(markDic(o, tables, 44, MET), false, "not a species of the table");
  assert.equal(markDic(o, tables, 20043, MET), false);
  assert.equal(markDic(o, tables, 0, MET), false);
  o.pets = [makePet(tables, 1, 5, "d", 1)];
  const res = dicMarks(o, tables);
  assert.equal(res.length, 10 + 1417);
  assert.equal(res.slice(0, 10), "0000000000");
  assert.equal(res.charAt(10 + 0), "2", "兔小子 in the bag");
  assert.equal(res.charAt(10 + 42), "2");
  assert.equal(res.charAt(10 + 49), "0");
});

test("a fight marks the species met and tells the client; a catch marks it owned", async () => {
  const { owner, call } = harness();
  const start = await call("PetExtension.54_2", { raceId: 43 });
  assert.deepEqual(start.map(([c]) => c), ["2303", "2401", "LatePMChartNotify"]);
  assert.equal(owner.dic?.charAt(42), "1");
  const caught = await call("PocketMonsterExtension.1405", { tarSId: 1, itemId: 64 });
  assert.deepEqual(caught.map(([c]) => c), ["onAmountUpdated", "2415", "2403", "LatePMChartNotify"]);
  assert.equal(owner.dic?.charAt(42), "2");
  // Met before: no new record.
  owner.items["2"]["64"] = 1;
  const again = await call("PetExtension.54_2", { raceId: 43 });
  assert.deepEqual(again.map(([c]) => c), ["2303", "2401"]);
  const res = String((await call("PetExtension.54_5"))[0][1].res);
  assert.equal(res.charAt(10 + 42), "2");
  assert.equal(res.charAt(10 + 0), "2");
});

test("the 最新亚比: offered until looked at", async () => {
  const { owner, call, saves } = harness();
  const first = await call("PetExtension2.54e_11");
  assert.deepEqual(first, [["54e_11", { l: 1, p: "1417" }]]);
  assert.ok(LATEST_PETS.includes(1417));
  await call("PetExtension2.54e_12");
  assert.equal(owner.dicLatest, true);
  const n = saves();
  await call("PetExtension2.54e_12");
  assert.equal(saves(), n);
  assert.deepEqual(await call("PetExtension2.54e_11"), [["54e_11", { l: 0, p: "1417" }]]);
});
