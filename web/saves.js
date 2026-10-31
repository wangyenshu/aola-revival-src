// 存档: the 工具箱's 导出存档 / 导入存档 (the revival's, not of 2013). The
// in-page emulator keeps every save in this browser's IndexedDB
// ("aola-revival", store "kv", JSON values: server/src/browser/idbStore.ts).
// The toolbox calls aolaSaveExport / aolaSaveImport through ExternalInterface;
// both open a small panel over the game, so the file download and the file
// chooser start from a click on the page itself.
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

  function panel(title, text, buttons) {
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
    d.innerHTML = `<div class="box"><h1></h1><div class="close" title="关闭">×</div><p class="text"></p><div class="buttons"></div><p class="said"></p></div>`;
    d.querySelector("h1").textContent = title;
    d.querySelector(".text").textContent = text;
    d.querySelector(".close").addEventListener("click", close);
    for (const [label, fn] of buttons) {
      const b = document.createElement("button");
      b.textContent = label;
      b.addEventListener("click", () => fn(d.querySelector(".said")));
      d.querySelector(".buttons").appendChild(b);
    }
    stage.appendChild(d);
  }

  const inPage = () => (Object.assign({}, window.AOLA_CONFIG, window.AOLA_CONFIG_OVERRIDE || {}).mode || "inpage") === "inpage";
  const stamp = () => new Date().toISOString().slice(0, 16).replace(/[-:]/g, "").replace("T", "-");

  window.aolaSaveExport = () => {
    if (!inPage()) return panel("导出存档", "这个页面的存档在服务器上，不在浏览器里。", []);
    panel("导出存档", "把这个浏览器里的存档（所有角色、亚比、物品、家园）存成一个文件。", [
      [
        "保存文件",
        async (said) => {
          try {
            const data = await readAll();
            const blob = new Blob([JSON.stringify({ format: FORMAT, version: 1, saved: new Date().toISOString(), data }, null, 1)], { type: "application/json" });
            const a = document.createElement("a");
            a.href = URL.createObjectURL(blob);
            a.download = `aola-save-${stamp()}.json`;
            document.body.appendChild(a);
            a.click();
            a.remove();
            setTimeout(() => URL.revokeObjectURL(a.href), 10000);
            said.textContent = `已保存（${Object.keys(data).length} 项）。`;
          } catch (e) {
            said.textContent = "保存失败：" + e.message;
          }
        },
      ],
    ]);
  };

  window.aolaSaveImport = () => {
    if (!inPage()) return panel("导入存档", "这个页面的存档在服务器上，不在浏览器里。", []);
    panel("导入存档", "选一个导出的存档文件。它会替换这个浏览器里现在的存档，然后重新载入游戏。", [
      [
        "选择文件",
        (said) => {
          const input = document.createElement("input");
          input.type = "file";
          input.accept = ".json,application/json";
          input.addEventListener("change", async () => {
            const f = input.files && input.files[0];
            if (!f) return;
            try {
              const j = JSON.parse(await f.text());
              if (!j || j.format !== FORMAT || typeof j.data !== "object") throw new Error("这不是奥拉星的存档文件");
              await writeAll(j.data);
              said.textContent = "已导入，正在重新载入……";
              setTimeout(() => location.reload(), 600);
            } catch (e) {
              said.textContent = "导入失败：" + e.message;
            }
          });
          input.click();
        },
      ],
    ]);
  };
})();
