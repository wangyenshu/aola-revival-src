// 奥拉星 2013 game server on top of the generic 2013 room protocol.
// Grows command by command as rebuilt and original modules ask for them;
// every unhandled extension call is logged with its parameters.

import type { Emulator } from "../../core/emulator.ts";
import { installPets, maxHpOf, followVar, newPet, nameOf, speciesOf, detailOf, NO_FOLLOW, type PetRecord, type PetTables, type SpeciesTable } from "./pets.ts";
import { installBattles, gainExp, type WildEntry } from "./battle.ts";
import { installPetDic } from "./petdic.ts";
import { installPetItems, type Boosts } from "./petitems.ts";
import { checkPass, hashPass, nameProblem, LOCKED, PassGuard, type AccountOptions, type PassRec } from "./accounts.ts";
import { adoptRecord, fileProblem, jsonBytes, playerFile, rolesOf, SAVE_RECORD_MAX, type SaveFile } from "./saves.ts";
import { installSocial } from "./social.ts";
import { installTasks, isQuestItem, registerTaskTables, robotVar, stepsByItems, QUEST_REWARDS, type RobotRecord, type TaskTables, type UserTaskRec } from "./tasks.ts";
import { EMPTY_PMDATA, type PmData } from "./pmdata.ts";
import { installPetCards } from "./petcards.ts";
import { installHouse, houseOf, usedUp, type HouseRecord, type Visits } from "./house.ts";
import { installShoot, type CardRow } from "./shoot.ts";
import { installPlants, plantTree, type PlantRec } from "./plants.ts";
import { installEggs, type HatchRec } from "./eggs.ts";
import { installZoo, type ZooRec } from "./zoo.ts";
import { installParkour, type ParkourRankRow, type ParkourRec } from "./parkour.ts";
import { installMiniGames, type LimitBombRec, type LimitBombRow } from "./minigames.ts";
import { installPlanetActs } from "./planetacts.ts";
import { installAreaFuncs, type AreaRec } from "./areafuncs.ts";
import { fuseCollect, fuseState, installYabiStudy, type LabDeps, type LabRec } from "./yabistudy.ts";
import { installMods, stashModPets, type ModRec } from "./mods.ts";
import { World, type XtContext } from "./server.ts";
import { isGiftBag, openGiftBag, openHeldGiftBags } from "./giftbags.ts";

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
  /** 放生仓库 (pets.ts): 亚比 let go, kept a while. */
  released?: PetRecord[];
  /** 展示 (pets.ts revival_show): the 亚比 shown in the 家园. */
  showPet?: number;
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
  /** Fights asked for today with a 亚比 that comes out once a day only so often (70_6): race -> times. */
  dailyFights?: { day: string; n: Record<string, number> };
  /** 星币 (UserInfo.xingbi) and 晶豆 (a later currency: 极限轰炸 pays it; the toolbox shows it). */
  xingbi?: number;
  jingdou?: number;
  /** 蓝宝石 (member), set with the toolbox. */
  vip?: boolean;
  /** 亚比 of the 仓库 the HELLO trains (亚比训练, 2-14 / 2-15 / 2-16): lesson and start (ms). */
  training?: { pi: number; c: number; since: number }[];
  /** Friends and asks to be friends (social.ts), by player id. */
  friends?: number[];
  friendAsks?: number[];
  /** A shared server's password (accounts.ts). */
  pass?: PassRec;
  /** Mini games that open their levels one by one: game name -> the last level finished. */
  gameLevels?: Record<string, number>;
  /** Wins left of the 经验器, 学习器, 寻宝雷达 and 自动战斗仪 used (petitems.ts). */
  boosts?: Boosts;
  /** The trees of the 家园 (plants.ts). */
  plants?: PlantRec[];
  nextPlantId?: number;
  /** The eggs in the 亚比孵化器 of the 家园 (eggs.ts). */
  hatch?: HatchRec;
  /** 保卫战 progress per place (zoo.ts). */
  td?: Record<string, string[]>;
  /** The 动物园 (zoo.ts). */
  zoo?: ZooRec;
  /** 酷跑星世界 (parkour.ts). */
  parkour?: ParkourRec;
  /** 极限轰炸 (minigames.ts). */
  limitBomb?: LimitBombRec;
  /** 黑星堡垒: the highest floor reached and whether it was passed (VipTowerExtension). */
  vipTower?: { fl: number; ps: boolean };
  /** 欢乐岛 today: seconds used, seconds bought (增加时长 bought n times), 双倍经验. */
  hotSpring?: { day: string; used: number; extra: number; adds: number; double: boolean };
  /** 财富小管家's boxes: 晶币 put away (sc) on sd (ms) for d days. */
  fortune?: ({ sc: number; sd: number; d: number } | null)[];
  /** 欢乐弹珠机: the day its top prize was last given (once a day). */
  pinballTop?: string;
  /** 礼包 (giftbags.ts): the ones bought at least once, and 经验 waiting for the HELLO. */
  giftBags?: number[];
  helloExp?: number;
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
  /** A shared server: names with passwords (accounts.ts). Off for the one-player page. */
  accounts?: AccountOptions;
  /**
   * The 工具箱 (晶币, 亚比 … for nothing) and the 亚比 a mod gives: on (default), as in the page's
   * own game; a shared server's owner may close them (fair play: the others, 亚比对战).
   */
  toolbox?: boolean;
}

/**
 * Inventory requests the original 2013 material services send while the game
 * starts, with the reply field each one reads (from the decompiled 2012/13
 * services). Lists the revival does not keep yet stay empty; each service
 * then finishes its init and the game carries on.
 */
const EMPTY_INVENTORY: Record<string, Record<string, unknown>> = {
  "MaterialExtension.61_5": { pd: [] }, // PetClothesService
  "MaterialExtension.61-8": { cards: [] }, // PetCard2Service
  "SundriesExtension.70-1": { b: [] }, // BadgeService
};

/** 欢乐岛: seconds of 冲浪 a day (HotSpringConfig.DefaultLeftTime) and experience every 3 seconds (RECONSTRUCTED). */
export const HOT_SPRING_SECONDS = 900;
export const HOT_SPRING_EXP = 20;

const userKey = (name: string) => `user/${encodeURIComponent(name)}`;

const queues = new WeakMap<Emulator, Promise<unknown>>();
/** After an import ends an 奥拉's game: a moment for its requests still running to finish. */
export const IMPORT_SETTLE_MS = 300;
/** On a shared server, a connection that has not logged in within this is closed. */
export const LOGIN_WAIT_MS = 30_000;
/** What a quest's script hands out at once (14_8, 14_6), at most. */
export const QUEST_ITEM_MAX = 99;
/** Wrong passwords per name, whichever way they are tried (accounts.ts PassGuard). */
const guards = new WeakMap<Emulator, PassGuard>();
const guardOf = (emu: Emulator) => {
  let g = guards.get(emu);
  if (!g) guards.set(emu, (g = new PassGuard()));
  return g;
};
/**
 * The password of an 奥拉 of a shared server, tried from the client address addr: null if right,
 * else what to say. Wrong ones count towards the lock of that name from that address
 * (PassGuard), right ones clear it.
 */
async function passProblem(emu: Emulator, rec: UserRecord, pass: string | undefined, addr = ""): Promise<string | null> {
  const g = guardOf(emu);
  const key = `${rec.name}\u0000${addr}`;
  if (g.locked(key)) return LOCKED;
  if (!rec.pass || !pass || !(await checkPass(pass, rec.pass))) {
    g.failed(key);
    return "密码不对哦。";
  }
  g.passed(key);
  return null;
}

/**
 * Logins and renames of one server one after another: two at once could take one new player
 * id, sign one name up twice, or rename an 奥拉 as it logs in.
 */
function oneAtATime<T>(emu: Emulator, f: () => Promise<T>): Promise<T> {
  const r = (queues.get(emu) ?? Promise.resolve()).then(f, f);
  queues.set(emu, r.catch(() => {}));
  return r;
}

/** A new 奥拉 (the first login of a name, a new local 奥拉): the next id, the defaults; not saved yet. */
async function newUser(emu: Emulator, name: string): Promise<UserRecord> {
  const next = ((await emu.store.get<number>("meta/nextUserId")) ?? 10000) + 1;
  await emu.store.set("meta/nextUserId", next);
  return normalise({ id: next, name, avatar: DEFAULT_AVATAR, createdAt: emu.clock.now().toISOString() });
}

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
  openHeldGiftBags(rec);
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

/** How long after a table the site did not give it is asked again (siteTable). */
export const TABLE_RETRY_MS = 30_000;

/**
 * A table of the site (revival/*.json), kept once had. One not had (missing, or the site out of
 * reach a moment: the split setup reads the tables over the network) is the empty one meanwhile
 * and is asked again after retryMs, rather than kept empty until the server restarts.
 */
export function siteTable<T>(load: () => Promise<unknown>, empty: T, retryMs = TABLE_RETRY_MS, now = Date.now): () => Promise<T> {
  let kept: T | undefined;
  let asking: Promise<T> | undefined;
  let missedAt = -Infinity;
  return () => {
    if (kept !== undefined) return Promise.resolve(kept);
    if (asking) return asking;
    if (now() - missedAt < retryMs) return Promise.resolve(empty);
    asking = load()
      .then((t) => {
        if (t == null || typeof t !== "object") throw new Error("no table");
        return (kept = t as T);
      })
      .catch(() => {
        missedAt = now();
        return empty;
      })
      .finally(() => (asking = undefined));
    return asking;
  };
}

export function installSfs2013(emu: Emulator, opts: Sfs2013Options = {}): World {
  const site = (path: string): Promise<unknown> => (opts.loadJson ? opts.loadJson(path) : Promise.resolve(undefined));
  const table = siteTable<MaterialTable>(() => site("revival/materials.json"), {});
  const species = siteTable<SpeciesTable>(() => site("revival/pets.json"), {});
  const pmData = siteTable<PmData>(() => site("revival/pmdata.json"), EMPTY_PMDATA);
  // One object for the 亚比 tables (mods add their species to it, mods.ts), its parts as they come.
  const petTables: PetTables = { species: {}, pm: EMPTY_PMDATA };
  const tables = async (): Promise<PetTables> => {
    petTables.species = await species();
    petTables.pm = await pmData();
    return petTables;
  };
  const wild = siteTable<Record<string, WildEntry[]>>(() => site("revival/wildpets.json"), {});

  const world = new World(emu, {
    login: (zone, user, pass, s) => oneAtATime(emu, () => login(zone, user, pass, s.link.remote)),
    refuseDelayMs: opts.accounts?.required ? 1000 : 0,
    loginWaitMs: opts.accounts?.required ? LOGIN_WAIT_MS : 0,
  });
  async function login(_zone: string, user: string, pass: string, addr: string) {
    const name = (user || "小奥拉").trim();
    let rec = await userRecord(emu, name);
    // A shared server (accounts.ts): the name must be a fit one, and its password the one it
    // signed up with (the first login of a new name signs it up, when the server lets it).
    const acc = opts.accounts;
    if (acc?.required) {
      const bad = nameProblem(name);
      if (bad) return { id: 0, name, error: bad };
      if (!rec && !acc.register) return { id: 0, name, error: "没有这个奥拉，请先注册。" };
      if (!pass) return { id: 0, name, error: "请输入密码。" };
      if (rec?.pass) {
        const wrong = await passProblem(emu, rec, pass, addr);
        if (wrong) return { id: 0, name, error: wrong };
      } else if (rec) {
        if (!acc.adopt) return { id: 0, name, error: "这个奥拉还没有密码，请服务器的主人打开 --adopt 后再登录一次。" };
        rec.pass = await hashPass(pass);
      }
    }
    if (!rec) {
      rec = await newUser(emu, name);
      if (acc?.required && pass) rec.pass = await hashPass(pass);
    }
    // A mod's 亚比 the game does not know now (their mod not started yet in this page): aside.
    const known = await tables();
    stashModPets(rec as UserRecord & ModRec, (race) => !!speciesOf(known, race));
    await emu.store.set(userKey(name), rec);
    // id -> name, for the records that keep other players by id (social.ts friends).
    await emu.store.set(`uid/${rec.id}`, rec.name);
    // The 2013 client reads the worn clothes as "avatar" (SocketClient) and "c" (ClothesService).
    const follow = rec.pets?.find((p) => p.id === rec!.followPet);
    return {
      id: rec.id,
      name: rec.name,
      vars: { avatar: rec.avatar, c: rec.avatar, nn: rec.name, mtype: rec.vip ? 4 : 0, p: follow ? followVar(follow) : NO_FOLLOW },
    };
  }

  // A following 亚比 whose form changed (a level, an item, an activity): its room sees the new one.
  const syncFollow = (rec: UserRecord) => {
    const s = world.online(rec.name);
    const pet = rec.pets?.find((x) => x.id === rec.followPet);
    const [race, , id] = String(s ? world.player(s)?.vars.get("p")?.value ?? "" : "").split(",").map(Number);
    if (s && pet && id === pet.id && race !== pet.race) world.setUserVarOnce(s, "p", followVar(pet));
  };
  const save = async (rec: UserRecord) => {
    await emu.store.set(userKey(rec.name), rec);
    syncFollow(rec);
  };
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

  // ClothesService.getOthersAvatarInfo for a player not in the room (the 名片 from 好友): {un} -> the
  // clothes he wears ("id;id", as his user variable c).
  world.xt("MaterialExtension.getUserWearingClothes", async (ctx) => {
    const un = String((ctx.params as { un?: string })?.un ?? ctx.player.name).slice(0, 64);
    const rec = await userRecord(emu, un);
    ctx.reply({ un, cl: rec?.avatar ?? DEFAULT_AVATAR });
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
    world.setUserVars(ctx.session, { avatar: wornWithRide(rec), c: wornWithRide(rec) });
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

  // 财富小管家 (fortunemanager/fortunemanager, rebuilt; the later client's ScoreManager commands):
  //   getAccount {} -> {al: [{id, sc, sd, d}], now}; despositAccount {ai, sc, d} -> {b};
  //   takeAwawyAccount {ai} -> {res: 晶币 back or -1, interest}.
  // Five boxes, 1 to 7 days. Interest at the end: sc * d * d / 1000 (百田's guide of January 2012:
  // 500,000 晶币 for 7 days earn 24,500); taken out sooner: sc * whole days * 0.001 (the later panel's
  // figure), none in the first day. The limits (1000 to 1,000,000 a box) are RECONSTRUCTED.
  const FORTUNE_DAY = 24 * 3600 * 1000;
  world.xt("ScoreManager.getAccount", async (ctx) => {
    const rec = await me(ctx);
    const al = (rec.fortune ?? []).map((a, id) => (a ? { id, sc: a.sc, sd: a.sd, d: a.d } : null)).filter(Boolean);
    ctx.reply({ al, now: emu.clock.now().getTime() });
  });
  world.xt("ScoreManager.despositAccount", async (ctx) => {
    const rec = await me(ctx);
    const ai = Number(ctx.params.ai) | 0;
    const sc = Number(ctx.params.sc) | 0;
    const d = Number(ctx.params.d) | 0;
    const boxes = (rec.fortune ??= []);
    if (ai < 0 || ai > 4 || boxes[ai] || d < 1 || d > 7 || sc < 1000 || sc > 1_000_000 || (rec.score ?? 0) < sc) return ctx.reply({ b: false });
    rec.score = (rec.score ?? 0) - sc;
    boxes[ai] = { sc, sd: emu.clock.now().getTime(), d };
    await save(rec);
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    ctx.reply({ b: true });
  });
  world.xt("ScoreManager.takeAwawyAccount", async (ctx) => {
    const rec = await me(ctx);
    const ai = Number(ctx.params.ai) | 0;
    const a = rec.fortune?.[ai];
    if (!a) return ctx.reply({ res: -1, interest: 0 });
    const now = emu.clock.now().getTime();
    const interest = now >= a.sd + a.d * FORTUNE_DAY ? Math.floor((a.sc * a.d * a.d) / 1000) : Math.floor(a.sc * Math.floor((now - a.sd) / FORTUNE_DAY) * 0.001);
    rec.fortune![ai] = null;
    rec.score = (rec.score ?? 0) + a.sc + interest;
    await save(rec);
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    ctx.reply({ res: a.sc + interest, interest });
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
    // The level a game ended (or was finished) at, for the games that open their levels one by
    // one (极速3D赛车 gameMyCat: endGame(score, the level finished) when won, 0 when lost; 89_5).
    const game = String(ctx.params.gameName ?? "");
    const lv = Number(ctx.params.level) | 0;
    if (game && lv > 0) (rec.gameLevels ??= {})[game] = Math.max(rec.gameLevels[game] ?? 0, lv);
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
    const fail = (result: number) => ctx.reply({ result, tp: Number(tp), mi: Number(mi), qt, score: 0 });
    const worn = tp === "0" && String(rec.avatar ?? "").split(";").includes(mi);
    if (!row || row[1] <= 0 || worn) return fail(-1);
    const owned = ((rec.items ??= {})[tp] ??= {});
    // Furniture standing in the home, and the house in use, are not for sale (the house would
    // come back on the next load, houseOf, and could be sold again and again).
    const standing = tp === "1" ? (usedUp(rec)[mi] ?? 0) : 0;
    if ((owned[mi] ?? 0) - standing < qt) return fail(-2);
    owned[mi] -= qt;
    if (owned[mi] <= 0) delete owned[mi];
    // Never more than it costs in the shop (a few rows of the 2013 data buy back for more).
    const each = row[0] > 0 ? Math.min(row[1], row[0]) : row[1];
    const got = each * qt;
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
  // A 礼包 is opened at once (giftbags.ts): what it held comes through onAmountUpdated and the
  // reply's got ("三倍经验器×2、…") says it.
  world.xt("MaterialExtension.buyMaterial", async (ctx) => {
    const tp = String(ctx.params.tp ?? "0");
    const mi = String(ctx.params.mi ?? "0");
    const qt = Math.max(1, Number(ctx.params.qt ?? 1) | 0);
    const row = (await table())[tp]?.[mi];
    const rec = await me(ctx);
    // The 2015 欢乐弹珠机's buy panel reads result where the 2013 panels read res.
    const fail = (res: number) => ctx.reply({ res, result: res, tp: Number(tp), mi: Number(mi), qt });
    if (!row) return fail(-1);
    const owned = (rec.items![tp] ??= {});
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
    const tab = await table();
    // The bought thing into the bag (a 礼包: what it holds); the onAmountUpdated parts, what a bag gave.
    const deliver = (): { amount: string; got?: string; score?: boolean } => {
      if (!isGiftBag(tp, mi)) {
        owned[mi] = (owned[mi] ?? 0) + qt;
        return { amount: `${tp}_${mi}_0_${qt}` };
      }
      const op = openGiftBag(rec, Number(mi), qt, (t, id) => (t === "2" ? (tab["2"]?.[id]?.[3] ?? 9999) : 9999))!;
      return { amount: op.amounts.join("#"), got: op.got.join("、"), score: op.score };
    };
    if (vipOnly && !rec.vip) return fail(-6);
    if ((owned[mi] ?? 0) + qt > Math.max(1, maxQ)) return fail(-4);
    if (unit <= 0 && rmb > 0) {
      const coins = (rec.vip ? Math.ceil(rmb / 2) : rmb) * qt;
      if ((rec.xingbi ?? 0) < coins) return fail(-5);
      rec.xingbi = (rec.xingbi ?? 0) - coins;
      const d = deliver();
      await save(rec);
      ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
      if (d.score) ctx.reply({ score: rec.score }, "onScoreUpdated");
      if (d.amount) ctx.reply({ amount: d.amount }, "onAmountUpdated");
      return ctx.reply({ res: 1, tp: Number(tp), mi: Number(mi), qt, xingbi: rec.xingbi, ...(d.got !== undefined ? { got: d.got } : {}) });
    }
    const cost = unit * qt;
    if (rec.score! < cost) return fail(-2);
    rec.score! -= cost;
    const d = deliver();
    await save(rec);
    ctx.reply({ score: rec.score }, "onScoreUpdated");
    if (d.amount) ctx.reply({ amount: d.amount }, "onAmountUpdated");
    ctx.reply({ res: 1, result: 1, tp: Number(tp), mi: Number(mi), qt, score: rec.score, ...(d.got !== undefined ? { got: d.got } : {}) });
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
    // A 礼包 grows at no gather point (and would open itself on the next load).
    if (isGiftBag(2, mi) || (await gatherCheck(rec, mi)) !== 0) return ctx.reply({ result: 2, itemId: Number(mi), qt: 0 });
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
    // A quest hands out a few things at a time, and no 礼包 (it would open itself on the next load).
    const qt = Math.min(QUEST_ITEM_MAX, Math.max(1, Number(ctx.params.qt) | 0));
    // Handed out: only the 道具 the quest steps wait for (the scripts hand out nothing else).
    if (sign > 0 && !isQuestItem(Number(mi))) return;
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
  const toolbox = opts.toolbox ?? true;
  world.xt("SundriesExtension.revival_toolbox", async (ctx) => {
    const rec = await me(ctx);
    const p = ctx.params;
    // Closed (a shared server): the totals only (the game asks them at the start), no gifts.
    const gifts = ["score", "xingbi", "jingdou", "exp", "raceId", "vip"].some((k) => p[k] != null && p[k] !== 0 && p[k] !== "");
    if (!toolbox && gifts) {
      return ctx.reply({ score: rec.score ?? 0, xingbi: rec.xingbi ?? 0, jingdou: rec.jingdou ?? 0, vip: !!rec.vip, msg: "这个服务器关闭了工具箱。" }, "revival_toolbox");
    }
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
        if (r.evolvedTo && rec.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
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
  installPets(world, { load: me, save: (o) => save(o as UserRecord), tables, today, anyPet: toolbox || !!opts.dev, now: () => emu.clock.now().getTime() });
  installPetDic(world, { load: me, save: (o) => save(o as UserRecord), tables });
  installBattles(world, {
    load: me,
    save: (o) => save(o as UserRecord),
    tables,
    wild,
    today,
    now: () => emu.clock.now().getTime(),
    find: (name) => userRecord(emu, name),
  });
  installSocial(world, {
    load: me,
    save: (o) => save(o as UserRecord),
    byName: (name) => userRecord(emu, name),
    nameOf: (id) => emu.store.get<string>(`uid/${id}`),
  });
  // 战术卡 (petcards.ts).
  installPetCards(world, {
    load: me,
    save: (o) => save(o as UserRecord),
    maxHp: async (o, pet) => maxHpOf(pet as PetRecord, await tables()),
  });
  installPetItems(world, {
    load: me,
    save: (o) => save(o as UserRecord),
    tables,
    changedRace: (ctx, o, pet) => {
      if (o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
    },
  });

  const taskTables = siteTable<TaskTables>(
    () =>
      site("revival/tasks.json").then((t) => {
        if (t && typeof t === "object") registerTaskTables(t as TaskTables);
        return t;
      }),
    { defines: {}, starters: {} },
  );
  void taskTables();
  // A new 亚比 for the player: into the bag (2201 tells the client), or the 亚比仓库 when it is full.
  const givePetTo = async (rec: UserRecord, race: number, level: number): Promise<[string, Record<string, unknown>][]> => {
    const t = await tables();
    if (!speciesOf(t, race)) return [];
    const pet = newPet(rec, t, race, level, today());
    if ((rec.pets ??= []).length < 6) {
      rec.pets.push(pet);
      return [["2201", { pm: detailOf(pet, rec, t) }]];
    }
    (rec.storage ??= []).push(pet);
    return [];
  };
  installTasks(world, {
    load: me,
    byName: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
    ready: taskTables,
    dev: opts.dev,
    onFinish: async (o, task) => {
      const rw = QUEST_REWARDS[task];
      if (!rw) return [];
      const rec = o as UserRecord;
      const out: [string, Record<string, unknown>][] = [];
      if (rw.score) {
        rec.score = (rec.score ?? 0) + rw.score;
        out.push(["onScoreUpdated", { score: rec.score }]);
      }
      if (rw.petExp && rec.pets?.[0]) gainExp(await tables(), rec.pets[0], rw.petExp);
      for (const [type, ids] of Object.entries(rw.items ?? {})) {
        const bag = ((rec.items ??= {})[type] ??= {});
        for (const [id, n] of Object.entries(ids)) {
          bag[id] = (bag[id] ?? 0) + n;
          out.push(["onAmountUpdated", { amount: `${type}_${id}_0_${n}` }]);
        }
      }
      if (rw.vipPet && rec.vip) out.push(...(await givePetTo(rec, rw.vipPet, 1)));
      return out;
    },
  });

  // 坐骑 (the rebuilt pet/petride; PetClient2): 54_12 {pmId, cId} ride, 54_20 {} get off, 54_11 {pmId}
  // train. The 34 亚比 of the 2013 PetRideInfosMap and the 9 the later one adds up to 1651
  // (race: [ride clothes, speed, level]); only a 蓝宝骑士 rides. The ride clothes join the worn
  // ones in the "avatar" user variable while riding (not saved: a new login walks).
  const RIDE: Record<number, [number, number, number]> = {
    30: [10049, 1.2, 36], 45: [10047, 1.3, 36], 105: [10048, 1.2, 40], 141: [10051, 1.2, 36], 278: [10052, 1.5, 40], 138: [10050, 1.2, 36],
    198: [10053, 1.3, 36], 300: [10054, 1.2, 36], 189: [10055, 1.2, 40], 299: [10056, 1.3, 40], 153: [10057, 1.2, 40], 24: [10058, 1.2, 32],
    90: [10059, 1.3, 40], 481: [10060, 1.3, 40], 506: [10061, 1.5, 1], 290: [10062, 1.6, 40], 493: [10063, 1.3, 40], 391: [10064, 1.3, 40],
    388: [10065, 1.4, 40], 75: [10066, 1.25, 40], 215: [10067, 1.3, 40], 111: [10068, 1.3, 40], 624: [10069, 1.3, 40], 653: [10070, 1.4, 40],
    654: [10071, 1.3, 36], 741: [10072, 1.3, 40], 775: [10073, 1.3, 40], 794: [10074, 1.5, 40], 180: [10075, 1.3, 40], 838: [10076, 1.4, 40],
    1082: [10077, 1.4, 40], 1126: [10078, 1.4, 40], 1240: [10079, 1.3, 40], 1356: [10080, 1.3, 40],
    // The later client's 坐骑 up to 1651 (the revival's 亚比 go that far: the 工具箱).
    1101: [10089, 1.5, 40], 1122: [10087, 1.5, 42], 1350: [10086, 1.5, 40], 1423: [10083, 1.3, 40], 1426: [10088, 1.5, 40],
    1430: [10081, 1.3, 40], 1448: [10082, 1.3, 40], 1461: [10084, 1.3, 40], 1599: [10085, 1.3, 40],
  };
  const riding = new Map<string, { pmId: number; cloth: number }>();
  const wornWithRide = (rec: UserRecord) => {
    const r = riding.get(rec.name);
    return r ? `${rec.avatar};${r.cloth}` : (rec.avatar ?? "");
  };
  world.xt("PetExtension.54_12", async (ctx) => {
    const rec = await me(ctx);
    const pet = (rec.pets ?? []).find((p) => p.id === (Number(ctx.params.pmId) | 0));
    const ride = pet ? RIDE[pet.race] : undefined;
    if (!pet || !ride) return ctx.reply({ succ: false, msg: "这只亚比还不能骑乘哦！" }, "54_12");
    if (!rec.vip) return ctx.reply({ succ: false, msg: "只有蓝宝骑士才能骑乘亚比哦！" }, "54_12");
    if (pet.level < ride[2]) return ctx.reply({ succ: false, msg: `要到${ride[2]}级才能骑乘哦！` }, "54_12");
    riding.set(rec.name, { pmId: pet.id, cloth: ride[0] });
    world.setUserVars(ctx.session, { avatar: wornWithRide(rec), c: wornWithRide(rec) });
    ctx.reply({ succ: true, pmId: pet.id, cId: ride[0], sp: ride[1] }, "54_12");
  });
  world.xt("PetExtension.54_20", async (ctx) => {
    const rec = await me(ctx);
    riding.delete(rec.name);
    world.setUserVars(ctx.session, { avatar: rec.avatar, c: rec.avatar });
    ctx.reply({ succ: true }, "54_20");
  });
  world.xt("PetExtension.54_11", async (ctx) => ctx.reply({ succ: true, pmId: Number(ctx.params.pmId) | 0 }, "54_11"));

  // 纯白之翼的信念 (taskext/task1652): when its reward panel closes, a 蓝宝骑士 asks for 修普 (190),
  // once: SundriesExtension 70_52 {} -> 70_52 {bn} (the client then shows the 修普 egg).
  world.xt("SundriesExtension.70_52", async (ctx) => {
    const rec = await me(ctx);
    const r = rec as UserRecord & { gifts?: string[] };
    if (!rec.vip || rec.tasks?.["1652"]?.st !== 1 || (r.gifts ?? []).includes("1652")) return ctx.reply({}, "70_52");
    (r.gifts ??= []).push("1652");
    const msgs = await givePetTo(rec, 190, 1);
    await save(rec);
    for (const [cmd, body] of msgs) ctx.reply(body, cmd);
    ctx.reply({ bn: 1 }, "70_52");
  });

  installHouse(world, {
    me,
    find: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
    visits: {
      get: (id) => emu.store.get<Visits>(`visits/${id}`),
      set: (id, v) => emu.store.set(`visits/${id}`, v),
      nameOf: (id) => emu.store.get<string>(`uid/${id}`),
    },
    now: () => emu.clock.now().getTime(),
  });

  installPlants(world, {
    me,
    find: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
    // The 亚比 the owner 展示 (the 亚比仓库's, pets.ts revival_show): the garden shows it.
    shown: async (o) => {
      const r = o as UserRecord;
      const p = r.showPet ? [...(r.pets ?? []), ...(r.storage ?? [])].find((x) => x.id === r.showPet) : undefined;
      return p ? { i: p.id, r: p.race, lv: p.level, nm: p.nick || nameOf(await tables(), p.race) } : null;
    },
  });

  // The 沙盒's mods: their 亚比, gifts and saved data (mods.ts).
  installMods(world, {
    load: async (ctx) => (await me(ctx)) as UserRecord & ModRec,
    save: (o) => save(o),
    tables,
    today,
    gifts: toolbox,
  });

  // 亚比融合 and 天赋启迪 (亚比研究中心): yabistudy.ts.
  const labDeps: LabDeps<UserRecord & LabRec> = {
    load: async (ctx) => (await me(ctx)) as UserRecord & LabRec,
    save: (o) => save(o),
    now: () => emu.clock.now().getTime(),
    today,
    tables,
    get: (k) => emu.store.get(k),
    set: (k, v) => emu.store.set(k, v),
  };
  installYabiStudy(world, labDeps);

  installEggs(world, {
    me,
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
    hatchPet: async (o, race, level) => {
      const pet = newPet(o as UserRecord, await tables(), race, level, today());
      ((o as UserRecord).storage ??= []).push(pet);
      return pet.id;
    },
    fuse: {
      state: (o, st) => fuseState(o as UserRecord & LabRec, st, labDeps),
      collect: (o, id) => fuseCollect(o as UserRecord & LabRec, id),
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

  // 酷跑星世界 (game/parkour, HolidayExtension ActKuPaoStarWorld_*): its 金币 are the 晶币; the
  // list of the best runs is kept for everyone under parkour/board.
  installParkour(world, {
    load: me,
    save: (o) => save(o as UserRecord),
    today,
    now: () => emu.clock.now().getTime(),
    board: {
      get: async () => (await emu.store.get<ParkourRankRow[]>("parkour/board")) ?? [],
      set: (rows) => emu.store.set("parkour/board", rows),
    },
  });

  // 斑比向前冲 (game/ninja/ninjarush; UserGameExtension 89_bb1 / 89_bb2) and 极限轰炸 (game/limitbomb;
  // 89_18 … 89_23, its 排行榜 kept for everyone under limitbomb/board): minigames.ts.
  installMiniGames(world, {
    load: me,
    save: (o) => save(o as UserRecord),
    now: () => emu.clock.now().getTime(),
    pets: tables,
    board: {
      get: async () => (await emu.store.get<LimitBombRow[]>("limitbomb/board")) ?? [],
      set: (rows) => emu.store.set("limitbomb/board", rows),
    },
  });
  // The activities of the 2012 story planets (摩么卡, 亚伦, 巨锁石灵, 达黑黑, 白京京, 卡索, 阿莫, 波波嘟, 独角兽): planetacts.ts.
  installPlanetActs(world, {
    load: me,
    find: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
    tables,
    now: () => emu.clock.now().getTime(),
    today,
    givePet: (o, race, level) => givePetTo(o as UserRecord, race, level),
  });
  // The world map's 功能 of places (神奇摇摇树, 骑士王座, 星愿气球, 爱心协会 …): areafuncs.ts.
  installAreaFuncs(world, {
    load: async (ctx) => (await me(ctx)) as UserRecord & AreaRec,
    save: (o) => save(o as UserRecord),
    today,
    now: () => emu.clock.now().getTime(),
    get: (k) => emu.store.get(k),
    set: (k, v) => emu.store.set(k, v),
    pets: tables,
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
  // While one is in the spring, the user variable hs is his costume (1–5), so the others in the room
  // draw him in it (the scene's code); 100_12 clears it.
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
    // In the spring: the 更衣室's costume (1–5) for the others in the room to see (user variable hs).
    if (left(h) > 0) world.setUserVars(ctx.session, { hs: Math.min(5, Math.max(1, Number(ctx.params.id) | 0)) });
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
    world.setUserVars(ctx.session, { hs: null });
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
    if (r.evolvedTo && rec.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
    await save(rec);
    ctx.reply({ res: 1, pi, e: want, exp: rec.robot.exp, lv: pet.level }, "2-13");
  });

  // 亚比训练 (the HELLO menu's; era pet/pettraining of 2010 picks a 亚比 of the 亚比仓库 and a
  // lesson, pet/petbetraining shows the ones in training): the HELLO trains at most two at once.
  //   2-15 train {pi, c}    -> 2-15 {res, pi, c}   res 1, -1 no such 亚比 in the 仓库, -2 two in training
  //   2-14 getTrain {}      -> 2-14 {ps: [{pi, c, lt}]}   lt: seconds of the lesson left (0 done)
  //   2-16 trainStop {pi}   -> 2-16 {res, pi, exp, lv}   the experience of the time trained
  // The lessons are the panel's: 一天 (20×经验奖励), 三天 (15×), 五天 (10×) and 七天 (no
  // figure on it). Their experience is lost: RECONSTRUCTED as ten times the figure an hour
  // (七天 eight times).
  const DAY = 24 * 3600;
  const TRAIN_LESSONS: Record<number, [seconds: number, exp: number]> = {
    1: [DAY, 24 * 20 * 10],
    2: [3 * DAY, 72 * 15 * 10],
    3: [5 * DAY, 120 * 10 * 10],
    4: [7 * DAY, 168 * 8 * 10],
  };
  /** The lessons of 亚比 still had (one released or fused since leaves its place free). */
  const training = (rec: UserRecord) => {
    const has = (pi: number) => (rec.storage ?? []).some((p) => p.id === pi) || (rec.pets ?? []).some((p) => p.id === pi);
    return (rec.training = (rec.training ?? []).filter((t) => has(t.pi) && TRAIN_LESSONS[t.c]));
  };
  const trainView = (rec: UserRecord) => {
    const now = emu.clock.now().getTime();
    return training(rec).map((t) => ({ pi: t.pi, c: t.c, lt: Math.max(0, Math.ceil((t.since + TRAIN_LESSONS[t.c][0] * 1000 - now) / 1000)) }));
  };
  world.xt("RobotExtension.2-15", async (ctx) => {
    const rec = await me(ctx);
    const pi = Number(ctx.params.pi) | 0;
    const c = TRAIN_LESSONS[Number(ctx.params.c) | 0] ? Number(ctx.params.c) | 0 : 1;
    const list = training(rec);
    if (!(rec.storage ?? []).some((p) => p.id === pi) || list.some((t) => t.pi === pi)) return ctx.reply({ res: -1, pi, c }, "2-15");
    if (list.length >= 2) return ctx.reply({ res: -2, pi, c }, "2-15");
    list.push({ pi, c, since: emu.clock.now().getTime() });
    await save(rec);
    ctx.reply({ res: 1, pi, c }, "2-15");
  });
  world.xt("RobotExtension.2-14", async (ctx) => ctx.reply({ ps: trainView(await me(ctx)) }, "2-14"));
  world.xt("RobotExtension.2-16", async (ctx) => {
    const rec = await me(ctx);
    const pi = Number(ctx.params.pi) | 0;
    const at = training(rec).findIndex((t) => t.pi === pi);
    const pet = (rec.storage ?? []).find((p) => p.id === pi) ?? (rec.pets ?? []).find((p) => p.id === pi);
    if (at < 0 || !pet) {
      await save(rec);
      return ctx.reply({ res: -1, pi, exp: 0 }, "2-16");
    }
    const [t0] = rec.training!.splice(at, 1);
    const [secs, full] = TRAIN_LESSONS[t0.c];
    const done = Math.min(1, (emu.clock.now().getTime() - t0.since) / (secs * 1000));
    const exp = Math.floor(full * done);
    if (exp > 0) gainExp(await tables(), pet, exp);
    await save(rec);
    ctx.reply({ res: 1, pi, exp, lv: pet.level }, "2-16");
  });

  // ---------------------------------------------------------------- the HELLO's things
  // RobotClient (era library) and MaterialClient, for the HELLO's 基本资料 and HELLO物品 panels
  // (robot/robotmes, robot/robotitem; their January 2013 code is lost: these follow the 2015–16
  // copies). The HELLO's 道具 are materials of type 3 (RobotItemData: 1 能量晶石, 2 经验分配晶石,
  // 5 经验加成晶石, 6 亚比训练晶石, 7 技能唤醒晶石), its clothes of type 7 (RobotClothes 40001 …).
  //   2-6 getItems {}            -> {i: [{ItemId, Quantity}]}           RobotItemService at start
  //   61_6 {}                    -> {clothes: [{id, qt, uq}]}            RobotClothesService at start
  //   2-10 reName {n}            -> {res, n}                             1–14 characters
  //   2-5 useItem {ii}           -> {res, ii, e, f, msg}, onAmountUpdated "3_ii_0_-1"
  //   2-17 changeRobotAvatar {clothId} -> {result, clothId}, user variable r (members only, as the
  //                                  2016 RobotClothView: "只有蓝宝骑士才可以使用蓝宝石道具")
  //   2-18 addEnergy {}          -> {res, e, msg}                        the 营养饼干: back to 100
  // RECONSTRUCTED: what each 晶石 does (能量晶石 +20 energy, 技能唤醒晶石 wakes 技能替换, the
  // others are skills every HELLO of 2013 has, so they are not used up) and that 营养饼干 are free.
  const HELLO_ENERGY_ITEM = 20;
  world.xt("RobotExtension.2-6", async (ctx) => {
    const rec = await me(ctx);
    ctx.reply({ i: Object.entries(rec.items?.["3"] ?? {}).filter(([, q]) => q > 0).map(([id, q]) => ({ ItemId: Number(id), Quantity: q })) });
  });
  world.xt("MaterialExtension.61_6", async (ctx) => {
    const rec = await me(ctx);
    const worn = rec.robot?.avatar ?? "";
    ctx.reply({ clothes: Object.entries(rec.items?.["7"] ?? {}).filter(([, q]) => q > 0).map(([id, q]) => ({ id: Number(id), qt: q, uq: id === worn ? 1 : 0 })) });
  });
  world.xt("RobotExtension.2-10", async (ctx) => {
    const rec = await me(ctx);
    const n = String(ctx.params.n ?? "").trim();
    if (!rec.robot || n.length < 1 || [...n].length > 14) return ctx.reply({ res: 0, n: rec.robot?.name ?? "" });
    rec.robot.name = n;
    await save(rec);
    ctx.reply({ res: 1, n });
  });
  world.xt("RobotExtension.2-5", async (ctx) => {
    const rec = await me(ctx);
    const ii = String(Number(ctx.params.ii) | 0);
    const r = rec.robot;
    const have = rec.items?.["3"]?.[ii] ?? 0;
    const view = (res: number, msg: string) => ({ res, ii: Number(ii), e: r?.energy ?? 100, f: "", msg });
    if (!r || have < 1) return ctx.reply(view(0, "你没有这个道具哦。"));
    let msg = "";
    if (ii === "1") {
      if ((r.energy ?? 100) >= 100) return ctx.reply(view(0, "HELLO现在饱饱的，一点儿也不饿哦！"));
      r.energy = Math.min(100, (r.energy ?? 100) + HELLO_ENERGY_ITEM);
      msg = "主人对HELLO最好了，HELLO最喜欢主人了！";
    } else if (ii === "7") {
      const area = ((rec as UserRecord & AreaRec).area ??= {});
      const hello = (area.hello ??= { sc: [], pt: [], woken: [] });
      const woken = (hello.woken ??= []);
      if (woken.includes(4)) return ctx.reply(view(0, "HELLO已经会亚比技能替换了。"));
      woken.push(4);
      msg = "HELLO现在拥有了亚比技能替换了。";
    } else return ctx.reply(view(0, "HELLO已经拥有这个技能了。"));
    rec.items!["3"]![ii] = have - 1;
    if (rec.items!["3"]![ii] <= 0) delete rec.items!["3"]![ii];
    await save(rec);
    ctx.reply({ amount: `3_${ii}_0_-1` }, "onAmountUpdated");
    ctx.reply(view(1, msg));
  });
  world.xt("RobotExtension.2-17", async (ctx) => {
    const rec = await me(ctx);
    const id = String(Number(ctx.params.clothId) | 0);
    if (!rec.robot || !rec.vip || !((rec.items?.["7"]?.[id] ?? 0) > 0)) return ctx.reply({ result: false, clothId: Number(id) });
    rec.robot.avatar = id;
    await save(rec);
    if (rec.robot.follow) world.setUserVars(ctx.session, { r: robotVar(rec.robot) });
    ctx.reply({ result: true, clothId: Number(id) });
  });
  world.xt("RobotExtension.2-18", async (ctx) => {
    const rec = await me(ctx);
    if (!rec.robot) return ctx.reply({ res: 0, e: 0, msg: "你还没有HELLO哦！" });
    if ((rec.robot.energy ?? 100) >= 100) return ctx.reply({ res: 0, e: 100, msg: "HELLO现在饱饱的，一点儿也不饿哦！" });
    rec.robot.energy = 100;
    await save(rec);
    ctx.reply({ res: 1, e: 100 });
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
      const t = String(ctx.params.t === undefined ? 2 : Number(ctx.params.t) | 0);
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
  // A mini game started again (70_7 {GameName}) and the later SocketClient's
  // clientDebug: counted on the server only.
  world.xt("SundriesExtension.70_7", () => {});
  // Later games' open and buy counters (酷跑星世界: SundriesClient.logOpen 70_72, logBuy 70_67).
  world.xt("SundriesExtension.70_72", () => {});
  world.xt("SundriesExtension.70_67", () => {});
  world.xt("SurveyExtension.clientDebug", () => {});
  // 舞动全星's 冠军榜 (game/dance, 70_5 {} -> {rank: [{sId, dd, un, score}]}): the 2013 server's
  // list is lost; an empty list stops the panel waiting.
  world.xt("SundriesExtension.70_5", (ctx) => ctx.reply({ rank: [] }));
  // 虚无空间's 原子 (scene/emptyspace1 once 遇见小宇宙 is done: the password letters bring him out):
  // 70_6 {raceId: 510} -> {count}, this fight's number today; above 3 he sleeps (250_1038_3time).
  // The 2013 server is lost: RECONSTRUCTED as a count of the times asked today, so three a day.
  world.xt("SundriesExtension.70_6", async (ctx) => {
    const rec = await me(ctx);
    const race = String(Number(ctx.params.raceId) | 0);
    if (rec.dailyFights?.day !== today()) rec.dailyFights = { day: today(), n: {} };
    const count = (rec.dailyFights.n[race] ?? 0) + 1;
    rec.dailyFights.n[race] = count;
    await save(rec);
    ctx.reply({ count });
  });
  // 家具店's 安娜 asks whether the 我的荣誉 present is waiting (70_14 {} -> {showup}); the
  // present is given in the 家园's 我的荣誉, so none here. Statistics (HolidayExtension 74_1
  // logEvent {eventId}) are counted on the server only.
  world.xt("SundriesExtension.70_14", (ctx) => ctx.reply({ showup: false }));
  world.xt("HolidayExtension.74_1", () => {});

  // 欢乐弹珠机 (bumpbilliards/bumpbilliards, the 2015 copy; UserGameExtension): 89_2 {} when a game
  // starts, 89_1 {num: 欢乐弹珠 used, lvl} at its end -> {gf: "type:id:num;…"}, the prize of the slot
  // the points reached (lvl 1 for 7 points and more, 2 for 4–6, 3 for 1–3, 0 none). The balls (item
  // 343) go then. The 2013 prize table is lost: RECONSTRUCTED after the 2015 rules panel (things for
  // 1–3 points, better things or a 亚比蛋 for 4–6, rarer ones for 7 and more).
  world.xt("UserGameExtension.89_2", () => {});
  // 极速3D赛车 (game/mycat, GameTable 34 gameMyCat, the 极速俱乐部's btn_mycat): 89_5 {name} -> 89_5
  // {level}, the last of its three tracks open (0 the first; a track finished opens the next).
  world.xt("UserGameExtension.89_5", async (ctx) => {
    const rec = await me(ctx);
    const done = rec.gameLevels?.[String(ctx.params.name ?? "")] ?? 0;
    ctx.reply({ level: Math.min(2, done), name: String(ctx.params.name ?? "") }, "89_5");
  });
  world.xt("UserGameExtension.89_1", async (ctx) => {
    const rec = await me(ctx);
    const items = ((rec.items ??= {})["2"] ??= {});
    const used = Math.min(items["343"] ?? 0, Math.max(0, Number(ctx.params.num) | 0));
    if (used > 0) {
      items["343"] -= used;
      if (items["343"] <= 0) delete items["343"];
      ctx.reply({ amount: `2_343_0_${-used}` }, "onAmountUpdated");
    }
    // No 欢乐弹珠 played, no prize.
    // The slot reached is the game's word (its play is not followed here): the top prize (a
    // 亚比蛋, 天赋重组药剂 …) at most once a day, the second one otherwise.
    let lvl = used > 0 ? Number(ctx.params.lvl) | 0 : -1;
    const day = emu.clock.now().toISOString().slice(0, 10);
    if (lvl === 1) {
      if (rec.pinballTop === day) lvl = 2;
      else rec.pinballTop = day;
    }
    if (lvl < 0) {
      await save(rec);
      return ctx.reply({ gf: "" });
    }
    const pick = <T,>(a: T[]): T => a[Math.floor(Math.random() * a.length)];
    const prize: [string, number, number][] =
      lvl === 1 ? [pick([["5", 88, 1], ["2", 178, 1], ["2", 661, 1]] as [string, number, number][])]
      : lvl === 2 ? [pick([["5", 13, 1], ["5", 37, 1], ["2", 120, 1], ["2", 61, 2]] as [string, number, number][])]
      : lvl === 3 ? [pick([["2", 60, 2], ["2", 425, 2], ["2", 426, 2]] as [string, number, number][])]
      : [["2", 30, 1]];
    for (const [t, id, n] of prize) {
      const owned = (rec.items![t] ??= {});
      owned[id] = (owned[id] ?? 0) + n;
      ctx.reply({ amount: `${t}_${id}_0_${n}` }, "onAmountUpdated");
    }
    await save(rec);
    ctx.reply({ gf: prize.map(([t, id, n]) => `${t}:${id}:${n}`).join(";") });
  });

  world.xt("UserExtension.getLifeDay", async (ctx) => {
    const rec = await me(ctx);
    const made = rec?.createdAt ? new Date(rec.createdAt).getTime() : emu.clock.now().getTime();
    ctx.reply({ life: Math.max(1, Math.floor((emu.clock.now().getTime() - made) / 86400000) + 1) });
  });

  return world;
}

/**
 * Give an 奥拉 another name (the page's start screen: 改名字). The name is the record's key
 * (user/<name>) and the player's name everywhere, so the record moves; the newer social
 * records (friends, visits) keep ids, not names. On a shared server the password must be
 * the account's, and the 奥拉 must not be in the game at the time. null if done, else why not.
 */
export async function renameUser(
  emu: Emulator,
  from: string,
  to: string,
  opts: RenameOptions = {},
): Promise<string | null> {
  return oneAtATime(emu, () => rename(emu, from, to, opts));
}

export interface RenameOptions {
  pass?: string;
  addr?: string;
  accounts?: AccountOptions;
  online?: (name: string) => boolean;
  /** In the game (the 信息卡's 改名字): its game ends first (whether it was on); else an 奥拉 in the game is not renamed. */
  end?: (name: string) => boolean;
}

async function rename(
  emu: Emulator,
  from: string,
  to: string,
  opts: RenameOptions,
): Promise<string | null> {
  const a = from.trim(), b = to.trim();
  const bad = nameProblem(b);
  if (bad) return bad;
  if (a === b) return null;
  const rec = await userRecord(emu, a);
  if (!rec) return "没有这个奥拉。";
  if (opts.accounts?.required) {
    const wrong = await passProblem(emu, rec, opts.pass, opts.addr);
    if (wrong) return wrong;
  }
  if (await userRecord(emu, b)) return "这个名字已经有奥拉用了，换一个吧。";
  if (opts.end) {
    if (opts.end(a)) await new Promise((ok) => setTimeout(ok, IMPORT_SETTLE_MS));
  } else if (opts.online?.(a)) return "请先退出游戏，再改名字。";
  rec.name = b;
  await emu.store.set(userKey(b), rec);
  await emu.store.delete(userKey(a));
  await emu.store.set(`uid/${rec.id}`, b);
  return null;
}

/**
 * 导出存档 on a shared server: the 奥拉 as a 存档 file (saves.ts), the password asked. The file is
 * the page's format, so 单机模式 takes it in too. { save } if done, else { error }.
 */
export async function exportSave(
  emu: Emulator,
  name: string,
  opts: { pass?: string; addr?: string; accounts?: AccountOptions },
): Promise<{ save?: SaveFile; error?: string }> {
  return oneAtATime(emu, async () => {
    const rec = await userRecord(emu, name.trim());
    if (!rec) return { error: "没有这个奥拉。" };
    if (opts.accounts?.required) {
      const wrong = await passProblem(emu, rec, opts.pass, opts.addr);
      if (wrong) return { error: wrong };
    }
    return { save: playerFile(rec as UserRecord & Record<string, unknown>, userKey(rec.name), emu.clock.now().toISOString()) };
  });
}

/**
 * 导入存档 on a shared server: an 奥拉 of a 存档 file (either mode's) becomes this 奥拉's game,
 * the password asked. A file of several 奥拉 needs `from` (one of its names: { names } when
 * missing). The 奥拉's game ends first if it is on (end); its id, name, password and friends
 * stay the server's (saves.ts adoptRecord). Allowed only where the server lets players
 * (imports: a file can hold any 亚比 and items, as the 工具箱 gives). {} if done.
 */
export async function importSave(
  emu: Emulator,
  name: string,
  file: unknown,
  opts: { pass?: string; addr?: string; from?: string; accounts?: AccountOptions; imports?: boolean; end?: (name: string) => boolean },
): Promise<{ error?: string; names?: string[] }> {
  if (!opts.imports) return { error: "这个服务器没有打开导入存档。" };
  const bad = fileProblem(file);
  if (bad) return { error: bad };
  const roles = rolesOf(file as SaveFile);
  if (!roles.size) return { error: "这个存档里没有奥拉。" };
  const from = opts.from ? roles.get(opts.from) : roles.size === 1 ? [...roles.values()][0] : undefined;
  if (!from) return { error: opts.from ? `存档里没有${opts.from}。` : "存档里有好几个奥拉，请选一个。", names: [...roles.keys()] };
  if (jsonBytes(from) > SAVE_RECORD_MAX) return { error: "这个存档太大了。" };
  return oneAtATime(emu, async () => {
    const rec = await userRecord(emu, name.trim());
    if (!rec) return { error: "没有这个奥拉。" };
    if (opts.accounts?.required) {
      const wrong = await passProblem(emu, rec, opts.pass, opts.addr);
      if (wrong) return { error: wrong };
    }
    return replaceGame(emu, rec, from, opts.end);
  });
}

/**
 * An 奥拉's game becomes the file's (its id, name, password and friends stay: saves.ts
 * adoptRecord); its game ends first if it is on. {} if done.
 */
async function replaceGame(emu: Emulator, rec: UserRecord, from: Record<string, unknown>, end?: (name: string) => boolean): Promise<{ error?: string }> {
  const { id, name: as } = rec;
  const key = userKey(as);
  // Made and checked before anything changes: a file the game cannot read changes nothing.
  let next: UserRecord;
  try {
    next = normalise(adoptRecord(from, rec as UserRecord & Record<string, unknown>) as unknown as UserRecord);
    if (jsonBytes(next) > SAVE_RECORD_MAX) return { error: "这个存档太大了。" };
  } catch {
    return { error: "这个存档读不了。" };
  }
  // Its game ends (the page reloads after the import and logs in again); what its requests
  // still running do comes first.
  if (end?.(as)) await new Promise((ok) => setTimeout(ok, IMPORT_SETTLE_MS));
  // In place: the live record (store.ts LiveRecordStore) is the object a handler still
  // running for the game just ended holds; its save then writes the imported one. Undone if
  // the write fails, so what is kept and what is live stay one.
  const live = rec as unknown as Record<string, unknown>;
  const before = structuredClone(live);
  const fill = (o: Record<string, unknown>) => {
    for (const k of Object.keys(live)) delete live[k];
    Object.assign(live, o);
  };
  fill(next as unknown as Record<string, unknown>);
  try {
    await emu.store.set(key, live);
  } catch {
    fill(before);
    return { error: "存档没有存好，请再试一次。" };
  }
  await emu.store.set(`uid/${id}`, as);
  return {};
}

/**
 * 改密码 (the 信息卡, in the game): a shared server's 奥拉 takes a new password, its own asked
 * first (wrong ones count towards the lock, as at the login). The game goes on. null if done.
 */
export async function changePassword(
  emu: Emulator,
  name: string,
  pass: string,
  to: string,
  opts: { addr?: string; accounts?: AccountOptions },
): Promise<string | null> {
  if (!opts.accounts?.required) return "单机模式没有密码。";
  const bad = passwordProblem(to);
  if (bad) return bad;
  return oneAtATime(emu, async () => {
    const rec = await userRecord(emu, name.trim());
    if (!rec) return "没有这个奥拉。";
    const wrong = await passProblem(emu, rec, pass, opts.addr);
    if (wrong) return wrong;
    // The live record: a game that is on saves it with the new password too.
    rec.pass = await hashPass(to);
    await emu.store.set(userKey(rec.name), rec);
    return null;
  });
}

/** Whether a password may be one: 1 to 32 characters. null if fine. */
export function passwordProblem(pass: string): string | null {
  if (!pass) return "请输入新密码。";
  if ([...pass].length > 32) return "密码最多32个字。";
  return null;
}

// ---------------------------------------------------------------- the page's own 奥拉 (单机模式)

/** The 奥拉 of a page (单机模式), at most: its 选择奥拉 screen (web/accounts.js). */
export const LOCAL_ROLES_MAX = 3;

export interface LocalRole {
  name: string;
  id: number;
  score: number;
  /** 亚比 in the bag and the 仓库. */
  pets: number;
  /** The first 亚比 of the bag: its race and level (0 none). */
  race: number;
  level: number;
  createdAt?: string;
}

/** The 奥拉 kept here, oldest first. */
export async function listUsers(emu: Emulator): Promise<LocalRole[]> {
  const out: LocalRole[] = [];
  for (const k of await emu.store.keys("user/")) {
    const rec = await emu.store.get<UserRecord>(k);
    if (!rec || typeof rec !== "object" || !rec.name) continue;
    const first = rec.pets?.[0];
    out.push({
      name: rec.name,
      id: rec.id,
      score: rec.score ?? 0,
      pets: (rec.pets?.length ?? 0) + (rec.storage?.length ?? 0),
      race: first?.race ?? 0,
      level: first?.level ?? 0,
      createdAt: rec.createdAt,
    });
  }
  return out.sort((a, b) => a.id - b.id);
}

/** A new 奥拉 of this page: a fit name nobody here has, while there are fewer than max. null if done. */
export async function createUser(emu: Emulator, name: string, max = LOCAL_ROLES_MAX): Promise<string | null> {
  const n = name.trim();
  const bad = nameProblem(n);
  if (bad) return bad;
  return oneAtATime(emu, async () => {
    if (await userRecord(emu, n)) return `已经有一个叫${n}的奥拉了。`;
    if ((await emu.store.keys("user/")).length >= max) return `最多${max}个奥拉，先删除一个吧。`;
    const rec = await newUser(emu, n);
    await emu.store.set(userKey(n), rec);
    await emu.store.set(`uid/${rec.id}`, n);
    return null;
  });
}

/** An 奥拉 of this page goes, with its 足迹 (its game ends first if it is on). null if done. */
export async function deleteUser(emu: Emulator, name: string, end?: (name: string) => boolean): Promise<string | null> {
  return oneAtATime(emu, async () => {
    const rec = await userRecord(emu, name.trim());
    if (!rec) return "没有这个奥拉。";
    end?.(rec.name);
    await emu.store.delete(userKey(rec.name));
    await emu.store.delete(`uid/${rec.id}`);
    await emu.store.delete(`visits/${rec.id}`);
    return null;
  });
}

/**
 * 导入奥拉 (the page's 选择奥拉 screen): an 奥拉 of a 存档 file becomes one of this page's, as
 * `as` (default: its name in the file). A name one here already has is { conflict } unless
 * replace: then that 奥拉's game becomes the file's. A file of several needs `from` ({ names }).
 * Not more than max 奥拉. { name } (the 奥拉 it became) if done.
 */
export async function addUserFromFile(
  emu: Emulator,
  file: unknown,
  opts: { from?: string; as?: string; replace?: boolean; max?: number; end?: (name: string) => boolean } = {},
): Promise<{ name?: string; error?: string; names?: string[]; conflict?: string }> {
  const bad = fileProblem(file);
  if (bad) return { error: bad };
  const roles = rolesOf(file as SaveFile);
  if (!roles.size) return { error: "这个存档里没有奥拉。" };
  const fromName = opts.from ?? (roles.size === 1 ? [...roles.keys()][0] : undefined);
  const from = fromName === undefined ? undefined : roles.get(fromName);
  if (!from || fromName === undefined) return { error: opts.from ? `存档里没有${opts.from}。` : "存档里有好几个奥拉，请选一个。", names: [...roles.keys()] };
  if (jsonBytes(from) > SAVE_RECORD_MAX) return { error: "这个存档太大了。" };
  const as = (opts.as ?? fromName).trim();
  const badName = nameProblem(as);
  if (badName) return { error: badName, conflict: as };
  return oneAtATime(emu, async () => {
    const here = await userRecord(emu, as);
    if (here) {
      if (!opts.replace) return { conflict: as };
      const r = await replaceGame(emu, here, from, opts.end);
      return r.error ? r : { name: as };
    }
    const max = opts.max ?? LOCAL_ROLES_MAX;
    if ((await emu.store.keys("user/")).length >= max) return { error: `最多${max}个奥拉，先删除一个吧。` };
    const rec = await newUser(emu, as);
    let next: UserRecord;
    try {
      next = normalise(adoptRecord(from, rec as UserRecord & Record<string, unknown>) as unknown as UserRecord);
    } catch {
      return { error: "这个存档读不了。" };
    }
    await emu.store.set(userKey(as), next);
    await emu.store.set(`uid/${next.id}`, as);
    return { name: as };
  });
}
