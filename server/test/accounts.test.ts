// The 奥拉 of a page (单机模式's 选择奥拉: up to three, made, renamed, deleted, brought in from
// a file with its conflicts) and, on a shared server, renaming in the game and 改密码.
import assert from "node:assert/strict";
import { test } from "node:test";
import { MemoryStore } from "../src/core/store.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";

const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const key = (name: string) => `user/${encodeURIComponent(name)}`;

/** A page's own game (no accounts), as server/src/browser/entry.ts makes it. */
function page() {
  const store = new MemoryStore();
  return { store, host: createGameHost({ store, loadJson: async () => undefined }) };
}

/** A connection logged in as name (pass on a shared server); its closed state. */
async function play(host: ReturnType<typeof createGameHost>, store: MemoryStore, name: string, pass = "") {
  let closed = false;
  // A shared server: 注册 first (a name already there: no matter).
  if (pass) await host.register(name, pass, `ws reg ${name}`);
  const s = host.attach({ remote: "ws test", send: () => {}, close: () => (closed = true) });
  s.receive(encodeClientFrame(nextPacketNum(-1), clientPayload(0, Up.Login, -1).utf("aola").utf(name).utf(pass).body()));
  for (let i = 0; i < 100 && !host.world.online(name); i++) await tick(10);
  void store;
  return { s, closed: () => closed || s.closed };
}

const fileOf = (roles: Record<string, Record<string, unknown>>) => ({
  format: "aola-revival-save",
  version: 1,
  data: Object.fromEntries(Object.entries(roles).map(([n, r]) => [key(n), { name: n, ...r }])),
});

test("单机模式's 奥拉: three at most, one a name, made, renamed and deleted", async () => {
  const { host } = page();
  assert.equal(await host.createUser("小奥拉"), null);
  assert.match(String(await host.createUser("小奥拉")), /已经有一个叫小奥拉的奥拉了/);
  assert.match(String(await host.createUser("a b")), /空格/);
  assert.equal(await host.createUser("小花"), null);
  assert.equal(await host.createUser("小草"), null);
  assert.match(String(await host.createUser("第四个")), /最多3个奥拉/);
  const list = await host.users();
  assert.deepEqual(list.map((r) => r.name), ["小奥拉", "小花", "小草"]);
  assert.ok(list.every((r) => r.id > 0 && r.score > 0), "the defaults of a new 奥拉");
  // Renamed: never to another's name.
  assert.match(String(await host.rename("小花", "小草")), /已经有奥拉用了/);
  assert.equal(await host.rename("小花", "花花"), null);
  assert.equal(await host.deleteUser("小草"), null);
  assert.deepEqual((await host.users()).map((r) => r.name), ["小奥拉", "花花"]);
  assert.equal(await host.createUser("第四个"), null, "a place again");
});

test("导入奥拉: as itself, a conflict asked about, replaced or under a new name, never past three", async () => {
  const { host, store } = page();
  await host.createUser("小奥拉");
  const file = fileOf({ 小奥拉: { score: 999, pets: [{ id: 3, race: 1, level: 12 }] }, 外来: { score: 5 } });
  assert.deepEqual((await host.addUser(file)).names?.sort(), ["外来", "小奥拉"].sort(), "which one, asked");
  // The same name as one here: asked; replaced (it keeps its id) or brought in as another.
  const id = (await host.users())[0].id;
  assert.deepEqual(await host.addUser(file, { from: "小奥拉" }), { conflict: "小奥拉" });
  assert.deepEqual(await host.addUser(file, { from: "小奥拉", replace: true }), { name: "小奥拉" });
  const replaced = (await store.get<Record<string, unknown>>(key("小奥拉")))!;
  assert.equal(replaced.score, 999);
  assert.equal(replaced.id, id);
  assert.deepEqual(await host.addUser(file, { from: "小奥拉", as: "第二个" }), { name: "第二个" });
  const second = (await store.get<Record<string, unknown>>(key("第二个")))!;
  assert.notEqual(second.id, id, "an id of its own");
  assert.equal((second.pets as unknown[]).length, 1);
  assert.match(String((await host.addUser(file, { from: "外来", as: "a,b" })).error), /符号/);
  assert.deepEqual(await host.addUser(file, { from: "外来" }), { name: "外来" });
  assert.match(String((await host.addUser(fileOf({ 第四: {} }))).error), /最多3个奥拉/);
});

test("in the game: a rename ends the game first; a deleted 奥拉's game ends", async () => {
  const { host, store } = page();
  const a = await play(host, store, "小奥拉");
  assert.match(String(await host.rename("小奥拉", "大奥拉")), /请先退出游戏/, "from the start screen: not while on");
  assert.equal(await host.rename("小奥拉", "大奥拉", undefined, undefined, true), null);
  assert.equal(a.closed(), true);
  assert.ok(await store.get(key("大奥拉")));
  assert.equal(await store.get(key("小奥拉")), undefined);
  const b = await play(host, store, "大奥拉");
  assert.equal(await host.deleteUser("大奥拉"), null);
  assert.equal(b.closed(), true);
  assert.deepEqual(await host.users(), []);
});

test("改密码 on a shared server: the old password first, the game goes on", async () => {
  const store = new MemoryStore();
  const host = createGameHost({ store, loadJson: async () => undefined, accounts: { required: true, register: true } });
  const a = await play(host, store, "奥拉E", "old-pass");
  assert.equal(await host.changePassword("奥拉E", "wrong", "new-pass"), "名字或密码不对哦。");
  assert.match(String(await host.changePassword("奥拉E", "old-pass", "")), /新密码/);
  assert.equal(await host.changePassword("奥拉E", "old-pass", "new-pass"), null);
  assert.equal(a.closed(), false, "still in the game");
  assert.equal((await host.exportSave("奥拉E", "old-pass")).error, "名字或密码不对哦。");
  assert.ok((await host.exportSave("奥拉E", "new-pass")).save);
  // A rename in the game asks for the password too.
  assert.equal(await host.rename("奥拉E", "奥拉F", "nope", undefined, true), "名字或密码不对哦。");
  assert.equal(a.closed(), false);
  assert.equal(await host.rename("奥拉E", "奥拉F", "new-pass", undefined, true), null);
  assert.equal(a.closed(), true);
  // A page has no passwords.
  assert.equal(await page().host.changePassword("x", "", "y"), "单机模式没有密码。");
});
