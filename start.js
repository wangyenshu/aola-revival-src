// Which game and which 奥拉: 单机模式 (the game runs inside this page, the saves stay in this
// browser, up to three 奥拉 on 选择奥拉) or 联机模式 (a shared server, src/node/multi.ts or the
// Cloudflare worker: its address, the 奥拉's name and its password). The screens are the game's
// own, in its login (rebuild/src/login: StartScreen, RolesScreen), so they show in fullscreen
// too; the page keeps what they remember and does the work. The 奥拉's name is the name in the
// game, so 我的家, the 信息卡 and the other players show it.
//
// Remembered in this browser (localStorage): mode, server, 联机模式's name, the 单机 奥拉 played
// last; with 记住密码 a token the server gives for it (/__api/remember), never the password
// (a password a page of before this kept is dropped at its next 进入). Chosen without the
// screens (preset): ?bare=1 (the automated walk-throughs: 单机, the remembered name),
// ?mode=inpage, and a resume (an 奥拉 renamed or imported in the game) once, after its reload.
// ?mode=server&server=…&name=… only fills in the start screen (a password is never in an address).
//
// The login calls aolaStartPage(op, args, id), answered in its revivalStart(id, result):
//   saved                    -> what the start screen fills in, at once
//   check {server}           -> {online}: the server answers
//   register {server, name, pass}     注册: a new 联机 奥拉 (RegisterScreen)
//   rename {server, name, pass, to}   a 联机 奥拉's new name, from the start screen
//   begin {mode, server, name, pass, remember}   联机模式: the game starts (boot.js AolaBoot.begin);
//                               单机模式: only remembered (its game starts on 选择奥拉's 进入)
//   users                    -> {list: [{name, score, pets, level, createdAt, id}], last}
//   create {name}, renameRole {from, to}, delete {name}   单机模式's 奥拉
//   export {name}, exportAll -> {text, file}
//   import {text, from, as, replace} -> {roles} for a file of several 奥拉 and no from; {name}
//                               once imported; {conflict} for a name this page already has
//   chosen {name}            the 奥拉 who plays: 单机模式's game starts (AolaBoot.begin), remembered
// A failure is {error}.
(function () {
  const KEY = "aolaRevivalStart";
  const FORMAT = "aola-revival-save";
  const load = () => {
    try {
      return JSON.parse(localStorage.getItem(KEY) || "{}") || {};
    } catch (e) {
      return {};
    }
  };
  const store = (o) => {
    try {
      localStorage.setItem(KEY, JSON.stringify(o));
    } catch (e) {}
  };
  const remember = (fields) => store(Object.assign(load(), fields));

  /** "host:port", "https://host", "ws://host:8080/" -> "ws(s)://host[:port]" (no trailing /). */
  function wsBase(server) {
    let s = String(server || "").trim().replace(/\/+$/, "");
    if (!s) return "";
    if (/^https:\/\//i.test(s)) s = "wss://" + s.slice(8);
    else if (/^http:\/\//i.test(s)) s = "ws://" + s.slice(7);
    else if (!/^wss?:\/\//i.test(s)) s = (location.protocol === "https:" ? "wss://" : "ws://") + s;
    return s.replace(/\/__socket.*$/, "");
  }
  const httpBase = (server) => wsBase(server).replace(/^ws/i, "http");

  // A game the page just ended to come back to at once (an 奥拉 renamed or imported in the game:
  // saves.js): its mode, server, name and, on a shared server, password. Kept in this tab only
  // (sessionStorage) and taken at the next start, so it is there once.
  const RESUME = "aolaRevivalResume";
  function resume(o) {
    try {
      sessionStorage.setItem(RESUME, JSON.stringify(o));
    } catch (e) {}
  }
  function takeResume() {
    try {
      const v = sessionStorage.getItem(RESUME);
      sessionStorage.removeItem(RESUME);
      const o = v ? JSON.parse(v) : null;
      return o && (o.mode === "inpage" || o.mode === "server") && o.name ? o : null;
    } catch (e) {
      return null;
    }
  }

  /** The game chosen without the screens ({mode, server, name, pass}), or null. */
  function preset() {
    const q = new URLSearchParams(location.search);
    // A mod played as a game of its own: its 奥拉, no screens.
    const solo = window.AOLA_CONFIG && window.AOLA_CONFIG.standalone;
    if (solo) return { mode: "inpage", name: String(solo.player || "小奥拉"), pass: "" };
    const back = takeResume();
    if (back) return { mode: back.mode, server: back.server || "", name: back.name, pass: back.pass || "" };
    if (q.get("bare") === "1" || q.get("mode") === "inpage") return { mode: "inpage", name: q.get("name") || load().name || "小奥拉", pass: "" };
    return null;
  }

  async function postJson(url, body) {
    const r = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    return r.json();
  }

  const stamp = () => new Date().toISOString().slice(0, 16).replace(/[-:]/g, "").replace("T", "-");
  // 单机模式's game: the started one, else (选择奥拉, before 进入) the page's saves without the
  // game's sockets (entry.ts openSaves), so choosing 单机模式 and going back (返回) changes nothing.
  let savesCfg = null;
  const game = () => window.aola || (savesCfg && window.AolaEmulator && window.AolaEmulator.openSaves ? window.AolaEmulator.openSaves(savesCfg) : null);

  /** The 奥拉 of a 存档 file: [{key, name, rec}]. */
  function rolesOf(j) {
    const out = [];
    if (!j || typeof j !== "object" || !j.data || typeof j.data !== "object" || Array.isArray(j.data)) return out;
    for (const [k, v] of Object.entries(j.data)) {
      if (!k.startsWith("user/") || !v || typeof v !== "object" || Array.isArray(v)) continue;
      let name = typeof v.name === "string" ? v.name : "";
      if (!name) {
        try {
          name = decodeURIComponent(k.slice(5));
        } catch (e) {
          continue;
        }
      }
      out.push({ key: k, name, rec: v });
    }
    return out;
  }

  async function run(op, a, cfg) {
    if (op === "check") {
      const base = httpBase(a.server);
      if (!base) return { error: "请先填写服务器地址。" };
      try {
        const j = await (await fetch(base + "/__api/status")).json();
        return j.ok ? { online: j.online } : { error: "服务器没有回应。" };
      } catch (e) {
        return { error: "连不上这个服务器。" };
      }
    }
    if (op === "register") {
      const base = httpBase(a.server);
      if (!base) return { error: "请先填写服务器地址。" };
      try {
        const j = await postJson(base + "/__api/register", { name: String(a.name || "").trim(), pass: String(a.pass || "") });
        return j.ok ? { ok: true } : { error: j.error || "没有注册成。" };
      } catch (e) {
        return { error: "连不上这个服务器。" };
      }
    }
    if (op === "rename") {
      const base = httpBase(a.server);
      if (!base) return { error: "请先填写服务器地址。" };
      try {
        const j = await postJson(base + "/__api/rename", { name: a.name, pass: a.pass, to: a.to });
        if (j.ok && load().serverName === String(a.name || "").trim()) remember({ serverName: String(a.to || "").trim() });
        return j.ok ? { ok: true } : { error: j.error || "没有改成。" };
      } catch (e) {
        return { error: "连不上这个服务器。" };
      }
    }
    if (op === "begin") {
      const server = a.mode === "server";
      if (server && !wsBase(a.server)) return { error: "请填写服务器地址。" };
      if (!server) {
        // 单机模式: 选择奥拉 next, on the page's saves; the game starts on its 进入 (chosen).
        savesCfg = { date: cfg.date, verbose: !!cfg.verbose, protocol: cfg.protocol, demo: !!cfg.demo, dev: !!cfg.dev || /[?&]dev=1(&|$)/.test(location.search), standalone: !!cfg.standalone };
        remember({ mode: "inpage" });
        return { ok: true };
      }
      const address = String(a.server || "").trim(), name = String(a.name || "").trim(), pass = String(a.pass || "");
      // 记住密码: a token of the server's for this 奥拉 (it logs in as the password does), kept
      // instead of the password; the one kept already when the field still holds it. Taken off:
      // the server forgets it too.
      const s = load();
      let token = "";
      if (a.remember) {
        // The token is the 奥拉's (it goes with a rename): the field still holding it keeps it.
        if (s.token && pass === s.token) token = s.token;
        else {
          let j = null;
          try {
            j = await postJson(httpBase(address) + "/__api/remember", { name, pass });
          } catch (e) {
            return { error: "连不上这个服务器。" };
          }
          if (!j.ok || !j.token) return { error: j.error || "没有记住密码。" };
          token = j.token;
        }
      }
      if (s.token && s.token !== token) {
        postJson(httpBase(s.server || address) + "/__api/forget", { name: s.serverName || name, token: s.token }).catch(() => {});
      }
      const r = await window.AolaBoot.begin({ mode: "server", server: address, name });
      if (r.error) return r;
      const o = Object.assign(load(), { mode: "server", server: address, serverName: name, token });
      delete o.pass;
      store(o);
      return { ok: true };
    }
    // 单机模式's 奥拉 (the page's game: server/src/game/sfs2013/game.ts listUsers, createUser,
    // deleteUser, addUserFromFile, rename, exportSave), so its rules hold whatever the screen shows.
    if (!game() || !game().users) return { error: "单机模式还没有开始。" };
    if (op === "users") return { list: await game().users(), last: load().name || "" };
    if (op === "create") return { error: (await game().createUser(String(a.name || "").trim())) || "" };
    if (op === "renameRole") {
      const err = await game().rename(String(a.from), String(a.to || "").trim());
      if (!err && load().name === a.from) remember({ name: String(a.to).trim() });
      return { error: err || "" };
    }
    if (op === "delete") return { error: (await game().deleteUser(String(a.name))) || "" };
    if (op === "export") {
      const out = await game().exportSave(String(a.name));
      if (out.error || !out.save) return { error: out.error || "没有导出。" };
      return { text: JSON.stringify(out.save, null, 1), file: `aola-save-${stamp()}.json` };
    }
    if (op === "exportAll") {
      // Every 奥拉 of this browser, in one file (导入奥拉 takes them one at a time).
      const list = await game().users();
      const data = {};
      for (const r of list) {
        const out = await game().exportSave(r.name);
        if (out.save) Object.assign(data, out.save.data);
      }
      data["meta/nextUserId"] = Math.max(0, ...list.map((r) => r.id));
      return { text: JSON.stringify({ format: FORMAT, version: 1, saved: new Date().toISOString(), data }, null, 1), file: `aola-save-all-${stamp()}.json` };
    }
    if (op === "import") {
      let j = null;
      try {
        j = JSON.parse(String(a.text || "").replace(/^﻿/, ""));
      } catch (e) {}
      if (!j || j.format !== FORMAT || typeof j.version !== "number") return { error: "这不是奥拉星的存档文件。" };
      if (j.version > 1) return { error: "这个存档文件是更新的版本，这里读不了。" };
      const list = rolesOf(j);
      if (!list.length) return { error: "这个存档里没有奥拉。" };
      const from = list.length === 1 ? list[0].name : a.from;
      if (!from) return { roles: list.map((r) => r.name) };
      const r = await game().addUser(j, { from, as: a.as || undefined, replace: !!a.replace });
      if (r.name) return { name: r.name };
      if (r.conflict && !r.error) return { conflict: r.conflict, from };
      return { error: r.error || "没有导入。" };
    }
    if (op === "chosen") {
      // 进入: 单机模式's game starts now (one tab of it at a time: boot.js).
      if (!window.aola) {
        const r = await window.AolaBoot.begin({ mode: "inpage", server: "", name: "" });
        if (r.error) return r;
      }
      remember({ name: String(a.name) });
      if (window.aolaSession) window.aolaSession.name = String(a.name);
      return { ok: true };
    }
    return { error: "这个页面不能这样做。" };
  }

  /** What the start screen fills in: each mode's 奥拉, the address, the password if remembered. */
  function saved(cfg) {
    const s = load();
    // ?mode=server&server=…&name=…: that server and name written in (no password).
    const q = new URLSearchParams(location.search);
    if (q.get("mode") === "server") return { mode: "server", server: q.get("server") || s.server || cfg.server || "", serverName: q.get("name") || "", pass: "" };
    return {
      mode: s.mode === "server" ? "server" : "inpage",
      // The address last written, else the site's own (config.js server: a site made for one
      // shared server fills it in).
      server: s.server || cfg.server || "",
      // Older pages kept one name for both modes.
      serverName: s.serverName ?? (s.mode === "server" ? s.name || "" : ""),
      // 记住密码's token (a page of before kept the password: it is used once, then a token).
      pass: s.token || s.pass || "",
    };
  }

  function install(cfg) {
    window.aolaStartPage = (op, args, id) => {
      if (op === "saved") return saved(cfg);
      run(String(op), args || {}, cfg)
        .catch((e) => ({ error: String((e && e.message) || e) }))
        // Later: the call came from inside the game, which cannot be called back into then.
        .then((r) =>
          setTimeout(() => {
            try {
              window.aolaPlayer.revivalStart(String(id), r);
            } catch (e) {
              console.warn("[start]", e);
            }
          }, 0),
        );
      return true;
    };
  }

  window.AolaStart = { preset, install, wsBase, resume };
})();
