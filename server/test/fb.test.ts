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

test("each room's fights are the 亚比 its script and pictures show", () => {
  const [aixi, suolide, siwude, dino] = FBS;
  const species = (def: (typeof FBS)[number], room: string, run = 0) => fbRoomPets(def, room, 0, run).map((p) => fbSpecies(p.code));
  // 蚁族王朝: 兵蚁 (NPC 644) in the first two rooms, 牛角滴滴 (NPC 645) at 蚁穴下水道's doors,
  // 毒菇球 / 金刚蛤蟆 / 下水猛鳄 (npc_0–2, NPCs 190–192), the 工蚁, the two statues in turn.
  assert.deepEqual(species(siwude, "fbsiwude2"), [216, 216, 216]);
  assert.deepEqual(species(siwude, "fbsiwude3"), [244, 244, 244]);
  assert.deepEqual(species(siwude, "fbsiwude4"), [241, 242, 243]);
  assert.deepEqual(species(siwude, "fbsiwude5"), [217]);
  assert.deepEqual([species(siwude, "fbsiwude6", 0), species(siwude, "fbsiwude6", 1)], [[218], [219]]);
  assert.deepEqual(species(siwude, "fbsiwude10"), [225, 223, 224, 222]);
  assert.deepEqual(species(siwude, "fbsiwude11"), [216, 226, 227]);
  // The rooms the team route does not walk start no fight.
  assert.deepEqual([species(siwude, "fbsiwude7"), species(siwude, "fbsiwude8")], [[], []]);
  // 倒立金字塔: a 石像守卫 for each statue flagstone (ids on to 9), 帕克 in three coffins, the coin slot.
  assert.deepEqual(species(suolide, "fbsuolide2"), Array(9).fill(213));
  assert.deepEqual(species(suolide, "fbsuolide3"), [304, 304, 304]);
  assert.deepEqual(species(suolide, "fbsuolide7"), [81, 90, 272]);
  // No room fights the 2011 event boss 影刃.
  const all = FBS.flatMap((d) => Object.keys(d.rooms).flatMap((r) => [0, 1].flatMap((run) => species(d, r, run))));
  assert.ok(!all.includes(195));
  // Every 亚比 the 图鉴 says is only found in a 副本 is fought in its own.
  const own: [(typeof FBS)[number], number[]][] = [
    [aixi, [415, 448, 466]],
    [suolide, [210, 213, 240, 272, 340]],
    [siwude, [216, 217, 218, 219, 222, 223, 224, 225, 227, 241, 242, 243, 244]],
    [dino, [400, 401, 402, 403, 404, 405]],
  ];
  for (const [def, list] of own) {
    const here = new Set(Object.keys(def.rooms).flatMap((r) => [0, 1].flatMap((run) => species(def, r, run))));
    for (const s of list) assert.ok(here.has(s), `${def.title} fights ${s}`);
  }
  // Bosses stand a few levels above the room's other fights; harder modes above 简单.
  const [anubis] = fbRoomPets(suolide, "fbsuolide4", 0);
  assert.ok(anubis.lv > fbRoomPets(suolide, "fbsuolide3", 0)[0].lv);
  assert.ok(fbRoomPets(siwude, "fbsiwude3", 1)[0].lv > fbRoomPets(siwude, "fbsiwude3", 0)[0].lv + 20);
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
