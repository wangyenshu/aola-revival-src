import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import { applyFate, gymStone, gymWon, mazeDoll, rollFate, waterAttacker, GYM_MASTERS, MAZE_PER_DOLL, MAZE_TIERS, TOWER_FLOORS, WATER_ROUNDS } from "../src/game/sfs2013/gyms.ts";
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
  // 幻雷 Lv100, and a second 亚比 to step in for a turn (below).
  owner.pets = [makePet(tables, 1300, 100, "d", 1), makePet(tables, 1300, 100, "d", 2)];
  owner.nextPetId = 2;
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
      // The masters never run out of PP (高级活力豆): every 20 turns the 幻雷 steps out and back,
      // so that its 命中 lowered by 雷光四射 comes back, as a player would do.
      if (i % 20 === 19 && !all.some(([c]) => c === "2403")) {
        all.push(...(await call("PocketMonsterExtension.1403", { pmId: 2 })));
        all.push(...(await call("PocketMonsterExtension.1403", { pmId: 1 })));
      }
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

test("玩偶迷阵: dolls one after another, a 战斗力评价 when the run ends, its rewards once", async () => {
  const h = harness();
  assert.deepEqual(get(await h.call("PeriodicActiveExtension.Dark_0"), "Dark_0"), { max: 0 });
  for (let i = 0; i < 2; i++) {
    const out = await h.call("PetExtension.54_22", { type: 88, id: 2 });
    assert.equal(get(out, "54_22")!.res, true);
    const doll = mazeDoll(i);
    assert.deepEqual([opp(out).r, opp(out).lv], [doll.race, doll.level]);
    assert.equal(get(await h.win(), "2403")!.isWin, true);
    assert.deepEqual(get(await h.call("PeriodicActiveExtension.Dark_1", { hurt: 999999 }), "Dark_1"), { res: 1 }, "the run goes on");
  }
  // The third doll: the player runs (as a loss, the run ends).
  await h.call("PetExtension.54_22", { type: 88, id: 2 });
  await h.call("PocketMonsterExtension.1404");
  const end = get(await h.call("PeriodicActiveExtension.Dark_1", { hurt: 999999 }), "Dark_1") as Record<string, number>;
  assert.equal(end.num, 2);
  assert.ok(end.hurt > 0 && end.hurt < 999999, "the battles' own damage, not the client's");
  assert.equal(end.record, end.hurt + MAZE_PER_DOLL * 2);
  assert.equal(get(await h.call("PeriodicActiveExtension.Dark_0"), "Dark_0")!.max, end.record);
  // Rewards of the marks reached, once.
  (h.owner as { gymFights?: { mazeLast?: { record: number; claimed: boolean } } }).gymFights!.mazeLast = { record: MAZE_TIERS[2], claimed: false };
  const bn = get(await h.call("PeriodicActiveExtension.Dark_2"), "Dark_2")!.bn as { type: number; id: number; num: number }[];
  assert.deepEqual(bn, [{ type: 101, id: -1, num: 11000 }, { type: 2, id: 419, num: 5 }]);
  assert.equal(h.owner.items["2"]["419"], 5);
  assert.deepEqual(get(await h.call("PeriodicActiveExtension.Dark_2"), "Dark_2")!.bn, []);
  // The next challenge starts a new run with the first doll.
  assert.equal(opp(await h.call("PetExtension.54_22", { type: 88, id: 2 })).lv, mazeDoll(0).level);
});

test("最强防御PK战: a 局 is won by standing its rounds; the run's end is pushed; the day's rewards", async () => {
  const h = harness();
  const out = await h.call("PetExtension.54_22", { type: 85, sw: false, lv: 1, buff: false });
  assert.equal(get(out, "54_22")!.res, true);
  assert.deepEqual([opp(out).r, opp(out).lv], [waterAttacker(1).race, waterAttacker(1).level]);
  // The weakest skill only, so the attacker stands too: after WATER_ROUNDS[0] rounds the 局 is won.
  const weak = [...h.owner.pets![0].skills].sort((a, b) => (tables.pm.skills[String(a.id)]?.p ?? 0) - (tables.pm.skills[String(b.id)]?.p ?? 0))[0];
  const all: Msg[] = [];
  for (let i = 0; i < 10 && !all.some(([c]) => c === "2403"); i++) {
    all.push(...(await h.call("PocketMonsterExtension.1401", { skillId: weak.id })));
    h.owner.pets![0].hp = 9999;
    for (const k of h.owner.pets![0].skills) k.pp = k.max;
  }
  const end = get(all, "2403")!;
  assert.equal(end.isWin, true);
  assert.match(String(end.desc), new RegExp(`坚持了${WATER_ROUNDS[0]}回合`));
  assert.ok(!all.some(([c]) => c === "20121116water_finBattle"), "the run goes on");
  // The 7th 局 lost (run away): the run ends with 6 passed.
  await h.call("PetExtension.54_22", { type: 85, lv: 7 });
  const lost = await h.call("PocketMonsterExtension.1404");
  assert.deepEqual(get(lost, "20121116water_finBattle"), { r: 6, isnew: true, max: 6, min: 0, rank: 0 });
  assert.deepEqual(get(await h.call("PeriodicActiveExtension.20121116water_r2"), "20121116water_r2"), { times: 6, status: "0222" });
  const r3 = get(await h.call("PeriodicActiveExtension.20121116water_r3", { index: 0 }), "20121116water_r3")!;
  assert.equal(r3.res, 1);
  assert.equal(h.owner.items["2"]["419"], 2);
  assert.equal(get(await h.call("PeriodicActiveExtension.20121116water_r3", { index: 0 }), "20121116water_r3")!.res, 0, "taken");
  assert.equal(get(await h.call("PeriodicActiveExtension.20121116water_r3", { index: 1 }), "20121116water_r3")!.res, 0, "10 局 not reached");
  // 防御祝福 for 星币.
  (h.owner as { xingbi?: number }).xingbi = 10;
  assert.equal(get(await h.call("PeriodicActiveExtension.20121116water_r4", { num: 3 }), "20121116water_r4")!.res, 1);
  assert.equal(get(await h.call("PeriodicActiveExtension.20121116water_r5"), "20121116water_r5")!.num, 3);
  assert.equal(get(await h.call("PeriodicActiveExtension.20121116water_r4", { num: 1 }), "20121116water_r4")!.res, 101);
});
