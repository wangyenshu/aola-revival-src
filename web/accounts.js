// 选择奥拉: 单机模式's own 奥拉, after 开始 (the rebuilt login asks the page who plays: boot.js
// aolaRevivalAccount, and waits while this screen is up). Up to three 奥拉 a browser, one a
// name: 进入, 新建, 改名, 导出, 删除, and 导入 (a 存档 file of either mode: a file of several asks
// which; a name this page already has asks whether to replace that 奥拉 or to take the file's
// under another name). The game in the page does the work (server/src/game/sfs2013/game.ts:
// listUsers, createUser, deleteUser, addUserFromFile; rename and exportSave), so its rules hold
// whatever the page shows. No browser dialogs: every question is asked in the screen.
(() => {
  const MAX = 3;
  const FORMAT = "aola-revival-save";
  const START_KEY = "aolaRevivalStart";

  const CSS = `
#aolaRoles { position: absolute; left: 0; top: 0; width: 960px; height: 560px; z-index: 10003;
  background: radial-gradient(circle at 50% 30%, #3a9be8, #0b3f86 72%, #072a5e);
  font: 14px/1.5 SimSun, "宋体", "Microsoft YaHei", sans-serif; color: #12406f; user-select: none; }
#aolaRoles h1 { margin: 30px 0 24px; text-align: center; color: #fff27a; font-size: 30px; letter-spacing: 6px;
  text-shadow: 0 0 4px #1a4e9c, 0 3px 0 #1a4e9c; }
#aolaRoles .cards { display: flex; justify-content: center; gap: 22px; }
#aolaRoles .card { position: relative; width: 250px; height: 312px; box-sizing: border-box; padding: 18px 16px 14px;
  border-radius: 22px; background: linear-gradient(#f4fbff, #c8e7fa); border: 3px solid #8cc8ef;
  box-shadow: 0 4px 12px rgba(0,0,0,.35); display: flex; flex-direction: column; align-items: center; }
#aolaRoles .card.last { border-color: #f6a623; }
#aolaRoles .card.empty { background: rgba(232, 246, 255, .55); border-style: dashed; border-color: #cfe9fb; }
#aolaRoles .badge { position: absolute; top: -12px; left: 50%; transform: translateX(-50%); padding: 1px 12px;
  border-radius: 10px; background: #f39a1e; color: #fff; font-size: 12px; white-space: nowrap; }
#aolaRoles .face { width: 84px; height: 84px; border-radius: 50%; margin: 4px 0 8px; display: flex; align-items: center;
  justify-content: center; font: bold 40px "Microsoft YaHei", sans-serif; color: #fff;
  background: radial-gradient(circle at 40% 35%, #8fd8ff, #2e86d6); border: 3px solid #fff; box-shadow: 0 2px 6px rgba(0,0,0,.25); }
#aolaRoles .card.empty .face { background: rgba(255,255,255,.6); color: #8cc8ef; }
#aolaRoles .name { font: bold 19px "Microsoft YaHei", sans-serif; color: #1a5fa8; max-width: 216px; overflow: hidden;
  text-overflow: ellipsis; white-space: nowrap; }
#aolaRoles .facts { color: #335577; font-size: 13px; text-align: center; margin: 4px 0 0; min-height: 60px; }
#aolaRoles .grow { flex: 1; }
#aolaRoles button { cursor: pointer; font-family: "Microsoft YaHei", sans-serif; }
#aolaRoles .go { width: 180px; padding: 6px 0; border-radius: 16px; border: 2px solid #fff; color: #fff; font-size: 18px; font-weight: bold;
  background: linear-gradient(#ffd56a, #f0840e); text-shadow: 0 1px 1px #a45300; box-shadow: 0 2px 4px rgba(0,0,0,.25); }
#aolaRoles .go.blue { background: linear-gradient(#8fe3ff, #1e8fe0); text-shadow: 0 1px 1px #0d5a9c; }
#aolaRoles .go.red { background: linear-gradient(#ff9a80, #d9452b); text-shadow: 0 1px 1px #8a2410; }
#aolaRoles .go.small { width: auto; padding: 4px 16px; font-size: 14px; margin: 0 4px; }
#aolaRoles .links { margin-top: 8px; display: flex; gap: 14px; }
#aolaRoles .link { border: 0; background: none; color: #2a628f; text-decoration: underline; font-size: 13px; padding: 0; }
#aolaRoles .link.red { color: #b3361c; }
#aolaRoles input { width: 196px; box-sizing: border-box; padding: 6px 10px; margin: 6px 0 8px; border: 2px solid #8cc8ef; border-radius: 10px;
  font: 15px SimSun, sans-serif; text-align: center; }
#aolaRoles .ask { font-size: 13px; color: #1a4e7c; text-align: center; margin: 6px 0; }
#aolaRoles .warn { color: #b3361c; }
#aolaRoles .bar { position: absolute; left: 0; right: 0; bottom: 18px; text-align: center; }
#aolaRoles .msg { min-height: 22px; margin-bottom: 8px; color: #fff; text-shadow: 0 1px 2px #072a5e; }
#aolaRoles .msg.bad { color: #ffd0c4; }
#aolaRoles .sheet { position: absolute; inset: 0; background: rgba(4, 22, 52, .55); display: flex; align-items: center; justify-content: center; }
#aolaRoles .sheet .card { height: auto; width: 360px; }
`;

  const el = (tag, cls, text) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  };
  const button = (label, cls, fn) => {
    const b = el("button", cls, label);
    b.type = "button";
    b.addEventListener("click", (e) => {
      e.stopPropagation();
      fn();
    });
    return b;
  };
  const input = (value, placeholder, onEnter, onEsc) => {
    const i = el("input");
    i.type = "text";
    i.maxLength = 12;
    i.value = value || "";
    i.placeholder = placeholder || "";
    i.addEventListener("keydown", (e) => {
      e.stopPropagation();
      if (e.key === "Enter") onEnter();
      if (e.key === "Escape" && onEsc) onEsc();
    });
    return i;
  };

  const lastPlayed = () => {
    try {
      return (JSON.parse(localStorage.getItem(START_KEY) || "{}") || {}).name || "";
    } catch (e) {
      return "";
    }
  };
  const rememberPlayed = (name) => {
    try {
      const o = JSON.parse(localStorage.getItem(START_KEY) || "{}") || {};
      o.name = name;
      localStorage.setItem(START_KEY, JSON.stringify(o));
    } catch (e) {}
  };
  const stamp = () => new Date().toISOString().slice(0, 16).replace(/[-:]/g, "").replace("T", "-");
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
  function chooseFile(onFile) {
    const f = document.createElement("input");
    f.type = "file";
    f.accept = ".json,application/json";
    f.addEventListener("change", async () => {
      const file = f.files && f.files[0];
      if (!file) return;
      let j = null;
      try {
        j = JSON.parse(await file.text());
      } catch (e) {}
      onFile(j);
    });
    f.click();
  }
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
  const day = (iso) => (iso ? String(iso).slice(0, 10) : "");

  let open = false;

  /**
   * Show the screen over the game; done(name) once an 奥拉 is chosen (进入). game: the page's game
   * (window.aola: users, createUser, rename, deleteUser, exportSave, addUser).
   */
  function show(game, done) {
    if (open) return;
    open = true;
    if (!document.getElementById("aolaRolesCss")) {
      const st = el("style");
      st.id = "aolaRolesCss";
      st.textContent = CSS;
      document.head.appendChild(st);
    }
    const stage = document.getElementById("stage") || document.body;
    if (getComputedStyle(stage).position === "static") stage.style.position = "relative";
    const root = el("div");
    root.id = "aolaRoles";
    // Keys typed here are the screen's, not the game's.
    root.addEventListener("keydown", (e) => e.stopPropagation());
    stage.appendChild(root);

    let roles = [];
    /** The card being worked on: {i, kind: "new" | "rename" | "delete"} (one at a time). */
    let editing = null;
    let said = "", bad = false;
    const say = (t, isBad) => {
      said = t || "";
      bad = !!isBad;
      const m = root.querySelector(".msg");
      if (m) {
        m.textContent = said;
        m.className = "msg" + (bad ? " bad" : "");
      }
    };

    async function refresh(focusNew) {
      try {
        roles = await game.users();
      } catch (e) {
        roles = [];
        say("读不了这个浏览器里的存档：" + e.message, true);
      }
      if (focusNew && !roles.length) editing = { i: 0, kind: "new" };
      draw();
    }

    function draw() {
      root.textContent = "";
      root.appendChild(el("h1", "", "选择奥拉"));
      const cards = el("div", "cards");
      const last = lastPlayed();
      const slots = Math.max(MAX, roles.length);
      for (let i = 0; i < slots; i++) cards.appendChild(i < roles.length ? roleCard(roles[i], i, last) : emptyCard(i));
      root.appendChild(cards);
      const bar = el("div", "bar");
      const m = el("div", "msg" + (bad ? " bad" : ""), said);
      bar.appendChild(m);
      bar.appendChild(button("导入奥拉", "go blue small", importFlow));
      if (roles.length) bar.appendChild(button("全部导出", "go blue small", exportAll));
      root.appendChild(bar);
      const f = root.querySelector("input");
      if (f) f.focus();
    }

    function roleCard(r, i, last) {
      const c = el("div", "card" + (r.name === last ? " last" : ""));
      if (r.name === last) c.appendChild(el("div", "badge", "上次玩的"));
      c.appendChild(el("div", "face", [...r.name][0] || "奥"));
      const kind = editing && editing.i === i ? editing.kind : "";
      if (kind === "rename") {
        let f = null;
        const go = async () => {
          const to = f.value.trim();
          if (to === r.name) return cancel();
          const err = await game.rename(r.name, to);
          if (err) return say(err, true);
          if (lastPlayed() === r.name) rememberPlayed(to);
          editing = null;
          say("");
          refresh();
        };
        f = input(r.name, "新名字", go, cancel);
        c.appendChild(f);
        c.appendChild(el("div", "grow"));
        const row = el("div");
        row.appendChild(button("确定", "go small", go));
        row.appendChild(button("取消", "go blue small", cancel));
        c.appendChild(row);
        return c;
      }
      if (kind === "delete") {
        c.appendChild(el("div", "name", r.name));
        c.appendChild(el("div", "ask warn", `删除${r.name}？删除后不能找回。`));
        c.appendChild(button("先导出一份", "link", () => exportOne(r)));
        c.appendChild(el("div", "grow"));
        const row = el("div");
        row.appendChild(
          button("删除", "go red small", async () => {
            const err = await game.deleteUser(r.name);
            if (err) return say(err, true);
            editing = null;
            say("");
            refresh();
          }),
        );
        row.appendChild(button("取消", "go blue small", cancel));
        c.appendChild(row);
        return c;
      }
      c.appendChild(el("div", "name", r.name));
      const facts = el("div", "facts");
      facts.appendChild(el("div", "", `晶币 ${r.score}`));
      facts.appendChild(el("div", "", r.pets ? `亚比 ${r.pets} 只` + (r.level ? `（第一只 Lv${r.level}）` : "") : "还没有亚比"));
      if (r.createdAt) facts.appendChild(el("div", "", `${day(r.createdAt)} 出发`));
      c.appendChild(facts);
      c.appendChild(el("div", "grow"));
      c.appendChild(
        button("进入", "go", () => {
          rememberPlayed(r.name);
          close();
          done(r.name);
        }),
      );
      const links = el("div", "links");
      links.appendChild(button("改名", "link", () => edit(i, "rename")));
      links.appendChild(button("导出", "link", () => exportOne(r)));
      links.appendChild(button("删除", "link red", () => edit(i, "delete")));
      c.appendChild(links);
      return c;
    }

    function emptyCard(i) {
      const c = el("div", "card empty");
      c.appendChild(el("div", "face", "+"));
      if (editing && editing.i === i && editing.kind === "new") {
        let f = null;
        const go = async () => {
          const name = f.value.trim();
          const err = await game.createUser(name);
          if (err) return say(err, true);
          editing = null;
          say("");
          refresh();
        };
        f = input("", "奥拉的名字", go, cancel);
        c.appendChild(f);
        c.appendChild(el("div", "grow"));
        const row = el("div");
        row.appendChild(button("确定", "go small", go));
        if (roles.length) row.appendChild(button("取消", "go blue small", cancel));
        c.appendChild(row);
        return c;
      }
      c.appendChild(el("div", "name", "空位"));
      c.appendChild(el("div", "facts", ""));
      c.appendChild(el("div", "grow"));
      c.appendChild(button("新建奥拉", "go blue", () => edit(i, "new")));
      return c;
    }

    function edit(i, kind) {
      editing = { i, kind };
      say("");
      draw();
    }
    function cancel() {
      editing = null;
      say("");
      draw();
    }

    async function exportOne(r) {
      const out = await game.exportSave(r.name);
      if (out.error || !out.save) return say(out.error || "没有导出。", true);
      download(out.save, `aola-save-${stamp()}.json`);
      say("已导出。");
    }

    async function exportAll() {
      // Every 奥拉 of this browser, in one file (导入奥拉 takes them one at a time).
      const data = {};
      for (const r of roles) {
        const out = await game.exportSave(r.name);
        if (out.save) Object.assign(data, out.save.data);
      }
      data["meta/nextUserId"] = Math.max(0, ...roles.map((r) => r.id));
      download({ format: FORMAT, version: 1, saved: new Date().toISOString(), data }, `aola-save-all-${stamp()}.json`);
      say("已导出。");
    }

    /** A sheet over the cards: a question with its answers (buttons, or an input and buttons). */
    function sheet(title, text, build) {
      const s = el("div", "sheet");
      const c = el("div", "card");
      c.appendChild(el("div", "name", title));
      if (text) c.appendChild(el("div", "ask", text));
      build(c, () => s.remove());
      s.appendChild(c);
      root.appendChild(s);
      const f = c.querySelector("input");
      if (f) f.focus();
    }

    function importFlow() {
      say("");
      chooseFile((j) => {
        const list = rolesOf(j);
        if (!j || j.format !== FORMAT || typeof j.version !== "number") return say("这不是奥拉星的存档文件。", true);
        if (j.version > 1) return say("这个存档文件是更新的版本，这里读不了。", true);
        if (!list.length) return say("这个存档里没有奥拉。", true);
        if (list.length === 1) return bring(j, list[0].name);
        sheet("选一个奥拉", "", (c, closeSheet) => {
          const row = el("div");
          for (const r of list) row.appendChild(button(r.name, "go small", () => (closeSheet(), bring(j, r.name))));
          c.appendChild(row);
          c.appendChild(button("取消", "link", closeSheet));
        });
      });
    }

    /** One 奥拉 of a file into this page: as itself, or (a name taken) replacing or renamed. */
    async function bring(j, from, as, replace) {
      const r = await game.addUser(j, { from, as, replace });
      if (r.name) {
        say("已导入。");
        return refresh();
      }
      if (r.conflict && !r.error) {
        return sheet(
          "名字重了",
          `已经有一个叫${r.conflict}的奥拉了。`,
          (c, closeSheet) => {
            const note = el("div", "ask warn", "");
            let f = null;
            const rename = async () => {
              const to = f.value.trim();
              if (!to) return void (note.textContent = "请输入新名字。");
              const again = await game.addUser(j, { from, as: to });
              if (again.name) {
                closeSheet();
                say("已导入。");
                return refresh();
              }
              note.textContent = again.conflict && !again.error ? `也已经有一个叫${again.conflict}的奥拉了。` : again.error || "没有导入。";
            };
            f = input("", "新名字", rename);
            c.appendChild(f);
            const row = el("div");
            row.appendChild(button("用新名字导入", "go small", rename));
            row.appendChild(button(`替换${r.conflict}`, "go red small", () => (closeSheet(), bring(j, from, r.conflict, true))));
            c.appendChild(row);
            c.appendChild(button("取消", "link", closeSheet));
            c.appendChild(note);
          },
        );
      }
      say(r.error || "没有导入。", true);
    }

    function close() {
      open = false;
      root.remove();
    }

    refresh(true);
  }

  window.AolaAccounts = { show };
})();
