// The kings' challenges of 奇灵神树 (scene/hexagrampalace3) for the 2013 server: 修罗 and 凯撒 of
// January 2013 (activityres/activity130117/boss/xiuluo and kaisa, era files: "挑战时间：1月18日—31日")
// and 召唤奇灵王 that followed them (activityres/activity130131/qiling/qilingdlg, its copy of
// February 2013: "挑战时间截至到3月7日"). The January scene and its two buttons are lost (the later
// boss list sends one to hexagrampalace3 for both: hexagrampalace3_sb_20130118_xiuluo, _kaisa): the
// rebuilt control's ScenePatches gives the room's NPC 修罗 the three choices (RECONSTRUCTED).
//
// 修罗 (index 0) and 凯撒 (index 1), HolidayExtension:
//   0118BW_whitePanel {} / 0118BW_blackPanel {} -> {buy, status, buff, use}
//        status 0 not beaten (Lv100: "战胜100级修罗即可获得修罗亚比蛋"), 1 beaten (Lv120: "战胜LV120级修罗
//        还可获得强者的象征"), 2 beaten at Lv120; buff the seconds left of the day's blessing, use
//        whether it was taken today; buy the 亚比蛋 got with 星币
//   0118BW_buff {index}  -> {suc}    the blessing, 15 minutes a day ("每天可以领取15分钟的光之祝福时间"):
//        修罗's 光之祝福 双攻 +150, 体力 +200; 凯撒's 暗之祝福 双防 +150, 体力 +200, on the 亚比 that fights
//   0118BW_buy {index}   -> {res}    "星币的强大力量可以帮助你直接获得修罗": 200 星币 for the 亚比蛋 (伊修
//        730, 阿凯 727; res 1, else the day's limit)
//   54_22 {type: 99, handler: "BW0118", index}   the fight (battle.ts addActFight)
// 召唤奇灵王, HolidayExtension:
//   0201qiling_panel {}    -> {info: "red:blue:green:state"}   each 奇灵玉 got (1), and the state: 0
//        not all three, 1 all three, 2 奇灵王 called (its 亚比蛋 got), 3 the 终极挑战 won
//   0201qiling_exchange {} -> {suc}   唤醒奇灵王: the three 奇灵玉 (items 494–496) for 小奇灵's 亚比蛋 (793)
//   54_22 {type: 99, handler: "qiling0201", index}   index 0–2 the 红色 普通, 蓝色 中级, 绿色 高级 试炼
//        (a win gives that 奇灵玉); 3 the 终极挑战 against 奇灵王 once it is called
//   The 星币获得 of a 奇灵玉 is the shop's MaterialExtension.buyMaterial (50, 100, 150 星币).
//
// The 2013 server is lost: whom the 奇灵 trials fight and at what levels (奇灵王 at Lv60, 80, 100, the
// 终极挑战 at Lv120) are RECONSTRUCTED; the purple titles the Lv120 wins gave (修罗终结者, 凯撒终结者,
// 奇灵王者) are not kept (the revival has no titles). The eggs go into the 亚比孵化器 (eggs.ts).

import { addActFight, type Battle } from "./battle.ts";
import type { PetOwner } from "./pets.ts";
import type { World, XtContext } from "./server.ts";
import { eggNow } from "./sevenstar.ts";

export const BW_BOSSES = [
  { index: 0, race: 731, egg: 730, panel: "0118BW_whitePanel", up: [1, 3] },
  { index: 1, race: 728, egg: 727, panel: "0118BW_blackPanel", up: [2, 4] },
];
export const BW_LEVELS = [100, 120];
export const BW_PRICE = 200;
export const BLESSING_MS = 15 * 60 * 1000;
export const BLESSING = { stat: 150, hp: 200 };

export const QILING = { race: 794, egg: 793, stones: [494, 495, 496], levels: [60, 80, 100], final: 120 };

export interface KingRec {
  /** 修罗 and 凯撒, by index: status, bought, the blessing's end and the day it was taken. */
  bw?: Record<string, { status?: number; bought?: boolean; until?: number; day?: string }>;
  /** 召唤奇灵王: the 奇灵玉 won, called, the 终极挑战 won. */
  qiling?: { passed?: boolean[]; called?: boolean; won?: boolean };
}

export interface KingOwner extends PetOwner {
  xingbi?: number;
  items?: Record<string, Record<string, number>>;
  kings?: KingRec;
}

export interface KingDeps {
  me(ctx: XtContext): Promise<KingOwner>;
  save(o: KingOwner): Promise<void>;
  today(): string;
  now(): number;
}

const recOf = (o: KingOwner) => (o.kings ??= {});
const bwOf = (o: KingOwner, index: number) => ((recOf(o).bw ??= {})[String(index)] ??= {});
const stoneOwned = (o: KingOwner, id: number) => (o.items?.["2"]?.[String(id)] ?? 0) > 0;

/** The 奇灵 panel's info: each 奇灵玉 got, then the state. */
export function qilingInfo(o: KingOwner): string {
  const q = recOf(o).qiling ?? {};
  const got = QILING.stones.map((id, i) => (q.called || q.passed?.[i] || stoneOwned(o, id) ? 1 : 0));
  const state = q.won ? 3 : q.called ? 2 : got.every(Boolean) ? 1 : 0;
  return [...got, state].join(":");
}

export function installKingBosses(world: World, deps: KingDeps): void {
  const H = "HolidayExtension";

  for (const boss of BW_BOSSES) {
    world.xt(`${H}.${boss.panel}`, async (ctx) => {
      const r = bwOf(await deps.me(ctx), boss.index);
      const left = Math.max(0, Math.ceil(((r.until ?? 0) - deps.now()) / 1000));
      ctx.reply({ buy: !!r.bought, status: r.status ?? 0, buff: left, use: r.day === deps.today() }, boss.panel);
    });
  }
  const bossOf = (ctx: XtContext) => BW_BOSSES[Math.max(0, Math.min(1, Number(ctx.params.index) | 0))];
  world.xt(`${H}.0118BW_buff`, async (ctx) => {
    const o = await deps.me(ctx);
    const r = bwOf(o, bossOf(ctx).index);
    if (r.day === deps.today()) return ctx.reply({ suc: false }, "0118BW_buff");
    r.day = deps.today();
    r.until = deps.now() + BLESSING_MS;
    await deps.save(o);
    ctx.reply({ suc: true }, "0118BW_buff");
  });
  world.xt(`${H}.0118BW_buy`, async (ctx) => {
    const o = await deps.me(ctx);
    const boss = bossOf(ctx);
    const r = bwOf(o, boss.index);
    if (r.bought || (o.xingbi ?? 0) < BW_PRICE) return ctx.reply({ res: 0 }, "0118BW_buy");
    o.xingbi = (o.xingbi ?? 0) - BW_PRICE;
    r.bought = true;
    const msgs = eggNow(o, boss.egg);
    await deps.save(o);
    ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ res: 1 }, "0118BW_buy");
  });

  world.xt(`${H}.0201qiling_panel`, async (ctx) => {
    ctx.reply({ info: qilingInfo(await deps.me(ctx)) }, "0201qiling_panel");
  });
  world.xt(`${H}.0201qiling_exchange`, async (ctx) => {
    const o = await deps.me(ctx);
    const q = (recOf(o).qiling ??= {});
    if (q.called || !QILING.stones.every((id) => stoneOwned(o, id))) return ctx.reply({ suc: false }, "0201qiling_exchange");
    const bag = o.items!["2"];
    for (const id of QILING.stones) {
      bag[String(id)] -= 1;
      ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
    }
    q.called = true;
    const msgs = eggNow(o, QILING.egg);
    await deps.save(o);
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ suc: true }, "0201qiling_exchange");
  });

  // The blessing on the 亚比 that fights: two stats up, and 体力.
  const blessing = (up: number[]) => (b: Battle) => {
    const st = b.mine.stats.slice();
    for (const i of up) st[i] += BLESSING.stat;
    st[0] += BLESSING.hp;
    b.mine.stats = st;
    b.mine.pet.hp += BLESSING.hp;
  };

  addActFight(world, 99, (ctx, owner) => {
    const o = owner as KingOwner;
    const handler = String(ctx.params.handler ?? "");
    const index = Number(ctx.params.index) | 0;
    if (handler === "BW0118") {
      const boss = BW_BOSSES[index];
      if (!boss) return "这个挑战现在还不能进行哦！";
      const r = bwOf(o, boss.index);
      const status = r.status ?? 0;
      if (status >= 2) return "你已经战胜了它并获得了亚比蛋和称号！";
      return {
        race: boss.race,
        level: BW_LEVELS[status],
        adjust: (r.until ?? 0) > deps.now() ? blessing(boss.up) : undefined,
        onWin: (w) => {
          const rec = bwOf(w as KingOwner, boss.index);
          const was = rec.status ?? 0;
          rec.status = Math.min(2, was + 1);
          return was === 0 ? eggNow(w as KingOwner, boss.egg) : [];
        },
      };
    }
    if (handler === "qiling0201") {
      const q = recOf(o).qiling ?? {};
      if (index === 3) {
        if (!q.called) return "集齐三色奇灵玉才能召唤奇灵王哦！快去挑战吧！";
        if (q.won) return "你已经通过终极挑战了哦！";
        return {
          race: QILING.race,
          level: QILING.final,
          onWin: (w) => {
            ((recOf(w as KingOwner).qiling ??= {})).won = true;
            return [];
          },
        };
      }
      const stone = QILING.stones[index];
      if (stone === undefined) return "这个挑战现在还不能进行哦！";
      return {
        race: QILING.race,
        level: QILING.levels[index],
        onWin: (w) => {
          const k = w as KingOwner;
          const qq = (recOf(k).qiling ??= {});
          (qq.passed ??= [false, false, false])[index] = true;
          if (qq.called || stoneOwned(k, stone)) return [];
          const bag = ((k.items ??= {})["2"] ??= {});
          bag[String(stone)] = 1;
          return [["onAmountUpdated", { amount: `2_${stone}_0_1` }]];
        },
      };
    }
    return "这个挑战现在还不能进行哦！";
  });
}
