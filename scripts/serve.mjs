// Serve dist/ the way a static host does, to try the built site locally.
//
//   node scripts/serve.mjs [--dir dist] [--port 8080] [--base /] [--bind 127.0.0.1]
//                          [--cert cert.pem --key key.pem]
//
// Then open http://127.0.0.1:8080/ (service workers need http://localhost,
// 127.0.0.1 or https). --base /aola-revival/ serves the site under a sub-path
// as GitHub Pages does for a project site; --cert/--key serve https.

import { createReadStream, readFileSync, statSync } from "node:fs";
import http from "node:http";
import https from "node:https";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const { values: a } = parseArgs({
  options: {
    dir: { type: "string", default: path.join(root, "dist") },
    port: { type: "string", default: "8080" },
    bind: { type: "string", default: "127.0.0.1" },
    base: { type: "string", default: "/" },
    cert: { type: "string" },
    key: { type: "string" },
  },
});
const dir = path.resolve(a.dir);
const base = ("/" + a.base.replace(/^\/+|\/+$/g, "") + "/").replace("//", "/");
const TYPES = {
  html: "text/html; charset=utf-8",
  js: "text/javascript; charset=utf-8",
  json: "application/json; charset=utf-8",
  wasm: "application/wasm",
  css: "text/css; charset=utf-8",
  png: "image/png",
  svg: "image/svg+xml",
};

function handle(req, res) {
  let p;
  try {
    p = decodeURIComponent(new URL(req.url, "http://x").pathname);
  } catch {
    res.writeHead(400).end();
    return;
  }
  if (!p.startsWith(base)) {
    res.writeHead(302, { Location: base }).end();
    return;
  }
  let rel = p.slice(base.length);
  if (rel === "" || rel.endsWith("/")) rel += "index.html";
  const file = path.join(dir, ...rel.split("/"));
  if (!file.startsWith(dir + path.sep)) {
    res.writeHead(403).end();
    return;
  }
  let st;
  try {
    st = statSync(file);
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain" }).end("not found\n");
    return;
  }
  if (!st.isFile()) {
    res.writeHead(404).end();
    return;
  }
  const ext = rel.includes(".") ? rel.slice(rel.lastIndexOf(".") + 1).toLowerCase() : "";
  res.writeHead(200, {
    "Content-Type": TYPES[ext] ?? "application/octet-stream",
    "Content-Length": st.size,
    "Cache-Control": "max-age=600",
    "X-Content-Type-Options": "nosniff",
  });
  if (req.method === "HEAD") res.end();
  else createReadStream(file).pipe(res);
}

const server = a.cert ? https.createServer({ cert: readFileSync(a.cert), key: readFileSync(a.key) }, handle) : http.createServer(handle);
server.listen(Number(a.port), a.bind, () => {
  const port = server.address().port;
  console.log(`serving ${path.relative(process.cwd(), dir) || dir} at ${a.cert ? "https" : "http"}://${a.bind}:${port}${base}`);
});
