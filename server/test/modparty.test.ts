import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { Emulator } from "../src/core/emulator.ts";
import { MemoryRecorder } from "../src/core/recorder.ts";
import { installSfs2013 } from "../src/game/sfs2013/game.ts";
import { endModParty, type ModRec } from "../src/game/sfs2013/mods.ts";
import { adoptRecord } from "../src/game/sfs2013/saves.ts";
import { SFS2013_FRAMING, sfs2013Codec, type XtContext, type XtHandler } from "../src/game/sfs2013/server.ts";

const site = new URL("../../rebuild/static/www.9aola.com/", import.meta.url);
const NAME = "小奥拉";
const KEY = `user/${encodeURIComponent(NAME)}`;

async function setup() {
  const emu = new Emulator({ framing: SFS2013_FRAMING, codec: sfs2013Codec, recorder: new MemoryRecorder(), answerPolicy: false });
  const world = installSfs2013(emu, { dev: true, loadJson: async (p) => JSON.parse(await readFile(new URL(p, site), "utf8")) }) as unknown as { handlers: Map<string, XtHandler> };
  // The player's own: one 兔小子, 5 初级体力糖.
  await emu.store.set(KEY, { id: 10001, name: NAME, pets: [], nextPetId: 1, items: { "2": { "30": 5 } } });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string, Record<string, any>][] = [];
    const ctx = {
      params,
      player: { name: NAME, room: { name: "sandboxroom" } },
      session: { data: {} },
      reply: (b: Record<string, unknown>, c = key.split(".")[1]) => out.push([c, b]),
      broadcast: () => {},
    } as unknown as XtContext;
    await world.handlers.get(key)!(ctx, key);
    return out;
  };
  const mod = async (params: Record<string, unknown>) => (await call("SundriesExtension.revival_mod", { mod: "antwar", ...params })).find(([c]) => c === "revival_mod")![1];
  const rec = async () => (await emu.store.get<ModRec & { items: Record<string, Record<string, number>> }>(KEY))!;
  await call("PocketMonsterExtension.1201", { raceId: 1, level: 5 });
  return { emu, call, mod, rec };
}

const PARTY = {
  pets: [{ race: 216, level: 100, keep: true }, { race: 217, level: 100, follow: true }],
  items: { "61": 3, "104": 2 },
  noHeal: "只能用体力糖！",
  keepText: "兵蚁倒下了……",
};

test("a mod's party takes the place of the player's 亚比 and 道具, and gives them back", async () => {
  const h = await setup();
  const own = (await h.rec()).pets!.map((p) => p.race);
  const ownItems = structuredClone((await h.rec()).items["2"]);
  const r = await h.mod({ op: "party", def: JSON.stringify(PARTY) });
  assert.equal(r.res, 1);
  assert.deepEqual(r.pets.map((p: { race: number }) => p.race), [216, 217]);
  assert.equal(r.pets[0].keep, true);
  assert.deepEqual(r.items, { "61": 3, "104": 2 });
  const inParty = await h.rec();
  assert.equal(inParty.followPet, inParty.pets![1].id);
  // 道具 for the party.
  assert.equal((await h.mod({ op: "item", id: 61, n: 2 })).count, 5);
  assert.equal((await h.mod({ op: "item", id: 999999, n: 1 })).res, 0);
  // Back: the player's own.
  await h.mod({ op: "unparty" });
  const back = await h.rec();
  assert.deepEqual(back.pets!.map((p) => p.race), own);
  assert.deepEqual(back.items["2"], ownItems);
  // Out again: the party as it was left.
  const again = await h.mod({ op: "party", def: JSON.stringify(PARTY) });
  assert.deepEqual(again.items, { "61": 5, "104": 2 });
  assert.equal(again.pets[0].id, r.pets[0].id);
  // fresh: a new one.
  const fresh = await h.mod({ op: "party", def: JSON.stringify({ ...PARTY, fresh: true }) });
  assert.deepEqual(fresh.items, { "61": 3, "104": 2 });
  assert.notEqual(fresh.pets[0].id, r.pets[0].id);
  // The next login (or a save made meanwhile) gives the player's own back.
  const saved = adoptRecord(structuredClone(await h.rec()) as never, { id: 10001, name: NAME });
  assert.deepEqual((saved.pets as { race: number }[]).map((p) => p.race), own);
  assert.equal(saved.modParty, undefined);
  const r2 = await h.rec();
  assert.equal(endModParty(r2), true);
  assert.deepEqual(r2.pets!.map((p) => p.race), own);
});

test("in a party that heals nobody, healing all is refused and the 亚比 to keep stays in the bag", async () => {
  const h = await setup();
  const r = await h.mod({ op: "party", def: JSON.stringify(PARTY) });
  const heal = await h.call("PocketMonsterExtension.revival_heal");
  assert.deepEqual(heal.at(-1)![1], { ok: 0, msg: "只能用体力糖！" });
  const move = await h.call("PocketMonsterExtension.1224", { id: r.pets[0].id, loc: 1 });
  assert.equal(move.at(-1)![1].result, -4);
  assert.match(move.at(-1)![1].msg, /兵蚁必须留在亚比背包里/);
  const release = await h.call("PocketMonsterExtension.revival_release", { id: r.pets[0].id });
  assert.equal(release.at(-1)![1].result, -4);
  // The other may go to the 仓库.
  assert.equal((await h.call("PocketMonsterExtension.1224", { id: r.pets[1].id, loc: 1 })).at(-1)![1].result, 1);
});

test("the 亚比 to keep falling ends the fight as lost, though another could fight on", async () => {
  const h = await setup();
  await h.mod({ op: "party", def: JSON.stringify({ ...PARTY, pets: [{ race: 216, level: 1, keep: true }, { race: 217, level: 100 }] }) });
  const lv = JSON.stringify({ format: "aola-revival-level", version: 1, heal: true, enemies: [{ race: 227, level: 100 }] });
  const start = await h.call("SundriesExtension.revival_sandbox", { lv, i: 0 });
  assert.equal(start.find(([c]) => c === "revival_sandbox")![1].res, 1);
  let end: Record<string, any> | undefined;
  for (let n = 0; n < 50 && !end; n++) {
    const pet = (await h.rec()).pets![0];
    const out = await h.call("PocketMonsterExtension.1401", { skillId: pet.skills[0].id });
    end = out.find(([c]) => c === "2403")?.[1];
    assert.ok(!out.some(([c]) => c === "2422"), "no choosing the next one");
  }
  assert.equal(end!.isWin, false);
  assert.equal(end!.desc, "兵蚁倒下了……");
});

test("a mod played as a game of its own: a new 奥拉 has the newbie quest done and its HELLO", async () => {
  const emu = new Emulator({ framing: SFS2013_FRAMING, codec: sfs2013Codec, recorder: new MemoryRecorder(), answerPolicy: false });
  const world = installSfs2013(emu, { standalone: true, loadJson: async (p) => JSON.parse(await readFile(new URL(p, site), "utf8")) }) as unknown as { handlers: Map<string, XtHandler> };
  await emu.store.set(KEY, { id: 10001, name: NAME, pets: [], nextPetId: 1 });
  const out: [string, Record<string, any>][] = [];
  const ctx = { params: {}, player: { name: NAME, room: { name: "sandboxroom" } }, session: { data: {} }, reply: (b: Record<string, unknown>, c = "10-0") => out.push([c, b]), broadcast: () => {} } as unknown as XtContext;
  await world.handlers.get("TaskExtension.10-0")!(ctx, "TaskExtension.10-0");
  const rec = (await emu.store.get<{ tasks: Record<string, { st: number }>; robot?: unknown }>(KEY))!;
  for (const t of ["135", "140", "150"]) assert.equal(rec.tasks[t].st, 1, `task ${t} done`);
  assert.ok(rec.robot, "the HELLO");
});

test("the game is told the 道具 a party swaps (its 物品 and bag show the party's)", async () => {
  const h = await setup();
  const amounts = async (params: Record<string, unknown>) =>
    (await h.call("SundriesExtension.revival_mod", { mod: "antwar", ...params }))
      .filter(([c]) => c === "onAmountUpdated")
      .flatMap(([, b]) => String(b.amount).split("#"))
      .sort();
  // Out: the player's 初级体力糖 go, the party's 体力糖 and 活力豆 come.
  const own = (await h.rec()).items["2"]["30"];
  assert.ok(own > 0);
  assert.deepEqual(await amounts({ op: "party", def: JSON.stringify(PARTY) }), ["2_104_0_2", `2_30_0_-${own}`, "2_61_0_3"]);
  // Out already: nothing changes.
  assert.deepEqual(await amounts({ op: "party", def: JSON.stringify(PARTY) }), []);
  // Back: the other way.
  assert.deepEqual(await amounts({ op: "unparty" }), ["2_104_0_-2", `2_30_0_${own}`, "2_61_0_-3"]);
});

test("a vip party makes the player a 蓝宝石 while it is out, and not after (unless he was one)", async () => {
  const h = await setup();
  const r = await h.mod({ op: "party", def: JSON.stringify({ ...PARTY, vip: true }) });
  assert.equal(r.vip, true);
  assert.equal((await h.rec()).vip, true);
  assert.equal((await h.mod({ op: "state" })).vip, true);
  const back = await h.mod({ op: "unparty" });
  assert.equal(back.vip, false);
  assert.equal(!!(await h.rec()).vip, false);
  // At the next login the party ends the same way.
  await h.mod({ op: "party", def: JSON.stringify({ ...PARTY, vip: true }) });
  const rec = await h.rec();
  endModParty(rec);
  assert.equal(rec.vip, false);
  // A 蓝宝石 already stays one.
  await h.emu.store.set(KEY, { ...rec, vip: true });
  await h.mod({ op: "party", def: JSON.stringify({ ...PARTY, vip: true, fresh: true }) });
  assert.equal((await h.mod({ op: "unparty" })).vip, true);
});
