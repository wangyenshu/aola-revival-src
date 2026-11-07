// The 家园's bar and its 友谊留言板, for the 2013 server.
//
// The bar (the rebuilt furniture/b000247: the strip under the garden of the 2012 tutorial
// picture house/houseteachmovie/houseteachgarden, with the owner's plate and three figures, and
// the friends' cards). The 2012 garden and its commands are lost; the later garden lists the
// player and the player's friends to go to their homes (HouseOutSideExtension 94_1). The
// revival's command:
//
//   revival_gardenbar {un}  -> {un, score, visits, friends, list: [{un, score}]}
//
//   score    the owner's 徽章分数 (honour.ts, 我的荣誉), visits the 人气 (足迹: visits of the home),
//            friends how many friends the owner has
//   list     the player and the player's friends, by 徽章分数 (the tutorial's card shows a place
//            and a star with a figure; its 我的荣誉 "还能看到你在朋友中的荣誉排名")
//
// 友谊留言板 (house/messageboard, MessageBoardService; HouseExtension, the commands of its own
// MessageBoardClient):
//
//   62_12 {un}                 -> {main, msgCount, recordCount, msg}   the first page
//   62_13 {un, page}           -> {msg}                                a page (1 …)
//   62_14 {un, content, type}  -> {suc, id}    a message on un's board (便签 type 1–6); suc false:
//                                              too many today ("你今天已经给很多朋友留言过了")
//   62_15 {id}                 -> {suc}        the owner takes one off
//   62_16 {un, id}             -> {suc}        举报 (once each)
//   62_11 {msg}                -> {suc}        the owner's 寄语
//
//   msg: [{id, type, content, dd (writer), nn (writer's name), month, day}], latest first, PAGE
//   a page. A board keeps BOARD_KEPT (the panel shows at most 100); a 寄语 is at most 90
//   characters, a message 26 (the panel's limits). Kept apart from the owner's record
//   ("board/<owner id>"), as the 足迹 are: other players write it. RECONSTRUCTED: the day's
//   limit (LEAVE_PER_DAY), what a 举报 does (it is only counted).

import { honourScore, type HonourOwner } from "./honour.ts";
import type { World } from "./server.ts";

export const PAGE = 8;
export const BOARD_KEPT = 100;
export const LEAVE_PER_DAY = 20;
const MAIN_MAX = 90;
const CONTENT_MAX = 26;

export interface BoardMsg {
  id: number;
  type: number;
  content: string;
  /** The writer's id. */
  from: number;
  t: number;
  reports?: number[];
}

export interface Board {
  main: string;
  next: number;
  msgs: BoardMsg[];
}

export interface GardenOwner extends HonourOwner {
  id: number;
  /** Messages left today on others' boards. */
  boardDay?: { day: string; n: number };
}

export interface GardenDeps {
  me(ctx: { player: { name: string } }): Promise<GardenOwner>;
  find(name: string): Promise<GardenOwner | undefined>;
  save(o: GardenOwner): Promise<void>;
  nameOf(id: number): Promise<string | undefined>;
  visits(id: number): Promise<number>;
  board: { get(id: number): Promise<Board | undefined>; set(id: number, b: Board): Promise<void> };
  now(): number;
}

/** China time: the day, and its month and date. */
const china = (ms: number) => new Date(ms + 8 * 3600_000);

export function installGarden(world: World, deps: GardenDeps): void {
  world.xt("SundriesExtension.revival_gardenbar", async (ctx) => {
    const un = String(ctx.params.un ?? ctx.player.name);
    const owner = await deps.find(un);
    const me = await deps.me(ctx);
    const people: GardenOwner[] = [me];
    for (const id of me.friends ?? []) {
      const name = await deps.nameOf(id);
      const o = name ? await deps.find(name) : undefined;
      if (o) people.push(o);
    }
    const list = people
      .map((o) => ({ un: o.name, score: honourScore(o).score }))
      .sort((a, b) => b.score - a.score || (a.un < b.un ? -1 : a.un > b.un ? 1 : 0));
    ctx.reply(
      {
        un: owner?.name ?? un,
        score: owner ? honourScore(owner).score : 0,
        visits: owner ? await deps.visits(owner.id) : 0,
        friends: owner?.friends?.length ?? 0,
        list,
      },
      "revival_gardenbar",
    );
  });

  const boardOf = async (id: number): Promise<Board> => (await deps.board.get(id)) ?? { main: "", next: 1, msgs: [] };
  const view = async (m: BoardMsg) => {
    const name = (await deps.nameOf(m.from)) ?? "";
    const d = china(m.t);
    return { id: m.id, type: m.type, content: m.content, dd: name, nn: name, month: d.getUTCMonth() + 1, day: d.getUTCDate() };
  };
  const pageOf = async (b: Board, page: number) => {
    const out = [];
    for (const m of b.msgs.slice((page - 1) * PAGE, page * PAGE)) out.push(await view(m));
    return out;
  };

  world.xt("HouseExtension.62_12", async (ctx) => {
    const o = await deps.find(String(ctx.params.un ?? ctx.player.name));
    const b = o ? await boardOf(o.id) : { main: "", next: 1, msgs: [] };
    ctx.reply({ main: b.main, msgCount: b.msgs.length, recordCount: b.msgs.length, msg: await pageOf(b, 1) }, "62_12");
  });

  world.xt("HouseExtension.62_13", async (ctx) => {
    const o = await deps.find(String(ctx.params.un ?? ctx.player.name));
    const page = Math.max(1, Number(ctx.params.page) | 0);
    ctx.reply({ msg: o ? await pageOf(await boardOf(o.id), page) : [] }, "62_13");
  });

  // One board written at a time (two messages at once would lose one).
  let writing: Promise<unknown> = Promise.resolve();
  const serial = <T>(f: () => Promise<T>): Promise<T> => {
    const p = writing.then(f, f);
    writing = p.catch(() => {});
    return p;
  };

  world.xt("HouseExtension.62_14", async (ctx) => {
    const me = await deps.me(ctx);
    const owner = await deps.find(String(ctx.params.un ?? ""));
    const content = String(ctx.params.content ?? "").trim().slice(0, CONTENT_MAX);
    const type = Math.min(6, Math.max(1, Number(ctx.params.type) | 0));
    const day = china(deps.now()).toISOString().slice(0, 10);
    const today = me.boardDay?.day === day ? me.boardDay.n : 0;
    if (!owner || !content || today >= LEAVE_PER_DAY) return ctx.reply({ suc: false }, "62_14");
    const id = await serial(async () => {
      const b = await boardOf(owner.id);
      const m: BoardMsg = { id: b.next++, type, content, from: me.id, t: deps.now() };
      b.msgs = [m, ...b.msgs].slice(0, BOARD_KEPT);
      await deps.board.set(owner.id, b);
      return m.id;
    });
    me.boardDay = { day, n: today + 1 };
    await deps.save(me);
    ctx.reply({ suc: true, id }, "62_14");
  });

  world.xt("HouseExtension.62_15", async (ctx) => {
    const me = await deps.me(ctx);
    const id = Number(ctx.params.id) | 0;
    const ok = await serial(async () => {
      const b = await boardOf(me.id);
      const left = b.msgs.filter((m) => m.id !== id);
      if (left.length === b.msgs.length) return false;
      b.msgs = left;
      await deps.board.set(me.id, b);
      return true;
    });
    ctx.reply({ suc: ok, id }, "62_15");
  });

  world.xt("HouseExtension.62_16", async (ctx) => {
    const me = await deps.me(ctx);
    const owner = await deps.find(String(ctx.params.un ?? ""));
    const id = Number(ctx.params.id) | 0;
    const ok = owner
      ? await serial(async () => {
          const b = await boardOf(owner.id);
          const m = b.msgs.find((x) => x.id === id);
          if (!m || m.from === me.id || (m.reports ?? []).includes(me.id)) return false;
          (m.reports ??= []).push(me.id);
          await deps.board.set(owner.id, b);
          return true;
        })
      : false;
    ctx.reply({ suc: ok }, "62_16");
  });

  world.xt("HouseExtension.62_11", async (ctx) => {
    const me = await deps.me(ctx);
    const main = String(ctx.params.msg ?? "").trim().slice(0, MAIN_MAX);
    if (!main) return ctx.reply({ suc: false }, "62_11");
    await serial(async () => {
      const b = await boardOf(me.id);
      b.main = main;
      await deps.board.set(me.id, b);
    });
    ctx.reply({ suc: true }, "62_11");
  });
}
