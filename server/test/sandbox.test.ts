import assert from "node:assert/strict";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import type { PmData } from "../src/game/sfs2013/pmdata.ts";
import { makePet, statsOf, type PetOwner, type PetTables } from "../src/game/sfs2013/pets.ts";
import { parseSandboxLevel, SANDBOX_FORMAT, SANDBOX_MAX } from "../src/game/sfs2013/sandbox.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const pm: PmData = {
  species: {
    "1": { n: "兔小子", s: [45, 45, 60, 45, 60, 45], ev: [0, 0, 0, 0, 1, 0], t: [11, 11], bx: 64, xt: "0", c: ["NA", "NA"], evo: "0-1#18-2", learn: [[0, 1016]] },
    "43": { n: "小冰犬", s: [50, 50, 40, 30, 30, 50], ev: [0, 1, 0, 0, 0, 0], t: [14, 14], bx: 64, xt: "0", c: ["1", "0"], evo: "0-43#18-44", learn: [[0, 1016]] },
  },
  skills: { "1016": { n: "噼啪乱击", p: 80, acc: 100, pp: 35, pri: 0, t: 0, k: 0, d: "给对方单体造成伤害" } },
  chart: {},
  exp: { "0": Array.from({ length: 100 }, (_, i) => (i + 1) ** 3) },
};
const tables: PetTables = { species: {}, pm };
const fights = (r: number) => r === 1 || r === 43;

test("a 关卡 is read and checked: races that fight, levels up to 999, stats in percent", () => {
  const lv = parseSandboxLevel(
    JSON.stringify({ format: SANDBOX_FORMAT, version: 1, name: "试炼", enemies: [{ race: 43, level: 150, hp: 300, at: 50 }, { race: 1, level: 5000 }] }),
    fights,
  );
  assert.ok(typeof lv !== "string");
  assert.equal(lv.name, "试炼");
  assert.equal(lv.heal, true);
  assert.deepEqual(lv.enemies[0], { race: 43, level: 150, mul: [3, 0.5, 1, 1, 1, 1] });
  assert.equal(lv.enemies[1].level, 999);
  assert.equal(parseSandboxLevel("{", fights), "这不是关卡文件");
  assert.equal(parseSandboxLevel(JSON.stringify({ format: "x", enemies: [{ race: 1 }] }), fights), "这不是奥拉星的关卡文件");
  assert.equal(parseSandboxLevel(JSON.stringify({ enemies: [] }), fights), "关卡里还没有对手");
  assert.match(String(parseSandboxLevel(JSON.stringify({ enemies: [{ race: 7 }] }), fights)), /不能对战/);
  const many = Array.from({ length: SANDBOX_MAX + 1 }, () => ({ race: 1 }));
  assert.match(String(parseSandboxLevel(JSON.stringify({ enemies: many }), fights)), /最多/);
  // Out of range percentages are held to 1%–10000%.
  const odd = parseSandboxLevel(JSON.stringify({ enemies: [{ race: 1, level: 3, sp: 0, hp: 1e9 }] }), fights);
  assert.ok(typeof odd !== "string");
  assert.deepEqual(odd.enemies[0].mul, [100, 1, 1, 1, 1, 0.01]);
});

test("stat factors multiply a 亚比's stats", () => {
  const p = makePet(tables, 43, 150, "2013-01-25");
  const plain = statsOf(p, tables);
  p.mul = [2, 1, 1, 1, 1, 0.5];
  const s = statsOf(p, tables);
  assert.equal(s[0], Math.round(plain[0] * 2));
  assert.equal(s[5], Math.round(plain[5] * 0.5));
  assert.equal(s[1], plain[1]);
});

test("a 沙盒 fight: the i-th opponent at its level and stats, not to be caught, no experience for the win", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: PetOwner = { id: 1, name: "小奥拉", pets: [makePet(tables, 1, 100, "d", 1)], nextPetId: 1 };
  installBattles(world, { load: async () => owner, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => "2013-01-25", rng: () => 0.5 });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = { params, player: { name: owner.name, room: { name: "starland" } }, reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  const lv = JSON.stringify({ format: SANDBOX_FORMAT, enemies: [{ race: 1, level: 3 }, { race: 43, level: 120, hp: 200 }] });
  const bad = await call("SundriesExtension.revival_sandbox", { lv: "nope", i: 0 });
  assert.deepEqual(bad, [["revival_sandbox", { res: 0, msg: "这不是关卡文件" }]]);
  const start = await call("SundriesExtension.revival_sandbox", { lv, i: 1 });
  assert.deepEqual(start[0], ["revival_sandbox", { res: 1, i: 1, n: 2, race: 43, level: 120 }]);
  const join = start.find(([c]) => c === "2303")![1] as { ch: boolean; pmmList: { battleView: { pmList: { pmSView: { r: number; lv: number } }[] } }[] };
  assert.equal(join.ch, false);
  assert.equal(join.pmmList[1].battleView.pmList[0].pmSView.r, 43);
  assert.equal(join.pmmList[1].battleView.pmList[0].pmSView.lv, 120);
  // A battle still open: refused before anything (its heal would heal that battle's 亚比).
  owner.pets![0].hp = 1;
  const again = await call("SundriesExtension.revival_sandbox", { lv, i: 1 });
  assert.deepEqual(again, [["revival_sandbox", { res: 0, msg: "战斗还没有结束，现在不能这样做。" }]]);
  assert.equal(owner.pets![0].hp, 1, "not healed");
  await call("PocketMonsterExtension.1404", {}); // run away: the next fight may start
  // The first opponent (Lv3) is beaten without any experience.
  const exp0 = owner.pets![0].exp;
  owner.pets![0].hp = 1; // healed before the fight (heal is the default)
  await call("SundriesExtension.revival_sandbox", { lv, i: 0 });
  let end: Msg | undefined;
  for (let i = 0; i < 20 && !end; i++) end = (await call("PocketMonsterExtension.1401", { skillId: 1016, tarSId: 1 })).find(([c]) => c === "2403");
  assert.equal(end?.[1].isWin, true);
  assert.equal(owner.pets![0].exp, exp0);
  assert.equal(owner.pets![0].level, 100);
  assert.ok(owner.pets![0].hp > 1);
  // heal: false leaves the bag as it is.
  owner.pets![0].hp = 5;
  await call("SundriesExtension.revival_sandbox", { lv: JSON.stringify({ heal: false, enemies: [{ race: 1, level: 1 }] }), i: 0 });
  assert.equal(owner.pets![0].hp, 5);
});

test("a 沙盒 team together: one battle, the next opponent out as each falls, the end names the first", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: PetOwner = { id: 1, name: "小奥拉", pets: [makePet(tables, 1, 100, "d", 1)], nextPetId: 1 };
  installBattles(world, { load: async () => owner, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => "2013-01-25", rng: () => 0.5 });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = { params, player: { name: owner.name, room: { name: "starland" } }, reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  const lv = JSON.stringify({ format: SANDBOX_FORMAT, together: true, enemies: [{ race: 1, level: 3 }, { race: 43, level: 4, hp: 200 }, { race: 1, level: 5 }] });
  const start = await call("SundriesExtension.revival_sandbox", { lv, i: 2 });
  assert.deepEqual(start[0], ["revival_sandbox", { res: 1, i: 0, n: 1, race: 1, level: 3 }]);
  const out: Msg[] = [];
  let end: Msg | undefined;
  for (let i = 0; i < 40 && !end; i++) {
    const turn = await call("PocketMonsterExtension.1401", { skillId: 1016, tarSId: 1 });
    out.push(...turn);
    end = turn.find(([c]) => c === "2403");
  }
  const outs = out.filter(([c, o]) => c === "2413" && (o.extInfo as { foe?: boolean }).foe);
  assert.equal(outs.length, 2);
  assert.match(String((outs[0][1].extInfo as { desc: string }).desc), /小冰犬出战了/);
  assert.equal(end?.[1].isWin, true);
  assert.equal(end?.[1].raceId, 1);
});
