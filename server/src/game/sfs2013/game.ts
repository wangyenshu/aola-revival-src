// 奥拉星 2013 game server on top of the generic 2013 room protocol.
// Grows command by command as rebuilt and original modules ask for them;
// every unhandled extension call is logged with its parameters.

import type { Emulator } from "../../core/emulator.ts";
import { installPets, followVar, newPet, nameOf, speciesOf, detailOf, NO_FOLLOW, type PetRecord, type PetTables, type SpeciesTable } from "./pets.ts";
import { installBattles, gainExp, type WildEntry } from "./battle.ts";
import { installTasks, registerTaskTables, stepsByItems, type RobotRecord, type TaskTables, type UserTaskRec } from "./tasks.ts";
import { EMPTY_PMDATA, type PmData } from "./pmdata.ts";
import { installHouse, houseOf, usedUp, type HouseRecord } from "./house.ts";
import { installShoot, type CardRow } from "./shoot.ts";
import { installPlants, plantTree, type PlantRec } from "./plants.ts";
import { installEggs, type HatchRec } from "./eggs.ts";
import { installZoo, type ZooRec } from "./zoo.ts";
import { World, type XtContext } from "./server.ts";

export interface UserRecord {
  id: number;
  name: string;
  /** Worn clothes, as the "avatar" user variable carries them ("id;id;…"). */
  avatar?: string;
  createdAt?: string;
  /** 晶币. */
  score?: number;
  /** Owned materials: type -> id -> quantity (type 0 clothes, 1 furniture, 2 items, …). */
  items?: Record<string, Record<string, number>>;
  /** 亚比 carried (at most 6; the first fights first). */
  pets?: PetRecord[];
  nextPetId?: number;
  followPet?: number;
  /** 亚比 that did not fit in the bag. */
  storage?: PetRecord[];
  /** Experience of the 捕捉等级. */
  catchExp?: number;
  /** The starting balls and sweets were given. */
  kit?: boolean;
  /** The home: main house id and what stands in each house. */
  house?: HouseRecord;
  /** Gathering today: {day, item id -> times}. */
  gathered?: { day: string; n: Record<string, number> };
  /** Tasks (TaskExtension): task or step id -> state. */
  tasks?: Record<string, UserTaskRec>;
  /** The HELLO, once the newbie quest has given it. */
  robot?: RobotRecord;
  /** 晶币 won in mini games today. */
  gameCoins?: { day: string; n: number };
  /** 星币 (UserInfo.xingbi) and 晶豆 (a later currency; kept for the toolbox only). */
  xingbi?: number;
  jingdou?: number;
  /** 蓝宝石 (member), set with the toolbox. */
  vip?: boolean;
  /** The trees of the 家园 (plants.ts). */
  plants?: PlantRec[];
  nextPlantId?: number;
  /** The eggs in the 亚比孵化器 of the 家园 (eggs.ts). */
  hatch?: HatchRec;
  /** 保卫战 progress per place (zoo.ts). */
  td?: Record<string, string[]>;
  /** The 动物园 (zoo.ts). */
  zoo?: ZooRec;
  /** 黑星堡垒: the highest floor reached and whether it was passed (VipTowerExtension). */
  vipTower?: { fl: number; ps: boolean };
  /** 欢乐岛 today: seconds used, seconds bought (增加时长 bought n times), 双倍经验. */
  hotSpring?: { day: string; used: number; extra: number; adds: number; double: boolean };
}

/**
 * Starting outfit for a new player. The server-side default is not in any
 * surviving file; this is the 酷蓝 set (clothes 126–132 in the 2013
 * materialdata: hair, cape, suit, trousers, boots, eyes), one of the free
 * outfits the client data marks as not for sale, over the bare head and body
 * (BASE_CLOTHES).
 */
export const DEFAULT_AVATAR = "6;7;126;127;129;130;131;132";

/**
 * The bare head and body (clothes 6 _底色头部 and 7 _底色身体, hidden from the
 * wardrobe by their "_" names): always worn, under everything. The big
 * avatar of the 形象卡 draws the legs and arms from 7 (its parts
 * DI_SE__QU_GAN_HE_TUI, DI_SE__SHOU_BI_*); without it the trousers float
 * above the shoes.
 */
export const BASE_CLOTHES = ["6", "7"];

/**
 * 晶币 a new player starts with. Not in any surviving file (the 2013 server
 * is lost); enough for a few pieces from the clothes catalog (most cost
 * 300–700), so the shops can be tried at once.
 */
export const START_SCORE = 2000;

/**
 * Items a player starts with: 3 初级体力糖 (RECONSTRUCTED). The first 亚比球
 * are bought from 米娜 in the newbie quest (step 143).
 */
export const START_ITEMS: Record<string, number> = { "30": 3 };

/** Price table written by tools/gen_materials.py: type -> id -> [price, buyback, rmb, maxQ, vip, name]. */
export type MaterialTable = Record<string, Record<string, [number, number, number, number, number, string]>>;

export interface Sfs2013Options {
  /** Read a JSON file next to the game files (www.9aola.com/<path>); used for revival/materials.json. */
  loadJson?: (path: string) => Promise<unknown>;
  /** Test commands for the automated walk-throughs (PocketMonsterExtension.revival_give). Never on for players. */
  dev?: boolean;
}

/**
 * Inventory requests the original 2013 material services send while the game
 * starts, with the reply field each one reads (from the decompiled 2012/13
 * services). Lists the revival does not keep yet stay empty; each service
 * then finishes its init and the game carries on.
 */
const EMPTY_INVENTORY: Record<string, Record<string, unknown>> = {
  "MaterialExtension.61_5": { pd: [] }, // PetClothesService
  "MaterialExtension.61_6": { clothes: [] }, // RobotClothesService
  "MaterialExtension.61_7": { cards: [] }, // PetCardService
  "MaterialExtension.61-8": { cards: [] }, // PetCard2Service
  "PlantItemExtension.81_2": { items: [] }, // PlantItemService
  "RobotExtension.2-6": { i: [] }, // RobotItemService
  "SundriesExtension.70-1": { b: [] }, // BadgeService
};

/** 欢乐岛: seconds of 冲浪 a day (HotSpringConfig.DefaultLeftTime) and experience every 3 seconds (RECONSTRUCTED). */
export const HOT_SPRING_SECONDS = 900;
export const HOT_SPRING_EXP = 20;

const userKey = (name: string) => `user/${encodeURIComponent(name)}`;

async function userRecord(emu: Emulator, name: string): Promise<UserRecord | undefined> {
  const rec = await emu.store.get<UserRecord>(userKey(name));
  if (rec) normalise(rec);
  return rec;
}

/** Older saves predate money and inventory: give them the defaults. */
function normalise(rec: UserRecord): UserRecord {
  if (!rec.avatar) rec.avatar = DEFAULT_AVATAR;
  const wornNow = rec.avatar.split(";").filter(Boolean);
  for (const id of BASE_CLOTHES) if (!wornNow.includes(id)) wornNow.unshift(id);
  rec.avatar = wornNow.join(";");
  if (rec.score == null) rec.score = START_SCORE;
  if (!rec.items) rec.items = {};
  const clothes = (rec.items["0"] ??= {});
  for (const id of rec.avatar.split(";").filter(Boolean)) clothes[id] ??= 1;
  if (!rec.kit) {
    const items = (rec.items["2"] ??= {});
    for (const [id, q] of Object.entries(START_ITEMS)) items[id] = (items[id] ?? 0) + q;
    rec.kit = true;
  }
  houseOf(rec);
  return rec;
}

/** Mini game rates (RECONSTRUCTED): points per 晶币, 晶币 a game at most, 晶币 a day at most. */
export const GAME_SCORE_PER_COIN = 10;
export const GAME_COINS_PER_GAME = 200;
export const GAME_COINS_PER_DAY = 1000;

/**
 * The inverse of the 2013 client's Encrypt.encryptCode (a 7-digit score
 * shuffled, framed and turned into 9 digits).
 */
export function decryptScore(code: number): number {
  const EVEN = [1, 3, 6, 0, 9, 5, 2, 7, 4, 8];
  const ODD = [2, 7, 4, 8, 1, 3, 6, 0, 9, 5];
  const POS = [2, 5, 3, 0, 6, 4, 1];
  const c = String(Math.max(0, Math.floor(code))).padStart(9, "0").slice(-9).split("").map(Number);
  const b = c.map((v, i) => (i % 2 === 1 ? ODD : EVEN).indexOf(v));
  const p: number[] = [];
  p[0] = (b[0] - 7 + 10) % 10;
  for (let i = 1; i < 9; i++) p[i] = (b[i] - p[i - 1] + 10) % 10;
  const a = p.slice(1, 8);
  const d: number[] = new Array(7).fill(0);
  for (let i = 0; i < 7; i++) d[POS[i]] = a[i];
  return Number(d.join(""));
}

export function installSfs2013(emu: Emulator, opts: Sfs2013Options = {}): World {
  let materials: Promise<MaterialTable> | undefined;
  const table = () =>
    (materials ??= (opts.loadJson ? opts.loadJson("revival/materials.json") : Promise.resolve({}))
      .then((t) => (t ?? {}) as MaterialTable)
      .catch(() => ({}) as MaterialTable));

  const json = <T>(path: string, empty: T) => (opts.loadJson ? opts.loadJson(path) : Promise.resolve(empty)).then((t) => (t ?? empty) as T).catch(() => empty);
  let petTables: Promise<PetTables> | undefined;
  const tables = () =>
    (petTables ??= Promise.all([json<SpeciesTable>("revival/pets.json", {}), json<PmData>("revival/pmdata.json", EMPTY_PMDATA)]).then(
      ([species, pm]) => ({ species, pm }),
    ));
  let wildTable: Promise<Record<string, WildEntry[]>> | undefined;
  const wild = () => (wildTable ??= json<Record<string, WildEntry[]>>("revival/wildpets.json", {}));

  const world = new World(emu, {
    login: async (_zone, user) => {
      const name = user || "小奥拉";
      let rec = await userRecord(emu, name);
      if (!rec) {
        const next = ((await emu.store.get<number>("meta/nextUserId")) ?? 10000) + 1;
        await emu.store.set("meta/nextUserId", next);
        rec = normalise({ id: next, name, avatar: DEFAULT_AVATAR, createdAt: emu.clock.now().toISOString() });
      }
      await emu.store.set(userKey(name), rec);
      // The 2013 client reads the worn clothes as "avatar" (SocketClient) and "c" (ClothesService).
      const follow = rec.pets?.find((p) => p.id === rec!.followPet);
      return {
        id: rec.id,
        name: rec.name,
        vars: { avatar: rec.avatar, c: rec.avatar, nn: rec.name, mtype: rec.vip ? 4 : 0, p: follow ? followVar(follow) : NO_FOLLOW },
      };
    },
  });

  const save = (rec: UserRecord) => emu.store.set(userKey(rec.name), rec);
  const me = async (ctx: XtContext) => (await userRecord(emu, ctx.player.name))!;

  for (const [key, reply] of Object.entries(EMPTY_INVENTORY)) {
    world.xt(key, (ctx) => ctx.reply(structuredClone(reply)));
  }

  // ---------------------------------------------------------------- inventory

  // ClothesService: owned clothes as "id,wearing;id,wearing".
  world.xt("MaterialExtension.getUserClothes", async (ctx) => {
    const un = String((ctx.params as { un?: string })?.un ?? ctx.player.name);
    const rec = await userRecord(emu, un);
    const worn = new Set((rec?.avatar ?? DEFAULT_AVATAR).split(";").filter(Boolean));
    const owned = Object.keys(rec?.items?.["0"] ?? {});
    for (const id of worn) if (!owned.includes(id)) owned.push(id);
    ctx.reply({ un, cl: owned.map((id) => `${id},${worn.has(id) ? 1 : 0}`).join(";") });
  });

  // ClothesService.updateMyWearingClothes: {cid: "id,id"} = clothes whose worn state flips.
  world.xt("MaterialExtension.updateMyWearingClothes", async (ctx) => {
    const rec = await me(ctx);
    const worn = new Set(rec.avatar!.split(";").filter(Boolean));
    for (const id of String(ctx.params.cid ?? "").split(",").filter(Boolean)) {
      if (!rec.items!["0"]?.[id] || BASE_CLOTHES.includes(id)) continue;
      if (worn.has(id)) worn.delete(id);
      else worn.add(id);
    }
    rec.avatar = [...worn].join(";");
    await save(rec);
    world.setUserVars(ctx.session, { avatar: rec.avatar, c: rec.avatar });
    ctx.reply({ res: "true", cid: ctx.params.cid });
  });

  // FurnitureService (61_1, {uid}) and ItemService (GatherClient 14_2): owned lists.
  world.xt("MaterialExtension.61_1", async (ctx) => {
    const rec = await me(ctx);
    const f = rec.items!["1"] ?? {};
    const used = usedUp(rec);
    ctx.reply({ furnitures: Object.entries(f).map(([id, q]) => ({ id: Number(id), qt: q, uq: Math.min(q, used[id] ?? 0) })) });
  });
  world.xt("MaterialExtension.14_2", async (ctx) => {
    const rec = await me(ctx);
    const it = rec.items!["2"] ?? {};
    ctx.reply({ userms: Object.entries(it).map(([id, q]) => ({ mi: Number(id), qt: q, uq: 0 })), period: [] });
  });

  // ---------------------------------------------------------------- money

  world.xt("ScoreManager.getTotalScore", async (ctx) => {
    const rec = await me(ctx);
    ctx.reply({ userId: rec.id, totalScore: rec.score });
  });

  // Mini games: SocketClient.endGame -> ScoreManager.increaseScore {score (encrypted, Encrypt.encryptCode),
  // level, exitWay, gameName} -> increaseScore {scoreAdded, state, got}; the games show scoreAdded as
  // the 晶币 won and a tip for state -1/-2/-3. The 2013 rates are lost: RECONSTRUCTED as one 晶币 per
  // GAME_SCORE_PER_COIN points, at most GAME_COINS_PER_GAME a game and GAME_COINS_PER_DAY a day (then state -1).
  world.xt("ScoreManager.increaseScore", async (ctx) => {
    const rec = await me(ctx);
    const points = Math.max(0, decryptScore(Number(ctx.params.score) || 0));
    const day = emu.clock.now().toISOString().slice(0, 10);
    if (rec.gameCoins?.day !== day) rec.gameCoins = { day, n: 0 };
    let coins = Math.min(GAME_COINS_PER_GAME, Math.floor(points / GAME_SCORE_PER_COIN));
    let state = 1;
    if (rec.gameCoins.n + coins > GAME_COINS_PER_DAY) {
      coins = Math.max(0, GAME_COINS_PER_DAY - rec.gameCoins.n);
      state = -1;
    }
    rec.gameCoins.n += coins;
    rec.score = (rec.score ?? 0) + coins;
    await save(rec);
    if (coins > 0) ctx.reply({ score: rec.score }, "onScoreUpdated");
    ctx.reply({ scoreAdded: coins, state, got: false, score: rec.score, points, gameName: String(ctx.params.gameName ?? "") }, "increaseScore");
  });

  // MaterialClient.buyBack (61_2) {tp, mi, qt}: the 兜兜回收器 buys things back for their buyback
  // price in 晶币 (the 2013 material data's). Worn clothes and things without a buyback price stay.
  //   -> 61_2 {result (1, -1 cannot, -2 not that many), tp, mi, qt, score (晶币 got)}, onAmountUpdated, onScoreUpdated
  world.xt("MaterialExtension.61_2", async (ctx) => {
    const tp = String(Number(ctx.params.tp ?? 0) | 0);
    const mi = String(Number(ctx.params.mi ?? 0) | 0);
    const qt = Math.max(1, Number(ctx.params.qt ?? 1) | 0);
    const rec = await me(ctx);
    const row = (await table())[tp]?.[mi];
    const owned = ((rec.items ??= {})[tp] ??= {});
    const fail = (result: number) => ctx.reply({ result, tp: Number(tp), mi: Number(mi), qt, score: 0 });
    const worn = tp === "0" && String(rec.avatar ?? "").split(";").includes(mi);
    if (!row || row[1] <= 0 || worn) return fail(-1);
    if ((owned[mi] ?? 0) < qt) return fail(-2);
    owned[mi] -= qt;
    if (owned[mi] <= 0) delete owned[mi];
    const got = row[1] * qt;
    rec.score = Math.min(9_999_999, (rec.score ?? 0) + got);
    await save(rec);
    ctx.reply({ amount: `${tp}_${mi}_0_-${qt}` }, "onAmountUpdated");
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    ctx.reply({ result: 1, tp: Number(tp), mi: Number(mi), qt, score: got });
  });

  // MaterialClient.buyMaterial: {tp, mi, qt, ed}. Replies {res} (1 ok, -1 not for sale, -2 too little 晶币,
  // -4 already owned, -5 too little 星币, -6 for 蓝宝石 only); on success pushes onScoreUpdated (or
  // onXingBiUpdate) and onAmountUpdated (the original AmountUpdateService adds the item on the client).
  // Goods of real money (rmb) cost their price in 星币, half for 蓝宝石 (the "蓝宝石价" the era pages
  // print); the 星币 come from the toolbox (RECONSTRUCTED: the 2013 payment server is lost).
  world.xt("MaterialExtension.buyMaterial", async (ctx) => {
    const tp = String(ctx.params.tp ?? "0");
    const mi = String(ctx.params.mi ?? "0");
    const qt = Math.max(1, Number(ctx.params.qt ?? 1) | 0);
    const row = (await table())[tp]?.[mi];
    const rec = await me(ctx);
    const owned = (rec.items![tp] ??= {});
    const fail = (res: number) => ctx.reply({ res, tp: Number(tp), mi: Number(mi), qt });
    if (!row) return fail(-1);
    if (tp === "9") {
      // A tree of the 种植手册: it goes into the 植树盆 of the 家园 (plants.ts).
      const tree = plantTree(rec, Number(mi));
      if (typeof tree === "number") return fail(tree === -2 ? -2 : -4);
      await save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      ctx.reply({ amount: `9_${mi}_0_1_${tree.id}` }, "onAmountUpdated");
      return ctx.reply({ res: 1, tp: 9, mi: Number(mi), qt: 1, score: rec.score });
    }
    const [price, buyback, rmb, maxQ, vipOnly] = row;
    const unit = price > 0 ? price : buyback * 2;
    if (vipOnly && !rec.vip) return fail(-6);
    if ((owned[mi] ?? 0) + qt > Math.max(1, maxQ)) return fail(-4);
    if (unit <= 0 && rmb > 0) {
      const coins = (rec.vip ? Math.ceil(rmb / 2) : rmb) * qt;
      if ((rec.xingbi ?? 0) < coins) return fail(-5);
      rec.xingbi = (rec.xingbi ?? 0) - coins;
      owned[mi] = (owned[mi] ?? 0) + qt;
      await save(rec);
      ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
      ctx.reply({ amount: `${tp}_${mi}_0_${qt}` }, "onAmountUpdated");
      return ctx.reply({ res: 1, tp: Number(tp), mi: Number(mi), qt, xingbi: rec.xingbi });
    }
    const cost = unit * qt;
    if (rec.score! < cost) return fail(-2);
    rec.score! -= cost;
    owned[mi] = (owned[mi] ?? 0) + qt;
    await save(rec);
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    ctx.reply({ amount: `${tp}_${mi}_0_${qt}` }, "onAmountUpdated");
    ctx.reply({ res: 1, tp: Number(tp), mi: Number(mi), qt, score: rec.score });
  });

  // ---------------------------------------------------------------- gathering

  // GatherService (the original gather/gather): fruit, ore and soil points in scenes.
  //   14_14 {ItemId}      -> {ItemId, result}  0 may gather, 1 picked clean for today, 2 owns too many
  //   14_11 {ItemId, iw}  -> {result: 1, itemId, qt}, and the item arrives through onAmountUpdated
  // The 2013 limits are lost: RECONSTRUCTED as GATHER_PER_DAY times per item a day, up to the item's maxQ.
  const GATHER_PER_DAY = 10;
  const gatherState = (rec: UserRecord) => {
    const day = emu.clock.now().toISOString().slice(0, 10);
    if (rec.gathered?.day !== day) rec.gathered = { day, n: {} };
    return rec.gathered;
  };
  const gatherCheck = async (rec: UserRecord, mi: string) => {
    const row = (await table())["2"]?.[mi];
    const maxQ = row ? Math.max(1, row[3]) : 99;
    if ((gatherState(rec).n[mi] ?? 0) >= GATHER_PER_DAY) return 1;
    if ((rec.items!["2"]?.[mi] ?? 0) >= maxQ) return 2;
    return 0;
  };
  world.xt("MaterialExtension.14_14", async (ctx) => {
    const mi = String(Number(ctx.params.ItemId));
    ctx.reply({ ItemId: Number(mi), result: await gatherCheck(await me(ctx), mi) });
  });
  world.xt("MaterialExtension.14_11", async (ctx) => {
    const mi = String(Number(ctx.params.ItemId));
    const rec = await me(ctx);
    if ((await gatherCheck(rec, mi)) !== 0) return ctx.reply({ result: 2, itemId: Number(mi), qt: 0 });
    const qt = 1;
    const st = gatherState(rec);
    st.n[mi] = (st.n[mi] ?? 0) + 1;
    const items = (rec.items!["2"] ??= {});
    items[mi] = (items[mi] ?? 0) + qt;
    await save(rec);
    ctx.reply({ amount: `2_${mi}_0_${qt}` }, "onAmountUpdated");
    ctx.reply({ result: 1, itemId: Number(mi), qt });
  });

  // Items a quest's script hands out or takes (the era GatherClient):
  //   14_8 collectItem {ii, qt}, 14_6 collectItemOnce {ii, qt} (only while the player has none),
  //   14_7 decreaseMyItem {ii, qt}; the items (道具, type 2) arrive through onAmountUpdated, and the
  //   quest steps waiting for them finish (tasks.ts stepsByItems). No reply of the 2013 server to
  //   these survives, and the scripts wait for none. RECONSTRUCTED.
  const questItem = async (ctx: XtContext, once: boolean, sign: number) => {
    const mi = String(Number(ctx.params.ii));
    const qt = Math.max(1, Number(ctx.params.qt) | 0);
    const rec = await me(ctx);
    const items = (rec.items!["2"] ??= {});
    if (once && (items[mi] ?? 0) > 0) return;
    const row = (await table())["2"]?.[mi];
    const maxQ = row ? Math.max(1, row[3]) : 999;
    const before = items[mi] ?? 0;
    const after = sign > 0 ? Math.min(maxQ, before + qt) : Math.max(0, before - qt);
    if (after === before) return;
    if (after > 0) items[mi] = after;
    else delete items[mi];
    ctx.reply({ amount: `2_${mi}_0_${after - before}` }, "onAmountUpdated");
    const r = stepsByItems(rec, emu.clock.now().getTime());
    for (const [ii, n] of r.taken) ctx.reply({ amount: `2_${ii}_0_${-n}` }, "onAmountUpdated");
    for (const c of r.changes) ctx.reply({ t: c.t, ty: c.ty }, "10-1");
    if (r.score !== undefined) ctx.reply({ score: r.score }, "onScoreUpdated");
    await save(rec);
  };
  world.xt("MaterialExtension.14_8", (ctx) => questItem(ctx, false, 1));
  world.xt("MaterialExtension.14_6", (ctx) => questItem(ctx, true, 1));
  world.xt("MaterialExtension.14_7", (ctx) => questItem(ctx, false, -1));

  // ---------------------------------------------------------------- the toolbox (工具箱)
  // Not of 2013: the revival's own panel for testing and for players who want it
  // (rebuilt control, ToolboxPanel). SundriesExtension.revival_toolbox (the client
  // reaches the server only through the extensions it numbers)
  //   {score, xingbi, jingdou, exp}  adds that much (晶币 at most 9,999,999; exp to the
  //                                  first 亚比 of the bag, with its levels and evolutions)
  //   {raceId, level}                a new 亚比 (to the bag, or the 亚比仓库 when the bag is full)
  //   -> revival_toolbox {score, xingbi, jingdou, msg}, onScoreUpdated, and the 亚比 replies
  world.xt("SundriesExtension.revival_toolbox", async (ctx) => {
    const rec = await me(ctx);
    const p = ctx.params;
    const t = await tables();
    const add = (v: unknown) => Math.max(0, Math.min(9_999_999, Number(v) | 0));
    const said: string[] = [];
    if (add(p.score)) {
      rec.score = Math.min(9_999_999, (rec.score ?? 0) + add(p.score));
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      said.push(`晶币 +${add(p.score)}`);
    }
    if (add(p.xingbi)) {
      rec.xingbi = Math.min(9_999_999, (rec.xingbi ?? 0) + add(p.xingbi));
      ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
      said.push(`星币 +${add(p.xingbi)}`);
    }
    if (p.vip != null) {
      // 蓝宝石 (MemberTypes.Member, 4): the user variable "mtype" others see, MemberManager on the client.
      rec.vip = !!p.vip;
      world.setUserVars(ctx.session, { mtype: rec.vip ? 4 : 0 });
      said.push(rec.vip ? "你成为了蓝宝石！" : "你不再是蓝宝石了");
    }
    if (add(p.jingdou)) {
      rec.jingdou = Math.min(9_999_999, (rec.jingdou ?? 0) + add(p.jingdou));
      said.push(`晶豆 +${add(p.jingdou)}`);
    }
    if (add(p.exp)) {
      const pet = rec.pets?.[0];
      if (!pet) said.push("背包里没有亚比，经验没有加上");
      else {
        const r = gainExp(t, pet, add(p.exp));
        for (const [cmd, body] of r.msgs) ctx.reply(body, cmd);
        if (r.evolvedTo && rec.followPet === pet.id) world.setUserVars(ctx.session, { p: followVar(pet) });
        said.push(`${nameOf(t, pet.race)} 经验 +${add(p.exp)}（Lv${pet.level}）`);
      }
    }
    const race = Number(p.raceId) | 0;
    if (race > 0) {
      if (!speciesOf(t, race)) said.push(`没有编号为 ${race} 的亚比`);
      else {
        const pet = newPet(rec, t, race, Math.max(1, Math.min(100, Number(p.level) || 5)), today());
        if ((rec.pets ??= []).length < 6) {
          rec.pets.push(pet);
          ctx.reply({ pm: detailOf(pet, rec, t) }, "2201");
          said.push(`得到了 Lv${pet.level} ${nameOf(t, race)}`);
        } else {
          (rec.storage ??= []).push(pet);
          said.push(`得到了 Lv${pet.level} ${nameOf(t, race)}，背包满了，放进了亚比仓库`);
        }
      }
    }
    await save(rec);
    ctx.reply({ score: rec.score ?? 0, xingbi: rec.xingbi ?? 0, jingdou: rec.jingdou ?? 0, vip: !!rec.vip, msg: said.join("\n") }, "revival_toolbox");
  });

  // ---------------------------------------------------------------- pets

  const today = () => emu.clock.now().toISOString().slice(0, 10);
  installPets(world, { load: me, save: (o) => save(o as UserRecord), tables, today });
  installBattles(world, { load: me, save: (o) => save(o as UserRecord), tables, wild, today, now: () => emu.clock.now().getTime() });

  const taskTables = json<TaskTables>("revival/tasks.json", { defines: {}, starters: {} }).then(registerTaskTables);
  installTasks(world, { load: me, save: (o) => save(o as UserRecord), now: () => emu.clock.now().getTime(), ready: taskTables, dev: opts.dev });

  installHouse(world, {
    me,
    find: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
  });

  installPlants(world, {
    me,
    find: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
  });

  installEggs(world, {
    me,
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
    hatchPet: async (o, race, level) => {
      const pet = newPet(o as UserRecord, await tables(), race, level, today());
      ((o as UserRecord).storage ??= []).push(pet);
      return pet.id;
    },
  });

  installZoo(world, {
    me,
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
    byName: (name) => userRecord(emu, name),
    givePet: async (o, race) => {
      const t = await tables();
      if (!t.species[String(race)]) return undefined;
      const pet = newPet(o as UserRecord, t, race, 1, today());
      ((o as UserRecord).storage ??= []).push(pet);
      return t.species[String(race)].n;
    },
  });

  // 黑星堡垒 (viparena, VipArenaClient, VipTowerExtension): the floors one has reached and passed
  // (VipArenaLevelManager). Floor n is reached on entering its first room (viparena1, 4, 7) and
  // passed by beating its boss; the next one opens once the last is passed.
  //   84_1 {} -> {fl, ps}   84_2 {fl} -> {res, fl}   84_3 {rm} -> {rm: "race:lv:cc#…"}   84_4 {fl} -> {res, fl}
  // The rooms' roaming 亚比 (84_3) are lost with the 2013 server, and the era client places
  // none (VipArenaPetLocationMap is empty): only the floors' bosses fight (54_22 type 12).
  world.xt("VipTowerExtension.84_1", async (ctx) => {
    const rec = await me(ctx);
    ctx.reply({ fl: rec.vipTower?.fl ?? 0, ps: rec.vipTower?.ps ?? false });
  });
  world.xt("VipTowerExtension.84_2", async (ctx) => {
    const rec = await me(ctx);
    const fl = Math.max(1, Math.min(3, Number(ctx.params.fl) | 0));
    const v = (rec.vipTower ??= { fl: 0, ps: false });
    if (fl === v.fl + 1 && (v.fl === 0 || v.ps)) {
      v.fl = fl;
      v.ps = false;
      await save(rec);
    }
    ctx.reply({ res: 1, fl: v.fl });
  });
  world.xt("VipTowerExtension.84_3", async (ctx) => ctx.reply({ rm: "" }));
  world.xt("VipTowerExtension.84_4", async (ctx) => {
    const rec = await me(ctx);
    const fl = Number(ctx.params.fl) | 0;
    const v = (rec.vipTower ??= { fl: 0, ps: false });
    if (fl === v.fl && !v.ps) {
      v.ps = true;
      await save(rec);
    }
    ctx.reply({ res: 1, fl: v.fl });
  });

  // 欢乐岛 (scene summerhotspring, rebuilt; HotSpringExtension, ExtMap 67, the commands of the later
  // HotSpringClient): after the 更衣室 one 冲浪s for 15 minutes a day (HotSpringConfig.DefaultLeftTime
  // 900), gathering experience every 3 seconds, which goes to the HELLO's 经验分配器 on leaving.
  //   100_10 {id} -> {res, lt, db}   100_5 -> {lt, db}   100_12 {exp, sec} -> {res, exp, robotExp, lt}
  //   100_20 {id} (the revival's purchase: 1 增加时长 +5 min, 3 a day, 2 星币; 2 双倍经验, once, 11 星币,
  //   HotSpringPropConfig's 星币 prices) -> {res (1, -1 used up, -5 星币), id, lt, db}
  // The experience per 3 seconds is RECONSTRUCTED (HOT_SPRING_EXP; the 2020 module gives 1000).
  const hotSpring = (rec: UserRecord) => {
    const day = today();
    if (rec.hotSpring?.day !== day) rec.hotSpring = { day, used: 0, extra: 0, adds: 0, double: false };
    return rec.hotSpring!;
  };
  const left = (h: NonNullable<UserRecord["hotSpring"]>) => Math.max(0, HOT_SPRING_SECONDS + h.extra - h.used);
  world.xt("HotSpringExtension.100_10", async (ctx) => {
    const rec = await me(ctx);
    const h = hotSpring(rec);
    await save(rec);
    ctx.reply({ res: left(h) > 0 ? 1 : 0, lt: left(h), db: h.double ? 1 : 0 });
  });
  world.xt("HotSpringExtension.100_5", async (ctx) => {
    const rec = await me(ctx);
    const h = hotSpring(rec);
    ctx.reply({ lt: left(h), db: h.double ? 1 : 0 });
  });
  world.xt("HotSpringExtension.100_12", async (ctx) => {
    const rec = await me(ctx);
    const h = hotSpring(rec);
    const sec = Math.max(0, Math.min(left(h), Number(ctx.params.sec) | 0));
    const cap = Math.floor(sec / 3) * HOT_SPRING_EXP * (h.double ? 2 : 1);
    const exp = Math.max(0, Math.min(cap, Number(ctx.params.exp) | 0));
    h.used += sec;
    if (exp > 0) (rec.robot ??= { name: "HELLO", exp: 0, follow: true, born: today() }).exp += exp;
    await save(rec);
    ctx.reply({ res: 1, exp, robotExp: rec.robot?.exp ?? 0, lt: left(h) });
  });
  world.xt("HotSpringExtension.100_20", async (ctx) => {
    const rec = await me(ctx);
    const h = hotSpring(rec);
    const id = Number(ctx.params.id) | 0;
    const reply = (res: number) => ctx.reply({ res, id, lt: left(h), db: h.double ? 1 : 0, xingbi: rec.xingbi ?? 0 });
    const price = id === 1 ? 2 : id === 2 ? 11 : 0;
    if (!price || (id === 1 && h.adds >= 3) || (id === 2 && h.double)) return reply(-1);
    if ((rec.xingbi ?? 0) < price) return reply(-5);
    rec.xingbi = (rec.xingbi ?? 0) - price;
    if (id === 1) {
      h.adds += 1;
      h.extra += 300;
    } else h.double = true;
    await save(rec);
    ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
    reply(1);
  });

  // RobotClient.giveExp {pi, e}: the 家园's 经验分配器 hands experience the HELLO
  // keeps (tasks reward it, RobotClient 2-12) to a 亚比 of the bag.
  //   -> "2-13" {res, pi, e, exp} (res 1, -1 no such 亚比, -2 not that much), and the 亚比 replies
  world.xt("RobotExtension.2-13", async (ctx) => {
    const rec = await me(ctx);
    const pi = Number(ctx.params.pi) | 0;
    const want = Math.max(0, Number(ctx.params.e) | 0);
    const pet = (rec.pets ?? []).find((p) => p.id === pi);
    const have = rec.robot?.exp ?? 0;
    if (!pet) return ctx.reply({ res: -1, pi, e: 0, exp: have }, "2-13");
    if (want <= 0 || want > have || !rec.robot) return ctx.reply({ res: -2, pi, e: 0, exp: have }, "2-13");
    const t = await tables();
    rec.robot.exp = have - want;
    const r = gainExp(t, pet, want);
    for (const [cmd, body] of r.msgs) ctx.reply(body, cmd);
    if (r.evolvedTo && rec.followPet === pet.id) world.setUserVars(ctx.session, { p: followVar(pet) });
    await save(rec);
    ctx.reply({ res: 1, pi, e: want, exp: rec.robot.exp, lv: pet.level }, "2-13");
  });

  installShoot(world, {
    me,
    save: (o) => save(o as UserRecord),
    cards: async () => ((await table())["4"] ?? {}) as unknown as Record<string, CardRow>,
  });

  // ---------------------------------------------------------------- test commands

  if (opts.dev) {
    // revival_give {mi, qt[, t]}: materials (type t, items 2 by default) for a test run, sent through onAmountUpdated.
    world.xt("PocketMonsterExtension.revival_give", async (ctx) => {
      const rec = await me(ctx);
      const mi = String(Number(ctx.params.mi));
      const qt = Math.max(1, Number(ctx.params.qt) || 1);
      const t = String(Number(ctx.params.t ?? 2) | 0 || 2);
      const items = ((rec.items ??= {})[t] ??= {});
      items[mi] = (items[mi] ?? 0) + qt;
      await save(rec);
      ctx.reply({ amount: `${t}_${mi}_0_${qt}` }, "onAmountUpdated");
    });
  }

  // ---------------------------------------------------------------- misc

  // RobotDataService: days since the account was made.
  // Click counters the 2013 client sends (SundriesExtension 70_8 {id},
  // 70_12 {type}): the server only counted them; nothing comes back.
  world.xt("SundriesExtension.70_8", () => {});
  world.xt("SundriesExtension.70_12", () => {});

  world.xt("UserExtension.getLifeDay", async (ctx) => {
    const rec = await me(ctx);
    const made = rec?.createdAt ? new Date(rec.createdAt).getTime() : emu.clock.now().getTime();
    ctx.reply({ life: Math.max(1, Math.floor((emu.clock.now().getTime() - made) / 86400000) + 1) });
  });

  return world;
}
