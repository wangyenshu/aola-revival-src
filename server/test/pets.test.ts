import assert from "node:assert/strict";
import { test } from "node:test";
import { installPets, makePet, type PetOwner, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const tables: PetTables = {
  species: {},
  pm: {
    species: {
      "1": { n: "兔小子", s: [45, 45, 60, 45, 60, 45], ev: [0, 0, 0, 0, 1, 0], t: [11, 11], bx: 64, xt: "0", c: ["NA", "NA"], evo: "", learn: [[0, 1016]] },
      "43": { n: "小冰犬", s: [50, 50, 40, 30, 30, 50], ev: [0, 1, 0, 0, 0, 0], t: [14, 14], bx: 64, xt: "0", c: ["1", "0"], evo: "", learn: [[0, 1016]] },
    },
    skills: { "1016": { n: "噼啪乱击", p: 80, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "给对方单体造成伤害" } },
    chart: {},
    exp: { "0": Array.from({ length: 100 }, (_, i) => (i + 1) ** 3) },
  },
};

function harness() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: PetOwner = { id: 10001, name: "小奥拉", nextPetId: 0 };
  owner.pets = [1, 2, 3, 4, 5, 6].map((i) => makePet(tables, 1, 5 + i, "d", i));
  owner.nextPetId = 6;
  installPets(world, { load: async () => owner, save: async () => {}, tables: async () => tables, today: () => "2013-01-25" });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string, Record<string, unknown>][] = [];
    const ctx = { params, player: { name: owner.name }, reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { owner, call };
}

test("亚比仓库: a 亚比 got with a full bag goes to the 仓库; moving between bag and 仓库", async () => {
  const { owner, call } = harness();
  const got = await call("PocketMonsterExtension.1201", { raceId: 43, level: 20 });
  assert.match(String(got[0][1].msg), /仓库/);
  assert.equal(owner.storage?.length, 1);
  const list = await call("PocketMonsterExtension.1213", { loc: 1, page: 0 });
  assert.equal(list[0][0], "2213");
  assert.equal(list[0][1].total, 1);
  const stored = owner.storage![0].id;
  assert.equal((await call("PocketMonsterExtension.1224", { id: stored, loc: 0 }))[0][1].result, -2, "the bag is full");
  assert.equal((await call("PocketMonsterExtension.1224", { id: 1, loc: 1 }))[0][1].result, 1);
  assert.equal((await call("PocketMonsterExtension.1224", { id: stored, loc: 0 }))[0][1].result, 1);
  assert.deepEqual(owner.pets!.map((p) => p.id), [2, 3, 4, 5, 6, stored]);
  assert.deepEqual(owner.storage!.map((p) => p.id), [1]);
  const bag = await call("PocketMonsterExtension.1213", { loc: 0 });
  assert.equal((bag[0][1].pmList as unknown[]).length, 6);
  // The last 亚比 stays in the bag.
  owner.pets = owner.pets!.slice(0, 1);
  assert.equal((await call("PocketMonsterExtension.1224", { id: owner.pets[0].id, loc: 1 }))[0][1].result, -3);
});
