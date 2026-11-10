// 礼包 (giftbags.ts): opened when bought, what they hold into the bag; bags an older save holds.
import assert from "node:assert/strict";
import { test } from "node:test";
import { amf3Encode } from "../src/core/amf3.ts";
import { concat } from "../src/core/bytes.ts";
import { FrameSplitter } from "../src/core/framing.ts";
import { MemoryStore } from "../src/core/store.ts";
import { GIFT_BAGS, openGiftBag, openHeldGiftBags, type GiftOwner } from "../src/game/sfs2013/giftbags.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { EXT_NAMES, Reader, Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";
import { SFS2013_FRAMING } from "../src/game/sfs2013/server.ts";

const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const EXT = (name: string) => Number(Object.entries(EXT_NAMES).find(([, n]) => n === name)![0]);

test("炫光魔法礼包: what its page shows, the 经验 for the HELLO", () => {
  const o: GiftOwner = { items: {}, robot: { exp: 5 } };
  const op = openGiftBag(o, 644)!;
  assert.deepEqual(o.items!["2"], { 378: 2, 66: 2, 62: 2, 189: 2, 44: 3 });
  assert.equal(o.robot!.exp, 100005);
  assert.deepEqual(op.amounts.sort(), ["2_189_0_2", "2_378_0_2", "2_44_0_3", "2_62_0_2", "2_66_0_2"]);
  assert.match(op.got.join("、"), /三倍经验器×2.*自动战斗仪×3、经验×100000/);
  assert.equal(op.score, false);
  // Two at once: twice as much.
  const two: GiftOwner = { items: {}, robot: { exp: 0 } };
  openGiftBag(two, 644, 2);
  assert.equal(two.items!["2"]["44"], 6);
  assert.equal(two.robot!.exp, 200000);
});

test("the first one bought brings its 龙珠; eggs, 战术卡, zoo things, clothes, 晶币; a cap", () => {
  const o: GiftOwner = { items: {} };
  openGiftBag(o, 271);
  openGiftBag(o, 271);
  assert.equal(o.items!["2"]["285"], 1, "one 六星龙珠, the first time only");
  assert.equal(o.items!["2"]["221"], 400);
  assert.equal(o.helloExp, 200000, "no HELLO yet: it waits");
  o.robot = { exp: 1 };
  openHeldGiftBags(o);
  assert.equal(o.robot.exp, 200001);
  assert.equal(o.helloExp, undefined);
  openGiftBag(o, 611);
  assert.equal(o.items!["5"]["1292"], 1, "小幻亚比蛋 (an egg is its race)");
  openGiftBag(o, 635);
  assert.equal(o.items!["8"]["33"], 1, "超攻之勇者卡");
  openGiftBag(o, 463);
  assert.deepEqual(o.items!["12"], { 10008: 1, 10019: 1 });
  assert.equal(o.items!["13"]["5"], 4);
  openGiftBag(o, 502);
  openGiftBag(o, 502);
  assert.deepEqual(o.items!["0"], { 1218: 1, 1219: 1, 1220: 1, 1221: 1, 1222: 1, 1223: 1 }, "clothes: one each");
  const rich: GiftOwner = { items: {}, score: 9_990_000 };
  assert.equal(openGiftBag(rich, 662)!.score, true);
  assert.equal(rich.score, 9_999_999);
  const capped: GiftOwner = { items: { 2: { 419: 9990 } } };
  const op = openGiftBag(capped, 659, 1, () => 9999)!;
  assert.equal(capped.items!["2"]["419"], 9999);
  assert.ok(op.amounts.includes("2_419_0_9"));
  assert.equal(openGiftBag({}, 419), undefined, "not a bag");
  // Every bag gives something, and names what.
  for (const [id, bag] of Object.entries(GIFT_BAGS)) assert.ok(bag.got.length || bag.exp || bag.score, id);
});

test("a bag an older save holds is opened when it is loaded", () => {
  const o: GiftOwner = { items: { 2: { 644: 1, 30: 3 } }, robot: { exp: 0 } };
  openHeldGiftBags(o);
  assert.equal(o.items!["2"]["644"], undefined);
  assert.equal(o.items!["2"]["30"], 3);
  assert.equal(o.items!["2"]["44"], 3);
});

test("bought in the catalog: opened, what it held through onAmountUpdated, got in the reply", async () => {
  const materials = { 2: { 644: [0, 0, 99, 999, 1, "炫光魔法礼包"], 30: [100, 50, 0, 999, 0, "体力糖"] } };
  const store = new MemoryStore();
  const host = createGameHost({ store, loadJson: async (p) => (p === "revival/materials.json" ? materials : undefined), toolbox: true });
  const out: Uint8Array[] = [];
  const s = host.attach({ remote: "t", send: (b) => out.push(b), close: () => {} });
  let pn = -1;
  const send = (payload: Uint8Array) => s.receive(encodeClientFrame((pn = nextPacketNum(pn)), payload));
  const sp = new FrameSplitter(SFS2013_FRAMING);
  let first = true;
  const got: Record<string, unknown>[] = [];
  const pull = () => {
    let all = concat(...out.splice(0));
    if (first && all[0] === 0x3c) all = all.subarray(all.indexOf(0) + 1);
    first = false;
    for (const f of sp.push(all)) {
      const r = new Reader(f);
      r.i32();
      if (r.u8() === 1) got.push(r.amf3() as Record<string, unknown>);
    }
  };
  const wait = async (cmd: string) => {
    for (let i = 0; i < 300; i++) {
      pull();
      const k = got.findIndex((o) => o._cmd === cmd);
      if (k >= 0) return got.splice(k, 1)[0];
      await tick(10);
    }
    return undefined;
  };
  const xt = (ext: string, cmd: string, params: Record<string, unknown>) =>
    send(clientPayload(1, Up.XtReq, 1).i16(EXT(ext)).utf(cmd).raw(amf3Encode(params)).body());
  send(clientPayload(0, Up.Login, -1).utf("aola").utf("小奥拉").utf("").body());
  assert.ok(await wait("logOK"));
  xt("SundriesExtension", "revival_toolbox", { xingbi: 500, vip: 1 });
  assert.ok(await wait("revival_toolbox"));
  got.length = 0;
  xt("MaterialExtension", "buyMaterial", { tp: 2, mi: 644, qt: 1, ed: true });
  const r = (await wait("buyMaterial"))!;
  assert.equal(r.res, 1);
  assert.match(String(r.got), /^三倍经验器×2、性格重塑卡×2、双倍学习器×2、寻宝雷达×2、自动战斗仪×3、经验×100000$/);
  const amounts = got.filter((o) => o._cmd === "onAmountUpdated").map((o) => String(o.amount)).join("#");
  assert.ok(amounts.includes("2_378_0_2") && amounts.includes("2_44_0_3"), amounts);
  assert.ok(!amounts.includes("2_644_"), "no bag in the bag");
  const save = (await host.exportSave("小奥拉")).save as { data: Record<string, { items: Record<string, Record<string, number>>; xingbi: number }> };
  const rec = Object.values(save.data).find((v) => v && typeof v === "object" && "items" in v)!;
  assert.equal(rec.items["2"]["644"], undefined);
  assert.equal(rec.items["2"]["378"], 2);
  assert.equal(rec.xingbi, 500 - 50, "half for 蓝宝石");
  // Not a bag: as before.
  xt("MaterialExtension", "buyMaterial", { tp: 2, mi: 30, qt: 1 });
  const r2 = (await wait("buyMaterial"))!;
  assert.equal(r2.res, 1);
  assert.equal(r2.got, undefined);
});

test("购买全套 (61_4): what one lacks of the 套装, its prices added up, all or none", async () => {
  const materials = { 0: { 8: [9_000_000, 0, 0, 1, 0, "金冠"], 9: [200, 100, 0, 1, 0, "香蕉衣"], 10: [100, 50, 0, 1, 0, "香蕉裤"], 11: [50, 25, 0, 1, 0, "香蕉鞋"] } };
  const store = new MemoryStore();
  const host = createGameHost({ store, loadJson: async (p) => (p === "revival/materials.json" ? materials : undefined), toolbox: true });
  const out: Uint8Array[] = [];
  const s = host.attach({ remote: "t", send: (b) => out.push(b), close: () => {} });
  let pn = -1;
  const send = (payload: Uint8Array) => s.receive(encodeClientFrame((pn = nextPacketNum(pn)), payload));
  const sp = new FrameSplitter(SFS2013_FRAMING);
  let first = true;
  const got: Record<string, unknown>[] = [];
  const pull = () => {
    let all = concat(...out.splice(0));
    if (first && all[0] === 0x3c) all = all.subarray(all.indexOf(0) + 1);
    first = false;
    for (const f of sp.push(all)) {
      const r = new Reader(f);
      r.i32();
      if (r.u8() === 1) got.push(r.amf3() as Record<string, unknown>);
    }
  };
  const wait = async (cmd: string) => {
    for (let i = 0; i < 300; i++) {
      pull();
      const k = got.findIndex((o) => o._cmd === cmd);
      if (k >= 0) return got.splice(k, 1)[0];
      await tick(10);
    }
    return undefined;
  };
  const xt = (ext: string, cmd: string, params: Record<string, unknown>) =>
    send(clientPayload(1, Up.XtReq, 1).i16(EXT(ext)).utf(cmd).raw(amf3Encode(params)).body());
  send(clientPayload(0, Up.Login, -1).utf("aola").utf("小奥拉").utf("").body());
  assert.ok(await wait("logOK"));
  xt("SundriesExtension", "revival_toolbox", { score: 1000 });
  assert.ok(await wait("revival_toolbox"));
  xt("MaterialExtension", "buyMaterial", { tp: 0, mi: 9, qt: 1 });
  assert.equal((await wait("buyMaterial"))!.res, 1);
  // Too little 晶币 for all: none is bought.
  xt("MaterialExtension", "61_4", { m: "0,8,1;0,10,1" });
  assert.equal((await wait("61_4"))!.res, -2);
  got.length = 0;
  // The 香蕉衣 had already is left out; the other two for 150.
  xt("MaterialExtension", "61_4", { m: "0,9,1;0,10,1;0,11,1" });
  const r = (await wait("61_4"))!;
  assert.deepEqual([r.res, r.m], [1, "0,10,1;0,11,1"]);
  assert.equal(r.score, (got.find((o) => o._cmd === "onScoreUpdated") as { score: number }).score);
  assert.ok(got.some((o) => o._cmd === "onAmountUpdated" && o.amount === "0_10_0_1#0_11_0_1"));
  xt("MaterialExtension", "61_4", { m: "0,9,1;0,10,1;0,11,1" });
  assert.equal((await wait("61_4"))!.res, -4);
});
