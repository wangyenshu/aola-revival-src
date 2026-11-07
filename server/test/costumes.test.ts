import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { GUARDIANS, installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import { COSTUME_CHANCE, GUARDIAN_SUITS, SUITS, WUSHEN_SUIT, costumeDrop } from "../src/game/sfs2013/costumes.ts";
import { installFightKing } from "../src/game/sfs2013/fightking.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};

test("a part not had, by chance, until the suit is complete", () => {
  const o: { items?: Record<string, Record<string, number>> } = {};
  assert.deepEqual(costumeDrop(o, 162, () => COSTUME_CHANCE), [], "missed");
  const parts = Object.keys(SUITS[162][1]);
  const got = new Set<string>();
  for (let i = 0; i < 20; i++) {
    const r = costumeDrop(o, 162, () => 0);
    if (!r.length) break;
    const id = String(r[0][1].amount).split("_")[1];
    assert.ok(!got.has(id), "never one had");
    got.add(id);
    assert.match(String(r[1][1].text), /^获得了.+！$/);
  }
  assert.deepEqual([...got].sort(), parts.sort());
  assert.deepEqual(costumeDrop(o, 162, () => 0), [], "all had");
  assert.deepEqual(costumeDrop(o, undefined, () => 0), [], "no suit");
});

test("every 守护者 of a suit is one of the table's", () => {
  const species = new Set(GUARDIANS.flatMap(([races]) => races.split(/[#,]/).map((r) => Number(r) % 10000)));
  for (const [sp, suit] of Object.entries(GUARDIAN_SUITS)) {
    assert.ok(SUITS[suit], `suit ${suit}`);
    if (Number(sp) !== 114) assert.ok(species.has(Number(sp)), `守护者 ${sp}`);
  }
});

function harness() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {}, handlers } as unknown as World;
  const o = { id: 1, name: "小奥拉", items: {} as Record<string, Record<string, number>>, score: 0, pets: [makePet(tables, 1300, 100, "d", 1)], nextPetId: 1 };
  installBattles(world, { load: async () => o as never, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => "2013-01-25", rng: () => 0, now: () => 1 });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = { params, player: { name: o.name, room: { name: "woerte4" } }, reply: (b: Record<string, unknown>, c = key.split(".")[1]) => out.push([c, b]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  const fight = async () => {
    const all: Msg[] = [];
    for (let n = 0; n < 300 && !all.some(([c]) => c === "2403" || c === "2404"); n++) {
      const sk = o.pets[0].skills.filter((s) => s.pp > 0).sort((a, b) => (tables.pm.skills[String(b.id)]?.p ?? 0) - (tables.pm.skills[String(a.id)]?.p ?? 0))[0];
      all.push(...(await call("PocketMonsterExtension.1401", { skillId: sk.id })));
      o.pets[0].hp = 99999;
      for (const s of o.pets[0].skills) s.pp = s.max;
    }
    return all;
  };
  return { o, world, call, fight };
}

test("金刚库巴 leaves a part of its suit, shown at the end of the battle", async () => {
  const h = harness();
  await h.call("PetExtension.54_16", { raceId: "10096", index: 0 });
  const end = await h.fight();
  const win = end.find(([c]) => c === "2403")![1] as Record<string, any>;
  assert.equal(win.isWin, true);
  const bn = (win.bn as { type: number; id: number }[]).find((b) => b.type === 0)!;
  assert.ok(Object.keys(SUITS[162][1]).includes(String(bn.id)));
  assert.equal(h.o.items["0"][String(bn.id)], 1);
});

test("a general of 武神大陆 leaves a part of the 武神套装", async () => {
  const h = harness();
  installFightKing(h.world, { me: async () => h.o as never, save: async () => {}, today: () => "2013-01-25", now: () => 1 });
  await h.call("PetExtension.54_22", { type: 70 });
  const end = await h.fight();
  const win = end.find(([c]) => c === "2403")![1] as Record<string, any>;
  assert.equal(win.isWin, true);
  const bn = (win.bn as { type: number; id: number }[]).find((b) => b.type === 0)!;
  assert.ok(Object.keys(SUITS[WUSHEN_SUIT][1]).includes(String(bn.id)));
});
