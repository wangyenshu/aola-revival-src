// 注册 apart from the login on a shared server (update100): a name a server does not have is
// refused as a wrong password is, 注册 makes it (fit names, passwords of 6 to 32, so many an
// address), 记住密码 keeps a token, not the password; a rename moves the 排行榜 rows and leaves
// no second record; the accounts' work goes a name at a time; the server's places.
import assert from "node:assert/strict";
import { test } from "node:test";
import { KeyedLocks } from "../src/core/locks.ts";
import { addrKey } from "../src/core/addr.ts";
import { Emulator } from "../src/core/emulator.ts";
import { MemoryRecorder } from "../src/core/recorder.ts";
import { MemoryStore } from "../src/core/store.ts";
import { looksLikeToken, SignupGuard, SIGNUP_TOO_FAST, SIGNUP_TOO_MANY, WRONG } from "../src/game/sfs2013/accounts.ts";
import { handleApi } from "../src/game/sfs2013/api.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";
import { FULL_TEXT, SFS2013_FRAMING, sfs2013Codec, World } from "../src/game/sfs2013/server.ts";

const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const key = (name: string) => `user/${encodeURIComponent(name)}`;

function shared(o: { register?: boolean; maxPlayers?: number; signupsPerDay?: number } = {}) {
  const store = new MemoryStore();
  const host = createGameHost({
    store,
    loadJson: async () => undefined,
    accounts: { required: true, register: o.register ?? true, signupsPerDay: o.signupsPerDay },
    maxPlayers: o.maxPlayers,
  });
  /** A login over the protocol: the logOK's name, or the logKO's words. */
  const login = async (name: string, pass: string, remote = "ws t") => {
    const out: Uint8Array[] = [];
    const s = host.attach({ remote, send: (b) => out.push(b), close: () => {} });
    s.receive(encodeClientFrame(nextPacketNum(-1), clientPayload(0, Up.Login, -1).utf("aola").utf(name).utf(pass).body()));
    for (let i = 0; i < 300; i++) {
      await tick(10);
      if (host.world.player(s)) return { ok: true, s };
      const text = new TextDecoder().decode(Buffer.concat(out.map((b) => Buffer.from(b))));
      if (/logKO|密码|名字|奥拉/.test(text) && !host.world.player(s) && i > 0) {
        // The refusal's words (utf in the frame): what follows the last length.
        const m = /([一-鿿][^\u0000]*)$/.exec(text);
        if (m) return { ok: false, s, error: m[1] };
      }
    }
    return { ok: false, s, error: "no answer" };
  };
  return { store, host, login };
}

test("注册: an unknown name does not sign up at the login; 注册 makes it, with fit names and passwords", async () => {
  const { store, host, login } = shared();
  const first = await login("新奥拉", "secret-1");
  assert.equal(first.ok, false);
  assert.equal(first.error, WRONG, "refused as a wrong password is");
  assert.equal(await store.get(key("新奥拉")), undefined, "nothing made");
  assert.match(String(await host.register("", "secret-1")), /名字/);
  assert.match(String(await host.register("新奥拉", "12345")), /最少6个字/);
  assert.match(String(await host.register("新奥拉", "x".repeat(33))), /最多32个字/);
  assert.match(String(await host.register("a b", "secret-1")), /空格/);
  assert.equal(await host.register("新奥拉", "secret-1"), null);
  assert.match(String(await host.register("新奥拉", "secret-2")), /已经有奥拉用了/);
  assert.equal((await login("新奥拉", "secret-2")).error, WRONG);
  assert.equal((await login("新奥拉", "secret-1")).ok, true);
  // A closed server (--closed) takes no new names.
  const closed = shared({ register: false });
  assert.match(String(await closed.host.register("别的", "secret-1")), /不收新的奥拉/);
  assert.equal(closed.host.registers, false);
  // The status says whether it does (the start screen's 注册).
  assert.equal((await handleApi(host, "/__api/status", "GET", "")).body.register, true);
});

test("注册: an address signs up so many a day and tries so many in ten minutes", async () => {
  const { host } = shared({ signupsPerDay: 2 });
  assert.equal(await host.register("一号", "secret-1", "ws a"), null);
  assert.equal(await host.register("二号", "secret-1", "ws a"), null);
  assert.equal(await host.register("三号", "secret-1", "ws a"), SIGNUP_TOO_MANY);
  assert.equal(await host.register("三号", "secret-1", "ws b"), null, "another address goes on");
  // Tries (a name taken counts): ten in ten minutes.
  let t = 0;
  const g = new SignupGuard(() => t);
  for (let i = 0; i < 10; i++) assert.equal(g.tryNow("x", 0), null);
  assert.equal(g.tryNow("x", 0), SIGNUP_TOO_FAST);
  t += 10 * 60 * 1000 + 1;
  assert.equal(g.tryNow("x", 0), null, "later, again");
});

test("a name the server does not have is answered as a wrong password, as late", async () => {
  const { host } = shared();
  assert.equal(await host.register("有的", "secret-1"), null);
  const time = async (name: string) => {
    const t0 = Date.now();
    const r = await handleApi(host, "/__api/save/export", "POST", JSON.stringify({ name, pass: "wrong-one" }), `ws ${name}`);
    return { ms: Date.now() - t0, body: r.body };
  };
  const [none, wrong] = await Promise.all([time("没有的"), time("有的")]);
  assert.deepEqual(none.body, wrong.body);
  assert.equal(none.body.error, WRONG);
  assert.ok(none.ms >= 950 && wrong.ms >= 950, `${none.ms} ms, ${wrong.ms} ms`);
  // The rename and 改密码 alike.
  assert.equal(await host.rename("没有的", "别名", "x"), WRONG);
  assert.equal(await host.changePassword("没有的", "x", "new-secret"), WRONG);
});

test("记住密码: a token logs in instead of the password; 改密码 asks the password and ends the tokens", async () => {
  const { store, host, login } = shared();
  assert.equal(await host.register("记住", "secret-1"), null);
  assert.equal((await host.remember("记住", "wrong-one")).error, WRONG);
  const { token } = await host.remember("记住", "secret-1");
  assert.ok(token && looksLikeToken(token) && token.length <= 32, String(token));
  const rec = (await store.get<{ tokens: { h: string }[] }>(key("记住")))!;
  assert.equal(rec.tokens.length, 1);
  assert.ok(!JSON.stringify(rec).includes(token!), "only its hash is kept");
  assert.equal((await host.remember("记住", token!)).error, WRONG, "a token makes no more");
  const inGame = await login("记住", token!);
  assert.equal(inGame.ok, true);
  inGame.s.close();
  await tick(20);
  assert.equal(await host.rename("记住", "记住了", token!), null, "the start screen's 改名字 takes it");
  assert.equal(await host.rename("记住了", "记住", token!), null);
  const file = (await host.exportSave("记住", token!)).save!;
  assert.ok(!JSON.stringify(file).includes("tokens"), "a 存档 file has no tokens");
  assert.equal(await host.changePassword("记住", token!, "secret-2"), WRONG, "改密码: the password itself");
  assert.equal(await host.changePassword("记住", "secret-1", "secret-2"), null);
  assert.equal((await login("记住", token!, "ws other")).error, WRONG, "the new password ended it");
  // 记住密码 taken off: that token goes.
  const t2 = (await host.remember("记住", "secret-2")).token!;
  await host.forget("记住", t2);
  assert.equal((await login("记住", t2, "ws third")).error, WRONG);
});

test("a rename moves the 排行榜 rows; a record a stopped rename left behind is not logged in to", async () => {
  const { store, host, login } = shared();
  assert.equal(await host.register("跑者", "secret-1"), null);
  await store.set("parkour/board", [{ dd: "跑者", nn: "跑者", md: 900 }, { dd: "别人", nn: "别人", md: 800 }]);
  await store.set("limitbomb/board", [{ dd: "跑者", nn: "跑者", score: 50 }]);
  assert.equal(await host.rename("跑者", "飞者", "secret-1"), null);
  assert.deepEqual((await store.get<{ dd: string }[]>("parkour/board"))!.map((r) => r.dd), ["飞者", "别人"]);
  assert.equal((await store.get<{ nn: string }[]>("limitbomb/board"))![0].nn, "飞者");
  assert.equal(await store.get(key("跑者")), undefined);
  // Stopped after the new name and the id were written: the old record is the id's no longer.
  const rec = (await store.get<Record<string, unknown>>(key("飞者")))!;
  await store.set(key("跑者"), { ...rec, name: "跑者" });
  assert.equal((await login("跑者", "secret-1")).ok, false);
  assert.equal(await store.get(key("跑者")), undefined, "taken away");
  assert.equal(await host.register("跑者", "secret-9"), null, "the name is free again");
});

test("the accounts' work a name at a time: a slow one holds up only its own name", async () => {
  const l = new KeyedLocks();
  const done: string[] = [];
  const slow = l.run(["a"], async () => {
    await tick(80);
    done.push("a slow");
  });
  const other = l.run(["b"], async () => void done.push("b"));
  const same = l.run(["a"], async () => void done.push("a next"));
  const both = l.run(["a", "b"], async () => void done.push("a+b"));
  await Promise.all([slow, other, same, both]);
  assert.deepEqual(done, ["b", "a slow", "a next", "a+b"]);
  assert.equal(l.size, 0, "nothing kept once done");
  // A failure is its call's; the next goes on.
  await assert.rejects(l.run(["c"], async () => { throw new Error("x"); }));
  assert.equal(await l.run(["c"], async () => 1), 1);
});

test("the server's places: logins past maxPlayers are refused, a player's own second page comes in", async () => {
  const { host, login } = shared({ maxPlayers: 1 });
  for (const n of ["甲", "乙"]) assert.equal(await host.register(n, "secret-1", `ws ${n}`), null);
  assert.equal((await login("甲", "secret-1")).ok, true);
  assert.equal((await login("乙", "secret-1")).error, FULL_TEXT);
  assert.equal((await login("甲", "secret-1", "ws again")).ok, true, "his own, in his place");
  // Connections not logged in: a few an address, so many in all.
  const pending = [];
  for (let i = 0; i < 4; i++) pending.push(host.attach({ remote: "ws idle", send: () => {}, close: () => {} }));
  assert.equal(host.admit("ws idle"), "address");
  assert.equal(host.admit("ws someone"), null);
  for (const s of pending) s.close();
});

test("a connection that logs out is closed if it does not log in again in time", async () => {
  const emu = new Emulator({ framing: SFS2013_FRAMING, codec: sfs2013Codec, recorder: new MemoryRecorder(), answerPolicy: false });
  new World(emu, { loginWaitMs: 60 });
  let closed = false;
  const s = emu.attach({ remote: "t", send: () => {}, close: () => (closed = true) }, 9339);
  let pn = -1;
  const send = (p: Uint8Array) => s.receive(encodeClientFrame((pn = nextPacketNum(pn)), p));
  send(clientPayload(0, Up.Login, -1).utf("aola").utf("某某").utf("").body());
  await tick(100);
  assert.equal(closed, false, "logged in: kept");
  send(clientPayload(0, Up.Logout, -1).body());
  await tick(120);
  assert.equal(closed || s.closed, true, "logged out and idle: closed");
});

test("addresses: IPv6 by its /64, IPv4 as it is", () => {
  assert.equal(addrKey("2001:db8:1:2:aaaa::1"), "2001:db8:1:2::/64");
  assert.equal(addrKey("2001:db8:1:2:bbbb:cccc:dddd:eeee"), "2001:db8:1:2::/64");
  assert.equal(addrKey("::ffff:10.0.0.7"), "10.0.0.7");
  assert.equal(addrKey("203.0.113.5"), "203.0.113.5");
  assert.equal(addrKey("[fe80::1%eth0]"), "fe80:0:0:0::/64");
});
