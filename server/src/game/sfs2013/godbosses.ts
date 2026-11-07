// The gods' challenges of the 幻龙星系 for the 2013 server: 天空之神 拉诺斯 (activityres/activity120927/
// skychallenge, the copy of February 2014), 地之神兽 施瓦辛格 (零时迷城 mysticearth4: activity121101/
// schwarzenegger/challengepanel, 2014), 海洋之神 波塞冬 (海洋神域 mysticocean5: activity121206/
// poseidon_challenge, 2014) and 魔龙之战 of 赤翼魔龙王 (深渊魔域 msevenstar5: activity121220/
// abyssevilmainpanel, 2015, its films of December 2012). The commands are the panels':
//
// 天空之神 (HolidayExtension; the 天神圣殿 cloudstar6: its 2012 entrance is lost, 拉诺斯 there offers it):
//   20120928_F1 {} -> {proc, left, bought}   proc the stages won (0–3: 第一关, 第二关, 天空之神), left
//        today's tries at 天空之神 ("今天还可以挑战天空之神 5 次"), bought its 亚比蛋 got with 星币
//   jehad_today {index} -> {done}   the 天空圣战 勋章 of that day (its panel bariconpanels/skyjehad is lost)
//   20120928_F2 {} -> {res}   星币力量: 诺斯's 亚比蛋 (1233; res 1, -1 had, 101 too few 星币)
//   54_22 {type: 75}   the stage's fight; "首次战胜天空之神——拉诺斯就可以获得它的亚比蛋"
// 施瓦辛格 (PeriodicActiveExtension):
//   ega-1 {} -> {cnt, buy}   tries left today (5), -1 once won
//   ega-2 {} -> {rc: "race,level;…"}   "辛格会随机带上以下1至2只亚比与你对战": 雏菊仙子, 莫莫亚特, 友人契约书,
//        多古拉伯爵 (41257, 41248, 41259, 41267), drawn for the next fight
//   ega-3 {} -> {res}   200 星币 for 辛格's 亚比蛋 (1281; res 1, 101 too few 星币)
//   54_22 {type: 81}   施瓦辛格 and its helpers, one after another
// 波塞冬 (PeriodicActiveExtension):
//   sgc-1 {} -> {cnt, buy}   as ega-1;  sgc-2 {} -> {res}   200 星币 for 波塞's 亚比蛋 (1335)
//   54_22 {type: 92}   "战胜即可获得波塞冬亚比蛋"
// 魔龙之战 (PeriodicActiveExtension; "击败魔龙王的三个分身，就可以获得赤翼魔龙王亚比蛋"):
//   mdk1224-1 {} -> {dcc, st}   today's challenges (5 a day), the stage (0–2 暗之魔魂, 龙之魔魂, 魔龙之魂;
//        3 all won; 4 called)
//   mdk1224-2 {} -> {succ}   召唤: 小魔龙's 亚比蛋 (1348) once the three are won
//   SynthesizeExtension 57_8 {id: 344} -> {res}   the three 魂石 (636–638, bought with 星币) for the
//        亚比蛋, once ("依靠星币的力量最多只能获得1只魔龙王哦")
//   54_22 {type: 97}   the stage's 分身
//
// The 2012 server is lost: the levels, who the 天空之神's first two stages are (the panel's pictures:
// 乐天 and 茜点, then 飞蓬, the 云端王国's guardians of the 天空之神), the 分身 (赤翼魔龙王 at three
// levels), the helpers' level, the 天空之神's 星币 price and the 魂石's are RECONSTRUCTED. The eggs go
// into the 亚比孵化器 (eggs.ts).

import { addActFight } from "./battle.ts";
import type { PetOwner } from "./pets.ts";
import type { World, XtContext } from "./server.ts";
import { eggNow } from "./sevenstar.ts";

export const GOD_TRIES = 5;
export const GOD_PRICE = 200;

export const SKY = {
  type: 75,
  stages: [
    { race: 1240, level: 70, team: [{ race: 1227, level: 70 }] },
    { race: 1185, level: 85 },
    { race: 1234, level: 100 },
  ],
  egg: 1233,
};
export const SCHWARZ = { type: 81, race: 1282, level: 100, egg: 1281, helpers: [41257, 41248, 41259, 41267], helperLevel: 90 };
export const POSEIDON = { type: 92, race: 1336, level: 100, egg: 1335 };
export const ABYSS = { type: 97, race: 1350, levels: [80, 90, 100], egg: 1348, stones: [636, 637, 638], synth: 344 };
/** The 魂石's 星币 price (the 2013 material table has none; the panel: "星币获取"). */
export const SOUL_STONE_PRICE = 100;

interface Daily {
  day?: string;
  n?: number;
}
export interface GodRec {
  sky?: { proc?: number; bought?: boolean } & Daily;
  schwarz?: { won?: boolean; bought?: boolean; helpers?: number[] } & Daily;
  poseidon?: { won?: boolean; bought?: boolean } & Daily;
  abyss?: { st?: number; bought?: boolean } & Daily;
}

export interface GodOwner extends PetOwner {
  xingbi?: number;
  items?: Record<string, Record<string, number>>;
  gods?: GodRec;
}

export interface GodDeps {
  me(ctx: XtContext): Promise<GodOwner>;
  save(o: GodOwner): Promise<void>;
  today(): string;
  rng?: () => number;
}

export function installGodBosses(world: World, deps: GodDeps): void {
  const rec = (o: GodOwner) => (o.gods ??= {});
  const used = (d: Daily) => (d.day === deps.today() ? (d.n ?? 0) : 0);
  const take = (d: Daily) => {
    d.n = used(d) + 1;
    d.day = deps.today();
  };
  const left = (d: Daily) => Math.max(0, GOD_TRIES - used(d));
  const rng = () => (deps.rng ?? Math.random)();

  // A 亚比蛋 for 星币 (the panels' 星币力量), once.
  const buyEgg = async (ctx: XtContext, cmd: string, part: { bought?: boolean }, egg: number, o: GodOwner) => {
    if (part.bought) return ctx.reply({ res: -1 }, cmd);
    if ((o.xingbi ?? 0) < GOD_PRICE) return ctx.reply({ res: 101 }, cmd);
    o.xingbi = (o.xingbi ?? 0) - GOD_PRICE;
    part.bought = true;
    const msgs = eggNow(o, egg);
    await deps.save(o);
    ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ res: 1 }, cmd);
  };

  // ---------------------------------------------------------------- 天空之神
  const H = "HolidayExtension";
  const sky = (o: GodOwner) => (rec(o).sky ??= {});
  world.xt(`${H}.20120928_F1`, async (ctx) => {
    const s = sky(await deps.me(ctx));
    ctx.reply({ proc: s.proc ?? 0, left: left(s), bought: !!s.bought }, "20120928_F1");
  });
  world.xt(`${H}.jehad_today`, (ctx) => ctx.reply({ done: false }, "jehad_today"));
  world.xt(`${H}.20120928_F2`, async (ctx) => {
    const o = await deps.me(ctx);
    await buyEgg(ctx, "20120928_F2", sky(o), SKY.egg, o);
  });
  addActFight(world, SKY.type, async (_ctx, owner) => {
    const o = owner as GodOwner;
    const s = sky(o);
    const proc = s.proc ?? 0;
    const stage = SKY.stages[proc];
    if (!stage) return "你已经战胜了天空之神并获得了它的亚比蛋哦！";
    if (proc === 2) {
      if (left(s) <= 0) return "你今天已经没有挑战次数了，明天再来吧！";
      take(s);
      await deps.save(o);
    }
    return {
      race: stage.race,
      level: stage.level,
      team: stage.team,
      onWin: (w) => {
        const r = sky(w as GodOwner);
        r.proc = Math.min(3, (r.proc ?? 0) + 1);
        return r.proc === 3 ? eggNow(w as GodOwner, SKY.egg) : [];
      },
    };
  });

  // ---------------------------------------------------------------- 施瓦辛格
  const PA = "PeriodicActiveExtension";
  const sch = (o: GodOwner) => (rec(o).schwarz ??= {});
  world.xt(`${PA}.ega-1`, async (ctx) => {
    const s = sch(await deps.me(ctx));
    ctx.reply({ cnt: s.won ? -1 : left(s), buy: !!s.bought }, "ega-1");
  });
  world.xt(`${PA}.ega-2`, async (ctx) => {
    const o = await deps.me(ctx);
    const s = sch(o);
    const pool = [...SCHWARZ.helpers];
    const n = rng() < 0.5 ? 1 : 2;
    const picked: number[] = [];
    for (let i = 0; i < n; i++) picked.push(...pool.splice(Math.floor(rng() * pool.length), 1));
    s.helpers = picked;
    await deps.save(o);
    ctx.reply({ rc: picked.map((r) => `${r},${SCHWARZ.helperLevel}`).join(";") }, "ega-2");
  });
  world.xt(`${PA}.ega-3`, async (ctx) => {
    const o = await deps.me(ctx);
    await buyEgg(ctx, "ega-3", sch(o), SCHWARZ.egg, o);
  });
  addActFight(world, SCHWARZ.type, async (_ctx, owner) => {
    const o = owner as GodOwner;
    const s = sch(o);
    if (s.won) return "你已经战胜了施瓦辛格并获得了它的亚比蛋！";
    if (left(s) <= 0) return "你今天已经没有挑战次数了哦，明天再来吧！";
    take(s);
    await deps.save(o);
    return {
      race: SCHWARZ.race,
      level: SCHWARZ.level,
      team: (s.helpers ?? [SCHWARZ.helpers[0]]).map((r) => ({ race: r % 10000, level: SCHWARZ.helperLevel })),
      onWin: (w) => {
        const r = sch(w as GodOwner);
        if (r.won) return [];
        r.won = true;
        return eggNow(w as GodOwner, SCHWARZ.egg);
      },
    };
  });

  // ---------------------------------------------------------------- 波塞冬
  const pos = (o: GodOwner) => (rec(o).poseidon ??= {});
  world.xt(`${PA}.sgc-1`, async (ctx) => {
    const s = pos(await deps.me(ctx));
    ctx.reply({ cnt: s.won ? -1 : left(s), buy: !!s.bought }, "sgc-1");
  });
  world.xt(`${PA}.sgc-2`, async (ctx) => {
    const o = await deps.me(ctx);
    await buyEgg(ctx, "sgc-2", pos(o), POSEIDON.egg, o);
  });
  addActFight(world, POSEIDON.type, async (_ctx, owner) => {
    const o = owner as GodOwner;
    const s = pos(o);
    if (s.won) return "你已经战胜了海洋之神并获得了它！";
    if (left(s) <= 0) return "你今天已经没有挑战次数了哦！";
    take(s);
    await deps.save(o);
    return {
      race: POSEIDON.race,
      level: POSEIDON.level,
      onWin: (w) => {
        const r = pos(w as GodOwner);
        if (r.won) return [];
        r.won = true;
        return eggNow(w as GodOwner, POSEIDON.egg);
      },
    };
  });

  // ---------------------------------------------------------------- 魔龙之战
  const aby = (o: GodOwner) => (rec(o).abyss ??= {});
  world.xt(`${PA}.mdk1224-1`, async (ctx) => {
    const s = aby(await deps.me(ctx));
    ctx.reply({ dcc: used(s), st: s.st ?? 0 }, "mdk1224-1");
  });
  world.xt(`${PA}.mdk1224-2`, async (ctx) => {
    const o = await deps.me(ctx);
    const s = aby(o);
    if ((s.st ?? 0) !== 3) return ctx.reply({ succ: false }, "mdk1224-2");
    s.st = 4;
    const msgs = eggNow(o, ABYSS.egg);
    await deps.save(o);
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ succ: true }, "mdk1224-2");
  });
  const before = world.handlers?.get("SynthesizeExtension.57_8");
  world.xt("SynthesizeExtension.57_8", async (ctx, cmd) => {
    if ((Number(ctx.params.id) | 0) !== ABYSS.synth) return before ? before(ctx, cmd) : ctx.reply({ res: 0 }, "57_8");
    const o = await deps.me(ctx);
    const s = aby(o);
    const bag = ((o.items ??= {})["2"] ??= {});
    if (s.bought || !ABYSS.stones.every((id) => (bag[String(id)] ?? 0) > 0)) return ctx.reply({ res: 0 }, "57_8");
    for (const id of ABYSS.stones) {
      bag[String(id)] -= 1;
      ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
    }
    s.bought = true;
    const msgs = eggNow(o, ABYSS.egg);
    await deps.save(o);
    for (const [c, body] of msgs) ctx.reply(body, c);
    ctx.reply({ res: 1 }, "57_8");
  });
  addActFight(world, ABYSS.type, async (_ctx, owner) => {
    const o = owner as GodOwner;
    const s = aby(o);
    const st = s.st ?? 0;
    if (st >= 3) return "你已经战胜了魔龙王的三个分身！";
    if (left(s) <= 0) return "你今天已经没有挑战次数了哦！";
    take(s);
    await deps.save(o);
    return {
      race: ABYSS.race,
      level: ABYSS.levels[st],
      onWin: (w) => {
        const r = aby(w as GodOwner);
        r.st = Math.min(3, (r.st ?? 0) + 1);
        return [];
      },
    };
  });
}
