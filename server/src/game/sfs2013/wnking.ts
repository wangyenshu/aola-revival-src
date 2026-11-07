// 夜王复出！狼王再现！ for the 2013 server: the activity of February 2013 (activityres/activity130221/
// wolfandnightking; the module's copy of 2016, its films and the 夜王's trial panels of 2013, the
// others' copies of 2014–16). Its panels' commands:
//
// HolidayExtension:
//   nwk0219-1 {} -> {got0, got1, won, f, t}   each king called (got1 狼王, got0 夜王: the panels read
//        got<1 - index>), the 终极试炼 won; f and t are the later panels' (快速挑战, 领取夜王), false
//   nwk0219-2 {type} -> {cnt}   the 光之星 / 幽之星 lit (type 1 狼王, 0 夜王): "战斗失败可点亮光之星！
//        累计点亮3颗光之星也可获得光之剑魂哦！（光之星每天最多只能点亮一个哦！）"
//   nwk0219-3 {} -> {c, won}   the 终极试炼's tries today ("剩余挑战次数: 5 次")
// SynthesizeExtension 57_8 {id: 337 | 367, num} -> {res, id}   召唤狼王 / 召唤夜王: the three 剑魂
//        (565–567) or 封印 (707–709) for 洛洛's (1121) or 小夜's (1123) 亚比蛋, once
// MaterialExtension.buyMaterial {tp: 2, mi}   星币力量: a 剑魂 or 封印 for 70, 100, 130 星币 (the panel's
//        prices; the rows below, as the August 2013 material table has them, the January one having
//        none for the 封印 and the 剑魂 there for 蓝宝石 only, from the 2012 activity)
// 54_22 {type: 99, handler: "holiday.NWKChallenge", t, id}   the fights: t 1 狼王, 0 夜王, id 0–2 the
//        three 分身 (光/幽, 王/暗, 灵/冥); t 2 the 终极试炼 against both kings in one battle ("必须在
//        同一场战斗中，同时击败狼王和夜王才能胜利！"), five tries a day
//
// The 分身's tricks are the panels': the 王之分身 and 暗之分身 "每5回合会秒掉你一只亚比", the 灵之分身 and
// 冥之分身 "每回合会恢复部分血量". The 2013 server is lost: the levels, how much the 分身 heal, and
// that a king is called once are RECONSTRUCTED; the red title the 终极试炼 gave (夜狼传说) is not kept
// (the revival has no titles). The eggs go into the 亚比孵化器 (eggs.ts).

import { addHandlerFight } from "./battle.ts";
import type { Msg } from "./battle.ts";
import type { PetOwner } from "./pets.ts";
import type { World, XtContext } from "./server.ts";
import { eggNow } from "./sevenstar.ts";

/** The two sides by the panels' t: 0 夜王, 1 狼王. */
export const WNK_SIDES = [
  { race: 1124, egg: 1123, items: [707, 708, 709], synth: 367, item: "封印" },
  { race: 1122, egg: 1121, items: [565, 566, 567], synth: 337, item: "剑魂" },
];
export const WNK_LEVELS = [80, 90, 100];
export const WNK_FINAL = { level: 100, tries: 5 };
export const WNK_STARS = 3;
export const WNK_KILL_EVERY = 5;
export const WNK_HEAL = 0.1;
export const WNK_PRICES = [70, 100, 130];
/** The 剑魂 and 封印 as the August 2013 material table has them: [price, buyback, rmb, maxQ, vip, name]. */
export const WNK_ITEM_ROWS: Record<string, [number, number, number, number, number, string]> = {
  "565": [0, 0, 70, 1, 0, "光之剑魂"],
  "566": [0, 0, 100, 1, 0, "王之剑魂"],
  "567": [0, 0, 130, 1, 0, "灵之剑魂"],
  "707": [0, 0, 70, 1, 0, "幽之封印"],
  "708": [0, 0, 100, 1, 0, "暗之封印"],
  "709": [0, 0, 130, 1, 0, "冥之封印"],
};

export interface WnkRec {
  /** Called, by t. */
  got?: boolean[];
  /** The stars lit and the day of the last, by t. */
  stars?: number[];
  starDay?: string[];
  /** The 终极试炼: tries of the day, won. */
  day?: string;
  n?: number;
  won?: boolean;
}

export interface WnkOwner extends PetOwner {
  items?: Record<string, Record<string, number>>;
  wnk?: WnkRec;
}

export interface WnkDeps {
  me(ctx: XtContext): Promise<WnkOwner>;
  save(o: WnkOwner): Promise<void>;
  today(): string;
}

const recOf = (o: WnkOwner) => (o.wnk ??= {});
const bagOf = (o: WnkOwner) => ((o.items ??= {})["2"] ??= {});
const owns = (o: WnkOwner, id: number) => (o.items?.["2"]?.[String(id)] ?? 0) > 0;

/** An item of the side into the bag, if not had and the king not called. */
function giveItem(o: WnkOwner, t: number, id: number): Msg[] {
  const item = WNK_SIDES[t].items[id];
  if (recOf(o).got?.[t] || owns(o, item)) return [];
  bagOf(o)[String(item)] = 1;
  return [["onAmountUpdated", { amount: `2_${item}_0_1` }]];
}

export function installWnKing(world: World, deps: WnkDeps): void {
  const H = "HolidayExtension";
  const tries = (r: WnkRec) => (r.day === deps.today() ? r.n ?? 0 : 0);

  world.xt(`${H}.nwk0219-1`, async (ctx) => {
    const r = recOf(await deps.me(ctx));
    ctx.reply({ got0: !!r.got?.[0], got1: !!r.got?.[1], won: !!r.won, f: false, t: 0 }, "nwk0219-1");
  });
  world.xt(`${H}.nwk0219-2`, async (ctx) => {
    const t = Number(ctx.params.type) === 1 ? 1 : 0;
    const r = recOf(await deps.me(ctx));
    ctx.reply({ cnt: r.stars?.[t] ?? 0 }, "nwk0219-2");
  });
  world.xt(`${H}.nwk0219-3`, async (ctx) => {
    const r = recOf(await deps.me(ctx));
    ctx.reply({ c: tries(r), won: !!r.won }, "nwk0219-3");
  });

  const before = world.handlers?.get("SynthesizeExtension.57_8");
  world.xt("SynthesizeExtension.57_8", async (ctx, cmd) => {
    const id = Number(ctx.params.id) | 0;
    const t = WNK_SIDES.findIndex((s) => s.synth === id);
    if (t < 0) return before ? before(ctx, cmd) : ctx.reply({ res: 0 }, "57_8");
    const o = await deps.me(ctx);
    const r = recOf(o);
    const side = WNK_SIDES[t];
    if (r.got?.[t] || !side.items.every((i) => owns(o, i))) return ctx.reply({ res: 0, id }, "57_8");
    const bag = bagOf(o);
    for (const i of side.items) {
      bag[String(i)] -= 1;
      if (bag[String(i)] <= 0) delete bag[String(i)];
      ctx.reply({ amount: `2_${i}_0_-1` }, "onAmountUpdated");
    }
    (r.got ??= [false, false])[t] = true;
    const msgs = eggNow(o, side.egg);
    await deps.save(o);
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ res: 1, id }, "57_8");
  });

  addHandlerFight(world, "holiday.NWKChallenge", async (ctx, owner) => {
    const o = owner as WnkOwner;
    const r = recOf(o);
    const t = Number(ctx.params.t) | 0;
    if (t === 2) {
      if (!r.got?.[0] || !r.got?.[1]) return "只有获得了狼王和夜王的小奥拉才能开启终极试炼!";
      if (tries(r) >= WNK_FINAL.tries) return "你已经不能再挑战了！";
      r.day = deps.today();
      r.n = tries(r) + 1;
      await deps.save(o);
      return {
        race: WNK_SIDES[1].race,
        level: WNK_FINAL.level,
        team: [{ race: WNK_SIDES[0].race, level: WNK_FINAL.level }],
        onWin: (w) => {
          recOf(w as WnkOwner).won = true;
          return [];
        },
      };
    }
    const side = WNK_SIDES[t];
    const id = Number(ctx.params.id) | 0;
    if (!side || id < 0 || id > 2) return "这个挑战现在还不能进行哦！";
    if (r.got?.[t]) return t ? "你已经召唤了狼王！" : "你已经召唤了夜王！";
    if (owns(o, side.items[id])) return `你已经获得这个${side.item}了！`;
    return {
      race: side.race,
      level: WNK_LEVELS[id],
      boss: id === 1 ? { killEvery: WNK_KILL_EVERY } : id === 2 ? { healFrac: WNK_HEAL } : undefined,
      onWin: (w) => giveItem(w as WnkOwner, t, id),
      // The first 分身: a loss lights a star (one a day); the third brings the item too.
      onLose: id === 0
        ? (w) => {
            const k = recOf(w as WnkOwner);
            const day = deps.today();
            if ((k.starDay ??= ["", ""])[t] === day) return [];
            k.starDay[t] = day;
            const n = ((k.stars ??= [0, 0])[t] = Math.min(WNK_STARS, (k.stars[t] ?? 0) + 1));
            return n >= WNK_STARS ? giveItem(w as WnkOwner, t, 0) : [];
          }
        : undefined,
    };
  });
}
