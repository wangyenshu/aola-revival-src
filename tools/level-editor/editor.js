/*
 * 奥拉星 revival · 沙盒关卡编辑器 (docs/SANDBOX.md "The editor"): makes version-2 关卡 packs.
 * A plain script with no build step; the format's rules live in pack.js (window.AolaPack).
 *
 * The pack is held as AolaPack.normalize gives it and changed in place; each change goes
 * through change() (or capture()/commitFrom() around a drag), which keeps the undo history,
 * redraws and autosaves to localStorage.
 */
(() => {
  "use strict";
  const P = window.AolaPack;
  const L = P.LIMITS;
  const STORE_KEY = "aola-level-editor:pack";
  const PETS_URL = "../files/www.9aola.com/revival/pets.json";
  const FONT = '"Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "Noto Sans CJK TC", sans-serif';
  const HISTORY = 60;

  // ------------------------------------------------------------------ DOM helpers

  const $ = (s) => document.querySelector(s);
  /** An element: attributes (on* listeners, dataset, style object, value set after children), then children. */
  function h(tag, attrs, ...kids) {
    const el = document.createElement(tag);
    let value;
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v === undefined || v === null || v === false) continue;
      if (k === "class") el.className = v;
      else if (k === "dataset") Object.assign(el.dataset, v);
      else if (k === "style") Object.assign(el.style, v);
      else if (k.startsWith("on") && typeof v === "function") el.addEventListener(k.slice(2), v);
      else if (k === "value") value = v;
      else if (k === "checked" || k === "disabled" || k === "hidden" || k === "title" || k === "draggable") el[k] = v;
      else el.setAttribute(k, v === true ? "" : String(v));
    }
    for (const c of kids.flat(Infinity)) if (c !== null && c !== undefined && c !== false) el.append(c instanceof Node ? c : String(c));
    if (value !== undefined) el.value = value;
    return el;
  }
  const button = (label, onclick, attrs) => h("button", Object.assign({ type: "button", onclick }, attrs), label);
  const field = (label, control, hint) => h("div", { class: "field" }, h("span", null, label), control, hint ? h("small", null, hint) : null);
  function textIn(key, value, commit, attrs) {
    return h("input", Object.assign({ type: "text", value: value ?? "", dataset: { key }, onchange: (e) => commit(e.target.value, e.target) }, attrs));
  }
  function numIn(key, value, commit, attrs) {
    return h(
      "input",
      Object.assign(
        {
          type: "number",
          value: value ?? "",
          dataset: { key },
          onchange: (e) => {
            const t = e.target;
            const v = Number(t.value);
            if (t.value.trim() === "" || !Number.isFinite(v)) {
              t.value = value ?? "";
              return;
            }
            commit(v, t);
          },
        },
        attrs,
      ),
    );
  }
  /** A select; options [{value, label}] or [{group, options}]; a value not among them is shown as missing. */
  function selectIn(key, options, value, commit, attrs) {
    const s = h("select", Object.assign({ dataset: { key }, onchange: (e) => commit(e.target.value, e.target) }, attrs));
    const add = (parent, o) => parent.append(h("option", { value: o.value, disabled: o.disabled }, o.label));
    for (const o of options) {
      if (o.options) {
        if (!o.options.length) continue;
        const g = h("optgroup", { label: o.group });
        o.options.forEach((x) => add(g, x));
        s.append(g);
      } else add(s, o);
    }
    const v = value ?? "";
    s.value = v;
    if (s.value !== v) {
      s.append(h("option", { value: v }, `（找不到：${v}）`));
      s.value = v;
      s.classList.add("bad");
    }
    return s;
  }
  const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
  const isPt = (v) => Array.isArray(v) && v.length === 2 && v.every(Number.isFinite);
  const isRect = (v) => Array.isArray(v) && v.length === 4 && v.every(Number.isFinite);
  function fmtBytes(b) {
    if (b < 1000) return `${b} B`;
    if (b < 1e6) return `${(b / 1e3).toFixed(b < 1e4 ? 1 : 0)} KB`;
    return `${(b / 1e6).toFixed(2)} MB`;
  }
  function cnNum(n) {
    const d = "零一二三四五六七八九";
    if (n < 10) return d[n];
    if (n < 20) return "十" + (n % 10 ? d[n % 10] : "");
    if (n < 100) return d[Math.floor(n / 10)] + "十" + (n % 10 ? d[n % 10] : "");
    return String(n);
  }
  const timeNow = () => new Date().toTimeString().slice(0, 5);

  // ------------------------------------------------------------------ state

  let pack = null;
  /** The selected 关卡 and room (indexes), and the selected thing of the room: {kind: "spawn", id} | {kind: "door" | "enemy" | "prop", index}. */
  let sel = { level: 0, room: 0, obj: null };
  let tab = "levels";
  let tool = "select";
  const view = { mask: false, overlay: true, markers: true, zoom: "fit" };
  let brush = 32;
  let propImage = "";
  let names = null; // {race: name} once pets.json is read
  let pristine = true; // nothing changed since the pack was made or loaded
  let packBytes = 0;
  const sharedOk = new Set(); // shared masks the maker chose to paint for every room using them

  const curLevel = () => (pack.levels[sel.level] || null);
  const curRoom = () => {
    const l = curLevel();
    return (l && l.rooms[sel.room]) || null;
  };
  function fixSel() {
    sel.level = clamp(sel.level | 0, 0, Math.max(0, pack.levels.length - 1));
    const l = curLevel();
    sel.room = l ? clamp(sel.room | 0, 0, Math.max(0, l.rooms.length - 1)) : 0;
    const r = curRoom();
    const o = sel.obj;
    if (!o || !r) sel.obj = null;
    else if (o.kind === "spawn" ? !Object.prototype.hasOwnProperty.call(r.spawns, o.id) : !(o.index >= 0 && o.index < (r[o.kind === "door" ? "doors" : o.kind === "enemy" ? "enemies" : "props"] || []).length)) sel.obj = null;
  }
  const levelLabel = (l) => `${l.name || "（没有名字）"} (${l.id})`;
  const roomLabel = (r) => `${r.name || "（没有名字）"} (${r.id})`;

  // ------------------------------------------------------------------ history

  const undoStack = [];
  const redoStack = [];
  function capture() {
    const { images, ...rest } = pack;
    return { j: JSON.stringify(rest), images: Object.assign({}, images), sel: JSON.stringify(sel) };
  }
  function sameState(a, b) {
    if (a.j !== b.j) return false;
    const ka = Object.keys(a.images);
    const kb = Object.keys(b.images);
    if (ka.length !== kb.length) return false;
    for (let i = 0; i < ka.length; i++) if (ka[i] !== kb[i] || a.images[ka[i]] !== b.images[kb[i]]) return false;
    return true;
  }
  function restoreState(s) {
    pack = Object.assign(JSON.parse(s.j), { images: Object.assign({}, s.images) });
    sel = JSON.parse(s.sel);
    fixSel();
  }
  /** Runs fn (which changes the pack), then keeps the state before it for undo. */
  function change(fn) {
    const before = capture();
    try {
      fn();
    } finally {
      commitFrom(before);
    }
  }
  function commitFrom(before) {
    fixSel();
    if (!sameState(before, capture())) {
      undoStack.push(before);
      if (undoStack.length > HISTORY) undoStack.shift();
      redoStack.length = 0;
      pristine = false;
      changed();
    } else renderSoon();
  }
  function changed() {
    renderSoon();
    scheduleAutosave();
    scheduleSize();
  }
  function undo() {
    if (!undoStack.length) return;
    redoStack.push(capture());
    restoreState(undoStack.pop());
    changed();
  }
  function redo() {
    if (!redoStack.length) return;
    undoStack.push(capture());
    restoreState(redoStack.pop());
    changed();
  }

  // A change made on blur (an input's "change" while the mouse is pressed elsewhere) must not
  // rebuild the panels under the pointer before its click lands: rendering waits for pointerup.
  let pointerIsDown = false;
  let renderPending = false;
  document.addEventListener("pointerdown", () => (pointerIsDown = true), true);
  document.addEventListener(
    "pointerup",
    () => {
      pointerIsDown = false;
      if (renderPending) setTimeout(() => renderPending && renderAll(), 0);
    },
    true,
  );
  for (const ev of ["pointercancel", "blur"])
    (ev === "blur" ? window : document).addEventListener(ev, () => {
      pointerIsDown = false;
      if (renderPending) setTimeout(() => renderPending && renderAll(), 0);
    });
  function renderSoon() {
    if (pointerIsDown) renderPending = true;
    else renderAll();
  }

  // ------------------------------------------------------------------ pictures

  const infoCache = new Map(); // id -> {src, info}
  function infoOf(id, src) {
    const s = src === undefined ? pack.images[id] : src;
    const c = infoCache.get(id);
    if (c && c.src === s) return c.info;
    const info = P.imageInfo(s);
    infoCache.set(id, { src: s, info });
    return info;
  }
  const imgCache = new Map(); // id -> {src, el, w, h, ok, err}
  function imgOf(id) {
    if (!id || !pack.images[id]) return null;
    const src = pack.images[id];
    let c = imgCache.get(id);
    if (c && c.src === src) return c;
    c = { src, el: new Image(), w: 0, h: 0, ok: false, err: false };
    const inf = infoOf(id);
    if (!inf.error) {
      c.w = inf.width;
      c.h = inf.height;
    }
    c.el.onload = () => {
      c.ok = true;
      c.w = c.el.naturalWidth;
      c.h = c.el.naturalHeight;
      requestDraw();
    };
    c.el.onerror = () => {
      c.err = true;
      requestDraw();
    };
    c.el.src = src;
    imgCache.set(id, c);
    return c;
  }
  const thumbCache = new Map(); // id -> {src, el}
  function thumbOf(id) {
    const src = pack.images[id];
    let t = thumbCache.get(id);
    if (!t || t.src !== src) {
      const el = h("img", { alt: id, draggable: true });
      el.src = src;
      el.addEventListener("dragstart", (e) => {
        e.dataTransfer.setData("text/x-aola-image", t.id);
        e.dataTransfer.effectAllowed = "copy";
      });
      t = { src, el, id };
      thumbCache.set(id, t);
    }
    t.id = id;
    t.el.alt = id;
    t.el.title = `${id}：拖到画布上放成道具`;
    return t.el;
  }
  function roomSize(room) {
    const c = room && imgOf(room.background);
    return c && c.w > 0 && c.h > 0 ? { w: c.w, h: c.h } : { w: 960, h: 560 };
  }
  const imageOptions = () => Object.keys(pack.images).map((id) => {
    const inf = infoOf(id);
    return { value: id, label: inf.error ? `${id}（坏图）` : `${id}  ${inf.width}×${inf.height}` };
  });
  function looksLikeBackground(id) {
    const inf = infoOf(id);
    return !inf.error && inf.height === L.roomHeight && inf.width >= L.roomMinWidth && inf.width <= L.imageWidth;
  }

  // ------------------------------------------------------------------ walk masks

  const maskCache = new Map(); // image id -> {src, w, h, grid: Uint8Array (1 wall), tint, dirty}
  /** The mask image `id` read at the room's size (null until the picture is decoded). */
  function maskGrid(id, w, hgt) {
    const src = pack.images[id];
    if (!src) return null;
    let m = maskCache.get(id);
    if (m && m.src === src && m.w === w && m.h === hgt) return m;
    const c = imgOf(id);
    if (!c || !c.ok) return null;
    const cv = document.createElement("canvas");
    cv.width = w;
    cv.height = hgt;
    const g = cv.getContext("2d", { willReadFrequently: true });
    g.imageSmoothingEnabled = false;
    g.drawImage(c.el, 0, 0, w, hgt);
    const d = g.getImageData(0, 0, w, hgt).data;
    const grid = new Uint8Array(w * hgt);
    for (let i = 0, p = 0; i < grid.length; i++, p += 4) grid[i] = P.isWallPixel(d[p], d[p + 1], d[p + 2], d[p + 3]) ? 1 : 0;
    m = { src, w, h: hgt, grid, tint: null, dirty: [0, 0, w, hgt] };
    maskCache.set(id, m);
    return m;
  }
  function markDirty(m, x0, y0, x1, y1) {
    x0 = clamp(Math.floor(x0), 0, m.w);
    y0 = clamp(Math.floor(y0), 0, m.h);
    x1 = clamp(Math.ceil(x1), 0, m.w);
    y1 = clamp(Math.ceil(y1), 0, m.h);
    if (x1 <= x0 || y1 <= y0) return;
    m.dirty = m.dirty ? [Math.min(m.dirty[0], x0), Math.min(m.dirty[1], y0), Math.max(m.dirty[2], x1), Math.max(m.dirty[3], y1)] : [x0, y0, x1, y1];
  }
  /** The walls tinted red, at the room's size. */
  function tintOf(m) {
    if (!m.tint) {
      m.tint = document.createElement("canvas");
      m.tint.width = m.w;
      m.tint.height = m.h;
      m.dirty = [0, 0, m.w, m.h];
    }
    if (m.dirty) {
      const [x0, y0, x1, y1] = m.dirty;
      const W = x1 - x0;
      const H = y1 - y0;
      const g = m.tint.getContext("2d");
      const im = g.createImageData(W, H);
      const d = im.data;
      for (let y = 0; y < H; y++) {
        const row = (y0 + y) * m.w + x0;
        for (let x = 0; x < W; x++)
          if (m.grid[row + x]) {
            const p = (y * W + x) * 4;
            d[p] = 228;
            d[p + 1] = 38;
            d[p + 2] = 38;
            d[p + 3] = 120;
          }
      }
      g.putImageData(im, x0, y0);
      m.dirty = null;
    }
    return m.tint;
  }
  function stamp(m, cx, cy, r, v) {
    const x0 = Math.max(0, Math.floor(cx - r));
    const x1 = Math.min(m.w - 1, Math.ceil(cx + r));
    const y0 = Math.max(0, Math.floor(cy - r));
    const y1 = Math.min(m.h - 1, Math.ceil(cy + r));
    const rr = r * r;
    for (let y = y0; y <= y1; y++)
      for (let x = x0; x <= x1; x++) {
        const dx = x + 0.5 - cx;
        const dy = y + 0.5 - cy;
        if (dx * dx + dy * dy <= rr) m.grid[y * m.w + x] = v;
      }
    markDirty(m, x0, y0, x1 + 1, y1 + 1);
  }
  function strokeLine(m, a, b, r, v) {
    const dist = Math.hypot(b.x - a.x, b.y - a.y);
    const steps = Math.max(1, Math.ceil(dist / Math.max(1, r / 2)));
    for (let i = 1; i <= steps; i++) stamp(m, a.x + ((b.x - a.x) * i) / steps, a.y + ((b.y - a.y) * i) / steps, r, v);
  }
  /** Turns the connected area under (sx, sy) to the other kind: floor to wall, wall to floor. */
  function floodFill(m, sx, sy) {
    const { w, h: H, grid } = m;
    const x = Math.floor(sx);
    const y = Math.floor(sy);
    if (x < 0 || y < 0 || x >= w || y >= H) return false;
    const from = grid[y * w + x];
    const to = from ? 0 : 1;
    const stack = [x, y];
    while (stack.length) {
      const cy = stack.pop();
      const cx = stack.pop();
      if (grid[cy * w + cx] !== from) continue;
      let lx = cx;
      let rx = cx;
      while (lx > 0 && grid[cy * w + lx - 1] === from) lx--;
      while (rx < w - 1 && grid[cy * w + rx + 1] === from) rx++;
      for (let i = lx; i <= rx; i++) grid[cy * w + i] = to;
      for (const ny of [cy - 1, cy + 1]) {
        if (ny < 0 || ny >= H) continue;
        let run = false;
        for (let i = lx; i <= rx; i++) {
          const hit = grid[ny * w + i] === from;
          if (hit && !run) stack.push(i, ny);
          run = hit;
        }
      }
    }
    m.dirty = [0, 0, w, H];
    return true;
  }
  /** The mask as the format writes it: a PNG at the background's size, walls opaque black, floor transparent. */
  function encodeMask(grid, w, hgt) {
    const cv = document.createElement("canvas");
    cv.width = w;
    cv.height = hgt;
    const g = cv.getContext("2d");
    const im = g.createImageData(w, hgt);
    for (let i = 0; i < grid.length; i++) if (grid[i]) im.data[i * 4 + 3] = 255;
    g.putImageData(im, 0, 0);
    return cv.toDataURL("image/png");
  }
  function saveMask(id, m) {
    const url = encodeMask(m.grid, m.w, m.h);
    pack.images[id] = url;
    m.src = url;
  }
  /** A new all-floor mask for the room (an image entry of its own). */
  function createMask(room) {
    const { w, h: H } = roomSize(room);
    const id = P.uniqueId(room.id + "-mask", (s) => s in pack.images);
    const grid = new Uint8Array(w * H);
    const url = encodeMask(grid, w, H);
    pack.images[id] = url;
    maskCache.set(id, { src: url, w, h: H, grid, tint: null, dirty: [0, 0, w, H] });
    room.mask = id;
    return id;
  }
  function otherMaskUses(room) {
    return P.imageUses(pack, room.mask).filter((u) => !(u.level === sel.level && u.room === sel.room && u.field === "mask"));
  }
  /** Before painting a mask other rooms use too: copy it for this room, or paint them all. False when painting must wait. */
  function maskReady(room) {
    if (!room.mask) return true;
    if (!pack.images[room.mask]) {
      toast(`遮罩图片 ${room.mask} 不在包里：在左边重新选一张，或选“画一张新遮罩”`, "error");
      return false;
    }
    const others = otherMaskUses(room);
    if (!others.length || sharedOk.has(room.mask)) return true;
    const where = others.map((u) => {
      const l = pack.levels[u.level];
      const r = l.rooms[u.room];
      return `${l.id}/${r.id}（${{ background: "背景", mask: "遮罩", overlay: "前景", prop: "道具" }[u.field]}）`;
    });
    ask({
      title: "这张遮罩还用在别处",
      body: [h("p", null, `图片 ${room.mask} 还用在：${where.join("、")}。`), h("p", null, "改它会让那些地方一起变。要复制一份只给这个房间用吗？")],
      buttons: [
        { label: "复制一份给这个房间", value: "copy", kind: "primary" },
        { label: "一起改", value: "both" },
        { label: "取消", value: null },
      ],
    }).then((c) => {
      if (c === "copy") {
        change(() => {
          const id = P.uniqueId(room.id + "-mask", (s) => s in pack.images);
          pack.images[id] = pack.images[room.mask];
          room.mask = id;
        });
        toast("已复制一份遮罩，现在可以画了");
      } else if (c === "both") {
        sharedOk.add(room.mask);
        toast("好的，现在可以画了（会一起改）");
      }
    });
    return false;
  }
  /** The mask grid to paint on, made when the room has none; null while the picture is still being read. */
  function paintGrid(room) {
    if (!room.mask) createMask(room);
    const { w, h: H } = roomSize(room);
    const m = maskGrid(room.mask, w, H);
    if (!m) toast("遮罩图片还在读取，请稍等一下再画", "warn");
    return m;
  }
  function wallAt(room, x, y, W, H) {
    if (!room.mask) return false;
    const m = maskGrid(room.mask, W || roomSize(room).w, H || roomSize(room).h);
    if (!m) return undefined;
    const xi = clamp(Math.floor(x), 0, m.w - 1);
    const yi = clamp(Math.floor(y), 0, m.h - 1);
    return m.grid[yi * m.w + xi] === 1;
  }

  // ------------------------------------------------------------------ packs

  function starterPack() {
    return P.normalize({
      format: P.FORMAT,
      version: 2,
      name: "我的关卡包",
      author: "",
      images: { bg1: P.placeholderBackground(960, 560) },
      levels: [{ id: "l1", name: "第一关", heal: true, start: "r1", rooms: [newRoomObj("r1", "入口", "bg1")] }],
    });
  }
  function newRoomObj(id, name, background, startX) {
    return { id, name, background, mask: "", overlay: "", music: "", props: [], spawns: { start: [startX || 160, 440] }, doors: [], enemies: [] };
  }
  /** The middle of a room with background `bg` (where a new room's start point goes, away from doors at its edges). */
  const middleOf = (bg) => {
    const inf = infoOf(bg);
    return Math.round((inf.error ? 960 : inf.width) / 2);
  };
  /** A background for a new room: the current room's, a picture of room size, or a plain one made here. */
  function defaultBackground() {
    const r = curRoom();
    if (r && r.background && pack.images[r.background]) return r.background;
    const id = Object.keys(pack.images).find(looksLikeBackground);
    if (id) return id;
    const nid = P.uniqueId("bg1", (s) => s in pack.images);
    pack.images[nid] = P.placeholderBackground(960, 560);
    return nid;
  }

  // ------------------------------------------------------------------ 关卡 and rooms

  function selectLevel(i) {
    sel = { level: i, room: 0, obj: null };
    renderAll();
  }
  function selectRoom(j) {
    sel.room = j;
    sel.obj = null;
    renderAll();
  }
  function addLevel() {
    if (pack.levels.length >= L.levels) return toast(`一个包最多 ${L.levels} 个关卡`, "error");
    change(() => {
      const n = pack.levels.length + 1;
      const id = P.uniqueId("l" + n, pack.levels.map((l) => l.id));
      const bg = defaultBackground();
      pack.levels.push({ id, name: `第${cnNum(n)}关`, heal: true, start: "r1", next: "", rooms: [newRoomObj("r1", "入口", bg, middleOf(bg))] });
      sel = { level: pack.levels.length - 1, room: 0, obj: null };
    });
  }
  function moveLevel(d) {
    const i = sel.level;
    const j = i + d;
    if (j < 0 || j >= pack.levels.length) return;
    change(() => {
      const a = pack.levels;
      [a[i], a[j]] = [a[j], a[i]];
      sel.level = j;
    });
  }
  async function deleteLevel() {
    const lv = curLevel();
    if (!lv) return;
    let doors = 0;
    pack.levels.forEach((l) => {
      if (l === lv) return;
      for (const r of l.rooms)
        for (const d of r.doors) {
          const t = P.parseTarget(d.to);
          if (t && t.kind === "room" && t.level === lv.id) doors++;
        }
    });
    const nexts = pack.levels.filter((l) => l !== lv && l.next === lv.id);
    const ok = await ask({
      title: "删除关卡",
      body: [
        h("p", null, `删除关卡「${lv.name || lv.id}」(${lv.id}) 和它的 ${lv.rooms.length} 个房间？`),
        doors ? h("p", { class: "note warn" }, `别的关卡有 ${doors} 扇门通向它，删除后这些门会失效（“检查”会列出来）。`) : null,
        nexts.length ? h("p", { class: "note" }, `${nexts.map((l) => l.id).join("、")} 的“下一关”会改成没有。`) : null,
        h("p", { class: "note" }, "删错了可以撤销。"),
      ],
      buttons: [
        { label: "删除", value: "go", kind: "danger" },
        { label: "取消", value: null },
      ],
    });
    if (ok !== "go") return;
    change(() => {
      for (const l of nexts) l.next = "";
      pack.levels.splice(pack.levels.indexOf(lv), 1);
      sel = { level: Math.max(0, sel.level - 1), room: 0, obj: null };
    });
  }
  function renameLevelId(lv, v, el) {
    const err = P.idProblem(v, pack.levels.map((l) => l.id), lv.id);
    if (err) {
      el.value = lv.id;
      return toast(err, "error");
    }
    change(() => P.renameLevel(pack, lv, v));
  }
  function addRoom() {
    const lv = curLevel();
    if (!lv) return;
    if (lv.rooms.length >= L.rooms) return toast(`一个关卡最多 ${L.rooms} 个房间`, "error");
    change(() => {
      const n = lv.rooms.length + 1;
      const id = P.uniqueId("r" + n, lv.rooms.map((r) => r.id));
      const bg = defaultBackground();
      lv.rooms.push(newRoomObj(id, `房间${n}`, bg, middleOf(bg)));
      sel.room = lv.rooms.length - 1;
      sel.obj = null;
    });
  }
  function moveRoom(d) {
    const lv = curLevel();
    const i = sel.room;
    const j = i + d;
    if (!lv || j < 0 || j >= lv.rooms.length) return;
    change(() => {
      [lv.rooms[i], lv.rooms[j]] = [lv.rooms[j], lv.rooms[i]];
      sel.room = j;
    });
  }
  async function deleteRoom() {
    const lv = curLevel();
    const room = curRoom();
    if (!room) return;
    if (lv.rooms.length <= 1) return toast("一个关卡至少要有一个房间（可以删除整个关卡）", "warn");
    const refs = P.doorsTo(pack, lv, room.id).filter((d) => !(d.level === sel.level && d.room === sel.room));
    const ok = await ask({
      title: "删除房间",
      body: [
        h("p", null, `删除房间「${room.name || room.id}」(${room.id})？它的入口点、门、对手和道具会一起删掉；图片留在包里。`),
        refs.length ? h("p", { class: "note warn" }, `有 ${refs.length} 扇门通向这个房间，删除后这些门会失效（“检查”会列出来）。`) : null,
        h("p", { class: "note" }, "删错了可以撤销。"),
      ],
      buttons: [
        { label: "删除", value: "go", kind: "danger" },
        { label: "取消", value: null },
      ],
    });
    if (ok !== "go") return;
    change(() => {
      lv.rooms.splice(lv.rooms.indexOf(room), 1);
      if (lv.start === room.id) lv.start = lv.rooms[0].id;
      sel.room = Math.max(0, sel.room - 1);
      sel.obj = null;
    });
  }
  function renameRoomId(lv, room, v, el) {
    const err = P.idProblem(v, lv.rooms.map((r) => r.id), room.id);
    if (err) {
      el.value = room.id;
      return toast(err, "error");
    }
    change(() => P.renameRoom(pack, lv, room, v));
  }
  function newMaskForRoom() {
    const room = curRoom();
    if (!room) return;
    change(() => createMask(room));
    view.mask = true;
    setTool("wall");
    toast("新遮罩已经建好（全是地面）：用“画墙”把不能走的地方涂黑");
  }

  // ------------------------------------------------------------------ things in a room

  const LIST = { door: "doors", enemy: "enemies", prop: "props" };
  function selectObj(o) {
    sel.obj = o;
    renderInspector();
    requestDraw();
  }
  function roomCenter(room) {
    const { w, h: H } = roomSize(room);
    return { x: Math.round(w / 2), y: Math.round(H * 0.75) };
  }
  function spawnName(room) {
    if (!("start" in room.spawns)) return "start";
    return P.uniqueId("spawn2", Object.keys(room.spawns));
  }
  function addSpawn(room, pt) {
    if (Object.keys(room.spawns).length >= L.spawns) {
      toast(`一个房间最多 ${L.spawns} 个入口点`, "error");
      return null;
    }
    const id = spawnName(room);
    room.spawns[id] = [Math.round(pt.x), Math.round(pt.y)];
    sel.obj = { kind: "spawn", id };
    return id;
  }
  function addDoor(room, rect) {
    if (room.doors.length >= L.doors) {
      toast(`一个房间最多 ${L.doors} 扇门`, "error");
      return -1;
    }
    room.doors.push({ rect, to: "", spawn: "", open: "always", label: "" });
    sel.obj = { kind: "door", index: room.doors.length - 1 };
    return room.doors.length - 1;
  }
  function addEnemy(room, pt) {
    if (room.enemies.length >= L.enemies) {
      toast(`一个房间最多 ${L.enemies} 个对手`, "error");
      return -1;
    }
    const lv = curLevel();
    const ids = lv.rooms.flatMap((r) => r.enemies.map((e) => e.id));
    const id = P.uniqueId("e1", ids);
    room.enemies.push({ id, at: [Math.round(pt.x), Math.round(pt.y)], name: `对手${room.enemies.length + 1}`, boss: false, team: [P.newOpponent(1, 10)] });
    sel.obj = { kind: "enemy", index: room.enemies.length - 1 };
    return room.enemies.length - 1;
  }
  function addProp(room, image, pt) {
    if (room.props.length >= L.props) {
      toast(`一个房间最多 ${L.props} 个道具`, "error");
      return -1;
    }
    const c = imgOf(image);
    const w = c ? c.w : 0;
    const H = c ? c.h : 0;
    room.props.push({ image, at: [Math.round(pt.x - w / 2), Math.round(pt.y - H / 2)], front: false });
    sel.obj = { kind: "prop", index: room.props.length - 1 };
    return room.props.length - 1;
  }
  function deleteSelected() {
    const room = curRoom();
    const o = sel.obj;
    if (!room || !o) return;
    change(() => {
      if (o.kind === "spawn") delete room.spawns[o.id];
      else room[LIST[o.kind]].splice(o.index, 1);
      sel.obj = null;
    });
  }
  function duplicateSelected() {
    const room = curRoom();
    const o = sel.obj;
    if (!room || !o || o.kind === "spawn") return;
    const src = room[LIST[o.kind]][o.index];
    const max = { door: L.doors, enemy: L.enemies, prop: L.props }[o.kind];
    if (room[LIST[o.kind]].length >= max) return toast(`这个房间的${{ door: "门", enemy: "对手", prop: "道具" }[o.kind]}已经满了（最多 ${max}）`, "error");
    change(() => {
      const c = JSON.parse(JSON.stringify(src));
      if (o.kind === "door") c.rect = [c.rect[0] + 20, c.rect[1] + 20, c.rect[2], c.rect[3]];
      else c.at = [c.at[0] + 20, c.at[1] + 20];
      if (o.kind === "enemy") c.id = P.uniqueId(c.id, curLevel().rooms.flatMap((r) => r.enemies.map((e) => e.id)));
      room[LIST[o.kind]].push(c);
      sel.obj = { kind: o.kind, index: room[LIST[o.kind]].length - 1 };
    });
  }
  function nudge(dx, dy) {
    const room = curRoom();
    const o = sel.obj;
    if (!room || !o) return;
    change(() => {
      if (o.kind === "spawn") {
        const p = room.spawns[o.id];
        room.spawns[o.id] = [p[0] + dx, p[1] + dy];
      } else if (o.kind === "door") {
        const r = room.doors[o.index].rect;
        room.doors[o.index].rect = [r[0] + dx, r[1] + dy, r[2], r[3]];
      } else {
        const t = room[LIST[o.kind]][o.index];
        t.at = [t.at[0] + dx, t.at[1] + dy];
      }
    });
  }
  /** A door back from the door's target room, and an entry point just inside each of the two doors. */
  function linkBack(door) {
    const lv = curLevel();
    const room = curRoom();
    const t = P.resolveTarget(pack, lv, door.to);
    if (!t || !isRect(door.rect)) return;
    if (t.room === room) return toast("这扇门通向它自己的房间", "warn");
    if (t.room.doors.length >= L.doors) return toast(`房间 ${t.room.id} 的门已经满了（最多 ${L.doors}）`, "error");
    change(() => {
      const { w: W, h: H } = roomSize(room);
      const { w: TW, h: TH } = roomSize(t.room);
      const [x, y, w, dh] = door.rect;
      // Mirrored, each room by its own width: a door at the right edge comes back at the left edge.
      const bx = clamp(Math.round(x + w / 2 > W / 2 ? W - x - w : TW - x - w), 0, Math.max(0, TW - w));
      const by = clamp(Math.round(y), 0, Math.max(0, TH - dh));
      const back = { rect: [bx, by, w, dh], to: t.level === lv ? room.id : `${lv.id}/${room.id}`, spawn: "", open: "always", label: "" };
      const inside = (rx, rw, RW) => (rx + rw / 2 < RW / 2 ? rx + rw + 60 : rx - 60);
      if (Object.keys(room.spawns).length < L.spawns) {
        const name = P.uniqueId("from" + t.room.id, Object.keys(room.spawns));
        room.spawns[name] = [clamp(Math.round(inside(x, w, W)), 0, W), clamp(Math.round(y + dh * 0.75), 0, H)];
        back.spawn = name;
      }
      if (!door.spawn && Object.keys(t.room.spawns).length < L.spawns) {
        const name = P.uniqueId("from" + room.id, Object.keys(t.room.spawns));
        t.room.spawns[name] = [clamp(Math.round(inside(bx, w, TW)), 0, TW), clamp(Math.round(by + dh * 0.75), 0, TH)];
        door.spawn = name;
      }
      t.room.doors.push(back);
    });
    toast(`已在房间 ${t.room.id} 加了一扇通回 ${room.id} 的门`, "ok");
  }

  // ------------------------------------------------------------------ the room canvas

  const stage = $("#stage");
  const wrap = $("#stageWrap");
  const geo = { s: 1, w: 960, h: 560 };
  let hover = null;
  let drag = null;
  let drawQueued = false;
  function requestDraw() {
    if (drawQueued) return;
    drawQueued = true;
    requestAnimationFrame(() => {
      drawQueued = false;
      draw();
    });
  }
  function scaleFor(w, H) {
    if (view.zoom !== "fit") return Number(view.zoom);
    const aw = wrap.clientWidth - 24;
    const ah = wrap.clientHeight - 24;
    return clamp(Math.min(aw / w, ah / H), 0.1, 2);
  }
  const toRoom = (e) => {
    const r = stage.getBoundingClientRect();
    return { x: (e.clientX - r.left) / geo.s, y: (e.clientY - r.top) / geo.s };
  };
  function enemyGeom(e) {
    const R = e.boss ? 36 : 24;
    return { cx: e.at[0], cy: e.at[1] - R, R };
  }
  function doorHandles(r) {
    const [x, y, w, H] = r;
    return { nw: [x, y], n: [x + w / 2, y], ne: [x + w, y], e: [x + w, y + H / 2], se: [x + w, y + H], s: [x + w / 2, y + H], sw: [x, y + H], w: [x, y + H / 2] };
  }
  const CURSORS = { nw: "nwse-resize", se: "nwse-resize", ne: "nesw-resize", sw: "nesw-resize", n: "ns-resize", s: "ns-resize", e: "ew-resize", w: "ew-resize" };

  function pill(g, text, x, y, px, fg, bg, align) {
    g.font = `${12 * px}px ${FONT}`;
    const tw = g.measureText(text).width;
    const pw = tw + 10 * px;
    const ph = 17 * px;
    // Kept inside the room so labels at its edges stay readable.
    const left = clamp(align === "center" ? x - pw / 2 : x, 2 * px, Math.max(2 * px, geo.w - pw - 2 * px));
    g.fillStyle = bg;
    g.beginPath();
    if (g.roundRect) g.roundRect(left, y - ph / 2, pw, ph, 8 * px);
    else g.rect(left, y - ph / 2, pw, ph);
    g.fill();
    g.fillStyle = fg;
    g.textBaseline = "middle";
    g.textAlign = "left";
    g.fillText(text, left + 5 * px, y + 0.5 * px);
  }
  function doorTargetText(d) {
    const t = P.parseTarget(d.to);
    if (!d.to) return "（还没选通向哪里）";
    if (!t) return "（不对：" + d.to + "）";
    if (t.kind === "finish") return "通关";
    if (t.kind === "exit") return "离开";
    const r = P.resolveTarget(pack, curLevel(), d.to);
    return "→ " + (r ? (t.level !== null ? r.level.id + "/" : "") + (r.room.name || r.room.id) : d.to + "（找不到）");
  }

  function draw() {
    const room = curRoom();
    const empty = $("#stageEmpty");
    if (!room) {
      stage.hidden = true;
      empty.hidden = false;
      empty.textContent = pack.levels.length ? "这个关卡还没有房间。" : "还没有关卡：点左边的“＋ 关卡”开始。";
      $("#roomInfo").textContent = "";
      return;
    }
    stage.hidden = false;
    empty.hidden = true;
    const { w, h: H } = roomSize(room);
    const s = scaleFor(w, H);
    geo.s = s;
    geo.w = w;
    geo.h = H;
    const dpr = window.devicePixelRatio || 1;
    const cw = Math.max(1, Math.round(w * s));
    const ch = Math.max(1, Math.round(H * s));
    if (stage.width !== Math.round(cw * dpr) || stage.height !== Math.round(ch * dpr)) {
      stage.width = Math.round(cw * dpr);
      stage.height = Math.round(ch * dpr);
    }
    stage.style.width = cw + "px";
    stage.style.height = ch + "px";
    $("#roomInfo").textContent = `房间 ${w}×${H} · 缩放 ${Math.round(s * 100)}%`;
    const g = stage.getContext("2d");
    g.setTransform(1, 0, 0, 1, 0, 0);
    g.clearRect(0, 0, stage.width, stage.height);
    g.setTransform(s * dpr, 0, 0, s * dpr, 0, 0);
    const px = 1 / s;

    // Background.
    const bg = imgOf(room.background);
    if (bg && bg.ok) g.drawImage(bg.el, 0, 0, w, H);
    else {
      for (let y = 0; y < H; y += 40) for (let x = 0; x < w; x += 40) {
        g.fillStyle = (x / 40 + y / 40) % 2 ? "#e9f1f8" : "#f6fafd";
        g.fillRect(x, y, 40, 40);
      }
      g.fillStyle = "#7a93ad";
      g.font = `${16 * px}px ${FONT}`;
      g.textAlign = "center";
      g.textBaseline = "middle";
      g.fillText(room.background ? (bg && !bg.err ? "背景读取中…" : `背景图片 ${room.background} 打不开`) : "还没有背景图片：在左边“房间设置”里选一张", w / 2, H / 2);
    }
    // Props behind the players, then in front of them, then the overlay.
    const order = room.props.map((p, k) => k).filter((k) => !room.props[k].front).concat(room.props.map((p, k) => k).filter((k) => room.props[k].front));
    for (const k of order) {
      const p = room.props[k];
      if (!isPt(p.at)) continue;
      const c = imgOf(p.image);
      if (c && c.ok) g.drawImage(c.el, p.at[0], p.at[1]);
      else {
        g.fillStyle = "rgba(122,147,173,.35)";
        g.fillRect(p.at[0], p.at[1], 60, 60);
        g.fillStyle = "#2c3e57";
        g.font = `${11 * px}px ${FONT}`;
        g.textAlign = "left";
        g.textBaseline = "top";
        g.fillText(p.image || "？", p.at[0] + 3 * px, p.at[1] + 3 * px);
      }
    }
    if (view.overlay && room.overlay) {
      const ov = imgOf(room.overlay);
      if (ov && ov.ok) g.drawImage(ov.el, 0, 0);
    }
    if (view.mask && room.mask) {
      const m = maskGrid(room.mask, w, H);
      if (m) {
        g.imageSmoothingEnabled = false;
        g.drawImage(tintOf(m), 0, 0, w, H);
        g.imageSmoothingEnabled = true;
      }
    }

    // Markers.
    const isSel = (kind, key) => sel.obj && sel.obj.kind === kind && (kind === "spawn" ? sel.obj.id === key : sel.obj.index === key);
    if (view.markers) {
      room.doors.forEach((d, k) => {
        if (!isRect(d.rect)) return;
        const [x, y, dw, dh] = d.rect;
        const t = P.parseTarget(d.to);
        const ok = t && (t.kind !== "room" || P.resolveTarget(pack, curLevel(), d.to));
        const color = !ok ? "#d9443a" : t.kind === "finish" ? "#2e9d5b" : t.kind === "exit" ? "#6b7f95" : "#2b8fe0";
        g.globalAlpha = 0.28;
        g.fillStyle = color;
        g.fillRect(x, y, dw, dh);
        g.globalAlpha = 1;
        g.lineWidth = (isSel("door", k) ? 3 : 2) * px;
        g.strokeStyle = isSel("door", k) ? "#e8641b" : color;
        g.setLineDash(d.open === "cleared" ? [7 * px, 4 * px] : []);
        g.strokeRect(x, y, dw, dh);
        g.setLineDash([]);
        const parts = [d.label, doorTargetText(d)];
        const text = parts.filter((x, i) => x && parts.indexOf(x) === i).join(" ") + (d.open === "cleared" ? "（打完开）" : "");
        g.save();
        g.beginPath();
        g.rect(x - 200 * px, y - 30 * px, dw + 400 * px, dh + 60 * px);
        g.clip();
        pill(g, `门${k + 1} ${text}`, x + dw / 2, y + 12 * px, px, "#fff", color, "center");
        g.restore();
      });
      for (const [id, pt] of Object.entries(room.spawns)) {
        if (!isPt(pt)) continue;
        if (isSel("spawn", id)) {
          g.beginPath();
          g.arc(pt[0], pt[1], 12 * px, 0, Math.PI * 2);
          g.strokeStyle = "#e8641b";
          g.lineWidth = 3 * px;
          g.stroke();
        }
        g.beginPath();
        g.arc(pt[0], pt[1], 7 * px, 0, Math.PI * 2);
        g.fillStyle = id === "start" ? "#2e9d5b" : "#3cb371";
        g.fill();
        g.lineWidth = 2 * px;
        g.strokeStyle = "#fff";
        g.stroke();
        pill(g, id, pt[0] + 11 * px, pt[1], px, "#fff", "rgba(46,157,91,.92)");
      }
      room.enemies.forEach((e, k) => {
        if (!isPt(e.at)) return;
        const { cx, cy, R } = enemyGeom(e);
        g.fillStyle = "rgba(0,0,0,.22)";
        g.beginPath();
        g.ellipse(e.at[0], e.at[1], R * 0.95, R * 0.32, 0, 0, Math.PI * 2);
        g.fill();
        g.beginPath();
        g.arc(cx, cy, R, 0, Math.PI * 2);
        g.fillStyle = e.boss ? "#d9443a" : "#f39a2b";
        g.fill();
        g.lineWidth = (isSel("enemy", k) ? 4 : 2) * px;
        g.strokeStyle = isSel("enemy", k) ? "#1a5fa8" : "#fff";
        g.stroke();
        if (e.boss) {
          g.fillStyle = "#ffd34d";
          g.beginPath();
          const top = cy - R - 2;
          g.moveTo(cx - 16, top);
          g.lineTo(cx - 20, top - 16);
          g.lineTo(cx - 8, top - 7);
          g.lineTo(cx, top - 20);
          g.lineTo(cx + 8, top - 7);
          g.lineTo(cx + 20, top - 16);
          g.lineTo(cx + 16, top);
          g.closePath();
          g.fill();
          g.lineWidth = 1.5 * px;
          g.strokeStyle = "#b77900";
          g.stroke();
        }
        const first = e.team[0];
        g.fillStyle = "#fff";
        g.font = `bold ${Math.round(R * 0.62)}px ${FONT}`;
        g.textAlign = "center";
        g.textBaseline = "middle";
        g.fillText(first && first.race !== undefined ? String(first.race) : "?", cx, cy + 1);
        const pet = first && names ? names[first.race] : "";
        const text = (e.name || e.id) + (pet ? " · " + pet : "") + (e.team.length > 1 ? ` ×${e.team.length}` : "");
        pill(g, text, e.at[0], e.at[1] + 14 * px, px, "#fff", e.boss ? "rgba(217,68,58,.92)" : "rgba(232,100,27,.9)", "center");
      });
    }
    // The selection.
    const o = sel.obj;
    if (o && o.kind === "prop" && room.props[o.index] && isPt(room.props[o.index].at)) {
      const p = room.props[o.index];
      const c = imgOf(p.image);
      const pw = c && c.w ? c.w : 60;
      const ph = c && c.h ? c.h : 60;
      g.setLineDash([6 * px, 4 * px]);
      g.lineWidth = 2 * px;
      g.strokeStyle = "#e8641b";
      g.strokeRect(p.at[0], p.at[1], pw, ph);
      g.setLineDash([]);
      pill(g, p.front ? "道具（前）" : "道具（后）", p.at[0], p.at[1] - 11 * px, px, "#fff", "rgba(232,100,27,.92)");
    }
    if (o && o.kind === "door" && room.doors[o.index] && isRect(room.doors[o.index].rect)) {
      for (const [hx, hy] of Object.values(doorHandles(room.doors[o.index].rect))) {
        g.fillStyle = "#fff";
        g.strokeStyle = "#e8641b";
        g.lineWidth = 2 * px;
        g.fillRect(hx - 4 * px, hy - 4 * px, 8 * px, 8 * px);
        g.strokeRect(hx - 4 * px, hy - 4 * px, 8 * px, 8 * px);
      }
    }
    if (drag && drag.kind === "newdoor" && drag.rect) {
      g.setLineDash([5 * px, 4 * px]);
      g.strokeStyle = "#e8641b";
      g.lineWidth = 2 * px;
      g.strokeRect(...drag.rect);
      g.setLineDash([]);
    }
    // The brush.
    if (hover && (tool === "wall" || tool === "floor")) {
      g.beginPath();
      g.arc(hover.x, hover.y, brush / 2, 0, Math.PI * 2);
      g.lineWidth = 3 * px;
      g.strokeStyle = "rgba(255,255,255,.9)";
      g.stroke();
      g.lineWidth = 1.5 * px;
      g.strokeStyle = tool === "wall" ? "#c62828" : "#1a5fa8";
      g.stroke();
    }
  }

  function hitTest(pt) {
    const room = curRoom();
    if (!room) return null;
    const tol = 9 / geo.s;
    const o = sel.obj;
    if (o && o.kind === "door" && room.doors[o.index] && isRect(room.doors[o.index].rect)) {
      for (const [name, [hx, hy]] of Object.entries(doorHandles(room.doors[o.index].rect))) if (Math.abs(pt.x - hx) <= tol && Math.abs(pt.y - hy) <= tol) return { kind: "door", index: o.index, handle: name };
    }
    if (view.markers) {
      const sp = Object.entries(room.spawns).reverse();
      for (const [id, p] of sp) if (isPt(p) && Math.hypot(pt.x - p[0], pt.y - p[1]) <= tol + 2 / geo.s) return { kind: "spawn", id };
      for (let k = room.enemies.length - 1; k >= 0; k--) {
        const e = room.enemies[k];
        if (!isPt(e.at)) continue;
        const { cx, cy, R } = enemyGeom(e);
        if (Math.hypot(pt.x - cx, pt.y - cy) <= R + 2 / geo.s || (((pt.x - e.at[0]) / R) ** 2 + ((pt.y - e.at[1]) / (R * 0.4)) ** 2 <= 1)) return { kind: "enemy", index: k };
      }
      for (let k = room.doors.length - 1; k >= 0; k--) {
        const r = room.doors[k].rect;
        if (isRect(r) && pt.x >= r[0] - tol / 2 && pt.x <= r[0] + r[2] + tol / 2 && pt.y >= r[1] - tol / 2 && pt.y <= r[1] + r[3] + tol / 2) return { kind: "door", index: k };
      }
    }
    const front = [];
    const back = [];
    room.props.forEach((p, k) => (p.front ? front : back).push(k));
    for (const k of front.reverse().concat(back.reverse())) {
      const p = room.props[k];
      if (!isPt(p.at)) continue;
      const c = imgOf(p.image);
      const pw = c && c.w ? c.w : 60;
      const ph = c && c.h ? c.h : 60;
      if (pt.x >= p.at[0] && pt.x <= p.at[0] + pw && pt.y >= p.at[1] && pt.y <= p.at[1] + ph) return { kind: "prop", index: k };
    }
    return null;
  }

  function onStageDown(e) {
    if (e.button !== 0) return;
    const room = curRoom();
    if (!room) return;
    const pt = toRoom(e);
    const { w, h: H } = roomSize(room);
    const inRoom = { x: clamp(pt.x, 0, w), y: clamp(pt.y, 0, H) };
    const before = capture();
    let started = null;
    if (tool === "select") {
      const hit = hitTest(pt);
      sel.obj = hit ? (hit.kind === "spawn" ? { kind: "spawn", id: hit.id } : { kind: hit.kind, index: hit.index }) : null;
      if (hit && hit.handle) started = { kind: "resize", index: hit.index, handle: hit.handle, orig: room.doors[hit.index].rect.slice() };
      else if (hit) {
        const orig = hit.kind === "spawn" ? room.spawns[hit.id].slice() : hit.kind === "door" ? room.doors[hit.index].rect.slice() : room[LIST[hit.kind]][hit.index].at.slice();
        started = { kind: "move", obj: sel.obj, orig };
      }
      renderInspector();
    } else if (tool === "spawn") {
      const id = addSpawn(room, inRoom);
      if (id) started = { kind: "move", obj: sel.obj, orig: room.spawns[id].slice() };
    } else if (tool === "enemy") {
      const k = addEnemy(room, inRoom);
      if (k >= 0) started = { kind: "move", obj: sel.obj, orig: room.enemies[k].at.slice() };
    } else if (tool === "prop") {
      if (!propImage || !pack.images[propImage]) toast("先在工具栏里选一张道具图片（或把左边“图片”里的图拖到画布上）", "warn");
      else {
        const k = addProp(room, propImage, inRoom);
        if (k >= 0) started = { kind: "move", obj: sel.obj, orig: room.props[k].at.slice() };
      }
    } else if (tool === "door") {
      if (room.doors.length >= L.doors) toast(`一个房间最多 ${L.doors} 扇门`, "error");
      else started = { kind: "newdoor", rect: null };
    } else if (tool === "wall" || tool === "floor" || tool === "fill") {
      if (maskReady(room)) {
        const m = paintGrid(room);
        if (m) {
          if (tool === "fill") {
            floodFill(m, pt.x, pt.y);
            saveMask(room.mask, m);
          } else {
            stamp(m, pt.x, pt.y, brush / 2, tool === "wall" ? 1 : 0);
            started = { kind: "paint", m, last: pt, v: tool === "wall" ? 1 : 0 };
          }
        }
      }
    }
    if (started) {
      drag = Object.assign(started, { start: pt, before });
      stage.setPointerCapture(e.pointerId);
    } else commitFrom(before);
    requestDraw();
  }

  function onStageMove(e) {
    const room = curRoom();
    if (!room) return;
    const pt = toRoom(e);
    hover = pt;
    const { w, h: H } = roomSize(room);
    const wall = room.mask ? wallAt(room, pt.x, pt.y, w, H) : false;
    $("#coords").textContent = `x ${Math.round(pt.x)}  y ${Math.round(pt.y)}` + (pt.x >= 0 && pt.y >= 0 && pt.x < w && pt.y < H ? (wall === true ? " · 墙" : wall === false ? " · 地面" : "") : "");
    if (drag) {
      const dx = pt.x - drag.start.x;
      const dy = pt.y - drag.start.y;
      if (drag.kind === "move") {
        const o = drag.obj;
        const [ox, oy] = drag.orig;
        if (o.kind === "spawn") room.spawns[o.id] = [Math.round(clamp(ox + dx, 0, w)), Math.round(clamp(oy + dy, 0, H))];
        else if (o.kind === "door") {
          const r = room.doors[o.index].rect;
          room.doors[o.index].rect = [Math.round(ox + dx), Math.round(oy + dy), r[2], r[3]];
        } else if (o.kind === "enemy") room.enemies[o.index].at = [Math.round(clamp(ox + dx, 0, w)), Math.round(clamp(oy + dy, 0, H))];
        else room.props[o.index].at = [Math.round(ox + dx), Math.round(oy + dy)];
      } else if (drag.kind === "resize") {
        const r = drag.orig;
        let x0 = r[0];
        let y0 = r[1];
        let x1 = r[0] + r[2];
        let y1 = r[1] + r[3];
        if (drag.handle.includes("w")) x0 += dx;
        if (drag.handle.includes("e")) x1 += dx;
        if (drag.handle.includes("n")) y0 += dy;
        if (drag.handle.includes("s")) y1 += dy;
        room.doors[drag.index].rect = [Math.round(Math.min(x0, x1)), Math.round(Math.min(y0, y1)), Math.max(4, Math.round(Math.abs(x1 - x0))), Math.max(4, Math.round(Math.abs(y1 - y0)))];
      } else if (drag.kind === "newdoor") {
        const a = drag.start;
        const b = { x: clamp(pt.x, 0, w), y: clamp(pt.y, 0, H) };
        drag.rect = [Math.round(Math.min(a.x, b.x)), Math.round(Math.min(a.y, b.y)), Math.round(Math.abs(b.x - a.x)), Math.round(Math.abs(b.y - a.y))];
      } else if (drag.kind === "paint") {
        strokeLine(drag.m, drag.last, pt, brush / 2, drag.v);
        drag.last = pt;
      }
    } else if (tool === "select") {
      const hit = hitTest(pt);
      stage.style.cursor = hit ? (hit.handle ? CURSORS[hit.handle] : "move") : "default";
    }
    requestDraw();
  }

  function onStageUp() {
    if (!drag) return;
    const d = drag;
    drag = null;
    const room = curRoom();
    if (room) {
      if (d.kind === "newdoor") {
        let rect = d.rect;
        if (!rect || rect[2] < 8 || rect[3] < 8) {
          const { w, h: H } = roomSize(room);
          rect = [Math.round(clamp(d.start.x - 30, 0, w - 60)), Math.round(clamp(d.start.y - 70, 0, H - 140)), 60, 140];
        }
        addDoor(room, rect);
      } else if (d.kind === "paint") saveMask(room.mask, d.m);
    }
    commitFrom(d.before);
  }

  function setCursorForTool() {
    stage.style.cursor = { select: "default", wall: "none", floor: "none", fill: "cell", door: "crosshair", spawn: "copy", enemy: "copy", prop: "copy" }[tool] || "default";
  }
  function setTool(t) {
    tool = t;
    if (t === "wall" || t === "floor" || t === "fill") view.mask = true;
    if (t === "prop" && (!propImage || !pack.images[propImage])) propImage = Object.keys(pack.images).find((id) => !looksLikeBackground(id)) || Object.keys(pack.images)[0] || "";
    setCursorForTool();
    renderToolbar();
    renderStatusHint();
    requestDraw();
  }

  stage.addEventListener("pointerdown", onStageDown);
  stage.addEventListener("pointermove", onStageMove);
  stage.addEventListener("pointerup", onStageUp);
  stage.addEventListener("pointercancel", onStageUp);
  stage.addEventListener("pointerleave", () => {
    hover = null;
    $("#coords").textContent = "—";
    requestDraw();
  });
  stage.addEventListener("dragover", (e) => {
    if (e.dataTransfer.types.includes("text/x-aola-image")) {
      e.preventDefault();
      e.dataTransfer.dropEffect = "copy";
    }
  });
  stage.addEventListener("drop", (e) => {
    const id = e.dataTransfer.getData("text/x-aola-image");
    const room = curRoom();
    if (!id || !room || !pack.images[id]) return;
    e.preventDefault();
    e.stopPropagation();
    const pt = toRoom(e);
    change(() => addProp(room, id, pt));
    propImage = id;
  });
  new ResizeObserver(() => requestDraw()).observe(wrap);

  // ------------------------------------------------------------------ panels

  const levelsPane = $("#levelsPane");
  const imagesPane = $("#imagesPane");
  const inspector = $("#inspector");
  const toolbar = $("#toolbar");

  /** Replaces a panel's content, keeping its scroll and the focused field (by data-key). */
  function fill(container, kids) {
    const a = document.activeElement;
    let key = null;
    let s0 = null;
    let s1 = null;
    if (a && container.contains(a) && a.dataset && a.dataset.key) {
      key = a.dataset.key;
      try {
        s0 = a.selectionStart;
        s1 = a.selectionEnd;
      } catch {
        /* not a text field */
      }
    }
    const top = container.scrollTop;
    container.replaceChildren(...kids.filter(Boolean));
    container.scrollTop = top;
    if (key) {
      const el = container.querySelector(`[data-key="${CSS.escape(key)}"]`);
      if (el) {
        el.focus({ preventScroll: true });
        try {
          if (s0 !== null) el.setSelectionRange(s0, s1);
        } catch {
          /* not a text field */
        }
      }
    }
  }

  function renderAll() {
    renderPending = false;
    fixSel();
    renderHeader();
    renderTabs();
    if (tab === "levels") renderLevels();
    else renderImages();
    renderToolbar();
    renderInspector();
    renderStatusHint();
    requestDraw();
  }

  function renderHeader() {
    const n = $("#packName");
    const a = $("#packAuthor");
    if (document.activeElement !== n) n.value = pack.name || "";
    if (document.activeElement !== a) a.value = pack.author || "";
    $("#btnUndo").disabled = !undoStack.length;
    $("#btnRedo").disabled = !redoStack.length;
    $("#imageCount").textContent = `(${Object.keys(pack.images).length})`;
  }

  function renderTabs() {
    for (const b of document.querySelectorAll(".tabs button")) {
      b.classList.toggle("on", b.dataset.tab === tab);
      b.setAttribute("aria-selected", String(b.dataset.tab === tab));
    }
    levelsPane.hidden = tab !== "levels";
    imagesPane.hidden = tab !== "images";
  }

  function renderLevels() {
    const lv = curLevel();
    const room = curRoom();
    const kids = [];
    kids.push(h("h3", { class: "sec" }, "关卡", h("small", null, `${pack.levels.length}/${L.levels}`)));
    const ol = h("ol", { class: "list", id: "levelList" });
    pack.levels.forEach((l, i) =>
      ol.append(
        h(
          "li",
          { class: i === sel.level ? "sel" : "", dataset: { level: i }, onclick: () => selectLevel(i) },
          h("span", { class: "n" }, i + 1),
          h("span", { class: "t" }, l.name || "（没有名字）"),
          h("code", null, l.id),
          l.next ? h("span", { class: "badge", title: "通关后的下一关" }, "→ " + l.next) : null,
        ),
      ),
    );
    if (!pack.levels.length) ol.append(h("li", { class: "empty" }, "还没有关卡"));
    kids.push(ol);
    kids.push(
      h(
        "div",
        { class: "row-btns" },
        button("＋ 关卡", addLevel, { id: "btnAddLevel", disabled: pack.levels.length >= L.levels }),
        button("↑", () => moveLevel(-1), { class: "icon", title: "上移", disabled: !lv || sel.level === 0 }),
        button("↓", () => moveLevel(1), { class: "icon", title: "下移", disabled: !lv || sel.level >= pack.levels.length - 1 }),
        button("删除", deleteLevel, { class: "danger", disabled: !lv, id: "btnDelLevel" }),
      ),
    );
    if (!lv) return fill(levelsPane, kids);

    kids.push(
      h(
        "div",
        { class: "card" },
        h("h4", null, "关卡设置"),
        field("名字", textIn("level-name", lv.name, (v) => change(() => (lv.name = v.trim())), { maxlength: L.nameLength, placeholder: "第一关" })),
        field("编号", textIn("level-id", lv.id, (v, el) => renameLevelId(lv, v.trim(), el), { maxlength: L.idLength, class: "mono" }), "英文字母、数字、_ 和 -；门用它找到这一关"),
        field(
          "起始房间",
          selectIn("level-start", lv.rooms.map((r) => ({ value: r.id, label: roomLabel(r) })), lv.start, (v) => change(() => (lv.start = v))),
        ),
        field(
          "下一关",
          selectIn("level-next", [{ value: "", label: "（没有）" }].concat(pack.levels.filter((x) => x !== lv).map((x) => ({ value: x.id, label: levelLabel(x) }))), lv.next || "", (v) => change(() => (lv.next = v))),
          "通关（#finish）后给玩家的下一个关卡",
        ),
        h(
          "label",
          { class: "check" },
          h("input", { type: "checkbox", checked: lv.heal !== false, dataset: { key: "level-heal" }, onchange: (e) => change(() => (lv.heal = e.target.checked)) }),
          "每场战斗前回满背包亚比的体力和PP",
        ),
      ),
    );

    kids.push(h("h3", { class: "sec" }, "房间", h("small", null, `${lv.rooms.length}/${L.rooms}`)));
    const rl = h("ol", { class: "list", id: "roomList" });
    lv.rooms.forEach((r, j) =>
      rl.append(
        h(
          "li",
          { class: j === sel.room ? "sel" : "", dataset: { room: j }, onclick: () => selectRoom(j) },
          h("span", { class: "n" }, j + 1),
          h("span", { class: "t" }, r.name || "（没有名字）"),
          h("code", null, r.id),
          lv.start === r.id ? h("span", { class: "badge green" }, "起始") : null,
          r.enemies.some((e) => e.boss) ? h("span", { class: "badge red" }, "首领") : null,
        ),
      ),
    );
    kids.push(rl);
    kids.push(
      h(
        "div",
        { class: "row-btns" },
        button("＋ 房间", addRoom, { id: "btnAddRoom", disabled: lv.rooms.length >= L.rooms }),
        button("↑", () => moveRoom(-1), { class: "icon", title: "上移", disabled: sel.room === 0 }),
        button("↓", () => moveRoom(1), { class: "icon", title: "下移", disabled: sel.room >= lv.rooms.length - 1 }),
        button("删除", deleteRoom, { class: "danger", disabled: lv.rooms.length <= 1, id: "btnDelRoom" }),
      ),
    );
    if (room) {
      const { w, h: H } = roomSize(room);
      const notes = [];
      const bi = room.background && pack.images[room.background] ? infoOf(room.background) : null;
      if (bi && !bi.error) {
        if (bi.height !== L.roomHeight) notes.push(h("div", { class: "note warn" }, `背景高 ${bi.height}：房间应为 ${L.roomHeight} 高（可在“图片”里缩放）`));
        if (bi.width < L.roomMinWidth) notes.push(h("div", { class: "note warn" }, `背景宽 ${bi.width}：房间至少 ${L.roomMinWidth} 宽`));
      }
      if (room.mask && pack.images[room.mask]) {
        const mi = infoOf(room.mask);
        if (!mi.error && (mi.width !== w || mi.height !== H)) notes.push(h("div", { class: "note" }, `遮罩是 ${mi.width}×${mi.height}，会拉伸到房间大小；在上面画一笔后会存成 ${w}×${H}。`));
      }
      kids.push(
        h(
          "div",
          { class: "card" },
          h("h4", null, "房间设置"),
          field("名字", textIn("room-name", room.name, (v) => change(() => (room.name = v.trim())), { maxlength: L.nameLength, placeholder: "入口" })),
          field("编号", textIn("room-id", room.id, (v, el) => renameRoomId(lv, room, v.trim(), el), { maxlength: L.idLength, class: "mono" })),
          field(
            "背景",
            h(
              "div",
              { class: "with" },
              selectIn("room-bg", [{ value: "", label: "（选一张图片）" }].concat(imageOptions()), room.background, (v) => change(() => (room.background = v))),
              button("＋", pickImages, { class: "icon", title: "添加图片" }),
            ),
            "房间的大小由它决定：560 高，960–2880 宽",
          ),
          field("前景", selectIn("room-overlay", [{ value: "", label: "（没有）" }].concat(imageOptions()), room.overlay, (v) => change(() => (room.overlay = v))), "从左上角画在玩家前面（树、柱子）"),
          field(
            "遮罩",
            selectIn(
              "room-mask",
              [{ value: "", label: "（没有：到处都能走）" }].concat(imageOptions(), [{ value: "#new", label: "＋ 画一张新遮罩" }]),
              room.mask,
              (v) => (v === "#new" ? newMaskForRoom() : change(() => (room.mask = v))),
            ),
            "黑色是墙，白色或透明是地面",
          ),
          field("音乐", textIn("room-music", room.music, (v) => change(() => (room.music = v.trim())), { placeholder: "music/xxx.mp3（可不填）", class: "mono", pattern: "music/[A-Za-z0-9_.\\/\\-]+\\.mp3" }), "游戏里的音乐文件，可不填"),
          h("div", { class: "note" }, `房间大小 ${w}×${H}`),
          notes,
        ),
      );
    }
    fill(levelsPane, kids);
  }

  function renderImages() {
    const ids = Object.keys(pack.images);
    const ratio = packBytes / L.fileBytes;
    const bar = h("div", { class: "bar" }, h("span", { style: { width: Math.min(100, ratio * 100).toFixed(1) + "%" } }));
    const kids = [
      h(
        "div",
        { class: "sizebar" + (ratio > 1 ? " over" : ratio > 0.8 ? " high" : ""), id: "sizeBar" },
        bar,
        h("div", { class: "txt" }, h("span", null, `包的大小 ${fmtBytes(packBytes)} / ${L.fileBytes / 1e6} MB`), h("span", null, `${ids.length}/${L.images} 张图片`)),
      ),
      h("div", { class: "row-btns" }, button("＋ 添加图片…", pickImages, { class: "primary", id: "btnAddImages", disabled: ids.length >= L.images })),
      h("p", { class: "note" }, "PNG 或 JPG，可以一次选好几张（也可以把文件拖进窗口）。背景应为 560 高、960–2880 宽。把下面的图片拖到画布上，就放成了一个道具。"),
    ];
    const ul = h("ul", { class: "images" });
    for (const id of ids) {
      const inf = infoOf(id);
      const uses = P.imageUses(pack, id);
      const kinds = { background: "背景", mask: "遮罩", overlay: "前景", prop: "道具" };
      const byKind = {};
      for (const u of uses) {
        const l = pack.levels[u.level];
        const r = l.rooms[u.room];
        (byKind[u.field] ||= new Set()).add(pack.levels.length > 1 ? `${l.id}/${r.id}` : r.id);
      }
      const useText = Object.entries(byKind).map(([k, set]) => `${kinds[k]}：${[...set].join("、")}`).join("；");
      const notes = [];
      if (inf.error) notes.push(h("div", { class: "err" }, inf.error));
      else {
        if (inf.width > L.imageWidth || inf.height > L.imageHeight) notes.push(h("div", { class: "err" }, `太大了：最大 ${L.imageWidth}×${L.imageHeight}`));
        const bgUse = !!byKind.background;
        if (inf.height !== L.roomHeight || inf.width < L.roomMinWidth || inf.width > L.imageWidth) {
          if (bgUse) notes.push(h("div", { class: "warn" }, `作背景应为 560 高、960–2880 宽`));
          else if (inf.height <= L.imageHeight && inf.width <= L.imageWidth) notes.push(h("div", { class: "dim" }, "不是背景的尺寸（可作道具、前景、遮罩）"));
        }
        if (inf.mismatch) notes.push(h("div", { class: "warn" }, "文件类型和内容不一致"));
      }
      const canScale = !inf.error && (inf.height > L.imageHeight || inf.width > L.imageWidth || (byKind.background && inf.height !== L.roomHeight));
      ul.append(
        h(
          "li",
          { class: "img-item", id: "img-" + id, dataset: { image: id } },
          h("div", { class: "thumb" }, thumbOf(id)),
          h(
            "div",
            { class: "img-meta" },
            textIn("img-id-" + id, id, (v, el) => renameImageId(id, v.trim(), el), { class: "mono", maxlength: L.idLength, title: "图片编号（改了会同时改所有用到它的地方）" }),
            h("div", { class: "dim" }, inf.error ? fmtBytes(inf.bytes || 0) : `${inf.width}×${inf.height} · ${fmtBytes(inf.bytes)} · ${inf.type === "png" ? "PNG" : "JPG"}`),
            h("div", { class: "uses" }, useText || h("span", { class: "warn" }, "没有用到")),
            notes,
          ),
          h(
            "div",
            { class: "img-ops" },
            canScale ? button(inf.height > L.imageHeight || byKind.background ? "缩放到 560 高" : "缩小", () => scaleImage(id), { title: "按比例缩放，最大 2880×560" }) : null,
            button("删除", () => deleteImage(id), { class: "danger" }),
          ),
        ),
      );
    }
    if (!ids.length) ul.append(h("li", { class: "note" }, "还没有图片。"));
    kids.push(ul);
    fill(imagesPane, kids);
  }

  function renderToolbar() {
    const room = curRoom();
    const seg = (items) =>
      h(
        "div",
        { class: "seg" },
        items.map(([t, label, title]) => button(label, () => setTool(t), { class: tool === t ? "on" : "", title, dataset: { tool: t } })),
      );
    const kids = [
      h(
        "div",
        { class: "tgroup" },
        h("span", { class: "lbl" }, "工具"),
        seg([
          ["select", "选择", "点选、拖动、改大小（V）"],
          ["spawn", "入口点", "点一下放一个入口点"],
          ["door", "门", "拖出门的方框（D）"],
          ["enemy", "对手", "点一下放一个对手"],
          ["prop", "道具", "选好图片后点一下"],
        ]),
      ),
    ];
    if (tool === "prop")
      kids.push(
        h(
          "div",
          { class: "tgroup" },
          h("span", { class: "lbl" }, "道具图片"),
          selectIn("prop-image", [{ value: "", label: "（选择）" }].concat(imageOptions()), propImage, (v) => {
            propImage = v;
          }),
        ),
      );
    const brushIn = h("input", {
      type: "range",
      min: 2,
      max: 200,
      step: 2,
      value: brush,
      dataset: { key: "brush" },
      title: "笔刷大小（房间里的像素）",
      oninput: (e) => {
        brush = Number(e.target.value);
        brushVal.textContent = brush;
        requestDraw();
      },
    });
    const brushVal = h("span", { class: "val" }, brush);
    kids.push(
      h(
        "div",
        { class: "tgroup" },
        h("span", { class: "lbl" }, "遮罩"),
        seg([
          ["wall", "画墙", "按住拖动，把不能走的地方涂成墙（B）"],
          ["floor", "画地面", "按住拖动，擦成能走的地面（E）"],
          ["fill", "填充", "点一块连着的区域：地面变墙，墙变地面（F）"],
        ]),
        h("label", null, "笔刷", brushIn, brushVal),
        button("全部地面", () => fillAll(0), { disabled: !room, dataset: { action: "all-floor" } }),
        button("全部墙", () => fillAll(1), { disabled: !room, dataset: { action: "all-wall" } }),
      ),
    );
    const check = (key, label, title) =>
      h(
        "label",
        { title },
        h("input", {
          type: "checkbox",
          checked: view[key],
          dataset: { view: key },
          onchange: (e) => {
            view[key] = e.target.checked;
            requestDraw();
          },
        }),
        label,
      );
    kids.push(
      h(
        "div",
        { class: "tgroup" },
        h("span", { class: "lbl" }, "显示"),
        check("mask", "遮罩", "墙显示成半透明的红色（M）"),
        check("overlay", "前景", "显示前景图片"),
        check("markers", "标记", "显示入口点、门和对手"),
        selectIn(
          "zoom",
          [
            { value: "fit", label: "适应窗口" },
            { value: "0.5", label: "50%" },
            { value: "1", label: "100%" },
            { value: "2", label: "200%" },
          ],
          view.zoom,
          (v) => {
            view.zoom = v;
            requestDraw();
          },
          { title: "缩放" },
        ),
      ),
    );
    fill(toolbar, kids);
  }

  function fillAll(v) {
    const room = curRoom();
    if (!room || !maskReady(room)) return;
    const before = capture();
    const m = paintGrid(room);
    if (m) {
      m.grid.fill(v);
      m.dirty = [0, 0, m.w, m.h];
      saveMask(room.mask, m);
      view.mask = true;
    }
    commitFrom(before);
  }

  const HINTS = {
    select: "点选、拖动；拖门的角改大小；Delete 删除，方向键微调（Shift 一次 10）",
    spawn: "在画布上点一下放一个入口点（第一个叫 start）",
    door: "在画布上拖出门的方框（点一下放一扇默认大小的门）",
    enemy: "在画布上点一下放一个对手",
    prop: "选好道具图片后在画布上点一下；也可以把“图片”里的图拖到画布上",
    wall: "按住拖动画墙（游戏里是黑色）",
    floor: "按住拖动擦成地面（游戏里是透明）",
    fill: "点一块连着的区域：地面变成墙，墙变成地面",
  };
  function renderStatusHint() {
    $("#toolHint").textContent = HINTS[tool] || "";
    setCursorForTool();
  }

  function renderInspector() {
    const lv = curLevel();
    const room = curRoom();
    if (!room) return fill(inspector, [h("div", { class: "hint-box" }, "先在左边选一个关卡和房间。")]);
    const isSel = (kind, key) => sel.obj && sel.obj.kind === kind && (kind === "spawn" ? sel.obj.id === key : sel.obj.index === key);
    const chip = (text, selected, o, title) => h("button", { type: "button", class: "chip" + (selected ? " sel" : ""), title: title || text, onclick: () => selectObj(o) }, text);
    const section = (label, n, max, onAdd, chips, emptyText) =>
      h(
        "section",
        null,
        h("div", { class: "head" }, h("b", null, label), h("small", null, `${n}/${max}`), h("span", { class: "grow" }), button("＋", onAdd, { class: "icon", title: "加一个" + label, disabled: n >= max, dataset: { add: label } })),
        h("div", { class: "chips" }, chips.length ? chips : h("span", { class: "chip none" }, emptyText)),
      );
    const c = roomCenter(room);
    const spawnIds = Object.keys(room.spawns);
    const things = h(
      "div",
      { class: "things" },
      h("h3", { class: "sec" }, "房间里的东西", h("span", { class: "grow" }), h("small", null, roomLabel(room))),
      section("入口点", spawnIds.length, L.spawns, () => change(() => addSpawn(room, c)), spawnIds.map((id) => chip(id, isSel("spawn", id), { kind: "spawn", id })), "还没有：门进来的玩家站在这里"),
      section("门", room.doors.length, L.doors, () => change(() => addDoor(room, [Math.round(c.x - 30), Math.round(c.y - 140), 60, 140])), room.doors.map((d, k) => chip(`门${k + 1} ${d.label || doorTargetText(d)}`, isSel("door", k), { kind: "door", index: k })), "还没有门"),
      section("对手", room.enemies.length, L.enemies, () => change(() => addEnemy(room, c)), room.enemies.map((e, k) => chip((e.boss ? "首领 " : "") + (e.name || e.id), isSel("enemy", k), { kind: "enemy", index: k }, `${e.id}：${e.team.length} 只亚比`)), "还没有对手"),
      section(
        "道具",
        room.props.length,
        L.props,
        () => {
          const img = propImage && pack.images[propImage] ? propImage : Object.keys(pack.images).find((id) => !looksLikeBackground(id));
          if (!img) return toast("先在“图片”里添加道具图片", "warn");
          change(() => addProp(room, img, c));
        },
        room.props.map((p, k) => chip(`${k + 1} ${p.image}${p.front ? "（前）" : ""}`, isSel("prop", k), { kind: "prop", index: k })),
        "还没有道具",
      ),
    );
    if (!("start" in room.spawns)) things.append(h("div", { class: "note warn" }, "这个房间还没有 start 入口点：门没写入口点时，玩家从 start 进来。"));
    fill(inspector, [things, h("div", { class: "inspect", id: "inspect" }, inspectorFor(lv, room))]);
  }

  function xyFields(prefix, pt, commit) {
    return h(
      "div",
      { class: "xy" },
      h("label", null, "x", numIn(prefix + "-x", pt[0], (v) => commit([Math.round(v), pt[1]]), { step: 1 })),
      h("label", null, "y", numIn(prefix + "-y", pt[1], (v) => commit([pt[0], Math.round(v)]), { step: 1 })),
    );
  }

  function inspectorFor(lv, room) {
    const o = sel.obj;
    const head = (title, extra) => h("h3", null, title, h("span", { class: "grow" }), extra, button("删除", deleteSelected, { class: "danger", id: "btnDelObj" }));
    if (!o)
      return [
        h(
          "div",
          { class: "hint-box" },
          "在画布上点选一个东西来修改它，或用上面的工具添加：",
          h(
            "ul",
            null,
            h("li", null, "入口点：玩家进房间时站的地方（start 是默认的）。"),
            h("li", null, "门：走进方框就到别的房间、别的关卡、通关或离开。"),
            h("li", null, "对手：点它就开打，一队 1–10 只亚比一个接一个上。"),
            h("li", null, "遮罩：用“画墙”把不能走的地方涂掉。"),
          ),
        ),
      ];
    if (o.kind === "spawn") {
      const pt = room.spawns[o.id];
      const used = P.doorsTo(pack, lv, room.id).filter((d) => pack.levels[d.level].rooms[d.room].doors[d.index].spawn === o.id);
      return [
        head("入口点"),
        field(
          "名字",
          textIn(
            "spawn-id",
            o.id,
            (v, el) => {
              v = v.trim();
              const err = P.idProblem(v, Object.keys(room.spawns), o.id);
              if (err) {
                el.value = o.id;
                return toast(err, "error");
              }
              change(() => {
                P.renameSpawn(pack, lv, room, o.id, v);
                sel.obj = { kind: "spawn", id: v };
              });
            },
            { class: "mono", maxlength: L.idLength },
          ),
          o.id === "start" ? "门没写入口点时用 start；起始房间也从 start 开始" : "门可以指定从这个入口点进来",
        ),
        field("位置", xyFields("spawn", pt, (p) => change(() => (room.spawns[o.id] = p)))),
        used.length ? h("div", { class: "note" }, `有 ${used.length} 扇门指定从这里进来。`) : null,
        o.id !== "start" && !("start" in room.spawns)
          ? button("改名为 start", () =>
              change(() => {
                P.renameSpawn(pack, lv, room, o.id, "start");
                sel.obj = { kind: "spawn", id: "start" };
              }),
            )
          : null,
      ];
    }
    if (o.kind === "door") {
      const d = room.doors[o.index];
      const t = P.parseTarget(d.to);
      const target = P.resolveTarget(pack, lv, d.to);
      const groups = [
        { group: "这个关卡的房间", options: lv.rooms.map((r) => ({ value: r.id, label: roomLabel(r) + (r === room ? "（这个房间）" : "") })) },
        ...pack.levels.filter((l) => l !== lv).map((l) => ({ group: `关卡「${l.name || l.id}」(${l.id})`, options: l.rooms.map((r) => ({ value: `${l.id}/${r.id}`, label: `${l.id}/${r.id}  ${r.name || ""}` })) })),
        {
          group: "特殊",
          options: [
            { value: "#finish", label: "通关（#finish）" },
            { value: "#exit", label: "离开沙盒（#exit）" },
          ],
        },
      ];
      const spawnOpts = [{ value: "", label: "（默认：start）" }].concat(target ? Object.keys(target.room.spawns).map((k) => ({ value: k, label: k })) : []);
      const r = isRect(d.rect) ? d.rect : [0, 0, 60, 140];
      const rectIn = (i, label) => h("label", null, label, numIn("door-rect-" + i, r[i], (v) => change(() => {
        const nr = r.slice();
        nr[i] = Math.round(v);
        d.rect = nr;
      }), { step: 1, min: i >= 2 ? 1 : undefined }));
      return [
        head(`门 ${o.index + 1}`, button("复制", duplicateSelected, { title: "复制一扇一样的门" })),
        field(
          "通向",
          selectIn("door-to", [{ value: "", label: "（选择）" }].concat(groups), d.to, (v) =>
            change(() => {
              d.to = v;
              const nt = P.resolveTarget(pack, lv, v);
              if (d.spawn && !(nt && d.spawn in nt.room.spawns)) d.spawn = "";
            }),
          ),
        ),
        field(
          "入口点",
          selectIn("door-spawn", spawnOpts, d.spawn || "", (v) => change(() => (d.spawn = v)), { disabled: !target }),
          target ? `进 ${target.room.id} 后站在哪个入口点` : t && t.kind !== "room" ? "通关和离开用不到入口点" : "",
        ),
        field(
          "开门",
          selectIn(
            "door-open",
            [
              { value: "always", label: "一直开着" },
              { value: "cleared", label: "打败这个房间所有对手后" },
            ],
            d.open || "always",
            (v) => change(() => (d.open = v)),
          ),
        ),
        field("门上的字", textIn("door-label", d.label, (v) => change(() => (d.label = v.trim())), { maxlength: L.labelLength, placeholder: "可不填" })),
        field("方框", h("div", { class: "xy" }, rectIn(0, "x"), rectIn(1, "y"))),
        field("", h("div", { class: "xy" }, rectIn(2, "宽"), rectIn(3, "高"))),
        target && target.room !== room
          ? h("div", { class: "row-btns" }, button("＋ 在目标房间加一扇通回来的门", () => linkBack(d), { id: "btnLinkBack", title: "在目标房间对面的位置加一扇门通回这里，两边各加一个入口点" }))
          : null,
      ];
    }
    if (o.kind === "enemy") {
      const e = room.enemies[o.index];
      const lvIds = lv.rooms.flatMap((r) => r.enemies.filter((x) => x !== e).map((x) => x.id));
      const team = h("div", { class: "team", id: "team" });
      e.team.forEach((m, n) => team.append(memberRow(e, m, n)));
      return [
        head("对手", button("复制", duplicateSelected, { title: "复制一个一样的对手" })),
        field(
          "编号",
          textIn(
            "enemy-id",
            e.id,
            (v, el) => {
              v = v.trim();
              const err = P.idProblem(v, lvIds, e.id);
              if (err) {
                el.value = e.id;
                return toast(err, "error");
              }
              change(() => (e.id = v));
            },
            { class: "mono", maxlength: L.idLength },
          ),
          "打败后这一关里它就不再出现",
        ),
        field("名字", textIn("enemy-name", e.name, (v) => change(() => (e.name = v.trim())), { maxlength: L.enemyNameLength, placeholder: "守卫" })),
        h("label", { class: "check" }, h("input", { type: "checkbox", checked: e.boss, dataset: { key: "enemy-boss" }, onchange: (ev) => change(() => (e.boss = ev.target.checked)) }), "首领（画得更大，显示名字）"),
        field("位置", xyFields("enemy", e.at, (p) => change(() => (e.at = p))), "脚下的位置；站着的是队伍里第一只亚比"),
        h("h4", null, `队伍 ${e.team.length}/${L.team}`, h("small", null, " · 一个接一个打；百分数 100 是原样")),
        team,
        h(
          "div",
          { class: "row-btns" },
          button(
            "＋ 添加亚比",
            () =>
              change(() => {
                const last = e.team[e.team.length - 1];
                e.team.push(last ? P.newOpponent(last.race, last.level) : P.newOpponent(1, 10)); // stats as they are
              }),
            { disabled: e.team.length >= L.team, id: "btnAddMember" },
          ),
        ),
        names ? null : h("div", { class: "note" }, location.protocol === "file:" ? "直接从文件打开时读不到亚比名字，只显示编号。" : "没读到亚比名字（游戏的 pets.json），只显示编号。"),
      ];
    }
    if (o.kind === "prop") {
      const p = room.props[o.index];
      const c = imgOf(p.image);
      return [
        head(`道具 ${o.index + 1}`, button("复制", duplicateSelected, { title: "复制一个一样的道具" })),
        field("图片", selectIn("prop-img", imageOptions(), p.image, (v) => change(() => (p.image = v)))),
        field("位置", xyFields("prop", p.at, (pt) => change(() => (p.at = pt))), c && c.w ? `左上角；图片 ${c.w}×${c.h}` : "左上角"),
        h("label", { class: "check" }, h("input", { type: "checkbox", checked: p.front, dataset: { key: "prop-front" }, onchange: (ev) => change(() => (p.front = ev.target.checked)) }), "画在玩家前面（不勾是后面）"),
        h(
          "div",
          { class: "row-btns" },
          button("放到最上层", () => change(() => {
            room.props.push(room.props.splice(o.index, 1)[0]);
            sel.obj = { kind: "prop", index: room.props.length - 1 };
          }), { disabled: o.index === room.props.length - 1 }),
          button("放到最下层", () => change(() => {
            room.props.unshift(room.props.splice(o.index, 1)[0]);
            sel.obj = { kind: "prop", index: 0 };
          }), { disabled: o.index === 0 }),
        ),
      ];
    }
    return [];
  }

  function petName(race) {
    if (!names) return "";
    return names[race] || "图鉴里没有";
  }

  function memberRow(e, m, n) {
    const pet = h("span", { class: "pet" + (names && !names[m.race] ? " unknown" : "") }, petName(m.race));
    const race = numIn("team-" + n + "-race", m.race, (v) => change(() => (m.race = Math.round(v))), { min: 1, step: 1, class: "race", list: "raceList", title: "图鉴编号", oninput: (ev) => {
      pet.textContent = petName(Math.round(Number(ev.target.value)));
      pet.classList.toggle("unknown", !!names && !names[Math.round(Number(ev.target.value))]);
    } });
    const move = (d) =>
      change(() => {
        const j = n + d;
        [e.team[n], e.team[j]] = [e.team[j], e.team[n]];
      });
    return h(
      "div",
      { class: "member", dataset: { member: n } },
      h(
        "div",
        { class: "member-head" },
        h("span", { class: "num" }, n + 1),
        race,
        pet,
        h("span", null, "等级"),
        numIn("team-" + n + "-level", m.level, (v) => change(() => (m.level = Math.round(v))), { min: 1, max: L.maxLevel, step: 1, class: "lv" }),
        h(
          "span",
          { class: "ops" },
          button("↑", () => move(-1), { class: "icon", title: "上移", disabled: n === 0 }),
          button("↓", () => move(1), { class: "icon", title: "下移", disabled: n === e.team.length - 1 }),
          button("✕", () => change(() => e.team.splice(n, 1)), { class: "icon danger", title: "去掉", disabled: e.team.length <= 1 }),
        ),
      ),
      h(
        "div",
        { class: "stats" },
        P.STATS.map((k) => h("label", { title: `${P.STAT_NAMES[k]}（${k}）：百分数，1–10000，100 是原样` }, P.STAT_NAMES[k], numIn(`team-${n}-${k}`, m[k], (v) => change(() => (m[k] = v)), { min: L.pctMin, max: L.pctMax, step: "any" }))),
      ),
    );
  }

  // ------------------------------------------------------------------ pictures: add, rename, delete, scale

  const fileImages = $("#fileImages");
  function pickImages() {
    fileImages.value = "";
    fileImages.click();
  }
  fileImages.addEventListener("change", () => addImageFiles([...fileImages.files]));

  const readAsDataURL = (f) =>
    new Promise((res, rej) => {
      const r = new FileReader();
      r.onload = () => res(r.result);
      r.onerror = () => rej(r.error);
      r.readAsDataURL(f);
    });
  const loadImage = (src) =>
    new Promise((res, rej) => {
      const im = new Image();
      im.onload = () => res(im);
      im.onerror = () => rej(new Error("打不开"));
      im.src = src;
    });
  /** A data: URL of the picture as PNG or JPEG, its type named by what is in it (other formats drawn into a PNG). */
  async function asPngOrJpeg(url) {
    const b64 = url.slice(url.indexOf(",") + 1);
    const head = atob(b64.slice(0, 16));
    if (head.startsWith("\x89PNG")) return { url: "data:image/png;base64," + b64 };
    if (head.charCodeAt(0) === 0xff && head.charCodeAt(1) === 0xd8) return { url: "data:image/jpeg;base64," + b64 };
    const im = await loadImage(url);
    const cv = document.createElement("canvas");
    cv.width = im.naturalWidth;
    cv.height = im.naturalHeight;
    cv.getContext("2d").drawImage(im, 0, 0);
    return { url: cv.toDataURL("image/png"), converted: true };
  }
  async function addImageFiles(files) {
    if (!files.length) return;
    const before = capture();
    const msgs = [];
    let added = 0;
    let last = "";
    for (const f of files) {
      if (Object.keys(pack.images).length >= L.images) {
        msgs.push(`最多 ${L.images} 张图片，剩下的没加`);
        break;
      }
      try {
        const raw = await readAsDataURL(f);
        const { url, converted } = await asPngOrJpeg(raw);
        const inf = P.imageInfo(url);
        if (inf.error) {
          msgs.push(`${f.name}：${inf.error}`);
          continue;
        }
        const id = P.uniqueId(P.sanitizeId(f.name, "img1"), (s) => s in pack.images);
        pack.images[id] = url;
        last = id;
        added++;
        if (converted) msgs.push(`${f.name} 已转成 PNG`);
        if (inf.width > L.imageWidth || inf.height > L.imageHeight) msgs.push(`${id} 是 ${inf.width}×${inf.height}，超过 ${L.imageWidth}×${L.imageHeight}：用“缩放到 560 高”缩小它`);
      } catch {
        msgs.push(`${f.name}：打不开，只能用 PNG 或 JPG`);
      }
    }
    commitFrom(before);
    if (added && (!propImage || !pack.images[propImage])) propImage = last;
    if (added) {
      tab = "images";
      renderAll();
    }
    toast((added ? `加了 ${added} 张图片。` : "没有加图片。") + (msgs.length ? " " + msgs.join("；") : ""), msgs.length ? "warn" : "ok", msgs.length ? 7000 : 3500);
  }
  function renameImageId(id, v, el) {
    const err = P.idProblem(v, Object.keys(pack.images), id);
    if (err) {
      el.value = id;
      return toast(err, "error");
    }
    if (v === id) return;
    change(() => P.renameImage(pack, id, v));
    for (const cache of [imgCache, thumbCache, infoCache, maskCache]) if (cache.has(id)) {
      cache.set(v, cache.get(id));
      cache.delete(id);
    }
    if (propImage === id) propImage = v;
    renderAll();
  }
  async function deleteImage(id) {
    const uses = P.imageUses(pack, id);
    const bg = uses.filter((u) => u.field === "background");
    if (bg.length) {
      const where = [...new Set(bg.map((u) => pack.levels[u.level].id + "/" + pack.levels[u.level].rooms[u.room].id))];
      return ask({ title: "不能删除", body: h("p", null, `图片 ${id} 是这些房间的背景：${where.join("、")}。先给它们换一张背景，再删除这张图片。`), buttons: [{ label: "知道了", value: null, kind: "primary" }] });
    }
    if (uses.length) {
      const kinds = { mask: "遮罩", overlay: "前景", prop: "道具" };
      const list = uses.map((u) => `${pack.levels[u.level].rooms[u.room].id} 的${kinds[u.field]}`);
      const ok = await ask({
        title: "删除图片",
        body: [h("p", null, `图片 ${id} 用作：${[...new Set(list)].join("、")}。`), h("p", null, "删除后这些地方会去掉它（道具会删掉，遮罩和前景改成没有）。删错了可以撤销。")],
        buttons: [
          { label: "删除", value: "go", kind: "danger" },
          { label: "取消", value: null },
        ],
      });
      if (ok !== "go") return;
    }
    change(() => {
      for (const l of pack.levels)
        for (const r of l.rooms) {
          if (r.mask === id) r.mask = "";
          if (r.overlay === id) r.overlay = "";
          r.props = r.props.filter((p) => p.image !== id);
        }
      delete pack.images[id];
    });
    toast(`已删除图片 ${id}（可以撤销）`);
  }
  async function scaleImage(id) {
    const inf = infoOf(id);
    if (inf.error) return;
    let im;
    try {
      im = await loadImage(pack.images[id]);
    } catch {
      return toast("这张图片打不开", "error");
    }
    const k = Math.min(L.imageHeight / im.naturalHeight, L.imageWidth / im.naturalWidth);
    const w = Math.max(1, Math.round(im.naturalWidth * k));
    const H = Math.max(1, Math.round(im.naturalHeight * k));
    const cv = document.createElement("canvas");
    cv.width = w;
    cv.height = H;
    const g = cv.getContext("2d");
    g.imageSmoothingQuality = "high";
    g.drawImage(im, 0, 0, w, H);
    const url = inf.type === "jpeg" ? cv.toDataURL("image/jpeg", 0.9) : cv.toDataURL("image/png");
    change(() => (pack.images[id] = url));
    toast(`${id} 已缩放到 ${w}×${H}` + (w < L.roomMinWidth ? `（宽不到 ${L.roomMinWidth}，作背景太窄）` : ""), w < L.roomMinWidth ? "warn" : "ok");
  }

  // ------------------------------------------------------------------ dialogs and messages

  const dlg = $("#dialog");
  let dlgResolve = null;
  /** An in-page dialog; resolves with the chosen button's value (null on Esc). */
  function ask({ title, body, buttons }) {
    if (dlgResolve) dlgResolve(null);
    $("#dlgTitle").textContent = title;
    const b = $("#dlgBody");
    b.replaceChildren(...[].concat(body).filter(Boolean).map((x) => (x instanceof Node ? x : h("p", null, x))));
    const bs = $("#dlgButtons");
    bs.replaceChildren(
      ...buttons.map((x) =>
        button(
          x.label,
          () => {
            const r = dlgResolve;
            dlgResolve = null;
            dlg.close();
            if (r) r(x.value);
          },
          { class: x.kind || "", dataset: { value: x.value === null ? "cancel" : String(x.value) } },
        ),
      ),
    );
    return new Promise((res) => {
      dlgResolve = res;
      if (!dlg.open) dlg.showModal();
      const first = bs.querySelector("button.primary") || bs.querySelector("button");
      if (first) first.focus();
    });
  }
  dlg.addEventListener("close", () => {
    if (dlgResolve) {
      const r = dlgResolve;
      dlgResolve = null;
      r(null);
    }
  });

  function toast(msg, kind, ms) {
    const t = h("div", { class: "toast " + (kind || ""), role: "status" }, msg);
    const box = $("#toasts");
    box.append(t);
    while (box.children.length > 4) box.firstElementChild.remove();
    setTimeout(() => t.remove(), ms || (kind === "error" ? 6000 : 3500));
  }

  function setSaveState(text, warn) {
    const s = $("#saveState");
    s.textContent = text;
    s.classList.toggle("warn", !!warn);
  }

  // ------------------------------------------------------------------ checking

  function runValidate() {
    const ser = P.serialize(pack);
    const text = P.stringify(ser);
    const bytes = P.utf8Length(text);
    packBytes = bytes;
    return P.validate(ser, { names, bytes, imageInfo: (id, url) => infoOf(id, url), wallAt });
  }
  function problemList(problems) {
    const errs = problems.filter((p) => p.severity === "error").length;
    const warns = problems.length - errs;
    const head = problems.length ? h("p", null, h("b", null, `${errs} 个错误，${warns} 条提醒。`), " 错误会让游戏读不了这个文件；提醒是可能的疏忽。点一条可以跳到那里。") : h("p", { class: "summary-ok" }, "没有发现问题，可以导出。");
    const ul = h("ul", { class: "problems", id: "problemList" });
    for (const p of problems)
      ul.append(
        h(
          "li",
          {
            onclick: () => {
              dlg.close();
              goTo(p.loc);
            },
          },
          h("span", { class: "sev " + p.severity }, p.severity === "error" ? "错误" : "提醒"),
          h("div", null, h("div", null, p.message), h("div", { class: "where" }, p.where)),
        ),
      );
    return [head, problems.length ? ul : null];
  }
  function showProblems(problems) {
    return ask({ title: "检查关卡包", body: problemList(problems), buttons: [{ label: "关闭", value: null, kind: "primary" }] });
  }
  function goTo(loc) {
    if (!loc) return;
    if (loc.kind === "image") {
      tab = "images";
      renderAll();
      const el = document.getElementById("img-" + loc.image);
      if (el) {
        el.scrollIntoView({ block: "center" });
        el.classList.remove("flash");
        void el.offsetWidth;
        el.classList.add("flash");
      }
      return;
    }
    if (loc.kind === "pack") {
      $("#packName").focus();
      return;
    }
    tab = "levels";
    sel.level = loc.level ?? sel.level;
    if (loc.room !== undefined) sel.room = loc.room;
    else if (loc.kind === "level") sel.room = 0;
    sel.obj = loc.kind === "spawn" ? { kind: "spawn", id: loc.spawn } : LIST[loc.kind] ? { kind: loc.kind, index: loc.index } : null;
    renderAll();
  }

  // ------------------------------------------------------------------ new, import, export

  async function newPack() {
    if (!pristine) {
      const ok = await ask({
        title: "新建关卡包",
        body: [h("p", null, "当前的包会换成一个新的空包。"), h("p", { class: "note" }, "没导出的改动还能用“撤销”找回，关掉页面后就没有了。")],
        buttons: [
          { label: "新建", value: "go", kind: "primary" },
          { label: "取消", value: null },
        ],
      });
      if (ok !== "go") return;
    }
    change(() => {
      pack = starterPack();
      sel = { level: 0, room: 0, obj: null };
    });
    pristine = true;
    toast("新建了一个关卡包");
  }

  const fileImport = $("#fileImport");
  fileImport.addEventListener("change", () => {
    const f = fileImport.files[0];
    fileImport.value = "";
    if (f) importFile(f);
  });
  async function importFile(file) {
    let obj;
    try {
      obj = JSON.parse(await file.text());
    } catch {
      return toast(`${file.name} 不是 JSON 文件，打不开`, "error");
    }
    const kind = P.detect(obj);
    if (!kind) return toast(obj && typeof obj === "object" && obj.format !== undefined && obj.format !== P.FORMAT ? "这不是奥拉星的关卡文件" : "这不是关卡文件（没有 levels，也没有 enemies）", "error");
    const label = (obj.name && String(obj.name)) || file.name;
    if (kind === "v1") {
      const n = Array.isArray(obj.enemies) ? obj.enemies.length : 0;
      const how = await ask({
        title: "导入第 1 版关卡",
        body: [
          h("p", null, `「${label}」是第 1 版的关卡文件：${n} 个对手，没有房间。`),
          h("p", null, "可以把它变成只有一个房间的关卡：对手们组成一队站在房间里（一个接一个打），打败后右边的门通关。房间用一张简单的背景，之后可以换。"),
        ],
        buttons: [
          { label: "变成新的关卡包", value: "replace", kind: "primary" },
          { label: "加到当前包里", value: "merge" },
          { label: "取消", value: null },
        ],
      });
      if (!how) return;
      return applyImport(P.fromV1(obj), how, label);
    }
    const nl = Array.isArray(obj.levels) ? obj.levels.length : 0;
    const ni = obj.images && typeof obj.images === "object" ? Object.keys(obj.images).length : 0;
    let how = "replace";
    if (!pristine) {
      how = await ask({
        title: "导入关卡包",
        body: [h("p", null, `「${label}」：${nl} 个关卡，${ni} 张图片。`), h("p", null, "替换当前的包，还是把它的关卡和图片加到当前包里？（编号重复的会自动改名）")],
        buttons: [
          { label: "替换当前包", value: "replace", kind: "primary" },
          { label: "合并到当前包", value: "merge" },
          { label: "取消", value: null },
        ],
      });
      if (!how) return;
    }
    applyImport(obj, how, label);
  }
  function applyImport(src, how, label) {
    change(() => {
      if (how === "replace") {
        pack = P.normalize(src);
        sel = { level: 0, room: 0, obj: null };
      } else {
        const r = P.mergeInto(pack, src);
        sel = { level: Math.max(0, pack.levels.length - r.added), room: 0, obj: null };
      }
    });
    if (how === "replace") {
      pristine = true;
      sharedOk.clear();
    }
    tab = "levels";
    renderAll();
    const probs = runValidate();
    const errs = probs.filter((p) => p.severity === "error").length;
    toast(`已${how === "replace" ? "导入" : "合并"}「${label}」` + (errs ? `；有 ${errs} 个错误，点“检查”查看` : ""), errs ? "warn" : "ok", errs ? 6000 : 3500);
  }

  function download(name, text) {
    const url = URL.createObjectURL(new Blob([text], { type: "application/json" }));
    const a = h("a", { href: url, download: name });
    document.body.append(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 30000);
  }
  async function exportPack() {
    const probs = runValidate();
    const errs = probs.filter((p) => p.severity === "error");
    if (errs.length) {
      const how = await ask({
        title: "导出",
        body: [h("p", null, `检查发现 ${errs.length} 个错误，游戏可能读不了这个文件。还是要导出吗？`)].concat(problemList(probs)),
        buttons: [
          { label: "仍然导出", value: "go", kind: "danger" },
          { label: "取消", value: null, kind: "primary" },
        ],
      });
      if (how !== "go") return;
    }
    const text = P.stringify(P.serialize(pack));
    const name = P.fileName(pack.name);
    download(name, text);
    const warns = probs.length - errs.length;
    toast(`已导出 ${name}（${fmtBytes(P.utf8Length(text))}）` + (errs.length ? `，有 ${errs.length} 个错误` : "") + (warns ? `，${warns} 条提醒` : ""), errs.length ? "warn" : "ok");
  }

  // ------------------------------------------------------------------ autosave, size, names

  let saveTimer = 0;
  function scheduleAutosave() {
    clearTimeout(saveTimer);
    saveTimer = setTimeout(autosave, 800);
  }
  function autosave() {
    let text;
    try {
      text = JSON.stringify({ savedAt: Date.now(), pack: P.serialize(pack) });
    } catch {
      return;
    }
    try {
      localStorage.setItem(STORE_KEY, text);
      setSaveState(`已自动保存到这个浏览器 ${timeNow()}`);
    } catch {
      setSaveState(`包有 ${fmtBytes(text.length)}，浏览器放不下自动保存：记得导出`, true);
    }
  }
  function restore() {
    try {
      const raw = localStorage.getItem(STORE_KEY);
      if (!raw) return false;
      const s = JSON.parse(raw);
      if (!s || P.detect(s.pack) !== "v2") return false;
      pack = P.normalize(s.pack);
      const when = s.savedAt ? new Date(s.savedAt).toLocaleString("zh-CN", { hour12: false }) : "";
      setSaveState(`已恢复自动保存的包 ${when}`);
      return true;
    } catch {
      return false;
    }
  }
  let sizeTimer = 0;
  function scheduleSize() {
    clearTimeout(sizeTimer);
    sizeTimer = setTimeout(() => {
      packBytes = P.packBytes(pack);
      if (tab === "images") {
        const bar = document.getElementById("sizeBar");
        if (bar) renderImages();
      }
    }, 400);
  }

  function loadNames() {
    if (!/^https?:$/.test(location.protocol)) return; // opened from the folder: numbers alone, no error
    fetch(PETS_URL)
      .then((r) => (r.ok ? r.json() : null))
      .then((j) => {
        if (!j || typeof j !== "object") return;
        const n = {};
        for (const [k, v] of Object.entries(j)) if (v && typeof v.n === "string") n[k] = v.n;
        if (!Object.keys(n).length) return;
        names = n;
        const dl = $("#raceList");
        dl.replaceChildren(...Object.entries(n).map(([k, v]) => h("option", { value: k }, v)));
        renderInspector();
        requestDraw();
      })
      .catch(() => {});
  }

  // ------------------------------------------------------------------ wiring

  $("#packName").addEventListener("change", (e) => change(() => (pack.name = e.target.value.trim())));
  $("#packAuthor").addEventListener("change", (e) => change(() => (pack.author = e.target.value.trim())));
  $("#btnNew").addEventListener("click", newPack);
  $("#btnImport").addEventListener("click", () => fileImport.click());
  $("#btnExport").addEventListener("click", exportPack);
  $("#btnCheck").addEventListener("click", () => showProblems(runValidate()));
  $("#btnUndo").addEventListener("click", undo);
  $("#btnRedo").addEventListener("click", redo);
  for (const b of document.querySelectorAll(".tabs button"))
    b.addEventListener("click", () => {
      tab = b.dataset.tab;
      if (tab === "images") packBytes = P.packBytes(pack);
      renderAll();
    });

  document.addEventListener("keydown", (e) => {
    if (dlg.open) return;
    const t = e.target;
    const typing = t && (t.tagName === "INPUT" || t.tagName === "SELECT" || t.tagName === "TEXTAREA");
    const mod = e.ctrlKey || e.metaKey;
    if (mod && !typing && e.key.toLowerCase() === "z") {
      e.preventDefault();
      if (e.shiftKey) redo();
      else undo();
      return;
    }
    if (mod && !typing && e.key.toLowerCase() === "y") {
      e.preventDefault();
      redo();
      return;
    }
    if (typing || mod || e.altKey) return;
    if (e.key === "Delete" || e.key === "Backspace") {
      if (sel.obj) {
        e.preventDefault();
        deleteSelected();
      }
      return;
    }
    const arrows = { ArrowLeft: [-1, 0], ArrowRight: [1, 0], ArrowUp: [0, -1], ArrowDown: [0, 1] };
    if (arrows[e.key] && sel.obj) {
      e.preventDefault();
      const k = e.shiftKey ? 10 : 1;
      nudge(arrows[e.key][0] * k, arrows[e.key][1] * k);
      return;
    }
    const keys = { v: "select", d: "door", b: "wall", e: "floor", f: "fill", Escape: "select" };
    if (keys[e.key]) setTool(keys[e.key]);
    else if (e.key === "m") {
      view.mask = !view.mask;
      renderToolbar();
      requestDraw();
    }
  });

  // Files dropped on the window: a .json is imported, pictures are added.
  window.addEventListener("dragover", (e) => {
    if (e.dataTransfer && e.dataTransfer.types.includes("Files")) e.preventDefault();
  });
  window.addEventListener("drop", (e) => {
    if (!e.dataTransfer || !e.dataTransfer.files.length) return;
    e.preventDefault();
    const files = [...e.dataTransfer.files];
    const json = files.find((f) => /\.json$/i.test(f.name) || f.type === "application/json");
    if (json) importFile(json);
    else addImageFiles(files.filter((f) => f.type.startsWith("image/")));
  });

  // A restored pack may hold work: importing over it asks first.
  if (restore()) pristine = false;
  else {
    pack = starterPack();
    pristine = true;
  }
  fixSel();
  packBytes = P.packBytes(pack);
  renderAll();
  loadNames();

  // For automated checks of the page (and the curious): the current pack and its problems.
  window.aolaEditor = {
    get pack() {
      return pack;
    },
    validate: runValidate,
    serialize: () => P.serialize(pack),
    geo: () => Object.assign({}, geo),
    select: (level, room) => {
      sel = { level, room, obj: null };
      renderAll();
    },
  };
})();
