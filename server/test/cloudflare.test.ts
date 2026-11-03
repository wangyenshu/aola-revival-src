// The Cloudflare adapter without Cloudflare: its Store over a Durable Object's storage, the
// Worker's routing, and the Durable Object's API answers (the WebSocket part needs the runtime).
import assert from "node:assert/strict";
import { test } from "node:test";
import worker, { AolaGame, DurableStore, type Env } from "../src/cloudflare/worker.ts";

function fakeStorage() {
  const m = new Map<string, unknown>();
  return {
    async get<T>(k: string) { return m.get(k) as T | undefined; },
    async put<T>(k: string, v: T) { m.set(k, v); },
    async delete(k: string) { return m.delete(k); },
    async list<T>(o: { prefix?: string } = {}) { return new Map([...m].filter(([k]) => k.startsWith(o.prefix ?? ""))) as Map<string, T>; },
  };
}

test("the Durable Object store keeps JSON copies and lists by prefix", async () => {
  const s = new DurableStore(fakeStorage());
  const rec = { a: [1, 2] };
  await s.set("user/x", rec);
  rec.a.push(3);
  assert.deepEqual(await s.get("user/x"), { a: [1, 2] });
  await s.set("uid/1", "x");
  assert.deepEqual(await s.keys("user/"), ["user/x"]);
  await s.delete("user/x");
  assert.equal(await s.get("user/x"), undefined);
});

test("the Worker: the site from the assets, the game and its API from the Durable Object", async () => {
  const seen: string[] = [];
  const game = new AolaGame({ storage: fakeStorage() }, { ASSETS: { fetch: async () => new Response("{}", { status: 404 }) } } as unknown as Env);
  const env = {
    ASSETS: { fetch: async (r: Request | string) => (seen.push("assets " + new URL(typeof r === "string" ? r : r.url).pathname), new Response("page")) },
    GAME: { idFromName: (n: string) => n, get: () => ({ fetch: (r: Request) => (seen.push("game " + new URL(r.url).pathname), game.fetch(r)) }) },
  } as unknown as Env;
  assert.equal(await (await worker.fetch(new Request("https://aola.example/index.html"), env)).text(), "page");
  const status = await worker.fetch(new Request("https://aola.example/__api/status"), env);
  assert.deepEqual(await status.json(), { ok: true, online: 0, name: "aola-revival", imports: true });
  const rename = await worker.fetch(new Request("https://aola.example/__api/rename", { method: "POST", body: JSON.stringify({ name: "没有", pass: "x", to: "新名字" }) }), env);
  assert.equal(rename.status, 400);
  // An import carries a save file: more than the other requests may (4 KB), within its own limit.
  const big = JSON.stringify({ name: "没有", pass: "x", save: { format: "aola-revival-save", version: 1, data: { pad: "x".repeat(10000) } } });
  assert.equal((await game.fetch(new Request("https://aola.example/__api/rename", { method: "POST", body: big }))).status, 413);
  const imp = await game.fetch(new Request("https://aola.example/__api/save/import", { method: "POST", body: big }));
  assert.equal(imp.status, 400);
  assert.match(String(((await imp.json()) as { error: string }).error), /没有奥拉/);
  // Not a WebSocket: refused.
  assert.equal((await worker.fetch(new Request("https://aola.example/__socket/9339"), env)).status, 404);
  assert.deepEqual(seen, ["assets /index.html", "game /__api/status", "game /__api/rename", "game /__socket/9339"]);
});
