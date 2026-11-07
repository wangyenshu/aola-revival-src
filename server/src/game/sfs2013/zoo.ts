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
//   97_205 / 97_206 / 97_207 the 地狱模式: entered {place}, a wave passed, lost -> {scoreAdded, state}
//   97_104 getGameItemGame {}                    -> {items: [{itemId, num}]}   捕捉 things, items 424–431
//   97_100 enterGame / 97_101 leaveGame          -> {res: 1}
//   97_102 useGameItem {itemId}                  -> {res, itemId}
//   97_103 catchBabyAniaml {raceId, itemId, rate} -> {res, raceId}; a caught baby animal is a zoo
//                                                   animal (material type 12, id 10000 + raceId, as the era
//                                                   ZooAnimalDataService names baby animals)
//
// The 动物园 (the zoo house furniture/b020000, rebuilt; ZooClient, mmo.framework.comm.zoo):
//
//   97_1  getZooInfo {un}                 -> {un, lv, exp, next, cap, n, fodder, fodderMax, fillCost}
//   97_4  getAnimalInfos {un}             -> {un, animals: [{id, raceId, mature, left (s), rate, hungry}]}
//   97_9  getAllBabyAnimals {}            -> {babys: [{raceId, type: 1, num}]}   (AnimalData, as zoores_1 reads it)
//   97_10 getAllMatureAnimals {}          -> {matrues: [{raceId, type: 2, num, price}]}   (price: what 97_21 pays)
//   97_11 getZooItems {}                  -> {items: [{id, num}]}   the 饲料 in the bag (the 动物仓库's 道具)
//   97_5  putAnimal2Zoo {raceId}          -> {res (1, -1 none, -2 full), animal}
//   97_7  harvestAnimal {id}              -> {res (1, -1 none, -2 not grown), id, raceId, petRace, petName, exp, lv}
//   97_12 addFodder {un, id, itemId}      -> {res (1, -1 none, -2 晶币, -3 used, -4 grown), id, itemId, left, rate}   a 饲料 for one
//   97_12 addFodder {name, itemId, num}   -> {res (1, -1 none, -2 晶币, -3 full), itemId, num, fodder, fodderMax, fillCost}
//                                            the 饲料机 (itemId -1: filled for 晶币)
//   97_13 amuseAnimal {name, animalId}    -> {res (1, -3 played this hour, -4 grown, -5 hungry), animalId, left …}   玩耍
//   97_6  dropAnimal {id}                 -> {res, id}
//   97_21 sell mature animals {raceId, num} -> {res, raceId, num, score}   (the revival's; the era sold them
//                                             back through MaterialClient)
//
// A baby animal (material type 12, id = race) put into the zoo grows for its
// Animal.matureTime hours (ZooAnimalData); grown, 收获 gives the zoo its exp and
// the mature animal (type 12, id 20000 + race), or, at Animal.evoRate percent, the
// 亚比 it may turn into (变异, Animal.evoIds) into the 仓库. The ZooItemData 饲料
// are sold here for 晶币 and used at once on one animal: 加速饲料 take 1, 6 or 24
// hours off, 普通变异饲料 adds 10 percent (once an animal), the 一星…四星变异饲料
// make 变异 certain for animals of that many stars or fewer. The zoo's levels,
// room, the 晶币 prices (the era sold most 饲料 for 星币) and 玩耍 are RECONSTRUCTED; the 饲料机
// keeps the era's numbers (see FODDER_MAX). A 饲料 the bag holds (type 13, from
// a 礼包) is used before one is bought.
//
// The game SWFs in game/ are later copies (2017, 2020); the 2013 server is lost:
// the rewards (晶币 for a won stage) and the catch odds when the game leaves them to
// the server (rate -1) are RECONSTRUCTED. 动物捕捉's things (items 424–430) are bought
// (its panel's 购买道具: MaterialExtension buyMaterial, type 2).

import type { World, XtContext } from "./server.ts";

export const ZOO_EXT = "ZooExtension";
/** 晶币 for a won stage of a 保卫战 (RECONSTRUCTED). */
export const TD_WIN_SCORE = 100;
/** The 保卫战 games' own 道具 (items 431–453: the 动物保卫战's 431–434, 444, 445, the 天空保卫战's 450–453). */
export const TD_ITEMS = [431, 469];
/** 地狱模式: 晶币 a wave passed and at most a game (RECONSTRUCTED). */
export const TD_ENDLESS_WAVE = 10;
export const TD_ENDLESS_MAX = 300;
/** Catching odds in percent when the game leaves them to the server (RECONSTRUCTED). */
export const CATCH_RATE = 40;
/** The most a catch's own odds (its rate) may be. */
export const CATCH_RATE_MAX = 80;
/** 晶币 the 保卫战 (wins and the 地狱模式) pay a day, at most. RECONSTRUCTED. */
export const TD_DAY_MAX = 3000;
/** The places (the three 保卫战) and their zones and steps a client may name. */
export const TD_PLACES_MAX = 9;
export const TD_ZONES_MAX = 60;
export const TD_STEPS_MAX = 99;
export const ANIMAL_TYPE = "12";
/** ZooItemData 饲料 kept in the bag (material type 13). */
export const FODDER_TYPE = "13";

export interface ZooAnimalRec {
  id: number;
  race: number;
  /** When it was put in (ms). */
  at: number;
  /** Hours of growth given by 饲料 (ms). */
  cut: number;
  /** Extra 变异 percent (普通变异饲料), 100 for a certain one. */
  boost: number;
  /** Time it went hungry, the 饲料机 empty (ms): its growth waits that long. */
  hungry?: number;
  /** Last 玩耍 (ms). */
  played?: number;
}

export interface ZooRec {
  exp: number;
  nextId: number;
  animals: ZooAnimalRec[];
  /** The 饲料机: 饲料 points in it, and when what the animals ate was last counted (ms). */
  fodder?: number;
  fedTo?: number;
}

export interface ZooOwner {
  score?: number;
  zoo?: ZooRec;
  items?: Record<string, Record<string, number>>;
  /** 保卫战 progress per place: "zone:stars" entries. */
  td?: Record<string, string[]>;
  /** 晶币 the 保卫战 paid today (TD_DAY_MAX a day). */
  tdPaid?: { day: string; n: number };
}

export interface ZooDeps<O extends ZooOwner> {
  me: (ctx: XtContext) => Promise<O>;
  save: (o: O) => Promise<void>;
  random?: () => number;
  now?: () => number;
  /** Another player's record by name (a visited zoo), if there is one. */
  byName?: (name: string) => Promise<O | undefined>;
  /** Put a new 亚比 of this race into the owner's 仓库: its name, or undefined when the race is unknown. */
  givePet?: (o: O, race: number) => Promise<string | undefined>;
}

/** ZooAnimalData (era materialdata): [race, name, matureName, stars, where, matureTime h, exp, price, evoIds, evoRates]. */
export const ANIMALS: [number, string, string, number, "land" | "sky" | "sea", number, number, number, string, string][] = [
  [1, "小狗", "卷毛狗", 1, "land", 2, 4, 500, "1009", "25"],
  [2, "小刺猬", "刺猬", 2, "land", 4, 7, 1500, "1013", "15"],
  [3, "小鸭", "勋章鸭", 1, "land", 22, 40, 1500, "1003", "20"],
  [4, "小兔", "萝卜兔", 2, "land", 24, 45, 1800, "1005", "25"],
  [5, "小猫", "铃铛猫", 3, "land", 48, 90, 2000, "1011", "20"],
  [6, "小松鼠", "大尾松鼠", 2, "land", 8, 17, 1500, "1017", "20"],
  [7, "小考拉", "双子考拉", 3, "land", 4, 9, 1500, "1015", "10"],
  [8, "小奶牛", "牛大叔", 2, "land", 24, 50, 1500, "1019", "15"],
  [9, "BB鼠", "蓝小鼠", 3, "land", 6, 13, 1800, "1021", "20"],
  [10, "小红雀", "红毛雀", 3, "sky", 24, 48, 1800, "1023", "20"],
  [11, "蛋蛋鸟", "小蓝鸟", 1, "sky", 2, 4, 1200, "1025", "15"],
  [12, "毛毛虫", "小蓝蝶", 2, "sky", 4, 8, 1000, "1027", "20"],
  [13, "袋鼠宝宝", "跳跳袋鼠", 3, "land", 6, 15, 1500, "1031", "20"],
  [14, "葵花小鹦鹉", "凤头鹦鹉", 2, "sky", 2, 5, 1000, "1029", "20"],
  [15, "咕咕鸟", "咕咕啄木鸟", 2, "sky", 3, 7, 1400, "1033", "18"],
  [16, "金丝雀", "红角黄莺", 2, "sky", 7, 15, 1600, "1035", "23"],
  [17, "豆豆鸡", "黑羽豆豆鸡", 2, "sky", 4, 7, 1800, "1037", "19"],
  [18, "小土拨鼠", "天竺暴牙鼠", 2, "land", 4, 8, 1200, "1041", "18"],
  [19, "小狸狸", "红尾赤狸", 3, "land", 24, 50, 2000, "1039", "15"],
  [20, "小海燕", "长嘴信天翁", 2, "sky", 6, 13, 1400, "1043", "21"],
  [21, "海星星", "太阳海星", 2, "sea", 4, 7, 1200, "1045", "21"],
  [22, "小珊瑚鱼", "神仙鱼", 1, "sea", 2, 4, 1000, "1047", "23"],
  [23, "小箭鱼", "飞箭旗鱼", 2, "sea", 6, 13, 1400, "1049", "21"],
  [24, "小白鹤", "丹顶鹤", 3, "sky", 8, 18, 1600, "1051", "19"],
  [25, "章鱼仔", "章鱼哥", 2, "sea", 8, 17, 1600, "1053", "18"],
  [26, "扁扁鱼", "魔鬼鱼", 2, "sea", 8, 17, 1600, "1055", "15"],
  [27, "小海龟", "绿海龟", 2, "sea", 6, 13, 1300, "1057", "17"],
  [28, "小海马", "飞飞海马", 2, "sea", 4, 9, 1200, "1059", "19"],
  [29, "泡泡鱼", "刺刺河豚", 2, "sea", 6, 12, 1300, "1061", "18"],
  [30, "小海豹", "球球海豹", 3, "sea", 8, 16, 1500, "1063", "18"],
  [31, "波波狗", "博美狗", 4, "land", 24, 50, 2000, "1007_1065", "15_5"],
  [32, "哈仔", "哈士奇", 4, "land", 24, 50, 2000, "1007_1065", "5_15"],
  [33, "小土狗", "中华田园犬", 2, "land", 8, 15, 500, "1007_1065", "6_9"],
  [34, "小球球", "秋田犬", 2, "land", 8, 15, 500, "1007_1065", "9_6"],
  [35, "小狮子", "狮子王", 3, "land", 24, 50, 2000, "1067", "18"],
  [36, "趴趴熊", "绅士熊", 3, "land", 24, 52, 2000, "1069", "15"],
  [37, "小燕子", "燕子哥", 2, "sky", 8, 16, 500, "1071", "15"],
  [38, "小企鹅", "围巾企鹅", 3, "land", 24, 50, 1500, "1073", "16"],
  [39, "狸小猫", "狸猫猫", 2, "land", 8, 17, 800, "1075", "17"],
  [40, "小小鹿", "长颈鹿", 3, "land", 6, 18, 1000, "1214", "15"],
];
const ANIMAL = new Map(ANIMALS.map((a) => [a[0], a]));
export const BABY_BASE = 10000;
export const MATURE_BASE = 20000;

/** The owner's zoo animals (type 12), with saves from before baby animals took id 10000 + race moved over. */
export function animalsOwned(o: ZooOwner): Record<string, number> {
  const zoo = ((o.items ??= {})[ANIMAL_TYPE] ??= {});
  for (const [id, n] of Object.entries(zoo)) {
    if (Number(id) >= BABY_BASE) continue;
    const key = String(BABY_BASE + Number(id));
    zoo[key] = (zoo[key] ?? 0) + n;
    delete zoo[id];
  }
  return zoo;
}
const HOUR = 3600 * 1000;
/**
 * The 饲料机 (era zoo/zoores_5 FeedingMachinePanel, ZooCommonConfig): it holds at most
 * 800 points of 饲料; every animal still growing eats 6 an hour; when it is empty the
 * animals are hungry and stop growing until it is filled. It is filled with gathered
 * things (炎冰, 蓝晶, 金块 …: the era FeedingCommonConfig, item id -> points) or at once for 晶币 (2 points for 5 晶币 short
 * of full, as the era 快速添加饲料 counted them). A new zoo's 饲料机 starts full.
 */
export const FODDER_MAX = 800;
export const FODDER_PER_HOUR = 6;
export const FODDER_POINTS: Record<number, number> = {
  38: 31, 39: 31, 40: 30, 84: 28, 85: 29, 86: 71, 87: 69, 90: 32, 91: 71, 93: 71, 122: 32, 124: 71,
  133: 70, 165: 32, 167: 70, 198: 28, 211: 31, 212: 29, 213: 72,
};
/** 晶币 to fill the 饲料机 from fodder points (快速添加饲料). */
export const fillCost = (fodder: number) => Math.ceil((2 * Math.max(0, FODDER_MAX - fodder)) / 5);
/** 玩耍 with an animal: once an hour, ten minutes off its growth (RECONSTRUCTED: the era raised its mood). */
export const PLAY_EVERY = HOUR;
export const PLAY_CUT = 10 * 60 * 1000;
/** ZooItemData 饲料: id -> [晶币 (RECONSTRUCTED but 1, the era's), hours off, stars for a certain 变异 (0 none), extra percent]. */
export const FODDER: Record<number, [number, number, number, number]> = {
  1: [1000, 0, 0, 10],
  2: [2000, 0, 1, 100],
  3: [4000, 0, 2, 100],
  4: [6000, 0, 3, 100],
  8: [8000, 0, 4, 100],
  5: [200, 1, 0, 0],
  6: [1000, 6, 0, 0],
  7: [3000, 24, 0, 0],
};

/** The zoo's level for its exp: level n needs 100·n·(n−1)/2 (RECONSTRUCTED). */
export function zooLevel(exp: number): { lv: number; next: number } {
  let lv = 1;
  while (exp >= (100 * lv * (lv + 1)) / 2) lv++;
  return { lv, next: (100 * lv * (lv + 1)) / 2 };
}
/** How many animals the zoo holds (RECONSTRUCTED). */
export const zooRoom = (lv: number) => Math.min(20, 6 + 2 * lv);

export function animalLeft(a: ZooAnimalRec, now: number): number {
  const def = ANIMAL.get(a.race);
  const grow = (def ? def[5] : 1) * HOUR;
  return Math.max(0, Math.ceil((a.at + grow + (a.hungry ?? 0) - a.cut - now) / 1000));
}

/**
 * What the animals ate since it was last counted: FODDER_PER_HOUR each animal still growing
 * (as it was then); the time the 饲料机 was empty they waited, hungry.
 */
export function settleFodder(z: ZooRec, now: number): void {
  if (z.fodder === undefined) z.fodder = FODDER_MAX;
  const from = z.fedTo ?? now;
  z.fedTo = now;
  if (now <= from) return;
  const growing = z.animals.filter((a) => animalLeft(a, from) > 0);
  if (growing.length === 0) return;
  const perMs = (growing.length * FODDER_PER_HOUR) / HOUR;
  const fedMs = Math.min(now - from, z.fodder / perMs);
  z.fodder = Math.max(0, z.fodder - fedMs * perMs);
  const hungryMs = now - from - fedMs;
  if (hungryMs > 0) for (const a of growing) a.hungry = (a.hungry ?? 0) + hungryMs;
}

export function installZoo<O extends ZooOwner>(world: World, deps: ZooDeps<O>): void {
  const rnd = deps.random ?? Math.random;
  const place = (ctx: XtContext) => String(Math.min(TD_PLACES_MAX, Math.max(1, Number(ctx.params.place ?? 1) | 0 || 1)));
  const items = (o: O) => ((o.items ??= {})["2"] ??= {});
  /** What of add the day's cap leaves to pay. */
  const tdPay = (o: O, add: number): number => {
    const day = new Date(deps.now ? deps.now() : Date.now()).toISOString().slice(0, 10);
    if (o.tdPaid?.day !== day) o.tdPaid = { day, n: 0 };
    const pay = Math.max(0, Math.min(add, TD_DAY_MAX - o.tdPaid.n));
    o.tdPaid.n += pay;
    return pay;
  };

  world.xt(`${ZOO_EXT}.97_203`, async (ctx) => {
    const o = await deps.me(ctx);
    const p = place(ctx);
    // The games' own 道具 the player has (天空保卫战 reads them here: 450–453; the
    // 动物保卫战 asks the item service), as {itemId, num}.
    const mine = items(o);
    const tools = Object.entries(mine)
      .filter(([id, n]) => Number(id) >= TD_ITEMS[0] && Number(id) <= TD_ITEMS[1] && Number(n) > 0)
      .map(([id, n]) => ({ itemId: Number(id), num: Number(n) }));
    ctx.reply({ place: Number(p), gameInfo: (o.td?.[p] ?? []).join(";"), items: tools }, "97_203");
  });

  // 地狱模式 (the endless game of the three 保卫战): entered (97_205 {place}), a wave
  // passed (97_206), lost at last (97_207 -> the stars it earned, GameResultWrapper's
  // scoreAdded and state). RECONSTRUCTED: TD_ENDLESS_WAVE stars a wave, at most
  // TD_ENDLESS_MAX a game.
  const endless = new Map<string, number>();
  const tdKey = (ctx: XtContext): string => String((ctx.player as { name?: string } | undefined)?.name ?? "");
  world.xt(`${ZOO_EXT}.97_205`, async (ctx) => {
    endless.set(tdKey(ctx), 0);
    ctx.reply({ res: 1, place: Number(place(ctx)) }, "97_205");
  });
  world.xt(`${ZOO_EXT}.97_206`, async (ctx) => {
    endless.set(tdKey(ctx), (endless.get(tdKey(ctx)) ?? 0) + 1);
    ctx.reply({ res: 1, step: endless.get(tdKey(ctx)) }, "97_206");
  });
  world.xt(`${ZOO_EXT}.97_207`, async (ctx) => {
    const o = await deps.me(ctx);
    const waves = endless.get(tdKey(ctx)) ?? 0;
    endless.delete(tdKey(ctx));
    const add = tdPay(o, Math.min(TD_ENDLESS_MAX, waves * TD_ENDLESS_WAVE));
    if (add > 0) {
      o.score = (o.score ?? 0) + add;
      await deps.save(o);
      ctx.reply({ score: o.score }, "onScoreUpdated");
    }
    ctx.reply({ res: 1, state: 1, scoreAdded: add, score: o.score ?? 0, step: waves }, "97_207");
  });

  world.xt(`${ZOO_EXT}.97_200`, async (ctx) => ctx.reply({ res: 1, place: Number(place(ctx)) }, "97_200"));
  world.xt(`${ZOO_EXT}.97_204`, async (ctx) => ctx.reply({ res: 1 }, "97_204"));

  world.xt(`${ZOO_EXT}.97_201`, async (ctx) => {
    const o = await deps.me(ctx);
    const p = place(ctx);
    const win = Number(ctx.params.isWin) === 1;
    const zone = Number(ctx.params.zoneNum) | 0;
    const step = Math.min(TD_STEPS_MAX, Number(ctx.params.step) | 0);
    let add = 0;
    if (win && zone > 0 && zone <= TD_ZONES_MAX) {
      const list = ((o.td ??= {})[p] ??= []);
      const i = list.findIndex((e) => Number(e.split(":")[0]) === zone);
      const had = i >= 0 ? Number(list[i].split(":")[1]) : 0;
      if (i < 0) list.push(`${zone}:${Math.max(1, step)}`);
      else if (step > had) list[i] = `${zone}:${step}`;
      add = tdPay(o, TD_WIN_SCORE);
      o.score = (o.score ?? 0) + add;
      await deps.save(o);
      if (add) ctx.reply({ score: o.score }, "onScoreUpdated");
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
    // 能源石 (424, the flyer's energy) and the 糖果 are bought (the panel's 购买道具, MaterialExtension).
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
    const odds = Math.min(CATCH_RATE_MAX, rate >= 0 ? rate : CATCH_RATE);
    const mine = items(o);
    // A catch takes its tool, and is of an animal of the zoo (a baby one: its race, not its key).
    if (!((mine[tool] ?? 0) > 0) || !ANIMAL.has(race)) return ctx.reply({ res: 0, raceId: race }, "97_103");
    mine[tool] -= 1;
    if (mine[tool] <= 0) delete mine[tool];
    ctx.reply({ amount: `2_${tool}_0_-1` }, "onAmountUpdated");
    const caught = rnd() * 100 < odds;
    if (caught) {
      const zoo = animalsOwned(o);
      const key = String(BABY_BASE + race);
      zoo[key] = (zoo[key] ?? 0) + 1;
      ctx.reply({ amount: `${ANIMAL_TYPE}_${key}_0_1` }, "onAmountUpdated");
    }
    await deps.save(o);
    ctx.reply({ res: caught ? 1 : 0, raceId: race }, "97_103");
  });

  // The 动物园.
  const now = deps.now ?? Date.now;
  const zooOf = (o: ZooOwner): ZooRec => {
    const z = (o.zoo ??= { exp: 0, nextId: 1, animals: [] });
    settleFodder(z, now());
    return z;
  };
  const owned = animalsOwned;
  const whose = async (ctx: XtContext): Promise<O> => {
    const un = typeof ctx.params.un === "string" ? ctx.params.un : "";
    const mine = await deps.me(ctx);
    if (!un || !deps.byName || un === (mine as { name?: string }).name) return mine;
    return (await deps.byName(un)) ?? mine;
  };
  const view = (a: ZooAnimalRec, z?: ZooRec) => {
    const left = animalLeft(a, now());
    const def = ANIMAL.get(a.race);
    const hungry = left > 0 && z !== undefined && (z.fodder ?? 0) <= 0;
    return { id: a.id, raceId: a.race, mature: left === 0 ? 1 : 0, left, rate: Math.min(100, (def ? Number(def[9].split("_")[0]) : 0) + a.boost), hungry: hungry ? 1 : 0 };
  };
  const take = (o: ZooOwner, id: string, n: number, ctx: XtContext) => {
    const mine = owned(o);
    mine[id] = (mine[id] ?? 0) + n;
    if (mine[id] <= 0) delete mine[id];
    ctx.reply({ amount: `${ANIMAL_TYPE}_${id}_0_${n}` }, "onAmountUpdated");
  };

  world.xt(`${ZOO_EXT}.97_1`, async (ctx) => {
    const o = await whose(ctx);
    const z = zooOf(o);
    const { lv, next } = zooLevel(z.exp);
    ctx.reply({ un: (o as { name?: string }).name ?? "", lv, exp: z.exp, next, cap: zooRoom(lv), n: z.animals.length, fodder: Math.floor(z.fodder ?? 0), fodderMax: FODDER_MAX, fillCost: fillCost(z.fodder ?? 0) }, "97_1");
  });

  world.xt(`${ZOO_EXT}.97_4`, async (ctx) => {
    const o = await whose(ctx);
    const z = zooOf(o);
    ctx.reply({ un: (o as { name?: string }).name ?? "", animals: z.animals.map((a) => view(a, z)) }, "97_4");
  });

  world.xt(`${ZOO_EXT}.97_9`, async (ctx) => {
    const o = await deps.me(ctx);
    const babys = Object.entries(owned(o))
      .filter(([id, n]) => Number(id) < MATURE_BASE && n > 0)
      .map(([id, n]) => ({ raceId: Number(id) - BABY_BASE, type: 1, num: n }));
    ctx.reply({ babys }, "97_9");
  });

  world.xt(`${ZOO_EXT}.97_10`, async (ctx) => {
    const o = await deps.me(ctx);
    const matrues = Object.entries(owned(o))
      .filter(([id, n]) => Number(id) > MATURE_BASE && n > 0)
      .map(([id, n]) => ({ raceId: Number(id) - MATURE_BASE, type: 2, num: n, price: ANIMAL.get(Number(id) - MATURE_BASE)?.[7] ?? 0 }));
    ctx.reply({ matrues }, "97_10");
  });

  // The 动物仓库's 道具: the zoo's 饲料 one has (material type 13).
  world.xt(`${ZOO_EXT}.97_11`, async (ctx) => {
    const o = await deps.me(ctx);
    const items = Object.entries((o.items ?? {})[FODDER_TYPE] ?? {})
      .filter(([, n]) => n > 0)
      .map(([id, n]) => ({ id: Number(id), num: n }));
    ctx.reply({ items }, "97_11");
  });

  world.xt(`${ZOO_EXT}.97_5`, async (ctx) => {
    const o = await deps.me(ctx);
    const race = Number(ctx.params.raceId) | 0;
    const z = zooOf(o);
    if (!ANIMAL.has(race) || (owned(o)[String(BABY_BASE + race)] ?? 0) <= 0) return ctx.reply({ res: -1, raceId: race }, "97_5");
    if (z.animals.length >= zooRoom(zooLevel(z.exp).lv)) return ctx.reply({ res: -2, raceId: race }, "97_5");
    const a: ZooAnimalRec = { id: z.nextId++, race, at: now(), cut: 0, boost: 0 };
    z.animals.push(a);
    take(o, String(BABY_BASE + race), -1, ctx);
    await deps.save(o);
    ctx.reply({ res: 1, raceId: race, animal: view(a) }, "97_5");
  });

  world.xt(`${ZOO_EXT}.97_6`, async (ctx) => {
    const o = await deps.me(ctx);
    const id = Number(ctx.params.id) | 0;
    const z = zooOf(o);
    const i = z.animals.findIndex((a) => a.id === id);
    if (i < 0) return ctx.reply({ res: -1, id }, "97_6");
    z.animals.splice(i, 1);
    await deps.save(o);
    ctx.reply({ res: 1, id }, "97_6");
  });

  world.xt(`${ZOO_EXT}.97_7`, async (ctx) => {
    const o = await deps.me(ctx);
    const id = Number(ctx.params.id) | 0;
    const z = zooOf(o);
    const i = z.animals.findIndex((a) => a.id === id);
    if (i < 0) return ctx.reply({ res: -1, id }, "97_7");
    const a = z.animals[i];
    if (animalLeft(a, now()) > 0) return ctx.reply({ res: -2, id }, "97_7");
    const def = ANIMAL.get(a.race)!;
    z.animals.splice(i, 1);
    z.exp += def[6];
    // 变异: one of its 亚比 by their own odds, plus the 饲料's.
    let petRace = 0;
    let petName = "";
    const ids = def[8].split("_").map(Number);
    const rates = def[9].split("_").map(Number);
    let roll = rnd() * 100;
    for (let k = 0; k < ids.length && !petRace; k++) {
      const odds = Math.min(100, (rates[k] ?? 0) + a.boost);
      if (roll < odds) petRace = ids[k];
      else roll -= rates[k] ?? 0;
    }
    if (petRace && deps.givePet) {
      const got = await deps.givePet(o, petRace);
      if (got === undefined) petRace = 0;
      else petName = got;
    } else petRace = 0;
    if (!petRace) take(o, String(MATURE_BASE + a.race), 1, ctx);
    await deps.save(o);
    const { lv } = zooLevel(z.exp);
    ctx.reply({ res: 1, id, raceId: a.race, petRace, petName, exp: z.exp, lv, gain: def[6] }, "97_7");
  });

  world.xt(`${ZOO_EXT}.97_12`, async (ctx) => {
    const o = await deps.me(ctx);
    if (ctx.params.num !== undefined && ctx.params.id === undefined) return fillMachine(o, ctx);
    const id = Number(ctx.params.id) | 0;
    const item = Number(ctx.params.itemId) | 0;
    const a = zooOf(o).animals.find((x) => x.id === id);
    const reply = (res: number) => ctx.reply({ res, id, itemId: item, ...(a ? view(a) : {}) }, "97_12");
    if (!a) return reply(-1);
    const t = now();
    if (animalLeft(a, t) === 0) return reply(-4);
    {
      const f = FODDER[item];
      if (!f) return reply(-1);
      const [price, hours, stars, extra] = f;
      const def = ANIMAL.get(a.race)!;
      if (extra > 0 && (a.boost >= 100 || (stars === 0 && a.boost > 0) || (stars > 0 && def[3] > stars))) return reply(-3);
      // One of the bag's (type 13, from a 礼包: giftbags.ts) first, else bought.
      const bag = ((o.items ??= {})[FODDER_TYPE] ??= {});
      if ((bag[item] ?? 0) > 0) {
        bag[item] -= 1;
        if (bag[item] <= 0) delete bag[item];
        ctx.reply({ amount: `${FODDER_TYPE}_${item}_0_-1` }, "onAmountUpdated");
      } else {
        if ((o.score ?? 0) < price) return reply(-2);
        o.score = (o.score ?? 0) - price;
        ctx.reply({ score: o.score }, "onScoreUpdated");
      }
      a.cut += hours * HOUR;
      if (extra > 0) a.boost = Math.min(100, a.boost + extra);
    }
    await deps.save(o);
    reply(1);
  });

  /**
   * 添加饲料 at the 饲料机 (era ZooClient.addFodder {name, itemId, num}): itemId -1 fills it
   * for 晶币 (fillCost), a crop of FODDER_POINTS adds its points, num of them (no more than
   * fill it).
   */
  const fillMachine = async (o: O, ctx: XtContext) => {
    const z = zooOf(o);
    const item = Number(ctx.params.itemId) | 0;
    const room = FODDER_MAX - (z.fodder ?? 0);
    const reply = (res: number, extra: Record<string, unknown> = {}) =>
      ctx.reply({ res, itemId: item, fodder: Math.floor(z.fodder ?? 0), fodderMax: FODDER_MAX, fillCost: fillCost(z.fodder ?? 0), ...extra }, "97_12");
    if (room < 1) return reply(-3);
    if (item === -1) {
      const cost = fillCost(z.fodder ?? 0);
      if ((o.score ?? 0) < cost) return reply(-2);
      o.score = (o.score ?? 0) - cost;
      z.fodder = FODDER_MAX;
      await deps.save(o);
      ctx.reply({ score: o.score }, "onScoreUpdated");
      return reply(1, { num: 0, cost });
    }
    const points = FODDER_POINTS[item];
    const have = items(o)[String(item)] ?? 0;
    const n = Math.min(Number(ctx.params.num) | 0, have, Math.ceil(room / (points || 1)));
    if (!points || n <= 0) return reply(-1);
    items(o)[String(item)] = have - n;
    if (items(o)[String(item)] <= 0) delete items(o)[String(item)];
    z.fodder = Math.min(FODDER_MAX, (z.fodder ?? 0) + points * n);
    await deps.save(o);
    ctx.reply({ amount: `2_${item}_0_${-n}` }, "onAmountUpdated");
    reply(1, { num: n });
  };

  // 玩耍 (era ZooClient.amuseAnimal {name, animalId}): one's own animal still growing, not hungry.
  world.xt(`${ZOO_EXT}.97_13`, async (ctx) => {
    const o = await deps.me(ctx);
    const z = zooOf(o);
    const id = Number(ctx.params.animalId) | 0;
    const a = z.animals.find((x) => x.id === id);
    const t = now();
    const reply = (res: number) => ctx.reply({ res, animalId: id, ...(a ? view(a, z) : {}) }, "97_13");
    if (!a) return reply(-1);
    if (animalLeft(a, t) === 0) return reply(-4);
    if ((z.fodder ?? 0) <= 0) return reply(-5);
    if (a.played !== undefined && t - a.played < PLAY_EVERY) return reply(-3);
    a.played = t;
    a.cut += PLAY_CUT;
    await deps.save(o);
    reply(1);
  });

  world.xt(`${ZOO_EXT}.97_21`, async (ctx) => {
    const o = await deps.me(ctx);
    const race = Number(ctx.params.raceId) | 0;
    const def = ANIMAL.get(race);
    const key = String(MATURE_BASE + race);
    const num = Math.min(Math.max(1, Number(ctx.params.num) | 0), owned(o)[key] ?? 0);
    if (!def || num <= 0) return ctx.reply({ res: -1, raceId: race, num: 0, score: o.score ?? 0 }, "97_21");
    take(o, key, -num, ctx);
    o.score = (o.score ?? 0) + def[7] * num;
    ctx.reply({ score: o.score }, "onScoreUpdated");
    await deps.save(o);
    ctx.reply({ res: 1, raceId: race, num, score: o.score, got: def[7] * num }, "97_21");
  });
}
