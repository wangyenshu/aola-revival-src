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

function harness(clock = { now: Date.parse("2013-01-25T10:00:00Z") }) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: PetOwner = { id: 10001, name: "小奥拉", nextPetId: 0 };
  owner.pets = [1, 2, 3, 4, 5, 6].map((i) => makePet(tables, 1, 5 + i, "d", i));
  owner.nextPetId = 6;
  installPets(world, { load: async () => owner, save: async () => {}, tables: async () => tables, today: () => "2013-01-25", anyPet: true, now: () => clock.now });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string, Record<string, unknown>][] = [];
    const ctx = { params, player: { name: owner.name }, reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { owner, call, clock };
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

test("放生: a 亚比 of the bag or the 仓库 goes to the 放生仓库, comes back from it, is gone after seven days", async () => {
  const { owner, call, clock } = harness();
  await call("PocketMonsterExtension.1201", { raceId: 43, level: 20 });
  const stored = owner.storage![0].id;
  owner.followPet = 2;
  owner.showPet = stored;
  const r = async (id: number) => (await call("PocketMonsterExtension.revival_release", { id }))[0];
  assert.deepEqual(await r(stored), ["revival_release", { result: 1, id: stored }]);
  assert.equal(owner.storage!.length, 0);
  assert.equal(owner.showPet, 0);
  assert.equal((await r(2))[1].result, 1);
  assert.deepEqual(owner.pets!.map((p) => p.id), [1, 3, 4, 5, 6]);
  assert.equal(owner.followPet, 0);
  assert.equal((await r(99))[1].result, -1);
  // The 放生仓库 lists them with the days they are kept still.
  const gone = (await call("PocketMonsterExtension.1213", { loc: 3, page: 0 }))[0][1];
  assert.equal(gone.total, 2);
  const views = (gone.pmList as { pmSView: { i: number; rl: number } }[]).map((x) => x.pmSView);
  assert.deepEqual(views.map((v) => [v.i, v.rl]), [[stored, 7], [2, 7]]);
  // One comes back to the bag, another to the 仓库.
  assert.equal((await call("PocketMonsterExtension.1224", { id: 2, loc: 0 }))[0][1].result, 1);
  assert.deepEqual(owner.pets!.map((p) => p.id), [1, 3, 4, 5, 6, 2]);
  assert.equal(owner.pets!.at(-1)!.relAt, undefined);
  await r(2);
  clock.now += 6 * 24 * 3600 * 1000;
  assert.equal((await call("PocketMonsterExtension.1213", { loc: 3 }))[0][1].total, 2);
  clock.now += 1 * 24 * 3600 * 1000 + 1;
  assert.equal((await call("PocketMonsterExtension.1213", { loc: 3 }))[0][1].total, 0, "gone for good after seven days");
  assert.equal((await call("PocketMonsterExtension.1224", { id: stored, loc: 1 }))[0][1].result, -1);
  owner.pets = owner.pets!.slice(0, 1);
  assert.equal((await r(owner.pets[0].id))[1].result, -3);
  assert.equal(owner.pets.length, 1);
});

test("亚比仓库: 系, order and pages of nine; 精英 and the 精英仓库; 昵称; 展示", async () => {
  const { owner, call } = harness();
  owner.storage = [
    makePet(tables, 1, 30, "d", 11),
    makePet(tables, 43, 12, "d", 12),
    makePet(tables, 1, 8, "d", 13),
    ...Array.from({ length: 9 }, (_, i) => makePet(tables, 43, 40 + i, "d", 20 + i)),
  ];
  const ids = async (q: Record<string, unknown>) =>
    ((await call("PocketMonsterExtension.1213", { size: 9, ...q }))[0][1].pmList as { pmSView: { i: number } }[]).map((x) => x.pmSView.i);
  const first = (await call("PocketMonsterExtension.1213", { loc: 1, size: 9 }))[0][1];
  assert.equal(first.total, 12);
  assert.equal(first.totalPage, 2);
  assert.equal(first.page, 1, "pages count from 1");
  assert.deepEqual(await ids({ loc: 1, page: 2 }), [26, 27, 28]);
  // The era panels that pick a 亚比 of the 仓库 (亚比特训, 融合, 重组): loc 2, nine to a page.
  const era = (await call("PocketMonsterExtension.1213", { pmType: 0, page: 1, loc: 2, order: 1, asc: false }))[0][1];
  assert.deepEqual([era.pmType, era.page, era.totalPage, (era.pmList as unknown[]).length], [0, 1, 2, 9]);
  // 木 (11): 兔小子; 冰 (14): 小冰犬.
  assert.deepEqual(await ids({ loc: 1, pmType: 11 }), [11, 13]);
  assert.equal((await ids({ loc: 1, pmType: 14 })).length, 9);
  // By level, highest first; by when got, newest first.
  assert.deepEqual((await ids({ loc: 1, order: 2, asc: false })).slice(0, 2), [28, 27]);
  assert.deepEqual(await ids({ loc: 1, pmType: 11, order: 2, asc: true }), [13, 11]);
  assert.deepEqual((await ids({ loc: 1, order: 1, asc: false })).slice(0, 2), [28, 27]);
  // 精英.
  assert.deepEqual((await call("PocketMonsterExtension.1225", { id: 12, e: true }))[0], ["2225", { result: 1, id: 12, e: true }]);
  assert.deepEqual(await ids({ loc: 4 }), [12]);
  const listed = (await call("PocketMonsterExtension.1213", { loc: 1, pmType: 14, size: 9 }))[0][1].pmList as { pmSView: { i: number; el: number } }[];
  assert.equal(listed.find((x) => x.pmSView.i === 12)!.pmSView.el, 1);
  await call("PocketMonsterExtension.1225", { id: 12, e: false });
  assert.deepEqual(await ids({ loc: 4 }), []);
  assert.equal((await call("PocketMonsterExtension.1225", { id: 99, e: true }))[0][1].result, -1);
  // 昵称: up to six; empty gives the name back.
  assert.deepEqual((await call("PocketMonsterExtension.revival_nick", { id: 11, nick: "小 兔" }))[0], ["revival_nick", { result: 1, id: 11, nick: "小兔" }]);
  assert.equal(owner.storage.find((p) => p.id === 11)!.nick, "小兔");
  assert.equal((await call("PocketMonsterExtension.revival_nick", { id: 11, nick: "一二三四五六七" }))[0][1].result, -2);
  assert.equal((await call("PocketMonsterExtension.revival_nick", { id: 11, nick: "<b>" }))[0][1].result, -2);
  await call("PocketMonsterExtension.revival_nick", { id: 11, nick: "" });
  assert.equal(owner.storage.find((p) => p.id === 11)!.nick, undefined);
  // 展示: one at a time; the same again takes it back.
  assert.deepEqual((await call("PocketMonsterExtension.revival_show", { id: 12 }))[0], ["revival_show", { result: 1, id: 12 }]);
  assert.equal(owner.showPet, 12);
  assert.equal((await call("PocketMonsterExtension.revival_show", { id: 13 }))[0][1].id, 13);
  assert.equal((await call("PocketMonsterExtension.revival_show", { id: 13 }))[0][1].id, 0);
  assert.equal((await call("PocketMonsterExtension.revival_show", { id: 99 }))[0][1].result, -1);
  // Its page says 精英 and 展示 too.
  await call("PocketMonsterExtension.1225", { id: 13, e: true });
  await call("PocketMonsterExtension.revival_show", { id: 13 });
  const d = (await call("PocketMonsterExtension.1211", { id: 13 }))[0][1].pm as { pmPView: { el: number; sh: number } };
  assert.deepEqual([d.pmPView.el, d.pmPView.sh], [1, 1]);
});

test("a 亚比 made at a high level knows every skill of its line up to it, and carries the last four", () => {
  const learn: [number, number][] = [[1, 101], [5, 102], [10, 103], [20, 104], [30, 105], [40, 106], [99, 107]];
  const skills: Record<string, { n: string; p: number; acc: number; pp: number; pri: number; t: number; k: number; d: string }> = {};
  for (const [, id] of learn) skills[String(id)] = { n: "技" + id, p: 50, acc: 100, pp: 10, pri: 0, t: 0, k: 0, d: "" };
  const t: PetTables = { ...tables, pm: { ...tables.pm, species: { ...tables.pm.species, "9": { ...tables.pm.species["1"], learn } }, skills } };
  const p = makePet(t, 9, 50, "d", 1);
  assert.deepEqual(p.learned, [101, 102, 103, 104, 105, 106]);
  assert.deepEqual(p.skills.map((s) => s.id), [103, 104, 105, 106]);
});
