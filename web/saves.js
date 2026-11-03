// 存档: the 工具箱's 导出存档 / 导入存档 (the revival's, not of 2013), in both modes, one file
// format (server/src/game/sfs2013/saves.ts):
//   {format: "aola-revival-save", version: 1, saved, data: {<store key>: value}}
// 单机模式: the in-page emulator keeps every save in this browser's IndexedDB ("aola-revival",
// store "kv", JSON values: server/src/browser/idbStore.ts); its file holds all of them.
// 联机模式: the server keeps the saves; its file holds the one 奥拉 (/__api/save/export and
// /__api/save/import, with the password, asked in the panel). Either file goes into either mode.
// The toolbox calls aolaSaveExport / aolaSaveImport through ExternalInterface; both open a
// small panel over the game, so the file download and the file chooser start from a click on
// the page itself.
(() => {
  const DB = "aola-revival";
  const FORMAT = "aola-revival-save";

  const CSS = `
#aolaSaves { position: absolute; left: 0; top: 0; width: 960px; height: 560px; z-index: 10002;
  background: rgba(4, 22, 52, .6); font: 13px/1.6 SimSun, "宋体", "Microsoft YaHei", sans-serif; }
#aolaSaves .box { position: absolute; left: 270px; top: 150px; width: 420px; padding: 0 0 18px; border-radius: 20px;
  background: linear-gradient(#f2fbff, #c4e5f8); border: 3px solid #2e7dbe; box-shadow: 0 4px 14px rgba(0,0,0,.45); text-align: center; }
#aolaSaves h1 { margin: 0; height: 48px; line-height: 48px; color: #fff27a; font-size: 22px; letter-spacing: 3px;
  text-shadow: 0 0 3px #1a4e9c, 0 2px 0 #1a4e9c; }
#aolaSaves .close { position: absolute; right: 10px; top: 8px; width: 30px; height: 30px; border-radius: 50%;
  border: 2px solid #fff; background: linear-gradient(#ffb15a, #f0601a); color: #fff; font: bold 18px/26px Arial; cursor: pointer; }
#aolaSaves p { margin: 6px 24px; color: #1a4e7c; }
#aolaSaves button { margin: 10px 8px 0; padding: 6px 20px; border-radius: 14px; border: 2px solid #fff; cursor: pointer;
  background: linear-gradient(#ffc45a, #f07812); color: #fff; font: bold 15px "Microsoft YaHei", sans-serif; }
#aolaSaves .said { color: #8a3b00; min-height: 1.6em; }
#aolaSaves input.pass { width: 200px; margin: 6px 0 0; padding: 4px 8px; border: 2px solid #8cc8ef; border-radius: 10px; font: 14px SimSun, sans-serif; }
`;

  function db() {
    return new Promise((resolve, reject) => {
      const r = indexedDB.open(DB, 1);
      r.onupgradeneeded = () => r.result.createObjectStore("kv");
      r.onsuccess = () => resolve(r.result);
      r.onerror = () => reject(r.error);
    });
  }

  async function readAll() {
    const d = await db();
    return new Promise((resolve, reject) => {
      const out = {};
      const req = d.transaction("kv").objectStore("kv").openCursor();
      req.onsuccess = () => {
        const c = req.result;
        if (!c) return resolve(out);
        try {
          out[String(c.key)] = JSON.parse(c.value);
        } catch {
          out[String(c.key)] = c.value;
        }
        c.continue();
      };
      req.onerror = () => reject(req.error);
    });
  }

  async function writeAll(data) {
    const d = await db();
    return new Promise((resolve, reject) => {
      const t = d.transaction("kv", "readwrite");
      const s = t.objectStore("kv");
      s.clear();
      for (const [k, v] of Object.entries(data)) s.put(JSON.stringify(v), k);
      t.oncomplete = resolve;
      t.onerror = () => reject(t.error);
    });
  }

  function close() {
    document.getElementById("aolaSaves")?.remove();
  }

  /**
   * A panel: a title, a line, buttons ([label, fn(said, fields)]); opts.password adds a
   * password field (fields.pass). said is the line under the buttons, for what happened.
   */
  function panel(title, text, buttons, opts = {}) {
    close();
    if (!document.getElementById("aolaSavesCss")) {
      const st = document.createElement("style");
      st.id = "aolaSavesCss";
      st.textContent = CSS;
      document.head.appendChild(st);
    }
    const stage = document.getElementById("stage") || document.body;
    if (getComputedStyle(stage).position === "static") stage.style.position = "relative";
    const d = document.createElement("div");
    d.id = "aolaSaves";
    d.innerHTML = `<div class="box"><h1></h1><div class="close" title="关闭">×</div><p class="text"></p><div class="fields"></div><div class="buttons"></div><p class="said"></p></div>`;
    d.querySelector("h1").textContent = title;
    d.querySelector(".text").textContent = text;
    d.querySelector(".close").addEventListener("click", close);
    let pass = null;
    if (opts.password) {
      pass = document.createElement("input");
      pass.type = "password";
      pass.className = "pass";
      pass.maxLength = 32;
      pass.placeholder = "密码";
      pass.autocomplete = "current-password";
      d.querySelector(".fields").appendChild(pass);
    }
    const said = d.querySelector(".said");
    const fields = () => ({ pass: pass ? pass.value : "" });
    const setButtons = (list) => {
      const box = d.querySelector(".buttons");
      box.textContent = "";
      for (const [label, fn] of list) {
        const b = document.createElement("button");
        b.textContent = label;
        b.addEventListener("click", () => fn(said, fields()));
        box.appendChild(b);
      }
    };
    setButtons(buttons);
    // Keys typed in the panel are the panel's, not the game's.
    d.addEventListener("keydown", (e) => e.stopPropagation());
    stage.appendChild(d);
    if (pass) pass.focus();
    return { said, setButtons, text: (t) => (d.querySelector(".text").textContent = t) };
  }

  /** Save a file of this JSON (a click on the page started it). */
  function download(json, name) {
    const blob = new Blob([JSON.stringify(json, null, 1)], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 10000);
  }

  /** A file chosen by the player, as JSON (a click on the page started it). */
  function chooseFile(onFile) {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = ".json,application/json";
    input.addEventListener("change", async () => {
      const f = input.files && input.files[0];
      if (!f) return;
      let j = null;
      try {
        j = JSON.parse(await f.text());
      } catch (e) {}
      onFile(j);
    });
    input.click();
  }

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

  /** The start screen opens with this 奥拉 next time (start.js keeps its choices here). */
  function rememberName(name) {
    try {
      const k = "aolaRevivalStart";
      const o = JSON.parse(localStorage.getItem(k) || "{}") || {};
      o.name = name;
      localStorage.setItem(k, JSON.stringify(o));
    } catch (e) {}
  }

  const inPage = () => session().mode === "inpage";
  const stamp = () => new Date().toISOString().slice(0, 16).replace(/[-:]/g, "").replace("T", "-");
  // A file name of letters a browser keeps as they are (some save a Chinese one as "download").
  const fileTag = (n) => (/^[A-Za-z0-9-]+$/.test(String(n)) ? String(n) + "-" : "");

  window.aolaSaveExport = () => (inPage() ? exportHere() : exportServer());
  window.aolaSaveImport = () => (inPage() ? importHere() : importServer());

  function exportHere() {
    panel("导出存档", "把这个浏览器里的存档存成一个文件（联机模式也能导入）。", [
      [
        "保存文件",
        async (said) => {
          try {
            const data = await readAll();
            download({ format: FORMAT, version: 1, saved: new Date().toISOString(), data }, `aola-save-${stamp()}.json`);
            // One file holds every save: each role ("user/<name>") and the
            // emulator's own counter ("meta/nextUserId").
            const roles = Object.keys(data).filter((k) => k.startsWith("user/")).length;
            said.textContent = roles > 1 ? `已保存（${roles} 个角色）。` : "已保存。";
          } catch (e) {
            said.textContent = "保存失败：" + e.message;
          }
        },
      ],
    ]);
  }

  function importHere() {
    panel("导入存档", "选一个导出的存档文件（单机模式或联机模式的都可以）。它会替换这个浏览器里现在的存档，然后重新载入游戏。", [
      [
        "选择文件",
        (said) =>
          chooseFile(async (j) => {
            const bad = fileProblem(j);
            if (bad) return void (said.textContent = "导入失败：" + bad);
            // A file of no 奥拉 would leave this browser with none (the saves here are replaced).
            if (!rolesOf(j).length) return void (said.textContent = "导入失败：这个存档里没有奥拉");
            try {
              await writeAll(j.data);
              // The game starts with the file's 奥拉 (the one of a server's file; one of a page's).
              const names = rolesOf(j).map((r) => r.name);
              const now = session().name;
              if (names.length && !names.includes(now)) rememberName(names[0]);
              said.textContent = "已导入，正在重新载入……";
              setTimeout(() => location.reload(), 600);
            } catch (e) {
              said.textContent = "导入失败：" + e.message;
            }
          }),
      ],
    ]);
  }

  function exportServer() {
    const name = session().name;
    panel("导出存档", `把服务器上${name}的存档存成一个文件（单机模式也能导入）。请输入密码：`, [
      [
        "保存文件",
        async (said, f) => {
          if (!f.pass) return void (said.textContent = "请输入密码。");
          said.textContent = "正在下载……";
          const r = await api("/__api/save/export", { name, pass: f.pass });
          if (!r.ok || !r.save) return void (said.textContent = r.error || "没有导出。");
          download(r.save, `aola-save-${fileTag(name)}${stamp()}.json`);
          said.textContent = "已保存。";
        },
      ],
    ], { password: true });
  }

  async function importServer() {
    const name = session().name;
    const p = panel("导入存档", "", [], { password: true });
    const st = await api("/__api/status");
    if (st.ok && st.imports === false) {
      p.text("这个服务器关闭了导入存档。");
      return;
    }
    p.text(`选一个存档文件（单机模式或联机模式的都可以）。它会替换服务器上${name}现在的存档，然后重新载入游戏。请输入密码：`);
    const send = async (said, pass, role) => {
      said.textContent = "正在导入……";
      // The one 奥拉 only (a page's file may hold several, and the page's boards).
      const save = { format: FORMAT, version: 1, saved: new Date().toISOString(), data: { [role.key]: role.rec } };
      const r = await api("/__api/save/import", { name, pass, save });
      if (!r.ok) return void (said.textContent = "导入失败：" + (r.error || ""));
      said.textContent = "已导入，正在重新载入……";
      setTimeout(() => location.reload(), 600);
    };
    p.setButtons([
      [
        "选择文件",
        (said, f) => {
          if (!f.pass) return void (said.textContent = "请输入密码。");
          const pass = f.pass;
          chooseFile((j) => {
            const bad = fileProblem(j);
            if (bad) return void (said.textContent = "导入失败：" + bad);
            const roles = rolesOf(j);
            if (!roles.length) return void (said.textContent = "导入失败：这个存档里没有奥拉");
            if (roles.length === 1) return void send(said, pass, roles[0]);
            // A page's file of several 奥拉: which one becomes this one.
            p.text(`这个存档里有 ${roles.length} 个奥拉，选一个导入成${name}：`);
            // The password as it is in the field when one is chosen (it may have been put right).
            p.setButtons(roles.map((role) => [role.name, (s2, f2) => (f2.pass ? send(s2, f2.pass, role) : void (s2.textContent = "请输入密码。"))]));
          });
        },
      ],
    ]);
  }
})();
