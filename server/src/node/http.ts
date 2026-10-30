// HTTP side of the revival: answers requests for aola.100bt.com (and other
// original hosts) from the frozen mirror, serves the browser front end, and
// logs every URL it cannot answer (the HTTP half of "listen mode").
//
// Three ways requests arrive, all handled here:
//   1. hosts-file mode   Host: aola.100bt.com            -> mirror lookup
//   2. proxy mode        GET http://aola.100bt.com/x     -> mirror lookup
//   3. local front end   Host: localhost / 127.0.0.1    -> web/ and /mirror/

import { createReadStream, promises as fs } from "node:fs";
import http from "node:http";
import path from "node:path";
import { CROSSDOMAIN_XML } from "../core/policy.ts";
import { contentType, normalizeUrl, urlToRelpath, withoutQuery } from "../core/mirrorPath.ts";

export interface DynamicRequest {
  url: string;
  method: string;
  headers: http.IncomingHttpHeaders;
  body: Buffer;
}

export interface DynamicResponse {
  status?: number;
  headers?: Record<string, string>;
  body: string | Uint8Array;
}

/** Emulated server-side pages (login, .jsp services). Key: "host/path" without query. */
export type DynamicHandler = (req: DynamicRequest) => DynamicResponse | Promise<DynamicResponse>;

export interface MirrorServerOptions {
  /** One root, or several searched in order (e.g. rebuilt/, mirror/, supplement/). */
  mirrorDir: string | string[];
  webDir?: string;
  /** Host names that mean "the front end" rather than an original site. */
  localNames?: string[];
  dynamic?: Map<string, DynamicHandler>;
  onMiss?: (rec: { t: string; url: string; method: string; referer?: string }) => void;
  log?: (line: string) => void;
}

const DEFAULT_LOCAL = ["localhost", "127.0.0.1", "[::1]", "0.0.0.0"];

function inside(root: string, rel: string): string | null {
  const full = path.resolve(root, rel);
  return full === path.resolve(root) || full.startsWith(path.resolve(root) + path.sep) ? full : null;
}

async function isFile(p: string | null): Promise<boolean> {
  if (!p) return false;
  try {
    return (await fs.stat(p)).isFile();
  } catch {
    return false;
  }
}

async function readBody(req: http.IncomingMessage): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  return Buffer.concat(chunks);
}

export function createMirrorServer(opts: MirrorServerOptions): http.Server {
  const local = new Set(opts.localNames ?? DEFAULT_LOCAL);
  const roots = (Array.isArray(opts.mirrorDir) ? opts.mirrorDir : [opts.mirrorDir]).map((r) => path.resolve(r));
  const rootNames = new Map(roots.map((r) => [path.basename(r), r]));
  /** First root holding rel (or its query-less form). */
  async function find(rel: string, only?: string): Promise<{ file: string; rel: string; root: string } | null> {
    for (const root of only ? [only] : roots) {
      for (const candidate of [rel, withoutQuery(rel)]) {
        const file = inside(root, candidate);
        if (await isFile(file)) return { file: file!, rel: candidate, root: path.basename(root) };
      }
    }
    return null;
  }
  const log = opts.log ?? (() => {});

  async function sendFile(res: http.ServerResponse, file: string, rel: string, head: boolean): Promise<void> {
    const st = await fs.stat(file);
    res.writeHead(200, {
      "Content-Type": contentType(rel),
      "Content-Length": st.size,
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "no-cache",
    });
    if (head) res.end();
    else createReadStream(file).pipe(res);
  }

  async function serveOriginal(req: http.IncomingMessage, res: http.ServerResponse, url: string): Promise<void> {
    const head = req.method === "HEAD";
    const rel = urlToRelpath(url);
    const hit = await find(rel);
    if (hit) {
      log(`200 ${url} <- ${hit.root}`);
      return sendFile(res, hit.file, hit.rel, head);
    }
    const key = withoutQuery(rel);
    const dyn = opts.dynamic?.get(key);
    if (dyn) {
      const out = await dyn({ url, method: req.method ?? "GET", headers: req.headers, body: await readBody(req) });
      res.writeHead(out.status ?? 200, { "Access-Control-Allow-Origin": "*", ...out.headers });
      res.end(out.body);
      log(`${out.status ?? 200} ${url} (emulated)`);
      return;
    }
    if (key.endsWith("/crossdomain.xml")) {
      res.writeHead(200, { "Content-Type": "text/xml" });
      res.end(CROSSDOMAIN_XML);
      log(`200 ${url} (synthesized crossdomain.xml)`);
      return;
    }
    opts.onMiss?.({ t: new Date().toISOString(), url, method: req.method ?? "GET", referer: req.headers.referer });
    log(`404 ${url}`);
    res.writeHead(404, { "Content-Type": "text/plain", "Access-Control-Allow-Origin": "*" });
    res.end(`not in mirror: ${url}\n`);
  }

  async function serveLocal(req: http.IncomingMessage, res: http.ServerResponse, pathname: string): Promise<void> {
    const head = req.method === "HEAD";
    if (pathname.startsWith("/web/")) pathname = pathname.slice(4);
    const m = /^\/([\w.-]+)\/(.+)$/.exec(pathname);
    if (m && rootNames.has(m[1])) {
      // Plain static view of one root (what the service worker reads).
      const rel = decodeURIComponent(m[2]);
      const hit = await find(rel, rootNames.get(m[1]));
      if (hit) {
        log(`200 ${m[1]}/${hit.rel}`);
        return sendFile(res, hit.file, hit.rel, head);
      }
      log(`404 ${m[1]}/${rel}`);
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("not here\n");
      return;
    }
    if (pathname === "/__original") {
      // Service-worker fallback: emulated endpoints and the miss log.
      const target = new URLSearchParams(req.url?.split("?")[1] ?? "").get("url");
      if (target) return serveOriginal(req, res, normalizeUrl(target));
    }
    if (!opts.webDir) {
      res.writeHead(404);
      res.end();
      return;
    }
    let rel = decodeURIComponent(pathname).replace(/^\/+/, "");
    if (rel === "" || rel.endsWith("/")) rel += "index.html";
    const file = inside(opts.webDir, rel);
    if (await isFile(file)) return sendFile(res, file!, rel, head);
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("not found\n");
  }

  return http.createServer((req, res) => {
    const raw = req.url ?? "/";
    let task: Promise<void>;
    if (/^https?:\/\//i.test(raw)) {
      task = serveOriginal(req, res, normalizeUrl(raw)); // proxy mode
    } else {
      const host = (req.headers.host ?? "localhost").toLowerCase();
      const hostname = host.startsWith("[") ? host.slice(0, host.indexOf("]") + 1) : host.split(":")[0];
      const pathname = raw.split("?")[0];
      task = local.has(hostname)
        ? serveLocal(req, res, pathname)
        : serveOriginal(req, res, normalizeUrl(`http://${host}${raw}`));
    }
    task.catch((e: unknown) => {
      log(`500 ${raw}: ${(e as Error).message}`);
      if (!res.headersSent) res.writeHead(500);
      res.end();
    });
  });
}
