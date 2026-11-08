// Service worker (bundled to dist/sw.js). It answers requests for the original
// hosts (http://www.9aola.com/…, or https:// on an https page) from the game
// files served next to the page, so the SWFs see their real URLs: domain
// checks pass with no hosts-file edit and no network. Requests for other
// sites (百田's statistics, video and picture hosts the 2013 client names) are
// answered as missing: nothing goes out but to the page's own origin and to a
// shared server's API (/__api/…: the page's 存档, 改名字 and 改密码, on the server
// the start screen named, which may be another site: the split setup).
//
// Static hosting (GitHub Pages, any file server): the build writes the files
// under files/ with "%" in their names turned into "~" and lists them in
// files/index.json, so each request is one fetch and misses cost nothing. An
// exported mod has a build (?build=…, from config.js): the list and the files
// are asked for with it (…?v=<build>), so a browser that kept an earlier
// export's copies, which the host may call unchanged (the export's files all
// carry the same date), takes the new ones.
// Without an index (the Node server's roots), each root is tried in turn and
// the server's emulated HTTP endpoints are the last resort.

import { contentType, staticName, urlToRelpath, withoutQuery } from "../core/mirrorPath.ts";

// Minimal service-worker typings (lib "webworker" clashes with lib "dom").
interface FetchEvt extends Event {
  readonly request: Request;
  respondWith(r: Promise<Response> | Response): void;
}
interface ExtendableEvt extends Event {
  waitUntil(p: Promise<unknown>): void;
}
declare const self: {
  readonly location: Location;
  skipWaiting(): Promise<void>;
  readonly clients: { claim(): Promise<void> };
  addEventListener(type: "install", fn: (e: ExtendableEvt) => void): void;
  addEventListener(type: "activate", fn: (e: ExtendableEvt) => void): void;
  addEventListener(type: "fetch", fn: (e: FetchEvt) => void): void;
  addEventListener(type: "message", fn: (e: ExtendableEvt & { data: unknown }) => void): void;
};

const params = new URL(self.location.href).searchParams;
const HOSTS = new Set((params.get("hosts") ?? "www.9aola.com,web.9aola.com,login.9aola.com,service.9aola.com,aola.100bt.com,www.100bt.com,service-aola.100bt.com").split(","));
// Roots searched in order, e.g. "../rebuilt/,../mirror/,../supplement/".
const ROOTS = (params.get("mirror") ?? "./mirror/").split(",").filter(Boolean).map((r) => new URL(r, self.location.href).href);
const ORIGINAL = new URL("./__original", self.location.href).href;
const INDEX = params.get("index") ? new URL(params.get("index")!, self.location.href).href : "";
const BUILD = params.get("build") ?? "";
/** Added to what is fetched from the static files: this build's own copy. */
const VERSION = BUILD ? `?v=${encodeURIComponent(BUILD)}` : "";
let listed: Promise<Set<string> | null> | null = null;
/** The files the static build put up (relpaths as the mirror names them), or null without an index. */
function index(): Promise<Set<string> | null> {
  listed ??= INDEX
    ? fetch(INDEX + VERSION)
        .then((r) => (r.ok ? r.json() : null))
        .then((l: string[] | null) => (l ? new Set(l) : null))
        .catch(() => null)
    : Promise.resolve(null);
  return listed;
}

self.addEventListener("install", () => void self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));
// A page loaded with a forced reload (Ctrl+Shift+R) is not served by the worker, which is
// already active and does not activate again: the page asks it to take it over (boot.js).
self.addEventListener("message", (e) => {
  if (e.data === "aola-claim") e.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);
  if (HOSTS.has(url.hostname)) {
    event.respondWith(fromMirror(event.request));
    return;
  }
  // Nothing goes out to other sites (百田's statistics, video and picture hosts the
  // 2013 client names): only the page's own origin is fetched, and a shared server's API
  // (saves.js, start.js), which the 2013 client never asks for.
  if (url.pathname.startsWith("/__api/")) return;
  if (url.origin !== self.location.origin && /^https?:$/.test(url.protocol)) event.respondWith(missing(event.request.url));
});

/** Mirror file names are already percent-encoded; escape "%" once more for HTTP. */
const fileUrl = (root: string, rel: string) => root + rel.replace(/%/g, "%25");

function respond(res: Response, rel: string): Response {
  const headers = new Headers(res.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  // Static hosts cannot tell the type of "x.js%3F2012": give it from the name.
  headers.set("Content-Type", contentType(rel));
  return new Response(res.body, { status: res.status, headers });
}

const CROSSDOMAIN = '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>';
const missing = (url: string) => {
  console.warn("[aola-sw] not in mirror:", url);
  return new Response(`not in mirror: ${url}\n`, { status: 404, headers: { "Access-Control-Allow-Origin": "*" } });
};

async function fromMirror(req: Request): Promise<Response> {
  const rel = urlToRelpath(req.url);
  const files = await index();
  if (files) {
    const hit = [rel, withoutQuery(rel)].find((c) => files.has(c));
    if (hit) {
      // A request for part of the file (Range, as media players ask): pass that on, the static host answers 206.
      const range = req.headers.get("Range");
      const res = await fetch(ROOTS[0] + encodeURI(staticName(hit)) + VERSION, range ? { headers: { Range: range } } : undefined).catch(() => null);
      if (res?.ok) return respond(res, hit);
    }
    if (withoutQuery(rel).endsWith("/crossdomain.xml")) {
      return new Response(CROSSDOMAIN, { headers: { "Content-Type": "text/xml", "Access-Control-Allow-Origin": "*" } });
    }
    return missing(req.url);
  }
  for (const root of ROOTS) {
    for (const candidate of new Set([rel, withoutQuery(rel)])) {
      const res = await fetch(fileUrl(root, candidate)).catch(() => null);
      if (res?.ok) return respond(res, candidate);
    }
  }
  const body = req.method === "GET" || req.method === "HEAD" ? undefined : await req.arrayBuffer();
  const fallback = await fetch(`${ORIGINAL}?url=${encodeURIComponent(req.url)}`, {
    method: req.method,
    headers: req.headers,
    body,
  }).catch(() => null);
  if (fallback && fallback.status !== 404) {
    const headers = new Headers(fallback.headers);
    headers.set("Access-Control-Allow-Origin", "*");
    return new Response(fallback.body, { status: fallback.status, headers });
  }
  return missing(req.url);
}
