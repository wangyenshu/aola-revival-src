import assert from "node:assert/strict";
import { test } from "node:test";
import {
  BUY_LOVE,
  BUY_MONEY,
  GAME_MONEY_MAX,
  LOVE_EVERY_MS,
  MAX_LOVE,
  PARKOUR_ROLES,
  RENT_PRICE,
  SIGN_MONEY,
  TASK_MONEY,
  WELCOME_MONEY,
  expToLevel,
  installParkour,
  runMoney,
  signIndex,
  signWeek,
  type ParkourOwner,
  type ParkourRankRow,
} from "../src/game/sfs2013/parkour.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const CMD = "HolidayExtension.ActKuPaoStarWorld";

function setup(opts: { score?: number; board?: boolean; start?: number } = {}) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const owner: ParkourOwner = { name: "小奥拉", score: opts.score ?? 5000 };
  // 2013-01-25, a Friday (sign index 0), 10:00 UTC.
  const clock = { now: opts.start ?? Date.UTC(2013, 0, 25, 10, 0, 0) };
  let rows: ParkourRankRow[] = [];
  let saves = 0;
  installParkour(world, {
    load: async () => owner,
    save: async () => {
      saves++;
    },
    today: () => new Date(clock.now).toISOString().slice(0, 10),
    now: () => clock.now,
    board: opts.board === false ? undefined : { get: async () => rows, set: async (r) => void (rows = r) },
  });
  const call = async (name: string, params: Record<string, unknown> = {}) => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: owner.name }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    const h = handlers.get(CMD + name);
    assert.ok(h, `no handler for ${name}`);
    await h(ctx, CMD + name);
    return replies;
  };
  /** The reply under the request's own cmd (the handlers use the default, as plants.ts does). */
  const answer = (r: [string | undefined, Record<string, any>][]) => r.find(([c]) => c === undefined)![1];
  return { owner, call, answer, clock, rows: () => rows, saves: () => saves };
}

test("every ParkourClient command has a handler", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  installParkour(world, { load: async () => ({ name: "x" }), save: async () => {}, today: () => "2013-01-25" });
  const names = ["_panel", "_upgradeRole", "_upgradeRidePet", "_gainRole", "_gainRidePet", "_startGame", "_endGame", "_sReStartGame", "_buyJingBi", "_buyEngery", "_getAllGB", "_gainGB", "_dailySign", "_dailyTaskPanel", "_gainDailyTask", "_dailyTaskFinish", "_rent"];
  for (const n of names) assert.ok(handlers.has(CMD + n), n);
  assert.equal(handlers.size, names.length);
});

test("the main panel: first role and ride pet owned, full 星星能量, the 金币 are the 晶币", async () => {
  const { call, answer } = setup();
  const r = answer(await call("_panel"));
  assert.equal(r.fr, true);
  assert.equal(r.e, MAX_LOVE);
  assert.equal(r.cd, 0);
  assert.equal(r.j, 5000);
  assert.equal(r.d, 0);
  assert.equal(r.ml, 0);
  assert.equal(r.mr, -1);
  assert.deepEqual(r.l, []);
  assert.deepEqual(r.pl, [{ pId: 1, lv: 1, ce: 0 }]);
  assert.deepEqual(r.rl, [{ rId: 1, lv: 1, ce: 0 }]);
  assert.equal(r.rents, "");
  assert.equal(r.df, 0);
  assert.equal(r.ts, 0);
  assert.ok(r.rt >= 5 && r.rt <= 9);
  assert.equal(r.gc, 1);
});

test("a run: start uses one 星星能量, the end pays ParkourPlayer.calMoney in 晶币 and levels the role", async () => {
  const { owner, call, answer, clock, rows } = setup();
  const start = answer(await call("_startGame", { pId: 1, rId: 1, ir: false }));
  assert.equal(start.res, 1);
  assert.equal(owner.parkour!.love, MAX_LOVE - 1);
  clock.now += 90_000;
  const end = await call("_endGame", { t: 90, l: 3000, sc: 4000 });
  // int(4000 / 40) × (1 + 34 / 100) × (1 + 0 / 100) = 134 for 酷伊乐 Lv1 on ride pet 1 Lv1.
  assert.equal(runMoney(4000, 1, 1, 1, 1), 134);
  assert.deepEqual(end[0], ["onScoreUpdated", { score: 5134 }]);
  assert.equal(answer(end).sc, 4000);
  assert.equal(answer(end).money, 134);
  assert.equal(owner.score, 5134);
  // 3000 m: Lv1 takes 1000, Lv2 2000 -> Lv3.
  const panel = answer(await call("_panel"));
  assert.equal(panel.fr, false);
  assert.equal(panel.j, 5134);
  assert.equal(panel.d, 3000);
  assert.equal(panel.ml, 3000);
  assert.deepEqual(panel.pl, [{ pId: 1, lv: 3, ce: expToLevel(3) }]);
  assert.deepEqual(panel.rl, [{ rId: 1, lv: 3, ce: 0 }]);
  assert.equal(panel.e, MAX_LOVE - 1);
  assert.equal(panel.cd, LOVE_EVERY_MS / 1000 - 90);
  assert.equal(panel.mr, 1);
  assert.deepEqual(panel.l, [{ dd: "小奥拉", nn: "小奥拉", md: 3000 }]);
  assert.deepEqual(rows(), panel.l);
  // An end with no run going pays nothing; a huge score pays at most GAME_MONEY_MAX.
  await call("_endGame", { t: 10, l: 100, sc: 1000 });
  assert.equal(owner.score, 5134);
  await call("_startGame", { pId: 1, rId: 1, ir: false });
  assert.equal(answer(await call("_sReStartGame", { pId: 1, rId: 1, t: 30, l: 900, sc: 500 })).res, 1);
  await call("_endGame", { t: 999, l: 1000, sc: 9_999_999 });
  assert.equal(owner.score, 5134 + GAME_MONEY_MAX);
});

test("星星能量: none left, no run; one more every 600 s, full again the next day", async () => {
  const { owner, call, answer, clock } = setup();
  for (let i = 0; i < MAX_LOVE; i++) assert.equal(answer(await call("_startGame", { pId: 1, rId: 1 })).res, 1);
  assert.equal(answer(await call("_startGame", { pId: 1, rId: 1 })).res, 0);
  clock.now += LOVE_EVERY_MS;
  assert.equal(answer(await call("_panel")).e, 1);
  assert.equal(answer(await call("_startGame", { pId: 1, rId: 1 })).res, 1);
  clock.now += 24 * 3600_000;
  assert.equal(answer(await call("_panel")).e, MAX_LOVE);
  // Bought 星星能量 go over the top (free here: the client prices them in 星币).
  assert.equal(answer(await call("_buyEngery", { id: 0 })).res, 1);
  assert.equal(owner.parkour!.love, MAX_LOVE + BUY_LOVE[0]);
  assert.equal(answer(await call("_panel")).cd, 0);
});

test("buying and levelling roles with 晶币 at the client's prices; 金币 packs are free", async () => {
  const { owner, call, answer } = setup({ score: 8000 });
  // 酷魔兔 costs 8888.
  const short = await call("_gainRole", { id: 2 });
  assert.equal(answer(short).res, -2);
  assert.equal(owner.score, 8000);
  const pack = await call("_buyJingBi", { id: 0 });
  assert.equal(answer(pack).res, 1);
  assert.deepEqual(pack[0], ["onScoreUpdated", { score: 8000 + BUY_MONEY[0] }]);
  const bought = await call("_gainRole", { id: 2 });
  assert.equal(answer(bought).res, 1);
  assert.deepEqual(answer(bought).bn, []);
  assert.equal(owner.score, 8000 + BUY_MONEY[0] - PARKOUR_ROLES[2].price);
  assert.equal(answer(await call("_gainRole", { id: 2 })).res, 0);
  const before = owner.score!;
  assert.equal(answer(await call("_upgradeRole", { id: 2 })).res, 1);
  assert.equal(owner.score, before - 100);
  assert.equal(answer(await call("_upgradeRidePet", { id: 1 })).res, 1);
  assert.equal(owner.score, before - 200);
  assert.equal(answer(await call("_upgradeRole", { id: 5 })).res, 0); // not owned
  assert.equal(answer(await call("_gainRidePet", { id: 1 })).res, 0); // owned from the start
  const pl = answer(await call("_panel")).pl;
  assert.deepEqual(pl, [
    { pId: 1, lv: 1, ce: 0 },
    { pId: 2, lv: 2, ce: expToLevel(2) },
  ]);
});

test("renting a role: 200 晶币, used by one run, three a day", async () => {
  const { owner, call, answer, clock } = setup();
  assert.equal(answer(await call("_rent", { rId: 1 })).res, 0); // owned already
  assert.equal(answer(await call("_rent", { rId: 3 })).res, 1);
  assert.equal(owner.score, 5000 - RENT_PRICE);
  assert.equal(answer(await call("_rent", { rId: 3 })).res, 0); // still renting it
  assert.equal(answer(await call("_panel")).rents, "3:0");
  assert.equal(answer(await call("_startGame", { pId: 3, rId: 1, ir: true })).res, 1);
  assert.equal(answer(await call("_panel")).rents, "3:1");
  // Rented, 酷小黑 runs at level 1 (超酷程度 35) and gains no experience.
  await call("_endGame", { t: 60, l: 2000, sc: 4000 });
  assert.equal(owner.score, 5000 - RENT_PRICE + runMoney(4000, 3, 1, 1, 1));
  assert.equal(owner.parkour!.roles["3"], undefined);
  assert.equal(answer(await call("_rent", { rId: 3 })).res, 1);
  assert.equal(answer(await call("_rent", { rId: 4 })).res, 1);
  assert.equal(answer(await call("_rent", { rId: 5 })).res, 0); // three today
  clock.now += 24 * 3600_000;
  assert.equal(answer(await call("_panel")).rents, "");
});

test("the week's sign-in: a bit a day, the panel's 金币, once a day", async () => {
  assert.equal(signIndex("2013-01-25"), 0); // Friday
  assert.equal(signIndex("2013-01-27"), 2); // Sunday
  assert.equal(signIndex("2013-01-31"), 6); // Thursday
  assert.equal(signWeek("2013-01-31"), "2013-01-25");
  assert.equal(signWeek("2013-02-01"), "2013-02-01");
  const { owner, call, answer, clock } = setup({ start: Date.UTC(2013, 0, 27, 10) });
  const r = await call("_dailySign", { dId: 2 });
  assert.deepEqual(answer(r), { bn: [{ type: 100, id: -1, num: SIGN_MONEY[2] }], gBn: [{ op: 1, va: SIGN_MONEY[2] }] });
  assert.equal(owner.score, 5000 + SIGN_MONEY[2]);
  assert.deepEqual(answer(await call("_dailySign", { dId: 2 })), { bn: [], gBn: [] });
  assert.equal(answer(await call("_panel")).df, 1 << 2);
  clock.now += 24 * 3600_000;
  await call("_dailySign", { dId: 3 });
  assert.equal(answer(await call("_panel")).df, (1 << 2) | (1 << 3));
  // A new week (from Friday) starts over.
  clock.now = Date.UTC(2013, 1, 1, 10);
  assert.equal(answer(await call("_panel")).df, 0);
});

test("daily tasks: progress from the game, a reward once, the counts reset the next day", async () => {
  const { owner, call, answer, clock } = setup();
  for (let i = 0; i < 9; i++) assert.deepEqual(await call("_dailyTaskFinish", { tId: "0" }), []);
  await call("_dailyTaskFinish", { tId: "5,9" });
  const panel = answer(await call("_dailyTaskPanel"));
  assert.equal(panel.rds, "8,0,0,0,0,1,0,0,0,1");
  assert.equal(panel.rs, 0);
  assert.ok(panel.rt >= 5 && panel.rt <= 9);
  assert.deepEqual(answer(await call("_gainDailyTask", { tId: 1 })), { bn: [], gBn: [] }); // not done
  const got = await call("_gainDailyTask", { tId: 0 });
  assert.deepEqual(answer(got).gBn, [{ op: 1, va: TASK_MONEY[0] }]);
  assert.equal(owner.score, 5000 + TASK_MONEY[0]);
  assert.deepEqual(answer(await call("_gainDailyTask", { tId: 0 })), { bn: [], gBn: [] });
  assert.equal(answer(await call("_dailyTaskPanel")).rs, 1);
  assert.equal(answer(await call("_panel")).ts, 1);
  clock.now += 24 * 3600_000;
  assert.equal(answer(await call("_dailyTaskPanel")).rds, "0,0,0,0,0,0,0,0,0,0");
});

test("the reward boxes: a welcome box, opened once", async () => {
  const { owner, call, answer } = setup({ board: false });
  const list = answer(await call("_getAllGB")).gbs;
  assert.equal(list.length, 1);
  assert.equal(typeof list[0].ti, "string");
  const open = await call("_gainGB", { gId: list[0].gId });
  assert.deepEqual(answer(open), { bn: [{ type: 100, id: -1, num: WELCOME_MONEY }], gBn: [{ op: 1, va: WELCOME_MONEY }] });
  assert.equal(owner.score, 5000 + WELCOME_MONEY);
  assert.deepEqual(answer(await call("_gainGB", { gId: list[0].gId })), { bn: [], gBn: [] });
  const panel = answer(await call("_panel"));
  assert.equal(panel.gc, 0);
  // Without a shared list the player's own best is the list.
  await call("_startGame", { pId: 1, rId: 1 });
  await call("_endGame", { t: 10, l: 500, sc: 100 });
  const after = answer(await call("_panel"));
  assert.deepEqual(after.l, [{ dd: "小奥拉", nn: "小奥拉", md: 500 }]);
  assert.equal(after.mr, 1);
});
