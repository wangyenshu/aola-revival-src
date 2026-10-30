// TypeScript twin of tools/mirrorpath.py: original URL -> path inside mirror/.
// Both sides are checked against tests/mirrorpath-fixtures.json.
// Deliberately not using WHATWG URL, which re-encodes paths differently from
// Python's urllib and would make the two sides disagree.

const SAFE_PATH = "/-_.~!$'()+,;=@";
const SAFE_QUERY = "-_.~=&";
export const QUERY_MARK = "%3F";

const encoder = new TextEncoder();
const decoder = new TextDecoder("utf-8", { fatal: false });

function isUnreserved(b: number): boolean {
  return (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5a) || (b >= 0x61 && b <= 0x7a) || b === 0x5f || b === 0x2e || b === 0x2d || b === 0x7e;
}

/** Same result as Python's urllib.parse.quote(s, safe). */
export function quote(s: string, safe: string): string {
  let out = "";
  for (const b of encoder.encode(s)) {
    const c = String.fromCharCode(b);
    out += isUnreserved(b) || (b < 0x80 && safe.includes(c)) ? c : "%" + b.toString(16).toUpperCase().padStart(2, "0");
  }
  return out;
}

/** Same result as Python's urllib.parse.unquote(s) (UTF-8, errors replaced). */
export function unquote(s: string): string {
  if (!s.includes("%")) return s;
  let out = "";
  let i = 0;
  while (i < s.length) {
    if (s[i] === "%" && /^[0-9a-fA-F]{2}$/.test(s.slice(i + 1, i + 3))) {
      const bytes: number[] = [];
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

interface Split {
  scheme: string;
  host: string;
  port: number | null;
  path: string;
  query: string;
}

function split(url: string): Split {
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

function normpath(p: string): string {
  const out: string[] = [];
  for (const seg of p.split("/")) {
    if (seg === "" || seg === ".") continue;
    if (seg === "..") out.pop();
    else out.push(seg);
  }
  return "/" + out.join("/");
}

function cleanPath(raw: string): string {
  let path = unquote(raw || "/");
  const trailing = path.endsWith("/");
  path = normpath(path.replace(/\\/g, "/"));
  if (trailing && !path.endsWith("/")) path += "/";
  return quote(path, SAFE_PATH);
}

/** Canonical URL used as the key everywhere (always http://, default port dropped). */
export function normalizeUrl(url: string): string {
  const u = split(url);
  let host = u.host;
  if (u.port && !((u.scheme === "http" && u.port === 80) || (u.scheme === "https" && u.port === 443))) {
    host += `:${u.port}`;
  }
  let out = `http://${host}${cleanPath(u.path)}`;
  if (u.query) out += "?" + u.query;
  return out;
}

/** Relative file path inside the mirror root. */
export function urlToRelpath(url: string): string {
  const u = split(normalizeUrl(url));
  const host = u.port ? `${u.host}_${u.port}` : u.host;
  let path = u.path;
  if (path.endsWith("/")) path += "index.html";
  let rel = host + path;
  if (u.query) rel += QUERY_MARK + quote(u.query, SAFE_QUERY);
  return rel;
}

/**
 * The name a mirror file gets in the static build (dist/files/): "%" turned
 * into "~", so names are plain on any static host (the build checks that no
 * two names meet).
 */
export function staticName(relpath: string): string {
  return relpath.replace(/%/g, "~");
}

export function withoutQuery(relpath: string): string {
  const i = relpath.indexOf(QUERY_MARK);
  return i < 0 ? relpath : relpath.slice(0, i);
}

const TYPES: Record<string, string> = {
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
  ico: "image/x-icon",
};

export function contentType(relpath: string): string {
  const name = withoutQuery(relpath);
  const ext = name.slice(name.lastIndexOf(".") + 1).toLowerCase();
  return TYPES[ext] ?? "application/octet-stream";
}
