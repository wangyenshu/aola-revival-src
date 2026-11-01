import assert from "node:assert/strict";
import { test } from "node:test";
import { installEggs } from "../src/game/sfs2013/eggs.ts";
import {
  EGG_OF,
  FUSE_LOC,
  GENIUS_ENERGY_COST,
  GENIUS_ENERGY_MAX,
  GENIUS_XINGBI,
  HATCH_HOURS,
  fuseCollect,
  fuseState,
  geniusStars,
  installYabiStudy,
  type LabDeps,
  type LabRec,
} from "../src/game/sfs2013/yabistudy.ts";
import type { PetRecord, PetTables } from "../src/game/sfs2013/pets.ts";
import { EMPTY_PMDATA } from "../src/game/sfs2013/pmdata.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

type Reply = [string | undefined, Record<string, any>];

const pet = (id: number, race: number, level: number, iv = [31, 31, 31, 31, 31, 31]): PetRecord =>
  ({ id, race, level, exp: 0, hp: 100, character: "勤奋", skills: [], iv, got: "2013-01-25" }) as PetRecord;

function setup(randoms: number[] = []) {
  const handlers = new Map<string, XtHandler>();
  const vars: Record<string, unknown>[] = [];
  const world = {
    xt: (k: string, h: XtHandler) => (handlers.set(k, h), world),
    setUserVars: (_s: unknown, v: Record<string, unknown>) => vars.push(v),
  } as unknown as World;
  const rec: LabRec = {
    id: 10001,
    name: "小奥拉",
    xingbi: 25,
    items: { "2": { "38": 2 } },
    // 伊莎女王 (39, Lv50) and 雪雾怪 (144, Lv40): the formula of 伊蓝 (431), with 炎冰 (38).
    pets: [pet(1, 39, 50), pet(2, 144, 40), pet(3, 13, 30, [5, 5, 5, 5, 5, 5])],
    nextPetId: 3,
    followPet: 2,
  };
  const store = new Map<string, unknown>();
  const clock = { now: Date.UTC(2013, 0, 25, 10, 0, 0) };
  const tables = { species: {}, pm: EMPTY_PMDATA } as unknown as PetTables;
  const queue = [...randoms];
  const deps: LabDeps<LabRec> = {
    load: async () => rec,
    save: async () => {},
    now: () => clock.now,
    today: () => "2013-01-25",
    tables: async () => tables,
    get: async <T>(k: string) => store.get(k) as T | undefined,
    set: async (k, v) => void store.set(k, structuredClone(v)),
    random: () => (queue.length ? queue.shift()! : 0),
  };
  installYabiStudy(world, deps);
  installEggs(world, {
    me: async () => rec,
    save: async () => {},
    now: () => clock.now,
    hatchPet: async () => 0,
    fuse: { state: (o, st) => fuseState(o, st, deps), collect: (o, id) => fuseCollect(o, id) },
  });
  const player = { name: "小奥拉" };
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const replies: Reply[] = [];
    const ctx = { params, player, session: {}, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    const h = handlers.get(key);
    assert.ok(h, `no handler for ${key}`);
    await h(ctx, key);
    return replies;
  };
  const answer = (r: Reply[], cmd?: string) => r.find(([c]) => c === cmd)?.[1];
  return { rec, store, clock, call, answer, vars };
}

test("亚比融合: two 亚比 and the material make a 元生体, which hatches in its place's 孵化器", async () => {
  const { rec, clock, call, answer, vars } = setup();
  // The wrong second 亚比: nothing happens.
  assert.equal(answer(await call("PetExtension2.54e_13", { mId: 1, sId: 3, ss: true }))!.succ, false);
  const r = await call("PetExtension2.54e_13", { mId: 1, sId: 2, ss: true });
  assert.deepEqual(answer(r), { succ: true, id: 395 });
  assert.deepEqual(rec.pets!.map((p) => p.id), [3]);
  assert.equal(rec.items!["2"]["38"], 1);
  assert.equal(rec.items!["2"]["395"], 1);
  assert.equal(rec.followPet, undefined);
  assert.ok(vars.length > 0);
  // The 寒冰孵化器 (aixiscene4, kind 3) is empty; the others too.
  assert.equal(answer(await call("PetEggExtension.1-2", { st: 3 }), "1-2")!.st, 4);
  await call("PetExtension2.54e_14", { id: 395 });
  assert.equal(rec.items!["2"]["395"], undefined);
  const hatching = answer(await call("PetEggExtension.1-2", { st: 3 }), "1-2")!;
  assert.equal(hatching.os, 3);
  assert.equal(hatching.st, 2);
  assert.equal(hatching.es[0].ri, 431);
  assert.equal(hatching.es[0].lt, HATCH_HOURS[431] * 3600);
  assert.equal(answer(await call("PetEggExtension.1-2", { st: 4 }), "1-2")!.st, 4);
  // 72 hours later it is a 伊蓝, in the 仓库, until GetPetPanel takes it out.
  clock.now += HATCH_HOURS[431] * 3600 * 1000;
  const done = answer(await call("PetEggExtension.1-2", { st: 3 }), "1-2")!;
  assert.equal(done.st, 3);
  const id = done.pmList[0].pmPView.i;
  assert.equal(done.pmList[0].pmPView.r, 431);
  assert.equal(rec.storage!.find((p) => p.id === id)!.race, 431);
  assert.equal(answer(await call("PocketMonsterExtension.1223", { id, loc: FUSE_LOC }), "2223")!.res, 1);
  assert.equal(answer(await call("PetEggExtension.1-2", { st: 3 }), "1-2")!.st, 4);
});

test("亚比融合: one formula, two forms: the 变异 one sometimes", async () => {
  const { rec, call, answer } = setup([0, 0]);
  rec.pets = [pet(1, 258, 40), pet(2, 69, 20)];
  rec.items = { "2": { "90": 1 } };
  assert.deepEqual(answer(await call("PetExtension2.54e_13", { mId: 1, sId: 2, ss: true })), { succ: true, id: EGG_OF[353] });
});

test("天赋启迪: 10 energy a time, back 1 a minute online; 星币启迪 10 星币", async () => {
  const { rec, clock, call, answer, store } = setup([0, 0.99, 0, 0.99, 0, 0.99, 0, 0.99]);
  const panel = answer(await call("HolidayExtension.0118genius_panel", { pId: 3 }))!;
  assert.equal(panel.ba, "5#5#5#5#5#5");
  assert.equal(panel.energy, GENIUS_ENERGY_MAX);
  const p = answer(await call("HolidayExtension.0118genius_power", { pId: 3 }))!;
  assert.equal(p.result, 2);
  assert.equal(p.index, 0);
  assert.equal(p.diff, 3);
  assert.equal(p.energy, GENIUS_ENERGY_MAX - GENIUS_ENERGY_COST);
  assert.equal(rec.pets![2].iv![0], 8);
  await call("HolidayExtension.0118genius_power", { pId: 3 });
  await call("HolidayExtension.0118genius_power", { pId: 3 });
  assert.equal(answer(await call("HolidayExtension.0118genius_power", { pId: 3 }))!.result, -1);
  clock.now += 10 * 60 * 1000;
  assert.equal(answer(await call("HolidayExtension.revival_genius_energy"))!.energy, 10);
  // 星币启迪.
  const before = rec.xingbi!;
  const b = await call("HolidayExtension.0118genius_buy", { pId: 3 });
  assert.equal(answer(b)!.res, 1);
  assert.equal(rec.xingbi, before - GENIUS_XINGBI);
  assert.deepEqual(answer(b, "onXingBiUpdate"), { xingbi: rec.xingbi });
  // 万众瞩目 and above: no 天赋启迪; reaching 王者无敌 goes on the board.
  rec.pets![2].iv = [62, 62, 62, 62, 62, 45];
  assert.equal(geniusStars(rec.pets![2].iv!), 29);
  assert.equal(answer(await call("HolidayExtension.0118genius_power", { pId: 3 }))!.result, 0);
  rec.pets![2].iv = [62, 62, 62, 62, 62, 50];
  rec.xingbi = 10;
  await call("HolidayExtension.0118genius_buy", { pId: 3 });
  assert.ok(rec.pets![2].iv![5] > 50);
  assert.deepEqual(store.get("area/geniusTop"), ["小奥拉:小奥拉:13"]);
  // Answered empty (GENIUS_TOP_SHOWN).
  assert.equal(answer(await call("HolidayExtension.0118genius_top"))!.top, "");
});
