"use strict";
(() => {
  // server/src/core/mirrorPath.ts
  var SAFE_PATH = "/-_.~!$'()+,;=@";
  var SAFE_QUERY = "-_.~=&";
  var QUERY_MARK = "%3F";
  var encoder = new TextEncoder();
  var decoder = new TextDecoder("utf-8", { fatal: false });
  function isUnreserved(b) {
    return b >= 48 && b <= 57 || b >= 65 && b <= 90 || b >= 97 && b <= 122 || b === 95 || b === 46 || b === 45 || b === 126;
  }
  function quote(s, safe) {
    let out = "";
    for (const b of encoder.encode(s)) {
      const c = String.fromCharCode(b);
      out += isUnreserved(b) || b < 128 && safe.includes(c) ? c : "%" + b.toString(16).toUpperCase().padStart(2, "0");
    }
    return out;
  }
  function unquote(s) {
    if (!s.includes("%")) return s;
    let out = "";
    let i = 0;
    while (i < s.length) {
      if (s[i] === "%" && /^[0-9a-fA-F]{2}$/.test(s.slice(i + 1, i + 3))) {
        const bytes = [];
        while (s[i] === "%" && /^[0-9a-fA-F]{2}$/.test(s.slice(i + 1, i + 3))) {
          bytes.push(parseInt(s.slice(i + 1, i + 3), 16));
          i += 3;
        }
        out += decoder.decode(new Uint8Array(bytes));
      } else {
        out += s[i++];
      }
    }
    return out;
  }
  function split(url) {
    if (!url.includes("://")) url = "http://" + url;
    const m = /^([a-zA-Z][a-zA-Z0-9+.-]*):\/\/([^/?#]*)([^?#]*)(?:\?([^#]*))?/.exec(url);
    if (!m) throw new Error(`not a URL: ${url}`);
    const [, scheme, netloc, path, query = ""] = m;
    const hostport = netloc.includes("@") ? netloc.slice(netloc.lastIndexOf("@") + 1) : netloc;
    const pm = /^(\[[^\]]*\]|[^:]*)(?::(\d*))?$/.exec(hostport);
    const host = (pm?.[1] ?? hostport).toLowerCase();
    const port = pm?.[2] ? Number(pm[2]) : null;
    return { scheme: scheme.toLowerCase(), host, port, path, query };
  }
  function normpath(p) {
    const out = [];
    for (const seg of p.split("/")) {
      if (seg === "" || seg === ".") continue;
      if (seg === "..") out.pop();
      else out.push(seg);
    }
    return "/" + out.join("/");
  }
  function cleanPath(raw) {
    let path = unquote(raw || "/");
    const trailing = path.endsWith("/");
    path = normpath(path.replace(/\\/g, "/"));
    if (trailing && !path.endsWith("/")) path += "/";
    return quote(path, SAFE_PATH);
  }
  function normalizeUrl(url) {
    const u = split(url);
    let host = u.host;
    if (u.port && !(u.scheme === "http" && u.port === 80 || u.scheme === "https" && u.port === 443)) {
      host += `:${u.port}`;
    }
    let out = `http://${host}${cleanPath(u.path)}`;
    if (u.query) out += "?" + u.query;
    return out;
  }
  function urlToRelpath(url) {
    const u = split(normalizeUrl(url));
    const host = u.port ? `${u.host}_${u.port}` : u.host;
    let path = u.path;
    if (path.endsWith("/")) path += "index.html";
    let rel = host + path;
    if (u.query) rel += QUERY_MARK + quote(u.query, SAFE_QUERY);
    return rel;
  }
  function staticName(relpath) {
    return relpath.replace(/%/g, "~");
  }
  function withoutQuery(relpath) {
    const i = relpath.indexOf(QUERY_MARK);
    return i < 0 ? relpath : relpath.slice(0, i);
  }
  var TYPES = {
    swf: "application/x-shockwave-flash",
    xml: "text/xml; charset=utf-8",
    html: "text/html; charset=utf-8",
    htm: "text/html; charset=utf-8",
    js: "text/javascript; charset=utf-8",
    mjs: "text/javascript; charset=utf-8",
    css: "text/css; charset=utf-8",
    json: "application/json; charset=utf-8",
    txt: "text/plain; charset=utf-8",
    png: "image/png",
    jpg: "image/jpeg",
    jpeg: "image/jpeg",
    gif: "image/gif",
    mp3: "audio/mpeg",
    wav: "audio/wav",
    flv: "video/x-flv",
    mp4: "video/mp4",
    webm: "video/webm",
    wasm: "application/wasm",
    ico: "image/x-icon"
  };
  function contentType(relpath) {
    const name = withoutQuery(relpath);
    const ext = name.slice(name.lastIndexOf(".") + 1).toLowerCase();
    return TYPES[ext] ?? "application/octet-stream";
  }

  // server/src/browser/sw.ts
  var params = new URL(self.location.href).searchParams;
  var HOSTS = new Set((params.get("hosts") ?? "www.9aola.com,web.9aola.com,login.9aola.com,service.9aola.com,aola.100bt.com,www.100bt.com,service-aola.100bt.com").split(","));
  var ROOTS = (params.get("mirror") ?? "./mirror/").split(",").filter(Boolean).map((r) => new URL(r, self.location.href).href);
  var ORIGINAL = new URL("./__original", self.location.href).href;
  var INDEX = params.get("index") ? new URL(params.get("index"), self.location.href).href : "";
  var listed = null;
  function index() {
    listed ??= INDEX ? fetch(INDEX).then((r) => r.ok ? r.json() : null).then((l) => l ? new Set(l) : null).catch(() => null) : Promise.resolve(null);
    return listed;
  }
  self.addEventListener("install", () => void self.skipWaiting());
  self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));
  self.addEventListener("message", (e) => {
    if (e.data === "aola-claim") e.waitUntil(self.clients.claim());
  });
  self.addEventListener("fetch", (event) => {
    const url = new URL(event.request.url);
    if (HOSTS.has(url.hostname)) {
      event.respondWith(fromMirror(event.request));
      return;
    }
    if (url.pathname.startsWith("/__api/")) return;
    if (url.origin !== self.location.origin && /^https?:$/.test(url.protocol)) event.respondWith(missing(event.request.url));
  });
  var fileUrl = (root, rel) => root + rel.replace(/%/g, "%25");
  function respond(res, rel) {
    const headers = new Headers(res.headers);
    headers.set("Access-Control-Allow-Origin", "*");
    headers.set("Content-Type", contentType(rel));
    return new Response(res.body, { status: res.status, headers });
  }
  var CROSSDOMAIN = '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>';
  var missing = (url) => {
    console.warn("[aola-sw] not in mirror:", url);
    return new Response(`not in mirror: ${url}
`, { status: 404, headers: { "Access-Control-Allow-Origin": "*" } });
  };
  async function fromMirror(req) {
    const rel = urlToRelpath(req.url);
    const files = await index();
    if (files) {
      const hit = [rel, withoutQuery(rel)].find((c) => files.has(c));
      if (hit) {
        const range = req.headers.get("Range");
        const res = await fetch(ROOTS[0] + encodeURI(staticName(hit)), range ? { headers: { Range: range } } : void 0).catch(() => null);
        if (res?.ok) return respond(res, hit);
      }
      if (withoutQuery(rel).endsWith("/crossdomain.xml")) {
        return new Response(CROSSDOMAIN, { headers: { "Content-Type": "text/xml", "Access-Control-Allow-Origin": "*" } });
      }
      return missing(req.url);
    }
    for (const root of ROOTS) {
      for (const candidate of /* @__PURE__ */ new Set([rel, withoutQuery(rel)])) {
        const res = await fetch(fileUrl(root, candidate)).catch(() => null);
        if (res?.ok) return respond(res, candidate);
      }
    }
    const body = req.method === "GET" || req.method === "HEAD" ? void 0 : await req.arrayBuffer();
    const fallback = await fetch(`${ORIGINAL}?url=${encodeURIComponent(req.url)}`, {
      method: req.method,
      headers: req.headers,
      body
    }).catch(() => null);
    if (fallback && fallback.status !== 404) {
      const headers = new Headers(fallback.headers);
      headers.set("Access-Control-Allow-Origin", "*");
      return new Response(fallback.body, { status: fallback.status, headers });
    }
    return missing(req.url);
  }
})();
