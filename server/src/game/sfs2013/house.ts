// The home (小屋) for the 2013 server: HouseExtension (62_x) and
// UserFurntitureInfoExtension (63_x), the commands of the 2013 HouseClient and
// UserFurnitureInfoClient, with the reply fields the rebuilt house modules read.
//
//   62_1 {un}                 -> {un, hid, nn, count}         the owner's main house
//   62_2 {hid}                -> {result, nid}                change the main house (as 63_3)
//   62_3 {userName}           -> {userName, count, visitors: [{un, t}], now}  recent visitors (足迹), latest first
//   63_1 {un, hid}            -> {infos: [{fid, key, x, y, ag, ex}]}
//   63_2 {hid, changes}       -> {result}  changes [{fid, key, x, y, a, exd, op}], op 1 add, 2 move, 3 remove
//   63_3 {hid, nid}           -> {result, nid}                another house type, the furniture (and the trees
//                                                             made furniture) back in storage
//
// The 2013 server is lost; the result codes are those the client checks
// (1 ok, -1 error, -2 empty, -3 repeated key, -4 not enough of that item).
//
// 足迹 (a shared server): another 奥拉 coming into a room of one's home (家园, 小屋, 动物园)
// is a visit; 62_1's count is how many there have been, 62_3 the last VISITS_KEPT of them
// (one each, the latest). Kept apart from the owner's record ("visits/<owner id>"), by ids,
// as friends are (names may change). What the era counted and showed is RECONSTRUCTED.

import { plantsBackToStorage, type PlantOwner } from "./plants.ts";
import { plainCopy } from "../../core/plain.ts";
import type { World, XtContext } from "./server.ts";

export interface Placement {
  fid: number;
  key: number;
  x: number;
  y: number;
  a: number;
  exd?: unknown;
}

export interface HouseRecord {
  /** Main house: a furniture id of type "house" (1 空间舱 for a new player). */
  hid: number;
  /** House id -> what stands in it. */
  placed: Record<string, Placement[]>;
}

/** Fields of UserRecord the house code uses. */
export interface HouseOwner {
  id: number;
  name: string;
  items?: Record<string, Record<string, number>>;
  house?: HouseRecord;
}

/** A new player's home: the 空间舱 and an empty 亚比仓库 to place (both price 0, not for sale in the 2013 data). */
export const DEFAULT_HOUSE_ID = 1;
export const DEFAULT_FURNITURE: Record<string, number> = { "1": 1, "7": 1 };

export function houseOf(o: HouseOwner): HouseRecord {
  const furniture = ((o.items ??= {})["1"] ??= {});
  if (!o.house) {
    o.house = { hid: DEFAULT_HOUSE_ID, placed: {} };
    for (const [id, q] of Object.entries(DEFAULT_FURNITURE)) furniture[id] ??= q;
  }
  furniture[String(o.house.hid)] ??= 1;
  return o.house;
}

/** How many of each furniture item stand somewhere ("usedUp"); the house in use counts as one. */
export function usedUp(o: HouseOwner): Record<string, number> {
  const h = houseOf(o);
  const used: Record<string, number> = {};
  for (const list of Object.values(h.placed)) for (const p of list) used[p.fid] = (used[p.fid] ?? 0) + 1;
  used[h.hid] = (used[h.hid] ?? 0) + 1;
  return used;
}

export interface HouseDeps {
  me: (ctx: XtContext) => Promise<HouseOwner>;
  find: (name: string) => Promise<HouseOwner | undefined>;
  save: (o: HouseOwner) => Promise<void>;
  /** 足迹: where the visits are kept (by the owner's id), and a player's name by id. */
  visits?: {
    get(ownerId: number): Promise<Visits | undefined>;
    set(ownerId: number, v: Visits): Promise<void>;
    nameOf(id: number): Promise<string | undefined>;
  };
  now?: () => number;
}

export interface Visits {
  /** Visits ever. */
  count: number;
  /** The latest, one a visitor: [visitor id, time]. */
  recent: [number, number][];
}

export const VISITS_KEPT = 20;
/** The room of a home: "<owner>_<house id>_Home" (house/houseloader). */
export const HOME_ROOM = /^(.+)_(-?\d+)_Home$/;

/**
 * A furniture's extData as the client gave it, made plain (JSON) and small: a client not the
 * 2013 one could send a cyclic or huge object, and the record could then not be written.
 */
function plainExd(v: unknown): unknown {
  if (v == null) return undefined;
  // Walked with a budget: never stringified whole (a small frame can name a huge value).
  return plainCopy(v, 2000, 8);
}

export function installHouse(world: World, deps: HouseDeps): void {
  world.xt("HouseExtension.62_1", async (ctx) => {
    const un = String(ctx.params.un ?? ctx.player.name);
    const o = await deps.find(un);
    if (!o) return ctx.reply({ un, hid: 0 });
    // A record from before the house: its default, saved by the owner only.
    const fresh = !o.house;
    const h = houseOf(o);
    if (fresh && o.name === ctx.player.name) await deps.save(o);
    const count = (await deps.visits?.get(o.id))?.count ?? 0;
    ctx.reply({ un: o.name, hid: h.hid, nn: o.name, count });
  });

  world.xt("HouseExtension.62_3", async (ctx) => {
    const un = String(ctx.params.userName ?? ctx.player.name);
    const o = await deps.find(un);
    const v = o ? await deps.visits?.get(o.id) : undefined;
    const visitors = [];
    for (const [id, t] of v?.recent ?? []) {
      const name = await deps.visits!.nameOf(id);
      if (name) visitors.push({ un: name, t });
    }
    ctx.reply({ userName: un, count: v?.count ?? 0, visitors, now: deps.now?.() ?? Date.now() });
  });

  world.xt("UserFurntitureInfoExtension.63_1", async (ctx) => {
    const un = String(ctx.params.un ?? ctx.player.name);
    const o = await deps.find(un);
    const list = o ? houseOf(o).placed[String(Number(ctx.params.hid))] ?? [] : [];
    ctx.reply({ un, hid: Number(ctx.params.hid), infos: list.map((p) => ({ fid: p.fid, key: p.key, x: p.x, y: p.y, ag: p.a, ex: p.exd ?? null })) });
  });

  world.xt("UserFurntitureInfoExtension.63_2", async (ctx) => {
    const o = await deps.me(ctx);
    const h = houseOf(o);
    const hid = String(Number(ctx.params.hid));
    const changes = ctx.params.changes as Record<string, unknown>[] | undefined;
    if (!Array.isArray(changes) || changes.length === 0) return ctx.reply({ result: -2 });
    const list = [...(h.placed[hid] ?? [])];
    for (const c of changes) {
      const fid = Number(c.fid), key = Number(c.key), op = Number(c.op);
      const at = list.findIndex((p) => p.fid === fid && p.key === key);
      const p: Placement = { fid, key, x: Math.round(Number(c.x)), y: Math.round(Number(c.y)), a: Number(c.a) || 0, exd: plainExd(c.exd) };
      if (op === 1) {
        if (at >= 0) return ctx.reply({ result: -3 });
        list.push(p);
      } else if (op === 2) {
        if (at >= 0) list[at] = p;
        else list.push(p);
      } else if (op === 3) {
        if (at >= 0) list.splice(at, 1);
      }
    }
    // Never more placed than owned (the house in use counts as one).
    const trial: HouseOwner = { ...o, house: { ...h, placed: { ...h.placed, [hid]: list } } };
    const used = usedUp(trial);
    const owned = o.items!["1"] ?? {};
    for (const [fid, n] of Object.entries(used)) if (n > (owned[fid] ?? 0)) return ctx.reply({ result: -4 });
    h.placed[hid] = list;
    await deps.save(o);
    ctx.reply({ result: 1 });
  });

  const changeHouse = async (ctx: XtContext, cmd: string) => {
    const o = await deps.me(ctx);
    const h = houseOf(o);
    const nid = Number(ctx.params.nid ?? ctx.params.hid);
    if (!(o.items!["1"] ?? {})[String(nid)]) return ctx.reply({ result: -2, nid }, cmd);
    delete h.placed[String(h.hid)];
    // The trees made furniture (plants.ts) that stood in it go back into the storage too.
    plantsBackToStorage(o as PlantOwner, h.hid);
    h.hid = nid;
    await deps.save(o);
    ctx.reply({ result: 1, nid }, cmd);
  };
  world.xt("UserFurntitureInfoExtension.63_3", (ctx) => changeHouse(ctx, "63_3"));
  world.xt("HouseExtension.62_2", (ctx) => changeHouse(ctx, "62_2"));

  // SocketClient.createAndJoinRoom: a home's room is made when its first visitor arrives.
  world.xt("UserExtension.cmdCreateAndJoinRoom", (ctx) => {
    world.join(ctx.session, String(ctx.params.room));
  });

  // 足迹: into someone else's home from outside it (not from another of its rooms). The visits
  // of one home one after another (two at once would count one).
  let writing: Promise<void> = Promise.resolve();
  const visited = async (visitor: { id: number; name: string }, ownerName: string) => {
    const owner = await deps.find(ownerName);
    if (!owner || owner.id === visitor.id || !deps.visits) return;
    const v = (await deps.visits.get(owner.id)) ?? { count: 0, recent: [] };
    v.count++;
    v.recent = [[visitor.id, deps.now?.() ?? Date.now()] as [number, number], ...v.recent.filter(([id]) => id !== visitor.id)].slice(0, VISITS_KEPT);
    await deps.visits.set(owner.id, v);
  };
  world.onJoinRoom?.((_s, p, room, from) => {
    const m = HOME_ROOM.exec(room.name);
    if (!m || !deps.visits || m[1] === p.name) return;
    const fm = HOME_ROOM.exec(from);
    if (fm && fm[1] === m[1]) return;
    const who = { id: p.id, name: p.name };
    writing = writing.then(() => visited(who, m[1])).catch(() => {});
  });
}
