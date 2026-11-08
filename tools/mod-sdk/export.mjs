#!/usr/bin/env node
// A mod exported as a game of its own: a folder (and a .zip of it) with the page, Ruffle, the
// server emulator, the mod, and only the game files the mod uses, which any static web server
// can serve (docs/MODDING.md, "Exporting a mod").
//
//   npm run export:mod -- <mod folder | mod.swf> [--out build/export] [--seconds 900] [--no-record] [--no-zip] [--exe]
//   (node tools/mod-sdk/export.mjs … is the same)
//
// What it needs is made first when it is missing or older than its sources: the game's rebuilt
// modules (npm run build:swf), the site (npm run build), the mod. The test browser (Playwright's
// Chromium) is asked for once: npx playwright install chromium.
//
// The mod folder is one tools/mod-sdk/build.mjs builds (asconfig.json); or a mod's .swf already
// built, with its about.json beside it (<name>.json or about.json) if it has one. about.json gives
// the name and, under "export", the page's and what to keep besides what is seen played:
//   {"name": "…", "description": "…",
//    "export": {"player": "the 奥拉's name", "cover": "cover.svg",
//               "races": [216, …], "npcs": [28, …], "items": [61, …], "music": ["music/…mp3"],
//               "files": ["www.9aola.com/…"]}}
// The mod itself may say what it uses: a public uses() on its main class answering {races, npcs,
// items, music, files} (worked out from its own tables: every team of every difficulty …); both
// lists are kept.
//
// Which game files: those the game loads while the mod is walked through (export-tour.mjs, in
// the headless browser of server/test/e2e/boot2013.mjs: every room it defines, its
// conversations, a battle, the bag and its 道具 page, the 物品 panel, the HELLO's menu, the
// 亚比仓库), and by rule for each 亚比 of "races" its battle sprite, its pictures and the
// animations of the skills it knows by Lv100, for each NPC of "npcs" its picture, for each 道具
// of "items" its picture, the "music" and "files" named; and whole, what the game shows of any
// 亚比 (every 属性's icon, the game's data, the windows of what is got, the battle's backgrounds). The page and the emulator are built as npm run build builds them (made
// first when older than their sources: the tour plays the site of dist/).
import { execFileSync, spawnSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync, copyFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { build } from "esbuild";
import { staticName, withoutQuery } from "../../server/src/core/mirrorPath.ts";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const { values: a, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    out: { type: "string", default: path.join(root, "build/export") },
    seconds: { type: "string", default: "900" },
    "no-record": { type: "boolean", default: false },
    "no-zip": { type: "boolean", default: false },
    exe: { type: "boolean", default: false },
  },
});
if (positionals.length !== 1) {
  console.error("usage: npm run export:mod -- <mod folder | mod.swf> [--out dir] [--seconds n] [--no-record] [--no-zip] [--exe]");
  process.exit(2);
}
const given = path.resolve(positionals[0]);
const fromSwf = /\.swf$/i.test(given);
const modDir = fromSwf ? path.dirname(given) : given;
const readJson = (p) => (existsSync(p) ? JSON.parse(readFileSync(p, "utf8")) : null);
const about = (fromSwf ? readJson(given.replace(/\.swf$/i, ".json")) ?? readJson(path.join(modDir, "about.json")) : readJson(path.join(modDir, "about.json"))) ?? {};
const ex = about.export ?? {};
const swf = fromSwf ? given : path.resolve(modDir, readJson(path.join(modDir, "asconfig.json")).compilerOptions.output);
if (fromSwf && !existsSync(swf)) throw new Error(`no ${positionals[0]}`);
const file = path.basename(swf);
if (!/^[A-Za-z0-9_.-]+\.swf$/.test(file)) throw new Error(`the mod's file name ${file}: letters, digits, _ . - only`);
const id = file.replace(/\.swf$/, "");
const out = path.resolve(a.out, id);
const rebuilt = path.join(root, "build/rebuilt");
const game = path.join(root, "game");
const dist = path.join(root, "dist");
if (!existsSync(game)) throw new Error("missing game/ (the game files)");
const newest = (dir) => (existsSync(dir) ? readdirSync(dir, { withFileTypes: true, recursive: true }).reduce((t, e) => (e.isFile() ? Math.max(t, statSync(path.join(e.parentPath ?? e.path, e.name)).mtimeMs) : t), 0) : 0);
const npm = (script) => {
  console.log(`npm run ${script} …`);
  execFileSync(process.platform === "win32" ? "npm.cmd" : "npm", ["run", script], { cwd: root, stdio: "inherit", shell: process.platform === "win32" });
};
// The game's rebuilt modules, then the site the export is taken from: made when missing or older
// than their sources.
if (!existsSync(rebuilt)) npm("build:swf");
else if (newest(path.join(root, "rebuild/src")) > newest(rebuilt)) console.warn("warning: rebuild/src is newer than build/rebuilt: the export takes the modules as last built (npm run build:swf makes them anew)");
const distAt = existsSync(path.join(dist, "index.html")) ? statSync(path.join(dist, "index.html")).mtimeMs : 0;
if (!distAt || Math.max(newest(path.join(root, "web")), newest(path.join(root, "server/src"))) > distAt) npm("build");
// The browser the walk-through plays in.
if (!a["no-record"]) {
  let browser = "";
  try {
    browser = (await import("playwright")).chromium.executablePath();
  } catch {}
  if (!browser || !existsSync(browser)) {
    console.error("The walk-through needs Playwright's Chromium: npx playwright install chromium (once), or --no-record.");
    process.exit(1);
  }
}

// The mod, built when its sources are newer than its SWF.
if (!fromSwf && (!existsSync(swf) || newest(path.join(modDir, "src")) > statSync(swf).mtimeMs)) {
  console.log("building the mod …");
  execFileSync(process.execPath, [path.join(root, "tools/mod-sdk/build.mjs"), modDir], { stdio: "inherit" });
}

// Every game file there is (build/rebuilt above game/, as the site serves them): rel -> full path.
function* walk(dir, rel = "") {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const r = rel ? `${rel}/${e.name}` : e.name;
    if (e.isDirectory()) yield* walk(path.join(dir, e.name), r);
    else if (e.isFile()) yield [r, path.join(dir, e.name)];
  }
}
const all = new Map();
const plainHave = new Set();
for (const r of [rebuilt, game]) {
  for (const [rel, full] of walk(r)) {
    if (rel === "FILES.jsonl" || rel === "README.md") continue;
    const p = withoutQuery(rel);
    if (plainHave.has(p) || all.has(rel)) continue;
    all.set(rel, full);
    if (p === rel) plainHave.add(p);
  }
}
const keep = new Set();
const byPlain = new Map();
for (const rel of all.keys()) {
  const p = withoutQuery(rel);
  if (!byPlain.has(p)) byPlain.set(p, []);
  byPlain.get(p).push(rel);
}
/** Keep the files of that path (any version). */
const want = (plain) => {
  for (const rel of byPlain.get(plain) ?? []) keep.add(rel);
  return byPlain.has(plain);
};

// 1. What the game loads as the mod is walked through (and what the mod says it uses).
const uses = {};
/** How many of the game's files the mod's first room took in the walk-through (the loading bar's whole). */
let firstFiles = 0;
const work = mkdtempSync(path.join(os.tmpdir(), "aola-export-"));
try {
  const overlay = path.join(work, "overlay");
  mkdirSync(path.join(overlay, "www.9aola.com/revival/mods"), { recursive: true });
  copyFileSync(swf, path.join(overlay, "www.9aola.com/revival/mods", file));
  if (!a["no-record"]) {
    console.log(`walking the mod through (up to ${a.seconds} s) …`);
    const rec = path.join(work, "rec");
    const r = spawnSync(process.execPath, [
      path.join(root, "server/test/e2e/boot2013.mjs"),
      "--mirror", [overlay, rebuilt, game].join(","),
      "--dist", dist,
      "--out", rec,
      "--seconds", a.seconds,
      "--shots", "",
      "--query", `standalone=${file}&dev=1`,
      "--scenario", path.join(root, "tools/mod-sdk/export-tour.mjs"),
    ], { stdio: ["ignore", "inherit", "inherit"], env: { ...process.env, EXPORT_RACE: String(ex.races?.[0] ?? "") } });
    if (r.status !== 0) throw new Error("the walk-through failed");
    const log = readFileSync(path.join(rec, "http.txt"), "utf8").split("\n");
    let seen = 0;
    for (const line of log) {
      const m = /^200 [^/]+\/(.+)$/.exec(line.trim());
      if (!m) continue;
      const rel = m[1];
      if (all.has(rel)) {
        keep.add(rel);
        seen++;
      }
    }
    const tour = readFileSync(path.join(rec, "console.txt"), "utf8");
    if (!/export tour: done/.test(tour)) console.warn("warning: the walk-through did not finish; some files may be missing");
    console.log(`  ${seen} files loaded`);
    const first = /export tour: first room after (\d+) files/.exec(tour);
    if (first && Number(first[1]) > 0) firstFiles = Number(first[1]);
    const told = /export tour: uses (\{.*\})\s*$/m.exec(tour);
    if (told) {
      try {
        Object.assign(uses, JSON.parse(told[1]));
        console.log(`  the mod uses ${["races", "npcs", "items", "music", "files"].map((k) => `${(uses[k] ?? []).length} ${k}`).join(", ")}`);
      } catch {
        console.warn("warning: the mod's uses() did not answer JSON");
      }
    }
  }

  // 2. By rule: about.json's lists and the mod's (uses()) together.
  const pm = JSON.parse(readFileSync(path.join(root, "rebuild/static/www.9aola.com/revival/pmdata.json"), "utf8"));
  const W = "www.9aola.com/";
  const both = (k) => [...new Set([...(Array.isArray(ex[k]) ? ex[k] : []), ...(Array.isArray(uses[k]) ? uses[k] : [])])];
  for (const race of both("races").map(Number).filter((r) => r > 0)) {
    want(`${W}fightassets/pet${race}.swf`);
    want(`${W}peticon/peticon${race}.swf`);
    want(`${W}bossfightmovie/boss${race}.swf`);
    for (const [lv, skill] of pm.species[String(race)]?.learn ?? []) if (lv <= 100) want(`${W}fightassets/effect${skill}.swf`);
  }
  for (const npc of both("npcs").map(Number).filter((n) => n > 0)) want(`${W}tasknpc/npc${npc}.swf`);
  // The pictures of the 道具 it gives (the bag's 道具 page, the window of what is got).
  for (const item of both("items").map(Number).filter((n) => n > 0)) want(`${W}item/view${item}.swf`);
  for (const f of [...both("music"), ...both("files")].map(String)) if (!want(f.startsWith(W) ? f : W + f)) console.warn(`warning: ${f} is not a game file`);
  // What the game shows of any 亚比 or 道具, whole (not only what the walk-through met): every 属性's
  // icon (petattribute: the bag, the battle's skills and 属性 relation), the windows of what is got
  // (material), the battle's backgrounds and sounds, and the game's data (revival: 亚比, skills, 属性
  // table … that the rebuilt modules read).
  const GENERAL = /^www\.9aola\.com\/(petattribute|material|petfightbackground|revival)\//;
  for (const rel of all.keys()) if (GENERAL.test(rel)) keep.add(rel);
  for (const rel of [...keep]) if (/^www\.9aola\.com\/revival\/mods\//.test(rel)) keep.delete(rel);

  // 3. The site.
  rmSync(out, { recursive: true, force: true });
  mkdirSync(out, { recursive: true });
  const web = path.join(root, "web");
  for (const f of ["boot.js", "start.js", "theatre.js", "saves.js", "robots.txt", "_headers"]) copyFileSync(path.join(web, f), path.join(out, f));
  const title = String(about.name || id);
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  let html = readFileSync(path.join(web, "index.html"), "utf8");
  html = html.replace(/<title>[^<]*<\/title>/, `<title>${esc(title)}</title>`);
  // The game alone (as ?bare=1 shows it), on black, without the site's decoration.
  const bare = /<script>if \(\/\[\?&\]bare=1\(&\|\$\)\/\.test\(location\.search\)\) document\.documentElement\.classList\.add\("bare"\);<\/script>/;
  if (!bare.test(html)) throw new Error("web/index.html: no bare switch to replace");
  html = html.replace(bare, '<script>document.documentElement.classList.add("bare", "solo");</script>');
  writeFileSync(path.join(out, "index.html"), html);
  let cover = "";
  if (ex.cover && existsSync(path.join(modDir, ex.cover))) {
    cover = "cover" + path.extname(ex.cover);
    copyFileSync(path.join(modDir, ex.cover), path.join(out, cover));
  }
  const solo = { mod: file, name: title, player: String(ex.player || "小奥拉"), ...(cover ? { cover } : {}), ...(firstFiles ? { files: firstFiles } : {}) };
  let config = readFileSync(path.join(web, "config.js"), "utf8");
  const start = config.indexOf("  standalone: (function () {");
  const end = config.indexOf("})(),", start);
  if (start < 0 || end < 0) throw new Error("web/config.js: no standalone setting to replace");
  config = config.slice(0, start) + `  standalone: ${JSON.stringify(solo)},` + config.slice(end + "})(),".length);
  writeFileSync(path.join(out, "config.js"), config);
  await build({ entryPoints: [path.join(root, "server/src/browser/entry.ts")], outfile: path.join(out, "emulator.js"), bundle: true, format: "iife", target: "es2022", legalComments: "none", logLevel: "warning" });
  await build({ entryPoints: [path.join(root, "server/src/browser/sw.ts")], outfile: path.join(out, "sw.js"), bundle: true, format: "iife", target: "es2022", logLevel: "warning" });
  cpSync(path.join(root, "node_modules/@ruffle-rs/ruffle"), path.join(out, "ruffle"), { recursive: true, filter: (src) => !src.endsWith(".map") && !src.endsWith("package.json") });
  writeFileSync(path.join(out, ".nojekyll"), "");
  const files = path.join(out, "files");
  const listed = [];
  let bytes = 0;
  const put = (rel, full) => {
    const dest = path.join(files, ...staticName(rel).split("/"));
    mkdirSync(path.dirname(dest), { recursive: true });
    copyFileSync(full, dest);
    listed.push(rel);
    bytes += statSync(full).size;
  };
  for (const rel of [...keep].sort()) put(rel, all.get(rel));
  put(`www.9aola.com/revival/mods/${file}`, swf);
  writeFileSync(path.join(files, "index.json"), JSON.stringify(listed));

  // 4. A word on hosting it: the folder is a website, for any static web server.
  writeFileSync(path.join(out, "README.txt"), [
    title,
    "",
    String(about.description || ""),
    "",
    "这个文件夹是一个静态网站：把它整个放到任何网页服务器上（GitHub Pages、Netlify、Cloudflare Pages、nginx……），打开 index.html 就能玩。",
    "要用 https（或本机的 localhost）打开；直接双击 index.html 打不开。",
    "进度自动保存在浏览器里（这个网址的 IndexedDB）。屏幕下方的「存档」可以把进度导出成文件，在别的浏览器或电脑上导入。",
    "",
    "This folder is a static website: put it on any web server (GitHub Pages, Netlify, Cloudflare Pages, nginx …) and open index.html.",
    "It has to be served over https (or from localhost); opening index.html as a file does not work.",
    "The game is saved in the browser as it goes (IndexedDB of the page's address). 存档 on the bar exports it to a file, to import in another browser or computer.",
    "",
  ].join("\n"));
  let total = 0;
  for (const [, full] of walk(out)) total += statSync(full).size;
  console.log(`${listed.length} game files, ${(bytes / 1e6).toFixed(1)} MB; the export: ${(total / 1e6).toFixed(1)} MB in ${path.relative(process.cwd(), out) || out}`);
  // A .zip of a folder (base/name) or of one file: every entry dated the game's own day
  // (2013-01-25), not the day it was exported.
  const zipUp = (zip, base, name, as = name) => {
    rmSync(zip, { force: true });
    execFileSync("python3", ["-c", [
      "import os, sys, zipfile",
      "zip, base, name, as_ = sys.argv[1:5]",
      "def put(z, full, arc):",
      "    info = zipfile.ZipInfo(arc, (2013, 1, 25, 0, 0, 0))",
      "    info.compress_type = zipfile.ZIP_DEFLATED",
      "    info.external_attr = 0o644 << 16",
      "    with open(full, 'rb') as fh: z.writestr(info, fh.read())",
      "with zipfile.ZipFile(zip, 'w', zipfile.ZIP_DEFLATED) as z:",
      "    top = os.path.join(base, name)",
      "    if os.path.isfile(top): put(z, top, as_)",
      "    for root, dirs, files in os.walk(top):",
      "        dirs.sort()",
      "        for f in sorted(files):",
      "            full = os.path.join(root, f)",
      "            put(z, full, os.path.relpath(full, base).replace(os.sep, '/'))",
    ].join("\n"), zip, base, name, as]);
    console.log(`zip: ${path.relative(process.cwd(), zip)} (${(statSync(zip).size / 1e6).toFixed(1)} MB)`);
  };
  if (!a["no-zip"]) zipUp(`${out}.zip`, path.dirname(out), path.basename(out));
  // --exe: a program for Windows with the site inside it (tools/mod-sdk/launcher): double-clicked,
  // it serves the site on the computer itself (127.0.0.1, at the mod's own port, where the browser
  // keeps its progress) and opens it in the default browser; offline. Built with Go.
  if (a.exe) {
    if (spawnSync("go", ["version"], { stdio: "ignore" }).status !== 0) {
      console.warn("warning: --exe needs Go (https://go.dev/dl/) to build the Windows program; not made");
    } else {
      const lw = mkdtempSync(path.join(os.tmpdir(), "aola-launcher-"));
      try {
        const src = path.join(root, "tools/mod-sdk/launcher");
        for (const f of readdirSync(src)) if (/\.go$|^go\.mod$/.test(f) && f !== "meta.go") copyFileSync(path.join(src, f), path.join(lw, f));
        cpSync(out, path.join(lw, "site"), { recursive: true });
        // The mod's own port, the same each time (the browser keeps the progress by address).
        let h = 2166136261;
        for (const c of Buffer.from(id)) h = Math.imul(h ^ c, 16777619) >>> 0;
        const port = String(20000 + (h % 9000));
        writeFileSync(path.join(lw, "meta.go"), `package main\n\nvar (\n\ttitle   = ${JSON.stringify(title)}\n\tport    = ${JSON.stringify(port)}\n\tmodFile = ${JSON.stringify(file)}\n)\n`);
        const exe = `${out}.exe`;
        // No path of this computer, no date, no build id in it.
        execFileSync("go", ["build", "-trimpath", "-buildvcs=false", "-ldflags", "-s -w -buildid=", "-o", exe, "."], {
          cwd: lw,
          stdio: "inherit",
          env: { ...process.env, GOOS: "windows", GOARCH: "amd64", CGO_ENABLED: "0", GOFLAGS: "" },
        });
        console.log(`exe: ${path.relative(process.cwd(), exe)} (${(statSync(exe).size / 1e6).toFixed(1)} MB, port ${port})`);
        if (!a["no-zip"]) zipUp(`${out}-windows.zip`, path.dirname(exe), path.basename(exe), `${title.replace(/[\\/:*?"<>|]/g, "")}.exe`);
      } finally {
        rmSync(lw, { recursive: true, force: true });
      }
    }
  }
} finally {
  rmSync(work, { recursive: true, force: true });
}
