import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { concat, utf8, fromUtf8 } from "../src/core/bytes.ts";
import { GameClock, parseAnchor } from "../src/core/clock.ts";
import { Emulator } from "../src/core/emulator.ts";
import { FRAMING_PRESETS, FrameSplitter, FramingError } from "../src/core/framing.ts";
import { urlToRelpath, normalizeUrl } from "../src/core/mirrorPath.ts";
import { MemoryRecorder } from "../src/core/recorder.ts";

test("mirror paths match the Python tools (shared fixtures)", () => {
  const fixtures = JSON.parse(readFileSync(new URL("../../tests/mirrorpath-fixtures.json", import.meta.url), "utf8"));
  for (const [url, rel] of Object.entries(fixtures)) assert.equal(urlToRelpath(url), rel, url);
  assert.equal(normalizeUrl("https://AOLA.100bt.com/play/x.swf?v=1"), "http://aola.100bt.com/play/x.swf?v=1");
});

test("frame splitter reassembles split and coalesced frames", () => {
  const f = (cmd: number, body: string) => {
    const b = utf8(body);
    const out = new Uint8Array(8 + b.length);
    const v = new DataView(out.buffer);
    v.setUint32(0, out.length);
    v.setUint32(4, cmd);
    out.set(b, 8);
    return out;
  };
  const stream = concat(f(1001, "hello"), f(1002, ""), f(1003, "奥拉星"));
  const sp = new FrameSplitter(FRAMING_PRESETS["u32be-total"]);
  const frames: Uint8Array[] = [];
  for (let i = 0; i < stream.length; i += 3) frames.push(...sp.push(stream.subarray(i, i + 3)));
  assert.equal(frames.length, 3);
  assert.equal(new DataView(frames[2].buffer).getUint32(4), 1003);
  assert.equal(fromUtf8(frames[2].subarray(8)), "奥拉星");
  assert.equal(sp.pending, 0);
});

test("body-length framing and garbage detection", () => {
  const sp = new FrameSplitter(FRAMING_PRESETS["u16be-body"]);
  assert.deepEqual(sp.push(new Uint8Array([0, 2, 9, 9, 0, 0])).map((x) => x.length), [4, 2]);
  const bad = new FrameSplitter(FRAMING_PRESETS["u32be-total"]);
  assert.throws(() => bad.push(utf8("GET / HTTP/1.1\r\n")), FramingError);
});

test("game clock starts at the 2012 anchor in China time and keeps running", () => {
  let now = 1_800_000_000_000;
  const clock = new GameClock("2012-08-15T10:00", () => now);
  assert.equal(clock.now().toISOString(), "2012-08-15T02:00:00.000Z");
  now += 90_000;
  assert.equal(clock.now().toISOString(), "2012-08-15T02:01:30.000Z");
  assert.equal(parseAnchor("2012-07-16").toISOString(), "2012-07-16T02:00:00.000Z");
});

test("emulator answers the Flash policy request and dispatches by port and cmd", async () => {
  const rec = new MemoryRecorder();
  const emu = new Emulator({ recorder: rec });
  const sent: string[] = [];
  let closed = false;
  const s1 = emu.attach({ remote: "t", send: (b) => sent.push(fromUtf8(b)), close: () => (closed = true) }, 8001);
  s1.receive(utf8("<policy-file-request/>\0"));
  assert.match(sent[0], /allow-access-from domain="\*"/);
  assert.ok(sent[0].endsWith("\0"));
  assert.ok(closed);

  const got: string[] = [];
  emu.on("raw", (s, m) => void got.push(`any:${s.port}:${fromUtf8(m.raw)}`));
  emu.on("raw", (s, m) => void got.push(`login:${fromUtf8(m.raw)}`), 7000);
  const s2 = emu.attach({ remote: "t", send: () => {}, close: () => {} }, 8001);
  const s3 = emu.attach({ remote: "t", send: () => {}, close: () => {} }, 7000);
  s2.receive(utf8("a"));
  s3.receive(utf8("b"));
  await new Promise((r) => setTimeout(r, 10));
  assert.deepEqual(got.sort(), ["any:8001:a", "login:b"]);
  assert.ok(rec.records.some((r) => r.dir === "in" && r.text === "a"));
});

test("md5 matches known vectors", async () => {
  const { md5 } = await import("../src/game/md5.ts");
  const { toHex } = await import("../src/core/bytes.ts");
  assert.equal(toHex(md5(utf8(""))), "d41d8cd98f00b204e9800998ecf8427e");
  assert.equal(toHex(md5(utf8("The quick brown fox jumps over the lazy dog"))), "9e107d9d372bb6826bd81d3542a419d6");
  assert.equal(toHex(md5(utf8("a".repeat(1000)))), "cabe45dcc9ae5b66ba86600cca6b8ba8");
});
