// Walk through scenes of the revived 2013 client: boot, log in, then for each
// room ask the rebuilt control's test hook to go there, wait, screenshot, and
// record whether the scene opened and what errors the console showed.
//
//   node server/test/e2e/scenewalk.mjs --rooms rooms.txt --out work/walk \
//     [--dist dist] [--mirror build/rebuilt,game] [--wait 20] [--click "x,y;..."]
//
// rooms.txt: one room name per line (config.xml roomMap nm). Writes
// walk/report.json and walk/<room>.png.

import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { chromium } from "playwright";
import { createMirrorServer } from "../../src/node/http.ts";

const here = path.dirname(fileURLToPath(import.meta.url));
const { values: a } = parseArgs({
  options: {
    mirror: { type: "string" },
    dist: { type: "string", default: path.resolve(here, "../../../dist") },
    rooms: { type: "string" },
    out: { type: "string", default: "walk" },
    wait: { type: "string", default: "20" },
    settle: { type: "string", default: "4" },
    click: { type: "string", default: "" },
  },
});
const out = path.resolve(a.out);
mkdirSync(out, { recursive: true });
const rooms = readFileSync(a.rooms, "utf8").split(/\s+/).filter(Boolean);
const roots = a.mirror ? a.mirror.split(",").map((m) => path.resolve(m)) : [];
const misses = [];
const server = createMirrorServer({
  mirrorDir: roots,
  webDir: path.resolve(a.dist),
  log: () => {},
  onMiss: (r) => misses.push(r.url),
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const port = server.address().port;
const browser = await chromium.launch({ args: ["--enable-unsafe-swiftshader"] });
const context = await browser.newContext({ locale: "zh-CN", viewport: { width: 1000, height: 640 } });
await context.route(/^https?:\/\/(?!127\.0\.0\.1)/, (route) => route.abort());
const page = await context.newPage();
if (roots.length) {
  const mirror = roots.map((r) => path.basename(r) + "/").join(",");
  await page.addInitScript((m) => (window.AOLA_CONFIG_OVERRIDE = { mirror: m, index: "" }), mirror);
}
let lines = [];
const all = [];
page.on("console", (m) => {
  const t = m.text();
  if (/AudioContext|GL Driver|willReadFrequently|%cINFO%c web\/src\/log_adapter/.test(t)) return;
  lines.push(t);
  all.push(t);
});
page.on("pageerror", (e) => lines.push("[pageerror] " + e.message));

const hook = (cmd, arg) =>
  page
    .evaluate(
      ([c, x]) => {
        const g = document.getElementById("myFlash") || document.querySelector("ruffle-player,ruffle-object");
        try { return String(g.revival(c, x)); } catch (e) { return "error: " + e.message; }
      },
      [cmd, arg],
    )
    .catch((e) => "error: " + e.message);

await page.goto(`http://127.0.0.1:${port}/index.html?bare=1`);
await page.waitForTimeout(38000);
await page.mouse.click(500, 520);
await page.waitForTimeout(8000);
await page.mouse.click(500, 520);
for (let i = 0; i < 60; i++) {
  await page.waitForTimeout(2000);
  if ((await hook("scene")) === "starland") break;
}
await page.waitForTimeout(3000);
console.log("booted:", await hook("scene"));

const report = [];
for (const room of rooms) {
  lines = [];
  const t0 = Date.now();
  const r0 = await hook("goto", room);
  let scene = "";
  for (let i = 0; i < Number(a.wait) * 2; i++) {
    await page.waitForTimeout(500);
    scene = await hook("scene");
    if (scene === room && (await hook("busy")) === "0") break;
  }
  await page.waitForTimeout(Number(a.settle) * 1000);
  for (const c of a.click.split(";").filter(Boolean)) {
    const [x, y] = c.split(",").map(Number);
    await page.mouse.click(x, y);
    await page.waitForTimeout(1500);
  }
  scene = await hook("scene");
  const shot = path.join(out, `${room}.png`);
  await page.screenshot({ path: shot, clip: { x: 20, y: 16, width: 960, height: 560 } });
  const errors = lines.filter((l) => /ERROR|Error #|\[pageerror\]|not in mirror|failed|stub called/.test(l)).map((l) => l.replace(/%c|color:[^;]*;?|background:[^;]*;?|font-style:[^;]*;?/g, "").trim());
  const ok = scene === room;
  const layers = await hook("layers", "8");
  const i4 = layers.indexOf("BaseLayer_c4"), i5 = layers.indexOf("BaseLayer_c5");
  const modal = i4 >= 0 && layers.slice(i4, i5 > i4 ? i5 : undefined).includes("ModalDialogContainer") ? layers.slice(i4, i5 > i4 ? i5 : undefined).trim() : "";
  report.push({ room, ok, scene, secs: Math.round((Date.now() - t0) / 1000), hook: r0, modal, errors: [...new Set(errors)].slice(0, 30) });
  console.log(`${ok ? "OK  " : "FAIL"} ${room} -> ${scene} (${errors.length} errors)${modal ? " MODAL" : ""}`);
  writeFileSync(path.join(out, "report.json"), JSON.stringify(report, null, 1));
  if (!ok) {
    // get back to a known place before the next room
    await hook("goto", "starland");
    await page.waitForTimeout(6000);
  }
}
writeFileSync(path.join(out, "console.txt"), all.join("\n") + "\n");
writeFileSync(path.join(out, "misses.txt"), [...new Set(misses)].join("\n") + "\n");
console.log(`done: ${report.filter((r) => r.ok).length}/${report.length} opened`);
await browser.close();
server.close();
