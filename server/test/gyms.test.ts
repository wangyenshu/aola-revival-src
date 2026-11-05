import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import { applyFate, gymStone, gymWon, rollFate, GYM_MASTERS, TOWER_FLOORS } from "../src/game/sfs2013/gyms.ts";
import { makePet, type PetOwner, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};

/** 0.5, but now and then a lower and a higher number, so that a fight does not stall on one roll. */
const steady = () => {
  let i = 0;
  const seq = [0.5, 0.5, 0.5, 0.2, 0.5, 0.8];
  return () => seq[i++ % seq.length];
};

function harness(rng = steady()) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const owner: PetOwner & { items: Record<string, Record<string, number>>; score: number; gymFights?: Record<string, unknown> } = {
    id: 10001,
    name: "小奥拉",
    items: {},
    score: 100,
  };
  owner.pets = [makePet(tables, 1300, 100, "d", 1)]; // 幻雷 Lv100
  owner.nextPetId = 1;
  let clock = 1_000_000;
  installBattles(world, { load: async () => owner, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => "2013-01-25", rng, now: () => clock });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = {
      params,
      player: { name: owner.name, room: { name: "huanlei" } },
      reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]),
    } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  /** Win the battle open now with the strongest skill until 2403. */
  const win = async () => {
    const all: Msg[] = [];
    for (let i = 0; i < 300 && !all.some(([c]) => c === "2403"); i++) {
      // the strongest skill, but 幻雷's own 电 (雷光四射) hardly hurts the 幻雷 of the master, who heals: its 麻痹一击 first
      const usable = owner.pets![0].skills.filter((s) => s.pp > 0);
      const sk = usable.find((s) => s.id === 1039) ?? usable.sort((a, b) => (tables.pm.skills[String(b.id)]?.p ?? 0) - (tables.pm.skills[String(a.id)]?.p ?? 0))[0];
      all.push(...(await call("PocketMonsterExtension.1401", { skillId: sk.id })));
      for (const p of owner.pets!) {
        p.hp = 9999; // the test's 亚比 does not fall nor tire
        for (const k of p.skills) k.pp = k.max;
      }
    }
    return all;
  };
  return { owner, call, win, tick: (ms: number) => (clock += ms), handlers };
}
const get = (out: Msg[], cmd: string) => out.find(([c]) => c === cmd)?.[1];
const opp = (out: Msg[]) => (get(out, "2303")!.pmmList as { battleView: { pmList: { pmSView: { r: number; lv: number } }[] } }[])[1].battleView.pmList[0].pmSView;

test("the 踢馆 of 幻雷, 幻炎, 幻流 and 幻冥 begin against the masters", async () => {
  for (const [type, extra] of [[84, {}], [86, { id: 1, buff: 1 }], [87, {}], [88, { id: 3 }]] as const) {
    const h = harness();
    const out = await h.call("PetExtension.54_22", { type, ...extra });
    assert.equal(get(out, "54_22")!.res, true, `type ${type}`);
    assert.equal(opp(out).r, GYM_MASTERS[type].race);
    assert.equal(opp(out).lv, GYM_MASTERS[type].level);
    assert.ok(get(out, "2401"));
  }
});

test("a won 踢馆 pays its stone once a day, the first one sure when the gym's own 亚比 ended it", async () => {
  const h = harness(); // rng mostly 0.5: no luck (STONE_CHANCE 0.3), only the sure stone
  await h.call("PetExtension.54_22", { type: 84 });
  const end = get(await h.win(), "2403")!;
  assert.equal(end.isWin, true);
  assert.equal(end.myFinalRaceId, 1300);
  const out = await h.call("PeriodicActiveExtension.20121113_hlf", { h: true });
  assert.equal(get(out, "20121113_hlf")!.n, 1);
  assert.equal(h.owner.items["2"]["619"], 1);
  // asked again without a new win: nothing
  assert.equal(get(await h.call("PeriodicActiveExtension.20121113_hlf", { h: true }), "20121113_hlf")!.n, 0);
  // a second win the same day: nothing (每天只能获得一个)
  await h.call("PetExtension.54_22", { type: 84 });
  await h.win();
  assert.equal(get(await h.call("PeriodicActiveExtension.20121113_hlf", { h: true }), "20121113_hlf")!.n, 0);
});

test("stones of the other gyms; no stone without a win", () => {
  const o = { id: 1, name: "a", items: {} } as PetOwner & { items: Record<string, Record<string, number>> };
  assert.equal(gymStone(o, 86, "d1", () => 0), 0); // not won
  gymWon(o, 86, 1296);
  assert.equal(gymStone(o, 86, "d1", () => 0.99), 617); // 幻炎 ended it: the first is sure
  gymWon(o, 87, 1);
  assert.equal(gymStone(o, 87, "d1", () => 0.99), 0); // another 亚比, no luck
  gymWon(o, 87, 1);
  assert.equal(gymStone(o, 87, "d2", () => 0.1), 618); // another day, luck
});

test("幻冥's 命运 changes the player's 亚比 for the next 踢馆 only", async () => {
  const fate = rollFate(() => 0.9);
  assert.equal(fate.length, 6);
  assert.ok(fate.every((v) => Math.abs(v) >= 5 && Math.abs(v) <= 30));
  assert.deepEqual(applyFate([100, 100, 100, 100, 100, 100], [10, -10, 20, -20, 30, -30]), [110, 90, 120, 80, 130, 70]);
  const h = harness(() => 0.9);
  const f = get(await h.call("PeriodicActiveExtension.Dark_7"), "Dark_7")!;
  assert.equal(Object.keys(f).length, 6);
  const out = await h.call("PetExtension.54_22", { type: 88, id: 3 });
  assert.equal(get(out, "54_22")!.res, true);
  assert.equal((h.owner.gymFights as { fate?: number[] }).fate, undefined);
});

test("命运玩偶's 亚比 fight by their raceId", async () => {
  const h = harness();
  const out = await h.call("PetExtension.54_22", { type: 88, id: 1, raceId: 20697 });
  assert.equal(opp(out).r, 697);
  assert.equal(opp(out).lv, 55);
});

test("雷霆之塔: floors in turn after openthunder, 20121112_ted with each, the record at the top", async () => {
  const h = harness();
  const refused = await h.call("PetExtension.54_22", { type: 85, layer: 1 });
  assert.equal(get(refused, "54_22")!.res, false);
  assert.ok(get(refused, "2303")!.msg);
  assert.equal(get(await h.call("PeriodicActiveExtension.20121112_openthunder"), "20121112_openthunder")!.suc, true);
  assert.equal(get(await h.call("PetExtension.54_22", { type: 85, layer: 2 }), "54_22")!.res, false); // not its turn
  let ted: Record<string, unknown> | undefined;
  for (let layer = 1; layer <= TOWER_FLOORS.length; layer++) {
    const out = await h.call("PetExtension.54_22", { type: 85, layer, min: 0, sec: 0 });
    assert.equal(opp(out).r, TOWER_FLOORS[layer - 1].race);
    h.tick(30_000);
    const end = await h.win();
    ted = get(end, "20121112_ted");
    assert.equal(ted!.fl, layer);
    // the floor's end comes before the battle's end (the panel reads the floor from it)
    assert.ok(end.findIndex(([c]) => c === "20121112_ted") < end.findIndex(([c]) => c === "2403"));
  }
  assert.equal(ted!.ps, 300);
  assert.equal(ted!.p4, true);
  const rank = get(await h.call("PeriodicActiveExtension.20121112_getmyrank"), "20121112_getmyrank")!;
  assert.equal(rank.r, "1:300");
  assert.equal(rank.c, 1);
});

test("other kinds of 54_22 are refused with a message (ENTER_FIGHT_FAIL), 幻光's 友情的试炼 too", async () => {
  const h = harness();
  for (const type of [89, 1024]) {
    const out = await h.call("PetExtension.54_22", { type });
    assert.equal(get(out, "54_22")!.res, false);
    assert.ok(get(out, "2303")!.msg, `type ${type}`);
  }
});

test("治疗 (54_4): every 亚比 back to full for 50 晶币", async () => {
  const h = harness();
  h.owner.pets![0].hp = 1;
  const out = await h.call("PetExtension.54_4");
  assert.equal(get(out, "54_4")!.res, true);
  assert.equal(h.owner.score, 50);
  assert.ok(h.owner.pets![0].hp > 1);
  h.owner.score = 10;
  assert.equal(get(await h.call("PetExtension.54_4"), "54_4")!.res, false);
});

test("NPC challenges: 机械师马赫 fights the 火宝宝 line, 上古使者 gives 上古圣水", async () => {
  const h = harness();
  const out = await h.call("PetExtension.54_22", { type: 14, npc: 10, npcId: 172, lv: 1, name: "机械师马赫" });
  assert.equal(opp(out).r, 97); // 火宝宝, not 火花龙 (the 守护者's kind) in every mode
  await h.win();
  assert.equal(h.owner.items["2"]["343"], 1);
  await h.call("PetExtension.54_22", { type: 14, npc: 11, npcId: 312, lv: 1, name: "上古使者" });
  await h.win();
  assert.equal(h.owner.items["2"]["379"], 1);
});
