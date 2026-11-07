// The activities of the 七星 places for the 2013 server: 黑暗三连星 in 黑暗星穴 (scene/msevenstar3, the
// era activityres/activity120927/darkmanjueqi) and 魔将挑战 at 深渊之门 (scene/msevenstar4, the era
// activityres/activity121213/evilgeneralmainpanel). The commands are those panels':
//
// 黑暗三连星 (DarkManJueQiPanel, its panel 1 魔星·鲁曼, 2 妖星·纳兹, 3 幽星·塞娅):
//   54_22 {type: 74 | 76 | 82}   the fight (PetClient2.startFight, battle.ts addActFight); a win
//                                gives 5 of the boss's 星魂 (item 595 魔之星魂, 599 妖之星魂, 609 幽之星魂:
//                                "每战胜鲁曼1次，可获得5颗魔之星魂")
//   HolidayExtension 20120928_luman2, 20121012_nazi2, PeriodicActiveExtension b3ls-2 {}
//                                30 星魂 -> the boss's 亚比蛋 ("收集30颗魔之星魂…获得鲁曼的亚比蛋"): 鲁迪
//                                1231, 纳德 1249, 塞西 1290; the panel shows the egg, the 亚比 is given
//   HolidayExtension 20120928_luman3, 20121012_nazi3, PeriodicActiveExtension b3ls-3 {}
//                                -> {res, index}   星魂法阵: 20 星币 for one of four packs, index 0–3 of
//                                3, 5, 7, 30 星魂 (DarkManChoosePanel; res 1 done, 12 the day's limit)
// 魔将挑战 (MainPanel):
//   HolidayExtension 20121214_MJ1 {} -> {bought, leftTimes, beat}   bought with 星币, tries left today
//                                (5: the panel's art), beaten
//   54_22 {type: 94}             魔将·魔洛 (1347); the first win gives 魔洛's 亚比蛋 (格洛 1346: "首次战胜
//                                魔将·魔洛就可以获得魔洛亚比蛋")
//   HolidayExtension 20121214_MJ2 {} -> {res}   星币的力量: 160 星币 for the 亚比蛋 (1 done, 101 too few
//                                星币, -1 had already)
//
// The 2012 server is lost: the bosses' levels are RECONSTRUCTED from the panels' words (黑暗三连星:
// "战胜…次数越多，…的实力越强", and Lv60 every day 12:00–14:00, "受到龙族的影响，全部60级"; 魔洛 at Lv100,
// "如果带上100级的亚比来挑战把握会更大哦"), and so are the odds of the 星魂法阵's packs. The eggs go
// into the 亚比孵化器 (the panels: "已经放入你的亚比孵化器"; eggs.ts hatches egg N as race N).

import { addActFight, type Msg } from "./battle.ts";
import type { PetOwner } from "./pets.ts";
import type { World, XtContext } from "./server.ts";

/** 黑暗三连星: the boss of each panel (1–3). */
export const DARK_STARS = [
  { type: 74, race: 1232, item: 595, egg: 1231, ext: "HolidayExtension", get: "20120928_luman2", buy: "20120928_luman3" },
  { type: 76, race: 1250, item: 599, egg: 1249, ext: "HolidayExtension", get: "20121012_nazi2", buy: "20121012_nazi3" },
  { type: 82, race: 1291, item: 609, egg: 1290, ext: "PeriodicActiveExtension", get: "b3ls-2", buy: "b3ls-3" },
];
export const STAR_SOULS_PER_WIN = 5;
export const STAR_SOULS_FOR_EGG = 30;
/** The panel counts the day's 星魂 full at 999 (_dailyMaxItemGetNum). */
export const STAR_SOULS_MAX = 999;
/** 星魂法阵: 20 星币; its packs and their odds (RECONSTRUCTED). */
export const SOUL_DRAW_COST = 20;
export const SOUL_PACKS = [3, 5, 7, 30];
export const SOUL_PACK_ODDS = [0.5, 0.3, 0.17, 0.03];
/** The bosses' level: Lv60 in the 降级时间 (12:00–14:00), else 60 and 5 more for each win, to 100. */
export function darkStarLevel(wins: number, chinaHour: number): number {
  if (chinaHour >= 12 && chinaHour < 14) return 60;
  return Math.min(100, 60 + 5 * wins);
}

export const EVIL_GENERAL = { type: 94, race: 1347, level: 100, egg: 1346, tries: 5, price: 160 };

export interface SevenStarRec {
  /** 黑暗三连星: wins against each boss, by its race. */
  wins?: Record<string, number>;
  /** 魔将挑战: tries of the day, beaten, bought. */
  mj?: { day: string; tries: number };
  mjBeat?: boolean;
  mjBought?: boolean;
}

export interface SevenStarOwner extends PetOwner {
  xingbi?: number;
  items?: Record<string, Record<string, number>>;
  sevenstar?: SevenStarRec;
}

export interface SevenStarDeps {
  me(ctx: XtContext): Promise<SevenStarOwner>;
  save(o: SevenStarOwner): Promise<void>;
  today(): string;
  now(): number;
  rng?: () => number;
}

/** A 亚比蛋 into the 亚比孵化器 (the 亚比蛋 materials, type 5: eggs.ts). */
export function eggNow(o: { items?: Record<string, Record<string, number>> }, egg: number): Msg[] {
  const eggs = ((o.items ??= {})["5"] ??= {});
  eggs[String(egg)] = (eggs[String(egg)] ?? 0) + 1;
  return [["onAmountUpdated", { amount: `5_${egg}_0_1` }]];
}

const itemsOf = (o: SevenStarOwner) => ((o.items ??= {})["2"] ??= {});

export function installSevenStar(world: World, deps: SevenStarDeps): void {
  const rec = (o: SevenStarOwner) => (o.sevenstar ??= {});
  const hour = () => new Date(deps.now() + 8 * 3600_000).getUTCHours();

  for (const star of DARK_STARS) {
    addActFight(world, star.type, (_ctx, o) => {
      const wins = rec(o as SevenStarOwner).wins?.[String(star.race)] ?? 0;
      return {
        race: star.race,
        level: darkStarLevel(wins, hour()),
        onWin: (owner) => {
          const r = rec(owner as SevenStarOwner);
          (r.wins ??= {})[String(star.race)] = wins + 1;
          const bag = itemsOf(owner as SevenStarOwner);
          const have = bag[String(star.item)] ?? 0;
          const n = Math.max(0, Math.min(STAR_SOULS_PER_WIN, STAR_SOULS_MAX - have));
          if (!n) return [];
          bag[String(star.item)] = have + n;
          return [["onAmountUpdated", { amount: `2_${star.item}_0_${n}` }]];
        },
      };
    });

    world.xt(`${star.ext}.${star.get}`, async (ctx) => {
      const o = await deps.me(ctx);
      const bag = itemsOf(o);
      const have = bag[String(star.item)] ?? 0;
      if (have < STAR_SOULS_FOR_EGG) return ctx.reply({ res: 0 }, star.get);
      bag[String(star.item)] = have - STAR_SOULS_FOR_EGG;
      const msgs = eggNow(o, star.egg);
      await deps.save(o);
      ctx.reply({ amount: `2_${star.item}_0_-${STAR_SOULS_FOR_EGG}` }, "onAmountUpdated");
      for (const [c, body] of msgs) ctx.reply(body, c);
      ctx.reply({ res: 1 }, star.get);
    });

    world.xt(`${star.ext}.${star.buy}`, async (ctx) => {
      const o = await deps.me(ctx);
      if ((o.xingbi ?? 0) < SOUL_DRAW_COST) return ctx.reply({ res: 0 }, star.buy);
      o.xingbi = (o.xingbi ?? 0) - SOUL_DRAW_COST;
      let x = (deps.rng ?? Math.random)();
      let index = SOUL_PACKS.length - 1;
      for (let i = 0; i < SOUL_PACK_ODDS.length; i++) {
        if (x < SOUL_PACK_ODDS[i]) {
          index = i;
          break;
        }
        x -= SOUL_PACK_ODDS[i];
      }
      const bag = itemsOf(o);
      const n = Math.max(0, Math.min(SOUL_PACKS[index], STAR_SOULS_MAX - (bag[String(star.item)] ?? 0)));
      bag[String(star.item)] = (bag[String(star.item)] ?? 0) + n;
      await deps.save(o);
      ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
      if (n) ctx.reply({ amount: `2_${star.item}_0_${n}` }, "onAmountUpdated");
      ctx.reply({ res: 1, index }, star.buy);
    });
  }

  // 魔将挑战
  const MJ = "HolidayExtension.20121214_MJ";
  const triesLeft = (r: SevenStarRec) => EVIL_GENERAL.tries - (r.mj?.day === deps.today() ? r.mj.tries : 0);
  world.xt(`${MJ}1`, async (ctx) => {
    const r = rec(await deps.me(ctx));
    ctx.reply({ bought: !!r.mjBought, leftTimes: r.mjBeat ? 0 : Math.max(0, triesLeft(r)), beat: !!r.mjBeat }, "20121214_MJ1");
  });
  addActFight(world, EVIL_GENERAL.type, async (_ctx, o) => {
    const r = rec(o as SevenStarOwner);
    if (r.mjBeat) return "你已经战胜并获得了魔洛！";
    if (triesLeft(r) <= 0) return "今天已经没有挑战次数了，明天再来吧！";
    r.mj = { day: deps.today(), tries: (r.mj?.day === deps.today() ? r.mj.tries : 0) + 1 };
    await deps.save(o as SevenStarOwner);
    return {
      race: EVIL_GENERAL.race,
      level: EVIL_GENERAL.level,
      onWin: (owner) => {
        const w = rec(owner as SevenStarOwner);
        if (w.mjBeat) return [];
        w.mjBeat = true;
        return eggNow(owner as SevenStarOwner, EVIL_GENERAL.egg);
      },
    };
  });
  world.xt(`${MJ}2`, async (ctx) => {
    const o = await deps.me(ctx);
    const r = rec(o);
    if (r.mjBought) return ctx.reply({ res: -1 }, "20121214_MJ2");
    if ((o.xingbi ?? 0) < EVIL_GENERAL.price) return ctx.reply({ res: 101 }, "20121214_MJ2");
    o.xingbi = (o.xingbi ?? 0) - EVIL_GENERAL.price;
    r.mjBought = true;
    const msgs = eggNow(o, EVIL_GENERAL.egg);
    await deps.save(o);
    ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ res: 1 }, "20121214_MJ2");
  });
}
