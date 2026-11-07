"use strict";
(() => {
  // server/src/core/clock.ts
  var GameClock = class {
    anchor;
    startedAt;
    realNow;
    constructor(anchor, realNow = Date.now) {
      this.anchor = typeof anchor === "string" ? parseAnchor(anchor) : anchor;
      this.realNow = realNow;
      this.startedAt = realNow();
    }
    now() {
      return new Date(this.anchor.getTime() + (this.realNow() - this.startedAt));
    }
    /** Seconds since 1970, the usual on-the-wire form. */
    unix() {
      return Math.floor(this.now().getTime() / 1e3);
    }
    /** Offset to add to the real clock, for clients that read local time. */
    offsetMs() {
      return this.now().getTime() - this.realNow();
    }
  };
  function parseAnchor(s) {
    const m = /^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?$/.exec(s.trim());
    if (!m) throw new Error(`anchor date must look like 2012-08-15 or 2012-08-15T10:00, got ${s}`);
    const [, y, mo, d, h = "10", mi = "00", se = "00"] = m;
    return new Date(Date.UTC(+y, +mo - 1, +d, +h - 8, +mi, +se));
  }

  // server/src/core/codec.ts
  var rawCodec = {
    name: "raw",
    decode: (frame) => ({ cmd: "raw", raw: frame }),
    encode: (msg) => {
      if (!msg.raw) throw new Error(`raw codec cannot encode cmd ${String(msg.cmd)} without raw bytes`);
      return msg.raw;
    }
  };

  // server/src/core/framing.ts
  var FRAMING_PRESETS = {
    /** No framing: each received chunk is one record. Use while learning the protocol. */
    raw: null,
    "u32be-total": { lengthOffset: 0, lengthBytes: 4, littleEndian: false, lengthIncludesHeader: true, headerBytes: 4 },
    "u32be-body": { lengthOffset: 0, lengthBytes: 4, littleEndian: false, lengthIncludesHeader: false, headerBytes: 4 },
    "u32le-total": { lengthOffset: 0, lengthBytes: 4, littleEndian: true, lengthIncludesHeader: true, headerBytes: 4 },
    "u16be-total": { lengthOffset: 0, lengthBytes: 2, littleEndian: false, lengthIncludesHeader: true, headerBytes: 2 },
    "u16be-body": { lengthOffset: 0, lengthBytes: 2, littleEndian: false, lengthIncludesHeader: false, headerBytes: 2 },
    /** Taomee web games (摩尔庄园 online): len u32 | ver u8 | cmd u32 | uid u32 | ret u32. Reference only. */
    taomee: { lengthOffset: 0, lengthBytes: 4, littleEndian: false, lengthIncludesHeader: true, headerBytes: 17 }
  };
  function parseFraming(arg) {
    if (arg in FRAMING_PRESETS) return FRAMING_PRESETS[arg];
    const spec = JSON.parse(arg);
    for (const k of ["lengthOffset", "lengthBytes", "headerBytes"]) {
      if (typeof spec[k] !== "number") throw new Error(`framing spec needs numeric ${k}`);
    }
    return spec;
  }
  var FramingError = class extends Error {
  };
  var FrameSplitter = class {
    // What has come and is not yet a whole frame, in the pieces it came in: joined only once a
    // frame is whole (piece by piece joining copies the whole pending frame for every piece).
    parts = [];
    size = 0;
    /** The length of the frame at the front, once its header has come. */
    want = 0;
    spec;
    constructor(spec) {
      this.spec = spec;
    }
    get pending() {
      return this.size;
    }
    /** Feed received bytes; returns every complete frame (header included). */
    push(chunk) {
      if (!this.spec) return chunk.length ? [chunk.slice()] : [];
      if (chunk.length) {
        this.parts.push(chunk.slice());
        this.size += chunk.length;
      }
      const need = Math.max(this.spec.lengthOffset + this.spec.lengthBytes, this.spec.headerBytes);
      if (this.size < need) return [];
      if (!this.want) this.want = this.frameLength(this.head(need), 0);
      if (this.size < this.want) return [];
      const buf = this.parts.length === 1 ? this.parts[0] : concatParts(this.parts, this.size);
      const frames = [];
      let off = 0;
      while (buf.length - off >= need) {
        const total = this.frameLength(buf.subarray(off, off + need), off);
        if (buf.length - off < total) break;
        frames.push(buf.slice(off, off + total));
        off += total;
      }
      const rest = buf.subarray(off);
      this.parts = rest.length ? [rest.slice()] : [];
      this.size = rest.length;
      this.want = rest.length >= need ? this.frameLength(rest.subarray(0, need), off) : 0;
      return frames;
    }
    /** The first n pending bytes (n is a header's few bytes). */
    head(n) {
      if (this.parts[0].length >= n) return this.parts[0];
      const out = new Uint8Array(n);
      let at = 0;
      for (const p of this.parts) {
        const take = Math.min(p.length, n - at);
        out.set(p.subarray(0, take), at);
        at += take;
        if (at === n) break;
      }
      return out;
    }
    /** A frame's whole length from its header. */
    frameLength(head, off) {
      const { lengthOffset, lengthBytes, littleEndian, lengthIncludesHeader, headerBytes } = this.spec;
      const need = Math.max(lengthOffset + lengthBytes, headerBytes);
      const view2 = new DataView(head.buffer, head.byteOffset, need);
      let len = lengthBytes === 1 ? view2.getUint8(lengthOffset) : lengthBytes === 2 ? view2.getUint16(lengthOffset, littleEndian) : view2.getUint32(lengthOffset, littleEndian);
      len += this.spec.adjust ?? 0;
      const total = lengthIncludesHeader ? len : headerBytes + len;
      if (total < need || total > (this.spec.maxFrame ?? 4 * 1024 * 1024)) {
        throw new FramingError(`implausible frame length ${total} at stream offset ${off}`);
      }
      return total;
    }
  };
  function concatParts(parts, size) {
    const out = new Uint8Array(size);
    let at = 0;
    for (const p of parts) {
      out.set(p, at);
      at += p.length;
    }
    return out;
  }

  // server/src/core/bytes.ts
  var enc = new TextEncoder();
  var dec = new TextDecoder("utf-8", { fatal: false });
  function utf8(s) {
    return enc.encode(s);
  }
  function fromUtf8(b) {
    return dec.decode(b);
  }
  function concat(...parts) {
    const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
    let o = 0;
    for (const p of parts) {
      out.set(p, o);
      o += p.length;
    }
    return out;
  }
  function toHex(b, max = Infinity) {
    const n = Math.min(b.length, max);
    let s = "";
    for (let i = 0; i < n; i++) s += b[i].toString(16).padStart(2, "0");
    return n < b.length ? s + "\u2026" : s;
  }
  function asciiPreview(b, max = 256) {
    let s = "";
    for (let i = 0; i < Math.min(b.length, max); i++) {
      const c = b[i];
      s += c >= 32 && c < 127 ? String.fromCharCode(c) : ".";
    }
    return s;
  }
  function looksLikeText(b) {
    if (b.length === 0) return false;
    const s = fromUtf8(b);
    let bad = 0;
    for (const ch of s) {
      const c = ch.codePointAt(0);
      if (c === 65533 || c < 32 && c !== 9 && c !== 10 && c !== 13 && c !== 0) bad++;
    }
    return bad / s.length < 0.05;
  }

  // server/src/core/policy.ts
  var POLICY_REQUEST = "<policy-file-request/>";
  function isPolicyRequest(chunk) {
    return chunk.length >= POLICY_REQUEST.length && fromUtf8(chunk.subarray(0, POLICY_REQUEST.length)) === POLICY_REQUEST;
  }
  function policyResponse(ports = "*") {
    const xml = `<?xml version="1.0"?><!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd"><cross-domain-policy><site-control permitted-cross-domain-policies="master-only"/><allow-access-from domain="*" to-ports="${ports}"/></cross-domain-policy>`;
    return utf8(xml + "\0");
  }

  // server/src/core/recorder.ts
  function frameRecord(session, port, dir, bytes2, note, maxHex = 4096) {
    const r = { t: (/* @__PURE__ */ new Date()).toISOString(), session, port, dir, len: bytes2?.length ?? 0 };
    if (bytes2) {
      r.hex = toHex(bytes2, maxHex);
      r.text = looksLikeText(bytes2) ? fromUtf8(bytes2.subarray(0, maxHex)) : asciiPreview(bytes2, 128);
    }
    if (note) r.note = note;
    return r;
  }
  var MemoryRecorder = class {
    records = [];
    max;
    constructor(max = 0) {
      this.max = max;
    }
    record(r) {
      this.records.push(r);
      if (this.max && this.records.length > this.max + (this.max >> 2)) this.records.splice(0, this.records.length - this.max);
    }
  };
  var ConsoleRecorder = class {
    record(r) {
      const head = `[${r.port}#${r.session}] ${r.dir.padEnd(5)} ${String(r.len).padStart(6)}B`;
      console.log(r.note ? `${head} ${r.note}` : `${head} ${r.text ?? ""}`.slice(0, 220));
    }
  };
  var TeeRecorder = class {
    sinks;
    constructor(...sinks) {
      this.sinks = sinks;
    }
    record(r) {
      for (const s of this.sinks) s.record(r);
    }
  };

  // server/src/core/store.ts
  var MemoryStore = class {
    map = /* @__PURE__ */ new Map();
    async get(key) {
      const v = this.map.get(key);
      return v === void 0 ? void 0 : JSON.parse(v);
    }
    async set(key, value) {
      this.map.set(key, JSON.stringify(value));
    }
    async delete(key) {
      this.map.delete(key);
    }
    async keys(prefix = "") {
      return [...this.map.keys()].filter((k) => k.startsWith(prefix)).sort();
    }
  };
  var LiveRecordStore = class {
    live = /* @__PURE__ */ new Map();
    inner;
    prefixes;
    max;
    pinned;
    maxBytes;
    log;
    /**
     * pinned: records never let go (the players in the game: their handlers hold them). maxBytes: a
     * kept record larger than this as JSON is not written (0: no limit; a Durable Object value is
     * at most 2 MB).
     */
    constructor(inner, prefixes, max = 1e3, pinned = () => false, maxBytes = 0, log = (m) => console.error(m)) {
      this.inner = inner;
      this.prefixes = prefixes;
      this.max = max;
      this.pinned = pinned;
      this.maxBytes = maxBytes;
      this.log = log;
    }
    kept(key) {
      return this.prefixes.some((p) => key.startsWith(p));
    }
    remember(key, value) {
      this.live.delete(key);
      this.live.set(key, value);
      if (this.live.size <= this.max) return;
      for (const k of this.live.keys()) {
        if (this.live.size <= this.max) break;
        if (k !== key && !this.pinned(k)) this.live.delete(k);
      }
    }
    async get(key) {
      if (!this.kept(key)) return this.inner.get(key);
      if (this.live.has(key)) {
        const v2 = this.live.get(key);
        this.remember(key, v2);
        return v2;
      }
      const before = this.changes.get(key) ?? 0;
      const v = await this.inner.get(key);
      if (this.live.has(key)) return this.live.get(key);
      if ((this.changes.get(key) ?? 0) !== before) return this.get(key);
      if (v !== void 0) this.remember(key, v);
      return v;
    }
    /** Writes and deletes of each kept key so far (a get in flight then reads again). */
    changes = /* @__PURE__ */ new Map();
    changed(key) {
      this.changes.set(key, (this.changes.get(key) ?? 0) + 1);
      if (this.changes.size > this.max * 4) this.changes.clear();
    }
    async set(key, value) {
      if (!this.kept(key)) return this.inner.set(key, value);
      this.remember(key, value);
      this.changed(key);
      let err;
      if (this.maxBytes && new TextEncoder().encode(JSON.stringify(value)).length > this.maxBytes) err = new Error(`record over ${this.maxBytes} bytes`);
      else {
        for (let tries = 0; tries < 3; tries++) {
          try {
            await this.inner.set(key, value);
            return;
          } catch (e) {
            err = e;
            await new Promise((r) => setTimeout(r, 50 * (tries + 1)));
          }
        }
      }
      if (this.live.get(key) === value) {
        this.live.delete(key);
        this.changed(key);
      }
      this.log(`[aola] save of ${key} failed, its last saved state is kept: ${err?.message ?? String(err)}`);
      throw err;
    }
    async delete(key) {
      this.live.delete(key);
      this.changed(key);
      await this.inner.delete(key);
    }
    keys(prefix = "") {
      return this.inner.keys(prefix);
    }
  };

  // server/src/core/emulator.ts
  var Session = class {
    id;
    port;
    link;
    emu;
    /** Per-connection game state (user id, current map, …). */
    data = {};
    closed = false;
    splitter;
    first = true;
    constructor(id, port, link, emu) {
      this.id = id;
      this.port = port;
      this.link = link;
      this.emu = emu;
      this.splitter = new FrameSplitter(emu.framing);
    }
    /** Bytes arrived from the client. */
    receive(chunk) {
      if (this.closed || chunk.length === 0) return;
      if (this.first) {
        this.first = false;
        if (this.emu.answerPolicy && isPolicyRequest(chunk)) {
          this.note("policy request answered");
          this.link.send(policyResponse());
          this.close();
          return;
        }
      }
      let frames;
      try {
        frames = this.splitter.push(chunk);
      } catch (e) {
        if (!(e instanceof FramingError)) throw e;
        this.note(`framing error: ${e.message}; switch --framing or fix the spec`);
        this.emu.recorder.record(frameRecord(this.id, this.port, "in", chunk, "unframed bytes"));
        this.close();
        return;
      }
      for (const frame of frames) {
        this.emu.recorder.record(frameRecord(this.id, this.port, "in", frame));
        let msg;
        try {
          msg = this.emu.codec.decode(frame);
        } catch (e) {
          this.note(`decode failed: ${e.message}`);
          continue;
        }
        this.emu.dispatch(this, msg);
      }
    }
    send(msg) {
      this.sendBytes(this.emu.codec.encode(msg), msg.raw ? void 0 : `cmd ${String(msg.cmd)}`);
    }
    sendBytes(bytes2, note) {
      if (this.closed) return;
      this.emu.recorder.record(frameRecord(this.id, this.port, "out", bytes2, note));
      this.link.send(bytes2);
    }
    note(text) {
      this.emu.recorder.record(frameRecord(this.id, this.port, "event", null, text));
    }
    close() {
      if (this.closed) return;
      this.closed = true;
      this.link.close();
      this.emu.detach(this);
    }
  };
  var Emulator = class {
    framing;
    codec;
    clock;
    store;
    recorder;
    answerPolicy;
    sessions = /* @__PURE__ */ new Set();
    handlers = /* @__PURE__ */ new Map();
    connectHooks = [];
    closeHooks = [];
    fallback = (s, m) => s.note(`unhandled cmd ${String(m.cmd)}`);
    nextId = 1;
    constructor(opts = {}) {
      this.framing = opts.framing ?? null;
      this.codec = opts.codec ?? rawCodec;
      this.clock = opts.clock ?? new GameClock("2012-08-15");
      this.store = opts.store ?? new MemoryStore();
      this.recorder = opts.recorder ?? new MemoryRecorder();
      this.answerPolicy = opts.answerPolicy ?? true;
    }
    /** Register a handler for a command, optionally only on one port. */
    on(cmd, handler, port) {
      this.handlers.set(`${port ?? "*"}:${String(cmd)}`, handler);
      return this;
    }
    /** Handler for every command nobody registered (default: log it). */
    onUnhandled(handler) {
      this.fallback = handler;
      return this;
    }
    onConnect(hook) {
      this.connectHooks.push(hook);
      return this;
    }
    onClose(hook) {
      this.closeHooks.push(hook);
      return this;
    }
    /** A transport accepted a connection. */
    attach(link, port) {
      const s = new Session(this.nextId++, port, link, this);
      this.sessions.add(s);
      s.note(`connected from ${link.remote}`);
      for (const h of this.connectHooks) h(s);
      return s;
    }
    detach(s) {
      if (!this.sessions.delete(s)) return;
      s.closed = true;
      s.note("closed");
      for (const h of this.closeHooks) h(s);
    }
    dispatch(s, msg) {
      const key = String(msg.cmd);
      const h = this.handlers.get(`${s.port}:${key}`) ?? this.handlers.get(`*:${key}`) ?? this.fallback;
      Promise.resolve().then(() => h(s, msg, this)).catch((e) => s.note(`handler for ${key} threw: ${e.stack ?? String(e)}`));
    }
    /** Send to every session matching the filter (e.g. everyone on the same map). */
    broadcast(msg, filter = () => true) {
      for (const s of this.sessions) if (filter(s)) s.send(msg);
    }
  };

  // server/src/game/aola2012.ts
  function installAola2012(emu) {
    emu.onConnect((s) => s.note(`listen mode: game clock reads ${emu.clock.now().toISOString()}`));
  }

  // server/src/game/md5.ts
  var S = [7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21];
  var K = Array.from({ length: 64 }, (_, i) => Math.floor(Math.abs(Math.sin(i + 1)) * 2 ** 32) >>> 0);
  function md5(input) {
    const bitLen = input.length * 8;
    const padded = new Uint8Array(((input.length + 8 >> 6) + 1) * 64);
    padded.set(input);
    padded[input.length] = 128;
    const dv = new DataView(padded.buffer);
    dv.setUint32(padded.length - 8, bitLen >>> 0, true);
    dv.setUint32(padded.length - 4, Math.floor(bitLen / 2 ** 32), true);
    let a0 = 1732584193, b0 = 4023233417, c0 = 2562383102, d0 = 271733878;
    for (let off = 0; off < padded.length; off += 64) {
      let a = a0, b = b0, c = c0, d = d0;
      for (let i = 0; i < 64; i++) {
        let f, g;
        if (i < 16) {
          f = b & c | ~b & d;
          g = i;
        } else if (i < 32) {
          f = d & b | ~d & c;
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = b ^ c ^ d;
          g = (3 * i + 5) % 16;
        } else {
          f = c ^ (b | ~d);
          g = 7 * i % 16;
        }
        const m = dv.getUint32(off + g * 4, true);
        const s = S[(i >> 4) * 4 + (i & 3)];
        const sum = a + f + K[i] + m >>> 0;
        a = d;
        d = c;
        c = b;
        b = b + (sum << s | sum >>> 32 - s) >>> 0;
      }
      a0 = a0 + a >>> 0;
      b0 = b0 + b >>> 0;
      c0 = c0 + c >>> 0;
      d0 = d0 + d >>> 0;
    }
    const out = new Uint8Array(16);
    const ov = new DataView(out.buffer);
    [a0, b0, c0, d0].forEach((v, i) => ov.setUint32(i * 4, v, true));
    return out;
  }

  // server/src/game/devHandlers.ts
  var WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
  async function sha1Base64(s) {
    const digest = new Uint8Array(await crypto.subtle.digest("SHA-1", new TextEncoder().encode(s)));
    let bin = "";
    for (const b of digest) bin += String.fromCharCode(b);
    return btoa(bin);
  }
  function header(text, name) {
    return new RegExp(`^${name}:[ \\t]*(.*?)\\r?$`, "im").exec(text)?.[1];
  }
  function hixieKey(key) {
    const n = Number(key.replace(/\D/g, "")) / (key.split(" ").length - 1);
    const out = new Uint8Array(4);
    new DataView(out.buffer).setUint32(0, n);
    return out;
  }
  function installHandshakeDemo(emu, greeting = "hello from the 2012 emulator") {
    const hello = () => `${greeting}; clock=${emu.clock.now().toISOString().slice(0, 10)}`;
    emu.onUnhandled(async (s, msg) => {
      const st = s.data.demo ??= { buf: new Uint8Array(0) };
      st.buf = concat(st.buf, msg.raw);
      if (!st.mode) {
        const text = fromUtf8(st.buf);
        const end = text.indexOf("\r\n\r\n");
        if (end < 0) return;
        const headBytes = utf8(text.slice(0, end + 4)).length;
        const key = header(text, "Sec-WebSocket-Key");
        if (key) {
          st.mode = "rfc6455";
          st.buf = st.buf.slice(headBytes);
          s.sendBytes(
            utf8(
              `HTTP/1.1 101 Switching Protocols\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Accept: ${await sha1Base64(key + WS_GUID)}\r
\r
`
            ),
            "demo: rfc6455 upgrade"
          );
          s.sendBytes(concat(new Uint8Array([129, utf8(hello()).length]), utf8(hello())), "demo: greeting");
          return;
        }
        const k1 = header(text, "Sec-WebSocket-Key1");
        const k2 = header(text, "Sec-WebSocket-Key2");
        if (k1 && k2) {
          if (st.buf.length < headBytes + 8) return;
          const key3 = st.buf.slice(headBytes, headBytes + 8);
          st.buf = st.buf.slice(headBytes + 8);
          st.mode = "hixie76";
          const host = header(text, "Host") ?? "localhost";
          const origin = header(text, "Origin") ?? "null";
          const path = /^GET (\S+)/.exec(text)?.[1] ?? "/";
          s.sendBytes(
            concat(
              utf8(
                `HTTP/1.1 101 WebSocket Protocol Handshake\r
Upgrade: WebSocket\r
Connection: Upgrade\r
Sec-WebSocket-Origin: ${origin}\r
Sec-WebSocket-Location: ws://${host}${path}\r
\r
`
              ),
              md5(concat(hixieKey(k1), hixieKey(k2), key3))
            ),
            "demo: hixie-76 upgrade"
          );
          s.sendBytes(concat(new Uint8Array([0]), utf8(hello()), new Uint8Array([255])), "demo: greeting");
          return;
        }
        s.note("demo: not a WebSocket upgrade");
        return;
      }
      if (st.mode === "hixie76") {
        for (; ; ) {
          const endIdx = st.buf.indexOf(255);
          if (st.buf[0] !== 0 || endIdx < 0) break;
          const text = fromUtf8(st.buf.subarray(1, endIdx));
          st.buf = st.buf.slice(endIdx + 1);
          s.sendBytes(concat(new Uint8Array([0]), utf8("echo: " + text), new Uint8Array([255])), "demo: echo");
        }
        return;
      }
      const b = st.buf;
      if (b.length < 6) return;
      const len = b[1] & 127;
      if (b.length < 6 + len) return;
      const mask = b.subarray(2, 6);
      const data = b.subarray(6, 6 + len).map((x, i) => x ^ mask[i % 4]);
      st.buf = b.slice(6 + len);
      const reply = utf8("echo: " + fromUtf8(data));
      s.sendBytes(concat(new Uint8Array([129, reply.length]), reply), "demo: echo");
    });
  }

  // server/src/game/sfs2013/saves.ts
  var SAVE_FORMAT = "aola-revival-save";
  var SAVE_VERSION = 1;
  var SAVE_RECORD_MAX = 15e5;
  var jsonBytes = (v) => new TextEncoder().encode(JSON.stringify(v)).length;
  var SERVER_FIELDS = ["id", "name", "pass", "friends", "friendAsks"];
  var KINDS = {
    pets: "array",
    storage: "array",
    training: "array",
    plants: "array",
    items: "object",
    house: "object",
    tasks: "object",
    robot: "object",
    boosts: "object",
    hatch: "object",
    gameLevels: "object",
    gathered: "object",
    gameCoins: "object",
    dailyFights: "object",
    score: "number",
    xingbi: "number",
    jingdou: "number",
    nextPetId: "number",
    followPet: "number",
    catchExp: "number",
    nextPlantId: "number",
    avatar: "string",
    createdAt: "string",
    kit: "boolean",
    vip: "boolean"
  };
  var kindOf = (v) => Array.isArray(v) ? "array" : v === null ? "null" : typeof v;
  var isObject = (v) => kindOf(v) === "object";
  var num = (v, lo, hi) => typeof v === "number" && Number.isFinite(v) ? Math.max(lo, Math.min(hi, v)) : void 0;
  var int = (v, lo, hi) => {
    const n = num(v, lo, hi);
    return n === void 0 ? void 0 : Math.trunc(n);
  };
  var str = (v, max) => typeof v === "string" ? v.slice(0, max) : void 0;
  var nums = (v, n, lo, hi) => {
    if (!Array.isArray(v) || v.length !== n) return void 0;
    const out = v.map((x) => num(x, lo, hi));
    return out.every((x) => x !== void 0) ? out : void 0;
  };
  function fitPet(v) {
    if (!isObject(v)) return null;
    const id = int(v.id, 1, 1e9), race = int(v.race, 1, 1e7), level = int(v.level, 1, 100);
    if (id === void 0 || race === void 0 || level === void 0) return null;
    const skills = (Array.isArray(v.skills) ? v.skills : []).flatMap((k) => {
      if (!isObject(k)) return [];
      const sid = int(k.id, 0, 1e7), max = int(k.max, 0, 1e3), pp = int(k.pp, 0, 1e3);
      return sid === void 0 ? [] : [{ id: sid, name: str(k.name, 32) ?? "", pp: Math.min(pp ?? max ?? 0, max ?? 1e3), max: max ?? pp ?? 0 }];
    });
    const out = {
      id,
      race,
      level,
      exp: num(v.exp, 0, 1e12) ?? 0,
      hp: num(v.hp, 0, 1e7) ?? 0,
      character: str(v.character, 16) ?? "",
      skills: skills.slice(0, 8),
      got: str(v.got, 32) ?? ""
    };
    const nick = str(v.nick, 32);
    if (nick !== void 0) out.nick = nick;
    if (Array.isArray(v.learned)) out.learned = v.learned.flatMap((x) => int(x, 0, 1e7) === void 0 ? [] : [int(x, 0, 1e7)]).slice(0, 500);
    const iv = nums(v.iv, 6, 0, 31), ev = nums(v.ev, 6, 0, 1e6), mul = nums(v.mul, 6, 0, 1e4);
    if (iv && ev) {
      out.iv = iv.map(Math.trunc);
      out.ev = ev;
    }
    if (mul) out.mul = mul;
    const mod = str(v.mod, 64);
    if (mod !== void 0) out.mod = mod;
    if (typeof v.fixed === "boolean") out.fixed = v.fixed;
    if (isObject(v.buff) && int(v.buff.i, 0, 5) !== void 0 && num(v.buff.add, -1e6, 1e6) !== void 0) {
      out.buff = { i: int(v.buff.i, 0, 5), add: num(v.buff.add, -1e6, 1e6) };
    }
    if (Array.isArray(v.cards)) out.cards = v.cards.slice(0, 3).map((x) => int(x, 0, 1e7) ?? 0);
    return out;
  }
  function fitItems(v) {
    const out = {};
    if (!isObject(v)) return out;
    for (const [type, ids] of Object.entries(v)) {
      if (!isObject(ids)) continue;
      const row = {};
      for (const [id, q] of Object.entries(ids)) {
        const n = int(q, 0, 1e9);
        if (n !== void 0) row[id] = n;
      }
      out[type] = row;
    }
    return out;
  }
  function fileProblem(file) {
    if (!isObject(file) || file.format !== SAVE_FORMAT || !isObject(file.data)) return "\u8FD9\u4E0D\u662F\u5965\u62C9\u661F\u7684\u5B58\u6863\u6587\u4EF6\u3002";
    if (typeof file.version !== "number" || file.version > SAVE_VERSION) return "\u8FD9\u4E2A\u5B58\u6863\u6587\u4EF6\u662F\u66F4\u65B0\u7684\u7248\u672C\uFF0C\u8FD9\u91CC\u8BFB\u4E0D\u4E86\u3002";
    return null;
  }
  function rolesOf(file) {
    const out = /* @__PURE__ */ new Map();
    for (const [k, v] of Object.entries(file.data)) {
      if (!k.startsWith("user/") || !isObject(v)) continue;
      let name;
      try {
        name = typeof v.name === "string" && v.name ? v.name : decodeURIComponent(k.slice("user/".length));
      } catch {
        continue;
      }
      out.set(name, v);
    }
    return out;
  }
  function playerFile(rec, key, saved) {
    const copy = structuredClone(rec);
    delete copy.pass;
    delete copy.friends;
    delete copy.friendAsks;
    return {
      format: SAVE_FORMAT,
      version: SAVE_VERSION,
      saved,
      // uid and the counter: the page that takes the file in knows the id, and gives the next 奥拉 another.
      data: { [key]: copy, [`uid/${rec.id}`]: rec.name, "meta/nextUserId": rec.id }
    };
  }
  function adoptRecord(from, here) {
    const out = {};
    for (const [k, v] of Object.entries(structuredClone(from))) {
      if (SERVER_FIELDS.includes(k)) continue;
      const want = KINDS[k];
      if (want && kindOf(v) !== want) continue;
      if (want === "number" && !Number.isFinite(v)) continue;
      out[k] = v;
    }
    const seen = /* @__PURE__ */ new Set();
    for (const k of ["pets", "storage"]) {
      if (!Array.isArray(out[k])) continue;
      out[k] = out[k].flatMap((p) => {
        const f = fitPet(p);
        if (!f || seen.has(f.id)) return [];
        seen.add(f.id);
        return [f];
      });
    }
    if (Array.isArray(out.pets) && out.pets.length > 6) {
      out.storage = [...out.storage ?? [], ...out.pets.slice(6)];
      out.pets = out.pets.slice(0, 6);
    }
    if (out.items !== void 0) out.items = fitItems(out.items);
    const ids = [...out.pets ?? [], ...out.storage ?? []].map((p) => p.id);
    if (ids.length) out.nextPetId = Math.max(Number(out.nextPetId) || 0, ...ids);
    for (const k of SERVER_FIELDS) if (here[k] !== void 0) out[k] = structuredClone(here[k]);
    if (out.createdAt === void 0 && here.createdAt !== void 0) out.createdAt = here.createdAt;
    return out;
  }

  // server/src/game/sfs2013/pmdata.ts
  var EMPTY_PMDATA = { species: {}, skills: {}, chart: {}, exp: {} };
  var NATURES = {
    \u5B64\u50FB: [1, 2],
    \u56FA\u6267: [1, 3],
    \u8C03\u76AE: [1, 4],
    \u52C7\u6562: [1, 5],
    \u5766\u7387: [0, 0],
    \u5927\u80C6: [2, 1],
    \u6DD8\u6C14: [2, 3],
    \u65E0\u8651: [2, 4],
    \u60A0\u95F2: [2, 5],
    \u5BB3\u7F9E: [0, 0],
    \u4FDD\u5B88: [3, 1],
    \u7A33\u91CD: [3, 2],
    \u9A6C\u864E: [3, 4],
    \u51B7\u9759: [3, 5],
    \u8BA4\u771F: [0, 0],
    \u6C89\u7740: [4, 1],
    \u6E29\u987A: [4, 2],
    \u614E\u91CD: [4, 3],
    \u72C2\u5984: [4, 5],
    \u5B9E\u5E72: [0, 0],
    \u80C6\u5C0F: [5, 1],
    \u6025\u8E81: [5, 2],
    \u5F00\u6717: [5, 3],
    \u5929\u771F: [5, 4],
    \u6D6E\u8E81: [0, 0]
  };
  var NATURE_NAMES = Object.keys(NATURES);
  var MAX_IV = 62;
  function calcStats(sp, level, iv = [], ev = [], nature) {
    const n = nature ? NATURES[nature] : void 0;
    return sp.s.map((base, i) => {
      const core = Math.floor((2 * base + (iv[i] ?? 31) + Math.floor((ev[i] ?? 0) / 4)) * level / 100);
      if (i === 0) return core + level + 10;
      const mod = n && n[0] !== n[1] ? n[0] === i ? 1.1 : n[1] === i ? 0.9 : 1 : 1;
      return Math.floor((core + 5) * mod);
    });
  }
  function curve(pm, sp) {
    return pm.exp[sp?.xt ?? "0"] ?? pm.exp["0"];
  }
  function expNeed(pm, sp, level) {
    const c = curve(pm, sp);
    if (!c || level >= c.length) return 20 + level * level * 4;
    return Math.max(1, c[level] - c[level - 1]);
  }
  function expYield(sp, level) {
    return Math.max(1, Math.floor((sp?.bx ?? 50) * level / 7));
  }
  function skillsAt(sp, level) {
    const ids = [];
    for (const [lv, id] of sp.learn) {
      if (lv > level) break;
      const at = ids.indexOf(id);
      if (at >= 0) ids.splice(at, 1);
      ids.push(id);
    }
    return ids.slice(-4);
  }
  function allSkillsAt(sp, level) {
    const ids = [];
    for (const [lv, id] of sp.learn) {
      if (lv > level) break;
      if (!ids.includes(id)) ids.push(id);
    }
    return ids;
  }
  function skillsLearntAt(sp, level) {
    return sp.learn.filter(([lv]) => lv === level && level > 0).map(([, id]) => id);
  }
  function evolutionAt(sp, race, level) {
    const steps = sp.evo.split("#").map((s) => s.split("-").map(Number)).filter((x) => x.length === 2 && !x.some(Number.isNaN));
    const i = steps.findIndex(([, r]) => r === race);
    if (i < 0 || i + 1 >= steps.length) return 0;
    const [lv, next] = steps[i + 1];
    return lv > 0 && level >= lv ? next : 0;
  }
  function typeMultiplier(pm, atk, def) {
    const row = pm.chart[String(atk)] ?? {};
    const m1 = row[String(def[0])] ?? 1;
    const m2 = def[1] !== def[0] ? row[String(def[1])] ?? 1 : 1;
    return m1 * m2;
  }
  var CATCH_TABLE = (() => {
    const t = [0, 0];
    for (let n = 2; n <= 101; n++) t.push(t[n - 1] + (n - 1) * 30 + Math.round((n - 1) / 10) * (n - 1) * 15);
    return t;
  })();
  function catchLevel(total) {
    let clv = 1;
    while (clv < 100 && CATCH_TABLE[clv + 1] <= total) clv++;
    const span = CATCH_TABLE[clv + 1] - CATCH_TABLE[clv];
    const ccle = Math.min(span, total - CATCH_TABLE[clv]);
    return { clv, ccle, cnx: span - ccle, pct: Math.floor(ccle / span * 100) };
  }

  // server/src/game/sfs2013/fighting.ts
  var fights = /* @__PURE__ */ new WeakMap();
  function registerFights(world, byOwner) {
    fights.set(world, byOwner);
  }
  function inFight(world, id) {
    return fights.get(world)?.has(id) ?? false;
  }

  // server/src/game/sfs2013/petcards.ts
  var PET_CARD = 8;
  var CARD_DROP = 25;
  var PET_CARDS = {
    1: { name: "\u5FE0\u8BDA\u4E4B\u6597\u58EB\u5361", type: 0, color: 0, hp: 20, sp: -10, at: 0, de: 0, sa: 0, sd: 0 },
    2: { name: "\u654F\u611F\u4E4B\u6597\u58EB\u5361", type: 0, color: 0, hp: -10, sp: 20, at: 0, de: 0, sa: 0, sd: 0 },
    3: { name: "\u5B64\u50FB\u4E4B\u6597\u58EB\u5361", type: 1, color: 0, hp: 0, sp: 0, at: 20, de: -10, sa: 0, sd: 0 },
    4: { name: "\u8C03\u76AE\u4E4B\u6597\u58EB\u5361", type: 1, color: 0, hp: 0, sp: 0, at: 20, de: 0, sa: 0, sd: -10 },
    5: { name: "\u56FA\u6267\u4E4B\u6597\u58EB\u5361", type: 1, color: 0, hp: 0, sp: 0, at: 20, de: 0, sa: -10, sd: 0 },
    6: { name: "\u65E0\u8651\u4E4B\u6597\u58EB\u5361", type: 2, color: 0, hp: 0, sp: 0, at: 0, de: 20, sa: 0, sd: -10 },
    7: { name: "\u4F53\u529B\u4E4B\u6B66\u8005\u5361", type: 0, color: 1, hp: 25, sp: 0, at: 0, de: 0, sa: 0, sd: 0 },
    8: { name: "\u901F\u5EA6\u4E4B\u6B66\u8005\u5361", type: 0, color: 1, hp: 0, sp: 25, at: 0, de: 0, sa: 0, sd: 0 },
    9: { name: "\u653B\u51FB\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 25, de: 0, sa: 0, sd: 0 },
    10: { name: "\u7279\u653B\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 25, sd: 0 },
    11: { name: "\u9632\u5FA1\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 25, sa: 0, sd: 0 },
    12: { name: "\u7279\u9632\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 0, sd: 25 },
    13: { name: "\u5F3A\u608D\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 15, de: 15, sa: 0, sd: 0 },
    14: { name: "\u667A\u8C0B\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 15, sd: 15 },
    15: { name: "\u94C1\u58C1\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 15, sa: 0, sd: 15 },
    16: { name: "\u4F53\u529B\u4E4B\u52C7\u8005\u5361", type: 0, color: 2, hp: 80, sp: 0, at: 0, de: 0, sa: 0, sd: 0 },
    17: { name: "\u654F\u611F\u4E4B\u6B66\u8005\u5361", type: 0, color: 1, hp: -30, sp: 35, at: 0, de: 0, sa: 0, sd: 0 },
    18: { name: "\u5B64\u50FB\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 35, de: -25, sa: 0, sd: 0 },
    19: { name: "\u6D1E\u5BDF\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 35, sd: -25 },
    20: { name: "\u6DD8\u6C14\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 50, sa: -20, sd: 0 },
    21: { name: "\u6C89\u7740\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: -20, de: 0, sa: 0, sd: 50 },
    22: { name: "\u9632\u5FA1\u4E4B\u52C7\u8005\u5361", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 80, sa: 0, sd: 0 },
    23: { name: "\u7279\u9632\u4E4B\u52C7\u8005\u5361", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 0, sa: 0, sd: 80 },
    24: { name: "\u901F\u5EA6\u4E4B\u52C7\u8005\u5361", type: 0, color: 2, hp: 0, sp: 60, at: 0, de: 0, sa: 0, sd: 0 },
    25: { name: "\u56FA\u6267\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: 35, de: 0, sa: -25, sd: 0 },
    26: { name: "\u4FDD\u5B88\u4E4B\u6B66\u8005\u5361", type: 1, color: 1, hp: 0, sp: 0, at: -25, de: 0, sa: 35, sd: 0 },
    27: { name: "\u65E0\u8651\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 50, sa: 0, sd: -20 },
    28: { name: "\u6E29\u987A\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: -20, sa: 0, sd: 50 },
    29: { name: "\u94C1\u58C1\u4E4B\u52C7\u8005\u5361", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 45, sa: 0, sd: 45 },
    30: { name: "\u5F3A\u4F53\u4E4B\u52C7\u8005\u5361", type: 0, color: 2, hp: 100, sp: 0, at: -40, de: 0, sa: -40, sd: 0 },
    31: { name: "\u5927\u80C6\u4E4B\u52C7\u8005\u5361", type: 2, color: 2, hp: 0, sp: 0, at: -50, de: 90, sa: 0, sd: 0 },
    32: { name: "\u614E\u91CD\u4E4B\u52C7\u8005\u5361", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 0, sa: -50, sd: 90 },
    33: { name: "\u8D85\u653B\u4E4B\u52C7\u8005\u5361", type: 1, color: 2, hp: 0, sp: 0, at: 40, de: 0, sa: 40, sd: 0 },
    34: { name: "\u5927\u80C6\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: -20, de: 40, sa: 0, sd: 0 },
    35: { name: "\u614E\u91CD\u4E4B\u6B66\u8005\u5361", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: -20, sd: 40 }
  };
  function cardBonus(cards) {
    const add = [0, 0, 0, 0, 0, 0];
    for (const id of cards ?? []) {
      const c = PET_CARDS[id];
      if (!c) continue;
      add[0] += c.hp;
      add[1] += c.at;
      add[2] += c.de;
      add[3] += c.sa;
      add[4] += c.sd;
      add[5] += c.sp;
    }
    return add;
  }
  function cardsOf(pet) {
    return [0, 1, 2].map((i) => Number(pet.cards?.[i]) || 0);
  }
  function cardDrop(rng = Math.random) {
    if (rng() * 100 >= CARD_DROP) return 0;
    const ids = Object.keys(PET_CARDS).map(Number);
    const weights = ids.map((id) => PET_CARDS[id].color === 2 ? 1 : 3);
    let r = rng() * weights.reduce((a, b) => a + b, 0);
    for (let i = 0; i < ids.length; i++) if ((r -= weights[i]) < 0) return ids[i];
    return ids[ids.length - 1];
  }
  function installPetCards(world, deps) {
    world.xt("MaterialExtension.61_7", async (ctx) => {
      const o = await deps.load(ctx);
      const have = o.items?.[String(PET_CARD)] ?? {};
      const cards = Object.entries(have).filter(([id, n]) => n > 0 && PET_CARDS[Number(id)]).map(([id, n]) => ({ id: Number(id), qt: n, uq: 0 }));
      ctx.reply({ cards }, "61_7");
    });
    world.xt("PetExtension.54_25", async (ctx) => {
      const o = await deps.load(ctx);
      const pid = Number(ctx.params.pid) | 0, cid = Number(ctx.params.cid) | 0;
      const pet = (o.pets ?? []).find((p) => p.id === pid);
      const reply = (res, msg2, cards2 = pet ? cardsOf(pet) : [0, 0, 0]) => ctx.reply({ res, pid, cid, cards: cards2, msg: msg2 }, "54_25");
      if (!pet) return reply(0, "\u80CC\u5305\u91CC\u6CA1\u6709\u8FD9\u53EA\u4E9A\u6BD4\u3002");
      if (cid === 0) return reply(1, "");
      const def = PET_CARDS[cid];
      if (!def) return reply(0, "\u6CA1\u6709\u8FD9\u79CD\u6218\u672F\u5361\u3002");
      const have = (o.items ??= {})[String(PET_CARD)] ??= {};
      const cards = cardsOf(pet);
      const changed = [];
      let msg;
      if (cards[def.type] === cid) {
        cards[def.type] = 0;
        changed.push([cid, 1]);
        msg = `\u53D6\u4E0B\u4E86\u300C${def.name}\u300D\u3002`;
      } else {
        if (!((have[String(cid)] ?? 0) > 0)) return reply(0, "\u4F60\u6CA1\u6709\u8FD9\u5F20\u6218\u672F\u5361\u3002");
        const before = cards[def.type];
        cards[def.type] = cid;
        changed.push([cid, -1]);
        if (before) changed.push([before, 1]);
        msg = `\u88C5\u4E0A\u4E86\u300C${def.name}\u300D\u3002`;
      }
      for (const [id, d] of changed) {
        const n = (have[String(id)] ?? 0) + d;
        if (n > 0) have[String(id)] = n;
        else delete have[String(id)];
      }
      pet.cards = cards.some(Boolean) ? cards : void 0;
      pet.hp = Math.min(pet.hp, await deps.maxHp(o, pet));
      await deps.save(o);
      for (const [id, d] of changed) ctx.reply({ amount: `${PET_CARD}_${id}_0_${d}` }, "onAmountUpdated");
      reply(1, msg, cards);
    });
  }

  // server/src/game/sfs2013/pets.ts
  var RELEASE_KEEP_MS = 7 * 24 * 3600 * 1e3;
  function dropOldReleased(o, now) {
    const before = o.released?.length ?? 0;
    if (!before) return false;
    o.released = o.released.filter((p) => now - (p.relAt ?? 0) < RELEASE_KEEP_MS);
    return o.released.length !== before;
  }
  var GROWTH = [
    [20, 3],
    [10, 2],
    [10, 2],
    [10, 2],
    [10, 2],
    [10, 2]
  ];
  function speciesOf(t, race) {
    return t.pm.species[String(race)];
  }
  function nameOf(t, race) {
    return t.pm.species[String(race)]?.n ?? t.species[String(race)]?.n ?? `\u4E9A\u6BD4${race}`;
  }
  function statsOf(p, t) {
    const sp = t ? speciesOf(t, p.race) : void 0;
    const base = sp ? calcStats(sp, p.level, p.iv, p.ev, p.character) : GROWTH.map(([b, k]) => b + k * p.level);
    const mul = p.mul ? base.map((v, i) => Math.max(1, Math.round(v * (p.mul[i] ?? 1)))) : base;
    if (!p.cards?.some(Boolean)) return mul;
    const add = cardBonus(p.cards);
    return mul.map((v, i) => Math.max(1, v + add[i]));
  }
  function maxHpOf(p, t) {
    return statsOf(p, t)[0];
  }
  function expToNext(p, t) {
    return expNeed(t?.pm ?? EMPTY_PMDATA, t ? speciesOf(t, p.race) : void 0, p.level);
  }
  function skillOf(t, id, pp) {
    const s = t.pm.skills[String(id)];
    const max = s?.pp ?? 20;
    return { id, name: s?.n ?? `\u6280\u80FD${id}`, pp: pp ?? max, max };
  }
  function skillsFor(t, race, level) {
    const sp = speciesOf(t, race);
    if (sp && sp.learn.length) return skillsAt(sp, level).map((id) => skillOf(t, id));
    const names = t.species[String(race)]?.sk ?? [];
    const n = Math.max(2, Math.min(4, 1 + Math.floor(level / 5)));
    return names.slice(0, n).map((name, i) => ({ id: race * 100 + i + 1, name, pp: 20, max: 20 }));
  }
  function randomIv() {
    return Array.from({ length: 6 }, () => Math.floor(Math.random() * (MAX_IV + 1)));
  }
  function randomNature() {
    return NATURE_NAMES[Math.floor(Math.random() * NATURE_NAMES.length)];
  }
  function learntFor(t, race, level, carried) {
    const sp = speciesOf(t, race);
    const all = sp && sp.learn.length ? allSkillsAt(sp, level) : [];
    return [.../* @__PURE__ */ new Set([...all, ...carried.map((s) => s.id)])];
  }
  function makePet(t, race, level, today, id = 0, character) {
    const skills = skillsFor(t, race, level);
    const p = {
      id,
      race,
      level,
      exp: 0,
      hp: 0,
      character: character ?? randomNature(),
      skills,
      // A 亚比 given at a high level (the 工具箱, a task) knows every skill of its line up to it.
      learned: learntFor(t, race, level, skills),
      iv: randomIv(),
      ev: [0, 0, 0, 0, 0, 0],
      got: today
    };
    p.hp = statsOf(p, t)[0];
    return p;
  }
  function newPet(owner, t, race, level, today) {
    const id = owner.nextPetId = (owner.nextPetId ?? 0) + 1;
    return makePet(t, race, level, today, id);
  }
  function normalisePet(p, t) {
    let changed = false;
    if (!p.iv) {
      p.iv = [31, 31, 31, 31, 31, 31];
      p.ev = [0, 0, 0, 0, 0, 0];
      changed = true;
    }
    if (!NATURES[p.character]) {
      p.character = randomNature();
      changed = true;
    }
    const sp = speciesOf(t, p.race);
    if (sp && p.skills.some((s) => !t.pm.skills[String(s.id)])) {
      p.skills = skillsFor(t, p.race, p.level);
      p.learned = p.skills.map((s) => s.id);
      changed = true;
    }
    const max = statsOf(p, t)[0];
    if (p.hp > max) {
      p.hp = max;
      changed = true;
    }
    return changed;
  }
  function sView(p, owner, t) {
    const st = statsOf(p, t);
    return {
      i: p.id,
      ch: p.character,
      c0: Math.min(p.hp, st[0]),
      lv: p.level,
      s0: `${st[0]}#0`,
      nm: nameOf(t, p.race),
      nick: p.nick ?? "",
      r: p.race,
      f: 0,
      st: "",
      st2: "",
      cr1: 0,
      cr2: 0,
      sks: p.skills.map((s) => s.id).join(","),
      m: owner.id,
      pcp: '<pcp r="0" sc=""/>',
      drs: "",
      // Not a 2013 field: the 亚比's first attribute, for the rebuilt battle screen.
      t: speciesOf(t, p.race)?.t[0] ?? t.species[String(p.race)]?.a ?? 0
    };
  }
  function skillList(p, t) {
    return p.skills.map((s) => {
      const d = t.pm.skills[String(s.id)];
      return { id: s.id, name: s.name, pp: `${s.pp}/${s.max}`, ssi: 0, used: true, t: d?.t ?? 0, k: d?.k ?? 0, pw: d?.p ?? 0, d: d?.d ?? "" };
    });
  }
  function briefOf(p, owner, t, extra) {
    const v = sView(p, owner, t);
    if (extra?.st) v.st = extra.st;
    if (extra?.bal) v.bal = extra.bal;
    return { pmSView: v, skills: skillList(p, t), eqp: [] };
  }
  function detailOf(p, owner, t) {
    const st = statsOf(p, t);
    const v = sView(p, owner, t);
    const need = expToNext(p, t);
    const sp = speciesOf(t, p.race);
    const iv = p.iv ?? [31, 31, 31, 31, 31, 31];
    const ev = p.ev ?? [0, 0, 0, 0, 0, 0];
    return {
      pmPView: {
        ...v,
        curExp: p.exp,
        curHp: v.c0,
        curAtt: st[1],
        curDef: st[2],
        curSAtt: st[3],
        curSDef: st[4],
        curSpd: st[5],
        s1: `${st[1]}#0`,
        s2: `${st[2]}#0`,
        s3: `${st[3]}#0`,
        s4: `${st[4]}#0`,
        s5: `${st[5]}#0`,
        nx: Math.max(0, need - p.exp),
        totalRace: sp ? sp.s.reduce((a, b) => a + b, 0) : st.reduce((a, b) => a + b, 0),
        speciality: "",
        lc: 0,
        d: p.got,
        "lu%": Math.floor(p.exp / need * 100),
        i0: iv[0],
        i1: iv[1],
        i2: iv[2],
        i3: iv[3],
        i4: iv[4],
        i5: iv[5],
        e0: ev[0],
        e1: ev[1],
        e2: ev[2],
        e3: ev[3],
        e4: ev[4],
        e5: ev[5],
        cle: p.exp,
        t: sp?.t[0] ?? t.species[String(p.race)]?.a ?? 0
      },
      skills: skillList(p, t),
      eqp: []
    };
  }
  function catchFields(o) {
    const c = catchLevel(o.catchExp ?? 0);
    return { clv: c.clv, ccle: c.ccle, "clu%": c.pct, cnx: c.cnx };
  }
  var STARTERS = /* @__PURE__ */ new Set([1, 4, 7]);
  var EXT = "PocketMonsterExtension";
  var NO_FOLLOW = "0#0#0";
  function followVar(p) {
    return `${p.race},${p.race},${p.id},,,0`;
  }
  function installPets(world, deps) {
    const list = (o) => o.pets ??= [];
    const loadAll = async (ctx) => {
      const o = await deps.load(ctx);
      const t = await deps.tables();
      let changed = false;
      for (const p of [...list(o), ...o.storage ?? []]) changed = normalisePet(p, t) || changed;
      if (changed) await deps.save(o);
      return { o, t };
    };
    world.xt(`${EXT}.1101`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      const pets = list(o);
      ctx.reply(
        {
          simpleView: {
            curPM: pets[0] ? briefOf(pets[0], o, t) : void 0,
            pmCanBattle: pets.filter((p) => p.hp > 0).length,
            pmmId: o.id,
            slotId: 0,
            pmExp: 0
          },
          ...catchFields(o)
        },
        "2101"
      );
    });
    world.xt(`${EXT}.1212`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      const pets = list(o);
      ctx.reply({ pmList: pets.map((p) => briefOf(p, o, t)), pms: pets[0] ? `${pets[0].id}#` : "", cui: 0, prv: [] }, "2212");
    });
    const STORAGE_PAGE = 9;
    const now = () => deps.now ? deps.now() : Date.now();
    const attrOf = (t, p) => speciesOf(t, p.race)?.t[0] ?? t.species[String(p.race)]?.a ?? 0;
    const located = (o, loc) => loc === 1 || loc === 2 ? o.storage ??= [] : loc === 4 ? (o.storage ?? []).filter((p) => p.elite) : loc === 3 ? o.released ?? [] : list(o);
    world.xt(`${EXT}.1213`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      if (dropOldReleased(o, now())) await deps.save(o);
      const loc = Number(ctx.params.loc) | 0;
      const type = Number(ctx.params.pmType) | 0;
      const order = Number(ctx.params.order) | 0;
      const asc = ctx.params.asc === void 0 ? true : ctx.params.asc === true || ctx.params.asc === "true" || Number(ctx.params.asc) === 1;
      const size = Math.max(1, Math.min(60, Number(ctx.params.size) | 0 || STORAGE_PAGE));
      let all = located(o, loc).slice();
      if (type > 0) all = all.filter((p) => attrOf(t, p) === type);
      if (order === 2) all.sort((a, b) => a.level - b.level || a.id - b.id);
      if ((order === 1 || order === 2) && !asc) all.reverse();
      const pages = Math.max(1, Math.ceil(all.length / size));
      const page = Math.max(1, Math.min(pages, Number(ctx.params.page) | 0));
      const shown = loc === 0 ? all : all.slice((page - 1) * size, page * size);
      const left = (p) => Math.max(0, Math.ceil((RELEASE_KEEP_MS - (now() - (p.relAt ?? 0))) / (24 * 3600 * 1e3)));
      const pmList = shown.map((p) => {
        const b = briefOf(p, o, t);
        return { ...b, pmSView: { ...b.pmSView, el: p.elite ? 1 : 0, sh: o.showPet === p.id ? 1 : 0, ...loc === 3 ? { rl: left(p) } : {} } };
      });
      ctx.reply({ pmType: type, loc, page, totalPage: pages, pages, total: all.length, pmList }, "2213");
    });
    world.xt(`${EXT}.1224`, async (ctx) => {
      const o = await deps.load(ctx);
      dropOldReleased(o, now());
      const id = Number(ctx.params.id);
      const loc = Number(ctx.params.loc) | 0;
      const bag3 = list(o);
      const store = o.storage ??= [];
      const gone = o.released ??= [];
      const answer = (result) => ctx.reply({ result, id, loc }, "2224");
      const back = gone.findIndex((p2) => p2.id === id);
      if (back >= 0) {
        if (loc === 0 && bag3.length >= 6) return answer(-2);
        const [p2] = gone.splice(back, 1);
        delete p2.relAt;
        (loc === 0 ? bag3 : store).push(p2);
        await deps.save(o);
        return answer(1);
      }
      const from = loc === 1 ? bag3 : store;
      const to = loc === 1 ? store : bag3;
      const i = from.findIndex((p2) => p2.id === id);
      if (i < 0) return answer(-1);
      if (loc === 0 && bag3.length >= 6) return answer(-2);
      if (loc === 1 && bag3.length <= 1) return answer(-3);
      const [p] = from.splice(i, 1);
      to.push(p);
      if (loc === 1 && o.followPet === id) o.followPet = 0;
      await deps.save(o);
      answer(1);
    });
    world.xt(`${EXT}.1225`, async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id);
      const e = ctx.params.e === true || ctx.params.e === "true" || Number(ctx.params.e) === 1;
      const p = [...list(o), ...o.storage ?? []].find((x) => x.id === id);
      if (!p) return ctx.reply({ result: -1, id, e }, "2225");
      if (e) p.elite = true;
      else delete p.elite;
      await deps.save(o);
      ctx.reply({ result: 1, id, e }, "2225");
    });
    world.xt(`${EXT}.revival_release`, async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id);
      const answer = (result) => ctx.reply({ result, id }, "revival_release");
      const bag3 = list(o);
      const store = o.storage ??= [];
      const inBag = bag3.findIndex((p2) => p2.id === id);
      const inStore = store.findIndex((p2) => p2.id === id);
      if (inBag < 0 && inStore < 0) return answer(-1);
      if (inBag >= 0 && bag3.length <= 1) return answer(-3);
      const [p] = inBag >= 0 ? bag3.splice(inBag, 1) : store.splice(inStore, 1);
      p.relAt = now();
      delete p.elite;
      (o.released ??= []).push(p);
      dropOldReleased(o, now());
      if (o.followPet === id) o.followPet = 0;
      if (o.showPet === id) o.showPet = 0;
      await deps.save(o);
      answer(1);
    });
    world.xt(`${EXT}.revival_nick`, async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id);
      const nick = String(ctx.params.nick ?? "").replace(/\s+/g, "").slice(0, 32);
      const p = [...list(o), ...o.storage ?? []].find((x) => x.id === id);
      if (!p) return ctx.reply({ result: -1, id, nick }, "revival_nick");
      if ([...nick].length > 6 || /[<>&"'\\]/.test(nick)) return ctx.reply({ result: -2, id, nick }, "revival_nick");
      if (nick) p.nick = nick;
      else delete p.nick;
      await deps.save(o);
      ctx.reply({ result: 1, id, nick }, "revival_nick");
    });
    world.xt(`${EXT}.revival_show`, async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      const has = id > 0 && [...list(o), ...o.storage ?? []].some((x) => x.id === id);
      if (id > 0 && !has) return ctx.reply({ result: -1, id }, "revival_show");
      o.showPet = id > 0 && o.showPet !== id ? id : 0;
      await deps.save(o);
      ctx.reply({ result: 1, id: o.showPet }, "revival_show");
    });
    world.xt(`${EXT}.1211`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      const p = [...list(o), ...o.storage ?? [], ...o.released ?? []].find((x) => x.id === Number(ctx.params.id));
      if (!p) return ctx.reply({ msg: "\u6CA1\u6709\u8FD9\u53EA\u4E9A\u6BD4" }, "2211");
      const d = detailOf(p, o, t);
      const era = { id: p.id, name: p.nick || d.pmPView.nm, level: p.level, next: d.pmPView.nx, character: p.character, getDate: p.got };
      ctx.reply({ pm: { ...d, pmPView: { ...d.pmPView, el: p.elite ? 1 : 0, sh: o.showPet === p.id ? 1 : 0, ...era } } }, "2211");
    });
    world.xt(`${EXT}.1201`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      const race = Number(ctx.params.raceId);
      if (!t.species[String(race)] && !t.pm.species[String(race)]) return ctx.reply({ msg: "\u6CA1\u6709\u8FD9\u79CD\u4E9A\u6BD4" }, "2201");
      const pets = list(o);
      let level = Math.max(1, Math.min(100, Number(ctx.params.level) || 5));
      if (!deps.anyPet) {
        if (!STARTERS.has(race) || pets.length > 0 || (o.storage?.length ?? 0) > 0) return ctx.reply({ msg: "\u8FD9\u4E2A\u670D\u52A1\u5668\u5173\u95ED\u4E86\u5DE5\u5177\u7BB1\u3002" }, "2201");
        level = 5;
      }
      const p = newPet(o, t, race, level, deps.today());
      if (pets.length >= 6) {
        (o.storage ??= []).push(p);
        await deps.save(o);
        return ctx.reply({ msg: `${nameOf(t, race)}\u5DF2\u7ECF\u653E\u8FDB\u4E86\u4E9A\u6BD4\u4ED3\u5E93` }, "2201");
      }
      pets.push(p);
      await deps.save(o);
      ctx.reply({ pm: detailOf(p, o, t) }, "2201");
    });
    world.xt(`${EXT}.1221`, async (ctx) => {
      const o = await deps.load(ctx);
      const pets = list(o);
      const i = pets.findIndex((x) => x.id === Number(ctx.params.id));
      if (i > 0) [pets[0], pets[i]] = [pets[i], pets[0]];
      await deps.save(o);
      ctx.reply({ id: Number(ctx.params.id) }, "2221");
    });
    world.xt(`${EXT}.1231`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      const p = list(o).find((x) => x.id === Number(ctx.params.id));
      if (!p) return ctx.reply({ id: Number(ctx.params.id), skills: [] }, "2231");
      const carried = new Set(p.skills.map((s) => s.id));
      const all = learntFor(t, p.race, p.level, p.skills);
      if (all.some((id) => !(p.learned ?? []).includes(id))) {
        p.learned = [.../* @__PURE__ */ new Set([...p.learned ?? [], ...all])];
        await deps.save(o);
      }
      const ids = [.../* @__PURE__ */ new Set([...p.learned ?? [], ...carried])];
      ctx.reply(
        {
          id: p.id,
          skills: ids.map((id) => {
            const d = t.pm.skills[String(id)];
            return { ...skillOf(t, id), pp: `${p.skills.find((s) => s.id === id)?.pp ?? skillOf(t, id).max}/${skillOf(t, id).max}`, used: carried.has(id), power: d?.p ?? 0, kind: d?.k ?? 0, desc: d?.d ?? "" };
          })
        },
        "2231"
      );
    });
    world.xt(`${EXT}.1232`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      const p = list(o).find((x) => x.id === Number(ctx.params.id));
      const ids = String(ctx.params.sks ?? "").split(",").map(Number).filter((n) => n > 0);
      if (!p || inFight(world, o.id) || ids.length === 0 || ids.length > 4 || new Set(ids).size !== ids.length || ids.some((id) => !(p.learned ?? []).includes(id) && !p.skills.some((s) => s.id === id))) {
        return ctx.reply({ id: Number(ctx.params.id), res: -1 }, "2232");
      }
      p.skills = ids.map((id) => p.skills.find((s) => s.id === id) ?? skillOf(t, id));
      await deps.save(o);
      ctx.reply({ id: p.id, sks: ids.join(","), res: 1 }, "2232");
    });
    world.xt(`${EXT}.revival_heal`, async (ctx) => {
      const { o, t } = await loadAll(ctx);
      if (inFight(world, o.id)) return ctx.reply({ ok: 0 });
      for (const p of list(o)) {
        p.hp = statsOf(p, t)[0];
        for (const s of p.skills) s.pp = s.max;
      }
      await deps.save(o);
      ctx.reply({ ok: 1 });
    });
    world.xt(`PetExtension.54_8`, async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.pi);
      const p = list(o).find((x) => x.id === id);
      if (!p) return;
      o.followPet = id;
      await deps.save(o);
      world.setUserVars(ctx.session, { p: followVar(p) });
      ctx.broadcast({ name: o.name, pRId: p.race, pVId: p.race, pId: p.id, dr: "", ind: "", indLv: 0 }, "54_8", true);
    });
    world.xt(`PetExtension.54_9`, async (ctx) => {
      const o = await deps.load(ctx);
      o.followPet = -1;
      await deps.save(o);
      world.setUserVars(ctx.session, { p: NO_FOLLOW });
      ctx.broadcast({ name: o.name }, "54_9", true);
    });
    world.xt(`PetExtension.54_21`, async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      const pet = [...list(o), ...o.storage ?? []].find((p) => p.id === id);
      const ids = String(ctx.params.sks ?? "").split(/[,#]/).filter(Boolean).map(Number);
      const same = pet && ids.length === pet.skills.length && [...ids].sort().join() === pet.skills.map((s) => s.id).sort().join();
      if (!pet || !same) return ctx.reply({ res: 0, id }, "54_21");
      pet.skills = ids.map((sid) => pet.skills.find((s) => s.id === sid));
      await deps.save(o);
      ctx.reply({ res: 1, id }, "54_21");
    });
  }

  // server/src/game/sfs2013/tasks.ts
  var TASK_DEFS = {
    135: { steps: [136, 137, 138, 139] },
    140: { steps: [142, 143, 144, 145, 146, 147], pre: [135], auto: true },
    150: { steps: [152], pre: [140], auto: true, bonus: { score: 2e3, robotExp: 3e3 } }
  };
  function registerTaskTables(t) {
    for (const [id, d] of Object.entries(t.defines ?? {})) {
      if (d[0] === STEP_ITEMS || d[0] === STEP_BEAT_PET) STEP_RULES[Number(id)] = { type: d[0], param: d[1] };
    }
    for (const [id, st] of Object.entries(t.starters ?? {})) {
      const ti = Number(id);
      if (TASK_DEFS[ti]) continue;
      const d = t.defines[id];
      if (!d || d[0] !== 0) continue;
      TASK_DEFS[ti] = { steps: d[1].split(",").filter(Boolean).map(Number), pre: st.pre, auto: st.type === 12 };
    }
  }
  var STEP_ITEMS = 14;
  var STEP_BEAT_PET = 101;
  var STEP_RULES = {};
  function isQuestItem(id) {
    for (const rule of Object.values(STEP_RULES)) {
      if (rule.type !== STEP_ITEMS) continue;
      for (const x of (rule.param.split("|")[1] ?? "").split(",")) if (Number(x.split(":")[0]) === id) return true;
    }
    return false;
  }
  function stepsByItems(rec, now) {
    const out = { changes: [], taken: [] };
    for (const [id, rule] of Object.entries(STEP_RULES)) {
      if (rule.type !== STEP_ITEMS || !isDoing(rec, Number(id))) continue;
      const [take, list] = rule.param.split("|");
      const need = (list ?? "").split(",").filter(Boolean).map((x) => x.split(":").map(Number));
      const bag3 = rec.items?.["2"] ?? {};
      if (!need.length || need.some(([ii, n]) => (bag3[ii] ?? 0) < n)) continue;
      if (take === "1") {
        for (const [ii, n] of need) {
          bag3[ii] -= n;
          if (bag3[ii] <= 0) delete bag3[ii];
          out.taken.push([ii, n]);
        }
      }
      const r = finishStep(rec, Number(id), now);
      out.changes.push(...r.changes);
      if (r.score !== void 0) out.score = r.score;
      if (r.finished) (out.finished ??= []).push(...r.finished);
    }
    return out;
  }
  function stepsByPetWin(rec, pet, now) {
    const out = { changes: [] };
    for (const [id, rule] of Object.entries(STEP_RULES)) {
      const step = Number(id);
      if (rule.type !== STEP_BEAT_PET || !isDoing(rec, step)) continue;
      const [want, times] = rule.param.split(",").map(Number);
      if (want !== pet) continue;
      const r = book(rec)[step];
      r.ex = (r.ex | 0) + 1;
      if (r.ex < (times || 1)) {
        out.changes.push({ t: view(step, r), ty: TaskUpdate.UPDATE });
        continue;
      }
      const f = finishStep(rec, step, now);
      out.changes.push(...f.changes);
      if (f.score !== void 0) out.score = f.score;
      if (f.finished) (out.finished ??= []).push(...f.finished);
    }
    return out;
  }
  var NEWBIE_TASK = 135;
  var TaskUpdate = { UPDATE: 0, ADD: 1, FINISH: 2, ADD_FINISH: 3, RESET: 4, DROP: 5 };
  function robotVar(r) {
    return `0,1,${r.avatar ?? ""},`;
  }
  var QUEST_REWARDS = {
    1411: { score: 500, petExp: 1500, items: { "2": { "162": 30 } } },
    1416: { vipPet: 228 },
    1652: { score: 500, petExp: 1500, items: { "2": { "162": 30 } } }
  };
  var parentOf = (step) => {
    for (const [id, d] of Object.entries(TASK_DEFS)) if (d.steps.includes(step)) return Number(id);
    return void 0;
  };
  var view = (ti, r) => ({ ti, st: r.st, ex: r.ex, ad: r.ad, fd: r.fd });
  function book(rec) {
    return rec.tasks ??= {};
  }
  function isFinished(rec, ti) {
    return rec.tasks?.[ti]?.st === 1;
  }
  function isDoing(rec, ti) {
    return rec.tasks?.[ti]?.st === 0;
  }
  function startTask(rec, ti, now) {
    const def = TASK_DEFS[ti];
    const out = { changes: [] };
    if (!def) return out;
    const b = book(rec);
    if (b[ti] && b[ti].st !== 2) return out;
    if (def.pre?.some((p) => !isFinished(rec, p))) return out;
    b[ti] = { st: 0, ex: 0, ad: now, fd: 0 };
    out.changes.push({ t: view(ti, b[ti]), ty: TaskUpdate.ADD });
    const first = def.steps[0];
    if (first !== void 0) {
      b[first] = { st: 0, ex: 0, ad: now, fd: 0 };
      out.changes.push({ t: view(first, b[first]), ty: TaskUpdate.ADD });
    }
    return out;
  }
  function finishStep(rec, step, now) {
    const out = { changes: [] };
    const parent = parentOf(step);
    if (parent === void 0 || !isDoing(rec, step) || !isDoing(rec, parent)) return out;
    const b = book(rec);
    b[step] = { ...b[step], st: 1, fd: now };
    out.changes.push({ t: view(step, b[step]), ty: TaskUpdate.FINISH });
    const def = TASK_DEFS[parent];
    const next = def.steps[def.steps.indexOf(step) + 1];
    if (next !== void 0) {
      b[next] = { st: 0, ex: 0, ad: now, fd: 0 };
      out.changes.push({ t: view(next, b[next]), ty: TaskUpdate.ADD });
      return out;
    }
    b[parent] = { ...b[parent], st: 1, fd: now };
    out.finished = [parent];
    if (def.bonus?.score) {
      rec.score = (rec.score ?? 0) + def.bonus.score;
      out.score = rec.score;
    }
    if (def.bonus?.robotExp) {
      if (rec.robot) rec.robot.exp += def.bonus.robotExp;
      out.robotExp = def.bonus.robotExp;
    }
    out.changes.push({ t: view(parent, b[parent]), ty: TaskUpdate.FINISH });
    for (const [id, d] of Object.entries(TASK_DEFS)) {
      if (d.auto && d.pre?.includes(parent)) {
        const started = startTask(rec, Number(id), now);
        out.changes.push(...started.changes);
      }
    }
    return out;
  }
  function dropTask(rec, ti) {
    const out = { changes: [] };
    const def = TASK_DEFS[ti];
    const b = book(rec);
    if (!def || !b[ti] || b[ti].st !== 0) return out;
    b[ti].st = 2;
    for (const s of def.steps) delete b[s];
    out.changes.push({ t: view(ti, b[ti]), ty: TaskUpdate.DROP });
    return out;
  }
  function setTaskData(rec, ti, ed) {
    const out = { changes: [] };
    const r = rec.tasks?.[ti];
    if (!r || r.st !== 0) return out;
    r.ex = ed | 0;
    out.changes.push({ t: view(ti, r), ty: TaskUpdate.UPDATE });
    return out;
  }
  function taskList(rec) {
    return Object.entries(rec.tasks ?? {}).map(([ti, r]) => ({ s: `${ti},${r.st},${r.ex}`, a: r.ad, f: r.fd }));
  }
  function isNewPlayer(rec) {
    return Object.keys(rec.tasks ?? {}).length === 0 && (rec.pets ?? []).length === 0;
  }
  function skipTo(rec, step, now) {
    const out = { changes: [] };
    const b = book(rec);
    const parent = TASK_DEFS[step] ? step : parentOf(step);
    if (parent === void 0) return out;
    const chain = [];
    const visit = (t) => {
      for (const p of TASK_DEFS[t]?.pre ?? []) {
        if (chain.includes(p)) continue;
        visit(p);
        chain.push(p);
      }
    };
    visit(parent);
    for (const t of chain) {
      for (const s of [...TASK_DEFS[t]?.steps ?? [], t]) {
        b[s] = { st: 1, ex: 0, ad: now, fd: now };
        out.changes.push({ t: view(s, b[s]), ty: TaskUpdate.ADD_FINISH });
      }
    }
    if (b[146]?.st === 1 && !rec.robot) rec.robot = { name: "HELLO", exp: 0, follow: true, born: new Date(now).toISOString().slice(0, 10) };
    if (parent === step) return out;
    const d = TASK_DEFS[parent];
    const at = d.steps.indexOf(step);
    b[parent] = { st: 0, ex: 0, ad: now, fd: 0 };
    out.changes.push({ t: view(parent, b[parent]), ty: TaskUpdate.ADD });
    d.steps.forEach((s, i) => {
      if (i > at) {
        delete b[s];
        return;
      }
      b[s] = { st: i < at ? 1 : 0, ex: 0, ad: now, fd: i < at ? now : 0 };
      out.changes.push({ t: view(s, b[s]), ty: i < at ? TaskUpdate.ADD_FINISH : TaskUpdate.ADD });
    });
    return out;
  }
  function installTasks(world, deps) {
    const load = async (ctx) => {
      await (typeof deps.ready === "function" ? deps.ready() : deps.ready)?.catch(() => void 0);
      return deps.load(ctx);
    };
    const push = (ctx, r) => {
      for (const c of r.changes) ctx.reply({ t: c.t, ty: c.ty }, "10-1");
      if (r.score !== void 0) ctx.reply({ score: r.score }, "onScoreUpdated");
    };
    world.xt("TaskExtension.10-0", async (ctx) => {
      const rec = await load(ctx);
      if (isNewPlayer(rec)) {
        startTask(rec, NEWBIE_TASK, deps.now());
        await deps.save(rec);
      }
      ctx.reply({ t: taskList(rec), ou: false });
    });
    world.xt("TaskExtension.10-3", async (ctx) => {
      const rec = await load(ctx);
      const r = startTask(rec, Number(ctx.params.ti), deps.now());
      if (r.changes.length) await deps.save(rec);
      push(ctx, r);
    });
    world.xt("TaskExtension.10-2", async (ctx) => {
      const rec = await load(ctx);
      const r = finishStep(rec, Number(ctx.params.ti), deps.now());
      const extra = [];
      for (const t of r.finished ?? []) if (deps.onFinish) extra.push(...await deps.onFinish(rec, t));
      if (r.changes.length) await deps.save(rec);
      push(ctx, r);
      for (const [cmd, body] of extra) ctx.reply(body, cmd);
      ctx.reply({ ti: Number(ctx.params.ti), res: r.changes.length ? 1 : 0 }, "10-2");
    });
    world.xt("TaskExtension.10-4", async (ctx) => {
      const rec = await load(ctx);
      const r = dropTask(rec, Number(ctx.params.ti));
      if (r.changes.length) await deps.save(rec);
      push(ctx, r);
    });
    world.xt("TaskExtension.10-5", async (ctx) => {
      const rec = await load(ctx);
      const r = setTaskData(rec, Number(ctx.params.ti), Number(ctx.params.ed));
      if (r.changes.length) await deps.save(rec);
      push(ctx, r);
    });
    if (deps.dev) {
      world.xt("TaskExtension.revival_task", async (ctx) => {
        const rec = await load(ctx);
        const r = skipTo(rec, Number(ctx.params.ti), deps.now());
        await deps.save(rec);
        push(ctx, r);
      });
    }
    const skillBits = (rec) => {
      const woken = rec.area?.hello?.woken ?? [];
      return [0, 1, 2, 3, 4].map((i) => woken.includes(i) ? "1" : "0").join("");
    };
    const robotView = (rec) => {
      const r = rec.robot;
      const f = skillBits(rec);
      return r ? { has: 1, n: r.name, a: r.avatar ?? "", b: r.born ?? "2012-08-15", e: r.energy ?? 100, f, t: 0, exp: r.exp, fl: r.follow ? 1 : 0 } : { has: 0, f };
    };
    const today = () => new Date(deps.now()).toISOString().slice(0, 10);
    world.xt("RobotExtension.2-11", async (ctx) => {
      const rec = await deps.load(ctx);
      if (!rec.robot) {
        rec.robot = { name: "HELLO", exp: 0, follow: true, born: today() };
        await deps.save(rec);
        world.setUserVars(ctx.session, { r: robotVar(rec.robot) });
      }
      ctx.reply({ res: 1, ...robotView(rec) });
    });
    world.xt("RobotExtension.2-0", async (ctx) => {
      const un = typeof ctx.params.un === "string" ? ctx.params.un : "";
      const rec = un && un !== ctx.player?.name && deps.byName ? await deps.byName(un) : await deps.load(ctx);
      const who = un || ctx.player?.name;
      ctx.reply(rec ? { ...robotView(rec), ...who ? { un: who } : {} } : { has: 0, f: "00000", ...un ? { un } : {} });
    });
    world.xt("RobotExtension.2-1", async (ctx) => {
      const rec = await deps.load(ctx);
      if (!rec.robot) return ctx.reply({ res: 0 });
      if (!rec.robot.follow) {
        rec.robot.follow = true;
        await deps.save(rec);
      }
      world.setUserVars(ctx.session, { r: robotVar(rec.robot) });
      ctx.reply({ res: 1, ...robotView(rec) });
    });
    world.xt("RobotExtension.2-2", async (ctx) => {
      const rec = await deps.load(ctx);
      if (rec.robot?.follow) {
        rec.robot.follow = false;
        await deps.save(rec);
      }
      world.setUserVars(ctx.session, { r: null });
      ctx.reply({ res: 1 });
    });
    world.xt("RobotExtension.2-12", async (ctx) => {
      const rec = await deps.load(ctx);
      ctx.reply({ exp: rec.robot?.exp ?? 0 });
    });
  }

  // server/src/game/sfs2013/planetacts.ts
  var ITEM = "2";
  var SPECIAL_EVOLUTION = { 698: [699, 50], 894: [895, 40] };
  var LOCK_WAIT_MS = 10 * 60 * 1e3;
  var HEART_WAIT_MS = 10 * 60 * 1e3;
  var HEART_TIMES = 4;
  var MORA_WINS = 10;
  var MARBLE = 476;
  var HAMMER = 590;
  var AMO_COIN = 597;
  var SMILE_STAR = 610;
  var ARMOR_FRAG = 461;
  var ARMOR_PARTS = { 186: 454, 187: 455, 188: 456, 189: 457 };
  var SAGE_TREASURES = [458, 459, 460];
  var SKY_LOVE = 15;
  var SKY_PLAYS_PER_DAY = 3;
  var REWARD_PET = { lock: 832, mora: 335, heart: 336, food: 1209, amo: 1247, bobodu: 1286, unicorn: 651 };
  var AMO_BONUS = [
    { type: 101, num: 200 },
    { type: 101, num: 500 },
    { type: 100, num: 100 },
    { type: 100, num: 200 }
  ];
  var FISH_PER_DAY = 20;
  var FISH_CATCH = [
    [2, SMILE_STAR, 1, 40],
    [2, 32, 1, 12],
    [100, -1, 50, 12],
    [2, 61, 1, 8],
    [101, -1, 100, 12],
    [2, 103, 1, 8],
    [0, 0, 0, 8]
  ];
  var WILD_DROPS = {
    haikustar4: { 705: [MARBLE, 1], 706: [MARBLE, 2] },
    cloudstar4: { 1203: [HAMMER, 1] },
    mysticearth1: { 1245: [AMO_COIN, 1] },
    mysticearth2: { 1245: [AMO_COIN, 1] },
    mysticearth3: { 1245: [AMO_COIN, 1] },
    mysticearth4: { 1245: [AMO_COIN, 1] },
    unicornstar1: { 645: [ARMOR_FRAG, 1], 646: [ARMOR_FRAG, 1] },
    unicornstar4: { 647: [ARMOR_FRAG, 1] },
    // 小白吐获得 and 骑士王座 (areafuncs.ts): 糖果 (513) “won from the 布布兔”, 骑士卡 (531) from the 小骑兵.
    candystar1: { 844: [513, 1] },
    candystar3: { 844: [513, 1] },
    knightstar1: { 932: [531, 1] }
  };
  var actsOf = (o) => o.planetActs ??= {};
  var itemsOf = (o, type = ITEM) => (o.items ??= {})[type] ??= {};
  var countOf = (o, id) => o.items?.[ITEM]?.[String(id)] ?? 0;
  function addItem(o, id, n) {
    const items = itemsOf(o);
    const before = items[String(id)] ?? 0;
    const after = n > 0 ? Math.min(Math.max(before, 9999), before + n) : Math.max(0, before + n);
    if (after === before) return [];
    if (after) items[String(id)] = after;
    else delete items[String(id)];
    return [["onAmountUpdated", { amount: `${ITEM}_${id}_0_${after - before}` }]];
  }
  function wildDrop(o, room, race) {
    const d = WILD_DROPS[room]?.[race];
    return d ? addItem(o, d[0], d[1]) : [];
  }
  function clockText(ms) {
    const d = new Date(ms);
    const p = (n) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
  }
  var allPets = (o) => [...o.pets ?? [], ...o.storage ?? []];
  var petById = (o, id) => (o.pets ?? []).find((p) => p.id === (Number(id) | 0));
  function evolve(world, ctx, o, pet, to) {
    pet.race = to;
    if (o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
  }
  async function payBonus(deps, o, bn) {
    const out = [];
    for (const b of bn) {
      if (b.type === 100) {
        o.score = (o.score ?? 0) + b.num;
        out.push(["onScoreUpdated", { score: o.score }]);
      } else if (b.type === 101 && o.pets?.[0]) {
        out.push(...gainExp(await deps.tables(), o.pets[0], b.num).msgs);
      }
    }
    return out;
  }
  function installPlanetActs(world, deps) {
    const rng = deps.rng ?? Math.random;
    const send = (ctx, msgs) => {
      for (const [cmd, body] of msgs) ctx.reply(body, cmd);
    };
    world.xt("PetExtension2.54e_20", async (ctx) => {
      const o = await deps.load(ctx);
      const pet = petById(o, ctx.params.pid);
      const to = pet ? SPECIAL_EVOLUTION[pet.race] : void 0;
      if (!pet || !to || pet.level < to[1]) return ctx.reply({ res: 1 }, "54e_20");
      evolve(world, ctx, o, pet, to[0]);
      await deps.save(o);
      ctx.reply({ res: 0, pid: pet.id, raceId: pet.race }, "54e_20");
    });
    world.xt("PetExtension2.54e_23", async (ctx) => {
      const lock = actsOf(await deps.load(ctx)).lock ?? { c: 0, next: 0 };
      ctx.reply({ c: lock.c, t: Math.max(0, lock.next - deps.now()) }, "54e_23");
    });
    world.xt("PetExtension2.54e_24", async (ctx) => {
      const o = await deps.load(ctx);
      const a = actsOf(o);
      const lock = a.lock ??= { c: 0, next: 0 };
      if (deps.now() < lock.next) return ctx.reply({ succ: false }, "54e_24");
      lock.c++;
      lock.next = deps.now() + LOCK_WAIT_MS;
      const succ = lock.c % 5 === 0;
      const msgs = succ ? await deps.givePet(o, REWARD_PET.lock, 1) : [];
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ succ }, "54e_24");
    });
    world.xt("PeriodicActiveExtension.91_47", async (ctx) => {
      ctx.reply({ c: actsOf(await deps.load(ctx)).mora?.w ?? 0 }, "91_47");
    });
    world.xt("PeriodicActiveExtension.91_46", async (ctx) => {
      const o = await deps.load(ctx);
      const mora = actsOf(o).mora ??= { w: 0 };
      const num3 = Math.max(1, Math.min(4, Number(ctx.params.num) | 0));
      if (countOf(o, MARBLE) < num3) return ctx.reply({ get: false }, "91_46");
      const msgs = addItem(o, MARBLE, -num3);
      const won = ctx.params.w === true || ctx.params.w === "true" || ctx.params.w === 1;
      if (won) mora.w++;
      let get = false;
      if (won && mora.w >= MORA_WINS && !mora.got) {
        mora.got = true;
        get = true;
        mora.w = 0;
        msgs.push(...await deps.givePet(o, REWARD_PET.mora, 1));
      }
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ get }, "91_46");
    });
    world.xt("PeriodicActiveExtension.91_48", async (ctx) => {
      const h = actsOf(await deps.load(ctx)).heart;
      ctx.reply({ c: h?.c ?? 0, l: h?.last ? clockText(h.last) : "" }, "91_48");
    });
    world.xt("PeriodicActiveExtension.91_49", async (ctx) => {
      const o = await deps.load(ctx);
      const h = actsOf(o).heart ??= { c: 0, last: 0 };
      if (h.c >= HEART_TIMES || h.last && deps.now() - h.last < HEART_WAIT_MS) return ctx.reply({ get: false }, "91_49");
      h.c++;
      h.last = deps.now();
      const get = h.c >= HEART_TIMES;
      const msgs = get ? await deps.givePet(o, REWARD_PET.heart, 1) : [];
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ get }, "91_49");
    });
    world.xt("HolidayExtension.20120914_Fu1", async (ctx) => {
      const f = actsOf(await deps.load(ctx)).food;
      ctx.reply({ got: !!f?.got, sign: f?.sign ?? 0 }, "20120914_Fu1");
    });
    world.xt("HolidayExtension.20120914_Fu2", async (ctx) => {
      const o = await deps.load(ctx);
      const f = actsOf(o).food ??= { sign: 0 };
      if (f.got || countOf(o, HAMMER) <= 0) return ctx.reply({ stone: -1, bn: [] }, "20120914_Fu2");
      const msgs = addItem(o, HAMMER, -1);
      const missing = [0, 1, 2, 3, 4, 5, 6, 7].filter((i) => !(f.sign & 1 << i));
      const stone = missing.length && rng() < 1 / 3 ? missing[Math.floor(rng() * missing.length)] : Math.floor(rng() * 8);
      f.sign |= 1 << stone;
      let bn = [];
      if (f.sign === 255) {
        f.got = true;
        bn = [{ type: 102, id: REWARD_PET.food, num: 1 }];
        msgs.push(...await deps.givePet(o, REWARD_PET.food, 1));
      }
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ stone, bn: bn.length ? bn : null }, "20120914_Fu2");
    });
    world.xt("HolidayExtension.20121012_A1", async (ctx) => {
      ctx.reply({ state: actsOf(await deps.load(ctx)).amo?.state ?? 0 }, "20121012_A1");
    });
    world.xt("HolidayExtension.20121012_A2", async (ctx) => {
      const o = await deps.load(ctx);
      const amo = actsOf(o).amo ??= { state: 0 };
      if (amo.state === 255 || countOf(o, AMO_COIN) <= 0) return ctx.reply({ res: false, joke: -1, bn: [] }, "20121012_A2");
      const msgs = addItem(o, AMO_COIN, -1);
      let joke = -1;
      let bn = [];
      const missing = [0, 1, 2, 3, 4, 5, 6, 7].filter((i) => !(amo.state & 1 << i));
      if (rng() < 0.5 && missing.length) {
        joke = missing[Math.floor(rng() * missing.length)];
        amo.state |= 1 << joke;
        if (amo.state === 255) msgs.push(...await deps.givePet(o, REWARD_PET.amo, 1));
      } else {
        bn = [AMO_BONUS[Math.floor(rng() * AMO_BONUS.length)]];
        msgs.push(...await payBonus(deps, o, bn));
      }
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: true, joke, bn }, "20121012_A2");
    });
    world.xt("PeriodicActiveExtension.gofish-1", async (ctx) => {
      const o = await deps.load(ctx);
      const a = actsOf(o);
      if (a.fish?.day !== deps.today()) a.fish = { day: deps.today(), n: 0 };
      if (a.fish.n >= FISH_PER_DAY) return ctx.reply({ id: FISH_CATCH.length - 1, bn: null }, "gofish-1");
      a.fish.n++;
      const total = FISH_CATCH.reduce((s, c) => s + c[3], 0);
      let r = rng() * total;
      let id = FISH_CATCH.length - 1;
      for (let i = 0; i < FISH_CATCH.length; i++) {
        if ((r -= FISH_CATCH[i][3]) < 0) {
          id = i;
          break;
        }
      }
      const [type, item, num3] = FISH_CATCH[id];
      const msgs = [];
      let bn = null;
      if (type === 2) {
        const got = addItem(o, item, num3);
        if (got.length) {
          msgs.push(...got);
          bn = [{ type, id: item, num: num3 }];
        }
      } else if (type === 100 || type === 101) {
        msgs.push(...await payBonus(deps, o, [{ type, num: num3 }]));
        bn = [{ type, id: item, num: num3 }];
      }
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ id, bn }, "gofish-1");
    });
    world.xt("PeriodicActiveExtension.gofish-2", async (ctx) => {
      const o = await deps.load(ctx);
      const a = actsOf(o);
      if (countOf(o, SMILE_STAR) < 20 || a.bobodu?.day === deps.today()) return ctx.reply({ res: false }, "gofish-2");
      const msgs = addItem(o, SMILE_STAR, -20);
      a.bobodu = { day: deps.today() };
      msgs.push(...await deps.givePet(o, REWARD_PET.bobodu, 1));
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: true }, "gofish-2");
    });
    world.xt("PeriodicActiveExtension.gofish-3", async (ctx) => {
      const o = await deps.load(ctx);
      const num3 = Math.max(0, Math.min(99, Number(ctx.params.num) | 0));
      if (!num3 || (o.xingbi ?? 0) < num3 * 2) return ctx.reply({ res: 0 }, "gofish-3");
      o.xingbi = (o.xingbi ?? 0) - num3 * 2;
      const msgs = addItem(o, SMILE_STAR, num3);
      await deps.save(o);
      ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
      send(ctx, msgs);
      ctx.reply({ res: 1 }, "gofish-3");
    });
    world.xt("PetExtension2.54e_1", async (ctx) => {
      const o = await deps.load(ctx);
      const pet = petById(o, ctx.params.pid);
      const t = Number(ctx.params.t) | 0;
      const need = t === 1 ? SAGE_TREASURES : t === 2 ? Object.values(ARMOR_PARTS) : [];
      if (!pet || pet.race !== REWARD_PET.unicorn || !need.length || need.some((id) => countOf(o, id) <= 0)) return ctx.reply({ res: 1 }, "54e_1");
      const msgs = [];
      for (const id of need) msgs.push(...addItem(o, id, -1));
      evolve(world, ctx, o, pet, t === 1 ? 655 : 656);
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: 0, pid: pet.id, raceId: pet.race }, "54e_1");
    });
    world.xt("SynthesizeExtension.57_8", async (ctx) => {
      const o = await deps.load(ctx);
      const part = ARMOR_PARTS[Number(ctx.params.id) | 0];
      if (!part || countOf(o, ARMOR_FRAG) < 5 || countOf(o, part) > 0) return ctx.reply({ res: 0 }, "57_8");
      const msgs = [...addItem(o, ARMOR_FRAG, -5), ...addItem(o, part, 1)];
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: 1 }, "57_8");
    });
    world.xt("PeriodicActiveExtension.91_31", async (ctx) => {
      const o = await deps.load(ctx);
      const item = SAGE_TREASURES[(Number(ctx.params.id) | 0) - 1];
      if (!item || countOf(o, item) > 0) return ctx.reply({ res: false }, "91_31");
      const msgs = addItem(o, item, 1);
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: true }, "91_31");
    });
    world.xt("PeriodicActiveExtension.91_34", async (ctx) => {
      const x = actsOf(await deps.load(ctx)).xianlin;
      ctx.reply({ c: x?.c ?? 0, td: x?.day === deps.today() }, "91_34");
    });
    world.xt("PeriodicActiveExtension.91_35", async (ctx) => {
      const o = await deps.load(ctx);
      const x = actsOf(o).xianlin ??= { c: 0, day: "" };
      const follow = (o.pets ?? []).find((p) => p.id === o.followPet);
      if (x.day === deps.today() || x.c >= 3 || follow?.race !== REWARD_PET.unicorn) return ctx.reply({ res: false, c: x.c }, "91_35");
      x.c++;
      x.day = deps.today();
      await deps.save(o);
      ctx.reply({ res: true, c: x.c }, "91_35");
    });
    world.xt("PeriodicActiveExtension.91_36", async (ctx) => {
      const o = await deps.load(ctx);
      const x = actsOf(o).xianlin ??= { c: 0, day: "" };
      const pet = petById(o, ctx.params.id);
      if (!pet || pet.race !== REWARD_PET.unicorn || x.c < 3) return ctx.reply({ res: false }, "91_36");
      x.c = 0;
      evolve(world, ctx, o, pet, 654);
      await deps.save(o);
      ctx.reply({ res: true }, "91_36");
    });
    const sky = (o) => actsOf(o).sky ??= { love: 0, nl: [] };
    world.xt("PeriodicActiveExtension.91_33", async (ctx) => {
      const s = sky(await deps.load(ctx));
      ctx.reply({ es: !!s.es, ad: !!s.ad || !!s.hatched }, "91_33");
    });
    world.xt("PeriodicActiveExtension.91_32", async (ctx) => {
      const o = await deps.load(ctx);
      const s = sky(o);
      if (s.es) return ctx.reply({ res: false }, "91_32");
      s.es = true;
      const msgs = await deps.givePet(o, REWARD_PET.unicorn, 1);
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: true }, "91_32");
    });
    world.xt("PeriodicActiveExtension.91_37", async (ctx) => {
      const o = await deps.load(ctx);
      const s = sky(o);
      if (s.ad && !s.hatched) return ctx.reply({ res: 2 }, "91_37");
      const raised = new Set(allPets(o).map((p) => p.race).filter((r) => r === 654 || r === 655 || r === 656));
      if (s.hatched || raised.size < 2) return ctx.reply({ res: 0 }, "91_37");
      s.ad = true;
      await deps.save(o);
      ctx.reply({ res: 1 }, "91_37");
    });
    world.xt("PeriodicActiveExtension.91_38", async (ctx) => {
      const owner = String(ctx.params.n ?? "") || ctx.player.name;
      const o = owner === ctx.player.name ? await deps.load(ctx) : await deps.find(owner);
      const s = o?.planetActs?.sky;
      ctx.reply({ sum: s?.love ?? 0, nl: (s?.nl ?? []).join(",") }, "91_38");
    });
    world.xt("PeriodicActiveExtension.91_39", async (ctx) => {
      const me = await deps.load(ctx);
      const ownerName = String(ctx.params.n ?? "") || me.name;
      const o = ownerName === me.name ? me : await deps.find(ownerName);
      if (!o) return ctx.reply({ res: 0 }, "91_39");
      const s = sky(o);
      const mine = sky(me);
      const today = deps.today();
      if (mine.day !== today) {
        mine.day = today;
        mine.plays = 0;
      }
      if ((mine.plays ?? 0) >= SKY_PLAYS_PER_DAY) return ctx.reply({ res: 3 }, "91_39");
      if (s.played?.day !== today) s.played = { day: today, names: [] };
      if (o !== me && s.played.names.includes(me.name)) return ctx.reply({ res: 2 }, "91_39");
      mine.plays = (mine.plays ?? 0) + 1;
      const bump = (egg) => {
        if (egg.played?.day !== today) egg.played = { day: today, names: [] };
        if (!egg.played.names.includes(me.name)) egg.played.names.push(me.name);
        const counted2 = !!egg.ad && !egg.hatched && egg.love < SKY_LOVE;
        if (counted2) egg.love++;
        const tag = `${me.name}#${me.name}`;
        if (!egg.nl.includes(tag)) egg.nl = [...egg.nl, tag].slice(-10);
        return counted2;
      };
      me.score = (me.score ?? 0) + 20;
      let counted;
      if (o === me) {
        counted = bump(s);
        await deps.save(me);
      } else {
        await deps.save(me);
        const fresh2 = await deps.find(ownerName);
        counted = fresh2 ? bump(sky(fresh2)) : false;
        if (fresh2) await deps.save(fresh2);
      }
      ctx.reply({ score: me.score }, "onScoreUpdated");
      ctx.reply({ res: counted ? 1 : 4 }, "91_39");
    });
    world.xt("PeriodicActiveExtension.91_40", async (ctx) => {
      const o = await deps.load(ctx);
      const s = sky(o);
      if (!s.ad || s.hatched || s.love < SKY_LOVE) return ctx.reply({ res: false }, "91_40");
      s.hatched = true;
      s.ad = false;
      const msgs = await deps.givePet(o, 653, 1);
      await deps.save(o);
      send(ctx, msgs);
      ctx.reply({ res: true }, "91_40");
    });
  }

  // server/src/game/sfs2013/fb.ts
  var each = (first, last, species) => Object.fromEntries(Array.from({ length: last - first + 1 }, (_, i) => [first + i, species]));
  var FB_STANDIN = {};
  var FB_EXTRA_SPECIES = { 999: { n: "\u62C9\u8D1D\u5C14\u5E7B\u5F71", like: 899 } };
  var FBS = [
    {
      name: "fbaixi",
      title: "\u5E7B\u5F71\u51B0\u5BAB",
      levels: [30, 55, 75],
      rooms: {
        // fbaixi3: the first three of 冰沙斗士 / 埃黑多夫 open the first door, all six the second.
        fbaixi1: { wild: [421, 421, 421] },
        fbaixi2: { wild: [415, 421, 415, 421, 415] },
        fbaixi3: { wild: [421, 415, 421, 466, 448, 466] },
        // 水晶密室's 变异库斯特, then 尤莱亚 and 拉贝尔幻影 in the 风暴核心.
        fbaixi4: { fights: { 1: 463 }, boss: [1] },
        fbaixi6: { wild: [448, 466, 448, 466, 448] },
        fbaixi8: { fights: { 1: 249 }, boss: [1] },
        fbaixi9: { fights: { 1: 999 }, boss: [1] }
      }
    },
    {
      name: "fbsuolide",
      title: "\u5012\u7ACB\u91D1\u5B57\u5854",
      levels: [35, 60, 80],
      rooms: {
        fbsuolide1: { fights: { 1: 210 } },
        // 石像迷阵: a 石像守卫 for each statue flagstone turned, numbered on (the grid has nine).
        fbsuolide2: { fights: each(1, 9, 213) },
        // 木乃伊之棺: 帕克 in three of the five coffins.
        fbsuolide3: { fights: each(1, 3, 304) },
        fbsuolide4: { fights: { 1: 238 }, boss: [1] },
        // 土木战场: 扭扭大王 (wood) and 斯多王 (earth); the single 副本's script told them 30060 / 30072.
        fbsuolide6: { fights: { 1: 30060, 2: 30072 } },
        // 莎华之间: the coin slot's 夜眼风魔 (10 晶币) and 沙麒麟 (100), and 曼珠沙华.
        fbsuolide7: { fights: { 1: 81, 2: 90, 3: 272 }, boss: [3] },
        fbsuolide8: { fights: { 1: 340 }, boss: [1] },
        fbsuolide9: { fights: { 1: 240 }, boss: [1] }
      }
    },
    {
      name: "fbsiwude",
      title: "\u8681\u65CF\u738B\u671D",
      levels: [40, 65, 85],
      rooms: {
        // 蚁穴入口 and the searchlights: three 兵蚁 each.
        fbsiwude1: { fights: each(1, 3, 216) },
        fbsiwude2: { fights: each(1, 3, 216) },
        // 蚁穴下水道: three 牛角滴滴 at the doors.
        fbsiwude3: { fights: each(1, 3, 244) },
        // The 蚁将军's treasure: 毒菇球, 金刚蛤蟆, 下水猛鳄 (the boss of the place, by the chest).
        fbsiwude4: { fights: { 1: 241, 2: 242, 3: 243 }, boss: [3] },
        // 工蚁聚集地.
        fbsiwude5: { fights: { 1: 217 } },
        // 蚁神守护大厅: the two statues, 守护力士 and 守护法师; one fight, one of them in turn.
        fbsiwude6: { fights: { 1: [218, 219] }, boss: [1] },
        // 蚁神巨像: 蚁族圣斗士 and 魔斗士 on either side.
        fbsiwude9: { fights: { 1: 220, 2: 221 } },
        // The 女王守护骑士: 保斯, 兰斯罗特, 哥拉海德, 贝德威尓 (btnPet_1 … 4).
        fbsiwude10: { fights: { 1: 225, 2: 223, 3: 224, 4: 222 } },
        // The 蚁将军's 小弟, the 蚁将军, the 变异蚁将军 (FBSiwude11_5FightWithAberrance).
        fbsiwude11: { fights: { 1: 216, 2: 226, 3: 227 }, boss: [2, 3] }
      }
    },
    {
      name: "fbyishuzhidu",
      title: "\u6050\u9F99\u535A\u7269\u9986",
      levels: [40, 65, 85],
      rooms: {
        // 迅猛龙, 龙之谷 (the script's 梁龙 30401, 翼龙 30402, 鱼龙 30403), 暴君王座's 霸王龙,
        // 龙殇墓地's 射手座 (星辰毁灭者).
        fbyishuzhidu1: { fights: { 1: 400 } },
        fbyishuzhidu2: { fights: { 1: 30401, 2: 30402, 3: 30403 } },
        fbyishuzhidu3: { fights: { 1: 404 }, boss: [1] },
        fbyishuzhidu4: { fights: { 1: 405 }, boss: [1] }
      }
    }
  ];
  var FB_TIMES = 5;
  var fbByName = (name) => FBS.find((f) => f.name === name);
  var fbOfRoom = (room) => FBS.find((f) => room.startsWith(f.name) && /^\d+$/.test(room.slice(f.name.length)));
  function fbCode(species, mode) {
    if (species >= 1e4) return species;
    return (mode > 0 ? 12 : 1) * 1e4 + species;
  }
  function ensureFbSpecies(pm) {
    for (const [id, x] of Object.entries(FB_EXTRA_SPECIES)) {
      if (pm.species[id] || !pm.species[String(x.like)]) continue;
      pm.species[id] = { ...pm.species[String(x.like)], n: x.n, c: ["NA", "NA"], evo: "" };
    }
  }
  function fbSpecies(code) {
    const s = code >= 1e5 ? code % 1e4 : code >= 1e4 ? code % 1e4 : code;
    return FB_STANDIN[s] ?? s;
  }
  function fbRoomPets(def, room, mode, run = 0) {
    const r = def.rooms[room];
    if (!r) return [];
    const base = def.levels[Math.max(0, Math.min(2, mode))];
    const deep = Number(room.slice(def.name.length)) || 1;
    const lv = (i) => Math.min(100, base + Math.floor(deep / 2) + i % 3);
    if (r.wild) return r.wild.map((s, i) => ({ id: i + 1, code: fbCode(s, mode), lv: lv(i) }));
    return Object.entries(r.fights ?? {}).map(([k, f]) => {
      const id = Number(k);
      const s = Array.isArray(f) ? f[Math.max(0, run) % f.length] : f;
      return { id, code: fbCode(s, mode), lv: Math.min(100, lv(id) + (r.boss?.includes(id) ? 6 : 3)) };
    });
  }
  function fbGrade(seconds) {
    if (seconds <= 5 * 60) return "SSS";
    if (seconds <= 8 * 60) return "S";
    if (seconds <= 11 * 60) return "A";
    if (seconds <= 15 * 60) return "B";
    return "C";
  }
  var GRADE_ORDER = ["#", "C", "B", "A", "S", "SSS"];
  var betterGrade = (a, b) => GRADE_ORDER.indexOf(b) > GRADE_ORDER.indexOf(a) ? b : a;
  function fbPay(mode, grade) {
    const base = [600, 1200, 2e3][Math.max(0, Math.min(2, mode))];
    return Math.round(base * (1 + 0.25 * Math.max(0, GRADE_ORDER.indexOf(grade) - 1)));
  }
  function fbBossBeaten(cur) {
    const def = FBS.find((d) => d.name === cur.name);
    if (!def) return false;
    const rooms = Object.entries(def.rooms).filter(([, r]) => r.boss?.length);
    if (!rooms.length) return true;
    const [last, room] = rooms[rooms.length - 1];
    const dead = cur.dead[last] ?? [];
    return room.boss.every((id) => dead.includes(id));
  }

  // server/src/game/sfs2013/sandbox.ts
  var SANDBOX_FORMAT = "aola-revival-level";
  var SANDBOX_MAX = 10;
  var SANDBOX_MAX_LEVEL = 999;
  var SANDBOX_PCT = [1, 1e4];
  var STAT_KEYS = ["hp", "at", "de", "sa", "sd", "sp"];
  var clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
  function parseSandboxLevel(text, fights2) {
    let j;
    try {
      j = typeof text === "string" ? JSON.parse(text) : text;
    } catch {
      return "\u8FD9\u4E0D\u662F\u5173\u5361\u6587\u4EF6";
    }
    if (!j || typeof j !== "object") return "\u8FD9\u4E0D\u662F\u5173\u5361\u6587\u4EF6";
    const o = j;
    if (o.format !== void 0 && o.format !== SANDBOX_FORMAT) return "\u8FD9\u4E0D\u662F\u5965\u62C9\u661F\u7684\u5173\u5361\u6587\u4EF6";
    if (!Array.isArray(o.enemies) || o.enemies.length === 0) return "\u5173\u5361\u91CC\u8FD8\u6CA1\u6709\u5BF9\u624B";
    if (o.enemies.length > SANDBOX_MAX) return `\u4E00\u4E2A\u5173\u5361\u6700\u591A${SANDBOX_MAX}\u4E2A\u5BF9\u624B`;
    const enemies = [];
    for (const [i, e] of o.enemies.entries()) {
      if (!e || typeof e !== "object") return `\u7B2C${i + 1}\u4E2A\u5BF9\u624B\u4E0D\u5BF9`;
      const r = e;
      const race = Math.floor(Number(r.race));
      if (!(race > 0) || !fights2(race)) return `\u7B2C${i + 1}\u4E2A\u5BF9\u624B\uFF08\u7F16\u53F7${r.race}\uFF09\u4E0D\u80FD\u5BF9\u6218`;
      const level = clamp(Math.floor(Number(r.level)) || 1, 1, SANDBOX_MAX_LEVEL);
      const mul = STAT_KEYS.map((k) => {
        const v = r[k] === void 0 ? 100 : Number(r[k]);
        return clamp(Number.isFinite(v) ? v : 100, SANDBOX_PCT[0], SANDBOX_PCT[1]) / 100;
      });
      enemies.push({ race, level, mul });
    }
    return { name: String(o.name ?? "").slice(0, 30), heal: o.heal !== false, enemies };
  }
  function installSandbox(world, deps) {
    world.xt("SundriesExtension.revival_sandbox", async (ctx) => {
      const t = await deps.tables();
      const lv = parseSandboxLevel(ctx.params.lv, (race) => !!speciesOf(t, race));
      if (typeof lv === "string") return ctx.reply({ res: 0, msg: lv });
      const i = clamp(Math.floor(Number(ctx.params.i)) || 0, 0, lv.enemies.length - 1);
      const e = lv.enemies[i];
      if (lv.heal) {
        const o = await deps.load(ctx);
        for (const p of o.pets ?? []) {
          p.hp = statsOf(p, t)[0];
          for (const s of p.skills ?? []) s.pp = s.max;
        }
        await deps.save(o);
      }
      ctx.reply({ res: 1, i, n: lv.enemies.length, race: e.race, level: e.level });
      if (!await deps.begin(ctx, e.race, e.level, { mul: e.mul })) ctx.reply({ res: 0, msg: "" });
    });
  }

  // server/src/game/sfs2013/gyms.ts
  var GYM_THUNDER = 84;
  var GYM_TOWER = 85;
  var GYM_FIRE = 86;
  var GYM_WATER = 87;
  var GYM_DARK = 88;
  var GYM_LIGHT = 89;
  var GYM_MASTERS = {
    [GYM_THUNDER]: { race: 1300, level: 100, name: "\u5E7B\u96F7" },
    [GYM_FIRE]: { race: 1296, level: 100, name: "\u5E7B\u708E" },
    [GYM_WATER]: { race: 1298, level: 100, name: "\u5E7B\u6D41" },
    [GYM_DARK]: { race: 1309, level: 100, name: "\u5E7B\u51A5" }
  };
  var GYM_STONES = {
    [GYM_THUNDER]: { item: 619, pets: [1300], cmd: "20121113_hlf" },
    [GYM_FIRE]: { item: 617, pets: [1295, 1296], cmd: "Fire_7" },
    [GYM_WATER]: { item: 618, pets: [1297, 1298], cmd: "20121116water_c2" },
    [GYM_DARK]: { item: 622, pets: [1308, 1309], cmd: "Dark_8" }
  };
  var STONE_CHANCE = 0.3;
  var TOWER_FLOORS = [
    { race: 1299, level: 30 },
    // 灵雷
    { race: 339, level: 35 },
    // 霹雳闪电狗
    { race: 1074, level: 40 },
    // 超电流企鹅
    { race: 469, level: 50 },
    // 雷纳瑞
    { race: 1078, level: 55 },
    // 罗宾斯
    { race: 1036, level: 60 },
    // 狂雷鸟
    { race: 589, level: 65 },
    // 雷角兽
    { race: 236, level: 70 },
    // 雷鸣女王
    { race: 891, level: 80 },
    // 刀锋
    { race: 1300, level: 100 }
    // 幻雷
  ];
  var TOWER_SPECIAL_FLOOR = 4;
  function dollLevel(raceId) {
    return Math.floor(raceId / 1e4) >= 2 ? 55 : 35;
  }
  function rollFate(rng) {
    return Array.from({ length: 6 }, () => (rng() < 0.5 ? -1 : 1) * (5 + Math.floor(rng() * 26)));
  }
  function applyFate(stats, fate) {
    if (!fate) return stats;
    return stats.map((v, i) => Math.max(1, Math.round(v * (1 + (fate[i] ?? 0) / 100))));
  }
  var gymOf = (o) => o.gymFights ??= {};
  function gymWon(o, type, finalRace) {
    (gymOf(o).won ??= {})[String(type)] = finalRace;
  }
  function gymStone(o, type, today, rng) {
    const g = gymOf(o);
    const s = GYM_STONES[type];
    const fin = g.won?.[String(type)];
    if (!s || fin === void 0) return 0;
    delete g.won[String(type)];
    if ((g.stoneDay ??= {})[String(type)] === today) return 0;
    const own = s.pets.includes(fin);
    const first = own && !(g.firstStone ?? []).includes(type);
    if (!first && rng() >= STONE_CHANCE) return 0;
    if (first) (g.firstStone ??= []).push(type);
    g.stoneDay[String(type)] = today;
    const bag3 = (o.items ??= {})["2"] ??= {};
    bag3[String(s.item)] = (bag3[String(s.item)] ?? 0) + 1;
    return s.item;
  }
  var towerRank = (g) => g.towerBest ? 1 : 0;
  function installGyms(world, deps) {
    const PA = "PeriodicActiveExtension";
    const amount = (ctx, item) => ctx.reply({ amount: `2_${item}_0_1` }, "onAmountUpdated");
    world.xt(`${PA}.20121113_hlf`, async (ctx) => {
      const o = await deps.load(ctx);
      const item = gymStone(o, GYM_THUNDER, deps.today(), deps.rng);
      await deps.save(o);
      if (item) amount(ctx, item);
      ctx.reply({ n: item ? 1 : 0 });
    });
    world.xt(`${PA}.Fire_7`, async (ctx) => {
      const o = await deps.load(ctx);
      const item = gymStone(o, GYM_FIRE, deps.today(), deps.rng);
      await deps.save(o);
      if (item) amount(ctx, item);
      ctx.reply({ bn: item ? 1 : 0 });
    });
    world.xt(`${PA}.20121116water_c2`, async (ctx) => {
      const o = await deps.load(ctx);
      const item = gymStone(o, GYM_WATER, deps.today(), deps.rng);
      await deps.save(o);
      if (item) amount(ctx, item);
      ctx.reply({ res: item ? 1 : 0 });
    });
    world.xt(`${PA}.Dark_8`, async (ctx) => {
      const o = await deps.load(ctx);
      const item = gymStone(o, GYM_DARK, deps.today(), deps.rng);
      await deps.save(o);
      if (item) amount(ctx, item);
      ctx.reply({ bn: item ? 1 : 0 });
    });
    world.xt(`${PA}.Dark_7`, async (ctx) => {
      const o = await deps.load(ctx);
      const fate = rollFate(deps.rng);
      gymOf(o).fate = fate;
      await deps.save(o);
      ctx.reply(Object.fromEntries(fate.map((v, i) => [`s${i}`, v])));
    });
    world.xt(`${PA}.20121112_openthunder`, async (ctx) => {
      const o = await deps.load(ctx);
      gymOf(o).tower = { start: deps.now(), floor: 0, p4: false };
      await deps.save(o);
      ctx.reply({ suc: true });
    });
    world.xt(`${PA}.20121112_tel`, async (ctx) => {
      const o = await deps.load(ctx);
      gymOf(o).tower = null;
      await deps.save(o);
      ctx.reply({});
    });
    world.xt(`${PA}.20121112_getmyrank`, async (ctx) => {
      const g = gymOf(await deps.load(ctx));
      ctx.reply({ r: `${towerRank(g)}:${g.towerBest ?? 0}`, p: "0,0,0,0", c: g.towerRuns ?? 0 });
    });
    world.xt("PetExtension.54_4", async (ctx) => {
      const o = await deps.load(ctx);
      const t = await deps.tables();
      const cost = o.vip ? 0 : 50;
      if ((o.score ?? 0) < cost) return ctx.reply({ res: false }, "54_4");
      o.score = (o.score ?? 0) - cost;
      for (const p of o.pets ?? []) {
        normalisePet(p, t);
        p.hp = statsOf(p, t)[0];
        for (const s of p.skills) s.pp = s.max;
      }
      await deps.save(o);
      if (cost) ctx.reply({ score: o.score }, "onScoreUpdated");
      ctx.reply({ res: true }, "54_4");
    });
  }
  function towerFloorWon(o, layer, now) {
    const g = gymOf(o);
    const run = g.tower;
    if (!run || layer !== run.floor + 1) return [];
    run.floor = layer;
    if (layer === TOWER_SPECIAL_FLOOR) run.p4 = true;
    const ps = Math.max(1, Math.round((now - run.start) / 1e3));
    if (layer === TOWER_FLOORS.length) {
      g.towerRuns = (g.towerRuns ?? 0) + 1;
      if (!g.towerBest || ps < g.towerBest) g.towerBest = ps;
    }
    return [["20121112_ted", { fl: layer, ps, ra: towerRank(g), p4: run.p4 }]];
  }

  // server/src/core/amf3.ts
  var Amf3TypedObject = class {
    className;
    values;
    constructor(className, values) {
      this.className = className;
      this.values = values;
    }
  };
  var INT_MIN = -(1 << 28);
  var INT_MAX = (1 << 28) - 1;
  var Amf3Reader = class _Amf3Reader {
    view;
    bytes;
    pos;
    strings = [];
    objects = [];
    traits = [];
    static dec = new TextDecoder("utf-8");
    constructor(bytes2, pos = 0) {
      this.bytes = bytes2;
      this.view = new DataView(bytes2.buffer, bytes2.byteOffset, bytes2.byteLength);
      this.pos = pos;
    }
    u8() {
      if (this.pos >= this.bytes.length) throw new RangeError("AMF3: unexpected end of data");
      return this.bytes[this.pos++];
    }
    u29() {
      let n = 0;
      for (let i = 0; i < 3; i++) {
        const b = this.u8();
        if (b < 128) return n << 7 | b;
        n = n << 7 | b & 127;
      }
      return n << 8 | this.u8();
    }
    str() {
      const h = this.u29();
      if ((h & 1) === 0) return this.strings[h >> 1];
      const len = h >> 1;
      if (len === 0) return "";
      const s = _Amf3Reader.dec.decode(this.bytes.subarray(this.pos, this.pos + len));
      this.pos += len;
      this.strings.push(s);
      return s;
    }
    read() {
      const marker = this.u8();
      switch (marker) {
        case 0:
          return void 0;
        case 1:
          return null;
        case 2:
          return false;
        case 3:
          return true;
        case 4: {
          const n = this.u29();
          return n & 268435456 ? n - 536870912 : n;
        }
        case 5: {
          const d = this.view.getFloat64(this.pos);
          this.pos += 8;
          return d;
        }
        case 6:
          return this.str();
        case 7:
        case 11: {
          const h = this.u29();
          if ((h & 1) === 0) return this.objects[h >> 1];
          const s = _Amf3Reader.dec.decode(this.bytes.subarray(this.pos, this.pos + (h >> 1)));
          this.pos += h >> 1;
          this.objects.push(s);
          return s;
        }
        case 8: {
          const h = this.u29();
          if ((h & 1) === 0) return this.objects[h >> 1];
          const d = new Date(this.view.getFloat64(this.pos));
          this.pos += 8;
          this.objects.push(d);
          return d;
        }
        case 9:
          return this.array();
        case 10:
          return this.object();
        case 12: {
          const h = this.u29();
          if ((h & 1) === 0) return this.objects[h >> 1];
          const b = this.bytes.slice(this.pos, this.pos + (h >> 1));
          this.pos += h >> 1;
          this.objects.push(b);
          return b;
        }
        default:
          throw new Error(`AMF3: unsupported marker 0x${marker.toString(16)} at ${this.pos - 1}`);
      }
    }
    array() {
      const h = this.u29();
      if ((h & 1) === 0) return this.objects[h >> 1];
      const dense = h >> 1;
      const assoc = {};
      let hasAssoc = false;
      const out = [];
      this.objects.push(out);
      for (; ; ) {
        const key = this.str();
        if (key === "") break;
        assoc[key] = this.read();
        hasAssoc = true;
      }
      for (let i = 0; i < dense; i++) out.push(this.read());
      if (hasAssoc) Object.assign(out, assoc);
      return out;
    }
    object() {
      const h = this.u29();
      if ((h & 1) === 0) return this.objects[h >> 1];
      let t;
      if ((h & 2) === 0) {
        t = this.traits[h >> 2];
      } else {
        t = {
          externalizable: (h & 4) !== 0,
          dynamic: (h & 8) !== 0,
          className: this.str(),
          members: []
        };
        const count = h >> 4;
        for (let i = 0; i < count; i++) t.members.push(this.str());
        this.traits.push(t);
      }
      if (t.externalizable) throw new Error(`AMF3: externalizable class ${t.className} not supported`);
      const values = {};
      const result = t.className ? new Amf3TypedObject(t.className, values) : values;
      this.objects.push(result);
      for (const m of t.members) values[m] = this.read();
      if (t.dynamic) {
        for (; ; ) {
          const key = this.str();
          if (key === "") break;
          values[key] = this.read();
        }
      }
      return result;
    }
  };
  var Amf3Writer = class _Amf3Writer {
    buf = new Uint8Array(256);
    len = 0;
    strings = /* @__PURE__ */ new Map();
    objects = /* @__PURE__ */ new Map();
    static enc = new TextEncoder();
    ensure(n) {
      if (this.len + n <= this.buf.length) return;
      let size = this.buf.length * 2;
      while (size < this.len + n) size *= 2;
      const next = new Uint8Array(size);
      next.set(this.buf.subarray(0, this.len));
      this.buf = next;
    }
    u8(b) {
      this.ensure(1);
      this.buf[this.len++] = b & 255;
    }
    u29(n) {
      n &= 536870911;
      if (n < 128) this.u8(n);
      else if (n < 16384) {
        this.u8(n >> 7 | 128);
        this.u8(n & 127);
      } else if (n < 2097152) {
        this.u8(n >> 14 | 128);
        this.u8(n >> 7 & 127 | 128);
        this.u8(n & 127);
      } else {
        this.u8(n >> 22 | 128);
        this.u8(n >> 15 & 127 | 128);
        this.u8(n >> 8 & 127 | 128);
        this.u8(n & 255);
      }
    }
    f64(d) {
      this.ensure(8);
      new DataView(this.buf.buffer).setFloat64(this.len, d);
      this.len += 8;
    }
    str(s) {
      if (s === "") {
        this.u29(1);
        return;
      }
      const ref = this.strings.get(s);
      if (ref !== void 0) {
        this.u29(ref << 1);
        return;
      }
      this.strings.set(s, this.strings.size);
      const b = _Amf3Writer.enc.encode(s);
      this.u29(b.length << 1 | 1);
      this.ensure(b.length);
      this.buf.set(b, this.len);
      this.len += b.length;
    }
    ref(o) {
      const r = this.objects.get(o);
      if (r !== void 0) {
        this.u29(r << 1);
        return true;
      }
      this.objects.set(o, this.objects.size);
      return false;
    }
    write(v) {
      if (v === void 0) this.u8(0);
      else if (v === null) this.u8(1);
      else if (v === false) this.u8(2);
      else if (v === true) this.u8(3);
      else if (typeof v === "number") {
        if (Number.isInteger(v) && v >= INT_MIN && v <= INT_MAX && !Object.is(v, -0)) {
          this.u8(4);
          this.u29(v);
        } else {
          this.u8(5);
          this.f64(v);
        }
      } else if (typeof v === "bigint") {
        this.u8(5);
        this.f64(Number(v));
      } else if (typeof v === "string") {
        this.u8(6);
        this.str(v);
      } else if (v instanceof Date) {
        this.u8(8);
        if (!this.ref(v)) {
          this.u29(1);
          this.f64(v.getTime());
        }
      } else if (v instanceof Uint8Array) {
        this.u8(12);
        if (!this.ref(v)) {
          this.u29(v.length << 1 | 1);
          this.ensure(v.length);
          this.buf.set(v, this.len);
          this.len += v.length;
        }
      } else if (Array.isArray(v)) {
        this.u8(9);
        if (!this.ref(v)) {
          this.u29(v.length << 1 | 1);
          for (const k of Object.keys(v)) if (!/^\d+$/.test(k)) {
            this.str(k);
            this.write(v[k]);
          }
          this.str("");
          for (const item of v) this.write(item);
        }
      } else if (v instanceof Amf3TypedObject) {
        this.u8(10);
        if (!this.ref(v)) {
          const keys = Object.keys(v.values);
          this.u29(keys.length << 4 | 3);
          this.str(v.className);
          for (const k of keys) this.str(k);
          for (const k of keys) this.write(v.values[k]);
        }
      } else if (typeof v === "object") {
        this.u8(10);
        if (!this.ref(v)) {
          this.u29(11);
          this.str("");
          for (const [k, val] of Object.entries(v)) {
            if (val === void 0 || typeof val === "function") continue;
            this.str(k);
            this.write(val);
          }
          this.str("");
        }
      } else {
        this.u8(0);
      }
      return this;
    }
    bytes() {
      return this.buf.slice(0, this.len);
    }
  };
  function amf3Encode(v) {
    return new Amf3Writer().write(v).bytes();
  }
  function amf3Decode(bytes2, pos = 0) {
    const r = new Amf3Reader(bytes2, pos);
    const value = r.read();
    return { value, end: r.pos };
  }

  // server/src/game/sfs2013/protocol.ts
  var SALT = [26];
  var Up = {
    AsObj: 10002,
    Hit: 10011,
    JoinRoom: 10012,
    LeaveRoom: 10013,
    Login: 10016,
    Logout: 10017,
    PubMsg: 10020,
    SetRvars: 10027,
    SetUvars: 10028,
    XtReq: 10033,
    XtReqB: 10034
  };
  var Down = {
    createRmKO: 20015,
    dataObj: 20016,
    dmnMsg: 20017,
    joinKO: 20018,
    joinOK: 20019,
    leaveRoom: 20020,
    logKO: 20021,
    logout: 20023,
    pubMsg: 20026,
    rVarsUpdate: 20034,
    uER: 20036,
    userGone: 20037,
    uVarsUpdate: 20039,
    xtRes: 20041,
    crossDomain: 20042,
    xtResB: 20043
  };
  var EXT_NAMES = {
    0: "StartupExtension",
    1: "UserExtension",
    2: "TeamExtension",
    3: "BuddyManagerExtension",
    4: "ScoreManager",
    5: "Log",
    6: "SurveyExtension",
    7: "PlayBookExtension",
    8: "OneOffExtension",
    9: "MemberExtension",
    10: "GameRealTimeRankManager",
    11: "GameMessageList",
    12: "UserDisplayExtension",
    13: "PocketMonsterExtension",
    14: "PetFightExtension",
    15: "PetExtension",
    16: "PetExtension2",
    17: "PetEggExtension",
    18: "AntiAddictionExtension",
    19: "TowerExtension",
    20: "SynthesizeExtension",
    21: "MaterialExtension",
    22: "RobotExtension",
    23: "MatchExtension",
    24: "FightRingExtension",
    25: "RobMedalArenaExtension",
    26: "HouseExtension",
    27: "UserFurntitureInfoExtension",
    28: "ShootExtension",
    29: "TaskExtension",
    30: "DailyTaskExtension",
    31: "GiftBagExtension",
    32: "AvatarExtension",
    33: "FollowExtension",
    34: "SundriesExtension",
    35: "FBExtension",
    36: "AvocationExtension",
    37: "MidautumnGameExtension",
    38: "MoveStateExtension",
    39: "UserStateExtension",
    40: "AchievementExtension",
    41: "NewAreaExtension",
    42: "HolidayExtension",
    43: "MailBoxExtension",
    44: "PTowerExtension",
    45: "PMDailyCollectExtension",
    46: "VipNickNameExtension",
    47: "VipTowerExtension",
    48: "PlantExtension",
    49: "PlantItemExtension",
    50: "ConnectTestExtension",
    52: "WisdomStarExtension",
    53: "DonateExtension",
    54: "BalloonExtension",
    55: "UserGameExtension",
    56: "PlaneChessGameManager",
    57: "PeriodicActiveExtension",
    58: "MagicCubicExtension",
    59: "WarTeamExtension",
    60: "WTBeatBossExtension",
    61: "HouseOutSideExtension",
    62: "WarTeamTaskExtension",
    63: "PiracyTowerExtension",
    64: "MentalHallExtension",
    65: "ZooExtension",
    66: "StateExtension",
    67: "HotSpringExtension",
    68: "MSExtension",
    69: "LabExtension",
    70: "KOFExtension",
    71: "FieldGameExtension",
    72: "HbhBeatBossExtension",
    73: "TeamTowerExtension",
    74: "LuandouExtension",
    75: "Sundries2ndExtension",
    76: "GalaxyExtension",
    99: "TrainingExtension"
  };
  function encodeVar(name, v) {
    if (typeof v === "boolean") return { name, type: "b", value: v ? "1" : "0" };
    if (typeof v === "number") return { name, type: "n", value: String(v) };
    if (v === null || v === void 0) return { name, type: "x", value: "" };
    return { name, type: "s", value: String(v) };
  }
  var dec2 = new TextDecoder("utf-8");
  var enc2 = new TextEncoder();
  var Reader = class {
    view;
    bytes;
    pos = 0;
    constructor(bytes2) {
      this.bytes = bytes2;
      this.view = new DataView(bytes2.buffer, bytes2.byteOffset, bytes2.byteLength);
    }
    get left() {
      return this.bytes.length - this.pos;
    }
    u8() {
      return this.view.getUint8(this.pos++);
    }
    i16() {
      const v = this.view.getInt16(this.pos);
      this.pos += 2;
      return v;
    }
    i32() {
      const v = this.view.getInt32(this.pos);
      this.pos += 4;
      return v;
    }
    bool() {
      return this.u8() === 49;
    }
    char() {
      return String.fromCharCode(this.u8());
    }
    utf() {
      const n = this.view.getUint16(this.pos);
      this.pos += 2;
      const s = dec2.decode(this.bytes.subarray(this.pos, this.pos + n));
      this.pos += n;
      return s;
    }
    amf3() {
      const { value, end } = amf3Decode(this.bytes, this.pos);
      this.pos = end;
      return value;
    }
    rest() {
      const b = this.bytes.slice(this.pos);
      this.pos = this.bytes.length;
      return b;
    }
  };
  function decodeClientFrame(frame, saltLen = SALT.length) {
    const r = new Reader(frame);
    r.i32();
    const packetNum = r.u8();
    r.pos += saltLen;
    const type = r.u8();
    const action = r.i16();
    const roomId = r.i32();
    let msg;
    switch (action) {
      case Up.Login:
        msg = { kind: "login", roomId, zone: r.utf(), user: r.utf(), pass: r.utf() };
        break;
      case Up.JoinRoom:
        msg = { kind: "joinRoom", roomId, room: r.utf(), notSpectator: r.bool(), leaveId: r.i32(), isTemp: r.bool(), pass: r.utf() };
        break;
      case Up.LeaveRoom:
        msg = { kind: "leaveRoom", roomId, leave: r.i32() };
        break;
      case Up.Logout:
        msg = { kind: "logout", roomId };
        break;
      case Up.Hit:
        msg = { kind: "hit", roomId };
        break;
      case Up.PubMsg:
        msg = { kind: "pubMsg", roomId, message: r.utf() };
        break;
      case Up.SetUvars: {
        const n = r.i16();
        const vars = [];
        for (let i = 0; i < n; i++) vars.push({ name: r.utf(), type: r.char(), value: r.utf() });
        msg = { kind: "setUvars", roomId, vars };
        break;
      }
      case Up.SetRvars: {
        const setOwnership = r.bool();
        const n = r.i16();
        const vars = [];
        for (let i = 0; i < n; i++) {
          vars.push({ name: r.utf(), type: r.char(), value: r.utf(), persistent: r.bool(), priv: r.bool() });
        }
        msg = { kind: "setRvars", roomId, setOwnership, vars };
        break;
      }
      case Up.AsObj:
        msg = { kind: "asObj", roomId, xml: r.utf() };
        break;
      case Up.XtReq: {
        const extId = r.i16();
        msg = { kind: "xt", roomId, extId, ext: EXT_NAMES[extId] ?? `ext${extId}`, cmd: r.utf(), params: r.left ? r.amf3() : null };
        break;
      }
      case Up.XtReqB: {
        const data = r.rest();
        const extId = data[0];
        msg = { kind: "xtB", roomId, extId, ext: EXT_NAMES[extId] ?? `ext${extId}`, data: data.slice(1) };
        break;
      }
      default:
        msg = { kind: "unknown", type, action, roomId, data: r.rest() };
    }
    return { packetNum, msg };
  }
  function nextPacketNum(prev) {
    if (prev === -1) return 0;
    const n = prev * 3 + 1;
    return n >= 127 ? 0 : n;
  }
  var Writer = class {
    parts = [];
    scratch = new DataView(new ArrayBuffer(8));
    u8(v) {
      this.parts.push(new Uint8Array([v & 255]));
      return this;
    }
    i16(v) {
      this.scratch.setInt16(0, v);
      this.parts.push(new Uint8Array(this.scratch.buffer.slice(0, 2)));
      return this;
    }
    i32(v) {
      this.scratch.setInt32(0, v);
      this.parts.push(new Uint8Array(this.scratch.buffer.slice(0, 4)));
      return this;
    }
    bool(v) {
      return this.u8(v ? 49 : 48);
    }
    char(c) {
      return this.u8(c.charCodeAt(0));
    }
    utf(s) {
      const b = enc2.encode(s);
      if (b.length > 65535) throw new Error("utf string too long");
      this.parts.push(new Uint8Array([b.length >> 8, b.length & 255]), b);
      return this;
    }
    raw(b) {
      this.parts.push(b);
      return this;
    }
    vars(vars) {
      this.i16(vars.length);
      for (const v of vars) this.utf(v.name).char(v.type).utf(v.value);
      return this;
    }
    /** The payload alone. */
    body() {
      return concat(...this.parts);
    }
    /** The payload wrapped in its int32 length. */
    frame() {
      const body = concat(...this.parts);
      const head = new Uint8Array(4);
      new DataView(head.buffer).setInt32(0, body.length);
      return concat(head, body);
    }
  };
  function sys(action, roomId) {
    return new Writer().u8(0).i16(action).i32(roomId);
  }
  var S2 = {
    policy() {
      const xml = '<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>';
      return concat(enc2.encode(xml), new Uint8Array([0]));
    },
    /** Extension response: an AMF3 object whose "_cmd" names it. */
    ext(obj) {
      return new Writer().u8(1).raw(amf3Encode(obj)).frame();
    },
    extB(data) {
      return new Writer().u8(2).raw(data).frame();
    },
    logKO(error) {
      return sys(Down.logKO, -1).utf(error).frame();
    },
    logout() {
      return sys(Down.logout, -1).frame();
    },
    joinOK(room, users, joinData = "") {
      const w = sys(Down.joinOK, room.id).i32(room.id).utf(room.name).i32(room.maxUsers).utf(joinData).vars(room.vars);
      w.i16(users.length);
      for (const u of users) w.i32(u.id).utf(u.name).vars(u.vars);
      return w.frame();
    },
    joinKO(error) {
      return sys(Down.joinKO, -1).utf(error).frame();
    },
    userEnterRoom(roomId, u, isInit = false, joinData = "") {
      return sys(Down.uER, roomId).i32(u.id).utf(u.name).bool(isInit).utf(joinData).vars(u.vars).frame();
    },
    userGone(roomId, userId) {
      return sys(Down.userGone, roomId).i32(userId).frame();
    },
    leaveRoom(roomId) {
      return sys(Down.leaveRoom, roomId).i32(roomId).frame();
    },
    userVarsUpdate(roomId, userId, vars) {
      return sys(Down.uVarsUpdate, roomId).i32(userId).vars(vars).frame();
    },
    roomVarsUpdate(roomId, vars) {
      return sys(Down.rVarsUpdate, roomId).vars(vars).frame();
    },
    pubMsg(roomId, userId, message) {
      return sys(Down.pubMsg, roomId).i32(userId).utf(message).frame();
    },
    adminMsg(roomId, userId, message) {
      return sys(Down.dmnMsg, roomId).i32(userId).utf(message).frame();
    }
  };

  // server/src/game/sfs2013/server.ts
  var SFS2013_FRAMING = {
    lengthOffset: 0,
    lengthBytes: 4,
    littleEndian: false,
    lengthIncludesHeader: false,
    headerBytes: 4,
    maxFrame: 1 << 20
  };
  var sfs2013Codec = {
    name: "sfs2013",
    decode(frame) {
      const f = decodeClientFrame(frame);
      const cmd = f.msg.kind === "xt" || f.msg.kind === "xtB" ? `${f.msg.ext}.${f.msg.kind === "xt" ? f.msg.cmd : "bytes"}` : f.msg.kind;
      return { cmd, seq: f.packetNum, body: f.msg, raw: frame };
    },
    encode() {
      throw new Error("sfs2013: send with Session.sendBytes(S.*)");
    }
  };
  var REPLACED_TEXT = "\u4F60\u7684\u5965\u62C9\u5728\u522B\u7684\u5730\u65B9\u767B\u5F55\u4E86\uFF0C\u8FD9\u91CC\u7684\u8FDE\u63A5\u5DF2\u7ECF\u65AD\u5F00\u3002";
  var sceneOfRoom = (r) => r ? r.scene ?? r.name.split("@")[0] : "";
  var PLAYER = "sfs2013.player";
  var ROOM_NAME_MAX = 500;
  var ROOMS_MAX = 5e3;
  var CHAT_MAX = 300;
  var CHAT_EVERY_MS = 300;
  var RVAR_MAX = 256;
  var UVARS_MAX = 64;
  var UVAR_BYTES = 8192;
  var TEMP_ROOM = /_Home$|^sandboxroom[_|]|@/;
  var utf82 = new TextEncoder();
  function varBytes(vars) {
    let n = 0;
    for (const v of vars) n += utf82.encode(v.name).length + utf82.encode(String(v.value ?? "")).length;
    return n;
  }
  var World = class {
    rooms = /* @__PURE__ */ new Map();
    handlers = /* @__PURE__ */ new Map();
    nextRoomId = 1;
    nextUserId = 10001;
    emu;
    opts;
    constructor(emu, opts = {}) {
      this.emu = emu;
      this.opts = opts;
      emu.onConnect((s) => {
        s.sendBytes(S2.policy(), "sfs2013: policy (client discards it)");
        if (this.opts.loginWaitMs) {
          const t = setTimeout(() => {
            if (!s.closed && !this.player(s)) {
              s.note("sfs2013: no login in time, closed");
              s.close();
            }
          }, this.opts.loginWaitMs);
          t.unref?.();
        }
      });
      emu.onClose((s) => {
        if (this.player(s)) for (const h of this.leaveHooks) h(s);
        this.leave(s, true);
      });
      emu.onUnhandled((s, m) => this.handle(s, m.body, m.seq ?? 0));
    }
    leaveHooks = [];
    /** Called when a logged-in 奥拉's connection ends (before it leaves its room). */
    onLeaveGame(hook) {
      this.leaveHooks.push(hook);
    }
    joinHooks = [];
    /** Called when an 奥拉 has come into a room (from: the room it was in before, or ""). */
    onJoinRoom(hook) {
      this.joinHooks.push(hook);
    }
    /** Register an extension handler: "SundriesExtension.70_12", or "SundriesExtension.*". */
    xt(key, handler) {
      this.handlers.set(key, handler);
      return this;
    }
    player(s) {
      return s.data[PLAYER];
    }
    room(name, isTemp = false) {
      let r = this.rooms.get(name);
      if (!r) {
        r = { id: this.nextRoomId++, name, scene: name.split("@")[0], maxUsers: 100, vars: /* @__PURE__ */ new Map(), members: /* @__PURE__ */ new Set(), isTemp };
        this.rooms.set(name, r);
      }
      return r;
    }
    roomById(id) {
      for (const r of this.rooms.values()) if (r.id === id) return r;
      return void 0;
    }
    wireUser(p) {
      return { id: p.id, name: p.name, vars: [...p.vars.values()] };
    }
    /** Change a player's user variables from the server side and tell the room (the player too). */
    setUserVars(s, vars) {
      const p = this.player(s);
      if (!p) return;
      const list = Object.entries(vars).map(([k, v]) => encodeVar(k, v));
      for (const v of list) {
        if (v.type === "x") p.vars.delete(v.name);
        else p.vars.set(v.name, v);
      }
      if (p.room) this.sendRoom(p.room, S2.userVarsUpdate(p.room.id, p.id, list));
      else s.sendBytes(S2.userVarsUpdate(0, p.id, list));
    }
    /** One user variable, set and told only when it changes (a following 亚比's "p", which several paths set). */
    setUserVarOnce(s, name, value) {
      const now = this.player(s)?.vars.get(name);
      const v = encodeVar(name, value);
      if (now && now.type === v.type && now.value === v.value) return;
      this.setUserVars(s, { [name]: value });
    }
    /** The session of the 奥拉 of that name in the game, if any. */
    online(name) {
      for (const s of this.emu.sessions) if (this.player(s)?.name === name) return s;
      return void 0;
    }
    /** Every 奥拉 in the game: name, id and room. */
    players() {
      const out = [];
      for (const s of this.emu.sessions) {
        const p = this.player(s);
        if (p) out.push({ session: s, player: p });
      }
      return out;
    }
    /** An extension message to one session from the server side (no request). */
    push(s, cmd, obj) {
      s.sendBytes(S2.ext({ _cmd: cmd, ...obj }), `xt push ${cmd}`);
    }
    sendRoom(room, bytes2, except, note) {
      for (const m of room.members) if (m !== except) m.sendBytes(bytes2, note);
    }
    async handle(s, msg, packetNum) {
      const p = this.player(s);
      if (p && this.opts.checkPacketNumbers !== false) {
        const want = nextPacketNum(p.lastPacket);
        if (packetNum !== want) s.note(`sfs2013: packet number ${packetNum}, expected ${want}`);
        p.lastPacket = packetNum;
      }
      switch (msg.kind) {
        case "login":
          return this.login(s, msg.zone, msg.user, msg.pass, packetNum);
        case "joinRoom":
          return this.join(s, msg.room, msg.isTemp);
        case "leaveRoom":
          this.leave(s);
          s.sendBytes(S2.leaveRoom(msg.leave));
          return;
        case "logout":
          if (p) for (const h of this.leaveHooks) h(s);
          this.leave(s);
          s.sendBytes(S2.logout());
          s.data[PLAYER] = void 0;
          return;
        case "hit":
          return;
        case "pubMsg": {
          if (!p?.room || msg.message.length > CHAT_MAX) return;
          const now = Date.now();
          if (now - (p.lastChat ?? 0) < CHAT_EVERY_MS) return;
          p.lastChat = now;
          this.sendRoom(p.room, S2.pubMsg(p.room.id, p.id, msg.message));
          return;
        }
        case "setUvars": {
          if (!p || msg.vars.length > UVARS_MAX) return;
          const next = new Map(p.vars);
          for (const v of msg.vars) {
            if (v.type === "x") next.delete(v.name);
            else next.set(v.name, v);
          }
          if (next.size > UVARS_MAX || varBytes(next.values()) > UVAR_BYTES) {
            s.note(`sfs2013: user variables of "${p.name}" over the limit, not set`);
            return;
          }
          p.vars = next;
          if (p.room) this.sendRoom(p.room, S2.userVarsUpdate(p.room.id, p.id, msg.vars));
          return;
        }
        case "setRvars": {
          if (!p?.room || !p.room.isTemp) return;
          const vars = msg.vars.filter((v) => v.name.length <= RVAR_MAX && String(v.value ?? "").length <= RVAR_MAX).slice(0, 50);
          for (const v of vars) {
            if (v.type === "x") p.room.vars.delete(v.name);
            else if (p.room.vars.size < 50 || p.room.vars.has(v.name)) p.room.vars.set(v.name, v);
          }
          if (vars.length) this.sendRoom(p.room, S2.roomVarsUpdate(p.room.id, vars));
          return;
        }
        case "xt":
          return this.dispatchXt(s, msg.ext, msg.cmd, msg.params);
        default:
          s.note(`sfs2013: unhandled ${msg.kind}`);
      }
    }
    /** Sessions whose login is being checked: one at a time a session. */
    loggingIn = /* @__PURE__ */ new WeakSet();
    async login(s, zone, user, pass, packetNum) {
      if (this.loggingIn.has(s) || this.player(s)) {
        s.note(`sfs2013: a second login on one connection ignored`);
        return;
      }
      this.loggingIn.add(s);
      let r;
      try {
        r = this.opts.login ? await this.opts.login(zone, user, pass, s) : { id: this.nextUserId++, name: user || `aola${this.nextUserId}` };
      } catch (err) {
        this.loggingIn.delete(s);
        throw err;
      }
      if (s.closed) return void this.loggingIn.delete(s);
      if (r.error) {
        s.note(`sfs2013: login of "${user}" refused: ${r.error}`);
        if (this.opts.refuseDelayMs) await new Promise((ok) => setTimeout(ok, this.opts.refuseDelayMs));
        this.loggingIn.delete(s);
        s.sendBytes(S2.logKO(r.error), "logKO");
        return;
      }
      this.loggingIn.delete(s);
      for (const other of this.emu.sessions) {
        if (other !== s && this.player(other)?.name === r.name) {
          for (const h of this.leaveHooks) h(other);
          this.leave(other, true);
          other.sendBytes(S2.ext({ _cmd: "revival_replaced", msg: REPLACED_TEXT }), "revival_replaced");
          other.close();
        }
      }
      const p = { id: r.id, name: r.name, vars: /* @__PURE__ */ new Map(), lastPacket: packetNum };
      for (const [k, v] of Object.entries(r.vars ?? {})) p.vars.set(k, encodeVar(k, v));
      s.data[PLAYER] = p;
      s.note(`sfs2013: ${r.name} (#${r.id}) logged in to zone "${zone}"`);
      s.sendBytes(
        S2.ext({ _cmd: "logOK", id: r.id, n: r.name, lastLoginTime: this.emu.clock.now().getTime(), ...r.extra }),
        "logOK"
      );
    }
    join(s, name, isTemp = false) {
      const p = this.player(s);
      if (!p) {
        s.sendBytes(S2.joinKO("not logged in"));
        return;
      }
      const from = p.room?.name ?? "";
      this.leave(s);
      if (name.length > ROOM_NAME_MAX || !this.rooms.has(name) && this.rooms.size >= ROOMS_MAX) {
        s.sendBytes(S2.joinKO("no such room"));
        return;
      }
      void isTemp;
      const room = this.room(name, TEMP_ROOM.test(name));
      const users = [...room.members, s].flatMap((m) => {
        const mp = this.player(m);
        return mp ? [this.wireUser(mp)] : [];
      });
      let ok;
      try {
        ok = S2.joinOK({ id: room.id, name: room.name, maxUsers: room.maxUsers, vars: [...room.vars.values()] }, users);
      } catch (err) {
        s.note(`sfs2013: joinOK ${name} not built: ${err.message}`);
        if (!room.members.size) this.rooms.delete(room.name);
        s.sendBytes(S2.joinKO("no such room"));
        return;
      }
      room.members.add(s);
      p.room = room;
      s.sendBytes(ok, `joinOK ${name}`);
      this.sendRoom(room, S2.userEnterRoom(room.id, this.wireUser(p)), s);
      this.opts.onJoin?.(s, p, room);
      for (const h of this.joinHooks) h(s, p, room, from);
    }
    leave(s, gone = false) {
      const p = this.player(s);
      const room = p?.room;
      if (!p || !room) return;
      room.members.delete(s);
      p.room = void 0;
      this.sendRoom(room, S2.userGone(room.id, p.id));
      if (room.members.size === 0) this.rooms.delete(room.name);
      if (gone) s.data[PLAYER] = void 0;
    }
    /**
     * One player's extension requests run one after another, as on the 2013
     * server: handlers load the player's record, change it and save it, and two
     * at once (say a task step and a new 亚比) would lose one change.
     */
    xtQueues = /* @__PURE__ */ new WeakMap();
    dispatchXt(s, ext, cmd, params) {
      const run = (this.xtQueues.get(s) ?? Promise.resolve()).then(() => this.runXt(s, ext, cmd, params));
      this.xtQueues.set(
        s,
        run.catch(() => void 0)
      );
      return run;
    }
    async runXt(s, ext, cmd, params) {
      const p = this.player(s);
      const h = this.handlers.get(`${ext}.${cmd}`) ?? this.handlers.get(`${ext}.*`) ?? this.handlers.get("*");
      if (!p || !h) {
        s.note(`sfs2013: unhandled xt ${ext}.${cmd} ${JSON.stringify(params)?.slice(0, 300)}`);
        return;
      }
      const ctx = {
        session: s,
        player: p,
        world: this,
        params: params && typeof params === "object" ? params : {},
        reply: (obj, c) => {
          const name = c ?? cmd;
          if (name === "onAmountUpdated" && typeof obj.amount === "string") {
            const amount = obj.amount.split("#").filter((a) => !a.startsWith("5_")).join("#");
            if (!amount) return;
            obj = { ...obj, amount };
          }
          s.sendBytes(S2.ext({ _cmd: name, ...obj }), `xt reply ${name}`);
        },
        broadcast: (obj, c, includeSelf = true) => {
          if (p.room) this.sendRoom(p.room, S2.ext({ _cmd: c, ...obj }), includeSelf ? void 0 : s, `xt broadcast ${c}`);
        }
      };
      await h(ctx, cmd);
    }
  };

  // server/src/game/sfs2013/petdic.ts
  var MET = 1;
  var OWNED = 2;
  var LATEST_PETS = [1417, 1418, 1419, 1420, 1421, 1422, 1424, 1425, 1426];
  var tops = /* @__PURE__ */ new WeakMap();
  function dicTop(t) {
    let top = tops.get(t.species);
    if (top === void 0) {
      top = 0;
      for (const k of Object.keys(t.species)) {
        const n = Number(k);
        if (n < 1e4 && n > top) top = n;
      }
      tops.set(t.species, top);
    }
    return top;
  }
  function markDic(o, t, race, state) {
    if (!Number.isInteger(race) || race < 1 || race > dicTop(t) || !t.species[String(race)]) return false;
    const s = typeof o.dic === "string" ? o.dic : "";
    if (Number(s.charAt(race - 1) || "0") >= state) return false;
    o.dic = s.padEnd(race - 1, "0").slice(0, race - 1) + String(state) + s.slice(race);
    return true;
  }
  function dicMarks(o, t) {
    for (const p of [...o.pets ?? [], ...o.storage ?? []]) if (p) markDic(o, t, Number(p.race), OWNED);
    return "0".repeat(10) + (typeof o.dic === "string" ? o.dic : "").padEnd(dicTop(t), "0");
  }
  var NEW_RECORD = ["LatePMChartNotify", {}];
  function installPetDic(world, deps) {
    world.xt("PetExtension.54_5", async (ctx) => {
      const o = await deps.load(ctx);
      const before = o.dic;
      const res = dicMarks(o, await deps.tables());
      if (o.dic !== before) await deps.save(o);
      ctx.reply({ res }, "54_5");
    });
    world.xt("PetExtension2.54e_11", async (ctx) => {
      const o = await deps.load(ctx);
      const t = await deps.tables();
      const p = LATEST_PETS.filter((r) => t.species[String(r)]);
      ctx.reply({ l: o.dicLatest || !p.length ? 0 : 1, p: p.join(",") }, "54e_11");
    });
    world.xt("PetExtension2.54e_12", async (ctx) => {
      const o = await deps.load(ctx);
      if (o.dicLatest) return;
      o.dicLatest = true;
      await deps.save(o);
    });
  }

  // server/src/game/sfs2013/skilltext.ts
  var BAD_STATUSES = ["\u9EBB\u75F9", "\u51B0\u51BB", "\u7761\u7720", "\u70E7\u4F24", "\u4E2D\u6BD2", "\u6DF7\u4E71"];
  var ATTRS = {
    \u666E\u901A: 0,
    \u683C\u6597: 1,
    \u98DE\u884C: 2,
    \u6BD2: 3,
    \u722C\u884C: 4,
    \u571F: 5,
    \u866B: 6,
    \u6570\u7801: 7,
    \u673A\u68B0: 8,
    \u706B: 9,
    \u6C34: 10,
    \u6728: 11,
    \u7535: 12,
    \u795E\u79D8: 13,
    \u51B0: 14,
    \u4E0A\u53E4: 15,
    \u6697\u9ED1: 16,
    \u5149\u660E: 18,
    \u9F99: 19,
    \u5723\u7075: 20,
    \u795E\u5175: 21,
    \u738B: 22
  };
  var ALL_STATS = ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"];
  var FIVE_STATS = ["atk", "def", "satk", "sdef", "spd"];
  var STAT_WORDS = {
    \u653B\u51FB: ["atk"],
    \u666E\u653B: ["atk"],
    \u9632\u5FA1: ["def"],
    \u666E\u9632: ["def"],
    \u7279\u653B: ["satk"],
    \u7279\u9632: ["sdef"],
    \u901F\u5EA6: ["spd"],
    \u547D\u4E2D: ["acc"],
    \u95EA\u907F: ["eva"],
    \u66B4\u51FB: ["crit"],
    \u5168\u5C5E\u6027: ALL_STATS,
    \u53CC\u653B: ["atk", "satk"],
    \u53CC\u9632: ["def", "sdef"]
  };
  var STAT_RE = "(?:\u5168\u5C5E\u6027|\u653B\u51FB|\u666E\u653B|\u9632\u5FA1|\u666E\u9632|\u7279\u653B|\u7279\u9632|\u901F\u5EA6|\u547D\u4E2D|\u95EA\u907F|\u66B4\u51FB|\u53CC\u653B|\u53CC\u9632)";
  var STAT_LIST = `${STAT_RE}(?:(?:\u548C|\u3001|\u53CA|\u4E0E)${STAT_RE})*`;
  var ST = "(?:\u9EBB\u75F9|\u5BB3\u6015|\u51B0\u51BB|\u7761\u7720|\u70E7\u4F24|\u4E2D\u6BD2|\u6DF7\u4E71|\u675F\u7F1A|\u8870\u5F31|\u5BC4\u751F)";
  var CN = { \u4E00: "1", \u4E8C: "2", \u4E24: "2", \u4E09: "3", \u56DB: "4", \u4E94: "5", \u516D: "6", \u4E03: "7", \u516B: "8", \u4E5D: "9", \u5341: "10" };
  var FRACS = { \u56DB\u5206\u4E4B\u4E00: "1/4", \u4E09\u5206\u4E4B\u4E00: "1/3", \u4E8C\u5206\u4E4B\u4E00: "1/2", \u4E09\u5206\u4E4B\u4E8C: "2/3", \u516B\u5206\u4E4B\u4E00: "1/8" };
  function normalise(desc) {
    let d = String(desc || "").replace(/％/g, "%").replace(/[～〜]/g, "~").replace(/(\d)\s*[-－—]\s*(\d)/g, "$1~$2").replace(/[（]/g, "(").replace(/[）]/g, ")").replace(/[：]/g, ":").replace(/[“”"]/g, "").replace(/[３]/g, "3").replace(/机率/g, "\u6982\u7387").replace(/回避/g, "\u95EA\u907F").replace(/对手/g, "\u5BF9\u65B9").replace(/催眠/g, "\u7761\u7720").replace(/先发后至/g, "\u5148\u53D1").replace(/普攻攻击/g, "\u666E\u901A\u653B\u51FB").replace(/普通攻击和特殊攻击|特殊攻击和普通攻击|普通和特殊/g, "\u666E\u901A\u653B\u51FB\u4E0E\u7279\u6B8A\u653B\u51FB").replace(/等级的等级/g, "\u7684\u7B49\u7EA7").replace(/(\d)等级/g, "$1\u7EA7").replace(/(\d)个等级/g, "$1\u7EA7").replace(/(\d+)\s*个回合/g, "$1\u56DE\u5408").replace(/，(?:此)?技能威力(?=加倍|提升至\d)/g, "\uFF0C\u5A01\u529B").replace(/(\d+)%(?=削弱|提升|令|使|降低)/g, "$1%\u6982\u7387").replace(/次回合自己无法行动/g, "\u4E0B\u56DE\u5408\u81EA\u5DF1\u505C\u6B62\u884C\u52A8").replace(/若暴击，(?:则)?(?=提升)/g, "\u66B4\u51FB\u540E");
    for (const [k, v] of Object.entries(FRACS)) d = d.split(k).join(v);
    d = d.replace(/([一二两三四五六七八九十])(级|回合|次|点|倍|种|个)/g, (_m, a, b) => CN[a] + b);
    d = d.replace(new RegExp(`(\\d\u7EA7)\u548C(?=${STAT_RE})`, "g"), "$1\uFF0C").replace(/停止1回合|不能行动1回合/g, "\u505C\u6B62\u884C\u52A81\u56DE\u5408");
    for (let i = 0; i < 4; i++) d = d.replace(new RegExp(`(${STAT_RE})[\uFF0C,](?=${STAT_RE})`, "g"), "$1\u3001");
    return d;
  }
  var num2 = (s, dflt = 0) => s === void 0 || s === "" ? dflt : Number(s);
  var frac = (s) => {
    if (s === "\u4E00\u534A" || s === "1/2") return 0.5;
    if (s === "\u5168\u90E8" || s === "\u6240\u6709") return 1;
    const m = s.match(/^(\d+)\/(\d+)$/);
    if (m) return Number(m[1]) / Number(m[2]);
    const p = s.match(/^(\d+(?:\.\d+)?)%$/);
    if (p) return Number(p[1]) / 100;
    return Number(s) || 0;
  };
  var pct = (s) => s ? Math.min(100, Number(s)) : 100;
  var statsOf2 = (list) => [...new Set(list.split(/和|、|及|与/).flatMap((w) => STAT_WORDS[w] ?? []))];
  var statusOf = (s) => s;
  var FILLER = [
    /攻击对方(?:单体|全体|全场|随机目标|单个)?(?:亚比)?/g,
    /给对方(?:单体|全体|全场)?(?:亚比)?造成伤害/g,
    /给(?:全场|对方全体)亚比造成伤害/g,
    /攻击(?:自己以外的)?全场(?:亚比)?/g,
    /攻击自己以外的全场亚比/g,
    /对方每个目标均有/g,
    /威力(?:十分)?巨大|破坏力巨大|威力不可小觑|难以想象、极其恐怖的破坏力|威力很大/g,
    /(?:对|对于)?(?:某些|大多数|大部分)?(?:BOSS|boss|守护者?|守护的?)(?:会产生抵抗|无效|效果会削弱|效果减半|的概率和效果会削弱|回复效果减半|效果会减半)/g,
    /(?:可是)?(?:对|对于)(?:某些|大多数|大部分)?(?:BOSS|boss|守护者?)[^，；。]*/g,
    /可是|回复效果减半|当回合|直至病毒死亡|攻击等级越高，概率越高|自己速度等级越高效果越强|若对方是青龙守护，则伤害和效果概率加倍|对对方单体造成伤害/g,
    /(?:替换|交换|更换)亚比(?:有效|无效)/g,
    /对守护(?:者)?无效/g,
    /我方全体(?:亚比|队员)?|我方单个亚比|以后|不需要任何解释的强大|恢复效果不能叠加|自己等级越高(?:伤害|威力)越(?:高|大)|命中次数越多，威力越大|威力递增/g,
    /宁教我负天下人，休教天下人负我|老骥伏枥，志在千里，烈士暮年，壮心不已|向对方全体亚比派发大量福袋|通过命运的力量/g,
    /(?:替换|交换)亚比(?:有效|无效|可解除|解除(?:此)?效果|后(?:效果)?消失)/g,
    /不可叠加(?:使用)?|不能叠加|效果不能叠加|可以叠加使用|可接力/g,
    /(?:持续|5回合)?有效/g,
    /向对方单体扔出两把刷子/g,
    /将周围的水分变为无数根水针来/g,
    /孤好梦中杀人|周公吐哺，天下归心|觉醒技|通过命运的力量|传说中|吞噬对方的时间/g,
    /至少能为对方亚比|再用亚比球捕捉会比较容易成功/g,
    /给对方单体造成巨大伤害|撞击对方全体|对属性攻击无效|保护自己|额外/g,
    /(?:持续|在)?\d+回合(?:内|有效)?/g,
    /对方单体|对方全体|单体/g,
    /(?:对某些守护)?效果较弱|自己速度越快，成功概率越高|使用1次/g,
    /本回合|使用后|命中后|命中则|命中|攻击|并且|并|且|但|同时|另外|则|的|，|；|。|,|;|\.|、|!|！|\s/g
  ];
  var Reader2 = class {
    d;
    left;
    constructor(desc) {
      this.d = normalise(desc);
      this.left = this.d;
    }
    /** Every match of re in what is left: fn(match); the words are taken (they are read). */
    take(re, fn) {
      const g = new RegExp(re.source, re.flags.includes("g") ? re.flags : re.flags + "g");
      let any = false;
      for (const m of [...this.left.matchAll(g)]) {
        if (fn(m) === false) continue;
        any = true;
        this.left = this.left.slice(0, m.index) + "\uFF3F".repeat(m[0].length) + this.left.slice(m.index + m[0].length);
      }
      return any;
    }
    /** Is re in the words left? */
    has(re) {
      return re.test(this.left);
    }
    /** The words no reader took (fillers aside). */
    unread() {
      let s = this.left;
      for (const f of FILLER) s = s.replace(f, "");
      return s.replace(/＿+/g, " ").replace(/\s+/g, " ").trim();
    }
  };
  function readSkill(desc) {
    const r = new Reader2(desc);
    const e = { stages: [], statuses: [], timed: [] };
    const cond = (s) => {
      let m;
      if (m = s.match(/对方(?:被|处于)?(麻痹|冰冻|睡眠|烧伤|中毒|混乱|束缚|衰弱|寄生)/)) return { foeStatus: statusOf(m[1]) };
      if (/自己(?:中毒、麻痹或烧伤|处于异常状态)/.test(s)) return { selfStatus: /异常/.test(s) ? "any" : ["\u4E2D\u6BD2", "\u9EBB\u75F9", "\u70E7\u4F24"] };
      if (m = s.match(/对方体力值(?:小于|低于|少于)(1\/2|一半|1\/4)/)) return { foeHpBelow: frac(m[1]) };
      if (m = s.match(/自(?:己|身)(?:剩余)?体力值?(?:小于|低于|少于)(1\/2|一半|1\/4)/)) return { selfHpBelow: frac(m[1]) };
      if (m = s.match(/自(?:己|身)(?:剩余)?体力值?(?:大于|高于|多于)(1\/2|一半)/)) return { selfHpAbove: frac(m[1]) };
      if (/对方体力值(?:多过|比)自己多|对方体力值多于自己/.test(s)) return { foeHpMore: true };
      if (/对方体力值比自己少/.test(s)) return { foeHpLess: true };
      if (/自己后出手|^后发$/.test(s)) return { second: true };
      if (/自己速度比对方慢/.test(s)) return { slower: true };
      if (/自己(?:出手)?速度(?:快过|比)对方(?:快)?/.test(s)) return { faster: true };
      if (/暴击/.test(s)) return { crit: true };
      return void 0;
    };
    const turnsOf = (s, dflt) => {
      const m = s.match(/(?:持续|在|接下来)?(\d+)回合|(\d+)回合内|持续(\d+)回合/);
      return m ? num2(m[1] ?? m[2] ?? m[3]) : dflt;
    };
    {
      const x = r.d.match(/不能和(?:技能)?(\S{2,6}?)(?:效果)?同时存在/);
      if (x) e.exclusiveWith = x[1];
    }
    r.take(/1\/3概率秒杀对方单体，2\/3自己死亡/, () => {
      e.ohkoIf = { chance: 100 / 3 };
      e.ohkoFailFaint = true;
    });
    r.take(new RegExp(`^(\u63D0\u5347|\u524A\u5F31)(\u81EA\u5DF1|\u5BF9\u65B9\u5355\u4F53)(${STAT_LIST})\u7B49\u7EA7(\\d+)\u7EA7\uFF0C\u6301\u7EED(\\d+)\u56DE\u5408$`), (m) => {
      e.stages.push({ self: m[2] === "\u81EA\u5DF1", stats: statsOf2(m[3]), delta: (m[1] === "\u63D0\u5347" ? 1 : -1) * num2(m[4]), chance: 100, turns: num2(m[5]) });
    });
    r.take(/(\d+)%概率回复自己所有PP(\d+)点/, (m) => {
      e.ppSelf = num2(m[2]);
      e.ppSelfChance = num2(m[1]);
    });
    r.take(/(\d+)回合内附加(\d+)~(\d+)点伤害值?/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: num2(m[1]), a: num2(m[2]), b: num2(m[3]) }));
    r.take(/令对方衰弱，对方损失的体力值会逐渐增加(?:，持续(\d+)回合)?/, (m) => void e.statuses.push({ name: "\u8870\u5F31", chance: 100, ...m[1] ? { turns: [num2(m[1]), num2(m[1])] } : {} }));
    r.take(/若对方体力值比自己多，则有(\d+)%概率平分双方体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "painsplit", turns: num2(m[2]), chance: num2(m[1]) }));
    r.take(/我方全体(数码)系亚比防御值增加(\d+)%，特防值增加\d+%，持续(\d+)回合/, (m) => {
      e.trait = { name: m[1] + "\u7CFB", side: "self", statmult: { stats: ["def", "sdef"], mult: 1 + num2(m[2]) / 100, turns: num2(m[3]) } };
    });
    r.take(/使用后(\d+)回合内，每回合将自己所有PP值1点转化来回复(\d+)点体力值，可以叠加使用，最多叠加(\d+)次/, (m) => void e.timed.push({ who: "self", kind: "pphp", turns: num2(m[1]), n: num2(m[2]), stack: num2(m[3]) }));
    r.take(/(\d+)回合内，对方提升能力等级也会给自己提升/, (m) => void e.timed.push({ who: "self", kind: "mirror", turns: num2(m[1]) }));
    r.take(/持续(\d+)回合，自己属性能力等级不能被削弱；若对方提升它的属性能力等级，同样也会加给自己/, (m) => {
      e.timed.push({ who: "self", kind: "guard", turns: num2(m[1]) });
      e.timed.push({ who: "self", kind: "mirror", turns: num2(m[1]) });
    });
    r.take(/(?:使用后)?自身战斗力瞬间破表，额外增强自己双攻、双防和速度基础数值的(\d+)%，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "statmult", turns: num2(m[2]), stats: FIVE_STATS, mult: 1 + num2(m[1]) / 100 }));
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(${ST})\uFF0C\u82E5\u66B4\u51FB\u5219(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(?:${ST})`), (m) => void e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]), condChance: { cond: { crit: true }, chance: num2(m[3]) } }));
    r.take(/使用后(\d+)回合内，若当回合对方不使用攻击技能，则当回合结束时扣除对方(\d+)点体力值/, (m) => void e.timed.push({ who: "foe", kind: "punish", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/恢复自己所有被削弱的属性能力等级并清除自己的不良状态，且(\d+)~(\d+)回合内不受不良状态影响/, (m) => {
      e.restoreOwn = { chance: 100 };
      e.cure = true;
      e.timed.push({ who: "self", kind: "nostatus", turns: num2(m[2]), turnsMin: num2(m[1]) });
    });
    r.take(/(?:使用后，)?(\d+)%概率闪避特殊攻击技能造成的伤害，持续(\d+)~(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num2(m[3]), turnsMin: num2(m[2]), spec: num2(m[1]) }));
    r.take(/连续攻击对方(\d+)~(\d+)回合，威力每回合递增/, (m) => void (e.rollout = { turns: num2(m[2]), min: num2(m[1]) }));
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(${ST})\u540C\u65F6(${ST})`), (m) => {
      e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]) }, { name: statusOf(m[3]), chance: 100, cond: { landed: true } });
    });
    const mk = (n) => ({ mark: n.replace(/[“”"]/g, "") });
    r.take(/若存在技能(\S+?)的效果，此技能威力可以再增加(\d+)/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), power: num2(m[2]) }));
    r.take(/使用后能给\S+?类的技能附加特殊效果|并且下次使用\S+?技能效果提升/, () => void 0);
    r.take(/有(\S+?)效果存在的话，能将伤害值的(1\/3)转化来回复自己体力值/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), drain: frac(m[2]) }));
    r.take(/有(\S+?)效果存在的话，有一定概率令对方处于各种异常状态/, (m) => {
      for (const st of BAD_STATUSES) e.statuses.push({ name: st, chance: 30 / BAD_STATUSES.length, cond: mk(m[1]) });
    });
    r.take(/恢复被降低的属性/, () => void (e.restoreOwn = { chance: 100 }));
    r.take(/有(\S+?)存在的话，回复效果提升至(1\/2)/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), heal: frac(m[2]) }));
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u524A\u5F31\u5BF9\u65B9(${STAT_LIST})(\\d+)\u7EA7\uFF1B\u6709(\\S+?)\u5B58\u5728\u7684\u8BDD\uFF0C\u989D\u5916\u589E\u52A0(\\d+)%\u6982\u7387`), (m) => {
      e.stages.push({ self: false, stats: statsOf2(m[2]), delta: -num2(m[3]), chance: num2(m[1]), condChance: { cond: mk(m[4]), chance: num2(m[1]) + num2(m[5]) } });
    });
    r.take(/有(\S+?)存在的话，增加(\d+)次攻击/, (m) => void (e.hitsIf = { cond: mk(m[1]), add: num2(m[2]) }));
    r.take(/消耗(\d+)倍的技能PP提升\S+的效果/, (m) => void (e.ppCost = num2(m[1])));
    r.take(/使用(\S+?)后技能威力可提升至(\d+)/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), set: num2(m[2]) }));
    r.take(/使用技能(\S+?)后，本技能威力提升(\d+)%/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), mult: 1 + num2(m[2]) / 100 }));
    r.take(/命中则令对方获得(陶醉)标记，对方双攻基础数值减少(\d+)%；若对方已陶醉则(?:(\d+)%概率(提升自身双防等级1级|令对方混乱)|将伤害值的(\d+)%转化来回复自己)/, (m) => {
      e.markFoe = { name: m[1], downPct: num2(m[2]) };
      const c = { foeMark: m[1] };
      if (m[5]) (e.powerIf ??= []).push({ cond: c, drain: num2(m[5]) / 100 });
      else if (/混乱/.test(m[4])) e.statuses.push({ name: "\u6DF7\u4E71", chance: num2(m[3]), cond: c });
      else e.stages.push({ self: true, stats: ["def", "sdef"], delta: 1, chance: num2(m[3]), cond: c });
    });
    r.take(/先复制对方上回合使用的技能的威力的一半，加上本技能的威力/, () => void (e.copyPower = true));
    r.take(/削弱对方全体(光明)与(暗黑)技能威力的(\d+)%，效果持续(\d+)回合/, (m) => {
      for (const a of [m[1], m[2]]) e.timed.push({ who: "foe", kind: "power", turns: num2(m[4]), mult: 1 - num2(m[3]) / 100, attr: ATTRS[a] });
    });
    r.take(/使用后，下次出手攻击对方时，吸取(\d+)%体力值用来回复自己/, (m) => void e.timed.push({ who: "self", kind: "drain", turns: 99, f: num2(m[1]) / 100, once: true }));
    r.take(/若自己速度快过对方，则无视对方本回合攻击/, () => {
      e.protect = true;
      e.protectIfFirst = true;
    });
    r.take(/(?:使用后)?受到伤害则减半，并额外提升自己伤害能力(\d+)%，持续(\d+)回合/, (m) => {
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[2]), phys: 0.5, spec: 0.5 });
      e.timed.push({ who: "self", kind: "power", turns: num2(m[2]), mult: 1 + num2(m[1]) / 100 });
    });
    r.take(/使用后受到伤害则减半，每次受到伤害都有(\d+)%概率削弱对方全属性(\d+)级，持续(\d+)回合/, (m) => {
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[3]), phys: 0.5, spec: 0.5 });
      e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[3]), chance: num2(m[1]), stats: ALL_STATS, delta: -num2(m[2]) });
    });
    r.take(/使用后(\d+)回合内，?自己受到特殊攻击时伤害减半；若受到普通攻击，则将受到伤害的(\d+\/\d+)返击对方/, (m) => {
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), spec: 0.5 });
      e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]) });
    });
    r.take(/使用后(\d+)回合内受到普通或特殊攻击，都有(\d+)%概率令对方(烧伤)或者(睡眠)/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[1]), chance: num2(m[2]), status: statusOf(m[3]), statusAlt: statusOf(m[4]) }));
    r.take(/扣除对方单体(\d+)点体力值，自己回复(\d+)点体力值/, (m) => {
      e.dmg = { kind: "flat", n: num2(m[1]) };
      e.dmgHeals = num2(m[2]);
    });
    r.take(/若对方(烧伤)，自己回复(\d+\/\d+)体力值/, (m) => void (e.healAfter = { f: frac(m[2]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
    r.take(/提升我方全体伤害(\d+)%，闪避等级(\d+)级/, (m) => {
      e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num2(m[1]) / 100 });
      e.stages.push({ self: true, stats: ["eva"], delta: num2(m[2]), chance: 100 });
    });
    r.take(new RegExp(`\u4F7F\u7528\u540E\uFF0C\u6BCF\u56DE\u5408\u63D0\u5347\u81EA\u5DF1(?:\u7684)?(${STAT_LIST})(?:\u7684)?\u7B49\u7EA7\u5404?(\\d+)\u7EA7(?:\uFF0C\u5E76\u63D0\u5347\u81EA\u5DF1\u4F24\u5BB3\u62B5\u6297\u80FD\u529B(\\d+)%)?\uFF0C\u6301\u7EED(\\d+)\u56DE\u5408`), (m) => {
      e.timed.push({ who: "self", kind: "stagesEachTurn", turns: num2(m[4]), stats: statsOf2(m[1]), delta: num2(m[2]), chance: 100 });
      if (m[3]) e.timed.push({ who: "self", kind: "screen", turns: num2(m[4]), phys: 1 - num2(m[3]) / 100, spec: 1 - num2(m[3]) / 100 });
    });
    r.take(/(?:使用后接下来(\d+)回合，)?(?:自己|我方全体)?(光明|飞行)系技能威力提升(\d+)%，伤害抵抗(?:能力)?提升(\d+)%(?:，持续(\d+)回合)?/, (m) => {
      const turns = num2(m[1] || m[5], turnsOf(r.d, 3));
      e.timed.push({ who: "self", kind: "power", turns, mult: 1 + num2(m[3]) / 100, attr: ATTRS[m[2]] });
      e.timed.push({ who: "self", kind: "screen", turns, phys: 1 - num2(m[4]) / 100, spec: 1 - num2(m[4]) / 100 });
    });
    r.take(/(\d+)%概率作用给自己，(\d+)%概率作用给对方/, (m) => void (e.fate = num2(m[1])));
    r.take(/每回合恢复(\d+)体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/我方剩余体力值越少，对方剩余体力值越多，威力越大/, () => void (e.powerByHp = "low"));
    r.take(/对方剩余体力值越多，?威力越大/, () => void (e.powerByHp = "foeHigh"));
    r.take(/(?:本回合不行动|本回合停止行动|本回合休息，提升暴击率)，下回合(先发)?(?:自动)?攻击对方(?:单体)?/, (m) => {
      e.charge = true;
      if (m[1]) e.chargeFirst = true;
      if (/暴击/.test(m[0])) e.highCrit = true;
    });
    r.take(/下回合攻击对方(\d+)~(\d+)次/, (m) => {
      e.charge = true;
      e.hits = [num2(m[1]), num2(m[2])];
    });
    r.take(/给(?:自己的伤害|每次攻击)附加(\d+)点伤害值，持续(\d+)(?:回合|次攻击|次)/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/使用后(\d+)回合内，每回合将自己所有PP值1点转化来回复(\d+)点体力值(?:，可以叠加使用)?(?:，最多叠加\d+次)?/, (m) => void e.timed.push({ who: "self", kind: "pphp", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/若暴击，(?:则)?令对方(麻痹|害怕|混乱)/, (m) => void e.statuses.push({ name: statusOf(m[1]), chance: 100, cond: { crit: true } }));
    r.take(new RegExp(`\u82E5\u66B4\u51FB\uFF0C\u6BCF\u6B21\u66B4\u51FB\u63D0\u5347\u81EA\u8EAB(${STAT_LIST})(\\d+)\u7EA7`), (m) => void e.stages.push({ self: true, stats: statsOf2(m[1]), delta: num2(m[2]), chance: 100, cond: { crit: true } }));
    r.take(/若造成的伤害值含9或为9的倍数，则(?:将伤害值的(\d+)%转化来回复自己|必定令对方(混乱))/, (m) => {
      if (m[1]) {
        e.drain = num2(m[1]) / 100;
        e.drainCond = { nine: true };
      } else e.statuses.push({ name: statusOf(m[2]), chance: 100, cond: { nine: true } });
    });
    r.take(/若自己处于(束缚)状态，则将造成伤害的(1\/2)转化来回复自己/, (m) => {
      e.drain = frac(m[2]);
      e.drainCond = { selfStatus: [statusOf(m[1])] };
    });
    r.take(/若对方处于(烧伤)状态，则威力提升为(\d+(?:\.\d+)?)倍/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[1]) }, mult: num2(m[2]) }));
    r.take(/(?:使用后)?自身战斗力瞬间破表，额外增强自己双攻、双防和速度基础数值的(\d+)%/, (m) => void (e.baseUp = { pct: num2(m[1]), max: 1 }));
    r.take(/无视对方本回合攻击|无视当回合对方的伤害|闪避对方的攻击/, () => void (e.protect = true));
    r.take(/本回合若被对方打败，则立即恢复到生命最大值/, () => void (e.endure = "revive"));
    r.take(/使用后防御与攻击、特防与特攻属性等级交换/, () => void (e.swapOwnStages = true));
    r.take(/一场战斗使用次数越高，成功率越高/, () => void (e.grow = true));
    r.take(/扣除对方剩余体力值的(1\/2)来转化回复自己的体力值/, (m) => {
      e.dmg = { kind: "hpFrac", f: frac(m[1]) };
      e.dmgHeals = "all";
    });
    r.take(/(\d+)\/(\d+)概率令对方(害怕|麻痹|混乱)/, (m) => void e.statuses.push({ name: statusOf(m[3]), chance: num2(m[1]) * 100 / num2(m[2]) }));
    r.take(/(?:并)?解除自己(冰冻|烧伤)状态/, (m) => void (e.unstatus = statusOf(m[1])));
    r.take(/给对方单体造成(\d+)伤害值；微弱伤害减半，克制伤害变为原来的(\d+(?:\.\d+)?)倍/, (m) => {
      e.dmg = { kind: "flat", n: num2(m[1]) };
      e.dmgByType = true;
    });
    r.take(/持续(\d+)回合进入隐身状态，(\d+)%概率无视对方的特殊攻击，自己攻击等级下降(\d+)级，但受到普通攻击的伤害会加倍/, (m) => {
      e.timed.push({ who: "self", kind: "dodge", turns: num2(m[1]), spec: num2(m[2]) });
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), phys: 2 });
      e.stages.push({ self: true, stats: ["atk"], delta: -num2(m[3]), chance: 100 });
    });
    r.take(/替换亚比则会立即解除隐身状态/, () => void 0);
    r.take(/使用后(\d+)回合内，若受到伤害，则将伤害的(1\/3)返还给对方，并有(1\/3)的概率令对方(害怕)/, (m) => {
      e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]), spec: frac(m[2]) });
      e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[1]), chance: frac(m[3]) * 100, status: statusOf(m[4]) });
    });
    r.take(/令自身束缚(\d+)回合，\d+回合内每回合回复自身(\d+)点体力值/, (m) => {
      e.statuses.push({ name: "\u675F\u7F1A", chance: 100, turns: [num2(m[1]), num2(m[1])], self: true });
      e.timed.push({ who: "self", kind: "regen", turns: num2(m[1]), n: num2(m[2]) });
    });
    r.take(/若对方烧伤，则将对方烧伤的体力值用来回复自己/, () => void e.timed.push({ who: "foe", kind: "leech", turns: 99, f: 1 / 8, while: "\u70E7\u4F24" }));
    r.take(/若对方害怕则吸取对方体力最大值的(1\/10)用来回复自己体力值/, () => void 0);
    r.take(/发动时此技能威力提升至(\d+)倍，但是命中很低/, (m) => {
      (e.boost ??= []).push({ chance: 100, mult: num2(m[1]) });
      e.acc = 30;
    });
    r.take(/但是只有一半的命中率/, () => void (e.acc = 50));
    r.take(/自己速度比对方(慢|快)，则威力加倍，否则减半/, (m) => {
      const slow = m[1] === "\u6162";
      (e.powerIf ??= []).push({ cond: slow ? { slower: true } : { faster: true }, mult: 2 }, { cond: slow ? { faster: true } : { slower: true }, mult: 0.5 });
    });
    r.take(/若对方体力值比自己多，则发动2倍威力；若对方体力值比自己少，则发动1\/2倍威力/, () => {
      (e.powerIf ??= []).push({ cond: { foeHpMore: true }, mult: 2 }, { cond: { foeHpLess: true }, mult: 0.5 });
    });
    r.take(/自己体力值少于一半时，威力加倍；自己体力值小于1\/4时，威力提升至4倍/, () => {
      (e.powerIf ??= []).push({ cond: { selfHpBelow: 0.25 }, mult: 4 }, { cond: { selfHpBelow: 0.5 }, mult: 2 });
    });
    r.take(/(\d+)%概率秒杀对方，若对方处于(烧伤)状态，则秒杀概率翻倍/, (m) => {
      e.ohko = num2(m[1]);
      e.ohkoDoubleIf = { foeStatus: statusOf(m[2]) };
    });
    r.take(/若对方处于(烧伤|冰冻|麻痹|睡眠)状态，有(\d+)%概率秒杀对方/, (m) => void (e.ohkoIf = { chance: num2(m[2]), cond: { foeStatus: statusOf(m[1]) } }));
    r.take(/命中后(\d+)%概率秒杀对方且停止行动1回合|(\d+)%概率秒杀对方，秒杀后停止行动1回合/, (m) => {
      e.ohko = num2(m[1] ?? m[2]);
      e.recharge = true;
    });
    r.take(/每次攻击都有(\d+)%的?概率直接秒杀对方/, (m) => void (e.ohko = num2(m[1])));
    r.take(/秒杀体力值少于(\d+)点的对方/, (m) => void (e.ohkoIf = { chance: 100, hpBelow: num2(m[1]) }));
    r.take(/回复自己全部体力值和技能PP/, () => {
      e.healFull = true;
      e.ppSelf = 99;
    });
    r.take(/消耗自己所有PP值，完全回复自己体力值并清除所有不良状态和被削弱的属性能力等级/, () => {
      e.ppSelfAll = true;
      e.healFull = true;
      e.cure = true;
      e.restoreOwn = { chance: 100 };
    });
    r.take(/恢复自己所有被削弱的属性能力等级并清除自己的不良状态，且(\d+)~(\d+)回合内不受不良状态影响/, (m) => {
      e.restoreOwn = { chance: 100 };
      e.cure = true;
      e.timed.push({ who: "self", kind: "nostatus", turns: num2(m[2]) });
    });
    r.take(/若自己受到对方攻击，则令对方(混乱)和(中毒)/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 1, chance: 100, status: statusOf(m[1]), statusAlt: statusOf(m[2]), bothStatus: true }));
    r.take(/自己(?:速度|速度值)与对方(?:速度|速度值)比值越(大|小)，威力越(大|小)/, (m) => void (e.powerBySpeed = m[1] === "\u5927" === (m[2] === "\u5927") ? "fast" : "slow"));
    r.take(/(?:(\d+)%概率)?复制对方(?:提升的)?(?:属性)?能力等级(?:效果)?(?:给自己)?/, (m) => void (e.copyFoeUps = { chance: pct(m[1]) }));
    r.take(/复制对方的能力等级/, () => {
      e.copyFoeUps = { chance: 100 };
      e.copyAll = true;
    });
    r.take(/(\d+)%概率夺取对方提升的属性能力等级加给自己，之后必定清除对方提升的属性能力等级/, (m) => {
      e.copyFoeUps = { chance: num2(m[1]) };
      e.clearFoeUps = { chance: 100 };
    });
    r.take(/回合结束时为自己回复(\d+)(?:点)?体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: 1, n: num2(m[1]) }));
    r.take(/一场战斗使用(?:多次|越多)，?则?(?:闪避)?成功率(?:会下降|逐渐降低)/, () => void (e.fade = true));
    r.take(new RegExp(`\u6781\u5927\u6982\u7387\u80FD\u591F\u6210\u529F\u63D0\u5347\u81EA\u5DF1(${STAT_LIST})\u7684\u7B49\u7EA7\u5404(\\d+)\u7EA7\uFF0C\u5931\u8D25\u5219\u6263\u9664\u81EA\u5DF1(\\d+)\u70B9\u4F53\u529B\u503C`), (m) => {
      e.stages.push({ self: true, stats: statsOf2(m[1]), delta: num2(m[2]), chance: 90 });
      e.failCost = num2(m[3]);
    });
    r.take(/(?:先发；)?自己若受到伤害，则对方所有PP减少(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[2]), chance: 100, n: num2(m[1]) }));
    r.take(/若自己受到(?:伤害|攻击)，(?:有(\d+)%概率)?(?:则)?扣除对方(?:全部技能PP|所有PP)(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[3]), chance: pct(m[1]), n: num2(m[2]) }));
    r.take(/每回合扣除自己体力值(\d+)点，随机削弱对方1种属性的等级(\d+)级，持续(\d+)回合/, (m) => {
      e.timed.push({ who: "self", kind: "dot", turns: num2(m[3]), n: num2(m[1]) });
      e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: num2(m[3]), stats: ALL_STATS, delta: -num2(m[2]), chance: 100, pick: 1 });
    });
    r.take(/清除双方所有的?(?:属性)?能力等级/, () => {
      e.resetFoe = true;
      e.resetSelf = true;
    });
    r.take(/将自己不良状态转移给对方/, () => void (e.passStatus = true));
    r.take(/若自己剩余体力值与满体力的比值小于对方，有(\d+)%概率按比例调换双方体力/, (m) => void (e.swapHpRatio = num2(m[1])));
    r.take(/若对方处于(烧伤)状态，每回合削弱对方(攻击)等级(\d+)级，持续削弱回合数=烧伤回合数/, (m) => void e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: 99, stats: statsOf2(m[2]), delta: -num2(m[3]), chance: 100, while: statusOf(m[1]) }));
    r.take(/若当回合抵挡对方伤害，并将对方造成伤害值的(1\/2)反击对方|若先发，当回合抵挡对方伤害，并将对方造成伤害值的(1\/2)反击对方/, (m) => void (e.shield = { take: 0, reflect: frac(m[1] ?? m[2]), ifFirst: true }));
    r.take(/(?:本回合)?(?:命中则)?(?:本回合)?(?:自己)?(?:承受|受到)伤害减半/, () => void (e.shield = { take: 0.5, reflect: 0 }));
    r.take(/此回合自己免受(普通攻击与特殊攻击|特殊攻击|普通攻击)造成的伤害/, (m) => void (e.shield = { take: 0, reflect: 0, ...m[1] === "\u7279\u6B8A\u653B\u51FB" ? { kind: "spec" } : m[1] === "\u666E\u901A\u653B\u51FB" ? { kind: "phys" } : {} }));
    r.take(/若本回合受到攻击则令对方攻击无效/, () => void (e.shield = { take: 0, reflect: 0 }));
    r.take(/下回合(?:先发)?(?:自动)?攻击对方(?:单体)?(?![\d~])/, (m) => {
      e.charge = true;
      if (/先发/.test(m[0])) e.chargeFirst = true;
    });
    r.take(/使用后进入装弹状态，停止行动1回合，然后发射威力巨大的子弹攻击对方/, () => void (e.charge = true));
    r.take(/令冰冻中的对方所有技能PP每回合减少(\d+)点，持续到冰冻效果解除/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num2(m[1]), while: "\u51B0\u51BB" }));
    r.take(/束缚时每回合所有技能PP值-(\d+)/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num2(m[1]), while: "\u675F\u7F1A" }));
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u524A\u5F31\u5BF9\u65B9(?:\u5355\u4F53)?(${STAT_LIST})(?:\u7684)?\u7B49\u7EA7\u5404?(\\d+)\u7EA7\uFF0C(?:\u82E5)?\u5BF9\u65B9(\u51B0\u51BB|\u70E7\u4F24)(?:\u65F6)?\uFF0C?\u524A\u5F31\u6982\u7387(?:\u4F1A)?\u589E\u52A0\u81F3(\\d+)%`), (m) => {
      e.stages.push({ self: false, stats: statsOf2(m[2]), delta: -num2(m[3]), chance: num2(m[1]), condChance: { cond: { foeStatus: statusOf(m[4]) }, chance: num2(m[5]) } });
    });
    r.take(new RegExp(`\u5BF9\u65B9(\u9EBB\u75F9|\u51B0\u51BB|\u70E7\u4F24|\u7761\u7720|\u6DF7\u4E71)\u65F6\uFF0C(\\d+)%\u6982\u7387\u524A\u5F31\u5BF9\u65B9(${STAT_LIST})(\\d+)\u7EA7`), (m) => {
      e.stages.push({ self: false, stats: statsOf2(m[3]), delta: -num2(m[4]), chance: num2(m[2]), cond: { foeStatus: statusOf(m[1]) } });
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u524A\u5F31\u5BF9\u65B9(?:\u5355\u4F53)?(${STAT_LIST})(?:\u7B49\u7EA7)?(\\d+)\u7EA7\uFF1B?\uFF0C?\u82E5(\u66B4\u51FB|\u81EA\u5DF1\u901F\u5EA6\u5FEB\u8FC7\u5BF9\u65B9)(?:\uFF0C)?(?:\u547D\u4E2D)?\u5219?(\\d+)%(?:\u6982\u7387)?\u524A\u5F31\u5BF9\u65B9(?:\u5355\u4F53)?(?:${STAT_LIST})(?:\u7B49\u7EA7)?\\d+\u7EA7`), (m) => {
      const c = m[4] === "\u66B4\u51FB" ? { crit: true } : { faster: true };
      e.stages.push({ self: false, stats: statsOf2(m[2]), delta: -num2(m[3]), chance: num2(m[1]), condChance: { cond: c, chance: num2(m[5]) } });
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(${ST})\uFF0C\u82E5\u66B4\u51FB\u5219(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(?:${ST})`), (m) => {
      e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]), doubleIf: { crit: true } });
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(${ST})\u5E76\u675F\u7F1A\u5BF9\u65B9(\\d+)~(\\d+)\u56DE\u5408\uFF1B\u82E5\u5BF9\u65B9\u5904\u4E8E(\u51B0\u51BB)\u72B6\u6001\uFF0C\u5219\u6982\u7387\u7FFB\u500D`), (m) => {
      e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]), doubleIf: { foeStatus: statusOf(m[5]) } });
      e.statuses.push({ name: "\u675F\u7F1A", chance: num2(m[1]), turns: [num2(m[3]), num2(m[4])], doubleIf: { foeStatus: statusOf(m[5]) } });
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9\u5355\u4F53(\u51B0\u51BB)\uFF0C\u9020\u6210\u51B0\u51BB\u65F6\u81EA\u5DF1\u56DE\u590D(\\d+\\/\\d+)\u4F53\u529B\u503C`), (m) => {
      e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]) });
      e.healAfter = { f: frac(m[3]), chance: 100, cond: { landed: true } };
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9\u7761\u7720\uFF0C\u82E5\u6210\u529F\u4EE4\u5BF9\u65B9\u7761\u7720\u5219\u63D0\u5347\u81EA\u8EAB(${STAT_LIST})\u7B49\u7EA7\u5404(\\d+)\u7EA7`), (m) => {
      e.statuses.push({ name: "\u7761\u7720", chance: num2(m[1]) });
      e.stages.push({ self: true, stats: statsOf2(m[2]), delta: num2(m[3]), chance: 100, cond: { landed: true } });
    });
    r.take(new RegExp(`\u82E5\u5BF9\u65B9\u5904\u4E8E(?:\u4E0D\u826F|\u5F02\u5E38)\u72B6\u6001\uFF0C\u6709?(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(${ST})`), (m) => void e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]), cond: { foeStatus: "any" } }));
    r.take(new RegExp(`\u82E5\u5BF9\u65B9(?:\u5DF2)?(\u9EBB\u75F9|\u675F\u7F1A)\uFF0C(?:\u5219)?\u989D\u5916\u63D0\u5347\u81EA\u5DF1(${STAT_LIST})\u7B49\u7EA7(\\d+)\u7EA7`), (m) => void e.stages.push({ self: true, stats: statsOf2(m[2]), delta: num2(m[3]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
    r.take(new RegExp(`\u5982\u679C\u5BF9\u65B9\u5904\u4E8E(\u6DF7\u4E71|\u70E7\u4F24)\u72B6\u6001\uFF0C\u5219\u524A\u5F31\u5BF9\u65B9(${STAT_LIST})\u7684\u7B49\u7EA7\u5404(\\d+)\u7EA7`), (m) => void e.stages.push({ self: false, stats: statsOf2(m[2]), delta: -num2(m[3]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
    r.take(/(?:若|如果)对方处于(烧伤)状态，则扣除对方所有技能(?:的)?PP(?:值)?(\d+)点/, (m) => void (e.ppFoe = { n: num2(m[2]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
    r.take(/若对方(?:已)?(麻痹)则附加(\d+)点固定伤害/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[1]) }, add: num2(m[2]) }));
    r.take(/若对方处于(睡眠)状态，(\d+)%概率发动(\d+(?:\.\d+)?)倍威力/, (m) => void (e.boost ??= []).push({ chance: num2(m[2]), mult: num2(m[3]), cond: { foeStatus: statusOf(m[1]) } }));
    r.take(/如果对方处于(混乱)状态，则发动(\d+(?:\.\d+)?)倍伤害/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[1]) }, mult: num2(m[2]) }));
    r.take(/若对方此回合不使用伤害型技能，则可发动(\d+(?:\.\d+)?)倍威力/, (m) => void (e.powerIf ??= []).push({ cond: { foeNoDamage: true }, mult: num2(m[1]) }));
    r.take(/若本回合受到伤害则必定令对方(混乱)/, (m) => void e.statuses.push({ name: statusOf(m[1]), chance: 100, cond: { hurt: true } }));
    r.take(new RegExp(`\u82E5\u672C\u56DE\u5408\u672A\u53D7\u5230\u4F24\u5BB3\uFF0C\u5219\u964D\u4F4E\u5BF9\u65B9\u5355\u4F53(${STAT_LIST})\u5404(\\d+)\u7EA7`), (m) => void e.stages.push({ self: false, stats: statsOf2(m[1]), delta: -num2(m[2]), chance: 100, cond: { hurt: false } }));
    r.take(/若本回合未受到伤害，则回合结束时扣除对方(\d+)点体力值/, (m) => void (e.delayed = { who: "foe", turns: 0, kind: "flat", n: num2(m[1]) }));
    r.take(/若对方处于(冰冻|混乱|麻痹)(?:状态)?，?(?:则)?可多攻击(\d+)次/, (m) => void (e.hitsIf = { cond: { foeStatus: statusOf(m[1]) }, add: num2(m[2]) }));
    r.take(/若对方(束缚)，则必定攻击(\d+)次/, (m) => void (e.hitsIf = { cond: { foeStatus: statusOf(m[1]) }, set: num2(m[2]) }));
    r.take(/若暴击，每次暴击均回复自身体力最大值的(\d+\/\d+)/, (m) => void (e.critHeal = frac(m[1])));
    r.take(/自己剩余体力值越少回复体力值越多/, () => void (e.healLost = 0.5));
    r.take(/并束缚对方，束缚回合数等于黏住的次数/, () => {
      e.statuses.push({ name: "\u675F\u7F1A", chance: 100 });
      e.bindHits = true;
    });
    r.take(/随机召唤1~10块数码幻镜攻击对方单体；召唤幻镜数量为3时，令对方害怕；召唤幻镜数量为6时，令对方混乱；召唤幻镜数量为9时，令对方麻痹/, () => {
      e.hits = [1, 10];
      e.hitStatus = { 3: "\u5BB3\u6015", 6: "\u6DF7\u4E71", 9: "\u9EBB\u75F9" };
    });
    r.take(/向敌方扔出(\d+)~(\d+)个气球爆弹|射出(\d+)支毒箭攻击对方单体/, (m) => void (e.hits = m[3] ? [num2(m[3]), num2(m[3])] : [num2(m[1]), num2(m[2])]));
    r.take(/每支毒箭有/, () => void (e.perHit = true));
    r.take(/回合结束时回复对方体力值(\d+)点/, (m) => void (e.healFoeEnd = num2(m[1])));
    r.take(/(?:使用后)?额外增强自己双攻、双防和速度基础数值的?(\d+)%，1场战斗最多增强(\d+)次/, (m) => void (e.baseUp = { pct: num2(m[1]), max: num2(m[2]) }));
    r.take(/令对方单体基础(攻击|特攻)值减少(\d+)点/, (m) => void (e.baseDown = { stat: m[1] === "\u653B\u51FB" ? "atk" : "satk", n: num2(m[2]) }));
    r.take(/(\d+)%概率无视对方(?:防御|特防)提升的等级/, (m) => void (e.ignoreUps = num2(m[1])));
    r.take(/一定概率令提升效果翻倍/, () => void (e.stageDouble = 30));
    r.take(/(\d+)%概率令自己或对方下回合停止行动1回合，若对方麻痹则自己下回合不会停止行动(?:，若对方害怕则对方下回合不会停止行动)?/, (m) => void (e.eitherStops = num2(m[1])));
    r.take(/每次攻击威力增加(\d+)/, (m) => void (e.perHitPower = num2(m[1])));
    r.take(/(?:先发；)?(?:连续攻击对方(?:单体)?(\d+)回合)，每回合威力增加(\d+)/, (m) => void (e.rollout = { turns: num2(m[1]), add: num2(m[2]) }));
    r.take(/每回合末均有(\d+)%概率令自己(混乱)/, (m) => void e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]), self: true }));
    r.take(/连续(\d+)~(\d+)回合攻击对方(?:单体)?(?!随机)/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[2])], after: "none" }));
    r.take(/连续(?:攻击对方(?:单体)?(\d+)回合|(\d+)回合攻击对方(?:单体)?)，(?:威力十分巨大，)?之后自己(?:休息|停止行动)1回合/, (m) => void (e.lock = { turns: [num2(m[1] ?? m[2]), num2(m[1] ?? m[2])], after: "rest" }));
    r.take(/连续攻击对方单体(\d+)回合，(?=每次攻击)/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[1])], after: "none" }));
    r.take(/(\d+)回合自己停止行动，(\d+)回合后提升自己全属性(\d+)级/, (m) => {
      e.recharge = true;
      e.rechargeTurns = num2(m[1]);
      e.delayed = { who: "self", turns: num2(m[2]), kind: "stages", stats: ALL_STATS, delta: num2(m[3]) };
    });
    r.take(/(先回复自己所有体力值，)?(\d+)回合自己停止行动，(\d+)回合后满状态回复并令对方害怕/, (m) => {
      if (m[1]) e.healFull = true;
      e.recharge = true;
      e.rechargeTurns = num2(m[2]);
      e.delayed = { who: "self", turns: num2(m[3]), kind: "rebirth" };
    });
    r.take(/(\d+)%概率(?:会)?使自己下回合处于异常状态/, (m) => void (e.delayed = { who: "self", turns: 0, kind: "badStatus", chance: num2(m[1]) }));
    r.take(new RegExp(`(?:\u53D7\u5230\u4F24\u5BB3|\u6BCF\u56DE\u5408\u53D7\u5230\u4F24\u5BB3|\u6BCF\u6B21\u53D7\u5230\u4F24\u5BB3)(?:\u65F6|\u5219)?\uFF0C?(?:\u90FD\u6709)?(?:(\\d+)%\u6982\u7387)?(\u63D0\u5347|\u524A\u5F31)(\u81EA\u5DF1|\u81EA\u8EAB|\u5BF9\u65B9)?(?:\u7684)?(${STAT_LIST})(?:\u7684)?(?:\u7B49\u7EA7)?(?:\u5404)?(\\d+)\u7EA7(?:\uFF0C\u6301\u7EED(\\d+)\u56DE\u5408)?`), (m) => {
      const self = m[3] !== "\u5BF9\u65B9";
      e.timed.push({ who: "self", kind: "onhurt", turns: m[6] ? num2(m[6]) : turnsOf(r.d, 5), chance: pct(m[1]), stats: statsOf2(m[4]), delta: (m[2] === "\u63D0\u5347" ? 1 : -1) * num2(m[5]), selfStage: self });
    });
    r.take(new RegExp(`(?:(\\d+)\u56DE\u5408\u5185)?\u53D7\u5230\u4F24\u5BB3(?:\u65F6)?\uFF0C(?:(\\d+)%\u6982\u7387)?(?:\u63D0\u5347\u81EA\u5DF1)?(${STAT_LIST})(?:\u548C(${STAT_LIST}))?\u7684?\u7B49\u7EA7(?:\u5404)?\u63D0\u5347(\\d+)\u7EA7(?:\uFF0C\u6301\u7EED(\\d+)\u56DE\u5408)?`), (m) => {
      e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[6] || m[1], 5), chance: pct(m[2]), stats: statsOf2(m[3] + (m[4] ? "\u548C" + m[4] : "")), delta: num2(m[5]), selfStage: true });
    });
    r.take(new RegExp(`(?:\u53D7\u5230\u4F24\u5BB3|\u6BCF\u6B21\u53D7\u5230\u4F24\u5BB3)(?:\u65F6)?(?:\u90FD\u6709)?(\\d+)%\u6982\u7387(\u63D0\u5347\u81EA\u5DF1)(${STAT_LIST})\u7B49\u7EA7(\\d+)\u7EA7\uFF0C\u6301\u7EED(\\d+)\u56DE\u5408`), (m) => {
      e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[5]), chance: num2(m[1]), stats: statsOf2(m[3]), delta: num2(m[4]), selfStage: true });
    });
    r.take(new RegExp(`(?:\u4F7F\u7528\u540E(\\d+)\u56DE\u5408\u5185\uFF0C)?(?:\u6BCF\u6B21)?\u53D7\u5230\u4F24\u5BB3(?:\u65F6|\u90FD\u6709)?(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(?:\u8FDB\u5165)?(${ST}|\u5F02\u5E38\u72B6\u6001)`), (m) => {
      const any = m[3] === "\u5F02\u5E38\u72B6\u6001";
      e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[1], turnsOf(r.d, 5)), chance: num2(m[2]), status: any ? "\u9EBB\u75F9" : statusOf(m[3]), ...any ? { statusAlt: "\u7761\u7720" } : {} });
    });
    r.take(/使用后(\d+)回合内每次受到攻击则返还(\d+)点伤害给对方/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/使用后(\d+)回合内，若受到伤害，则将伤害的(1\/3)返还给对方/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]), spec: frac(m[2]) }));
    r.take(/使用后(\d+)回合内，将受到伤害的(\d+\/\d+)返还给对方，自身承受(\d+\/\d+)/, (m) => {
      e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]), spec: frac(m[2]) });
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), phys: frac(m[3]), spec: frac(m[3]) });
    });
    r.take(/使用后接下来(\d+)回合，反击受到伤害的(\d+\/\d+)给对方，若自己被击败则无法反击/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]), spec: frac(m[2]) }));
    r.take(/(?:额外)?提升(?:自己|自身)?(?:的)?(?:抵抗伤害能力|伤害抵抗能力|伤害抵抗)(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 3), phys: 1 - num2(m[1]) / 100, spec: 1 - num2(m[1]) / 100 }));
    r.take(/(?:额外)?提升(?:自己|我方全体)(?:的)?(?:伤害值的|伤害能力|伤害)(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num2(m[1]) / 100 }));
    r.take(/提升(水)系、(火)系技能威力(\d+)%/, (m) => {
      for (const a of [m[1], m[2]]) e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num2(m[3]) / 100, attr: ATTRS[a] });
    });
    r.take(/(?:使用后)?(?:接下来的?(\d+)回合，)?给?(?:技能糖果炮弹的)?(?:下个回合的)?每次攻击附加(\d+)点伤害(?:值)?(?:和(\d+)%概率(害怕))?(?:，持续(\d+)回合)?/, (m) => {
      const turns = m[1] ? num2(m[1]) : m[5] ? num2(m[5]) : 2;
      e.timed.push({ who: "self", kind: "extra", turns, n: num2(m[2]) });
      if (m[3]) e.timed.push({ who: "self", kind: "onhit", turns, chance: num2(m[3]), n: 1 });
    });
    r.take(/每次暴击附加(\d+)点伤害值/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: 1, n: num2(m[1]), chance: -1 }));
    r.take(/接下来(\d+)回合，每回合攻击对方时均有(\d+)%概率令对方(麻痹)/, (m) => void e.timed.push({ who: "self", kind: "onhit", turns: num2(m[1]), chance: num2(m[2]), n: 3, status: statusOf(m[3]) }));
    r.take(/使用后(\d+)回合内，每回合有(\d+)%概率令对方单体(害怕)/, (m) => void e.timed.push({ who: "foe", kind: "plague", turns: num2(m[1]), chance: num2(m[2]), status: statusOf(m[3]) }));
    r.take(/使用后每次攻击有(\d+)%概率令对方害怕，并将伤害值的(\d+)%转化来回复自己，每回合结束时扣除自己(\d+)点体力值，持续(\d+)回合/, (m) => {
      const turns = num2(m[4]);
      e.timed.push({ who: "self", kind: "onhit", turns, chance: num2(m[1]), n: 1 });
      e.timed.push({ who: "self", kind: "drain", turns, f: num2(m[2]) / 100 });
      e.timed.push({ who: "self", kind: "dot", turns, n: num2(m[3]) });
    });
    r.take(new RegExp(`\u4F7F\u7528\u540E(\\d+)\u56DE\u5408\u5185\uFF0C\u63D0\u5347\u81EA\u5DF1(${STAT_LIST})\u7B49\u7EA7\u5404(\\d+)\u7EA7\uFF0C\u4F7F\u7528\u4EFB\u4F55\u6280\u80FD\u5FC5\u5B9A\u547D\u4E2D\uFF0C\u6BCF\u56DE\u5408\u672B\u6263\u9664\u81EA\u5DF1\u4F53\u529B\u503C(\\d+)\u70B9`), (m) => {
      const turns = num2(m[1]);
      e.stages.push({ self: true, stats: statsOf2(m[2]), delta: num2(m[3]), chance: 100 });
      e.timed.push({ who: "self", kind: "sure", turns });
      e.timed.push({ who: "self", kind: "dot", turns, n: num2(m[4]) });
    });
    r.take(new RegExp(`\u4F7F\u7528\u540E\uFF0C\u6BCF\u56DE\u5408\u63D0\u5347\u81EA\u5DF1(?:\u7684)?(${STAT_LIST})(?:\u7684)?\u7B49\u7EA7\u5404?(\\d+)\u7EA7(?:\uFF0C\u5E76\u63D0\u5347\u81EA\u5DF1\u4F24\u5BB3\u62B5\u6297\u80FD\u529B(\\d+)%)?\uFF0C\u6301\u7EED(\\d+)\u56DE\u5408`), (m) => {
      e.timed.push({ who: "self", kind: "stagesEachTurn", turns: num2(m[4]), stats: statsOf2(m[1]), delta: num2(m[2]), chance: 100 });
      if (m[3]) e.timed.push({ who: "self", kind: "screen", turns: num2(m[4]), phys: 1 - num2(m[3]) / 100, spec: 1 - num2(m[3]) / 100 });
    });
    r.take(new RegExp(`\u4E14\u5BF9\u65B9(\u675F\u7F1A)\u65F6\uFF0C\u6BCF\u56DE\u5408\u63D0\u5347\u81EA\u5DF1(${STAT_LIST})\u7B49\u7EA7(\\d+)\u7EA7`), (m) => void e.timed.push({ who: "self", kind: "stagesEachTurn", turns: 99, stats: statsOf2(m[2]), delta: num2(m[3]), chance: 100, whileOther: statusOf(m[1]) }));
    r.take(new RegExp(`\u4E14(\u8870\u5F31)\u65F6\u5BF9\u65B9\u6BCF\u56DE\u5408\u968F\u673A\u4E0B\u964D(\\d+)\u79CD\u5C5E\u6027`), (m) => void e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: 99, stats: ALL_STATS, delta: -1, chance: 100, pick: num2(m[2]), while: statusOf(m[1]) }));
    r.take(new RegExp(`(?:\u4EE4\u5BF9\u65B9(?:\u5355\u4F53)?)?(\\d+)~(\\d+)\u56DE\u5408(${ST})`), (m) => void e.statuses.push({ name: statusOf(m[3]), chance: 100, turns: [num2(m[1]), num2(m[2])] }));
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u675F\u7F1A\u5BF9\u65B9(?:\u5355\u4F53)?(?:(\\d+)~(\\d+)\u56DE\u5408)?`), (m) => void e.statuses.push({ name: "\u675F\u7F1A", chance: num2(m[1]), ...m[2] ? { turns: [num2(m[2]), num2(m[3])] } : {} }));
    r.take(/一定概率麻痹对方单体，自己剩余体力值越少概率越高/, () => void e.statuses.push({ name: "\u9EBB\u75F9", chance: 20, byLowHp: true }));
    r.take(/自己体力值越低，睡眠成功率越高/, () => void e.statuses.push({ name: "\u7761\u7720", chance: 20, byLowHp: true }));
    r.take(new RegExp(`\u81EA\u5DF1\u635F\u5931\u4F53\u529B\u8D8A\u591A\uFF0C\u4EE4\u5BF9\u65B9(${ST})\u7684\u6982\u7387\u8D8A\u5927`), (m) => void e.statuses.push({ name: statusOf(m[1]), chance: 10, byLowHp: true }));
    r.take(/令对方单体烧伤，自己速度提升的等级越高，烧伤对方的概率越高/, () => void e.statuses.push({ name: "\u70E7\u4F24", chance: 30, bySpeed: true }));
    r.take(new RegExp(`(?:(\\d+)%\u6982\u7387|\u4E00\u5B9A\u6982\u7387)\u4EE4\u5BF9\u65B9(?:\u5355\u4F53)?(?:\u5904\u4E8E)?(${ST})(?:\u3001(${ST}))?(?:\u3001(${ST}))?(?:\u6216\u8005|\u6216)(${ST})`), (m) => {
      const names = [m[2], m[3], m[4], m[5]].filter(Boolean);
      const chance = m[1] ? num2(m[1]) : 30;
      for (const n of names) e.statuses.push({ name: n, chance: chance / names.length });
    });
    r.take(new RegExp(`(?:(\\d+)%\u6982\u7387|\u4E00\u5B9A\u6982\u7387)(?:\u4EE4|\u4F7F)?\u5BF9\u65B9(?:\u5355\u4F53|\u5168\u4F53|\u5168\u573A)?(?:\u5904\u4E8E|\u8FDB\u5165)?(?:\u4EFB\u610F1\u79CD|\u5404\u79CD)?(?:\u4E0D\u826F\u6216\u5F02\u5E38|\u4E0D\u826F|\u5F02\u5E38)\u72B6\u6001`), (m) => {
      const chance = m[1] ? num2(m[1]) : 30;
      for (const s of BAD_STATUSES) e.statuses.push({ name: s, chance: chance / BAD_STATUSES.length });
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u968F\u673A\u524A\u5F31\u5BF9\u65B9(${STAT_RE})\u3001(${STAT_RE})\u6216(${STAT_RE})\u7B49\u7EA7(\\d+)\u7EA7`), (m) => {
      e.stages.push({ self: false, stats: statsOf2(`${m[2]}\u548C${m[3]}\u548C${m[4]}`), delta: -num2(m[5]), chance: num2(m[1]), pick: [1, 1] });
    });
    r.take(/(\d+)%概率(?:削弱|降低)对方防御\+特防或攻击\+特攻(\d+)级/, (m) => {
      e.stages.push({ self: false, stats: [], delta: -num2(m[2]), chance: num2(m[1]), groups: [["def", "sdef"], ["atk", "satk"]] });
    });
    r.take(/(\d+)%概率扣光对方所有技能(?:的)?PP(?:点数)?|(\d+)%概率清除对方所有技能PP值/, (m) => void (e.ppFoe = { n: "all", chance: num2(m[1] ?? m[2]) }));
    r.take(/(\d+)%概率清除对方所有技能PP(\d+)点/, (m) => void (e.ppFoe = { n: num2(m[2]), chance: num2(m[1]) }));
    r.take(/命中后消耗自己所有技能的PP/, () => void (e.ppSelfAll = true));
    r.take(/额外消耗自身所有技能PP值(\d+)点/, (m) => void (e.ppSelf = -num2(m[1])));
    r.take(/回复自己所有PP值(\d+)点和(\d+)点体力值/, (m) => {
      e.ppSelf = num2(m[1]);
      e.healFlat = num2(m[2]);
    });
    r.take(/随机扣除对方单体的体力值和所有技能PP/, () => {
      e.dmg = { kind: "range", a: 50, b: 300 };
      e.ppFoe = { n: 2, chance: 100 };
    });
    r.take(/(?:先发；)?使用后接下来(\d+)回合，自己技能暴击概率提升至(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num2(m[1]), chance: num2(m[2]) }));
    r.take(/(\d+)回合内，?(?:自己的)?(?:属性)?(?:能力)?等级不会被削弱|(?:接下来)?(\d+)回合内?，自己的能力等级不会被削弱/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num2(m[1] ?? m[2]) }));
    r.take(/持续(\d+)回合，自己属性能力等级不能被削弱(?:；若对方提升它的属性能力等级，同样也会加给自己)?/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num2(m[1]) }));
    r.take(/(\d+)回合内，对方提升能力等级也会给自己提升/, () => void (e.copyFoeUps = { chance: 100 }));
    r.take(/(?:\d+回合内对方|两回合内对方)属性等级无法被提升或降低/, () => void e.timed.push({ who: "foe", kind: "lockStages", turns: 2 }));
    r.take(/(\d+)回合内对方属性等级无法被提升或降低/, (m) => void e.timed.push({ who: "foe", kind: "lockStages", turns: num2(m[1]) }));
    r.take(/全场属性等级无法被提升或降低，持续(\d+)回合/, (m) => void e.timed.push({ who: "both", kind: "lockStages", turns: num2(m[1]) }));
    r.take(/(?:若自己不死，则)?每回合扣除对方(\d+)点体力值/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: 99, n: num2(m[1]) }));
    r.take(/(?:若|另外，)?自身不死，每回合扣除对方所有PP值(\d+)(?:~(\d+))?点|若自己不死，每回合扣除对方所有PP值(\d+)点/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num2(m[1] ?? m[3]) }));
    r.take(/(\d+)%概率令对方(?:单体)?害怕，对方害怕的同时，会吸取(1\/2)伤害值来回复自己/, (m) => {
      e.statuses.push({ name: "\u5BB3\u6015", chance: num2(m[1]) });
      e.drain = frac(m[2]);
      e.drainCond = { landed: true };
    });
    r.take(/若对方处于(麻痹)状态，将伤害值的(\d+)%转化来回复自己体力值/, (m) => {
      e.drain = num2(m[2]) / 100;
      e.drainCond = { foeStatus: statusOf(m[1]) };
    });
    r.take(/若对方(睡眠)则将伤害值的(\d+)%转化来回复自己体力值/, (m) => {
      e.drain = num2(m[2]) / 100;
      e.drainCond = { foeStatus: statusOf(m[1]) };
    });
    r.take(/将伤害值的(\d+)%转化来回复自己；若对方已(麻痹)则将伤害值的(\d+)%转化来回复自己/, (m) => {
      e.drain = num2(m[1]) / 100;
      (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[2]) }, drain: num2(m[3]) / 100 });
    });
    r.take(/自己速度越快，给对方单体造成的伤害越多，自己回复的体力值也越多/, () => {
      e.powerBySpeed = "fast";
      e.drain = 0.5;
    });
    r.take(/(?:使用后，)?(\d+)%概率闪避(?:特殊攻击与普通攻击|普通攻击与特殊攻击)技能造成的伤害，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num2(m[2]), phys: num2(m[1]), spec: num2(m[1]) }));
    r.take(/持续(\d+)回合进入隐身状态，(\d+)%概率无视对方的特殊攻击/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num2(m[1]), spec: num2(m[2]) }));
    r.take(/使用后自己进入隐身状态，(\d+)%概率闪避对方的伤害/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: turnsOf(r.d, 3), phys: num2(m[1]), spec: num2(m[1]) }));
    r.take(/(\d+)%概率令自己停止行动1回合|(\d+)%概率自己停止行动1回合/, (m) => {
      e.recharge = true;
      e.rechargeChance = num2(m[1] ?? m[2]);
    });
    r.take(/命中后自己停止行动1回合/, () => void (e.recharge = true));
    r.take(/若击败对方，回合结束时回复自己(一半|\d+\/\d+)的?体力值/, (m) => void (e.healOnKO = frac(m[1])));
    r.take(/造成伤害等于自己等级的(\d+(?:\.\d+)?)倍/, (m) => void (e.dmg = { kind: "level", a: num2(m[1]), b: num2(m[1]) }));
    r.take(/(?:自己|自身)?(?:需要)?承受伤害值的(\d+\/\d+)/, (m) => void (e.recoil = frac(m[1])));
    r.take(/自己承受(\d+\/\d+)伤害/, (m) => void (e.recoil = frac(m[1])));
    r.take(/(?<!每回合)(?:自己|自身)(?:回复|恢复)(\d+\/\d+)(?:的)?体力值/, (m) => void (e.healAfter = { f: frac(m[1]), chance: 100 }));
    r.take(/(?<!每回合|否则)(?:自己|自身)(?:回复|恢复)(\d+)点体力值/, (m) => void (e.healFlat = num2(m[1])));
    r.take(/(\d+)%概率回复自己(\d+)点体力值/, (m) => {
      e.healFlat = num2(m[2]);
      e.healChance = num2(m[1]);
    });
    r.take(/回复最大体力值(\d+\/\d+)/, (m) => {
      e.heal = frac(m[1]);
      e.healAfter = { f: frac(m[1]), chance: 100 };
    });
    r.take(/每回合结束时扣除自己(\d+)点体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "dot", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/(?:自己|自身)(?:剩余)?体力值越多造成的伤害值越高|自己最大体力值越高则造成伤害越大/, (m) => {
      if (/剩余/.test(m[0])) e.powerByHp = "high";
    });
    r.take(/自身体力值越少威力越高/, () => void (e.powerByHp = "low"));
    r.take(/对方(攻击)和(特攻)等级越低，威力越大/, () => void 0);
    r.take(/自己双防越高，伤害越高，令对方害怕的概率越高|并有一定概率令对方害怕/, (m) => /并有/.test(m[0]) ? void e.statuses.push({ name: "\u5BB3\u6015", chance: 30 }) : void 0);
    r.take(/(?:在)?自己危在旦夕的时候，能发挥秒杀对方单体的巨大威力/, () => void (e.powerByHp = "low"));
    r.take(/1回合内攻击对方(?:单体)?(\d+)~(\d+)次，?(?:威力递增)?/, (m) => void (e.hits = [num2(m[1]), num2(m[2])]));
    r.take(/(?:自己|我方全体)?(?:“)?(光明|飞行)系(?:”)?技能威力提升(\d+)%，伤害抵抗(?:能力)?提升(\d+)%(?:，持续(\d+)回合)?/, (m) => {
      const turns = num2(m[4], turnsOf(r.d, 3));
      e.timed.push({ who: "self", kind: "power", turns, mult: 1 + num2(m[2]) / 100, attr: ATTRS[m[1]] });
      e.timed.push({ who: "self", kind: "screen", turns, phys: 1 - num2(m[3]) / 100, spec: 1 - num2(m[3]) / 100 });
    });
    r.take(/下回合使用(火|木)系技能威力(?:增加|上升)(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "power", turns: 2, mult: 1 + num2(m[2]) / 100, attr: ATTRS[m[1]] }));
    r.take(/接下来(\d+)回合提升我方全体队员抵抗普通攻击伤害的(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), phys: 1 - num2(m[2]) / 100 }));
    r.take(/提升我方全体伤害(\d+)%，闪避等级(\d+)级/, (m) => {
      e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num2(m[1]) / 100 });
      e.stages.push({ self: true, stats: ["eva"], delta: num2(m[2]), chance: 100 });
    });
    r.take(/提升全场(超暗黑)亚比闪避(\d+)~(\d+)级/, (m) => void (e.trait = { name: m[1], stats: ["eva"], delta: num2(m[2]), deltaMax: num2(m[3]) }));
    r.take(/全场具有(\S+?)特性的亚比伤害增加(\d+)%，速度增加(\d+)级/, (m) => void (e.trait = { name: m[1], power: 1 + num2(m[2]) / 100, stats: ["spd"], delta: num2(m[3]) }));
    r.take(/(?:(\d+)%概率)?令对方停止行动1回合/, (m) => void e.statuses.push({ name: "\u5BB3\u6015", chance: pct(m[1]) }));
    r.take(/使用后直到自己受到伤害，才削弱对方(攻击和特攻)的等级各(\d+)级/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 99, chance: 100, stats: statsOf2(m[1]), delta: -num2(m[2]), selfStage: false, n: 0, once: true }));
    r.take(/若自己出手速度快过对方，则恢复自己体力最大值的(\d+\/\d+)/, (m) => void (e.healAfter = { f: frac(m[1]), chance: 100, cond: { faster: true } }));
    r.take(/使用后防御与攻击，特防与特攻属性等级交换/, () => void (e.swapOwnStages = true));
    r.take(/若攻击次数为3的倍数，则提升自己(攻击和命中)等级各(\d+)级/, (m) => void e.stages.push({ self: true, stats: statsOf2(m[1]), delta: num2(m[2]), chance: 100, cond: { hitsMultipleOf: 3 } }));
    r.take(/若伤害超过(\d+)，则将对方的(防御和特防)的等级各(\d+)级转化给自己/, (m) => void (e.stealStages = { stats: statsOf2(m[2]), delta: num2(m[3]), minDmg: num2(m[1]) }));
    r.take(/本回合休息，提升暴击率，下回合攻击对方单体/, () => {
      e.charge = true;
      e.highCrit = true;
    });
    r.take(/下回合必定命中(?:对方单体)?/, () => void e.timed.push({ who: "self", kind: "sure", turns: 2 }));
    r.take(/^先发|先发(?=；|，|;|,)/, () => void (e.first = true));
    r.take(/(?:^|；|;|，)后发(?=；|，|;|,|$)/, () => void (e.last = true));
    r.take(/必定命中|必中技除外/, (m) => m[0] === "\u5FC5\u5B9A\u547D\u4E2D" ? void (e.sure = true) : void 0);
    r.take(/容易暴击|本回合提升暴击概率|暴击概率提升|自己提升暴击等级|提升暴击率/, () => void (e.highCrit = true));
    r.take(/一场战斗使用(?:次数越多|多次)，?(?:则)?成功率(?:会)?(?:越低|降低)(?:；使用失败则回复自己(\d+)点体力值?)?/, (m) => {
      e.fade = true;
      if (m[1]) e.failHeal = num2(m[1]);
    });
    r.take(/(?:本回合)?受到伤害时至少为自己保留1点体力值/, () => void (e.hold = true));
    r.take(/无视对方攻击/, () => void (e.protect = true));
    r.take(/(?:若|当)?([^，；]*?)(?:时|的话)?，?(?:则|可)?(?:发动|威力)?(?:加倍|(\d+(?:\.\d+)?)倍威力|提升至(\d+(?:\.\d+)?)倍|威力加倍|威力提升至(\d+)|可发动(\d+(?:\.\d+)?)倍(?:威力|伤害))/, (m) => {
      const c = cond(m[1]);
      if (!c) return false;
      const mult = m[2] ? num2(m[2]) : m[3] ? num2(m[3]) : m[5] ? num2(m[5]) : m[4] ? void 0 : 2;
      (e.powerIf ??= []).push(m[4] ? { cond: c, set: num2(m[4]) } : { cond: c, mult });
    });
    r.take(/若对方体力值比自己多，则发动2倍威力；若对方体力值比自己少，则发动1\/2倍威力/, () => {
      (e.powerIf ??= []).push({ cond: { foeHpMore: true }, mult: 2 }, { cond: { foeHpLess: true }, mult: 0.5 });
    });
    r.take(/自己体力值少于一半时，威力加倍；自己体力值小于1\/4时，威力提升至4倍/, () => {
      (e.powerIf ??= []).push({ cond: { selfHpBelow: 0.25 }, mult: 4 }, { cond: { selfHpBelow: 0.5 }, mult: 2 });
    });
    r.take(/令被束缚中的对方，承受(\d+(?:\.\d+)?)倍的伤害/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: "\u675F\u7F1A" }, mult: num2(m[1]) }));
    r.take(/若对方处于(麻痹|烧伤)状态，(?:则)?必定暴击对方/, (m) => void (e.critIf = { foeStatus: statusOf(m[1]) }));
    r.take(/(?:自己)?(?:剩余)?(?:体力值?|损伤的体力值|损失体力)越(?:少|多|高|低)，?(?:技能)?(?:威力|附加伤害)越(?:大|高|多|低)|自己体力越少，威力越低|自己危在旦夕的时候，能发挥秒杀对方单体的巨大威力|自己当前的体力值越高，威力越大/, (m) => {
      const t = m[0];
      if (/秒杀/.test(t)) e.powerByHp = "low";
      else if (/损伤|损失/.test(t)) e.powerByHp = /越多/.test(t) ? "low" : "high";
      else if (/越(?:少|低)，(?:技能)?(?:威力|附加伤害)越(?:大|高|多)/.test(t)) e.powerByHp = "low";
      else e.powerByHp = "high";
    });
    r.take(/对方剩余体力值越多(?:威力越大)?|我方剩余体力值越少，对方剩余体力值越多，威力越大/, (m) => void (e.powerByHp = /我方/.test(m[0]) ? "low" : "foeHigh"));
    r.take(/(?:自己)?(?:与对方)?的?速度(?:比值|越快|等级越高|与对方速度比值越大)[^，；]*?(?:威力|伤害)越(?:大|高|多|小)|自己速度越快，爆发的威力也越大|我方速度等级与对方速度等级之差越大，伤害越高|对方速度等级越低，威力越大/, (m) => {
      e.powerBySpeed = /越小(?:威力越大)?$|比值越小威力越大/.test(m[0]) && !/越大，威力越小/.test(m[0]) ? "slow" : /越大，威力越小/.test(m[0]) ? "slow" : "fast";
    });
    r.take(/自己与对方的速度比值越小威力越大/, () => void (e.powerBySpeed = "slow"));
    r.take(/(?:自己|我方)?(?:攻击|特攻|双防等级)(?:与对方(?:攻击|特攻))?(?:比值)?越(?:大|高)，?(?:则)?(?:威力|伤害)?越(?:大|高)|自己(?:当前)?(?:普通)?攻击越高(?:则)?造成伤害越大|自己特攻越高，伤害越高/, () => void 0);
    r.take(/无视对方(?:防御|特防)/, () => void (e.ignoreDef = true));
    r.take(/(\d+)%概率无视对方(?:防御|特防)提升的等级/, () => void 0);
    r.take(/连续(?:攻击对方(?:单体)?)?(\d+)回合(?:攻击对方(?:单体)?)?，?(?:每(?:回合|次)威力加倍|威力(?:每回合)?(?:增加|递增)|不管命中与否，每回合威力增加(\d+))/, (m) => void (e.rollout = { turns: num2(m[1]), add: m[2] ? num2(m[2]) : void 0, .../不管命中与否/.test(m[0]) ? { always: true } : {} }));
    r.take(/连续攻击对方(\d+)~(\d+)回合，威力每回合递增/, (m) => void (e.rollout = { turns: num2(m[2]) }));
    r.take(/(?:使用(?:技能)?)?(元素庇护)后?威力(?:再)?加倍|使用(千军万马)后威力大大提升/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1] ?? m[2]), mult: 2 }));
    r.take(/攻击失误则清除加倍效果/, () => void 0);
    r.take(/至少(?:能)?为(?:对方亚比|其)保留1点体力值/, () => void (e.falseSwipe = true));
    r.take(/若对方体力值多过自己，则将对方的体力值减为与自己相同/, () => void (e.endeavor = true));
    r.take(/(?:若对方体力值比自己多，则有(\d+)%概率)?平分(?:自己和对方单体|双方)的?(?:当前)?体力值/, (m) => {
      e.painSplit = true;
      if (m[1]) e.painSplitChance = num2(m[1]);
    });
    r.take(/调换双方的体力值/, () => void (e.swapHp = true));
    const endsOnSwitch = (s) => /(?:替换|交换)亚比(?:可)?解除|交换亚比解除效果|替换亚比后消失/.test(r.d) || /解除/.test(s);
    r.take(/下回合自己使用(\S{1,2}?)系技能威力加倍/, (m) => void e.timed.push({ who: "self", kind: "power", turns: 2, mult: 2, attr: ATTRS[m[1]] }));
    r.take(/给(?:自己的伤害|每次攻击)附加(\d+)点伤害值，持续(\d+)(?:回合|次攻击|次)/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/自己受到伤害则自动提升(速度)等级(\d+)级(?:，持续(\d+)回合)?/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: m[3] ? num2(m[3]) : 5, stats: statsOf2(m[1]), delta: num2(m[2]), chance: 100, selfStage: true }));
    r.take(/(\d+)%概率令攻击自己的对方进入(睡眠)状态/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 3, chance: num2(m[1]), status: statusOf(m[2]) }));
    r.take(/(?:使用后)?受到伤害则减半，并额外提升自己伤害能力(\d+)%，持续(\d+)回合/, (m) => {
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[2]), phys: 0.5, spec: 0.5 });
      e.timed.push({ who: "self", kind: "power", turns: num2(m[2]), mult: 1 + num2(m[1]) / 100 });
    });
    r.take(/提升自己伤害抵抗能力(\d+)%，每回合回复自己(\d+)点体力值，持续(\d+)回合/, (m) => {
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[3]), phys: 1 - num2(m[1]) / 100, spec: 1 - num2(m[1]) / 100 });
      e.timed.push({ who: "self", kind: "regen", turns: num2(m[3]), n: num2(m[2]) });
    });
    r.take(/下回合先发攻击，扣除对方单体(\d+)点体力值/, (m) => {
      e.charge = true;
      e.chargeFirst = true;
      e.dmg = { kind: "flat", n: num2(m[1]) };
    });
    r.take(/连续攻击对方(\d+)回合，之后提升自己/, (m) => {
      e.lock = { turns: [num2(m[1]), num2(m[1])], after: "none" };
      return false;
    });
    r.take(/连续攻击对方(\d+)回合，之后/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[1])], after: "none" }));
    r.take(/(?:本回合)?自己回复(\d+)点体力值保护自己/, (m) => void (e.healFlat = num2(m[1])));
    r.take(/一定概率扣除对方单体(1\/4)体力值/, (m) => {
      e.dmg = { kind: "hpFrac", f: frac(m[1]) };
      e.dmgChance = 50;
    });
    r.take(/自己速度比对方慢，则威力加倍，否则减半/, () => void (e.powerIf ??= []).push({ cond: { slower: true }, mult: 2 }, { cond: { faster: true }, mult: 0.5 }));
    r.take(/每次受到攻击都有(\d+)%概率令对方(睡眠)，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[3]), chance: num2(m[1]), status: statusOf(m[2]) }));
    r.take(/使用后(\d+)回合内受到普通或特殊攻击，都有(\d+)%概率令对方(烧伤)或者(睡眠)/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[1]), chance: num2(m[2]), status: statusOf(m[3]), statusAlt: statusOf(m[4]) }));
    r.take(/暴击后(?=提升)/, () => void (e.stagesIfCrit = true));
    r.take(/回复敌我双方的体力值/, () => void (e.healBoth = true));
    r.take(/重置双方提升的能力等级，(\d+)%概率令对方当回合攻击难以命中/, (m) => {
      e.clearBothUps = true;
      e.timed.push({ who: "self", kind: "dodge", turns: 1, phys: num2(m[1]), spec: num2(m[1]) });
    });
    r.take(/(?:使用后)?接下来(\d+)回合，能将伤害值的(\d+)%转化来回复自己|使用后(\d+)回合内，能将伤害值的(\d+)%转化来回复自己/, (m) => void e.timed.push({ who: "self", kind: "drain", turns: num2(m[1] ?? m[3]), f: num2(m[2] ?? m[4]) / 100 }));
    r.take(/每回合扣除对方单体最大体力值的(\d+\/\d+)，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: num2(m[2]), f: frac(m[1]) }));
    r.take(/接下来(\d+)回合若对方受到伤害，都可能被秒杀/, (m) => void e.timed.push({ who: "foe", kind: "doom", turns: num2(m[1]), chance: 10 }));
    r.take(new RegExp(`\u5BF9\u65B9\u6BCF\u53D7\u5230(\u70E7\u4F24|\u51B0\u51BB|\u675F\u7F1A)\u4F24\u5BB31\u6B21\uFF0C\u5C31(\u63D0\u5347\u81EA\u5DF1|\u964D\u4F4E\u5BF9\u65B9)(${STAT_LIST})(?:\u7684)?\u7B49\u7EA7(?:\u5404)?(\\d+)\u7EA7`), (m) => {
      const up = m[2] === "\u63D0\u5347\u81EA\u5DF1";
      e.timed.push({ who: up ? "self" : "foe", kind: "stagesEachTurn", turns: 99, stats: statsOf2(m[3]), delta: (up ? 1 : -1) * num2(m[4]), chance: 100, ...up ? { whileOther: statusOf(m[1]) } : { while: statusOf(m[1]) } });
    });
    r.take(/若对方处于(烧伤)状态，秒杀概率翻倍/, (m) => void (e.ohkoDoubleIf = { foeStatus: statusOf(m[1]) }));
    r.take(/(?:本回合)?自己若被对方打败，则扣除对方所有技能的PP/, () => void (e.grudge = true));
    r.take(/连续攻击对方(?:单体)?(\d+)回合，(?=每回合均有)/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[1])], after: "none" }));
    r.take(/每回合均有(?=\d+%概率令对方)/, () => void 0);
    r.take(/使用后本回合自己只承受对方一半的伤害，反击另一半伤害；?自己被击败(?:则)?无法反击/, () => void (e.shield = { take: 0.5, reflect: 0.5, ifAlive: true }));
    r.take(/提升我方全体伤害(\d+)%，(?=闪避)/, (m) => void e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num2(m[1]) / 100 }));
    r.take(/若对方(烧伤)，自己回复(\d+\/\d+)体力值/, (m) => void (e.healAfter = { f: frac(m[2]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
    r.take(/(\d+)回合内自己不受(睡眠)和(害怕)的状态影响/, (m) => void e.timed.push({ who: "self", kind: "nostatus", turns: num2(m[1]), only: [statusOf(m[2]), statusOf(m[3])] }));
    r.take(/回合结束时消耗自己体力值到1点/, () => void (e.delayed = { who: "self", turns: 0, kind: "hpTo1" }));
    r.take(/但是必定能被普通系技能攻击命中且伤害加倍/, () => void 0);
    r.take(/(?:另外，)?自身不死，每回合扣除对方所有PP值(\d+)点/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num2(m[1]) }));
    r.take(/然后连续攻击对方(?:单体)?(\d+)回合/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[1])], after: "none" }));
    r.take(/被冰冻时，速度等级每回合削弱(\d+)级/, (m) => void e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: 99, stats: ["spd"], delta: -num2(m[1]), chance: 100, while: "\u51B0\u51BB" }));
    r.take(/随机攻击对方(\d+)~(\d+)回合/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[2])], after: "none" }));
    r.take(/完全吸收对方的伤害值来回复自己体力/, () => void (e.absorbHit = true));
    r.take(/使用后自己停止行动(\d+)回合/, (m) => {
      e.recharge = true;
      e.rechargeTurns = num2(m[1]);
    });
    r.take(/(?:3回合内|使用后3回合内)?每回合(?:自己)?(?:为我方全体|自己|自动)?(?:回复|恢复)(?:自己|该亚比|亚比)?(?:(\d+)点|最大体力值的(\d+\/\d+)|(\d+)点体力值|(\d+)体力值|(\d+\/\d+)体力值)?(?:体力值)?(?:，?(?:持续)?(\d+)回合(?:有效)?)?/, (m) => {
      const n = m[1] ?? m[3] ?? m[4];
      const turns = m[6] ? num2(m[6]) : turnsOf(r.d, /无限/.test(r.d) ? 999 : 5);
      const f = m[2] ?? m[5];
      e.timed.push({ who: "self", kind: "regen", turns, ...n ? { n: num2(n) } : { f: f ? frac(f) : 1 / 16 }, endsOnSwitch: endsOnSwitch(m[0]) });
    });
    r.take(/(?:持续(\d+)回合)?(?:回复|恢复)(\d+)点体力值/, () => false);
    r.take(/每?回合结束时(?:回复|恢复)(?:最大体力值的)?(\d+\/\d+)(?:最大体力值?)?/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: turnsOf(r.d, 3), f: frac(m[1]) }));
    r.take(/每回合结束时回复1\/10最大体力/, () => void e.timed.push({ who: "self", kind: "regen", turns: 5, f: 0.1 }));
    r.take(/(?:回合末回复的体力值=已损失体力值\/8|自己体力值损失越多回复越多|每回合结束时回复自己的体力值，自己的剩余体力值越少，回复量越多)，?(?:持续(\d+)回合)?/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: m[1] ? num2(m[1]) : turnsOf(r.d, 5), f: 1 / 8, lost: true }));
    r.take(/每回合均有(\d+)%概率回复自己所有体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: turnsOf(r.d, 5), f: 1, chance: num2(m[1]) }));
    r.take(/每回合恢复(\d+)体力值，持续(\d+)回合，75%概率作用给自己，25%概率作用给对方/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num2(m[2]), n: num2(m[1]), chance: 75 }));
    r.take(/持续(\d+)回合回复(\d+)点体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/(\d+)回合内每回合回复自身(\d+)点体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/回合结束时恢复一定体力值/, () => void e.timed.push({ who: "self", kind: "regen", turns: 5, f: 1 / 16 }));
    r.take(/回合结束时(?:为自己|回复对方体力值)(?:回复)?(\d+)点体力值?/, (m) => /对方/.test(m[0]) ? void 0 : void e.timed.push({ who: "self", kind: "regen", turns: 1, n: num2(m[1]) }));
    r.take(/每回合(?:吸取|扣除)对方单体(?:最大体力值的(\d+\/\d+)|(\d+)点体力值)用来回复自己(?:体力值)?(?:，?持续(\d+)回合)?(?:，对木系无效)?/, (m) => {
      e.timed.push({ who: "foe", kind: "leech", turns: m[3] ? num2(m[3]) : 99, ...m[2] ? { n: num2(m[2]) } : { f: frac(m[1]) }, .../木系无效/.test(m[0]) ? { attr: ATTRS.\u6728 } : {} });
    });
    r.take(/扣除对方(\d+\/\d+)的最大体力值来回复自己体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "leech", turns: num2(m[2]), f: frac(m[1]) }));
    r.take(/若对方处于睡眠中，夺取(\d+\/\d+)体力值用来回复自己/, (m) => {
      e.dmg = { kind: "hpFrac", f: frac(m[1]) };
      e.dmgHeals = "all";
      (e.powerIf ??= []).push({ cond: { foeStatus: "\u7761\u7720" }, mult: 1 });
    });
    r.take(/(?:令对方单体)?(\d+)~(\d+)回合无法替换亚比，且每回合(?:扣除|损伤)最大体力值的(\d+\/\d+)/, (m) => {
      e.trap = [num2(m[1]), num2(m[2])];
      e.timed.push({ who: "foe", kind: "dot", turns: num2(m[2]), f: frac(m[3]) });
    });
    r.take(/(?:令对方单体)?无法替换亚比，每回合扣除最大体力值的(\d+\/\d+)/, (m) => {
      e.trap = [5, 5];
      e.timed.push({ who: "foe", kind: "dot", turns: 5, f: frac(m[1]) });
    });
    r.take(/使用后(\d+)~(\d+)回合对方不能替换亚比，且每回合损伤最大体力值的(\d+\/\d+)/, (m) => {
      e.trap = [num2(m[1]), num2(m[2])];
      e.timed.push({ who: "foe", kind: "dot", turns: num2(m[2]), f: frac(m[3]) });
    });
    r.take(/束缚对方单体，禁止对方替换亚比|束缚对方(?=$|，)/, () => {
      e.statuses.push({ name: "\u675F\u7F1A", chance: 100 });
      e.trap = [4, 5];
    });
    r.take(/(?:若自己不死，)?每回合给对方(?:单体)?造成(\d+)点伤害值?(?:，持续(\d+)回合)?/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: m[2] ? num2(m[2]) : 99, n: num2(m[1]) }));
    r.take(/令对方单体每回合随机损失(\d+)~(\d+)点体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: num2(m[3]), a: num2(m[1]), b: num2(m[2]) }));
    r.take(/每回合结束时，均有(\d+)%概率令扣除对方单体最大体力值的(\d+)%，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: num2(m[3]), f: num2(m[2]) / 100, chance: num2(m[1]) }));
    r.take(/令睡眠中的对方每回合扣除最大体力值的(\d+\/\d+)/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: 99, f: frac(m[1]), while: "\u7761\u7720" }));
    r.take(/(?:数码系亚比扣除自己最大体力值的1\/2，)?对方单体每回合扣除最大体力值的(\d+\/\d+)/, (m) => {
      e.timed.push({ who: "foe", kind: "dot", turns: 5, f: frac(m[1]) });
      if (/数码系/.test(m[0])) e.selfCost = { f: 0.5 };
    });
    r.take(/每回合扣除对方单体最大体力值的(\d+\/\d+)，无限回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: 999, f: frac(m[1]) }));
    r.take(/双方每回合均扣除自己最大体力值的(\d+\/\d+)，持续(\d+)回合/, (m) => void e.timed.push({ who: "both", kind: "dot", turns: num2(m[2]), f: frac(m[1]) }));
    r.take(/每回合扣除双方体力值(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "both", kind: "dot", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/(\d+)回合，(\d+)%概率扣除对方单体(\d+)点体力值，否则扣除自己(\d+)点体力值/, (m) => void e.timed.push({ who: "foe", kind: "gamble", turns: num2(m[1]), chance: num2(m[2]), n: num2(m[3]), self: -num2(m[4]) }));
    r.take(/(\d+)%概率扣除对方单体(\d+)点体力值，否则自己回复(\d+)点体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "gamble", turns: num2(m[4]), chance: num2(m[1]), n: num2(m[2]), self: num2(m[3]) }));
    r.take(/(\d+)%概率扣除对方单体一半的体力值，否则扣除自己一半的体力值/, (m) => {
      e.dmg = { kind: "hpFrac", f: 0.5 };
      e.painSplitChance = num2(m[1]);
    });
    r.take(/每回合扣除自己体力值(\d+)点，随机削弱对方一种属性的等级(\d+)级，持续(\d+)回合/, (m) => {
      e.timed.push({ who: "self", kind: "dot", turns: num2(m[3]), n: num2(m[1]) });
      e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: num2(m[3]), stats: ALL_STATS, delta: -num2(m[2]), chance: 100 });
    });
    r.take(/回合结束时随机提升自己(防御或特防)等级(\d+)级(?:，持续(\d+)回合)?/, (m) => void e.timed.push({ who: "self", kind: "stagesEachTurn", turns: m[3] ? num2(m[3]) : turnsOf(r.d, 4), stats: statsOf2(m[1].replace("\u6216", "\u548C")), delta: num2(m[2]), chance: 100 }));
    r.take(/(\d+)回合内双方亚比每回合随机下降全属性1级/, (m) => void e.timed.push({ who: "both", kind: "stagesEachTurn", turns: num2(m[1]), stats: ALL_STATS, delta: -1, chance: 100 }));
    r.take(/(?:回合结束时有一定几率|一定几率)扣除自身最大生命值(\d+\/\d+)/, (m) => void e.timed.push({ who: "self", kind: "dot", turns: 1, f: frac(m[1]), chance: 30 }));
    r.take(/使用后(\d+)回合内，每回合将自己所有PP值1点转化来回复(\d+)点体力值(?:，最多叠加\d+次)?/, (m) => void e.timed.push({ who: "self", kind: "pphp", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/(?:使用后)?(\d+)回合内，每攻击对方1次，就回复自己(\d+)点体力值/, (m) => void e.timed.push({ who: "self", kind: "hitHeal", turns: num2(m[1]), n: num2(m[2]) }));
    r.take(/扔出骰子的点数越大，给对方造成伤害越大，自己回复的体力值也越多，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "gamble", turns: num2(m[1]), chance: 100, a: 20, b: 120, self: 1 }));
    r.take(/我方全体受到(普通|特殊)攻击的伤害减半，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: num2(m[2]), ...m[1] === "\u666E\u901A" ? { phys: 0.5 } : { spec: 0.5 } }));
    r.take(/(?:自己受到普通或特殊攻击时伤害减半|自己只承受一半普通攻击与特殊攻击造成的伤害|抵抗普通攻击与特殊攻击类型造成伤害的一半)/, () => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 3), phys: 0.5, spec: 0.5 }));
    r.take(/(?:接下来\d+个回合)?提升我方全体队员抵抗普通攻击伤害的(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 4), phys: 1 - num2(m[1]) / 100 }));
    r.take(/自己抵抗对方造成伤害的(\d+)%，甚至抵抗秒杀/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 3), phys: 1 - num2(m[1]) / 100, spec: 1 - num2(m[1]) / 100 }));
    r.take(/连续攻击对方单体2回合，期间只承受对方2\/3的伤害/, () => {
      e.lock = { turns: [2, 2], after: "none" };
      e.timed.push({ who: "self", kind: "screen", turns: 2, phys: 2 / 3, spec: 2 / 3 });
    });
    r.take(/(?:使用后)?(\d+)回合内，自己受到特殊攻击时伤害减半；若受到普通攻击，则将受到伤害的(\d+\/\d+)返击对方/, (m) => {
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), spec: 0.5 });
      e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]) });
    });
    r.take(/使用后(\d+)回合内，将对方(特殊|普通)攻击(\d+\/\d+)的伤害反击回去，自己只承受伤害的(\d+\/\d+)(?:；不能和.*同时存在(?:效果)?.*)?/, (m) => {
      const k = m[2] === "\u666E\u901A" ? "phys" : "spec";
      e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), [k]: frac(m[3]) });
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), [k]: frac(m[4]) });
    });
    r.take(/使用后(\d+)回合内，将所受伤害的(\d+\/\d+)返还给对方，自身承受(\d+\/\d+)/, (m) => {
      e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: frac(m[2]), spec: frac(m[2]) });
      e.timed.push({ who: "self", kind: "screen", turns: num2(m[1]), phys: frac(m[3]), spec: frac(m[3]) });
    });
    r.take(/(\d+)回合内将受到的伤害值的(\d+)%反击对方单体/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num2(m[1]), phys: num2(m[2]) / 100, spec: num2(m[2]) / 100 }));
    r.take(/反弹受到普通攻击的(\d+(?:\.\d+)?)倍伤害给对方/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: 5, phys: num2(m[1]) }));
    r.take(/若5回合内不受普通攻击，浑天.*$/, () => void 0);
    r.take(/自己受到伤害则反弹(\d+)点伤害给对方，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/每回合自己可以抵抗(\d+)点伤害值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "absorb", turns: num2(m[2]), n: num2(m[1]) }));
    r.take(/(\d+)%概率自己免受(普通|特殊)攻击造成的伤害，持续(\d+)回合(?:，不能和技能.*效果同时存在)?/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num2(m[3]), ...m[2] === "\u666E\u901A" ? { phys: num2(m[1]) } : { spec: num2(m[1]) } }));
    r.take(/(?:使用后，)?(\d+)%概率(?:闪避|躲过)(特殊攻击与普通攻击技能|特殊攻击技能|对方的攻击)(?:造成的伤害)?，持续(\d+)(?:~(\d+))?回合/, (m) => {
      const both = !/^特殊攻击技能$/.test(m[2]);
      e.timed.push({ who: "self", kind: "dodge", turns: num2(m[4] || m[3]), spec: num2(m[1]), ...both ? { phys: num2(m[1]) } : {} });
    });
    r.take(/使用后(?:3回合内)?(\d+)%概率令对方的攻击无效/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: 3, phys: num2(m[1]), spec: num2(m[1]) }));
    r.take(/使用后3回合内30%概率令对方的攻击无效/, () => void e.timed.push({ who: "self", kind: "dodge", turns: 3, phys: 30, spec: 30 }));
    r.take(/使用后自己进入隐身状态，(\d+)%概率闪避对方的伤害，但是必定能被普通系技能攻击命中/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: 3, phys: num2(m[1]), spec: num2(m[1]) }));
    r.take(/每回合自动随机产生对普通攻击或者特殊攻击的抵抗/, () => void e.timed.push({ who: "self", kind: "screen", turns: 5, phys: 0.5, flip: true }));
    r.take(/(?:保护我方全体，)?(?:持续)?(\d+)回合(?:内)?(?:，)?(?:自己)?(?:属性能力等级|全属性)(?:不能|不可|不会)被削弱|自己属性能力等级不会被削弱，持续(\d+)回合|(?:接下来)?(\d+)回合(?:自己)?全属性不(?:能|可)被削弱/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num2(m[1] ?? m[2] ?? m[3]) }));
    r.take(/持续(\d+)回合，自己属性能力等级不能被削弱(?:；若对方提升它的属性能力等级，同样也会加给自己)?/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num2(m[1]) }));
    r.take(/两回合内对方属性等级无法被提升或降低/, () => void 0);
    r.take(/使用后自己不会陷入异常状态，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "nostatus", turns: num2(m[1]) }));
    r.take(/免疫烧伤/, () => void 0);
    r.take(/给自己的普通攻击与特殊攻击技能附加(\d+)威力，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "power", turns: num2(m[2]), add: num2(m[1]) }));
    r.take(/提升自身所有技能威力(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "power", turns: num2(m[2]), add: num2(m[1]) }));
    r.take(/(?:技能)?威力提升至(\d+(?:\.\d+)?)倍/, (m) => void e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 4), mult: num2(m[1]) }));
    r.take(/(?:使用后接下来(\d+)回合，)?(?:我方全体)?(光明|飞行)系技能威力提升(\d+)%，伤害抵抗(?:能力)?提升(\d+)%(?:，持续(\d+)回合)?/, (m) => {
      const turns = num2(m[1] || m[5], 3);
      e.timed.push({ who: "self", kind: "power", turns, mult: 1 + num2(m[3]) / 100, attr: ATTRS[m[2]] });
      e.timed.push({ who: "self", kind: "screen", turns, phys: 1 - num2(m[4]) / 100, spec: 1 - num2(m[4]) / 100 });
    });
    r.take(/下回合使用(木)系技能威力上升(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "power", turns: 2, mult: 1 + num2(m[2]) / 100, attr: ATTRS[m[1]] }));
    r.take(/使用后(\d+)回合内，使得自己的每次攻击均有(\d+)%概率暴击对方/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num2(m[1]), chance: num2(m[2]) }));
    r.take(/使用后接下来(\d+)回合，自己技能暴击概率提升至(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num2(m[1]), chance: num2(m[2]) }));
    r.take(/使用后，接下来(\d+)个?回合暴击等级提升至6级/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num2(m[1]), chance: 50 }));
    r.take(/使用后接下来(\d+)回合，给对方造成伤害时附加(\d+)%概率害怕效果/, (m) => void e.timed.push({ who: "self", kind: "onhit", turns: num2(m[1]), chance: num2(m[2]), n: 1 }));
    r.take(/使用后(\d+)回合内，自己给对方造成伤害时，都有(\d+)%概率清除对方提升的属性能力等级/, (m) => void e.timed.push({ who: "self", kind: "onhit", turns: num2(m[1]), chance: num2(m[2]), n: 2 }));
    r.take(/使用后(\d+)回合内，自己的(防御和速度)加倍/, (m) => void e.timed.push({ who: "self", kind: "statmult", turns: num2(m[1]), stats: statsOf2(m[2]), mult: 2 }));
    r.take(/(?:使用后)?(\d+)回合内，受到伤害则提升自身(防御和特防)的等级各(\d+)级/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num2(m[1]), stats: statsOf2(m[2]), delta: num2(m[3]), chance: 100, selfStage: true }));
    r.take(/若自己受到(?:伤害|攻击)，(?:有(\d+)%概率)?(?:则)?扣除对方(?:全部技能PP|所有PP)(\d+)点，持续(\d+)回合/, () => void 0);
    r.take(/(?:使用后)?(\d+)回合内，?若当回合对方不使用攻击技能，则当回合结束时扣除对方(\d+)点体力值/, () => void 0);
    r.take(/令对方单体每回合均有(\d+)%概率无法进行攻击，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "noact", turns: num2(m[2]), chance: num2(m[1]) }));
    r.take(/(\d+)回合内，每回合均有(\d+\/\d+)概率令对方单体无法使用技能/, (m) => void e.timed.push({ who: "foe", kind: "noact", turns: num2(m[1]), chance: frac(m[2]) * 100 }));
    r.take(/令对方单体(\d+)~(\d+)回合内使用普通攻击技能必定很难命中/, (m) => void e.timed.push({ who: "foe", kind: "blind", turnsMin: num2(m[1]), turns: num2(m[2]), phys: 25 }));
    r.take(/(?:全场|10回合内，全场)(\S{1,3}?)系(?:技能)?威力(?:提升|上升)(\d+)%(?:，(\S{1,2}?)系威力削弱(\d+)%)?(?:，(?:持续)?(\d+)回合(?:有效)?)?/, (m) => {
      const up = ATTRS[m[1]];
      if (up === void 0) return false;
      e.field = { up, upPct: num2(m[2]), ...m[3] && ATTRS[m[3]] !== void 0 ? { down: ATTRS[m[3]], downPct: num2(m[4]) } : {}, turns: m[5] ? num2(m[5]) : turnsOf(r.d, 5) };
    });
    r.take(/每回合结束时(\d+)%概率令对方全场(麻痹)/, (m) => void e.timed.push({ who: "foe", kind: "plague", turns: turnsOf(r.d, 5), chance: num2(m[1]), status: statusOf(m[2]) }));
    r.take(/(?:本回合不行动，下回合自动攻击对方单体|本回合停止行动，下回合先发攻击对方单体|本回合聚集能量，下回合给予对方致命打击|蓄力(\d+)回合下回合爆发出无法阻挡的伤害)/, (m) => {
      if (m[1] && num2(m[1]) > 1) e.chargeTurns = num2(m[1]);
      if (/无法阻挡/.test(m[0])) {
        e.sure = true;
        e.pierce = true;
      }
      e.charge = true;
      if (/先发/.test(m[0])) e.chargeFirst = true;
    });
    r.take(/若蓄力时未受到伤害则伤害翻倍/, () => void (e.powerIf ??= []).push({ cond: { chargeUnhurt: true }, mult: 2 }));
    r.take(/连续(\d+)~(\d+)个?回合攻击对方随机目标(?:，命中后自己陷入混乱|，之后自己陷入混乱)?|连续攻击对方随机单体(\d+)~(\d+)回合，之后自己陷入混乱/, (m) => void (e.lock = { turns: [num2(m[1] ?? m[3]), num2(m[2] ?? m[4])], after: "confuse" }));
    r.take(/连续(\d+)回合(?:向敌方扔出威力巨大的飞刀|攻击对方(?:单体)?)?，?(?:威力十分巨大)?，?之后自己(?:休息|停止行动)1回合/, (m) => void (e.lock = { turns: [num2(m[1]), num2(m[1])], after: "rest" }));
    r.take(/连续攻击对方单体2回合，第2回合结束时回复自己(\d+\/\d+)体力值/, (m) => void (e.lock = { turns: [2, 2], after: "heal", healF: frac(m[1]) }));
    r.take(/连续3回合攻击对方单体，威力每回合增加/, () => void (e.rollout = { turns: 3 }));
    r.take(/本回合闪避对方的攻击|当回合闪避对方的攻击|本回合闪避对方攻击/, () => void (e.protect = true));
    r.take(/一场战斗使用次数越多，成功率越低(?:；使用失败则回复自己(\d+)点体力值?)?/, (m) => m[1] ? void (e.failHeal = num2(m[1])) : void 0);
    r.take(/若自己速度快过对方，则无视对方本回合攻击/, () => void (e.protect = true));
    r.take(/将本回合受到对方(特殊|普通)攻击的伤害，加倍反击对方/, (m) => void (e.shield = { take: 1, reflect: 2, kind: m[1] === "\u666E\u901A" ? "phys" : "spec" }));
    r.take(/若(?:没死亡|自己不死)，(?:则)?将(?:承受的伤害|本回合承受伤害的|本回合受到的伤害)(加倍|(\d+(?:\.\d+)?)倍)反击(?:给)?对方/, (m) => void (e.shield = { take: 1, reflect: m[2] ? num2(m[2]) : 2, ifAlive: true }));
    r.take(/若自己先出手，则将本回合受到攻击的(\d+(?:\.\d+)?)倍，反击对方/, (m) => void (e.shield = { take: 1, reflect: num2(m[1]), ifFirst: true }));
    r.take(/将自己受到伤害的(\d+(?:\.\d+)?)倍反击对方全体/, (m) => void (e.shield = { take: 1, reflect: num2(m[1]) }));
    r.take(/本回合自己若被对方打败，则双方同归于尽/, () => void (e.destiny = true));
    r.take(/自己本回合若死亡，则自己满状态复活/, () => void (e.endure = "revive"));
    r.take(/使用后被对方打败则满状态复活/, () => void (e.endure = "reviveOnce"));
    r.take(/(?:令对方单体)?下回合结束时睡眠/, () => void (e.delayed = { who: "foe", turns: 1, kind: "sleep" }));
    r.take(/下回合结束时，?(?:回复自己所有体力值|完全回复自己体力值)/, () => void (e.delayed = { who: "self", turns: 1, kind: "healFull" }));
    r.take(/下回合结束时，对方体力值减少(\d+)点/, (m) => void (e.delayed = { who: "foe", turns: 1, kind: "flat", n: num2(m[1]) }));
    r.take(/(\d+)回合后，扣除对方(?:亚比)?(1\/2)的体力值/, (m) => void (e.delayed = { who: "foe", turns: num2(m[1]), kind: "hpFrac", f: frac(m[2]) }));
    r.take(/(\d+)回合后，对方全体扣除最大体力值的(1\/2)/, (m) => void (e.delayed = { who: "foe", turns: num2(m[1]), kind: "maxFrac", f: frac(m[2]) }));
    r.take(/(\d+)回合后，对方单体将因为时间被完全吞噬而死亡/, (m) => void (e.delayed = { who: "foe", turns: num2(m[1]), kind: "kill" }));
    r.take(/下回合结束时，自己体力值降为1点/, () => void (e.delayed = { who: "self", turns: 1, kind: "hpTo1" }));
    r.take(/(\d+)回合后提升自己全属性(\d+)级/, (m) => void (e.delayed = { who: "self", turns: num2(m[1]), kind: "stages", stats: ALL_STATS, delta: num2(m[2]) }));
    r.take(/强制对方单体替换亚比战斗|若本回合未受到伤害则强制对方单体替换亚比战斗/, () => void (e.forceSwitch = true));
    r.take(/(?:令对方单体)?(\d+)~(\d+)回合无法替换亚比|使用后无法替换亚比/, (m) => m[1] ? void (e.trap = [num2(m[1]), num2(m[2])]) : void 0);
    r.take(/使用后无法替换亚比/, () => void 0);
    r.take(/(?:(\d+)%概率|一定概率|有一定概率)?(?:令)?(?:自己)?下回合(?:自己)?(?:停止行动|无法行动)(?:1回合)?|命中后(?:有一定概率)?自己停止行动(?:1回合)?|使用后(?:自己)?停止行动1回合|之后自己停止行动1回合/, (m) => {
      e.recharge = true;
      if (m[1]) e.rechargeChance = num2(m[1]);
      else if (/一定概率/.test(m[0])) e.rechargeChance = 30;
    });
    r.take(/(\d+)%概率下回合自己停止?行?动?|(\d+)%概率(?:会)?使自己下回合.*$/, (m) => {
      e.recharge = true;
      e.rechargeChance = num2(m[1] ?? m[2]);
    });
    r.take(/(\d+)%概率令自己或对方下回合停止行动1回合，若对方麻痹则自己下回合不会停止行动/, (m) => void (e.eitherStops = num2(m[1])));
    r.take(/(\d+)%概率扣除自己(\d+)体力值/, (m) => void (e.selfCost = { n: num2(m[2]), chance: num2(m[1]) }));
    r.take(new RegExp(`\u82E5\u5BF9\u65B9(\u6DF7\u4E71)\u5219\u989D\u5916\u63D0\u5347\u81EA\u5DF1(${STAT_LIST})\u7B49\u7EA7(\\d+)\u7EA7`), (m) => void e.stages.push({ self: true, stats: statsOf2(m[2]), delta: num2(m[3]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4F1A\u4F7F\u81EA\u5DF1\u5904\u4E8E(${ST})\u6216(${ST})\u72B6\u6001`), (m) => {
      e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]) / 2, self: true }, { name: statusOf(m[3]), chance: num2(m[1]) / 2, self: true });
    });
    r.take(/(?:以后)?每回合回复该亚比最大体力值的(\d+\/\d+)，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num2(m[2]), f: frac(m[1]) }));
    r.take(/无限回合，直至病毒死亡|无限回合/, () => void 0);
    r.take(/将束缚时造成的伤害值用来回复自己/, () => void e.timed.push({ who: "foe", kind: "leech", turns: 5, f: 1 / 16 }));
    r.take(/(\d+)%概率秒杀(?:对方)?/, (m) => void (e.ohko = num2(m[1])));
    r.take(/(?:一定概率)?秒杀(?:对|对方)?(?:同等级或低等级|等级小于或等于自己)的(?:对方|亚比)?/, () => void (e.ohkoIf = { chance: 30, lowerLevel: true }));
    r.take(/秒杀体力值小于(\d+)的对方/, (m) => void (e.ohkoIf = { chance: 100, hpBelow: num2(m[1]) }));
    r.take(/若对方体力值少于(\d+)，则直接秒杀/, (m) => void (e.ohkoIf = { chance: 100, hpBelow: num2(m[1]) }));
    r.take(/命中后敌我双方同归于尽/, () => void (e.bothFaint = true));
    r.take(/牺牲(?:自己|当前亚比)/, () => void (e.sacrifice = true));
    r.take(/令自己以外的亚比防御值减半/, () => void e.stages.push({ self: false, stats: ["def"], delta: -2, chance: 100 }));
    r.take(/为自己下一只出场的亚比满状态回复/, () => void (e.nextFullHeal = true));
    r.take(/(?:给对方(?:单体)?)?造成(?:的)?伤害(?:=|为|是)?(?:自己|我方)等级(?:×|\*|的)(\d+(?:\.\d+)?)(?:~(\d+(?:\.\d+)?))?倍?(?:的伤害)?/, (m) => void (e.dmg = { kind: "level", a: num2(m[1]), b: num2(m[2] || m[1]) }));
    r.take(/给对方单体造成自己等级(\d+(?:\.\d+)?)倍的伤害/, (m) => void (e.dmg = { kind: "level", a: num2(m[1]), b: num2(m[1]) }));
    r.take(/造成(?:的)?伤害(?:是|为|=)?对方等级的(\d+)倍/, (m) => void (e.dmg = { kind: "foeLevel", mult: num2(m[1]) }));
    r.take(/(?:给对方(?:单体)?)?造成(\d+)(?:点)?伤害值?/, (m) => void (e.dmg = { kind: "flat", n: num2(m[1]) }));
    r.take(/(?:50%概率)?扣除对方(?:单体|全体)?(?:剩余)?(?:的)?(一半|1\/2|1\/4|\d+%)(?:的)?体力值(?:来转化回复自己的体力值|来回复自己)?/, (m) => {
      const f = frac(m[1]);
      e.dmg = { kind: "hpFrac", f };
      if (/回复/.test(m[0])) e.dmgHeals = "all";
    });
    r.take(/扣除对方(?:单体|全体)?剩余体力值的(\d+%)/, (m) => void (e.dmg = { kind: "hpFrac", f: frac(m[1]) }));
    r.take(/扣除对方单体最大体力值的(\d+\/\d+)转化来回复自己体力值/, (m) => {
      e.dmg = { kind: "maxFrac", f: frac(m[1]) };
      e.dmgHeals = "all";
    });
    r.take(/扣除对方单体(\d+)点体力值，自己回复(\d+)点体力值/, (m) => {
      e.dmg = { kind: "flat", n: num2(m[1]) };
      e.dmgHeals = num2(m[2]);
    });
    r.take(/随机扣除对方(?:单体)?(\d+)~(\d+)的?体力值(用来回复自己)?/, (m) => {
      e.dmg = { kind: "range", a: num2(m[1]), b: num2(m[2]) };
      if (m[3]) e.dmgHeals = "all";
    });
    r.take(/(?:附加|随机附加)(\d+)~(\d+)点(?:固定)?伤害值?/, (m) => void (e.fixedRange = [num2(m[1]), num2(m[2])]));
    r.take(/(?:(\d+)%概率)?附加(\d+)点伤害值?/, (m) => {
      e.fixed = num2(m[2]);
      if (m[1]) e.fixedChance = num2(m[1]);
    });
    r.take(/若自己速度比对方快，则必定附加(\d+)点固定伤害/, () => void 0);
    r.take(/(?:随机爆发|威力)(\d+)~(\d+)(?:的威力)?/, (m) => void (e.powerRange = [num2(m[1]), num2(m[2])]));
    r.take(/随机爆发1~500的威力/, () => void (e.powerRange = [1, 500]));
    r.take(/(\d+)%概率(?:发动|打出|发挥|造成)(\d+(?:\.\d+)?)倍(?:威力|伤害)?/, (m) => void (e.boost ??= []).push({ chance: num2(m[1]), mult: num2(m[2]) }));
    r.take(/一定概率发动1\.2倍威力，或者2倍威力，甚至3倍威力/, () => void (e.boost ??= []).push({ chance: 20, mult: 1.2 }, { chance: 10, mult: 2 }, { chance: 5, mult: 3 }));
    r.take(/发动时此技能威力提升至(\d+)倍，但是命中很低|发动时此威力提升至(\d+)倍，但是命中很低/, (m) => void (e.boost ??= []).push({ chance: 100, mult: num2(m[1]) }));
    r.take(/但是只有一半的命中率/, () => void 0);
    r.take(/(\d+)%概率(?:1回合内)?发动(\d+)次攻击(?:效果)?/, (m) => void (e.extraHits ??= []).push({ chance: num2(m[1]), n: num2(m[2]) }));
    r.take(/1回合内，一定概率发动多次攻击效果，每次威力减半/, () => void (e.extraHits ??= []).push({ chance: 30, n: 2 }));
    r.take(/(\d+)%概率暴击(?:对方单体)?/, (m) => void (e.critChance = num2(m[1])));
    {
      const h = r.d;
      if (!/下回合(?:内)?攻击/.test(h) && !/%概率\d*回合内?发动/.test(h)) {
        r.take(/(?:\d+回合内?)?(?:连续)?(?:攻击|撞击)对方(?:单体|全体|全场)?(\d+)~(\d+)次/, (m) => void (e.hits = [num2(m[1]), num2(m[2])]));
        r.take(/(?:\d+回合内?)?(?:爆发|发动)(\d+)~(\d+)次(?:攻击)?/, (m) => void (e.hits ??= [num2(m[1]), num2(m[2])]));
        r.take(/\d+回合内?(?:攻击|撞击)对方(?:单体|全体|全场)?(\d+)次/, (m) => Number(m[1]) > 1 ? void (e.hits ??= [num2(m[1]), num2(m[1])]) : false);
        r.take(/\d+回合内?发动(\d+)次攻击/, (m) => Number(m[1]) > 1 ? void (e.hits ??= [num2(m[1]), num2(m[1])]) : false);
      }
      if (e.hits && /每次(?:攻击|命中)/.test(h)) e.perHit = true;
    }
    r.take(/每次(?:攻击|命中)?(?:均|都)?(?:会|有|可以)?/, () => void 0);
    r.take(/(?:若暴击，则|自己体力值少于一半时，会|对方被冰冻时，|如果对方处于睡眠状态，则|若对方处于睡眠状态，则)?(?:吸取|将|给对方)?(?:造成(?:的)?)?(?:伤害值?|攻击值|对敌人造成伤害|全部伤害值)(?:的)?(一半|\d+\/\d+|\d+%|4倍)?(?:转化来|用来|来)?回复(?:自己)?(?:的)?(?:体力值?)?/, (m) => {
      const t = m[0];
      const f = m[1] === "4\u500D" ? 4 : m[1] ? frac(m[1]) : 1;
      const c = /暴击/.test(t) ? { crit: true } : /少于一半/.test(t) ? { selfHpBelow: 0.5 } : /冰冻/.test(t) ? { foeStatus: "\u51B0\u51BB" } : /睡眠/.test(t) ? { foeStatus: "\u7761\u7720" } : void 0;
      if (c && e.drain !== void 0 && /如果/.test(t)) {
        e.healAfter = void 0;
        (e.powerIf ??= []).push({ cond: c, drain: f });
        return;
      }
      e.drain = f;
      if (c) e.drainCond = c;
    });
    r.take(/伤害的(\d+%)转化回复自己/, (m) => void (e.drain = frac(m[1])));
    r.take(/回复对敌人造成伤害的一半的体力值/, () => void (e.drain = 0.5));
    r.take(/溢出的回复量会转化为自己的护盾/, () => void (e.overShield = true));
    r.take(/(?:(\d+)%概率)?(?:自身|自己)承受(?:造成|给)?(?:伤害值?|伤害)的(\d+\/\d+)/, (m) => {
      e.recoil = frac(m[2]);
      if (m[1]) e.recoilChance = num2(m[1]);
    });
    r.take(/自己承受(\d+\/\d+)的伤害/, (m) => void (e.recoil = frac(m[1])));
    r.take(/命中后扣除自己(\d+\/\d+)体力值/, (m) => void (e.selfCost = { f: frac(m[1]), current: true }));
    r.take(/(?:先)?扣除(?:自己|自身)(?:最大体力值的)?(\d+\/\d+|一半)(?:最大体力值)?/, (m) => void (e.selfCost = { f: frac(m[1]) }));
    r.take(/扣除自身当前体力值(\d+\/\d+)/, (m) => void (e.selfCost = { f: frac(m[1]), current: true }));
    r.take(/(?:先)?扣除自己(\d+)(?:点)?体力值|扣除自己体力值(\d+)点/, (m) => void (e.selfCost = { n: num2(m[1] ?? m[2]) }));
    r.take(/消耗自己最大体力值的(\d+\/\d+)/, (m) => void (e.selfCost = { f: frac(m[1]) }));
    r.take(/(?:(\d+)%概率)?(?:回复|恢复)(?:自己|自身)?(?:体力最大值的|最大体力值的)?(\d+\/\d+|一半|\d+%)(?:(?:最大)?(?:的)?体力值?)?/, (m) => {
      const f = frac(m[2]);
      e.healAfter = { f, chance: pct(m[1]) };
      if (!m[1]) e.heal = f;
    });
    r.take(/若自己出手速度快过对方，则恢复自己体力最大值的(\d+\/\d+)/, (m) => void (e.healAfter = { f: frac(m[1]), chance: 100, cond: { faster: true } }));
    r.take(/(\d+)%概率回复自己所有体力值/, (m) => void (e.healAfter = { f: 1, chance: num2(m[1]) }));
    r.take(/(?:回复|恢复|完全回复)(?:自己|我方全体|自身)?(?:所有|全部)体力值?/, () => void (e.healFull = true));
    r.take(/回复自己全部体力值和技能PP/, () => {
      e.healFull = true;
      e.ppSelf = 99;
    });
    r.take(/(?:回复|恢复)(?:自己|我方全体(?:亚比)?|自身|其)?(\d+)(?:点)?体力值?/, (m) => void (e.healFlat = num2(m[1])));
    r.take(/治愈我方(?:全体|单个亚比)，?(?:回复(?:亚比|其)?(一半)体力值)?/, (m) => {
      e.cure = true;
      if (m[1]) e.healAfter = { f: 0.5, chance: 100 };
    });
    r.take(/(\d+)回合进入睡眠状态|自己进入睡眠状态/, (m) => void (e.sleepAfter = m[1] ? num2(m[1]) : 2));
    r.take(/(?:清除|净化)(?:我方全体|自己)(?:所有)?(?:异常|不良)状态|清除自己烧伤、冰冻、寄生和中毒的状态|并清除自己不良状态|清除所有不良状态/, () => void (e.cure = true));
    r.take(/若对方死亡则自己满状态回复/, () => void (e.healOnKO = 1));
    r.take(/若击败对方，回合结束时回复自己(一半|\d+\/\d+)的?体力值/, (m) => void (e.healOnKO = frac(m[1])));
    r.take(/(?:若对方处于(睡眠|衰弱|烧伤)(?:状态)?，(?:则|可|有)?)?(?:(\d+)%概率)?(?:扣光对方所有技能的PP|扣除(?:睡眠中的)?对方(?:单体)?(?:所有|全部)?(?:技能)?PP(?:值)?(\d+)点|令对方单体所有技能的PP减少(\d+)点|扣除对方全部技能PP(\d+)点|扣除对方所有PP(\d+)点)/, (m) => {
      const n = m[3] ?? m[4] ?? m[5] ?? m[6];
      const c = m[1] ? { foeStatus: statusOf(m[1]) } : /睡眠中的/.test(m[0]) ? { foeStatus: "\u7761\u7720" } : void 0;
      e.ppFoe = { n: n ? num2(n) : "all", chance: pct(m[2]), cond: c };
    });
    r.take(/(?:(\d+)%概率)?(?:令|扣除)?对方(?:单体)?(?:最后使用(?:的)?技能的?)PP(?:值)?(?:减少)?(\d+)点/, (m) => void (e.ppFoe = { n: num2(m[2]), last: true, chance: pct(m[1]) }));
    r.take(/(?:并)?(?:扣除)?(?:对方)?最后使用技能的PP值(\d+)点/, (m) => void (e.ppFoe = { n: num2(m[1]), last: true, chance: 100 }));
    r.take(/(?:(\d+)%概率)?(?:自己)?(?:增加|回复|恢复)(?:自己|我方全体亚比)?(?:所有)?(?:技能)?PP值?(\d+)点/, (m) => void (e.ppSelf = num2(m[2])));
    r.take(/我方全体亚比回复PP值(\d+)点/, (m) => void (e.ppSelf = num2(m[1])));
    r.take(/(?:消耗|额外消耗)(?:自己|自身)?(?:所有|全部)(?:技能)?PP值?(?:(\d+)点)?/, (m) => m[1] ? void (e.ppSelf = -num2(m[1])) : void (e.ppSelfAll = true));
    r.take(/如果对方睡眠，则清除对方上次使用的技能的全部PP/, () => void (e.ppFoe = { n: "all", last: true, chance: 100, cond: { foeStatus: "\u7761\u7720" } }));
    r.take(/(?:令)?(?:自身|自己)束缚(\d+)回合/, () => void 0);
    r.take(/令对方衰弱，对方损失的体力值会逐渐增加/, () => void e.statuses.push({ name: "\u8870\u5F31", chance: 100 }));
    r.take(/(?:如果对方攻击自己，)?有(\d+)%概率也陷入睡眠/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 3, chance: num2(m[1]), status: "\u7761\u7720" }));
    r.take(/(?:(\d+)%概率)?(?:令)?(?:自己|自身)(?:陷入|处于)?(混乱|睡眠|麻痹)/, (m) => void e.statuses.push({ name: statusOf(m[2]), chance: pct(m[1]), self: true }));
    r.take(/(\d+)%概率(混乱)自己/, (m) => void e.statuses.push({ name: "\u6DF7\u4E71", chance: num2(m[1]), self: true }));
    r.take(/(?:之后)?自己陷入混乱|命中后自己(?:陷入)?混乱/, () => void (e.selfConfuse = true));
    r.take(/(?:(\d+)%概率|一定概率)?(?:令|使)?对方(?:单体|全体|全场)?(?:处于)?(?:任意一种|各种)(?:不良|异常|不良或异常)状态/, (m) => {
      const chance = m[1] ? num2(m[1]) : 30;
      for (const s of BAD_STATUSES) e.statuses.push({ name: s, chance: chance / BAD_STATUSES.length });
    });
    r.take(new RegExp(`(\\d+)%\u6982\u7387\u4EE4\u5BF9\u65B9(?:\u5355\u4F53)?(${ST})\u6216(${ST})`), (m) => {
      e.statuses.push({ name: statusOf(m[2]), chance: num2(m[1]) / 2 }, { name: statusOf(m[3]), chance: num2(m[1]) / 2 });
    });
    r.take(/附加一定概率的(中毒)、(冰冻)或者(烧伤)/, (m) => {
      for (const s of [m[1], m[2], m[3]]) e.statuses.push({ name: statusOf(s), chance: 10 });
    });
    r.take(new RegExp(`(?:(\\d+)%(?:\u7684)?(?:\u6982\u7387)?|\u4E00\u5B9A\u6982\u7387|\u5FC5\u5B9A|\u547D\u4E2D\u5219)?(?:\u4EE4|\u4F7F|\u8BA9)?(?:\u5BF9\u65B9)?(?:\u5355\u4F53|\u5168\u4F53|\u5168\u573A)?(?:\u5904\u4E8E|\u8FDB\u5165|\u9677\u5165)?(${ST})(?:\u72B6\u6001)?(?:\u5BF9\u65B9)?(?:\u5355\u4F53)?(?:(\\d+)~(\\d+)\u56DE\u5408|(\\d+)\u56DE\u5408)?`), (m) => {
      const before = r.d.slice(Math.max(0, m.index - 3), m.index);
      if (/若|处|被|疫|除|化|于$/.test(before) && !m[1]) return false;
      const name = statusOf(m[2]);
      const turns = m[3] ? [num2(m[3]), num2(m[4])] : m[5] ? [num2(m[5]), num2(m[5])] : void 0;
      const chance = m[1] ? num2(m[1]) : /一定概率/.test(m[0]) ? 30 : 100;
      e.statuses.push({ name, chance, ...turns ? { turns } : {} });
    });
    r.take(/(?:30%概率)?令对方停止行动(\d+)(?:~(\d+))?回合/, (m) => void e.statuses.push({ name: "\u5BB3\u6015", chance: /30%/.test(m[0]) ? 30 : 100, turns: [num2(m[1]), num2(m[2] || m[1])] }));
    r.take(/(\d+)%概率令对方停止行动1回合/, (m) => void e.statuses.push({ name: "\u5BB3\u6015", chance: num2(m[1]) }));
    r.take(/能令对方惊醒/, () => void 0);
    r.take(/一定概率麻痹对方单体，自己剩余体力值越少概率越高/, () => void e.statuses.push({ name: "\u9EBB\u75F9", chance: 30 }));
    r.take(/自己体力值越低，睡眠成功率越高/, () => void e.statuses.push({ name: "\u7761\u7720", chance: 60 }));
    r.take(/(?:(\d+)%概率)?(?:清除|消除|清空)对方(?:单体|全体)?(?:所有能力的|提升的|增益)?(防御和特防|攻击和特攻|防御|特防|攻击)?(?:提升)?(?:的)?(?:属性能力|能力|属性)?(?:等级|能力效果)(?:效果)?/, (m) => {
      const stats = m[2] ? statsOf2(m[2]) : void 0;
      e.clearFoeUps = { chance: pct(m[1]), stats };
    });
    r.take(/(?:(\d+)%概率)?(?:恢复|回复|清除)(?:自己|我方全体)被削弱的(?:属性)?(?:能力)?等级/, (m) => void (e.restoreOwn = { chance: pct(m[1]) }));
    r.take(/将对方属性等级重置为0/, () => void (e.resetFoe = true));
    r.take(/将自己的能力等级重置为0/, () => void (e.resetSelf = true));
    r.take(/交换(?:双方|敌我双方)的?(?:属性)?能力(?:的)?等级/, () => void (e.swapStages = true));
    r.take(/(?:(\d+)%概率)?复制对方(?:提升的)?(?:能力等级|属性)(?:给自己)?/, (m) => void (e.copyFoeUps = { chance: pct(m[1]) }));
    r.take(/将自己被削弱的(?:属性)?能力等级转移给对方/, () => void (e.passDowns = true));
    r.take(/将对方(攻击和命中)的等级各1级转化给自己/, (m) => void (e.stealStages = { stats: statsOf2(m[1]), delta: 1 }));
    r.take(/令对方单体(防御|特防)值减半/, (m) => void e.stages.push({ self: false, stats: statsOf2(m[1]), delta: -2, chance: 100 }));
    r.take(/随机提升自己任意(\d+)种属性能力等级(\d+)级/, (m) => void e.stages.push({ self: true, stats: ALL_STATS, delta: num2(m[2]), chance: 100, pick: [num2(m[1]), num2(m[1])] }));
    r.take(/随机提升自己(特攻和速度)各(\d+)~(\d+)级/, (m) => void e.stages.push({ self: true, stats: statsOf2(m[1]), delta: num2(m[2]), deltaMax: num2(m[3]), chance: 100 }));
    r.take(/(?:(\d+)%概率)?削弱对方(?:单体)?(?:攻击、特攻、防御和特防中的)?任意(\d+)(?:~(\d+))?种属性(\d+)级/, (m) => void e.stages.push({ self: false, stats: m[0].includes("\u653B\u51FB\u3001\u7279\u653B") ? ["atk", "satk", "def", "sdef"] : ALL_STATS, delta: -num2(m[4]), chance: pct(m[1]), pick: [num2(m[2]), num2(m[3] || m[2])] }));
    r.take(/(\d+)%概率提升自己速度等级(\d+)~(\d+)级/, (m) => void e.stages.push({ self: true, stats: ["spd"], delta: num2(m[2]), deltaMax: num2(m[3]), chance: num2(m[1]) }));
    r.take(/(?:削弱|降低)双方的(防御|特防)等级(\d+)级/, (m) => {
      e.stages.push({ self: false, stats: statsOf2(m[1]), delta: -num2(m[2]), chance: 100 });
      e.stages.push({ self: true, stats: statsOf2(m[1]), delta: -num2(m[2]), chance: 100 });
    });
    r.take(/(?:削弱|降低)全场(?:亚比)?(命中)等级(\d+)级/, (m) => {
      e.stages.push({ self: false, stats: statsOf2(m[1]), delta: -num2(m[2]), chance: 100 });
      e.stages.push({ self: true, stats: statsOf2(m[1]), delta: -num2(m[2]), chance: 100 });
    });
    {
      let lastSelf;
      let lastUp;
      let lastChance;
      const stageRe = new RegExp(
        `(?:(\\d+)%\u6982\u7387|(\\d+)\\/(\\d+)\u6982\u7387|(\u4E00\u5B9A\u6982\u7387))?(?:\u4EE4)?(\u63D0\u5347|\u524A\u5F31|\u964D\u4F4E|\u63D0\u9AD8|\u589E\u52A0|\u524A\u51CF)?(\u81EA\u5DF1|\u81EA\u8EAB|\u5BF9\u65B9\u5355\u4F53|\u5BF9\u65B9\u5168\u4F53|\u5BF9\u65B9|\u5176|\u6211\u65B9\u5168\u4F53|\u5168\u573A)?\u7684?(${STAT_LIST})(?:\u7684)?(?:\u7B49\u7EA7)?(?:\u5404)?(\u4E0B\u964D|\u63D0\u5347|\u4E0A\u5347|\u524A\u5F31)?(\\d+)(?:~(\\d+))?\u7EA7`
      );
      r.take(stageRe, (m) => {
        const [, p1, p2, p3, some, verb, who, list, after, n, nMax] = m;
        if (!verb && !after && lastUp === void 0) return false;
        const up = verb ? verb !== "\u524A\u5F31" && verb !== "\u964D\u4F4E" && verb !== "\u524A\u51CF" : after ? after !== "\u4E0B\u964D" && after !== "\u524A\u5F31" : lastUp;
        const self = who ? who === "\u81EA\u5DF1" || who === "\u81EA\u8EAB" || who === "\u6211\u65B9\u5168\u4F53" : lastSelf ?? up;
        const chance = p1 ? num2(p1) : p2 ? num2(p2) * 100 / num2(p3) : some ? 30 : lastChance ?? 100;
        e.stages.push({ self, stats: statsOf2(list), delta: (up ? 1 : -1) * num2(n), chance, ...nMax ? { deltaMax: num2(nMax) } : {} });
        lastSelf = self;
        lastUp = up;
        if (p1 || p2 || some) lastChance = chance;
      });
    }
    r.take(/将其增加到自身/, () => {
      const down = e.stages.find((s) => !s.self && s.delta < 0);
      if (down) e.stages.push({ self: true, stats: down.stats, delta: -down.delta, chance: down.chance });
    });
    e.status = e.statuses.find((s) => !s.self && !s.cond);
    return { fx: e, unread: r.unread() };
  }

  // server/src/game/sfs2013/duel.ts
  var CHOOSE_MS = 45e3;
  var DUEL_INVITE_MS = 6e4;
  function fresh(p, t) {
    const c = structuredClone(p);
    delete c.buff;
    c.hp = statsOf(c, t)[0];
    for (const s of c.skills) s.pp = s.max;
    return c;
  }
  var SLOT_FIELDS = ["reqSId", "tarSId", "slotId", "locaId"];
  function installDuels(world, deps) {
    const invites = /* @__PURE__ */ new Map();
    const lastAsk = /* @__PURE__ */ new Map();
    const sideOf = (d, id) => d.sides[0].id === id ? 0 : 1;
    const fighterOf = (d, i) => i === 0 ? d.canon.mine : d.canon.wild;
    const engine = (t) => new BattleEngine(t, deps.rng);
    const viewsFor = (d, i, e) => {
      const s = d.sides[i];
      const b = i === 0 ? d.canon : { ...d.canon, mine: d.canon.wild, wild: d.canon.mine };
      return [e.view(b, 0, s.pets, s.owner), e.view(b, 1, s.pets, s.owner)];
    };
    const asSide = (d, i, e, [cmd, body]) => {
      const out = { ...body };
      if (i === 1) {
        for (const k of SLOT_FIELDS) if (out[k] === 0 || out[k] === 1) out[k] = 1 - out[k];
      }
      if ("pmmList" in out) out.pmmList = viewsFor(d, i, e);
      return [cmd, out];
    };
    const sendTo = (d, i, msgs) => {
      const s = d.sides[i];
      if (s.session.closed) return;
      for (const [cmd, body] of msgs) world.push(s.session, cmd, body);
    };
    const both = (d, e, out, m) => {
      out[0].push(asSide(d, 0, e, m));
      out[1].push(asSide(d, 1, e, m));
    };
    const notice = (d, i, e, desc) => ["2421", { slotId: 0, hpInc: 0, desc, pmmList: viewsFor(d, i, e) }];
    const end = (d, e, winner, out, why = "") => {
      d.over = true;
      d.canon.over = true;
      if (d.timer) clearTimeout(d.timer);
      for (const i of [0, 1]) {
        const won = winner === i;
        const desc = why || (winner === null ? "\u5E73\u5C40\uFF01" : won ? "\u6218\u6597\u80DC\u5229\uFF01" : "\u6218\u6597\u5931\u8D25\uFF01");
        out[i].push(["2403", { isWin: won, pvp: true, raceId: 0, id: 0, myFinalRaceId: fighterOf(d, i).pet.race, desc, pmmList: viewsFor(d, i, e) }]);
        if (deps.battles.get(d.sides[i].id) === d.canon) deps.battles.delete(d.sides[i].id);
      }
    };
    const healthy = (s, but) => s.pets.filter((p) => p.hp > 0 && p !== but);
    const doSwitch = (d, i, pid, t, e, out, forced, why = "") => {
      const s = d.sides[i];
      const next = s.pets.find((p) => p.id === pid);
      if (!next || next.hp <= 0 || next === fighterOf(d, i).pet) return false;
      const f = fighter(i, next, s.id, t);
      if (i === 0) d.canon.mine = f;
      else d.canon.wild = f;
      s.must = false;
      const name = next.nick || nameOf(t, next.race);
      const pre = why ? why + "\n" : "";
      out[i].push(["2413", { playerInfo: viewsFor(d, i, e)[0], extInfo: { desc: `${pre}\u5C31\u51B3\u5B9A\u662F\u4F60\u4E86\uFF0C${name}\uFF01`, res: 1, forced } }]);
      out[1 - i].push(["2413", { playerInfo: viewsFor(d, 1 - i, e)[1], extInfo: { desc: `${pre}${s.name}\u6D3E\u51FA\u4E86${name}\uFF01`, res: 1, forced: true, foe: true } }]);
      return true;
    };
    const flush = (d, out) => {
      sendTo(d, 0, out[0]);
      sendTo(d, 1, out[1]);
    };
    const failed = (d, err) => {
      console.error(`[duel] ${d.sides[0].name} / ${d.sides[1].name}: ${err?.stack ?? String(err)}`);
      d.over = true;
      d.canon.over = true;
      if (d.timer) clearTimeout(d.timer);
      for (const s of d.sides) if (deps.battles.get(s.id) === d.canon) deps.battles.delete(s.id);
      try {
        const msg = ["2403", { isWin: false, pvp: true, raceId: 0, id: 0, myFinalRaceId: 0, desc: "\u5BF9\u6218\u51FA\u9519\u4E86\uFF0C\u6CA1\u6709\u7ED3\u679C\u3002", pmmList: [] }];
        flush(d, [[msg], [msg]]);
      } catch {
      }
    };
    const safely = (d, run) => void run.catch((err) => failed(d, err));
    const arm = (d) => {
      if (d.timer) clearTimeout(d.timer);
      d.timer = setTimeout(() => safely(d, timeUp(d)), CHOOSE_MS);
    };
    const timeUp = async (d) => {
      if (d.over) return;
      const t = await deps.tables();
      for (const i of [0, 1]) {
        const s = d.sides[i];
        if (s.choice) continue;
        if (s.must) {
          const next = healthy(s)[0];
          if (next) s.choice = { kind: "switch", pid: next.id };
        } else if (!d.sides.some((x) => x.must)) {
          const first = fighterOf(d, i).pet.skills.find((k) => k.pp > 0);
          s.choice = first ? { kind: "skill", id: first.id } : { kind: "wait" };
        }
      }
      step(d, t);
    };
    const step = (d, t) => {
      if (d.over) return;
      const e = engine(t);
      const out = [[], []];
      if (d.sides.some((s) => s.must)) {
        if (d.sides.some((s) => s.must && !s.choice)) return;
        for (const i of [0, 1]) {
          const c = d.sides[i].choice;
          d.sides[i].choice = void 0;
          if (d.sides[i].must && c?.kind === "switch") doSwitch(d, i, c.pid, t, e, out, true);
        }
        nextTurn(d, e, out);
        flush(d, out);
        return;
      }
      if (!d.sides[0].choice || !d.sides[1].choice) return;
      const [c0, c1] = [d.sides[0].choice, d.sides[1].choice];
      d.sides[0].choice = d.sides[1].choice = void 0;
      if (c0.kind === "switch") doSwitch(d, 0, c0.pid, t, e, out, false);
      if (c1.kind === "switch") doSwitch(d, 1, c1.pid, t, e, out, false);
      e.startTurn(d.canon);
      const skillOf2 = (i, c) => {
        const f = fighterOf(d, i);
        if (c.kind === "wait" && e.forcedOf(f) !== void 0) return e.forcedOf(f);
        if (c.kind !== "skill") return -1;
        const usable = f.pet.skills.filter((k) => k.pp > 0);
        if (!usable.length && e.forcedOf(f) === void 0) return -1;
        return e.choice(f, usable.find((k) => k.id === c.id) ? c.id : usable[0].id);
      };
      const s0 = skillOf2(0, c0), s1 = skillOf2(1, c1);
      for (const [i, si, c] of [[0, s0, c0], [1, s1, c1]]) {
        if (si >= 0 || c.kind === "switch") continue;
        const pet = fighterOf(d, i).pet;
        const name = pet.nick || nameOf(t, pet.race);
        const out_ = pet.skills.every((k) => k.pp <= 0) ? `${name}\u7684\u6280\u80FD\u6B21\u6570\u7528\u5B8C\u4E86\uFF0C\u4EC0\u4E48\u4E5F\u6CA1\u6709\u505A\u3002` : `${name}\u4EC0\u4E48\u4E5F\u6CA1\u6709\u505A\u3002`;
        both(d, e, out, ["2421", { slotId: i, hpInc: 0, desc: out_, pmmList: [] }]);
      }
      const acts = [];
      if (s0 >= 0 && s1 >= 0) {
        const first = e.firstMover(d.canon, s0, s1);
        const second = first === d.canon.mine ? d.canon.wild : d.canon.mine;
        acts.push([first, second, first === d.canon.mine ? s0 : s1], [second, first, second === d.canon.mine ? s0 : s1]);
      } else if (s0 >= 0) acts.push([d.canon.mine, d.canon.wild, s0]);
      else if (s1 >= 0) acts.push([d.canon.wild, d.canon.mine, s1]);
      for (const [att, def, id] of acts) {
        if (att.pet.hp <= 0 || def.pet.hp <= 0) break;
        both(d, e, out, e.act(d.canon, att, def, id));
      }
      const forced = d.canon.forceOut;
      d.canon.forceOut = void 0;
      if (forced !== void 0 && fighterOf(d, forced).pet.hp > 0) {
        const gone = fighterOf(d, forced).pet;
        const others = healthy(d.sides[forced], gone);
        if (others.length) {
          const next = others[Math.floor((deps.rng ?? Math.random)() * others.length)];
          doSwitch(d, forced, next.id, t, e, out, false, `${gone.nick || nameOf(t, gone.race)}\u88AB\u5F3A\u5236\u66FF\u6362\u4E0B\u573A\uFF01`);
        }
      }
      if (d.canon.mine.pet.hp > 0 && d.canon.wild.pet.hp > 0) for (const m of e.endOfTurn(d.canon)) both(d, e, out, m);
      const down = [0, 1].filter((i) => fighterOf(d, i).pet.hp <= 0);
      const out0 = down.filter((i) => healthy(d.sides[i]).length === 0);
      if (out0.length) {
        end(d, e, out0.length === 2 ? null : 1 - out0[0], out);
        flush(d, out);
        return;
      }
      if (down.length) {
        for (const i of down) {
          d.sides[i].must = true;
          out[i].push(["2422", { slotId: 0, desc: "\u8BF7\u9009\u62E9\u4E0B\u4E00\u53EA\u51FA\u6218\u7684\u4E9A\u6BD4\u3002", pmmList: viewsFor(d, i, e) }]);
        }
        for (const i of [0, 1]) if (!down.includes(i)) out[i].push(notice(d, i, e, `\u7B49\u5F85${d.sides[1 - i].name}\u2026\u2026`));
        arm(d);
        flush(d, out);
        return;
      }
      nextTurn(d, e, out);
      flush(d, out);
    };
    const nextTurn = (d, e, out) => {
      d.canon.turn++;
      for (const i of [0, 1]) out[i].push(["2402", { turn: d.canon.turn, pmmList: viewsFor(d, i, e) }]);
      arm(d);
    };
    const giveUp = async (d, i) => {
      if (d.over) return;
      const e = engine(await deps.tables());
      const out = [[], []];
      out[i].push(["2414", { reqSId: 0, isEscape: true, raceId: 0, desc: "\u8BA4\u8F93\u4E86\u3002" }]);
      end(d, e, 1 - i, out, "");
      out[i] = out[i].filter(([c]) => c !== "2403");
      out[1 - i] = out[1 - i].map(([c, b]) => c === "2403" ? [c, { ...b, desc: `${d.sides[i].name}\u8BA4\u8F93\u4E86\u3002` }] : [c, b]);
      flush(d, out);
    };
    world.onLeaveGame?.((s) => {
      const p = world.player(s);
      if (!p) return;
      invites.delete(p.name);
      const b = deps.battles.get(p.id);
      const d = b?.duel;
      if (d && !d.over) safely(d, giveUp(d, sideOf(d, p.id)));
    });
    const fighting = (id) => {
      const b = deps.battles.get(id);
      return !!b && !b.over;
    };
    world.xt("PocketMonsterExtension.revival_duel_invite", async (ctx) => {
      const reply = (res, msg) => ctx.reply({ res, msg }, "revival_duel_invite");
      const me = ctx.player.name;
      const name = String(ctx.params.name ?? "").trim();
      const s = world.online(name);
      const other = s ? world.player(s) : void 0;
      if (!name || name === me) return reply(0, "\u4E0D\u80FD\u548C\u81EA\u5DF1\u5BF9\u6218\u54E6\u3002");
      if (!other) return reply(0, `${name}\u73B0\u5728\u4E0D\u5728\u5965\u62C9\u661F\u4E0A\u3002`);
      if (other.room?.name !== ctx.player.room?.name) return reply(0, `\u8981\u548C${name}\u5728\u540C\u4E00\u4E2A\u5730\u65B9\u624D\u80FD\u5BF9\u6218\u54E6\u3002`);
      if (fighting(ctx.player.id)) return reply(0, "\u4F60\u6B63\u5728\u6218\u6597\u4E2D\u3002");
      if (fighting(other.id)) return reply(0, `${name}\u6B63\u5728\u6218\u6597\u4E2D\uFF0C\u7B49\u4E00\u4E0B\u518D\u9080\u8BF7\u5427\u3002`);
      const o = await deps.load(ctx);
      if (!(o.pets ?? []).some((p) => p.hp > 0)) return reply(0, "\u4F60\u7684\u4E9A\u6BD4\u90FD\u5F88\u865A\u5F31\uFF0C\u5148\u53BB\u6CBB\u7597\u5B83\u4EEC\u5427\uFF01");
      const k = `${me}\0${name}`;
      if (Date.now() - (lastAsk.get(k) ?? -Infinity) < 1e4) return reply(0, "\u521A\u521A\u5DF2\u7ECF\u9080\u8BF7\u8FC7\u4E86\uFF0C\u7B49\u5BF9\u65B9\u56DE\u7B54\u5427\u3002");
      if (lastAsk.size > 1e4) lastAsk.clear();
      lastAsk.set(k, Date.now());
      let mine = invites.get(name);
      if (!mine) invites.set(name, mine = /* @__PURE__ */ new Map());
      mine.set(me, Date.now());
      world.push(s, "revival_duel_ask", { from: me });
      reply(1, `\u5DF2\u7ECF\u9080\u8BF7${name}\u8FDB\u884C\u4E9A\u6BD4\u5BF9\u6218\uFF0C\u7B49\u5F85\u5BF9\u65B9\u540C\u610F\u3002`);
    });
    world.xt("PocketMonsterExtension.revival_duel_answer", async (ctx) => {
      const me = ctx.player.name;
      const from = String(ctx.params.from ?? "");
      const at = invites.get(me)?.get(from);
      invites.get(me)?.delete(from);
      const fs = world.online(from);
      const fp = fs ? world.player(fs) : void 0;
      const said = (msg) => fs && world.push(fs, "revival_duel_said", { msg });
      const ok = ctx.params.ok === true || ctx.params.ok === 1 || ctx.params.ok === "1" || ctx.params.ok === "true";
      if (at == null || Date.now() - at > DUEL_INVITE_MS) return ctx.reply({ res: 0, msg: "\u8FD9\u4E2A\u9080\u8BF7\u5DF2\u7ECF\u8FC7\u671F\u4E86\u3002" }, "revival_duel_answer");
      if (!ok) {
        said(`${me}\u62D2\u7EDD\u4E86\u4F60\u7684\u5BF9\u6218\u9080\u8BF7\u3002`);
        return ctx.reply({ res: 1, msg: "" }, "revival_duel_answer");
      }
      if (!fp || !fs) return ctx.reply({ res: 0, msg: `${from}\u5DF2\u7ECF\u79BB\u5F00\u4E86\u3002` }, "revival_duel_answer");
      if (fighting(fp.id) || fighting(ctx.player.id)) {
        said(`${me}\u6B63\u5728\u6218\u6597\u4E2D\uFF0C\u5BF9\u6218\u6CA1\u6709\u5F00\u59CB\u3002`);
        return ctx.reply({ res: 0, msg: "\u73B0\u5728\u4E0D\u80FD\u5F00\u59CB\u5BF9\u6218\u3002" }, "revival_duel_answer");
      }
      const [a, b] = [await deps.find(from), await deps.load(ctx)];
      const t = await deps.tables();
      if (!a || !b) return ctx.reply({ res: 0, msg: "\u73B0\u5728\u4E0D\u80FD\u5F00\u59CB\u5BF9\u6218\u3002" }, "revival_duel_answer");
      const bagA = (a.pets ?? []).filter((p) => p.hp > 0).map((p) => fresh(p, t));
      const bagB = (b.pets ?? []).filter((p) => p.hp > 0).map((p) => fresh(p, t));
      if (!bagA.length || !bagB.length) {
        said("\u6709\u4E00\u65B9\u7684\u4E9A\u6BD4\u90FD\u5F88\u865A\u5F31\uFF0C\u5BF9\u6218\u6CA1\u6709\u5F00\u59CB\u3002");
        return ctx.reply({ res: 0, msg: "\u6709\u4E00\u65B9\u7684\u4E9A\u6BD4\u90FD\u5F88\u865A\u5F31\uFF0C\u5BF9\u6218\u6CA1\u6709\u5F00\u59CB\u3002" }, "revival_duel_answer");
      }
      ctx.reply({ res: 1, msg: "" }, "revival_duel_answer");
      const e = engine(t);
      const canon = e.start(deps.nextId(), sceneOfRoom(ctx.player.room), a, bagA[0], bagB[0], false);
      canon.wild = fighter(1, bagB[0], b.id, t);
      const d = {
        canon,
        sides: [
          { id: a.id, name: from, session: fs, owner: a, pets: bagA, must: false },
          { id: b.id, name: me, session: ctx.session, owner: b, pets: bagB, must: false }
        ],
        over: false
      };
      canon.duel = d;
      deps.battles.set(a.id, canon);
      deps.battles.set(b.id, canon);
      for (const i of [0, 1]) {
        sendTo(d, i, [
          ["2303", { esc: true, sw: true, ch: false, cd: 1, pvp: { vs: d.sides[1 - i].name }, pmmList: viewsFor(d, i, e) }],
          ["2401", { id: canon.id, type: 0, pt: 0, bs: "", srt: 0, scene: canon.room, boss: 0, pvp: true }]
        ]);
      }
      arm(d);
    });
    const command = async (name, ctx, b) => {
      const d = b.duel;
      const i = sideOf(d, ctx.player.id);
      const s = d.sides[i];
      const t = await deps.tables();
      const e = engine(t);
      const me = (msgs) => sendTo(d, i, msgs);
      if (d.over) return me([["2414", { msg: "\u6218\u6597\u5DF2\u7ECF\u7ED3\u675F\u4E86" }]]);
      if (name === "1404") return giveUp(d, i);
      if (name === "1402") return me([["2412", { reqSId: 0, itemId: Number(ctx.params.itemId), res: -1, refused: true, desc: "\u5BF9\u6218\u4E2D\u4E0D\u80FD\u4F7F\u7528\u9053\u5177\u3002", pmmList: viewsFor(d, i, e) }]]);
      if (name === "1405") return me([["2415", { reqId: s.id, tarSId: 1, itemId: Number(ctx.params.itemId), pmId: 0, lv: 0, lc: 0, refused: true, desc: "\u4E0D\u80FD\u6355\u6349\u522B\u4EBA\u7684\u4E9A\u6BD4\uFF01" }]]);
      if (name === "1403") {
        const pid = Number(ctx.params.pmId);
        const next = s.pets.find((p) => p.id === pid);
        const mustOther = d.sides[1 - i].must;
        if (!next || next.hp <= 0 || next === fighterOf(d, i).pet || s.choice || mustOther && !s.must) {
          return me([["2413", { playerInfo: viewsFor(d, i, e)[0], extInfo: { desc: "\u8FD9\u53EA\u4E9A\u6BD4\u73B0\u5728\u4E0D\u80FD\u51FA\u6218\u3002", res: -1, refused: true } }]]);
        }
        const cur = fighterOf(d, i);
        if (!s.must && cur.trapped > 0) {
          return me([["2413", { playerInfo: viewsFor(d, i, e)[0], extInfo: { desc: `${cur.pet.nick || nameOf(t, cur.pet.race)}\u65E0\u6CD5\u66FF\u6362\uFF01`, res: -1, refused: true } }]]);
        }
        s.choice = { kind: "switch", pid };
      } else if (name === "1401" || name === "1406") {
        if (s.must) return me([["2422", { slotId: 0, desc: "\u8BF7\u9009\u62E9\u4E0B\u4E00\u53EA\u51FA\u6218\u7684\u4E9A\u6BD4\u3002", pmmList: viewsFor(d, i, e) }]]);
        if (s.choice || d.sides[1 - i].must) return;
        s.choice = name === "1401" ? { kind: "skill", id: Number(ctx.params.skillId) } : { kind: "wait" };
      } else return;
      const waiting = d.sides.some((x) => x.must) ? d.sides.some((x) => x.must && !x.choice) : !d.sides[1 - i].choice;
      if (waiting) me([notice(d, i, e, `\u7B49\u5F85${d.sides[1 - i].name}\u2026\u2026`)]);
      step(d, t);
    };
    const leave = (b, id) => {
      const d = b.duel;
      if (d && !d.over) safely(d, giveUp(d, sideOf(d, id)));
    };
    return { command, leave };
  }

  // server/src/game/sfs2013/battle.ts
  var fxCache = /* @__PURE__ */ new Map();
  function parseEffects(desc) {
    let fx = fxCache.get(desc);
    if (!fx) {
      fx = readSkill(desc).fx;
      fxCache.set(desc, fx);
    }
    return fx;
  }
  var STAT_LABEL = { atk: "\u653B\u51FB", def: "\u9632\u5FA1", satk: "\u7279\u653B", sdef: "\u7279\u9632", spd: "\u901F\u5EA6", acc: "\u547D\u4E2D", eva: "\u95EA\u907F", crit: "\u66B4\u51FB" };
  var STAT_INDEX = { atk: 1, def: 2, satk: 3, sdef: 4, spd: 5 };
  var ALL_KEYS = ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"];
  var noStages = () => ({ atk: 0, def: 0, satk: 0, sdef: 0, spd: 0, acc: 0, eva: 0, crit: 0 });
  var BUFF_ROUNDS = 20;
  var NOTE = "revival_note";
  function fighter(slot, pet, owner, t) {
    const sp = speciesOf(t, pet.race);
    const stats = statsOf(pet, t);
    let buff;
    if (slot === 0 && pet.buff) {
      buff = { ...pet.buff, until: BUFF_ROUNDS };
      stats[buff.i] += buff.add;
      delete pet.buff;
    }
    return {
      slot,
      pet,
      owner,
      stats,
      buff,
      types: sp ? sp.t : [0, 0],
      stages: noStages(),
      statusLeft: 0,
      sleep: 0,
      confuse: 0,
      bind: 0,
      fear: 0,
      weak: 0,
      seeded: false,
      rest: 0,
      trapped: 0,
      timed: [],
      turn: {},
      uses: {},
      marks: {},
      marked: [],
      baseUp: { n: 0, pct: 0 },
      baseDown: { atk: 0, satk: 0, pct: 0 }
    };
  }
  var stageMult = (s) => s >= 0 ? (2 + s) / 2 : 2 / (2 - s);
  var accMult = (s) => s >= 0 ? (3 + s) / 3 : 3 / (3 - s);
  var clampStage = (s) => Math.max(-6, Math.min(6, s));
  var balOf = (st) => [st.atk, st.def, st.satk, st.sdef, st.spd, st.acc, st.eva, st.crit].map(clampStage).join("#");
  var live = (f, kind) => f.timed.filter((x) => x.kind === kind && x.left > 0);
  function stat(f, k, noUps = false) {
    let base = f.stats[STAT_INDEX[k]] * (1 + f.baseUp.n * f.baseUp.pct / 100);
    if (k === "atk" || k === "satk") base = base * (1 - f.baseDown.pct / 100) - f.baseDown[k];
    let v = Math.max(1, base) * stageMult(noUps ? Math.min(0, f.stages[k]) : f.stages[k]);
    for (const x of live(f, "statmult")) if (x.stats?.includes(k)) v *= x.mult ?? 1;
    if (k === "spd" && f.status === "\u9EBB\u75F9") v /= 2;
    return Math.max(1, v);
  }
  function petName(t, f) {
    return f.pet.nick || nameOf(t, f.pet.race);
  }
  function aimsAtFoe(sk, fx) {
    if (sk.k !== 2) return true;
    return !!(fx.dmg || fx.statuses.some((s) => !s.self) || fx.stages.some((s) => !s.self) || fx.ppFoe || fx.clearFoeUps || fx.resetFoe || fx.swapStages || fx.stealStages || fx.passDowns || fx.passStatus || fx.painSplit || fx.swapHp || fx.endeavor || fx.ohko || fx.ohkoIf || fx.forceSwitch || fx.trap || fx.baseDown || fx.timed.some((x) => x.who === "foe" && x.kind !== "power"));
  }
  function selfOnly(sk) {
    return sk.k === 2 && !aimsAtFoe(sk, parseEffects(sk.d));
  }
  var TRAITS = {
    \u9A6C\u620F\u56E2: (f) => [175, 176, 177].includes(f.pet.race % 1e4),
    \u8D85\u6697\u9ED1: (f) => f.types.includes(30)
  };
  var hasTrait = (f, name) => {
    if (TRAITS[name]) return TRAITS[name](f);
    const attr = ATTRS[name.replace(/系$/, "")];
    return attr !== void 0 && f.types.includes(attr);
  };
  var hpShare = (f) => Math.max(0, f.pet.hp) / Math.max(1, f.stats[0]);
  function hpPower(kind, listed, att, def) {
    const own = hpShare(att);
    if (kind === "foeHigh") return Math.max(2, 240 * hpShare(def));
    if (kind === "high") return Math.max(2, (listed > 1 ? listed : 300) * own);
    if (listed > 1) return listed * (2 - own);
    const steps = [[0.6875, 40], [0.3542, 80], [0.2083, 160], [0.1042, 200], [0.0417, 300]];
    for (const [at, p] of steps) if (own >= at) return p;
    return 400;
  }
  var STRUGGLE = { n: "\u6323\u624E", p: 100, acc: 100, pp: 1, pri: 0, t: -1, k: 0, d: "\u81EA\u5DF1\u627F\u53D7\u4F24\u5BB3\u503C\u76841/4" };
  var markTurns = (d) => {
    const m = d.match(/(\d+)\s*(?:个)?回合/);
    return m ? Number(m[1]) : 99;
  };
  var plain = (n) => n.replace(/[“”"]/g, "");
  var STATUS_WORDS = { \u9EBB\u75F9: "\u9EBB\u75F9\u4E86\uFF01", \u51B0\u51BB: "\u88AB\u51BB\u4F4F\u4E86\uFF01", \u7761\u7720: "\u7761\u7740\u4E86\uFF01", \u70E7\u4F24: "\u88AB\u70E7\u4F24\u4E86\uFF01", \u4E2D\u6BD2: "\u4E2D\u6BD2\u4E86\uFF01" };
  var BattleEngine = class {
    t;
    rng;
    constructor(t, rng = Math.random) {
      this.t = t;
      this.rng = rng;
    }
    chance(p) {
      return p >= 100 || p > 0 && this.rng() * 100 < p;
    }
    int(a, b) {
      return a + Math.floor(this.rng() * (b - a + 1));
    }
    start(id, room, owner, active, wild, canCatch) {
      return {
        id,
        room,
        mine: fighter(0, active, owner.id, this.t),
        wild: fighter(1, wild, 0, this.t),
        turn: 0,
        canCatch,
        mustSwitch: false,
        over: false
      };
    }
    skill(id) {
      return id === 0 ? STRUGGLE : this.t.pm.skills[String(id)] ?? { ...STRUGGLE, n: `\u6280\u80FD${id}`, d: "" };
    }
    /** The wild 亚比's choice: a random skill with PP left. */
    wildChoice(b) {
      const usable = b.wild.pet.skills.filter((s) => s.pp > 0);
      return usable.length ? usable[Math.floor(this.rng() * usable.length)].id : 0;
    }
    /** The skill a fighter uses this turn: the one it gathers power for or keeps using, else its choice. */
    choice(f, id) {
      return this.forcedOf(f) ?? id;
    }
    /** The skill f uses this turn by itself, not chosen (the one it gathers power for or keeps using). */
    forcedOf(f) {
      if (f.charging !== void 0) return f.charging;
      if (f.lock && f.lock.left > 0) return f.lock.id;
      return void 0;
    }
    /**
     * 连续攻击N回合 (lock, rollout), after its use this turn (hit: it landed): the turn counted, the
     * growth of its power for the next one, and after the last what comes then. The HP it healed.
     */
    keepUp(att, fx, id, hit, lines) {
      if (!fx.lock && !fx.rollout) return 0;
      const ro = fx.rollout;
      if (!att.lock || att.lock.id !== id) {
        const turns = fx.lock ? this.int(fx.lock.turns[0], fx.lock.turns[1]) : this.int(ro.min ?? ro.turns, ro.turns);
        att.lock = { id, left: turns - 1, after: fx.lock?.after ?? "none", healF: fx.lock?.healF, boost: 0 };
      } else att.lock.left--;
      if (ro) att.lock.boost = hit || ro.always ? Math.min((att.lock.boost ?? 0) + 1, ro.turns - 1) : 0;
      if (att.lock.left > 0) return 0;
      const after = att.lock.after;
      att.lock = void 0;
      if (after === "confuse" && att.confuse === 0) this.applyStatus(att, "\u6DF7\u4E71", lines);
      if (after === "rest") att.rest = Math.max(att.rest, 1);
      if (after === "heal" && fx.lock?.healF) return this.heal(att, att.stats[0] * fx.lock.healF);
      return 0;
    }
    /** A new turn: what lasted only the last one ends. */
    startTurn(b) {
      b.mine.turn = {};
      b.wild.turn = {};
    }
    other(b, f) {
      return f === b.mine ? b.wild : b.mine;
    }
    has(f, s) {
      if (s === "any") return !!f.status || f.confuse > 0 || f.bind > 0 || f.weak > 0 || f.seeded || f.fear > 0;
      if (s === "\u6DF7\u4E71") return f.confuse > 0;
      if (s === "\u675F\u7F1A") return f.bind > 0;
      if (s === "\u5BB3\u6015") return f.fear > 0;
      if (s === "\u8870\u5F31") return f.weak > 0;
      if (s === "\u5BC4\u751F") return f.seeded;
      return f.status === s;
    }
    /** Does cond hold for att using a skill on def? */
    holds(c, b, att, def, ctx = {}) {
      if (!c) return true;
      const hp = (f) => f.pet.hp / Math.max(1, f.stats[0]);
      if ("foeStatus" in c) return this.has(def, c.foeStatus);
      if ("selfStatus" in c) return c.selfStatus === "any" ? this.has(att, "any") : c.selfStatus.some((s) => this.has(att, s));
      if ("foeHpBelow" in c) return hp(def) < c.foeHpBelow;
      if ("selfHpBelow" in c) return hp(att) < c.selfHpBelow;
      if ("selfHpAbove" in c) return hp(att) > c.selfHpAbove;
      if ("foeHpMore" in c) return def.pet.hp > att.pet.hp;
      if ("foeHpLess" in c) return def.pet.hp < att.pet.hp;
      if ("second" in c) return !att.turn.first;
      if ("faster" in c) return stat(att, "spd") > stat(def, "spd");
      if ("slower" in c) return stat(att, "spd") < stat(def, "spd");
      if ("crit" in c) return !!ctx.crit;
      if ("landed" in c) return !!ctx.landed;
      if ("foeNoDamage" in c) return !def.turn.damaging;
      if ("hurt" in c) return !!att.turn.hurt === c.hurt;
      if ("hitsMultipleOf" in c) return (ctx.hits ?? 0) > 0 && (ctx.hits ?? 0) % c.hitsMultipleOf === 0;
      if ("nine" in c) return (ctx.dmg ?? 0) > 0 && (String(ctx.dmg).includes("9") || (ctx.dmg ?? 0) % 9 === 0);
      if ("mark" in c) return (att.marks[c.mark] ?? -1) >= b.turn;
      if ("chargeUnhurt" in c) return !att.chargeHurt;
      if ("foeMark" in c) return def.marked.includes(c.foeMark);
      return false;
    }
    /** What the heals of this act (or turn end) could not give, by fighter: the 回复 is shown whole. */
    over = /* @__PURE__ */ new Map();
    heal(f, n) {
      const want = Math.max(0, Math.floor(n));
      const h = Math.min(Math.max(0, f.stats[0] - f.pet.hp), want);
      f.pet.hp += h;
      if (want > h) this.over.set(f, (this.over.get(f) ?? 0) + want - h);
      return h;
    }
    /** The part of f's heals the cap kept back, since it was last asked; it is forgotten. */
    overflow(f) {
      const o = this.over.get(f) ?? 0;
      this.over.delete(f);
      return o;
    }
    hurt(f, n) {
      const l = Math.max(0, Math.min(f.pet.hp, Math.floor(n)));
      f.pet.hp -= l;
      return l;
    }
    /** A change of stages; false when it could not be made (guarded, locked, at the limit). */
    stage(f, by, stats, delta, lines, mirrored = false) {
      if (!stats.length || !delta) return false;
      const name = petName(this.t, f);
      if (live(f, "lockStages").length) {
        lines.push(`${name}\u7684\u5C5E\u6027\u7B49\u7EA7\u4E0D\u4F1A\u6539\u53D8\uFF01`);
        return false;
      }
      if (delta < 0 && by !== f && live(f, "guard").length) {
        lines.push(`${name}\u7684\u5C5E\u6027\u7B49\u7EA7\u6CA1\u6709\u88AB\u524A\u5F31\uFF01`);
        return false;
      }
      let moved = false;
      for (const k of stats) {
        const v = clampStage(f.stages[k] + delta);
        if (v !== f.stages[k]) moved = true;
        f.stages[k] = v;
      }
      const label = ALL_KEYS.every((k) => stats.includes(k)) ? "\u5168\u5C5E\u6027" : stats.map((k) => STAT_LABEL[k]).join("\u548C");
      lines.push(moved ? `${name}\u7684${label}${delta > 0 ? "\u63D0\u5347" : "\u4E0B\u964D"}\u4E86\uFF01` : `${name}\u7684${label}\u5DF2\u7ECF\u4E0D\u80FD\u518D${delta > 0 ? "\u63D0\u5347" : "\u4E0B\u964D"}\u4E86\uFF01`);
      const o = this.cur && (this.cur.mine === f ? this.cur.wild : this.cur.mine);
      if (moved && delta > 0 && by === f && !mirrored && o && o !== f && o.pet.hp > 0 && live(o, "mirror").length) this.stage(o, o, stats, delta, lines, true);
      return moved;
    }
    /** The battle being played (for what one fighter's change does to the other). */
    cur;
    /** What a counter used after the blow took off the other this action. */
    countered = 0;
    /** Give f a status (害怕 混乱 束缚 衰弱 寄生 beside the five); false when it does not take. */
    applyStatus(f, s, lines, turns) {
      const name = petName(this.t, f);
      if (f.pet.hp <= 0) return false;
      if (live(f, "nostatus").some((x) => !x.only || x.only.includes(s))) return false;
      const n = turns ? this.int(turns[0], turns[1]) : 0;
      if (s === "\u5BB3\u6015") {
        f.fear = Math.max(f.fear, n || 1);
        lines.push(`${name}\u5BB3\u6015\u4E86\uFF01`);
        return true;
      }
      if (s === "\u6DF7\u4E71") {
        if (f.confuse > 0) return false;
        f.confuse = n || this.int(2, 4);
        lines.push(`${name}\u6DF7\u4E71\u4E86\uFF01`);
        return true;
      }
      if (s === "\u675F\u7F1A") {
        if (f.bind > 0) return false;
        f.bind = n || this.int(4, 5);
        f.trapped = Math.max(f.trapped, f.bind);
        lines.push(`${name}\u88AB\u675F\u7F1A\u4F4F\u4E86\uFF01`);
        return true;
      }
      if (s === "\u8870\u5F31") {
        if (f.weak > 0) return false;
        f.weak = 1;
        f.weakLeft = n;
        lines.push(`${name}\u8870\u5F31\u4E86\uFF01`);
        return true;
      }
      if (s === "\u5BC4\u751F") {
        if (f.seeded || f.types.includes(11)) return false;
        f.seeded = true;
        lines.push(`${name}\u88AB\u5BC4\u751F\u4E86\uFF01`);
        return true;
      }
      if (f.status) return false;
      const immune = { \u70E7\u4F24: 9, \u51B0\u51BB: 14, \u4E2D\u6BD2: 3 };
      if (immune[s] !== void 0 && f.types.includes(immune[s])) return false;
      f.status = s;
      f.statusLeft = s === "\u7761\u7720" ? 0 : n;
      if (s === "\u7761\u7720") f.sleep = n || this.int(2, 4);
      lines.push(`${name}${STATUS_WORDS[s]}`);
      return true;
    }
    /** Take away all of f's statuses. */
    cureAll(f) {
      f.status = void 0;
      f.statusLeft = 0;
      f.sleep = 0;
      f.confuse = 0;
      f.bind = 0;
      f.fear = 0;
      f.weak = 0;
      f.seeded = false;
    }
    /** One 亚比 uses a skill on the other; returns the 2411 report. */
    act(b, att, def, chosen) {
      const t = this.t;
      const lines = [];
      const name = petName(t, att);
      this.cur = b;
      this.countered = 0;
      this.over.clear();
      const skillId = this.choice(att, chosen);
      const sk = this.skill(skillId);
      const fx = parseEffects(sk.d);
      const foeFirst = !!def.turn.moved;
      att.turn.moved = true;
      att.turn.first = !foeFirst;
      att.turn.damaging = sk.k !== 2 || !!fx.dmg;
      const report = (srt, extra = {}) => {
        const shown2 = { ...extra };
        const whole = (key, f) => {
          const o = this.overflow(f);
          if (o > 0) shown2[key] = Number(shown2[key] ?? 0) + o;
        };
        whole("selfHpInc", att);
        if (def !== att) whole("hpInc", def);
        return [
          "2411",
          { reqSId: att.slot, tarSId: def.slot, id: skillId, name: sk.n, k: sk.k, t: sk.t, self: selfOnly(sk), srt, cri: false, hits: 0, hpInc: 0, selfHpInc: 0, eff: 1, ...shown2, desc: lines.join("\n"), pmmList: this.views(b) }
        ];
      };
      const stopped = (why) => {
        att.charging = void 0;
        att.lock = void 0;
        lines.push(why);
        return report(3);
      };
      if (att.rest > 0 && (att.restFrom ?? 0) <= b.turn) {
        att.rest--;
        return stopped(`${name}\u9700\u8981\u4F11\u606F\uFF0C\u65E0\u6CD5\u884C\u52A8\uFF01`);
      }
      if (att.fear > 0) {
        att.fear--;
        return stopped(`${name}\u5BB3\u6015\u5F97\u4E0D\u6562\u884C\u52A8\uFF01`);
      }
      if (att.status === "\u7761\u7720") {
        if (--att.sleep > 0) return stopped(`${name}\u6B63\u5728\u7761\u89C9\u2026\u2026`);
        att.status = void 0;
        lines.push(`${name}\u9192\u8FC7\u6765\u4E86\uFF01`);
      } else if (att.status === "\u51B0\u51BB") {
        if (att.statusLeft > 0 ? --att.statusLeft > 0 : !this.chance(20)) return stopped(`${name}\u88AB\u51BB\u4F4F\u4E86\uFF0C\u65E0\u6CD5\u884C\u52A8\uFF01`);
        att.status = void 0;
        att.statusLeft = 0;
        lines.push(`${name}\u89E3\u51BB\u4E86\uFF01`);
      } else if (att.status === "\u9EBB\u75F9" && this.chance(25)) {
        return stopped(`${name}\u9EBB\u75F9\u4E86\uFF0C\u65E0\u6CD5\u884C\u52A8\uFF01`);
      }
      for (const x of live(att, "noact")) if (this.chance(x.chance ?? 0)) return stopped(`${name}\u65E0\u6CD5\u884C\u52A8\uFF01`);
      if (att.confuse > 0) {
        att.confuse--;
        if (att.confuse === 0) lines.push(`${name}\u4E0D\u518D\u6DF7\u4E71\u4E86\uFF01`);
        else if (this.chance(33)) {
          const dmg2 = Math.max(1, Math.floor(Math.floor(2 * att.pet.level / 5 + 2) * 40 * stat(att, "atk") / stat(att, "def") / 50 + 2));
          att.pet.hp = Math.max(0, att.pet.hp - dmg2);
          att.lock = void 0;
          att.charging = void 0;
          lines.push(`${name}\u5728\u6DF7\u4E71\u4E2D\u653B\u51FB\u4E86\u81EA\u5DF1\uFF01`);
          if (att.pet.hp <= 0) lines.push(`${name}\u5012\u4E0B\u4E86\uFF01`);
          return report(3, { selfHpInc: -dmg2 });
        }
      }
      const known = att.pet.skills.find((s) => s.id === skillId);
      const keptUp = att.lock && att.lock.id === skillId && att.lock.left > 0 || att.charging === skillId;
      if (known && !keptUp) known.pp = Math.max(0, known.pp - (fx.ppCost ?? 1));
      lines.push(`${name}\u4F7F\u7528\u4E86${sk.n}\uFF01`);
      const uses = att.uses[skillId] = (att.uses[skillId] ?? 0) + 1;
      const rolled = att.last === skillId;
      att.last = skillId;
      att.marks[plain(sk.n)] = b.turn + markTurns(sk.d);
      const grow = (p) => fx.grow ? Math.min(100, p * Math.min(3, 1 + (uses - 1) * 0.5)) : p;
      if (fx.charge && att.charging === skillId && (att.chargeLeft ?? 0) > 0) {
        att.chargeLeft--;
        lines.push(`${name}\u6B63\u5728\u84C4\u529B\uFF01`);
        return report(0, { k: 2, self: true });
      }
      if (fx.charge && att.charging === void 0) {
        att.charging = skillId;
        att.chargeLeft = (fx.chargeTurns ?? 1) - 1;
        att.chargeHurt = false;
        lines.push(`${name}\u6B63\u5728\u84C4\u529B\uFF01`);
        this.stagesOf(b, att, def, fx, lines, { hits: 0 });
        if (fx.shield) att.turn.shield = fx.shield;
        this.lasting(b, att, def, fx, lines, plain(sk.n));
        return report(0, { k: 2, self: true });
      }
      const releasing = att.charging === skillId;
      if (releasing) {
        att.charging = void 0;
        att.chargeLeft = void 0;
      }
      if (fx.fade && uses > 1 && !this.chance(100 / 2 ** (uses - 1))) {
        lines.push("\u4F46\u662F\u5931\u8D25\u4E86\u2026\u2026");
        let selfHp2 = 0;
        if (fx.failHeal) selfHp2 = this.heal(att, fx.failHeal);
        return report(1, { selfHpInc: selfHp2 });
      }
      let selfHp = 0;
      const missed = () => {
        if (fx.rollout) selfHp += this.keepUp(att, fx, skillId, false, lines);
        else att.lock = void 0;
      };
      if (fx.selfCost && this.chance(fx.selfCost.chance ?? 100)) {
        const c = fx.selfCost;
        const cost = c.n ?? Math.floor((c.current ? att.pet.hp : att.stats[0]) * (c.f ?? 0));
        selfHp -= this.hurt(att, Math.min(cost, att.pet.hp - 1));
      }
      if (fx.protect && (!fx.protectIfFirst || att.turn.first)) att.turn.protect = true;
      if (fx.shield && !releasing) {
        const sh = fx.shield;
        const taken = sh.kind === "phys" ? att.turn.takenPhys ?? 0 : sh.kind === "spec" ? att.turn.takenSpec ?? 0 : (att.turn.takenPhys ?? 0) + (att.turn.takenSpec ?? 0);
        if (sh.take === 1 && sh.reflect > 0 && taken > 0) {
          if (!sh.ifFirst && def !== att && def.pet.hp > 0) {
            const back = this.hurt(def, taken * sh.reflect);
            lines.push(`${name}\u53CD\u51FB\u4E86${back}\u70B9\u4F24\u5BB3\uFF01`);
            if (def.pet.hp <= 0) lines.push(`${petName(t, def)}\u5012\u4E0B\u4E86\uFF01`);
            this.countered = back;
          }
        } else att.turn.shield = sh;
      }
      if (fx.endure === "revive") att.turn.endure = true;
      if (fx.endure === "reviveOnce") att.revive = true;
      if (fx.destiny) att.turn.destiny = true;
      if (fx.grudge) att.turn.grudge = true;
      if (fx.hold) att.turn.hold = true;
      if (fx.absorbHit) att.turn.absorb = true;
      const aims = aimsAtFoe(sk, fx) && def !== att;
      if (aims && def.pet.hp > 0) {
        const sure = fx.sure || live(att, "sure").length > 0;
        let acc = fx.acc ?? sk.acc;
        if (sk.k === 0) for (const x of live(att, "blind")) acc = Math.min(acc, x.phys ?? 100);
        if (!sure && acc < 101 && this.rng() >= acc / 100 * accMult(att.stages.acc - def.stages.eva)) {
          missed();
          lines.push("\u6CA1\u6709\u547D\u4E2D\uFF01");
          return report(2, { selfHpInc: selfHp });
        }
        if (def.turn.protect && !fx.pierce) {
          missed();
          lines.push(`${petName(t, def)}\u6321\u4F4F\u4E86\u653B\u51FB\uFF01`);
          return report(1, { selfHpInc: selfHp });
        }
      }
      let dmg = 0;
      let shown = 0;
      let cri = false;
      let mult = 1;
      let hits = 0;
      let crits = 0;
      let perHit;
      let foeHeal = 0;
      if (aims && (sk.k !== 2 || fx.dmg || fx.ohko || fx.ohkoIf)) {
        mult = sk.t < 0 ? 1 : typeMultiplier(t.pm, sk.t, def.types);
        if (mult === 0 && !fx.dmg) {
          missed();
          lines.push("\u597D\u50CF\u6CA1\u6709\u6548\u679C\u2026\u2026");
          return report(1, { eff: 0, selfHpInc: selfHp });
        }
        const hit = this.strike(b, att, def, sk, fx, mult, rolled, lines);
        ({ dmg, shown, cri, hits, crits, foeHeal } = hit);
        if (hit.list.length > 1) perHit = { hitDmg: hit.list, hitCri: hit.criList };
        selfHp += hit.selfHp;
        if (hits > 1) lines.splice(lines.length - hit.after, 0, `\u8FDE\u7EED\u653B\u51FB\u4E86${hits}\u6B21\uFF01`);
      }
      const ctx = { crit: cri, crits, dmg: shown, hits, landed: false };
      const drainOnStatus = !!fx.drainCond && "landed" in fx.drainCond;
      if (dmg > 0) {
        let drain = live(att, "drain").reduce((s, x) => s + (x.f ?? 0), 0);
        for (const x of live(att, "drain")) if (x.once) x.left = 0;
        if (fx.drain && !drainOnStatus && this.holds(fx.drainCond, b, att, def, ctx)) drain += fx.drain;
        for (const p of fx.powerIf ?? []) if (p.drain !== void 0 && this.holds(p.cond, b, att, def, ctx)) drain = Math.max(drain, p.drain);
        if (fx.dmgHeals !== void 0) selfHp += this.heal(att, fx.dmgHeals === "all" ? dmg : fx.dmgHeals);
        if (drain > 0) {
          const want = Math.floor(Math.max(1, dmg * drain));
          const h = this.heal(att, want);
          selfHp += h;
          if (h > 0) lines.push(`${name}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
          if (fx.overShield && want > h && att.pet.hp > 0) {
            att.armour = (att.armour ?? 0) + want - h;
            lines.push(`${name}\u83B7\u5F97\u4E86${want - h}\u70B9\u62A4\u76FE\uFF01`);
          }
        }
        if ((fx.recoil || sk === STRUGGLE) && this.chance(fx.recoilChance ?? 100)) {
          const r = Math.max(1, Math.floor(dmg * (fx.recoil ?? 0.25)));
          selfHp -= this.hurt(att, r);
          lines.push(`${name}\u53D7\u5230\u4E86\u53CD\u4F5C\u7528\u4F24\u5BB3\uFF01`);
        }
        if (fx.critHeal && crits) selfHp += this.heal(att, att.stats[0] * fx.critHeal * crits);
      }
      if (aims && fx.ppFoe && this.holds(fx.ppFoe.cond, b, att, def, ctx) && this.chance(fx.ppFoe.chance)) {
        const n = fx.ppFoe.n;
        const which = fx.ppFoe.last ? def.pet.skills.filter((s) => s.id === def.last) : def.pet.skills;
        for (const s of which) s.pp = n === "all" ? 0 : Math.max(0, s.pp - n);
        if (which.length) lines.push(`${petName(t, def)}\u7684\u6280\u80FD\u6B21\u6570\u51CF\u5C11\u4E86\uFF01`);
      }
      if (fx.ppSelfAll) for (const s of att.pet.skills) s.pp = 0;
      if (fx.ppSelf && this.chance(fx.ppSelfChance ?? 100)) {
        for (const s of att.pet.skills) s.pp = Math.max(0, Math.min(s.max, s.pp + fx.ppSelf));
        lines.push(fx.ppSelf > 0 ? `${name}\u7684\u6280\u80FD\u6B21\u6570\u56DE\u590D\u4E86\uFF01` : `${name}\u7684\u6280\u80FD\u6B21\u6570\u51CF\u5C11\u4E86\uFF01`);
      }
      let landed = sk.k !== 2 || dmg > 0;
      const rolls = fx.perHit ? Math.max(1, hits) : 1;
      let statusTried = false;
      let statusLanded = false;
      for (const s of fx.statuses) {
        const target = s.self ? att : def;
        if (!s.self && !aims) continue;
        if (s.cond && !("landed" in s.cond) && !this.holds(s.cond, b, att, def, ctx)) continue;
        if (s.cond && "landed" in s.cond && !statusLanded) continue;
        statusTried = true;
        let chance = s.chance;
        if (s.byLowHp) chance += (100 - chance) * (1 - att.pet.hp / Math.max(1, att.stats[0]));
        if (s.bySpeed) chance += 15 * Math.max(0, att.stages.spd);
        if (s.doubleIf && this.holds(s.doubleIf, b, att, def, ctx)) chance *= 2;
        if (s.condChance && this.holds(s.condChance.cond, b, att, def, ctx)) chance = Math.max(chance, s.condChance.chance);
        chance = grow(chance);
        let ok = false;
        for (let r = 0; r < rolls && !ok; r++) ok = this.chance(chance) && this.applyStatus(target, s.name, lines, s.turns);
        if (ok) {
          statusLanded = true;
          if (s.name === "\u675F\u7F1A" && fx.bindHits && hits > 0) target.bind = target.trapped = hits;
        }
      }
      if (fx.hitStatus && fx.hitStatus[hits]) statusLanded = this.applyStatus(def, fx.hitStatus[hits], lines) || statusLanded;
      ctx.landed = statusLanded;
      landed ||= statusLanded;
      if (statusTried && !statusLanded && sk.k === 2 && !fx.stages.length) lines.push("\u597D\u50CF\u6CA1\u6709\u6548\u679C\u2026\u2026");
      if (statusLanded && drainOnStatus && fx.drain && dmg > 0) selfHp += this.heal(att, dmg * fx.drain);
      if (!releasing && this.stagesOf(b, att, def, fx, lines, ctx, grow, aims)) landed = true;
      let heal = 0;
      const ha = fx.healAfter;
      if (ha && (ha.cond && "landed" in ha.cond ? statusLanded : this.holds(ha.cond, b, att, def, ctx)) && this.chance(ha.chance)) {
        let f = ha.f;
        for (const p of fx.powerIf ?? []) if (p.heal !== void 0 && this.holds(p.cond, b, att, def, ctx)) f = Math.max(f, p.heal);
        heal += this.heal(att, att.stats[0] * f);
      }
      if (fx.healFull) heal += this.heal(att, att.stats[0]);
      if (fx.healFlat && this.chance(fx.healChance ?? 100)) heal += this.heal(att, fx.healFlat);
      if (fx.healLost) heal += this.heal(att, (att.stats[0] - att.pet.hp) * fx.healLost);
      if (fx.healBoth) {
        heal += this.heal(att, att.stats[0] / 4);
        foeHeal += this.heal(def, def.stats[0] / 4);
      }
      if (heal > 0) {
        selfHp += heal;
        lines.push(`${name}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
        landed = true;
      } else if ((fx.healAfter || fx.healFull || fx.healFlat) && sk.k === 2 && !fx.stages.length && !fx.statuses.length) lines.push("\u4F53\u529B\u5DF2\u7ECF\u662F\u6EE1\u7684\u4E86\u3002");
      if (fx.cure && this.has(att, "any")) {
        this.cureAll(att);
        lines.push(`${name}\u7684\u4E0D\u826F\u72B6\u6001\u90FD\u6D88\u9664\u4E86\uFF01`);
        landed = true;
      }
      if (fx.unstatus && att.status === fx.unstatus) {
        att.status = void 0;
        lines.push(`${name}\u7684${fx.unstatus}\u72B6\u6001\u89E3\u9664\u4E86\uFF01`);
      }
      if (fx.sleepAfter && att.pet.hp > 0) {
        att.status = void 0;
        this.applyStatus(att, "\u7761\u7720", lines, [fx.sleepAfter + 1, fx.sleepAfter + 1]);
      }
      if (aims && fx.passStatus && att.status && !def.status) {
        def.status = att.status;
        def.sleep = att.sleep;
        def.statusLeft = att.statusLeft;
        lines.push(`${name}\u628A${att.status}\u8F6C\u79FB\u7ED9\u4E86${petName(t, def)}\uFF01`);
        att.status = void 0;
        att.sleep = att.statusLeft = 0;
      }
      const share = (f) => f.pet.hp / Math.max(1, f.stats[0]);
      if (aims && fx.swapHpRatio && share(att) < share(def) && this.chance(fx.swapHpRatio)) {
        const [a, d] = [share(att), share(def)];
        const before = [att.pet.hp, def.pet.hp];
        att.pet.hp = Math.max(1, Math.round(att.stats[0] * d));
        def.pet.hp = Math.max(1, Math.round(def.stats[0] * a));
        selfHp += att.pet.hp - before[0];
        shown -= def.pet.hp - before[1];
        lines.push("\u53CC\u65B9\u7684\u4F53\u529B\u8C03\u6362\u4E86\uFF01");
      }
      if (aims && fx.painSplit && this.chance(fx.painSplitChance ?? 100) && (fx.painSplitChance === void 0 || def.pet.hp > att.pet.hp)) {
        const avg = Math.floor((att.pet.hp + def.pet.hp) / 2);
        const before = [att.pet.hp, def.pet.hp];
        att.pet.hp = Math.min(att.stats[0], avg);
        def.pet.hp = Math.min(def.stats[0], avg);
        selfHp += att.pet.hp - before[0];
        shown -= def.pet.hp - before[1];
        lines.push("\u53CC\u65B9\u5E73\u5206\u4E86\u4F53\u529B\uFF01");
      }
      if (aims && fx.swapHp) {
        const before = [att.pet.hp, def.pet.hp];
        att.pet.hp = Math.min(att.stats[0], before[1]);
        def.pet.hp = Math.min(def.stats[0], before[0]);
        selfHp += att.pet.hp - before[0];
        shown -= def.pet.hp - before[1];
        lines.push("\u53CC\u65B9\u7684\u4F53\u529B\u8C03\u6362\u4E86\uFF01");
      }
      if (!releasing && this.lasting(b, att, def, fx, lines, plain(sk.n))) landed = true;
      if (aims && fx.trap) def.trapped = Math.max(def.trapped, this.int(fx.trap[0], fx.trap[1]));
      if (aims && fx.forceSwitch && def.pet.hp > 0) {
        if (def.slot === 1 && !b.duel) lines.push("\u597D\u50CF\u6CA1\u6709\u6548\u679C\u2026\u2026");
        else {
          b.forceOut = def.slot;
          landed = true;
        }
      }
      if (fx.trait && !releasing) {
        let any_ = false;
        for (const f of def === att || fx.trait.side === "self" ? [att] : [att, def]) {
          if (f.pet.hp <= 0 || !hasTrait(f, fx.trait.name)) continue;
          any_ = true;
          if (fx.trait.statmult) {
            const m = fx.trait.statmult;
            f.timed = f.timed.filter((x) => !(x.kind === "statmult" && x.trait));
            f.timed.push({ who: "self", kind: "statmult", turns: m.turns, left: m.turns, stats: m.stats, mult: m.mult, trait: true });
            lines.push(`${petName(t, f)}\u7684${m.stats.map((k) => STAT_LABEL[k]).join("\u548C")}\u589E\u52A0\u4E86\uFF01`);
          }
          if (fx.trait.power) {
            f.timed = f.timed.filter((x) => !(x.kind === "power" && x.trait));
            f.timed.push({ who: "self", kind: "power", turns: 99, mult: fx.trait.power, trait: true, left: 99 });
            lines.push(`${petName(t, f)}\u7684\u4F24\u5BB3\u589E\u52A0\u4E86\uFF01`);
          }
          if (fx.trait.stats) {
            const d = fx.trait.deltaMax !== void 0 ? this.int(fx.trait.delta ?? 1, fx.trait.deltaMax) : fx.trait.delta ?? 1;
            this.stage(f, f, fx.trait.stats, d, lines);
          }
        }
        if (any_) landed = true;
        else lines.push("\u597D\u50CF\u6CA1\u6709\u6548\u679C\u2026\u2026");
      }
      if (aims && fx.baseDown) {
        def.baseDown[fx.baseDown.stat] += fx.baseDown.n;
        lines.push(`${petName(t, def)}\u7684${fx.baseDown.stat === "atk" ? "\u653B\u51FB" : "\u7279\u653B"}\u964D\u4F4E\u4E86\uFF01`);
        landed = true;
      }
      if (fx.baseUp && att.baseUp.n < fx.baseUp.max) {
        att.baseUp = { n: att.baseUp.n + 1, pct: fx.baseUp.pct };
        lines.push(`${name}\u7684\u80FD\u529B\u589E\u5F3A\u4E86\uFF01`);
        landed = true;
      }
      if (aims && fx.markFoe && dmg > 0 && !def.marked.includes(fx.markFoe.name)) {
        def.marked.push(fx.markFoe.name);
        def.baseDown.pct = Math.min(90, def.baseDown.pct + fx.markFoe.downPct);
        lines.push(`${petName(t, def)}\u9676\u9189\u4E86\uFF01`);
      }
      if (fx.nextFullHeal || fx.reviveNext) (b.nextHeal ??= [])[att.slot] = true;
      if (fx.recharge && this.chance(fx.rechargeChance ?? 100)) att.rest = Math.max(att.rest, fx.rechargeTurns ?? 1);
      if (fx.eitherStops && aims && dmg > 0 && def.pet.hp > 0 && this.chance(fx.eitherStops)) {
        if (this.rng() < 0.5) {
          if (!this.has(def, "\u9EBB\u75F9")) {
            att.rest = Math.max(att.rest, 1);
            lines.push(`${name}\u4E0B\u56DE\u5408\u505C\u6B62\u884C\u52A8\uFF01`);
          }
        } else if (!this.has(def, "\u5BB3\u6015")) {
          def.rest = Math.max(def.rest, 1);
          def.restFrom = b.turn + 1;
          lines.push(`${petName(t, def)}\u4E0B\u56DE\u5408\u505C\u6B62\u884C\u52A8\uFF01`);
        }
      }
      selfHp += this.keepUp(att, fx, skillId, true, lines);
      if (fx.selfConfuse && att.confuse === 0) this.applyStatus(att, "\u6DF7\u4E71", lines);
      if (fx.sacrifice) att.pet.hp = 0;
      if (fx.bothFaint && aims) {
        shown += def.pet.hp;
        def.pet.hp = 0;
        att.pet.hp = 0;
      }
      if (fx.healOnKO && def.pet.hp <= 0 && att.pet.hp > 0) selfHp += this.heal(att, att.stats[0] * fx.healOnKO);
      if (def.pet.hp <= 0 && def !== att) lines.push(`${petName(t, def)}\u5012\u4E0B\u4E86\uFF01`);
      if (att.pet.hp <= 0) lines.push(`${name}\u5012\u4E0B\u4E86\uFF01`);
      const any = landed || sk.k !== 2 || selfHp !== 0 || fx.timed.length > 0 || !!fx.field || fx.protect || !!fx.shield;
      return report(any || this.countered > 0 ? 0 : 1, { cri, hits, hpInc: -(shown + this.countered) + foeHeal, selfHpInc: selfHp, eff: mult, ...perHit });
    }
    /** The damage of a damaging skill (all its hits) on def, with what def's guards make of it. */
    strike(b, att, def, sk, fx, mult, rolled, lines) {
      const t = this.t;
      const out = { dmg: 0, shown: 0, cri: false, crits: 0, hits: 0, selfHp: 0, foeHeal: 0, after: 0, list: [], criList: [] };
      const mark = lines.length;
      const dn = petName(t, def);
      let n = fx.hits ? this.int(fx.hits[0], fx.hits[1]) : 1;
      for (const x of fx.extraHits ?? []) if (this.chance(x.chance)) n = Math.max(n, x.n);
      if (fx.hitsIf && this.holds(fx.hitsIf.cond, b, att, def)) n = fx.hitsIf.set ?? n + (fx.hitsIf.add ?? 0);
      let fixedDmg = -1;
      if (fx.dmg) {
        if (fx.dmgChance === void 0 || this.chance(fx.dmgChance)) {
          const d = fx.dmg;
          let raw = d.kind === "flat" ? d.n : d.kind === "level" ? att.pet.level * (d.a + this.rng() * (d.b - d.a)) : d.kind === "foeLevel" ? def.pet.level * d.mult : d.kind === "hpFrac" ? def.pet.hp * d.f : d.kind === "maxFrac" ? def.stats[0] * d.f : this.int(d.a, d.b);
          if (fx.dmgByType) raw *= mult > 1 ? 1.5 : mult < 1 ? 0.5 : 1;
          fixedDmg = Math.max(1, Math.floor(raw));
        }
        n = fixedDmg >= 0 ? 1 : 0;
      } else if (sk.k === 2) n = 1;
      let ohko = fx.ohko ?? 0;
      if (ohko && fx.ohkoDoubleIf && this.holds(fx.ohkoDoubleIf, b, att, def)) ohko *= 2;
      if (fx.ohkoIf && this.holds(fx.ohkoIf.cond, b, att, def) && (!fx.ohkoIf.lowerLevel || def.pet.level <= att.pet.level) && (fx.ohkoIf.hpBelow === void 0 || def.pet.hp < fx.ohkoIf.hpBelow)) ohko = Math.max(ohko, fx.ohkoIf.chance);
      if (isGuardian(def.pet.race)) ohko /= 2;
      const ohkoEachHit = !!fx.hits && !!fx.perHit;
      let killed = false;
      const phys = sk.k === 0;
      const spec = sk.k === 1;
      const kindOk = (x) => phys ? x.phys : spec ? x.spec : void 0;
      const sh = fx.pierce ? void 0 : def.turn.shield;
      const shieldOn = !!sh && (!sh.kind || (sh.kind === "phys" ? phys : spec)) && (!sh.ifFirst || !!def.turn.first);
      let reflect = 0;
      let dodged = 0;
      let blocked = 0;
      let soaked = 0;
      let shielded = 0;
      let armoured = 0;
      for (let i = 0; i < n && def.pet.hp > 0 && att.pet.hp > 0; i++) {
        let dmg = 0;
        let hitCri = false;
        if (fixedDmg >= 0) dmg = fixedDmg;
        else if (sk.k !== 2) {
          const r = this.damage(b, att, def, sk, fx, mult, rolled, i, this.rollCrit(b, att, def, fx));
          dmg = r.dmg;
          if (r.cri) {
            out.cri = true;
            out.crits++;
            hitCri = true;
          }
        }
        out.hits++;
        out.list.push(0);
        out.criList.push(hitCri ? 1 : 0);
        if (ohko && !killed && (i === 0 || ohkoEachHit)) {
          if (this.chance(ohko)) {
            killed = true;
            dmg = Math.max(dmg, def.pet.hp);
            lines.push("\u4E00\u51FB\u5FC5\u6740\uFF01");
          }
        }
        if (fx.endeavor) dmg = Math.max(0, def.pet.hp - att.pet.hp);
        if (fx.falseSwipe) dmg = Math.min(dmg, def.pet.hp - 1);
        if (!fx.pierce && live(def, "dodge").some((x) => kindOk(x) !== void 0 && this.chance(kindOk(x)))) {
          dodged++;
          continue;
        }
        if (shieldOn) {
          reflect += dmg * sh.reflect;
          dmg = Math.floor(dmg * sh.take);
          if (sh.take === 0) blocked++;
        }
        for (const x of live(def, "screen")) {
          const f = kindOk(x);
          if (f !== void 0) dmg = Math.floor(dmg * f);
        }
        for (const x of fx.pierce ? [] : live(def, "absorb")) {
          const left = Math.max(0, (x.n ?? 0) - (def.turn.absorbed ?? 0));
          const take = Math.min(left, dmg);
          if (take <= 0) continue;
          dmg -= take;
          def.turn.absorbed = (def.turn.absorbed ?? 0) + take;
          shielded += take;
        }
        if (!fx.pierce && (def.armour ?? 0) > 0 && dmg > 0) {
          const take = Math.min(def.armour, dmg);
          def.armour -= take;
          dmg -= take;
          armoured += take;
        }
        if (dmg > 0 && live(def, "doom").some((x) => this.chance(x.chance ?? 0))) {
          dmg = Math.max(dmg, def.pet.hp);
          lines.push("\u4E00\u51FB\u5FC5\u6740\uFF01");
        }
        if (def.turn.absorb && dmg > 0) {
          out.foeHeal += this.heal(def, dmg);
          soaked++;
          continue;
        }
        if (def.turn.hold) dmg = Math.min(dmg, def.pet.hp - 1);
        out.shown += dmg;
        out.list[out.list.length - 1] = dmg;
        const lost = this.hurt(def, dmg);
        out.dmg += lost;
        if (lost > 0) {
          def.turn.hurt = true;
          if (phys) def.turn.takenPhys = (def.turn.takenPhys ?? 0) + lost;
          if (spec) def.turn.takenSpec = (def.turn.takenSpec ?? 0) + lost;
          if (def.charging !== void 0) def.chargeHurt = true;
        }
        for (const x of live(def, "reflect")) if (lost > 0 || x.n) reflect += x.n ?? lost * (kindOk(x) ?? 0);
        if (def.pet.hp <= 0 && def.turn.endure) {
          def.pet.hp = def.stats[0];
          lines.push(`${dn}\u6EE1\u72B6\u6001\u590D\u6D3B\u4E86\uFF01`);
        } else if (def.pet.hp <= 0 && def.revive) {
          def.revive = false;
          def.pet.hp = def.stats[0];
          lines.push(`${dn}\u6EE1\u72B6\u6001\u590D\u6D3B\u4E86\uFF01`);
        }
        if (lost <= 0) continue;
        if (def.pet.hp > 0) {
          for (const x of live(def, "onhurt")) {
            if (!this.chance(x.chance ?? 100)) continue;
            if (x.stats?.length) this.stage(x.selfStage ? def : att, def, x.stats, x.delta ?? 0, lines);
            if (x.status) {
              const ss = x.bothStatus ? [x.status, x.statusAlt] : [x.statusAlt && this.rng() < 0.5 ? x.statusAlt : x.status];
              for (const st of ss) this.applyStatus(att, st, lines);
            }
            if (x.n) for (const s2 of att.pet.skills) s2.pp = Math.max(0, s2.pp - x.n);
            if (x.once) x.left = 0;
          }
        }
        for (const x of live(att, "hitHeal")) out.selfHp += this.heal(att, x.n ?? 0);
        for (const x of live(att, "onhit")) {
          if (!this.chance(x.chance ?? 0)) continue;
          if (x.n === 1) this.applyStatus(def, "\u5BB3\u6015", lines);
          else if (x.n === 2) for (const k of ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
          else if (x.status) this.applyStatus(def, x.status, lines);
        }
      }
      if (ohko && !killed && fx.ohkoFailFaint) {
        out.selfHp -= this.hurt(att, att.pet.hp);
        lines.push(`${petName(t, att)}\u5012\u4E0B\u4E86\u2026\u2026`);
      }
      if (dodged) lines.push(dodged === out.hits ? `${dn}\u95EA\u907F\u4E86\u653B\u51FB\uFF01` : `${dn}\u95EA\u907F\u4E86${dodged}\u6B21\u653B\u51FB\uFF01`);
      if (blocked) lines.push(`${dn}\u6321\u4F4F\u4E86\u4F24\u5BB3\uFF01`);
      if (shielded) lines.push(`${dn}\u62B5\u6321\u4E86${shielded}\u70B9\u4F24\u5BB3\uFF01`);
      if (armoured) lines.push(`${dn}\u7684\u62A4\u76FE\u62B5\u6321\u4E86${armoured}\u70B9\u4F24\u5BB3\uFF01${def.armour ? "" : `${dn}\u7684\u62A4\u76FE\u6D88\u5931\u4E86\uFF01`}`);
      if (soaked) lines.push(`${dn}\u5438\u6536\u4E86\u4F24\u5BB3\uFF01`);
      if (def.pet.hp <= 0 && def.turn.destiny) {
        out.selfHp -= this.hurt(att, att.pet.hp);
        lines.push("\u53CC\u65B9\u540C\u5F52\u4E8E\u5C3D\uFF01");
      }
      if (def.pet.hp <= 0 && def.turn.grudge) for (const s2 of att.pet.skills) s2.pp = 0;
      if (sh && sh.ifAlive && def.pet.hp <= 0) reflect = 0;
      if (reflect >= 1 && att.pet.hp > 0) {
        const back = this.hurt(att, reflect);
        out.selfHp -= back;
        lines.push(`${dn}\u53CD\u51FB\u4E86${back}\u70B9\u4F24\u5BB3\uFF01`);
      }
      if (out.cri) lines.push(out.crits > 1 ? `\u66B4\u51FB${out.crits}\u6B21\uFF01` : "\u66B4\u51FB\uFF01");
      if (out.hits - dodged > 0) {
        if (mult > 1) lines.push("\u6548\u679C\u62D4\u7FA4\uFF01");
        else if (mult < 1) lines.push("\u6548\u679C\u4E0D\u7406\u60F3\u2026\u2026");
      }
      const mine = lines.splice(mark);
      for (let i = 0; i < mine.length; ) {
        let j = i + 1;
        while (j < mine.length && mine[j] === mine[i]) j++;
        lines.push(j - i > 1 ? `${mine[i]}\xD7${j - i}` : mine[i]);
        i = j;
      }
      out.after = lines.length - mark;
      return out;
    }
    /** One hit by the formula. */
    /** 暴击 of one hit: sure when the description says, its chance, or by the 暴击 stage. */
    rollCrit(b, att, def, fx) {
      if (fx.critIf && this.holds(fx.critIf, b, att, def)) return true;
      const timedCrit = Math.max(0, ...live(att, "crit").map((x) => x.chance ?? 0));
      const critStage = Math.min(4, Math.max(0, att.stages.crit + (fx.highCrit ? 1 : 0)));
      const p = Math.max(fx.critChance ?? 0, timedCrit, [100 / 16, 100 / 8, 100 / 4, 100 / 3, 100 / 2][critStage]);
      return this.rng() * 100 < p;
    }
    damage(b, att, def, sk, fx, mult, rolled, i, cri) {
      let power = sk.p > 1 ? sk.p : 60;
      if (fx.powerRange) power = this.int(fx.powerRange[0], fx.powerRange[1]);
      const ctx0 = { crit: false };
      let fixed = fx.fixed && this.chance(fx.fixedChance ?? 100) ? fx.fixed : 0;
      if (fx.fixedRange) fixed += this.int(fx.fixedRange[0], fx.fixedRange[1]);
      for (const p of fx.powerIf ?? []) {
        if (p.drain !== void 0 || p.heal !== void 0 || !this.holds(p.cond, b, att, def, ctx0)) continue;
        if (p.set !== void 0) power = p.set;
        if (p.mult !== void 0) power *= p.mult;
        if (p.power !== void 0) power += p.power;
        if (p.add !== void 0) fixed += p.add;
      }
      if (fx.copyPower && def.last !== void 0) power += Math.max(0, this.skill(def.last).p) / 2;
      const grown = fx.rollout && att.lock && att.lock.id === att.last ? att.lock.boost ?? 0 : 0;
      if (fx.rollout && grown > 0) power = fx.rollout.add ? power + fx.rollout.add * grown : power * 2 ** grown;
      if (fx.perHitPower) power += fx.perHitPower * i;
      if (fx.powerByHp) power = hpPower(fx.powerByHp, sk.p, att, def);
      if (fx.powerBySpeed) {
        const r = stat(att, "spd") / stat(def, "spd");
        power *= Math.max(0.5, Math.min(2.5, fx.powerBySpeed === "fast" ? r : 1 / r));
      }
      for (const x of live(att, "power")) {
        if (x.attr !== void 0 && x.attr !== sk.t) continue;
        if (x.mult) power *= x.mult;
        if (x.add) power += x.add;
      }
      for (const x of live(att, "extra")) if (x.chance !== -1) fixed += x.n ?? (x.a !== void 0 ? this.int(x.a, x.b ?? x.a) : 0);
      if (b.field) {
        if (sk.t === b.field.up) power *= 1 + b.field.upPct / 100;
        if (b.field.down !== void 0 && sk.t === b.field.down) power *= 1 - (b.field.downPct ?? 0) / 100;
      }
      power /= 2;
      const special = sk.k === 1;
      const a = stat(att, special ? "satk" : "atk");
      const noUps = !!fx.ignoreDef || fx.ignoreUps !== void 0 && this.chance(fx.ignoreUps);
      const d = stat(def, special ? "sdef" : "def", noUps) * (fx.ignoreDef ? 0.5 : 1);
      const base = Math.floor(Math.floor(Math.floor(2 * att.pet.level / 5 + 2) * power * a / d) / 50) + 2;
      if (cri) {
        for (const x of live(att, "extra")) if (x.chance === -1) fixed += x.n ?? 0;
      }
      const stab = sk.t >= 0 && (att.types[0] === sk.t || att.types[1] === sk.t) ? 1.5 : 1;
      const burn = att.status === "\u70E7\u4F24" && !special ? 0.5 : 1;
      let boost = 1;
      for (const x of fx.boost ?? []) {
        if (this.holds(x.cond, b, att, def) && this.chance(x.chance)) {
          boost = x.mult;
          break;
        }
      }
      const rand = 0.85 + this.rng() * 0.15;
      const dmg = Math.max(1, Math.floor(base * stab * mult * (cri ? 1.5 : 1) * burn * boost * rand)) + fixed;
      return { dmg, cri };
    }
    /** The skill's stage changes, and the moves of stages (clear, restore, copy, swap…); true when one was made. */
    stagesOf(b, att, def, fx, lines, ctx, grow = (p) => p, aims = true) {
      let any = false;
      const toUser = fx.fate === void 0 || this.chance(fx.fate);
      let failed = false;
      for (const ch of fx.stages) {
        if (fx.stagesIfCrit && !ctx.crit) continue;
        if (ch.cond && !this.holds(ch.cond, b, att, def, ctx)) continue;
        let f = ch.self ? att : def;
        if (!ch.self && (!aims || def === att)) continue;
        if (ch.self && !toUser) f = def;
        const chance = grow(ch.condChance && this.holds(ch.condChance.cond, b, att, def, ctx) ? ch.condChance.chance : ch.chance);
        const rolls = ch.cond && "crit" in ch.cond ? Math.max(1, ctx.crits ?? 1) : fx.perHit ? Math.max(1, ctx.hits ?? 1) : 1;
        for (let r = 0; r < rolls; r++) {
          if (f.pet.hp <= 0) break;
          if (!this.chance(chance)) {
            failed = true;
            continue;
          }
          let stats = ch.stats;
          if (ch.groups) stats = ch.groups[Math.floor(this.rng() * ch.groups.length)];
          if (ch.pick) {
            const pool = [...stats];
            const k = this.int(ch.pick[0], ch.pick[1]);
            stats = [];
            while (stats.length < k && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
          }
          let delta = ch.deltaMax !== void 0 ? Math.sign(ch.delta) * this.int(Math.abs(ch.delta), Math.abs(ch.deltaMax)) : ch.delta;
          if (fx.stageDouble && this.chance(fx.stageDouble)) delta *= 2;
          const before = stats.map((k) => f.stages[k]);
          if (this.stage(f, att, stats, delta, lines)) {
            any = true;
            if (ch.turns) f.timed.push({ who: "self", kind: "revert", turns: ch.turns, left: ch.turns, stats, deltas: stats.map((k, i) => f.stages[k] - before[i]) });
          }
        }
      }
      if (failed && fx.failCost) {
        this.hurt(att, fx.failCost);
        lines.push(`${petName(this.t, att)}\u5931\u8D25\u4E86\uFF0C\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
      }
      const name = petName(this.t, def);
      if (aims && def !== att) {
        if (fx.clearFoeUps && this.chance(fx.clearFoeUps.chance)) {
          if (fx.copyFoeUps && this.chance(fx.copyFoeUps.chance)) {
            for (const k of ALL_KEYS) if (def.stages[k] > 0) att.stages[k] = clampStage(att.stages[k] + def.stages[k]);
          }
          for (const k of fx.clearFoeUps.stats ?? ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
          lines.push(`${name}\u63D0\u5347\u7684\u80FD\u529B\u7B49\u7EA7\u88AB\u6E05\u9664\u4E86\uFF01`);
          any = true;
        } else if (fx.copyFoeUps && this.chance(fx.copyFoeUps.chance)) {
          for (const k of ALL_KEYS) if (fx.copyAll ? def.stages[k] !== 0 : def.stages[k] > 0) att.stages[k] = clampStage(fx.copyAll ? def.stages[k] : Math.max(att.stages[k], def.stages[k]));
          lines.push(`${petName(this.t, att)}\u590D\u5236\u4E86${name}\u7684\u80FD\u529B\u7B49\u7EA7\uFF01`);
          any = true;
        }
        if (fx.resetFoe) for (const k of ALL_KEYS) def.stages[k] = 0;
        if (fx.swapStages) {
          const a = { ...att.stages };
          att.stages = { ...def.stages };
          def.stages = a;
          lines.push("\u53CC\u65B9\u4EA4\u6362\u4E86\u80FD\u529B\u7B49\u7EA7\uFF01");
          any = true;
        }
        if (fx.passDowns) {
          for (const k of ALL_KEYS) {
            if (att.stages[k] < 0) {
              def.stages[k] = clampStage(def.stages[k] + att.stages[k]);
              att.stages[k] = 0;
            }
          }
          lines.push(`${petName(this.t, att)}\u628A\u88AB\u524A\u5F31\u7684\u80FD\u529B\u7B49\u7EA7\u8F6C\u79FB\u7ED9\u4E86${name}\uFF01`);
          any = true;
        }
        if (fx.stealStages && (fx.stealStages.minDmg === void 0 || (ctx.dmg ?? 0) > fx.stealStages.minDmg)) {
          for (const k of fx.stealStages.stats) {
            def.stages[k] = clampStage(def.stages[k] - fx.stealStages.delta);
            att.stages[k] = clampStage(att.stages[k] + fx.stealStages.delta);
          }
          any = true;
        }
      }
      if (fx.clearBothUps) for (const f of [att, def]) for (const k of ALL_KEYS) f.stages[k] = Math.min(0, f.stages[k]);
      if (fx.resetSelf) for (const k of ALL_KEYS) att.stages[k] = 0;
      if (fx.restoreOwn && this.chance(fx.restoreOwn.chance) && ALL_KEYS.some((k) => att.stages[k] < 0)) {
        for (const k of ALL_KEYS) att.stages[k] = Math.max(0, att.stages[k]);
        lines.push(`${petName(this.t, att)}\u88AB\u524A\u5F31\u7684\u80FD\u529B\u7B49\u7EA7\u6062\u590D\u4E86\uFF01`);
        any = true;
      }
      if (fx.swapOwnStages) {
        const s = att.stages;
        [s.atk, s.def, s.satk, s.sdef] = [s.def, s.atk, s.sdef, s.satk];
        any = true;
      }
      return any;
    }
    /** The skill's lasting effects onto their holders, the field, later turns; true when there was one. */
    lasting(b, att, def, fx, lines, from) {
      let any = false;
      const toUser = fx.fate === void 0 || this.chance(fx.fate);
      for (const x of fx.timed) {
        const holders = x.who === "both" ? [att, def] : x.who === "self" ? [toUser ? att : def] : def === att ? [] : [def];
        for (const f of holders) {
          if (f.pet.hp <= 0) continue;
          if (fx.exclusiveWith) f.timed = f.timed.filter((y2) => y2.from !== fx.exclusiveWith);
          const same = (y2) => y2.from === from && y2.kind === x.kind && y2.attr === x.attr && y2.left > 0 && y2.n === x.n && y2.f === x.f && y2.mult === x.mult && y2.status === x.status;
          if (x.stack) {
            const old = f.timed.filter(same);
            if (old.length >= x.stack) f.timed.splice(f.timed.indexOf(old[0]), 1);
          } else f.timed = f.timed.filter((y2) => !same(y2));
          const y = { ...x, from, left: x.turnsMin !== void 0 ? this.int(x.turnsMin, x.turns) : x.turns };
          if (y.flip) this.flip(y);
          f.timed.push(y);
          any = true;
        }
      }
      if (fx.field) {
        b.field = { ...fx.field, left: fx.field.turns };
        lines.push("\u573A\u5730\u7684\u529B\u91CF\u6539\u53D8\u4E86\uFF01");
        any = true;
      }
      if (fx.delayed) {
        const d = fx.delayed;
        (b.delayed ??= []).push({ slot: d.who === "self" ? att.slot : def.slot, left: d.turns, kind: d.kind, n: d.n, f: d.f, stats: d.stats, delta: d.delta, chance: d.chance });
        any = true;
      }
      if (fx.healFoeEnd) (b.delayed ??= []).push({ slot: def.slot, left: 0, kind: "heal", n: fx.healFoeEnd });
      return any;
    }
    /** 龙之逆鳞: this turn against 普通攻击 or 特殊攻击, at random. */
    flip(x) {
      const phys = this.rng() < 0.5;
      x.phys = phys ? 0.5 : void 0;
      x.spec = phys ? void 0 : 0.5;
    }
    /** The end of a turn: statuses, the lasting effects and later-turn effects; 2421 reports. */
    endOfTurn(b) {
      this.cur = b;
      this.over.clear();
      const out = [];
      const lostOf = /* @__PURE__ */ new Map();
      const lineOf = /* @__PURE__ */ new Map();
      const lose = (f, n, line) => {
        const l = this.hurt(f, n);
        lostOf.set(f, (lostOf.get(f) ?? 0) - l);
        if (line) lineOf.get(f).push(line);
        return l;
      };
      const gain = (f, n, line) => {
        const h = this.heal(f, n);
        lostOf.set(f, (lostOf.get(f) ?? 0) + h);
        if (line && h > 0) lineOf.get(f).push(line);
        return h;
      };
      for (const f of [b.mine, b.wild]) lineOf.set(f, []);
      for (const f of [b.mine, b.wild]) {
        if (f.pet.hp <= 0) continue;
        const o = this.other(b, f);
        const lines = lineOf.get(f);
        const name = petName(this.t, f);
        const max = f.stats[0];
        if (f.status === "\u70E7\u4F24" || f.status === "\u4E2D\u6BD2") lose(f, Math.max(1, max / 8), `${name}\u53D7\u5230\u4E86${f.status === "\u70E7\u4F24" ? "\u70E7\u4F24" : "\u6BD2"}\u7684\u4F24\u5BB3\uFF01`);
        if (f.weak > 0) {
          lose(f, Math.max(1, max * Math.min(8, f.weak) / 16), `${name}\u53D7\u5230\u4E86\u8870\u5F31\u7684\u4F24\u5BB3\uFF01`);
          f.weak++;
          if (f.weakLeft && --f.weakLeft === 0) {
            f.weak = 0;
            lines.push(`${name}\u4E0D\u518D\u8870\u5F31\u4E86\uFF01`);
          }
        }
        if (f.seeded && o.pet.hp > 0) {
          const l = lose(f, Math.max(1, max / 8), `${name}\u88AB\u5438\u53D6\u4E86\u4F53\u529B\uFF01`);
          gain(o, l);
        }
        if (f.bind > 0) {
          f.bind--;
          lose(f, Math.max(1, max / 16), f.bind > 0 ? `${name}\u53D7\u5230\u4E86\u675F\u7F1A\u7684\u4F24\u5BB3\uFF01` : `${name}\u6323\u8131\u4E86\u675F\u7F1A\uFF01`);
        }
        if (f.status && f.status !== "\u7761\u7720" && f.status !== "\u51B0\u51BB" && f.statusLeft > 0 && --f.statusLeft === 0) {
          lines.push(`${name}\u7684${f.status}\u72B6\u6001\u89E3\u9664\u4E86\uFF01`);
          f.status = void 0;
        }
        if (f.trapped > 0) f.trapped--;
        for (const x of f.timed) {
          if (x.left <= 0 || f.pet.hp <= 0) continue;
          if (x.while && !this.has(f, x.while) || x.whileOther && !this.has(o, x.whileOther)) {
            x.left = 0;
            continue;
          }
          switch (x.kind) {
            case "regen":
              if (this.chance(x.chance ?? 100)) gain(f, x.n ?? (x.lost ? (max - f.pet.hp) * (x.f ?? 0) : max * (x.f ?? 0)), `${name}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
              break;
            case "leech": {
              if (x.attr !== void 0 && f.types.includes(x.attr)) break;
              const l = lose(f, x.n ?? max * (x.f ?? 0), `${name}\u88AB\u5438\u53D6\u4E86\u4F53\u529B\uFF01`);
              if (o.pet.hp > 0) gain(o, l, `${petName(this.t, o)}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
              break;
            }
            case "dot":
              if (this.chance(x.chance ?? 100)) lose(f, x.n ?? (x.a !== void 0 ? this.int(x.a, x.b ?? x.a) : max * (x.f ?? 0)), `${name}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
              break;
            case "gamble":
              if (this.chance(x.chance ?? 50)) {
                const l = lose(f, x.a !== void 0 ? this.int(x.a, x.b ?? x.a) : x.n ?? 0, `${name}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
                if (x.a !== void 0 && o.pet.hp > 0) gain(o, l / 2);
              } else if (x.self && o.pet.hp > 0) {
                if (x.self < 0) lose(o, -x.self, `${petName(this.t, o)}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
                else gain(o, x.self, `${petName(this.t, o)}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
              }
              break;
            case "stagesEachTurn":
              if (this.chance(x.chance ?? 100) && x.stats) {
                let stats = x.stats;
                if (x.pick) {
                  const pool = [...stats];
                  stats = [];
                  while (stats.length < x.pick && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
                }
                this.stage(f, x.delta && x.delta < 0 ? o : f, stats, x.delta ?? 0, lines);
              }
              break;
            case "pphp": {
              const with_ = f.pet.skills.filter((s) => s.pp > 0);
              if (with_.length && f.pet.hp < max) {
                for (const s of with_) s.pp--;
                gain(f, x.n ?? 0, `${name}\u7528\u6280\u80FD\u6B21\u6570\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
              }
              break;
            }
            case "ppdrain":
              for (const s of f.pet.skills) s.pp = Math.max(0, s.pp - (x.n ?? 1));
              lines.push(`${name}\u7684\u6280\u80FD\u6B21\u6570\u51CF\u5C11\u4E86\uFF01`);
              break;
            case "painsplit":
              if (o.pet.hp > f.pet.hp && this.chance(x.chance ?? 100)) {
                const avg = Math.floor((f.pet.hp + o.pet.hp) / 2);
                gain(f, Math.min(f.stats[0], avg) - f.pet.hp);
                lose(o, o.pet.hp - Math.min(o.stats[0], avg));
                lines.push("\u53CC\u65B9\u5E73\u5206\u4E86\u4F53\u529B\uFF01");
              }
              break;
            case "screen":
              if (x.flip) this.flip(x);
              break;
            case "punish":
              if (!f.turn.damaging) lose(f, x.n ?? 0, `${name}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
              break;
            case "plague":
              if (x.status && this.chance(x.chance ?? 0)) this.applyStatus(f, x.status, lines);
              break;
          }
        }
      }
      for (const d of b.delayed ?? []) {
        if (d.left-- > 0) continue;
        const f = d.slot === b.mine.slot ? b.mine : b.wild;
        if (f.pet.hp <= 0) continue;
        const name = petName(this.t, f);
        if (d.kind === "healFull") gain(f, f.stats[0], `${name}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
        else if (d.kind === "rebirth") {
          gain(f, f.stats[0], `${name}\u6EE1\u72B6\u6001\u56DE\u590D\u4E86\uFF01`);
          for (const s of f.pet.skills) s.pp = s.max;
          this.cureAll(f);
          const o = this.other(b, f);
          if (o.pet.hp > 0) this.applyStatus(o, "\u5BB3\u6015", lineOf.get(o));
        } else if (d.kind === "stages" && d.stats) this.stage(f, f, d.stats, d.delta ?? 0, lineOf.get(f));
        else if (d.kind === "badStatus") {
          if (this.chance(d.chance ?? 100)) this.applyStatus(f, BAD_STATUSES[Math.floor(this.rng() * BAD_STATUSES.length)], lineOf.get(f));
        } else if (d.kind === "heal") gain(f, d.n ?? 0, `${name}\u56DE\u590D\u4E86\u4F53\u529B\uFF01`);
        else if (d.kind === "sleep") this.applyStatus(f, "\u7761\u7720", lineOf.get(f));
        else if (d.kind === "flat") lose(f, d.n ?? 0, `${name}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
        else if (d.kind === "hpFrac") lose(f, f.pet.hp * (d.f ?? 0), `${name}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
        else if (d.kind === "maxFrac") lose(f, f.stats[0] * (d.f ?? 0), `${name}\u53D7\u5230\u4E86\u4F24\u5BB3\uFF01`);
        else if (d.kind === "kill") lose(f, f.pet.hp, `${name}\u7684\u65F6\u95F4\u88AB\u541E\u566C\u4E86\uFF01`);
        else if (d.kind === "hpTo1") lose(f, f.pet.hp - 1);
      }
      if (b.delayed) b.delayed = b.delayed.filter((d) => d.left >= 0);
      for (const f of [b.mine, b.wild]) {
        for (const x of f.timed) {
          if (x.left > 0) x.left--;
          if (x.left <= 0 && x.kind === "revert" && x.stats && x.deltas) {
            x.stats.forEach((k, i) => f.stages[k] = clampStage(f.stages[k] - (x.deltas[i] ?? 0)));
            lineOf.get(f).push(`${petName(this.t, f)}\u7684\u80FD\u529B\u7B49\u7EA7\u6062\u590D\u4E86\u3002`);
          }
        }
        f.timed = f.timed.filter((x) => x.left > 0);
      }
      if (b.field && --b.field.left <= 0) {
        b.field = void 0;
        lineOf.get(b.mine).push("\u573A\u5730\u7684\u529B\u91CF\u6D88\u5931\u4E86\u3002");
      }
      for (const f of [b.mine, b.wild]) {
        const lines = lineOf.get(f);
        const inc = (lostOf.get(f) ?? 0) + this.overflow(f);
        if (!lines.length && !inc) continue;
        if (f.pet.hp <= 0) lines.push(`${petName(this.t, f)}\u5012\u4E0B\u4E86\uFF01`);
        out.push(["2421", { slotId: f.slot, hpInc: inc, desc: lines.join("\n"), pmmList: this.views(b) }]);
      }
      return out;
    }
    /** Who goes first: priority (先发, 后发), then speed. */
    firstMover(b, mySkill, wildSkill) {
      const pri = (f, id) => {
        const sk = this.skill(this.choice(f, id));
        const fx = parseEffects(sk.d);
        return sk.pri + (fx.first || fx.chargeFirst && f.charging !== void 0 ? 1 : 0) - (fx.last ? 1 : 0);
      };
      const pm = pri(b.mine, mySkill), pw = pri(b.wild, wildSkill);
      if (pm !== pw) return pm > pw ? b.mine : b.wild;
      const sm = stat(b.mine, "spd"), sw = stat(b.wild, "spd");
      if (sm !== sw) return sm > sw ? b.mine : b.wild;
      return this.rng() < 0.5 ? b.mine : b.wild;
    }
    /** A whole turn in which the player uses a skill. */
    skillTurn(b, mySkill) {
      this.startTurn(b);
      if (this.needsBean(b.wild)) {
        const out2 = [this.useBean(b, b.wild)];
        if (b.mine.pet.hp > 0 && b.wild.pet.hp > 0) out2.push(this.act(b, b.mine, b.wild, mySkill));
        return out2;
      }
      const wildSkill = this.wildChoice(b);
      const first = this.firstMover(b, mySkill, wildSkill);
      const second = first === b.mine ? b.wild : b.mine;
      const secondSkill = this.skill(this.choice(second, second === b.mine ? mySkill : wildSkill));
      second.turn.damaging = secondSkill.k !== 2 || !!parseEffects(secondSkill.d).dmg;
      const out = [this.act(b, first, second, first === b.mine ? mySkill : wildSkill)];
      if (first.pet.hp > 0 && second.pet.hp > 0) out.push(this.act(b, second, first, second === b.mine ? mySkill : wildSkill));
      return out;
    }
    /** The wild 亚比 alone acts (after an item, a failed catch or a switch). */
    wildTurn(b) {
      this.startTurn(b);
      if (b.wild.pet.hp <= 0 || b.mine.pet.hp <= 0) return [];
      if (this.needsBean(b.wild)) return [this.useBean(b, b.wild)];
      return [this.act(b, b.wild, b.mine, this.wildChoice(b))];
    }
    /**
     * The computer's 亚比 (wild ones, bosses, 副本, 时空隧道, quests, 道馆) with no PP left on any
     * skill: it has 高级活力豆 without end (RECONSTRUCTED: the 2013 server's rule is lost), so it
     * never falls back on 挣扎. Not when a skill goes on by itself (蓄力, 连续攻击: no PP needed).
     */
    needsBean(f) {
      return f.pet.skills.length > 0 && f.pet.skills.every((s) => s.pp <= 0) && this.forcedOf(f) === void 0;
    }
    /** It takes a 高级活力豆 (104: 可恢复战斗中的亚比技能使用次数20次): its turn goes on it. The 2412 report. */
    useBean(b, f) {
      for (const s of f.pet.skills) s.pp = Math.min(s.max, s.pp + PP_BEANS[BEAN]);
      const name = petName(this.t, f);
      return ["2412", { reqSId: f.slot, itemId: BEAN, res: 1, hpInc: 0, desc: `${name}\u4F7F\u7528\u4E86\u9AD8\u7EA7\u6D3B\u529B\u8C46\uFF01
${name}\u7684\u6280\u80FD\u6B21\u6570\u56DE\u590D\u4E86\uFF01`, pmmList: this.views(b) }];
    }
    /** PlayerBattleInfo of both sides. */
    views(b, bag3, owner) {
      return [this.view(b, 0, bag3, owner), this.view(b, 1)];
    }
    bag;
    ownerRef;
    view(b, slot, bag3 = this.bag, owner = this.ownerRef) {
      const f = slot === 0 ? b.mine : b.wild;
      const st = [f.status, f.confuse > 0 ? "\u6DF7\u4E71" : "", f.bind > 0 ? "\u675F\u7F1A" : "", f.fear > 0 ? "\u5BB3\u6015" : "", f.weak > 0 ? "\u8870\u5F31" : "", f.seeded ? "\u5BC4\u751F" : "", f.armour ? `\u62A4\u76FE${f.armour}` : ""].filter(Boolean).join(",");
      const forced = this.forcedOf(f);
      const list = slot === 0 && bag3 ? [f.pet, ...bag3.filter((p) => p !== f.pet)] : [f.pet];
      const own = { id: f.owner };
      return {
        battleView: {
          pmCanBattle: list.filter((p) => p.hp > 0).length,
          ...slot === 0 && owner ? catchFields(owner) : { clv: 0, ccle: 0, "clu%": 0, cnx: 0 },
          pmmId: f.owner,
          slotId: slot,
          pms: list.map((p) => p.id).join("#"),
          bag: slot === 0,
          locaId: slot,
          // Not a 2013 field: how my 亚比's attribute fares against the wild one's (the 强效 / 普通 / 弱效 row).
          ...slot === 0 ? { mu: typeMultiplier(this.t.pm, b.mine.types[0], b.wild.types) } : {},
          // Not a 2013 field: the skill it uses this turn by itself (蓄力, 连续攻击N回合): no choice is asked.
          ...forced !== void 0 ? { forced } : {},
          pmList: list.map((p) => briefOf(p, own, this.t, p === f.pet ? { st, bal: balOf(f.stages) } : void 0))
        }
      };
    }
  };
  function award(t, pet, wildRace, wildLevel, boost = {}) {
    const wsp = speciesOf(t, wildRace);
    const gained = expYield(wsp, wildLevel) * (boost.exp ?? 1);
    if (wsp) {
      pet.ev ??= [0, 0, 0, 0, 0, 0];
      const total = pet.ev.reduce((a, b) => a + b, 0);
      let room = Math.max(0, 510 - total);
      wsp.ev.forEach((y, i) => {
        const add = Math.min(y * (boost.ev ?? 1), room, 255 - pet.ev[i]);
        if (add > 0) {
          pet.ev[i] += add;
          room -= add;
        }
      });
    }
    return gainExp(t, pet, gained);
  }
  function gainExp(t, pet, gained) {
    const msgs = [];
    pet.exp += gained;
    let evolvedTo;
    const ups = [];
    while (pet.level < 100 && pet.exp >= expToNext(pet, t)) {
      pet.exp -= expToNext(pet, t);
      const before = statsOf(pet, t);
      pet.level++;
      const sp = speciesOf(t, pet.race);
      const next = sp && !pet.fixed ? evolutionAt(sp, pet.race, pet.level) : 0;
      if (next && speciesOf(t, next)) {
        pet.race = next;
        evolvedTo = next;
      }
      const after = statsOf(pet, t);
      pet.hp = Math.min(after[0], pet.hp + Math.max(0, after[0] - before[0]));
      ups.push([
        "2242",
        {
          id: pet.id,
          lv: pet.level,
          raceId: pet.race,
          evolve: next || 0,
          abilityChange: {
            pmId: pet.id,
            oldHP: before[0],
            oldAtt: before[1],
            oldDef: before[2],
            oldSAtt: before[3],
            oldSDef: before[4],
            oldSpd: before[5],
            newHP: after[0],
            newAtt: after[1],
            newDef: after[2],
            newSAtt: after[3],
            newSDef: after[4],
            newSpd: after[5]
          }
        }
      ]);
      const learnt = speciesOf(t, pet.race) ? skillsLearntAt(speciesOf(t, pet.race), pet.level) : [];
      for (const id of learnt) {
        pet.learned ??= pet.skills.map((s) => s.id);
        if (pet.learned.includes(id)) continue;
        pet.learned.push(id);
        const carried = pet.skills.length < 4;
        if (carried) pet.skills.push(skillOf(t, id));
        ups.push(["2234", { id: pet.id, skillId: id, name: skillOf(t, id).name, used: carried }]);
      }
    }
    msgs.push(["2241", { id: pet.id, exp: gained, lv: pet.level, curExp: pet.exp, nx: Math.max(0, expToNext(pet, t) - pet.exp) }], ...ups);
    return { msgs, evolvedTo };
  }
  var BALLS = { 32: 0.5, 67: 0.7, 68: 0.9, 64: 1 };
  var POTIONS = { 30: 40, 60: 100, 61: 200, 102: 300, 263: 400, 390: 200 };
  var PP_BEANS = { 31: 5, 103: 10, 104: 20, 391: 20 };
  var BEAN = 104;
  var CURES = { 94: "\u7761\u7720", 95: "\u6DF7\u4E71", 96: "\u5BC4\u751F", 97: "\u70E7\u4F24", 98: "\u51B0\u51BB", 99: "\u4E2D\u6BD2", 100: "all", 101: "all" };
  var CATCH_HP = 0.2;
  function catchHpLimit(t, race) {
    const c = Number(speciesOf(t, race)?.c[0]);
    return Number.isFinite(c) ? Math.max(CATCH_HP, 1 - c / 8) : CATCH_HP;
  }
  function catchStars(c) {
    const n = Number(c);
    return Number.isFinite(n) ? Math.max(1, Math.min(5, 1 + Math.floor(n / 8))) : 5;
  }
  function catchChance(t, wild, ball, clv) {
    const base = BALLS[ball] ?? 0;
    if (base >= 1) return 1;
    if (wild.pet.hp > wild.stats[0] * catchHpLimit(t, wild.pet.race)) return 0;
    const c = Number(speciesOf(t, wild.pet.race)?.c[0]);
    const lf = Number.isFinite(c) ? Math.max(0.2, Math.min(1, 1 - Math.max(0, c - clv) * 0.05)) : 0;
    const st = wild.status === "\u7761\u7720" || wild.status === "\u51B0\u51BB" ? 0.1 : wild.status ? 0.05 : 0;
    return Math.min(1, (base + st) * lf);
  }
  var PM = "PocketMonsterExtension";
  var FIGHT_IN_NPCCHALLENGE = 14;
  var GUARDIANS = [
    ["10317,20317", "80,100"],
    ["20087", "80"],
    ["20427", "60"],
    ["10090,20090", "60,80"],
    ["10093,20093", "60,80"],
    ["20418", "100"],
    ["10099,20099", "60,80"],
    ["10102,10102,20102", "60,80,100"],
    ["10096,10096,20096", "60,80,100"],
    ["10108,10108,20108", "60,80,100"],
    ["10469#10472", "100#100"],
    ["10475#20475", "100#100"],
    ["30682,10682", "88,100"],
    ["10715,20715", "80,100"],
    ["14523#11514#11516", "100#80#80"],
    ["10757,20757", "80,100"],
    ["10840,20840", "80,100"],
    ["10865,20865", "80,100"],
    ["11213,21213,31213", "60,80,100"],
    // Bosses of the 2013 world beside that table (the rebuilt dailyactivity): 伊泽 and 迦娜 (mysticocean5),
    // 烈焰鸟 (feier4), 神武月 and 战无炎 (choicetemple); their levels are RECONSTRUCTED. 神武月 is its
    // "一次机会" partner fight (10105, boss10105); the 满月 神武月 (20105, the later StartBoss of 哈米乐园)
    // is not in the 2013 world.
    ["11320,11322", "100,100"],
    ["30278", "80"],
    ["10105", "80"],
    ["10111", "90"],
    // The bosses of the 2011–12 events (dailyactivity, rows added in the revival; levels RECONSTRUCTED
    // but 天女若希's second form, Lv100 in the later BossTimeHelper).
    ["11259", "100"],
    ["10884", "100"],
    ["10639", "100"],
    ["10493", "100"],
    ["10112,20112", "80,100"],
    ["10195,20195", "80,100"],
    ["10633", "100"],
    ["10665", "100"],
    ["10796,20796", "80,100"],
    ["10771,20771", "80,100"],
    ["11190", "100"],
    ["10819,20819", "80,100"],
    ["10995", "100"],
    // 蓝羽灵者 (迷境花园, January 2013): three forms fought from its panel (RECONSTRUCTED levels).
    ["31394,21394,11394", "60,80,100"]
  ];
  var FILM_RACES = /* @__PURE__ */ new Set([192, 230]);
  var GUARDIAN_RACES = new Set(GUARDIANS.flatMap(([races]) => races.split(/[#,]/).map(Number)));
  var isGuardian = (race) => GUARDIAN_RACES.has(race);
  var BOSS_SPECIES = { 10112: 114, 20112: 114 };
  var BOSS_EGGS = { 11516: 520, 31394: 0, 21394: 0, 11394: 1393 };
  var FIRST_WIN_ONLY = /* @__PURE__ */ new Set([11394, 11259, 31213]);
  var BOSS_MARKS = { 11259: 1257, 31213: 1211, 11394: 1393 };
  function guardianLevel(race, index) {
    let anywhere = 0;
    for (const [races, levels] of GUARDIANS) {
      const rs = races.split(/[#,]/).map(Number);
      const ls = levels.split(/[#,]/).map(Number);
      if (rs[index] === race) return ls[index] ?? ls[0];
      const at = rs.indexOf(race);
      if (at >= 0 && !anywhere) anywhere = ls[at] ?? ls[0];
    }
    return anywhere || Math.min(100, 20 + 5 * index);
  }
  function lastGuardianForm(race, index) {
    for (const [races] of GUARDIANS) {
      for (const pair of races.split("#")) {
        const chain = pair.split(",").map(Number);
        const at = chain[index] === race ? index : chain.lastIndexOf(race);
        if (at >= 0) return at === chain.length - 1;
      }
    }
    return true;
  }
  var EGG_IDS = /* @__PURE__ */ new Set([
    13,
    37,
    64,
    73,
    79,
    82,
    85,
    88,
    91,
    94,
    97,
    100,
    103,
    106,
    109,
    112,
    127,
    130,
    178,
    193,
    253,
    265,
    267,
    276,
    282,
    285,
    297,
    315,
    337,
    392,
    409,
    416,
    425,
    467,
    470,
    473,
    482,
    488,
    515,
    520,
    602,
    637,
    663,
    680,
    705,
    713,
    755,
    770,
    786,
    817,
    839,
    856,
    858,
    864,
    873,
    890,
    947,
    1143,
    1160,
    1184,
    1188,
    1211,
    1226,
    1237,
    1239,
    1256,
    1258,
    1260,
    1264,
    1266,
    1275,
    1277,
    1292,
    1311,
    1319,
    1321,
    1337,
    1340,
    1393
  ]);
  function eggOfLine(t, race) {
    const prev = /* @__PURE__ */ new Map();
    for (const [id, sp] of Object.entries(t.species)) if (sp.next) prev.set(sp.next, Number(id));
    let r = race;
    for (let i = 0; i < 6 && !EGG_IDS.has(r) && prev.has(r); i++) r = prev.get(r);
    return EGG_IDS.has(r) ? r : 0;
  }
  var FIGHT_IN_MEMBER_ARENA = 12;
  var MEMBER_ARENA_LEVELS = { viparena2: 50, viparena3: 50, viparena5: 65, viparena6: 65, viparena7: 80 };
  var NPC_LEVELS = [8, 18, 30];
  var NPC_TEAM_BASE = { 13: 61, 35: 10, 145: 43, 14: 1, 3: 34, 26: 70, 142: 19, 32: 10, 31: 1, 172: 97, 312: 70 };
  function tutorial(o, race) {
    const tasks = o.tasks;
    return race === 322 && tasks?.["138"]?.st === 0;
  }
  var WEAK = "\u4F60\u7684\u4E9A\u6BD4\u5F88\u865A\u5F31\u4E86\uFF0C\u5FEB\u53BB\u6CBB\u7597\u5B83\u5427\uFF01\n\u70B9\u51FB\u4E9A\u6BD4\u80CC\u5305\u5185\u7684\u4E9A\u6BD4\u6062\u590D\u5C31\u53EF\u4EE5\u6CBB\u7597\u5B83\u54E6\uFF01";
  function installBattles(world, deps) {
    const battles = /* @__PURE__ */ new Map();
    registerFights(world, battles);
    let nextBattle = 1;
    const send = (ctx, msgs) => {
      for (const [cmd, body] of msgs) ctx.reply(body, cmd);
    };
    const duels = installDuels(world, {
      battles,
      load: deps.load,
      find: async (name) => deps.find?.(name),
      tables: deps.tables,
      rng: deps.rng,
      nextId: () => nextBattle++
    });
    world.xt("PetExtension.54_7", async (ctx) => {
      const room = sceneOfRoom(ctx.player.room);
      const auto = (await deps.load(ctx)).boosts?.auto ?? 0;
      ctx.reply({ pms: (await deps.wild())[room] ?? [], ...auto ? { auto } : {} });
    });
    const begin = async (ctx, race, level, catchable, onWin, asked, onLose, copyId, sandbox, adjust) => {
      const o = await deps.load(ctx);
      const t = await deps.tables();
      for (const p of o.pets ?? []) normalisePet(p, t);
      const old = battles.get(o.id);
      const refuse = (msg) => (ctx.reply({ msg }, "2303"), false);
      if (old && !old.over) return refuse("\u4F60\u4E0D\u80FD\u591F\u5728\u79BB\u5F00\u4E00\u4E2A\u6218\u573A\u4E4B\u524D\uFF0C\u52A0\u5165\u53E6\u5916\u4E00\u4E2A\u6218\u573A\uFF01");
      const active = (o.pets ?? []).find((p) => p.hp > 0);
      if (!active) return refuse(WEAK);
      if (!speciesOf(t, race)) return refuse("\u8FD9\u53EA\u4E9A\u6BD4\u8FD8\u4E0D\u80FD\u5BF9\u6218\u54E6\uFF01");
      const lesson = tutorial(o, race);
      const wildPet = makePet(t, race, lesson ? Math.min(level, 2) : level, deps.today());
      if (sandbox) {
        wildPet.mul = sandbox.mul;
        wildPet.hp = statsOf(wildPet, t)[0];
      }
      if (lesson) {
        const hits = wildPet.skills.filter((s) => (t.pm.skills[String(s.id)]?.k ?? 0) !== 2);
        if (hits.length) wildPet.skills = hits;
      }
      const engine = new BattleEngine(t, deps.rng);
      const canCatch = catchable && Number.isFinite(Number(speciesOf(t, race).c[0]));
      const b = engine.start(nextBattle++, sceneOfRoom(ctx.player.room), o, active, wildPet, canCatch);
      b.onWin = onWin;
      b.onLose = onLose;
      b.asked = asked;
      b.copyId = copyId;
      b.noAward = !!sandbox;
      adjust?.(b);
      const boosts = o.boosts;
      const auto = !!boosts?.auto && catchable && !copyId && !sandbox;
      b.auto = auto;
      if (auto && boosts) {
        boosts.auto = (boosts.auto ?? 0) - 1;
        if (boosts.auto <= 0) delete boosts.auto;
        await deps.save(o);
      }
      battles.set(o.id, b);
      engine.bag = o.pets;
      engine.ownerRef = o;
      send(ctx, [
        // chp (not in the 2013 reply): the HP fraction from which balls work, for the 捕捉难度 hint.
        ["2303", { esc: true, sw: true, ch: canCatch, cd: catchStars(speciesOf(t, race).c[0]), chp: catchHpLimit(t, race), pmmList: engine.views(b) }],
        // boss: the opponent's id as the fight was asked for (variant * 10000 + species for the
        // bosses), by which the battle screen finds the boss's films (bossfightmovie/boss<id>).
        ["2401", { id: b.id, type: 0, pt: 0, bs: "", srt: 0, scene: b.room, boss: asked ?? race, ...auto ? { auto: true, autoLeft: boosts?.auto ?? 0 } : {} }]
      ]);
      if (!sandbox && markDic(o, t, race, MET)) {
        await deps.save(o);
        send(ctx, [NEW_RECORD]);
      }
      return true;
    };
    const TASK_PET_RACES = /* @__PURE__ */ new Set([230, 305]);
    world.xt("PetExtension.54_2", async (ctx) => {
      const asked = Number(ctx.params.level);
      const id = Number(ctx.params.raceId);
      const onWin = (o) => stepsByPetWin(o, id, deps.now?.() ?? Date.now()).changes.map((c) => ["10-1", { t: c.t, ty: c.ty }]);
      if (id >= 1e4 || TASK_PET_RACES.has(id)) {
        const o = await deps.load(ctx);
        const top = Math.max(5, ...(o.pets ?? []).map((p) => p.level));
        const level2 = asked > 0 ? asked : top + 2 * (Math.floor(id / 1e4) - 1);
        return void await begin(ctx, id % 1e4, Math.max(1, Math.min(100, level2)), false, onWin, id);
      }
      const entry = ((await deps.wild())[sceneOfRoom(ctx.player.room)] ?? []).find((w) => w.raceId === id);
      const rng = deps.rng ?? Math.random;
      const level = entry ? entry.min + Math.floor(rng() * (entry.max - entry.min + 1)) : asked > 0 ? asked : 5;
      const room = sceneOfRoom(ctx.player.room);
      await begin(ctx, id, Math.max(1, Math.min(100, level)), !!entry, (o) => [...onWin(o), ...entry ? wildDrop(o, room, id) : []]);
    });
    const gymFight = async (ctx, type) => {
      const refuse = (msg) => {
        ctx.reply({ res: false });
        ctx.reply({ msg }, "2303");
      };
      if (type === GYM_TOWER) {
        const layer = Number(ctx.params.layer) | 0;
        const run = gymOf(await deps.load(ctx)).tower;
        const floor = TOWER_FLOORS[layer - 1];
        if (!run || !floor || layer !== run.floor + 1) return refuse("\u8BF7\u5148\u5F00\u542F\u96F7\u9706\u4E4B\u5854\u7684\u6311\u6218\uFF01");
        ctx.reply({ res: true });
        return void await begin(ctx, floor.race, floor.level, false, (o2) => towerFloorWon(o2, layer, deps.now?.() ?? Date.now()));
      }
      if (type === GYM_DARK && Number(ctx.params.raceId) > 0) {
        const raceId = Number(ctx.params.raceId) | 0;
        ctx.reply({ res: true });
        return void await begin(ctx, raceId % 1e4, dollLevel(raceId), false, void 0, raceId);
      }
      const master = GYM_MASTERS[type];
      if (!master) return refuse(type === GYM_LIGHT ? "\u53CB\u60C5\u7684\u8BD5\u70BC\u9700\u8981\u597D\u53CB\u7684\u4E9A\u6BD4\u4E00\u8D77\u53C2\u52A0\u54E6\uFF01" : "\u8FD9\u4E2A\u6311\u6218\u73B0\u5728\u8FD8\u4E0D\u80FD\u8FDB\u884C\u54E6\uFF01");
      const o = await deps.load(ctx);
      const fate = type === GYM_DARK ? gymOf(o).fate : void 0;
      if (fate) {
        delete gymOf(o).fate;
        await deps.save(o);
      }
      ctx.reply({ res: true });
      await begin(
        ctx,
        master.race,
        master.level,
        false,
        (owner) => {
          const b = battles.get(owner.id);
          gymWon(owner, type, b?.mine.pet.race ?? 0);
          return [];
        },
        void 0,
        void 0,
        void 0,
        void 0,
        fate ? (b) => {
          const st = applyFate(b.mine.stats, fate);
          b.mine.pet.hp = Math.min(st[0], Math.round(b.mine.pet.hp * st[0] / Math.max(1, b.mine.stats[0])));
          b.mine.stats = st;
        } : void 0
      );
    };
    world.xt("PetExtension.54_22", async (ctx) => {
      if (Number(ctx.params.type) === FIGHT_IN_MEMBER_ARENA) {
        const mi = Number(ctx.params.mi) | 0;
        const level = MEMBER_ARENA_LEVELS[String(ctx.params.rm ?? "")] ?? 60;
        return void await begin(ctx, mi % 1e4, level, false, void 0, mi);
      }
      const type = Number(ctx.params.type);
      if (type >= GYM_THUNDER && type <= GYM_LIGHT) return gymFight(ctx, type);
      if (type !== FIGHT_IN_NPCCHALLENGE) {
        ctx.reply({ res: false });
        return ctx.reply({ msg: "\u8FD9\u4E2A\u6311\u6218\u73B0\u5728\u8FD8\u4E0D\u80FD\u8FDB\u884C\u54E6\uFF01" }, "2303");
      }
      const npcId = Number(ctx.params.npcId) | 0;
      if (NPC_TEAM_BASE[npcId] === void 0) {
        ctx.reply({ res: false, canGet: false, canGet1: false });
        return ctx.reply({ msg: "\u8FD9\u4E2A\u6311\u6218\u73B0\u5728\u8FD8\u4E0D\u80FD\u8FDB\u884C\u54E6\uFF01" }, "2303");
      }
      const lv = Math.max(1, Math.min(3, Number(ctx.params.lv) | 0));
      const o = await deps.load(ctx);
      const t = await deps.tables();
      const rec = o.npcChallenge ??= { won: {}, gift: {} };
      if (lv > (rec.won[npcId] ?? 0) + 1) return ctx.reply({ res: false, canGet: false, canGet1: false });
      const day = deps.today();
      const canGet = rec.gift[npcId] !== day;
      let race = NPC_TEAM_BASE[npcId];
      for (let i = 1; i < lv; i++) {
        const next = t.species[String(race)]?.next;
        if (next && speciesOf(t, next)) race = next;
      }
      ctx.reply({ res: true, canGet, canGet1: canGet });
      await begin(ctx, race, NPC_LEVELS[lv - 1], false, (owner) => {
        const r = owner.npcChallenge ??= { won: {}, gift: {} };
        r.won[npcId] = Math.max(r.won[npcId] ?? 0, lv);
        if (r.gift[npcId] === day) return [];
        r.gift[npcId] = day;
        const items = (owner.items ??= {})["2"] ??= {};
        const gift = npcId === 312 ? 379 : 343;
        items[String(gift)] = (items[String(gift)] ?? 0) + 1;
        return [["onAmountUpdated", { amount: `2_${gift}_0_1` }]];
      });
    });
    const TOWER_FLOORS2 = 100;
    const towerOf = (o) => o.tower ??= { mf: 1, cf: 1, en: [], alive: [], chest: false };
    const TOWER_POOL = [
      2,
      3,
      5,
      6,
      8,
      9,
      102,
      105,
      108,
      201,
      203,
      204,
      207,
      208,
      301,
      302,
      303,
      304,
      305,
      408,
      503,
      504,
      509,
      601,
      608,
      701,
      704,
      11,
      12,
      14,
      15,
      16,
      17,
      18,
      111,
      114,
      218,
      219,
      317,
      411,
      414,
      418,
      512,
      514,
      516,
      612,
      615,
      618,
      619,
      710,
      711,
      715,
      20,
      21,
      23,
      24,
      27,
      29,
      123,
      126,
      129,
      220,
      221,
      222,
      223,
      224,
      225,
      227,
      322,
      325,
      328,
      329,
      424,
      427,
      522,
      526,
      620,
      621,
      622,
      30,
      31,
      32,
      33,
      35,
      36,
      39,
      132,
      135,
      138,
      230,
      232,
      233,
      238,
      339,
      430,
      433,
      436,
      439,
      533,
      633,
      639,
      41,
      42,
      44,
      45,
      47,
      48,
      141,
      144,
      147,
      240,
      241,
      242,
      243,
      249,
      340,
      343,
      346,
      349,
      442,
      445,
      542,
      545,
      548,
      641,
      643,
      644,
      51,
      54,
      57,
      59,
      150,
      153,
      155,
      156,
      158,
      159,
      255,
      258,
      355,
      358,
      457,
      551,
      554,
      557,
      650,
      653,
      654,
      655,
      656,
      60,
      62,
      63,
      66,
      67,
      68,
      69,
      162,
      165,
      168,
      261,
      265,
      266,
      267,
      268,
      364,
      366,
      367,
      368,
      460,
      463,
      469,
      566,
      569,
      662,
      665,
      71,
      72,
      75,
      78,
      171,
      174,
      177,
      271,
      278,
      370,
      371,
      372,
      373,
      374,
      375,
      472,
      475,
      571,
      574,
      577,
      672,
      673,
      678,
      81,
      84,
      87,
      180,
      183,
      185,
      189,
      284,
      287,
      382,
      383,
      484,
      487,
      580,
      583,
      682,
      90,
      93,
      96,
      99,
      192,
      195,
      198,
      293,
      296,
      299,
      393,
      394,
      397,
      398,
      493,
      499,
      598,
      697,
      699
    ];
    const isBossFloor = (f) => f % 10 === 0;
    const towerLevel = (f) => Math.min(100, 5 + 2 * f + (isBossFloor(f) ? 5 : 0));
    const towerFloor = async (o, f) => {
      const t = await deps.tables();
      const pool = TOWER_POOL.filter((r) => speciesOf(t, r));
      const rng = deps.rng ?? Math.random;
      const n = isBossFloor(f) ? 1 : 2 + Math.floor(rng() * 3);
      const rec = towerOf(o);
      rec.cf = f;
      rec.mf = Math.max(rec.mf, f);
      const forced = rec.force;
      rec.en = forced?.length ? forced : Array.from({ length: n }, () => String(pool[Math.floor(rng() * pool.length)]));
      delete rec.force;
      rec.alive = rec.en.map(() => true);
      rec.chest = false;
    };
    const floorReply = (rec) => ({ ca: isBossFloor(rec.cf), en: rec.en.map((r, i) => ({ raceId: rec.alive[i] ? r : "-1" })), cf: rec.cf });
    for (const [ext, sfx] of [["TowerExtension", ""], ["TeamTowerExtension", "_t"]]) {
      world.xt(`${ext}.56_1${sfx}`, async (ctx) => {
        const rec = towerOf(await deps.load(ctx));
        ctx.reply({ mf: rec.mf, cf: rec.cf, mtf: rec.mf, ctf: rec.cf }, `56_1${sfx}`);
      });
      world.xt(`${ext}.56_2${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        const rec = towerOf(o);
        if (battles.has(o.id)) return ctx.reply(floorReply(rec), `56_2${sfx}`);
        const fl = Math.max(1, Math.min(rec.mf, Number(ctx.params.fl ?? ctx.params.floor ?? rec.cf) | 0 || rec.cf));
        await towerFloor(o, fl);
        await deps.save(o);
        ctx.reply(floorReply(rec), `56_2${sfx}`);
      });
      world.xt(`${ext}.56_6${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        const rec = towerOf(o);
        if (!rec.en.length || !rec.alive.some(Boolean)) await towerFloor(o, rec.cf);
        await deps.save(o);
        ctx.reply(floorReply(rec), `56_6${sfx}`);
      });
      world.xt(`${ext}.56_3${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        const rec = towerOf(o);
        if (rec.alive.some(Boolean) || battles.has(o.id)) return ctx.reply({ result: 0 }, `56_3${sfx}`);
        if (rec.cf >= TOWER_FLOORS2) return ctx.reply({ result: -2 }, `56_3${sfx}`);
        await towerFloor(o, rec.cf + 1);
        await deps.save(o);
        ctx.reply({ result: 1, ...floorReply(rec) }, `56_3${sfx}`);
      });
      world.xt(`${ext}.56_5${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        const rec = towerOf(o);
        const i = Number(ctx.params.enId) | 0;
        const race = Number(rec.en[i]);
        if (!race || !rec.alive[i]) return ctx.reply({ enId: -1 }, `56_5${sfx}`);
        ctx.reply({ enId: i }, `56_5${sfx}`);
        const f = rec.cf;
        await begin(ctx, race, towerLevel(f), false, (owner) => {
          const r = towerOf(owner);
          if (r.cf === f) r.alive[i] = false;
          const coins = 10 + 2 * f;
          owner.score = (owner.score ?? 0) + coins;
          return [
            [`56_7${sfx}`, { bonus: [{ id: -1, type: 100, num: coins }] }],
            ["onScoreUpdated", { score: owner.score }]
          ];
        }, void 0, () => [[`56_10${sfx}`, {}]]);
      });
      world.xt(`${ext}.56_10${sfx}`, async (ctx) => ctx.reply({}, `56_10${sfx}`));
      world.xt(`${ext}.revival_tower${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        towerOf(o).force = String(ctx.params.en ?? "").split(",").filter(Boolean);
        await deps.save(o);
        ctx.reply({ ok: true }, `revival_tower${sfx}`);
      });
      world.xt(`${ext}.56_11${sfx}`, async (ctx) => {
        const rec = towerOf(await deps.load(ctx));
        ctx.reply({ res: isBossFloor(rec.cf) && !rec.alive.some(Boolean) && !rec.chest ? 1 : 0 }, `56_11${sfx}`);
      });
      world.xt(`${ext}.56_4${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        const rec = towerOf(o);
        if (!isBossFloor(rec.cf) || rec.alive.some(Boolean) || rec.chest) return ctx.reply({ res: 0, bonus: [] }, `56_4${sfx}`);
        rec.chest = true;
        const items = o.items ??= {};
        const bag3 = items["2"] ??= {};
        const id = rec.cf >= 50 ? 61 : 60;
        bag3[String(id)] = (bag3[String(id)] ?? 0) + 2;
        await deps.save(o);
        ctx.reply({ amount: `2_${id}_0_2` }, "onAmountUpdated");
        ctx.reply({ res: 1, bonus: [{ type: 2, id, num: 2 }] }, `56_4${sfx}`);
      });
    }
    const FB = "FBExtension";
    const fbOf = (o) => {
      const r = o.fb ??= {};
      if (r.day !== deps.today()) {
        r.day = deps.today();
        r.used = {};
      }
      return r;
    };
    const fbNow = () => deps.now?.() ?? Date.now();
    world.xt(`${FB}.fb_9`, async (ctx) => {
      const o = await deps.load(ctx);
      const r = fbOf(o);
      const id = Number(ctx.params.id) | 0;
      const best = r.best?.[id] ?? ["#", "#", "#"];
      ctx.reply({ id, g: best.some((g) => g !== "#"), lt: Math.max(0, FB_TIMES - (r.used?.[id] ?? 0)), bt: 0, gr: best.join(";") }, "fb_9");
    });
    world.xt(`${FB}.fb_6`, async (ctx) => {
      const r = fbOf(await deps.load(ctx));
      const id = Number(ctx.params.id) | 0;
      ctx.reply({ gr: (r.best?.[id] ?? ["#", "#", "#"]).join(";") }, "fb_6");
    });
    world.xt(`${FB}.fb_1`, async (ctx) => {
      const o = await deps.load(ctx);
      const r = fbOf(o);
      const asked = FBS[Number(ctx.params.id) | 0] ?? fbByName(String(ctx.params.name ?? ""));
      const def = asked && FBS.includes(asked) ? asked : void 0;
      const id = def ? FBS.indexOf(def) : -1;
      const used = r.used?.[id] ?? 0;
      if (!def || used >= FB_TIMES) return ctx.reply({ succ: false, task: false, score: false }, "fb_1");
      (r.used ??= {})[id] = used + 1;
      r.cur = { id, name: def.name, lv: Math.max(0, Math.min(2, Number(ctx.params.lv) | 0)), start: fbNow(), dead: {}, chests: [], n: used + 1 };
      await deps.save(o);
      ctx.reply({ succ: true }, "fb_1");
    });
    world.xt(`${FB}.fb_2`, async (ctx) => {
      const o = await deps.load(ctx);
      fbOf(o).cur = null;
      await deps.save(o);
      ctx.reply({}, "fb_2");
    });
    const fbHere = (o, ctx) => {
      const cur = fbOf(o).cur;
      const room = sceneOfRoom(ctx.player.room);
      const def = fbOfRoom(room);
      if (!cur || !def || def.name !== cur.name) return null;
      return { cur, room, def, pets: fbRoomPets(def, room, cur.lv, (cur.n ?? 1) - 1) };
    };
    world.xt(`${FB}.fb_3`, async (ctx) => {
      const o = await deps.load(ctx);
      const here = fbHere(o, ctx);
      if (!here || !here.def.rooms[here.room]?.wild) return ctx.reply({ pms: [] }, "fb_3");
      const dead = here.cur.dead[here.room] ?? [];
      ctx.reply({ pms: here.pets.filter((p) => !dead.includes(p.id)).map((p) => ({ raceId: p.code, id: p.id, lv: p.lv })) }, "fb_3");
    });
    world.xt(`${FB}.fb_7`, async (ctx) => {
      const o = await deps.load(ctx);
      const here = fbHere(o, ctx);
      if (here) delete here.cur.dead[here.room];
      await deps.save(o);
      ctx.reply({}, "fb_7");
    });
    world.xt(`${FB}.fb_8`, async (ctx) => {
      const o = await deps.load(ctx);
      if (battles.has(o.id)) return ctx.reply({ res: false }, "fb_8");
      const t = await deps.tables();
      for (const p of o.pets ?? []) {
        normalisePet(p, t);
        p.hp = statsOf(p, t)[0];
        for (const sk of p.skills) sk.pp = sk.max;
      }
      await deps.save(o);
      ctx.reply({ res: true }, "fb_8");
    });
    world.xt(`${FB}.fb_5`, async (ctx) => {
      const o = await deps.load(ctx);
      const here = fbHere(o, ctx);
      if (!here || here.cur.chests.includes(here.room)) return ctx.reply({ succ: false, bn: [] }, "fb_5");
      here.cur.chests.push(here.room);
      const coins = 100 * (here.cur.lv + 1);
      o.score = (o.score ?? 0) + coins;
      const bag3 = (o.items ??= {})["2"] ??= {};
      const candy = here.cur.lv > 0 ? 61 : 60;
      bag3[String(candy)] = (bag3[String(candy)] ?? 0) + 1;
      await deps.save(o);
      ctx.reply({ score: o.score }, "onScoreUpdated");
      ctx.reply({ amount: `2_${candy}_0_1` }, "onAmountUpdated");
      ctx.reply({ succ: true, bn: [{ type: 100, id: -1, num: coins }, { type: 2, id: candy, num: 1 }] }, "fb_5");
    });
    world.xt(`${FB}.fb_4`, async (ctx) => {
      const o = await deps.load(ctx);
      const r = fbOf(o);
      const cur = r.cur;
      if (!cur || !fbBossBeaten(cur)) return ctx.reply({ fin: false, bn: [], gr: "", tm: 0 }, "fb_4");
      const tm = Math.max(1, Math.round((fbNow() - cur.start) / 1e3));
      const gr = fbGrade(tm);
      const best = (r.best ??= {})[cur.id] ??= ["#", "#", "#"];
      best[cur.lv] = betterGrade(best[cur.lv], gr);
      const coins = fbPay(cur.lv, gr);
      o.score = (o.score ?? 0) + coins;
      r.cur = null;
      await deps.save(o);
      ctx.reply({ score: o.score }, "onScoreUpdated");
      ctx.reply({ fin: true, bn: [{ type: 100, id: -1, num: coins }], gr, tm }, "fb_4");
    });
    world.xt("PetExtension.54_17", async (ctx) => {
      const o = await deps.load(ctx);
      const here = fbHere(o, ctx);
      const id = Number(ctx.params.id) | 0;
      const pet = here?.pets.find((p) => p.id === id);
      if (!here || !pet) return ctx.reply({ msg: "\u8FD9\u91CC\u6CA1\u6709\u53EF\u4EE5\u6311\u6218\u7684\u4E9A\u6BD4\u3002" }, "2303");
      ensureFbSpecies((await deps.tables()).pm);
      const room = here.room;
      await begin(ctx, fbSpecies(pet.code), pet.lv, false, (owner) => {
        const cur = fbOf(owner).cur;
        if (cur) (cur.dead[room] ??= []).includes(id) || cur.dead[room].push(id);
        return [];
      }, pet.code, void 0, id);
    });
    world.xt("PetExtension2.54e_5", async (ctx) => {
      const o = await deps.load(ctx);
      const pet = (o.pets ?? []).find((p) => p.id === (Number(ctx.params.pid) | 0));
      const sid = Number(ctx.params.sid) | 0;
      const t = await deps.tables();
      if (!pet || !sid || !FILM_RACES.has(pet.race) || !t.pm.skills[String(sid)]) return ctx.reply({ res: false }, "54e_5");
      pet.learned = [.../* @__PURE__ */ new Set([...pet.learned ?? [], sid])];
      await deps.save(o);
      ctx.reply({ res: true, pid: pet.id, sid }, "54e_5");
    });
    world.xt("PetExtension.54_19", async (ctx) => {
      const o = await deps.load(ctx);
      ctx.reply({ bo: (o.bossMarks ?? []).join(",") }, "54_19");
    });
    world.xt("PetExtension.54_16", async (ctx) => {
      const asked = Number(String(ctx.params.raceId ?? "0").split("#")[0]) | 0;
      const index = Math.max(0, Number(ctx.params.index) | 0);
      if (!isGuardian(asked)) return ctx.reply({ msg: "\u8FD9\u91CC\u6CA1\u6709\u53EF\u4EE5\u6311\u6218\u7684\u5B88\u62A4\u8005\u3002" }, "2303");
      const t = await deps.tables();
      const species = BOSS_SPECIES[asked] ?? (speciesOf(t, asked % 1e4) ? asked % 1e4 : speciesOf(t, asked % 1e3) ? asked % 1e3 : asked % 1e4);
      const egg = BOSS_EGGS[asked] ?? (asked === 14523 || asked === 11514 || !lastGuardianForm(asked, index) ? 0 : eggOfLine(t, species));
      const mark = BOSS_MARKS[asked];
      const onWin = (o) => {
        const out = [];
        const items = o.items ??= {};
        const card = cardDrop(deps.rng ?? Math.random);
        if (card) {
          const cards = items[String(PET_CARD)] ??= {};
          cards[String(card)] = (cards[String(card)] ?? 0) + 1;
          out.push(["onAmountUpdated", { amount: `${PET_CARD}_${card}_0_1` }], [NOTE, { text: `\u83B7\u5F97\u4E86\u6218\u672F\u5361\u300C${PET_CARDS[card].name}\u300D\uFF01`, bn: { type: PET_CARD, id: card, num: 1 } }]);
        }
        let again = false;
        if (mark) {
          const marks = o.bossMarks ??= [];
          again = marks.includes(mark);
          if (!again) marks.push(mark);
        }
        if (!egg || again && FIRST_WIN_ONLY.has(asked)) return out;
        const eggs = items["5"] ??= {};
        eggs[String(egg)] = (eggs[String(egg)] ?? 0) + 1;
        return [...out, ["onAmountUpdated", { amount: `5_${egg}_0_1` }], [NOTE, { text: `\u83B7\u5F97\u4E86${nameOf(t, egg)}\u4E9A\u6BD4\u86CB\uFF01`, bn: { type: 5, id: egg, num: 1 } }]];
      };
      await begin(ctx, species, guardianLevel(asked, index), false, onWin, asked);
    });
    const turn = (name, run) => world.xt(`${PM}.${name}`, async (ctx) => {
      const o = await deps.load(ctx);
      const b = battles.get(o.id);
      if (!b || b.over) return ctx.reply({ msg: "\u6218\u6597\u8FD8\u6CA1\u6709\u5F00\u59CB" }, "2414");
      if (b.duel) return duels.command(name, ctx, b);
      const t = await deps.tables();
      const rebind = (f) => {
        const fresh2 = (o.pets ?? []).find((p) => p.id === f.pet.id);
        if (fresh2) {
          fresh2.hp = f.pet.hp;
          fresh2.skills = f.pet.skills;
          f.pet = fresh2;
        }
      };
      rebind(b.mine);
      const e = new BattleEngine(t, deps.rng);
      e.bag = o.pets;
      e.ownerRef = o;
      const out = await run(ctx, b, e, o, t);
      if (out === "end") {
        await deps.save(o);
        return;
      }
      if (!Array.isArray(out)) return send(ctx, out.refused);
      out.push(...finish(b, e, o, t, ctx));
      await deps.save(o);
      send(ctx, out);
    });
    const autoRestore = (b, o, t) => {
      if (!b.auto) return "";
      for (const p of o.pets ?? []) {
        p.hp = statsOf(p, t)[0];
        for (const s of p.skills) s.pp = s.max;
      }
      return "\u81EA\u52A8\u6218\u6597\u4EEA\u56DE\u590D\u4E86\u4E9A\u6BD4\u7684\u5168\u90E8\u72B6\u6001\u3002";
    };
    const finish = (b, e, o, t, ctx) => {
      const out = [];
      if (b.forceOut === 0 && b.mine.pet.hp > 0 && b.wild.pet.hp > 0) {
        const others = (o.pets ?? []).filter((p) => p.hp > 0 && p !== b.mine.pet);
        const gone = b.mine.pet;
        if (others.length) {
          const next = others[Math.floor((deps.rng ?? Math.random)() * others.length)];
          b.mine = fighter(0, next, o.id, t);
          const desc = `${gone.nick || nameOf(t, gone.race)}\u88AB\u5F3A\u5236\u66FF\u6362\u4E0B\u573A\uFF01
${next.nick || nameOf(t, next.race)}\u51FA\u6218\u4E86\uFF01`;
          out.push(["2413", { playerInfo: e.view(b, 0), extInfo: { desc, res: 1, forced: false } }]);
        } else out.push(["2421", { slotId: 0, hpInc: 0, desc: "\u6CA1\u6709\u53EF\u4EE5\u66FF\u6362\u7684\u4E9A\u6BD4\u3002", pmmList: e.views(b) }]);
      }
      b.forceOut = void 0;
      if (b.wild.pet.hp > 0 && b.mine.pet.hp > 0) out.push(...e.endOfTurn(b));
      if (b.wild.pet.hp <= 0) {
        b.over = true;
        let radarCoins = 0;
        const pet = b.mine.pet;
        const before = pet.race;
        const boosts = o.boosts ?? {};
        const mult = { exp: boosts.exp3 ? 3 : boosts.exp2 ? 2 : 1, ev: boosts.ev2 ? 2 : 1 };
        const r = b.noAward ? { msgs: [] } : award(t, pet, b.wild.pet.race, b.wild.pet.level, mult);
        out.push(...r.msgs);
        if (!b.noAward) {
          const used = [];
          for (const k of [mult.exp === 3 ? "exp3" : mult.exp === 2 ? "exp2" : "", mult.ev === 2 ? "ev2" : "", boosts.radar ? "radar" : ""]) {
            if (!k) continue;
            boosts[k] = Math.max(0, (boosts[k] ?? 0) - 1);
            if (!boosts[k]) delete boosts[k];
            used.push(k);
          }
          if (used.includes("radar")) {
            const rec = o;
            const coins = 50 + 5 * b.wild.pet.level;
            rec.score = Math.min(9999999, (rec.score ?? 0) + coins);
            out.push(["onScoreUpdated", { score: rec.score }]);
            radarCoins = coins;
          }
        }
        if (r.evolvedTo && o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
        const won = b.onWin ? b.onWin(o) : [];
        const notes = won.filter(([c]) => c === NOTE).map(([, m]) => String(m.text));
        const bn = won.filter(([c, m]) => c === NOTE && m.bn).map(([, m]) => m.bn);
        out.push(...won.filter(([c]) => c !== NOTE));
        const desc = (b.noAward ? "\u6218\u6597\u80DC\u5229\uFF01" : `\u6218\u6597\u80DC\u5229\uFF01${nameOf(t, before)}\u83B7\u5F97\u4E86\u7ECF\u9A8C\u3002${radarCoins ? `\u5BFB\u5B9D\u96F7\u8FBE\u627E\u5230\u4E86${radarCoins}\u6676\u5E01\uFF01` : ""}`) + autoRestore(b, o, t);
        out.push(["2403", { isWin: true, raceId: b.asked ?? b.wild.pet.race, id: b.copyId ?? 0, evolveFrom: r.evolvedTo ? before : 0, myFinalRaceId: before, desc, ...notes.length ? { note: notes.join("\n") } : {}, ...bn.length ? { bn } : {}, pmmList: e.views(b) }]);
        battles.delete(o.id);
        return out;
      }
      if (b.mine.pet.hp <= 0) {
        if ((o.pets ?? []).some((p) => p.hp > 0)) {
          b.mustSwitch = true;
          out.push(["2422", { slotId: 0, desc: "\u8BF7\u9009\u62E9\u4E0B\u4E00\u53EA\u51FA\u6218\u7684\u4E9A\u6BD4\u3002", pmmList: e.views(b) }]);
          return out;
        }
        b.over = true;
        if (b.onLose) out.push(...b.onLose(o));
        const healed = autoRestore(b, o, t);
        out.push(["2403", { isWin: false, raceId: b.asked ?? b.wild.pet.race, id: b.copyId ?? 0, myFinalRaceId: b.mine.pet.race, desc: healed ? `\u6218\u6597\u5931\u8D25\u4E86\u2026\u2026${healed}` : "\u4F60\u7684\u4E9A\u6BD4\u90FD\u5012\u4E0B\u4E86\u2026\u2026\u5FEB\u5E26\u5B83\u4EEC\u53BB\u6CBB\u7597\u5427\uFF01", pmmList: e.views(b) }]);
        battles.delete(o.id);
        return out;
      }
      b.turn++;
      const bf = b.mine.buff;
      if (bf && b.turn > bf.until) {
        b.mine.stats[bf.i] = Math.max(1, b.mine.stats[bf.i] - bf.add);
        b.mine.buff = void 0;
      }
      out.push(["2402", { turn: b.turn, pmmList: e.views(b) }]);
      return out;
    };
    const idle = (b, e, t) => {
      const pet = b.mine.pet;
      const name = pet.nick || nameOf(t, pet.race);
      const desc = pet.skills.every((s) => s.pp <= 0) ? `${name}\u7684\u6280\u80FD\u6B21\u6570\u7528\u5B8C\u4E86\uFF0C\u4EC0\u4E48\u4E5F\u6CA1\u6709\u505A\u3002` : `${name}\u4EC0\u4E48\u4E5F\u6CA1\u6709\u505A\u3002`;
      return [["2421", { slotId: 0, hpInc: 0, desc, pmmList: e.views(b) }], ...e.wildTurn(b)];
    };
    turn("1401", (_ctx, b, e, _o, t) => {
      if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "\u8BF7\u9009\u62E9\u4E0B\u4E00\u53EA\u51FA\u6218\u7684\u4E9A\u6BD4\u3002", pmmList: e.views(b) }]] };
      const id = Number(_ctx.params.skillId);
      const usable = b.mine.pet.skills.filter((s) => s.pp > 0);
      const forced = e.forcedOf(b.mine);
      if (!usable.length && forced === void 0) return idle(b, e, t);
      const chosen = usable.find((s) => s.id === id) ? id : usable.length ? usable[0].id : 0;
      return e.skillTurn(b, forced ?? chosen);
    });
    turn("1406", (_ctx, b, e, _o, t) => {
      if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "\u8BF7\u9009\u62E9\u4E0B\u4E00\u53EA\u51FA\u6218\u7684\u4E9A\u6BD4\u3002", pmmList: e.views(b) }]] };
      const forced = e.forcedOf(b.mine);
      if (forced !== void 0) return e.skillTurn(b, forced);
      return idle(b, e, t);
    });
    turn("1402", (ctx, b, e, o, t) => {
      const items = o.items ??= {};
      const bag3 = items["2"] ??= {};
      const id = Number(ctx.params.itemId);
      const pet = b.mine.pet;
      const name = pet.nick || nameOf(t, pet.race);
      const refuse = (desc2) => ({ refused: [["2412", { reqSId: 0, itemId: id, res: -1, refused: true, desc: desc2, pmmList: e.views(b) }]] });
      if (b.mustSwitch || !(bag3[id] > 0) || !POTIONS[id] && !PP_BEANS[id] && !CURES[id]) return refuse("\u8FD9\u4E2A\u9053\u5177\u73B0\u5728\u4E0D\u80FD\u4F7F\u7528\u3002");
      const f = b.mine;
      const cure = CURES[id];
      if (cure) {
        const has = cure === "all" ? !!f.status || f.sleep > 0 || f.confuse > 0 || f.bind > 0 || f.fear > 0 || f.weak > 0 || f.seeded || id === 101 && Object.values(f.stages).some((v) => v < 0) : cure === "\u7761\u7720" ? f.status === "\u7761\u7720" || f.sleep > 0 : cure === "\u6DF7\u4E71" ? f.confuse > 0 : cure === "\u5BC4\u751F" ? f.seeded : f.status === cure;
        if (!has) return refuse(`${name}\u6CA1\u6709\u9700\u8981\u89E3\u9664\u7684\u72B6\u6001\u3002`);
      } else if (POTIONS[id] && pet.hp >= f.stats[0]) return refuse(`${name}\u7684\u4F53\u529B\u662F\u6EE1\u7684\u3002`);
      bag3[id]--;
      if (bag3[id] <= 0) delete bag3[id];
      ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
      let hpInc = 0;
      let desc;
      if (cure) {
        if (cure === "all" || f.status === cure || cure === "\u7761\u7720" && f.sleep > 0) {
          f.status = void 0;
          f.statusLeft = 0;
        }
        if (cure === "all" || cure === "\u7761\u7720") f.sleep = 0;
        if (cure === "all" || cure === "\u6DF7\u4E71") f.confuse = 0;
        if (cure === "all" || cure === "\u5BC4\u751F") f.seeded = false;
        if (cure === "all") f.bind = f.fear = f.weak = 0;
        if (id === 101) for (const k of Object.keys(f.stages)) f.stages[k] = Math.max(0, f.stages[k]);
        desc = id === 101 ? `${name}\u7684\u4E0D\u5229\u72B6\u6001\u548C\u80FD\u529B\u4E0B\u964D\u90FD\u6D88\u9664\u4E86\uFF01` : cure === "all" ? `${name}\u7684\u4E0D\u5229\u72B6\u6001\u90FD\u6D88\u9664\u4E86\uFF01` : `${name}\u7684${cure}\u72B6\u6001\u89E3\u9664\u4E86\uFF01`;
      } else if (POTIONS[id]) {
        hpInc = Math.min(b.mine.stats[0] - pet.hp, POTIONS[id]);
        pet.hp += hpInc;
        desc = `${name}\u56DE\u590D\u4E86${hpInc}\u70B9\u4F53\u529B\uFF01`;
      } else {
        for (const s of pet.skills) s.pp = Math.min(s.max, s.pp + PP_BEANS[id]);
        desc = `${name}\u7684\u6280\u80FD\u6B21\u6570\u56DE\u590D\u4E86\uFF01`;
      }
      return [["2412", { reqSId: 0, itemId: id, res: 1, hpInc, desc, pmmList: e.views(b) }], ...e.wildTurn(b)];
    });
    turn("1403", (ctx, b, e, o, t) => {
      const id = Number(ctx.params.pmId);
      const next = (o.pets ?? []).find((p) => p.id === id);
      if (!next || next.hp <= 0 || next.id === b.mine.pet.id) {
        return { refused: [["2413", { playerInfo: e.view(b, 0), extInfo: { desc: "\u8FD9\u53EA\u4E9A\u6BD4\u4E0D\u80FD\u51FA\u6218\u3002", res: -1, refused: true } }]] };
      }
      const forced = b.mustSwitch;
      if (!forced && b.mine.trapped > 0) {
        return { refused: [["2413", { playerInfo: e.view(b, 0), extInfo: { desc: `${b.mine.pet.nick || nameOf(t, b.mine.pet.race)}\u65E0\u6CD5\u66FF\u6362\uFF01`, res: -1, refused: true } }]] };
      }
      b.mustSwitch = false;
      b.mine = fighter(0, next, o.id, t);
      if (b.nextHeal?.[0]) {
        b.nextHeal[0] = false;
        next.hp = b.mine.stats[0];
        for (const s of next.skills) s.pp = s.max;
      }
      const msg = ["2413", { playerInfo: e.view(b, 0), extInfo: { desc: `\u5C31\u51B3\u5B9A\u662F\u4F60\u4E86\uFF0C${next.nick || nameOf(t, next.race)}\uFF01`, res: 1, forced } }];
      return forced ? [msg] : [msg, ...e.wildTurn(b)];
    });
    turn("1404", (ctx, b, _e, o, t) => {
      b.over = true;
      battles.delete(o.id);
      if (b.onLose) for (const [c, body] of b.onLose(o)) ctx.reply(body, c);
      ctx.reply({ reqSId: 0, isEscape: true, raceId: b.asked ?? b.wild.pet.race, desc: "\u6210\u529F\u9003\u8DD1\u4E86\uFF01" + autoRestore(b, o, t) }, "2414");
      return "end";
    });
    turn("1405", (ctx, b, e, o, t) => {
      const items = o.items ??= {};
      const bag3 = items["2"] ??= {};
      const ball = Number(ctx.params.itemId);
      const clv = catchLevel(o.catchExp ?? 0).clv;
      const fail = (desc, refused = false) => ["2415", { reqId: o.id, tarSId: 1, itemId: ball, pmId: 0, lv: clv, lc: 0, refused, desc }];
      if (b.mustSwitch) return { refused: [fail("\u8BF7\u5148\u9009\u62E9\u51FA\u6218\u7684\u4E9A\u6BD4\u3002", true)] };
      if (!b.canCatch) return { refused: [fail("\u8FD9\u53EA\u4E9A\u6BD4\u4E0D\u80FD\u6355\u6349\uFF01", true)] };
      if (!(bag3[ball] > 0) || BALLS[ball] === void 0) return { refused: [fail("\u4F60\u6CA1\u6709\u8FD9\u79CD\u4E9A\u6BD4\u7403\u3002", true)] };
      if (BALLS[ball] < 1 && b.wild.pet.hp > b.wild.stats[0] * catchHpLimit(t, b.wild.pet.race)) return { refused: [fail("\u4E9A\u6BD4\u7684\u4F53\u529B\u8FD8\u5F88\u591A\uFF0C\u73B0\u5728\u8FD8\u6349\u4E0D\u5230\u5B83\u54E6\uFF01", true)] };
      bag3[ball]--;
      if (bag3[ball] <= 0) delete bag3[ball];
      ctx.reply({ amount: `2_${ball}_0_-1` }, "onAmountUpdated");
      const rng = deps.rng ?? Math.random;
      if (rng() >= catchChance(t, b.wild, ball, clv)) return [fail("\u54CE\u5440\uFF0C\u4E9A\u6BD4\u6323\u8131\u4E86\uFF01"), ...e.wildTurn(b)];
      const caught = b.wild.pet;
      caught.id = o.nextPetId = (o.nextPetId ?? 0) + 1;
      caught.got = deps.today();
      caught.ev = [0, 0, 0, 0, 0, 0];
      const pets = o.pets ??= [];
      const inBag = pets.length < 6;
      (inBag ? pets : o.storage ??= []).push(caught);
      const c = Number(speciesOf(t, caught.race)?.c[0]) || 1;
      o.catchExp = (o.catchExp ?? 0) + 10 + 5 * c;
      const lv = catchLevel(o.catchExp).clv;
      b.over = true;
      battles.delete(o.id);
      const healed = autoRestore(b, o, t);
      send(ctx, [
        ["2415", { reqId: o.id, tarSId: 1, itemId: ball, pmId: caught.id, raceId: caught.race, lv, lc: inBag ? 1 : 2, pet: briefOf(caught, o, t), desc: `\u6355\u6349\u6210\u529F\uFF01${nameOf(t, caught.race)}${inBag ? "\u8FDB\u5165\u4E86\u4F60\u7684\u4E9A\u6BD4\u80CC\u5305" : "\u88AB\u9001\u8FDB\u4E86\u4E9A\u6BD4\u4ED3\u5E93"}\u3002` }],
        ["2403", { isWin: true, isCatched: true, raceId: caught.race, desc: "\u6355\u6349\u6210\u529F\uFF01" + healed, pmmList: e.views(b) }],
        ...markDic(o, t, caught.race, OWNED) ? [NEW_RECORD] : []
      ]);
      return "end";
    });
    installGyms(world, { load: deps.load, save: deps.save, tables: deps.tables, today: deps.today, now: () => deps.now?.() ?? Date.now(), rng: deps.rng ?? Math.random });
    installSandbox(world, { load: deps.load, save: deps.save, tables: deps.tables, begin: (ctx, race, level, sandbox) => begin(ctx, race, level, false, void 0, void 0, void 0, void 0, sandbox) });
    world.xt(`${PM}.1307`, async (ctx) => {
      const o = await deps.load(ctx);
      const b = battles.get(o.id);
      if (b?.duel) duels.leave(b, o.id);
      else battles.delete(o.id);
      ctx.reply({}, "2308");
    });
    world.onLeaveGame?.((s) => {
      const p = world.player(s);
      const b = p ? battles.get(p.id) : void 0;
      if (p && b && !b.duel) battles.delete(p.id);
    });
  }

  // server/src/game/sfs2013/petitems.ts
  var STAT_NAMES = ["\u4F53\u529B", "\u653B\u51FB", "\u9632\u5FA1", "\u7279\u653B", "\u7279\u9632", "\u901F\u5EA6"];
  var HP_ITEMS = { 30: 40, 60: 100, 61: 200, 102: 300, 263: 400, 390: 200, 354: 200, 355: 200 };
  var PP_ITEMS = { 31: 5, 103: 10, 104: 20, 391: 20 };
  var CURES2 = [94, 95, 96, 97, 98, 99, 100, 101];
  var STARTER_EXP = { 233: 500, 234: 3e3, 235: 7e3, 236: 12e3, 237: 17e3, 238: 22e3, 239: 27e3, 240: 32e3, 241: 37e3 };
  var STARTER_RACES = [1, 2, 3, 500, 4, 5, 6, 501, 7, 8, 9, 502];
  var FRUIT_EXP = { 419: 1e3, 664: 5e3, 665: 4e5 };
  var EV_FRUITS = { 524: 0, 525: 1, 526: 2, 527: 3, 528: 4, 529: 5 };
  var FORGET = { 154: 1, 155: 2, 156: 3, 157: 4, 158: 5, 159: 0 };
  var NATURE_SETS = {
    414: ["\u5B64\u50FB", "\u52C7\u6562", "\u56FA\u6267", "\u8C03\u76AE"],
    415: ["\u60A0\u95F2", "\u6DD8\u6C14", "\u5927\u80C6", "\u65E0\u8651"],
    416: ["\u4FDD\u5B88", "\u9A6C\u864E", "\u7A33\u91CD", "\u51B7\u9759"],
    417: ["\u6E29\u987A", "\u6C89\u7740", "\u72C2\u5984", "\u614E\u91CD"],
    418: ["\u80C6\u5C0F", "\u5F00\u6717", "\u5929\u771F", "\u6025\u8E81"]
  };
  var BUFF_ITEMS = { 381: [3, 260], 382: [4, 260], 383: [1, 260], 384: [2, 260], 385: [5, 200] };
  var BOOST_ITEMS = {
    43: ["exp2", 50],
    120: ["exp2", 20],
    499: ["exp2", 50],
    378: ["exp3", 50],
    62: ["ev2", 30],
    189: ["radar", 20],
    663: ["radar", 20],
    44: ["auto", 100]
  };
  var EVO_STONES = {
    614: [1292, 1295],
    615: [1292, 1297],
    616: [1292, 1299],
    620: [1292, 1308],
    621: [1292, 1306],
    645: [371, 372],
    646: [371, 373],
    647: [371, 374],
    648: [371, 375]
  };
  var SKILL_STONES = {
    617: [1296, 10284, 40],
    618: [1298, 11297, 40],
    619: [1300, 13262, 40],
    622: [1309, 17260, 40],
    623: [1307, 19065, 40],
    631: [105, 16235, 60],
    632: [111, 16234, 60],
    642: [1381, 14317, 60],
    649: [372, 2226, 60],
    650: [373, 6215, 60],
    651: [374, 9223, 60],
    652: [375, 3221, 60],
    657: [592, 8257, 40]
  };
  var PET_ITEM_IDS = [
    ...Object.keys(HP_ITEMS),
    ...Object.keys(PP_ITEMS),
    ...CURES2,
    ...Object.keys(STARTER_EXP),
    ...Object.keys(FRUIT_EXP),
    ...Object.keys(EV_FRUITS),
    ...Object.keys(FORGET),
    523,
    63,
    65,
    66,
    193,
    220,
    ...Object.keys(NATURE_SETS),
    ...Object.keys(BUFF_ITEMS),
    ...Object.keys(BOOST_ITEMS),
    ...Object.keys(EVO_STONES),
    ...Object.keys(SKILL_STONES)
  ].map(Number);
  function firstForm(t, race) {
    const chain = (speciesOf(t, race)?.evo ?? "").split("#").map((s) => Number(s.split("-")[1])).filter((r) => r > 0);
    return chain.length && chain.includes(race) ? chain[0] : race;
  }
  function evolvesFurther(t, race) {
    const steps = (speciesOf(t, race)?.evo ?? "").split("#").map((s) => s.split("-").map(Number));
    const i = steps.findIndex(([, r]) => r === race);
    return i >= 0 && i + 1 < steps.length && steps[i + 1][0] > 0;
  }
  var no = (msg) => ({ ok: false, msg });
  function applyPetItem(t, o, ii, pet, rng = Math.random) {
    const boost = BOOST_ITEMS[ii];
    if (boost) {
      const [key, wins] = boost;
      const b = o.boosts ??= {};
      b[key] = (b[key] ?? 0) + wins;
      const what = { exp2: "\u6218\u6597\u7ECF\u9A8C\u7FFB\u500D", exp3: "\u6218\u6597\u7ECF\u9A8C\u7FFB\u4E09\u500D", ev2: "\u5B66\u4E60\u529B\u63D0\u5347\u52A0\u500D", radar: "\u6218\u6597\u80DC\u5229\u540E\u53EF\u4EE5\u5F97\u5230\u6676\u5E01", auto: "\u4E9A\u6BD4\u4F1A\u81EA\u5DF1\u6218\u6597" }[key];
      return { ok: true, msg: `\u63A5\u4E0B\u6765\u7684${b[key]}\u573A\u6218\u6597\u80DC\u5229\uFF0C${what}\uFF01` };
    }
    if (!pet) return no("\u8BF7\u5148\u9009\u62E9\u4E00\u53EA\u4E9A\u6BD4\u3002");
    const name = pet.nick || nameOf(t, pet.race);
    const max = statsOf(pet, t);
    if (HP_ITEMS[ii]) {
      if (pet.hp >= max[0]) return no(`${name}\u7684\u4F53\u529B\u662F\u6EE1\u7684\uFF0C\u4E0D\u9700\u8981\u6062\u590D\u54E6\u3002`);
      const before = pet.hp;
      pet.hp = Math.min(max[0], pet.hp + HP_ITEMS[ii]);
      return { ok: true, msg: `${name}\u6062\u590D\u4E86${pet.hp - before}\u70B9\u4F53\u529B\u3002` };
    }
    if (PP_ITEMS[ii]) {
      if (pet.skills.every((s) => s.pp >= s.max)) return no(`${name}\u7684\u6280\u80FD\u4F7F\u7528\u6B21\u6570\u662F\u6EE1\u7684\uFF0C\u4E0D\u9700\u8981\u6062\u590D\u54E6\u3002`);
      for (const s of pet.skills) s.pp = Math.min(s.max, s.pp + PP_ITEMS[ii]);
      return { ok: true, msg: `${name}\u7684\u6280\u80FD\u4F7F\u7528\u6B21\u6570\u6062\u590D\u4E86\uFF01` };
    }
    if (CURES2.includes(ii)) return no("\u8FD9\u4E2A\u836F\u5242\u8981\u5728\u6218\u6597\u4E2D\u4F7F\u7528\u54E6\uFF0C\u6218\u6597\u7ED3\u675F\u540E\u4E9A\u6BD4\u7684\u5F02\u5E38\u72B6\u6001\u5C31\u6D88\u5931\u4E86\u3002");
    const exp = STARTER_EXP[ii] ?? FRUIT_EXP[ii];
    if (exp) {
      if (STARTER_EXP[ii] && !STARTER_RACES.includes(pet.race)) return no("\u521D\u59CB\u4E9A\u6BD4\u7ECF\u9A8C\u7CD6\u53EA\u80FD\u5BF9\u5409\u62C9\u7CFB\u5217\u3001\u6EF4\u6EF4\u7CFB\u5217\u548C\u5154\u5C0F\u5B50\u7CFB\u5217\u7684\u4E9A\u6BD4\u4F7F\u7528\u54E6\uFF01");
      if (pet.level >= 100) return no(`${name}\u5DF2\u7ECF100\u7EA7\u4E86\uFF0C\u4E0D\u9700\u8981\u518D\u589E\u52A0\u7ECF\u9A8C\u5566\uFF01`);
      const before = pet.race;
      const r = gainExp(t, pet, exp);
      return { ok: true, msg: `${name}\u83B7\u5F97\u4E86${exp}\u70B9\u7ECF\u9A8C\uFF01`, msgs: r.msgs, raceChanged: pet.race !== before };
    }
    pet.ev ??= [0, 0, 0, 0, 0, 0];
    const ev = pet.ev;
    if (EV_FRUITS[ii] !== void 0) {
      const i = EV_FRUITS[ii];
      const total = ev.reduce((a, b) => a + b, 0);
      if (total >= 510) return no(`${name}\u7684\u5B66\u4E60\u529B\u5DF2\u7ECF\u6EE1510\u4E86\u54E6\uFF01`);
      if (ev[i] >= 255) return no(`${name}\u7684${STAT_NAMES[i]}\u5B66\u4E60\u529B\u5DF2\u7ECF\u6EE1255\u4E86\u54E6\uFF01`);
      const add = Math.min(5, 255 - ev[i], 510 - total);
      ev[i] += add;
      return { ok: true, msg: `${name}\u7684${STAT_NAMES[i]}\u5B66\u4E60\u529B\u589E\u52A0\u4E86${add}\u70B9\uFF01` };
    }
    if (FORGET[ii] !== void 0 || ii === 523 || ii === 63) {
      if (ii !== 63 && pet.level >= 100) return no("\u9057\u5FD8\u55B7\u96FE\u4E0D\u80FD\u5BF9100\u7EA7\u7684\u4E9A\u6BD4\u4F7F\u7528\uFF0C\u8BF7\u5148\u7528\u964D\u7EA7\u55B7\u96FE\u964D\u523099\u7EA7\u518D\u4F7F\u7528\u3002");
      if (FORGET[ii] !== void 0) {
        const i = FORGET[ii];
        if (ev[i] === 0) return no(`${name}\u7684${STAT_NAMES[i]}\u5B66\u4E60\u529B\u5DF2\u7ECF\u662F0\u4E86\u3002`);
        ev[i] = 0;
        return { ok: true, msg: `${name}\u7684${STAT_NAMES[i]}\u5B66\u4E60\u529B\u6E05\u7A7A\u4E86\u3002` };
      }
      if (ev.every((v) => v === 0)) return no(`${name}\u7684\u5B66\u4E60\u529B\u5DF2\u7ECF\u662F0\u4E86\u3002`);
      ev.fill(0);
      return { ok: true, msg: `${name}\u7684\u5B66\u4E60\u529B\u5168\u90E8\u6E05\u7A7A\u4E86\u3002` };
    }
    if (ii === 65) {
      if (pet.level <= 1) return no("\u964D\u7EA7\u55B7\u96FE\u4E0D\u80FD\u5BF91\u7EA7\u7684\u4E9A\u6BD4\u4F7F\u7528\u3002");
      pet.level--;
      pet.exp = 0;
      pet.hp = Math.min(pet.hp, statsOf(pet, t)[0]);
      return { ok: true, msg: `${name}\u964D\u5230\u4E86${pet.level}\u7EA7\u3002` };
    }
    if (ii === 193) {
      const first = firstForm(t, pet.race);
      if (first === pet.race && pet.level === 1) return no(`${name}\u5DF2\u7ECF\u662F\u7B2C\u4E00\u5F62\u6001\u76841\u7EA7\u4E9A\u6BD4\u4E86\u3002`);
      const before = pet.race;
      pet.race = first;
      pet.level = 1;
      pet.exp = 0;
      pet.fixed = void 0;
      pet.hp = Math.min(pet.hp, statsOf(pet, t)[0]);
      return { ok: true, msg: `${name}\u8FD8\u539F\u6210\u4E861\u7EA7\u7684${nameOf(t, first)}\uFF0C\u6027\u683C\u3001\u6280\u80FD\u548C\u5B66\u4E60\u529B\u90FD\u4FDD\u7559\u7740\u3002`, raceChanged: before !== first };
    }
    if (ii === 220) {
      if (pet.fixed) return no(`${name}\u7684\u5F62\u6001\u5DF2\u7ECF\u56FA\u5316\u4E86\u3002`);
      if (!evolvesFurther(t, pet.race)) return no(`${name}\u5DF2\u7ECF\u4E0D\u4F1A\u518D\u8FDB\u5316\u4E86\uFF0C\u4E0D\u9700\u8981\u56FA\u5316\u5F62\u6001\u54E6\u3002`);
      pet.fixed = true;
      return { ok: true, msg: `${name}\u7684\u5F62\u6001\u56FA\u5316\u4E86\uFF01\u4EE5\u540E\u5347\u7EA7\u4E5F\u4E0D\u4F1A\u518D\u8FDB\u5316\u3002` };
    }
    if (ii === 66 || NATURE_SETS[ii]) {
      const pool = (NATURE_SETS[ii] ?? NATURE_NAMES).filter((n) => n !== pet.character);
      const next = pool[Math.floor(rng() * pool.length)] ?? pet.character;
      const before = pet.character;
      pet.character = next;
      pet.hp = Math.min(pet.hp, statsOf(pet, t)[0]);
      return { ok: true, msg: `${name}\u7684\u6027\u683C\u4ECE${before}\u53D8\u6210\u4E86${next}\uFF01` };
    }
    if (BUFF_ITEMS[ii]) {
      const [i, add] = BUFF_ITEMS[ii];
      pet.buff = { i, add };
      return { ok: true, msg: `${name}\u7684\u4E0B\u4E00\u573A\u6218\u6597\u4E2D\uFF0C\u524D${BUFF_ROUNDS}\u56DE\u5408${STAT_NAMES[i]}\u63D0\u5347${add}\u70B9\uFF01\uFF08\u4E0D\u80FD\u7528\u5728\u548C\u5176\u4ED6\u5965\u62C9\u7684\u4E9A\u6BD4\u7684\u5BF9\u6218\u4E2D\uFF09` };
    }
    const evo = EVO_STONES[ii];
    if (evo) {
      const [from, to] = evo;
      if (pet.race !== from) return no(`\u53EA\u6709${nameOf(t, from)}\u624D\u53EF\u4EE5\u4F7F\u7528\u8FD9\u5757\u8FDB\u5316\u77F3\u54E6\uFF01`);
      if (!speciesOf(t, to)) return no("\u8FD9\u5757\u8FDB\u5316\u77F3\u73B0\u5728\u8FD8\u4E0D\u80FD\u4F7F\u7528\u3002");
      pet.race = to;
      pet.learned = learntFor(t, to, pet.level, pet.skills);
      pet.hp = Math.min(statsOf(pet, t)[0], pet.hp);
      return { ok: true, msg: `${name}\u8FDB\u5316\u6210\u4E86${nameOf(t, to)}\uFF01`, raceChanged: true };
    }
    const stone = SKILL_STONES[ii];
    if (stone) {
      const [race, skill, lv] = stone;
      if (pet.race !== race) return no(`\u53EA\u6709${nameOf(t, race)}\u624D\u53EF\u4EE5\u5B66\u4E60\u8FD9\u4E2A\u6280\u80FD\u54E6\uFF01`);
      if (pet.level < lv) return no(`\u53EA\u6709\u8FBE\u5230${lv}\u7EA7\u6216\u4EE5\u4E0A\u7684${nameOf(t, race)}\u624D\u53EF\u4EE5\u5B66\u4E60\u8FD9\u4E2A\u6280\u80FD\u54E6\uFF01`);
      pet.learned ??= pet.skills.map((s) => s.id);
      if (pet.learned.includes(skill)) return no(`${name}\u5DF2\u7ECF\u5B66\u4F1A${skillOf(t, skill).name}\u4E86\u3002`);
      pet.learned.push(skill);
      const carried = pet.skills.length < 4;
      if (carried) pet.skills.push(skillOf(t, skill));
      return { ok: true, msg: `${name}\u5B66\u4F1A\u4E86${skillOf(t, skill).name}\uFF01${carried ? "" : "\u53EF\u4EE5\u5728\u4E9A\u6BD4\u80CC\u5305\u7684\u201C\u66F4\u6362\u6280\u80FD\u201D\u4E2D\u5E26\u4E0A\u5B83\u3002"}` };
    }
    if (ii === 34 || ii === 35) return no("DNA\u82AF\u7247\u8981\u5728\u4E9A\u6BD4\u514B\u9686\u4EEA\u548C\u4E9A\u6BD4\u91CD\u7EC4\u4EEA\u91CC\u4F7F\u7528\u54E6\u3002");
    return no("\u8FD9\u4E2A\u9053\u5177\u4E0D\u80FD\u5BF9\u4E9A\u6BD4\u4F7F\u7528\u54E6\u3002");
  }
  function installPetItems(world, deps) {
    world.xt("MaterialExtension.14_12", async (ctx) => {
      const ii = Number(ctx.params.ii) | 0;
      const pi = Number(ctx.params.pi) | 0;
      const o = await deps.load(ctx);
      const t = await deps.tables();
      const reply = (res, msg) => ctx.reply({ res, ii, pi, msg });
      if (inFight(world, o.id ?? -1)) return reply(0, "\u6218\u6597\u4E2D\u4E0D\u80FD\u8FD9\u6837\u4F7F\u7528\u9053\u5177\u54E6\u3002");
      const bag3 = (o.items ??= {})["2"] ??= {};
      if ((bag3[String(ii)] ?? 0) < 1) return reply(0, "\u4F60\u6CA1\u6709\u8FD9\u4E2A\u9053\u5177\u54E6\u3002");
      const pet = pi > 0 ? [...o.pets ?? [], ...o.storage ?? []].find((p) => p.id === pi) : void 0;
      if (pi > 0 && !pet) return reply(0, "\u627E\u4E0D\u5230\u8FD9\u53EA\u4E9A\u6BD4\u3002");
      const r = applyPetItem(t, o, ii, pet);
      if (!r.ok) return reply(0, r.msg);
      const left = bag3[String(ii)] - 1;
      if (left > 0) bag3[String(ii)] = left;
      else delete bag3[String(ii)];
      await deps.save(o);
      ctx.reply({ amount: `2_${ii}_0_-1` }, "onAmountUpdated");
      for (const [cmd, body] of r.msgs ?? []) ctx.reply(body, cmd);
      if (r.raceChanged && pet) deps.changedRace?.(ctx, o, pet);
      reply(1, r.msg);
    });
  }

  // server/src/game/sfs2013/accounts.ts
  var ITERATIONS = 6e4;
  var hex = (b) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("");
  async function hashPass(pass, salt, iter = ITERATIONS) {
    const subtle = globalThis.crypto.subtle;
    const s = salt ?? hex(globalThis.crypto.getRandomValues(new Uint8Array(16)));
    const key = await subtle.importKey("raw", new TextEncoder().encode(pass), "PBKDF2", false, ["deriveBits"]);
    const bits = await subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: new TextEncoder().encode(s), iterations: iter }, key, 256);
    return { salt: s, hash: hex(bits), iter };
  }
  async function checkPass(pass, rec) {
    const h = await hashPass(pass, rec.salt, rec.iter);
    let diff = 0;
    for (let i = 0; i < h.hash.length; i++) diff |= h.hash.charCodeAt(i) ^ rec.hash.charCodeAt(i);
    return diff === 0 && h.hash.length === rec.hash.length;
  }
  function nameProblem(name) {
    const n = name.trim();
    if (!n) return "\u8BF7\u8F93\u5165\u5965\u62C9\u7684\u540D\u5B57\u3002";
    if ([...n].length > 12) return "\u540D\u5B57\u6700\u591A12\u4E2A\u5B57\u3002";
    if (/[\s#;,|<>&"'\\/%_:=]/.test(n) || /[\u0000-\u001f]/.test(n)) return "\u540D\u5B57\u91CC\u4E0D\u80FD\u6709\u7A7A\u683C\u548C\u7B26\u53F7\u3002";
    return null;
  }
  var FAILS_MAX = 5;
  var FAIL_WINDOW_MS = 10 * 60 * 1e3;
  var LOCK_MS = 60 * 1e3;
  var LOCKED = "\u5BC6\u7801\u9519\u4E86\u592A\u591A\u6B21\uFF0C\u8BF7\u8FC7\u4E00\u5206\u949F\u518D\u8BD5\u3002";
  var PassGuard = class {
    fails = /* @__PURE__ */ new Map();
    now;
    constructor(now = Date.now) {
      this.now = now;
    }
    /** The name takes no password now. */
    locked(name) {
      const f = this.fails.get(name);
      return !!f && f.until > this.now();
    }
    failed(name) {
      const t = this.now();
      let f = this.fails.get(name);
      if (!f || t - f.first > FAIL_WINDOW_MS) f = { n: 0, first: t, until: 0 };
      f.n++;
      if (f.n >= FAILS_MAX) {
        f.until = t + LOCK_MS;
        f.n = 0;
        f.first = t;
      }
      this.fails.set(name, f);
      if (this.fails.size > 1e4) {
        for (const [k, v] of this.fails) if (t - v.first > FAIL_WINDOW_MS && v.until <= t) this.fails.delete(k);
      }
    }
    passed(name) {
      this.fails.delete(name);
    }
  };

  // server/src/game/sfs2013/social.ts
  var TEAM_MAX = 3;
  var INVITE_MS = 5 * 60 * 1e3;
  var ASK_EVERY_MS = 10 * 1e3;
  var MOD_EVENT_MAX = 4096;
  var PRIVATE_MAX = 100;
  var FRIENDS_MAX = 100;
  function installSocial(world, deps) {
    const where = (name) => {
      const s = world.online(name);
      const room = s ? world.player(s)?.room?.name ?? "" : "";
      return { online: !!s, room };
    };
    const pushTo = (name, cmd, obj) => {
      const s = world.online(name);
      if (s) world.push(s, cmd, obj);
    };
    const asked = /* @__PURE__ */ new Map();
    const mayAsk = (from, to, kind) => {
      const k = `${kind}\0${from}\0${to}`, now = Date.now();
      if (now - (asked.get(k) ?? -Infinity) < ASK_EVERY_MS) return false;
      if (asked.size > 1e4) asked.clear();
      asked.set(k, now);
      return true;
    };
    world.xt("BuddyManagerExtension.revival_friends", async (ctx) => {
      const o = await deps.load(ctx);
      const list = [];
      for (const id of o.friends ?? []) {
        const name = await deps.nameOf(id);
        if (name) list.push({ id, name, ...where(name) });
      }
      list.sort((a, b) => Number(b.online) - Number(a.online) || a.name.localeCompare(b.name));
      const asks = [];
      for (const id of o.friendAsks ?? []) {
        const name = await deps.nameOf(id);
        if (name) asks.push({ id, name });
      }
      ctx.reply({ list, asks }, "revival_friends");
    });
    world.xt("BuddyManagerExtension.revival_friend_add", async (ctx) => {
      const reply = (res, msg) => ctx.reply({ res, msg }, "revival_friend_add");
      const o = await deps.load(ctx);
      const name = String(ctx.params.name ?? "").trim();
      if (!name || name === o.name) return reply(0, "\u4E0D\u80FD\u52A0\u81EA\u5DF1\u4E3A\u597D\u53CB\u54E6\u3002");
      const other = await deps.byName(name);
      if (!other) return reply(0, `\u6CA1\u6709\u53EB\u201C${name}\u201D\u7684\u5965\u62C9\u3002`);
      if ((o.friends ?? []).includes(other.id)) return reply(0, `${name}\u5DF2\u7ECF\u662F\u4F60\u7684\u597D\u53CB\u4E86\u3002`);
      if ((o.friends ?? []).length >= FRIENDS_MAX) return reply(0, "\u4F60\u7684\u597D\u53CB\u5DF2\u7ECF\u6EE1\u4E86\u3002");
      if ((other.friends ?? []).length >= FRIENDS_MAX) return reply(0, `${name}\u7684\u597D\u53CB\u5DF2\u7ECF\u6EE1\u4E86\u3002`);
      if ((o.friendAsks ?? []).includes(other.id)) return befriend(ctx, o, other, reply);
      if (!mayAsk(o.name, other.name, "friend")) return reply(0, "\u521A\u521A\u5DF2\u7ECF\u9080\u8BF7\u8FC7\u4E86\uFF0C\u7B49\u5BF9\u65B9\u56DE\u7B54\u5427\u3002");
      other.friendAsks = [.../* @__PURE__ */ new Set([...other.friendAsks ?? [], o.id])].slice(-50);
      await deps.save(other);
      pushTo(other.name, "revival_friend_ask", { id: o.id, name: o.name });
      reply(1, `\u5DF2\u7ECF\u5411${name}\u53D1\u51FA\u597D\u53CB\u9080\u8BF7\uFF0C\u7B49\u5F85\u5BF9\u65B9\u540C\u610F\u3002`);
    });
    const befriend = async (ctx, o, other, reply) => {
      if ((o.friends ?? []).length >= FRIENDS_MAX || (other.friends ?? []).length >= FRIENDS_MAX) {
        o.friendAsks = (o.friendAsks ?? []).filter((id) => id !== other.id);
        await deps.save(o);
        return reply(0, "\u597D\u53CB\u5DF2\u7ECF\u6EE1\u4E86\u3002");
      }
      o.friends = [.../* @__PURE__ */ new Set([...o.friends ?? [], other.id])];
      other.friends = [.../* @__PURE__ */ new Set([...other.friends ?? [], o.id])];
      o.friendAsks = (o.friendAsks ?? []).filter((id) => id !== other.id);
      other.friendAsks = (other.friendAsks ?? []).filter((id) => id !== o.id);
      await deps.save(o);
      await deps.save(other);
      pushTo(other.name, "revival_friend_added", { id: o.id, name: o.name });
      reply(1, `${other.name}\u548C\u4F60\u6210\u4E3A\u597D\u53CB\u4E86\uFF01`);
    };
    world.xt("BuddyManagerExtension.revival_friend_answer", async (ctx) => {
      const reply = (res, msg) => ctx.reply({ res, msg }, "revival_friend_answer");
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      if (!(o.friendAsks ?? []).includes(id)) return reply(0, "\u8FD9\u4E2A\u9080\u8BF7\u5DF2\u7ECF\u8FC7\u671F\u4E86\u3002");
      const name = await deps.nameOf(id);
      const other = name ? await deps.byName(name) : void 0;
      if (!other || ctx.params.ok !== true && ctx.params.ok !== 1 && ctx.params.ok !== "1" && ctx.params.ok !== "true") {
        o.friendAsks = (o.friendAsks ?? []).filter((x) => x !== id);
        await deps.save(o);
        return reply(1, "\u5DF2\u7ECF\u62D2\u7EDD\u4E86\u3002");
      }
      return befriend(ctx, o, other, reply);
    });
    world.xt("BuddyManagerExtension.revival_friend_del", async (ctx) => {
      const o = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      o.friends = (o.friends ?? []).filter((x) => x !== id);
      await deps.save(o);
      const name = await deps.nameOf(id);
      const other = name ? await deps.byName(name) : void 0;
      if (other) {
        other.friends = (other.friends ?? []).filter((x) => x !== o.id);
        await deps.save(other);
      }
      ctx.reply({ res: 1, id }, "revival_friend_del");
    });
    world.xt("BuddyManagerExtension.revival_where", async (ctx) => {
      const name = String(ctx.params.name ?? "");
      const me = ctx.player.name;
      const t = teamOf(me);
      let known = !!t && t.members.includes(name);
      if (!known) {
        const [o, other] = [await deps.load(ctx), await deps.byName(name)];
        known = !!other && (o.friends ?? []).includes(other.id);
      }
      ctx.reply(known ? { name, ...where(name) } : { name, online: false, room: "" }, "revival_where");
    });
    const teams = /* @__PURE__ */ new Map();
    const teamOf = (name) => teams.get(name);
    const newTeam = (leader) => ({ leader, members: [leader] });
    const alone = (room) => room.includes("@");
    const invites = /* @__PURE__ */ new Map();
    const invited = (name, leader) => {
      const at = invites.get(name)?.get(leader);
      return at != null && Date.now() - at < INVITE_MS;
    };
    const tell = (t) => {
      for (const m of t.members) pushTo(m, "revival_team", { team: t });
    };
    const leave = (name) => {
      const t = teams.get(name);
      if (!t) return;
      teams.delete(name);
      t.members = t.members.filter((m) => m !== name);
      pushTo(name, "revival_team", { team: null });
      if (t.members.length === 0) return;
      if (t.leader === name) t.leader = t.members[0];
      if (t.members.length === 1) {
        teams.delete(t.members[0]);
        pushTo(t.members[0], "revival_team", { team: null });
        return;
      }
      tell(t);
    };
    world.onLeaveGame((s) => {
      const p = world.player(s);
      if (!p) return;
      leave(p.name);
      invites.delete(p.name);
    });
    world.xt("TeamExtension.revival_team", (ctx) => ctx.reply({ team: teamOf(ctx.player.name) ?? null }, "revival_team"));
    world.xt("TeamExtension.revival_team_make", (ctx) => {
      const me = ctx.player.name;
      let t = teamOf(me);
      if (!t) {
        t = newTeam(me);
        teams.set(me, t);
      }
      ctx.reply({ team: t }, "revival_team");
    });
    world.xt("TeamExtension.revival_team_invite", (ctx) => {
      const reply = (res, msg) => ctx.reply({ res, msg }, "revival_team_invite");
      const me = ctx.player.name;
      const name = String(ctx.params.name ?? "").trim();
      if (!name || name === me) return reply(0, "\u4E0D\u80FD\u9080\u8BF7\u81EA\u5DF1\u54E6\u3002");
      if (!world.online(name)) return reply(0, `${name}\u73B0\u5728\u4E0D\u5728\u5965\u62C9\u661F\u4E0A\u3002`);
      if (teamOf(name)) return reply(0, `${name}\u5DF2\u7ECF\u5728\u4E00\u4E2A\u961F\u4F0D\u91CC\u4E86\u3002`);
      let t = teamOf(me);
      if (!t) {
        t = newTeam(me);
        teams.set(me, t);
        ctx.reply({ team: t }, "revival_team");
      }
      if (t.leader !== me) return reply(0, "\u53EA\u6709\u961F\u957F\u624D\u80FD\u9080\u8BF7\u961F\u5458\u54E6\u3002");
      if (t.members.length >= TEAM_MAX) return reply(0, `\u961F\u4F0D\u6700\u591A${TEAM_MAX}\u4E2A\u4EBA\u3002`);
      if (!mayAsk(me, name, "team")) return reply(0, "\u521A\u521A\u5DF2\u7ECF\u9080\u8BF7\u8FC7\u4E86\uFF0C\u7B49\u5BF9\u65B9\u56DE\u7B54\u5427\u3002");
      let mine = invites.get(name);
      if (!mine) invites.set(name, mine = /* @__PURE__ */ new Map());
      mine.set(me, Date.now());
      pushTo(name, "revival_team_ask", { leader: me });
      reply(1, `\u5DF2\u7ECF\u9080\u8BF7${name}\u52A0\u5165\u961F\u4F0D\u3002`);
    });
    world.xt("TeamExtension.revival_team_join", (ctx) => {
      const me = ctx.player.name;
      const leader = String(ctx.params.leader ?? "");
      if (!invited(me, leader)) return ctx.reply({ team: teamOf(me) ?? null, msg: "\u8FD9\u4E2A\u9080\u8BF7\u5DF2\u7ECF\u8FC7\u671F\u4E86\u3002" }, "revival_team");
      invites.get(me)?.delete(leader);
      const t = teamOf(leader);
      if (!t || t.leader !== leader) return ctx.reply({ team: teamOf(me) ?? null, msg: "\u8FD9\u4E2A\u961F\u4F0D\u5DF2\u7ECF\u89E3\u6563\u4E86\u3002" }, "revival_team");
      if (teamOf(me) === t) return ctx.reply({ team: t }, "revival_team");
      if (t.members.length >= TEAM_MAX) return ctx.reply({ team: teamOf(me) ?? null, msg: "\u961F\u4F0D\u5DF2\u7ECF\u6EE1\u4E86\u3002" }, "revival_team");
      if (teamOf(me)) leave(me);
      if (teams.get(leader) !== t) return ctx.reply({ team: null, msg: "\u8FD9\u4E2A\u961F\u4F0D\u5DF2\u7ECF\u89E3\u6563\u4E86\u3002" }, "revival_team");
      t.members.push(me);
      teams.set(me, t);
      tell(t);
      const room = world.online(leader) ? world.player(world.online(leader))?.room?.name : "";
      if (room && !alone(room)) world.push(ctx.session, "revival_team_go", { room, leader });
    });
    world.xt("TeamExtension.revival_team_leave", (ctx) => leave(ctx.player.name));
    world.xt("TeamExtension.revival_team_go", (ctx) => {
      const me = ctx.player.name;
      const t = teamOf(me);
      if (!t || t.leader !== me) return;
      const room = ctx.player.room?.name ?? "";
      if (!room || alone(room) || String(ctx.params.room ?? "") !== room) return;
      for (const m of t.members) if (m !== me) pushTo(m, "revival_team_go", { room, leader: me });
    });
    const paced = /* @__PURE__ */ new Map();
    const pace = (name, perSecond) => {
      const now = Date.now();
      const p = paced.get(name);
      if (!p || now - p.at >= 1e3) {
        paced.set(name, { at: now, n: 1 });
        if (paced.size > 1e4) paced.clear();
        return true;
      }
      return ++p.n <= perSecond;
    };
    world.xt("BuddyManagerExtension.privateMsg", async (ctx) => {
      const to = String(ctx.params.to ?? "").slice(0, 64);
      const text = String(ctx.params.msg ?? "").replace(/^\[1\]/, "").trim().slice(0, PRIVATE_MAX);
      const fail = (msg) => ctx.reply({ res: 0, to, msg }, "privateMsg");
      if (!to || !text) return;
      if (!pace(`pm\0${ctx.player.name}`, 2)) return fail("\u8BF4\u5F97\u592A\u5FEB\u4E86\uFF0C\u6B47\u4E00\u4F1A\u513F\u518D\u8BF4\u5427\u3002");
      const o = await deps.load(ctx);
      const other = to === o.name ? void 0 : await deps.byName(to);
      if (!other || !(o.friends ?? []).includes(other.id)) return fail("\u53EA\u80FD\u548C\u597D\u53CB\u79C1\u804A\u54E6\u3002");
      if (!world.online(other.name)) return fail(`${other.name}\u4E0D\u5728\u7EBF\uFF0C\u6CA1\u6709\u53D1\u51FA\u53BB\u3002`);
      pushTo(other.name, "onPrivateMsg", { from: o.name, msg: "[1]" + text });
    });
    world.xt("TeamExtension.revival_team_mod", (ctx) => {
      const t = teamOf(ctx.player.name);
      if (!t || !pace(ctx.player.name, 20)) return;
      const mod = String(ctx.params.mod ?? ""), ver = String(ctx.params.ver ?? "");
      const event = String(ctx.params.event ?? "").slice(0, 64), data = String(ctx.params.data ?? "null");
      if (!t || !mod || mod.length > 32 || ver.length > 20 || !event || data.length > MOD_EVENT_MAX) return;
      for (const m of t.members) if (m !== ctx.player.name) pushTo(m, "revival_team_mod", { from: ctx.player.name, mod, ver, event, data });
    });
    world.xt("TeamExtension.revival_team_say", (ctx) => {
      const t = teamOf(ctx.player.name);
      const text = String(ctx.params.text ?? "").slice(0, 80);
      if (!t || !text || !pace(ctx.player.name, 3)) return;
      for (const m of t.members) pushTo(m, "revival_team_said", { name: ctx.player.name, text });
    });
    return { teamOf };
  }

  // server/src/game/sfs2013/house.ts
  var DEFAULT_HOUSE_ID = 1;
  var DEFAULT_FURNITURE = { "1": 1, "7": 1 };
  function houseOf(o) {
    const furniture = (o.items ??= {})["1"] ??= {};
    if (!o.house) {
      o.house = { hid: DEFAULT_HOUSE_ID, placed: {} };
      for (const [id, q] of Object.entries(DEFAULT_FURNITURE)) furniture[id] ??= q;
    }
    furniture[String(o.house.hid)] ??= 1;
    return o.house;
  }
  function usedUp(o) {
    const h = houseOf(o);
    const used = {};
    for (const list of Object.values(h.placed)) for (const p of list) used[p.fid] = (used[p.fid] ?? 0) + 1;
    used[h.hid] = (used[h.hid] ?? 0) + 1;
    return used;
  }
  var VISITS_KEPT = 20;
  var HOME_ROOM = /^(.+)_(-?\d+)_Home$/;
  function plainExd(v) {
    if (v == null) return void 0;
    try {
      const text = JSON.stringify(v);
      return text && text.length <= 2e3 ? JSON.parse(text) : void 0;
    } catch {
      return void 0;
    }
  }
  function installHouse(world, deps) {
    world.xt("HouseExtension.62_1", async (ctx) => {
      const un = String(ctx.params.un ?? ctx.player.name);
      const o = await deps.find(un);
      if (!o) return ctx.reply({ un, hid: 0 });
      const fresh2 = !o.house;
      const h = houseOf(o);
      if (fresh2 && o.name === ctx.player.name) await deps.save(o);
      const count = (await deps.visits?.get(o.id))?.count ?? 0;
      ctx.reply({ un: o.name, hid: h.hid, nn: o.name, count });
    });
    world.xt("HouseExtension.62_3", async (ctx) => {
      const un = String(ctx.params.userName ?? ctx.player.name);
      const o = await deps.find(un);
      const v = o ? await deps.visits?.get(o.id) : void 0;
      const visitors = [];
      for (const [id, t] of v?.recent ?? []) {
        const name = await deps.visits.nameOf(id);
        if (name) visitors.push({ un: name, t });
      }
      ctx.reply({ userName: un, count: v?.count ?? 0, visitors, now: deps.now?.() ?? Date.now() });
    });
    world.xt("UserFurntitureInfoExtension.63_1", async (ctx) => {
      const un = String(ctx.params.un ?? ctx.player.name);
      const o = await deps.find(un);
      const list = o ? houseOf(o).placed[String(Number(ctx.params.hid))] ?? [] : [];
      ctx.reply({ un, hid: Number(ctx.params.hid), infos: list.map((p) => ({ fid: p.fid, key: p.key, x: p.x, y: p.y, ag: p.a, ex: p.exd ?? null })) });
    });
    world.xt("UserFurntitureInfoExtension.63_2", async (ctx) => {
      const o = await deps.me(ctx);
      const h = houseOf(o);
      const hid = String(Number(ctx.params.hid));
      const changes = ctx.params.changes;
      if (!Array.isArray(changes) || changes.length === 0) return ctx.reply({ result: -2 });
      const list = [...h.placed[hid] ?? []];
      for (const c of changes) {
        const fid = Number(c.fid), key = Number(c.key), op = Number(c.op);
        const at = list.findIndex((p2) => p2.fid === fid && p2.key === key);
        const p = { fid, key, x: Math.round(Number(c.x)), y: Math.round(Number(c.y)), a: Number(c.a) || 0, exd: plainExd(c.exd) };
        if (op === 1) {
          if (at >= 0) return ctx.reply({ result: -3 });
          list.push(p);
        } else if (op === 2) {
          if (at >= 0) list[at] = p;
          else list.push(p);
        } else if (op === 3) {
          if (at >= 0) list.splice(at, 1);
        }
      }
      const trial = { ...o, house: { ...h, placed: { ...h.placed, [hid]: list } } };
      const used = usedUp(trial);
      const owned = o.items["1"] ?? {};
      for (const [fid, n] of Object.entries(used)) if (n > (owned[fid] ?? 0)) return ctx.reply({ result: -4 });
      h.placed[hid] = list;
      await deps.save(o);
      ctx.reply({ result: 1 });
    });
    const changeHouse = async (ctx, cmd) => {
      const o = await deps.me(ctx);
      const h = houseOf(o);
      const nid = Number(ctx.params.nid ?? ctx.params.hid);
      if (!(o.items["1"] ?? {})[String(nid)]) return ctx.reply({ result: -2, nid }, cmd);
      delete h.placed[String(h.hid)];
      h.hid = nid;
      await deps.save(o);
      ctx.reply({ result: 1, nid }, cmd);
    };
    world.xt("UserFurntitureInfoExtension.63_3", (ctx) => changeHouse(ctx, "63_3"));
    world.xt("HouseExtension.62_2", (ctx) => changeHouse(ctx, "62_2"));
    world.xt("UserExtension.cmdCreateAndJoinRoom", (ctx) => {
      world.join(ctx.session, String(ctx.params.room));
    });
    let writing = Promise.resolve();
    const visited = async (visitor, ownerName) => {
      const owner = await deps.find(ownerName);
      if (!owner || owner.id === visitor.id || !deps.visits) return;
      const v = await deps.visits.get(owner.id) ?? { count: 0, recent: [] };
      v.count++;
      v.recent = [[visitor.id, deps.now?.() ?? Date.now()], ...v.recent.filter(([id]) => id !== visitor.id)].slice(0, VISITS_KEPT);
      await deps.visits.set(owner.id, v);
    };
    world.onJoinRoom?.((_s, p, room, from) => {
      const m = HOME_ROOM.exec(room.name);
      if (!m || !deps.visits || m[1] === p.name) return;
      const fm = HOME_ROOM.exec(from);
      if (fm && fm[1] === m[1]) return;
      const who = { id: p.id, name: p.name };
      writing = writing.then(() => visited(who, m[1])).catch(() => {
      });
    });
  }

  // server/src/game/sfs2013/shoot.ts
  var SHOOT_EXT = "ShootExtension";
  var FREE_CARDS = { "1": 1, "2": 1 };
  var TARGET_PLAYER = 2;
  function cardsOf2(o) {
    const c = (o.items ??= {})["4"] ??= {};
    for (const [id, q] of Object.entries(FREE_CARDS)) if (!c[id]) c[id] = q;
    return c;
  }
  function installShoot(world, deps) {
    const later = deps.later ?? ((ms, fn) => void setTimeout(fn, ms));
    let shots = 0;
    const worn = /* @__PURE__ */ new Map();
    world.xt(`${SHOOT_EXT}.64_5`, async (ctx) => {
      const o = await deps.me(ctx);
      const c = cardsOf2(o);
      await deps.save(o);
      ctx.reply({ cards: Object.entries(c).filter(([, q]) => q > 0).map(([i, q]) => ({ i: Number(i), q })) });
    });
    world.xt(`${SHOOT_EXT}.64_3`, () => {
    });
    world.xt(`${SHOOT_EXT}.64_1`, async (ctx) => {
      const p = ctx.params;
      const cardId = Number(p.cardId) | 0;
      const o = await deps.me(ctx);
      const owned = cardsOf2(o);
      const row = (await deps.cards())[String(cardId)];
      if (!row || !(owned[cardId] > 0)) return;
      const [, , , maxQ, , , effect = 0, seconds = 0] = row;
      if (maxQ > 1) {
        owned[cardId] -= 1;
        if (owned[cardId] <= 0) delete owned[cardId];
        await deps.save(o);
        ctx.reply({ amount: `4_${cardId}_0_-1` }, "onAmountUpdated");
      }
      const target = String(p.target ?? "");
      const targetType = Number(p.targetType) | 0;
      const info = {
        key: `${ctx.player.name}_${++shots}`,
        from: ctx.player.name,
        cardId,
        target,
        targetType,
        x: Number(p.x) | 0,
        y: Number(p.y) | 0,
        roomId: ctx.player.room?.id ?? 0,
        mine: p.mine ?? null
      };
      ctx.broadcast({ info, hit: true }, "64_2");
      if (targetType !== TARGET_PLAYER || effect <= 0 || seconds <= 0) return;
      const s = sessionOf(world, target);
      if (!s) return;
      const mine = worn.get(target) ?? /* @__PURE__ */ new Map();
      worn.set(target, mine);
      const until = Date.now() + seconds * 1e3;
      mine.set(effect, until);
      world.setUserVars(s, { shoot_effect: `${target};${[...mine.keys()].join(",")};${effect};` });
      later(seconds * 1e3, () => {
        if (mine.get(effect) !== until) return;
        mine.delete(effect);
        world.setUserVars(s, { shoot_effect: `${target};${[...mine.keys()].join(",")};0;${effect}` });
      });
    });
  }
  function sessionOf(world, name) {
    for (const r of world.rooms.values()) for (const m of r.members) if (world.player(m)?.name === name) return m;
    return void 0;
  }

  // server/src/game/sfs2013/plants.ts
  var PLANT_EXT = "PlantExtension";
  var GARDEN_HOUSE = 247;
  var POT = { x: 550, y: 224 };
  var GROWTH_PER_CARE = 10;
  var CARE_PER_DAY = 2;
  var FRUIT_WAIT_MS = 60 * 60 * 1e3;
  var PLANTS = {
    1: { name: "\u661F\u8F89\u6811", fruit: 279, price: 1e3, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [40, 40, 0, 0], [70, 70, 4, 20], [110, 110, 8, 30], [160, 160, 12, 50], [220, 220, 16, 70], [0, 0, 20, 100]] },
    2: { name: "\u6447\u94B1\u6811", fruit: 298, price: 1e3, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [40, 40, 0, 0], [70, 70, 4, 20], [110, 110, 8, 30], [160, 160, 12, 50], [220, 220, 16, 70], [0, 0, 20, 100]] },
    3: { name: "\u5154\u5154\u6811", fruit: 338, price: 1e3, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [40, 40, 0, 0], [70, 70, 4, 20], [110, 110, 8, 30], [160, 160, 12, 50], [220, 220, 16, 70], [0, 0, 20, 100]] },
    4: { name: "\u5C0F\u718A\u6811", fruit: 365, price: 1e3, mature: 3, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 0, 0], [40, 40, 4, 20], [50, 50, 8, 30], [60, 60, 12, 50], [70, 70, 16, 70], [0, 0, 20, 100]] },
    5: { name: "\u6708\u4EAE\u6811", fruit: 449, price: 1e3, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
    6: { name: "\u592A\u9633\u6811", fruit: 474, price: 1e3, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
    7: { name: "\u96EA\u82B1\u9E8B\u9E7F\u6811", fruit: 486, price: 1e3, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] },
    8: { name: "\u70C2\u6F2B\u6A31\u82B1\u6811", fruit: 508, price: 1e3, mature: 2, levels: [[10, 10, 0, 0], [20, 20, 0, 0], [30, 30, 2, 10], [40, 40, 4, 20], [50, 50, 6, 40], [0, 0, 10, 80]] }
  };
  var FRUIT_MAX = 999;
  var dayOf = (ms) => new Date(ms + 8 * 36e5).toISOString().slice(0, 10);
  function nextFruitAt(now) {
    return Math.ceil((now + FRUIT_WAIT_MS) / 36e5) * 36e5;
  }
  function ripen(p, now) {
    if (p.remainFruit > 0 || p.remainProductTime <= 0 || now < p.nextFruitTime) return;
    const n = Math.max(1, Math.ceil(p.fruitLeft / p.remainProductTime));
    p.remainFruit = n;
    p.pickers = [];
    p.fruitLeft = Math.max(0, p.fruitLeft - n);
    p.remainProductTime -= 1;
  }
  function plantView(p, now) {
    ripen(p, now);
    const today = p.care.day === dayOf(now) ? p.care : { rain: 0, fat: 0 };
    return {
      id: p.id,
      plantId: p.plantId,
      houseId: GARDEN_HOUSE,
      positionX: POT.x,
      positionY: POT.y,
      level: p.level,
      health: p.health,
      nutrition: p.nutrition,
      remainFruit: p.remainFruit,
      remainProductTime: p.remainProductTime,
      nextFruitTime: p.nextFruitTime,
      healthCeil: GROWTH_PER_CARE * CARE_PER_DAY,
      nutritionCeil: GROWTH_PER_CARE * CARE_PER_DAY,
      petId: 0,
      visitors: "",
      isFurniture: false,
      rainLeft: CARE_PER_DAY - today.rain,
      fatLeft: CARE_PER_DAY - today.fat
    };
  }
  function growUp(p, kind, now) {
    const max = kind.levels.length - 1;
    const [mh, mn] = kind.levels[p.level];
    if (p.level >= max || p.health < mh || p.nutrition < mn) return false;
    p.level += 1;
    p.health = 0;
    p.nutrition = 0;
    const [, , times, fruit] = kind.levels[p.level];
    p.remainProductTime = times;
    p.fruitLeft = fruit;
    p.remainFruit = 0;
    p.nextFruitTime = times > 0 ? nextFruitAt(now) : 0;
    return true;
  }
  function care(p, what, now) {
    const kind = PLANTS[p.plantId];
    if (!kind) return -19;
    if (p.level >= kind.levels.length - 1) return -9;
    const day = dayOf(now);
    if (p.care.day !== day) p.care = { day, rain: 0, fat: 0 };
    if (p.care[what] >= CARE_PER_DAY) return -5;
    const [mh, mn] = kind.levels[p.level];
    const key = what === "rain" ? "health" : "nutrition";
    const top = what === "rain" ? mh : mn;
    if (p[key] >= top) return -17;
    p[key] = Math.min(top, p[key] + GROWTH_PER_CARE);
    p.care[what] += 1;
    return growUp(p, kind, now) ? 1 : 0;
  }
  function plantTree(o, plantId) {
    const kind = PLANTS[plantId];
    if (!kind) return -19;
    if ((o.plants ?? []).length > 0) return -21;
    if ((o.score ?? 0) < kind.price) return -2;
    o.score = (o.score ?? 0) - kind.price;
    o.nextPlantId = (o.nextPlantId ?? 0) + 1;
    const p = { id: o.nextPlantId, plantId, level: 0, health: 0, nutrition: 0, remainFruit: 0, remainProductTime: 0, fruitLeft: 0, nextFruitTime: 0, care: { day: "", rain: 0, fat: 0 } };
    (o.plants ??= []).push(p);
    return p;
  }
  function installPlants(world, deps) {
    const mine = (o) => o.plants ??= [];
    const target = async (ctx) => {
      const owner = String(ctx.params.owner ?? "");
      if (!owner || owner === ctx.player.name) return deps.me(ctx);
      const m = /^(.+)_(-?\d+)_Home$/.exec(ctx.player.room?.name ?? "");
      if (!m || m[1] !== owner) return void 0;
      return deps.find(owner);
    };
    const byId = (o, id) => o?.plants?.find((p) => p.id === (Number(id) | 0));
    world.xt(`${PLANT_EXT}.80_1`, async (ctx) => {
      const o = await deps.me(ctx);
      const now = deps.now();
      const list = mine(o).map((p) => plantView(p, now));
      await deps.save(o);
      ctx.reply({ userPlants: list });
    });
    world.xt(`${PLANT_EXT}.80_9`, async (ctx) => {
      const o = await target(ctx);
      const now = deps.now();
      ctx.reply({ owner: ctx.params.owner ?? "", houseId: ctx.params.houseId ?? GARDEN_HOUSE, userPlants: (o?.plants ?? []).map((p) => plantView(p, now)) });
    });
    world.xt(`${PLANT_EXT}.80_2`, async (ctx) => {
      const p = byId(await target(ctx), ctx.params.userPlantId);
      ctx.reply({ result: p ? { result: 0, userPlant: plantView(p, deps.now()) } : { result: -19 } });
    });
    for (const [cmd, what] of [["80_3", "rain"], ["80_4", "fat"]]) {
      world.xt(`${PLANT_EXT}.${cmd}`, async (ctx) => {
        const o = await target(ctx);
        const p = byId(o, ctx.params.userPlantId);
        if (!o || !p) return ctx.reply({ result: { result: -19 } });
        const now = deps.now();
        const result = care(p, what, now);
        if (result >= 0) await deps.save(o);
        ctx.reply({ result: { result, userPlant: plantView(p, now), surprise: 0 } });
      });
    }
    world.xt(`${PLANT_EXT}.80_5`, async (ctx) => {
      const o = await target(ctx);
      const p = byId(o, ctx.params.userPlantId);
      if (!o || !p) return ctx.reply({ result: { result: -19 } });
      const now = deps.now();
      ripen(p, now);
      if (p.remainFruit <= 0) return ctx.reply({ result: { result: -1, userPlant: plantView(p, now) } });
      const visitor = o.name !== ctx.player.name;
      const picker = visitor ? await deps.me(ctx) : o;
      if (visitor && (p.remainFruit <= 1 || (p.pickers ?? []).includes(picker.id ?? 0)))
        return ctx.reply({ result: { result: -22, userPlant: plantView(p, now) } });
      const fruit = String(PLANTS[p.plantId].fruit);
      const items = (picker.items ??= {})["2"] ??= {};
      const n = Math.min(visitor ? 1 : p.remainFruit, FRUIT_MAX - (items[fruit] ?? 0));
      if (n <= 0) return ctx.reply({ result: { result: -16, userPlant: plantView(p, now) } });
      items[fruit] = (items[fruit] ?? 0) + n;
      p.remainFruit -= n;
      if (visitor) (p.pickers ??= []).push(picker.id ?? 0);
      if (p.remainFruit === 0 && p.remainProductTime > 0) p.nextFruitTime = nextFruitAt(now);
      await deps.save(o);
      if (picker !== o) await deps.save(picker);
      ctx.reply({ amount: `2_${fruit}_0_${n}` }, "onAmountUpdated");
      ctx.reply({ result: { result: 0, extData: n, userPlant: plantView(p, now) } });
    });
    world.xt("SundriesExtension.revival_garden", async (ctx) => {
      const op = String(ctx.params.op ?? "info");
      const now = deps.now();
      const answer = async (o2, result) => {
        const list = (o2?.plants ?? []).map((p) => plantView(p, now));
        const show = o2 && deps.shown ? await deps.shown(o2) : null;
        ctx.reply({ op, result, plant: list[0] ?? null, plants: list, score: o2?.score ?? 0, show }, "revival_garden");
      };
      if (op === "info") {
        const un = String(ctx.params.un ?? "");
        return answer(!un || un === ctx.player.name ? await deps.me(ctx) : await deps.find(un), 0);
      }
      const o = await deps.me(ctx);
      if (op === "buy") {
        const id = Number(ctx.params.plantId) | 0;
        const p = plantTree(o, id);
        if (typeof p === "number") return answer(o, p);
        await deps.save(o);
        ctx.reply({ score: o.score }, "onScoreUpdated");
        ctx.reply({ amount: `9_${id}_0_1_${p.id}` }, "onAmountUpdated");
        return answer(o, 0);
      }
      if (op === "dig") {
        const p = byId(o, ctx.params.userPlantId);
        if (!p) return answer(o, -19);
        o.plants = mine(o).filter((x) => x !== p);
        await deps.save(o);
        ctx.reply({ amount: `9_${p.plantId}_0_-1_${p.id}` }, "onAmountUpdated");
        return answer(o, 0);
      }
      answer(o, -19);
    });
  }

  // server/src/game/sfs2013/eggs.ts
  var EGG_EXT = "PetEggExtension";
  var EGG_TYPE = "5";
  var HATCH_MS = 5 * 60 * 1e3;
  var HATCH_MAX = 29;
  var HATCH_LEVEL = 1;
  function eggList(o) {
    const out = [];
    for (const [mi, n] of Object.entries(o.items?.[EGG_TYPE] ?? {})) {
      for (let k = 0; k < Math.min(n, 999); k++) out.push({ ei: Number(mi) * 1e3 + k, ri: Number(mi) });
    }
    return out;
  }
  function installEggs(world, deps) {
    const state = async (o) => {
      const h = o.hatch;
      if (!h) return { st: 4, es: eggList(o) };
      const now = deps.now();
      if (now < h.end) {
        const lt = Math.max(1, Math.ceil((h.end - now) / 1e3));
        return { st: 2, es: h.eggs.map((e) => ({ ei: e.ei, ri: e.mi, lt })) };
      }
      if (!h.pets) {
        h.pets = [];
        for (const e of h.eggs) h.pets.push(await deps.hatchPet(o, e.mi, HATCH_LEVEL));
        await deps.save(o);
      }
      if (h.pets.length === 0) {
        delete o.hatch;
        await deps.save(o);
        return { st: 4, es: eggList(o) };
      }
      return { st: 3, pms: h.pets.map((id) => ({ id })) };
    };
    world.xt(`${EGG_EXT}.1=1`, async (ctx) => {
      const o = await deps.me(ctx);
      ctx.reply({ es: eggList(o).map((e) => ({ ...e, st: 0 })) }, "1=1");
    });
    world.xt(`${EGG_EXT}.1-2`, async (ctx) => {
      const o = await deps.me(ctx);
      const st = Number(ctx.params.st ?? 2) | 0 || 2;
      if (st >= 3 && st <= 9 && deps.fuse) return ctx.reply({ ...await deps.fuse.state(o, st), os: st }, "1-2");
      ctx.reply({ ...await state(o), os: st }, "1-2");
    });
    world.xt(`${EGG_EXT}.1-4`, async (ctx) => {
      const o = await deps.me(ctx);
      if (o.hatch) return ctx.reply({ res: -1 }, "1-4");
      const owned = (o.items ??= {})[EGG_TYPE] ??= {};
      const want = String(ctx.params.ids ?? "").split(",").map((s) => Number(s) | 0).filter((x) => x > 0);
      const eggs = [];
      const used = {};
      for (const ei of want) {
        const mi = String(Math.floor(ei / 1e3));
        if ((owned[mi] ?? 0) - (used[mi] ?? 0) <= 0 || eggs.length >= HATCH_MAX) continue;
        used[mi] = (used[mi] ?? 0) + 1;
        eggs.push({ ei, mi: Number(mi) });
      }
      if (eggs.length === 0) return ctx.reply({ res: -2 }, "1-4");
      for (const [mi, n] of Object.entries(used)) {
        owned[mi] -= n;
        if (owned[mi] <= 0) delete owned[mi];
        ctx.reply({ amount: `${EGG_TYPE}_${mi}_0_${-n}` }, "onAmountUpdated");
      }
      o.hatch = { eggs, end: deps.now() + HATCH_MS };
      await deps.save(o);
      ctx.reply({ res: 1 }, "1-4");
      ctx.reply({ ...await state(o), os: 2 }, "1-2");
    });
    world.xt(`${EGG_EXT}.1-6`, async (ctx) => {
      const o = await deps.me(ctx);
      const h = o.hatch;
      if (!h || h.pets) return ctx.reply({ res: -1 }, "1-6");
      const owned = (o.items ??= {})[EGG_TYPE] ??= {};
      const back = {};
      for (const e of h.eggs) back[e.mi] = (back[e.mi] ?? 0) + 1;
      for (const [mi, n] of Object.entries(back)) {
        owned[mi] = (owned[mi] ?? 0) + n;
        ctx.reply({ amount: `${EGG_TYPE}_${mi}_0_${n}` }, "onAmountUpdated");
      }
      delete o.hatch;
      await deps.save(o);
      ctx.reply({ res: 1 }, "1-6");
      ctx.reply({ ...await state(o), os: 2 }, "1-2");
    });
    world.xt("PocketMonsterExtension.1223", async (ctx) => {
      const o = await deps.me(ctx);
      const id = Number(ctx.params.id) | 0;
      const loc = Number(ctx.params.loc) | 0;
      if (loc === 7 && deps.fuse) {
        const ok = deps.fuse.collect(o, id);
        if (ok) await deps.save(o);
        return ctx.reply({ res: ok ? 1 : -1, id, loc }, "2223");
      }
      const h = o.hatch;
      const i = h?.pets?.indexOf(id) ?? -1;
      if (!h || !h.pets || i < 0) return ctx.reply({ res: -1, id, loc }, "2223");
      h.pets.splice(i, 1);
      if (h.pets.length === 0) delete o.hatch;
      await deps.save(o);
      ctx.reply({ res: 1, id, loc }, "2223");
    });
  }

  // server/src/game/sfs2013/zoo.ts
  var ZOO_EXT = "ZooExtension";
  var TD_WIN_SCORE = 100;
  var TD_ITEMS = [431, 469];
  var TD_ENDLESS_WAVE = 10;
  var TD_ENDLESS_MAX = 300;
  var CATCH_RATE = 40;
  var CATCH_RATE_MAX = 80;
  var TD_DAY_MAX = 3e3;
  var TD_PLACES_MAX = 9;
  var TD_ZONES_MAX = 60;
  var TD_STEPS_MAX = 99;
  var FREE_TOOLS = 5;
  var ANIMAL_TYPE = "12";
  var FODDER_TYPE = "13";
  var ANIMALS = [
    [1, "\u5C0F\u72D7", "\u5377\u6BDB\u72D7", 1, "land", 2, 4, 500, "1009", "25"],
    [2, "\u5C0F\u523A\u732C", "\u523A\u732C", 2, "land", 4, 7, 1500, "1013", "15"],
    [3, "\u5C0F\u9E2D", "\u52CB\u7AE0\u9E2D", 1, "land", 22, 40, 1500, "1003", "20"],
    [4, "\u5C0F\u5154", "\u841D\u535C\u5154", 2, "land", 24, 45, 1800, "1005", "25"],
    [5, "\u5C0F\u732B", "\u94C3\u94DB\u732B", 3, "land", 48, 90, 2e3, "1011", "20"],
    [6, "\u5C0F\u677E\u9F20", "\u5927\u5C3E\u677E\u9F20", 2, "land", 8, 17, 1500, "1017", "20"],
    [7, "\u5C0F\u8003\u62C9", "\u53CC\u5B50\u8003\u62C9", 3, "land", 4, 9, 1500, "1015", "10"],
    [8, "\u5C0F\u5976\u725B", "\u725B\u5927\u53D4", 2, "land", 24, 50, 1500, "1019", "15"],
    [9, "BB\u9F20", "\u84DD\u5C0F\u9F20", 3, "land", 6, 13, 1800, "1021", "20"],
    [10, "\u5C0F\u7EA2\u96C0", "\u7EA2\u6BDB\u96C0", 3, "sky", 24, 48, 1800, "1023", "20"],
    [11, "\u86CB\u86CB\u9E1F", "\u5C0F\u84DD\u9E1F", 1, "sky", 2, 4, 1200, "1025", "15"],
    [12, "\u6BDB\u6BDB\u866B", "\u5C0F\u84DD\u8776", 2, "sky", 4, 8, 1e3, "1027", "20"],
    [13, "\u888B\u9F20\u5B9D\u5B9D", "\u8DF3\u8DF3\u888B\u9F20", 3, "land", 6, 15, 1500, "1031", "20"],
    [14, "\u8475\u82B1\u5C0F\u9E66\u9E49", "\u51E4\u5934\u9E66\u9E49", 2, "sky", 2, 5, 1e3, "1029", "20"],
    [15, "\u5495\u5495\u9E1F", "\u5495\u5495\u5544\u6728\u9E1F", 2, "sky", 3, 7, 1400, "1033", "18"],
    [16, "\u91D1\u4E1D\u96C0", "\u7EA2\u89D2\u9EC4\u83BA", 2, "sky", 7, 15, 1600, "1035", "23"],
    [17, "\u8C46\u8C46\u9E21", "\u9ED1\u7FBD\u8C46\u8C46\u9E21", 2, "sky", 4, 7, 1800, "1037", "19"],
    [18, "\u5C0F\u571F\u62E8\u9F20", "\u5929\u7AFA\u66B4\u7259\u9F20", 2, "land", 4, 8, 1200, "1041", "18"],
    [19, "\u5C0F\u72F8\u72F8", "\u7EA2\u5C3E\u8D64\u72F8", 3, "land", 24, 50, 2e3, "1039", "15"],
    [20, "\u5C0F\u6D77\u71D5", "\u957F\u5634\u4FE1\u5929\u7FC1", 2, "sky", 6, 13, 1400, "1043", "21"],
    [21, "\u6D77\u661F\u661F", "\u592A\u9633\u6D77\u661F", 2, "sea", 4, 7, 1200, "1045", "21"],
    [22, "\u5C0F\u73CA\u745A\u9C7C", "\u795E\u4ED9\u9C7C", 1, "sea", 2, 4, 1e3, "1047", "23"],
    [23, "\u5C0F\u7BAD\u9C7C", "\u98DE\u7BAD\u65D7\u9C7C", 2, "sea", 6, 13, 1400, "1049", "21"],
    [24, "\u5C0F\u767D\u9E64", "\u4E39\u9876\u9E64", 3, "sky", 8, 18, 1600, "1051", "19"],
    [25, "\u7AE0\u9C7C\u4ED4", "\u7AE0\u9C7C\u54E5", 2, "sea", 8, 17, 1600, "1053", "18"],
    [26, "\u6241\u6241\u9C7C", "\u9B54\u9B3C\u9C7C", 2, "sea", 8, 17, 1600, "1055", "15"],
    [27, "\u5C0F\u6D77\u9F9F", "\u7EFF\u6D77\u9F9F", 2, "sea", 6, 13, 1300, "1057", "17"],
    [28, "\u5C0F\u6D77\u9A6C", "\u98DE\u98DE\u6D77\u9A6C", 2, "sea", 4, 9, 1200, "1059", "19"],
    [29, "\u6CE1\u6CE1\u9C7C", "\u523A\u523A\u6CB3\u8C5A", 2, "sea", 6, 12, 1300, "1061", "18"],
    [30, "\u5C0F\u6D77\u8C79", "\u7403\u7403\u6D77\u8C79", 3, "sea", 8, 16, 1500, "1063", "18"],
    [31, "\u6CE2\u6CE2\u72D7", "\u535A\u7F8E\u72D7", 4, "land", 24, 50, 2e3, "1007_1065", "15_5"],
    [32, "\u54C8\u4ED4", "\u54C8\u58EB\u5947", 4, "land", 24, 50, 2e3, "1007_1065", "5_15"],
    [33, "\u5C0F\u571F\u72D7", "\u4E2D\u534E\u7530\u56ED\u72AC", 2, "land", 8, 15, 500, "1007_1065", "6_9"],
    [34, "\u5C0F\u7403\u7403", "\u79CB\u7530\u72AC", 2, "land", 8, 15, 500, "1007_1065", "9_6"],
    [35, "\u5C0F\u72EE\u5B50", "\u72EE\u5B50\u738B", 3, "land", 24, 50, 2e3, "1067", "18"],
    [36, "\u8DB4\u8DB4\u718A", "\u7EC5\u58EB\u718A", 3, "land", 24, 52, 2e3, "1069", "15"],
    [37, "\u5C0F\u71D5\u5B50", "\u71D5\u5B50\u54E5", 2, "sky", 8, 16, 500, "1071", "15"],
    [38, "\u5C0F\u4F01\u9E45", "\u56F4\u5DFE\u4F01\u9E45", 3, "land", 24, 50, 1500, "1073", "16"],
    [39, "\u72F8\u5C0F\u732B", "\u72F8\u732B\u732B", 2, "land", 8, 17, 800, "1075", "17"],
    [40, "\u5C0F\u5C0F\u9E7F", "\u957F\u9888\u9E7F", 3, "land", 6, 18, 1e3, "1214", "15"]
  ];
  var ANIMAL = new Map(ANIMALS.map((a) => [a[0], a]));
  var BABY_BASE = 1e4;
  var MATURE_BASE = 2e4;
  function animalsOwned(o) {
    const zoo = (o.items ??= {})[ANIMAL_TYPE] ??= {};
    for (const [id, n] of Object.entries(zoo)) {
      if (Number(id) >= BABY_BASE) continue;
      const key = String(BABY_BASE + Number(id));
      zoo[key] = (zoo[key] ?? 0) + n;
      delete zoo[id];
    }
    return zoo;
  }
  var HOUR = 3600 * 1e3;
  var FEED_CUT = HOUR;
  var FEED_EVERY = HOUR / 2;
  var FODDER = {
    1: [1e3, 0, 0, 10],
    2: [2e3, 0, 1, 100],
    3: [4e3, 0, 2, 100],
    4: [6e3, 0, 3, 100],
    8: [8e3, 0, 4, 100],
    5: [200, 1, 0, 0],
    6: [1e3, 6, 0, 0],
    7: [3e3, 24, 0, 0]
  };
  function zooLevel(exp) {
    let lv = 1;
    while (exp >= 100 * lv * (lv + 1) / 2) lv++;
    return { lv, next: 100 * lv * (lv + 1) / 2 };
  }
  var zooRoom = (lv) => Math.min(20, 6 + 2 * lv);
  function animalLeft(a, now) {
    const def = ANIMAL.get(a.race);
    const grow = (def ? def[5] : 1) * HOUR;
    return Math.max(0, Math.ceil((a.at + grow - a.cut - now) / 1e3));
  }
  function installZoo(world, deps) {
    const rnd = deps.random ?? Math.random;
    const place = (ctx) => String(Math.min(TD_PLACES_MAX, Math.max(1, Number(ctx.params.place ?? 1) | 0 || 1)));
    const items = (o) => (o.items ??= {})["2"] ??= {};
    const tdPay = (o, add) => {
      const day = new Date(deps.now ? deps.now() : Date.now()).toISOString().slice(0, 10);
      if (o.tdPaid?.day !== day) o.tdPaid = { day, n: 0 };
      const pay = Math.max(0, Math.min(add, TD_DAY_MAX - o.tdPaid.n));
      o.tdPaid.n += pay;
      return pay;
    };
    world.xt(`${ZOO_EXT}.97_203`, async (ctx) => {
      const o = await deps.me(ctx);
      const p = place(ctx);
      const mine = items(o);
      const tools = Object.entries(mine).filter(([id, n]) => Number(id) >= TD_ITEMS[0] && Number(id) <= TD_ITEMS[1] && Number(n) > 0).map(([id, n]) => ({ itemId: Number(id), num: Number(n) }));
      ctx.reply({ place: Number(p), gameInfo: (o.td?.[p] ?? []).join(";"), items: tools }, "97_203");
    });
    const endless = /* @__PURE__ */ new Map();
    const tdKey = (ctx) => String(ctx.player?.name ?? "");
    world.xt(`${ZOO_EXT}.97_205`, async (ctx) => {
      endless.set(tdKey(ctx), 0);
      ctx.reply({ res: 1, place: Number(place(ctx)) }, "97_205");
    });
    world.xt(`${ZOO_EXT}.97_206`, async (ctx) => {
      endless.set(tdKey(ctx), (endless.get(tdKey(ctx)) ?? 0) + 1);
      ctx.reply({ res: 1, step: endless.get(tdKey(ctx)) }, "97_206");
    });
    world.xt(`${ZOO_EXT}.97_207`, async (ctx) => {
      const o = await deps.me(ctx);
      const waves = endless.get(tdKey(ctx)) ?? 0;
      endless.delete(tdKey(ctx));
      const add = tdPay(o, Math.min(TD_ENDLESS_MAX, waves * TD_ENDLESS_WAVE));
      if (add > 0) {
        o.score = (o.score ?? 0) + add;
        await deps.save(o);
        ctx.reply({ score: o.score }, "onScoreUpdated");
      }
      ctx.reply({ res: 1, state: 1, scoreAdded: add, score: o.score ?? 0, step: waves }, "97_207");
    });
    world.xt(`${ZOO_EXT}.97_200`, async (ctx) => ctx.reply({ res: 1, place: Number(place(ctx)) }, "97_200"));
    world.xt(`${ZOO_EXT}.97_204`, async (ctx) => ctx.reply({ res: 1 }, "97_204"));
    world.xt(`${ZOO_EXT}.97_201`, async (ctx) => {
      const o = await deps.me(ctx);
      const p = place(ctx);
      const win = Number(ctx.params.isWin) === 1;
      const zone = Number(ctx.params.zoneNum) | 0;
      const step = Math.min(TD_STEPS_MAX, Number(ctx.params.step) | 0);
      let add = 0;
      if (win && zone > 0 && zone <= TD_ZONES_MAX) {
        const list = (o.td ??= {})[p] ??= [];
        const i = list.findIndex((e) => Number(e.split(":")[0]) === zone);
        const had = i >= 0 ? Number(list[i].split(":")[1]) : 0;
        if (i < 0) list.push(`${zone}:${Math.max(1, step)}`);
        else if (step > had) list[i] = `${zone}:${step}`;
        add = tdPay(o, TD_WIN_SCORE);
        o.score = (o.score ?? 0) + add;
        await deps.save(o);
        if (add) ctx.reply({ score: o.score }, "onScoreUpdated");
      }
      ctx.reply({ res: 1, moneyState: 0, prize: "", score: o.score ?? 0, scoreAdded: add }, "97_201");
    });
    world.xt(`${ZOO_EXT}.97_202`, async (ctx) => {
      const o = await deps.me(ctx);
      const id = String(Number(ctx.params.itemId) | 0);
      const mine = items(o);
      if ((mine[id] ?? 0) > 0) {
        mine[id] -= 1;
        if (mine[id] <= 0) delete mine[id];
        await deps.save(o);
        ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
      }
      ctx.reply({ res: 1, itemId: Number(id) }, "97_202");
    });
    world.xt(`${ZOO_EXT}.97_104`, async (ctx) => {
      const o = await deps.me(ctx);
      const mine = items(o);
      for (const id of ["424", "425"]) {
        if ((mine[id] ?? 0) > 0) continue;
        mine[id] = FREE_TOOLS;
        ctx.reply({ amount: `2_${id}_0_${FREE_TOOLS}` }, "onAmountUpdated");
      }
      await deps.save(o);
      const list = [];
      for (let id = 424; id <= 431; id++) if ((mine[String(id)] ?? 0) > 0) list.push({ itemId: id, num: mine[String(id)] });
      ctx.reply({ items: list }, "97_104");
    });
    world.xt(`${ZOO_EXT}.97_100`, async (ctx) => ctx.reply({ res: 1 }, "97_100"));
    world.xt(`${ZOO_EXT}.97_101`, async (ctx) => ctx.reply({ res: 1 }, "97_101"));
    world.xt(`${ZOO_EXT}.97_102`, async (ctx) => {
      const o = await deps.me(ctx);
      const id = String(Number(ctx.params.itemId) | 0);
      const mine = items(o);
      if ((mine[id] ?? 0) > 0) {
        mine[id] -= 1;
        if (mine[id] <= 0) delete mine[id];
        await deps.save(o);
        ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
      }
      ctx.reply({ res: 1, itemId: Number(id) }, "97_102");
    });
    world.xt(`${ZOO_EXT}.97_103`, async (ctx) => {
      const o = await deps.me(ctx);
      const race = Number(ctx.params.raceId) | 0;
      const tool = String(Number(ctx.params.itemId) | 0);
      const rate = Number(ctx.params.rate);
      const odds = Math.min(CATCH_RATE_MAX, rate >= 0 ? rate : CATCH_RATE);
      const mine = items(o);
      if (!((mine[tool] ?? 0) > 0) || !ANIMAL.has(race)) return ctx.reply({ res: 0, raceId: race }, "97_103");
      mine[tool] -= 1;
      if (mine[tool] <= 0) delete mine[tool];
      ctx.reply({ amount: `2_${tool}_0_-1` }, "onAmountUpdated");
      const caught = rnd() * 100 < odds;
      if (caught) {
        const zoo = animalsOwned(o);
        const key = String(BABY_BASE + race);
        zoo[key] = (zoo[key] ?? 0) + 1;
        ctx.reply({ amount: `${ANIMAL_TYPE}_${key}_0_1` }, "onAmountUpdated");
      }
      await deps.save(o);
      ctx.reply({ res: caught ? 1 : 0, raceId: race }, "97_103");
    });
    const now = deps.now ?? Date.now;
    const zooOf = (o) => o.zoo ??= { exp: 0, nextId: 1, animals: [] };
    const owned = animalsOwned;
    const whose = async (ctx) => {
      const un = typeof ctx.params.un === "string" ? ctx.params.un : "";
      const mine = await deps.me(ctx);
      if (!un || !deps.byName || un === mine.name) return mine;
      return await deps.byName(un) ?? mine;
    };
    const view2 = (a) => {
      const left = animalLeft(a, now());
      const def = ANIMAL.get(a.race);
      return { id: a.id, raceId: a.race, mature: left === 0 ? 1 : 0, left, rate: Math.min(100, (def ? Number(def[9].split("_")[0]) : 0) + a.boost) };
    };
    const take = (o, id, n, ctx) => {
      const mine = owned(o);
      mine[id] = (mine[id] ?? 0) + n;
      if (mine[id] <= 0) delete mine[id];
      ctx.reply({ amount: `${ANIMAL_TYPE}_${id}_0_${n}` }, "onAmountUpdated");
    };
    world.xt(`${ZOO_EXT}.97_1`, async (ctx) => {
      const o = await whose(ctx);
      const z = zooOf(o);
      const { lv, next } = zooLevel(z.exp);
      ctx.reply({ un: o.name ?? "", lv, exp: z.exp, next, cap: zooRoom(lv), n: z.animals.length }, "97_1");
    });
    world.xt(`${ZOO_EXT}.97_4`, async (ctx) => {
      const o = await whose(ctx);
      ctx.reply({ un: o.name ?? "", animals: zooOf(o).animals.map(view2) }, "97_4");
    });
    world.xt(`${ZOO_EXT}.97_9`, async (ctx) => {
      const o = await deps.me(ctx);
      const babys = Object.entries(owned(o)).filter(([id, n]) => Number(id) < MATURE_BASE && n > 0).map(([id, n]) => ({ raceId: Number(id) - BABY_BASE, type: 1, num: n }));
      ctx.reply({ babys }, "97_9");
    });
    world.xt(`${ZOO_EXT}.97_10`, async (ctx) => {
      const o = await deps.me(ctx);
      const matrues = Object.entries(owned(o)).filter(([id, n]) => Number(id) > MATURE_BASE && n > 0).map(([id, n]) => ({ raceId: Number(id) - MATURE_BASE, type: 2, num: n }));
      ctx.reply({ matrues }, "97_10");
    });
    world.xt(`${ZOO_EXT}.97_5`, async (ctx) => {
      const o = await deps.me(ctx);
      const race = Number(ctx.params.raceId) | 0;
      const z = zooOf(o);
      if (!ANIMAL.has(race) || (owned(o)[String(BABY_BASE + race)] ?? 0) <= 0) return ctx.reply({ res: -1, raceId: race }, "97_5");
      if (z.animals.length >= zooRoom(zooLevel(z.exp).lv)) return ctx.reply({ res: -2, raceId: race }, "97_5");
      const a = { id: z.nextId++, race, at: now(), cut: 0, boost: 0 };
      z.animals.push(a);
      take(o, String(BABY_BASE + race), -1, ctx);
      await deps.save(o);
      ctx.reply({ res: 1, raceId: race, animal: view2(a) }, "97_5");
    });
    world.xt(`${ZOO_EXT}.97_6`, async (ctx) => {
      const o = await deps.me(ctx);
      const id = Number(ctx.params.id) | 0;
      const z = zooOf(o);
      const i = z.animals.findIndex((a) => a.id === id);
      if (i < 0) return ctx.reply({ res: -1, id }, "97_6");
      z.animals.splice(i, 1);
      await deps.save(o);
      ctx.reply({ res: 1, id }, "97_6");
    });
    world.xt(`${ZOO_EXT}.97_7`, async (ctx) => {
      const o = await deps.me(ctx);
      const id = Number(ctx.params.id) | 0;
      const z = zooOf(o);
      const i = z.animals.findIndex((a2) => a2.id === id);
      if (i < 0) return ctx.reply({ res: -1, id }, "97_7");
      const a = z.animals[i];
      if (animalLeft(a, now()) > 0) return ctx.reply({ res: -2, id }, "97_7");
      const def = ANIMAL.get(a.race);
      z.animals.splice(i, 1);
      z.exp += def[6];
      let petRace = 0;
      let petName2 = "";
      const ids = def[8].split("_").map(Number);
      const rates = def[9].split("_").map(Number);
      let roll = rnd() * 100;
      for (let k = 0; k < ids.length && !petRace; k++) {
        const odds = Math.min(100, (rates[k] ?? 0) + a.boost);
        if (roll < odds) petRace = ids[k];
        else roll -= rates[k] ?? 0;
      }
      if (petRace && deps.givePet) {
        const got = await deps.givePet(o, petRace);
        if (got === void 0) petRace = 0;
        else petName2 = got;
      } else petRace = 0;
      if (!petRace) take(o, String(MATURE_BASE + a.race), 1, ctx);
      await deps.save(o);
      const { lv } = zooLevel(z.exp);
      ctx.reply({ res: 1, id, raceId: a.race, petRace, petName: petName2, exp: z.exp, lv, gain: def[6] }, "97_7");
    });
    world.xt(`${ZOO_EXT}.97_12`, async (ctx) => {
      const o = await deps.me(ctx);
      const id = Number(ctx.params.id) | 0;
      const item = Number(ctx.params.itemId) | 0;
      const a = zooOf(o).animals.find((x) => x.id === id);
      const reply = (res) => ctx.reply({ res, id, itemId: item, ...a ? view2(a) : {} }, "97_12");
      if (!a) return reply(-1);
      const t = now();
      if (animalLeft(a, t) === 0) return reply(-4);
      if (item === 0) {
        if (a.fed !== void 0 && t - a.fed < FEED_EVERY) return reply(-3);
        a.fed = t;
        a.cut += FEED_CUT;
      } else {
        const f = FODDER[item];
        if (!f) return reply(-1);
        const [price, hours, stars, extra] = f;
        const def = ANIMAL.get(a.race);
        if (extra > 0 && (a.boost >= 100 || stars === 0 && a.boost > 0 || stars > 0 && def[3] > stars)) return reply(-3);
        const bag3 = (o.items ??= {})[FODDER_TYPE] ??= {};
        if ((bag3[item] ?? 0) > 0) {
          bag3[item] -= 1;
          if (bag3[item] <= 0) delete bag3[item];
          ctx.reply({ amount: `${FODDER_TYPE}_${item}_0_-1` }, "onAmountUpdated");
        } else {
          if ((o.score ?? 0) < price) return reply(-2);
          o.score = (o.score ?? 0) - price;
          ctx.reply({ score: o.score }, "onScoreUpdated");
        }
        a.cut += hours * HOUR;
        if (extra > 0) a.boost = Math.min(100, a.boost + extra);
      }
      await deps.save(o);
      reply(1);
    });
    world.xt(`${ZOO_EXT}.97_21`, async (ctx) => {
      const o = await deps.me(ctx);
      const race = Number(ctx.params.raceId) | 0;
      const def = ANIMAL.get(race);
      const key = String(MATURE_BASE + race);
      const num3 = Math.min(Math.max(1, Number(ctx.params.num) | 0), owned(o)[key] ?? 0);
      if (!def || num3 <= 0) return ctx.reply({ res: -1, raceId: race, num: 0, score: o.score ?? 0 }, "97_21");
      take(o, key, -num3, ctx);
      o.score = (o.score ?? 0) + def[7] * num3;
      ctx.reply({ score: o.score }, "onScoreUpdated");
      await deps.save(o);
      ctx.reply({ res: 1, raceId: race, num: num3, score: o.score, got: def[7] * num3 }, "97_21");
    });
  }

  // server/src/game/sfs2013/parkour.ts
  var PARKOUR_EXT = "HolidayExtension";
  var PARKOUR_CMD = "ActKuPaoStarWorld";
  var PARKOUR_ROLES = {
    1: { name: "\u9177\u4F0A\u4E50", price: 0, cool: 34 },
    2: { name: "\u9177\u9B54\u5154", price: 8888, cool: 41 },
    3: { name: "\u9177\u5C0F\u9ED1", price: 15e3, cool: 35 },
    4: { name: "\u9177\u591A\u591A\u7F57", price: 11e3, cool: 45 },
    5: { name: "\u9177\u708E\u9633", price: 14e3, cool: 45 },
    6: { name: "\u9177\u82E5\u5E0C", price: 16e3, cool: 46 },
    7: { name: "\u9177\u84DD\u5B9D\u661F", price: 14e3, cool: 44 }
  };
  var PARKOUR_RIDES = {
    1: { price: 0, score: [0, 1], money: [0, 1] }
  };
  var MAX_ROLE_LEVEL = 100;
  var MAX_RIDE_LEVEL = 80;
  var MAX_LOVE = 5;
  var LOVE_EVERY_MS = 10 * 60 * 1e3;
  var SIGN_DAYS = 7;
  var ALL_TASKS = 10;
  var RENTS_PER_DAY = 3;
  var RENT_PRICE = 200;
  var BUY_MONEY = [2500, 5200, 11e3, 24e3];
  var BUY_LOVE = [10, 20, 50, 100];
  var TASK_NEED = [8, 8, 8, 8, 8, 5, 5, 5, 5, 5];
  var TASK_MONEY = [588, 588, 588, 588, 588, 1488, 1488, 1488, 1488, 1488];
  var SIGN_MONEY = [1e3, 1500, 1500, 1e3, 1500, 1e3, 1500];
  var SIGN_WEEKDAY = [5, 6, 0, 1, 2, 3, 4];
  var GAME_MONEY_MAX = 2e3;
  var EXP_PER_METER = 1;
  var BOARD_SIZE = 10;
  var WELCOME_MONEY = 1e3;
  var MONEY_CAP = 9999999;
  var SENDER = "\u9177\u8DD1\u661F\u4E16\u754C";
  var levelCost = (lv) => Math.min(40, lv) * 100;
  var levelExp = (lv) => Math.min(40, lv) * 1e3;
  function expToLevel(lv) {
    let n = 0;
    for (let i = 1; i < lv; i++) n += levelExp(i);
    return n;
  }
  function signIndex(day) {
    return SIGN_WEEKDAY.indexOf((/* @__PURE__ */ new Date(`${day}T00:00:00Z`)).getUTCDay());
  }
  function signWeek(day) {
    const t = Date.parse(`${day}T00:00:00Z`) - signIndex(day) * 864e5;
    return new Date(t).toISOString().slice(0, 10);
  }
  function runMoney(score, roleId, roleLv, rideId, rideLv) {
    const cool = (PARKOUR_ROLES[roleId] ?? PARKOUR_ROLES[1]).cool + (roleLv - 1);
    const [base, up] = (PARKOUR_RIDES[rideId] ?? PARKOUR_RIDES[1]).money;
    const pct2 = base + (rideLv - 1) * up;
    return Math.max(0, Math.min(GAME_MONEY_MAX, Math.trunc(Math.floor(score / 40) * (1 + cool / 100) * (1 + pct2 / 100))));
  }
  function runScore(score, rideId, rideLv) {
    const [base, up] = (PARKOUR_RIDES[rideId] ?? PARKOUR_RIDES[1]).score;
    return Math.floor(score * (1 + (base + (rideLv - 1) * up) / 100));
  }
  function addExp(u, gain, max) {
    if (u.lv >= max) {
      u.exp = 0;
      return;
    }
    u.exp += Math.max(0, gain);
    while (u.lv < max && u.exp >= levelExp(u.lv)) {
      u.exp -= levelExp(u.lv);
      u.lv += 1;
    }
    if (u.lv >= max) u.exp = 0;
  }
  var dayHash = (day) => [...day].reduce((h, c) => h * 31 + c.charCodeAt(0) >>> 0, 7);
  function newParkour(day, now) {
    return {
      roles: { "1": { lv: 1, exp: 0 } },
      rides: { "1": { lv: 1, exp: 0 } },
      love: MAX_LOVE,
      loveAt: now,
      loveDay: day,
      dist: 0,
      best: 0,
      played: false,
      sign: { week: signWeek(day), flags: 0, day: "" },
      task: { day, rt: 5 + dayHash(day) % 5, prog: new Array(ALL_TASKS).fill(0), got: 0 },
      rents: { day, list: [] },
      gifts: [{ id: 1, ti: "\u9177\u8DD1\u661F\u4E16\u754C\u89C1\u9762\u793C", ct: `\u6B22\u8FCE\u6765\u5230\u9177\u8DD1\u661F\u4E16\u754C\uFF01\u9001\u4F60${WELCOME_MONEY}\u91D1\u5E01\u3002`, money: WELCOME_MONEY, love: 0 }],
      nextGift: 2
    };
  }
  function parkourOf(o, day, now) {
    const p = o.parkour ??= newParkour(day, now);
    if (p.loveDay !== day) {
      p.loveDay = day;
      p.love = Math.max(p.love, MAX_LOVE);
    }
    if (p.love >= MAX_LOVE) p.loveAt = now;
    else {
      const n = Math.floor((now - p.loveAt) / LOVE_EVERY_MS);
      if (n > 0) {
        p.love = Math.min(MAX_LOVE, p.love + n);
        p.loveAt = p.love >= MAX_LOVE ? now : p.loveAt + n * LOVE_EVERY_MS;
      }
    }
    if (p.task.day !== day) p.task = { day, rt: 5 + dayHash(day) % 5, prog: new Array(ALL_TASKS).fill(0), got: 0 };
    if (p.rents.day !== day) p.rents = { day, list: [] };
    const week = signWeek(day);
    if (p.sign.week !== week) p.sign = { week, flags: 0, day: "" };
    if (!p.rides["1"]) p.rides["1"] = { lv: 1, exp: 0 };
    if (!p.roles["1"]) p.roles["1"] = { lv: 1, exp: 0 };
    return p;
  }
  function loveCd(p, now) {
    if (p.love >= MAX_LOVE) return 0;
    return Math.max(1, Math.min(LOVE_EVERY_MS / 1e3, Math.ceil((p.loveAt + LOVE_EVERY_MS - now) / 1e3)));
  }
  var int2 = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.trunc(Number(v)) || 0));
  function installParkour(world, deps) {
    const now = () => deps.now ? deps.now() : Date.now();
    const on = (name, h) => world.xt(`${PARKOUR_EXT}.${PARKOUR_CMD}${name}`, h);
    const open = async (ctx) => {
      const o = await deps.load(ctx);
      return { o, p: parkourOf(o, deps.today(), now()) };
    };
    const pay = (ctx, o, n) => {
      o.score = Math.max(0, Math.min(MONEY_CAP, (o.score ?? 0) + n));
      if (n !== 0) ctx.reply({ score: o.score }, "onScoreUpdated");
    };
    const reward = (money, love = 0) => ({
      bn: money > 0 ? [{ type: 100, id: -1, num: money }] : [],
      gBn: [...money > 0 ? [{ op: 1, va: money }] : [], ...love > 0 ? [{ op: 2, va: love }] : []]
    });
    const board = async (o, p) => {
      if (deps.board) return await deps.board.get() ?? [];
      return p.best > 0 ? [{ dd: o.name, nn: o.name, md: p.best }] : [];
    };
    const spendLove = (p, t) => {
      const was = p.love;
      p.love -= 1;
      if (was >= MAX_LOVE && p.love < MAX_LOVE) p.loveAt = t;
    };
    on("_panel", async (ctx) => {
      const { o, p } = await open(ctx);
      const rows = await board(o, p);
      const mine = rows.findIndex((r) => r.dd === o.name);
      await deps.save(o);
      ctx.reply({
        fr: !p.played,
        e: p.love,
        cd: loveCd(p, now()),
        j: o.score ?? 0,
        d: p.dist,
        mr: mine >= 0 ? mine + 1 : -1,
        ml: p.best,
        gc: p.gifts.length,
        df: p.sign.flags,
        pl: Object.entries(p.roles).filter(([id]) => PARKOUR_ROLES[Number(id)]).map(([id, r]) => ({ pId: Number(id), lv: r.lv, ce: expToLevel(r.lv) + r.exp })),
        rl: Object.entries(p.rides).filter(([id]) => PARKOUR_RIDES[Number(id)]).map(([id, r]) => ({ rId: Number(id), lv: r.lv, ce: r.exp })),
        rents: p.rents.list.map(([id, used]) => `${id}:${used}`).join(";"),
        rt: p.task.rt,
        ts: p.task.got,
        l: rows
      });
    });
    on("_startGame", async (ctx) => {
      const { o, p } = await open(ctx);
      if (p.love <= 0) return ctx.reply({ res: 0, e: p.love });
      const askedRole = int2(ctx.params.pId, 0, 99);
      const askedRide = int2(ctx.params.rId, 0, 99);
      const pId = PARKOUR_ROLES[askedRole] ? askedRole : 1;
      const rId = PARKOUR_RIDES[askedRide] && p.rides[String(askedRide)] ? askedRide : 1;
      const rented = !p.roles[String(pId)];
      if (rented) {
        const r = p.rents.list.find(([id, used]) => id === pId && !used);
        if (r) r[1] = 1;
      }
      const t = now();
      spendLove(p, t);
      p.played = true;
      p.game = { pId, rId, rented, at: t };
      await deps.save(o);
      ctx.reply({ res: 1, e: p.love });
    });
    on("_sReStartGame", async (ctx) => {
      ctx.reply({ res: 1 });
    });
    on("_endGame", async (ctx) => {
      const { o, p } = await open(ctx);
      const sc = int2(ctx.params.sc, 0, 1e7);
      const meters = int2(ctx.params.l, 0, 1e7);
      const g = p.game;
      if (!g) return ctx.reply({ sc, money: 0, j: o.score ?? 0 });
      delete p.game;
      const role = g.rented ? void 0 : p.roles[String(g.pId)];
      const ride = p.rides[String(g.rId)] ?? p.rides["1"];
      const money = runMoney(sc, g.pId, role?.lv ?? 1, g.rId, ride.lv);
      const real = runScore(sc, g.rId, ride.lv);
      p.dist += meters;
      const better = meters > p.best;
      if (better) p.best = meters;
      if (role) addExp(role, meters * EXP_PER_METER, MAX_ROLE_LEVEL);
      addExp(ride, meters * EXP_PER_METER, MAX_RIDE_LEVEL);
      pay(ctx, o, money);
      if (better && deps.board) {
        const rows = (await deps.board.get() ?? []).filter((r) => r.dd !== o.name);
        rows.push({ dd: o.name, nn: o.name, md: p.best });
        rows.sort((a, b) => b.md - a.md);
        await deps.board.set(rows.slice(0, BOARD_SIZE));
      }
      await deps.save(o);
      ctx.reply({ sc: real, money, j: o.score ?? 0 });
    });
    on("_upgradeRole", async (ctx) => {
      const { o, p } = await open(ctx);
      const r = p.roles[String(int2(ctx.params.id, 0, 99))];
      if (!r || r.lv >= MAX_ROLE_LEVEL) return ctx.reply({ res: 0 });
      const cost = levelCost(r.lv);
      if ((o.score ?? 0) < cost) return ctx.reply({ res: -2 });
      pay(ctx, o, -cost);
      r.lv += 1;
      r.exp = 0;
      await deps.save(o);
      ctx.reply({ res: 1 });
    });
    on("_upgradeRidePet", async (ctx) => {
      const { o, p } = await open(ctx);
      const r = p.rides[String(int2(ctx.params.id, 0, 99))];
      if (!r || r.lv >= MAX_RIDE_LEVEL) return ctx.reply({ res: 0 });
      const cost = levelCost(r.lv);
      if ((o.score ?? 0) < cost) return ctx.reply({ res: -2 });
      pay(ctx, o, -cost);
      r.lv += 1;
      r.exp = 0;
      await deps.save(o);
      ctx.reply({ res: 1 });
    });
    on("_gainRole", async (ctx) => {
      const { o, p } = await open(ctx);
      const id = int2(ctx.params.id, 0, 99);
      const info = PARKOUR_ROLES[id];
      if (!info || p.roles[String(id)]) return ctx.reply({ res: 0, bn: [] });
      if ((o.score ?? 0) < info.price) return ctx.reply({ res: -2, bn: [] });
      pay(ctx, o, -info.price);
      p.roles[String(id)] = { lv: 1, exp: 0 };
      for (const r of p.rents.list) if (r[0] === id) r[1] = 1;
      await deps.save(o);
      ctx.reply({ res: 1, bn: [] });
    });
    on("_gainRidePet", async (ctx) => {
      const { o, p } = await open(ctx);
      const id = int2(ctx.params.id, 0, 99);
      const info = PARKOUR_RIDES[id];
      if (!info || p.rides[String(id)]) return ctx.reply({ res: 0, bn: [] });
      if ((o.score ?? 0) < info.price) return ctx.reply({ res: -2, bn: [] });
      pay(ctx, o, -info.price);
      p.rides[String(id)] = { lv: 1, exp: 0 };
      await deps.save(o);
      ctx.reply({ res: 1, bn: [] });
    });
    on("_rent", async (ctx) => {
      const { o, p } = await open(ctx);
      const id = int2(ctx.params.rId, 0, 99);
      if (!PARKOUR_ROLES[id] || p.roles[String(id)] || p.rents.list.length >= RENTS_PER_DAY) return ctx.reply({ res: 0 });
      if (p.rents.list.some(([rid, used]) => rid === id && !used)) return ctx.reply({ res: 0 });
      if ((o.score ?? 0) < RENT_PRICE) return ctx.reply({ res: -2 });
      pay(ctx, o, -RENT_PRICE);
      p.rents.list.push([id, 0]);
      await deps.save(o);
      ctx.reply({ res: 1 });
    });
    on("_buyJingBi", async (ctx) => {
      const id = Number(ctx.params.id);
      if (!Number.isInteger(id) || !BUY_MONEY[id]) return ctx.reply({ res: 0 });
      const { o } = await open(ctx);
      pay(ctx, o, BUY_MONEY[id]);
      await deps.save(o);
      ctx.reply({ res: 1 });
    });
    on("_buyEngery", async (ctx) => {
      const id = Number(ctx.params.id);
      if (!Number.isInteger(id) || !BUY_LOVE[id]) return ctx.reply({ res: 0 });
      const { o, p } = await open(ctx);
      p.love += BUY_LOVE[id];
      if (p.love >= MAX_LOVE) p.loveAt = now();
      await deps.save(o);
      ctx.reply({ res: 1 });
    });
    on("_getAllGB", async (ctx) => {
      const { o, p } = await open(ctx);
      await deps.save(o);
      ctx.reply({ gbs: p.gifts.map((g) => ({ gId: g.id, si: 0, sn: SENDER, ti: g.ti, ct: g.ct })) });
    });
    on("_gainGB", async (ctx) => {
      const { o, p } = await open(ctx);
      const gId = int2(ctx.params.gId, 0, 1 << 30);
      const g = p.gifts.find((x) => x.id === gId);
      if (!g) return ctx.reply({ bn: [], gBn: [] });
      p.gifts = p.gifts.filter((x) => x !== g);
      pay(ctx, o, g.money);
      p.love += g.love;
      if (p.love >= MAX_LOVE) p.loveAt = now();
      await deps.save(o);
      ctx.reply(reward(g.money, g.love));
    });
    on("_dailySign", async (ctx) => {
      const { o, p } = await open(ctx);
      const day = deps.today();
      const asked = Number(ctx.params.dId);
      const idx = Number.isInteger(asked) && asked >= 0 && asked < SIGN_DAYS ? asked : signIndex(day);
      if (p.sign.day === day || p.sign.flags & 1 << idx) return ctx.reply({ bn: [], gBn: [] });
      p.sign.flags |= 1 << idx;
      p.sign.day = day;
      pay(ctx, o, SIGN_MONEY[idx]);
      await deps.save(o);
      ctx.reply(reward(SIGN_MONEY[idx]));
    });
    on("_dailyTaskPanel", async (ctx) => {
      const { o, p } = await open(ctx);
      await deps.save(o);
      ctx.reply({ rt: p.task.rt, rds: p.task.prog.join(","), rs: p.task.got });
    });
    on("_gainDailyTask", async (ctx) => {
      const { o, p } = await open(ctx);
      const id = Number(ctx.params.tId);
      const today = id >= 0 && id <= 4 || id === p.task.rt;
      if (!Number.isInteger(id) || !today || p.task.prog[id] < TASK_NEED[id] || p.task.got & 1 << id) return ctx.reply({ bn: [], gBn: [] });
      p.task.got |= 1 << id;
      pay(ctx, o, TASK_MONEY[id]);
      await deps.save(o);
      ctx.reply(reward(TASK_MONEY[id]));
    });
    on("_dailyTaskFinish", async (ctx) => {
      const { o, p } = await open(ctx);
      for (const s of String(ctx.params.tId ?? "").split(",")) {
        const id = Number(s);
        if (s === "" || !Number.isInteger(id) || id < 0 || id >= ALL_TASKS) continue;
        p.task.prog[id] = Math.min(TASK_NEED[id], p.task.prog[id] + 1);
      }
      await deps.save(o);
    });
  }

  // server/src/game/sfs2013/minigames.ts
  var NINJA_PAY_CAP = 1e3;
  var LB_POINTS_PER_BEAN = 10;
  var LB_BEANS_PER_RUN = 50;
  var LB_BEANS_PER_WEEK = 500;
  var LB_RUN_MAX = 2e5;
  var LB_TOTAL_MAX = 9999999;
  var LB_BOARD_SIZE = 100;
  var LB_LEVELS = [1999, 7999, 19999, 49999, 99999, 299999];
  var LB_REWARDS = [
    [1888, 888],
    [3333, 1888],
    [6666, 3333],
    [10888, 6666],
    [21888, 10888],
    [36666, 21888]
  ];
  function lbLevel(points) {
    const i = LB_LEVELS.findIndex((top) => points <= top);
    return i < 0 ? LB_LEVELS.length + 1 : i + 1;
  }
  var weekOf = (ms) => Math.floor((ms / 864e5 - 4) / 7);
  function installMiniGames(world, deps) {
    world.xt("UserGameExtension.89_bb1", (ctx) => ctx.reply({ suc: true }, "89_bb1"));
    world.xt("UserGameExtension.89_bb2", async (ctx) => {
      const rec = await deps.load(ctx);
      const score = Math.max(0, Number(ctx.params.score) | 0);
      const pay = Math.min(NINJA_PAY_CAP, Math.max(0, Number(ctx.params.money) | 0));
      if (pay > 0) {
        rec.score = (rec.score ?? 0) + pay;
        await deps.save(rec);
        ctx.reply({ score: rec.score }, "onScoreUpdated");
      }
      ctx.reply({ s: score, m: pay, i: 0, st: 1 }, "89_bb2");
    });
    const lb = (rec) => rec.limitBomb ??= { total: 0, flag: 0 };
    const points = (v) => Number(v) | 0;
    const board = async (rec) => {
      if (deps.board) return await deps.board.get() ?? [];
      const t = lb(rec).total;
      return t > 0 ? [{ dd: rec.name ?? "", nn: rec.name ?? "", score: t }] : [];
    };
    world.xt("UserGameExtension.89_18", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = lb(rec);
      g.run = true;
      await deps.save(rec);
      ctx.reply({ score: g.total }, "89_18");
    });
    world.xt("UserGameExtension.89_20", (ctx) => {
      const p = points(ctx.params.score);
      ctx.reply({ suc: p >= 0 && p <= LB_RUN_MAX }, "89_20");
    });
    world.xt("UserGameExtension.89_19", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = lb(rec);
      const p = points(ctx.params.score);
      if (p < 0 || p > LB_RUN_MAX) return ctx.reply({ suc: false, money: 0, type: 1 }, "89_19");
      if (!g.run) return ctx.reply({ suc: true, money: 0, type: 1 }, "89_19");
      g.run = false;
      g.total = Math.min(LB_TOTAL_MAX, g.total + p);
      const week = weekOf(deps.now ? deps.now() : Date.now());
      if (g.week !== week) Object.assign(g, { week, beans: 0 });
      let money = Math.floor(p / LB_POINTS_PER_BEAN);
      let type = 1;
      if (money >= LB_BEANS_PER_RUN) {
        money = LB_BEANS_PER_RUN;
        type = 0;
      }
      if ((g.beans ?? 0) + money >= LB_BEANS_PER_WEEK) {
        money = Math.max(0, LB_BEANS_PER_WEEK - (g.beans ?? 0));
        type = 2;
      }
      g.beans = (g.beans ?? 0) + money;
      rec.jingdou = Math.min(9999999, (rec.jingdou ?? 0) + money);
      await deps.save(rec);
      if (deps.board && p > 0) {
        const rows = (await deps.board.get() ?? []).filter((r) => r.dd !== rec.name);
        rows.push({ dd: rec.name ?? "", nn: rec.name ?? "", score: g.total });
        rows.sort((a, b) => b.score - a.score);
        await deps.board.set(rows.slice(0, LB_BOARD_SIZE));
      }
      ctx.reply({ suc: true, money, type }, "89_19");
    });
    world.xt("UserGameExtension.89_21", async (ctx) => {
      const rec = await deps.load(ctx);
      const page = Math.max(1, Math.min(10, points(ctx.params.page) || 1));
      const rows = await board(rec);
      const rank = rows.slice((page - 1) * 10, page * 10).map((r, i) => ({ rank: (page - 1) * 10 + i + 1, dd: r.dd, nn: r.nn, score: r.score }));
      ctx.reply({ rank }, "89_21");
    });
    world.xt("UserGameExtension.89_23", async (ctx) => {
      const g = lb(await deps.load(ctx));
      ctx.reply({ flag: g.flag, score: g.total }, "89_23");
    });
    world.xt("UserGameExtension.89_22", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = lb(rec);
      const i = points(ctx.params.index);
      const reward = LB_REWARDS[i];
      if (!reward || g.flag & 1 << i || lbLevel(g.total) < i + 2) return ctx.reply({ bn: null }, "89_22");
      g.flag |= 1 << i;
      const [exp, coins] = reward;
      rec.score = (rec.score ?? 0) + coins;
      const pet = rec.pets?.[0];
      const msgs = pet && deps.pets ? gainExp(await deps.pets(), pet, exp).msgs : [];
      await deps.save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      for (const [c, b] of msgs) ctx.reply(b, c);
      ctx.reply({ bn: [{ type: 101, id: -1, num: exp }, { type: 100, id: -1, num: coins }] }, "89_22");
    });
  }

  // server/src/game/sfs2013/areafuncs.ts
  var TREE_FRUIT = 6;
  var TREE_ITEM = 419;
  var TREE_HOUR = 6;
  var KNIGHT_CARD = 531;
  var KNIGHT_CARDS_A_DAY = 3;
  var KNIGHT_AUGURY_CARDS = 5;
  var KNIGHT_PET = 932;
  var KNIGHT_LEVEL = 25;
  var KNIGHTS = [933, 935, 937, 939];
  var KNIGHT_XINGBI = 30;
  var BALLOON_KEEP = 50;
  var MOOD_PRICE = 100;
  var DONATE_MONEY = 100;
  var DONATE_MIN = 10;
  var DONATE_PER_DAY = 3;
  var DONATE_RICH = 1e3;
  var DONATE_TAKE = 200;
  var DONATE_NAMES = 10;
  var HELLO_GRADES = [[0, "d"], [30, "c"], [50, "b"], [90, "a"], [130, "s"]];
  var HELLO_POINTS = { d: 1, c: 2, b: 3, a: 4, s: 5 };
  var HELLO_SKILLS = {
    0: [[5, 10, 13], [3, "s"]],
    1: [[10, 6, 3], [1, "b"]],
    2: [[12, 15, 3], [2, "b"]],
    4: [[4, 10, 2], [2, "a"]]
  };
  var UNION_FORMS = {
    679: [[475, 721], [490, 729]],
    694: [[477, 722], [491, 742]],
    754: [[492, 788], [514, 870]]
  };
  var SWEET_ITEM = 513;
  var SWEETS_FOR_PET = 15;
  var XIAOBAITU = 846;
  var GYM_HIT_COINS = 5;
  var GYM_GAME_COINS = 200;
  var GYM_GAME_SCORE = 30;
  var GYM_GAMES_PER_DAY = 5;
  var THUNDER_STONE = 616;
  var GYM_SHOP = [[101, 0, 500], [100, 0, 500], [2, 524, 1], [2, 60, 3], [0, 1846, 1], [2, 384, 1]];
  var WATER_COST = [30, 30, 20, 20, 150, 40];
  var FIRE_COST = [300, 1e3, 350, 150, 100, 100];
  var FIRE_SHOP = [[2, 383, 1], [0, 1864, 1], [100, 0, 500], [101, 0, 500], [2, 524, 1], [2, 60, 3]];
  var GROW_LEVELS = 2;
  var GROW_WAIT = 600;
  var GROW_STEPS = 6;
  var GROW_GIFTS = [[100, 0, 1e3], [2, 60, 5], [2, 102, 1], [100, 0, 3e3]];
  var GROW_RUNS = [1, 3, 6, 10];
  var TICKET_ITEM = 297;
  var TICKET_GOODS = {
    84: [0, 533, 200],
    85: [0, 534, 200],
    86: [0, 535, 200],
    87: [1, 147, 100],
    88: [1, 148, 100],
    89: [1, 149, 100],
    139: [2, 343, 8],
    182: [1, 291, 50],
    183: [1, 292, 50],
    184: [1, 293, 50],
    185: [102, 139, 400]
  };
  var WEEK_GIFTS = {
    69: [67, 3, 5e3, 2e4],
    70: [61, 10, 5e3, 2e4],
    71: [104, 10, 5e3, 2e4],
    72: [0, 0, 7e3, 2e4]
  };
  var weekOf2 = (day) => Math.floor((Date.parse(day + "T00:00:00Z") / 864e5 - 4) / 7);
  var helloGrade = (score) => [...HELLO_GRADES].reverse().find(([min]) => score >= min)[1];
  var area = (rec) => rec.area ??= {};
  var bag = (rec, type = "2") => (rec.items ??= {})[type] ??= {};
  function give(ctx, rec, id, n, type = "2") {
    const b = bag(rec, type);
    b[id] = Math.max(0, (b[id] ?? 0) + n);
    if (b[id] === 0) delete b[id];
    ctx.reply({ amount: `${type}_${id}_0_${n}` }, "onAmountUpdated");
  }
  function treeDay(ms) {
    return new Date(ms - TREE_HOUR * 3600 * 1e3).toISOString().slice(0, 10);
  }
  function installAreaFuncs(world, deps) {
    world.xt("SundriesExtension.70_34", async (ctx) => {
      const rec = await deps.load(ctx);
      ctx.reply({ num: area(rec).tree === treeDay(deps.now()) ? 0 : TREE_FRUIT });
    });
    world.xt("SundriesExtension.70_35", async (ctx) => {
      const rec = await deps.load(ctx);
      const day = treeDay(deps.now());
      if (area(rec).tree === day) return ctx.reply({ res: false });
      area(rec).tree = day;
      give(ctx, rec, TREE_ITEM, TREE_FRUIT);
      await deps.save(rec);
      ctx.reply({ res: true });
    });
    const PA = "PeriodicActiveExtension";
    world.xt(`${PA}.knight_4`, async (ctx) => {
      const rec = await deps.load(ctx);
      ctx.reply({ res: area(rec).knightDay === deps.today() ? 1 : 0 });
    });
    world.xt(`${PA}.knight_5`, async (ctx) => {
      const rec = await deps.load(ctx);
      if (area(rec).knightDay === deps.today()) return ctx.reply({ suc: false });
      area(rec).knightDay = deps.today();
      give(ctx, rec, KNIGHT_CARD, KNIGHT_CARDS_A_DAY);
      await deps.save(rec);
      ctx.reply({ suc: true });
    });
    const firstKnight = (rec) => {
      const p = rec.pets?.[0];
      return p && p.race === KNIGHT_PET && p.level >= KNIGHT_LEVEL ? p : void 0;
    };
    world.xt(`${PA}.knight_1`, async (ctx) => {
      const rec = await deps.load(ctx);
      if (!firstKnight(rec) || (bag(rec)[KNIGHT_CARD] ?? 0) < KNIGHT_AUGURY_CARDS) return ctx.reply({ suc: false });
      give(ctx, rec, KNIGHT_CARD, -KNIGHT_AUGURY_CARDS);
      const race = KNIGHTS[Math.floor(Math.random() * KNIGHTS.length)];
      area(rec).knightSeen = race;
      await deps.save(rec);
      ctx.reply({ suc: true, res: race });
    });
    const becomeKnight = (ctx, rec, pmId, race) => {
      const p = rec.pets?.find((x) => x.id === pmId);
      if (!p || p.race !== KNIGHT_PET || p.level < KNIGHT_LEVEL || !KNIGHTS.includes(race)) return false;
      p.race = race;
      if (rec.followPet === p.id) world.setUserVarOnce(ctx.session, "p", followVar(p));
      return true;
    };
    world.xt(`${PA}.knight_2`, async (ctx) => {
      const rec = await deps.load(ctx);
      const race = area(rec).knightSeen ?? 0;
      const ok = becomeKnight(ctx, rec, Number(ctx.params.pmId) | 0, race);
      if (ok) {
        delete area(rec).knightSeen;
        await deps.save(rec);
      }
      ctx.reply({ suc: ok });
    });
    world.xt(`${PA}.knight_3`, async (ctx) => {
      const rec = await deps.load(ctx);
      if ((rec.xingbi ?? 0) < KNIGHT_XINGBI) return ctx.reply({ suc: false });
      const ok = becomeKnight(ctx, rec, Number(ctx.params.pmId) | 0, Number(ctx.params.raceId) | 0);
      if (ok) {
        rec.xingbi = (rec.xingbi ?? 0) - KNIGHT_XINGBI;
        ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
        await deps.save(rec);
      }
      ctx.reply({ suc: ok });
    });
    const BW = "BalloonExtension";
    const balloons = async () => await deps.get("area/balloon") ?? { wishes: [], moods: [] };
    const pickOther = (list, me) => {
      const others = list.filter((x) => x.dd !== me);
      return others.length ? others[Math.floor(Math.random() * others.length)] : void 0;
    };
    world.xt(`${BW}.88_2`, async (ctx) => {
      const rec = await deps.load(ctx);
      const w = area(rec).wish;
      ctx.reply({ result: w && w.day === deps.today() ? w.wi : 0 });
    });
    world.xt(`${BW}.88_1`, async (ctx) => {
      const rec = await deps.load(ctx);
      const wi = Math.max(1, Math.min(6, Number(ctx.params.wi) | 0));
      if (area(rec).wish?.day === deps.today()) return;
      area(rec).wish = { day: deps.today(), wi };
      await deps.save(rec);
      const s = await balloons();
      s.wishes.push({ dd: rec.name, nn: rec.name, wi, day: deps.today() });
      s.wishes = s.wishes.slice(-BALLOON_KEEP);
      await deps.set("area/balloon", s);
    });
    world.xt(`${BW}.88_10`, async (ctx) => {
      const rec = await deps.load(ctx);
      const content = String(ctx.params.content ?? "").slice(0, 50);
      if (!content || (rec.score ?? 0) < MOOD_PRICE) return;
      rec.score = (rec.score ?? 0) - MOOD_PRICE;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      await deps.save(rec);
      const s = await balloons();
      s.moods.push({ uid: rec.id, dd: rec.name, nn: rec.name, date: String(deps.now()), faceId: Number(ctx.params.faceId) | 0, content });
      s.moods = s.moods.slice(-BALLOON_KEEP);
      await deps.set("area/balloon", s);
    });
    world.xt(`${BW}.88_4`, async (ctx) => {
      const w = pickOther((await balloons()).wishes, ctx.player.name);
      ctx.reply(w ? { suc: true, wi: w.wi, dd: w.dd, nn: w.nn } : { suc: false });
    });
    world.xt(`${BW}.88_9`, async (ctx) => {
      const m = pickOther((await balloons()).moods, ctx.player.name);
      ctx.reply(m ? { suc: true, mood: { uid: m.uid, date: m.date, faceId: m.faceId, content: m.content }, dd: m.dd, nn: m.nn } : { suc: false });
    });
    for (const cmd of ["88_5", "88_11"]) world.xt(`${BW}.${cmd}`, () => {
    });
    for (const cmd of ["88_3", "88_6", "88_7", "88_8"]) world.xt(`${BW}.${cmd}`, (ctx) => ctx.reply({ list: [] }));
    const DE = "DonateExtension";
    const pool = async () => await deps.get("area/donate") ?? { pool: 0, people: 0, donation: 0, takes: 0, names: [] };
    let poolTurn = Promise.resolve();
    const inTurn = (f) => {
      const run = poolTurn.then(f, f);
      poolTurn = run.catch(() => void 0);
      return run;
    };
    const mine = (rec) => {
      const a = area(rec);
      if (!a.donate || a.donate.day !== deps.today()) a.donate = { day: deps.today(), n: 0, took: a.donate?.took, total: a.donate?.total ?? 0 };
      return a.donate;
    };
    world.xt(`${DE}.87_1`, async (ctx) => {
      const rec = await deps.load(ctx);
      const d = mine(rec);
      const type = Number(ctx.params.type) | 0;
      const id = Number(ctx.params.id) | 0;
      const num3 = Math.max(0, Number(ctx.params.num) | 0);
      if (d.n >= DONATE_PER_DAY) return ctx.reply({ result: 104, redFlower: false });
      let worth = 0;
      if (type === DONATE_MONEY) {
        if (num3 < DONATE_MIN || (rec.score ?? 0) < num3) return ctx.reply({ result: 101, redFlower: false });
        rec.score = (rec.score ?? 0) - num3;
        ctx.reply({ score: rec.score }, "onScoreUpdated");
        worth = num3;
      } else {
        const owned = rec.items?.[String(type)]?.[String(id)] ?? 0;
        if (num3 < 1 || owned < num3) return ctx.reply({ result: 101, redFlower: false });
        give(ctx, rec, id, -num3, String(type));
      }
      d.n++;
      d.total += worth;
      await deps.save(rec);
      await inTurn(async () => {
        const s = await pool();
        s.pool += worth;
        s.donation += worth;
        s.people++;
        s.names = [rec.name, ...s.names.filter((n) => n !== rec.name)].slice(0, DONATE_NAMES);
        await deps.set("area/donate", s);
      });
      ctx.reply({ result: 1, redFlower: false });
    });
    world.xt(`${DE}.87_2`, async (ctx) => {
      const rec = await deps.load(ctx);
      const d = mine(rec);
      if (d.took === deps.today()) return ctx.reply({ result: 106 });
      if ((rec.score ?? 0) >= DONATE_RICH) return ctx.reply({ result: 107 });
      const took = await inTurn(async () => {
        const s = await pool();
        if (s.pool < DONATE_TAKE) return false;
        s.pool -= DONATE_TAKE;
        s.takes++;
        await deps.set("area/donate", s);
        return true;
      });
      if (!took) return ctx.reply({ result: 108 });
      d.took = deps.today();
      rec.score = (rec.score ?? 0) + DONATE_TAKE;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      await deps.save(rec);
      ctx.reply({ result: 1 });
    });
    world.xt(`${DE}.87_3`, async (ctx) => {
      const s = await pool();
      ctx.reply({ donatePeople: s.people, donation: s.donation, takeCount: s.takes });
    });
    for (const cmd of ["87_4", "87_5"])
      world.xt(`${DE}.${cmd}`, async (ctx) => {
        const rec = await deps.load(ctx);
        ctx.reply({ ms: mine(rec).total });
      });
    world.xt(`${DE}.87_6`, async (ctx) => ctx.reply({ list: (await pool()).names.join(",") }));
    const hello = (rec) => area(rec).hello ??= { sc: [0, 0, 0], pt: [0, 0, 0], woken: [] };
    world.xt("RobotExtension.2-21", async (ctx) => {
      const rec = await deps.load(ctx);
      const type = Number(ctx.params.type) | 0;
      const score = Math.max(0, Number(ctx.params.score) | 0);
      if (type < 1 || type > 3) return ctx.reply({ pt: 0 });
      const h = hello(rec);
      const pt = HELLO_POINTS[helloGrade(score)];
      h.sc[type - 1] = Math.max(h.sc[type - 1], score);
      h.pt[type - 1] += pt;
      await deps.save(rec);
      ctx.reply({ pt });
    });
    world.xt("RobotExtension.2-20", async (ctx) => {
      const rec = await deps.load(ctx);
      const h = hello(rec);
      ctx.reply({ sc: h.sc.join(","), pt: h.pt.join(",") });
    });
    world.xt("RobotExtension.2-22", async (ctx) => {
      const rec = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      const need = HELLO_SKILLS[id];
      const h = hello(rec);
      if (!need) return ctx.reply({ result: -2 });
      if (h.woken.includes(id)) return ctx.reply({ result: -4 });
      if (need[0].some((n, i) => h.pt[i] < n)) return ctx.reply({ result: -2 });
      const min = HELLO_GRADES.find(([, g]) => g === need[1][1])[0];
      if (h.sc[need[1][0] - 1] < min) return ctx.reply({ result: -3 });
      h.woken.push(id);
      await deps.save(rec);
      ctx.reply({ result: 1 });
    });
    const unicorn = world.handlers?.get("PetExtension2.54e_1");
    world.xt("PetExtension2.54e_1", async (ctx, cmd) => {
      const rec = await deps.load(ctx);
      const p = rec.pets?.find((x) => x.id === (Number(ctx.params.pid) | 0));
      if (unicorn && !(p && UNION_FORMS[p.race])) return unicorn(ctx, cmd);
      const form = p ? UNION_FORMS[p.race]?.[(Number(ctx.params.t) | 0) - 1] : void 0;
      if (!p || !form || (bag(rec)[form[0]] ?? 0) < 1) return ctx.reply({ res: -1 });
      give(ctx, rec, form[0], -1);
      p.race = form[1];
      if (rec.followPet === p.id) world.setUserVarOnce(ctx.session, "p", followVar(p));
      await deps.save(rec);
      ctx.reply({ res: 0 });
    });
    const bottle = (rec) => {
      const a = area(rec);
      if (!a.bottle || a.bottle.day !== deps.today()) a.bottle = { day: deps.today(), n: 0 };
      return a.bottle;
    };
    world.xt(`${PA}.s_s_1`, async (ctx) => {
      const rec = await deps.load(ctx);
      ctx.reply({ res: bottle(rec).n });
    });
    world.xt(`${PA}.s_s_2`, async (ctx) => {
      const rec = await deps.load(ctx);
      const b = bottle(rec);
      const c = Math.min(Number(ctx.params.c) | 0, bag(rec)[SWEET_ITEM] ?? 0, SWEETS_FOR_PET - b.n);
      if (c <= 0) return ctx.reply({ res: false });
      give(ctx, rec, SWEET_ITEM, -c);
      b.n += c;
      let full = false;
      if (b.n >= SWEETS_FOR_PET && deps.pets) {
        const t = await deps.pets();
        const pet = newPet(rec, t, XIAOBAITU, 1, deps.today());
        if ((rec.pets ??= []).length < 6) {
          rec.pets.push(pet);
          ctx.reply({ pm: detailOf(pet, rec, t) }, "2201");
        } else (rec.storage ??= []).push(pet);
        full = true;
      }
      await deps.save(rec);
      ctx.reply({ res: full });
    });
    const gym = (rec) => {
      const a = area(rec);
      if (!a.gym) a.gym = { day: deps.today(), pb: false, pt: false, s: 0, water: 0, fire: 0 };
      if (a.gym.day !== deps.today()) Object.assign(a.gym, { day: deps.today(), pb: false, pt: false, coinsToday: 0, waterToday: 0, fireToday: 0 });
      return a.gym;
    };
    const payable = (asked, perGame, paid) => Math.max(0, Math.min(asked, perGame, perGame * GYM_GAMES_PER_DAY - (paid ?? 0)));
    const payShop = async (ctx, rec, kind, shop = GYM_SHOP) => {
      const [type, id, num3] = shop[kind];
      if (type === 100) {
        rec.score = (rec.score ?? 0) + num3;
        ctx.reply({ score: rec.score }, "onScoreUpdated");
      } else if (type === 101) {
        const p = rec.pets?.[0];
        if (p && deps.pets) for (const [c, b] of gainExp(await deps.pets(), p, num3).msgs) ctx.reply(b, c);
      } else give(ctx, rec, id, num3, String(type));
      return [{ type, id, num: num3 }];
    };
    world.xt(`${PA}.20121112_checkstone`, async (ctx) => {
      const g = gym(await deps.load(ctx));
      ctx.reply({ pb: g.pb, pt: g.pt, s: g.s });
    });
    world.xt(`${PA}.20121112_getbonus`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = gym(rec);
      const m = payable(Math.max(0, Number(ctx.params.n) | 0) * GYM_HIT_COINS, GYM_GAME_COINS, g.coinsToday);
      g.coinsToday = (g.coinsToday ?? 0) + m;
      const first = !g.pb;
      if (first) {
        g.pb = true;
        g.s = Math.min(3, g.s + 1);
      }
      if (m > 0) {
        rec.score = (rec.score ?? 0) + m;
        ctx.reply({ score: rec.score }, "onScoreUpdated");
      }
      await deps.save(rec);
      ctx.reply({ m, f: first, s: 1 });
    });
    world.xt(`${PA}.20121112_getstone`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = gym(rec);
      if (g.s < 3) return ctx.reply({ res: false });
      g.s = 0;
      give(ctx, rec, THUNDER_STONE, 1);
      await deps.save(rec);
      ctx.reply({ res: true });
    });
    world.xt(`${PA}.20121116water_score1`, async (ctx) => ctx.reply({ score: gym(await deps.load(ctx)).water }));
    world.xt(`${PA}.20121116water_score2`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = gym(rec);
      const got = payable(Math.max(0, Number(ctx.params.num) | 0), GYM_GAME_SCORE, g.waterToday);
      g.waterToday = (g.waterToday ?? 0) + got;
      g.water += got;
      await deps.save(rec);
    });
    world.xt(`${PA}.20121116water_score3`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = gym(rec);
      const kind = Number(ctx.params.index) | 0;
      if (!GYM_SHOP[kind] || g.water < WATER_COST[kind]) return ctx.reply({ bn: null, score: g.water });
      g.water -= WATER_COST[kind];
      const bn = kind === 5 ? (give(ctx, rec, GYM_SHOP[5][1], 1), true) : await payShop(ctx, rec, kind);
      await deps.save(rec);
      ctx.reply({ bn, score: g.water });
    });
    world.xt(`${PA}.Fire_8`, async (ctx) => ctx.reply({ score: gym(await deps.load(ctx)).fire }));
    world.xt(`${PA}.Fire_5`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = gym(rec);
      const got = payable(Math.max(0, Number(ctx.params.score) | 0), GYM_GAME_SCORE * 10, g.fireToday);
      g.fireToday = (g.fireToday ?? 0) + got;
      g.fire += got;
      await deps.save(rec);
      ctx.reply({ score: g.fire });
    });
    world.xt(`${PA}.Fire_6`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = gym(rec);
      const kind = Number(ctx.params.id ?? ctx.params.index) | 0;
      if (!FIRE_SHOP[kind] || g.fire < FIRE_COST[kind]) return ctx.reply({ suc: false, bn: [] });
      g.fire -= FIRE_COST[kind];
      const bn = await payShop(ctx, rec, kind, FIRE_SHOP);
      await deps.save(rec);
      ctx.reply({ suc: true, bn });
    });
    const empty = {
      "20121112_lookbonus": { c: 0, p: "0,0,0,0" },
      "2012113_tbo": { bn: [] },
      "20121113_htop": { l: "" },
      Fire_10: { res: false, recent: "" },
      "20121116water_c1": { res: false, top10: "" },
      "20121116water_r1": { max: 0, status: 0 },
      "20121116water_e1": {},
      Dark_0: { max: 0 },
      Dark_3: { turn: 0, pet: false },
      Dark_4: { status: -1, cd: 0 },
      Dark_6: { recent: "" },
      "20121123light_E1": { enter: true },
      "20121123light_C1": { top: "" },
      "20121123light_F1": { friend: "" },
      "20121123light_G1": { score: 0, friend: "0:0:0:0:0", got: false },
      Fire_1: { acc: 0, highest: 0, rank: 0, flag: 0 },
      Fire_2: { num: 0 }
    };
    for (const [cmd, reply] of Object.entries(empty)) world.xt(`${PA}.${cmd}`, (ctx) => ctx.reply(structuredClone(reply)));
    world.xt("GalaxyExtension.105_4", (ctx) => ctx.reply({ card: -1 }));
    const HE = "HolidayExtension.121109_";
    const grow = (rec) => area(rec).grow ??= { pet: -1, step: 0, taken: false, next: 0, count: 0, flag: 0 };
    const growView = (rec) => {
      const g = grow(rec);
      return { step: g.step, taken: g.taken, cd: Math.max(0, Math.ceil((g.next - deps.now()) / 1e3)), done: g.step >= GROW_STEPS };
    };
    world.xt(HE + "02", async (ctx) => ctx.reply({ petId: grow(await deps.load(ctx)).pet }));
    world.xt(HE + "06", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = grow(rec);
      const id = Number(ctx.params.petId) | 0;
      if (id === -1) Object.assign(g, { pet: -1, step: 0, taken: false, next: 0 });
      else {
        if (!rec.pets?.some((p) => p.id === id)) return ctx.reply({ suc: false });
        if (g.step >= GROW_STEPS) Object.assign(g, { step: 0, taken: false, next: 0 });
        g.pet = id;
      }
      await deps.save(rec);
      ctx.reply({ suc: true });
    });
    world.xt(HE + "03", async (ctx) => ctx.reply(growView(await deps.load(ctx))));
    world.xt(HE + "07", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = grow(rec);
      if (g.pet === -1 || g.step >= GROW_STEPS || g.next > deps.now()) return ctx.reply({ suc: false });
      g.taken = true;
      await deps.save(rec);
      ctx.reply({ suc: true });
    });
    world.xt(HE + "04", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = grow(rec);
      const p = rec.pets?.find((x) => x.id === g.pet) ?? rec.storage?.find((x) => x.id === g.pet);
      if (!g.taken || !p || g.step >= GROW_STEPS) return ctx.reply({ suc: false, bn: [], level: p?.level ?? 0, step: g.step });
      const done = g.step;
      p.level = Math.min(100, p.level + GROW_LEVELS);
      p.exp = 0;
      g.step++;
      g.taken = false;
      g.next = deps.now() + GROW_WAIT * 1e3;
      if (g.step >= GROW_STEPS) g.count++;
      await deps.save(rec);
      ctx.reply({ suc: true, bn: [], level: p.level, step: done });
    });
    world.xt(HE + "08", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = grow(rec);
      const left = g.next - deps.now();
      if (left <= 0) return ctx.reply({ res: 1 });
      const num3 = Math.max(Math.max(0, Number(ctx.params.num) | 0), Math.ceil(left / 6e4));
      if ((rec.score ?? 0) < num3) return ctx.reply({ res: 0 });
      rec.score = (rec.score ?? 0) - num3;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      g.next = 0;
      await deps.save(rec);
      ctx.reply({ res: 1 });
    });
    world.xt(HE + "01", async (ctx) => {
      const g = grow(await deps.load(ctx));
      ctx.reply({ count: g.count, flag: g.flag });
    });
    world.xt(HE + "05", async (ctx) => {
      const rec = await deps.load(ctx);
      const g = grow(rec);
      const id = Number(ctx.params.id) | 0;
      const gift = GROW_GIFTS[id];
      if (!gift || g.count < GROW_RUNS[id] || g.flag & 1 << id) return ctx.reply({ suc: false, bn: [] });
      g.flag |= 1 << id;
      const [type, mid, num3] = gift;
      if (type === 100) {
        rec.score = (rec.score ?? 0) + num3;
        ctx.reply({ score: rec.score }, "onScoreUpdated");
      } else if (type === 2) give(ctx, rec, mid, num3);
      await deps.save(rec);
      ctx.reply({ suc: true, bn: [{ type, id: mid, num: num3 }] });
    });
    world.xt("GiftBagExtension.68_6", async (ctx) => {
      const rec = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      ctx.reply({ res: 1, id, s: area(rec).weekGift === weekOf2(deps.today()) ? 1 : 0 });
    });
    world.xt("GiftBagExtension.68_7", async (ctx) => {
      const rec = await deps.load(ctx);
      const id = Number(ctx.params.id) | 0;
      const gift = WEEK_GIFTS[id];
      if (!gift) return ctx.reply({ res: 10, id });
      if (!rec.vip) return ctx.reply({ res: 0, id });
      const week = weekOf2(deps.today());
      if (area(rec).weekGift === week) return ctx.reply({ res: 3, id });
      area(rec).weekGift = week;
      const [item, n, coins, exp] = gift;
      if (item) give(ctx, rec, item, n);
      rec.score = (rec.score ?? 0) + coins;
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      if (rec.robot) rec.robot.exp = (rec.robot.exp ?? 0) + exp;
      await deps.save(rec);
      ctx.reply({ res: 1, id });
    });
    const armour = world.handlers?.get("SynthesizeExtension.57_8");
    world.xt("SynthesizeExtension.57_8", async (ctx, cmd) => {
      const id = Number(ctx.params.id) | 0;
      const goods = TICKET_GOODS[id];
      if (!goods) return armour ? armour(ctx, cmd) : ctx.reply({ res: 0 });
      const rec = await deps.load(ctx);
      const [type, mid, price] = goods;
      const num3 = type === 0 || type === 102 ? 1 : Math.max(1, Math.min(99, Number(ctx.params.num) | 0));
      if ((bag(rec)[TICKET_ITEM] ?? 0) < price * num3) return ctx.reply({ res: 0 });
      if (type === 0 && rec.items?.["0"]?.[mid]) return ctx.reply({ res: 0 });
      give(ctx, rec, TICKET_ITEM, -price * num3);
      if (type === 102) {
        if (!deps.pets) return ctx.reply({ res: 0 });
        const t = await deps.pets();
        const pet = newPet(rec, t, mid, 5, deps.today());
        if ((rec.pets ??= []).length < 6) {
          rec.pets.push(pet);
          ctx.reply({ pm: detailOf(pet, rec, t) }, "2201");
        } else (rec.storage ??= []).push(pet);
      } else give(ctx, rec, mid, num3, String(type));
      await deps.save(rec);
      ctx.reply({ res: 1 });
    });
  }

  // server/src/game/sfs2013/mods.ts
  var MOD_RACE_MIN = 900001;
  var MOD_RACE_MAX = 999999;
  var MOD_DATA_MAX = 65536;
  var MOD_DATA_TOTAL = 1048576;
  var MOD_LEVEL_MAX = 100;
  var MOD_SPECIES_MAX = 2e3;
  var BAG_MAX = 6;
  var MOD_ID_TEXT = /^[A-Za-z0-9_-]{1,32}$/;
  var isModId = (id) => MOD_ID_TEXT.test(id) && !(id in Object.prototype);
  var encoder = new TextEncoder();
  var bytes = (s) => encoder.encode(s).length;
  var owners = /* @__PURE__ */ new WeakMap();
  var ownersOf = (t) => {
    let m = owners.get(t);
    if (!m) owners.set(t, m = /* @__PURE__ */ new Map());
    return m;
  };
  var isModRace = (race) => race >= MOD_RACE_MIN && race <= MOD_RACE_MAX;
  function stashModPets(rec, known) {
    let moved = false;
    for (const [list, bag3] of [[rec.pets, true], [rec.storage, false]]) {
      if (!list) continue;
      for (let i = list.length - 1; i >= 0; i--) {
        const p = list[i];
        if (!isModRace(p.race) || known(p.race)) continue;
        list.splice(i, 1);
        (rec.modPets ??= []).push({ pet: p, bag: bag3 });
        if (rec.followPet === p.id) delete rec.followPet;
        moved = true;
      }
    }
    return moved;
  }
  function parseModSpecies(text, t) {
    let d;
    try {
      d = typeof text === "string" ? JSON.parse(text) : text;
    } catch {
      return "\u4E0D\u662F\u4E9A\u6BD4\u7684\u5B9A\u4E49";
    }
    if (!d || typeof d !== "object") return "\u4E0D\u662F\u4E9A\u6BD4\u7684\u5B9A\u4E49";
    const id = Math.floor(Number(d.id));
    if (!isModRace(id)) return `\u6A21\u7EC4\u4E9A\u6BD4\u7684\u7F16\u53F7\u662F${MOD_RACE_MIN}\u2013${MOD_RACE_MAX}`;
    const name = String(d.name ?? "").trim().slice(0, 12);
    if (!name) return "\u4E9A\u6BD4\u6CA1\u6709\u540D\u5B57";
    const attrs = Array.isArray(d.attr) ? d.attr.map((a) => Math.floor(Number(a))) : [];
    const charted = (a) => Number.isInteger(a) && a >= 0 && Object.hasOwn(t.pm.chart, String(a));
    if (attrs.length === 0 || !charted(attrs[0])) return "\u4E9A\u6BD4\u7684\u5C5E\u6027\u4E0D\u662F\u6E38\u620F\u7684\u5C5E\u6027";
    const attr = [attrs[0], charted(attrs[1] ?? NaN) ? attrs[1] : attrs[0]];
    const stats = Array.isArray(d.stats) ? d.stats.map((v) => Math.floor(Number(v))) : [];
    if (stats.length !== 6 || stats.some((v) => !(v >= 1 && v <= 255))) return "\u4E9A\u6BD4\u7684\u79CD\u65CF\u503C\u662F6\u4E2A1\u2013255\u7684\u6570";
    const learn = [];
    for (const s of Array.isArray(d.skills) ? d.skills : []) {
      const [lv, id2] = Array.isArray(s) ? [Math.floor(Number(s[0])), Math.floor(Number(s[1]))] : [1, Math.floor(Number(s))];
      if (!Object.hasOwn(t.pm.skills, String(id2))) return `\u6280\u80FD${id2}\u4E0D\u662F\u6E38\u620F\u7684\u6280\u80FD`;
      learn.push([Math.max(0, Math.min(MOD_LEVEL_MAX, lv || 0)), id2]);
      if (learn.length >= 40) break;
    }
    if (learn.length === 0) return "\u4E9A\u6BD4\u81F3\u5C11\u8981\u4F1A\u4E00\u4E2A\u6280\u80FD";
    learn.sort((a, b) => a[0] - b[0]);
    const exp = String(d.exp ?? "2");
    return { id, name, attr, stats, learn, exp: Object.hasOwn(t.pm.exp, exp) ? exp : "2" };
  }
  function installMods(world, deps) {
    world.xt("SundriesExtension.revival_mod", async (ctx) => {
      const p = ctx.params;
      const op = String(p.op ?? "");
      const reply = (o) => ctx.reply({ op, tag: p.tag ?? "", ...o });
      const mod = String(p.mod ?? "");
      const rec = await deps.load(ctx);
      if (op === "data") {
        return reply({ data: isModId(mod) && rec.modData && Object.hasOwn(rec.modData, mod) ? rec.modData[mod] : "" });
      }
      if (op === "save") {
        const data = String(p.data ?? "");
        if (!isModId(mod) || bytes(data) > MOD_DATA_MAX) return reply({ res: 0, msg: "too big" });
        const others = Object.entries(rec.modData ?? {}).reduce((n, [k, v]) => k === mod ? n : n + bytes(v), 0);
        if (others + bytes(data) > MOD_DATA_TOTAL) return reply({ res: 0, msg: "too much" });
        try {
          JSON.parse(data || "{}");
        } catch {
          return reply({ res: 0 });
        }
        (rec.modData ??= {})[mod] = data;
        await deps.save(rec);
        return reply({ res: 1 });
      }
      if (op === "species") {
        const t = await deps.tables();
        if (!isModId(mod)) return reply({ res: 0, msg: "\u6A21\u7EC4\u7684\u7F16\u53F7\u4E0D\u5BF9" });
        const sp = parseModSpecies(p.def, t);
        if (typeof sp === "string") return reply({ res: 0, msg: sp });
        const owner = ownersOf(t).get(sp.id);
        if (owner !== void 0 && owner !== mod) return reply({ res: 0, msg: `\u7F16\u53F7${sp.id}\u5DF2\u88AB\u6A21\u7EC4${owner}\u4F7F\u7528` });
        if (owner === void 0 && ownersOf(t).size >= MOD_SPECIES_MAX) return reply({ res: 0, msg: "\u8FD9\u4E2A\u670D\u52A1\u5668\u4E0A\u6A21\u7EC4\u7684\u4E9A\u6BD4\u5DF2\u7ECF\u592A\u591A\u4E86\u3002" });
        ownersOf(t).set(sp.id, mod);
        t.pm.species[String(sp.id)] = {
          n: sp.name,
          s: sp.stats,
          ev: [0, 0, 0, 0, 0, 0],
          t: sp.attr,
          bx: 64,
          xt: sp.exp,
          c: ["NA", "NA"],
          evo: "",
          learn: sp.learn
        };
        t.species[String(sp.id)] = { n: sp.name, a: sp.attr[0], e: 0, next: 0, sk: [] };
        const ours = (m) => m.pet.race === sp.id && (m.pet.mod === void 0 || m.pet.mod === mod);
        const back = (rec.modPets ?? []).filter(ours);
        if (back.length) {
          rec.modPets = (rec.modPets ?? []).filter((m) => !ours(m));
          for (const m of back) {
            if (m.bag && (rec.pets ??= []).length < BAG_MAX) rec.pets.push(m.pet);
            else (rec.storage ??= []).push(m.pet);
          }
          await deps.save(rec);
        }
        const def = { id: sp.id, name: sp.name, attr: sp.attr, stats: sp.stats, skills: sp.learn, exp: sp.exp };
        return reply({ res: 1, back: back.length, def: JSON.stringify(def) });
      }
      if (op === "give") {
        if (deps.gifts === false) return reply({ res: 0, msg: "\u8FD9\u4E2A\u670D\u52A1\u5668\u4E0A\uFF0C\u6A21\u7EC4\u4E0D\u80FD\u9001\u4E9A\u6BD4\u3002" });
        if (!isModId(mod)) return reply({ res: 0, msg: "\u6A21\u7EC4\u7684\u7F16\u53F7\u4E0D\u5BF9" });
        const t = await deps.tables();
        const race = Math.floor(Number(p.race));
        const level = Math.max(1, Math.min(MOD_LEVEL_MAX, Math.floor(Number(p.level)) || 1));
        if (!Object.hasOwn(t.pm.species, String(race))) return reply({ res: 0, msg: "\u6E38\u620F\u91CC\u6CA1\u6709\u8FD9\u4E2A\u4E9A\u6BD4" });
        if (isModRace(race) && ownersOf(t).get(race) !== mod) return reply({ res: 0, msg: "\u8FD9\u4E2A\u4E9A\u6BD4\u4E0D\u662F\u8FD9\u4E2A\u6A21\u7EC4\u7684" });
        const pet = newPet(rec, t, race, level, deps.today());
        if (isModRace(race)) pet.mod = mod;
        if (pet.iv) pet.iv = pet.iv.map((v) => Math.min(MAX_IV, v));
        if ((rec.pets ??= []).length < BAG_MAX) rec.pets.push(pet);
        else (rec.storage ??= []).push(pet);
        await deps.save(rec);
        return reply({ res: 1, id: pet.id });
      }
      reply({ res: 0, msg: "unknown op" });
    });
  }

  // server/src/game/sfs2013/yabistudy.ts
  var FORMULAS = [
    { a: [37, 38, 39], b: [142, 143, 144], item: 38, lva: 50, lvb: 40, makes: [431] },
    { a: [282, 283, 284], b: [70, 71, 72], item: 41, lva: 50, lvb: 40, makes: [458] },
    { a: [422, 423, 424], b: [392, 393, 394], item: 133, lva: 40, lvb: 20, makes: [531] },
    { a: [437, 438, 439], b: [392, 393, 394], item: 133, lva: 50, lvb: 40, makes: [440] },
    { a: [82, 83, 84], b: [58, 59, 60], item: 42, lva: 40, lvb: 20, makes: [549] },
    { a: [73, 74, 75], b: [16, 17, 18], item: 90, lva: 40, lvb: 20, makes: [555] },
    { a: [256, 257, 258], b: [67, 68, 69], item: 90, lva: 40, lvb: 20, makes: [350, 353] },
    { a: [13, 14, 15], b: [46, 47, 48], item: 40, lva: 30, lvb: 30, makes: [596, 599] }
  ];
  var EGG_OF = { 431: 395, 458: 398, 531: 399, 440: 396, 549: 405, 555: 406, 350: 412, 353: 413, 596: 421, 599: 422 };
  var HATCH_HOURS = { 431: 72, 458: 72, 531: 24, 440: 72, 549: 24, 555: 24, 350: 24, 353: 24, 596: 24, 599: 24 };
  var FUSE_STATE = { 395: 3, 398: 4, 399: 6, 396: 5, 405: 7, 406: 8, 412: 8, 413: 8, 421: 9, 422: 9 };
  var VARIATION = 10;
  var FUSE_LEVEL = 1;
  var GENIUS_ENERGY_MAX = 30;
  var GENIUS_ENERGY_COST = 10;
  var GENIUS_XINGBI = 10;
  var GENIUS_COMMON = [1, 3];
  var GENIUS_MONEY = [3, 8];
  var GENIUS_TOP_KEEP = 20;
  var GENIUS_TOP_SHOWN = false;
  var geniusStars = (iv) => iv.reduce((n, v) => n + (v <= 10 ? 1 : v <= 20 ? 2 : v <= 30 ? 3 : v <= 50 ? 4 : 5), 0);
  var STARS_WANZHONG = 25;
  var STARS_WANGZHE = 30;
  var bag2 = (rec, type = "2") => (rec.items ??= {})[type] ??= {};
  function formulaFor(a, b) {
    return FORMULAS.find((f) => f.a.includes(a) && f.b.includes(b));
  }
  async function fuseState(rec, st, deps) {
    const f = rec.fuse?.[String(st)];
    if (!f) return { st: 4, es: [] };
    const now = deps.now();
    if (now < f.end) return { st: 2, es: [{ ri: f.race, lt: Math.max(1, Math.ceil((f.end - now) / 1e3)) }] };
    if (f.pet == null) {
      const pet = newPet(rec, await deps.tables(), f.race, FUSE_LEVEL, deps.today());
      (rec.storage ??= []).push(pet);
      f.pet = pet.id;
      await deps.save(rec);
    }
    return { st: 3, pmList: [{ pmPView: { i: f.pet, r: f.race } }] };
  }
  function fuseCollect(rec, id) {
    for (const [k, f] of Object.entries(rec.fuse ?? {})) {
      if (f.pet === id) {
        delete rec.fuse[k];
        return true;
      }
    }
    return false;
  }
  function installYabiStudy(world, deps) {
    const rnd = deps.random ?? Math.random;
    const pick = (xs) => xs[Math.floor(rnd() * xs.length)];
    const between = ([lo, hi]) => lo + Math.floor(rnd() * (hi - lo + 1));
    const findPet = (rec, id) => rec.pets?.find((p) => p.id === id) ?? rec.storage?.find((p) => p.id === id);
    const removePet = (rec, id) => {
      for (const list of [rec.pets, rec.storage]) {
        const i = list?.findIndex((p) => p.id === id) ?? -1;
        if (list && i >= 0) list.splice(i, 1);
      }
    };
    world.xt("PetExtension2.54e_13", async (ctx) => {
      const rec = await deps.load(ctx);
      const mId = Number(ctx.params.mId) | 0;
      const sId = Number(ctx.params.sId) | 0;
      const a = findPet(rec, mId);
      const b = findPet(rec, sId);
      const f = a && b && mId !== sId ? formulaFor(a.race, b.race) : void 0;
      const items = bag2(rec);
      if (!a || !b || !f || a.level < f.lva || b.level < f.lvb || (items[f.item] ?? 0) < 1) return ctx.reply({ succ: false });
      const race = f.makes.length > 1 && Math.floor(rnd() * VARIATION) === 0 ? f.makes[1] : f.makes[0];
      const egg = EGG_OF[race];
      items[f.item] -= 1;
      if (items[f.item] <= 0) delete items[f.item];
      items[egg] = (items[egg] ?? 0) + 1;
      const followed = rec.followPet === mId || rec.followPet === sId;
      removePet(rec, mId);
      removePet(rec, sId);
      if (followed) {
        delete rec.followPet;
        world.setUserVars(ctx.session, { p: NO_FOLLOW });
      }
      await deps.save(rec);
      ctx.reply({ amount: `2_${f.item}_0_-1` }, "onAmountUpdated");
      ctx.reply({ amount: `2_${egg}_0_1` }, "onAmountUpdated");
      ctx.reply({ succ: true, id: egg });
    });
    world.xt("PetExtension2.54e_14", async (ctx) => {
      const rec = await deps.load(ctx);
      const egg = Number(ctx.params.id) | 0;
      const st = FUSE_STATE[egg];
      const race = Number(Object.keys(EGG_OF).find((r) => EGG_OF[Number(r)] === egg));
      const items = bag2(rec);
      if (!st || !race || (items[egg] ?? 0) < 1 || rec.fuse?.[String(st)]) return;
      items[egg] -= 1;
      if (items[egg] <= 0) delete items[egg];
      (rec.fuse ??= {})[String(st)] = { race, end: deps.now() + HATCH_HOURS[race] * 3600 * 1e3 };
      await deps.save(rec);
      ctx.reply({ amount: `2_${egg}_0_-1` }, "onAmountUpdated");
    });
    const HE = "HolidayExtension";
    const since = /* @__PURE__ */ new WeakMap();
    const energy = (ctx, rec) => {
      const now = deps.now();
      if (!since.has(ctx.player)) since.set(ctx.player, now);
      const g = rec.genius ??= { energy: GENIUS_ENERGY_MAX, t: now };
      const from = Math.max(g.t, since.get(ctx.player));
      const minutes = Math.floor((now - from) / 6e4);
      if (g.energy >= GENIUS_ENERGY_MAX) g.t = now;
      else if (minutes > 0) {
        g.energy = Math.min(GENIUS_ENERGY_MAX, g.energy + minutes);
        g.t = from + minutes * 6e4;
      }
      return g;
    };
    const ivOf = (p) => p.iv ??= [31, 31, 31, 31, 31, 31];
    const raise = async (rec, p, amount) => {
      const iv = ivOf(p);
      const open = iv.map((v, i) => v < MAX_IV ? i : -1).filter((i) => i >= 0);
      const index = pick(open);
      const before = geniusStars(iv);
      const diff = Math.min(MAX_IV - iv[index], between(amount));
      iv[index] += diff;
      if (before < STARS_WANGZHE && geniusStars(iv) >= STARS_WANGZHE && !isModRace(p.race)) {
        const top = await deps.get("area/geniusTop") ?? [];
        top.push(`${rec.name}:${rec.name}:${p.race}`);
        await deps.set("area/geniusTop", top.slice(-GENIUS_TOP_KEEP));
      }
      return { index, diff };
    };
    world.xt(`${HE}.revival_genius_energy`, async (ctx) => {
      const rec = await deps.load(ctx);
      const g = energy(ctx, rec);
      await deps.save(rec);
      ctx.reply({ energy: g.energy });
    });
    world.xt(`${HE}.0118genius_panel`, async (ctx) => {
      const rec = await deps.load(ctx);
      const p = findPet(rec, Number(ctx.params.pId) | 0);
      const g = energy(ctx, rec);
      await deps.save(rec);
      ctx.reply({ ba: p ? ivOf(p).join("#") : "0#0#0#0#0#0", energy: g.energy });
    });
    world.xt(`${HE}.0118genius_power`, async (ctx) => {
      const rec = await deps.load(ctx);
      const p = findPet(rec, Number(ctx.params.pId) | 0);
      const g = energy(ctx, rec);
      if (!p) return ctx.reply({ result: 0, energy: g.energy });
      const iv = ivOf(p);
      if (g.energy < GENIUS_ENERGY_COST) return ctx.reply({ result: -1, energy: g.energy });
      if (geniusStars(iv) >= STARS_WANZHONG || iv.every((v) => v >= MAX_IV)) return ctx.reply({ result: 0, energy: g.energy });
      g.energy -= GENIUS_ENERGY_COST;
      const r = await raise(rec, p, GENIUS_COMMON);
      await deps.save(rec);
      ctx.reply({ result: 2, ...r, energy: g.energy });
    });
    world.xt(`${HE}.0118genius_buy`, async (ctx) => {
      const rec = await deps.load(ctx);
      const p = findPet(rec, Number(ctx.params.pId) | 0);
      if (!p || ivOf(p).every((v) => v >= MAX_IV)) return ctx.reply({ res: 0, result: 0 });
      if ((rec.xingbi ?? 0) < GENIUS_XINGBI) return ctx.reply({ res: 0, result: 0 });
      rec.xingbi = (rec.xingbi ?? 0) - GENIUS_XINGBI;
      ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
      const r = await raise(rec, p, GENIUS_MONEY);
      await deps.save(rec);
      ctx.reply({ res: 1, result: 2, ...r });
    });
    world.xt(`${HE}.0118genius_top`, async (ctx) => {
      const kept = GENIUS_TOP_SHOWN ? await deps.get("area/geniusTop") ?? [] : [];
      const top = kept.filter((row) => !isModRace(Number(row.split(":")[2])));
      ctx.reply({ top: top.join(";") });
    });
  }

  // server/src/game/sfs2013/giftbags.ts
  var I = (name, id, n = 1) => [name, 2, id, n];
  var EGG = (name, race) => [`${name}\u4E9A\u6BD4\u86CB`, 5, race, 1];
  var FORGET6 = (n) => [[154, "\u653B\u51FB"], [155, "\u9632\u5FA1"], [156, "\u7279\u653B"], [157, "\u7279\u9632"], [158, "\u901F\u5EA6"], [159, "\u4F53\u529B"]].map(([id, s]) => I(`\u9057\u5FD8\u55B7\u96FE-${s}`, id, n));
  var NATURE5 = [[414, "\u653B\u51FB"], [415, "\u9632\u5FA1"], [416, "\u7279\u653B"], [417, "\u7279\u9632"], [418, "\u901F\u5EA6"]].map(([id, s]) => I(`\u6027\u683C\u6539\u9020-${s}`, id));
  var EV6 = (n) => [[524, "\u4F53\u529B"], [525, "\u653B\u51FB"], [526, "\u9632\u5FA1"], [527, "\u7279\u653B"], [528, "\u7279\u9632"], [529, "\u901F\u5EA6"]].map(([id, s]) => I(`${s}\u679C\u5B9E`, id, n));
  var EXP2 = (n) => I("\u53CC\u500D\u7ECF\u9A8C\u5668", 43, n);
  var EXP3 = (n) => I("\u4E09\u500D\u7ECF\u9A8C\u5668", 378, n);
  var AUTO = (n) => I("\u81EA\u52A8\u6218\u6597\u4EEA", 44, n);
  var LEARN2 = (n) => I("\u53CC\u500D\u5B66\u4E60\u5668", 62, n);
  var RADAR = (n) => I("\u5BFB\u5B9D\u96F7\u8FBE", 189, n);
  var TALENT = (n) => I("\u5929\u8D4B\u589E\u5F3A\u7CBE\u534E", 177, n);
  var RESHAPE = (n) => I("\u6027\u683C\u91CD\u5851\u5361", 66, n);
  var FIX = (n) => I("\u5F62\u6001\u56FA\u5316\u5242", 220, n);
  var UNDO = (n) => I("\u8FD8\u539F\u55B7\u96FE", 193, n);
  var DOWN = (n) => I("\u964D\u7EA7\u55B7\u96FE", 65, n);
  var BALL = (n) => I("\u767E\u5206\u767E\u4E9A\u6BD4\u7403", 64, n);
  var BALL_DRAGON = (stars, id) => I(`${stars}\u661F\u9F99\u73E0`, id);
  var GIFT_BAGS = {
    228: { got: [...FORGET6(1), LEARN2(2)], exp: 1e5 },
    229: { got: [BALL(2), I("\u5929\u8D4B\u91CD\u7EC4\u80F6\u56CA", 506, 10), ["\u96EA\u82B1\u5C04\u51FB\u5361", 4, 22, 100]], exp: 1e5 },
    230: { got: [FIX(2), UNDO(2)] },
    231: { got: [EXP2(4), AUTO(1), BALL(1), RADAR(2)], exp: 1e5 },
    243: { got: [TALENT(6), RADAR(3), RESHAPE(2)], exp: 1e5 },
    271: { got: [BALL(2), LEARN2(2), EXP2(8), AUTO(4), RADAR(4), I("\u80DC\u5229\u5956\u7AE0", 221, 200)], exp: 1e5, first: BALL_DRAGON("\u516D", 285) },
    272: { got: [...FORGET6(2), DOWN(4), LEARN2(2), TALENT(6)], exp: 1e5, first: BALL_DRAGON("\u4E94", 284) },
    299: { got: [UNDO(5), FIX(4), DOWN(5), RESHAPE(4)], exp: 1e5, first: BALL_DRAGON("\u4E03", 286) },
    300: { got: [EGG("\u9177\u6CE2", 481)], exp: 1e5, first: BALL_DRAGON("\u56DB", 283) },
    321: { got: [EGG("\u5E74\u517D", 493), AUTO(1), LEARN2(2), EXP2(2), TALENT(3)], exp: 2e5 },
    462: { got: [I("\u5929\u8D4B\u91CD\u7EC4\u836F\u5242", 178, 5), EXP2(2), RESHAPE(2), TALENT(2), LEARN2(1), AUTO(1)], exp: 6e4 },
    463: { got: [["\u521D\u7EA7\u52A0\u901F\u9972\u6599", 13, 5, 4], ["\u4E2D\u7EA7\u52A0\u901F\u9972\u6599", 13, 6, 4], ["\u4E8C\u661F\u53D8\u5F02\u9972\u6599", 13, 3, 4], ["\u5C0F\u5976\u725B", 12, 10008, 1], ["\u5C0F\u72F8\u72F8", 12, 10019, 1]], exp: 2e4 },
    484: { got: [LEARN2(1), RADAR(1), RESHAPE(1), EGG("\u795E\u86CB\u86CB", 765), EXP2(2)], exp: 11e4 },
    487: { got: [EGG("\u5143\u86CB\u86CB", 772), BALL(1)], exp: 1e5 },
    497: { got: [EXP3(2), LEARN2(3), AUTO(3), RADAR(1), I("\u8D85\u7EA7\u9057\u5FD8\u55B7\u96FE", 523)], exp: 19e4 },
    498: { got: [BALL(2), TALENT(6), ...NATURE5, RESHAPE(2)], exp: 19e4 },
    501: { got: [AUTO(1), DOWN(1), UNDO(1), EXP2(2), RADAR(2), RESHAPE(2)], exp: 1e5 },
    502: {
      got: [["\u8D64\u9B54\u5BFC\u58EB\u5957\u88C5", 0, 1218, 1], ["", 0, 1219, 1], ["", 0, 1220, 1], ["", 0, 1221, 1], ["", 0, 1222, 1], ["", 0, 1223, 1], EGG("\u8D64\u9B54\u5BFC\u58EB", 796)],
      exp: 12e4
    },
    503: { got: [["\u9AD8\u7EA7\u52A0\u901F\u9972\u6599", 13, 7, 2], ["\u4E09\u661F\u53D8\u5F02\u9972\u6599", 13, 4, 2], ["\u4E2D\u7EA7\u52A0\u901F\u9972\u6599", 13, 6, 4], ["\u8DB4\u8DB4\u718A", 12, 10036, 2]], exp: 12e4 },
    512: { got: [RESHAPE(2), AUTO(2), EXP3(1), RADAR(1), DOWN(1), UNDO(1)], exp: 1e5 },
    516: { got: [EXP2(3), AUTO(2), RESHAPE(1), FIX(1), UNDO(1)], exp: 1e5 },
    521: { got: [EXP2(3), AUTO(2), TALENT(1), FIX(1), RADAR(1)], exp: 1e5 },
    522: { got: [...EV6(17), I("\u8D85\u7EA7\u9057\u5FD8\u55B7\u96FE", 523), DOWN(2)] },
    534: { got: [EXP2(4), AUTO(2), LEARN2(1), FIX(1), RESHAPE(1)], exp: 1e5 },
    537: { got: [EXP2(3), AUTO(2), LEARN2(2), FIX(1), RESHAPE(1)], exp: 1e5 },
    538: { got: [EGG("\u5C0F\u7075\u9F99", 994), I("\u6027\u683C\u6539\u9020-\u653B\u51FB", 414), TALENT(2), LEARN2(2)], exp: 1e5 },
    540: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 1e5 },
    542: { got: [EGG("\u5947\u5947", 1081), FIX(1), AUTO(1), EXP2(2)], exp: 15e4 },
    554: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 1e5 },
    562: { got: [I("\u7075\u4E4B\u5251\u9B42", 567), EXP3(2), AUTO(2), LEARN2(3)], exp: 15e4 },
    563: { got: [I("\u738B\u4E4B\u5251\u9B42", 566), FIX(1), TALENT(6)], exp: 15e4 },
    564: { got: [I("\u5149\u4E4B\u5251\u9B42", 565), BALL(1), RESHAPE(1), ...NATURE5], exp: 15e4 },
    572: { got: [EGG("\u5C0F\u7C73", 1166), FIX(1), AUTO(1), EXP2(2)], exp: 15e4 },
    573: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 1e5 },
    582: { got: [EXP3(2), AUTO(2), RADAR(2), TALENT(2)], exp: 1e5 },
    588: { got: [EXP3(3), ...NATURE5, TALENT(6)], exp: 15e4 },
    593: { got: [EGG("\u4E50\u4E50", 1239), FIX(1), RESHAPE(2)], exp: 15e4 },
    594: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 1e5 },
    601: { got: [EXP3(2), AUTO(2), RADAR(2), TALENT(2), LEARN2(3)], exp: 1e5 },
    602: { got: [I("\u7279\u653B\u679C\u5B9E", 527, 17), I("\u4F53\u529B\u679C\u5B9E", 524, 17), EXP3(2), AUTO(2), LEARN2(2)], exp: 1e5 },
    605: { got: [TALENT(2), AUTO(2), EXP3(2), I("\u653B\u51FB\u679C\u5B9E", 525, 17), I("\u9632\u5FA1\u679C\u5B9E", 526, 17)], exp: 88e3 },
    606: { got: [AUTO(3), LEARN2(3), RADAR(3), EXP3(2), EXP2(2)], exp: 1e5 },
    607: { got: [TALENT(6), ...NATURE5, ...FORGET6(1)], exp: 15e4 },
    611: { got: [EGG("\u5C0F\u5E7B", 1292), I("\u5E7B\u96F7\u8FDB\u5316\u77F3", 616), I("\u5E7B\u96F7\u2022\u8FC5\u96F7\u95EA", 619), I("\u6027\u683C\u6539\u9020-\u7279\u653B", 416)], exp: 1e5 },
    612: { got: [EGG("\u5C0F\u5E7B", 1292), I("\u5E7B\u708E\u8FDB\u5316\u77F3", 614), I("\u5E7B\u708E\u2022\u7206\u708E\u65A9", 617), I("\u6027\u683C\u6539\u9020-\u653B\u51FB", 414)], exp: 1e5 },
    613: { got: [EGG("\u5C0F\u5E7B", 1292), I("\u5E7B\u6D41\u8FDB\u5316\u77F3", 615), I("\u5E7B\u6D41\u2022\u5FA1\u6D41\u672F", 618), I("\u6027\u683C\u6539\u9020-\u9632\u5FA1", 415)], exp: 1e5 },
    626: { got: [TALENT(2), EXP3(2), AUTO(2), RADAR(2), RESHAPE(3)], exp: 1e5 },
    630: { got: [TALENT(2), EXP3(2), AUTO(2), LEARN2(2), RESHAPE(3)], exp: 1e5 },
    633: { got: [EXP3(2), EXP2(2), AUTO(2), RADAR(2), FIX(1)], exp: 1e5 },
    634: { got: [LEARN2(4), I("\u7279\u653B\u679C\u5B9E", 527, 30), I("\u901F\u5EA6\u679C\u5B9E", 529, 30), ...FORGET6(1), ["\u901F\u5EA6\u4E4B\u52C7\u8005\u5361", 8, 24, 1]], exp: 15e4 },
    635: { got: [TALENT(10), BALL(1), I("\u6027\u683C\u6539\u9020-\u7279\u653B", 416, 5), ["\u8D85\u653B\u4E4B\u52C7\u8005\u5361", 8, 33, 1]], exp: 2e5 },
    644: { got: [EXP3(2), RESHAPE(2), LEARN2(2), RADAR(2), AUTO(3)], exp: 1e5 },
    659: { got: [I("\u6447\u6447\u679C\u5B9E", 419, 50), I("\u9AD8\u7EA7\u6447\u6447\u679C\u5B9E", 664, 15), EXP2(2)] },
    660: { got: [I("\u6447\u6447\u679C\u5B9E", 419, 80), I("\u9AD8\u7EA7\u6447\u6447\u679C\u5B9E", 664, 40), EXP2(2)] },
    661: { got: [I("\u6447\u6447\u679C\u5B9E", 419, 100), I("\u9AD8\u7EA7\u6447\u6447\u679C\u5B9E", 664, 30), I("\u8D85\u7EA7\u6447\u6447\u679C\u5B9E", 665), EXP3(2)] },
    662: { got: [RADAR(4)], score: 88888 }
  };
  function isGiftBag(type, id) {
    return String(type) === "2" && GIFT_BAGS[Number(id)] !== void 0;
  }
  function openGiftBag(o, id, count = 1, cap) {
    const bag3 = GIFT_BAGS[id];
    if (!bag3 || count <= 0) return void 0;
    const out = { amounts: [], got: [], score: false };
    const delta = /* @__PURE__ */ new Map();
    const give2 = ([name, type, mi, n], times) => {
      const t = String(type);
      const k = String(mi);
      const owned = (o.items ??= {})[t] ??= {};
      const max = t === "0" ? 1 : Math.max(1, cap?.(t, k) ?? 9999);
      const before = owned[k] ?? 0;
      const after = Math.min(max, before + n * times);
      if (after > before) {
        owned[k] = after;
        delta.set(`${t}_${k}`, (delta.get(`${t}_${k}`) ?? 0) + after - before);
      }
      if (name) out.got.push(`${name}\xD7${n * times}`);
    };
    const seen = o.giftBags ??= [];
    if (bag3.first && !seen.includes(id)) give2(bag3.first, 1);
    if (!seen.includes(id)) seen.push(id);
    for (const g of bag3.got) give2(g, count);
    if (bag3.score) {
      o.score = Math.min(9999999, (o.score ?? 0) + bag3.score * count);
      out.score = true;
      out.got.push(`\u6676\u5E01\xD7${bag3.score * count}`);
    }
    if (bag3.exp) {
      if (o.robot) o.robot.exp += bag3.exp * count;
      else o.helloExp = (o.helloExp ?? 0) + bag3.exp * count;
      out.got.push(`\u7ECF\u9A8C\xD7${bag3.exp * count}`);
    }
    out.amounts = [...delta].map(([k, n]) => `${k}_0_${n}`);
    return out;
  }
  function openHeldGiftBags(o) {
    const items = o.items?.["2"];
    if (items) {
      for (const [k, n] of Object.entries(items)) {
        if (!isGiftBag(2, k) || !(n > 0)) continue;
        delete items[k];
        openGiftBag(o, Number(k), n);
      }
    }
    if (o.helloExp && o.robot) {
      o.robot.exp += o.helloExp;
      delete o.helloExp;
    }
  }

  // server/src/game/sfs2013/game.ts
  var DEFAULT_AVATAR = "6;7;126;127;129;130;131;132";
  var BASE_CLOTHES = ["6", "7"];
  var START_SCORE = 2e3;
  var START_ITEMS = { "30": 3 };
  var EMPTY_INVENTORY = {
    "MaterialExtension.61_5": { pd: [] },
    // PetClothesService
    "MaterialExtension.61-8": { cards: [] },
    // PetCard2Service
    "PlantItemExtension.81_2": { items: [] },
    // PlantItemService
    "SundriesExtension.70-1": { b: [] }
    // BadgeService
  };
  var HOT_SPRING_SECONDS = 900;
  var HOT_SPRING_EXP = 20;
  var userKey = (name) => `user/${encodeURIComponent(name)}`;
  var queues = /* @__PURE__ */ new WeakMap();
  var IMPORT_SETTLE_MS = 300;
  var LOGIN_WAIT_MS = 3e4;
  var QUEST_ITEM_MAX = 99;
  var guards = /* @__PURE__ */ new WeakMap();
  var guardOf = (emu) => {
    let g = guards.get(emu);
    if (!g) guards.set(emu, g = new PassGuard());
    return g;
  };
  async function passProblem(emu, rec, pass, addr = "") {
    const g = guardOf(emu);
    const key = `${rec.name}\0${addr}`;
    if (g.locked(key)) return LOCKED;
    if (!rec.pass || !pass || !await checkPass(pass, rec.pass)) {
      g.failed(key);
      return "\u5BC6\u7801\u4E0D\u5BF9\u54E6\u3002";
    }
    g.passed(key);
    return null;
  }
  function oneAtATime(emu, f) {
    const r = (queues.get(emu) ?? Promise.resolve()).then(f, f);
    queues.set(emu, r.catch(() => {
    }));
    return r;
  }
  async function newUser(emu, name) {
    const next = (await emu.store.get("meta/nextUserId") ?? 1e4) + 1;
    await emu.store.set("meta/nextUserId", next);
    return normalise2({ id: next, name, avatar: DEFAULT_AVATAR, createdAt: emu.clock.now().toISOString() });
  }
  async function userRecord(emu, name) {
    const rec = await emu.store.get(userKey(name));
    if (rec) normalise2(rec);
    return rec;
  }
  function normalise2(rec) {
    if (!rec.avatar) rec.avatar = DEFAULT_AVATAR;
    const wornNow = rec.avatar.split(";").filter(Boolean);
    for (const id of BASE_CLOTHES) if (!wornNow.includes(id)) wornNow.unshift(id);
    rec.avatar = wornNow.join(";");
    if (rec.score == null) rec.score = START_SCORE;
    if (!rec.items) rec.items = {};
    const clothes = rec.items["0"] ??= {};
    for (const id of rec.avatar.split(";").filter(Boolean)) clothes[id] ??= 1;
    if (!rec.kit) {
      const items = rec.items["2"] ??= {};
      for (const [id, q] of Object.entries(START_ITEMS)) items[id] = (items[id] ?? 0) + q;
      rec.kit = true;
    }
    houseOf(rec);
    openHeldGiftBags(rec);
    return rec;
  }
  var GAME_SCORE_PER_COIN = 10;
  var GAME_COINS_PER_GAME = 200;
  var GAME_COINS_PER_DAY = 1e3;
  function decryptScore(code) {
    const EVEN = [1, 3, 6, 0, 9, 5, 2, 7, 4, 8];
    const ODD = [2, 7, 4, 8, 1, 3, 6, 0, 9, 5];
    const POS = [2, 5, 3, 0, 6, 4, 1];
    const c = String(Math.max(0, Math.floor(code))).padStart(9, "0").slice(-9).split("").map(Number);
    const b = c.map((v, i) => (i % 2 === 1 ? ODD : EVEN).indexOf(v));
    const p = [];
    p[0] = (b[0] - 7 + 10) % 10;
    for (let i = 1; i < 9; i++) p[i] = (b[i] - p[i - 1] + 10) % 10;
    const a = p.slice(1, 8);
    const d = new Array(7).fill(0);
    for (let i = 0; i < 7; i++) d[POS[i]] = a[i];
    return Number(d.join(""));
  }
  var TABLE_RETRY_MS = 3e4;
  function siteTable(load, empty, retryMs = TABLE_RETRY_MS, now = Date.now) {
    let kept;
    let asking;
    let missedAt = -Infinity;
    return () => {
      if (kept !== void 0) return Promise.resolve(kept);
      if (asking) return asking;
      if (now() - missedAt < retryMs) return Promise.resolve(empty);
      asking = load().then((t) => {
        if (t == null || typeof t !== "object") throw new Error("no table");
        return kept = t;
      }).catch(() => {
        missedAt = now();
        return empty;
      }).finally(() => asking = void 0);
      return asking;
    };
  }
  function installSfs2013(emu, opts = {}) {
    const site = (path) => opts.loadJson ? opts.loadJson(path) : Promise.resolve(void 0);
    const table = siteTable(() => site("revival/materials.json"), {});
    const species = siteTable(() => site("revival/pets.json"), {});
    const pmData = siteTable(() => site("revival/pmdata.json"), EMPTY_PMDATA);
    const petTables = { species: {}, pm: EMPTY_PMDATA };
    const tables = async () => {
      petTables.species = await species();
      petTables.pm = await pmData();
      return petTables;
    };
    const wild = siteTable(() => site("revival/wildpets.json"), {});
    const world = new World(emu, {
      login: (zone, user, pass, s) => oneAtATime(emu, () => login(zone, user, pass, s.link.remote)),
      refuseDelayMs: opts.accounts?.required ? 1e3 : 0,
      loginWaitMs: opts.accounts?.required ? LOGIN_WAIT_MS : 0
    });
    async function login(_zone, user, pass, addr) {
      const name = (user || "\u5C0F\u5965\u62C9").trim();
      let rec = await userRecord(emu, name);
      const acc = opts.accounts;
      if (acc?.required) {
        const bad = nameProblem(name);
        if (bad) return { id: 0, name, error: bad };
        if (!rec && !acc.register) return { id: 0, name, error: "\u6CA1\u6709\u8FD9\u4E2A\u5965\u62C9\uFF0C\u8BF7\u5148\u6CE8\u518C\u3002" };
        if (!pass) return { id: 0, name, error: "\u8BF7\u8F93\u5165\u5BC6\u7801\u3002" };
        if (rec?.pass) {
          const wrong = await passProblem(emu, rec, pass, addr);
          if (wrong) return { id: 0, name, error: wrong };
        } else if (rec) {
          if (!acc.adopt) return { id: 0, name, error: "\u8FD9\u4E2A\u5965\u62C9\u8FD8\u6CA1\u6709\u5BC6\u7801\uFF0C\u8BF7\u670D\u52A1\u5668\u7684\u4E3B\u4EBA\u6253\u5F00 --adopt \u540E\u518D\u767B\u5F55\u4E00\u6B21\u3002" };
          rec.pass = await hashPass(pass);
        }
      }
      if (!rec) {
        rec = await newUser(emu, name);
        if (acc?.required && pass) rec.pass = await hashPass(pass);
      }
      const known = await tables();
      stashModPets(rec, (race) => !!speciesOf(known, race));
      await emu.store.set(userKey(name), rec);
      await emu.store.set(`uid/${rec.id}`, rec.name);
      const follow = rec.pets?.find((p) => p.id === rec.followPet);
      return {
        id: rec.id,
        name: rec.name,
        vars: { avatar: rec.avatar, c: rec.avatar, nn: rec.name, mtype: rec.vip ? 4 : 0, p: follow ? followVar(follow) : NO_FOLLOW }
      };
    }
    const syncFollow = (rec) => {
      const s = world.online(rec.name);
      const pet = rec.pets?.find((x) => x.id === rec.followPet);
      const [race, , id] = String(s ? world.player(s)?.vars.get("p")?.value ?? "" : "").split(",").map(Number);
      if (s && pet && id === pet.id && race !== pet.race) world.setUserVarOnce(s, "p", followVar(pet));
    };
    const save = async (rec) => {
      await emu.store.set(userKey(rec.name), rec);
      syncFollow(rec);
    };
    const me = async (ctx) => await userRecord(emu, ctx.player.name);
    for (const [key, reply] of Object.entries(EMPTY_INVENTORY)) {
      world.xt(key, (ctx) => ctx.reply(structuredClone(reply)));
    }
    world.xt("MaterialExtension.getUserClothes", async (ctx) => {
      const un = String(ctx.params?.un ?? ctx.player.name);
      const rec = await userRecord(emu, un);
      const worn = new Set((rec?.avatar ?? DEFAULT_AVATAR).split(";").filter(Boolean));
      const owned = Object.keys(rec?.items?.["0"] ?? {});
      for (const id of worn) if (!owned.includes(id)) owned.push(id);
      ctx.reply({ un, cl: owned.map((id) => `${id},${worn.has(id) ? 1 : 0}`).join(";") });
    });
    world.xt("MaterialExtension.getUserWearingClothes", async (ctx) => {
      const un = String(ctx.params?.un ?? ctx.player.name).slice(0, 64);
      const rec = await userRecord(emu, un);
      ctx.reply({ un, cl: rec?.avatar ?? DEFAULT_AVATAR });
    });
    world.xt("MaterialExtension.updateMyWearingClothes", async (ctx) => {
      const rec = await me(ctx);
      const worn = new Set(rec.avatar.split(";").filter(Boolean));
      for (const id of String(ctx.params.cid ?? "").split(",").filter(Boolean)) {
        if (!rec.items["0"]?.[id] || BASE_CLOTHES.includes(id)) continue;
        if (worn.has(id)) worn.delete(id);
        else worn.add(id);
      }
      rec.avatar = [...worn].join(";");
      await save(rec);
      world.setUserVars(ctx.session, { avatar: wornWithRide(rec), c: wornWithRide(rec) });
      ctx.reply({ res: "true", cid: ctx.params.cid });
    });
    world.xt("MaterialExtension.61_1", async (ctx) => {
      const rec = await me(ctx);
      const f = rec.items["1"] ?? {};
      const used = usedUp(rec);
      ctx.reply({ furnitures: Object.entries(f).map(([id, q]) => ({ id: Number(id), qt: q, uq: Math.min(q, used[id] ?? 0) })) });
    });
    world.xt("MaterialExtension.14_2", async (ctx) => {
      const rec = await me(ctx);
      const it = rec.items["2"] ?? {};
      ctx.reply({ userms: Object.entries(it).map(([id, q]) => ({ mi: Number(id), qt: q, uq: 0 })), period: [] });
    });
    world.xt("ScoreManager.getTotalScore", async (ctx) => {
      const rec = await me(ctx);
      ctx.reply({ userId: rec.id, totalScore: rec.score });
    });
    const FORTUNE_DAY = 24 * 3600 * 1e3;
    world.xt("ScoreManager.getAccount", async (ctx) => {
      const rec = await me(ctx);
      const al = (rec.fortune ?? []).map((a, id) => a ? { id, sc: a.sc, sd: a.sd, d: a.d } : null).filter(Boolean);
      ctx.reply({ al, now: emu.clock.now().getTime() });
    });
    world.xt("ScoreManager.despositAccount", async (ctx) => {
      const rec = await me(ctx);
      const ai = Number(ctx.params.ai) | 0;
      const sc = Number(ctx.params.sc) | 0;
      const d = Number(ctx.params.d) | 0;
      const boxes = rec.fortune ??= [];
      if (ai < 0 || ai > 4 || boxes[ai] || d < 1 || d > 7 || sc < 1e3 || sc > 1e6 || (rec.score ?? 0) < sc) return ctx.reply({ b: false });
      rec.score = (rec.score ?? 0) - sc;
      boxes[ai] = { sc, sd: emu.clock.now().getTime(), d };
      await save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      ctx.reply({ b: true });
    });
    world.xt("ScoreManager.takeAwawyAccount", async (ctx) => {
      const rec = await me(ctx);
      const ai = Number(ctx.params.ai) | 0;
      const a = rec.fortune?.[ai];
      if (!a) return ctx.reply({ res: -1, interest: 0 });
      const now = emu.clock.now().getTime();
      const interest = now >= a.sd + a.d * FORTUNE_DAY ? Math.floor(a.sc * a.d * a.d / 1e3) : Math.floor(a.sc * Math.floor((now - a.sd) / FORTUNE_DAY) * 1e-3);
      rec.fortune[ai] = null;
      rec.score = (rec.score ?? 0) + a.sc + interest;
      await save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      ctx.reply({ res: a.sc + interest, interest });
    });
    world.xt("ScoreManager.increaseScore", async (ctx) => {
      const rec = await me(ctx);
      const points = Math.max(0, decryptScore(Number(ctx.params.score) || 0));
      const day = emu.clock.now().toISOString().slice(0, 10);
      if (rec.gameCoins?.day !== day) rec.gameCoins = { day, n: 0 };
      let coins = Math.min(GAME_COINS_PER_GAME, Math.floor(points / GAME_SCORE_PER_COIN));
      let state = 1;
      if (rec.gameCoins.n + coins > GAME_COINS_PER_DAY) {
        coins = Math.max(0, GAME_COINS_PER_DAY - rec.gameCoins.n);
        state = -1;
      }
      rec.gameCoins.n += coins;
      rec.score = (rec.score ?? 0) + coins;
      const game = String(ctx.params.gameName ?? "");
      const lv = Number(ctx.params.level) | 0;
      if (game && lv > 0) (rec.gameLevels ??= {})[game] = Math.max(rec.gameLevels[game] ?? 0, lv);
      await save(rec);
      if (coins > 0) ctx.reply({ score: rec.score }, "onScoreUpdated");
      ctx.reply({ scoreAdded: coins, state, got: false, score: rec.score, points, gameName: String(ctx.params.gameName ?? "") }, "increaseScore");
    });
    world.xt("MaterialExtension.61_2", async (ctx) => {
      const tp = String(Number(ctx.params.tp ?? 0) | 0);
      const mi = String(Number(ctx.params.mi ?? 0) | 0);
      const qt = Math.max(1, Number(ctx.params.qt ?? 1) | 0);
      const rec = await me(ctx);
      const row = (await table())[tp]?.[mi];
      const fail = (result) => ctx.reply({ result, tp: Number(tp), mi: Number(mi), qt, score: 0 });
      const worn = tp === "0" && String(rec.avatar ?? "").split(";").includes(mi);
      if (!row || row[1] <= 0 || worn) return fail(-1);
      const owned = (rec.items ??= {})[tp] ??= {};
      const standing = tp === "1" ? usedUp(rec)[mi] ?? 0 : 0;
      if ((owned[mi] ?? 0) - standing < qt) return fail(-2);
      owned[mi] -= qt;
      if (owned[mi] <= 0) delete owned[mi];
      const each2 = row[0] > 0 ? Math.min(row[1], row[0]) : row[1];
      const got = each2 * qt;
      rec.score = Math.min(9999999, (rec.score ?? 0) + got);
      await save(rec);
      ctx.reply({ amount: `${tp}_${mi}_0_-${qt}` }, "onAmountUpdated");
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      ctx.reply({ result: 1, tp: Number(tp), mi: Number(mi), qt, score: got });
    });
    world.xt("MaterialExtension.buyMaterial", async (ctx) => {
      const tp = String(ctx.params.tp ?? "0");
      const mi = String(ctx.params.mi ?? "0");
      const qt = Math.max(1, Number(ctx.params.qt ?? 1) | 0);
      const row = (await table())[tp]?.[mi];
      const rec = await me(ctx);
      const fail = (res) => ctx.reply({ res, result: res, tp: Number(tp), mi: Number(mi), qt });
      if (!row) return fail(-1);
      const owned = rec.items[tp] ??= {};
      if (tp === "9") {
        const tree = plantTree(rec, Number(mi));
        if (typeof tree === "number") return fail(tree === -2 ? -2 : -4);
        await save(rec);
        ctx.reply({ score: rec.score }, "onScoreUpdated");
        ctx.reply({ amount: `9_${mi}_0_1_${tree.id}` }, "onAmountUpdated");
        return ctx.reply({ res: 1, tp: 9, mi: Number(mi), qt: 1, score: rec.score });
      }
      const [price, buyback, rmb, maxQ, vipOnly] = row;
      const unit = price > 0 ? price : buyback * 2;
      const tab = await table();
      const deliver = () => {
        if (!isGiftBag(tp, mi)) {
          owned[mi] = (owned[mi] ?? 0) + qt;
          return { amount: `${tp}_${mi}_0_${qt}` };
        }
        const op = openGiftBag(rec, Number(mi), qt, (t, id) => t === "2" ? tab["2"]?.[id]?.[3] ?? 9999 : 9999);
        return { amount: op.amounts.join("#"), got: op.got.join("\u3001"), score: op.score };
      };
      if (vipOnly && !rec.vip) return fail(-6);
      if ((owned[mi] ?? 0) + qt > Math.max(1, maxQ)) return fail(-4);
      if (unit <= 0 && rmb > 0) {
        const coins = (rec.vip ? Math.ceil(rmb / 2) : rmb) * qt;
        if ((rec.xingbi ?? 0) < coins) return fail(-5);
        rec.xingbi = (rec.xingbi ?? 0) - coins;
        const d2 = deliver();
        await save(rec);
        ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
        if (d2.score) ctx.reply({ score: rec.score }, "onScoreUpdated");
        if (d2.amount) ctx.reply({ amount: d2.amount }, "onAmountUpdated");
        return ctx.reply({ res: 1, tp: Number(tp), mi: Number(mi), qt, xingbi: rec.xingbi, ...d2.got !== void 0 ? { got: d2.got } : {} });
      }
      const cost = unit * qt;
      if (rec.score < cost) return fail(-2);
      rec.score -= cost;
      const d = deliver();
      await save(rec);
      ctx.reply({ score: rec.score }, "onScoreUpdated");
      if (d.amount) ctx.reply({ amount: d.amount }, "onAmountUpdated");
      ctx.reply({ res: 1, result: 1, tp: Number(tp), mi: Number(mi), qt, score: rec.score, ...d.got !== void 0 ? { got: d.got } : {} });
    });
    const GATHER_PER_DAY = 10;
    const gatherState = (rec) => {
      const day = emu.clock.now().toISOString().slice(0, 10);
      if (rec.gathered?.day !== day) rec.gathered = { day, n: {} };
      return rec.gathered;
    };
    const gatherCheck = async (rec, mi) => {
      const row = (await table())["2"]?.[mi];
      const maxQ = row ? Math.max(1, row[3]) : 99;
      if ((gatherState(rec).n[mi] ?? 0) >= GATHER_PER_DAY) return 1;
      if ((rec.items["2"]?.[mi] ?? 0) >= maxQ) return 2;
      return 0;
    };
    world.xt("MaterialExtension.14_14", async (ctx) => {
      const mi = String(Number(ctx.params.ItemId));
      ctx.reply({ ItemId: Number(mi), result: await gatherCheck(await me(ctx), mi) });
    });
    world.xt("MaterialExtension.14_11", async (ctx) => {
      const mi = String(Number(ctx.params.ItemId));
      const rec = await me(ctx);
      if (isGiftBag(2, mi) || await gatherCheck(rec, mi) !== 0) return ctx.reply({ result: 2, itemId: Number(mi), qt: 0 });
      const qt = 1;
      const st = gatherState(rec);
      st.n[mi] = (st.n[mi] ?? 0) + 1;
      const items = rec.items["2"] ??= {};
      items[mi] = (items[mi] ?? 0) + qt;
      await save(rec);
      ctx.reply({ amount: `2_${mi}_0_${qt}` }, "onAmountUpdated");
      ctx.reply({ result: 1, itemId: Number(mi), qt });
    });
    const questItem = async (ctx, once, sign) => {
      const mi = String(Number(ctx.params.ii));
      const qt = Math.min(QUEST_ITEM_MAX, Math.max(1, Number(ctx.params.qt) | 0));
      if (sign > 0 && !isQuestItem(Number(mi))) return;
      const rec = await me(ctx);
      const items = rec.items["2"] ??= {};
      if (once && (items[mi] ?? 0) > 0) return;
      const row = (await table())["2"]?.[mi];
      const maxQ = row ? Math.max(1, row[3]) : 999;
      const before = items[mi] ?? 0;
      const after = sign > 0 ? Math.min(maxQ, before + qt) : Math.max(0, before - qt);
      if (after === before) return;
      if (after > 0) items[mi] = after;
      else delete items[mi];
      ctx.reply({ amount: `2_${mi}_0_${after - before}` }, "onAmountUpdated");
      const r = stepsByItems(rec, emu.clock.now().getTime());
      for (const [ii, n] of r.taken) ctx.reply({ amount: `2_${ii}_0_${-n}` }, "onAmountUpdated");
      for (const c of r.changes) ctx.reply({ t: c.t, ty: c.ty }, "10-1");
      if (r.score !== void 0) ctx.reply({ score: r.score }, "onScoreUpdated");
      await save(rec);
    };
    world.xt("MaterialExtension.14_8", (ctx) => questItem(ctx, false, 1));
    world.xt("MaterialExtension.14_6", (ctx) => questItem(ctx, true, 1));
    world.xt("MaterialExtension.14_7", (ctx) => questItem(ctx, false, -1));
    const toolbox = opts.toolbox ?? true;
    world.xt("SundriesExtension.revival_toolbox", async (ctx) => {
      const rec = await me(ctx);
      const p = ctx.params;
      const gifts = ["score", "xingbi", "jingdou", "exp", "raceId", "vip"].some((k) => p[k] != null && p[k] !== 0 && p[k] !== "");
      if (!toolbox && gifts) {
        return ctx.reply({ score: rec.score ?? 0, xingbi: rec.xingbi ?? 0, jingdou: rec.jingdou ?? 0, vip: !!rec.vip, msg: "\u8FD9\u4E2A\u670D\u52A1\u5668\u5173\u95ED\u4E86\u5DE5\u5177\u7BB1\u3002" }, "revival_toolbox");
      }
      const t = await tables();
      const add = (v) => Math.max(0, Math.min(9999999, Number(v) | 0));
      const said = [];
      if (add(p.score)) {
        rec.score = Math.min(9999999, (rec.score ?? 0) + add(p.score));
        ctx.reply({ score: rec.score }, "onScoreUpdated");
        said.push(`\u6676\u5E01 +${add(p.score)}`);
      }
      if (add(p.xingbi)) {
        rec.xingbi = Math.min(9999999, (rec.xingbi ?? 0) + add(p.xingbi));
        ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
        said.push(`\u661F\u5E01 +${add(p.xingbi)}`);
      }
      if (p.vip != null) {
        rec.vip = !!p.vip;
        world.setUserVars(ctx.session, { mtype: rec.vip ? 4 : 0 });
        said.push(rec.vip ? "\u4F60\u6210\u4E3A\u4E86\u84DD\u5B9D\u77F3\uFF01" : "\u4F60\u4E0D\u518D\u662F\u84DD\u5B9D\u77F3\u4E86");
      }
      if (add(p.jingdou)) {
        rec.jingdou = Math.min(9999999, (rec.jingdou ?? 0) + add(p.jingdou));
        said.push(`\u6676\u8C46 +${add(p.jingdou)}`);
      }
      if (add(p.exp)) {
        const pet = rec.pets?.[0];
        if (!pet) said.push("\u80CC\u5305\u91CC\u6CA1\u6709\u4E9A\u6BD4\uFF0C\u7ECF\u9A8C\u6CA1\u6709\u52A0\u4E0A");
        else {
          const r = gainExp(t, pet, add(p.exp));
          for (const [cmd, body] of r.msgs) ctx.reply(body, cmd);
          if (r.evolvedTo && rec.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
          said.push(`${nameOf(t, pet.race)} \u7ECF\u9A8C +${add(p.exp)}\uFF08Lv${pet.level}\uFF09`);
        }
      }
      const race = Number(p.raceId) | 0;
      if (race > 0) {
        if (!speciesOf(t, race)) said.push(`\u6CA1\u6709\u7F16\u53F7\u4E3A ${race} \u7684\u4E9A\u6BD4`);
        else {
          const pet = newPet(rec, t, race, Math.max(1, Math.min(100, Number(p.level) || 5)), today());
          if ((rec.pets ??= []).length < 6) {
            rec.pets.push(pet);
            ctx.reply({ pm: detailOf(pet, rec, t) }, "2201");
            said.push(`\u5F97\u5230\u4E86 Lv${pet.level} ${nameOf(t, race)}`);
          } else {
            (rec.storage ??= []).push(pet);
            said.push(`\u5F97\u5230\u4E86 Lv${pet.level} ${nameOf(t, race)}\uFF0C\u80CC\u5305\u6EE1\u4E86\uFF0C\u653E\u8FDB\u4E86\u4E9A\u6BD4\u4ED3\u5E93`);
          }
        }
      }
      await save(rec);
      ctx.reply({ score: rec.score ?? 0, xingbi: rec.xingbi ?? 0, jingdou: rec.jingdou ?? 0, vip: !!rec.vip, msg: said.join("\n") }, "revival_toolbox");
    });
    const today = () => emu.clock.now().toISOString().slice(0, 10);
    installPets(world, { load: me, save: (o) => save(o), tables, today, anyPet: toolbox || !!opts.dev, now: () => emu.clock.now().getTime() });
    installPetDic(world, { load: me, save: (o) => save(o), tables });
    installBattles(world, {
      load: me,
      save: (o) => save(o),
      tables,
      wild,
      today,
      now: () => emu.clock.now().getTime(),
      find: (name) => userRecord(emu, name)
    });
    installSocial(world, {
      load: me,
      save: (o) => save(o),
      byName: (name) => userRecord(emu, name),
      nameOf: (id) => emu.store.get(`uid/${id}`)
    });
    installPetCards(world, {
      load: me,
      save: (o) => save(o),
      maxHp: async (o, pet) => maxHpOf(pet, await tables())
    });
    installPetItems(world, {
      load: me,
      save: (o) => save(o),
      tables,
      changedRace: (ctx, o, pet) => {
        if (o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
      }
    });
    const taskTables = siteTable(
      () => site("revival/tasks.json").then((t) => {
        if (t && typeof t === "object") registerTaskTables(t);
        return t;
      }),
      { defines: {}, starters: {} }
    );
    void taskTables();
    const givePetTo = async (rec, race, level) => {
      const t = await tables();
      if (!speciesOf(t, race)) return [];
      const pet = newPet(rec, t, race, level, today());
      if ((rec.pets ??= []).length < 6) {
        rec.pets.push(pet);
        return [["2201", { pm: detailOf(pet, rec, t) }]];
      }
      (rec.storage ??= []).push(pet);
      return [];
    };
    installTasks(world, {
      load: me,
      byName: (name) => userRecord(emu, name),
      save: (o) => save(o),
      now: () => emu.clock.now().getTime(),
      ready: taskTables,
      dev: opts.dev,
      onFinish: async (o, task) => {
        const rw = QUEST_REWARDS[task];
        if (!rw) return [];
        const rec = o;
        const out = [];
        if (rw.score) {
          rec.score = (rec.score ?? 0) + rw.score;
          out.push(["onScoreUpdated", { score: rec.score }]);
        }
        if (rw.petExp && rec.pets?.[0]) gainExp(await tables(), rec.pets[0], rw.petExp);
        for (const [type, ids] of Object.entries(rw.items ?? {})) {
          const bag3 = (rec.items ??= {})[type] ??= {};
          for (const [id, n] of Object.entries(ids)) {
            bag3[id] = (bag3[id] ?? 0) + n;
            out.push(["onAmountUpdated", { amount: `${type}_${id}_0_${n}` }]);
          }
        }
        if (rw.vipPet && rec.vip) out.push(...await givePetTo(rec, rw.vipPet, 1));
        return out;
      }
    });
    const RIDE = {
      30: [10049, 1.2, 36],
      45: [10047, 1.3, 36],
      105: [10048, 1.2, 40],
      141: [10051, 1.2, 36],
      278: [10052, 1.5, 40],
      138: [10050, 1.2, 36],
      198: [10053, 1.3, 36],
      300: [10054, 1.2, 36],
      189: [10055, 1.2, 40],
      299: [10056, 1.3, 40],
      153: [10057, 1.2, 40],
      24: [10058, 1.2, 32],
      90: [10059, 1.3, 40],
      481: [10060, 1.3, 40],
      506: [10061, 1.5, 1],
      290: [10062, 1.6, 40],
      493: [10063, 1.3, 40],
      391: [10064, 1.3, 40],
      388: [10065, 1.4, 40],
      75: [10066, 1.25, 40],
      215: [10067, 1.3, 40],
      111: [10068, 1.3, 40],
      624: [10069, 1.3, 40],
      653: [10070, 1.4, 40],
      654: [10071, 1.3, 36],
      741: [10072, 1.3, 40],
      775: [10073, 1.3, 40],
      794: [10074, 1.5, 40],
      180: [10075, 1.3, 40],
      838: [10076, 1.4, 40],
      1082: [10077, 1.4, 40],
      1126: [10078, 1.4, 40],
      1240: [10079, 1.3, 40],
      1356: [10080, 1.3, 40],
      // The later client's 坐骑 up to 1651 (the revival's 亚比 go that far: the 工具箱).
      1101: [10089, 1.5, 40],
      1122: [10087, 1.5, 42],
      1350: [10086, 1.5, 40],
      1423: [10083, 1.3, 40],
      1426: [10088, 1.5, 40],
      1430: [10081, 1.3, 40],
      1448: [10082, 1.3, 40],
      1461: [10084, 1.3, 40],
      1599: [10085, 1.3, 40]
    };
    const riding = /* @__PURE__ */ new Map();
    const wornWithRide = (rec) => {
      const r = riding.get(rec.name);
      return r ? `${rec.avatar};${r.cloth}` : rec.avatar ?? "";
    };
    world.xt("PetExtension.54_12", async (ctx) => {
      const rec = await me(ctx);
      const pet = (rec.pets ?? []).find((p) => p.id === (Number(ctx.params.pmId) | 0));
      const ride = pet ? RIDE[pet.race] : void 0;
      if (!pet || !ride) return ctx.reply({ succ: false, msg: "\u8FD9\u53EA\u4E9A\u6BD4\u8FD8\u4E0D\u80FD\u9A91\u4E58\u54E6\uFF01" }, "54_12");
      if (!rec.vip) return ctx.reply({ succ: false, msg: "\u53EA\u6709\u84DD\u5B9D\u9A91\u58EB\u624D\u80FD\u9A91\u4E58\u4E9A\u6BD4\u54E6\uFF01" }, "54_12");
      if (pet.level < ride[2]) return ctx.reply({ succ: false, msg: `\u8981\u5230${ride[2]}\u7EA7\u624D\u80FD\u9A91\u4E58\u54E6\uFF01` }, "54_12");
      riding.set(rec.name, { pmId: pet.id, cloth: ride[0] });
      world.setUserVars(ctx.session, { avatar: wornWithRide(rec), c: wornWithRide(rec) });
      ctx.reply({ succ: true, pmId: pet.id, cId: ride[0], sp: ride[1] }, "54_12");
    });
    world.xt("PetExtension.54_20", async (ctx) => {
      const rec = await me(ctx);
      riding.delete(rec.name);
      world.setUserVars(ctx.session, { avatar: rec.avatar, c: rec.avatar });
      ctx.reply({ succ: true }, "54_20");
    });
    world.xt("PetExtension.54_11", async (ctx) => ctx.reply({ succ: true, pmId: Number(ctx.params.pmId) | 0 }, "54_11"));
    world.xt("SundriesExtension.70_52", async (ctx) => {
      const rec = await me(ctx);
      const r = rec;
      if (!rec.vip || rec.tasks?.["1652"]?.st !== 1 || (r.gifts ?? []).includes("1652")) return ctx.reply({}, "70_52");
      (r.gifts ??= []).push("1652");
      const msgs = await givePetTo(rec, 190, 1);
      await save(rec);
      for (const [cmd, body] of msgs) ctx.reply(body, cmd);
      ctx.reply({ bn: 1 }, "70_52");
    });
    installHouse(world, {
      me,
      find: (name) => userRecord(emu, name),
      save: (o) => save(o),
      visits: {
        get: (id) => emu.store.get(`visits/${id}`),
        set: (id, v) => emu.store.set(`visits/${id}`, v),
        nameOf: (id) => emu.store.get(`uid/${id}`)
      },
      now: () => emu.clock.now().getTime()
    });
    installPlants(world, {
      me,
      find: (name) => userRecord(emu, name),
      save: (o) => save(o),
      now: () => emu.clock.now().getTime(),
      // The 亚比 the owner 展示 (the 亚比仓库's, pets.ts revival_show): the garden shows it.
      shown: async (o) => {
        const r = o;
        const p = r.showPet ? [...r.pets ?? [], ...r.storage ?? []].find((x) => x.id === r.showPet) : void 0;
        return p ? { i: p.id, r: p.race, lv: p.level, nm: p.nick || nameOf(await tables(), p.race) } : null;
      }
    });
    installMods(world, {
      load: async (ctx) => await me(ctx),
      save: (o) => save(o),
      tables,
      today,
      gifts: toolbox
    });
    const labDeps = {
      load: async (ctx) => await me(ctx),
      save: (o) => save(o),
      now: () => emu.clock.now().getTime(),
      today,
      tables,
      get: (k) => emu.store.get(k),
      set: (k, v) => emu.store.set(k, v)
    };
    installYabiStudy(world, labDeps);
    installEggs(world, {
      me,
      save: (o) => save(o),
      now: () => emu.clock.now().getTime(),
      hatchPet: async (o, race, level) => {
        const pet = newPet(o, await tables(), race, level, today());
        (o.storage ??= []).push(pet);
        return pet.id;
      },
      fuse: {
        state: (o, st) => fuseState(o, st, labDeps),
        collect: (o, id) => fuseCollect(o, id)
      }
    });
    installZoo(world, {
      me,
      save: (o) => save(o),
      now: () => emu.clock.now().getTime(),
      byName: (name) => userRecord(emu, name),
      givePet: async (o, race) => {
        const t = await tables();
        if (!t.species[String(race)]) return void 0;
        const pet = newPet(o, t, race, 1, today());
        (o.storage ??= []).push(pet);
        return t.species[String(race)].n;
      }
    });
    installParkour(world, {
      load: me,
      save: (o) => save(o),
      today,
      now: () => emu.clock.now().getTime(),
      board: {
        get: async () => await emu.store.get("parkour/board") ?? [],
        set: (rows) => emu.store.set("parkour/board", rows)
      }
    });
    installMiniGames(world, {
      load: me,
      save: (o) => save(o),
      now: () => emu.clock.now().getTime(),
      pets: tables,
      board: {
        get: async () => await emu.store.get("limitbomb/board") ?? [],
        set: (rows) => emu.store.set("limitbomb/board", rows)
      }
    });
    installPlanetActs(world, {
      load: me,
      find: (name) => userRecord(emu, name),
      save: (o) => save(o),
      tables,
      now: () => emu.clock.now().getTime(),
      today,
      givePet: (o, race, level) => givePetTo(o, race, level)
    });
    installAreaFuncs(world, {
      load: async (ctx) => await me(ctx),
      save: (o) => save(o),
      today,
      now: () => emu.clock.now().getTime(),
      get: (k) => emu.store.get(k),
      set: (k, v) => emu.store.set(k, v),
      pets: tables
    });
    world.xt("VipTowerExtension.84_1", async (ctx) => {
      const rec = await me(ctx);
      ctx.reply({ fl: rec.vipTower?.fl ?? 0, ps: rec.vipTower?.ps ?? false });
    });
    world.xt("VipTowerExtension.84_2", async (ctx) => {
      const rec = await me(ctx);
      const fl = Math.max(1, Math.min(3, Number(ctx.params.fl) | 0));
      const v = rec.vipTower ??= { fl: 0, ps: false };
      if (fl === v.fl + 1 && (v.fl === 0 || v.ps)) {
        v.fl = fl;
        v.ps = false;
        await save(rec);
      }
      ctx.reply({ res: 1, fl: v.fl });
    });
    world.xt("VipTowerExtension.84_3", async (ctx) => ctx.reply({ rm: "" }));
    world.xt("VipTowerExtension.84_4", async (ctx) => {
      const rec = await me(ctx);
      const fl = Number(ctx.params.fl) | 0;
      const v = rec.vipTower ??= { fl: 0, ps: false };
      if (fl === v.fl && !v.ps) {
        v.ps = true;
        await save(rec);
      }
      ctx.reply({ res: 1, fl: v.fl });
    });
    const hotSpring = (rec) => {
      const day = today();
      if (rec.hotSpring?.day !== day) rec.hotSpring = { day, used: 0, extra: 0, adds: 0, double: false };
      return rec.hotSpring;
    };
    const left = (h) => Math.max(0, HOT_SPRING_SECONDS + h.extra - h.used);
    world.xt("HotSpringExtension.100_10", async (ctx) => {
      const rec = await me(ctx);
      const h = hotSpring(rec);
      await save(rec);
      if (left(h) > 0) world.setUserVars(ctx.session, { hs: Math.min(5, Math.max(1, Number(ctx.params.id) | 0)) });
      ctx.reply({ res: left(h) > 0 ? 1 : 0, lt: left(h), db: h.double ? 1 : 0 });
    });
    world.xt("HotSpringExtension.100_5", async (ctx) => {
      const rec = await me(ctx);
      const h = hotSpring(rec);
      ctx.reply({ lt: left(h), db: h.double ? 1 : 0 });
    });
    world.xt("HotSpringExtension.100_12", async (ctx) => {
      const rec = await me(ctx);
      const h = hotSpring(rec);
      const sec = Math.max(0, Math.min(left(h), Number(ctx.params.sec) | 0));
      const cap = Math.floor(sec / 3) * HOT_SPRING_EXP * (h.double ? 2 : 1);
      const exp = Math.max(0, Math.min(cap, Number(ctx.params.exp) | 0));
      h.used += sec;
      if (exp > 0) (rec.robot ??= { name: "HELLO", exp: 0, follow: true, born: today() }).exp += exp;
      await save(rec);
      world.setUserVars(ctx.session, { hs: null });
      ctx.reply({ res: 1, exp, robotExp: rec.robot?.exp ?? 0, lt: left(h) });
    });
    world.xt("HotSpringExtension.100_20", async (ctx) => {
      const rec = await me(ctx);
      const h = hotSpring(rec);
      const id = Number(ctx.params.id) | 0;
      const reply = (res) => ctx.reply({ res, id, lt: left(h), db: h.double ? 1 : 0, xingbi: rec.xingbi ?? 0 });
      const price = id === 1 ? 2 : id === 2 ? 11 : 0;
      if (!price || id === 1 && h.adds >= 3 || id === 2 && h.double) return reply(-1);
      if ((rec.xingbi ?? 0) < price) return reply(-5);
      rec.xingbi = (rec.xingbi ?? 0) - price;
      if (id === 1) {
        h.adds += 1;
        h.extra += 300;
      } else h.double = true;
      await save(rec);
      ctx.reply({ xingbi: rec.xingbi }, "onXingBiUpdate");
      reply(1);
    });
    world.xt("RobotExtension.2-13", async (ctx) => {
      const rec = await me(ctx);
      const pi = Number(ctx.params.pi) | 0;
      const want = Math.max(0, Number(ctx.params.e) | 0);
      const pet = (rec.pets ?? []).find((p) => p.id === pi);
      const have = rec.robot?.exp ?? 0;
      if (!pet) return ctx.reply({ res: -1, pi, e: 0, exp: have }, "2-13");
      if (want <= 0 || want > have || !rec.robot) return ctx.reply({ res: -2, pi, e: 0, exp: have }, "2-13");
      const t = await tables();
      rec.robot.exp = have - want;
      const r = gainExp(t, pet, want);
      for (const [cmd, body] of r.msgs) ctx.reply(body, cmd);
      if (r.evolvedTo && rec.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
      await save(rec);
      ctx.reply({ res: 1, pi, e: want, exp: rec.robot.exp, lv: pet.level }, "2-13");
    });
    const TRAIN_LESSONS = { 1: [3600, 1500], 2: [4 * 3600, 5e3], 3: [8 * 3600, 9e3], 4: [12 * 3600, 12e3] };
    const training = (rec) => {
      const has = (pi) => (rec.storage ?? []).some((p) => p.id === pi) || (rec.pets ?? []).some((p) => p.id === pi);
      return rec.training = (rec.training ?? []).filter((t) => has(t.pi) && TRAIN_LESSONS[t.c]);
    };
    const trainView = (rec) => {
      const now = emu.clock.now().getTime();
      return training(rec).map((t) => ({ pi: t.pi, c: t.c, lt: Math.max(0, Math.ceil((t.since + TRAIN_LESSONS[t.c][0] * 1e3 - now) / 1e3)) }));
    };
    world.xt("RobotExtension.2-15", async (ctx) => {
      const rec = await me(ctx);
      const pi = Number(ctx.params.pi) | 0;
      const c = TRAIN_LESSONS[Number(ctx.params.c) | 0] ? Number(ctx.params.c) | 0 : 1;
      const list = training(rec);
      if (!(rec.storage ?? []).some((p) => p.id === pi) || list.some((t) => t.pi === pi)) return ctx.reply({ res: -1, pi, c }, "2-15");
      if (list.length >= 2) return ctx.reply({ res: -2, pi, c }, "2-15");
      list.push({ pi, c, since: emu.clock.now().getTime() });
      await save(rec);
      ctx.reply({ res: 1, pi, c }, "2-15");
    });
    world.xt("RobotExtension.2-14", async (ctx) => ctx.reply({ ps: trainView(await me(ctx)) }, "2-14"));
    world.xt("RobotExtension.2-16", async (ctx) => {
      const rec = await me(ctx);
      const pi = Number(ctx.params.pi) | 0;
      const at = training(rec).findIndex((t) => t.pi === pi);
      const pet = (rec.storage ?? []).find((p) => p.id === pi) ?? (rec.pets ?? []).find((p) => p.id === pi);
      if (at < 0 || !pet) {
        await save(rec);
        return ctx.reply({ res: -1, pi, exp: 0 }, "2-16");
      }
      const [t0] = rec.training.splice(at, 1);
      const [secs, full] = TRAIN_LESSONS[t0.c];
      const done = Math.min(1, (emu.clock.now().getTime() - t0.since) / (secs * 1e3));
      const exp = Math.floor(full * done);
      if (exp > 0) gainExp(await tables(), pet, exp);
      await save(rec);
      ctx.reply({ res: 1, pi, exp, lv: pet.level }, "2-16");
    });
    const HELLO_ENERGY_ITEM = 20;
    world.xt("RobotExtension.2-6", async (ctx) => {
      const rec = await me(ctx);
      ctx.reply({ i: Object.entries(rec.items?.["3"] ?? {}).filter(([, q]) => q > 0).map(([id, q]) => ({ ItemId: Number(id), Quantity: q })) });
    });
    world.xt("MaterialExtension.61_6", async (ctx) => {
      const rec = await me(ctx);
      const worn = rec.robot?.avatar ?? "";
      ctx.reply({ clothes: Object.entries(rec.items?.["7"] ?? {}).filter(([, q]) => q > 0).map(([id, q]) => ({ id: Number(id), qt: q, uq: id === worn ? 1 : 0 })) });
    });
    world.xt("RobotExtension.2-10", async (ctx) => {
      const rec = await me(ctx);
      const n = String(ctx.params.n ?? "").trim();
      if (!rec.robot || n.length < 1 || [...n].length > 14) return ctx.reply({ res: 0, n: rec.robot?.name ?? "" });
      rec.robot.name = n;
      await save(rec);
      ctx.reply({ res: 1, n });
    });
    world.xt("RobotExtension.2-5", async (ctx) => {
      const rec = await me(ctx);
      const ii = String(Number(ctx.params.ii) | 0);
      const r = rec.robot;
      const have = rec.items?.["3"]?.[ii] ?? 0;
      const view2 = (res, msg2) => ({ res, ii: Number(ii), e: r?.energy ?? 100, f: "", msg: msg2 });
      if (!r || have < 1) return ctx.reply(view2(0, "\u4F60\u6CA1\u6709\u8FD9\u4E2A\u9053\u5177\u54E6\u3002"));
      let msg = "";
      if (ii === "1") {
        if ((r.energy ?? 100) >= 100) return ctx.reply(view2(0, "HELLO\u73B0\u5728\u9971\u9971\u7684\uFF0C\u4E00\u70B9\u513F\u4E5F\u4E0D\u997F\u54E6\uFF01"));
        r.energy = Math.min(100, (r.energy ?? 100) + HELLO_ENERGY_ITEM);
        msg = "\u4E3B\u4EBA\u5BF9HELLO\u6700\u597D\u4E86\uFF0CHELLO\u6700\u559C\u6B22\u4E3B\u4EBA\u4E86\uFF01";
      } else if (ii === "7") {
        const area2 = rec.area ??= {};
        const hello = area2.hello ??= { sc: [], pt: [], woken: [] };
        const woken = hello.woken ??= [];
        if (woken.includes(4)) return ctx.reply(view2(0, "HELLO\u5DF2\u7ECF\u4F1A\u4E9A\u6BD4\u6280\u80FD\u66FF\u6362\u4E86\u3002"));
        woken.push(4);
        msg = "HELLO\u73B0\u5728\u62E5\u6709\u4E86\u4E9A\u6BD4\u6280\u80FD\u66FF\u6362\u4E86\u3002";
      } else return ctx.reply(view2(0, "HELLO\u5DF2\u7ECF\u62E5\u6709\u8FD9\u4E2A\u6280\u80FD\u4E86\u3002"));
      rec.items["3"][ii] = have - 1;
      if (rec.items["3"][ii] <= 0) delete rec.items["3"][ii];
      await save(rec);
      ctx.reply({ amount: `3_${ii}_0_-1` }, "onAmountUpdated");
      ctx.reply(view2(1, msg));
    });
    world.xt("RobotExtension.2-17", async (ctx) => {
      const rec = await me(ctx);
      const id = String(Number(ctx.params.clothId) | 0);
      if (!rec.robot || !rec.vip || !((rec.items?.["7"]?.[id] ?? 0) > 0)) return ctx.reply({ result: false, clothId: Number(id) });
      rec.robot.avatar = id;
      await save(rec);
      if (rec.robot.follow) world.setUserVars(ctx.session, { r: robotVar(rec.robot) });
      ctx.reply({ result: true, clothId: Number(id) });
    });
    world.xt("RobotExtension.2-18", async (ctx) => {
      const rec = await me(ctx);
      if (!rec.robot) return ctx.reply({ res: 0, e: 0, msg: "\u4F60\u8FD8\u6CA1\u6709HELLO\u54E6\uFF01" });
      if ((rec.robot.energy ?? 100) >= 100) return ctx.reply({ res: 0, e: 100, msg: "HELLO\u73B0\u5728\u9971\u9971\u7684\uFF0C\u4E00\u70B9\u513F\u4E5F\u4E0D\u997F\u54E6\uFF01" });
      rec.robot.energy = 100;
      await save(rec);
      ctx.reply({ res: 1, e: 100 });
    });
    installShoot(world, {
      me,
      save: (o) => save(o),
      cards: async () => (await table())["4"] ?? {}
    });
    if (opts.dev) {
      world.xt("PocketMonsterExtension.revival_give", async (ctx) => {
        const rec = await me(ctx);
        const mi = String(Number(ctx.params.mi));
        const qt = Math.max(1, Number(ctx.params.qt) || 1);
        const t = String(ctx.params.t === void 0 ? 2 : Number(ctx.params.t) | 0);
        const items = (rec.items ??= {})[t] ??= {};
        items[mi] = (items[mi] ?? 0) + qt;
        await save(rec);
        ctx.reply({ amount: `${t}_${mi}_0_${qt}` }, "onAmountUpdated");
      });
    }
    world.xt("SundriesExtension.70_8", () => {
    });
    world.xt("SundriesExtension.70_12", () => {
    });
    world.xt("SundriesExtension.70_7", () => {
    });
    world.xt("SundriesExtension.70_72", () => {
    });
    world.xt("SundriesExtension.70_67", () => {
    });
    world.xt("SurveyExtension.clientDebug", () => {
    });
    world.xt("SundriesExtension.70_5", (ctx) => ctx.reply({ rank: [] }));
    world.xt("SundriesExtension.70_6", async (ctx) => {
      const rec = await me(ctx);
      const race = String(Number(ctx.params.raceId) | 0);
      if (rec.dailyFights?.day !== today()) rec.dailyFights = { day: today(), n: {} };
      const count = (rec.dailyFights.n[race] ?? 0) + 1;
      rec.dailyFights.n[race] = count;
      await save(rec);
      ctx.reply({ count });
    });
    world.xt("SundriesExtension.70_14", (ctx) => ctx.reply({ showup: false }));
    world.xt("HolidayExtension.74_1", () => {
    });
    world.xt("UserGameExtension.89_2", () => {
    });
    world.xt("UserGameExtension.89_5", async (ctx) => {
      const rec = await me(ctx);
      const done = rec.gameLevels?.[String(ctx.params.name ?? "")] ?? 0;
      ctx.reply({ level: Math.min(2, done), name: String(ctx.params.name ?? "") }, "89_5");
    });
    world.xt("UserGameExtension.89_1", async (ctx) => {
      const rec = await me(ctx);
      const items = (rec.items ??= {})["2"] ??= {};
      const used = Math.min(items["343"] ?? 0, Math.max(0, Number(ctx.params.num) | 0));
      if (used > 0) {
        items["343"] -= used;
        if (items["343"] <= 0) delete items["343"];
        ctx.reply({ amount: `2_343_0_${-used}` }, "onAmountUpdated");
      }
      let lvl = used > 0 ? Number(ctx.params.lvl) | 0 : -1;
      const day = emu.clock.now().toISOString().slice(0, 10);
      if (lvl === 1) {
        if (rec.pinballTop === day) lvl = 2;
        else rec.pinballTop = day;
      }
      if (lvl < 0) {
        await save(rec);
        return ctx.reply({ gf: "" });
      }
      const pick = (a) => a[Math.floor(Math.random() * a.length)];
      const prize = lvl === 1 ? [pick([["5", 88, 1], ["2", 178, 1], ["2", 661, 1]])] : lvl === 2 ? [pick([["5", 13, 1], ["5", 37, 1], ["2", 120, 1], ["2", 61, 2]])] : lvl === 3 ? [pick([["2", 60, 2], ["2", 425, 2], ["2", 426, 2]])] : [["2", 30, 1]];
      for (const [t, id, n] of prize) {
        const owned = rec.items[t] ??= {};
        owned[id] = (owned[id] ?? 0) + n;
        ctx.reply({ amount: `${t}_${id}_0_${n}` }, "onAmountUpdated");
      }
      await save(rec);
      ctx.reply({ gf: prize.map(([t, id, n]) => `${t}:${id}:${n}`).join(";") });
    });
    world.xt("UserExtension.getLifeDay", async (ctx) => {
      const rec = await me(ctx);
      const made = rec?.createdAt ? new Date(rec.createdAt).getTime() : emu.clock.now().getTime();
      ctx.reply({ life: Math.max(1, Math.floor((emu.clock.now().getTime() - made) / 864e5) + 1) });
    });
    return world;
  }
  async function renameUser(emu, from, to, opts = {}) {
    return oneAtATime(emu, () => rename(emu, from, to, opts));
  }
  async function rename(emu, from, to, opts) {
    const a = from.trim(), b = to.trim();
    const bad = nameProblem(b);
    if (bad) return bad;
    if (a === b) return null;
    const rec = await userRecord(emu, a);
    if (!rec) return "\u6CA1\u6709\u8FD9\u4E2A\u5965\u62C9\u3002";
    if (opts.accounts?.required) {
      const wrong = await passProblem(emu, rec, opts.pass, opts.addr);
      if (wrong) return wrong;
    }
    if (await userRecord(emu, b)) return "\u8FD9\u4E2A\u540D\u5B57\u5DF2\u7ECF\u6709\u5965\u62C9\u7528\u4E86\uFF0C\u6362\u4E00\u4E2A\u5427\u3002";
    if (opts.end) {
      if (opts.end(a)) await new Promise((ok) => setTimeout(ok, IMPORT_SETTLE_MS));
    } else if (opts.online?.(a)) return "\u8BF7\u5148\u9000\u51FA\u6E38\u620F\uFF0C\u518D\u6539\u540D\u5B57\u3002";
    rec.name = b;
    await emu.store.set(userKey(b), rec);
    await emu.store.delete(userKey(a));
    await emu.store.set(`uid/${rec.id}`, b);
    return null;
  }
  async function exportSave(emu, name, opts) {
    return oneAtATime(emu, async () => {
      const rec = await userRecord(emu, name.trim());
      if (!rec) return { error: "\u6CA1\u6709\u8FD9\u4E2A\u5965\u62C9\u3002" };
      if (opts.accounts?.required) {
        const wrong = await passProblem(emu, rec, opts.pass, opts.addr);
        if (wrong) return { error: wrong };
      }
      return { save: playerFile(rec, userKey(rec.name), emu.clock.now().toISOString()) };
    });
  }
  async function importSave(emu, name, file, opts) {
    if (!opts.imports) return { error: "\u8FD9\u4E2A\u670D\u52A1\u5668\u6CA1\u6709\u6253\u5F00\u5BFC\u5165\u5B58\u6863\u3002" };
    const bad = fileProblem(file);
    if (bad) return { error: bad };
    const roles = rolesOf(file);
    if (!roles.size) return { error: "\u8FD9\u4E2A\u5B58\u6863\u91CC\u6CA1\u6709\u5965\u62C9\u3002" };
    const from = opts.from ? roles.get(opts.from) : roles.size === 1 ? [...roles.values()][0] : void 0;
    if (!from) return { error: opts.from ? `\u5B58\u6863\u91CC\u6CA1\u6709${opts.from}\u3002` : "\u5B58\u6863\u91CC\u6709\u597D\u51E0\u4E2A\u5965\u62C9\uFF0C\u8BF7\u9009\u4E00\u4E2A\u3002", names: [...roles.keys()] };
    if (jsonBytes(from) > SAVE_RECORD_MAX) return { error: "\u8FD9\u4E2A\u5B58\u6863\u592A\u5927\u4E86\u3002" };
    return oneAtATime(emu, async () => {
      const rec = await userRecord(emu, name.trim());
      if (!rec) return { error: "\u6CA1\u6709\u8FD9\u4E2A\u5965\u62C9\u3002" };
      if (opts.accounts?.required) {
        const wrong = await passProblem(emu, rec, opts.pass, opts.addr);
        if (wrong) return { error: wrong };
      }
      return replaceGame(emu, rec, from, opts.end);
    });
  }
  async function replaceGame(emu, rec, from, end) {
    const { id, name: as } = rec;
    const key = userKey(as);
    let next;
    try {
      next = normalise2(adoptRecord(from, rec));
      if (jsonBytes(next) > SAVE_RECORD_MAX) return { error: "\u8FD9\u4E2A\u5B58\u6863\u592A\u5927\u4E86\u3002" };
    } catch {
      return { error: "\u8FD9\u4E2A\u5B58\u6863\u8BFB\u4E0D\u4E86\u3002" };
    }
    if (end?.(as)) await new Promise((ok) => setTimeout(ok, IMPORT_SETTLE_MS));
    const live2 = rec;
    const before = structuredClone(live2);
    const fill = (o) => {
      for (const k of Object.keys(live2)) delete live2[k];
      Object.assign(live2, o);
    };
    fill(next);
    try {
      await emu.store.set(key, live2);
    } catch {
      fill(before);
      return { error: "\u5B58\u6863\u6CA1\u6709\u5B58\u597D\uFF0C\u8BF7\u518D\u8BD5\u4E00\u6B21\u3002" };
    }
    await emu.store.set(`uid/${id}`, as);
    return {};
  }
  async function changePassword(emu, name, pass, to, opts) {
    if (!opts.accounts?.required) return "\u5355\u673A\u6A21\u5F0F\u6CA1\u6709\u5BC6\u7801\u3002";
    const bad = passwordProblem(to);
    if (bad) return bad;
    return oneAtATime(emu, async () => {
      const rec = await userRecord(emu, name.trim());
      if (!rec) return "\u6CA1\u6709\u8FD9\u4E2A\u5965\u62C9\u3002";
      const wrong = await passProblem(emu, rec, pass, opts.addr);
      if (wrong) return wrong;
      rec.pass = await hashPass(to);
      await emu.store.set(userKey(rec.name), rec);
      return null;
    });
  }
  function passwordProblem(pass) {
    if (!pass) return "\u8BF7\u8F93\u5165\u65B0\u5BC6\u7801\u3002";
    if ([...pass].length > 32) return "\u5BC6\u7801\u6700\u591A32\u4E2A\u5B57\u3002";
    return null;
  }
  var LOCAL_ROLES_MAX = 3;
  async function listUsers(emu) {
    const out = [];
    for (const k of await emu.store.keys("user/")) {
      const rec = await emu.store.get(k);
      if (!rec || typeof rec !== "object" || !rec.name) continue;
      const first = rec.pets?.[0];
      out.push({
        name: rec.name,
        id: rec.id,
        score: rec.score ?? 0,
        pets: (rec.pets?.length ?? 0) + (rec.storage?.length ?? 0),
        race: first?.race ?? 0,
        level: first?.level ?? 0,
        createdAt: rec.createdAt
      });
    }
    return out.sort((a, b) => a.id - b.id);
  }
  async function createUser(emu, name, max = LOCAL_ROLES_MAX) {
    const n = name.trim();
    const bad = nameProblem(n);
    if (bad) return bad;
    return oneAtATime(emu, async () => {
      if (await userRecord(emu, n)) return `\u5DF2\u7ECF\u6709\u4E00\u4E2A\u53EB${n}\u7684\u5965\u62C9\u4E86\u3002`;
      if ((await emu.store.keys("user/")).length >= max) return `\u6700\u591A${max}\u4E2A\u5965\u62C9\uFF0C\u5148\u5220\u9664\u4E00\u4E2A\u5427\u3002`;
      const rec = await newUser(emu, n);
      await emu.store.set(userKey(n), rec);
      await emu.store.set(`uid/${rec.id}`, n);
      return null;
    });
  }
  async function deleteUser(emu, name, end) {
    return oneAtATime(emu, async () => {
      const rec = await userRecord(emu, name.trim());
      if (!rec) return "\u6CA1\u6709\u8FD9\u4E2A\u5965\u62C9\u3002";
      end?.(rec.name);
      await emu.store.delete(userKey(rec.name));
      await emu.store.delete(`uid/${rec.id}`);
      await emu.store.delete(`visits/${rec.id}`);
      return null;
    });
  }
  async function addUserFromFile(emu, file, opts = {}) {
    const bad = fileProblem(file);
    if (bad) return { error: bad };
    const roles = rolesOf(file);
    if (!roles.size) return { error: "\u8FD9\u4E2A\u5B58\u6863\u91CC\u6CA1\u6709\u5965\u62C9\u3002" };
    const fromName = opts.from ?? (roles.size === 1 ? [...roles.keys()][0] : void 0);
    const from = fromName === void 0 ? void 0 : roles.get(fromName);
    if (!from || fromName === void 0) return { error: opts.from ? `\u5B58\u6863\u91CC\u6CA1\u6709${opts.from}\u3002` : "\u5B58\u6863\u91CC\u6709\u597D\u51E0\u4E2A\u5965\u62C9\uFF0C\u8BF7\u9009\u4E00\u4E2A\u3002", names: [...roles.keys()] };
    if (jsonBytes(from) > SAVE_RECORD_MAX) return { error: "\u8FD9\u4E2A\u5B58\u6863\u592A\u5927\u4E86\u3002" };
    const as = (opts.as ?? fromName).trim();
    const badName = nameProblem(as);
    if (badName) return { error: badName, conflict: as };
    return oneAtATime(emu, async () => {
      const here = await userRecord(emu, as);
      if (here) {
        if (!opts.replace) return { conflict: as };
        const r = await replaceGame(emu, here, from, opts.end);
        return r.error ? r : { name: as };
      }
      const max = opts.max ?? LOCAL_ROLES_MAX;
      if ((await emu.store.keys("user/")).length >= max) return { error: `\u6700\u591A${max}\u4E2A\u5965\u62C9\uFF0C\u5148\u5220\u9664\u4E00\u4E2A\u5427\u3002` };
      const rec = await newUser(emu, as);
      let next;
      try {
        next = normalise2(adoptRecord(from, rec));
      } catch {
        return { error: "\u8FD9\u4E2A\u5B58\u6863\u8BFB\u4E0D\u4E86\u3002" };
      }
      await emu.store.set(userKey(as), next);
      await emu.store.set(`uid/${next.id}`, as);
      return { name: as };
    });
  }

  // server/src/game/sfs2013/host.ts
  function createGameHost(o) {
    let world;
    const emulator = new Emulator({
      framing: SFS2013_FRAMING,
      codec: sfs2013Codec,
      clock: new GameClock(o.date ?? "2012-08-15"),
      // The players' records live: one object a player, whoever's handler changes it (store.ts).
      store: new LiveRecordStore(o.store, ["user/"], 1e3, (key) => {
        try {
          return !!world?.online(decodeURIComponent(key.slice("user/".length)));
        } catch {
          return false;
        }
      }, SAVE_RECORD_MAX),
      recorder: o.recorder ?? new MemoryRecorder(),
      answerPolicy: o.answerPolicy ?? false
    });
    const w = installSfs2013(emulator, { loadJson: o.loadJson, dev: o.dev, accounts: o.accounts, toolbox: o.toolbox });
    world = w;
    const playing = (name) => [...emulator.sessions].some((s) => w.player(s)?.name === name);
    const imports = o.imports ?? o.toolbox ?? true;
    const end = (name) => {
      let was = false;
      for (const s of [...emulator.sessions]) {
        if (w.player(s)?.name !== name) continue;
        was = true;
        s.close();
      }
      return was;
    };
    return {
      emulator,
      world: w,
      attach: (link, port = 9339) => emulator.attach(link, port),
      detach: (s) => emulator.detach(s),
      rename: (from, to, pass, addr, now) => renameUser(emulator, from, to, { pass, addr, accounts: o.accounts, online: playing, end: now ? end : void 0 }),
      changePassword: (name, pass, to, addr) => changePassword(emulator, name, pass, to, { addr, accounts: o.accounts }),
      users: () => listUsers(emulator),
      createUser: (name) => createUser(emulator, name),
      deleteUser: (name) => deleteUser(emulator, name, end),
      addUser: (file, a = {}) => addUserFromFile(emulator, file, { ...a, end }),
      exportSave: (name, pass, addr) => exportSave(emulator, name, { pass, addr, accounts: o.accounts }),
      importSave: (name, pass, file, from, addr) => importSave(emulator, name, file, { pass, addr, from, accounts: o.accounts, imports, end }),
      imports,
      online: () => [...emulator.sessions].filter((s) => w.player(s)).length
    };
  }

  // server/src/browser/idbStore.ts
  var IdbStore = class {
    db;
    constructor(name = "aola-revival") {
      this.db = new Promise((resolve, reject) => {
        const req = indexedDB.open(name, 1);
        req.onupgradeneeded = () => req.result.createObjectStore("kv");
        req.onsuccess = () => resolve(req.result);
        req.onerror = () => reject(req.error);
      });
    }
    async tx(mode, fn) {
      const db = await this.db;
      return new Promise((resolve, reject) => {
        const t = db.transaction("kv", mode);
        const req = fn(t.objectStore("kv"));
        t.oncomplete = () => resolve(req.result);
        t.onabort = () => reject(t.error ?? req.error ?? new Error("IndexedDB transaction aborted"));
        t.onerror = () => reject(t.error ?? req.error);
      });
    }
    async get(key) {
      const v = await this.tx("readonly", (s) => s.get(key));
      return v === void 0 ? void 0 : JSON.parse(v);
    }
    async set(key, value) {
      await this.tx("readwrite", (s) => s.put(JSON.stringify(value), key));
    }
    async delete(key) {
      await this.tx("readwrite", (s) => s.delete(key));
    }
    async keys(prefix = "") {
      const all = await this.tx("readonly", (s) => s.getAllKeys());
      return all.map(String).filter((k) => k.startsWith(prefix)).sort();
    }
  };

  // server/src/browser/shim.ts
  function installInPageSockets(emu, opts) {
    const Real = globalThis.WebSocket;
    class InPageSocket extends EventTarget {
      static CONNECTING = 0;
      static OPEN = 1;
      static CLOSING = 2;
      static CLOSED = 3;
      CONNECTING = 0;
      OPEN = 1;
      CLOSING = 2;
      CLOSED = 3;
      url;
      protocol = "";
      extensions = "";
      readyState = 0;
      binaryType = "blob";
      bufferedAmount = 0;
      onopen = null;
      onmessage = null;
      onclose = null;
      onerror = null;
      session = null;
      constructor(url, _protocols) {
        super();
        this.url = String(url);
        const port = opts.match(this.url);
        queueMicrotask(() => {
          this.readyState = 1;
          this.session = emu.attach(
            {
              remote: `in-page ${this.url}`,
              send: (bytes2) => this.deliver(bytes2),
              close: () => this.finish(1e3, "server closed")
            },
            port
          );
          this.fire(new Event("open"), this.onopen);
        });
      }
      send(data) {
        if (this.readyState !== 1) throw new DOMException("socket is not open", "InvalidStateError");
        const s = this.session;
        if (typeof data === "string") s.receive(new TextEncoder().encode(data));
        else if (data instanceof Blob) void data.arrayBuffer().then((b) => s.receive(new Uint8Array(b)));
        else if (ArrayBuffer.isView(data)) s.receive(new Uint8Array(data.buffer, data.byteOffset, data.byteLength).slice());
        else s.receive(new Uint8Array(data).slice());
      }
      close(code = 1e3, reason = "") {
        if (this.readyState >= 2) return;
        this.readyState = 2;
        const s = this.session;
        queueMicrotask(() => {
          s?.close();
          this.finish(code, reason);
        });
      }
      deliver(bytes2) {
        if (this.readyState !== 1) return;
        const copy = bytes2.slice();
        const data = this.binaryType === "arraybuffer" ? copy.buffer : new Blob([copy]);
        setTimeout(() => this.fire(new MessageEvent("message", { data }), this.onmessage), 0);
      }
      finish(code, reason) {
        if (this.readyState === 3) return;
        this.readyState = 3;
        setTimeout(() => this.fire(new CloseEvent("close", { code, reason, wasClean: true }), this.onclose), 0);
      }
      fire(ev, handler) {
        handler?.call(this, ev);
        this.dispatchEvent(ev);
      }
    }
    const Patched = new Proxy(Real, {
      construct(target, args) {
        return opts.match(String(args[0])) !== void 0 ? new InPageSocket(args[0], args[1]) : Reflect.construct(target, args);
      }
    });
    globalThis.WebSocket = Patched;
    return Real;
  }

  // server/src/browser/entry.ts
  var FRAMES_KEPT = 5e3;
  function startInPage(cfg) {
    const memory = new MemoryRecorder(FRAMES_KEPT);
    const sfs = cfg.protocol === "sfs2013";
    if (sfs && !cfg.demo) {
      const host = createGameHost({
        store: new IdbStore(),
        // Game data next to the game files (the service worker serves www.9aola.com from the mirror roots).
        // Through the service worker; over https on an https page (mixed content is blocked).
        loadJson: (path) => fetch(`${location.protocol === "https:" ? "https" : "http"}://www.9aola.com/${path}`).then((r) => r.ok ? r.json() : void 0),
        date: cfg.date,
        dev: cfg.dev,
        recorder: cfg.verbose ? new TeeRecorder(memory, new ConsoleRecorder()) : memory
      });
      installInPageSockets(host.emulator, {
        match: (url) => url.startsWith(cfg.proxyPrefix) ? Number(url.slice(cfg.proxyPrefix.length)) || 0 : void 0
      });
      return {
        emulator: host.emulator,
        frames: memory.records,
        rename: (from, to, now = false) => host.rename(from, to, void 0, void 0, now),
        users: host.users,
        createUser: host.createUser,
        deleteUser: host.deleteUser,
        addUser: host.addUser,
        exportSave: (name) => host.exportSave(name),
        importSave: (name, file, from) => host.importSave(name, void 0, file, from)
      };
    }
    const emu = new Emulator({
      framing: sfs ? SFS2013_FRAMING : parseFraming(cfg.framing ?? "raw"),
      codec: sfs ? sfs2013Codec : void 0,
      clock: new GameClock(cfg.date ?? "2012-08-15"),
      store: new IdbStore(),
      recorder: cfg.verbose ? new TeeRecorder(memory, new ConsoleRecorder()) : memory,
      answerPolicy: false
    });
    if (cfg.demo) installHandshakeDemo(emu);
    else installAola2012(emu);
    installInPageSockets(emu, {
      match: (url) => url.startsWith(cfg.proxyPrefix) ? Number(url.slice(cfg.proxyPrefix.length)) || 0 : void 0
    });
    return { emulator: emu, frames: memory.records, rename: async () => "\u8FD9\u4E2A\u9875\u9762\u4E0D\u80FD\u6539\u540D\u5B57\u3002" };
  }
  globalThis.AolaEmulator = { startInPage };
})();
