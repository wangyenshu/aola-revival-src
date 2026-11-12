// What a client says, and what the server checks itself (update100), on a fair server (the
// 工具箱 closed): gathering at the room's own points, the 黑星堡垒 floor and the seals after a win
// of the session's, the levels a client asks for a fight, the free shops closed, the day's 晶币 of
// the mini games, the 亚比 of a fight kept, a mod's species, the money's bounds.
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { amf3Encode } from "../src/core/amf3.ts";
import { concat } from "../src/core/bytes.ts";
import { FrameSplitter } from "../src/core/framing.ts";
import { MemoryStore } from "../src/core/store.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { capMoney, keepMoney, MONEY_MAX } from "../src/game/sfs2013/money.ts";
import { EXT_NAMES, Reader, Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";
import { SFS2013_FRAMING } from "../src/game/sfs2013/server.ts";
import { recordWin } from "../src/game/sfs2013/wins.ts";
import { FAIR_ABOVE } from "../src/game/sfs2013/battle.ts";
import { PARKOUR_CMD, PARKOUR_EXT } from "../src/game/sfs2013/parkour.ts";

const TABLES = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../rebuild/static/www.9aola.com");
const tables = async (p: string) => {
  try {
    return JSON.parse(await readFile(path.join(TABLES, p), "utf8"));
  } catch {
    return undefined;
  }
};
const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const extNo = (name: string) => Number(Object.entries(EXT_NAMES).find(([, n]) => n === name)![0]);
const key = (n: string) => `user/${encodeURIComponent(n)}`;

async function fairPlayer(name = "公平") {
  const store = new MemoryStore();
  const host = createGameHost({ store, loadJson: tables, accounts: { required: true, register: true }, toolbox: false });
  assert.equal(await host.register(name, "secret-1"), null);
  const out: Uint8Array[] = [];
  const s = host.attach({ remote: "ws c", send: (b) => out.push(b), close: () => {} });
  let pn = -1;
  const send = (p: Uint8Array) => s.receive(encodeClientFrame((pn = nextPacketNum(pn)), p));
  const sp = new FrameSplitter(SFS2013_FRAMING);
  let first = true;
  let kept: Record<string, unknown>[] = [];
  const pull = () => {
    let all = concat(...out.splice(0));
    if (first && all[0] === 0x3c) all = all.subarray(all.indexOf(0) + 1);
    first = false;
    for (const f of sp.push(all)) {
      const r = new Reader(f);
      r.i32();
      if (r.u8() === 1) kept.push(r.amf3() as Record<string, unknown>);
    }
  };
  const wait = async (cmd: string, ms = 3000) => {
    for (const end = Date.now() + ms; ; ) {
      pull();
      const i = kept.findIndex((o) => o._cmd === cmd);
      if (i >= 0) return kept.splice(i, 1)[0];
      if (Date.now() > end) return undefined;
      await tick(10);
    }
  };
  const xt = (ext: string, cmd: string, params: Record<string, unknown> = {}) =>
    send(clientPayload(1, Up.XtReq, 1).i16(extNo(ext)).utf(cmd).raw(amf3Encode(params)).body());
  const join = (room: string) => send(clientPayload(0, Up.JoinRoom, -1).utf(room).u8(49).i32(-1).u8(48).utf("").body());
  send(clientPayload(0, Up.Login, -1).utf("aola").utf(name).utf("secret-1").body());
  for (let i = 0; i < 200 && !host.world.online(name); i++) await tick(10);
  const rec = async () => (await store.get<Record<string, any>>(key(name)))!;
  const clear = () => {
    pull();
    kept = [];
  };
  return { host, store, s, xt, join, wait, rec, clear, name };
}

test("14_11: what the room's gather points give, not any 道具", async () => {
  const p = await fairPlayer();
  p.join("maintown1");
  await tick(50);
  p.xt("MaterialExtension", "14_11", { ItemId: 38 });
  assert.equal((await p.wait("14_11"))?.result, 2, "no gather point of it here");
  await tick(1100);
  p.join("aixiscene1");
  await tick(50);
  p.xt("MaterialExtension", "14_11", { ItemId: 38 });
  assert.equal((await p.wait("14_11"))?.result, 1, "炎冰 at 艾希's point");
  p.xt("MaterialExtension", "14_11", { ItemId: 402 });
  assert.equal((await p.wait("14_11"))?.result, 2, "anything else: no");
  assert.equal((await p.rec()).items["2"]["38"], 1);
});

test("黑星堡垒's floor and the 念之塔's seals: only after a win of the session's there", async () => {
  const p = await fairPlayer();
  p.xt("VipTowerExtension", "84_2", { fl: 1 });
  await p.wait("84_2");
  p.xt("VipTowerExtension", "84_4", { fl: 1 });
  await p.wait("84_4");
  assert.equal((await p.rec()).vipTower.ps, false, "said, not won");
  recordWin(p.s, 70536, "viparena2");
  p.xt("VipTowerExtension", "84_4", { fl: 1 });
  await p.wait("84_4");
  assert.equal((await p.rec()).vipTower.ps, true);
  // A win elsewhere does not open a seal.
  recordWin(p.s, 10001, "maintown1");
  p.xt("MentalHallExtension", "98_1", { type: 18 });
  assert.equal((await p.wait("98_1"))?.result, 0);
});

test("54_2 on a fair server: a level asked is at most FAIR_ABOVE over the strongest 亚比", async () => {
  const p = await fairPlayer();
  p.join("maintown1");
  await tick(50);
  // A starter (addPM gives one to a player with none).
  p.xt("PocketMonsterExtension", "1201", { raceId: 7, level: 5 });
  await tick(100);
  const top = Math.max(...(await p.rec()).pets.map((x: { level: number }) => x.level));
  p.clear();
  p.xt("PetExtension", "54_2", { raceId: 1, level: 100 });
  const start = (await p.wait("2303"))!;
  const foe = (start.pmmList as { battleView: { pmList: { pmSView: { lv: number } }[] } }[])[1].battleView.pmList[0].pmSView.lv;
  assert.ok(foe <= top + FAIR_ABOVE, `Lv${foe} against a Lv${top}`);
});

test("the free shops and the day's 晶币: closed with the 工具箱, and 斑比向前冲 within the mini games' day", async () => {
  const p = await fairPlayer();
  const before = (await p.rec()).score;
  p.xt(PARKOUR_EXT, `${PARKOUR_CMD}_buyJingBi`, { id: 3 });
  assert.equal((await p.wait(`${PARKOUR_CMD}_buyJingBi`))?.res, 0);
  assert.equal((await p.rec()).score, before);
  p.xt("UserGameExtension", "89_bb2", { score: 1, money: 1000 });
  assert.equal((await p.wait("89_bb2"))?.m, 1000);
  p.xt("UserGameExtension", "89_bb2", { score: 1, money: 1000 });
  assert.equal((await p.wait("89_bb2"))?.m, 0, "the day's 1000 paid");
});

test("a 亚比 of a fight is not moved, let go or fused till it is over; a mod adds no species here", async () => {
  const p = await fairPlayer();
  p.join("maintown1");
  await tick(50);
  p.xt("PocketMonsterExtension", "1201", { raceId: 7, level: 5 });
  await tick(100);
  const id = (await p.rec()).pets[0].id;
  p.xt("PetExtension", "54_2", { raceId: 1, level: 5 });
  await p.wait("2303");
  p.xt("PocketMonsterExtension", "revival_release", { id });
  const r = await p.wait("revival_release");
  assert.equal(r?.result, -4, JSON.stringify(r));
  p.xt("SundriesExtension", "revival_mod", { op: "species", mod: "testmod", def: "{}" });
  assert.match(String((await p.wait("revival_mod"))?.msg), /不能加自己的亚比/);
});

test("money stays within 0 … 9,999,999 whatever a handler adds", () => {
  assert.equal(capMoney(-5), 0);
  assert.equal(capMoney(12_345_678), MONEY_MAX);
  assert.equal(capMoney("12.7"), 12);
  const rec: Record<string, unknown> = { score: 20_000_000, xingbi: -1, jingdou: 5, name: "x" };
  keepMoney(rec);
  assert.deepEqual(rec, { score: MONEY_MAX, xingbi: 0, jingdou: 5, name: "x" });
});
