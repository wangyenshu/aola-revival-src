import assert from "node:assert/strict";
import { test } from "node:test";
import { BAG_MAX, MOD_DATA_MAX, MOD_DATA_TOTAL, installMods, parseModSpecies, stashModPets, type ModRec } from "../src/game/sfs2013/mods.ts";
import type { PetRecord, PetTables } from "../src/game/sfs2013/pets.ts";
import { EMPTY_PMDATA } from "../src/game/sfs2013/pmdata.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const pet = (id: number, race: number): PetRecord =>
  ({ id, race, level: 5, exp: 0, hp: 20, character: "勤奋", skills: [], iv: [1, 2, 3, 4, 5, 6], got: "2013-01-25" }) as PetRecord;

function tables(): PetTables {
  return {
    species: { "1": { n: "兔小子", a: 11, e: 18, next: 2, sk: [] } },
    pm: {
      ...structuredClone(EMPTY_PMDATA),
      species: { "1": { n: "兔小子", s: [45, 45, 60, 45, 60, 45], ev: [0, 0, 0, 0, 1, 0], t: [11, 11], bx: 64, xt: "2", c: ["NA", "NA"], evo: "", learn: [[0, 1016]] } },
      skills: { "1016": { n: "噼啪乱击", old: "", p: 40, p1: 40, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "" } } as unknown as PetTables["pm"]["skills"],
      chart: { "10": { "9": 2 }, "11": { "10": 2 } },
      exp: { "2": [1, 15, 52, 122, 237] },
    },
  };
}

function setup(rec: ModRec, t = tables()) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  installMods(world, { load: async () => rec, save: async () => {}, tables: async () => t, today: () => "2013-01-25" });
  const call = async (params: Record<string, unknown>) => {
    const replies: Record<string, any>[] = [];
    const ctx = { params, player: { name: rec.name }, reply: (o: Record<string, unknown>) => replies.push(o) } as unknown as XtContext;
    await handlers.get("SundriesExtension.revival_mod")!(ctx, "revival_mod");
    return replies[0];
  };
  return { call, t };
}

const FROG = JSON.stringify({ id: 900101, name: "泡泡蛙", attr: [10, 10], stats: [70, 60, 65, 80, 70, 75], skills: [[0, 1016]], exp: "2" });

test("mods: saved data by mod, its limits", async () => {
  const rec: ModRec = { id: 1, name: "小奥拉" };
  const { call } = setup(rec);
  assert.deepEqual(await call({ op: "data", mod: "hello", tag: "1" }), { op: "data", tag: "1", data: "" });
  assert.equal((await call({ op: "save", mod: "hello", data: '{"visits":2}', tag: "2" })).res, 1);
  assert.equal((await call({ op: "data", mod: "hello" })).data, '{"visits":2}');
  assert.equal((await call({ op: "save", mod: "bad id!", data: "{}" })).res, 0);
  assert.equal((await call({ op: "save", mod: "hello", data: "{not json" })).res, 0);
  assert.equal((await call({ op: "save", mod: "hello", data: JSON.stringify({ x: "y".repeat(MOD_DATA_MAX) }) })).res, 0);
  // Bytes, not characters: 30000 CJK characters are 90000 bytes.
  assert.equal((await call({ op: "save", mod: "hello", data: JSON.stringify({ x: "字".repeat(30000) }) })).res, 0);
  assert.equal((await call({ op: "data", mod: "other" })).data, "");
  // Names objects already have are no mod ids.
  assert.equal((await call({ op: "save", mod: "__proto__", data: "{}" })).res, 0);
  assert.equal((await call({ op: "data", mod: "constructor" })).data, "");
  // All mods together: at most MOD_DATA_TOTAL.
  const big = JSON.stringify({ x: "y".repeat(MOD_DATA_MAX - 20) });
  let saved = 0;
  for (let i = 0; i < MOD_DATA_TOTAL / MOD_DATA_MAX + 2; i++) saved += (await call({ op: "save", mod: `m${i}`, data: big })).res;
  assert.ok(saved < MOD_DATA_TOTAL / MOD_DATA_MAX + 2);
});

test("mods: a 亚比 of a mod is checked, made known, given; put aside while unknown and given back", async () => {
  const t = tables();
  assert.equal(typeof parseModSpecies(JSON.stringify({ id: 5, name: "x", attr: [10], stats: [1, 1, 1, 1, 1, 1], skills: [1016] }), t), "string");
  assert.equal(typeof parseModSpecies(JSON.stringify({ id: 900101, name: "x", attr: [77], stats: [1, 1, 1, 1, 1, 1], skills: [1016] }), t), "string");
  assert.equal(typeof parseModSpecies(JSON.stringify({ id: 900101, name: "x", attr: [10], stats: [1, 1, 1, 1, 1, 300], skills: [1016] }), t), "string");
  assert.equal(typeof parseModSpecies(JSON.stringify({ id: 900101, name: "x", attr: [10], stats: [1, 1, 1, 1, 1, 1], skills: [9999] }), t), "string");
  // An unknown or inherited curve becomes "2"; a legend cell of the chart is no attribute.
  const sp = parseModSpecies(JSON.stringify({ id: 900101, name: "x", attr: [10], stats: [1, 1, 1, 1, 1, 1], skills: [1016], exp: "__proto__" }), t);
  assert.equal(typeof sp === "object" && sp.exp, "2");
  assert.equal(typeof parseModSpecies(JSON.stringify({ id: 900101, name: "x", attr: [9], stats: [1, 1, 1, 1, 1, 1], skills: [1016] }), t), "string");

  const rec: ModRec = { id: 1, name: "小奥拉", pets: [pet(1, 1)], nextPetId: 1 };
  const { call } = setup(rec, t);
  // Not known yet: not given.
  assert.equal((await call({ op: "give", mod: "bubblefrog", race: 900101, level: 5 })).res, 0);
  const r = await call({ op: "species", mod: "bubblefrog", def: FROG });
  assert.equal(r.res, 1);
  assert.equal(JSON.parse(r.def).exp, "2");
  assert.equal(t.pm.species["900101"].n, "泡泡蛙");
  // Another mod may neither redefine it nor give it.
  assert.equal((await call({ op: "species", mod: "other", def: FROG })).res, 0);
  assert.equal((await call({ op: "give", mod: "other", race: 900101, level: 5 })).res, 0);
  assert.equal((await call({ op: "give", mod: "bubblefrog", race: 900101, level: 5 })).res, 1);
  assert.equal(rec.pets![1].mod, "bubblefrog");
  assert.deepEqual(rec.pets!.map((p) => p.race), [1, 900101]);
  rec.followPet = rec.pets![1].id;

  // A new page: the game does not know it; at login it is put aside, the follow forgotten.
  delete t.pm.species["900101"];
  assert.equal(stashModPets(rec, (race) => !!t.pm.species[String(race)]), true);
  assert.deepEqual(rec.pets!.map((p) => p.race), [1]);
  assert.equal(rec.modPets!.length, 1);
  assert.equal(rec.followPet, undefined);
  // A new run (the tables made again): another mod with the same number does not take it back.
  const t2 = tables();
  const { call: call2 } = setup(rec, t2);
  assert.equal((await call2({ op: "species", mod: "other", def: FROG })).back, 0);
  assert.equal(rec.modPets!.length, 1);
  // Its own mod does: back in the bag.
  const { call: call3 } = setup(rec, tables());
  assert.equal((await call3({ op: "species", mod: "bubblefrog", def: FROG })).back, 1);
  assert.deepEqual(rec.pets!.map((p) => p.race), [1, 900101]);
  assert.equal(rec.modPets!.length, 0);
});

test("mods: gifts go to the 仓库 when the bag is full", async () => {
  const rec: ModRec = { id: 1, name: "小奥拉", pets: Array.from({ length: BAG_MAX }, (_, i) => pet(i + 1, 1)), nextPetId: BAG_MAX };
  const { call } = setup(rec);
  assert.equal((await call({ op: "give", race: 1, level: 3 })).res, 1);
  assert.equal(rec.pets!.length, BAG_MAX);
  assert.equal(rec.storage![0].race, 1);
  assert.equal(rec.storage![0].level, 3);
});
