#!/usr/bin/env node
// Build the 沙盒's mods (docs/MODDING.md) with the repository's toolchain (Apache Royale's
// compiler and playerglobal.swc in .toolchain/, set up by `npm run build:swf` or
// rebuild/build/setup-toolchain.sh).
//
//   node tools/mod-sdk/build.mjs api                 the mod API as a SWC: build/mod-sdk/aola-mod-api.swc,
//                                                    and the classes embedded files are based on:
//                                                    build/mod-sdk/aola-mod-embed.swc
//   node tools/mod-sdk/build.mjs <mod folder> …      a mod from its asconfig.json (mainClass,
//                                                    compilerOptions.source-path, .library-path, .output)
//   node tools/mod-sdk/build.mjs examples [out dir]  the examples of tools/mod-sdk/examples into
//                                                    out dir (default build/mods) with index.json
//
// A mod is compiled against playerglobal.swc and the API SWC as external libraries: the game
// gives those classes at run time. The embed SWC (mx.core.BitmapAsset, SoundAsset, …, which
// the compiler bases [Embed] classes on) is linked into the mod. Java 11+ is needed.

import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const API_SRC = path.join(ROOT, "rebuild/src/shared");
const API_DIR = path.join(API_SRC, "mmo/revival/mod");
const API_SWC = path.join(ROOT, "build/mod-sdk/aola-mod-api.swc");
const EMBED_SRC = path.join(HERE, "embed");
const EMBED_DIR = path.join(EMBED_SRC, "mx/core");
const EMBED_SWC = path.join(ROOT, "build/mod-sdk/aola-mod-embed.swc");
const CONFIG = path.join(ROOT, "rebuild/build/empty-config.xml");

function toolchain() {
  let royale = process.env.ROYALE, pg = process.env.PLAYERGLOBAL;
  const env = path.join(ROOT, ".toolchain/env.sh");
  if ((!royale || !pg) && !existsSync(env)) execFileSync("sh", [path.join(ROOT, "rebuild/build/setup-toolchain.sh"), path.join(ROOT, ".toolchain")], { stdio: "inherit" });
  if ((!royale || !pg) && existsSync(env)) {
    for (const line of readFileSync(env, "utf8").split("\n")) {
      const m = line.match(/^export (\w+)="(.*)"$/);
      if (m && m[1] === "ROYALE") royale ||= m[2];
      if (m && m[1] === "PLAYERGLOBAL") pg ||= m[2];
    }
  }
  if (!royale || !pg) throw new Error("no toolchain: run `npm run build:swf` once, or set ROYALE and PLAYERGLOBAL");
  return { royale, pg };
}

function java(tc, jar, args) {
  const out = execFileSync("java", [`-Droyalelib=${tc.royale}/frameworks`, "-jar", path.join(tc.royale, "lib", jar), ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  return out;
}

function newest(dir) {
  let t = 0;
  for (const f of readdirSync(dir)) t = Math.max(t, statSync(path.join(dir, f)).mtimeMs);
  return t;
}

function swc(tc, srcRoot, dir, pkg, out, label) {
  if (existsSync(out) && statSync(out).mtimeMs > newest(dir)) return out;
  mkdirSync(path.dirname(out), { recursive: true });
  const classes = readdirSync(dir).filter((f) => f.endsWith(".as")).map((f) => `${pkg}.${f.slice(0, -3)}`);
  java(tc, "compc.jar", [`-load-config=${CONFIG}`, `-external-library-path+=${tc.pg}`, `-source-path+=${srcRoot}`,
    "-target-player=10.1", "-swf-version=10", "-include-classes", ...classes, `-output=${out}`]);
  console.log(`${label}: ${path.relative(process.cwd(), out)}`);
  return out;
}

export function buildApi(tc = toolchain()) {
  swc(tc, EMBED_SRC, EMBED_DIR, "mx.core", EMBED_SWC, "embed");
  return swc(tc, API_SRC, API_DIR, "mmo.revival.mod", API_SWC, "API");
}

export function buildMod(dir, out, tc = toolchain()) {
  const conf = JSON.parse(readFileSync(path.join(dir, "asconfig.json"), "utf8"));
  const opts = conf.compilerOptions ?? {};
  const main = String(conf.mainClass ?? "");
  if (!main) throw new Error(`${dir}/asconfig.json: no mainClass`);
  const sources = (opts["source-path"] ?? ["src"]).map((s) => path.resolve(dir, s));
  const mainFile = sources.map((s) => path.join(s, ...main.split(".")) + ".as").find(existsSync);
  if (!mainFile) throw new Error(`${main}.as is not in the source path`);
  out = path.resolve(out ?? path.resolve(dir, opts.output ?? `bin/${path.basename(dir)}.swf`));
  mkdirSync(path.dirname(out), { recursive: true });
  const api = buildApi(tc);
  const libs = new Set([EMBED_SWC, ...(opts["library-path"] ?? []).map((l) => path.resolve(dir, l))]);
  const args = [`-load-config=${CONFIG}`, `-external-library-path+=${tc.pg}`, `-external-library-path+=${api}`,
    ...sources.map((s) => `-source-path+=${s}`), ...[...libs].map((l) => `-library-path+=${l}`),
    "-target-player=10.1", "-swf-version=10", "-static-link-runtime-shared-libraries=true", "-debug=false", "-optimize=true",
    "-default-size", "960", "560", "-default-frame-rate", "25", `-output=${out}`, mainFile];
  try {
    java(tc, "mxmlc.jar", args);
  } catch (e) {
    process.stderr.write(String(e.stdout ?? "") + String(e.stderr ?? ""));
    throw new Error(`could not compile ${dir}`);
  }
  console.log(`mod: ${path.relative(process.cwd(), out)}`);
  return out;
}

export function buildExamples(outDir = path.join(ROOT, "build/mods")) {
  const tc = toolchain();
  const base = path.join(HERE, "examples");
  const index = [];
  for (const name of readdirSync(base).sort()) {
    const dir = path.join(base, name);
    if (!existsSync(path.join(dir, "asconfig.json"))) continue;
    const file = `${name}.swf`;
    buildMod(dir, path.join(outDir, file), tc);
    const about = existsSync(path.join(dir, "about.json")) ? JSON.parse(readFileSync(path.join(dir, "about.json"), "utf8")) : {};
    index.push({ file, name: about.name ?? name, description: about.description ?? "" });
  }
  writeFileSync(path.join(outDir, "index.json"), JSON.stringify(index, null, 1) + "\n");
  console.log(`${index.length} examples, index: ${path.relative(process.cwd(), path.join(outDir, "index.json"))}`);
  return index;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [what, ...rest] = process.argv.slice(2);
  try {
    if (!what) {
      console.log("node tools/mod-sdk/build.mjs api | examples [out dir] | <mod folder> [<mod folder> …]");
      process.exit(1);
    } else if (what === "api") buildApi();
    else if (what === "examples") buildExamples(rest[0] ? path.resolve(rest[0]) : undefined);
    else for (const d of [what, ...rest]) buildMod(path.resolve(d));
  } catch (e) {
    console.error(e.message);
    process.exit(1);
  }
}
