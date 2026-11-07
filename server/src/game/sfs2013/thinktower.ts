// The 念之塔 of 风暴星系 (黑暗念之塔) for the 2013 server: its four seals and its 念之大厅, the
// scenes of 2011–12 (scene/thinktowerofwater, …fire, …ice, …thunder, …think) with the rebuilt
// ThinkTowerService and thinktower/enterpanel. The commands are the era ThinkTowerClient's
// (MentalHallExtension) and the 念之大厅's own (SundriesExtension):
//
//   98_2 {}          -> {result: "w,f,i,t"}   the seals opened (1) of 水, 火, 冰, 雷: the panel lets
//                                             one into 念之大厅 once all four are "1"
//   98_1 {type}      -> {result}              a seal opened (its guardian beaten): type 17 水,
//                                             18 火, 19 冰, 20 雷; 21 念 (邪念) beaten in 念之大厅
//   98_3 {type}      -> {bn: [{type, id, num}]}   the seal's chest (type 17–20): 100 晶币, 101
//                                             经验 (the HELLO's, as quests give it), else a material
//   70_46 {race}     -> {has}                 念之大厅: has the player a 亚比 of 念's line (小念 602)
//   70_45 {race}     -> {suc}                 念之大厅: 小念's egg once 邪念 is beaten
//
// The 2011–12 server is lost: RECONSTRUCTED are the chests (CHEST: once a day each), 小念's
// level, and that 小念 is given only once 念 has been beaten (98_1 type 21) and only to one who
// has none of its line.

import type { World, XtContext } from "./server.ts";

export const SEAL_TYPES = [17, 18, 19, 20];
export const NIAN_TYPE = 21;
/** 念's line (小念, 幻念, 念). */
export const NIAN_LINE = [602, 603, 604];
/** A seal's chest: 晶币 and the HELLO's 经验 (RECONSTRUCTED). */
export const CHEST = { coins: 1000, exp: 2000 };
export const XIAONIAN_LEVEL = 5;

export interface TowerRec {
  /** Seals opened: their types. */
  sealed?: number[];
  /** 念 beaten. */
  nian?: boolean;
  /** The day each seal's chest was last opened. */
  chests?: Record<string, string>;
}

export interface TowerOwner {
  score?: number;
  pets?: { race: number }[];
  storage?: { race: number }[];
  robot?: { exp: number };
  helloExp?: number;
  tower?: TowerRec;
}

export interface TowerDeps {
  me(ctx: XtContext): Promise<TowerOwner>;
  save(o: TowerOwner): Promise<void>;
  today(): string;
  /** A new 亚比 (the bag or the 仓库): the messages for the client. */
  givePet(o: TowerOwner, race: number, level: number): Promise<[string, Record<string, unknown>][]>;
}

const hasLine = (o: TowerOwner) => [...(o.pets ?? []), ...(o.storage ?? [])].some((p) => NIAN_LINE.includes(p.race));

export function installThinkTower(world: World, deps: TowerDeps): void {
  world.xt("MentalHallExtension.98_2", async (ctx) => {
    const t = (await deps.me(ctx)).tower ?? {};
    ctx.reply({ result: SEAL_TYPES.map((s) => ((t.sealed ?? []).includes(s) ? "1" : "0")).join(",") }, "98_2");
  });

  world.xt("MentalHallExtension.98_1", async (ctx) => {
    const o = await deps.me(ctx);
    const type = Number(ctx.params.type) | 0;
    const t = (o.tower ??= {});
    if (SEAL_TYPES.includes(type)) t.sealed = [...new Set([...(t.sealed ?? []), type])].sort((a, b) => a - b);
    else if (type === NIAN_TYPE) t.nian = true;
    else return ctx.reply({ result: 0 }, "98_1");
    await deps.save(o);
    ctx.reply({ result: 1 }, "98_1");
  });

  world.xt("MentalHallExtension.98_3", async (ctx) => {
    const o = await deps.me(ctx);
    const type = Number(ctx.params.type) | 0;
    const t = (o.tower ??= {});
    const day = deps.today();
    if (!SEAL_TYPES.includes(type) || (t.chests ??= {})[String(type)] === day) return ctx.reply({ bn: [] }, "98_3");
    t.chests[String(type)] = day;
    o.score = (o.score ?? 0) + CHEST.coins;
    if (o.robot) o.robot.exp += CHEST.exp;
    else o.helloExp = (o.helloExp ?? 0) + CHEST.exp;
    await deps.save(o);
    ctx.reply({ bn: [{ type: 100, id: 0, num: CHEST.coins }, { type: 101, id: 0, num: CHEST.exp }] }, "98_3");
    ctx.reply({ score: o.score }, "onScoreUpdated");
  });

  world.xt("SundriesExtension.70_46", async (ctx) => {
    ctx.reply({ has: hasLine(await deps.me(ctx)) }, "70_46");
  });

  world.xt("SundriesExtension.70_45", async (ctx) => {
    const o = await deps.me(ctx);
    if (Number(ctx.params.race) !== NIAN_LINE[0] || !o.tower?.nian || hasLine(o)) return ctx.reply({ suc: false }, "70_45");
    const msgs = await deps.givePet(o, NIAN_LINE[0], XIAONIAN_LEVEL);
    await deps.save(o);
    for (const [cmd, body] of msgs) ctx.reply(body, cmd);
    ctx.reply({ suc: true }, "70_45");
  });
}
