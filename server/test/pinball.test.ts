// 欢乐弹珠机 (89_1): a prize needs 欢乐弹珠 played; the top slot pays once a day.
import assert from "node:assert/strict";
import { test } from "node:test";
import { amf3Encode } from "../src/core/amf3.ts";
import { concat } from "../src/core/bytes.ts";
import { FrameSplitter } from "../src/core/framing.ts";
import { MemoryStore } from "../src/core/store.ts";
import { createGameHost } from "../src/game/sfs2013/host.ts";
import { EXT_NAMES, Reader, Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";
import { SFS2013_FRAMING } from "../src/game/sfs2013/server.ts";

const tick = (ms = 15) => new Promise((r) => setTimeout(r, ms));
const EXT = (name: string) => Number(Object.entries(EXT_NAMES).find(([, n]) => n === name)![0]);

test("89_1: nothing without balls; the top prize once a day, the second slot's then", async () => {
  const host = createGameHost({ store: new MemoryStore(), loadJson: async () => undefined, dev: true });
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
  const xt = (ext: string, cmd: string, params: Record<string, unknown>) =>
    send(clientPayload(1, Up.XtReq, 1).i16(EXT(ext)).utf(cmd).raw(amf3Encode(params)).body());
  send(clientPayload(0, Up.Login, -1).utf("aola").utf("小奥拉").utf("").body());
  assert.ok(await wait("logOK"));
  xt("UserGameExtension", "89_1", { num: 0, lvl: 1 });
  assert.equal((await wait("89_1"))!.gf, "", "no balls played: nothing");
  xt("PocketMonsterExtension", "revival_give", { mi: 343, qt: 5 });
  await tick(50);
  xt("UserGameExtension", "89_1", { num: 1, lvl: 1 });
  const top = String((await wait("89_1"))!.gf);
  assert.match(top, /^(5:88|2:178|2:661):1$/, "the top slot's prize");
  xt("UserGameExtension", "89_1", { num: 1, lvl: 1 });
  const again = String((await wait("89_1"))!.gf);
  assert.match(again, /^(5:13|5:37|2:120|2:61):/, "the same day: the second slot's");
});
