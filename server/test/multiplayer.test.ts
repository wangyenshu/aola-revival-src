// A shared server with two players over the 2013 protocol (createGameHost, as src/node/multi.ts
// runs it): accounts, one game a name, 好友, 组队 and following the leader, the rooms of a home
// (家园, 小屋, 动物园) and its 足迹, and the players' records kept live (LiveRecordStore).
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { amf3Encode } from "../src/core/amf3.ts";
import { concat } from "../src/core/bytes.ts";
import { FrameSplitter } from "../src/core/framing.ts";
import { LiveRecordStore, MemoryStore } from "../src/core/store.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { Down, EXT_NAMES, Reader, Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";

const EXT_NUMBER = (name: string) => Number(Object.entries(EXT_NAMES).find(([, n]) => n === name)![0]);
import { SFS2013_FRAMING } from "../src/game/sfs2013/server.ts";

const EXT = { UserExtension: 1, TeamExtension: 2, BuddyManagerExtension: 3, PocketMonsterExtension: 13, PetExtension: 15, HouseExtension: 26, SundriesExtension: 34, FBExtension: 35, TeamTowerExtension: EXT_NUMBER("TeamTowerExtension") } as const;
const TABLES = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../rebuild/static/www.9aola.com");
/** The game's tables (pets, skills) for the battles. */
const tables = async (p: string) => {
  try {
    return JSON.parse(await readFile(path.join(TABLES, p), "utf8"));
  } catch {
    return undefined;
  }
};
const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));

function server(withTables = false) {
  const store = new MemoryStore();
  const host = createGameHost({ store, loadJson: withTables ? tables : async () => undefined, accounts: { required: true, register: true } });
  const connect = () => {
    const out: Uint8Array[] = [];
    let closed = false;
    const s = host.attach({ remote: "t", send: (b) => out.push(b), close: () => (closed = true) });
    let pn = -1;
    const send = (payload: Uint8Array) => {
      pn = nextPacketNum(pn);
      s.receive(encodeClientFrame(pn, payload));
    };
    const sp = new FrameSplitter(SFS2013_FRAMING);
    let first = true;
    const frames = () => {
      let all = concat(...out.splice(0));
      if (first && all[0] === 0x3c) all = all.subarray(all.indexOf(0) + 1);
      first = false;
      return sp.push(all).map((f) => {
        const r = new Reader(f);
        r.i32();
        const handler = r.u8();
        if (handler === 1) return { handler, obj: r.amf3() as Record<string, unknown> };
        if (handler === 0) return { handler, action: r.i16() };
        return { handler };
      });
    };
    let kept: Record<string, unknown>[] = [];
    // Extension replies as they are; system messages as {_cmd: "sys:<action>"}.
    const pull = () => kept.push(...frames().flatMap((f) => (f.handler === 1 ? [f.obj!] : f.handler === 0 ? [{ _cmd: `sys:${f.action}` }] : [])));
    /** The extension replies since the last look. */
    const xts = () => {
      pull();
      const out = kept;
      kept = [];
      return out;
    };
    /** The first reply cmd from now on (or already here), within ms; undefined if none came. */
    const wait = async (cmd: string, ms = 5000) => {
      for (const end = Date.now() + ms; ; ) {
        pull();
        const i = kept.findIndex((o) => o._cmd === cmd);
        if (i >= 0) return kept.splice(i, 1)[0];
        if (Date.now() > end) return undefined;
        await tick(10);
      }
    };
    const login = (name: string, pass: string) => send(clientPayload(0, Up.Login, -1).utf("aola").utf(name).utf(pass).body());
    const join = (room: string) => send(clientPayload(0, Up.JoinRoom, -1).utf(room).u8(49).i32(-1).u8(48).utf("").body());
    const xt = (ext: keyof typeof EXT, cmd: string, params: Record<string, unknown> = {}) =>
      send(clientPayload(1, Up.XtReq, 1).i16(EXT[ext]).utf(cmd).raw(amf3Encode(params)).body());
    return { s, login, join, xt, xts, wait, frames, send, closed: () => closed };
  };
  return { host, store, connect };
}

async function twoPlayers(withTables = false) {
  const srv = server(withTables);
  const a = srv.connect(), b = srv.connect();
  a.login("奥拉A", "pass-a");
  b.login("奥拉B", "pass-b");
  const okA = (await a.wait("logOK"))!, okB = (await b.wait("logOK"))!;
  assert.equal(okA.n, "奥拉A");
  assert.equal(okB.n, "奥拉B");
  // Signed up at once, each its own id.
  assert.notEqual(okA.id, okB.id);
  a.join("maintown1");
  b.join("maintown1");
  await tick();
  a.frames();
  b.frames();
  return { ...srv, a, b };
}

test("an account's password, and one game a name", async () => {
  const { a, connect } = await twoPlayers();
  const wrong = connect();
  wrong.login("奥拉A", "not-it");
  assert.ok(await wrong.wait(`sys:${Down.logKO}`), "refused (a second later)");
  assert.equal(wrong.xts().some((o) => o._cmd === "logOK"), false);
  assert.equal(a.closed(), false);
  // The same 奥拉 again (another page): the older game ends.
  const again = connect();
  again.login("奥拉A", "pass-a");
  assert.ok(await again.wait("logOK"));
  assert.equal(a.closed(), true);
  assert.match(String(a.xts().find((o) => o._cmd === "revival_replaced")?.msg), /别的地方登录了/, "the older page is told why");
});

test("好友: an ask, an answer, the list with where the friend is", async () => {
  const { a, b } = await twoPlayers();
  a.xt("BuddyManagerExtension", "revival_friend_add", { name: "奥拉B" });
  assert.equal((await a.wait("revival_friend_add"))?.res, 1);
  const ask = (await b.wait("revival_friend_ask"))!;
  assert.equal(ask.name, "奥拉A");
  b.xt("BuddyManagerExtension", "revival_friend_answer", { id: ask.id, ok: true });
  assert.equal((await b.wait("revival_friend_answer"))?.res, 1);
  assert.equal((await a.wait("revival_friend_added"))?.name, "奥拉B");
  a.xt("BuddyManagerExtension", "revival_friends");
  const list = (await a.wait("revival_friends"))!.list as Record<string, unknown>[];
  assert.deepEqual(list.map((f) => [f.name, f.online, f.room]), [["奥拉B", true, "maintown1"]]);
});

test("私聊: a line to a friend in the game; to anyone else, or when he is gone, the sender is told", async () => {
  const { a, b } = await twoPlayers();
  // Not friends yet.
  a.xt("BuddyManagerExtension", "privateMsg", { to: "奥拉B", msg: "[1]你好" });
  assert.match(String((await a.wait("privateMsg"))?.msg), /只能和好友私聊/);
  assert.equal(await b.wait("onPrivateMsg", 200), undefined);
  a.xt("BuddyManagerExtension", "revival_friend_add", { name: "奥拉B" });
  const ask = (await b.wait("revival_friend_ask"))!;
  b.xt("BuddyManagerExtension", "revival_friend_answer", { id: ask.id, ok: true });
  await b.wait("revival_friend_answer");
  a.xt("BuddyManagerExtension", "privateMsg", { to: "奥拉B", msg: "[1]你好<b>" });
  assert.deepEqual(await b.wait("onPrivateMsg"), { _cmd: "onPrivateMsg", from: "奥拉A", msg: "[1]你好<b>" });
  assert.equal(await a.wait("privateMsg", 200), undefined, "delivered: no answer");
  // Two lines a second at most.
  a.xt("BuddyManagerExtension", "privateMsg", { to: "奥拉B", msg: "[1]再说" });
  assert.match(String((await a.wait("privateMsg"))?.msg), /太快/);
  await tick(1100);
  // Bounded in length.
  a.xt("BuddyManagerExtension", "privateMsg", { to: "奥拉B", msg: "[1]" + "长".repeat(300) });
  assert.equal(String((await b.wait("onPrivateMsg"))?.msg).length, 3 + 100);
  // B leaves the game: not delivered, A is told.
  b.s.close();
  await tick(50);
  a.xt("BuddyManagerExtension", "privateMsg", { to: "奥拉B", msg: "[1]还在吗" });
  assert.match(String((await a.wait("privateMsg"))?.msg), /不在线/);
});

test("组队: the leader invites, the member joins and follows the leader's rooms", async () => {
  const { a, b } = await twoPlayers();
  a.xt("TeamExtension", "revival_team_invite", { name: "奥拉B" });
  await tick();
  assert.equal(a.xts().find((o) => o._cmd === "revival_team_invite")?.res, 1);
  assert.equal(b.xts().find((o) => o._cmd === "revival_team_ask")?.leader, "奥拉A");
  b.xt("TeamExtension", "revival_team_join", { leader: "奥拉A" });
  await tick();
  const team = a.xts().find((o) => o._cmd === "revival_team")?.team as Record<string, unknown>;
  assert.deepEqual(team, { leader: "奥拉A", members: ["奥拉A", "奥拉B"] });
  b.xts();
  // The leader into his 小屋: the member is told to go there too (the room the leader is in, not
  // any he names: a stranger's home named is not sent on).
  a.xt("TeamExtension", "revival_team_go", { room: "奥拉B_1_Home" });
  a.join("奥拉A_1_Home");
  await tick();
  a.xt("TeamExtension", "revival_team_go", { room: "奥拉A_1_Home" });
  await tick();
  assert.deepEqual(
    b.xts().filter((o) => o._cmd === "revival_team_go").map((o) => o.room),
    ["奥拉A_1_Home"],
  );
  // The leader's game ends: no team is left of one.
  a.s.close();
  await tick();
  assert.equal(b.xts().filter((o) => o._cmd === "revival_team").at(-1)?.team, null);
});

test("a friend's home: 家园, 小屋 and 动物园, one 足迹 a visit", async () => {
  const { a, b } = await twoPlayers();
  // B goes to A's garden, then his 小屋 and his 动物园 (rooms of one visit).
  b.xt("HouseExtension", "62_1", { un: "奥拉A" });
  await tick();
  const info = b.xts().find((o) => o._cmd === "62_1")!;
  assert.equal(info.un, "奥拉A");
  assert.ok(Number(info.hid) > 0);
  // (The rebuilt scenes join a home's room as any other; SocketClient.createAndJoinRoom too.)
  b.join("奥拉A_247_Home");
  await tick();
  b.join(`奥拉A_${info.hid}_Home`);
  await tick();
  b.xt("UserExtension", "cmdCreateAndJoinRoom", { room: "奥拉A_20000_Home" });
  await tick();
  // A comes into his own 小屋: B is there; his own coming is no visit.
  a.xt("UserExtension", "cmdCreateAndJoinRoom", { room: `奥拉A_${info.hid}_Home` });
  await tick();
  a.xt("HouseExtension", "62_1", { un: "奥拉A" });
  a.xt("HouseExtension", "62_3", { userName: "奥拉A" });
  await tick();
  const got = a.xts();
  assert.equal(got.find((o) => o._cmd === "62_1")?.count, 1);
  const visitors = got.find((o) => o._cmd === "62_3")!.visitors as Record<string, unknown>[];
  assert.deepEqual(visitors.map((v) => v.un), ["奥拉B"]);
  // Out and back in: another visit, still one line for B.
  b.join("maintown1");
  await tick();
  b.xt("UserExtension", "cmdCreateAndJoinRoom", { room: "奥拉A_20000_Home" });
  await tick();
  a.xt("HouseExtension", "62_3", { userName: "奥拉A" });
  await tick();
  const again = a.xts().find((o) => o._cmd === "62_3")!;
  assert.equal(again.count, 2);
  assert.equal((again.visitors as unknown[]).length, 1);
});

test("the live records: one object a key, written through, the least used let go", async () => {
  const inner = new MemoryStore();
  const live = new LiveRecordStore(inner, ["user/"], 2);
  await inner.set("user/a", { n: 1 });
  const [x, y] = await Promise.all([live.get<{ n: number }>("user/a"), live.get<{ n: number }>("user/a")]);
  assert.equal(x, y);
  x!.n = 2;
  await live.set("user/a", x);
  assert.deepEqual(await inner.get("user/a"), { n: 2 });
  // Not kept: a copy each time.
  await live.set("meta/x", { n: 1 });
  assert.notEqual(await live.get("meta/x"), await live.get("meta/x"));
  await live.set("user/b", { n: 1 });
  await live.set("user/c", { n: 1 });
  assert.notEqual(await live.get("user/a"), x, "let go, read again");
  await live.delete("user/c");
  assert.equal(await live.get("user/c"), undefined);
});

test("the live records: a write that fails leaves the last saved state, not a record never saved", async () => {
  const inner = new MemoryStore();
  let fail = 0;
  const flaky: typeof inner = Object.assign(Object.create(inner), {
    set: async (k: string, v: unknown) => {
      if (fail > 0) {
        fail--;
        throw new Error("disk full");
      }
      return inner.set(k, v);
    },
  });
  const logs: string[] = [];
  const live = new LiveRecordStore(flaky, ["user/"], 10, () => true, 200, (m) => logs.push(m));
  await live.set("user/a", { n: 1 });
  const a = (await live.get<{ n: number }>("user/a"))!;
  // One failure is retried.
  fail = 1;
  a.n = 2;
  await live.set("user/a", a);
  assert.deepEqual(await inner.get("user/a"), { n: 2 });
  // Failing for good: the live copy goes, the next get reads what was last saved.
  fail = 5;
  a.n = 3;
  await assert.rejects(live.set("user/a", a), /disk full/);
  assert.deepEqual(await live.get("user/a"), { n: 2 });
  assert.match(logs.at(-1)!, /user\/a failed/);
  // Over the size limit: not written either.
  const big = (await live.get<{ n: number; pad?: string }>("user/a"))!;
  big.pad = "x".repeat(300);
  await assert.rejects(live.set("user/a", big), /over 200 bytes/);
  assert.deepEqual(await live.get("user/a"), { n: 2 });
});

test("a mod's team events go to the other members", async () => {
  const { a, b } = await twoPlayers();
  a.xt("TeamExtension", "revival_team_invite", { name: "奥拉B" });
  await tick();
  b.xt("TeamExtension", "revival_team_join", { leader: "奥拉A" });
  await tick();
  a.xts();
  b.xts();
  a.xt("TeamExtension", "revival_team_mod", { mod: "story", ver: "1.0", event: "door", data: '{"open":true}' });
  await tick();
  assert.deepEqual(b.xts().find((o) => o._cmd === "revival_team_mod"), { _cmd: "revival_team_mod", from: "奥拉A", mod: "story", ver: "1.0", event: "door", data: '{"open":true}' });
  assert.equal(a.xts().some((o) => o._cmd === "revival_team_mod"), false, "not to oneself");
  // The leader goes into a room of the mod: the member is told to follow there.
  a.join("sandboxroom|%E5%A5%A5%E6%8B%89A|story|1.0|hall");
  await tick();
  a.xt("TeamExtension", "revival_team_go", { room: "sandboxroom|%E5%A5%A5%E6%8B%89A|story|1.0|hall" });
  await tick();
  assert.equal(b.xts().find((o) => o._cmd === "revival_team_go")?.room, "sandboxroom|%E5%A5%A5%E6%8B%89A|story|1.0|hall");
});

test("no joining a team uninvited; one login a connection; rooms a client names are bounded", async () => {
  const { a, b } = await twoPlayers();
  // B asks to join A, who has not invited him.
  a.xt("TeamExtension", "revival_team_make");
  await tick();
  b.xt("TeamExtension", "revival_team_join", { leader: "奥拉A" });
  await tick();
  assert.equal(b.xts().find((o) => o._cmd === "revival_team")?.team, null);
  a.xts();
  a.xt("TeamExtension", "revival_team");
  await tick();
  assert.deepEqual((a.xts().find((o) => o._cmd === "revival_team")?.team as Record<string, unknown>).members, ["奥拉A"]);
  // An invitation, answered twice: one team of two.
  a.xt("TeamExtension", "revival_team_invite", { name: "奥拉B" });
  await tick();
  b.xt("TeamExtension", "revival_team_join", { leader: "奥拉A" });
  b.xt("TeamExtension", "revival_team_join", { leader: "奥拉A" });
  await tick();
  a.xts();
  a.xt("TeamExtension", "revival_team");
  await tick();
  assert.deepEqual((a.xts().find((o) => o._cmd === "revival_team")?.team as Record<string, unknown>).members, ["奥拉A", "奥拉B"]);
  // A second login on B's connection is not answered; B stays B.
  b.login("奥拉A", "pass-a");
  await tick(60);
  assert.equal(b.xts().some((o) => o._cmd === "logOK"), false);
  // A room's name longer than ROOM_NAME_MAX (500 characters): refused.
  b.join("x".repeat(600));
  await tick();
  assert.equal(b.frames().some((f) => f.handler === 0 && f.action === Down.joinOK), false);
});

/** Both get a 亚比 (the 工具箱). */
async function pets(a: Client, b: Client, level = 30) {
  for (const c of [a, b]) c.xt("SundriesExtension", "revival_toolbox", { raceId: 1, level });
  assert.ok(await a.wait("revival_toolbox"));
  assert.ok(await b.wait("revival_toolbox"));
}

/** A whole duel, each choosing his first skill every turn. */
async function duel(a: Client, b: Client) {
  a.xt("PocketMonsterExtension", "revival_duel_invite", { name: "奥拉B" });
  assert.equal((await a.wait("revival_duel_invite"))?.res, 1);
  assert.equal((await b.wait("revival_duel_ask"))?.from, "奥拉A");
  b.xt("PocketMonsterExtension", "revival_duel_answer", { from: "奥拉A", ok: true });
  const join = [(await a.wait("2303"))!, (await b.wait("2303"))!];
  assert.deepEqual(join.map((j) => (j.pvp as Record<string, unknown>).vs), ["奥拉B", "奥拉A"]);
  // Each sees his own 亚比 as slot 0.
  const mine = (j: Record<string, unknown>) => (j.pmmList as { battleView: { slotId: number; pmmId: number } }[]).find((v) => v.battleView.slotId === 0)!.battleView.pmmId;
  assert.notEqual(mine(join[0]), mine(join[1]));
  for (let turn = 0; turn < 60; turn++) {
    a.xt("PocketMonsterExtension", "1401", { skillId: 0 });
    b.xt("PocketMonsterExtension", "1401", { skillId: 0 });
    const [ea, eb] = [await a.wait("2403", 300), await b.wait("2403", 300)];
    if (ea || eb) return [ea ?? (await a.wait("2403")), eb ?? (await b.wait("2403"))];
    a.xts();
    b.xts();
  }
  throw new Error("the duel did not end");
}
type Client = ReturnType<ReturnType<typeof server>["connect"]>;

test("亚比对战: an invitation, turns both choose, one wins; nothing of theirs changes", async () => {
  const { a, b, host } = await twoPlayers(true);
  await pets(a, b);
  const before = JSON.stringify((await host.emulator.store.get<{ pets: unknown[] }>(`user/${encodeURIComponent("奥拉A")}`))!.pets);
  const [ea, eb] = await duel(a, b);
  assert.equal(ea!.pvp, true);
  assert.notEqual(ea!.isWin, eb!.isWin, "one wins");
  const after = JSON.stringify((await host.emulator.store.get<{ pets: unknown[] }>(`user/${encodeURIComponent("奥拉A")}`))!.pets);
  assert.equal(after, before, "a 切磋: the 亚比 as they were");
  // Over: a new fight may start.
  a.xt("PocketMonsterExtension", "revival_duel_invite", { name: "奥拉B" });
  assert.equal((await a.wait("revival_duel_invite"))?.res, 0, "asked again too soon");
});

test("亚比对战: one waits (1406) while the other's skill acts; the turn goes on", async () => {
  const { a, b } = await twoPlayers(true);
  await pets(a, b);
  a.xt("PocketMonsterExtension", "revival_duel_invite", { name: "奥拉B" });
  await a.wait("revival_duel_invite");
  await b.wait("revival_duel_ask");
  b.xt("PocketMonsterExtension", "revival_duel_answer", { from: "奥拉A", ok: true });
  await a.wait("2401");
  await b.wait("2401");
  a.xts();
  b.xts();
  a.xt("PocketMonsterExtension", "1406", { isAuto: true });
  b.xt("PocketMonsterExtension", "1401", { skillId: 0 });
  assert.ok(await a.wait("2402"), "the next turn");
  const bs = b.xts();
  const acts = bs.filter((o) => o._cmd === "2411");
  assert.equal(acts.length, 1, "only B's 亚比 acted");
});

test("亚比对战: giving up, and asking someone in another room", async () => {
  const { a, b } = await twoPlayers(true);
  await pets(a, b);
  a.xt("PocketMonsterExtension", "revival_duel_invite", { name: "奥拉B" });
  await a.wait("revival_duel_invite");
  await b.wait("revival_duel_ask");
  b.xt("PocketMonsterExtension", "revival_duel_answer", { from: "奥拉A", ok: true });
  await a.wait("2401");
  await b.wait("2401");
  b.xt("PocketMonsterExtension", "1404");
  assert.equal((await b.wait("2414"))?.isEscape, true);
  assert.equal((await a.wait("2403"))?.isWin, true);
  b.join("maintown2");
  await tick();
  a.xt("PocketMonsterExtension", "revival_duel_invite", { name: "奥拉B" });
  const r = await a.wait("revival_duel_invite");
  assert.equal(r?.res, 0, String(r?.msg));
  assert.match(String(r?.msg), /同一个地方/);
});

test("no team battles: the leader's boss fight is his alone", async () => {
  const { a, b } = await twoPlayers(true);
  await pets(a, b, 100);
  await team(a, b);
  // A boss (a 兔小子 at a 守护者's level): A fights it, B is not taken along.
  a.xt("PetExtension", "54_16", { raceId: "10001", index: 0 });
  assert.ok(await a.wait("2303"));
  assert.equal(await b.wait("2303", 300), undefined);
  assert.equal(await b.wait("2421", 50), undefined);
  // B, in the same room, starts his own fight meanwhile.
  b.xt("PetExtension", "54_16", { raceId: "10001", index: 0 });
  assert.ok(await b.wait("2303"));
});

test("a save without a password is not anyone's; records of players in the game stay live", async () => {
  const srv = server();
  // A save copied in, no password in it.
  await srv.store.set(`user/${encodeURIComponent("旧奥拉")}`, { id: 20001, name: "旧奥拉", avatar: "" });
  const c = srv.connect();
  c.login("旧奥拉", "anything");
  assert.ok(await c.wait(`sys:${Down.logKO}`), "refused");
  // Pinned keys are not let go.
  const inner = new MemoryStore();
  const live = new LiveRecordStore(inner, ["user/"], 1, (k) => k === "user/a");
  await inner.set("user/a", { n: 1 });
  const a = await live.get("user/a");
  await live.set("user/b", { n: 2 });
  assert.equal(await live.get("user/a"), a);
});

/** A and B in a team, A the leader. */
async function team(a: Client, b: Client) {
  a.xt("TeamExtension", "revival_team_invite", { name: "奥拉B" });
  await b.wait("revival_team_ask");
  b.xt("TeamExtension", "revival_team_join", { leader: "奥拉A" });
  await a.wait("revival_team");
  await b.wait("revival_team");
}

test("副本 and 时空隧道 in a team: each player's own, nobody follows, nothing relayed", async () => {
  const { a, b } = await twoPlayers(true);
  await team(a, b);
  await tick();
  b.xts();
  // The leader into his 副本 room: the member is not sent after him.
  a.join("fbaixi1@奥拉A");
  a.xt("TeamExtension", "revival_team_go", { room: "fbaixi1@奥拉A" });
  await tick();
  assert.equal(b.xts().some((o) => o._cmd === "revival_team_go"), false);
  // B goes in as well, into his own room: the era's step sync (sendCustomCommand) reaches nobody.
  b.join("fbaixi1@奥拉B");
  await tick();
  a.frames();
  b.frames();
  a.send(clientPayload(0, Up.AsObj, 1).utf("<dataObj><var n='what' t='s'>fb_team_service</var></dataObj>").body());
  await tick();
  assert.equal(b.frames().filter((f) => f.handler === 0 && f.action === Down.dataObj).length, 0);
  // A's run is his: B (no fb_1 of his own) has none, and A's end is answered to A only (not
  // finished: no boss beaten yet).
  a.xt("FBExtension", "fb_1", { id: 0, name: "fbaixi", lv: 0 });
  assert.equal((await a.wait("fb_1"))?.succ, true);
  a.xt("FBExtension", "fb_4");
  assert.equal((await a.wait("fb_4"))?.fin, false);
  assert.equal(await b.wait("fb_4", 300), undefined);
  // The team tunnel: each chooses his own floor, nobody is told another's.
  b.xt("TeamTowerExtension", "56_2_t", { fl: 1 });
  const theirs = (await b.wait("56_2_t"))!;
  assert.equal(theirs.refused, undefined);
  assert.equal(await a.wait("56_2_t", 300), undefined);
});

test("存档 on a shared server: export one 奥拉, import a page's file of several into another", async () => {
  const { a, b, host } = await twoPlayers();
  // A has friends here (the server's alone) and 晶币.
  a.xt("BuddyManagerExtension", "revival_friend_add", { name: "奥拉B" });
  const ask = (await b.wait("revival_friend_ask"))!;
  b.xt("BuddyManagerExtension", "revival_friend_answer", { id: ask.id, ok: true });
  await a.wait("revival_friend_added");
  const keyA = `user/${encodeURIComponent("奥拉A")}`;
  const recA = (await host.emulator.store.get<Record<string, unknown>>(keyA))!;
  recA.score = 4321;
  await host.emulator.store.set(keyA, recA);
  // Exported: the page's format, the record without the password and the friends.
  const out = await host.exportSave("奥拉A", "pass-a");
  assert.equal(out.error, undefined);
  const file = out.save!;
  assert.equal(file.format, "aola-revival-save");
  assert.equal(file.version, 1);
  const rec = file.data[keyA] as Record<string, unknown>;
  assert.equal(rec.score, 4321);
  assert.equal(rec.pass, undefined);
  assert.equal(rec.friends, undefined);
  assert.equal(file.data[`uid/${rec.id}`], "奥拉A");
  assert.equal(file.data["meta/nextUserId"], rec.id);
  assert.equal((await host.exportSave("奥拉A", "wrong")).error, "密码不对哦。");
  // A page's file (单机模式): two 奥拉 and the page's boards.
  const page = {
    format: "aola-revival-save",
    version: 1,
    data: {
      [`user/${encodeURIComponent("小奥拉")}`]: { id: 10001, name: "小奥拉", score: 777, pets: [{ id: 1, race: 1, level: 30 }, "junk"], nextPetId: 0, items: "bad" },
      [`user/${encodeURIComponent("小花")}`]: { id: 10002, name: "小花", score: 5 },
      "parkour/board": [],
      "meta/nextUserId": 10002,
    },
  };
  const many = await host.importSave("奥拉B", "pass-b", page);
  assert.deepEqual(many.names?.sort(), ["小奥拉", "小花"].sort(), "which one, asked");
  assert.match(String((await host.importSave("奥拉B", "wrong", page, "小奥拉")).error), /密码/);
  assert.equal(b.s.closed, false);
  const friendsB = ((await host.emulator.store.get<Record<string, unknown>>(`user/${encodeURIComponent("奥拉B")}`))!.friends as number[]).slice();
  const idB = (await host.emulator.store.get<{ id: number }>(`user/${encodeURIComponent("奥拉B")}`))!.id;
  assert.deepEqual(await host.importSave("奥拉B", "pass-b", page, "小奥拉"), {});
  // B's game ended; his 奥拉 has the file's game, and stays his here (id, name, password, friends).
  assert.equal(b.s.closed, true);
  const got = (await host.emulator.store.get<Record<string, unknown>>(`user/${encodeURIComponent("奥拉B")}`))!;
  assert.equal(got.score, 777);
  assert.equal(got.id, idB);
  assert.equal(got.name, "奥拉B");
  assert.ok(got.pass);
  assert.deepEqual(got.friends, friendsB);
  assert.deepEqual((got.pets as { id: number }[]).map((p) => p.id), [1], "not a 亚比: left out");
  assert.equal(got.nextPetId, 1, "the 亚比 counter not behind its 亚比");
  assert.equal(typeof got.items, "object", "a field of the wrong kind: dropped (the default)");
  // A's own export goes back in too (one file, either way).
  assert.deepEqual(await host.importSave("奥拉A", "pass-a", file), {});
  assert.equal((await host.emulator.store.get<Record<string, unknown>>(keyA))!.score, 4321);
});

test("存档: imports closed with the 工具箱; a name locked after wrong passwords", async () => {
  const store = new MemoryStore();
  const host = createGameHost({ store, loadJson: async () => undefined, accounts: { required: true, register: true }, toolbox: false });
  const c = (() => {
    const out: Uint8Array[] = [];
    const s = host.attach({ remote: "t", send: (x) => out.push(x), close: () => {} });
    let pn = -1;
    return (payload: Uint8Array) => {
      pn = nextPacketNum(pn);
      s.receive(encodeClientFrame(pn, payload));
    };
  })();
  c(clientPayload(0, Up.Login, -1).utf("aola").utf("奥拉C").utf("pass-c").body());
  for (let i = 0; i < 50 && !(await store.get(`user/${encodeURIComponent("奥拉C")}`)); i++) await tick(10);
  const file = (await host.exportSave("奥拉C", "pass-c")).save!;
  assert.ok(file, "export stays open");
  assert.match(String((await host.importSave("奥拉C", "pass-c", file)).error), /没有打开导入存档/);
  for (let i = 0; i < 5; i++) assert.equal((await host.exportSave("奥拉C", "nope")).error, "密码不对哦。");
  assert.equal((await host.exportSave("奥拉C", "pass-c")).error, "密码错了太多次，请过一分钟再试。", "locked, the right one too");
});

test("存档: an imported 亚比 is rebuilt from its known fields; the lock is a client's, not everyone's", async () => {
  const { host } = await twoPlayers();
  const file = {
    format: "aola-revival-save",
    version: 1,
    data: {
      [`user/${encodeURIComponent("某人")}`]: {
        name: "某人",
        pets: [{ id: 5, race: 1, level: 1000, exp: "lots", hp: 10, skills: "bad", iv: [1, 2], ev: null, extra: { x: 1 } }, { id: 5, race: 2, level: 3 }],
        storage: [{ id: 9, race: 3, level: 4, skills: [{ id: 1, pp: 99, max: 10 }, "x"] }],
        items: { "2": { "1": 3, "2": "many" }, "9": 5 },
      },
    },
  };
  assert.deepEqual(await host.importSave("奥拉A", "pass-a", file), {});
  const got = (await host.emulator.store.get<{ pets: Record<string, unknown>[]; storage: Record<string, unknown>[]; items: Record<string, unknown> }>(`user/${encodeURIComponent("奥拉A")}`))!;
  assert.equal(got.pets.length, 1, "one 亚比 an id");
  assert.deepEqual([got.pets[0].level, got.pets[0].exp, got.pets[0].skills, got.pets[0].extra], [100, 0, [], undefined]);
  assert.deepEqual(got.storage[0].skills, [{ id: 1, name: "", pp: 10, max: 10 }]);
  assert.equal((got.items["2"] as Record<string, number>)["1"], 3);
  assert.equal((got.items["2"] as Record<string, unknown>)["2"], undefined);
  // Five wrong from one address lock that one; the player from his own goes on.
  for (let i = 0; i < 5; i++) await host.exportSave("奥拉A", "nope", "ws client-a");
  assert.equal((await host.exportSave("奥拉A", "pass-a", "ws client-a")).error, "密码错了太多次，请过一分钟再试。");
  assert.equal((await host.exportSave("奥拉A", "pass-a", "ws client-b")).error, undefined);
});

test("review: made-up rooms go when empty; chat is bounded; a client cannot catch any species or get one by addPM", async () => {
  const { a, b, host } = await twoPlayers(true);
  // 5000 rooms one client names, one after another: each goes when he leaves it, so the table
  // does not fill, and the other player's joins go on.
  for (let i = 0; i < 300; i++) a.join(`junk${i}`);
  await tick(50);
  assert.ok(host.world.rooms.size < 20, `rooms standing: ${host.world.rooms.size}`);
  b.join("maintown2");
  await tick();
  assert.equal(b.xts().some((o) => o._cmd === `sys:${Down.joinKO}`), false, "others still join");
  // Chat: a line too long, or two at once, is not sent on.
  a.join("maintown2");
  await tick();
  a.frames();
  b.frames();
  const say = (t: string) => a.send(clientPayload(0, Up.PubMsg, 1).utf(t).body());
  say("x".repeat(400));
  say("你好");
  say("再见");
  await tick();
  const chats = b.frames().filter((f) => f.handler === 0 && f.action === Down.pubMsg).length;
  assert.equal(chats, 1, "one short line of the three");
  // The 工具箱 closed: addPM gives only a starter to a player with none; a wild fight is at the
  // room's levels and only its own species is catchable.
  const srv = server(true);
  const closed = createGameHost({ store: srv.store, loadJson: tables, accounts: { required: true, register: true }, toolbox: false });
  const c = (() => {
    const out: Uint8Array[] = [];
    const s = closed.attach({ remote: "t", send: (x) => out.push(x), close: () => {} });
    let pn = -1;
    return { send: (payload: Uint8Array) => (pn = nextPacketNum(pn), s.receive(encodeClientFrame(pn, payload))) };
  })();
  c.send(clientPayload(0, Up.Login, -1).utf("aola").utf("奥拉Z").utf("pass-z").body());
  for (let i = 0; i < 50 && !(await srv.store.get(`user/${encodeURIComponent("奥拉Z")}`)); i++) await tick(10);
  c.send(clientPayload(0, Up.JoinRoom, -1).utf("maintown1").u8(49).i32(-1).u8(48).utf("").body());
  const xt = (ext: number, cmd: string, params: Record<string, unknown>) => c.send(clientPayload(1, Up.XtReq, 1).i16(ext).utf(cmd).raw(amf3Encode(params)).body());
  xt(13, "1201", { raceId: 1101, level: 100 });
  xt(13, "1201", { raceId: 7, level: 5 });
  await tick(100);
  const rec = (await srv.store.get<{ pets: { race: number; level: number }[] }>(`user/${encodeURIComponent("奥拉Z")}`))!;
  assert.deepEqual(rec.pets.map((p) => [p.race, p.level]), [[7, 5]], "the starter only");
});
