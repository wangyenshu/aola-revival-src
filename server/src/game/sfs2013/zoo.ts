// The 生态园 games for the 2013 server: ZooExtension (ExtMap 65), the commands of
// the 2013 PvZClient and CatchAnimalClient (library/socketclient, mmo.framework.
// comm.zoo), as the game SWFs send and read them (game/pvz 动物保卫战 place 1,
// game/seadefend 海底保卫战 and game/guardnut 天空保卫战 on the same engine with
// other places; game/catchanimal 动物捕捉).
//
//   97_203 GetTDGameData {place}                 -> {place, gameInfo: "zone:stars;…", items: []}
//   97_200 EnterTDGame {place}                   -> {res, place}
//   97_204 EnterTDGameOneStep {zoneNum, step, place} -> {res}
//   97_201 PassOneStep {isWin, zoneNum, step, place} -> {res, moneyState, prize: "", score}
//   97_202 UseTDGameItem {itemId, place}         -> {res, itemId}, the item (type 2) goes through onAmountUpdated
//   97_104 getGameItemGame {}                    -> {items: [{itemId, num}]}   捕捉 things, items 424–431
//   97_100 enterGame / 97_101 leaveGame          -> {res: 1}
//   97_102 useGameItem {itemId}                  -> {res, itemId}
//   97_103 catchBabyAniaml {raceId, itemId, rate} -> {res, raceId}; a caught baby animal is a zoo
//                                                   animal (material type 12, ZooAnimalData id = raceId)
//
// The game SWFs in game/ are later copies (2017, 2020); the 2013 server is lost:
// the rewards (晶币 for a won stage), the catch odds when the game leaves them to
// the server (rate -1) and the free tools are RECONSTRUCTED.

import type { World, XtContext } from "./server.ts";

export const ZOO_EXT = "ZooExtension";
/** 晶币 for a won stage of a 保卫战 (RECONSTRUCTED). */
export const TD_WIN_SCORE = 100;
/** Catching odds in percent when the game leaves them to the server (RECONSTRUCTED). */
export const CATCH_RATE = 40;
/** 能源石 and 普通糖果 (items 424, 425; CatchAnimalClient keeps itemId - 424) one gets for a game when one has none (RECONSTRUCTED). */
export const FREE_TOOLS = 5;
export const ANIMAL_TYPE = "12";

export interface ZooOwner {
  score?: number;
  items?: Record<string, Record<string, number>>;
  /** 保卫战 progress per place: "zone:stars" entries. */
  td?: Record<string, string[]>;
}

export interface ZooDeps<O extends ZooOwner> {
  me: (ctx: XtContext) => Promise<O>;
  save: (o: O) => Promise<void>;
  random?: () => number;
}

export function installZoo<O extends ZooOwner>(world: World, deps: ZooDeps<O>): void {
  const rnd = deps.random ?? Math.random;
  const place = (ctx: XtContext) => String(Number(ctx.params.place ?? 1) | 0 || 1);
  const items = (o: O) => ((o.items ??= {})["2"] ??= {});

  world.xt(`${ZOO_EXT}.97_203`, async (ctx) => {
    const o = await deps.me(ctx);
    const p = place(ctx);
    ctx.reply({ place: Number(p), gameInfo: (o.td?.[p] ?? []).join(";"), items: [] }, "97_203");
  });

  world.xt(`${ZOO_EXT}.97_200`, async (ctx) => ctx.reply({ res: 1, place: Number(place(ctx)) }, "97_200"));
  world.xt(`${ZOO_EXT}.97_204`, async (ctx) => ctx.reply({ res: 1 }, "97_204"));

  world.xt(`${ZOO_EXT}.97_201`, async (ctx) => {
    const o = await deps.me(ctx);
    const p = place(ctx);
    const win = Number(ctx.params.isWin) === 1;
    const zone = Number(ctx.params.zoneNum) | 0;
    const step = Number(ctx.params.step) | 0;
    let add = 0;
    if (win && zone > 0) {
      const list = ((o.td ??= {})[p] ??= []);
      const i = list.findIndex((e) => Number(e.split(":")[0]) === zone);
      const had = i >= 0 ? Number(list[i].split(":")[1]) : 0;
      if (i < 0) list.push(`${zone}:${Math.max(1, step)}`);
      else if (step > had) list[i] = `${zone}:${step}`;
      add = TD_WIN_SCORE;
      o.score = (o.score ?? 0) + add;
      await deps.save(o);
      ctx.reply({ score: o.score }, "onScoreUpdated");
    }
    ctx.reply({ res: 1, moneyState: 0, prize: "", score: o.score ?? 0, scoreAdded: add }, "97_201");
  });

  world.xt(`${ZOO_EXT}.97_202`, async (ctx) => {
    const o = await deps.me(ctx);
    const id = String(Number(ctx.params.itemId) | 0);
    const mine = items(o);
    if ((mine[id] ?? 0) > 0) {
      mine[id] -= 1;
      if (mine[id] <= 0) delete mine[id];
      await deps.save(o);
      ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
    }
    ctx.reply({ res: 1, itemId: Number(id) }, "97_202");
  });

  world.xt(`${ZOO_EXT}.97_104`, async (ctx) => {
    const o = await deps.me(ctx);
    const mine = items(o);
    // 能源石 (424, the flyer's energy) and 普通糖果 (425, the plain catch): one never runs out of a few.
    for (const id of ["424", "425"]) {
      if ((mine[id] ?? 0) > 0) continue;
      mine[id] = FREE_TOOLS;
      ctx.reply({ amount: `2_${id}_0_${FREE_TOOLS}` }, "onAmountUpdated");
    }
    await deps.save(o);
    const list = [];
    for (let id = 424; id <= 431; id++) if ((mine[String(id)] ?? 0) > 0) list.push({ itemId: id, num: mine[String(id)] });
    ctx.reply({ items: list }, "97_104");
  });

  world.xt(`${ZOO_EXT}.97_100`, async (ctx) => ctx.reply({ res: 1 }, "97_100"));
  world.xt(`${ZOO_EXT}.97_101`, async (ctx) => ctx.reply({ res: 1 }, "97_101"));

  world.xt(`${ZOO_EXT}.97_102`, async (ctx) => {
    const o = await deps.me(ctx);
    const id = String(Number(ctx.params.itemId) | 0);
    const mine = items(o);
    if ((mine[id] ?? 0) > 0) {
      mine[id] -= 1;
      if (mine[id] <= 0) delete mine[id];
      await deps.save(o);
      ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
    }
    ctx.reply({ res: 1, itemId: Number(id) }, "97_102");
  });

  world.xt(`${ZOO_EXT}.97_103`, async (ctx) => {
    const o = await deps.me(ctx);
    const race = Number(ctx.params.raceId) | 0;
    const tool = String(Number(ctx.params.itemId) | 0);
    const rate = Number(ctx.params.rate);
    const odds = rate >= 0 ? rate : CATCH_RATE;
    const mine = items(o);
    if ((mine[tool] ?? 0) > 0) {
      mine[tool] -= 1;
      if (mine[tool] <= 0) delete mine[tool];
      ctx.reply({ amount: `2_${tool}_0_-1` }, "onAmountUpdated");
    }
    const caught = race > 0 && rnd() * 100 < odds;
    if (caught) {
      const zoo = ((o.items ??= {})[ANIMAL_TYPE] ??= {});
      zoo[String(race)] = (zoo[String(race)] ?? 0) + 1;
      ctx.reply({ amount: `${ANIMAL_TYPE}_${race}_0_1` }, "onAmountUpdated");
    }
    await deps.save(o);
    ctx.reply({ res: caught ? 1 : 0, raceId: race }, "97_103");
  });
}
