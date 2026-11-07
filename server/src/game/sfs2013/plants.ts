// The trees of the 家园 for the 2013 server: PlantExtension (80_x), the commands
// of the 2013 TreeClient and PlantClient (library/socketclient, material/
// materialservice), with the reply fields their UserPlant.parseData reads, and
// SundriesExtension.revival_garden for planting and digging up in the rebuilt
// garden. A tree bought from the 种植手册 (MaterialExtension.buyMaterial, type 9,
// game.ts) is planted in the same 植树盆.
//
//   80_1 {}                         -> {userPlants: [plant]}            my trees
//   80_9 {owner, houseId}           -> {owner, houseId, userPlants}     someone's trees: in the
//                                      garden (247) its 植树盆's, in a room those standing there
//   80_2 {owner, userPlantId}       -> {result: {result, userPlant}}
//   80_3 {owner, userPlantId}       -> {result: {result, userPlant, surprise}}   雨露 (health)
//   80_4 {owner, userPlantId}       -> the same for 养料 (nutrition)
//   80_5 {owner, userPlantId}       -> {result: {result, extData, userPlant}}    采摘 (pick the fruit)
//   80_12 {userPlantId, petId}      -> {result: {result, userPlant}}   守护亚比 (0: none), the owner's
//   80_14 {pi}                      -> {res}   收为家具: a grown tree with no fruit to come leaves the
//                                      植树盆 for the 小屋's storage (isFurniture, houseId 0)
//   80_10 {houseId, changes}        -> {result}   trees made furniture put down or taken up in a room
//                                      (yz/plantdecorator): changes [{id, x, y, houseId}], houseId 0
//                                      back in storage
//   80_11 {houseId, newHouseId}     -> {result, nid}   another house type: its trees back in storage
//   81_1 {itemId, userPlantId, quantity, owner} (PlantItemExtension) -> {result: {result, userPlant}}
//                                      a 盆栽道具 used (PlantItemData 1–7; 7 铲子 digs the tree up)
//   81_2 {}                         -> {items: [{id, qt, uq}]}           the 盆栽道具 one has
//   revival_garden {op: "buy", plantId} | {op: "dig", userPlantId} | {op: "info", un}
//                                   -> {op, result, plant, plants, score, show}
//                                      show: the 亚比 the owner 展示 {i, r, lv, nm} or null
//
// The plants, their levels and fruit are the January 2013 materialdata
// PlantData and ItemData. The 2013 server is lost: how much a 雨露 or 养料
// gives, how often, and when fruit comes are RECONSTRUCTED from the texts of
// the later tree panel (yz/treemanager: "你每天只能为这棵…添加两次雨露哦",
// "健康值是有上限的，在到达下一等级之前已经不能增加了", "下次结果时间为今天…：00，
// 还可以结果…次", "添加雨露需要50晶币"). Result codes are that panel's: 0 done, 1 done and
// grown a level, -1 no fruit, -2 too little 晶币, -3 no such 道具, -4 the day's growth is full,
// -5 twice today already (a 道具: as often as it may be), -8 no such 亚比, -9 top level,
// -14 the 守护亚比 saw the picker, -17 full until the next level, -18 not bearing fruit, -19 no
// such tree, -20 not one's own tree, -21 the pot is taken, -22 (the revival's) a visitor has
// picked of this fruiting already, or only the owner's last fruit is left.
// A 雨露 or 养料 gives half the day's growth (健康值 or 营养值 每日成长上限, 20, +5 a 基因药剂),
// two a day; the owner pays 50 晶币 for one, a visitor nothing and is remembered (植物心声, the
// last five). The 盆栽道具 do what PlantItemData says: 极速雨露 / 极速养料 +20 outside the day's
// growth (five a day), 基因药剂 +5 to the day's growth (five a tree), 增产养料 the next fruiting
// twice, 繁盛养料 two fruitings more, 铲子 the tree dug up. A visitor picking a guarded tree is
// seen one time in three (RECONSTRUCTED: the 2013 panel fought the 守护亚比 then).

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
/** What the owner pays for a 雨露 or 养料 (the 2013 panel: "添加雨露需要50晶币"). */
export const CARE_COST = 50;
/** PlantItemData: [affected (0 health, 1 nutrition, 2 health ceiling, 3 nutrition ceiling, 4 doubled fruit, 5 more fruitings, 6 dig), value, use (1 a day, 2 a tree), at most]. */
export const PLANT_ITEMS: Record<number, [number, number, number, number]> = {
  1: [0, 20, 1, 5], 2: [1, 20, 1, 5], 3: [2, 5, 2, 5], 4: [3, 5, 2, 5], 5: [4, 1, 0, 0], 6: [5, 2, 0, 0], 7: [6, 0, 0, 0],
};
export const PLANT_ITEM_TYPE = "10";

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
  /** Visitors (ids) who picked of this fruiting: one fruit each, the last left to the owner. */
  pickers?: number[];
  /** Today's growth from 雨露 and 养料 (each half the day's ceiling). */
  grown?: { day: string; health: number; nutrition: number };
  /** The 基因药剂's raise of the day's growth ceilings. */
  ceilUp?: { health: number; nutrition: number };
  /** 盆栽道具 used today on this tree (a day's limit), by item id. */
  tools?: { day: string; n: Record<string, number> };
  /** 增产养料: the next fruiting twice. */
  doubled?: boolean;
  /** 守护亚比 (a 亚比 id of the owner's; 0 or none: none). */
  petId?: number;
  /** 植物心声: who cared for it lately, "name|name", the latest first. */
  visitors?: string[];
  /** 收为家具: a tree of the 小屋 now, where it stands (houseId 0: in the storage). */
  furniture?: { houseId: number; x: number; y: number };
}

export interface PlantOwner {
  id?: number;
  name: string;
  score?: number;
  items?: Record<string, Record<string, number>>;
  plants?: PlantRec[];
  nextPlantId?: number;
  /** The 亚比 of the bag and the 仓库 (守护亚比 is one of them). */
  pets?: { id: number }[];
  storage?: { id: number }[];
}

export interface PlantDeps {
  me(ctx: XtContext): Promise<PlantOwner>;
  find(name: string): Promise<PlantOwner | undefined>;
  save(o: PlantOwner): Promise<void>;
  /** The 亚比 the owner shows in the garden (展示 in the 亚比仓库), for revival_garden's info. */
  shown?(o: PlantOwner): Promise<{ i: number; r: number; lv: number; nm: string } | null>;
  now(): number;
  /** 0 ≤ x < 1 (Math.random without). */
  random?(): number;
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
  p.remainFruit = p.doubled ? n * 2 : n;
  p.doubled = false;
  p.pickers = [];
  p.fruitLeft = Math.max(0, p.fruitLeft - n);
  p.remainProductTime -= 1;
}

/** The trees in the 植树盆 (not those made furniture). */
export function potTrees(o: PlantOwner | undefined): PlantRec[] {
  return (o?.plants ?? []).filter((p) => !p.furniture);
}

/** Another house type: the trees standing in the old one go back into the storage (house.ts 63_3). */
export function plantsBackToStorage(o: PlantOwner, houseId: number): void {
  for (const p of o.plants ?? []) if (p.furniture && p.furniture.houseId === houseId) p.furniture = { houseId: 0, x: 0, y: 0 };
}

/** The fields of UserPlant.parse / parseData, and the care left today for the rebuilt panel. */
export function plantView(p: PlantRec, now: number): Record<string, unknown> {
  ripen(p, now);
  const today = p.care.day === dayOf(now) ? p.care : { rain: 0, fat: 0 };
  const f = p.furniture;
  return {
    id: p.id,
    plantId: p.plantId,
    houseId: f ? f.houseId : GARDEN_HOUSE,
    positionX: f ? f.x : POT.x,
    positionY: f ? f.y : POT.y,
    level: p.level,
    health: p.health,
    nutrition: p.nutrition,
    remainFruit: p.remainFruit,
    remainProductTime: p.remainProductTime,
    nextFruitTime: p.nextFruitTime,
    healthCeil: dayCeil(p, "health"),
    nutritionCeil: dayCeil(p, "nutrition"),
    petId: p.petId ?? 0,
    visitors: (p.visitors ?? []).join("#"),
    isFurniture: !!f,
    rainLeft: CARE_PER_DAY - today.rain,
    fatLeft: CARE_PER_DAY - today.fat,
  };
}

/** The day's growth ceiling of 健康值 or 营养值. */
export function dayCeil(p: PlantRec, key: "health" | "nutrition"): number {
  return GROWTH_PER_CARE * CARE_PER_DAY + (p.ceilUp?.[key] ?? 0);
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
  if (p.grown?.day !== day) p.grown = { day, health: 0, nutrition: 0 };
  const ceil = dayCeil(p, key);
  if (p.grown[key] >= ceil) return -4;
  const add = Math.min(ceil - p.grown[key], Math.ceil(ceil / CARE_PER_DAY));
  p[key] = Math.min(top, p[key] + add);
  p.grown[key] += add;
  p.care[what] += 1;
  return growUp(p, kind, now) ? 1 : 0;
}

/**
 * A 盆栽道具 on a tree (the item is taken by the caller when the result is not negative):
 * the result code; 2 for the 铲子 (the tree to be dug up).
 */
export function useTool(p: PlantRec, item: number, now: number, mine: boolean): number {
  const kind = PLANTS[p.plantId];
  const info = PLANT_ITEMS[item];
  if (!kind || !info) return -19;
  const [what, value, use, most] = info;
  const max = kind.levels.length - 1;
  const day = dayOf(now);
  if (use === 1) {
    if (p.tools?.day !== day) p.tools = { day, n: {} };
    if ((p.tools.n[item] ?? 0) >= most) return -5;
  }
  let result = 0;
  if (what === 0 || what === 1) {
    if (p.level >= max) return -9;
    const key = what === 0 ? "health" : "nutrition";
    const top = kind.levels[p.level][what === 0 ? 0 : 1];
    if (p[key] >= top) return -17;
    p[key] = Math.min(top, p[key] + value);
    result = growUp(p, kind, now) ? 1 : 0;
  } else if (what === 2 || what === 3) {
    const key = what === 2 ? "health" : "nutrition";
    p.ceilUp ??= { health: 0, nutrition: 0 };
    if (p.ceilUp[key] >= value * most) return -5;
    p.ceilUp[key] += value;
  } else if (what === 4 || what === 5) {
    const bearing = p.level >= kind.mature && (p.remainProductTime > 0 || p.remainFruit > 0);
    if (!bearing) return -18;
    if (what === 4) {
      if (p.doubled) return -5;
      p.doubled = true;
    } else {
      const [, , times, fruit] = kind.levels[p.level];
      const each = times > 0 ? Math.ceil(fruit / times) : 0;
      if (p.remainProductTime <= 0 && p.remainFruit <= 0) p.nextFruitTime = nextFruitAt(now);
      p.remainProductTime += value;
      p.fruitLeft += each * value;
    }
  } else {
    if (!mine) return -20;
    return 2;
  }
  if (use === 1) p.tools!.n[item] = (p.tools!.n[item] ?? 0) + 1;
  return result;
}

/**
 * A new tree in the 植树盆 (the 种植手册's trees, bought with 晶币, or the
 * rebuilt garden's own list): the tree, or -21 when one grows there already,
 * -2 for too little 晶币, -19 for no such tree.
 */
export function plantTree(o: PlantOwner, plantId: number): PlantRec | number {
  const kind = PLANTS[plantId];
  if (!kind) return -19;
  if (potTrees(o).length > 0) return -21;
  if ((o.score ?? 0) < kind.price) return -2;
  o.score = (o.score ?? 0) - kind.price;
  o.nextPlantId = (o.nextPlantId ?? 0) + 1;
  const p: PlantRec = { id: o.nextPlantId, plantId, level: 0, health: 0, nutrition: 0, remainFruit: 0, remainProductTime: 0, fruitLeft: 0, nextFruitTime: 0, care: { day: "", rain: 0, fat: 0 } };
  (o.plants ??= []).push(p);
  return p;
}

export function installPlants(world: World, deps: PlantDeps): void {
  const mine = (o: PlantOwner) => (o.plants ??= []);
  /**
   * Whose trees a command is about: one's own, or (a visit) the owner's of the home room one is
   * in: not anyone's by name, or a player could pick from every tree on the server from his
   * own garden.
   */
  const target = async (ctx: XtContext) => {
    const owner = String(ctx.params.owner ?? "");
    if (!owner || owner === ctx.player.name) return deps.me(ctx);
    const m = /^(.+)_(-?\d+)_Home$/.exec(ctx.player.room?.name ?? "");
    if (!m || m[1] !== owner) return undefined;
    return deps.find(owner);
  };
  /** A tree of the 植树盆 (one made furniture is cared for no more). */
  const byId = (o: PlantOwner | undefined, id: unknown) => potTrees(o).find((p) => p.id === (Number(id) | 0));

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
    const house = Number(ctx.params.houseId ?? GARDEN_HOUSE) | 0;
    const trees = house === GARDEN_HOUSE ? potTrees(o) : (o?.plants ?? []).filter((p) => p.furniture && p.furniture.houseId !== 0 && p.furniture.houseId === house);
    ctx.reply({ owner: ctx.params.owner ?? "", houseId: house, userPlants: trees.map((p) => plantView(p, now)) });
  });

  // 收为家具: the owner's tree at its top level with no fruit on it or to come.
  world.xt(`${PLANT_EXT}.80_14`, async (ctx) => {
    const o = await deps.me(ctx);
    const p = byId(o, ctx.params.pi);
    const now = deps.now();
    if (!p) return ctx.reply({ res: false });
    ripen(p, now);
    const top = PLANTS[p.plantId].levels.length - 1;
    if (p.level < top || p.remainFruit > 0 || p.remainProductTime > 0) return ctx.reply({ res: false });
    p.furniture = { houseId: 0, x: 0, y: 0 };
    p.petId = 0;
    await deps.save(o);
    ctx.reply({ res: true, userPlant: plantView(p, now) });
  });

  // The trees made furniture put down in (or taken up from) a room of the 小屋.
  world.xt(`${PLANT_EXT}.80_10`, async (ctx) => {
    const o = await deps.me(ctx);
    const house = Number(ctx.params.houseId) | 0;
    const changes = Array.isArray(ctx.params.changes) ? (ctx.params.changes as Record<string, unknown>[]) : [];
    for (const c of changes) {
      const p = (o.plants ?? []).find((x) => x.furniture && x.id === (Number(c.id) | 0));
      const to = Number(c.houseId) | 0;
      const x = Number(c.x) | 0, y = Number(c.y) | 0;
      if (!p || (to !== 0 && to !== house) || (to !== 0 && (x < 0 || x > 960 || y < 0 || y > 560))) return ctx.reply({ result: false });
    }
    for (const c of changes) {
      const p = (o.plants ?? []).find((x) => x.furniture && x.id === (Number(c.id) | 0))!;
      const to = Number(c.houseId) | 0;
      p.furniture = to === 0 ? { houseId: 0, x: 0, y: 0 } : { houseId: to, x: Number(c.x) | 0, y: Number(c.y) | 0 };
    }
    await deps.save(o);
    ctx.reply({ result: true });
  });

  world.xt(`${PLANT_EXT}.80_11`, async (ctx) => {
    const o = await deps.me(ctx);
    plantsBackToStorage(o, Number(ctx.params.houseId) | 0);
    await deps.save(o);
    ctx.reply({ result: true, nid: Number(ctx.params.newHouseId) | 0 });
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
      const own = o.name === ctx.player.name;
      if (own && (o.score ?? 0) < CARE_COST) return ctx.reply({ result: { result: -2, userPlant: plantView(p, now), surprise: 0 } });
      const result = care(p, what, now);
      if (result >= 0) {
        if (own) {
          o.score = (o.score ?? 0) - CARE_COST;
          ctx.reply({ score: o.score }, "onScoreUpdated");
        } else {
          const me = `${ctx.player.name}|${ctx.player.name}`;
          p.visitors = [me, ...(p.visitors ?? []).filter((v) => v !== me)].slice(0, 5);
        }
        await deps.save(o);
      }
      ctx.reply({ result: { result, userPlant: plantView(p, now), surprise: 0 } });
    });
  }

  // 守护亚比: one of the owner's 亚比 (0: none).
  world.xt(`${PLANT_EXT}.80_12`, async (ctx) => {
    const o = await deps.me(ctx);
    const p = byId(o, ctx.params.userPlantId);
    const now = deps.now();
    if (!p) return ctx.reply({ result: { result: -19 } });
    const pet = Number(ctx.params.petId) | 0;
    if (pet > 0 && ![...(o.pets ?? []), ...(o.storage ?? [])].some((x) => x.id === pet)) return ctx.reply({ result: { result: -8, userPlant: plantView(p, now) } });
    p.petId = Math.max(0, pet);
    await deps.save(o);
    ctx.reply({ result: { result: 0, userPlant: plantView(p, now) } });
  });

  // 盆栽道具 (PlantItemExtension): bought in the 种植手册, used from the tree's panel.
  world.xt("PlantItemExtension.81_2", async (ctx) => {
    const o = await deps.me(ctx);
    const have = o.items?.[PLANT_ITEM_TYPE] ?? {};
    ctx.reply({ items: Object.entries(have).filter(([, q]) => q > 0).map(([id, q]) => ({ id: Number(id), qt: q, uq: 0 })) });
  });
  world.xt("PlantItemExtension.81_1", async (ctx) => {
    const o = await target(ctx);
    const p = byId(o, ctx.params.userPlantId);
    const now = deps.now();
    if (!o || !p) return ctx.reply({ result: { result: -19 } });
    const user = o.name === ctx.player.name ? o : await deps.me(ctx);
    const item = Number(ctx.params.itemId) | 0;
    const have = ((user.items ??= {})[PLANT_ITEM_TYPE] ??= {});
    if (!((have[String(item)] ?? 0) > 0)) return ctx.reply({ result: { result: -3, userPlant: plantView(p, now) } });
    const result = useTool(p, item, now, user === o);
    if (result < 0) return ctx.reply({ result: { result, userPlant: plantView(p, now) } });
    have[String(item)] -= 1;
    if (have[String(item)] <= 0) delete have[String(item)];
    ctx.reply({ amount: `${PLANT_ITEM_TYPE}_${item}_0_-1` }, "onAmountUpdated");
    if (result === 2) {
      // 铲子: the pot is empty again.
      o.plants = mine(o).filter((x) => x !== p);
      await deps.save(o);
      ctx.reply({ amount: `9_${p.plantId}_0_-1_${p.id}` }, "onAmountUpdated");
      return ctx.reply({ result: { result: 0, userPlant: null, dug: 1 } });
    }
    await deps.save(o);
    if (user !== o) await deps.save(user);
    ctx.reply({ result: { result, userPlant: plantView(p, now) } });
  });

  world.xt(`${PLANT_EXT}.80_5`, async (ctx) => {
    const o = await target(ctx);
    const p = byId(o, ctx.params.userPlantId);
    if (!o || !p) return ctx.reply({ result: { result: -19 } });
    const now = deps.now();
    ripen(p, now);
    if (p.remainFruit <= 0) return ctx.reply({ result: { result: -1, userPlant: plantView(p, now) } });
    const visitor = o.name !== ctx.player.name;
    const picker = visitor ? await deps.me(ctx) : o;
    // A guarded tree: its 守护亚比 sees a visitor one time in three.
    if (visitor && (p.petId ?? 0) > 0 && (deps.random ? deps.random() : Math.random()) < 1 / 3)
      return ctx.reply({ result: { result: -14, userPlant: plantView(p, now) } });
    // 摘果子 at a friend's: one fruit a visitor a fruiting, never the last (RECONSTRUCTED).
    if (visitor && (p.remainFruit <= 1 || (p.pickers ?? []).includes(picker.id ?? 0)))
      return ctx.reply({ result: { result: -22, userPlant: plantView(p, now) } });
    const fruit = String(PLANTS[p.plantId].fruit);
    const items = ((picker.items ??= {})["2"] ??= {});
    const n = Math.min(visitor ? 1 : p.remainFruit, FRUIT_MAX - (items[fruit] ?? 0));
    if (n <= 0) return ctx.reply({ result: { result: -16, userPlant: plantView(p, now) } });
    items[fruit] = (items[fruit] ?? 0) + n;
    p.remainFruit -= n;
    if (visitor) (p.pickers ??= []).push(picker.id ?? 0);
    if (p.remainFruit === 0 && p.remainProductTime > 0) p.nextFruitTime = nextFruitAt(now);
    await deps.save(o);
    if (picker !== o) await deps.save(picker);
    ctx.reply({ amount: `2_${fruit}_0_${n}` }, "onAmountUpdated");
    ctx.reply({ result: { result: 0, extData: n, userPlant: plantView(p, now) } });
  });

  world.xt("SundriesExtension.revival_garden", async (ctx) => {
    const op = String(ctx.params.op ?? "info");
    const now = deps.now();
    const answer = async (o: PlantOwner | undefined, result: number) => {
      const list = potTrees(o).map((p) => plantView(p, now));
      const show = o && deps.shown ? await deps.shown(o) : null;
      ctx.reply({ op, result, plant: list[0] ?? null, plants: list, score: o?.score ?? 0, show }, "revival_garden");
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
