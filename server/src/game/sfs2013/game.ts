// 奥拉星 2013 game server on top of the generic 2013 room protocol.
// Grows command by command as rebuilt and original modules ask for them;
// every unhandled extension call is logged with its parameters.

import type { Emulator } from "../../core/emulator.ts";
import { installPets, followVar, NO_FOLLOW, type PetRecord, type PetTables, type SpeciesTable } from "./pets.ts";
import { installBattles, type WildEntry } from "./battle.ts";
import { installTasks, registerTaskTables, type RobotRecord, type TaskTables, type UserTaskRec } from "./tasks.ts";
import { EMPTY_PMDATA, type PmData } from "./pmdata.ts";
import { installHouse, houseOf, usedUp, type HouseRecord } from "./house.ts";
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
}

/**
 * Starting outfit for a new player. The server-side default is not in any
 * surviving file; this is the 酷蓝 set (clothes 126–132 in the 2013
 * materialdata: hair, cape, suit, trousers, boots, eyes), one of the free
 * outfits the client data marks as not for sale. The body itself comes from
 * config.xml's <avatar dids="1,10145"> defaults.
 */
export const DEFAULT_AVATAR = "126;127;129;130;131;132";

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
  "PlantExtension.80_1": { userPlants: [] }, // PlantService
  "PlantItemExtension.81_2": { items: [] }, // PlantItemService
  "RobotExtension.2-6": { i: [] }, // RobotItemService
  "SundriesExtension.70-1": { b: [] }, // BadgeService
  "VipTowerExtension.84_1": { fl: 0, ps: false }, // VipArenaLevelManager
};

const userKey = (name: string) => `user/${encodeURIComponent(name)}`;

async function userRecord(emu: Emulator, name: string): Promise<UserRecord | undefined> {
  const rec = await emu.store.get<UserRecord>(userKey(name));
  if (rec) normalise(rec);
  return rec;
}

/** Older saves predate money and inventory: give them the defaults. */
function normalise(rec: UserRecord): UserRecord {
  if (!rec.avatar) rec.avatar = DEFAULT_AVATAR;
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
        vars: { avatar: rec.avatar, c: rec.avatar, nn: rec.name, mtype: 0, p: follow ? followVar(follow) : NO_FOLLOW },
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
      if (!rec.items!["0"]?.[id]) continue;
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

  // MaterialClient.buyMaterial: {tp, mi, qt}. Replies {res} (1 ok, -1 not for sale, -2 too little 晶币,
  // -3 real-money item, -4 already owned); on success pushes onScoreUpdated and onAmountUpdated
  // (the original AmountUpdateService adds the item on the client).
  world.xt("MaterialExtension.buyMaterial", async (ctx) => {
    const tp = String(ctx.params.tp ?? "0");
    const mi = String(ctx.params.mi ?? "0");
    const qt = Math.max(1, Number(ctx.params.qt ?? 1) | 0);
    const row = (await table())[tp]?.[mi];
    const rec = await me(ctx);
    const owned = (rec.items![tp] ??= {});
    const fail = (res: number) => ctx.reply({ res, tp: Number(tp), mi: Number(mi), qt });
    if (!row) return fail(-1);
    const [price, buyback, rmb, maxQ] = row;
    const unit = price > 0 ? price : buyback * 2;
    if (unit <= 0 && rmb > 0) return fail(-3);
    if ((owned[mi] ?? 0) + qt > Math.max(1, maxQ)) return fail(-4);
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

  // ---------------------------------------------------------------- pets

  const today = () => emu.clock.now().toISOString().slice(0, 10);
  installPets(world, { load: me, save: (o) => save(o as UserRecord), tables, today });
  installBattles(world, { load: me, save: (o) => save(o as UserRecord), tables, wild, today });

  const taskTables = json<TaskTables>("revival/tasks.json", { defines: {}, starters: {} }).then(registerTaskTables);
  installTasks(world, { load: me, save: (o) => save(o as UserRecord), now: () => emu.clock.now().getTime(), ready: taskTables, dev: opts.dev });

  installHouse(world, {
    me,
    find: (name) => userRecord(emu, name),
    save: (o) => save(o as UserRecord),
  });

  // ---------------------------------------------------------------- test commands

  if (opts.dev) {
    // revival_give {mi, qt}: items (type 2) for a test run, sent through onAmountUpdated.
    world.xt("PocketMonsterExtension.revival_give", async (ctx) => {
      const rec = await me(ctx);
      const mi = String(Number(ctx.params.mi));
      const qt = Math.max(1, Number(ctx.params.qt) || 1);
      const items = (rec.items!["2"] ??= {});
      items[mi] = (items[mi] ?? 0) + qt;
      await save(rec);
      ctx.reply({ amount: `2_${mi}_0_${qt}` }, "onAmountUpdated");
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
