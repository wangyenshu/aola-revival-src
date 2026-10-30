// End-to-end proof of the offline browser pipeline, in real Chromium:
//
//   Ruffle (wasm) loads http://aola.100bt.com/play/WebSocketMain.swf
//     -> the service worker answers it from mirror/ (real network to that host is blocked)
//   the AS3 code opens a raw flash.net.Socket to game.aola.test:8001
//     -> Ruffle's socketProxy maps it to ws://in-page.aola/8001
//     -> the in-page shim hands the bytes to the emulator running in the page
//   the emulator answers (WebSocket handshake demo), the SWF reports the reply.
//
// Run:  npm run build && npx playwright install chromium && npm run e2e

import assert from "node:assert/strict";
import { copyFileSync, mkdirSync, mkdtempSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";
import { createMirrorServer } from "../../src/node/http.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const web = path.resolve(here, "../../../dist");
const mirror = path.join(mkdtempSync(path.join(os.tmpdir(), "aola-e2e-")), "mirror");
mkdirSync(path.join(mirror, "aola.100bt.com/play"), { recursive: true });
copyFileSync(path.join(here, "fixtures/WebSocketMain.swf"), path.join(mirror, "aola.100bt.com/play/WebSocketMain.swf"));

const httpLog = [];
const server = createMirrorServer({ mirrorDir: mirror, webDir: web, log: (l) => httpLog.push(l) });
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const port = server.address().port;

const browser = await chromium.launch();
const context = await browser.newContext({ locale: "zh-CN" });
let leaked = 0;
await context.route(/aola\.100bt\.com/, (route) => {
  leaked++;
  return route.abort();
});
const page = await context.newPage();
const consoleLines = [];
page.on("console", (m) => consoleLines.push(m.text()));
page.on("pageerror", (e) => consoleLines.push("PAGEERROR " + e.message));

await page.addInitScript(() => {
  window.__events = [];
  window.AOLA_CONFIG_OVERRIDE = {
    bootUrl: "http://aola.100bt.com/play/WebSocketMain.swf",
    mirror: "mirror/",
    index: "",
    sockets: [{ host: "game.aola.test", port: 8001 }],
    mode: "inpage",
    demo: true,
    protocol: "raw",
    verbose: false,
    date: "2012-08-15",
    beforeRuffle() {
      // web-socket-js reports back through ExternalInterface.call("WebSocket.__…").
      const W = window.WebSocket;
      W.__onFlashInitialized = () => (window.__flashReady = true);
      W.__onFlashEvent = () => {
        setTimeout(() => window.__events.push(...window.aolaPlayer.receiveEvents()), 0);
        return true;
      };
      W.__log = (m) => console.log("[swf] " + decodeURIComponent(m));
      W.__error = (m) => console.log("[swf-error] " + decodeURIComponent(m));
    },
  };
});

try {
  await page.goto(`http://127.0.0.1:${port}/index.html`);
  await page.waitForFunction(() => window.__flashReady === true, null, { timeout: 60_000 });
  await page.evaluate(() => {
    const p = window.aolaPlayer;
    p.setCallerUrl(location.href);
    p.setDebug(true);
    p.create(1, "ws://game.aola.test:8001/", [], null, 0, null);
  });
  await page.waitForFunction(() => window.__events.some((e) => e.type === "message"), null, { timeout: 30_000 });
  await page.evaluate(() => window.aolaPlayer.send(1, encodeURIComponent("ping from AS3")));
  await page.waitForFunction(() => window.__events.filter((e) => e.type === "message").length >= 2, null, { timeout: 30_000 });

  const events = await page.evaluate(() => window.__events);
  const frames = await page.evaluate(() => window.aola.frames.map((f) => `${f.dir} ${f.len} ${f.note ?? ""}`));
  const messages = events.filter((e) => e.type === "message").map((e) => decodeURIComponent(e.message));
  console.log("events:", events.map((e) => e.type).join(", "));
  console.log("messages:", messages);
  console.log("emulator frames:", frames);
  assert.ok(events.some((e) => e.type === "open"), "socket opened");
  assert.match(messages[0], /hello from the 2012 emulator; clock=2012-08-15/);
  assert.equal(messages[1], "echo: ping from AS3");
  assert.equal(leaked, 0, "no request for aola.100bt.com reached the network");
  console.log("E2E OK: mirror via service worker -> Ruffle AS3 socket -> in-page emulator -> reply");
} catch (e) {
  console.log("--- browser console ---\n" + consoleLines.slice(-60).join("\n"));
  console.log("--- http ---\n" + httpLog.join("\n"));
  throw e;
} finally {
  await browser.close();
  server.close();
}
