// The shared server against a hostile client (update100): frames that decode to huge values,
// floods, and what a client may claim.
import assert from "node:assert/strict";
import { test } from "node:test";
import { amf3Decode, amf3Encode, AMF3_MAX_DEPTH } from "../src/core/amf3.ts";
import { brief, plainCopy } from "../src/core/plain.ts";

/** U29 of AMF3. */
const u29 = (n: number): number[] => {
  if (n < 0x80) return [n];
  if (n < 0x4000) return [(n >> 7) | 0x80, n & 0x7f];
  if (n < 0x200000) return [(n >> 14) | 0x80, ((n >> 7) & 0x7f) | 0x80, n & 0x7f];
  return [(n >> 22) | 0x80, ((n >> 15) & 0x7f) | 0x80, ((n >> 8) & 0x7f) | 0x80, n & 0xff];
};

test("AMF3: arrays that all point at each other are refused at once, not decoded into an exponential value", () => {
  // Array k holds two references to array k-1 (object index k-1): 2^levels leaves from a few hundred bytes.
  const levels = 25;
  const bytes: number[] = [0x09, ...u29((2 << 1) | 1), 0x01, 0x04, 0x01, 0x04, 0x02]; // [1, 2]
  const nest = (k: number): number[] => (k === 0 ? bytes : [0x09, ...u29((2 << 1) | 1), 0x01, 0x09, ...u29((k - 1) << 1), 0x09, ...u29((k - 1) << 1)]);
  // Built inside out: the outermost array first in the stream, its children after.
  const stream: number[] = [];
  for (let k = levels; k > 0; k--) stream.push(0x09, ...u29((2 << 1) | 1), 0x01);
  stream.push(...bytes);
  // The second child of each level names the first (the level below, object levels-k+1), now finished.
  for (let k = 1; k <= levels; k++) stream.push(0x09, ...u29((levels - k + 1) << 1));
  void nest;
  assert.ok(stream.length < 300, `${stream.length} bytes`);
  const t0 = Date.now();
  assert.throws(() => amf3Decode(Uint8Array.from(stream)), /too large/);
  assert.ok(Date.now() - t0 < 1000, "refused quickly");
});

test("AMF3: a long string named over and over is refused; a cycle and too deep a nesting too", () => {
  const long = "x".repeat(50_000);
  const enc = new TextEncoder().encode(long);
  const s: number[] = [0x09, ...u29((200 << 1) | 1), 0x01, 0x06, ...u29((enc.length << 1) | 1), ...enc];
  for (let i = 1; i < 200; i++) s.push(0x06, ...u29(0 << 1)); // the same string by reference
  assert.throws(() => amf3Decode(Uint8Array.from(s)), /too large/);
  // [ <itself> ]: the array names itself while it is being read.
  assert.throws(() => amf3Decode(Uint8Array.from([0x09, ...u29((1 << 1) | 1), 0x01, 0x09, 0x00])), /cyclic/);
  const deep: number[] = [];
  for (let i = 0; i <= AMF3_MAX_DEPTH; i++) deep.push(0x09, ...u29((1 << 1) | 1), 0x01);
  deep.push(0x01);
  assert.throws(() => amf3Decode(Uint8Array.from(deep)), /too deep/);
  // What the game sends is unchanged.
  const ok = { a: [1, "x", { b: true }], c: "奥拉" };
  assert.deepEqual(amf3Decode(amf3Encode(ok)).value, ok);
});

test("plainCopy and brief never walk more than they were asked for", () => {
  const big: unknown[] = [];
  let cur = big;
  for (let i = 0; i < 20; i++) {
    const next: unknown[] = [];
    cur.push(next, next);
    cur = next;
  }
  const t0 = Date.now();
  assert.equal(plainCopy(big, 2000, 8), undefined);
  assert.ok(brief(big, 300).length <= 301);
  assert.ok(Date.now() - t0 < 200);
  const cyc: Record<string, unknown> = { a: 1 };
  cyc.self = cyc;
  assert.equal(plainCopy(cyc), undefined);
  assert.deepEqual(plainCopy({ x: [1, 2], y: "z" }), { x: [1, 2], y: "z" });
});

test("the shared server answers `GET //` with 400 and keeps running", async () => {
  const { spawn } = await import("node:child_process");
  const net = await import("node:net");
  const { mkdtemp } = await import("node:fs/promises");
  const os = await import("node:os");
  const pathm = await import("node:path");
  const data = await mkdtemp(pathm.join(os.tmpdir(), "aola-multi-"));
  const port = 20000 + Math.floor(Math.random() * 20000);
  const proc = spawn(process.execPath, [new URL("../src/node/multi.ts", import.meta.url).pathname, "--port", String(port), "--bind", "127.0.0.1", "--data", data, "--web", ""], { stdio: ["ignore", "pipe", "pipe"] });
  try {
    await new Promise<void>((ok, fail) => {
      const t = setTimeout(() => fail(new Error("did not start")), 20000);
      proc.stdout!.on("data", (d) => /listening|http:\/\//i.test(String(d)) && (clearTimeout(t), ok()));
      proc.on("exit", (c) => fail(new Error(`exited ${c}`)));
    });
    const ask = (line: string) =>
      new Promise<string>((ok, fail) => {
        const sock = net.connect(port, "127.0.0.1", () => sock.write(`${line}\r\nHost: x\r\nConnection: close\r\n\r\n`));
        let out = "";
        sock.on("data", (d) => (out += d));
        sock.on("end", () => ok(out));
        sock.on("error", fail);
      });
    assert.match(await ask("GET // HTTP/1.1"), /^HTTP\/1\.1 400/);
    await new Promise((r) => setTimeout(r, 300));
    assert.equal(proc.exitCode, null, "still running");
    assert.match(await ask("GET /__api/none HTTP/1.1"), /^HTTP\/1\.1 \d{3}/);
  } finally {
    proc.kill();
  }
});
