// 存档 and the 奥拉's name and password, in the game, for both modes:
// - the 工具箱's 导出存档 / 导入存档 (the revival's, not of 2013) on the 奥拉 that plays: its file
//   (server/src/game/sfs2013/saves.ts, the same in both modes), and a file's 奥拉 (either mode's;
//   a file of several asks which) over its game, which ends: the page comes back to it;
// - the 信息卡's 改名字 (both) and 改密码 (联机模式): aolaAccountRename, aolaAccountPassword.
// 单机模式 asks the page's own game (window.aola: server/src/browser/entry.ts); 联机模式 the
// server's API (/__api/…, with the password, asked in the panel). Its other 奥拉 the page keeps
// on the 选择奥拉 screen (accounts.js). The toolbox and the 信息卡 call these through
// ExternalInterface; each opens a small panel over the game, so a file's download or choice
// starts from a click on the page itself. No browser dialogs.
(() => {
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
#aolaSaves input.pass { display: block; width: 200px; margin: 2px auto 0; padding: 4px 8px; border: 2px solid #8cc8ef; border-radius: 10px; font: 14px SimSun, sans-serif; }
#aolaSaves label.field { display: block; margin: 6px auto 0; width: 220px; text-align: left; color: #1a4e7c; font-size: 12px; }
`;

  function close() {
    document.getElementById("aolaSaves")?.remove();
  }

  /**
   * A panel: a title, a line, buttons ([label, fn(said, fields)]); opts.password adds a
   * password field (fields.pass), opts.inputs others ([{key, type, placeholder, maxLength}]:
   * fields[key]). said is the line under the buttons, for what happened. Enter in the last
   * field is the first button.
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
    const specs = [...(opts.inputs || []), ...(opts.password ? [{ key: "pass", type: "password", label: "密码", maxLength: 32 }] : [])];
    const inputs = {};
    for (const f of specs) {
      const i = document.createElement("input");
      i.type = f.type || "text";
      i.className = "pass";
      i.maxLength = f.maxLength || 32;
      // The label says what goes in (a placeholder too would say it twice).
      i.placeholder = f.label ? f.placeholder || "" : "";
      if (f.value) i.value = f.value;
      if (i.type === "password") i.autocomplete = f.key === "pass" ? "current-password" : "new-password";
      // A label over each field (a placeholder goes once something is typed).
      const row = document.createElement("label");
      row.className = "field";
      row.textContent = f.label || f.placeholder || "";
      row.appendChild(i);
      d.querySelector(".fields").appendChild(row);
      inputs[f.key] = i;
    }
    const said = d.querySelector(".said");
    const fields = () => Object.fromEntries(Object.entries({ pass: null, ...inputs }).map(([k, i]) => [k, i ? i.value : ""]));
    let first = null;
    const setButtons = (list) => {
      const box = d.querySelector(".buttons");
      box.textContent = "";
      first = null;
      for (const [label, fn] of list) {
        const b = document.createElement("button");
        b.textContent = label;
        b.addEventListener("click", () => fn(said, fields()));
        box.appendChild(b);
        first = first || b;
      }
    };
    setButtons(buttons);
    // Keys typed in the panel are the panel's, not the game's.
    d.addEventListener("keydown", (e) => {
      e.stopPropagation();
      if (e.key === "Enter" && e.target.tagName === "INPUT" && first) first.click();
      if (e.key === "Escape") close();
    });
    stage.appendChild(d);
    const firstInput = Object.values(inputs)[0];
    if (firstInput) firstInput.focus();
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

  const inPage = () => session().mode === "inpage";
  const stamp = () => new Date().toISOString().slice(0, 16).replace(/[-:]/g, "").replace("T", "-");
  // A file name of letters a browser keeps as they are (some save a Chinese one as "download").
  const fileTag = (n) => (/^[A-Za-z0-9-]+$/.test(String(n)) ? String(n) + "-" : "");

  window.aolaSaveExport = () => (inPage() ? exportHere() : exportServer());
  window.aolaSaveImport = () => (inPage() ? importHere() : importServer());

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

  function exportHere() {
    const name = session().name;
    panel("导出存档", "", [
      [
        "保存文件",
        async (said) => {
          const r = window.aola && window.aola.exportSave ? await window.aola.exportSave(name) : { error: "这个页面不能导出存档。" };
          if (r.error || !r.save) return void (said.textContent = r.error || "没有导出。");
          download(r.save, `aola-save-${fileTag(name)}${stamp()}.json`);
          said.textContent = "已保存。";
        },
      ],
    ]);
  }

  function importHere() {
    const name = session().name;
    const p = panel("导入存档", `导入的存档会替换${name}现在的存档。`, []);
    const send = async (said, role) => {
      said.textContent = "正在导入……";
      const save = { format: FORMAT, version: 1, saved: new Date().toISOString(), data: { [role.key]: role.rec } };
      const r = window.aola && window.aola.importSave ? await window.aola.importSave(name, save) : { error: "这个页面不能导入存档。" };
      if (r.error) return void (said.textContent = "导入失败：" + r.error);
      said.textContent = "正在重新进入……";
      comeBack(name);
    };
    p.setButtons([["选择文件", (said) => pickRole(p, said, name, (s2, role) => send(s2, role))]]);
  }

  /**
   * A file chosen, one of its 奥拉 to become this one: then(said, role) (a file of several asks which,
   * with the fields as they are when one is chosen).
   */
  function pickRole(p, said, name, then) {
    chooseFile((j) => {
      const bad = fileProblem(j);
      if (bad) return void (said.textContent = "导入失败：" + bad);
      const roles = rolesOf(j);
      if (!roles.length) return void (said.textContent = "导入失败：这个存档里没有奥拉");
      if (roles.length === 1) return void then(said, roles[0], null);
      p.text("选一个奥拉：");
      p.setButtons(roles.map((role) => [role.name, (s2, f2) => then(s2, role, f2)]));
    });
  }

  function exportServer() {
    const name = session().name;
    panel("导出存档", "", [
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
    p.text(`导入的存档会替换${name}现在的存档。`);
    const send = async (said, pass, role) => {
      said.textContent = "正在导入……";
      // The one 奥拉 only (a page's file may hold several, and the page's boards).
      const save = { format: FORMAT, version: 1, saved: new Date().toISOString(), data: { [role.key]: role.rec } };
      const r = await api("/__api/save/import", { name, pass, save });
      if (!r.ok) return void (said.textContent = "导入失败：" + (r.error || ""));
      said.textContent = "正在重新进入……";
      comeBack(name, pass);
    };
    p.setButtons([
      [
        "选择文件",
        (said, f) => {
          if (!f.pass) return void (said.textContent = "请输入密码。");
          // The password as it is in the field when the 奥拉 is chosen (it may have been put right).
          pickRole(p, said, name, (s2, role, f2) => {
            const pass = f2 ? f2.pass : f.pass;
            if (!pass) return void (s2.textContent = "请输入密码。");
            send(s2, pass, role);
          });
        },
      ],
    ]);
  }

  // ---------------------------------------------------------------- the 信息卡's 改名字 / 改密码

  window.aolaAccountRename = () => {
    const s = session();
    const server = !inPage();
    panel(
      "改名字",
      "",
      [
        [
          "确定",
          async (said, f) => {
            const to = String(f.to || "").trim();
            if (!to) return void (said.textContent = "请输入新名字。");
            if (to === s.name) return close();
            if (server && !f.pass) return void (said.textContent = "请输入密码。");
            said.textContent = "正在改名……";
            let err = null;
            if (server) {
              const r = await api("/__api/rename", { name: s.name, pass: f.pass, to, now: true });
              err = r.ok ? null : r.error || "没有改成。";
            } else {
              err = window.aola && window.aola.rename ? await window.aola.rename(s.name, to, true) : "这个页面不能改名字。";
            }
            if (err) return void (said.textContent = err);
            said.textContent = "正在重新进入……";
            comeBack(to, server ? f.pass : "");
          },
        ],
      ],
      { inputs: [{ key: "to", label: "新名字", maxLength: 12 }], password: server },
    );
  };

  window.aolaAccountPassword = () => {
    const s = session();
    if (inPage()) return void panel("改密码", "单机模式的奥拉没有密码。", []);
    panel(
      "改密码",
      "",
      [
        [
          "确定",
          async (said, f) => {
            if (!f.pass) return void (said.textContent = "请输入现在的密码。");
            if (!f.to) return void (said.textContent = "请输入新密码。");
            if (f.to !== f.again) return void (said.textContent = "两次输入的新密码不一样。");
            said.textContent = "正在改……";
            const r = await api("/__api/password", { name: s.name, pass: f.pass, to: f.to });
            if (!r.ok) return void (said.textContent = r.error || "没有改成。");
            // A remembered password (记住密码) is the new one now.
            try {
              const k = "aolaRevivalStart";
              const o = JSON.parse(localStorage.getItem(k) || "{}") || {};
              if (o.pass) o.pass = f.to;
              localStorage.setItem(k, JSON.stringify(o));
            } catch (e) {}
            said.textContent = "改好了。";
          },
        ],
      ],
      {
        inputs: [
          { key: "pass", type: "password", label: "现在的密码", maxLength: 32 },
          { key: "to", type: "password", label: "新密码", maxLength: 32 },
          { key: "again", type: "password", label: "再输一次新密码", maxLength: 32 },
        ],
      },
    );
  };

})();
