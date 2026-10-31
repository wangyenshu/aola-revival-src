import assert from "node:assert/strict";
import { test } from "node:test";
import { installBattles } from "../src/game/sfs2013/battle.ts";
import { ensureFbSpecies, fbCode, fbGrade, fbOfRoom, fbRoomPets, fbSpecies, FBS } from "../src/game/sfs2013/fb.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

test("the 四大副本's rooms: the ids the room scripts check", () => {
  const aixi = FBS[0];
  assert.equal(fbOfRoom("fbaixi3"), aixi);
  assert.equal(fbOfRoom("aixiscene4"), undefined);
  // 幻影冰宫's gate: 冰沙斗士 / 埃黑多夫 as the door of fbaixi3 counts them (10421, 10415; 120421, 120415 harder).
  assert.deepEqual([...new Set(fbRoomPets(aixi, "fbaixi3", 0).map((p) => p.code))].sort(), [10415, 10421, 10448, 10466]);
  assert.ok(fbRoomPets(aixi, "fbaixi3", 1).some((p) => p.code === 120421));
  // Its last boss is told 10999 (120999 harder), fought as the species made for it.
  assert.equal(fbRoomPets(aixi, "fbaixi9", 2)[0].code, 120999);
  assert.equal(fbSpecies(120999), 999);
  // 恐龙博物馆's 龙之谷 keeps the script's own ids.
  assert.deepEqual(fbRoomPets(FBS[3], "fbyishuzhidu2", 1).map((p) => p.code), [30401, 30402, 30403]);
  assert.equal(fbCode(30060, 2), 30060);
  assert.equal(fbGrade(200), "SSS");
  assert.equal(fbGrade(20 * 60), "C");
  const pm = { species: { "899": { n: "冰铠力士", c: ["45", "45"] } } as Record<string, unknown> };
  ensureFbSpecies(pm);
  assert.equal((pm.species["999"] as { n: string }).n, "拉贝尔幻影");
});

test("a 副本 run: join, the room's 亚比, a chest once, the rating", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const owner = { id: 1, pets: [], items: {} } as unknown as Parameters<Parameters<typeof installBattles>[1]["save"]>[0];
  let now = 1_000_000;
  installBattles(world, {
    load: async () => owner,
    save: async () => {},
    tables: async () => ({ species: {}, pm: { species: {}, skills: {}, chart: {}, exp: {} } }),
    wild: async () => ({}),
    today: () => "2013-01-25",
    now: () => now,
  });
  const call = async (key: string, params: Record<string, unknown> = {}, room = "") => {
    const replies: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: "小奥拉", room: { name: room } }, reply: (o: Record<string, unknown>, c?: string) => replies.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return replies;
  };
  assert.equal((await call("FBExtension.fb_9", { id: 0 }))[0][1].lt, 5);
  assert.equal((await call("FBExtension.fb_1", { id: 0, name: "fbaixi", lv: 1 }))[0][1].succ, true);
  const pets = (await call("FBExtension.fb_3", {}, "fbaixi1")).at(-1)![1].pms;
  assert.equal(pets.length, 3);
  assert.equal(pets[0].raceId, 120421);
  // A room without wanderers sends none; another 副本's room is not this run's.
  assert.equal((await call("FBExtension.fb_3", {}, "fbaixi4")).at(-1)![1].pms.length, 0);
  assert.equal((await call("FBExtension.fb_3", {}, "fbsuolide1")).at(-1)![1].pms.length, 0);
  assert.equal((await call("FBExtension.fb_5", {}, "fbaixi5")).at(-1)![1].succ, true);
  assert.equal((await call("FBExtension.fb_5", {}, "fbaixi5")).at(-1)![1].succ, false);
  now += 6 * 60 * 1000;
  const fin = (await call("FBExtension.fb_4", {}, "fbaixi9")).at(-1)![1];
  assert.equal(fin.fin, true);
  assert.equal(fin.gr, "S");
  assert.equal((await call("FBExtension.fb_6", { id: 0 }))[0][1].gr, "#;S;#");
  assert.equal((await call("FBExtension.fb_9", { id: 0 }))[0][1].lt, 4);
});
