// 武神大陆 (the 武神战争 of 2012, scenes fightkingwar1–9) for the 2013 server: the era panels of
// fightkingwar/ (September 2012: 武神战争 and 将军榜, 关羽, 赵云, 张飞, 诸葛亮; 吕布 and 刘备 in their
// copies of 2014) and the 黄巾军旗 of 恶人山道 (activityres/wushenyangcheng, May 2012). Their commands:
//
// 将军令 (GeneralOrderTimesService; "每天可使用将军令5次", "全属性提升1级 体力+200"):
//   HolidayExtension 20120921_warrior1 {} -> {times}   将军令 left today
//   a general's fight with token true uses one: the 亚比 that fights has every stat one stage up
//   and 200 more 体力
// 黄巾军旗 (PeriodicActiveExtension; 黄巾战魂 item 509, "在恶人山道击败黄巾小兵就有几率获得黄巾战魂";
// planetacts.ts WILD_DROPS gives one a win):
//   w_soul_2 {} -> {lt, left, right, doo}   the cooling seconds, 张角's and 张梁's energy (0–10),
//                                           the day's 战魂赠礼 taken (1)
//   w_soul_1 {} -> {lt}
//   w_soul_3 {t} -> {res, nx}   "每次注入能量需要5个战魂": 5 战魂 into 张角 (0) or 张梁 (1), then a while
//                               to wait (res 0 done, nx the energy now)
//   w_soul_4 {} -> {res}        the wait cleared with 星币 (a 星币 a minute left, as the panel counts it)
//   w_soul_5 {} -> {r}          "每天都可以领取10个战魂"
//   w_soul_6 {t, pi} -> {res}   "注满能量后，能将20级的黄巾小兵进化为黄巾勇士": a 黄巾小兵 (853) of
//                               Lv20 or more becomes 张角 (854) or 张梁 (855), back to Lv1
// The generals (54_22 {type, id, token}, battle.ts addActFight), each "每天可挑战…5次" but 关羽, whose
// fights cost 10 黄巾战魂 ("挑战关羽需要消耗10个黄巾战魂"); their eggs go into the 亚比孵化器:
//   关羽 28 {id 0–2}: the 狂, 暴 and 怒 seals; w_soul_7 -> {res: "s0,s1,s2,got"}; w_soul_8 {id}
//        clears a seal for 30, 50 or 100 星币; w_soul_9 the egg (860) once the three are cleared
//   赵云 32 {id 0–1}: 银龙枪 and 青龙剑; w_soul_10 -> {times, fight1, fight2, got}; w_soul_11 {id}
//        -> {res} (30, 90 星币; 101 too few); w_soul_12 -> {suc} the egg (929)
//   张飞 72 {id 0–1}: 电闪咒印 and 雷鸣咒印; w_soul_13 / 14 (30, 90 星币) / 15 the egg (953)
//   诸葛亮 71: PetExtension 54_30 {id} -> {chance (-1: got), awaked}; 54_31 {id} -> {id, suc} 120
//        星币; a win (the panel waits for 10976) gives the egg (974)
//   吕布 40: w_soul_16 -> {chance}; w_soul_17 -> {id, suc} 120 星币; a win gives the egg (1106)
//   刘备 70: HolidayExtension 20120921_warrior2 -> {times}; _warrior3 -> {win, times (将军令)};
//        _warrior4 -> {res} 150 星币; a win gives the egg (1223)
// 将军榜: PetExtension2 54e_25 {} -> {res: "a:b:…"}   which of 张梁, 张角, 关羽, 赵云, 张飞, 诸葛亮, 吕布,
//        刘备 (the panel's stamps mc0–mc7) one has (a 亚比 of its line)
// 刘备's 见面礼 (蜀中平原, the scene's btnNpc): GiftBagExtension 68_4 {id: 544} -> {res} (1: not yet
//        taken: 刘备 talks first), 68_5 {id: 544} -> {res} 700 晶币 and 1000 经验 (the scene's own
//        showGetMoneyAndExpPanel(700, 1000); the 经验 the HELLO's, as quests give it)
//
// The 2012 server is lost: the generals' levels are the 将军榜's 战斗力 (关羽 90, 赵云 90, 张飞 89,
// 诸葛亮 95, 吕布 99, 刘备 100), the wait between two 注入 and the 黄巾小兵's drops are RECONSTRUCTED;
// 诸葛亮 fights alone (the panel's "战胜诸葛亮和迷雾龙": the revival's battles are one against one).

import { inFight } from "./fighting.ts";
import { addActFight, type Battle, type Msg } from "./battle.ts";
import type { PetOwner, PetRecord } from "./pets.ts";
import type { World, XtContext } from "./server.ts";
import { eggNow } from "./sevenstar.ts";

export const WAR_SOUL = 509;
export const ORDERS_PER_DAY = 5;
export const TRIES_PER_DAY = 5;
export const FLAG_WAIT_MS = 30 * 60 * 1000;
export const FLAG_GIFT = 10;
export const FLAG_COST = 5;
export const FLAG_FULL = 10;
export const GUANYU_COST = 10;

export const GENERALS = {
  guanyu: { type: 28, race: 860, level: 90, egg: 860, prices: [30, 50, 100] },
  zhaoyun: { type: 32, race: 931, level: 90, egg: 929, prices: [30, 90] },
  zhangfei: { type: 72, race: 955, level: 89, egg: 953, prices: [30, 90] },
  zhuge: { type: 71, race: 976, level: 95, egg: 974, price: 120, asked: 10976 },
  lubu: { type: 40, race: 1108, level: 99, egg: 1106, price: 120 },
  liubei: { type: 70, race: 1225, level: 100, egg: 1223, price: 150 },
};
/** 将军榜's stamps: the lines of 张梁, 张角, 关羽, 赵云, 张飞, 诸葛亮, 吕布, 刘备. */
export const GENERAL_LINES = [[855], [854], [858, 859, 860], [929, 930, 931], [953, 954, 955], [974, 975, 976], [1106, 1107, 1108], [1223, 1224, 1225]];

interface TwoFights {
  day?: string;
  tries?: number;
  won?: boolean[];
  got?: boolean;
}

/** The scenes' gift bags (GiftBagClient): 刘备's 见面礼. */
export const GIFT_BAGS: Record<number, { score: number; exp: number }> = { 544: { score: 700, exp: 1000 } };

export interface WushenRec {
  /** Gift bags taken (GIFT_BAGS). */
  bags?: number[];
  orders?: { day: string; used: number };
  flag?: { until?: number; bars?: number[]; gift?: string };
  guanyu?: { seals?: boolean[]; got?: boolean };
  zhaoyun?: TwoFights;
  zhangfei?: TwoFights;
  zhuge?: TwoFights;
  lubu?: TwoFights;
  liubei?: TwoFights;
}

export interface WushenOwner extends PetOwner {
  xingbi?: number;
  score?: number;
  robot?: { exp: number };
  helloExp?: number;
  items?: Record<string, Record<string, number>>;
  wushen?: WushenRec;
}

export interface WushenDeps {
  me(ctx: XtContext): Promise<WushenOwner>;
  save(o: WushenOwner): Promise<void>;
  today(): string;
  now(): number;
}

const recOf = (o: WushenOwner) => (o.wushen ??= {});
const soulsOf = (o: WushenOwner) => o.items?.["2"]?.[String(WAR_SOUL)] ?? 0;
function addSouls(o: WushenOwner, n: number): Msg[] {
  const bag = ((o.items ??= {})["2"] ??= {});
  bag[String(WAR_SOUL)] = Math.max(0, (bag[String(WAR_SOUL)] ?? 0) + n);
  return [["onAmountUpdated", { amount: `2_${WAR_SOUL}_0_${n}` }]];
}

export function installFightKing(world: World, deps: WushenDeps): void {
  const H = "HolidayExtension";
  const P = "PeriodicActiveExtension";
  const reply = (ctx: XtContext, cmd: string, body: Record<string, unknown>, msgs: Msg[] = []) => {
    for (const [c, b] of msgs) ctx.reply(b, c);
    ctx.reply(body, cmd);
  };
  const pay = (o: WushenOwner, n: number): Msg[] | null => {
    if ((o.xingbi ?? 0) < n) return null;
    o.xingbi = (o.xingbi ?? 0) - n;
    return [["onXingBiUpdate", { xingbi: o.xingbi }]];
  };

  // 将军令
  const ordersLeft = (o: WushenOwner) => {
    const r = recOf(o).orders;
    return ORDERS_PER_DAY - (r?.day === deps.today() ? r.used : 0);
  };
  /** A fight with token true: one 将军令 used, and its blessing on the fighting 亚比. */
  const order = (o: WushenOwner, ctx: XtContext): ((b: Battle) => void) | undefined => {
    if (ctx.params.token !== true && String(ctx.params.token) !== "true") return undefined;
    if (ordersLeft(o) <= 0) return undefined;
    const r = recOf(o);
    r.orders = { day: deps.today(), used: (r.orders?.day === deps.today() ? r.orders.used : 0) + 1 };
    return (b) => {
      for (const k of ["atk", "def", "satk", "sdef", "spd"] as const) b.mine.stages[k] = Math.min(6, (b.mine.stages[k] ?? 0) + 1);
      b.mine.stats = b.mine.stats.slice();
      b.mine.stats[0] += 200;
      b.mine.pet.hp += 200;
    };
  };
  world.xt(`${H}.20120921_warrior1`, async (ctx) => {
    ctx.reply({ times: Math.max(0, ordersLeft(await deps.me(ctx))) }, "20120921_warrior1");
  });

  // 黄巾军旗
  const flagOf = (o: WushenOwner) => {
    const f = (recOf(o).flag ??= {});
    f.bars ??= [0, 0];
    return f as { until?: number; bars: number[]; gift?: string };
  };
  const waitLeft = (o: WushenOwner) => Math.max(0, Math.ceil(((flagOf(o).until ?? 0) - deps.now()) / 1000));
  world.xt(`${P}.w_soul_1`, async (ctx) => {
    ctx.reply({ lt: waitLeft(await deps.me(ctx)) }, "w_soul_1");
  });
  world.xt(`${P}.w_soul_2`, async (ctx) => {
    const o = await deps.me(ctx);
    const f = flagOf(o);
    ctx.reply({ lt: waitLeft(o), left: f.bars[0], right: f.bars[1], doo: f.gift === deps.today() ? 1 : 0 }, "w_soul_2");
  });
  world.xt(`${P}.w_soul_3`, async (ctx) => {
    const o = await deps.me(ctx);
    const f = flagOf(o);
    const t = Math.max(0, Math.min(1, Number(ctx.params.t) | 0));
    if (waitLeft(o) > 0 || soulsOf(o) < FLAG_COST || f.bars[t] >= FLAG_FULL) return ctx.reply({ res: 1 }, "w_soul_3");
    const msgs = addSouls(o, -FLAG_COST);
    f.bars[t] += 1;
    f.until = deps.now() + FLAG_WAIT_MS;
    await deps.save(o);
    reply(ctx, "w_soul_3", { res: 0, nx: f.bars[t] }, msgs);
  });
  world.xt(`${P}.w_soul_4`, async (ctx) => {
    const o = await deps.me(ctx);
    const left = waitLeft(o);
    if (left <= 0) return ctx.reply({ res: 1 }, "w_soul_4");
    const paid = pay(o, Math.floor(left / 60) + 1);
    if (!paid) return ctx.reply({ res: 0 }, "w_soul_4");
    flagOf(o).until = 0;
    await deps.save(o);
    reply(ctx, "w_soul_4", { res: 1 }, paid);
  });
  world.xt(`${P}.w_soul_5`, async (ctx) => {
    const o = await deps.me(ctx);
    const f = flagOf(o);
    if (f.gift === deps.today()) return ctx.reply({ r: false }, "w_soul_5");
    f.gift = deps.today();
    const msgs = addSouls(o, FLAG_GIFT);
    await deps.save(o);
    reply(ctx, "w_soul_5", { r: true }, msgs);
  });
  world.xt(`${P}.w_soul_6`, async (ctx) => {
    const o = await deps.me(ctx);
    const f = flagOf(o);
    const t = Math.max(0, Math.min(1, Number(ctx.params.t) | 0));
    const pet = (o.pets ?? []).find((p) => p.id === (Number(ctx.params.pi) | 0)) as PetRecord | undefined;
    if (!pet || pet.race !== 853 || pet.level < 20 || f.bars[t] < FLAG_FULL || inFight(world, (o as { id?: number }).id ?? -1)) return ctx.reply({}, "w_soul_6");
    pet.race = t === 0 ? 854 : 855;
    pet.level = 1;
    pet.exp = 0;
    f.bars[t] = 0;
    await deps.save(o);
    ctx.reply({ res: 1 }, "w_soul_6");
  });

  // Two fights a general (赵云, 张飞) or one (诸葛亮, 吕布, 刘备): the day's tries.
  const triesLeft = (r: TwoFights) => TRIES_PER_DAY - (r.day === deps.today() ? (r.tries ?? 0) : 0);
  const tryOne = (r: TwoFights) => {
    r.tries = (r.day === deps.today() ? (r.tries ?? 0) : 0) + 1;
    r.day = deps.today();
  };
  const gen = (o: WushenOwner, key: "zhaoyun" | "zhangfei" | "zhuge" | "lubu" | "liubei") => ((recOf(o)[key] ??= {}) as TwoFights);

  // 关羽
  const guanyu = (o: WushenOwner) => {
    const g = (recOf(o).guanyu ??= {});
    g.seals ??= [false, false, false];
    return g as { seals: boolean[]; got?: boolean };
  };
  world.xt(`${P}.w_soul_7`, async (ctx) => {
    const g = guanyu(await deps.me(ctx));
    ctx.reply({ res: [...g.seals.map((s) => (s ? 1 : 0)), g.got ? 1 : 0].join(",") }, "w_soul_7");
  });
  world.xt(`${P}.w_soul_8`, async (ctx) => {
    const o = await deps.me(ctx);
    const id = Math.max(0, Math.min(2, Number(ctx.params.id) | 0));
    const g = guanyu(o);
    if (g.seals[id]) return ctx.reply({ res: 0 }, "w_soul_8");
    const paid = pay(o, GENERALS.guanyu.prices[id]);
    if (!paid) return ctx.reply({ res: 101 }, "w_soul_8");
    g.seals[id] = true;
    await deps.save(o);
    reply(ctx, "w_soul_8", { res: 1 }, paid);
  });
  world.xt(`${P}.w_soul_9`, async (ctx) => {
    const o = await deps.me(ctx);
    const g = guanyu(o);
    if (g.got || !g.seals.every(Boolean)) return ctx.reply({ res: 0 }, "w_soul_9");
    g.got = true;
    const msgs = eggNow(o, GENERALS.guanyu.egg);
    await deps.save(o);
    reply(ctx, "w_soul_9", { res: 1 }, msgs);
  });
  addActFight(world, GENERALS.guanyu.type, async (ctx, owner) => {
    const o = owner as WushenOwner;
    const id = Math.max(0, Math.min(2, Number(ctx.params.id) | 0));
    if (guanyu(o).seals[id]) return "你已经打通这个封印了！";
    if (soulsOf(o) < GUANYU_COST) return "挑战关羽需要消耗10个黄巾战魂，再去消灭黄巾小兵，收集战魂吧！";
    const msgs = addSouls(o, -GUANYU_COST);
    const adjust = order(o, ctx);
    await deps.save(o);
    for (const [c, b] of msgs) ctx.reply(b, c);
    return { race: GENERALS.guanyu.race, level: GENERALS.guanyu.level, adjust, onWin: (w) => ((guanyu(w as WushenOwner).seals[id] = true), []) };
  });

  // 赵云 and 张飞: two fights each, then the egg.
  for (const [key, cmds] of [["zhaoyun", ["w_soul_10", "w_soul_11", "w_soul_12"]], ["zhangfei", ["w_soul_13", "w_soul_14", "w_soul_15"]]] as const) {
    const g = GENERALS[key];
    const two = (o: WushenOwner) => {
      const r = gen(o, key);
      r.won ??= [false, false];
      return r as TwoFights & { won: boolean[] };
    };
    world.xt(`${P}.${cmds[0]}`, async (ctx) => {
      const r = two(await deps.me(ctx));
      ctx.reply({ times: Math.max(0, triesLeft(r)), fight1: r.won[0], fight2: r.won[1], got: !!r.got }, cmds[0]);
    });
    world.xt(`${P}.${cmds[1]}`, async (ctx) => {
      const o = await deps.me(ctx);
      const id = Math.max(0, Math.min(1, Number(ctx.params.id) | 0));
      const r = two(o);
      if (r.won[id]) return ctx.reply({ res: 0 }, cmds[1]);
      const paid = pay(o, g.prices[id]);
      if (!paid) return ctx.reply({ res: 101 }, cmds[1]);
      r.won[id] = true;
      await deps.save(o);
      reply(ctx, cmds[1], { res: 1 }, paid);
    });
    world.xt(`${P}.${cmds[2]}`, async (ctx) => {
      const o = await deps.me(ctx);
      const r = two(o);
      if (r.got || !r.won.every(Boolean)) return ctx.reply({ suc: false }, cmds[2]);
      r.got = true;
      const msgs = eggNow(o, g.egg);
      await deps.save(o);
      reply(ctx, cmds[2], { suc: true }, msgs);
    });
    addActFight(world, g.type, async (ctx, owner) => {
      const o = owner as WushenOwner;
      const id = Math.max(0, Math.min(1, Number(ctx.params.id) | 0));
      const r = two(o);
      if (r.won[id]) return "你已经战胜它了！";
      if (triesLeft(r) <= 0) return "你今天已经没有挑战机会了，明天再来吧！";
      tryOne(r);
      const adjust = order(o, ctx);
      await deps.save(o);
      return { race: g.race, level: g.level, adjust, onWin: (w) => ((two(w as WushenOwner).won[id] = true), []) };
    });
  }

  // 诸葛亮, 吕布 and 刘备: one fight, its win the egg.
  const single = (key: "zhuge" | "lubu" | "liubei") => {
    const g = GENERALS[key];
    addActFight(world, g.type, async (ctx, owner) => {
      const o = owner as WushenOwner;
      const r = gen(o, key);
      if (r.got) return "你已经降伏它，获得它的亚比蛋了！";
      if (triesLeft(r) <= 0) return "你今天已经没有挑战机会了，明天再来吧！";
      tryOne(r);
      const adjust = order(o, ctx);
      await deps.save(o);
      return {
        race: g.race,
        level: g.level,
        asked: (g as { asked?: number }).asked,
        adjust,
        onWin: (w) => {
          const rr = gen(w as WushenOwner, key);
          if (rr.got) return [];
          rr.got = true;
          return eggNow(w as WushenOwner, g.egg);
        },
      };
    });
    /** The egg for 星币: the messages, or null. */
    return async (o: WushenOwner): Promise<Msg[] | null> => {
      const r = gen(o, key);
      if (r.got) return null;
      const paid = pay(o, g.price);
      if (!paid) return null;
      r.got = true;
      return [...paid, ...eggNow(o, g.egg)];
    };
  };
  const buyZhuge = single("zhuge");
  const buyLubu = single("lubu");
  const buyLiubei = single("liubei");

  world.xt("PetExtension.54_30", async (ctx) => {
    const r = gen(await deps.me(ctx), "zhuge");
    ctx.reply({ chance: r.got ? -1 : Math.max(0, triesLeft(r)), awaked: !!r.got }, "54_30");
  });
  world.xt("PetExtension.54_31", async (ctx) => {
    const o = await deps.me(ctx);
    const msgs = await buyZhuge(o);
    if (msgs) await deps.save(o);
    reply(ctx, "54_31", { id: Number(ctx.params.id) | 0, suc: !!msgs }, msgs ?? []);
  });
  world.xt(`${P}.w_soul_16`, async (ctx) => {
    const r = gen(await deps.me(ctx), "lubu");
    ctx.reply({ chance: r.got ? -1 : Math.max(0, triesLeft(r)) }, "w_soul_16");
  });
  world.xt(`${P}.w_soul_17`, async (ctx) => {
    const o = await deps.me(ctx);
    const msgs = await buyLubu(o);
    if (msgs) await deps.save(o);
    reply(ctx, "w_soul_17", { id: 0, suc: !!msgs }, msgs ?? []);
  });
  world.xt(`${H}.20120921_warrior2`, async (ctx) => {
    ctx.reply({ times: Math.max(0, triesLeft(gen(await deps.me(ctx), "liubei"))) }, "20120921_warrior2");
  });
  world.xt(`${H}.20120921_warrior3`, async (ctx) => {
    const o = await deps.me(ctx);
    ctx.reply({ win: !!gen(o, "liubei").got, times: Math.max(0, ordersLeft(o)) }, "20120921_warrior3");
  });
  world.xt(`${H}.20120921_warrior4`, async (ctx) => {
    const o = await deps.me(ctx);
    const msgs = await buyLiubei(o);
    if (msgs) await deps.save(o);
    reply(ctx, "20120921_warrior4", { res: msgs ? 1 : 0 }, msgs ?? []);
  });

  // 刘备's 见面礼
  world.xt("GiftBagExtension.68_4", async (ctx) => {
    const id = Number(ctx.params.id) | 0;
    const o = await deps.me(ctx);
    ctx.reply({ res: GIFT_BAGS[id] && !(recOf(o).bags ?? []).includes(id) ? 1 : 0 }, "68_4");
  });
  world.xt("GiftBagExtension.68_5", async (ctx) => {
    const id = Number(ctx.params.id) | 0;
    const o = await deps.me(ctx);
    const bag = GIFT_BAGS[id];
    const r = recOf(o);
    if (!bag || (r.bags ?? []).includes(id)) return ctx.reply({ res: 0 }, "68_5");
    (r.bags ??= []).push(id);
    o.score = (o.score ?? 0) + bag.score;
    if (o.robot) o.robot.exp += bag.exp;
    else o.helloExp = (o.helloExp ?? 0) + bag.exp;
    await deps.save(o);
    ctx.reply({ score: o.score }, "onScoreUpdated");
    ctx.reply({ res: 1 }, "68_5");
  });

  // 将军榜
  world.xt("PetExtension2.54e_25", async (ctx) => {
    const o = await deps.me(ctx);
    const races = new Set([...(o.pets ?? []), ...(o.storage ?? [])].map((p) => p.race));
    ctx.reply({ res: GENERAL_LINES.map((line) => (line.some((r) => races.has(r)) ? 1 : 0)).join(":") }, "54e_25");
  });
}
