// The shared (multiplayer) server on Cloudflare: a Worker in front, one Durable Object for the
// game (every 奥拉 in one world, as the Node server src/node/multi.ts has them in one process),
// and the built site (npm run build's dist/) as the Worker's static assets.
//
//   /__socket/9339   the game (WebSocket), handed to the Durable Object
//   /__api/…          the start screen's 改名字, the 存档 and the status (src/game/sfs2013/api.ts)
//   everything else   the static site (the ASSETS binding), when the Worker serves it
//
// Two ways to deploy (docs/MULTIPLAYER.md): the whole site on the Worker (wrangler.example.toml,
// the ASSETS binding), or the site on a static host and only the game here
// (wrangler.split.example.toml: no ASSETS; the game's tables are read from AOLA_TABLES_URL, the
// site's address). The saves are the Durable Object's storage (SQLite-backed: one value may be
// up to 2 MB).
// The game code is the same as on Node (src/game/sfs2013/host.ts); only this file knows of
// Cloudflare, and it declares the little of its runtime it uses (no @cloudflare/workers-types).

import type { Store } from "../core/store.ts";
import { NullRecorder } from "../core/recorder.ts";
import { apiBodyMax, handleApi } from "../game/sfs2013/api.ts";
import { createGameHost, type GameHost } from "../game/sfs2013/host.ts";
import { addrKey } from "../core/addr.ts";

// ---------------------------------------------------------------- the runtime, as used here

interface DurableObjectStorage {
  get<T>(key: string): Promise<T | undefined>;
  put<T>(key: string, value: T): Promise<void>;
  delete(key: string): Promise<boolean>;
  list<T>(options?: { prefix?: string }): Promise<Map<string, T>>;
}
interface DurableObjectState {
  storage: DurableObjectStorage;
}
interface DurableObjectId {}
interface DurableObjectStub {
  fetch(req: Request): Promise<Response>;
}
interface DurableObjectNamespace {
  idFromName(name: string): DurableObjectId;
  get(id: DurableObjectId): DurableObjectStub;
}
interface Fetcher {
  fetch(req: Request | string): Promise<Response>;
}
/** A Worker WebSocket: accept() takes it on; its events are those of a browser WebSocket. */
interface WorkerSocket extends WebSocket {
  accept(): void;
}
declare const WebSocketPair: { new (): { 0: WorkerSocket; 1: WorkerSocket } };

export interface Env {
  GAME: DurableObjectNamespace;
  /** The built site (dist/), when the Worker serves it; none in the split setup. */
  ASSETS?: Fetcher;
  /**
   * The split setup: where the site is (its address, "https://aola.example.netlify.app"), for
   * the game's tables (<site>/files/www.9aola.com/revival/*.json). Without ASSETS, required.
   */
  AOLA_TABLES_URL?: string;
  /** "1": no new names, only 奥拉 the server has may log in. */
  AOLA_CLOSED?: string;
  /** The game clock starts at this day (China time) at each start, for trying a day of the era; default: the real time. */
  AOLA_DATE?: string;
  /** At most this many in the game at once (default 200). */
  AOLA_MAX_PLAYERS?: string;
  /** New 奥拉 one address may 注册 a day (default 5; "0": no limit). */
  AOLA_SIGNUPS_PER_DAY?: string;
  /** "1": a save without a password takes the password of its first login. */
  AOLA_ADOPT?: string;
  /** "0": the 工具箱, mods' gifts and 导入存档 closed to the players (open by default). */
  AOLA_TOOLBOX?: string;
}

// ---------------------------------------------------------------- the Worker

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const api = url.pathname.startsWith("/__api/");
    if (url.pathname.startsWith("/__socket/") || api) {
      // Neither the site here nor its address: the game would have no tables.
      if (!env.ASSETS && !env.AOLA_TABLES_URL) return apiError(api, 500, "AOLA_TABLES_URL is not set (wrangler.toml): the game has no tables");
      // One world: every connection and request to the same Durable Object.
      try {
        return await env.GAME.get(env.GAME.idFromName("world")).fetch(req);
      } catch {
        // (A page on another site sees an answer without CORS headers as no answer at all.)
        return apiError(api, 503, "the game is not reachable now");
      }
    }
    if (!env.ASSETS) return new Response("this server has only the game: open the page on its own site and give it this address\n", { status: 404 });
    return env.ASSETS.fetch(req);
  },
};

// ---------------------------------------------------------------- the game

/** The Store of the game over a Durable Object's storage (values are kept as they are given). */
export class DurableStore implements Store {
  private readonly storage: DurableObjectStorage;
  constructor(storage: DurableObjectStorage) {
    this.storage = storage;
  }
  async get<T>(key: string): Promise<T | undefined> {
    // A copy, as from the file store: the live records are LiveRecordStore's (host.ts).
    const v = await this.storage.get<string>(key);
    return v === undefined ? undefined : (JSON.parse(v) as T);
  }
  async set<T>(key: string, value: T): Promise<void> {
    await this.storage.put(key, JSON.stringify(value));
  }
  async setText(key: string, json: string): Promise<void> {
    await this.storage.put(key, json);
  }
  async delete(key: string): Promise<void> {
    await this.storage.delete(key);
  }
  async keys(prefix = ""): Promise<string[]> {
    return [...(await this.storage.list({ prefix })).keys()].sort();
  }
}

const JSON_HEADERS = { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "Content-Type" };

/** A failure: JSON with the CORS headers for the API (the page reads its error), plain text otherwise. */
function apiError(api: boolean, status: number, text: string): Response {
  return api
    ? new Response(JSON.stringify({ ok: false, error: "服务器出错了，请稍后再试。" }), { status, headers: JSON_HEADERS })
    : new Response(text + "\n", { status });
}

/** How long a table may take to come from the site (the split setup), at most. */
const TABLE_FETCH_MS = 20_000;

export class AolaGame {
  private readonly host: GameHost;
  private readonly maxPlayers: number;

  constructor(state: DurableObjectState, env: Env) {
    this.maxPlayers = Number(env.AOLA_MAX_PLAYERS) || 200;
    this.host = createGameHost({
      store: new DurableStore(state.storage),
      // The tables the game reads (www.9aola.com/revival/*.json): the site's files, served here
      // (ASSETS) or elsewhere (AOLA_TABLES_URL: the split setup).
      loadJson: async (p) => {
        const site = (env.AOLA_TABLES_URL ?? "").replace(/\/+$/, "");
        const res = env.ASSETS
          ? await env.ASSETS.fetch(new Request(`https://assets.local/files/www.9aola.com/${p}`))
          : site
            ? await fetch(`${site}/files/www.9aola.com/${p}`, { signal: AbortSignal.timeout(TABLE_FETCH_MS) })
            : undefined;
        return res?.ok ? res.json() : undefined;
      },
      date: env.AOLA_DATE || undefined,
      accounts: { required: true, register: env.AOLA_CLOSED !== "1", adopt: env.AOLA_ADOPT === "1", signupsPerDay: count(env.AOLA_SIGNUPS_PER_DAY, 5) },
      recorder: new NullRecorder(),
      toolbox: env.AOLA_TOOLBOX !== "0",
      maxPlayers: this.maxPlayers,
    });
  }

  async fetch(req: Request): Promise<Response> {
    const url = new URL(req.url);
    if (url.pathname.startsWith("/__api/")) {
      // The limit is in bytes (a body of Chinese text is three bytes a character).
      // Read only up to the limit: the one object holds every player, and a body read whole
      // first could fill its memory.
      const bytes = req.method === "POST" ? await readCapped(req, apiBodyMax(url.pathname)) : new Uint8Array();
      if (bytes == null) {
        return new Response(JSON.stringify({ ok: false, error: "这个存档太大了。" }), { status: 413, headers: JSON_HEADERS });
      }
      const addr = clientAddr(req);
      try {
        const out = await handleApi(this.host, url.pathname, req.method, new TextDecoder().decode(bytes), addr);
        return new Response(out.status === 204 ? null : JSON.stringify(out.body), { status: out.status, headers: JSON_HEADERS });
      } catch (e) {
        console.error("[aola] api", url.pathname, e);
        return apiError(true, 500, "");
      }
    }
    const m = /^\/__socket\/(\d+)/.exec(url.pathname);
    if (!m || req.headers.get("Upgrade")?.toLowerCase() !== "websocket") return new Response("not found\n", { status: 404 });
    // The connections not logged in, of the server and of the address, and the address's in all
    // (host.ts admit); the game's places are counted at the login (AOLA_MAX_PLAYERS).
    const remote = clientAddr(req);
    const no = this.host.admit(remote);
    if (no === "full") return new Response("the server is full\n", { status: 503 });
    if (no) return new Response("too many connections\n", { status: 429 });
    const pair = new WebSocketPair();
    const [client, ws] = [pair[0], pair[1]];
    ws.accept();
    ws.binaryType = "arraybuffer";
    const session = this.host.attach(
      // The emulator's bytes are of an ArrayBuffer of their own (never shared), as ws.send asks.
      { remote, send: (b) => ws.send(b as Uint8Array<ArrayBuffer>), close: () => ws.close() },
      Number(m[1]),
    );
    ws.addEventListener("message", (e: MessageEvent) => {
      const d = e.data;
      session.receive(typeof d === "string" ? new TextEncoder().encode(d) : new Uint8Array(d as ArrayBuffer));
    });
    const gone = () => this.host.detach(session);
    ws.addEventListener("close", gone);
    ws.addEventListener("error", gone);
    return new Response(null, { status: 101, webSocket: client } as ResponseInit);
  }
}

/** The client's address as the limits count it (Cloudflare's header: an IPv6 one by its /64). */
const clientAddr = (req: Request) => `ws ${addrKey(req.headers.get("CF-Connecting-IP") ?? "?")}`;

/** A request's body, or null when it is longer than max (read no further than that). */
async function readCapped(req: Request, max: number): Promise<Uint8Array | null> {
  const said = Number(req.headers.get("Content-Length") ?? "");
  if (Number.isFinite(said) && said > max) return null;
  if (!req.body) return new Uint8Array();
  const reader = req.body.getReader();
  const parts: Uint8Array[] = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > max) {
      await reader.cancel().catch(() => {});
      return null;
    }
    parts.push(value);
  }
  const out = new Uint8Array(size);
  let at = 0;
  for (const p of parts) {
    out.set(p, at);
    at += p.length;
  }
  return out;
}

/** A count of the settings: a whole number 0 or more, else the default. */
function count(v: string | undefined, dflt: number): number {
  const n = Number(v);
  return v != null && v !== "" && Number.isInteger(n) && n >= 0 ? n : dflt;
}
