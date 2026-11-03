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

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const { values: a } = parseArgs({
  options: {
    port: { type: "string", default: process.env.PORT ?? "8080" },
    bind: { type: "string", default: process.env.BIND ?? "0.0.0.0" },
    data: { type: "string", default: process.env.AOLA_DATA ?? path.join(root, "work/server") },
    web: { type: "string", default: process.env.AOLA_WEB ?? path.join(root, "dist") },
    tables: { type: "string", default: process.env.AOLA_TABLES ?? "" },
    date: { type: "string", default: process.env.AOLA_DATE ?? "2012-08-15" },
    closed: { type: "boolean", default: process.env.AOLA_CLOSED === "1" },
    // The 工具箱 is open unless closed (--no-toolbox, or AOLA_TOOLBOX=0); --toolbox opens it
    // whatever AOLA_TOOLBOX says.
    toolbox: { type: "boolean" },
    "no-toolbox": { type: "boolean", default: process.env.AOLA_TOOLBOX === "0" },
    adopt: { type: "boolean", default: process.env.AOLA_ADOPT === "1" },
    "max-players": { type: "string", default: process.env.AOLA_MAX_PLAYERS ?? "200" },
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
  --date DAY        anchor of the game clock, China time (default 2012-08-15)
  --closed          no new names: only 奥拉 the server already has may log in
  --no-toolbox      close the 工具箱 (晶币, 亚比 … for nothing), mods' gifts of 亚比 and 导入存档
                    to the players (a fair server); open by default, as in 单机模式
  --adopt           a save with no password (copied in) takes the password of its first login
  --max-players N   at most N in the game at once (default 200)`);
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
  date: a.date,
  accounts: { required: true, register: !a.closed, adopt: a.adopt },
  recorder: new NullRecorder(),
  toolbox: a.toolbox === true ? true : !a["no-toolbox"],
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
  res.writeHead(200, { "Content-Type": contentType(rel), "Content-Length": st.size, "Cache-Control": rel.startsWith("files/") ? "public, max-age=86400" : "no-cache" });
  if (req.method === "HEAD") return void res.end();
  createReadStream(file).pipe(res);
}

// A last net: an error no request catches (a timer's, a hook's) is logged, and the game goes on
// for everyone else instead of the process ending.
process.on("unhandledRejection", (e) => console.error(`[aola] unhandled: ${(e as Error)?.stack ?? String(e)}`));

const API_HEADERS = { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "Content-Type" };
/** The client's address as its game connection gives it (the password lock's: accounts.ts). */
const clientAddr = (req: http.IncomingMessage) => `ws ${req.headers["x-forwarded-for"] ?? req.socket.remoteAddress}`;

const server = http.createServer((req, res) => {
  const url = new URL(req.url ?? "/", "http://x");
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
  // Every connection counts, logged in or not (a few more than players: pages reconnecting).
  if (host.emulator.sessions.size >= maxPlayers + 20) return void socket.destroy();
  wss.handleUpgrade(req, socket, head, (ws: WebSocket) => {
    const session = host.attach(
      { remote: clientAddr(req), send: (b) => ws.send(b), close: () => ws.close() },
      Number(m[1]),
    );
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
