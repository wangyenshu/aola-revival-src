/*
 * 奥拉星 revival · 沙盒 关卡 packs (format version 2, docs/SANDBOX.md): the level editor's
 * pure logic, with no DOM.
 *
 *   validate(pack, opts)    every problem of a pack (or a version-1 fight list), with where it is
 *   fromV1(v1, opts)        a version-1 fight list as a pack with one 关卡 of one room
 *   normalize / serialize   a file as the editor holds it / as it is written
 *   stringify               the JSON text of a file (compact where it reads better)
 *   sanitizeId, uniqueId, fileName, rename*, mergeInto, imageInfo, encodeIndexedPng …
 *
 * Runs in the page (window.AolaPack) and under Node (require: module.exports).
 */
(function (root, factory) {
  "use strict";
  const api = factory();
  if (typeof module === "object" && module && module.exports) module.exports = api;
  else root.AolaPack = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  const FORMAT = "aola-revival-level";
  /** The format's limits (docs/SANDBOX.md "Limits", docs/sandbox-level.schema.json). */
  const LIMITS = Object.freeze({
    fileBytes: 16000000, // "16 MB a file", read as decimal megabytes (the stricter reading)
    images: 64,
    imageWidth: 2880,
    imageHeight: 560,
    roomHeight: 560,
    roomMinWidth: 960,
    levels: 20,
    rooms: 20,
    doors: 16,
    enemies: 12,
    props: 32,
    spawns: 16,
    team: 10,
    v1Enemies: 10,
    maxLevel: 999,
    pctMin: 1,
    pctMax: 10000,
    nameLength: 30, // pack, 关卡 and room names, author
    labelLength: 20, // door labels
    enemyNameLength: 20,
    idLength: 32,
  });
  const STATS = ["hp", "at", "de", "sa", "sd", "sp"];
  const STAT_NAMES = { hp: "体力", at: "攻击", de: "防御", sa: "特攻", sd: "特防", sp: "速度" };
  const ID_RE = /^[A-Za-z0-9_-]{1,32}$/;
  const TO_RE = /^(#finish|#exit|[A-Za-z0-9_-]{1,32}(\/[A-Za-z0-9_-]{1,32})?)$/;
  const MUSIC_RE = /^music\/[A-Za-z0-9_./-]+\.mp3$/;
  const DATA_HEAD_RE = /^data:image\/(png|jpeg);base64,/;
  const B64_RE = /^[A-Za-z0-9+/=]+$/;

  // ---------------------------------------------------------------- small helpers

  const isObj = (v) => !!v && typeof v === "object" && !Array.isArray(v);
  const isNum = (v) => typeof v === "number" && Number.isFinite(v);
  const isPoint = (v) => Array.isArray(v) && v.length === 2 && v.every(isNum);
  const isRect = (v) => Array.isArray(v) && v.length === 4 && v.every(isNum);
  const isId = (v) => typeof v === "string" && ID_RE.test(v);
  /** Characters as JSON Schema counts them (code points). */
  const textLength = (s) => Array.from(String(s)).length;
  const show = (v) => (v === undefined ? "（没有）" : typeof v === "string" ? JSON.stringify(v) : JSON.stringify(v) ?? String(v));
  const own = (o, k) => Object.prototype.hasOwnProperty.call(o, k);

  /** An id made of what may be in one: ASCII letters, digits, "_" and "-", at most 32. */
  function sanitizeId(s, fallback) {
    const id = String(s ?? "")
      .trim()
      .replace(/\.[A-Za-z0-9]{1,5}$/, "") // a file name's extension
      .replace(/\s+/g, "_")
      .replace(/[^A-Za-z0-9_-]/g, "")
      .slice(0, LIMITS.idLength);
    return /[A-Za-z0-9]/.test(id) ? id : fallback === undefined ? "id" : fallback;
  }

  /** `base` (sanitized), or the first of base2, base3 … (or base-2 …) that is not taken. */
  function uniqueId(base, taken) {
    const has = typeof taken === "function" ? taken : taken instanceof Set ? (s) => taken.has(s) : (s) => (taken || []).includes(s);
    const id = sanitizeId(base, "id");
    if (!has(id)) return id;
    const m = /^(.*?)(\d+)$/.exec(id);
    const stem = m ? m[1] : id + "-";
    for (let n = m ? Number(m[2]) + 1 : 2; ; n++) {
      const tail = String(n);
      const cand = stem.slice(0, LIMITS.idLength - tail.length) + tail;
      if (!has(cand)) return cand;
    }
  }

  /** Why `id` cannot be a new id among `taken` (the old id excepted), or "" when it can. */
  function idProblem(id, taken, old) {
    if (typeof id !== "string" || id === "") return "编号不能是空的";
    if (!ID_RE.test(id)) return "编号只能用英文字母、数字、_ 和 -，最多 32 个";
    if (id !== old && (taken instanceof Set ? taken.has(id) : (taken || []).includes(id))) return `编号 ${id} 已经有了`;
    return "";
  }

  /** The export's file name: aola-levels-<name>.json, the name kept to ASCII letters and digits. */
  function fileName(name) {
    const s = String(name ?? "")
      .replace(/[^A-Za-z0-9]/g, "")
      .slice(0, 40);
    return s ? `aola-levels-${s}.json` : "aola-levels.json";
  }

  /** A door's `to`: {kind: "room", level?, room} | {kind: "finish"} | {kind: "exit"}, or null. */
  function parseTarget(to) {
    if (typeof to !== "string" || !TO_RE.test(to)) return null;
    if (to === "#finish") return { kind: "finish" };
    if (to === "#exit") return { kind: "exit" };
    const i = to.indexOf("/");
    return i < 0 ? { kind: "room", level: null, room: to } : { kind: "room", level: to.slice(0, i), room: to.slice(i + 1) };
  }

  /** The level and room a door of `fromLevel` leads to, or null (not a room, or not there). */
  function resolveTarget(pack, fromLevel, to) {
    const t = parseTarget(to);
    if (!t || t.kind !== "room") return null;
    const level = t.level === null ? fromLevel : (pack.levels || []).find((l) => l && l.id === t.level);
    if (!level || !Array.isArray(level.rooms)) return null;
    const room = level.rooms.find((r) => r && r.id === t.room);
    return room ? { level, room } : null;
  }

  function utf8Length(s) {
    let n = 0;
    for (let i = 0; i < s.length; i++) {
      const c = s.charCodeAt(i);
      if (c < 0x80) n++;
      else if (c < 0x800) n += 2;
      else if (c >= 0xd800 && c < 0xdc00 && i + 1 < s.length) {
        n += 4;
        i++;
      } else n += 3;
    }
    return n;
  }

  // ---------------------------------------------------------------- base64 and pictures

  function b64decode(s) {
    if (typeof atob === "function") {
      const bin = atob(s);
      const out = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
      return out;
    }
    return new Uint8Array(Buffer.from(s, "base64"));
  }

  function b64encode(bytes) {
    if (typeof btoa === "function") {
      let s = "";
      for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
      return btoa(s);
    }
    return Buffer.from(bytes).toString("base64");
  }

  const isPngSig = (b) => b.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47 && b[4] === 0x0d && b[5] === 0x0a && b[6] === 0x1a && b[7] === 0x0a;
  const isJpegSig = (b) => b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff;
  const u32 = (b, i) => ((b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3]) >>> 0;

  function pngSize(b) {
    if (b.length < 24 || String.fromCharCode(b[12], b[13], b[14], b[15]) !== "IHDR") return null;
    return { width: u32(b, 16), height: u32(b, 20) };
  }

  function jpegSize(b) {
    let i = 2;
    while (i + 9 < b.length) {
      if (b[i] !== 0xff) {
        i++;
        continue;
      }
      const mk = b[i + 1];
      if (mk === 0xff) {
        i++;
        continue;
      }
      if (mk === 0xd8 || mk === 0x01 || (mk >= 0xd0 && mk <= 0xd7)) {
        i += 2;
        continue;
      }
      if (mk === 0xd9 || mk === 0xda) return null; // the picture's end or data before any frame header
      if (mk >= 0xc0 && mk <= 0xcf && mk !== 0xc4 && mk !== 0xc8 && mk !== 0xcc) return { height: (b[i + 5] << 8) | b[i + 6], width: (b[i + 7] << 8) | b[i + 8] };
      i += 2 + ((b[i + 2] << 8) | b[i + 3]);
    }
    return null;
  }

  /**
   * What a picture of the pack is: {mime, type, bytes, width, height, mismatch} or {error}.
   * Reads the PNG or JPEG header out of the data: URL; the pixels are not decoded.
   */
  function imageInfo(url) {
    if (typeof url !== "string") return { error: "不是图片（应为 data: 地址的字符串）" };
    const m = DATA_HEAD_RE.exec(url);
    if (!m) {
      if (/^data:image\/[a-z+.-]+;base64,/i.test(url)) return { error: "只能用 PNG 或 JPG 图片" };
      return { error: "应为 PNG 或 JPG 的 data: 地址（data:image/png;base64,…）" };
    }
    const b64 = url.slice(m[0].length);
    if (b64.length === 0 || !B64_RE.test(b64)) return { error: "base64 数据是空的，或里面有不该有的字符（换行、空格等）" };
    if (b64.length % 4 !== 0 || /=[^=]/.test(b64)) return { error: "base64 数据不完整" };
    const bytes = (b64.length / 4) * 3 - (b64.endsWith("==") ? 2 : b64.endsWith("=") ? 1 : 0);
    let head;
    try {
      head = b64decode(b64.slice(0, Math.min(b64.length, 4 * 65536)));
    } catch {
      return { error: "base64 数据读不出来" };
    }
    const type = isPngSig(head) ? "png" : isJpegSig(head) ? "jpeg" : null;
    if (!type) return { error: "数据不是 PNG 也不是 JPG", bytes };
    let size = type === "png" ? pngSize(head) : jpegSize(head);
    if (!size && type === "jpeg" && head.length < bytes) {
      try {
        size = jpegSize(b64decode(b64));
      } catch {
        size = null;
      }
    }
    if (!size || !(size.width > 0) || !(size.height > 0)) return { error: "读不出图片的宽和高（文件可能坏了）", bytes, type, mime: m[1] };
    return { mime: m[1], type, bytes, width: size.width, height: size.height, mismatch: type !== m[1] };
  }

  // ---------------------------------------------------------------- a small PNG writer

  let crcTable = null;
  function crc32(bytes, crc) {
    if (!crcTable) {
      crcTable = new Uint32Array(256);
      for (let n = 0; n < 256; n++) {
        let c = n;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
        crcTable[n] = c >>> 0;
      }
    }
    let c = crc === undefined ? 0xffffffff : crc;
    for (let i = 0; i < bytes.length; i++) c = crcTable[(c ^ bytes[i]) & 0xff] ^ (c >>> 8);
    return c;
  }

  function adler32(bytes) {
    let a = 1;
    let b = 0;
    for (let i = 0; i < bytes.length; ) {
      const end = Math.min(bytes.length, i + 3800);
      for (; i < end; i++) {
        a += bytes[i];
        b += a;
      }
      a %= 65521;
      b %= 65521;
    }
    return ((b << 16) | a) >>> 0;
  }

  const LBASE = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258];
  const LEXT = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
  const DBASE = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577];
  const DEXT = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];

  /** Raw deflate (RFC 1951) in one block of fixed Huffman codes; greedy LZ77 with one candidate a hash. */
  function deflateRaw(data) {
    let buf = new Uint8Array(Math.max(1024, data.length >> 3));
    let pos = 0;
    let acc = 0;
    let nbits = 0;
    const byte = (v) => {
      if (pos === buf.length) {
        const nb = new Uint8Array(buf.length * 2);
        nb.set(buf);
        buf = nb;
      }
      buf[pos++] = v;
    };
    const put = (value, count) => {
      acc |= value << nbits;
      nbits += count;
      while (nbits >= 8) {
        byte(acc & 0xff);
        acc >>>= 8;
        nbits -= 8;
      }
    };
    // Huffman codes go most significant bit first into the LSB-first stream.
    const putRev = (code, len) => {
      let r = 0;
      for (let k = 0; k < len; k++) r |= ((code >> (len - 1 - k)) & 1) << k;
      put(r, len);
    };
    const sym = (s) => {
      if (s < 144) putRev(0x30 + s, 8);
      else if (s < 256) putRev(0x190 + s - 144, 9);
      else if (s < 280) putRev(s - 256, 7);
      else putRev(0xc0 + s - 280, 8);
    };
    put(1, 1); // BFINAL
    put(1, 2); // BTYPE 01: fixed Huffman codes
    const n = data.length;
    const head = new Int32Array(1 << 15).fill(-1);
    const hash = (i) => ((data[i] << 10) ^ (data[i + 1] << 5) ^ data[i + 2]) & 0x7fff;
    let i = 0;
    while (i < n) {
      let bestLen = 0;
      let bestDist = 0;
      if (i + 2 < n) {
        const h = hash(i);
        const max = Math.min(258, n - i);
        for (const c of [i - 1, head[h]]) {
          if (c < 0 || c >= i || i - c > 32768) continue;
          let l = 0;
          while (l < max && data[c + l] === data[i + l]) l++;
          if (l > bestLen) {
            bestLen = l;
            bestDist = i - c;
          }
        }
        head[h] = i;
      }
      if (bestLen >= 3) {
        let k = LBASE.length - 1;
        while (LBASE[k] > bestLen) k--;
        sym(257 + k);
        if (LEXT[k]) put(bestLen - LBASE[k], LEXT[k]);
        let d = DBASE.length - 1;
        while (DBASE[d] > bestDist) d--;
        putRev(d, 5);
        if (DEXT[d]) put(bestDist - DBASE[d], DEXT[d]);
        for (let j = i + 1; j < i + bestLen && j + 2 < n; j++) head[hash(j)] = j;
        i += bestLen;
      } else {
        sym(data[i]);
        i++;
      }
    }
    sym(256);
    if (nbits > 0) byte(acc & 0xff);
    return buf.subarray(0, pos);
  }

  function zlibWrap(data) {
    const d = deflateRaw(data);
    const out = new Uint8Array(d.length + 6);
    out[0] = 0x78;
    out[1] = 0x01;
    out.set(d, 2);
    const a = adler32(data);
    out[out.length - 4] = a >>> 24;
    out[out.length - 3] = (a >>> 16) & 0xff;
    out[out.length - 2] = (a >>> 8) & 0xff;
    out[out.length - 1] = a & 0xff;
    return out;
  }

  function pngChunk(type, data) {
    const out = new Uint8Array(12 + data.length);
    const len = data.length;
    out[0] = len >>> 24;
    out[1] = (len >>> 16) & 0xff;
    out[2] = (len >>> 8) & 0xff;
    out[3] = len & 0xff;
    for (let i = 0; i < 4; i++) out[4 + i] = type.charCodeAt(i);
    out.set(data, 8);
    const c = (crc32(out.subarray(4, 8 + len)) ^ 0xffffffff) >>> 0;
    out[8 + len] = c >>> 24;
    out[9 + len] = (c >>> 16) & 0xff;
    out[10 + len] = (c >>> 8) & 0xff;
    out[11 + len] = c & 0xff;
    return out;
  }

  /**
   * A PNG data: URL of an 8-bit indexed picture: `pixels` holds a palette index for each pixel
   * (row by row), `palette` up to 256 [r, g, b] or [r, g, b, a].
   */
  function encodeIndexedPng(width, height, pixels, palette) {
    const raw = new Uint8Array(height * (width + 1));
    for (let y = 0; y < height; y++) raw.set(pixels.subarray(y * width, y * width + width), y * (width + 1) + 1);
    const ihdr = new Uint8Array(13);
    ihdr.set([width >>> 24, (width >>> 16) & 255, (width >>> 8) & 255, width & 255, height >>> 24, (height >>> 16) & 255, (height >>> 8) & 255, height & 255, 8, 3, 0, 0, 0]);
    const plte = new Uint8Array(palette.length * 3);
    palette.forEach((c, i) => plte.set([c[0], c[1], c[2]], i * 3));
    const parts = [new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), pngChunk("IHDR", ihdr), pngChunk("PLTE", plte)];
    if (palette.some((c) => c.length > 3 && c[3] < 255)) parts.push(pngChunk("tRNS", new Uint8Array(palette.map((c) => (c.length > 3 ? c[3] : 255)))));
    parts.push(pngChunk("IDAT", zlibWrap(raw)), pngChunk("IEND", new Uint8Array(0)));
    const total = parts.reduce((s, p) => s + p.length, 0);
    const png = new Uint8Array(total);
    let o = 0;
    for (const p of parts) {
      png.set(p, o);
      o += p.length;
    }
    return "data:image/png;base64," + b64encode(png);
  }

  /** A plain room picture (sky, ground and a path), for a 关卡 made without pictures of its own. */
  function placeholderBackground(width, height) {
    const w = width || 960;
    const h = height || 560;
    const pal = [
      [196, 230, 250], [205, 235, 251], [214, 239, 252], [223, 243, 253], [232, 247, 254], [240, 250, 255],
      [255, 255, 255], // 6 cloud
      [139, 201, 112], // 7 grass
      [124, 186, 98], // 8 grass, darker
      [236, 214, 160], // 9 path
      [222, 196, 138], // 10 path edge
      [110, 160, 90], // 11 horizon line
    ];
    const px = new Uint8Array(w * h);
    const horizon = Math.round(h * 0.42);
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        let c;
        if (y < horizon) c = Math.min(5, Math.floor((y / horizon) * 6));
        else if (y < horizon + 3) c = 11;
        else c = (Math.floor(x / 48) + Math.floor((y - horizon) / 48)) % 2 ? 7 : 8;
        px[y * w + x] = c;
      }
    }
    const ell = (cx, cy, rx, ry, c, edge) => {
      for (let y = Math.max(0, Math.floor(cy - ry - 3)); y < Math.min(h, cy + ry + 3); y++)
        for (let x = Math.max(0, Math.floor(cx - rx - 3)); x < Math.min(w, cx + rx + 3); x++) {
          const d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2;
          if (d <= 1) px[y * w + x] = c;
          else if (edge !== undefined && d <= 1.06) px[y * w + x] = edge;
        }
    };
    for (const [cx, cy, r] of [[0.18, 0.12, 46], [0.24, 0.1, 34], [0.62, 0.2, 40], [0.68, 0.17, 30], [0.86, 0.09, 28]]) ell(cx * w, cy * h, r * 1.6, r * 0.6, 6);
    ell(w / 2, h * 0.8, w * 0.42, h * 0.16, 9, 10);
    return encodeIndexedPng(w, h, px, pal);
  }

  // ---------------------------------------------------------------- packs

  /** A new opponent: a 亚比 of race `race` at `level`, its six stats as they are (100%). */
  function newOpponent(race, level) {
    const o = { race: race || 1, level: level || 10 };
    for (const k of STATS) o[k] = 100;
    return o;
  }

  /** "v2" for a pack, "v1" for a fight list (enemies, no levels), null for anything else. */
  function detect(o) {
    if (!isObj(o)) return null;
    if (o.format !== undefined && o.format !== FORMAT) return null;
    if (o.version === 2 || Array.isArray(o.levels) || isObj(o.images)) return "v2";
    if (Array.isArray(o.enemies)) return "v1";
    return null;
  }

  const KNOWN = {
    pack: ["format", "version", "name", "author", "images", "levels"],
    level: ["id", "name", "heal", "start", "next", "rooms"],
    room: ["id", "name", "background", "mask", "overlay", "music", "props", "spawns", "doors", "enemies"],
    prop: ["image", "at", "front"],
    door: ["rect", "to", "spawn", "open", "label"],
    enemy: ["id", "at", "name", "boss", "team"],
    opponent: ["race", "level", ...STATS],
  };
  function extras(out, src, known) {
    if (!isObj(src)) return out;
    for (const k of Object.keys(src)) if (!known.includes(k) && src[k] !== undefined) out[k] = src[k];
    return out;
  }
  const arr = (v) => (Array.isArray(v) ? v : []);
  const clone = (v) => (v === undefined ? undefined : JSON.parse(JSON.stringify(v)));

  function normOpponent(o) {
    if (!isObj(o)) return o;
    const out = { race: o.race, level: o.level === undefined ? 1 : o.level };
    for (const k of STATS) out[k] = o[k] === undefined ? 100 : o[k];
    return extras(out, o, KNOWN.opponent);
  }

  /**
   * A file as the editor holds it: every list and map there (empty when missing), missing
   * stats as 100 and a missing level as 1; values that are wrong are kept for validate to show.
   */
  function normalize(src) {
    const s = isObj(src) ? src : {};
    const out = { format: FORMAT, version: 2, name: typeof s.name === "string" ? s.name : "", author: typeof s.author === "string" ? s.author : "", images: {}, levels: [] };
    extras(out, s, KNOWN.pack);
    if (isObj(s.images)) for (const [k, v] of Object.entries(s.images)) if (typeof v === "string") out.images[k] = v;
    for (const l of arr(clone(s.levels))) {
      if (!isObj(l)) continue;
      const lv = extras({ id: l.id ?? "", name: typeof l.name === "string" ? l.name : "", heal: l.heal !== false, start: l.start ?? "", next: l.next ?? "", rooms: [] }, l, KNOWN.level);
      for (const r of arr(l.rooms)) {
        if (!isObj(r)) continue;
        const room = extras(
          {
            id: r.id ?? "",
            name: typeof r.name === "string" ? r.name : "",
            background: r.background ?? "",
            mask: r.mask ?? "",
            overlay: r.overlay ?? "",
            music: r.music ?? "",
            props: arr(r.props).filter(isObj).map((p) => extras({ image: p.image ?? "", at: p.at, front: p.front === true }, p, KNOWN.prop)),
            spawns: isObj(r.spawns) ? r.spawns : {},
            doors: arr(r.doors).filter(isObj).map((d) => extras({ rect: d.rect, to: d.to ?? "", spawn: d.spawn ?? "", open: d.open ?? "always", label: typeof d.label === "string" ? d.label : "" }, d, KNOWN.door)),
            enemies: arr(r.enemies)
              .filter(isObj)
              .map((e) => extras({ id: e.id ?? "", at: e.at, name: typeof e.name === "string" ? e.name : "", boss: e.boss === true, team: arr(e.team).map(normOpponent) }, e, KNOWN.enemy)),
          },
          r,
          KNOWN.room,
        );
        lv.rooms.push(room);
      }
      out.levels.push(lv);
    }
    return out;
  }

  const nonEmpty = (v) => v !== undefined && v !== null && v !== "";

  /** A pack as it is written: the format's field order, empty optional fields left out. */
  function serialize(p) {
    const s = isObj(p) ? p : {};
    const out = { format: FORMAT, version: 2, name: typeof s.name === "string" ? s.name : "", author: typeof s.author === "string" ? s.author : "", images: {}, levels: [] };
    if (isObj(s.images)) for (const [k, v] of Object.entries(s.images)) out.images[k] = v;
    out.levels = arr(s.levels).map((l) => {
      if (!isObj(l)) return l;
      const lv = { id: l.id };
      if (nonEmpty(l.name)) lv.name = l.name;
      lv.heal = l.heal !== false;
      lv.start = l.start;
      if (nonEmpty(l.next)) lv.next = l.next;
      lv.rooms = arr(l.rooms).map((r) => {
        if (!isObj(r)) return r;
        const room = { id: r.id };
        if (nonEmpty(r.name)) room.name = r.name;
        room.background = r.background;
        if (nonEmpty(r.mask)) room.mask = r.mask;
        if (nonEmpty(r.overlay)) room.overlay = r.overlay;
        if (nonEmpty(r.music)) room.music = r.music;
        room.props = arr(r.props).map((pr) => (isObj(pr) ? extras({ image: pr.image, at: pr.at, front: pr.front === true }, pr, KNOWN.prop) : pr));
        room.spawns = isObj(r.spawns) ? Object.assign({}, r.spawns) : {};
        room.doors = arr(r.doors).map((d) => {
          if (!isObj(d)) return d;
          const door = { rect: d.rect, to: d.to };
          if (nonEmpty(d.spawn)) door.spawn = d.spawn;
          door.open = nonEmpty(d.open) ? d.open : "always";
          if (nonEmpty(d.label)) door.label = d.label;
          return extras(door, d, KNOWN.door);
        });
        room.enemies = arr(r.enemies).map((e) => {
          if (!isObj(e)) return e;
          const en = { id: e.id, at: e.at };
          if (nonEmpty(e.name)) en.name = e.name;
          en.boss = e.boss === true;
          en.team = arr(e.team).map(normOpponent);
          return extras(en, e, KNOWN.enemy);
        });
        return extras(room, r, KNOWN.room);
      });
      return extras(lv, l, KNOWN.level);
    });
    return extras(out, s, KNOWN.pack);
  }

  /**
   * JSON text: objects one key a line, but arrays of plain values and short objects of plain
   * values on one line (points, rectangles, doors, opponents), as in docs/SANDBOX.md.
   */
  function stringify(v) {
    const plain = (x) => x === null || typeof x !== "object";
    const flat = (x) => plain(x) || (Array.isArray(x) && x.every(plain));
    const go = (x, ind) => {
      if (Array.isArray(x)) {
        if (x.every(plain)) return "[" + x.map((e) => JSON.stringify(e) ?? "null").join(", ") + "]";
        const inner = ind + "  ";
        return "[\n" + x.map((e) => inner + go(e, inner)).join(",\n") + "\n" + ind + "]";
      }
      if (isObj(x)) {
        const keys = Object.keys(x).filter((k) => x[k] !== undefined);
        if (keys.length === 0) return "{}";
        if (keys.length <= 12 && keys.every((k) => flat(x[k]) && !(typeof x[k] === "string" && x[k].length > 120))) {
          const one = "{ " + keys.map((k) => JSON.stringify(k) + ": " + go(x[k], "")).join(", ") + " }";
          if (one.length + ind.length <= 120) return one;
        }
        const inner = ind + "  ";
        return "{\n" + keys.map((k) => inner + JSON.stringify(k) + ": " + go(x[k], inner)).join(",\n") + "\n" + ind + "}";
      }
      return JSON.stringify(x) ?? "null";
    };
    return go(v, "") + "\n";
  }

  /** The size in bytes of the file the pack is written as. */
  function packBytes(p) {
    return utf8Length(stringify(serialize(p)));
  }

  // ---------------------------------------------------------------- checking

  function where(...parts) {
    return parts.filter(Boolean).join(" › ");
  }
  const levelWhere = (l, i) => `关卡 ${i + 1}` + (isObj(l) ? (l.name ? `「${l.name}」` : "") + (l.id ? ` (${l.id})` : "") : "");
  const roomWhere = (r, j) => (isObj(r) ? (r.name ? `房间「${r.name}」` : `房间 ${j + 1}`) + (r.id ? ` (${r.id})` : "") : `房间 ${j + 1}`);

  function checkOpponent(o, add, names) {
    if (!isObj(o)) return add("error", "这里应当是一只亚比 {race, level, …}");
    if (!Number.isInteger(o.race) || o.race < 1) add("error", `编号 race 应为 1 以上的整数，现在是 ${show(o.race)}`);
    else if (names && !own(names, String(o.race))) add("warning", `图鉴里没有编号 ${o.race} 的亚比，游戏可能不让它出战`);
    if (o.level !== undefined && (!Number.isInteger(o.level) || o.level < 1 || o.level > LIMITS.maxLevel)) add("error", `等级应为 1–${LIMITS.maxLevel} 的整数，现在是 ${show(o.level)}`);
    for (const k of STATS)
      if (o[k] !== undefined && (!isNum(o[k]) || o[k] < LIMITS.pctMin || o[k] > LIMITS.pctMax))
        add("error", `${STAT_NAMES[k]}（${k}）应为 ${LIMITS.pctMin}–${LIMITS.pctMax} 的百分数（100 是原样），现在是 ${show(o[k])}`);
  }

  function checkText(v, max, label, add, required) {
    if (v === undefined || v === "") {
      if (required) add("warning", `还没有${label}`);
      return;
    }
    if (typeof v !== "string") add("error", `${label}应为文字，现在是 ${show(v)}`);
    else if (textLength(v) > max) add("error", `${label}最多 ${max} 个字，现在 ${textLength(v)} 个`);
  }

  function validateV1(o, opts, out) {
    const add = (sev, msg, loc, w) => out.push({ severity: sev, where: w || "关卡", loc: loc || { kind: "pack" }, message: msg });
    if (o.version !== undefined && o.version !== 1) add("error", `version 应为 1，现在是 ${show(o.version)}`);
    checkText(o.name, LIMITS.nameLength, "名字", add);
    if (o.heal !== undefined && typeof o.heal !== "boolean") add("error", "heal 应为 true 或 false");
    if (!Array.isArray(o.enemies) || o.enemies.length === 0) add("error", "还没有对手");
    else if (o.enemies.length > LIMITS.v1Enemies) add("error", `最多 ${LIMITS.v1Enemies} 个对手，现在 ${o.enemies.length} 个`);
    arr(o.enemies).forEach((e, m) => checkOpponent(e, (s, msg) => add(s, msg, { kind: "pack", member: m }, `关卡 › 第 ${m + 1} 个对手`), opts.names));
    return out;
  }

  /**
   * Every problem of a file: [{severity: "error" | "warning", where, loc, message}].
   * Errors break the format or its limits (the game may refuse the file); warnings are likely
   * mistakes. `loc` says where: {kind, image?, level?, room?, index?, spawn?, member?}.
   *
   * opts.names        {race: name} of the 亚比 (unknown races are warned about)
   * opts.imageInfo    (id, url) => imageInfo-like result, to reuse sizes already known
   * opts.wallAt       (room, x, y, width, height) => true on a wall, false on floor, undefined when unknown
   * opts.bytes        the file's size when already known
   */
  function validate(pack, opts) {
    const o = opts || {};
    const out = [];
    if (!isObj(pack)) return [{ severity: "error", where: "文件", loc: { kind: "pack" }, message: "这不是关卡包（应为一个 JSON 对象）" }];
    if (pack.format !== undefined && pack.format !== FORMAT) out.push({ severity: "error", where: "包", loc: { kind: "pack" }, message: `format 应为 "${FORMAT}"，现在是 ${show(pack.format)}` });
    if (detect(pack) === "v1") return validateV1(pack, o, out);
    const add = (loc, w) => (sev, msg) => out.push({ severity: sev, where: w, loc, message: msg });
    const P = add({ kind: "pack" }, "包");
    if (pack.format === undefined) P("error", `缺少 format（应为 "${FORMAT}"）`);
    if (pack.version !== 2) P("error", `version 应为 2，现在是 ${show(pack.version)}`);
    checkText(pack.name, LIMITS.nameLength, "包的名字", P, true);
    checkText(pack.author, LIMITS.nameLength, "作者", P);

    // Pictures.
    const info = {};
    const images = isObj(pack.images) ? pack.images : {};
    if (!isObj(pack.images)) P("error", "缺少 images（图片表）");
    const imageIds = Object.keys(images);
    if (imageIds.length > LIMITS.images) P("error", `最多 ${LIMITS.images} 张图片，现在 ${imageIds.length} 张`);
    for (const id of imageIds) {
      const I = add({ kind: "image", image: id }, `图片 ${id}`);
      if (!ID_RE.test(id)) I("error", "图片编号只能用英文字母、数字、_ 和 -，1–32 个");
      const inf = o.imageInfo ? o.imageInfo(id, images[id]) : imageInfo(images[id]);
      info[id] = inf;
      if (inf.error) {
        I("error", inf.error);
        continue;
      }
      if (inf.mismatch) I("warning", `标为 ${inf.mime === "png" ? "PNG" : "JPG"}，内容却是 ${inf.type === "png" ? "PNG" : "JPG"}`);
      if (inf.width > LIMITS.imageWidth || inf.height > LIMITS.imageHeight) I("error", `图片 ${inf.width}×${inf.height} 太大：最大 ${LIMITS.imageWidth}×${LIMITS.imageHeight}`);
    }

    // 关卡.
    const levels = Array.isArray(pack.levels) ? pack.levels : [];
    if (!Array.isArray(pack.levels)) P("error", "缺少 levels（关卡列表）");
    else if (levels.length === 0) P("error", "包里还没有关卡");
    else if (levels.length > LIMITS.levels) P("error", `最多 ${LIMITS.levels} 个关卡，现在 ${levels.length} 个`);
    const levelIds = new Map();
    levels.forEach((l, i) => {
      if (isObj(l) && typeof l.id === "string") levelIds.set(l.id, (levelIds.get(l.id) || 0) + 1);
    });
    const used = new Set();
    // Entry points of rooms from other 关卡 (a door "l2/r1"), for the reachability check.
    const entered = new Set();
    levels.forEach((l) => {
      if (!isObj(l)) return;
      for (const r of arr(l.rooms))
        for (const d of arr(isObj(r) ? r.doors : null)) {
          const t = isObj(d) ? parseTarget(d.to) : null;
          if (t && t.kind === "room" && t.level !== null && t.level !== l.id) entered.add(t.level + "/" + t.room);
        }
    });

    levels.forEach((l, i) => {
      const LW = levelWhere(l, i);
      const L = add({ kind: "level", level: i }, LW);
      if (!isObj(l)) return L("error", "这里应当是一个关卡对象");
      if (!isId(l.id)) L("error", `关卡编号 ${show(l.id)} 不对：只能用英文字母、数字、_ 和 -，1–32 个`);
      else if (levelIds.get(l.id) > 1) L("error", `关卡编号 ${l.id} 重复了`);
      checkText(l.name, LIMITS.nameLength, "关卡名字", L);
      if (l.heal !== undefined && typeof l.heal !== "boolean") L("error", "heal 应为 true 或 false");
      const rooms = Array.isArray(l.rooms) ? l.rooms : [];
      if (!Array.isArray(l.rooms) || rooms.length === 0) L("error", "关卡里还没有房间");
      else if (rooms.length > LIMITS.rooms) L("error", `一个关卡最多 ${LIMITS.rooms} 个房间，现在 ${rooms.length} 个`);
      const roomIds = new Map();
      for (const r of rooms) if (isObj(r) && typeof r.id === "string") roomIds.set(r.id, (roomIds.get(r.id) || 0) + 1);
      if (l.start === undefined || l.start === "") L("error", "还没有选起始房间（start）");
      else if (!isId(l.start)) L("error", `起始房间 ${show(l.start)} 不是一个编号`);
      else if (!roomIds.has(l.start)) L("error", `起始房间 ${l.start} 不在这个关卡里`);
      if (l.next !== undefined && l.next !== "") {
        if (!isId(l.next)) L("error", `下一关 ${show(l.next)} 不是一个编号`);
        else if (!levelIds.has(l.next)) L("error", `下一关 ${l.next} 不在这个包里`);
        else if (l.next === l.id) L("warning", "下一关就是它自己");
      }
      let finish = false;
      const enemyIds = new Map();
      rooms.forEach((r) => {
        for (const e of arr(isObj(r) ? r.enemies : null)) if (isObj(e) && typeof e.id === "string") enemyIds.set(e.id, (enemyIds.get(e.id) || 0) + 1);
      });

      rooms.forEach((r, j) => {
        const RW = where(LW, roomWhere(r, j));
        const R = add({ kind: "room", level: i, room: j }, RW);
        if (!isObj(r)) return R("error", "这里应当是一个房间对象");
        if (!isId(r.id)) R("error", `房间编号 ${show(r.id)} 不对：只能用英文字母、数字、_ 和 -，1–32 个`);
        else if (roomIds.get(r.id) > 1) R("error", `房间编号 ${r.id} 在这个关卡里重复了`);
        checkText(r.name, LIMITS.nameLength, "房间名字", R);
        let W = 0;
        let H = 0;
        const imageRef = (field, label, required) => {
          const v = r[field];
          if (v === undefined || v === "") {
            if (required) R("error", `还没有选${label}`);
            return null;
          }
          if (!isId(v)) {
            R("error", `${label} ${show(v)} 不是一个图片编号`);
            return null;
          }
          used.add(v);
          if (!own(images, v)) {
            R("error", `${label}用的图片 ${v} 不在包里`);
            return null;
          }
          return info[v] && !info[v].error ? info[v] : null;
        };
        const bg = imageRef("background", "背景");
        if (r.background === undefined || r.background === "") R("error", "还没有选背景图片（background）");
        if (bg) {
          W = bg.width;
          H = bg.height;
          if (H !== LIMITS.roomHeight) R("warning", `背景高 ${H}，房间应为 ${LIMITS.roomHeight} 高`);
          if (W < LIMITS.roomMinWidth) R("warning", `背景宽 ${W}，房间至少 ${LIMITS.roomMinWidth} 宽`);
        }
        const mk = imageRef("mask", "遮罩");
        if (mk && bg && Math.abs(mk.width / mk.height - W / H) > 0.01 * (W / H)) R("warning", `遮罩 ${mk.width}×${mk.height} 和背景 ${W}×${H} 的长宽比不同，会被拉伸`);
        imageRef("overlay", "前景");
        if (r.music !== undefined && r.music !== "" && (typeof r.music !== "string" || !MUSIC_RE.test(r.music)))
          R("error", `音乐 ${show(r.music)} 应写成 music/名字.mp3（英文字母、数字、_ . / -）`);
        const inRoom = (x, y) => !W || (x >= 0 && y >= 0 && x <= W && y <= H);

        // Props.
        if (r.props !== undefined && !Array.isArray(r.props)) R("error", "props 应为列表");
        const props = arr(r.props);
        if (props.length > LIMITS.props) R("error", `一个房间最多 ${LIMITS.props} 个道具，现在 ${props.length} 个`);
        props.forEach((p, k) => {
          const A = add({ kind: "prop", level: i, room: j, index: k }, where(RW, `道具 ${k + 1}` + (isObj(p) && p.image ? `（${p.image}）` : "")));
          if (!isObj(p)) return A("error", "这里应当是一个道具对象");
          let pi = null;
          if (!isId(p.image)) A("error", `道具图片 ${show(p.image)} 不是一个图片编号`);
          else {
            used.add(p.image);
            if (!own(images, p.image)) A("error", `道具用的图片 ${p.image} 不在包里`);
            else pi = info[p.image] && !info[p.image].error ? info[p.image] : null;
          }
          if (!isPoint(p.at)) A("error", `位置 at 应为 [x, y]，现在是 ${show(p.at)}`);
          else if (W && pi && (p.at[0] >= W || p.at[1] >= H || p.at[0] + pi.width <= 0 || p.at[1] + pi.height <= 0)) A("warning", "道具完全在房间外面");
          if (p.front !== undefined && typeof p.front !== "boolean") A("error", "front 应为 true 或 false");
        });

        // Spawns.
        const spawns = isObj(r.spawns) ? r.spawns : {};
        if (r.spawns !== undefined && !isObj(r.spawns)) R("error", "spawns 应为 {名字: [x, y]}");
        const spawnNames = Object.keys(spawns);
        if (spawnNames.length > LIMITS.spawns) R("error", `一个房间最多 ${LIMITS.spawns} 个入口点，现在 ${spawnNames.length} 个`);
        for (const sn of spawnNames) {
          const S = add({ kind: "spawn", level: i, room: j, spawn: sn }, where(RW, `入口点 ${sn}`));
          if (!ID_RE.test(sn)) S("error", "入口点名字只能用英文字母、数字、_ 和 -，1–32 个");
          const pt = spawns[sn];
          if (!isPoint(pt)) S("error", `位置应为 [x, y]，现在是 ${show(pt)}`);
          else if (!inRoom(pt[0], pt[1])) S("warning", "入口点在房间外面");
          else if (o.wallAt && o.wallAt(r, pt[0], pt[1], W, H) === true) S("warning", "入口点站在墙里（遮罩上的黑色）");
        }
        if (l.start === r.id && !own(spawns, "start")) R("warning", "这是起始房间，却没有名叫 start 的入口点（玩家从哪里出现？）");

        // Doors.
        if (r.doors !== undefined && !Array.isArray(r.doors)) R("error", "doors 应为列表");
        const doors = arr(r.doors);
        if (doors.length > LIMITS.doors) R("error", `一个房间最多 ${LIMITS.doors} 扇门，现在 ${doors.length} 扇`);
        const enemies = arr(r.enemies);
        doors.forEach((d, k) => {
          const D = add({ kind: "door", level: i, room: j, index: k }, where(RW, `门 ${k + 1}` + (isObj(d) && typeof d.label === "string" && d.label ? `「${d.label}」` : "")));
          if (!isObj(d)) return D("error", "这里应当是一个门对象");
          if (!isRect(d.rect)) D("error", `门的方框 rect 应为 [x, y, 宽, 高]，现在是 ${show(d.rect)}`);
          else {
            const [x, y, w, h] = d.rect;
            if (!(w > 0 && h > 0)) D("error", `门的宽和高要大于 0（现在 ${w}×${h}）`);
            else if (W && (x >= W || y >= H || x + w <= 0 || y + h <= 0)) D("warning", "门完全在房间外面，走不进去");
            else
              for (const sn of spawnNames) {
                const pt = spawns[sn];
                if (isPoint(pt) && pt[0] >= x && pt[0] <= x + w && pt[1] >= y && pt[1] <= y + h) D("warning", `入口点 ${sn} 在这扇门里，一进房间就会走进门`);
              }
          }
          const t = parseTarget(d.to);
          if (d.to === undefined || d.to === "") D("error", "还没有选门通向哪里（to）");
          else if (!t) D("error", `门通向 ${show(d.to)} 不对：应为 房间、关卡/房间、#finish 或 #exit`);
          else if (t.kind === "finish") finish = true;
          if (t && t.kind === "room") {
            const target = resolveTarget(pack, l, d.to);
            if (!target) {
              if (t.level !== null && !levelIds.has(t.level)) D("error", `门通向的关卡 ${t.level} 不在包里`);
              else D("error", `门通向的房间 ${t.room} 不在${t.level !== null ? `关卡 ${t.level}` : "这个关卡"}里`);
            } else {
              const ts = isObj(target.room.spawns) ? target.room.spawns : {};
              if (d.spawn !== undefined && d.spawn !== "") {
                if (!isId(d.spawn)) D("error", `入口点 ${show(d.spawn)} 不是一个名字`);
                else if (!own(ts, d.spawn)) D("error", `目标房间 ${target.room.id} 里没有入口点 ${d.spawn}`);
              } else if (!own(ts, "start")) D("warning", `门没写入口点，目标房间 ${target.room.id} 又没有 start 入口点`);
            }
          } else if (t && d.spawn !== undefined && d.spawn !== "") D("warning", "通关或离开的门用不到入口点");
          if (d.open !== undefined && d.open !== "always" && d.open !== "cleared") D("error", `open 应为 "always" 或 "cleared"，现在是 ${show(d.open)}`);
          else if (d.open === "cleared" && enemies.length === 0) D("warning", "门要“打败所有对手后”才开，可这个房间没有对手（门一开始就开着）");
          checkText(d.label, LIMITS.labelLength, "门上的字", D);
        });

        // Opponents.
        if (r.enemies !== undefined && !Array.isArray(r.enemies)) R("error", "enemies 应为列表");
        if (enemies.length > LIMITS.enemies) R("error", `一个房间最多 ${LIMITS.enemies} 个对手，现在 ${enemies.length} 个`);
        const here = new Map();
        for (const e of enemies) if (isObj(e) && typeof e.id === "string") here.set(e.id, (here.get(e.id) || 0) + 1);
        enemies.forEach((e, k) => {
          const EW = where(RW, `对手 ${k + 1}` + (isObj(e) ? (e.name ? `「${e.name}」` : "") + (e.id ? ` (${e.id})` : "") : ""));
          const E = add({ kind: "enemy", level: i, room: j, index: k }, EW);
          if (!isObj(e)) return E("error", "这里应当是一个对手对象");
          if (!isId(e.id)) E("error", `对手编号 ${show(e.id)} 不对：只能用英文字母、数字、_ 和 -，1–32 个`);
          else if (here.get(e.id) > 1) E("error", `对手编号 ${e.id} 在这个房间里重复了`);
          else if (enemyIds.get(e.id) > 1) E("warning", `对手编号 ${e.id} 在这个关卡的别的房间里也有`);
          if (!isPoint(e.at)) E("error", `位置 at 应为 [x, y]，现在是 ${show(e.at)}`);
          else if (!inRoom(e.at[0], e.at[1])) E("warning", "对手站在房间外面");
          else if (o.wallAt && o.wallAt(r, e.at[0], e.at[1], W, H) === true) E("warning", "对手站在墙里（遮罩上的黑色）");
          checkText(e.name, LIMITS.enemyNameLength, "对手名字", E);
          if (e.boss !== undefined && typeof e.boss !== "boolean") E("error", "boss 应为 true 或 false");
          if (!Array.isArray(e.team) || e.team.length === 0) E("error", "队伍里还没有亚比");
          else if (e.team.length > LIMITS.team) E("error", `队伍最多 ${LIMITS.team} 只亚比，现在 ${e.team.length} 只`);
          arr(e.team).forEach((m, n) => checkOpponent(m, add({ kind: "enemy", level: i, room: j, index: k, member: n }, where(EW, `队伍第 ${n + 1} 只`)), o.names));
        });
      });

      // Reachability: from the start room, and rooms other 关卡 lead into, through the doors.
      if (rooms.length > 1 && roomIds.has(l.start)) {
        const seen = new Set();
        const queue = [l.start];
        for (const r of rooms) if (isObj(r) && entered.has(l.id + "/" + r.id)) queue.push(r.id);
        while (queue.length) {
          const id = queue.shift();
          if (seen.has(id)) continue;
          seen.add(id);
          const r = rooms.find((x) => isObj(x) && x.id === id);
          for (const d of arr(r && r.doors)) {
            const t = isObj(d) ? parseTarget(d.to) : null;
            if (t && t.kind === "room" && (t.level === null || t.level === l.id) && roomIds.has(t.room)) queue.push(t.room);
          }
        }
        rooms.forEach((r, j) => {
          if (isObj(r) && typeof r.id === "string" && !seen.has(r.id)) out.push({ severity: "warning", where: where(LW, roomWhere(r, j)), loc: { kind: "room", level: i, room: j }, message: "从起始房间走不到这个房间（没有门通向它）" });
        });
      }
      if (rooms.length && !finish) L("warning", "这个关卡没有通关的门（#finish），打完也不算通关");
    });

    for (const id of imageIds) if (!used.has(id)) out.push({ severity: "warning", where: `图片 ${id}`, loc: { kind: "image", image: id }, message: "没有房间用到这张图片（它会让文件变大）" });

    const bytes = o.bytes !== undefined ? o.bytes : utf8Length(stringify(pack));
    if (bytes > LIMITS.fileBytes) P("error", `文件 ${(bytes / 1e6).toFixed(1)} MB，超过了 ${LIMITS.fileBytes / 1e6} MB 的上限`);
    return out;
  }

  // ---------------------------------------------------------------- version 1

  /**
   * A version-1 fight list as a pack: one 关卡 of one room, its opponents one team (fought one
   * after another, as in version 1) behind a door that opens once they are beaten.
   * opts.background: a data: URL for the room (default: a plain picture made here).
   */
  function fromV1(v1, opts) {
    const o = opts || {};
    const src = isObj(v1) ? v1 : {};
    const name = typeof src.name === "string" && src.name ? src.name : "导入的关卡";
    const team = arr(src.enemies).map((e) => (isObj(e) ? normOpponent(e) : e));
    return {
      format: FORMAT,
      version: 2,
      name: textLength(name) > LIMITS.nameLength ? Array.from(name).slice(0, LIMITS.nameLength).join("") : name,
      author: "",
      images: { bg: o.background || placeholderBackground(960, 560) },
      levels: [
        {
          id: "l1",
          name: textLength(name) > LIMITS.nameLength ? Array.from(name).slice(0, LIMITS.nameLength).join("") : name,
          heal: src.heal !== false,
          start: "r1",
          next: "",
          rooms: [
            {
              id: "r1",
              name: "战场",
              background: "bg",
              mask: "",
              overlay: "",
              music: "",
              props: [],
              spawns: { start: [180, 440] },
              doors: [{ rect: [880, 300, 80, 200], to: "#finish", spawn: "", open: "cleared", label: "通关" }],
              enemies: [{ id: "e1", at: [620, 420], name: "对手", boss: team.length > 0, team }],
            },
          ],
        },
      ],
    };
  }

  // ---------------------------------------------------------------- references and renames

  function eachRoom(pack, fn) {
    arr(pack.levels).forEach((l, i) => {
      if (isObj(l)) arr(l.rooms).forEach((r, j) => isObj(r) && fn(r, l, i, j));
    });
  }

  function eachDoor(pack, fn) {
    eachRoom(pack, (r, l, i, j) => arr(r.doors).forEach((d, k) => isObj(d) && fn(d, r, l, i, j, k)));
  }

  /** Where an image is used: [{level, room, field: "background" | "mask" | "overlay" | "prop", index?}]. */
  function imageUses(pack, id) {
    const uses = [];
    eachRoom(pack, (r, l, i, j) => {
      for (const f of ["background", "mask", "overlay"]) if (r[f] === id) uses.push({ level: i, room: j, field: f });
      arr(r.props).forEach((p, k) => isObj(p) && p.image === id && uses.push({ level: i, room: j, field: "prop", index: k }));
    });
    return uses;
  }

  /** Doors that lead to room `roomId` of level `level` (an object of pack.levels). */
  function doorsTo(pack, level, roomId) {
    const found = [];
    eachDoor(pack, (d, r, l, i, j, k) => {
      const t = parseTarget(d.to);
      if (t && t.kind === "room" && t.room === roomId && (t.level === null ? l === level : t.level === level.id)) found.push({ level: i, room: j, index: k });
    });
    return found;
  }

  /** Renames a key of an object in place, keeping the keys' order. */
  function renameKey(o, from, to) {
    const entries = Object.entries(o);
    for (const k of Object.keys(o)) delete o[k];
    for (const [k, v] of entries) o[k === from ? to : k] = v;
  }

  function renameImage(pack, from, to) {
    if (from === to || !isObj(pack.images) || !own(pack.images, from)) return;
    renameKey(pack.images, from, to);
    eachRoom(pack, (r) => {
      for (const f of ["background", "mask", "overlay"]) if (r[f] === from) r[f] = to;
      for (const p of arr(r.props)) if (isObj(p) && p.image === from) p.image = to;
    });
  }

  function renameLevel(pack, level, to) {
    const from = level.id;
    if (from === to) return;
    level.id = to;
    for (const l of arr(pack.levels)) if (isObj(l) && l.next === from) l.next = to;
    eachDoor(pack, (d) => {
      const t = parseTarget(d.to);
      if (t && t.kind === "room" && t.level === from) d.to = to + "/" + t.room;
    });
  }

  function renameRoom(pack, level, room, to) {
    const from = room.id;
    if (from === to) return;
    const doors = doorsTo(pack, level, from);
    room.id = to;
    if (level.start === from) level.start = to;
    for (const { level: i, room: j, index: k } of doors) {
      const d = pack.levels[i].rooms[j].doors[k];
      const t = parseTarget(d.to);
      d.to = t.level === null ? to : t.level + "/" + to;
    }
  }

  function renameSpawn(pack, level, room, from, to) {
    if (from === to || !isObj(room.spawns) || !own(room.spawns, from)) return;
    const doors = doorsTo(pack, level, room.id);
    renameKey(room.spawns, from, to);
    for (const { level: i, room: j, index: k } of doors) {
      const d = pack.levels[i].rooms[j].doors[k];
      if (d.spawn === from) d.spawn = to;
    }
  }

  /**
   * Adds the pictures and 关卡 of pack `source` to `target` (both as the editor holds them),
   * renaming ids that are taken; the same picture already there is used again.
   * Returns {images: {old: new}, levels: {old: new}, added}.
   */
  function mergeInto(target, source) {
    const src = normalize(source);
    const imgMap = {};
    for (const [id, url] of Object.entries(src.images)) {
      const same = Object.keys(target.images).find((k) => target.images[k] === url);
      if (same) imgMap[id] = same;
      else {
        const nid = uniqueId(id, (s) => own(target.images, s));
        target.images[nid] = url;
        imgMap[id] = nid;
      }
    }
    const taken = new Set(arr(target.levels).map((l) => l.id));
    const lvMap = {};
    for (const l of src.levels) {
      const nid = uniqueId(l.id || "l1", taken);
      taken.add(nid);
      lvMap[l.id] = nid;
    }
    const mapImg = (v) => (nonEmpty(v) && own(imgMap, v) ? imgMap[v] : v);
    for (const l of src.levels) {
      const fromId = l.id;
      l.id = lvMap[fromId];
      if (nonEmpty(l.next) && own(lvMap, l.next)) l.next = lvMap[l.next];
      for (const r of l.rooms) {
        r.background = mapImg(r.background);
        r.mask = mapImg(r.mask);
        r.overlay = mapImg(r.overlay);
        for (const p of r.props) p.image = mapImg(p.image);
        for (const d of r.doors) {
          const t = parseTarget(d.to);
          if (t && t.kind === "room" && t.level !== null && own(lvMap, t.level)) d.to = lvMap[t.level] + "/" + t.room;
        }
      }
      target.levels.push(l);
    }
    return { images: imgMap, levels: lvMap, added: src.levels.length };
  }

  /** Mask semantics: alpha under 128 is floor; otherwise dark (luminance under 128) is wall. */
  function isWallPixel(r, g, b, a) {
    if (a < 128) return false;
    // The same expression, in the same order, as the game (SandboxRoom.as), so both agree to the last bit.
    return 0.299 * r + 0.587 * g + 0.114 * b < 128;
  }

  return {
    FORMAT,
    LIMITS,
    STATS,
    STAT_NAMES,
    ID_RE,
    TO_RE,
    MUSIC_RE,
    isId,
    textLength,
    sanitizeId,
    uniqueId,
    idProblem,
    fileName,
    parseTarget,
    resolveTarget,
    utf8Length,
    imageInfo,
    encodeIndexedPng,
    placeholderBackground,
    newOpponent,
    detect,
    normalize,
    serialize,
    stringify,
    packBytes,
    validate,
    fromV1,
    imageUses,
    doorsTo,
    renameImage,
    renameLevel,
    renameRoom,
    renameSpawn,
    mergeInto,
    isWallPixel,
    // for tests
    _deflateRaw: deflateRaw,
    _crc32: crc32,
  };
});
