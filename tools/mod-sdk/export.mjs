#!/usr/bin/env node
// A mod exported as a game of its own: a folder (and a .zip of it) with the page, Ruffle, the
// server emulator, the mod, and only the game files the mod uses, which any static web server
// can serve (docs/MODDING.md, "Exporting a mod").
//
//   node tools/mod-sdk/export.mjs <mod folder> [--out build/export] [--seconds 900] [--no-record] [--no-zip]
//
// The mod folder is one tools/mod-sdk/build.mjs builds (asconfig.json); its about.json gives the
// name and, under "export", what to keep besides what is seen played:
//   {"name": "…", "description": "…",
//    "export": {"player": "the 奥拉's name", "cover": "cover.svg",
//               "races": [216, …], "npcs": [28, …], "music": ["music/…mp3"], "files": ["www.9aola.com/…"]}}
//
// Which game files: those the game loads while the mod is walked through (export-tour.mjs, in
// the headless browser of server/test/e2e/boot2013.mjs: every room it defines, its
// conversations, a battle, the bag), and by rule for each 亚比 of "races" its battle sprite, its
// pictures and the animations of the skills it knows by Lv100, for each NPC of "npcs" its
// picture, and the "music" and "files" named. The page and the emulator are built as
// npm run build builds them (run it first: the tour plays the site of dist/).
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
  },
});
if (positionals.length !== 1) {
  console.error("usage: node tools/mod-sdk/export.mjs <mod folder> [--out dir] [--seconds n] [--no-record] [--no-zip]");
  process.exit(2);
}
const modDir = path.resolve(positionals[0]);
const about = JSON.parse(readFileSync(path.join(modDir, "about.json"), "utf8"));
const asconfig = JSON.parse(readFileSync(path.join(modDir, "asconfig.json"), "utf8"));
const ex = about.export ?? {};
const swf = path.resolve(modDir, asconfig.compilerOptions.output);
const file = path.basename(swf);
if (!/^[A-Za-z0-9_.-]+\.swf$/.test(file)) throw new Error(`the mod's file name ${file}: letters, digits, _ . - only`);
const id = file.replace(/\.swf$/, "");
const out = path.resolve(a.out, id);
const rebuilt = path.join(root, "build/rebuilt");
const game = path.join(root, "game");
const dist = path.join(root, "dist");
for (const [p, why] of [[rebuilt, "npm run build:swf"], [game, "the game files"], [dist, "npm run build"]]) {
  if (!existsSync(p)) throw new Error(`missing ${path.relative(root, p)} (${why})`);
}

// The mod, built when its sources are newer than its SWF.
const newest = (dir) => readdirSync(dir, { withFileTypes: true, recursive: true }).reduce((t, e) => (e.isFile() ? Math.max(t, statSync(path.join(e.parentPath ?? e.path, e.name)).mtimeMs) : t), 0);
if (!existsSync(swf) || newest(path.join(modDir, "src")) > statSync(swf).mtimeMs) {
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

// 1. What the game loads as the mod is walked through.
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
    ], { stdio: ["ignore", "inherit", "inherit"], env: { ...process.env, EXPORT_RACE: String((ex.races ?? [1])[0]) } });
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
  }

  // 2. By rule.
  const pm = JSON.parse(readFileSync(path.join(root, "rebuild/static/www.9aola.com/revival/pmdata.json"), "utf8"));
  const W = "www.9aola.com/";
  for (const race of ex.races ?? []) {
    want(`${W}fightassets/pet${race}.swf`);
    want(`${W}peticon/peticon${race}.swf`);
    want(`${W}bossfightmovie/boss${race}.swf`);
    for (const [lv, skill] of pm.species[String(race)]?.learn ?? []) if (lv <= 100) want(`${W}fightassets/effect${skill}.swf`);
  }
  for (const npc of ex.npcs ?? []) want(`${W}tasknpc/npc${npc}.swf`);
  for (const f of [...(ex.music ?? []), ...(ex.files ?? [])]) if (!want(f.startsWith(W) ? f : W + f)) console.warn(`warning: ${f} is not a game file`);
  // The battle's backgrounds and sounds, and the data the rebuilt modules read.
  for (const rel of all.keys()) if (/^www\.9aola\.com\/(petfightbackground|revival)\//.test(rel)) keep.add(rel);
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
  // The game alone (as ?bare=1 shows it), without the site's decoration.
  html = html.replace(/<script>if \(\/\[\?&\]bare=1\(&\|\$\)\/\.test\(location\.search\)\) document\.documentElement\.classList\.add\("bare"\);<\/script>/, '<script>document.documentElement.classList.add("bare");</script>');
  writeFileSync(path.join(out, "index.html"), html);
  let cover = "";
  if (ex.cover && existsSync(path.join(modDir, ex.cover))) {
    cover = "cover" + path.extname(ex.cover);
    copyFileSync(path.join(modDir, ex.cover), path.join(out, cover));
  }
  const solo = { mod: file, name: title, player: String(ex.player || "小奥拉"), ...(cover ? { cover } : {}) };
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

  // 4. How to play it.
  writeFileSync(path.join(out, "serve.py"), `#!/usr/bin/env python3
"""Serves this folder at http://127.0.0.1:8000/ and opens it (browsers run the game only from a web server)."""
import http.server, os, socketserver, threading, webbrowser
os.chdir(os.path.dirname(os.path.abspath(__file__)))
H = http.server.SimpleHTTPRequestHandler
H.extensions_map.update({".wasm": "application/wasm", ".js": "text/javascript", ".svg": "image/svg+xml"})
class S(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
with S(("127.0.0.1", 8000), H) as s:
    print("${title.replace(/"/g, "")}: http://127.0.0.1:8000/  (Ctrl+C to stop)")
    threading.Timer(1, lambda: webbrowser.open("http://127.0.0.1:8000/")).start()
    s.serve_forever()
`);
  writeFileSync(path.join(out, "play.bat"), `@echo off\r\ncd /d "%~dp0"\r\npython serve.py || py serve.py\r\npause\r\n`);
  writeFileSync(path.join(out, "play.sh"), `#!/bin/sh\ncd "$(dirname "$0")" && exec python3 serve.py\n`);
  writeFileSync(path.join(out, "README.txt"), [
    title,
    "",
    String(about.description || ""),
    "",
    "怎么玩：游戏在浏览器里运行，要通过网页服务器打开（直接双击 index.html 不行）。",
    "  Windows：双击 play.bat（需要 Python 3）。macOS / Linux：运行 ./play.sh 或 python3 serve.py。",
    "  也可以把整个文件夹放到任何静态网站服务器上，打开 index.html。",
    "进度保存在浏览器里（这个网址的 IndexedDB）。",
    "",
    "How to play: the game runs in a browser, from a web server (not by opening index.html as a file).",
    "  Windows: double-click play.bat (Python 3 needed). macOS / Linux: ./play.sh, or python3 serve.py.",
    "  Any static web server works too (put this folder on it and open index.html).",
    "The game is saved in the browser (IndexedDB of the page's address).",
    "",
  ].join("\n"));
  let total = 0;
  for (const [, full] of walk(out)) total += statSync(full).size;
  console.log(`${listed.length} game files, ${(bytes / 1e6).toFixed(1)} MB; the export: ${(total / 1e6).toFixed(1)} MB in ${path.relative(process.cwd(), out) || out}`);
  if (!a["no-zip"]) {
    const zip = `${out}.zip`;
    rmSync(zip, { force: true });
    execFileSync("python3", ["-c", "import shutil,sys; shutil.make_archive(sys.argv[1], 'zip', sys.argv[2], sys.argv[3])", out, path.dirname(out), path.basename(out)]);
    console.log(`zip: ${path.relative(process.cwd(), zip)} (${(statSync(zip).size / 1e6).toFixed(1)} MB)`);
  }
} finally {
  rmSync(work, { recursive: true, force: true });
}
