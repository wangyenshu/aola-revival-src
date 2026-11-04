// The start screen, before the game: 单机模式 (the game runs inside this page, the saves stay
// in this browser; its 奥拉 are chosen after 开始, accounts.js 选择奥拉) or 联机模式 (a shared
// server, src/node/multi.ts or the Cloudflare worker: its address, the 奥拉's name and its
// password). The 奥拉's name is the name in the game (the rebuilt login asks the page for it:
// aolaRevivalAccount), so 我的家, the 信息卡 and the other players show it; 改名字 changes it
// (one's save moves with it).
//
// Remembered in this browser (localStorage): mode, server, 联机模式's name, the 单机 奥拉 played
// last; the password only with 记住密码. Skipped (single, the remembered name) with ?bare=1 (the
// automated walk-throughs); ?mode=server&server=…&name=…&pass=… chooses from the address
// (tests); a resume (an 奥拉 renamed or imported in the game) once, after its reload.
(function () {
  const KEY = "aolaRevivalStart";
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

  function css() {
    const st = document.createElement("style");
    st.textContent = `
      #aolaStart { position: absolute; inset: 0; z-index: 5; display: flex; align-items: center; justify-content: center;
        background: radial-gradient(circle at 50% 35%, #3a9be8, #0b3f86 70%, #072a5e); font: 14px/1.6 SimSun, "宋体", "Microsoft YaHei", sans-serif; color: #12406f; }
      #aolaStart .box { width: 420px; background: #f2fbff; border: 3px solid #7fd0ff; border-radius: 18px; box-shadow: 0 6px 24px rgba(0,0,0,.35); padding: 18px 26px 20px; }
      #aolaStart h1 { margin: 0 0 12px; text-align: center; font-size: 22px; color: #0e5fb4; letter-spacing: 4px; }
      #aolaStart .modes { display: flex; gap: 10px; margin-bottom: 12px; }
      #aolaStart .modes button { flex: 1; padding: 8px 0; border-radius: 12px; border: 2px solid #8cc8ef; background: #dff1fd; color: #2a628f; font: bold 15px SimSun, sans-serif; cursor: pointer; }
      #aolaStart .modes button.on { background: linear-gradient(#ffd56a, #f39a1e); border-color: #e07a12; color: #fff; text-shadow: 0 1px 1px #a45300; }
      #aolaStart .hint { font-size: 12px; color: #5a7fa3; margin: -4px 0 10px; min-height: 18px; }
      #aolaStart label { display: block; margin: 6px 0 2px; font-weight: bold; }
      #aolaStart input[type=text], #aolaStart input[type=password] { width: 100%; box-sizing: border-box; padding: 6px 8px; border: 1px solid #8cc8ef; border-radius: 8px; font: 14px SimSun, sans-serif; background: #fff; }
      #aolaStart .row { display: flex; align-items: center; gap: 8px; margin-top: 6px; font-size: 12px; }
      #aolaStart .go { display: block; width: 100%; margin-top: 14px; padding: 9px 0; border: 0; border-radius: 14px; background: linear-gradient(#ffd56a, #f08a12); color: #fff; font: bold 18px SimSun, sans-serif; letter-spacing: 6px; cursor: pointer; text-shadow: 0 1px 1px #a45300; }
      #aolaStart .link { background: none; border: 0; color: #1d6fc1; text-decoration: underline; cursor: pointer; font: 12px SimSun, sans-serif; padding: 0; }
      #aolaStart .msg { margin-top: 8px; min-height: 18px; color: #c8401a; font-size: 12px; }
      #aolaStart .msg.ok { color: #2a8a2a; }
      #aolaStart .hidden { display: none; }`;
    document.head.appendChild(st);
  }

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

  function choose(cfg) {
    const q = new URLSearchParams(location.search);
    const saved = load();
    const back = takeResume();
    if (back) return Promise.resolve({ mode: back.mode, server: back.server || "", name: back.name, pass: back.pass || "" });
    if (q.get("mode") === "server" && q.get("server") && q.get("name"))
      return Promise.resolve({ mode: "server", server: q.get("server"), name: q.get("name"), pass: q.get("pass") || "" });
    if (q.get("bare") === "1" || q.get("mode") === "inpage")
      return Promise.resolve({ mode: "inpage", name: q.get("name") || saved.name || "小奥拉", pass: "" });
    return new Promise((resolve) => {
      css();
      const el = document.createElement("div");
      el.id = "aolaStart";
      el.innerHTML = `
        <div class="box">
          <h1>进入奥拉星</h1>
          <div class="modes"><button data-mode="inpage">单机模式</button><button data-mode="server">联机模式</button></div>
          <div class="hint" id="asHint"></div>
          <div id="asServerRow"><label for="asServer">服务器地址</label><input type="text" id="asServer"></div>
          <div id="asNameRow"><label for="asName">奥拉的名字</label><input type="text" id="asName" maxlength="12"></div>
          <div id="asPassRow"><label for="asPass">密码</label><input type="password" id="asPass" maxlength="32">
            <div class="row"><input type="checkbox" id="asRemember"><label for="asRemember" style="display:inline;font-weight:normal;margin:0">记住密码</label>
              <span style="flex:1"></span><button class="link" id="asCheck">检查服务器</button></div></div>
          <div class="row" id="asRenameLinkRow"><button class="link" id="asRenameLink">改名字</button></div>
          <div id="asRenameRow" class="hidden"><label for="asNewName">新名字</label><input type="text" id="asNewName" maxlength="12">
            <div class="row"><button class="link" id="asRenameGo">确定改名</button><span style="flex:1"></span><button class="link" id="asRenameCancel">取消</button></div></div>
          <div class="msg" id="asMsg"></div>
          <button class="go" id="asGo">进入</button>
        </div>`;
      document.getElementById("stage").appendChild(el);
      const $ = (id) => document.getElementById(id);
      let mode = saved.mode === "server" ? "server" : "inpage";
      // Each mode's 奥拉: 单机模式's starts as 小奥拉; 联机模式's address, name and password start
      // empty (what one wrote there before, when remembered). Older pages kept one name for both.
      const names = {
        inpage: saved.name || "小奥拉",
        server: saved.serverName ?? (saved.mode === "server" ? saved.name || "" : ""),
      };
      // The address last written, else the site's own (config.js server: a site made for one
      // shared server fills it in).
      $("asServer").value = saved.server || cfg.server || "";
      $("asName").value = names[mode];
      $("asPass").value = saved.pass || "";
      $("asRemember").checked = !!saved.pass;
      const msg = (t, ok) => {
        $("asMsg").textContent = t || "";
        $("asMsg").className = "msg" + (ok ? " ok" : "");
      };
      const show = () => {
        for (const b of el.querySelectorAll(".modes button")) b.classList.toggle("on", b.dataset.mode === mode);
        $("asServerRow").classList.toggle("hidden", mode !== "server");
        $("asPassRow").classList.toggle("hidden", mode !== "server");
        // 单机模式's 奥拉 are chosen after 开始 (accounts.js 选择奥拉): here only the mode.
        $("asNameRow").classList.toggle("hidden", mode !== "server");
        $("asRenameLinkRow").classList.toggle("hidden", mode !== "server");
        if (mode !== "server") $("asRenameRow").classList.add("hidden");
        $("asHint").textContent = mode === "server"
          ? "和别的奥拉一起玩：存档在服务器上。第一次用这个名字登录，就会用这个密码注册。"
          : "一个人玩：游戏在这个页面里运行，存档留在这个浏览器里。";
        msg("");
      };
      for (const b of el.querySelectorAll(".modes button")) {
        b.onclick = () => {
          if (b.dataset.mode === mode) return;
          names[mode] = $("asName").value;
          mode = b.dataset.mode;
          $("asName").value = names[mode];
          show();
        };
      }
      show();
      $("asCheck").onclick = async () => {
        const base = httpBase($("asServer").value);
        if (!base) return msg("请先填写服务器地址。");
        msg("正在连接服务器……", true);
        try {
          const r = await fetch(base + "/__api/status");
          const j = await r.json();
          msg(j.ok ? `服务器正常，现在有 ${j.online} 个奥拉在线。` : "服务器没有回应。", !!j.ok);
        } catch (e) {
          msg("连不上这个服务器。");
        }
      };
      $("asRenameLink").onclick = () => { $("asRenameRow").classList.remove("hidden"); $("asNewName").focus(); };
      $("asRenameCancel").onclick = () => $("asRenameRow").classList.add("hidden");
      $("asRenameGo").onclick = async () => {
        const from = $("asName").value.trim(), to = $("asNewName").value.trim();
        if (!to) return msg("请输入新名字。");
        const base = httpBase($("asServer").value);
        if (!base) return msg("请先填写服务器地址。");
        try {
          const r = await fetch(base + "/__api/rename", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: from, pass: $("asPass").value, to }) });
          const j = await r.json();
          if (!j.ok) return msg(j.error || "没有改成。");
          $("asName").value = to;
          $("asRenameRow").classList.add("hidden");
          msg("名字改好了！", true);
        } catch (e) {
          msg("连不上这个服务器。");
        }
      };
      function finish() {
        // 单机模式: no name here (the 选择奥拉 screen after 开始 asks).
        const name = mode === "server" ? $("asName").value.trim() : "";
        const out = { mode, server: $("asServer").value.trim(), name, pass: mode === "server" ? $("asPass").value : "" };
        if (mode === "server") names.server = name;
        store({
          mode,
          server: out.server,
          name: String(names.inpage).trim() || "小奥拉",
          serverName: String(names.server).trim(),
          pass: mode === "server" && $("asRemember").checked ? out.pass : "",
        });
        resolve(out);
      }
      $("asGo").onclick = () => {
        if (mode === "server" && !wsBase($("asServer").value)) return msg("请填写服务器地址。");
        if (mode === "server" && !$("asPass").value) return msg("请输入密码。");
        if (mode === "server" && !$("asName").value.trim()) return msg("请输入奥拉的名字。");
        // The fields are read before the screen goes (once it is gone, they are not found).
        finish();
        el.remove();
      };
      el.addEventListener("keydown", (e) => { if (e.key === "Enter" && e.target.tagName === "INPUT" && e.target.id !== "asNewName") $("asGo").click(); });
    });
  }

  window.AolaStart = { choose, wsBase, resume };
})();
