// 百田大剧场: the overlay the January 2013 client opens through
// ExternalInterface. The original page script (js/aola.js) put an iframe of
// 百田's video site over the game: showVideoPlayer (the theatre scene) its
// list of cartoons, showAnniversaryVideo the 奥拉星2周年 film,
// showWarTeamVideo the 战队 film. v.100bt.com is gone; this shows the films
// of 奥拉星 that survive on the game's CDN (tools/theatre.py: the FLVs
// converted to WebM and MP4, listed in www.9aola.com/revival/theatre.json) in a panel
// of the same size over the game, and replaces those functions once the page
// scripts have loaded (boot.js calls AolaTheatre.install()).
(() => {
  const LIST = "http://www.9aola.com/revival/theatre.json";
  const secure = location.protocol === "https:";
  const up = (u) => (secure && typeof u === "string" ? u.replace(/^http:\/\//, "https://") : u);
  let films = null;
  const load = () =>
    (films ??= fetch(up(LIST))
      .then((r) => (r.ok ? r.json() : { films: [] }))
      .then((j) => j.films || [])
      .catch(() => []));

  const CSS = `
#aolaTheatre { position: absolute; left: 0; top: 0; width: 960px; height: 560px; z-index: 10001;
  background: rgba(4, 22, 52, .72); font: 12px/1.5 SimSun, "宋体", "Microsoft YaHei", sans-serif; }
#aolaTheatre .box { position: absolute; left: 70px; top: 28px; width: 820px; height: 500px; border-radius: 22px;
  background: linear-gradient(#7fd3ff, #2b8fe0); border: 3px solid #fff; box-shadow: 0 4px 14px rgba(0,0,0,.45); }
#aolaTheatre h1 { margin: 0; height: 52px; line-height: 52px; text-align: center; color: #fff; font-size: 24px;
  letter-spacing: 4px; text-shadow: 0 0 3px #0b4f9a, 0 2px 0 #0b4f9a; }
#aolaTheatre .close { position: absolute; right: 10px; top: 10px; width: 34px; height: 34px; border-radius: 50%;
  border: 2px solid #fff; background: linear-gradient(#ffb15a, #f0601a); color: #fff; font: bold 20px/30px Arial;
  text-align: center; cursor: pointer; }
#aolaTheatre .screen { position: absolute; left: 18px; top: 58px; width: 560px; height: 420px; border-radius: 14px;
  background: #001; overflow: hidden; border: 2px solid #c9ecff; }
#aolaTheatre video { width: 100%; height: 100%; background: #000; }
#aolaTheatre .screen .idle { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  color: #9fd6ff; font-size: 16px; text-align: center; padding: 30px; }
#aolaTheatre .list { position: absolute; left: 592px; top: 58px; width: 210px; height: 420px; overflow-y: auto;
  border-radius: 14px; background: #fff7e3; border: 2px solid #f2a23a; }
#aolaTheatre .film { margin: 8px; padding: 6px; border-radius: 10px; background: #fff; border: 2px solid #f2c27a; cursor: pointer; }
#aolaTheatre .film.on { border-color: #f07812; background: #fff1c9; }
#aolaTheatre .film img { display: block; width: 100%; border-radius: 6px; }
#aolaTheatre .film b { display: block; color: #1a5fa8; font-size: 14px; margin-top: 4px; }
#aolaTheatre .film i { font-style: normal; color: #7a8ea8; }
#aolaTheatre .note { margin: 8px 10px 10px; color: #8a6a3a; }
`;

  function close() {
    const d = document.getElementById("aolaTheatre");
    if (!d) return;
    const v = d.querySelector("video");
    if (v) v.pause();
    d.remove();
  }

  async function open(startId) {
    close();
    if (!document.getElementById("aolaTheatreCss")) {
      const st = document.createElement("style");
      st.id = "aolaTheatreCss";
      st.textContent = CSS;
      document.head.appendChild(st);
    }
    const stage = document.getElementById("stage") || document.body;
    if (getComputedStyle(stage).position === "static") stage.style.position = "relative";
    const d = document.createElement("div");
    d.id = "aolaTheatre";
    d.innerHTML =
      '<div class="box"><h1>百田大剧场</h1><div class="close" title="关闭">×</div>' +
      '<div class="screen"><div class="idle">正在打开……</div></div><div class="list"></div></div>';
    stage.appendChild(d);
    d.querySelector(".close").addEventListener("click", close);
    // Keys typed here are not the game's.
    d.addEventListener("keydown", (e) => e.stopPropagation());
    const list = await load();
    if (!d.isConnected) return;
    const screen = d.querySelector(".screen");
    const side = d.querySelector(".list");
    if (!list.length) {
      screen.innerHTML = '<div class="idle">放映厅里还没有动画片。</div>';
      return;
    }
    const play = (f) => {
      for (const el of side.querySelectorAll(".film")) el.classList.toggle("on", el.dataset.id === f.id);
      screen.innerHTML = "";
      const v = document.createElement("video");
      v.controls = true;
      v.autoplay = true;
      v.playsInline = true;
      v.poster = up(f.poster || "");
      for (const [src, type] of [[f.webm, "video/webm"], [f.mp4, "video/mp4"]]) {
        if (!src) continue;
        const s = document.createElement("source");
        s.src = up(src);
        s.type = type;
        v.appendChild(s);
      }
      // A <video> with <source>s reports a failure on the last source.
      const sources = v.querySelectorAll("source");
      if (sources.length) {
        sources[sources.length - 1].addEventListener("error", () => {
          screen.innerHTML = '<div class="idle">这部动画片没有找到（' + f.title + "）。</div>";
        });
      }
      screen.appendChild(v);
    };
    for (const f of list) {
      const el = document.createElement("div");
      el.className = "film";
      el.dataset.id = f.id;
      el.innerHTML = (f.poster ? '<img alt="" src="' + up(f.poster) + '">' : "") + "<b></b><i></i>";
      el.querySelector("b").textContent = f.title;
      el.querySelector("i").textContent = f.uploaded ? f.uploaded.replace(/-/g, ".") : "";
      el.addEventListener("click", () => play(f));
      side.appendChild(el);
    }
    const note = document.createElement("div");
    note.className = "note";
    note.textContent = "2013 年的大剧场还放过其他动画公司的卡通，那些片子没有保存在这里。";
    side.appendChild(note);
    const first = list.find((f) => f.id === startId);
    if (first) play(first);
    else screen.innerHTML = '<div class="idle">选一部动画片看看吧！</div>';
  }

  function install() {
    window.showVideoPlayer = () => open();
    window.showAnniversaryVideo = () => open("anniversary2");
    window.showWarTeamVideo = () => open("warteam");
    window.clearVideoPlayer = close;
    window.clearDiv = close;
  }

  window.AolaTheatre = { install, open, close };
})();
