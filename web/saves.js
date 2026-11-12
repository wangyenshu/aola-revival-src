// 存档 and the 奥拉's name and password, for both modes. The panels are the game's own
// (rebuild/src/shared/mmo/revival/SavePanels.as: the 工具箱's 导出存档 / 导入存档, the 信息卡's
// 改名字 and 改密码), so they show in fullscreen too, and the game's file dialogs save and open
// the files; the data is the page's. The game calls aolaSaves(op, args, id) and is answered in
// its revivalSaves(id, result):
//   session              -> {mode, name}, at once
//   status               -> {imports}: whether 联机模式's server takes files
//   export {pass}        -> {text, file}: the file (server/src/game/sfs2013/saves.ts, the same in
//                           both modes) and its name
//   import {text, pass, role} -> {roles: [{key, name}]} for a file of several 奥拉 and no role;
//                           else {ok}, and the game ends: the page comes back to it
//   rename {to, pass}    -> {ok}, and the page comes back to the new name
//   password {pass, to}  -> {ok}
// A failure is {error}. 单机模式 asks the page's own game (window.aola: server/src/browser/entry.ts);
// 联机模式 the server's API (/__api/…, with the password). 单机模式's other 奥拉 are on the
// 选择奥拉 screen (web/start.js).
(() => {
  const FORMAT = "aola-revival-save";
  const NO_PAGE = "这个页面不能这样做。";

  /** Why a file is not a 存档 file (either mode's), or "". */
  function fileProblem(j) {
    if (!j || typeof j !== "object" || j.format !== FORMAT || !j.data || typeof j.data !== "object" || Array.isArray(j.data)) return "这不是奥拉星的存档文件";
    if (typeof j.version !== "number" || j.version > 1) return "这个存档文件是更新的版本，这里读不了";
    return "";
  }

  /** The 奥拉 of a file: [{key, name, rec}] (its "user/…" keys). */
  function rolesOf(j) {
    const out = [];
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

  /** The game of this page: its mode, its 奥拉, its server's address (boot.js). */
  const session = () =>
    window.aolaSession || { mode: Object.assign({}, window.AOLA_CONFIG, window.AOLA_CONFIG_OVERRIDE || {}).mode || "inpage", name: "", server: "" };

  /** A request to the server's API: its JSON answer ({ok: false, error} when it cannot be had). */
  async function api(path, body) {
    try {
      const r = await fetch(session().server + path, {
        method: body ? "POST" : "GET",
        headers: body ? { "Content-Type": "application/json" } : {},
        body: body ? JSON.stringify(body) : undefined,
      });
      if (r.status === 413) return { ok: false, error: "这个存档太大了。" };
      return await r.json();
    } catch (e) {
      return { ok: false, error: "连不上服务器。" };
    }
  }

  const inPage = () => session().mode === "inpage";
  const stamp = () => new Date().toISOString().slice(0, 16).replace(/[-:]/g, "").replace("T", "-");
  // A file name of letters a browser keeps as they are (some save a Chinese one as "download").
  const fileTag = (n) => (/^[A-Za-z0-9-]+$/.test(String(n)) ? String(n) + "-" : "");

  /** The page comes back to this 奥拉 after its reload (start.js resume), and remembers it. */
  function comeBack(name, pass) {
    const s = session();
    if (window.AolaStart && window.AolaStart.resume) window.AolaStart.resume({ mode: s.mode, server: s.server, name, pass: pass || "" });
    try {
      const k = "aolaRevivalStart";
      const o = JSON.parse(localStorage.getItem(k) || "{}") || {};
      if (s.mode === "inpage") o.name = name;
      else o.serverName = name;
      localStorage.setItem(k, JSON.stringify(o));
    } catch (e) {}
    setTimeout(() => location.reload(), 600);
  }

  const fileName = (name) => `aola-save-${fileTag(name)}${stamp()}.json`;

  async function run(op, a) {
    const name = session().name;
    if (op === "status") {
      if (inPage()) return { imports: true };
      const st = await api("/__api/status");
      return { imports: !(st.ok && st.imports === false) };
    }
    if (op === "export") {
      let r;
      if (inPage()) r = window.aola && window.aola.exportSave ? await window.aola.exportSave(name) : { error: NO_PAGE };
      else if (!a.pass) return { error: "请输入密码。" };
      else r = await api("/__api/save/export", { name, pass: a.pass });
      if (r.error || !r.save) return { error: r.error || "没有导出。" };
      return { text: JSON.stringify(r.save, null, 1), file: fileName(name) };
    }
    if (op === "import") {
      let j = null;
      try {
        j = JSON.parse(String(a.text || "").replace(/^\uFEFF/, ""));
      } catch (e) {}
      const bad = fileProblem(j);
      if (bad) return { error: bad };
      const roles = rolesOf(j);
      if (!roles.length) return { error: "这个存档里没有奥拉" };
      const role = roles.length === 1 ? roles[0] : roles.find((r) => r.key === a.role);
      if (!role) return { roles: roles.map((r) => ({ key: r.key, name: r.name })) };
      // The one 奥拉 only (a page's file may hold several, and the page's boards).
      const save = { format: FORMAT, version: 1, saved: new Date().toISOString(), data: { [role.key]: role.rec } };
      if (inPage()) {
        const r = window.aola && window.aola.importSave ? await window.aola.importSave(name, save) : { error: NO_PAGE };
        if (r.error) return { error: r.error };
        comeBack(name);
        return { ok: true };
      }
      if (!a.pass) return { error: "请输入密码。" };
      const r = await api("/__api/save/import", { name, pass: a.pass, save });
      if (!r.ok) return { error: r.error || "没有导入。" };
      comeBack(name, a.pass);
      return { ok: true };
    }
    if (op === "rename") {
      const to = String(a.to || "").trim();
      if (!to) return { error: "请输入新名字。" };
      let err;
      if (!inPage()) {
        if (!a.pass) return { error: "请输入密码。" };
        const r = await api("/__api/rename", { name, pass: a.pass, to, now: true });
        err = r.ok ? null : r.error || "没有改成。";
      } else {
        err = window.aola && window.aola.rename ? await window.aola.rename(name, to, true) : NO_PAGE;
      }
      if (err) return { error: err };
      comeBack(to, inPage() ? "" : a.pass);
      return { ok: true };
    }
    if (op === "password") {
      if (inPage()) return { error: "单机模式的奥拉没有密码。" };
      const r = await api("/__api/password", { name, pass: a.pass, to: a.to });
      if (!r.ok) return { error: r.error || "没有改成。" };
      // 记住密码: the new password ended the server's tokens; a page that kept one asks for a new
      // one (a page of before kept the password itself: it goes).
      try {
        const k = "aolaRevivalStart";
        const o = JSON.parse(localStorage.getItem(k) || "{}") || {};
        const had = !!(o.token || o.pass);
        delete o.pass;
        delete o.token;
        if (had) {
          const t = await api("/__api/remember", { name, pass: a.to });
          if (t.ok && t.token) o.token = t.token;
        }
        localStorage.setItem(k, JSON.stringify(o));
      } catch (e) {}
      return { ok: true };
    }
    return { error: NO_PAGE };
  }

  window.aolaSaves = (op, args, id) => {
    if (op === "session") {
      const s = session();
      return { mode: s.mode, name: s.name };
    }
    run(String(op), args || {})
      .catch((e) => ({ error: String((e && e.message) || e) }))
      // Later: the call came from inside the game, which cannot be called back into then.
      .then((r) =>
        setTimeout(() => {
          try {
            window.aolaPlayer.revivalSaves(String(id), r);
          } catch (e) {
            console.warn("[saves]", e);
          }
        }, 0),
      );
    return true;
  };
})();
