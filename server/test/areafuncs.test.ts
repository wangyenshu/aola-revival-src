import assert from "node:assert/strict";
import { test } from "node:test";
import {
  DONATE_MIN,
  DONATE_PER_DAY,
  DONATE_TAKE,
  KNIGHT_AUGURY_CARDS,
  KNIGHT_CARD,
  KNIGHT_CARDS_A_DAY,
  KNIGHTS,
  MOOD_PRICE,
  SWEET_ITEM,
  SWEETS_FOR_PET,
  TREE_FRUIT,
  TREE_ITEM,
  XIAOBAITU,
  helloGrade,
  installAreaFuncs,
  treeDay,
  type AreaRec,
} from "../src/game/sfs2013/areafuncs.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";
import type { PetTables } from "../src/game/sfs2013/pets.ts";
import { EMPTY_PMDATA } from "../src/game/sfs2013/pmdata.ts";

type Reply = [string | undefined, Record<string, any>];

function setup(names = ["小奥拉", "小星"]) {
  const handlers = new Map<string, XtHandler>();
  const vars: Record<string, unknown>[] = [];
  const world = {
    xt: (k: string, h: XtHandler) => (handlers.set(k, h), world),
    setUserVars: (_s: unknown, v: Record<string, unknown>) => vars.push(v),
  } as unknown as World;
  const recs = new Map<string, AreaRec & { id: number }>();
  names.forEach((n, i) => recs.set(n, { id: 10001 + i, name: n, score: 500, xingbi: 0, items: {}, pets: [] }));
  const store = new Map<string, unknown>();
  // 2013-01-25 10:00 UTC.
  const clock = { now: Date.UTC(2013, 0, 25, 10, 0, 0) };
  const tables = { species: { "846": { n: "小白吐", a: 1, e: 0, next: 847, sk: [] } }, pm: EMPTY_PMDATA } as unknown as PetTables;
  installAreaFuncs(world, {
    load: async (ctx) => recs.get(ctx.player.name)!,
    save: async () => {},
    today: () => new Date(clock.now).toISOString().slice(0, 10),
    now: () => clock.now,
    get: async <T>(k: string) => store.get(k) as T | undefined,
    set: async (k, v) => void store.set(k, structuredClone(v)),
    pets: async () => tables,
  });
  const call = async (key: string, params: Record<string, unknown> = {}, who = names[0]) => {
    const replies: Reply[] = [];
    const ctx = { params, player: { name: who }, session: {}, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    const h = handlers.get(key);
    assert.ok(h, `no handler for ${key}`);
    await h(ctx, key);
    return replies;
  };
  const answer = (r: Reply[]) => r.find(([c]) => c === undefined)?.[1];
  return { handlers, recs, store, clock, call, answer, vars, me: recs.get(names[0])!, other: recs.get(names[1])! };
}

test("神奇摇摇树: six 摇摇果实 a day, again from 6:00", async () => {
  const { call, answer, me, clock } = setup();
  assert.equal(answer(await call("SundriesExtension.70_34"))!.num, TREE_FRUIT);
  const got = await call("SundriesExtension.70_35");
  assert.equal(answer(got)!.res, true);
  assert.deepEqual(got.find(([c]) => c === "onAmountUpdated")![1], { amount: `2_${TREE_ITEM}_0_${TREE_FRUIT}` });
  assert.equal(me.items!["2"][TREE_ITEM], TREE_FRUIT);
  assert.equal(answer(await call("SundriesExtension.70_34"))!.num, 0);
  assert.equal(answer(await call("SundriesExtension.70_35"))!.res, false);
  // 5:00 the next day is still the same tree day; 6:00 is a new one.
  clock.now = Date.UTC(2013, 0, 26, 5, 0, 0);
  assert.equal(answer(await call("SundriesExtension.70_34"))!.num, 0);
  clock.now = Date.UTC(2013, 0, 26, 6, 0, 0);
  assert.equal(answer(await call("SundriesExtension.70_34"))!.num, TREE_FRUIT);
  assert.equal(treeDay(Date.UTC(2013, 0, 26, 5, 59)), "2013-01-25");
});

test("骑士王座: daily cards, 占卜 and the 星币 choice turn the 小骑兵 into a 骑士", async () => {
  const { call, answer, me, vars } = setup();
  const PA = "PeriodicActiveExtension.";
  assert.equal(answer(await call(PA + "knight_4"))!.res, 0);
  assert.equal(answer(await call(PA + "knight_5"))!.suc, true);
  assert.equal(me.items!["2"][KNIGHT_CARD], KNIGHT_CARDS_A_DAY);
  assert.equal(answer(await call(PA + "knight_4"))!.res, 1);
  assert.equal(answer(await call(PA + "knight_5"))!.suc, false);
  // No 小骑兵 first in the bag, or too few cards: refused.
  assert.equal(answer(await call(PA + "knight_1"))!.suc, false);
  me.pets = [{ id: 7, race: 932, level: 25 }];
  me.followPet = 7;
  assert.equal(answer(await call(PA + "knight_1"))!.suc, false);
  me.items!["2"][KNIGHT_CARD] = KNIGHT_AUGURY_CARDS;
  const seen = answer(await call(PA + "knight_1"))!;
  assert.equal(seen.suc, true);
  assert.ok(KNIGHTS.includes(seen.res));
  assert.equal(me.items!["2"][KNIGHT_CARD], undefined);
  assert.equal(answer(await call(PA + "knight_2", { pmId: 7 }))!.suc, true);
  assert.equal(me.pets[0].race, seen.res);
  assert.equal(vars.length, 1);
  // The 星币 way: 30 星币, any of the four, only from a 小骑兵.
  me.pets.push({ id: 8, race: 932, level: 30 });
  assert.equal(answer(await call(PA + "knight_3", { pmId: 8, raceId: 939 }))!.suc, false);
  me.xingbi = 30;
  assert.equal(answer(await call(PA + "knight_3", { pmId: 8, raceId: 939 }))!.suc, true);
  assert.equal(me.pets[1].race, 939);
  assert.equal(me.xingbi, 0);
  assert.equal(answer(await call(PA + "knight_3", { pmId: 8, raceId: 939 }))!.suc, false);
});

test("星愿气球: one wish a day, others' wishes and 心情 float by", async () => {
  const { call, answer, me, other } = setup();
  const BW = "BalloonExtension.";
  assert.equal(answer(await call(BW + "88_2"))!.result, 0);
  await call(BW + "88_1", { wi: 3 });
  assert.equal(answer(await call(BW + "88_2"))!.result, 3);
  await call(BW + "88_1", { wi: 5 });
  assert.equal(answer(await call(BW + "88_2"))!.result, 3);
  // One's own balloon does not come back to one.
  assert.equal(answer(await call(BW + "88_4"))!.suc, false);
  const w = answer(await call(BW + "88_4", {}, other.name))!;
  assert.deepEqual([w.suc, w.wi, w.dd], [true, 3, me.name]);
  // A 心情 costs 100 晶币.
  const mood = await call(BW + "88_10", { faceId: 4, content: "今天真开心" });
  assert.equal(me.score, 500 - MOOD_PRICE);
  assert.ok(mood.some(([c]) => c === "onScoreUpdated"));
  const m = answer(await call(BW + "88_9", {}, other.name))!;
  assert.equal(m.suc, true);
  assert.equal(m.mood.content, "今天真开心");
  assert.equal(m.mood.uid, me.id);
  assert.deepEqual(answer(await call(BW + "88_6"))!.list, []);
});

test("爱心协会: give 晶币 or things to the pool, the poor take from it once a day", async () => {
  const { call, answer, me, other, store } = setup();
  const DE = "DonateExtension.";
  assert.equal(answer(await call(DE + "87_1", { type: 100, id: 0, num: DONATE_MIN - 1 }))!.result, 101);
  assert.equal(answer(await call(DE + "87_1", { type: 100, id: 0, num: 300 }))!.result, 1);
  assert.equal(me.score, 200);
  me.items = { "2": { "30": 2 } };
  assert.equal(answer(await call(DE + "87_1", { type: 2, id: 30, num: 3 }))!.result, 101);
  assert.equal(answer(await call(DE + "87_1", { type: 2, id: 30, num: 2 }))!.result, 1);
  assert.equal(me.items["2"]["30"], undefined);
  for (let i = 2; i < DONATE_PER_DAY; i++) await call(DE + "87_1", { type: 100, id: 0, num: 10 });
  assert.equal(answer(await call(DE + "87_1", { type: 100, id: 0, num: 10 }))!.result, 104);
  assert.equal(answer(await call(DE + "87_6"))!.list, me.name);
  const st = answer(await call(DE + "87_3"))!;
  assert.equal(st.donatePeople, DONATE_PER_DAY);
  assert.equal(answer(await call(DE + "87_4"))!.ms, 300 + 10 * (DONATE_PER_DAY - 2));
  // 小星 has 500 晶币: poor enough. One take a day.
  const before = (store.get("area/donate") as { pool: number }).pool;
  assert.equal(answer(await call(DE + "87_2", {}, other.name))!.result, 1);
  assert.equal(other.score, 500 + DONATE_TAKE);
  assert.equal((store.get("area/donate") as { pool: number }).pool, before - DONATE_TAKE);
  assert.equal(answer(await call(DE + "87_2", {}, other.name))!.result, 106);
  other.score = 5000;
  assert.equal(answer(await call(DE + "87_2", {}, me.name))!.result, 108);
});

test("HELLO技能学习: the HELLO games give 潜能, a skill wakes once what it asks is there", async () => {
  const { call, answer } = setup();
  const RE = "RobotExtension.";
  assert.equal(helloGrade(29), "d");
  assert.equal(helloGrade(130), "s");
  assert.equal(answer(await call(RE + "2-22", { id: 1 }))!.result, -2);
  // Skill 1 (孵化): 视觉 10, 记忆 6, 计算 3 and a 视觉 game of grade b.
  for (let i = 0; i < 3; i++) assert.equal(answer(await call(RE + "2-21", { type: 1, score: 95 }))!.pt, 4);
  for (let i = 0; i < 2; i++) await call(RE + "2-21", { type: 2, score: 95 });
  await call(RE + "2-21", { type: 3, score: 60 });
  assert.deepEqual(answer(await call(RE + "2-20", { un: "小奥拉" })), { sc: "95,95,60", pt: "12,8,3" });
  assert.equal(answer(await call(RE + "2-22", { id: 1 }))!.result, 1);
  assert.equal(answer(await call(RE + "2-22", { id: 1 }))!.result, -4);
  // Skill 0 (技能排序): 视觉 5, 记忆 10, 计算 13 and a 计算 game of grade s.
  await call(RE + "2-21", { type: 2, score: 95 });
  for (let i = 0; i < 4; i++) await call(RE + "2-21", { type: 3, score: 60 });
  assert.equal(answer(await call(RE + "2-22", { id: 0 }))!.result, -3);
  await call(RE + "2-21", { type: 3, score: 130 });
  assert.equal(answer(await call(RE + "2-22", { id: 0 }))!.result, 1);
});

test("职业亚比进化 and 小白吐获得", async () => {
  const { call, answer, me } = setup();
  me.pets = [{ id: 3, race: 754, level: 20 }];
  assert.equal(answer(await call("PetExtension2.54e_1", { pid: 3, t: 2 }))!.res, -1);
  me.items = { "2": { "514": 1 } };
  assert.equal(answer(await call("PetExtension2.54e_1", { pid: 3, t: 2 }))!.res, 0);
  assert.equal(me.pets[0].race, 870);
  assert.equal(me.items["2"]["514"], undefined);
  // The bottle: 15 糖果 for a 小白吐, one a day.
  const PA = "PeriodicActiveExtension.";
  me.items["2"][SWEET_ITEM] = 20;
  assert.equal(answer(await call(PA + "s_s_1"))!.res, 0);
  assert.equal(answer(await call(PA + "s_s_2", { c: 10 }))!.res, false);
  assert.equal(answer(await call(PA + "s_s_1"))!.res, 10);
  const full = await call(PA + "s_s_2", { c: 10 });
  assert.equal(answer(full)!.res, true);
  assert.ok(full.some(([c]) => c === "2201"));
  assert.equal(me.items["2"][SWEET_ITEM], 20 - SWEETS_FOR_PET);
  assert.equal(me.pets[1].race, XIAOBAITU);
  assert.equal(answer(await call(PA + "s_s_2", { c: 1 }))!.res, false);
});

test("道馆: 幻雷的试炼 fills 试炼值 for a 幻雷进化石; the training shops", async () => {
  const { call, answer, me, handlers } = setup();
  const PA = "PeriodicActiveExtension.";
  assert.deepEqual(answer(await call(PA + "20121112_checkstone")), { pb: false, pt: false, s: 0 });
  const r = answer(await call(PA + "20121112_getbonus", { lv: 3, n: 20 }))!;
  assert.deepEqual(r, { m: 100, f: true, s: 1 });
  assert.equal(me.score, 600);
  assert.equal(answer(await call(PA + "20121112_getbonus", { lv: 3, n: 1000 }))!.f, false);
  assert.equal(answer(await call(PA + "20121112_getstone"))!.res, false);
  me.area!.gym!.s = 3;
  assert.equal(answer(await call(PA + "20121112_getstone"))!.res, true);
  assert.equal(me.items!["2"]["616"], 1);
  // 幻流特训营: points from its games buy the shop's things.
  await call(PA + "20121116water_score2", { num: 25 });
  await call(PA + "20121116water_score2", { num: 25 });
  assert.equal(answer(await call(PA + "20121116water_score1"))!.score, 50);
  const bought = answer(await call(PA + "20121116water_score3", { index: 4 }))!;
  assert.equal(bought.bn, null);
  const got = answer(await call(PA + "20121116water_score3", { index: 1 }))!;
  assert.deepEqual(got.bn, [{ type: 100, id: 0, num: 500 }]);
  assert.equal(got.score, 20);
  // The games pay for at most five games a day: 30 points each, 150 in all.
  for (let i = 0; i < 8; i++) await call(PA + "20121116water_score2", { num: 30 });
  assert.equal(answer(await call(PA + "20121116water_score1"))!.score, 20 + 150 - 50);
  // 爆发力大冲击: points, then the exchange (exId_1, the 炼火拳套, costs 1000).
  assert.equal(answer(await call(PA + "Fire_5", { score: 120 }))!.score, 120);
  assert.equal(answer(await call(PA + "Fire_6", { id: 1 }))!.suc, false);
  assert.equal(answer(await call(PA + "Fire_6", { id: 4 }))!.suc, true);
  assert.equal(answer(await call(PA + "Fire_8"))!.score, 20);
  // The other panels open on these answers (雷霆之塔's getmyrank is gyms.ts's: gyms.test.ts).
  for (const c of ["20121113_htop", "Fire_10", "20121116water_c1", "Dark_4", "20121123light_E1"]) assert.ok(handlers.has(PA + c), c);
  assert.equal(answer(await call(PA + "20121123light_E1"))!.enter, true);
});

test("亚比成长计划: six steps, a wait between them, levels for the 亚比", async () => {
  const { call, answer, me, clock } = setup();
  const HE = "HolidayExtension.121109_";
  me.pets = [{ id: 5, race: 1, level: 10 }];
  assert.equal(answer(await call(HE + "02"))!.petId, -1);
  assert.equal(answer(await call(HE + "07"))!.suc, false);
  assert.equal(answer(await call(HE + "06", { petId: 9 }))!.suc, false);
  assert.equal(answer(await call(HE + "06", { petId: 5 }))!.suc, true);
  for (let i = 0; i < 6; i++) {
    assert.deepEqual(answer(await call(HE + "03")), { step: i, taken: false, cd: 0, done: false });
    assert.equal(answer(await call(HE + "07"))!.suc, true);
    const f = answer(await call(HE + "04"))!;
    assert.deepEqual([f.suc, f.step, f.level], [true, i, 12 + 2 * i]);
    if (i < 5) {
      assert.equal(answer(await call(HE + "03"))!.cd, 600);
      assert.equal(answer(await call(HE + "07"))!.suc, false);
      clock.now += 600 * 1000;
    }
  }
  assert.equal(answer(await call(HE + "03"))!.done, true);
  assert.deepEqual(answer(await call(HE + "01")), { count: 1, flag: 0 });
  assert.equal(answer(await call(HE + "05", { id: 1 }))!.suc, false);
  const g = answer(await call(HE + "05", { id: 0 }))!;
  assert.deepEqual(g.bn, [{ type: 100, id: 0, num: 1000 }]);
  assert.equal(answer(await call(HE + "05", { id: 0 }))!.suc, false);
  // Choosing again after the last step starts a new run.
  await call(HE + "06", { petId: 5 });
  assert.equal(answer(await call(HE + "03"))!.step, 0);
});

test("蓝宝石礼包派送: one of the four week gifts a week", async () => {
  const { call, answer, me, clock } = setup();
  me.robot = { exp: 0 };
  const GB = "GiftBagExtension.";
  assert.equal(answer(await call(GB + "68_6", { id: 69 }))!.s, 0);
  // 蓝宝石 only.
  assert.equal(answer(await call(GB + "68_7", { id: 69 }))!.res, 0);
  (me as { vip?: boolean }).vip = true;
  const r = await call(GB + "68_7", { id: 69 });
  assert.deepEqual(answer(r), { res: 1, id: 69 });
  assert.equal(me.items!["2"]["67"], 3);
  assert.equal(me.score, 5500);
  assert.equal(me.robot.exp, 20000);
  assert.equal(answer(await call(GB + "68_7", { id: 72 }))!.res, 3);
  // 2013-01-25 is a Friday: Monday the 28th is a new week.
  clock.now = Date.UTC(2013, 0, 27, 23, 0, 0);
  assert.equal(answer(await call(GB + "68_7", { id: 72 }))!.res, 3);
  clock.now = Date.UTC(2013, 0, 28, 1, 0, 0);
  assert.equal(answer(await call(GB + "68_7", { id: 72 }))!.res, 1);
});

test("54e_1 of any 亚比 but the union ones is left to the handler installed before (the 小独角兽)", async () => {
  const handlers = new Map<string, XtHandler>();
  let unicornCalls = 0;
  handlers.set("PetExtension2.54e_1", () => void unicornCalls++);
  const world = { handlers, xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const rec = { id: 1, name: "a", items: { "2": { "475": 1 } }, pets: [{ id: 1, race: 651, level: 30 }, { id: 2, race: 679, level: 10 }] } as AreaRec & { id: number };
  installAreaFuncs(world, { load: async () => rec, save: async () => {}, today: () => "2013-01-25", now: () => 0, get: async () => undefined, set: async () => {} });
  const replies: Record<string, unknown>[] = [];
  const ctx = (params: Record<string, unknown>) => ({ params, player: { name: "a" }, session: {}, reply: (o: Record<string, unknown>, c?: string) => void (c === undefined && replies.push(o)) }) as unknown as XtContext;
  await handlers.get("PetExtension2.54e_1")!(ctx({ pid: 1, t: 1 }), "54e_1");
  assert.equal(unicornCalls, 1);
  await handlers.get("PetExtension2.54e_1")!(ctx({ pid: 2, t: 1 }), "54e_1");
  assert.equal(unicornCalls, 1);
  assert.deepEqual(replies, [{ res: 0 }]);
  assert.equal(rec.pets![1].race, 721);
});

test("欢乐券兑换: 欢乐券 for the exchange's things; other ids go to the handler before", async () => {
  const handlers = new Map<string, XtHandler>();
  let armour = 0;
  handlers.set("SynthesizeExtension.57_8", () => void armour++);
  const world = { handlers, xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {} } as unknown as World;
  const rec = { id: 1, name: "a", items: { "2": { "297": 250 } }, pets: [] } as AreaRec & { id: number };
  installAreaFuncs(world, { load: async () => rec, save: async () => {}, today: () => "2013-01-25", now: () => 0, get: async () => undefined, set: async () => {} });
  const replies: Record<string, unknown>[] = [];
  const ctx = (params: Record<string, unknown>) => ({ params, player: { name: "a" }, session: {}, reply: (o: Record<string, unknown>, c?: string) => void (c === undefined && replies.push(o)) }) as unknown as XtContext;
  const h = handlers.get("SynthesizeExtension.57_8")!;
  await h(ctx({ id: 186 }), "57_8");
  assert.equal(armour, 1);
  await h(ctx({ id: 139, num: 5 }), "57_8");
  assert.equal(rec.items!["2"]["343"], 5);
  assert.equal(rec.items!["2"]["297"], 210);
  await h(ctx({ id: 84, num: 1 }), "57_8");
  assert.equal(rec.items!["0"]["533"], 1);
  await h(ctx({ id: 84, num: 1 }), "57_8");
  assert.deepEqual(replies, [{ res: 1 }, { res: 1 }, { res: 0 }]);
  assert.equal(rec.items!["2"]["297"], 10);
});
