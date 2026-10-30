import assert from "node:assert/strict";
import { test } from "node:test";
import { Amf3TypedObject, amf3Decode, amf3Encode } from "../src/core/amf3.ts";
import { concat, toHex } from "../src/core/bytes.ts";
import { Emulator } from "../src/core/emulator.ts";
import { FrameSplitter } from "../src/core/framing.ts";
import { MemoryRecorder } from "../src/core/recorder.ts";
import { Down, Reader, Up, clientPayload, encodeClientFrame, nextPacketNum } from "../src/game/sfs2013/protocol.ts";
import { SFS2013_FRAMING, World, sfs2013Codec } from "../src/game/sfs2013/server.ts";

test("AMF3 round-trips the shapes the 2013 client sends", () => {
  const v = { id: 3, cmd: "70_12", param: { type: 278, list: [1, 2.5, "三", null, true], when: new Date(1359612776000) }, big: 2 ** 30, neg: -5 };
  const back = amf3Decode(amf3Encode(v)).value as typeof v;
  assert.deepEqual(back, v);
  // Known bytes: writeObject({a:1}) in Flash = 0a 0b 01 03 61 04 01 01
  assert.equal(toHex(amf3Encode({ a: 1 })), "0a0b0103610401" + "01");
  // String and object references
  const shared = { k: "x" };
  const r = amf3Decode(amf3Encode([shared, shared, "dup", "dup"])).value as unknown[];
  assert.equal(r[0], r[1]);
  // Typed object with sealed members
  const t = amf3Decode(amf3Encode(new Amf3TypedObject("mmo.Foo", { a: 1, b: "s" }))).value as Amf3TypedObject;
  assert.equal(t.className, "mmo.Foo");
  assert.deepEqual(t.values, { a: 1, b: "s" });
  // Associative array part
  const arr = Object.assign([1, 2], { name: "n" });
  const ab = amf3Decode(amf3Encode(arr)).value as unknown[] & { name: string };
  assert.deepEqual([...ab], [1, 2]);
  assert.equal(ab.name, "n");
});

test("packet numbers follow n*3+1 wrapping at 127", () => {
  const seq = [-1];
  for (let i = 0; i < 8; i++) seq.push(nextPacketNum(seq.at(-1)!));
  assert.deepEqual(seq.slice(1), [0, 1, 4, 13, 40, 121, 0, 1]);
});

type Sent = { handler: number; action?: number; roomId?: number; r: Reader; obj?: Record<string, unknown> };

function harness() {
  const rec = new MemoryRecorder();
  const emu = new Emulator({ framing: SFS2013_FRAMING, codec: sfs2013Codec, recorder: rec, answerPolicy: false });
  const world = new World(emu);
  const connect = () => {
    const out: Uint8Array[] = [];
    const s = emu.attach({ remote: "t", send: (b) => out.push(b), close: () => {} }, 9339);
    let pn = -1;
    const send = (payload: Uint8Array) => {
      pn = nextPacketNum(pn);
      s.receive(encodeClientFrame(pn, payload));
    };
    const received = (): Sent[] => {
      const all = concat(...out.splice(0));
      // skip the policy file the server sends first
      let start = 0;
      if (all[0] === 0x3c) start = all.indexOf(0) + 1;
      const sp = new FrameSplitter(SFS2013_FRAMING);
      return sp.push(all.subarray(start)).map((f) => {
        const r = new Reader(f);
        r.i32();
        const handler = r.u8();
        if (handler === 1) return { handler, r, obj: r.amf3() as Record<string, unknown> };
        if (handler === 0) return { handler, action: r.i16(), roomId: r.i32(), r };
        return { handler, r };
      });
    };
    return { s, send, received, out };
  };
  return { emu, world, connect };
}

const tick = () => new Promise((r) => setTimeout(r, 5));

test("login, join, move, chat and an extension call, as the 2013 client sends them", async () => {
  const { world, connect } = harness();
  world.xt("SundriesExtension.70_12", (ctx) => ctx.reply({ ok: 1, type: ctx.params.type }));

  const a = connect();
  assert.equal(a.out[0][0], 0x3c, "policy XML first");
  a.send(clientPayload(0, Up.Login, -1).utf("aola").utf("小奥拉").utf("").body());
  await tick();
  let got = a.received();
  assert.equal(got.length, 1);
  assert.equal(got[0].obj?._cmd, "logOK");
  assert.equal(got[0].obj?.n, "小奥拉");
  const idA = got[0].obj?.id as number;

  a.send(clientPayload(0, Up.JoinRoom, -1).utf("starland").u8(49).i32(-1).u8(48).utf("").body());
  await tick();
  got = a.received();
  assert.equal(got[0].action, Down.joinOK);
  const r = got[0].r;
  const roomId = r.i32();
  assert.equal(r.utf(), "starland");
  r.i32();
  r.utf();
  assert.equal(r.i16(), 0, "no room vars");
  assert.equal(r.i16(), 1, "one user");
  assert.equal(r.i32(), idA);

  const b = connect();
  b.send(clientPayload(0, Up.Login, -1).utf("aola").utf("b").utf("").body());
  b.send(clientPayload(0, Up.JoinRoom, -1).utf("starland").u8(49).i32(-1).u8(48).utf("").body());
  await tick();
  got = a.received();
  assert.equal(got[0].action, Down.uER, "A sees B enter");

  // B moves: SetUvars pt = "x,y,type,speed,room,name"
  b.send(clientPayload(0, Up.SetUvars, roomId).i16(1).utf("pt").u8(115).utf("400,380,1,0,starland,b").body());
  b.send(clientPayload(0, Up.PubMsg, roomId).utf("你好").body());
  await tick();
  got = a.received();
  assert.equal(got[0].action, Down.uVarsUpdate);
  got[0].r.i32();
  got[0].r.i16();
  assert.equal(got[0].r.utf(), "pt");
  assert.equal(got[1].action, Down.pubMsg);
  got[1].r.i32();
  assert.equal(got[1].r.utf(), "你好");

  // Extension request: i16 extId (34 = SundriesExtension), utf cmd, AMF3 params
  a.send(clientPayload(1, Up.XtReq, roomId).i16(34).utf("70_12").raw(amf3Encode({ type: 278 })).body());
  await tick();
  got = a.received();
  assert.deepEqual(got.find((g) => g.handler === 1)?.obj, { _cmd: "70_12", ok: 1, type: 278 });

  b.s.close();
  await tick();
  got = a.received();
  assert.equal(got.at(-1)?.action, Down.userGone);
});

test("one player's extension requests run one after another", async () => {
  const { world, connect } = harness();
  // Each request loads the record, waits (as a store does), changes it and saves it.
  let saved: string[] = [];
  const slow = (ms: number) => new Promise((r) => setTimeout(r, ms));
  world.xt("SundriesExtension.*", async (ctx, cmd) => {
    const rec = [...saved];
    await slow(cmd === "first" ? 30 : 1);
    rec.push(cmd);
    saved = rec;
    ctx.reply({ ok: 1 });
  });
  const a = connect();
  a.send(clientPayload(0, Up.Login, -1).utf("aola").utf("小奥拉").utf("").body());
  await tick();
  a.send(clientPayload(0, Up.JoinRoom, -1).utf("starland").u8(49).i32(-1).u8(48).utf("").body());
  await tick();
  a.received();
  a.send(clientPayload(1, Up.XtReq, 1).i16(34).utf("first").raw(amf3Encode({})).body());
  a.send(clientPayload(1, Up.XtReq, 1).i16(34).utf("second").raw(amf3Encode({})).body());
  await slow(80);
  assert.deepEqual(saved, ["first", "second"]);
});
