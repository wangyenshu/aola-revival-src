// Boot the real winter 2012/13 client in Chromium + Ruffle and record what
// happens: every original-host request (hit or miss), console output, socket
// frames, and screenshots over time.
//
//   node server/test/e2e/boot2013.mjs --out work/run1 [--seconds 60] [--query "dev=1"]
//        [--dist dist] [--mirror build/rebuilt,game] [--url https://…/] [--https]
//
// By default it serves dist/ (npm run build) as a static host would. --mirror
// serves the front end of dist/ with game files straight from these roots
// (no rebuild of dist/ needed after changing a module); --url opens a site
// served elsewhere (scripts/serve.mjs, GitHub Pages).

import { mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { chromium } from "playwright";
import { createMirrorServer } from "../../src/node/http.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../..");
const { values: a } = parseArgs({
  options: {
    mirror: { type: "string" },
    dist: { type: "string", default: path.join(repo, "dist") },
    url: { type: "string" },
    out: { type: "string", default: "run" },
    seconds: { type: "string", default: "60" },
    query: { type: "string", default: "" },
    shots: { type: "string", default: "5,15,30,60" },
    script: { type: "string", default: "" },
    // "12:510,518;20:type=hello;25:key=Enter;30:js=revival('map')" -> at 12s click page (510,518), at 20s type text, ...
    actions: { type: "string", default: "" },
    // A module whose default export runs after the timed actions:
    // export default async (h) => { await h.until(() => h.revival("scene"), "maintown1"); ... }
    scenario: { type: "string", default: "" },
  },
});
const out = path.resolve(a.out);
mkdirSync(out, { recursive: true });

const httpLog = [];
const misses = [];
const roots = a.mirror ? a.mirror.split(",").map((m) => path.resolve(m)) : [];
let pageUrl = a.url;
let server;
if (!pageUrl) {
  server = createMirrorServer({
    mirrorDir: roots,
    webDir: path.resolve(a.dist),
    log: (l) => httpLog.push(l),
    onMiss: (r) => misses.push(r.url),
  });
  await new Promise((r) => server.listen(0, "127.0.0.1", r));
  pageUrl = `http://127.0.0.1:${server.address().port}/index.html`;
}

const browser = await chromium.launch({ args: ["--enable-unsafe-swiftshader", "--ignore-certificate-errors"] });
const context = await browser.newContext({ locale: "zh-CN", viewport: { width: 1000, height: 640 }, ignoreHTTPSErrors: true });
const leaked = [];
const pageHost = new URL(pageUrl).host;
// Nothing may reach the network: requests for the original hosts must be
// answered by the service worker (Playwright's routes do not see those).
await context.route((u) => u.host !== pageHost, (route) => {
  leaked.push(route.request().url());
  return route.abort();
});
const page = await context.newPage();
const consoleLines = [];
page.on("console", (m) => consoleLines.push(`[${m.type()}] ${m.text()}`));
page.on("pageerror", (e) => consoleLines.push("[pageerror] " + e.message));
if (a.script) await page.addInitScript({ path: path.resolve(a.script) });
if (roots.length) {
  // Game files from the roots (by folder name), not from dist/files/.
  const mirror = roots.map((r) => path.basename(r) + "/").join(",");
  await page.addInitScript((m) => (window.AOLA_CONFIG_OVERRIDE = Object.assign(window.AOLA_CONFIG_OVERRIDE || {}, { mirror: m, index: "" })), mirror);
}

const t0 = Date.now();
await page.goto(pageUrl + (a.query ? (pageUrl.includes("?") ? "&" : "?") + a.query : ""));
const events = [
  ...a.shots.split(",").filter(Boolean).map((s) => ({ t: Number(s), kind: "shot" })),
  ...a.actions.split(";").filter(Boolean).map((x) => {
    const [t, act] = x.split(/:(.*)/s);
    return { t: Number(t), kind: "act", act };
  }),
].filter((e) => e.t <= Number(a.seconds)).sort((x, y) => x.t - y.t || (x.kind === "act" ? -1 : 1));
for (const e of events) {
  const wait = e.t * 1000 - (Date.now() - t0);
  if (wait > 0) await page.waitForTimeout(wait);
  if (e.kind === "shot") {
    await page.screenshot({ path: path.join(out, `t${String(e.t).padStart(3, "0")}.png`) });
  } else if (e.act.startsWith("type=")) {
    await page.keyboard.type(e.act.slice(5), { delay: 60 });
  } else if (e.act.startsWith("key=")) {
    await page.keyboard.press(e.act.slice(4));
  } else if (e.act.startsWith("js=")) {
    // e.g. js=revival('goto','maintown1'): calls the rebuilt control's test hook
    const r = await page.evaluate((code) => {
      const g = document.getElementById("myFlash") || document.getElementById("game") || document.querySelector("ruffle-player,ruffle-object");
      const revival = (...args) => g.revival(...args);
      try { return String(eval(code)); } catch (err) { return "error: " + err.message; }
    }, e.act.slice(3)).catch((err) => "error: " + err.message);
    consoleLines.push(`[js] ${e.act.slice(3)} -> ${r}`);
  } else {
    const [x, y] = e.act.split(",").map(Number);
    await page.mouse.click(x, y);
  }
  consoleLines.push(`[action ${e.t}s] ${e.kind === "shot" ? "screenshot" : e.act}`);
}
if (a.scenario) {
  const callHook = (...args) =>
    page
      .evaluate((args) => {
        const g = document.getElementById("myFlash") || document.getElementById("game") || document.querySelector("ruffle-player,ruffle-object");
        try { return String(g.revival(...args)); } catch (err) { return "error: " + err.message; }
      }, args)
      .catch((err) => "error: " + err.message);
  let shotNo = 0;
  const h = {
    page,
    lines: consoleLines,
    /** How many console lines so far match re. */
    count: (re) => consoleLines.filter((l) => re.test(l)).length,
    t: () => Math.round((Date.now() - t0) / 1000),
    log: (m) => consoleLines.push(`[scenario ${Math.round((Date.now() - t0) / 1000)}s] ${m}`),
    sleep: (ms) => page.waitForTimeout(ms),
    click: (x, y) => page.mouse.click(x, y),
    revival: async (...args) => {
      const r = await callHook(...args);
      consoleLines.push(`[js] revival(${args.map((x) => JSON.stringify(x)).join(",")}) -> ${r}`);
      return r;
    },
    shot: (name) => page.screenshot({ path: path.join(out, `s${String(++shotNo).padStart(2, "0")}-${name}.png`) }),
    /** Poll fn() (quietly) every second until it returns something truthy (or matching `want`); false on timeout. */
    until: async (fn, want, seconds = 60) => {
      const end = Date.now() + seconds * 1000;
      while (Date.now() < end) {
        const v = await fn();
        if (want === undefined ? v && !String(v).startsWith("error") : want instanceof RegExp ? want.test(String(v)) : String(v) === String(want)) return v;
        await page.waitForTimeout(1000);
      }
      return false;
    },
    hook: callHook,
  };
  const deadline = new Promise((r) => setTimeout(() => r("scenario: out of time"), Number(a.seconds) * 1000 - (Date.now() - t0)));
  const mod = await import(path.resolve(a.scenario));
  const r = await Promise.race([mod.default(h).then(() => "scenario: done", (err) => "scenario failed: " + (err?.stack ?? err)), deadline]);
  consoleLines.push(`[${r}]`);
  console.log(r);
}
const rest = a.scenario ? 0 : Number(a.seconds) * 1000 - (Date.now() - t0);
if (rest > 0) await page.waitForTimeout(rest);

const swMisses = consoleLines.filter((l) => l.includes("not in mirror")).map((l) => l.replace(/.*not in mirror:\s*/, ""));
const frames = await page.evaluate(() => (window.aola ? window.aola.frames : []));
writeFileSync(path.join(out, "console.txt"), consoleLines.join("\n") + "\n");
writeFileSync(path.join(out, "http.txt"), httpLog.join("\n") + "\n");
writeFileSync(
  path.join(out, "summary.json"),
  JSON.stringify({ misses: [...new Set([...misses, ...swMisses])], leaked: [...new Set(leaked)], frames }, null, 1),
);
console.log(`console lines: ${consoleLines.length}, mirror misses: ${new Set([...misses, ...swMisses]).size}, leaked: ${leaked.length}, socket frames: ${frames.length}`);
await browser.close();
server?.close();
