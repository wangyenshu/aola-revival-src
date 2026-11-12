// A shared (multiplayer) server on Node: the 2013 game for many 奥拉 at once.
//
//   node server/src/node/multi.ts [--port 8080] [--bind 0.0.0.0] [--data work/server] [--web dist]
//
// One process, three things on one port:
//   /__socket/9339   the game (WebSocket; Ruffle's socketProxy of the page's 联机模式)
//   /__api/…          the start screen's 改名字 and the server's status (JSON)
//   everything else   the static site (npm run build's dist/), so the same address serves
//                     the page too; leave --web out to serve only the game (the page then
//                     comes from elsewhere, e.g. GitHub Pages, and is told this address).
// Saves are JSON files under --data. Nothing here is particular to a hosting service: any
// machine with Node 22 and a public port (a VPS, a container platform, a home PC behind a
// tunnel) runs it the same; src/cloudflare/worker.ts is the same game on Cloudflare.

import { createReadStream, promises as fs, realpathSync } from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { WebSocketServer, type WebSocket } from "ws";
import { contentType } from "../core/mirrorPath.ts";
import { createGameHost } from "../game/sfs2013/host.ts";
import { apiBodyMax, handleApi } from "../game/sfs2013/api.ts";
import { NullRecorder } from "../core/recorder.ts";
import { JsonFileStore } from "./fileStore.ts";
import { addrKey, localAddr } from "../core/addr.ts";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const { values: a } = parseArgs({
  options: {
    port: { type: "string", default: process.env.PORT ?? "8080" },
    bind: { type: "string", default: process.env.BIND ?? "0.0.0.0" },
    data: { type: "string", default: process.env.AOLA_DATA ?? path.join(root, "work/server") },
    web: { type: "string", default: process.env.AOLA_WEB ?? path.join(root, "dist") },
    tables: { type: "string", default: process.env.AOLA_TABLES ?? "" },
    date: { type: "string", default: process.env.AOLA_DATE ?? "" },
    closed: { type: "boolean", default: process.env.AOLA_CLOSED === "1" },
    // The 工具箱 is open unless closed (--no-toolbox, or AOLA_TOOLBOX=0); --toolbox opens it
    // whatever AOLA_TOOLBOX says.
    toolbox: { type: "boolean" },
    "no-toolbox": { type: "boolean", default: process.env.AOLA_TOOLBOX === "0" },
    adopt: { type: "boolean", default: process.env.AOLA_ADOPT === "1" },
    "max-players": { type: "string", default: process.env.AOLA_MAX_PLAYERS ?? "200" },
    "trust-proxy": { type: "boolean", default: process.env.AOLA_TRUST_PROXY === "1" },
    "signups-per-day": { type: "string", default: process.env.AOLA_SIGNUPS_PER_DAY ?? "5" },
    help: { type: "boolean", short: "h", default: false },
  },
});

if (a.help) {
  console.log(`aola-revival shared server

  --port N          HTTP + WebSocket port (default 8080, or $PORT)
  --bind ADDR       listen address (default 0.0.0.0)
  --data DIR        saves (default work/server, or $AOLA_DATA)
  --web DIR         the static site to serve too (default dist; "" for none)
  --tables DIR      where www.9aola.com/revival/*.json are (default <web>/files)
  --date DAY        the game clock starts at this day (China time) at each start: for trying a
                    day of the era, not for playing; default: the real time
  --closed          no 注册: only 奥拉 the server already has may log in
  --no-toolbox      close the 工具箱 (晶币, 亚比 … for nothing), mods' gifts of 亚比 and 导入存档
                    to the players (a fair server); open by default, as in 单机模式
  --adopt           a save with no password (copied in) takes the password of its first login
  --max-players N   at most N in the game at once (default 200)
  --signups-per-day N  new 奥拉 one address may 注册 a day (default 5; 0: no limit)
  --trust-proxy     behind a reverse proxy or tunnel: the client's address is the X-Forwarded-For
                    header's (the password lock is per address); off by default, when the header
                    could be anyone's`);
  process.exit(0);
}

const web = a.web ? path.resolve(a.web) : "";
const tables = a.tables ? path.resolve(a.tables) : web ? path.join(web, "files") : path.join(root, "build/rebuilt");
// The saves must not be in the site: the site's files are anyone's to download. Compared as the
// file system finds them (links followed; letter case alike where it does not count).
/** A path's real form: its nearest folder that exists, links followed, and the rest as given. */
function realOf(p: string): string {
  let head = path.resolve(p);
  const rest: string[] = [];
  for (;;) {
    try {
      return path.join(realpathSync(head), ...rest);
    } catch {
      const up = path.dirname(head);
      if (up === head) return path.resolve(p);
      rest.unshift(path.basename(head));
      head = up;
    }
  }
}
const webReal = web ? realOf(web) : "";
const sameCase = process.platform === "win32" || process.platform === "darwin" ? (p: string) => p.toLowerCase() : (p: string) => p;
const dataDir = path.resolve(a.data);
const realData = sameCase(realOf(dataDir)), realWeb = web ? sameCase(realOf(web)) : "";
if (realWeb && (realData === realWeb || realData.startsWith(realWeb + path.sep))) {
  console.error(`[aola] the saves (--data ${dataDir}) are inside the site (--web ${web}): anyone could download them. Keep them elsewhere.`);
  process.exit(1);
}
const maxPlayers = Number(a["max-players"]) || 200;

const host = createGameHost({
  store: new JsonFileStore(dataDir),
  loadJson: async (p) => {
    try {
      return JSON.parse(await fs.readFile(path.join(tables, "www.9aola.com", p), "utf8"));
    } catch {
      return undefined;
    }
  },
  date: a.date || undefined,
  accounts: { required: true, register: !a.closed, adopt: a.adopt, signupsPerDay: count(a["signups-per-day"], 5) },
  recorder: new NullRecorder(),
  toolbox: a.toolbox === true ? true : !a["no-toolbox"],
  maxPlayers,
});

function inside(dir: string, rel: string): string | null {
  const full = path.resolve(dir, rel);
  return full === dir || full.startsWith(dir + path.sep) ? full : null;
}

async function serveStatic(req: http.IncomingMessage, res: http.ServerResponse, pathname: string): Promise<void> {
  if (!web) {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("this server has only the game: open the page elsewhere and give it this address\n");
    return;
  }
  let rel = decodeURIComponent(pathname).replace(/^\/+/, "");
  if (rel === "" || rel.endsWith("/")) rel += "index.html";
  const found = inside(web, rel);
  // As the file system finds it: a link in the site to somewhere else (the saves) is not served.
  const real = found ? await fs.realpath(found).catch(() => null) : null;
  const file = real && inside(webReal, path.relative(webReal, real)) === real ? real : null;
  const st = file ? await fs.stat(file).catch(() => null) : null;
  if (!file || !st?.isFile()) {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("not found\n");
    return;
  }
  // Asked again each time, answered "not changed" when it is not (web/_headers: the rebuilt
  // modules, the tables and files/index.json change under the same names with each build).
  const tag = `W/"${st.size.toString(16)}-${Math.floor(st.mtimeMs).toString(16)}"`;
  const head = { "Cache-Control": "no-cache", ETag: tag, "Last-Modified": st.mtime.toUTCString() };
  if (req.headers["if-none-match"] === tag) {
    res.writeHead(304, head);
    return void res.end();
  }
  res.writeHead(200, { "Content-Type": contentType(rel), "Content-Length": st.size, ...head });
  if (req.method === "HEAD") return void res.end();
  createReadStream(file).pipe(res);
}

// A last net: an error no request catches (a timer's, a hook's) is logged, and the game goes on
// for everyone else instead of the process ending.
process.on("unhandledRejection", (e) => console.error(`[aola] unhandled: ${(e as Error)?.stack ?? String(e)}`));
// A throw nothing caught (in a timer, a socket's event): logged, and the server goes on for
// everyone else, as one player's failed request does. A fault that keeps throwing (more than
// UNCAUGHT_MAX a minute) ends the process instead, for whatever started it to start it again.
const UNCAUGHT_MAX = 50;
let uncaught: number[] = [];
process.on("uncaughtException", (e) => {
  console.error(`[aola] uncaught: ${(e as Error)?.stack ?? String(e)}`);
  const t = Date.now();
  uncaught = [...uncaught.filter((x) => t - x < 60_000), t];
  if (uncaught.length > UNCAUGHT_MAX) {
    console.error("[aola] too many uncaught errors in a minute: stopping");
    process.exit(1);
  }
});

const API_HEADERS = { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "Content-Type" };
/**
 * The client's address (the password lock's: accounts.ts, and the connections an address may
 * hold): the connection's, or behind a proxy (--trust-proxy) the last of X-Forwarded-For, the one
 * the proxy put there (what comes before it is the client's to write). Not the header's
 * otherwise: a client could set it to anything, a new one for every wrong password. An IPv6
 * address counts by its /64 (one line has a whole /64).
 */
const clientAddr = (req: http.IncomingMessage) => {
  const fwd = a["trust-proxy"] ? (String(req.headers["x-forwarded-for"] ?? "").split(",").pop() ?? "").trim() : "";
  if (!a["trust-proxy"]) proxyWarning(req);
  return `ws ${addrKey(fwd || req.socket.remoteAddress || "")}`;
};
/**
 * Behind a proxy without --trust-proxy, every player is the proxy's address: one password lock,
 * one count of connections and of 注册 for all. Said once, when a request shows it.
 */
let warned = false;
function proxyWarning(req: http.IncomingMessage): void {
  if (warned || !req.headers["x-forwarded-for"] || !localAddr(req.socket.remoteAddress ?? "")) return;
  warned = true;
  console.warn(
    "[aola] requests come through a proxy (X-Forwarded-For from " +
      (req.socket.remoteAddress ?? "?") +
      ") but --trust-proxy is off: every player counts as that one address (the password lock, connections, 注册). " +
      "Start with --trust-proxy if the proxy is yours.",
  );
}

/** Every this often a ping: a connection that has not answered the last one is ended. */
const PING_MS = 30_000;

const server = http.createServer((req, res) => {
  // A request line URL cannot read (`GET //`, `GET http://[`) is refused, not thrown: a throw
  // here is outside every promise and would end the process.
  let url: URL;
  try {
    url = new URL(req.url ?? "/", "http://x");
  } catch {
    res.writeHead(400, { "Content-Type": "text/plain" });
    return void res.end("bad request\n");
  }
  const task = url.pathname.startsWith("/__api/")
    ? (async () => {
        const chunks: Buffer[] = [];
        let size = 0;
        for await (const c of req) {
          size += (c as Buffer).length;
          if (size > apiBodyMax(url.pathname)) {
            // With the API's headers: a page of another address reads why (saves.js).
            res.writeHead(413, API_HEADERS);
            res.end(JSON.stringify({ ok: false, error: url.pathname === "/__api/save/import" ? "这个存档太大了。" : "请求太大了。" }));
            req.destroy();
            return;
          }
          chunks.push(c as Buffer);
        }
        const out = await handleApi(host, url.pathname, req.method ?? "GET", Buffer.concat(chunks).toString("utf8"), clientAddr(req));
        res.writeHead(out.status, API_HEADERS);
        res.end(JSON.stringify(out.body));
      })()
    : serveStatic(req, res, url.pathname);
  task.catch((e: unknown) => {
    // The path only: a query (?pass=… of the tests) is not logged.
    console.error(`[http] ${url.pathname}: ${(e as Error).message}`);
    if (!res.headersSent) res.writeHead(500, url.pathname.startsWith("/__api/") ? API_HEADERS : {});
    res.end(url.pathname.startsWith("/__api/") ? JSON.stringify({ ok: false, error: "服务器出错了。" }) : undefined);
  });
});

const wss = new WebSocketServer({ noServer: true, maxPayload: 1 << 20 });
server.on("upgrade", (req, socket, head) => {
  const m = /^\/__socket\/(\d+)/.exec(req.url ?? "");
  if (!m) return void socket.destroy();
  // The connections not logged in, of the server and of the address, and the address's in all
  // (host.ts admit); the game's places are counted at the login (--max-players).
  const addr = clientAddr(req);
  if (host.admit(addr)) return void socket.destroy();
  wss.handleUpgrade(req, socket, head, (ws: WebSocket) => {
    const session = host.attach(
      { remote: addr, send: (b) => ws.send(b), close: () => ws.close() },
      Number(m[1]),
    );
    // A connection gone without a word (a phone changing networks) is noticed by its silence.
    let alive = true;
    ws.on("pong", () => (alive = true));
    const ping = setInterval(() => {
      if (!alive) return void ws.terminate();
      alive = false;
      ws.ping();
    }, PING_MS);
    ws.on("close", () => clearInterval(ping));
    ws.on("message", (data, isBinary) => {
      const buf = Array.isArray(data) ? Buffer.concat(data) : Buffer.from(data as ArrayBuffer);
      session.receive(isBinary ? new Uint8Array(buf.buffer, buf.byteOffset, buf.byteLength) : new TextEncoder().encode(buf.toString("utf8")));
    });
    ws.on("close", () => host.detach(session));
    ws.on("error", () => host.detach(session));
  });
});

server.listen(Number(a.port), a.bind, () => {
  console.log(`[aola] shared server on http://${a.bind}:${a.port}/  (game: /__socket/9339, saves: ${path.resolve(a.data)})`);
  console.log(`[aola] ${web ? `site: ${web}` : "no site: the page comes from elsewhere"}; tables: ${tables}; new names ${a.closed ? "closed" : "open"}`);
});

/** A count of the settings: a whole number 0 or more, else the default. */
function count(v: string | undefined, dflt: number): number {
  const n = Number(v);
  return v != null && v !== "" && Number.isInteger(n) && n >= 0 ? n : dflt;
}
