import assert from "node:assert/strict";
import { test } from "node:test";
import type { PmData } from "../src/game/sfs2013/pmdata.ts";
import { makePet, statsOf, type PetTables } from "../src/game/sfs2013/pets.ts";
import { installSuperEvo, superEvolve, superTarget, type SuperOwner } from "../src/game/sfs2013/superevo.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

// 大师兔 (3) and its fourth form 终结兔 (500), 烈焰鸟 (278) and 烈焰凤凰 (506), and a 亚比 with none.
const sp = (n: string, learn: [number, number][]) => ({ n, s: [80, 80, 80, 80, 80, 80], ev: [0, 0, 1, 0, 0, 0], t: [11, 11] as [number, number], bx: 200, xt: "0", c: ["NA", "NA"] as [string, string], evo: "", learn });
const pm: PmData = {
  species: { "3": sp("大师兔", [[0, 1016], [40, 12022]]), "500": sp("终结兔", [[0, 1016], [4, 1019], [20, 1031]]), "278": sp("烈焰鸟", [[0, 1016]]), "506": sp("烈焰凤凰", [[0, 10002]]), "10": sp("朵朵兔", [[0, 1016]]) },
  skills: {
    "1016": { n: "噼啪乱击", p: 80, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "" },
    "1019": { n: "猛击", p: 60, acc: 100, pp: 30, pri: 0, t: 0, k: 0, d: "" },
    "1031": { n: "冲撞", p: 70, acc: 100, pp: 30, pri: 0, t: 0, k: 0, d: "" },
    "10002": { n: "火花", p: 40, acc: 100, pp: 30, pri: 0, t: 10, k: 1, d: "" },
    "12022": { n: "叶刃斩", p: 90, acc: 100, pp: 15, pri: 0, t: 11, k: 0, d: "" },
  },
  chart: {},
  exp: { "0": Array.from({ length: 100 }, (_, i) => (i + 1) ** 3) },
};
const t: PetTables = { species: {}, pm };

test("超进化: level 60 and the materials; back to 1级, 学习力 gone, 天赋 and 性格 kept", () => {
  assert.equal(superTarget(3), 500);
  assert.equal(superTarget(278), 506);
  assert.equal(superTarget(10), undefined);
  const p = makePet(t, 3, 59, "2013-02-01", 1, "坦率");
  p.iv = [31, 20, 31, 31, 31, 31];
  p.ev = [0, 100, 0, 0, 0, 0];
  const o: SuperOwner = { pets: [p], items: { "2": { "265": 30, "266": 10, "88": 1, "213": 1 } } };
  assert.match((superEvolve(t, o, p) as { msg: string }).msg, /60级/);
  p.level = 60;
  o.items!["2"]["213"] = 0;
  assert.match((superEvolve(t, o, p) as { msg: string }).msg, /材料/);
  o.items!["2"]["213"] = 1;
  const r = superEvolve(t, o, p);
  assert.ok("to" in r && r.to === 500);
  assert.deepEqual("amounts" in r && r.amounts, ["2_265_0_-30", "2_266_0_-10", "2_88_0_-1", "2_213_0_-1"]);
  assert.deepEqual(o.items!["2"], {});
  assert.equal(p.race, 500);
  assert.equal(p.level, 1);
  assert.deepEqual(p.ev, [0, 0, 0, 0, 0, 0]);
  assert.deepEqual(p.iv, [31, 20, 31, 31, 31, 31]);
  assert.equal(p.character, "坦率");
  assert.deepEqual(p.skills.map((s) => s.id), [1016]);
  assert.equal(p.hp, statsOf(p, t)[0]);
});

test("54e_1: 烈焰鸟 with a 炎之结晶; a 亚比 without a fourth form goes to the handler before", async () => {
  const handlers = new Map<string, XtHandler>();
  let before = 0;
  handlers.set("PetExtension2.54e_1", () => void before++);
  const world = { handlers, xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {}, setUserVarOnce: () => {} } as unknown as World;
  const bird = makePet(t, 278, 70, "2013-02-01", 1);
  const other = makePet(t, 10, 70, "2013-02-01", 2);
  const o: SuperOwner = { pets: [bird, other], items: { "2": { "335": 1 } } };
  installSuperEvo(world, { load: async () => o, save: async () => {}, tables: async () => t });
  const replies: [string | undefined, Record<string, unknown>][] = [];
  const ctx = (params: Record<string, unknown>) => ({ params, player: { name: "a" }, session: {}, reply: (b: Record<string, unknown>, c?: string) => void replies.push([c, b]) }) as unknown as XtContext;
  await handlers.get("PetExtension2.54e_1")!(ctx({ pid: 2, t: 1 }), "54e_1");
  assert.equal(before, 1);
  await handlers.get("PetExtension2.54e_1")!(ctx({ pid: 1, t: 2 }), "54e_1");
  assert.deepEqual(replies, [
    ["onAmountUpdated", { amount: "2_335_0_-1" }],
    ["54e_1", { res: 0, pid: 1, raceId: 506 }],
  ]);
  assert.equal(bird.race, 506);
  assert.equal(bird.level, 1);
});
