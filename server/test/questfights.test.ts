import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import { installQuestFights } from "../src/game/sfs2013/questfights.ts";
import { installTasks, registerTaskTables, skipTo, type TaskOwner } from "../src/game/sfs2013/tasks.ts";
import { makePet, type PetOwner, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};
registerTaskTables(JSON.parse(readFileSync(new URL("tasks.json", revival), "utf8")));

function harness() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {}, handlers } as unknown as World;
  const o: PetOwner & TaskOwner = { id: 10001, name: "小奥拉", items: {} } as never;
  o.pets = [makePet(tables, 1300, 50, "d", 1)];
  (o as { nextPetId?: number }).nextPetId = 1;
  installBattles(world, { load: async () => o, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => "2013-01-25", rng: () => 0.5, now: () => 1_000_000 });
  installTasks(world, { load: async () => o, save: async () => {}, now: () => 1_000_000 });
  installQuestFights(world);
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = { params, player: { name: o.name, room: { name: "youanmingzhou4" } }, reply: (b: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, b]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  const get = (out: Msg[], cmd: string) => out.find(([c]) => c === cmd)?.[1] as Record<string, any> | undefined;
  return { o, call, get };
}

test("月亮之殿's fights (54_22 type 17, npc 6 then 7) start while quest 1606 is being done", async () => {
  const h = harness();
  assert.equal(h.get(await h.call("PetExtension.54_22", { type: 17, npc: 6 }), "54_22")!.res, false, "not before the quest");
  skipTo(h.o, 1610, 1);
  const out = await h.call("PetExtension.54_22", { type: 17, npc: 6, canCatch: false });
  assert.equal(h.get(out, "54_22")!.res, true);
  assert.ok(out.some(([c]) => c === "2401" || c === "2402" || c === "2400"), "the battle begins");
});

test("task1427 names no team (念's); 大地迷城 sends type 48 {id: 2}; 魔法星's 魔幻摩卡 type 21 at the level its script names", async () => {
  const h = harness();
  skipTo(h.o, 1426, 1);
  assert.equal(h.get(await h.call("PetExtension.54_22", { type: 17 }), "54_22")!.res, true);
  const h2 = harness();
  skipTo(h2.o, 3150, 1);
  assert.equal(h2.get(await h2.call("PetExtension.54_22", { type: 48, id: 2 }), "54_22")!.res, true);
  const h3 = harness();
  assert.equal(h3.get(await h3.call("PetExtension.54_22", { type: 21, r: "10699", l: "100" }), "54_22")!.res, false);
  skipTo(h3.o, 2003, 1);
  assert.equal(h3.get(await h3.call("PetExtension.54_22", { type: 21, r: "10001", l: "100" }), "54_22")!.res, false, "another 亚比");
  assert.equal(h3.get(await h3.call("PetExtension.54_22", { type: 21, r: "10699", l: "1" }), "54_22")!.res, true);
});
