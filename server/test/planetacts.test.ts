import assert from "node:assert/strict";
import { test } from "node:test";
import { FISH_PER_DAY,
  AMO_COIN,
  ARMOR_FRAG,
  HAMMER,
  HEART_WAIT_MS,
  LOCK_WAIT_MS,
  MARBLE,
  SMILE_STAR,
  SKY_LOVE,
  clockText,
  installPlanetActs,
  wildDrop,
  type ActsOwner,
} from "../src/game/sfs2013/planetacts.ts";
import type { PetRecord, PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const pet = (id: number, race: number, level = 60): PetRecord => ({ id, race, level, exp: 0, hp: 100, character: "1", skills: [], got: "2013-01-25" });

function setup(opts: { rng?: number[]; pets?: PetRecord[] } = {}) {
  const handlers = new Map<string, XtHandler>();
  const userVars: Record<string, unknown>[] = [];
  const world = {
    xt: (k: string, h: XtHandler) => (handlers.set(k, h), world),
    setUserVars: (_s: unknown, v: Record<string, unknown>) => userVars.push(v),
    setUserVarOnce: (_s: unknown, k: string, v: unknown) => userVars.push({ [k]: v }),
  } as unknown as World;
  const owner: ActsOwner = { name: "小奥拉", score: 0, xingbi: 100, items: {}, pets: opts.pets ?? [pet(1, 651)] };
  const friend: ActsOwner = { name: "朋友", score: 0, items: {}, pets: [] };
  const clock = { now: Date.UTC(2013, 0, 25, 2, 0, 0) };
  const given: number[] = [];
  const rolls = [...(opts.rng ?? [])];
  installPlanetActs(world, {
    load: async (ctx) => (ctx.player.name === friend.name ? friend : owner),
    find: async (n) => (n === friend.name ? friend : n === owner.name ? owner : undefined),
    save: async () => {},
    tables: async () => ({}) as PetTables,
    now: () => clock.now,
    today: () => new Date(clock.now).toISOString().slice(0, 10),
    givePet: async (o, race) => {
      given.push(race);
      (o.pets ??= []).push(pet(100 + given.length, race, 1));
      return [["2201", { pm: { raceId: race } }]];
    },
    rng: () => (rolls.length ? rolls.shift()! : 0.99),
  });
  const call = async (key: string, params: Record<string, unknown> = {}, as = owner) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = {
      params,
      session: {},
      player: { name: as.name },
      reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]),
    } as unknown as XtContext;
    const h = handlers.get(key);
    assert.ok(h, `no handler for ${key}`);
    await h(ctx, key.split(".")[1]);
    return replies;
  };
  const answer = (r: [string | undefined, Record<string, any>][], cmd: string) => r.find(([c]) => c === cmd)![1];
  const item = (id: number) => owner.items?.["2"]?.[String(id)] ?? 0;
  const setItem = (id: number, n: number) => (((owner.items ??= {})["2"] ??= {})[String(id)] = n);
  return { handlers, owner, friend, call, answer, clock, given, item, setItem, userVars };
}

test("every command the panels send has a handler", () => {
  const { handlers } = setup();
  const keys = [
    "PetExtension2.54e_20", "PetExtension2.54e_23", "PetExtension2.54e_24", "PetExtension2.54e_1",
    "PeriodicActiveExtension.91_46", "PeriodicActiveExtension.91_47", "PeriodicActiveExtension.91_48", "PeriodicActiveExtension.91_49",
    "HolidayExtension.20120914_Fu1", "HolidayExtension.20120914_Fu2", "HolidayExtension.20121012_A1", "HolidayExtension.20121012_A2",
    "PeriodicActiveExtension.gofish-1", "PeriodicActiveExtension.gofish-2", "PeriodicActiveExtension.gofish-3",
    "SynthesizeExtension.57_8", "PeriodicActiveExtension.91_31", "PeriodicActiveExtension.91_32", "PeriodicActiveExtension.91_33",
    "PeriodicActiveExtension.91_34", "PeriodicActiveExtension.91_35", "PeriodicActiveExtension.91_36", "PeriodicActiveExtension.91_37",
    "PeriodicActiveExtension.91_38", "PeriodicActiveExtension.91_39", "PeriodicActiveExtension.91_40",
  ];
  for (const k of keys) assert.ok(handlers.has(k), k);
});

test("54e_20: 摩么卡 and 亚伦 evolve at their panels' levels, others do not", async () => {
  const s = setup({ pets: [pet(1, 698, 50), pet(2, 894, 39), pet(3, 651)] });
  s.owner.followPet = 1;
  assert.equal(s.answer(await s.call("PetExtension2.54e_20", { pid: 1, t: 1 }), "54e_20").res, 0);
  assert.equal(s.owner.pets![0].race, 699);
  assert.equal(s.userVars.length, 1, "the follow variable shows the new form");
  assert.equal(s.answer(await s.call("PetExtension2.54e_20", { pid: 2, t: 1 }), "54e_20").res, 1);
  assert.equal(s.answer(await s.call("PetExtension2.54e_20", { pid: 3, t: 1 }), "54e_20").res, 1);
  s.owner.pets![1].level = 40;
  assert.equal(s.answer(await s.call("PetExtension2.54e_20", { pid: 2, t: 1 }), "54e_20").res, 0);
  assert.equal(s.owner.pets![1].race, 895);
});

test("巨锁石灵的机关: one lock every ten minutes, the fifth brings 小石灵", async () => {
  const s = setup();
  for (let i = 1; i <= 5; i++) {
    const r = s.answer(await s.call("PetExtension2.54e_24"), "54e_24");
    assert.equal(r.succ, i === 5);
    const st = s.answer(await s.call("PetExtension2.54e_23"), "54e_23");
    assert.equal(st.c, i);
    assert.equal(st.t, LOCK_WAIT_MS);
    assert.equal(s.answer(await s.call("PetExtension2.54e_24"), "54e_24").succ, false, "too soon");
    s.clock.now += LOCK_WAIT_MS;
  }
  assert.deepEqual(s.given, [832]);
});

test("达黑黑's 猜弹珠: the marbles go, the tenth win brings 小黑黑 once", async () => {
  const s = setup();
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_46", { num: 1, w: true }), "91_46").get, false);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_47"), "91_47").c, 0, "no marbles, no game");
  s.setItem(MARBLE, 30);
  for (let i = 1; i <= 10; i++) {
    const r = await s.call("PeriodicActiveExtension.91_46", { num: 2, w: true });
    assert.equal(s.answer(r, "91_46").get, i === 10);
    assert.ok(r.some(([c, o]) => c === "onAmountUpdated" && o.amount === `2_${MARBLE}_0_-2`));
  }
  await s.call("PeriodicActiveExtension.91_46", { num: 1, w: false });
  assert.equal(s.item(MARBLE), 9);
  assert.deepEqual(s.given, [335]);
});

test("白京京之心: four times, ten minutes apart, then 小京京", async () => {
  const s = setup();
  assert.deepEqual(s.answer(await s.call("PeriodicActiveExtension.91_48"), "91_48"), { c: 0, l: "" });
  for (let i = 1; i <= 4; i++) {
    assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_49"), "91_49").get, i === 4);
    const st = s.answer(await s.call("PeriodicActiveExtension.91_48"), "91_48");
    assert.equal(st.c, i);
    assert.equal(st.l, clockText(s.clock.now));
    assert.match(st.l, /^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$/);
    s.clock.now += HEART_WAIT_MS;
  }
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_49"), "91_49").get, false);
  assert.deepEqual(s.given, [336]);
});

test("粗心的卡索: each 大力锤 breaks a stone; all eight words bring 卡索", async () => {
  const s = setup({ rng: [0.9, 0.0, ...Array(40).fill(0.1)] });
  assert.equal(s.answer(await s.call("HolidayExtension.20120914_Fu2"), "20120914_Fu2").stone, -1, "no hammer");
  s.setItem(HAMMER, 40);
  const a = s.answer(await s.call("HolidayExtension.20120914_Fu2"), "20120914_Fu2");
  assert.equal(a.stone, 0);
  assert.equal(s.item(HAMMER), 39);
  let last: Record<string, any> = a;
  for (let i = 0; i < 39 && !s.owner.planetActs?.food?.got; i++) last = s.answer(await s.call("HolidayExtension.20120914_Fu2"), "20120914_Fu2");
  assert.equal(s.owner.planetActs?.food?.sign, 255);
  assert.deepEqual(last.bn, [{ type: 102, id: 1209, num: 1 }]);
  assert.deepEqual(s.answer(await s.call("HolidayExtension.20120914_Fu1"), "20120914_Fu1"), { got: true, sign: 255 });
  assert.deepEqual(s.given, [1209]);
});

test("阿莫扭蛋机: a coin a turn, jokes or a bonus; the eighth joke brings 阿莫", async () => {
  // 0.9: bonus (index 3, 200 晶币), then jokes (rng < 0.5, the first missing one).
  const s = setup({ rng: [0.9, 0.9, ...Array(16).fill(0)] });
  s.setItem(AMO_COIN, 9);
  const b = s.answer(await s.call("HolidayExtension.20121012_A2"), "20121012_A2");
  assert.deepEqual(b, { res: true, joke: -1, bn: [{ type: 100, num: 200 }] });
  assert.equal(s.owner.score, 200);
  for (let i = 0; i < 8; i++) assert.equal(s.answer(await s.call("HolidayExtension.20121012_A2"), "20121012_A2").joke, i);
  assert.equal(s.answer(await s.call("HolidayExtension.20121012_A1"), "20121012_A1").state, 255);
  assert.equal(s.answer(await s.call("HolidayExtension.20121012_A2"), "20121012_A2").res, false);
  assert.deepEqual(s.given, [1247]);
  assert.equal(s.item(AMO_COIN), 0);
});

test("钓星星的波波嘟: buy and catch 笑脸星星, 20 of them for 波波嘟 once a day", async () => {
  const s = setup({ rng: [0] });
  const c = s.answer(await s.call("PeriodicActiveExtension.gofish-1"), "gofish-1");
  assert.deepEqual(c, { id: 0, bn: [{ type: 2, id: SMILE_STAR, num: 1 }] });
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.gofish-3", { num: 19 }), "gofish-3").res, 1);
  assert.equal(s.owner.xingbi, 100 - 38);
  assert.equal(s.item(SMILE_STAR), 20);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.gofish-2"), "gofish-2").res, true);
  assert.equal(s.item(SMILE_STAR), 0);
  s.setItem(SMILE_STAR, 40);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.gofish-2"), "gofish-2").res, false, "once a day");
  s.clock.now += 24 * 3600 * 1000;
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.gofish-2"), "gofish-2").res, true);
  assert.deepEqual(s.given, [1286, 1286]);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.gofish-3", { num: 99 }), "gofish-3").res, 0, "not enough 星币");
  // FISH_PER_DAY casts a day catch something; then nothing until the next day.
  for (let i = 0; i < FISH_PER_DAY; i++) await s.call("PeriodicActiveExtension.gofish-1");
  assert.deepEqual(s.answer(await s.call("PeriodicActiveExtension.gofish-1"), "gofish-1"), { id: 6, bn: null });
});

test("独角兽: 铠甲 parts, 先哲 treasures, 仙林 days, then the 飞天独角兽", async () => {
  const s = setup({ pets: [pet(1, 651), pet(2, 651), pet(3, 651)] });
  // 铠甲: four parts of five fragments each.
  s.setItem(ARMOR_FRAG, 20);
  for (const id of [186, 187, 188, 189]) assert.equal(s.answer(await s.call("SynthesizeExtension.57_8", { id, num: 1 }), "57_8").res, 1);
  assert.equal(s.answer(await s.call("SynthesizeExtension.57_8", { id: 186, num: 1 }), "57_8").res, 0);
  assert.equal(s.answer(await s.call("PetExtension2.54e_1", { pid: 1, t: 2 }), "54e_1").res, 0);
  assert.equal(s.owner.pets![0].race, 656);
  assert.equal(s.item(454), 0);
  // 先哲: three treasures after the fights.
  assert.equal(s.answer(await s.call("PetExtension2.54e_1", { pid: 2, t: 1 }), "54e_1").res, 1);
  for (const id of [1, 2, 3]) assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_31", { id }), "91_31").res, true);
  assert.equal(s.answer(await s.call("PetExtension2.54e_1", { pid: 2, t: 1 }), "54e_1").res, 0);
  assert.equal(s.owner.pets![1].race, 655);
  // 仙林: three days with a 小独角兽 following.
  s.owner.followPet = 3;
  for (let d = 0; d < 3; d++) {
    assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_35"), "91_35").res, true);
    assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_35"), "91_35").res, false, "once a day");
    s.clock.now += 24 * 3600 * 1000;
  }
  assert.deepEqual(s.answer(await s.call("PeriodicActiveExtension.91_34"), "91_34"), { c: 3, td: false });
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_36", { id: 3 }), "91_36").res, true);
  assert.equal(s.owner.pets![2].race, 654);
  // NPC 459's 小独角兽, once; then the 飞天 egg.
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_32"), "91_32").res, true);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_32"), "91_32").res, false);
  assert.deepEqual(s.answer(await s.call("PeriodicActiveExtension.91_33"), "91_33"), { es: true, ad: false });
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_37"), "91_37").res, 1);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_37"), "91_37").res, 2);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_40"), "91_40").res, false, "no 亲密度 yet");
  // A friend plays once a day; the owner three times a day.
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_39", { n: s.owner.name }, s.friend), "91_39").res, 1);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_39", { n: s.owner.name }, s.friend), "91_39").res, 2);
  for (let day = 0; s.owner.planetActs!.sky!.love < SKY_LOVE && day < 10; day++) {
    for (let i = 0; i < 3; i++) await s.call("PeriodicActiveExtension.91_39", { n: s.owner.name });
    assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_39", { n: s.owner.name }), "91_39").res, 3);
    s.clock.now += 24 * 3600 * 1000;
  }
  const info = s.answer(await s.call("PeriodicActiveExtension.91_38", { n: s.owner.name }), "91_38");
  assert.equal(info.sum, SKY_LOVE);
  assert.match(info.nl, /朋友#朋友/);
  assert.equal(s.answer(await s.call("PeriodicActiveExtension.91_40"), "91_40").res, true);
  assert.deepEqual(s.given, [651, 653]);
});

test("wild drops: the items the rooms' 亚比 leave after a won fight", () => {
  const o: ActsOwner = { name: "x" };
  assert.deepEqual(wildDrop(o, "cloudstar4", 1203), [["onAmountUpdated", { amount: `2_${HAMMER}_0_1` }]]);
  assert.deepEqual(wildDrop(o, "haikustar4", 706), [["onAmountUpdated", { amount: `2_${MARBLE}_0_2` }]]);
  assert.deepEqual(wildDrop(o, "cloudstar4", 1182), []);
  assert.equal(o.items?.["2"]?.[String(HAMMER)], 1);
});
