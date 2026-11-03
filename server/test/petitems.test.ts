import assert from "node:assert/strict";
import { test } from "node:test";
import { award } from "../src/game/sfs2013/battle.ts";
import { applyPetItem, installPetItems, type PetItemOwner } from "../src/game/sfs2013/petitems.ts";
import type { PmData } from "../src/game/sfs2013/pmdata.ts";
import { makePet, statsOf, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

// A small made-up table: a three-form line (1 -> 2 at 18 -> 3 at 36), a race that does not
// evolve, and the 伊尼 line of the 2013 PetStoneData (371 -> 372 by stone; 372's skill stone).
const pm: PmData = {
  species: {
    "1": { n: "兔小子", s: [45, 45, 60, 45, 60, 45], ev: [0, 0, 0, 0, 1, 0], t: [11, 11], bx: 64, xt: "0", c: ["NA", "NA"], evo: "0-1#18-2#36-3", learn: [[0, 1016]] },
    "2": { n: "犀利兔", s: [63, 63, 84, 63, 84, 63], ev: [0, 0, 1, 0, 1, 0], t: [11, 11], bx: 141, xt: "0", c: ["NA", "NA"], evo: "0-1#18-2#36-3", learn: [[0, 1016]] },
    "3": { n: "霸王兔", s: [80, 80, 100, 80, 100, 80], ev: [0, 0, 2, 0, 1, 0], t: [11, 11], bx: 200, xt: "0", c: ["NA", "NA"], evo: "0-1#18-2#36-3", learn: [[0, 1016]] },
    "10": { n: "朵朵兔", s: [65, 20, 55, 45, 70, 45], ev: [0, 0, 0, 0, 1, 0], t: [14, 14], bx: 64, xt: "0", c: ["0", "0"], evo: "", learn: [[0, 1016]] },
    "371": { n: "伊尼", s: [50, 50, 50, 50, 50, 50], ev: [1, 0, 0, 0, 0, 0], t: [0, 0], bx: 64, xt: "0", c: ["NA", "NA"], evo: "", learn: [[0, 1016]] },
    "372": { n: "功夫伊尼", s: [70, 90, 60, 50, 60, 70], ev: [0, 2, 0, 0, 0, 0], t: [0, 0], bx: 150, xt: "0", c: ["NA", "NA"], evo: "", learn: [[0, 1016]] },
  },
  skills: {
    "1016": { n: "噼啪乱击", p: 80, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "给对方单体造成伤害" },
    "2226": { n: "超神龙霸", p: 150, acc: 100, pp: 5, pri: 0, t: 0, k: 0, d: "给对方单体造成伤害" },
  },
  chart: {},
  exp: { "0": Array.from({ length: 100 }, (_, i) => (i + 1) ** 3) },
};
const t: PetTables = { species: {}, pm };
const owner = (): PetItemOwner => ({ id: 1, name: "小奥拉", pets: [] });
const pet = (race: number, level: number) => {
  const p = makePet(t, race, level, "2013-01-20", 1, "坦率");
  p.iv = [31, 31, 31, 31, 31, 31];
  p.hp = statsOf(p, t)[0];
  return p;
};

test("体力糖 heal, and not a 亚比 at full strength", () => {
  const p = pet(1, 20);
  assert.equal(applyPetItem(t, owner(), 60, p).ok, false);
  p.hp = 10;
  const r = applyPetItem(t, owner(), 60, p);
  assert.equal(r.ok, true);
  assert.equal(p.hp, Math.min(statsOf(p, t)[0], 110));
});

test("活力豆 give uses back to every skill carried", () => {
  const p = pet(1, 20);
  assert.equal(applyPetItem(t, owner(), 103, p).ok, false);
  p.skills[0].pp = 1;
  assert.equal(applyPetItem(t, owner(), 103, p).ok, true);
  assert.equal(p.skills[0].pp, 11);
});

test("初始亚比经验糖 only for the starters' lines; 摇摇果实 for any below 100", () => {
  assert.equal(applyPetItem(t, owner(), 233, pet(10, 5)).ok, false);
  const s = pet(1, 5);
  const r = applyPetItem(t, owner(), 241, s);
  assert.equal(r.ok, true);
  assert.ok(s.level > 5);
  assert.ok(r.ok && r.msgs && r.msgs.some(([c]) => c === "2241"));
  assert.equal(applyPetItem(t, owner(), 419, pet(10, 100)).ok, false);
});

test("学习力 fruits stop at 255 for one and 510 in all; 遗忘喷雾 not at level 100", () => {
  const p = pet(1, 50);
  assert.equal(applyPetItem(t, owner(), 525, p).ok, true);
  assert.equal(p.ev![1], 5);
  p.ev = [255, 255, 0, 0, 0, 0];
  assert.match(applyPetItem(t, owner(), 526, p).msg, /510/);
  p.ev = [0, 255, 0, 0, 0, 0];
  assert.match(applyPetItem(t, owner(), 525, p).msg, /255/);
  assert.equal(applyPetItem(t, owner(), 154, p).ok, true);
  assert.equal(p.ev![1], 0);
  assert.equal(applyPetItem(t, owner(), 154, p).ok, false);
  const top = pet(1, 100);
  top.ev = [10, 10, 10, 10, 10, 10];
  assert.equal(applyPetItem(t, owner(), 523, top).ok, false);
  top.level = 99;
  assert.equal(applyPetItem(t, owner(), 523, top).ok, true);
  assert.deepEqual(top.ev, [0, 0, 0, 0, 0, 0]);
});

test("降级喷雾, 还原喷雾 and 形态固化剂", () => {
  const p = pet(2, 30);
  assert.equal(applyPetItem(t, owner(), 65, p).ok, true);
  assert.equal(p.level, 29);
  assert.equal(applyPetItem(t, owner(), 65, pet(1, 1)).ok, false);
  p.ev = [4, 4, 4, 4, 4, 4];
  const r = applyPetItem(t, owner(), 193, p);
  assert.equal(r.ok && r.raceChanged, true);
  assert.equal(p.race, 1);
  assert.equal(p.level, 1);
  assert.deepEqual(p.ev, [4, 4, 4, 4, 4, 4]);
  assert.equal(applyPetItem(t, owner(), 193, p).ok, false);
  // Fixed: levels go on, the form stays.
  const f = pet(1, 17);
  assert.equal(applyPetItem(t, owner(), 220, f).ok, true);
  assert.equal(applyPetItem(t, owner(), 220, f).ok, false);
  applyPetItem(t, owner(), 664, f);
  assert.ok(f.level >= 18);
  assert.equal(f.race, 1);
  assert.equal(applyPetItem(t, owner(), 220, pet(10, 10)).ok, false);
});

test("性格 cards: 66 any other, 414 one of its four", () => {
  const p = pet(1, 10);
  assert.equal(applyPetItem(t, owner(), 66, p, () => 0).ok, true);
  assert.notEqual(p.character, "坦率");
  applyPetItem(t, owner(), 414, p, () => 0.99);
  assert.ok(["孤僻", "勇敢", "固执", "调皮"].includes(p.character));
});

test("进化石 and 技能石 of the 2013 PetStoneData", () => {
  const p = pet(371, 60);
  assert.equal(applyPetItem(t, owner(), 649, p).ok, false);
  const r = applyPetItem(t, owner(), 645, p);
  assert.equal(r.ok && r.raceChanged, true);
  assert.equal(p.race, 372);
  assert.equal(applyPetItem(t, owner(), 645, p).ok, false);
  p.level = 59;
  assert.equal(applyPetItem(t, owner(), 649, p).ok, false);
  p.level = 60;
  assert.equal(applyPetItem(t, owner(), 649, p).ok, true);
  assert.ok(p.learned!.includes(2226));
  assert.equal(applyPetItem(t, owner(), 649, p).ok, false);
});

test("经验器 and 学习器 count wins; the battle doubles or triples with them", () => {
  const o = owner();
  assert.equal(applyPetItem(t, o, 43, undefined).ok, true);
  assert.equal(applyPetItem(t, o, 378, undefined).ok, true);
  assert.deepEqual(o.boosts, { exp2: 50, exp3: 50 });
  const a = pet(1, 10), b = pet(1, 10);
  const expOf = (msgs: [string, Record<string, unknown>][]) => Number(msgs.find(([c]) => c === "2241")![1].exp);
  const plain = expOf(award(t, a, 10, 10).msgs);
  const boosted = expOf(award(t, b, 10, 10, { exp: 3, ev: 2 }).msgs);
  // Same species, same start: three times the experience, twice the 学习力.
  assert.equal(boosted, plain * 3);
  assert.equal(b.ev![4], a.ev![4] * 2);
});

test("14_12 takes one item, tells the client, and refuses what it cannot use", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (n: string, h: XtHandler) => handlers.set(n, h) } as unknown as World;
  const o: PetItemOwner = { id: 1, name: "小奥拉", pets: [pet(1, 20)], items: { "2": { "60": 2 } } };
  o.pets![0].hp = 1;
  installPetItems(world, { load: async () => o, save: async () => {}, tables: async () => t });
  const run = async (params: Record<string, unknown>) => {
    const out: [string, Record<string, unknown>][] = [];
    const ctx = { params, reply: (b: Record<string, unknown>, c = "14_12") => out.push([c, b]) } as unknown as XtContext;
    await handlers.get("MaterialExtension.14_12")!(ctx, "14_12");
    return out;
  };
  const ok = await run({ ii: 60, pi: 1, pa: -1, num: 1 });
  assert.deepEqual(ok[0], ["onAmountUpdated", { amount: "2_60_0_-1" }]);
  assert.equal(ok.at(-1)![1].res, 1);
  assert.equal(o.items!["2"]["60"], 1);
  const none = await run({ ii: 61, pi: 1 });
  assert.equal(none.at(-1)![1].res, 0);
  const full = await run({ ii: 60, pi: 1 });
  assert.equal(o.pets![0].hp < statsOf(o.pets![0], t)[0] ? 1 : 0, full.at(-1)![1].res);
});
