import assert from "node:assert/strict";
import { test } from "node:test";
import { BattleEngine, award, catchChance, installBattles, parseEffects, type Msg } from "../src/game/sfs2013/battle.ts";
import { catchLevel, skillsAt, type PmData } from "../src/game/sfs2013/pmdata.ts";
import { makePet, type PetOwner, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const pm: PmData = {
  species: {
    "1": { n: "兔小子", s: [45, 45, 60, 45, 60, 45], ev: [0, 0, 0, 0, 1, 0], t: [11, 11], bx: 64, xt: "0", c: ["NA", "NA"], evo: "0-1#18-2#36-3", learn: [[0, 1016], [4, 12002], [8, 4014]] },
    "2": { n: "犀利兔", s: [63, 63, 84, 63, 84, 63], ev: [0, 0, 1, 0, 1, 0], t: [11, 11], bx: 141, xt: "0", c: ["NA", "NA"], evo: "0-1#18-2#36-3", learn: [[0, 1016], [4, 12002], [8, 4014]] },
    "10": { n: "朵朵兔", s: [65, 20, 55, 45, 70, 45], ev: [0, 0, 0, 0, 1, 0], t: [14, 14], bx: 64, xt: "0", c: ["0", "0"], evo: "0-10#16-11", learn: [[0, 15009]] },
    "43": { n: "小冰犬", s: [50, 50, 40, 30, 30, 50], ev: [0, 1, 0, 0, 0, 0], t: [14, 14], bx: 64, xt: "0", c: ["1", "0"], evo: "0-43#18-44", learn: [[0, 15009], [4, 1021]] },
  },
  skills: {
    "1016": { n: "噼啪乱击", p: 80, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "给对方单体造成伤害" },
    "12002": { n: "生命长河", p: 80, acc: 100, pp: 15, pri: 0, t: 11, k: 1, d: "攻击对方单体，将伤害值的一半转化来回复自己体力值" },
    "4014": { n: "沙林毒气", p: -1, acc: 100, pp: 35, pri: 0, t: 3, k: 2, d: "命中则令对方单体中毒" },
    "15009": { n: "冰牙", p: 60, acc: 100, pp: 25, pri: 0, t: 14, k: 0, d: "10%概率令对方单体冰冻" },
    "1021": { n: "瞪眼", p: -1, acc: 100, pp: 30, pri: 0, t: 0, k: 2, d: "削弱对方单体防御等级1级" },
  },
  chart: { "14": { "11": 2 }, "11": { "14": 1 } },
  exp: { "0": Array.from({ length: 100 }, (_, i) => (i + 1) ** 3) },
};
const tables: PetTables = { species: {}, pm };

test("skill effects are read from the descriptions", () => {
  assert.deepEqual(parseEffects("30％概率令对方单体麻痹").status, { name: "麻痹", chance: 30 });
  assert.deepEqual(parseEffects("命中则令对方单体睡眠").status, { name: "睡眠", chance: 100 });
  assert.deepEqual(parseEffects("提升自己攻击和速度的等级各1级").stages, [{ self: true, stats: ["atk", "spd"], delta: 1, chance: 100 }]);
  assert.deepEqual(parseEffects("10%概率削弱对方单体特防等级1级").stages, [{ self: false, stats: ["sdef"], delta: -1, chance: 10 }]);
  assert.deepEqual(parseEffects("提升自己防御和特防的等级各1级，削弱速度等级1级").stages, [
    { self: true, stats: ["def", "sdef"], delta: 1, chance: 100 },
    { self: true, stats: ["spd"], delta: -1, chance: 100 },
  ]);
  assert.equal(parseEffects("攻击对方单体，将伤害值的一半转化来回复自己体力值").drain, 0.5);
  assert.equal(parseEffects("给对方单体造成伤害，自己承受伤害值的1/3").recoil, 1 / 3);
  assert.deepEqual(parseEffects("2回合内攻击对方单体2~5次").hits, [2, 5]);
  assert.equal(parseEffects("先发；给对方单体造成伤害").first, true);
  assert.equal(parseEffects("攻击对方单体，必定命中，容易暴击").sure, true);
  assert.equal(parseEffects("回复自己一半的体力值").heal, 0.5);
  assert.equal(parseEffects("攻击对方单体，下回合自己停止行动").recharge, true);
});

test("levels, skills and the catch-level table", () => {
  assert.deepEqual(skillsAt(pm.species["1"], 5), [1016, 12002]);
  assert.deepEqual(catchLevel(0), { clv: 1, ccle: 0, cnx: 30, pct: 0 });
  // 2013 petcatchgiftservice: expLevel[3] = 30 + 60 + round(0.2)*2*15 = 90
  assert.equal(catchLevel(90).clv, 3);
});

test("a skill hits, drains, poisons; attributes multiply", () => {
  const seq = [0.5, 0.99, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
  let i = 0;
  const e = new BattleEngine(tables, () => seq[i++ % seq.length]);
  const owner: PetOwner = { id: 7, name: "a" };
  const mine = makePet(tables, 1, 10, "d", 1);
  const wild = makePet(tables, 43, 5, "d");
  const b = e.start(1, "aixiscene1", owner, mine, wild, true);
  const hp0 = wild.hp;
  const [, r] = e.act(b, b.mine, b.wild, 1016);
  assert.equal(r.srt, 0);
  assert.ok(wild.hp < hp0);
  assert.equal(r.hpInc, wild.hp - hp0);
  const [, p] = e.act(b, b.mine, b.wild, 4014);
  assert.equal(b.wild.status, "中毒");
  assert.match(String(p.desc), /中毒了/);
  // Ice is good against grass (chart 14 -> 11 = 2).
  const [, ice] = e.act(b, b.wild, b.mine, 15009);
  assert.equal(ice.eff, 2);
  assert.match(String(ice.desc), /效果拔群/);
});

test("winning gives experience, levels and evolution", () => {
  const pet = makePet(tables, 1, 17, "d", 1);
  pet.exp = 18 ** 3 - 17 ** 3 - 1; // one short of 18
  const r = award(tables, pet, 43, 5);
  assert.equal(pet.level, 18);
  assert.equal(pet.race, 2);
  assert.equal(r.evolvedTo, 2);
  assert.equal(r.msgs[0][0], "2241");
  assert.ok(r.msgs.some(([c, m]) => c === "2242" && m.evolve === 2));
  assert.deepEqual(pet.ev, [0, 1, 0, 0, 0, 0]);
});

test("balls work once the wild 亚比 is weak", () => {
  const e = new BattleEngine(tables, () => 0.5);
  const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 10, "d", 1), makePet(tables, 43, 5, "d"), true);
  assert.equal(catchChance(tables, b.wild, 32, 1), 0);
  b.wild.pet.hp = 1;
  assert.equal(catchChance(tables, b.wild, 32, 1), 0.5);
  assert.equal(catchChance(tables, b.wild, 64, 1), 1);
});

test("the 朵朵兔 (捕获度 0) is caught at any HP; easy 亚比 earlier than a fifth", async () => {
  const { catchHpLimit } = await import("../src/game/sfs2013/battle.ts");
  const e = new BattleEngine(tables, () => 0.5);
  const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 10, "d", 1), makePet(tables, 10, 1, "d"), true);
  assert.equal(catchChance(tables, b.wild, 32, 1), 0.5);
  assert.equal(catchHpLimit(tables, 10), 1);
  assert.equal(catchHpLimit(tables, 43), 0.875);
  assert.equal(catchHpLimit(tables, 1), 0.2);
});

function harness(rng: () => number) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: PetOwner & { items: Record<string, Record<string, number>> } = { id: 10001, name: "小奥拉", items: { "2": { "32": 2, "30": 1 } } };
  owner.pets = [makePet(tables, 1, 12, "d", 1)];
  owner.nextPetId = 1;
  installBattles(world, {
    load: async () => owner,
    save: async () => {},
    tables: async () => tables,
    wild: async () => ({ aixiscene1: [{ raceId: 43, min: 3, max: 3, common: 1, rate: 0 }] }),
    today: () => "2013-01-25",
    rng,
  });
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
  return { owner, call };
}

test("a wild battle from the scene to the win", async () => {
  const { owner, call } = harness(() => 0.3);
  assert.deepEqual((await call("PetExtension.54_7"))[0][1], { pms: [{ raceId: 43, min: 3, max: 3, common: 1, rate: 0 }] });
  const start = await call("PetExtension.54_2", { raceId: 43, level: -1, sw: true, id: -1 });
  assert.deepEqual(start.map(([c]) => c), ["2303", "2401"]);
  const join = start[0][1] as { ch: boolean; pmmList: { battleView: { slotId: number; pmList: { pmSView: { r: number; lv: number } }[] } }[] };
  assert.equal(join.ch, true);
  assert.equal(join.pmmList[1].battleView.pmList[0].pmSView.r, 43);
  assert.equal(join.pmmList[1].battleView.pmList[0].pmSView.lv, 3);
  let end: Msg | undefined;
  for (let i = 0; i < 20 && !end; i++) {
    const out = await call("PocketMonsterExtension.1401", { skillId: 1016, tarSId: 1 });
    assert.ok(out.some(([c]) => c === "2411"));
    end = out.find(([c]) => c === "2403");
  }
  assert.ok(end, "the battle ended");
  assert.equal(end![1].isWin, true);
  assert.ok(owner.pets![0].exp > 0 || owner.pets![0].level > 12);
  // Over: further commands are refused.
  assert.equal((await call("PocketMonsterExtension.1401", { skillId: 1016 }))[0][0], "2414");
});

test("catching needs a weak 亚比 and uses up a ball", async () => {
  const { owner, call } = harness(() => 0.1);
  await call("PetExtension.54_2", { raceId: 43 });
  const early = await call("PocketMonsterExtension.1405", { tarSId: 1, itemId: 32 });
  assert.deepEqual(early.map(([c]) => c), ["2415"], "refused: no turn passes");
  assert.equal(early[0][1].pmId, 0);
  assert.equal(early[0][1].refused, true);
  assert.equal(owner.items["2"]["32"], 2, "no ball spent while it is too strong");
  // Weaken it by hand and try again.
  const out0 = await call("PocketMonsterExtension.1402", { itemId: 30 });
  assert.equal(out0[0][0], "onAmountUpdated");
  assert.equal(owner.items["2"]["30"], undefined);
});

test("escaping ends the battle", async () => {
  const { call } = harness(() => 0.5);
  await call("PetExtension.54_2", { raceId: 43 });
  const out = await call("PocketMonsterExtension.1404", {});
  assert.deepEqual(out.map(([c]) => c), ["2414"]);
  assert.equal(out[0][1].isEscape, true);
});

test("a 百分百亚比球 catches at once: the 亚比 joins the bag", async () => {
  const { owner, call } = harness(() => 0.5);
  owner.items["2"]["64"] = 1;
  await call("PetExtension.54_2", { raceId: 43 });
  const out = await call("PocketMonsterExtension.1405", { tarSId: 1, itemId: 64 });
  assert.deepEqual(out.map(([c]) => c), ["onAmountUpdated", "2415", "2403"]);
  const caught = out[1][1];
  assert.ok(Number(caught.pmId) > 0);
  assert.equal(caught.lc, 1);
  assert.equal(out[2][1].isCatched, true);
  assert.equal(owner.pets!.length, 2);
  assert.equal(owner.pets![1].race, 43);
  assert.ok((owner.catchExp ?? 0) > 0);
  assert.equal(owner.items["2"]["64"], undefined);
});
