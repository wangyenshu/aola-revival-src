// The home (小屋) for the 2013 server: HouseExtension (62_x) and
// UserFurntitureInfoExtension (63_x), the commands of the 2013 HouseClient and
// UserFurnitureInfoClient, with the reply fields the rebuilt house modules read.
//
//   62_1 {un}                 -> {un, hid, nn, count}         the owner's main house
//   62_2 {hid}                -> {result, nid}                change the main house (as 63_3)
//   62_3 {userName}           -> {visitors: []}               recent visitors (not kept yet)
//   63_1 {un, hid}            -> {infos: [{fid, key, x, y, ag, ex}]}
//   63_2 {hid, changes}       -> {result}  changes [{fid, key, x, y, a, exd, op}], op 1 add, 2 move, 3 remove
//   63_3 {hid, nid}           -> {result, nid}                another house type, the furniture back in storage
//
// The 2013 server is lost; the result codes are those the client checks
// (1 ok, -1 error, -2 empty, -3 repeated key, -4 not enough of that item).

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
}

export function installHouse(world: World, deps: HouseDeps): void {
  world.xt("HouseExtension.62_1", async (ctx) => {
    const un = String(ctx.params.un ?? ctx.player.name);
    const o = await deps.find(un);
    if (!o) return ctx.reply({ un, hid: 0 });
    const h = houseOf(o);
    await deps.save(o);
    ctx.reply({ un: o.name, hid: h.hid, nn: o.name, count: 0 });
  });

  world.xt("HouseExtension.62_3", (ctx) => ctx.reply({ userName: ctx.params.userName, visitors: [] }));

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
      const p: Placement = { fid, key, x: Math.round(Number(c.x)), y: Math.round(Number(c.y)), a: Number(c.a) || 0, exd: c.exd ?? undefined };
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
}
