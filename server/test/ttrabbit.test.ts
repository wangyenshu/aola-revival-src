import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { Emulator } from "../src/core/emulator.ts";
import { MemoryRecorder } from "../src/core/recorder.ts";
import { TT_RABBIT_COST, TT_RABBIT_GAME, TT_RABBIT_PET, installSfs2013 } from "../src/game/sfs2013/game.ts";
import { SFS2013_FRAMING, sfs2013Codec, type XtContext, type XtHandler } from "../src/game/sfs2013/server.ts";

const site = new URL("../../rebuild/static/www.9aola.com/", import.meta.url);
// Encrypt.encryptCode(0), as the 2013 client sends a score of 0.
const ZERO = 721212121;

test("大战TT兔's 积分 add up by the 关 passed, and buy 糖糖 once", async () => {
  const emu = new Emulator({ framing: SFS2013_FRAMING, codec: sfs2013Codec, recorder: new MemoryRecorder(), answerPolicy: false });
  const world = installSfs2013(emu, { dev: true, loadJson: async (p) => JSON.parse(await readFile(new URL(p, site), "utf8")) }) as unknown as { handlers: Map<string, XtHandler> };
  const name = "小奥拉";
  await emu.store.set(`user/${encodeURIComponent(name)}`, { id: 10001, name, pets: [], nextPetId: 1 });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string, Record<string, unknown>][] = [];
    const ctx = { params, player: { name, room: { name: "candymuseum" } }, session: {}, reply: (b: Record<string, unknown>, c = key) => out.push([c, b]) } as unknown as XtContext;
    await world.handlers.get(key)!(ctx, key);
    return out;
  };
  const state = async () => (await call("UserGameExtension.89_6", { name: TT_RABBIT_GAME })).at(-1)![1];
  assert.deepEqual(await state(), { score: 0, gainEgg: false });
  assert.deepEqual((await call("UserGameExtension.89_7", { name: TT_RABBIT_GAME })).at(-1)![1], { suc: false });

  // The game ends at 关 4 having passed 3: 1 + 2 + 3 积分, which its end panel shows when addScore is true.
  const end = (await call("ScoreManager.increaseScore", { score: ZERO, level: 3, exitWay: 1, gameName: TT_RABBIT_GAME })).at(-1)![1];
  assert.equal(end.addScore, true);
  assert.deepEqual(await state(), { score: 6, gainEgg: false });
  // Another game's levels are not 积分.
  const other = (await call("ScoreManager.increaseScore", { score: ZERO, level: 5, exitWay: 1, gameName: "gameMyCat" })).at(-1)![1];
  assert.equal(other.addScore, false);

  await call("ScoreManager.increaseScore", { score: ZERO, level: 5, exitWay: 1, gameName: TT_RABBIT_GAME });
  assert.deepEqual(await state(), { score: 21, gainEgg: false });
  const got = await call("UserGameExtension.89_7", { name: TT_RABBIT_GAME });
  assert.deepEqual(got.at(-1)![1], { suc: true });
  assert.ok(got.some(([c]) => c === "2201"), "the new 亚比 goes to the bag");
  const rec = (await emu.store.get<{ pets: { race: number }[] }>(`user/${encodeURIComponent(name)}`))!;
  assert.ok(rec.pets.some((p) => p.race === TT_RABBIT_PET));
  assert.deepEqual(await state(), { score: 21 - TT_RABBIT_COST, gainEgg: true });
  assert.deepEqual((await call("UserGameExtension.89_7", { name: TT_RABBIT_GAME })).at(-1)![1], { suc: false }, "only once");
});
