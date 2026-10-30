// The trees of the 家园 for the 2013 server: PlantExtension (80_x), the commands
// of the 2013 TreeClient and PlantClient (library/socketclient, material/
// materialservice), with the reply fields their UserPlant.parseData reads, and
// SundriesExtension.revival_garden for planting and digging up in the rebuilt
// garden. A tree bought from the 种植手册 (MaterialExtension.buyMaterial, type 9,
// game.ts) is planted in the same 植树盆.
//
//   80_1 {}                         -> {userPlants: [plant]}            my trees
//   80_9 {owner, houseId}           -> {owner, houseId, userPlants}     someone's trees
//   80_2 {owner, userPlantId}       -> {result: {result, userPlant}}
//   80_3 {owner, userPlantId}       -> {result: {result, userPlant, surprise}}   雨露 (health)
//   80_4 {owner, userPlantId}       -> the same for 养料 (nutrition)
//   80_5 {owner, userPlantId}       -> {result: {result, extData, userPlant}}    采摘 (pick the fruit)
//   revival_garden {op: "buy", plantId} | {op: "dig", userPlantId} | {op: "info", un}
//                                   -> {op, result, plant, plants, score}
//
// The plants, their levels and fruit are the January 2013 materialdata
// PlantData and ItemData. The 2013 server is lost: how much a 雨露 or 养料
// gives, how often, and when fruit comes are RECONSTRUCTED from the texts of
// the later tree panel (yz/treemanager: "你每天只能为这棵…添加两次雨露哦",
// "健康值是有上限的，在到达下一等级之前已经不能增加了", "下次结果时间为今天…：00，
// 还可以结果…次"). Result codes are that panel's: 0 done, 1 done and grown a
// level, -1 no fruit, -2 too little 晶币, -5 twice today already, -9 top level,
// -17 full until the next level, -19 no such tree, -21 the pot is taken.

import type { World, XtContext } from "./server.ts";

export const PLANT_EXT = "PlantExtension";
/** HouseInfo.GARDENHOUSEID: the trees stand in the garden. */
export const GARDEN_HOUSE = 247;
/** Where the 植树盆 is in the rebuilt garden (furniture/b000247). */
export const POT = { x: 550, y: 224 };
/** What one 雨露 or 养料 gives, and how many of each a tree takes a day (RECONSTRUCTED). */
export const GROWTH_PER_CARE = 10;
export const CARE_PER_DAY = 2;
/** Fruit comes back at a whole hour, at least this long after the last picking (RECONSTRUCTED). */
export const FRUIT_WAIT_MS = 60 * 60 * 1000;

/** materialdata PlantData: [maxHealth, maxNutrition, productTime, productFruit] per level. */
export interface PlantKind {
  name: string;
  fruit: number;
  price: number;
  mature: number;
  levels: [number, number, number, number][];
}

export const PLANTS: Record<number, PlantKind> = {
  1: { name: "星辉树", fruit: 279, price: 1000, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [40, 40, 0, 0], [70, 70, 4, 20], [110, 110, 8, 30], [160, 160, 12, 50], [220, 220, 16, 70], [0, 0, 20, 100]] },
  2: { name: "摇钱树", fruit: 298, price: 1000, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [40, 40, 0, 0], [70, 70, 4, 20], [110, 110, 8, 30], [160, 160, 12, 50], [220, 220, 16, 70], [0, 0, 20, 100]] },
  3: { name: "兔兔树", fruit: 338, price: 1000, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [40, 40, 0, 0], [70, 70, 4, 20], [110, 110, 8, 30], [160, 160, 12, 50], [220, 220, 16, 70], [0, 0, 20, 100]] },
  4: { name: "小熊树", fruit: 365, price: 1000, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 0, 0], [40, 40, 4, 20], [50, 50, 8, 30], [60, 60, 12, 50], [70, 70, 16, 70], [0, 0, 20, 100]] },
  5: { name: "月亮树", fruit: 449, price: 1000, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
  6: { name: "太阳树", fruit: 474, price: 1000, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
  7: { name: "雪花麋鹿树", fruit: 486, price: 1000, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
  8: { name: "烂漫樱花树", fruit: 508, price: 1000, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
};
/** ItemData: at most 999 of a fruit. */
const FRUIT_MAX = 999;

export interface PlantRec {
  id: number;
  plantId: number;
  level: number;
  health: number;
  nutrition: number;
  /** Fruit on the tree now, fruitings left at this level, fruit of this level not grown yet. */
  remainFruit: number;
  remainProductTime: number;
  fruitLeft: number;
  nextFruitTime: number;
  /** Care given today: {day, rain, fat}. */
  care: { day: string; rain: number; fat: number };
}

export interface PlantOwner {
  name: string;
  score?: number;
  items?: Record<string, Record<string, number>>;
  plants?: PlantRec[];
  nextPlantId?: number;
}

export interface PlantDeps {
  me(ctx: XtContext): Promise<PlantOwner>;
  find(name: string): Promise<PlantOwner | undefined>;
  save(o: PlantOwner): Promise<void>;
  now(): number;
}

const dayOf = (ms: number) => new Date(ms + 8 * 3600_000).toISOString().slice(0, 10); // China time

/** The next whole hour at least FRUIT_WAIT_MS from now. */
export function nextFruitAt(now: number): number {
  return Math.ceil((now + FRUIT_WAIT_MS) / 3600_000) * 3600_000;
}

/** Fruit that has come since the tree was last looked at. */
export function ripen(p: PlantRec, now: number): void {
  if (p.remainFruit > 0 || p.remainProductTime <= 0 || now < p.nextFruitTime) return;
  const n = Math.max(1, Math.ceil(p.fruitLeft / p.remainProductTime));
  p.remainFruit = n;
  p.fruitLeft = Math.max(0, p.fruitLeft - n);
  p.remainProductTime -= 1;
}

/** The fields of UserPlant.parse / parseData, and the care left today for the rebuilt panel. */
export function plantView(p: PlantRec, now: number): Record<string, unknown> {
  ripen(p, now);
  const today = p.care.day === dayOf(now) ? p.care : { rain: 0, fat: 0 };
  return {
    id: p.id,
    plantId: p.plantId,
    houseId: GARDEN_HOUSE,
    positionX: POT.x,
    positionY: POT.y,
    level: p.level,
    health: p.health,
    nutrition: p.nutrition,
    remainFruit: p.remainFruit,
    remainProductTime: p.remainProductTime,
    nextFruitTime: p.nextFruitTime,
    healthCeil: GROWTH_PER_CARE * CARE_PER_DAY,
    nutritionCeil: GROWTH_PER_CARE * CARE_PER_DAY,
    petId: 0,
    visitors: "",
    isFurniture: false,
    rainLeft: CARE_PER_DAY - today.rain,
    fatLeft: CARE_PER_DAY - today.fat,
  };
}

/** Both full: one level up; from the mature level on it bears fruit. */
function growUp(p: PlantRec, kind: PlantKind, now: number): boolean {
  const max = kind.levels.length - 1;
  const [mh, mn] = kind.levels[p.level];
  if (p.level >= max || p.health < mh || p.nutrition < mn) return false;
  p.level += 1;
  p.health = 0;
  p.nutrition = 0;
  const [, , times, fruit] = kind.levels[p.level];
  p.remainProductTime = times;
  p.fruitLeft = fruit;
  p.remainFruit = 0;
  p.nextFruitTime = times > 0 ? nextFruitAt(now) : 0;
  return true;
}

/** 雨露 (rain) or 养料 (fat): what it does to the tree, as the result code. */
export function care(p: PlantRec, what: "rain" | "fat", now: number): number {
  const kind = PLANTS[p.plantId];
  if (!kind) return -19;
  if (p.level >= kind.levels.length - 1) return -9;
  const day = dayOf(now);
  if (p.care.day !== day) p.care = { day, rain: 0, fat: 0 };
  if (p.care[what] >= CARE_PER_DAY) return -5;
  const [mh, mn] = kind.levels[p.level];
  const key = what === "rain" ? "health" : "nutrition";
  const top = what === "rain" ? mh : mn;
  if (p[key] >= top) return -17;
  p[key] = Math.min(top, p[key] + GROWTH_PER_CARE);
  p.care[what] += 1;
  return growUp(p, kind, now) ? 1 : 0;
}

/**
 * A new tree in the 植树盆 (the 种植手册's trees, bought with 晶币, or the
 * rebuilt garden's own list): the tree, or -21 when one grows there already,
 * -2 for too little 晶币, -19 for no such tree.
 */
export function plantTree(o: PlantOwner, plantId: number): PlantRec | number {
  const kind = PLANTS[plantId];
  if (!kind) return -19;
  if ((o.plants ?? []).length > 0) return -21;
  if ((o.score ?? 0) < kind.price) return -2;
  o.score = (o.score ?? 0) - kind.price;
  o.nextPlantId = (o.nextPlantId ?? 0) + 1;
  const p: PlantRec = { id: o.nextPlantId, plantId, level: 0, health: 0, nutrition: 0, remainFruit: 0, remainProductTime: 0, fruitLeft: 0, nextFruitTime: 0, care: { day: "", rain: 0, fat: 0 } };
  (o.plants ??= []).push(p);
  return p;
}

export function installPlants(world: World, deps: PlantDeps): void {
  const mine = (o: PlantOwner) => (o.plants ??= []);
  const target = async (ctx: XtContext) => {
    const owner = String(ctx.params.owner ?? "");
    if (!owner || owner === ctx.player.name) return deps.me(ctx);
    return deps.find(owner);
  };
  const byId = (o: PlantOwner | undefined, id: unknown) => o?.plants?.find((p) => p.id === (Number(id) | 0));

  world.xt(`${PLANT_EXT}.80_1`, async (ctx) => {
    const o = await deps.me(ctx);
    const now = deps.now();
    const list = mine(o).map((p) => plantView(p, now));
    await deps.save(o);
    ctx.reply({ userPlants: list });
  });

  world.xt(`${PLANT_EXT}.80_9`, async (ctx) => {
    const o = await target(ctx);
    const now = deps.now();
    ctx.reply({ owner: ctx.params.owner ?? "", houseId: ctx.params.houseId ?? GARDEN_HOUSE, userPlants: (o?.plants ?? []).map((p) => plantView(p, now)) });
  });

  world.xt(`${PLANT_EXT}.80_2`, async (ctx) => {
    const p = byId(await target(ctx), ctx.params.userPlantId);
    ctx.reply({ result: p ? { result: 0, userPlant: plantView(p, deps.now()) } : { result: -19 } });
  });

  for (const [cmd, what] of [["80_3", "rain"], ["80_4", "fat"]] as const) {
    world.xt(`${PLANT_EXT}.${cmd}`, async (ctx) => {
      const o = await target(ctx);
      const p = byId(o, ctx.params.userPlantId);
      if (!o || !p) return ctx.reply({ result: { result: -19 } });
      const now = deps.now();
      const result = care(p, what, now);
      if (result >= 0) await deps.save(o);
      ctx.reply({ result: { result, userPlant: plantView(p, now), surprise: 0 } });
    });
  }

  world.xt(`${PLANT_EXT}.80_5`, async (ctx) => {
    const o = await target(ctx);
    const p = byId(o, ctx.params.userPlantId);
    if (!o || !p) return ctx.reply({ result: { result: -19 } });
    const now = deps.now();
    ripen(p, now);
    if (p.remainFruit <= 0) return ctx.reply({ result: { result: -1, userPlant: plantView(p, now) } });
    const picker = o.name === ctx.player.name ? o : await deps.me(ctx);
    const fruit = String(PLANTS[p.plantId].fruit);
    const items = ((picker.items ??= {})["2"] ??= {});
    const n = Math.min(p.remainFruit, FRUIT_MAX - (items[fruit] ?? 0));
    if (n <= 0) return ctx.reply({ result: { result: -16, userPlant: plantView(p, now) } });
    items[fruit] = (items[fruit] ?? 0) + n;
    p.remainFruit = 0;
    if (p.remainProductTime > 0) p.nextFruitTime = nextFruitAt(now);
    await deps.save(o);
    if (picker !== o) await deps.save(picker);
    ctx.reply({ amount: `2_${fruit}_0_${n}` }, "onAmountUpdated");
    ctx.reply({ result: { result: 0, extData: n, userPlant: plantView(p, now) } });
  });

  world.xt("SundriesExtension.revival_garden", async (ctx) => {
    const op = String(ctx.params.op ?? "info");
    const now = deps.now();
    const answer = (o: PlantOwner | undefined, result: number) => {
      const list = (o?.plants ?? []).map((p) => plantView(p, now));
      ctx.reply({ op, result, plant: list[0] ?? null, plants: list, score: o?.score ?? 0 }, "revival_garden");
    };
    if (op === "info") {
      const un = String(ctx.params.un ?? "");
      return answer(!un || un === ctx.player.name ? await deps.me(ctx) : await deps.find(un), 0);
    }
    const o = await deps.me(ctx);
    if (op === "buy") {
      const id = Number(ctx.params.plantId) | 0;
      const p = plantTree(o, id);
      if (typeof p === "number") return answer(o, p);
      await deps.save(o);
      ctx.reply({ score: o.score }, "onScoreUpdated");
      // PlantService.onAmountUpdated: "type_materialId_0_1_userPlantId" adds the tree.
      ctx.reply({ amount: `9_${id}_0_1_${p.id}` }, "onAmountUpdated");
      return answer(o, 0);
    }
    if (op === "dig") {
      const p = byId(o, ctx.params.userPlantId);
      if (!p) return answer(o, -19);
      o.plants = mine(o).filter((x) => x !== p);
      await deps.save(o);
      ctx.reply({ amount: `9_${p.plantId}_0_-1_${p.id}` }, "onAmountUpdated");
      return answer(o, 0);
    }
    answer(o, -19);
  });
}
