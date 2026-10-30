// Command line entry: one process serves the mirror over HTTP, the browser
// front end, a WebSocket bridge for Ruffle web, and raw TCP game ports.
//
//   node server/src/node/main.ts [--mirror build/rebuilt,game] [--web dist] --game 8001 --date 2012-08-15
//
// Then point a runtime at it:
//   Ruffle desktop fork   built-in redirect (desktop/README.md)
//   browser               http://127.0.0.1:8080/  (service worker serves the mirror)
//   Flash projector       hosts file: 127.0.0.1 aola.100bt.com, and --http 80

import { appendFileSync, mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { GameClock } from "../core/clock.ts";
import { Emulator } from "../core/emulator.ts";
import { FRAMING_PRESETS, parseFraming } from "../core/framing.ts";
import { ConsoleRecorder, TeeRecorder } from "../core/recorder.ts";
import { aola2012Http, installAola2012 } from "../game/aola2012.ts";
import { installHandshakeDemo } from "../game/devHandlers.ts";
import { JsonFileStore, JsonlRecorder } from "./fileStore.ts";
import { createMirrorServer } from "./http.ts";
import { attachWebSocket, listenPolicy, listenTcp } from "./transports.ts";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

const { values: a } = parseArgs({
  options: {
    mirror: { type: "string", default: [path.join(root, "build/rebuilt"), path.join(root, "game")].join(",") },
    web: { type: "string", default: path.join(root, "dist") },
    work: { type: "string", default: path.join(root, "work") },
    bind: { type: "string", default: "127.0.0.1" },
    http: { type: "string", default: "8080" },
    game: { type: "string", default: "" },
    policy: { type: "string", default: "0" },
    date: { type: "string", default: "2012-08-15" },
    framing: { type: "string", default: "raw" },
    demo: { type: "boolean", default: false },
    quiet: { type: "boolean", default: false },
    help: { type: "boolean", short: "h", default: false },
  },
});

if (a.help) {
  console.log(`aola-revival server

  --mirror DIRS    game file roots searched in order (default build/rebuilt,game)
  --web DIR        browser front end (default dist, from npm run build)
  --work DIR       logs and saves (default ../work)
  --bind ADDR      listen address (default 127.0.0.1)
  --http PORT      HTTP + WebSocket bridge (default 8080; 80 for hosts-file mode)
  --game PORTS     raw TCP game ports, comma separated (e.g. 8001,8002)
  --policy PORT    Flash socket policy server, usually 843 (default off)
  --date DAY       anchor date for the game clock, China time (default 2012-08-15)
  --framing F      ${Object.keys(FRAMING_PRESETS).join(" | ")} | JSON spec (default raw)
  --demo           WebSocket-handshake demo handlers (pipeline test only)
  --quiet          no per-frame console output`);
  process.exit(0);
}

const work = path.resolve(a.work);
mkdirSync(work, { recursive: true });
const log = (s: string) => {
  if (!a.quiet) console.log(s);
};
const recorder = new TeeRecorder(new JsonlRecorder(path.join(work, "frames.jsonl")), ...(a.quiet ? [] : [new ConsoleRecorder()]));
const emu = new Emulator({
  framing: parseFraming(a.framing),
  clock: new GameClock(a.date),
  store: new JsonFileStore(path.join(work, "saves")),
  recorder,
});
if (a.demo) installHandshakeDemo(emu);
else installAola2012(emu);

const missLog = path.join(work, "http-misses.jsonl");
const server = createMirrorServer({
  mirrorDir: a.mirror.split(",").map((m) => path.resolve(m)),
  webDir: path.resolve(a.web),
  dynamic: aola2012Http(),
  onMiss: (rec) => appendFileSync(missLog, JSON.stringify(rec) + "\n"),
  log: (s) => log(`[http] ${s}`),
});
attachWebSocket(emu, server);
await new Promise<void>((resolve) => server.listen(Number(a.http), a.bind, resolve));
console.log(`[http] mirror + front end on http://${a.bind}:${a.http}/  (WebSocket bridge: /__socket/<port>)`);

for (const p of a.game.split(",").map((s) => s.trim()).filter(Boolean)) {
  await listenTcp(emu, Number(p), a.bind);
  console.log(`[tcp]  game port ${p}`);
}
if (Number(a.policy)) {
  await listenPolicy(Number(a.policy), a.bind, (s) => log(`[policy] ${s}`));
  console.log(`[policy] port ${a.policy}`);
}
console.log(`[clock] game time starts at ${emu.clock.now().toISOString()} (anchor ${a.date}, UTC+8)`);
console.log(`[log]  frames -> ${path.join(work, "frames.jsonl")}; HTTP misses -> ${missLog}`);
