import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import http from "node:http";
import type { AddressInfo } from "node:net";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { WebSocket } from "ws";
import { utf8 } from "../src/core/bytes.ts";
import { Emulator } from "../src/core/emulator.ts";
import { MemoryRecorder } from "../src/core/recorder.ts";
import { createMirrorServer } from "../src/node/http.ts";
import { JsonFileStore } from "../src/node/fileStore.ts";
import { attachWebSocket, listenTcp } from "../src/node/transports.ts";

function fixtureMirror(): { mirror: string; web: string } {
  const root = mkdtempSync(path.join(os.tmpdir(), "aola-"));
  const mirror = path.join(root, "mirror");
  const put = (rel: string, body: string) => {
    mkdirSync(path.dirname(path.join(mirror, rel)), { recursive: true });
    writeFileSync(path.join(mirror, rel), body);
  };
  put("aola.100bt.com/play/Main.swf", "FWS-main");
  put("aola.100bt.com/play/map.swf%3Fv=3", "map-v3");
  put("aola.100bt.com/play/%E4%BA%9A%E6%AF%94.swf", "yabi");
  put("aola.100bt.com/play/index.html", "<html>play</html>");
  const web = path.join(root, "web");
  mkdirSync(web);
  writeFileSync(path.join(web, "index.html"), "front end");
  return { mirror, web };
}

function request(port: number, opts: http.RequestOptions): Promise<{ status: number; body: string; type?: string }> {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: "127.0.0.1", port, ...opts }, (res) => {
      let body = "";
      res.setEncoding("utf8");
      res.on("data", (c) => (body += c));
      res.on("end", () => resolve({ status: res.statusCode ?? 0, body, type: res.headers["content-type"] }));
    });
    req.on("error", reject);
    req.end();
  });
}

test("HTTP server: hosts-file mode, proxy mode, front end, misses", async (t) => {
  const { mirror, web } = fixtureMirror();
  const misses: string[] = [];
  const server = createMirrorServer({
    mirrorDir: mirror,
    webDir: web,
    onMiss: (r) => misses.push(r.url),
    dynamic: new Map([["aola.100bt.com/play/login.jsp", async (req) => ({ body: `ok ${req.method}` })]]),
  });
  await new Promise<void>((r) => server.listen(0, "127.0.0.1", r));
  t.after(() => server.close());
  const port = (server.address() as AddressInfo).port;

  let r = await request(port, { path: "/play/Main.swf", headers: { host: "aola.100bt.com" } });
  assert.equal(r.body, "FWS-main");
  assert.equal(r.type, "application/x-shockwave-flash");
  r = await request(port, { path: "http://aola.100bt.com/play/map.swf?v=3", headers: { host: "aola.100bt.com" } });
  assert.equal(r.body, "map-v3");
  r = await request(port, { path: "/play/Main.swf?v=999", headers: { host: "aola.100bt.com" } });
  assert.equal(r.body, "FWS-main", "query-less fallback");
  r = await request(port, { path: "/play/%E4%BA%9A%E6%AF%94.swf", headers: { host: "aola.100bt.com" } });
  assert.equal(r.body, "yabi");
  r = await request(port, { path: "/play/", headers: { host: "aola.100bt.com" } });
  assert.equal(r.body, "<html>play</html>");
  r = await request(port, { path: "/play/login.jsp?u=1", method: "POST", headers: { host: "aola.100bt.com" } });
  assert.equal(r.body, "ok POST");
  r = await request(port, { path: "/crossdomain.xml", headers: { host: "aola.100bt.com" } });
  assert.match(r.body, /allow-access-from/);
  r = await request(port, { path: "/play/gone.swf", headers: { host: "aola.100bt.com" } });
  assert.equal(r.status, 404);
  assert.deepEqual(misses, ["http://aola.100bt.com/play/gone.swf"]);

  r = await request(port, { path: "/", headers: { host: `127.0.0.1:${port}` } });
  assert.equal(r.body, "front end");
  r = await request(port, { path: "/mirror/aola.100bt.com/play/map.swf%253Fv=3", headers: { host: "localhost" } });
  assert.equal(r.body, "map-v3", "static view used by the service worker");
  r = await request(port, { path: "/__original?url=" + encodeURIComponent("http://aola.100bt.com/play/Main.swf"), headers: { host: "localhost" } });
  assert.equal(r.body, "FWS-main");
});

test("TCP game port and WebSocket bridge reach the same emulator", async (t) => {
  const emu = new Emulator({ recorder: new MemoryRecorder() });
  emu.on("raw", (s, m) => s.sendBytes(utf8(`port ${s.port} got ${m.raw.length}B`)));
  const tcp = await listenTcp(emu, 0, "127.0.0.1");
  const tcpPort = (tcp.address() as AddressInfo).port;
  const httpServer = http.createServer();
  attachWebSocket(emu, httpServer);
  await new Promise<void>((r) => httpServer.listen(0, "127.0.0.1", r));
  t.after(() => {
    tcp.close();
    httpServer.close();
  });

  const viaTcp = await new Promise<string>((resolve) => {
    const c = net.connect(tcpPort, "127.0.0.1", () => c.write("abcd"));
    c.on("data", (d) => {
      resolve(d.toString());
      c.destroy();
    });
  });
  assert.equal(viaTcp, `port ${tcpPort} got 4B`);

  const wsPort = (httpServer.address() as AddressInfo).port;
  const viaWs = await new Promise<string>((resolve, reject) => {
    const ws = new WebSocket(`ws://127.0.0.1:${wsPort}/__socket/8001`);
    ws.on("open", () => ws.send(Buffer.from([1, 2, 3])));
    ws.on("message", (d) => {
      resolve(d.toString());
      ws.close();
    });
    ws.on("error", reject);
  });
  assert.equal(viaWs, "port 8001 got 3B");

  const viaPolicy = await new Promise<string>((resolve) => {
    let buf = "";
    const c = net.connect(tcpPort, "127.0.0.1", () => c.write("<policy-file-request/>\0"));
    c.on("data", (d) => (buf += d.toString()));
    c.on("close", () => resolve(buf));
  });
  assert.match(viaPolicy, /cross-domain-policy/);
});

test("JSON file store round-trips nested keys", async () => {
  const store = new JsonFileStore(mkdtempSync(path.join(os.tmpdir(), "aola-store-")));
  await store.set("user/10001", { nick: "小奥拉", pets: [12] });
  await store.set("user/10002", { nick: "b" });
  assert.deepEqual(await store.get("user/10001"), { nick: "小奥拉", pets: [12] });
  assert.deepEqual(await store.keys("user/"), ["user/10001", "user/10002"]);
  await store.delete("user/10002");
  assert.equal(await store.get("user/10002"), undefined);
});
