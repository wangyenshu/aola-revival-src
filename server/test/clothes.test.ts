// The clothes someone wears, asked by name (the 名片 opened from 好友 for a player not in the room).
import assert from "node:assert/strict";
import { test } from "node:test";
import { amf3Encode } from "../src/core/amf3.ts";
import { concat } from "../src/core/bytes.ts";
import { FrameSplitter } from "../src/core/framing.ts";
import { MemoryStore } from "../src/core/store.ts";
import { DEFAULT_AVATAR } from "../src/game/sfs2013/game.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { EXT_NAMES, Reader, Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";
import { SFS2013_FRAMING } from "../src/game/sfs2013/server.ts";

const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const EXT = (name: string) => Number(Object.entries(EXT_NAMES).find(([, n]) => n === name)![0]);

test("getUserWearingClothes: {un} -> {un, cl} as his user variable c", async () => {
  const host = createGameHost({ store: new MemoryStore(), loadJson: async () => undefined });
  const out: Uint8Array[] = [];
  const s = host.attach({ remote: "t", send: (b) => out.push(b), close: () => {} });
  let pn = -1;
  const send = (payload: Uint8Array) => s.receive(encodeClientFrame((pn = nextPacketNum(pn)), payload));
  const sp = new FrameSplitter(SFS2013_FRAMING);
  let first = true;
  const got: Record<string, unknown>[] = [];
  const wait = async (cmd: string) => {
    for (let i = 0; i < 300; i++) {
      let all = concat(...out.splice(0));
      if (first && all[0] === 0x3c) all = all.subarray(all.indexOf(0) + 1);
      if (all.length) first = false;
      for (const f of sp.push(all)) {
        const r = new Reader(f);
        r.i32();
        if (r.u8() === 1) got.push(r.amf3() as Record<string, unknown>);
      }
      const k = got.findIndex((o) => o._cmd === cmd);
      if (k >= 0) return got.splice(k, 1)[0];
      await tick(10);
    }
    return undefined;
  };
  const xt = (cmd: string, params: Record<string, unknown>) =>
    send(clientPayload(1, Up.XtReq, 1).i16(EXT("MaterialExtension")).utf(cmd).raw(amf3Encode(params)).body());
  send(clientPayload(0, Up.Login, -1).utf("aola").utf("小奥拉").utf("").body());
  assert.ok(await wait("logOK"));
  xt("getUserWearingClothes", { un: "小奥拉" });
  const r = (await wait("getUserWearingClothes"))!;
  assert.equal(r.un, "小奥拉");
  assert.equal(r.cl, DEFAULT_AVATAR);
  xt("getUserWearingClothes", { un: "没有这个人" });
  const r2 = (await wait("getUserWearingClothes"))!;
  assert.equal(r2.un, "没有这个人");
  assert.equal(r2.cl, DEFAULT_AVATAR);
});
