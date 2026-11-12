// What the 30 Nov 2012 world map (tools/data/map-places-2012.json) lists as places' 功能, for the
// 2013 server: the commands of the era panels and services behind them that nothing else answers.
// The 2013 server is lost; reply fields are the ones the panels read. What a reply decides (how
// much is paid, how often) is RECONSTRUCTED unless a panel's own figures say it.
//
// 神奇摇摇树 (亚比研究中心's 科学院: the scene's YaoYaoTree; SundriesExtension):
//   70_34 {}                 -> {num}            fruit on the tree (0–6)
//   70_35 {}                 -> {res}            pick them all: num × 摇摇果实 (item 419)
//   The tree's hover text counts to the next 6:00 ("离下次结果时间还有 30−h 小时"): it bears
//   TREE_FRUIT again every day from 6:00 (RECONSTRUCTED: how many; the panel draws six).
//
// 骑士王座 (骑士学院's btnKnight: activityres/knightpanel; PeriodicActiveExtension):
//   knight_4 {}              -> {res}            0: today's 骑士卡 (item 531) may be taken
//   knight_5 {}              -> {suc}            take them (KNIGHT_CARDS_A_DAY; the panel shows 3)
//   knight_1 {}              -> {suc, res}       占卜: 5 骑士卡 (KnightPanel.COUNT) for the 小骑兵 (932,
//                                                Lv 25, first in the bag) to learn its future: res
//                                                one of the four 骑士 (933 若水, 935 萧辰, 937 瑞阳, 939 浩然)
//   knight_2 {pmId}          -> {suc}            become the one foretold
//   knight_3 {raceId, pmId}  -> {suc}            choose one for 30 星币 (KnightEvolvePanel.XINGBI)
//
// 星愿气球 (ballwish/ballwish, BallWishService and its ballwishpanel; BalloonExtension):
//   88_2 {}                  -> {result}         0 no wish today, else today's wish (1–6)
//   88_1 {wi}                -> nothing          make today's wish (WishMakePanelMediator.items)
//   88_10 {faceId, content}  -> nothing          a 心情 with the wish (100 晶币: "你的晶币不够哦")
//   88_4 {}                  -> {suc, wi, dd, nn}         someone else's wish balloon floating by
//   88_5 {dd}                -> nothing          bless it
//   88_9 {}                  -> {suc, mood: {uid, date, faceId, content}, dd, nn}   someone's 心情
//   88_11 {uid, date, content, faceId, stuff}   -> nothing          answer it
//   88_3, 88_6, 88_7, 88_8   -> {list: []}       lists the 2013 panel never asks for
//   Wishes and 心情 are kept for everyone (store area/balloon), the last BALLOON_KEEP of each.
//
// 爱心捐赠 and 爱心领取 (爱心协会: donate/donateservice, its donatepanel; DonateExtension, the 2013
//   socketclient's DonateClient):
//   87_1 {type, id, num}     -> {result, redFlower}   give: type 100 晶币 (id 0), else that
//                                                material; 1 done, 101 too little, 104 enough today
//   87_2 {}                  -> {result}         take: 1 done (DONATE_TAKE 晶币 from the pool),
//                                                106 already today, 107 rich enough, 108 the pool is short
//   87_3 {}                  -> {donatePeople, donation, takeCount}   (the panel adds 500000 to the counts)
//   87_4 {}, 87_5 {}         -> {ms}             my 晶币 given in all (total and this week alike)
//   87_6 {}                  -> {list}           the latest givers' names ("a,b,c"), shown in the hall
//   The pool is everyone's (store area/donate). RECONSTRUCTED: the least one gives (DONATE_MIN
//   晶币), gifts a day (DONATE_PER_DAY), who may take (under DONATE_RICH 晶币) and how much.
//
// HELLO技能学习 (HELLO学院: robot/robotskillservice's SkillWakenTool, the HELLO games; RobotExtension,
//   the 2013 socketclient's RobotPotentialClient):
//   2-21 {type, score}       -> {pt}             a HELLO game ended (type 1 视觉, 2 记忆, 3 计算):
//                                                潜能 points of that kind got (HELLO_POINTS by grade)
//   2-20 {un}                -> {sc, pt}         best scores and 潜能 as "视觉,记忆,计算"
//   2-22 {id}                -> {result}         wake skill id (0 技能排序, 1 孵化, 2 研究, 4 觉醒):
//                                                1 done, -4 known, -2 too little 潜能, -3 game grade too low
//   What each skill asks is the panel's own table (MySkillWakenInfo.skillWakenInfo) and grades
//   (RobotGame: d 0, c 30, b 50, a 90, s 130). The points a game gives are RECONSTRUCTED. The
//   HELLO's own record (RobotExtension 2-0, tasks.ts) carries the woken skills ("f", one character
//   per skill id); waking one twice answers -4.
//
// 职业亚比进化 (银河商会's 塞恩斯, 职业亚比大变身: activityres/unionevolution; PetExtension2):
//   54e_1 {pid, t}           -> {res}            0 done: the union 亚比 pid (679 仔仔, 694 皮皮, 754 游游)
//                                                takes the t-th (1, 2) of its two sweets
//                                                (EvolutionPanelBase.itemIds) and becomes that form
//   The forms are the 2013 pet data's names: 霹雳/雷霆仔仔 (721, 729), 旋风/铁拳皮皮 (722, 742),
//   摩托/利尾游游 (788, 870). The 小独角兽's evolution uses the same command (planetacts.ts): any
//   other 亚比 is left to it.
//
// 小白吐获得 (彩虹小城's 小白吐的家: activityres/xiaobaitu; PeriodicActiveExtension):
//   s_s_1 {}                 -> {res}            糖果 in today's bottle (0–15)
//   s_s_2 {c}                -> {res}            put c 糖果 (item 513, won from the 布布兔) in; true when the
//                                                bottle is full: a 小白吐 (846, Lv 1) — one a day ("每天只能获得1只小白吐")

import { inFight } from "./fighting.ts";
import { chinaDay } from "../../core/clock.ts";
import { serial } from "../../core/locks.ts";
import type { World, XtContext } from "./server.ts";
import { detailOf, followVar, newPet, type PetRecord, type PetTables } from "./pets.ts";
import { gainExp } from "./battle.ts";

export const TREE_FRUIT = 6;
export const TREE_ITEM = 419;
export const TREE_HOUR = 6;

export const KNIGHT_CARD = 531;
export const KNIGHT_CARDS_A_DAY = 3;
export const KNIGHT_AUGURY_CARDS = 5;
export const KNIGHT_PET = 932;
export const KNIGHT_LEVEL = 25;
export const KNIGHTS = [933, 935, 937, 939];
export const KNIGHT_XINGBI = 30;

export const BALLOON_KEEP = 50;
export const MOOD_PRICE = 100;

export const DONATE_MONEY = 100;
export const DONATE_MIN = 10;
export const DONATE_PER_DAY = 3;
export const DONATE_RICH = 1000;
export const DONATE_TAKE = 200;
export const DONATE_NAMES = 10;

/** RobotGame.GRADES_ROBOTGAME lower bounds, and the 潜能 a game of that grade gives (RECONSTRUCTED). */
export const HELLO_GRADES: [number, string][] = [[0, "d"], [30, "c"], [50, "b"], [90, "a"], [130, "s"]];
export const HELLO_POINTS: Record<string, number> = { d: 1, c: 2, b: 3, a: 4, s: 5 };
/** MySkillWakenInfo.skillWakenInfo: skill -> [[视觉, 记忆, 计算 潜能], [game type, grade]]. */
export const HELLO_SKILLS: Record<number, [[number, number, number], [number, string]]> = {
  0: [[5, 10, 13], [3, "s"]],
  1: [[10, 6, 3], [1, "b"]],
  2: [[12, 15, 3], [2, "b"]],
  4: [[4, 10, 2], [2, "a"]],
};
/** EvolutionPanelBase.itemIds by union 亚比, and the form each sweet makes. */
export const UNION_FORMS: Record<number, [number, number][]> = {
  679: [[475, 721], [490, 729]],
  694: [[477, 722], [491, 742]],
  754: [[492, 788], [514, 870]],
};
export const SWEET_ITEM = 513;
export const SWEETS_FOR_PET = 15;
export const XIAOBAITU = 846;

export const GYM_HIT_COINS = 5;
export const GYM_GAME_COINS = 200;
export const GYM_GAME_SCORE = 30;
/** The 道馆 games pay (晶币, 训练积分, 爆发点) for at most this many games a day (RECONSTRUCTED). */
export const GYM_GAMES_PER_DAY = 5;
export const THUNDER_STONE = 616;
/** The training shops' six kinds (BuyPanel.giftId order): [type, id, num]; type 100 晶币, 101 经验. */
export const GYM_SHOP: [number, number, number][] = [[101, 0, 500], [100, 0, 500], [2, 524, 1], [2, 60, 3], [0, 1846, 1], [2, 384, 1]];
/** BuyPanel.COST by giftId (its COST is by row: rows giftId 5,4,1,0,2,3). */
export const WATER_COST = [30, 30, 20, 20, 150, 40];
/** BreakOutExchangePanel: exId_0–5 at _needPointArr; exId_1 is its clothes (_clothId 1864). */
export const FIRE_COST = [300, 1000, 350, 150, 100, 100];
export const FIRE_SHOP: [number, number, number][] = [[2, 383, 1], [0, 1864, 1], [100, 0, 500], [101, 0, 500], [2, 524, 1], [2, 60, 3]];

export const GROW_LEVELS = 2;
export const GROW_WAIT = 600;
export const GROW_STEPS = 6;
/** MainPanel's rewards by row (rewordConfig: after 1, 3, 6, 10 runs): [type, id, num] (RECONSTRUCTED;
 *  the fourth was a 特性卡, a kind of card the 2013 server here does not keep: 晶币 instead). */
export const GROW_GIFTS: [number, number, number][] = [[100, 0, 1000], [2, 60, 5], [2, 102, 1], [100, 0, 3000]];
export const GROW_RUNS = [1, 3, 6, 10];

/** ExchangePanel.BONUS_MAP: id -> [material type (102 a 亚比), id, 欢乐券 each]. */
export const TICKET_ITEM = 297;
export const TICKET_GOODS: Record<number, [number, number, number]> = {
  84: [0, 533, 200], 85: [0, 534, 200], 86: [0, 535, 200],
  87: [1, 147, 100], 88: [1, 148, 100], 89: [1, 149, 100],
  139: [2, 343, 8],
  182: [1, 291, 50], 183: [1, 292, 50], 184: [1, 293, 50],
  185: [102, 139, 400],
};

/** WeekSelectPanelContainer: gift id -> [item, count, 晶币, 经验]. */
export const WEEK_GIFTS: Record<number, [number, number, number, number]> = {
  69: [67, 3, 5000, 20000],
  70: [61, 10, 5000, 20000],
  71: [104, 10, 5000, 20000],
  72: [0, 0, 7000, 20000],
};
/** Weeks from Monday 5 January 1970 (a Monday). */
export const weekOf = (day: string) => Math.floor((Date.parse(day + "T00:00:00Z") / 86400000 - 4) / 7);

export const helloGrade = (score: number) => [...HELLO_GRADES].reverse().find(([min]) => score >= min)![1];

type Bag = Record<string, Record<string, number>>;

/** The fields of the player's record these functions use (UserRecord has them or keeps them). */
export interface AreaPet {
  id: number;
  race: number;
  level: number;
  exp?: number;
}
export interface AreaRec {
  id?: number;
  name: string;
  nextPetId?: number;
  storage?: AreaPet[];
  score?: number;
  xingbi?: number;
  items?: Bag;
  pets?: AreaPet[];
  followPet?: number;
  robot?: { exp: number };
  area?: {
    /** 摇摇树: the day (6:00 to 6:00) it was last picked. */
    tree?: string;
    /** 骑士王座: the day the cards were taken; the 骑士 foretold. */
    knightDay?: string;
    knightSeen?: number;
    /** 星愿气球: today's wish. */
    wish?: { day: string; wi: number };
    /** 爱心协会: gifts today, the day taken, 晶币 given in all. */
    donate?: { day: string; n: number; took?: string; total: number };
    /** HELLO: best scores and 潜能 per kind (视觉, 记忆, 计算), skills woken. */
    hello?: { sc: number[]; pt: number[]; woken: number[] };
    /** 小白吐的家: today's bottle. */
    bottle?: { day: string; n: number };
    /** 蓝宝石礼包: the week the weekly gift was taken. */
    weekGift?: number;
    /** 亚比成长计划: the 亚比, step, taken up, when the next may be taken (ms), runs, rewards taken. */
    grow?: { pet: number; step: number; taken: boolean; next: number; count: number; flag: number };
    /** The 道馆: today's passes, 试炼值, 训练积分, 爆发点. */
    gym?: { day: string; pb: boolean; pt: boolean; s: number; water: number; fire: number; coinsToday?: number; waterToday?: number; fireToday?: number };
  };
}

export interface BalloonStore {
  wishes: { dd: string; nn: string; wi: number; day: string }[];
  moods: { uid: number; dd: string; nn: string; date: string; faceId: number; content: string }[];
}
export interface DonateStore {
  pool: number;
  people: number;
  donation: number;
  takes: number;
  names: string[];
}

export interface AreaDeps {
  load: (ctx: XtContext) => Promise<AreaRec & { id: number }>;
  save: (rec: AreaRec) => Promise<void>;
  /** The day as YYYY-MM-DD, and the time in ms (the emulator clock). */
  today: () => string;
  now: () => number;
  /** Shared state (the emulator store). */
  get: <T>(key: string) => Promise<T | undefined>;
  set: (key: string, value: unknown) => Promise<void>;
  /** Shared state read, changed and written one change at a time (game.ts updateShared). */
  update?: <T>(key: string, f: (v: T | undefined) => T) => Promise<unknown>;
  /** The pet tables (a 亚比 given). */
  pets?: () => Promise<PetTables>;
}

const area = (rec: AreaRec) => (rec.area ??= {});
const bag = (rec: AreaRec, type = "2") => ((rec.items ??= {})[type] ??= {});

function give(ctx: XtContext, rec: AreaRec, id: number, n: number, type = "2"): void {
  const b = bag(rec, type);
  b[id] = Math.max(0, (b[id] ?? 0) + n);
  if (b[id] === 0) delete b[id];
  ctx.reply({ amount: `${type}_${id}_0_${n}` }, "onAmountUpdated");
}

/** The tree's day: from 6:00 to 6:00, China time (as the day of today() is). */
export function treeDay(ms: number): string {
  return chinaDay(ms - TREE_HOUR * 3600 * 1000);
}

export function installAreaFuncs(world: World, deps: AreaDeps): void {
  // ------------------------------------------------------------ 神奇摇摇树
  world.xt("SundriesExtension.70_34", async (ctx) => {
    const rec = await deps.load(ctx);
    ctx.reply({ num: area(rec).tree === treeDay(deps.now()) ? 0 : TREE_FRUIT });
  });
  world.xt("SundriesExtension.70_35", async (ctx) => {
    const rec = await deps.load(ctx);
    const day = treeDay(deps.now());
    if (area(rec).tree === day) return ctx.reply({ res: false });
    area(rec).tree = day;
    give(ctx, rec, TREE_ITEM, TREE_FRUIT);
    await deps.save(rec);
    ctx.reply({ res: true });
  });

  // ------------------------------------------------------------ 骑士王座
  const PA = "PeriodicActiveExtension";
  world.xt(`${PA}.knight_4`, async (ctx) => {
    const rec = await deps.load(ctx);
    ctx.reply({ res: area(rec).knightDay === deps.today() ? 1 : 0 });
  });
  world.xt(`${PA}.knight_5`, async (ctx) => {
    const rec = await deps.load(ctx);
    if (area(rec).knightDay === deps.today()) return ctx.reply({ suc: false });
    area(rec).knightDay = deps.today();
    give(ctx, rec, KNIGHT_CARD, KNIGHT_CARDS_A_DAY);
    await deps.save(rec);
    ctx.reply({ suc: true });
  });
  const firstKnight = (rec: AreaRec) => {
    const p = rec.pets?.[0];
    return p && p.race === KNIGHT_PET && p.level >= KNIGHT_LEVEL ? p : undefined;
  };
  world.xt(`${PA}.knight_1`, async (ctx) => {
    const rec = await deps.load(ctx);
    if (!firstKnight(rec) || (bag(rec)[KNIGHT_CARD] ?? 0) < KNIGHT_AUGURY_CARDS) return ctx.reply({ suc: false });
    give(ctx, rec, KNIGHT_CARD, -KNIGHT_AUGURY_CARDS);
    const race = KNIGHTS[Math.floor(Math.random() * KNIGHTS.length)];
    area(rec).knightSeen = race;
    await deps.save(rec);
    ctx.reply({ suc: true, res: race });
  });
  const becomeKnight = (ctx: XtContext, rec: AreaRec, pmId: number, race: number) => {
    const p = rec.pets?.find((x) => x.id === pmId);
    // Not in a fight (its 亚比 are the bag's own).
    if (inFight(world, (rec as { id?: number }).id ?? -1)) return false;
    if (!p || p.race !== KNIGHT_PET || p.level < KNIGHT_LEVEL || !KNIGHTS.includes(race)) return false;
    p.race = race;
    if (rec.followPet === p.id) world.setUserVarOnce(ctx.session, "p", followVar(p as PetRecord));
    return true;
  };
  world.xt(`${PA}.knight_2`, async (ctx) => {
    const rec = await deps.load(ctx);
    const race = area(rec).knightSeen ?? 0;
    const ok = becomeKnight(ctx, rec, Number(ctx.params.pmId) | 0, race);
    if (ok) {
      delete area(rec).knightSeen;
      await deps.save(rec);
    }
    ctx.reply({ suc: ok });
  });
  world.xt(`${PA}.knight_3`, async (ctx) => {
    const rec = await deps.load(ctx);
    if ((rec.xingbi ?? 0) < KNIGHT_XINGBI) return ctx.reply({ suc: false });
    const ok = becomeKnight(ctx, rec, Number(ctx.params.pmId) | 0, Number(ctx.params.raceId) | 0);
    if (ok) {
      rec.xingbi = (rec.xingbi ?? 0) - KNIGHT_XINGBI;
      ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
      await deps.save(rec);
    }
    ctx.reply({ suc: ok });
  });

  // ------------------------------------------------------------ 星愿气球
  const BW = "BalloonExtension";
  const balloons = async () => (await deps.get<BalloonStore>("area/balloon")) ?? { wishes: [], moods: [] };
  // The wishes and moods of everyone, one change at a time (two at once would lose one).
  const balloonTurn = serial();
  const updateBalloons = (f: (s: BalloonStore) => void) => {
    const change = (v: BalloonStore | undefined) => {
      const s = v ?? { wishes: [], moods: [] };
      f(s);
      return s;
    };
    return deps.update ? deps.update<BalloonStore>("area/balloon", change) : balloonTurn(async () => deps.set("area/balloon", change(await deps.get<BalloonStore>("area/balloon"))));
  };
  const pickOther = <T extends { dd: string }>(list: T[], me: string) => {
    const others = list.filter((x) => x.dd !== me);
    return others.length ? others[Math.floor(Math.random() * others.length)] : undefined;
  };
  world.xt(`${BW}.88_2`, async (ctx) => {
    const rec = await deps.load(ctx);
    const w = area(rec).wish;
    ctx.reply({ result: w && w.day === deps.today() ? w.wi : 0 });
  });
  world.xt(`${BW}.88_1`, async (ctx) => {
    const rec = await deps.load(ctx);
    const wi = Math.max(1, Math.min(6, Number(ctx.params.wi) | 0));
    if (area(rec).wish?.day === deps.today()) return;
    area(rec).wish = { day: deps.today(), wi };
    await deps.save(rec);
    const day = deps.today();
    await updateBalloons((s) => {
      s.wishes.push({ dd: rec.name, nn: rec.name, wi, day });
      s.wishes = s.wishes.slice(-BALLOON_KEEP);
    });
  });
  world.xt(`${BW}.88_10`, async (ctx) => {
    const rec = await deps.load(ctx);
    const content = String(ctx.params.content ?? "").slice(0, 50);
    if (!content || (rec.score ?? 0) < MOOD_PRICE) return;
    rec.score = (rec.score ?? 0) - MOOD_PRICE;
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    await deps.save(rec);
    const mood = { uid: rec.id, dd: rec.name, nn: rec.name, date: String(deps.now()), faceId: Number(ctx.params.faceId) | 0, content };
    await updateBalloons((s) => {
      s.moods.push(mood);
      s.moods = s.moods.slice(-BALLOON_KEEP);
    });
  });
  world.xt(`${BW}.88_4`, async (ctx) => {
    const w = pickOther((await balloons()).wishes, ctx.player.name);
    ctx.reply(w ? { suc: true, wi: w.wi, dd: w.dd, nn: w.nn } : { suc: false });
  });
  world.xt(`${BW}.88_9`, async (ctx) => {
    const m = pickOther((await balloons()).moods, ctx.player.name);
    ctx.reply(m ? { suc: true, mood: { uid: m.uid, date: m.date, faceId: m.faceId, content: m.content }, dd: m.dd, nn: m.nn } : { suc: false });
  });
  for (const cmd of ["88_5", "88_11"]) world.xt(`${BW}.${cmd}`, () => {});
  for (const cmd of ["88_3", "88_6", "88_7", "88_8"]) world.xt(`${BW}.${cmd}`, (ctx) => ctx.reply({ list: [] }));

  // ------------------------------------------------------------ 爱心协会
  const DE = "DonateExtension";
  const pool = async () => (await deps.get<DonateStore>("area/donate")) ?? { pool: 0, people: 0, donation: 0, takes: 0, names: [] };
  // The pool is everyone's: its changes one after another (on a server with several players two
  // takes at once would both have found it full).
  let poolTurn: Promise<unknown> = Promise.resolve();
  const inTurn = <T>(f: () => Promise<T>): Promise<T> => {
    const run = poolTurn.then(f, f);
    poolTurn = run.catch(() => undefined);
    return run;
  };
  const mine = (rec: AreaRec) => {
    const a = area(rec);
    if (!a.donate || a.donate.day !== deps.today()) a.donate = { day: deps.today(), n: 0, took: a.donate?.took, total: a.donate?.total ?? 0 };
    return a.donate;
  };
  world.xt(`${DE}.87_1`, async (ctx) => {
    const rec = await deps.load(ctx);
    const d = mine(rec);
    const type = Number(ctx.params.type) | 0;
    const id = Number(ctx.params.id) | 0;
    const num = Math.max(0, Number(ctx.params.num) | 0);
    if (d.n >= DONATE_PER_DAY) return ctx.reply({ result: 104, redFlower: false });
    let worth = 0;
    if (type === DONATE_MONEY) {
      if (num < DONATE_MIN || (rec.score ?? 0) < num) return ctx.reply({ result: 101, redFlower: false });
      rec.score = (rec.score ?? 0) - num;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      worth = num;
    } else {
      const owned = rec.items?.[String(type)]?.[String(id)] ?? 0;
      if (num < 1 || owned < num) return ctx.reply({ result: 101, redFlower: false });
      give(ctx, rec, id, -num, String(type));
    }
    d.n++;
    d.total += worth;
    await deps.save(rec);
    await inTurn(async () => {
      const s = await pool();
      s.pool += worth;
      s.donation += worth;
      s.people++;
      s.names = [rec.name, ...s.names.filter((n) => n !== rec.name)].slice(0, DONATE_NAMES);
      await deps.set("area/donate", s);
    });
    ctx.reply({ result: 1, redFlower: false });
  });
  world.xt(`${DE}.87_2`, async (ctx) => {
    const rec = await deps.load(ctx);
    const d = mine(rec);
    if (d.took === deps.today()) return ctx.reply({ result: 106 });
    if ((rec.score ?? 0) >= DONATE_RICH) return ctx.reply({ result: 107 });
    const took = await inTurn(async () => {
      const s = await pool();
      if (s.pool < DONATE_TAKE) return false;
      s.pool -= DONATE_TAKE;
      s.takes++;
      await deps.set("area/donate", s);
      return true;
    });
    if (!took) return ctx.reply({ result: 108 });
    d.took = deps.today();
    rec.score = (rec.score ?? 0) + DONATE_TAKE;
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    await deps.save(rec);
    ctx.reply({ result: 1 });
  });
  world.xt(`${DE}.87_3`, async (ctx) => {
    const s = await pool();
    ctx.reply({ donatePeople: s.people, donation: s.donation, takeCount: s.takes });
  });
  for (const cmd of ["87_4", "87_5"])
    world.xt(`${DE}.${cmd}`, async (ctx) => {
      const rec = await deps.load(ctx);
      ctx.reply({ ms: mine(rec).total });
    });
  world.xt(`${DE}.87_6`, async (ctx) => ctx.reply({ list: (await pool()).names.join(",") }));

  // ------------------------------------------------------------ HELLO技能学习
  const hello = (rec: AreaRec) => (area(rec).hello ??= { sc: [0, 0, 0], pt: [0, 0, 0], woken: [] });
  world.xt("RobotExtension.2-21", async (ctx) => {
    const rec = await deps.load(ctx);
    const type = Number(ctx.params.type) | 0;
    const score = Math.max(0, Number(ctx.params.score) | 0);
    if (type < 1 || type > 3) return ctx.reply({ pt: 0 });
    const h = hello(rec);
    const pt = HELLO_POINTS[helloGrade(score)];
    h.sc[type - 1] = Math.max(h.sc[type - 1], score);
    h.pt[type - 1] += pt;
    await deps.save(rec);
    ctx.reply({ pt });
  });
  world.xt("RobotExtension.2-20", async (ctx) => {
    const rec = await deps.load(ctx);
    const h = hello(rec);
    ctx.reply({ sc: h.sc.join(","), pt: h.pt.join(",") });
  });
  world.xt("RobotExtension.2-22", async (ctx) => {
    const rec = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    const need = HELLO_SKILLS[id];
    const h = hello(rec);
    if (!need) return ctx.reply({ result: -2 });
    if (h.woken.includes(id)) return ctx.reply({ result: -4 });
    if (need[0].some((n, i) => h.pt[i] < n)) return ctx.reply({ result: -2 });
    const min = HELLO_GRADES.find(([, g]) => g === need[1][1])![0];
    if (h.sc[need[1][0] - 1] < min) return ctx.reply({ result: -3 });
    h.woken.push(id);
    await deps.save(rec);
    ctx.reply({ result: 1 });
  });

  // ------------------------------------------------------------ 职业亚比进化
  // The same command evolves the 小独角兽 (planetacts.ts, installed before): other 亚比 go there.
  const unicorn = world.handlers?.get("PetExtension2.54e_1");
  world.xt("PetExtension2.54e_1", async (ctx, cmd) => {
    const rec = await deps.load(ctx);
    const p = rec.pets?.find((x) => x.id === (Number(ctx.params.pid) | 0));
    if (unicorn && !(p && UNION_FORMS[p.race])) return unicorn(ctx, cmd);
    const form = p ? UNION_FORMS[p.race]?.[(Number(ctx.params.t) | 0) - 1] : undefined;
    if (!p || !form || (bag(rec)[form[0]] ?? 0) < 1) return ctx.reply({ res: -1 });
    give(ctx, rec, form[0], -1);
    p.race = form[1];
    if (rec.followPet === p.id) world.setUserVarOnce(ctx.session, "p", followVar(p as PetRecord));
    await deps.save(rec);
    ctx.reply({ res: 0 });
  });

  // ------------------------------------------------------------ 小白吐获得
  const bottle = (rec: AreaRec) => {
    const a = area(rec);
    if (!a.bottle || a.bottle.day !== deps.today()) a.bottle = { day: deps.today(), n: 0 };
    return a.bottle;
  };
  world.xt(`${PA}.s_s_1`, async (ctx) => {
    const rec = await deps.load(ctx);
    ctx.reply({ res: bottle(rec).n });
  });
  world.xt(`${PA}.s_s_2`, async (ctx) => {
    const rec = await deps.load(ctx);
    const b = bottle(rec);
    const c = Math.min(Number(ctx.params.c) | 0, bag(rec)[SWEET_ITEM] ?? 0, SWEETS_FOR_PET - b.n);
    if (c <= 0) return ctx.reply({ res: false });
    give(ctx, rec, SWEET_ITEM, -c);
    b.n += c;
    let full = false;
    if (b.n >= SWEETS_FOR_PET && deps.pets) {
      const t = await deps.pets();
      const pet = newPet(rec as never, t, XIAOBAITU, 1, deps.today()) as PetRecord;
      if ((rec.pets ??= []).length < 6) {
        rec.pets.push(pet);
        ctx.reply({ pm: detailOf(pet, rec as never, t) }, "2201");
      } else (rec.storage ??= []).push(pet);
      full = true;
    }
    await deps.save(rec);
    ctx.reply({ res: full });
  });

  // ------------------------------------------------------------ 道馆
  const gym = (rec: AreaRec) => {
    const a = area(rec);
    if (!a.gym) a.gym = { day: deps.today(), pb: false, pt: false, s: 0, water: 0, fire: 0 };
    if (a.gym.day !== deps.today()) Object.assign(a.gym, { day: deps.today(), pb: false, pt: false, coinsToday: 0, waterToday: 0, fireToday: 0 });
    return a.gym;
  };
  /** What a game may still pay today: at most `perGame`, and GYM_GAMES_PER_DAY games' worth a day. */
  const payable = (asked: number, perGame: number, paid: number | undefined) => Math.max(0, Math.min(asked, perGame, perGame * GYM_GAMES_PER_DAY - (paid ?? 0)));
  const payShop = async (ctx: XtContext, rec: AreaRec, kind: number, shop = GYM_SHOP) => {
    const [type, id, num] = shop[kind];
    if (type === 100) {
      rec.score = (rec.score ?? 0) + num;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
    } else if (type === 101) {
      // 经验: for the first 亚比 of the bag, as the panels' other rewards of experience.
      const p = rec.pets?.[0] as PetRecord | undefined;
      if (p && deps.pets) for (const [c, b] of gainExp(await deps.pets(), p, num).msgs) ctx.reply(b, c);
    } else give(ctx, rec, id, num, String(type));
    return [{ type, id, num }];
  };
  world.xt(`${PA}.20121112_checkstone`, async (ctx) => {
    const g = gym(await deps.load(ctx));
    ctx.reply({ pb: g.pb, pt: g.pt, s: g.s });
  });
  world.xt(`${PA}.20121112_getbonus`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = gym(rec);
    const m = payable(Math.max(0, Number(ctx.params.n) | 0) * GYM_HIT_COINS, GYM_GAME_COINS, g.coinsToday);
    g.coinsToday = (g.coinsToday ?? 0) + m;
    const first = !g.pb;
    if (first) {
      g.pb = true;
      g.s = Math.min(3, g.s + 1);
    }
    if (m > 0) {
      rec.score = (rec.score ?? 0) + m;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
    }
    await deps.save(rec);
    ctx.reply({ m, f: first, s: 1 });
  });
  world.xt(`${PA}.20121112_getstone`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = gym(rec);
    if (g.s < 3) return ctx.reply({ res: false });
    g.s = 0;
    give(ctx, rec, THUNDER_STONE, 1);
    await deps.save(rec);
    ctx.reply({ res: true });
  });
  world.xt(`${PA}.20121116water_score1`, async (ctx) => ctx.reply({ score: gym(await deps.load(ctx)).water }));
  world.xt(`${PA}.20121116water_score2`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = gym(rec);
    const got = payable(Math.max(0, Number(ctx.params.num) | 0), GYM_GAME_SCORE, g.waterToday);
    g.waterToday = (g.waterToday ?? 0) + got;
    g.water += got;
    await deps.save(rec);
  });
  world.xt(`${PA}.20121116water_score3`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = gym(rec);
    const kind = Number(ctx.params.index) | 0;
    if (!GYM_SHOP[kind] || g.water < WATER_COST[kind]) return ctx.reply({ bn: null, score: g.water });
    g.water -= WATER_COST[kind];
    const bn = kind === 5 ? (give(ctx, rec, GYM_SHOP[5][1], 1), true) : await payShop(ctx, rec, kind);
    await deps.save(rec);
    ctx.reply({ bn, score: g.water });
  });
  world.xt(`${PA}.Fire_8`, async (ctx) => ctx.reply({ score: gym(await deps.load(ctx)).fire }));
  world.xt(`${PA}.Fire_5`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = gym(rec);
    const got = payable(Math.max(0, Number(ctx.params.score) | 0), GYM_GAME_SCORE * 10, g.fireToday);
    g.fireToday = (g.fireToday ?? 0) + got;
    g.fire += got;
    await deps.save(rec);
    ctx.reply({ score: g.fire });
  });
  world.xt(`${PA}.Fire_6`, async (ctx) => {
    const rec = await deps.load(ctx);
    const g = gym(rec);
    const kind = Number(ctx.params.id ?? ctx.params.index) | 0;
    if (!FIRE_SHOP[kind] || g.fire < FIRE_COST[kind]) return ctx.reply({ suc: false, bn: [] });
    g.fire -= FIRE_COST[kind];
    const bn = await payShop(ctx, rec, kind, FIRE_SHOP);
    await deps.save(rec);
    ctx.reply({ suc: true, bn });
  });
  // Opening the others. (雷霆之塔's run and rank, the 踢馆's stones and 幻冥's 命运 are gyms.ts's.)
  const empty: Record<string, Record<string, unknown>> = {
    "20121112_lookbonus": { c: 0, p: "0,0,0,0" },
    "2012113_tbo": { bn: [] },
    "20121113_htop": { l: "" },
    Fire_10: { res: false, recent: "" },
    "20121116water_c1": { res: false, top10: "" },
    "20121116water_e1": {},
    Dark_3: { turn: 0, pet: false },
    Dark_4: { status: -1, cd: 0 },
    Dark_6: { recent: "" },
    "20121123light_E1": { enter: true },
    "20121123light_C1": { top: "" },
    "20121123light_F1": { friend: "" },
    "20121123light_G1": { score: 0, friend: "0:0:0:0:0", got: false },
    Fire_1: { acc: 0, highest: 0, rank: 0, flag: 0 },
    Fire_2: { num: 0 },
  };
  for (const [cmd, reply] of Object.entries(empty)) world.xt(`${PA}.${cmd}`, (ctx) => ctx.reply(structuredClone(reply)));

  // ------------------------------------------------------------ 银河商会
  world.xt("GalaxyExtension.105_4", (ctx) => ctx.reply({ card: -1 }));

  // ------------------------------------------------------------ 亚比成长计划
  const HE = "HolidayExtension.121109_";
  const grow = (rec: AreaRec) => (area(rec).grow ??= { pet: -1, step: 0, taken: false, next: 0, count: 0, flag: 0 });
  const growView = (rec: AreaRec) => {
    const g = grow(rec);
    return { step: g.step, taken: g.taken, cd: Math.max(0, Math.ceil((g.next - deps.now()) / 1000)), done: g.step >= GROW_STEPS };
  };
  world.xt(HE + "02", async (ctx) => ctx.reply({ petId: grow(await deps.load(ctx)).pet }));
  world.xt(HE + "06", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = grow(rec);
    const id = Number(ctx.params.petId) | 0;
    if (id === -1) Object.assign(g, { pet: -1, step: 0, taken: false, next: 0 });
    else {
      if (!rec.pets?.some((p) => p.id === id)) return ctx.reply({ suc: false });
      if (g.step >= GROW_STEPS) Object.assign(g, { step: 0, taken: false, next: 0 });
      g.pet = id;
    }
    await deps.save(rec);
    ctx.reply({ suc: true });
  });
  world.xt(HE + "03", async (ctx) => ctx.reply(growView(await deps.load(ctx))));
  world.xt(HE + "07", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = grow(rec);
    if (g.pet === -1 || g.step >= GROW_STEPS || g.next > deps.now()) return ctx.reply({ suc: false });
    g.taken = true;
    await deps.save(rec);
    ctx.reply({ suc: true });
  });
  world.xt(HE + "04", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = grow(rec);
    const p = rec.pets?.find((x) => x.id === g.pet) ?? rec.storage?.find((x) => x.id === g.pet);
    if (!g.taken || !p || g.step >= GROW_STEPS) return ctx.reply({ suc: false, bn: [], level: p?.level ?? 0, step: g.step });
    const done = g.step;
    p.level = Math.min(100, p.level + GROW_LEVELS);
    p.exp = 0;
    g.step++;
    g.taken = false;
    g.next = deps.now() + GROW_WAIT * 1000;
    if (g.step >= GROW_STEPS) g.count++;
    await deps.save(rec);
    ctx.reply({ suc: true, bn: [], level: p.level, step: done });
  });
  world.xt(HE + "08", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = grow(rec);
    // The price the panel shows, but never less than 1 晶币 a minute still to wait (a client
    // that asks 0 does not skip the wait for nothing; RECONSTRUCTED floor).
    const left = g.next - deps.now();
    if (left <= 0) return ctx.reply({ res: 1 });
    const num = Math.max(Math.max(0, Number(ctx.params.num) | 0), Math.ceil(left / 60000));
    if ((rec.score ?? 0) < num) return ctx.reply({ res: 0 });
    rec.score = (rec.score ?? 0) - num;
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    g.next = 0;
    await deps.save(rec);
    ctx.reply({ res: 1 });
  });
  world.xt(HE + "01", async (ctx) => {
    const g = grow(await deps.load(ctx));
    ctx.reply({ count: g.count, flag: g.flag });
  });
  world.xt(HE + "05", async (ctx) => {
    const rec = await deps.load(ctx);
    const g = grow(rec);
    const id = Number(ctx.params.id) | 0;
    const gift = GROW_GIFTS[id];
    if (!gift || g.count < GROW_RUNS[id] || g.flag & (1 << id)) return ctx.reply({ suc: false, bn: [] });
    g.flag |= 1 << id;
    const [type, mid, num] = gift;
    if (type === 100) {
      rec.score = (rec.score ?? 0) + num;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
    } else if (type === 2) give(ctx, rec, mid, num);
    await deps.save(rec);
    ctx.reply({ suc: true, bn: [{ type, id: mid, num }] });
  });

  // ------------------------------------------------------------ 蓝宝石礼包派送
  world.xt("GiftBagExtension.68_6", async (ctx) => {
    const rec = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    ctx.reply({ res: 1, id, s: area(rec).weekGift === weekOf(deps.today()) ? 1 : 0 });
  });
  world.xt("GiftBagExtension.68_7", async (ctx) => {
    const rec = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    const gift = WEEK_GIFTS[id];
    if (!gift) return ctx.reply({ res: 10, id });
    // The 蓝宝石's weekly gift: members only (the 工具箱's 成为蓝宝石).
    if (!(rec as { vip?: boolean }).vip) return ctx.reply({ res: 0, id });
    const week = weekOf(deps.today());
    if (area(rec).weekGift === week) return ctx.reply({ res: 3, id });
    area(rec).weekGift = week;
    const [item, n, coins, exp] = gift;
    if (item) give(ctx, rec, item, n);
    rec.score = (rec.score ?? 0) + coins;
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    if (rec.robot) rec.robot.exp = (rec.robot.exp ?? 0) + exp;
    await deps.save(rec);
    ctx.reply({ res: 1, id });
  });

  // ------------------------------------------------------------ 欢乐券兑换
  const armour = world.handlers?.get("SynthesizeExtension.57_8");
  world.xt("SynthesizeExtension.57_8", async (ctx, cmd) => {
    const id = Number(ctx.params.id) | 0;
    const goods = TICKET_GOODS[id];
    if (!goods) return armour ? armour(ctx, cmd) : ctx.reply({ res: 0 });
    const rec = await deps.load(ctx);
    const [type, mid, price] = goods;
    const num = type === 0 || type === 102 ? 1 : Math.max(1, Math.min(99, Number(ctx.params.num) | 0));
    if ((bag(rec)[TICKET_ITEM] ?? 0) < price * num) return ctx.reply({ res: 0 });
    if (type === 0 && rec.items?.["0"]?.[mid]) return ctx.reply({ res: 0 });
    give(ctx, rec, TICKET_ITEM, -price * num);
    if (type === 102) {
      if (!deps.pets) return ctx.reply({ res: 0 });
      const t = await deps.pets();
      const pet = newPet(rec as never, t, mid, 5, deps.today()) as PetRecord;
      if ((rec.pets ??= []).length < 6) {
        rec.pets.push(pet);
        ctx.reply({ pm: detailOf(pet, rec as never, t) }, "2201");
      } else (rec.storage ??= []).push(pet);
    } else give(ctx, rec, mid, num, String(type));
    await deps.save(rec);
    ctx.reply({ res: 1 });
  });
}
