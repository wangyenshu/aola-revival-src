// 酷跑星世界 (game/parkour/parkour.swf, a 2014–15 mini game, mmo.game.parkour) for the 2013
// server: HolidayExtension, the commands of its ParkourClient ("ActKuPaoStarWorld" + the name
// below), with the reply fields its panels and ParkourUserData.parseParams read. Every reply
// goes out under the request's own cmd: the panels listen for ParkourClient.Cmd… itself.
//
//   _panel {}                         -> {fr, e, cd, j, d, mr, ml, gc, df, pl: [{pId, lv, ce}],
//                                         rl: [{rId, lv, ce}], rents, rt, ts, l: [{dd, nn, md}]}
//   _startGame {pId, rId, ir}         -> {res, e}      1 go (one 星星能量 used); else "能量不足"
//   _sReStartGame {pId, rId, t, l, sc} -> {res}        复活 (ParkourDiePanel; its 星币 price waived)
//   _endGame {t (s), l (m), sc}       -> {sc, money, j} sc is the score the end panel shows;
//                                         the 金币 are paid (onScoreUpdated)
//   _upgradeRole {id}                 -> {res}         ParkourUpRolePanel
//   _upgradeRidePet {id}              -> {res}         ParkourUpRidePetPanel
//   _gainRole {id}                    -> {res, bn}     ParkourGetRolePanel
//   _gainRidePet {id}                 -> {res, bn}     ParkourGetRidePetPanel
//   _rent {rId}                       -> {res}         ParkourRentRoleConfirmPanel (200 金币, one game)
//   _buyJingBi {id 0–3}               -> {res}         ParkourBuyMoneyPanel (2500/5200/11000/24000 金币)
//   _buyEngery {id 0–3}               -> {res}         ParkourBuyLovePanel (10/20/50/100 星星能量)
//   _getAllGB {}                      -> {gbs: [{gId, si, sn, ti, ct}]}   ParkourRewardPanel's boxes
//   _gainGB {gId}                     -> {bn, gBn}
//   _dailySign {dId 0–6}              -> {bn, gBn}     ParkourDailySignUpPanel
//   _dailyTaskPanel {}                -> {rt, rds, rs} ParkourDailyTaskPanel
//   _gainDailyTask {tId}              -> {bn, gBn}     ParkourDailyTaskView
//   _dailyTaskFinish {tId: "a,b"}     -> nothing       ParkourDailyTaskLogger (the client waits for none)
//
// The fields: fr the first run (the game plays its teach map), e 星星能量 (ParkourMainLoveUI: 5 at
// most, one more every 600 s, cd seconds to the next), j the 金币, d meters run in all, ml the best
// run, mr the rank on the list l (-1 未上榜; dd user, nn nick, md meters), gc boxes waiting; df the
// 7 days signed this week, bit i for day index i (ParkourDailySignUpData: index 0 is Friday); pl
// the roles owned (ce experience since level 1, ParkourRoleUserData.totalExp), rl the ride pets
// (ce experience in the level); rents "roleId:used;…" (ParkourUserData.parseRentingRole: 3 a day,
// used 1 once a game was run with it); rt the sixth task of the day (5–9; 0–4 are every day's),
// ts / rs the tasks whose reward was taken, bit i for task i, rds the progress of tasks 0–9
// ("p0,…,p9"). bn is a ShowBonusHelper list [{type, id, num}], gBn [{op: 1 金币 | 2 星星能量, va}]
// (ParkourHelper.showGBn adds them on the client as well). The 2013 ShowBonusHelper.showBonus
// returns without calling back on an empty list, so a reward's bn carries its 金币 as
// {type: 100, id: -1, num} for the gBn message to follow.
//
// The game's 金币 are the player's 晶币 (record.score) here. From the client: the roles, their
// prices and 超酷程度 (ParkourRoleConfig), the one ride pet (ParkourRidePetConfig), the level
// costs (min(40, lv) × 100) and experience (min(40, lv) × 1000), the top levels (100 and 80), the
// 金币 a run is worth (ParkourPlayer.calMoney: score / 40 × (1 + 超酷程度 %) × (1 + the pet's 金币
// 加成 %)), the 星星能量 rules, the rent price and the counts of the shops; the sign-in pay
// (DailySignUpPanel prints 1000/1500 under each day) and the tasks' (DailyTaskView: 588 for
// tasks 0–4, 1488 for 5–9) are the panels' own figures. The 2013 server is lost:
// RECONSTRUCTED are the 金币 a run pays at most (GAME_MONEY_MAX), that the 星星能量 fill up to 5
// every day as well, that the pet's 积分加成 is applied to the score the server sends back, that
// running gives the role and pet one experience a meter (levelling them up for free when full),
// that rents count by the day, which task 5–9 a day draws, the welcome box, the list (the best
// runs of all, BOARD_SIZE long) and that what costs 星币 in the client (复活, 金币, 星星能量) is free.

import { MONEY_MAX } from "./money.ts";
import { serial } from "../../core/locks.ts";
import type { World, XtContext } from "./server.ts";

export const PARKOUR_EXT = "HolidayExtension";
export const PARKOUR_CMD = "ActKuPaoStarWorld";

/** ParkourRoleConfig: id -> name, price in 金币, 超酷程度 at level 1 (+1 a level). */
export const PARKOUR_ROLES: Record<number, { name: string; price: number; cool: number }> = {
  1: { name: "酷伊乐", price: 0, cool: 34 },
  2: { name: "酷魔兔", price: 8888, cool: 41 },
  3: { name: "酷小黑", price: 15000, cool: 35 },
  4: { name: "酷多多罗", price: 11000, cool: 45 },
  5: { name: "酷炎阳", price: 14000, cool: 45 },
  6: { name: "酷若希", price: 16000, cool: 46 },
  7: { name: "酷蓝宝星", price: 14000, cool: 44 },
};
/** ParkourRidePetConfig: id -> price, 积分加成 and 金币加成 in percent at level 1 and per level. */
export const PARKOUR_RIDES: Record<number, { price: number; score: [number, number]; money: [number, number] }> = {
  1: { price: 0, score: [0, 1], money: [0, 1] },
};
/** ParkourConfig. */
export const MAX_ROLE_LEVEL = 100;
export const MAX_RIDE_LEVEL = 80;
export const MAX_LOVE = 5;
export const LOVE_EVERY_MS = 10 * 60 * 1000;
export const SIGN_DAYS = 7;
export const ALL_TASKS = 10;
export const RENTS_PER_DAY = 3;
/** ParkourRentRoleConfirmPanel.Price. */
export const RENT_PRICE = 200;
/** ParkourBuyMoneyPanel.BuyNumOfMoneys, ParkourBuyLovePanel.BuyNumOfLoves. */
export const BUY_MONEY = [2500, 5200, 11000, 24000];
export const BUY_LOVE = [10, 20, 50, 100];
/** ParkourDailyTaskConfig: the progress each task needs; the reward of each (DailyTaskView). */
export const TASK_NEED = [8, 8, 8, 8, 8, 5, 5, 5, 5, 5];
export const TASK_MONEY = [588, 588, 588, 588, 588, 1488, 1488, 1488, 1488, 1488];
/** DailySignUpPanel: the 金币 under mcSingUp_0…6. */
export const SIGN_MONEY = [1000, 1500, 1500, 1000, 1500, 1000, 1500];
/** ParkourDailySignUpData.FlagIndexByDay: Date.day of each sign index. */
const SIGN_WEEKDAY = [5, 6, 0, 1, 2, 3, 4];
/** RECONSTRUCTED: 金币 a run pays at most, experience a meter, the list's length, the welcome box. */
export const GAME_MONEY_MAX = 2000;
export const EXP_PER_METER = 1;
export const BOARD_SIZE = 10;
export const WELCOME_MONEY = 1000;
const MONEY_CAP = MONEY_MAX;
const SENDER = "酷跑星世界";

export interface ParkourLevel {
  lv: number;
  /** Experience in this level. */
  exp: number;
}

export interface ParkourGift {
  id: number;
  ti: string;
  ct: string;
  money: number;
  love: number;
}

export interface ParkourRec {
  roles: Record<string, ParkourLevel>;
  rides: Record<string, ParkourLevel>;
  love: number;
  /** When the running 600 s of the next 星星能量 began (ms). */
  loveAt: number;
  /** The day the daily refill was last given. */
  loveDay: string;
  /** Meters run in all, the best run. */
  dist: number;
  best: number;
  /** A run was started: no more teach map. */
  played: boolean;
  /** The week (the date of its Friday), bit i = sign index i, the day of the last sign-in. */
  sign: { week: string; flags: number; day: string };
  /** Today's tasks: the sixth one (5–9), progress of tasks 0–9, rewards taken (bit i). */
  task: { day: string; rt: number; prog: number[]; got: number };
  /** Today's rents: [roleId, used]. */
  rents: { day: string; list: [number, number][] };
  gifts: ParkourGift[];
  nextGift: number;
  /** The run going on. */
  game?: { pId: number; rId: number; rented: boolean; at: number };
}

export interface ParkourOwner {
  name: string;
  /** 晶币: the game's 金币. */
  score?: number;
  parkour?: ParkourRec;
}

export interface ParkourRankRow {
  dd: string;
  nn: string;
  md: number;
}

export interface ParkourDeps {
  load(ctx: XtContext): Promise<ParkourOwner>;
  save(o: ParkourOwner): Promise<void>;
  today(): string;
  now?(): number;
  /** Everyone's best runs; without it the list holds the player alone. */
  /**
   * The shop's 金币 and 星星能量 for nothing (_buyJingBi, _buyEngery: 2013's were bought with
   * 奥币): as the 工具箱's, so off where it is closed (default on).
   */
  free?: boolean;
  /** The 排行榜, everyone's: update reads, changes and writes it one change at a time (game.ts updateShared). */
  board?: { get(): Promise<ParkourRankRow[]>; set(rows: ParkourRankRow[]): Promise<void>; update?(f: (rows: ParkourRankRow[]) => ParkourRankRow[]): Promise<unknown> };
}

/** 金币 a level costs and experience a level takes (ParkourRoleUserData / ParkourRidePetUserData). */
export const levelCost = (lv: number) => Math.min(40, lv) * 100;
export const levelExp = (lv: number) => Math.min(40, lv) * 1000;
/** ParkourRoleUserData.getNeedExpFormBorn: experience from level 1 to the start of lv. */
export function expToLevel(lv: number): number {
  let n = 0;
  for (let i = 1; i < lv; i++) n += levelExp(i);
  return n;
}

/** The sign index of a day (0 Friday … 6 Thursday) and the date of its week's Friday. */
export function signIndex(day: string): number {
  return SIGN_WEEKDAY.indexOf(new Date(`${day}T00:00:00Z`).getUTCDay());
}
export function signWeek(day: string): string {
  const t = Date.parse(`${day}T00:00:00Z`) - signIndex(day) * 86_400_000;
  return new Date(t).toISOString().slice(0, 10);
}

/** ParkourPlayer.calMoney for the role and pet a run was made with, capped at GAME_MONEY_MAX. */
export function runMoney(score: number, roleId: number, roleLv: number, rideId: number, rideLv: number): number {
  const cool = (PARKOUR_ROLES[roleId] ?? PARKOUR_ROLES[1]).cool + (roleLv - 1);
  const [base, up] = (PARKOUR_RIDES[rideId] ?? PARKOUR_RIDES[1]).money;
  const pct = base + (rideLv - 1) * up;
  return Math.max(0, Math.min(GAME_MONEY_MAX, Math.trunc(Math.floor(score / 40) * (1 + cool / 100) * (1 + pct / 100))));
}

/** The score sent back: the pet's 积分加成 on what was collected. */
export function runScore(score: number, rideId: number, rideLv: number): number {
  const [base, up] = (PARKOUR_RIDES[rideId] ?? PARKOUR_RIDES[1]).score;
  return Math.floor(score * (1 + (base + (rideLv - 1) * up) / 100));
}

/** Experience gained; full levels go up by themselves (RECONSTRUCTED). */
export function addExp(u: ParkourLevel, gain: number, max: number): void {
  if (u.lv >= max) {
    u.exp = 0;
    return;
  }
  u.exp += Math.max(0, gain);
  while (u.lv < max && u.exp >= levelExp(u.lv)) {
    u.exp -= levelExp(u.lv);
    u.lv += 1;
  }
  if (u.lv >= max) u.exp = 0;
}

const dayHash = (day: string) => [...day].reduce((h, c) => (h * 31 + c.charCodeAt(0)) >>> 0, 7);

export function newParkour(day: string, now: number): ParkourRec {
  return {
    roles: { "1": { lv: 1, exp: 0 } },
    rides: { "1": { lv: 1, exp: 0 } },
    love: MAX_LOVE,
    loveAt: now,
    loveDay: day,
    dist: 0,
    best: 0,
    played: false,
    sign: { week: signWeek(day), flags: 0, day: "" },
    task: { day, rt: 5 + (dayHash(day) % 5), prog: new Array(ALL_TASKS).fill(0), got: 0 },
    rents: { day, list: [] },
    gifts: [{ id: 1, ti: "酷跑星世界见面礼", ct: `欢迎来到酷跑星世界！送你${WELCOME_MONEY}金币。`, money: WELCOME_MONEY, love: 0 }],
    nextGift: 2,
  };
}

/** The player's state, with the day's refills, the day's tasks and rents, and the 星星能量 grown since. */
export function parkourOf(o: ParkourOwner, day: string, now: number): ParkourRec {
  const p = (o.parkour ??= newParkour(day, now));
  if (p.loveDay !== day) {
    p.loveDay = day;
    p.love = Math.max(p.love, MAX_LOVE);
  }
  if (p.love >= MAX_LOVE) p.loveAt = now;
  else {
    const n = Math.floor((now - p.loveAt) / LOVE_EVERY_MS);
    if (n > 0) {
      p.love = Math.min(MAX_LOVE, p.love + n);
      p.loveAt = p.love >= MAX_LOVE ? now : p.loveAt + n * LOVE_EVERY_MS;
    }
  }
  if (p.task.day !== day) p.task = { day, rt: 5 + (dayHash(day) % 5), prog: new Array(ALL_TASKS).fill(0), got: 0 };
  if (p.rents.day !== day) p.rents = { day, list: [] };
  const week = signWeek(day);
  if (p.sign.week !== week) p.sign = { week, flags: 0, day: "" };
  if (!p.rides["1"]) p.rides["1"] = { lv: 1, exp: 0 };
  if (!p.roles["1"]) p.roles["1"] = { lv: 1, exp: 0 };
  return p;
}

/** Seconds to the next 星星能量 (ParkourUserData.nextLoveCD), 0 when full. */
export function loveCd(p: ParkourRec, now: number): number {
  if (p.love >= MAX_LOVE) return 0;
  return Math.max(1, Math.min(LOVE_EVERY_MS / 1000, Math.ceil((p.loveAt + LOVE_EVERY_MS - now) / 1000)));
}

const int = (v: unknown, lo: number, hi: number) => Math.max(lo, Math.min(hi, Math.trunc(Number(v)) || 0));

export function installParkour(world: World, deps: ParkourDeps): void {
  // The 排行榜 one change at a time (two runs ending at once would lose one).
  const turn = serial();
  const updateBoard = (f: (rows: ParkourRankRow[]) => ParkourRankRow[]) => {
    const b = deps.board!;
    return b.update ? b.update(f) : turn(async () => b.set(f((await b.get()) ?? [])));
  };
  const now = () => (deps.now ? deps.now() : Date.now());
  const on = (name: string, h: (ctx: XtContext) => Promise<void>) => world.xt(`${PARKOUR_EXT}.${PARKOUR_CMD}${name}`, h);
  const open = async (ctx: XtContext) => {
    const o = await deps.load(ctx);
    return { o, p: parkourOf(o, deps.today(), now()) };
  };
  /** 金币 in or out: the record's 晶币, and the client's 晶币 shown elsewhere. */
  const pay = (ctx: XtContext, o: ParkourOwner, n: number) => {
    o.score = Math.max(0, Math.min(MONEY_CAP, (o.score ?? 0) + n));
    if (n !== 0) ctx.reply({ score: o.score }, "onScoreUpdated");
  };
  const reward = (money: number, love = 0) => ({
    bn: money > 0 ? [{ type: 100, id: -1, num: money }] : [],
    gBn: [...(money > 0 ? [{ op: 1, va: money }] : []), ...(love > 0 ? [{ op: 2, va: love }] : [])],
  });
  const board = async (o: ParkourOwner, p: ParkourRec): Promise<ParkourRankRow[]> => {
    if (deps.board) return (await deps.board.get()) ?? [];
    return p.best > 0 ? [{ dd: o.name, nn: o.name, md: p.best }] : [];
  };
  const spendLove = (p: ParkourRec, t: number) => {
    const was = p.love;
    p.love -= 1;
    if (was >= MAX_LOVE && p.love < MAX_LOVE) p.loveAt = t;
  };

  on("_panel", async (ctx) => {
    const { o, p } = await open(ctx);
    const rows = await board(o, p);
    const mine = rows.findIndex((r) => r.dd === o.name);
    await deps.save(o);
    ctx.reply({
      fr: !p.played,
      e: p.love,
      cd: loveCd(p, now()),
      j: o.score ?? 0,
      d: p.dist,
      mr: mine >= 0 ? mine + 1 : -1,
      ml: p.best,
      gc: p.gifts.length,
      df: p.sign.flags,
      pl: Object.entries(p.roles)
        .filter(([id]) => PARKOUR_ROLES[Number(id)])
        .map(([id, r]) => ({ pId: Number(id), lv: r.lv, ce: expToLevel(r.lv) + r.exp })),
      rl: Object.entries(p.rides)
        .filter(([id]) => PARKOUR_RIDES[Number(id)])
        .map(([id, r]) => ({ rId: Number(id), lv: r.lv, ce: r.exp })),
      rents: p.rents.list.map(([id, used]) => `${id}:${used}`).join(";"),
      rt: p.task.rt,
      ts: p.task.got,
      l: rows,
    });
  });

  on("_startGame", async (ctx) => {
    const { o, p } = await open(ctx);
    if (p.love <= 0) return ctx.reply({ res: 0, e: p.love });
    const askedRole = int(ctx.params.pId, 0, 99);
    const askedRide = int(ctx.params.rId, 0, 99);
    let pId = PARKOUR_ROLES[askedRole] ? askedRole : 1;
    const rId = PARKOUR_RIDES[askedRide] && p.rides[String(askedRide)] ? askedRide : 1;
    // A role not owned runs at level 1 and uses up a rent of it (ParkourGameSceneJoinProxy
    // returns the rent once the run begins); a role neither owned nor rented runs as the first
    // one (its 金币 are the first one's: the 超酷程度 of a role is bought or rented).
    let rented = !p.roles[String(pId)];
    if (rented) {
      const r = p.rents.list.find(([id, used]) => id === pId && !used);
      if (r) r[1] = 1;
      else {
        pId = 1;
        rented = false;
      }
    }
    const t = now();
    spendLove(p, t);
    p.played = true;
    p.game = { pId, rId, rented, at: t };
    await deps.save(o);
    ctx.reply({ res: 1, e: p.love });
  });

  on("_sReStartGame", async (ctx) => {
    ctx.reply({ res: 1 });
  });

  on("_endGame", async (ctx) => {
    const { o, p } = await open(ctx);
    const sc = int(ctx.params.sc, 0, 10_000_000);
    const meters = int(ctx.params.l, 0, 10_000_000);
    const g = p.game;
    if (!g) return ctx.reply({ sc, money: 0, j: o.score ?? 0 });
    delete p.game;
    const role = g.rented ? undefined : p.roles[String(g.pId)];
    const ride = p.rides[String(g.rId)] ?? p.rides["1"];
    const money = runMoney(sc, g.pId, role?.lv ?? 1, g.rId, ride.lv);
    const real = runScore(sc, g.rId, ride.lv);
    p.dist += meters;
    const better = meters > p.best;
    if (better) p.best = meters;
    if (role) addExp(role, meters * EXP_PER_METER, MAX_ROLE_LEVEL);
    addExp(ride, meters * EXP_PER_METER, MAX_RIDE_LEVEL);
    pay(ctx, o, money);
    if (better && deps.board) {
      const best = p.best;
      await updateBoard((all) => {
        const rows = all.filter((r) => r.dd !== o.name);
        rows.push({ dd: o.name, nn: o.name, md: best });
        rows.sort((a, b) => b.md - a.md);
        return rows.slice(0, BOARD_SIZE);
      });
    }
    await deps.save(o);
    ctx.reply({ sc: real, money, j: o.score ?? 0 });
  });

  on("_upgradeRole", async (ctx) => {
    const { o, p } = await open(ctx);
    const r = p.roles[String(int(ctx.params.id, 0, 99))];
    if (!r || r.lv >= MAX_ROLE_LEVEL) return ctx.reply({ res: 0 });
    const cost = levelCost(r.lv);
    if ((o.score ?? 0) < cost) return ctx.reply({ res: -2 });
    pay(ctx, o, -cost);
    r.lv += 1;
    r.exp = 0;
    await deps.save(o);
    ctx.reply({ res: 1 });
  });

  on("_upgradeRidePet", async (ctx) => {
    const { o, p } = await open(ctx);
    const r = p.rides[String(int(ctx.params.id, 0, 99))];
    if (!r || r.lv >= MAX_RIDE_LEVEL) return ctx.reply({ res: 0 });
    const cost = levelCost(r.lv);
    if ((o.score ?? 0) < cost) return ctx.reply({ res: -2 });
    pay(ctx, o, -cost);
    r.lv += 1;
    r.exp = 0;
    await deps.save(o);
    ctx.reply({ res: 1 });
  });

  on("_gainRole", async (ctx) => {
    const { o, p } = await open(ctx);
    const id = int(ctx.params.id, 0, 99);
    const info = PARKOUR_ROLES[id];
    if (!info || p.roles[String(id)]) return ctx.reply({ res: 0, bn: [] });
    if ((o.score ?? 0) < info.price) return ctx.reply({ res: -2, bn: [] });
    pay(ctx, o, -info.price);
    p.roles[String(id)] = { lv: 1, exp: 0 };
    for (const r of p.rents.list) if (r[0] === id) r[1] = 1;
    await deps.save(o);
    ctx.reply({ res: 1, bn: [] });
  });

  on("_gainRidePet", async (ctx) => {
    const { o, p } = await open(ctx);
    const id = int(ctx.params.id, 0, 99);
    const info = PARKOUR_RIDES[id];
    if (!info || p.rides[String(id)]) return ctx.reply({ res: 0, bn: [] });
    if ((o.score ?? 0) < info.price) return ctx.reply({ res: -2, bn: [] });
    pay(ctx, o, -info.price);
    p.rides[String(id)] = { lv: 1, exp: 0 };
    await deps.save(o);
    ctx.reply({ res: 1, bn: [] });
  });

  on("_rent", async (ctx) => {
    const { o, p } = await open(ctx);
    const id = int(ctx.params.rId, 0, 99);
    if (!PARKOUR_ROLES[id] || p.roles[String(id)] || p.rents.list.length >= RENTS_PER_DAY) return ctx.reply({ res: 0 });
    if (p.rents.list.some(([rid, used]) => rid === id && !used)) return ctx.reply({ res: 0 });
    if ((o.score ?? 0) < RENT_PRICE) return ctx.reply({ res: -2 });
    pay(ctx, o, -RENT_PRICE);
    p.rents.list.push([id, 0]);
    await deps.save(o);
    ctx.reply({ res: 1 });
  });

  on("_buyJingBi", async (ctx) => {
    const id = Number(ctx.params.id);
    if (deps.free === false || !Number.isInteger(id) || !BUY_MONEY[id]) return ctx.reply({ res: 0 });
    const { o } = await open(ctx);
    pay(ctx, o, BUY_MONEY[id]);
    await deps.save(o);
    ctx.reply({ res: 1 });
  });

  on("_buyEngery", async (ctx) => {
    const id = Number(ctx.params.id);
    if (deps.free === false || !Number.isInteger(id) || !BUY_LOVE[id]) return ctx.reply({ res: 0 });
    const { o, p } = await open(ctx);
    p.love += BUY_LOVE[id];
    if (p.love >= MAX_LOVE) p.loveAt = now();
    await deps.save(o);
    ctx.reply({ res: 1 });
  });

  on("_getAllGB", async (ctx) => {
    const { o, p } = await open(ctx);
    await deps.save(o);
    ctx.reply({ gbs: p.gifts.map((g) => ({ gId: g.id, si: 0, sn: SENDER, ti: g.ti, ct: g.ct })) });
  });

  on("_gainGB", async (ctx) => {
    const { o, p } = await open(ctx);
    const gId = int(ctx.params.gId, 0, 1 << 30);
    const g = p.gifts.find((x) => x.id === gId);
    if (!g) return ctx.reply({ bn: [], gBn: [] });
    p.gifts = p.gifts.filter((x) => x !== g);
    pay(ctx, o, g.money);
    p.love += g.love;
    if (p.love >= MAX_LOVE) p.loveAt = now();
    await deps.save(o);
    ctx.reply(reward(g.money, g.love));
  });

  on("_dailySign", async (ctx) => {
    const { o, p } = await open(ctx);
    const day = deps.today();
    const asked = Number(ctx.params.dId);
    const idx = Number.isInteger(asked) && asked >= 0 && asked < SIGN_DAYS ? asked : signIndex(day);
    if (p.sign.day === day || p.sign.flags & (1 << idx)) return ctx.reply({ bn: [], gBn: [] });
    p.sign.flags |= 1 << idx;
    p.sign.day = day;
    pay(ctx, o, SIGN_MONEY[idx]);
    await deps.save(o);
    ctx.reply(reward(SIGN_MONEY[idx]));
  });

  on("_dailyTaskPanel", async (ctx) => {
    const { o, p } = await open(ctx);
    await deps.save(o);
    ctx.reply({ rt: p.task.rt, rds: p.task.prog.join(","), rs: p.task.got });
  });

  on("_gainDailyTask", async (ctx) => {
    const { o, p } = await open(ctx);
    const id = Number(ctx.params.tId);
    const today = (id >= 0 && id <= 4) || id === p.task.rt;
    if (!Number.isInteger(id) || !today || p.task.prog[id] < TASK_NEED[id] || p.task.got & (1 << id)) return ctx.reply({ bn: [], gBn: [] });
    p.task.got |= 1 << id;
    pay(ctx, o, TASK_MONEY[id]);
    await deps.save(o);
    ctx.reply(reward(TASK_MONEY[id]));
  });

  on("_dailyTaskFinish", async (ctx) => {
    const { o, p } = await open(ctx);
    for (const s of String(ctx.params.tId ?? "").split(",")) {
      const id = Number(s);
      if (s === "" || !Number.isInteger(id) || id < 0 || id >= ALL_TASKS) continue;
      p.task.prog[id] = Math.min(TASK_NEED[id], p.task.prog[id] + 1);
    }
    await deps.save(o);
  });
}
