// Build the static site (dist/) that plays the game from any static host,
// GitHub Pages included. Nothing is downloaded: the game files come from
// game/ (the archive) and build/rebuilt/ (npm run build:swf).
//
//   node scripts/build-static.mjs [--out dist] [--rebuilt build/rebuilt] [--game game]
//                                 [--exclude dir,dir] [--copy]
//
// dist/
//   index.html, config.js, boot.js     the front end (web/)
//   emulator.js                         the in-page server emulator (server/src/browser/entry.ts)
//   sw.js                               the service worker that answers the original URLs
//   ruffle/                             Ruffle 0.7.1 (npm @ruffle-rs/ruffle)
//   files/<host>/<path>                 game files, "%" in names turned into "~"
//   files/index.json                    the list of game files the service worker answers from
//
// The two roots are merged as the old lookup searched them: build/rebuilt
// first, then game/; a file the first root answers for is left out.
// Files are hard-linked into dist/ where possible (--copy to copy them).

import { build } from "esbuild";
import { cpSync, existsSync, linkSync, copyFileSync, mkdirSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { staticName, withoutQuery } from "../server/src/core/mirrorPath.ts";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const { values: a } = parseArgs({
  options: {
    out: { type: "string", default: path.join(root, "dist") },
    rebuilt: { type: "string", default: path.join(root, "build/rebuilt") },
    game: { type: "string", default: path.join(root, "game") },
    exclude: { type: "string", default: "" },
    copy: { type: "boolean", default: false },
  },
});
const out = path.resolve(a.out);
const roots = [path.resolve(a.rebuilt), path.resolve(a.game)];
for (const r of roots) {
  if (!existsSync(r)) {
    console.error(`missing ${path.relative(root, r) || r}: ` + (r === roots[0] ? "build the rebuilt modules first (npm run build:swf)" : "the game files are not there"));
    process.exit(1);
  }
}
const excluded = new Set(a.exclude.split(",").filter(Boolean));
const SKIP = new Set(["FILES.jsonl", "README.md"]);

rmSync(out, { recursive: true, force: true });
mkdirSync(out, { recursive: true });

// Front end.
for (const f of ["index.html", "config.js", "boot.js"]) copyFileSync(path.join(root, "web", f), path.join(out, f));
await build({
  entryPoints: [path.join(root, "server/src/browser/entry.ts")],
  outfile: path.join(out, "emulator.js"),
  bundle: true,
  format: "iife",
  target: "es2022",
  legalComments: "none",
  logLevel: "warning",
});
await build({
  entryPoints: [path.join(root, "server/src/browser/sw.ts")],
  outfile: path.join(out, "sw.js"),
  bundle: true,
  format: "iife",
  target: "es2022",
  logLevel: "warning",
});
const ruffle = path.join(root, "node_modules/@ruffle-rs/ruffle");
if (!existsSync(ruffle)) {
  console.error("Ruffle is not installed: run `npm ci` first");
  process.exit(1);
}
cpSync(ruffle, path.join(out, "ruffle"), { recursive: true, filter: (src) => !src.endsWith(".map") && !src.endsWith("package.json") });
// GitHub Pages: serve every file as it is (no Jekyll; names may start with "_").
writeFileSync(path.join(out, ".nojekyll"), "");

// Game files.
function* walk(dir, rel = "") {
  for (const e of readdirSync(dir, { withFileTypes: true }).sort((x, y) => (x.name < y.name ? -1 : 1))) {
    const r = rel ? `${rel}/${e.name}` : e.name;
    if (e.isDirectory()) yield* walk(path.join(dir, e.name), r);
    else if (e.isFile()) yield [r, path.join(dir, e.name)];
  }
}
const files = path.join(out, "files");
const listed = [];
const plainHave = new Set();
const exactHave = new Set();
const names = new Map();
let bytes = 0;
let linked = 0;
const perRoot = new Map();
for (const r of roots) {
  for (const [rel, full] of walk(r)) {
    if (SKIP.has(rel)) continue;
    const top = rel.split("/")[1];
    if (excluded.has(top)) continue;
    const p = withoutQuery(rel);
    if (plainHave.has(p) || exactHave.has(rel)) continue; // the root above answers for it
    exactHave.add(rel);
    if (p === rel) plainHave.add(p);
    const name = staticName(rel);
    if (names.has(name)) throw new Error(`two files would both be ${name}: ${names.get(name)} and ${rel}`);
    names.set(name, rel);
    const dest = path.join(files, ...name.split("/"));
    mkdirSync(path.dirname(dest), { recursive: true });
    if (!a.copy) {
      try {
        linkSync(full, dest);
        linked++;
      } catch {
        copyFileSync(full, dest);
      }
    } else copyFileSync(full, dest);
    const size = statSync(full).size;
    bytes += size;
    perRoot.set(r, (perRoot.get(r) ?? 0) + 1);
    listed.push(rel);
  }
}
writeFileSync(path.join(files, "index.json"), JSON.stringify(listed));

let total = 0;
for (const [, full] of walk(out)) total += statSync(full).size;
for (const r of roots) console.log(`${String(perRoot.get(r) ?? 0).padStart(6)} files from ${path.relative(root, r)}`);
console.log(`${String(listed.length).padStart(6)} game files, ${(bytes / 1e6).toFixed(1)} MB${linked ? " (hard-linked)" : ""}`);
console.log(`dist: ${(total / 1e6).toFixed(1)} MB in ${path.relative(process.cwd(), out) || out}`);
// GitHub Pages publishes at most 1 GB.
if (total > 1e9) console.warn("warning: over GitHub Pages' 1 GB limit; leave out folders with --exclude (e.g. --exclude activityres,game)");
