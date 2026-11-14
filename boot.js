// Boot sequence: service worker (mirror under original URLs) -> emulator
// (in-page or server bridge) -> Ruffle with socketProxy -> original boot SWF.
(async () => {
  const cfg = Object.assign({}, window.AOLA_CONFIG, window.AOLA_CONFIG_OVERRIDE || {});
  // On an https page (GitHub Pages) the browser blocks http:// requests before
  // the service worker sees them: ask for the original hosts over https
  // instead; the service worker answers either.
  const secure = location.protocol === "https:";
  const upgrade = (u) => (secure && typeof u === "string" ? u.replace(/^http:\/\//, "https://") : u);
  cfg.bootUrl = upgrade(cfg.bootUrl);
  cfg.base = upgrade(cfg.base);
  cfg.pageScripts = (cfg.pageScripts || []).map(upgrade);
  const status = document.getElementById("status");
  // A mod played as a game of its own (cfg.standalone): the page is the game alone, with nothing
  // written under it but what went wrong.
  const quiet = !!cfg.standalone;
  if (quiet) status.textContent = "";
  const say = (t, wrong = false) => {
    if (!quiet || wrong) status.textContent = t;
    console.log("[aola] " + t);
  };

  // A mod played as a game of its own (cfg.standalone): its cover over the game from the start, with a
  // bar of how far the loading has gone, as the game's own loading screen has one (正在进入奥拉星……
  // 46% [43/93]): the page's own steps first, then the game's files as they come, against how many
  // its first room took when it was exported (cfg.standalone.files, export.mjs).
  const loading = cfg.standalone ? coverWithBar(cfg.standalone) : null;
  const step = (f) => loading && loading.step(f);

  try {
    if (!("serviceWorker" in navigator)) {
      throw new Error("Service workers are unavailable. Open this page from http://localhost or http://127.0.0.1, not file://.");
    }
    say("Starting the mirror service worker…");
    step(0.02);
    const swUrl =
      `sw.js?hosts=${encodeURIComponent(cfg.hosts.join(","))}&mirror=${encodeURIComponent(cfg.mirror)}` +
      (cfg.index ? `&index=${encodeURIComponent(cfg.index)}` : "") +
      (cfg.build ? `&build=${encodeURIComponent(cfg.build)}` : "");
    await navigator.serviceWorker.register(swUrl);
    if (!navigator.serviceWorker.controller) {
      const taken = new Promise((r) => navigator.serviceWorker.addEventListener("controllerchange", () => r(true), { once: true }));
      // A forced reload (Ctrl+Shift+R) leaves the page without the worker, which is already
      // active and does not activate again: it is asked to take the page over, and failing
      // that the page is loaded once more (a plain reload is served by it).
      const reg = await navigator.serviceWorker.ready;
      if (!navigator.serviceWorker.controller) {
        if (reg.active) reg.active.postMessage("aola-claim");
        const ok = await Promise.race([taken, new Promise((r) => setTimeout(() => r(false), 4000))]);
        if (!ok && !navigator.serviceWorker.controller) {
          let again = false;
          try { again = sessionStorage.getItem("aola-sw-reload") === "1"; sessionStorage.setItem("aola-sw-reload", "1"); } catch (e) {}
          if (!again) {
            location.reload();
            return;
          }
          await taken;
        }
      }
    }
    try { sessionStorage.removeItem("aola-sw-reload"); } catch (e) {}
    // The page's 2012 pictures come from the mirror too (index.html).
    document.documentElement.classList.add("site");
    fetch(upgrade("http://www.9aola.com/favicon.ico"))
      .then((r) => (r.ok ? r.blob() : null))
      .then((b) => {
        if (!b) return;
        const l = document.createElement("link");
        l.rel = "icon";
        l.href = URL.createObjectURL(b);
        document.head.appendChild(l);
      })
      .catch(() => {});

    // Ruffle's sockets go to one address, taken when the game connects (its login): the
    // in-page game's (shim.ts, installed when 单机模式 starts) or a shared server's.
    const PREFIX = "ws://in-page.aola/";
    let serverWs = "";
    const RealSocket = window.WebSocket;
    window.WebSocket = new Proxy(RealSocket, {
      construct(target, args) {
        const u = String(args[0]);
        if (serverWs && u.startsWith(PREFIX)) args = [`${serverWs}/__socket/${u.slice(PREFIX.length)}`, ...args.slice(1)];
        return Reflect.construct(target, args);
      },
    });
    const socketProxy = cfg.sockets.map((s) => ({ host: s.host, port: s.port, proxyUrl: PREFIX + s.port }));

    // The game the player chose (start.js: the login's start screen, or chosen without it).
    // What the page's panels ask about it (saves.js): the mode, the 奥拉, the server's HTTP
    // address (no password: the 存档 panels of 联机模式 ask for it).
    let begun = null;
    async function begin(choice) {
      // 联机模式 again (a login refused: another address, name or password); the other mode once
      // a game has begun needs a new page (单机模式's game holds the page's sockets).
      if (begun && begun.mode !== choice.mode) return { error: "请刷新页面再换模式。" };
      if (choice.mode === "inpage" && !begun) {
        // One tab of 单机模式 at a time: each runs its own game on the same saves, and the one
        // behind would write its older 奥拉 over the other's.
        if (navigator.locks && navigator.locks.request) {
          const mine = await new Promise((r) => {
            navigator.locks
              .request("aola-revival-inpage", { ifAvailable: true }, (lock) => {
                r(!!lock);
                // Held while the page is open.
                return lock ? new Promise(() => {}) : null;
              })
              .catch(() => r(true));
          });
          if (!mine) return { error: "单机模式已经在另一个标签页里打开了：请回到那个标签页玩，或者关掉它再刷新这一页。" };
        }
        say("Starting the in-page emulator…");
        step(0.05);
        window.aola = window.AolaEmulator.startInPage({
          proxyPrefix: PREFIX,
          date: cfg.date,
          framing: cfg.framing,
          demo: !!cfg.demo,
          verbose: !!cfg.verbose,
          protocol: cfg.protocol,
          // ?dev=1: test commands (items on request) for the automated walk-throughs.
          dev: !!cfg.dev || /[?&]dev=1(&|$)/.test(location.search),
          // A mod played as a game of its own: no newbie quest for its 奥拉.
          standalone: !!cfg.standalone,
        });
      } else if (choice.mode !== "inpage") {
        // A shared server: the address the start screen gave, else this page's own host.
        serverWs = (choice.server && window.AolaStart ? window.AolaStart.wsBase(choice.server) : "") || `${secure ? "wss" : "ws"}://${location.host}`;
        say("联机模式：" + serverWs);
      }
      const name = choice.name || (begun && window.aolaSession ? window.aolaSession.name : "");
      cfg.mode = choice.mode;
      begun = choice;
      window.aolaSession = { mode: cfg.mode, name, server: serverWs.replace(/^ws/i, "http") };
      return { ok: true };
    }
    window.AolaBoot = { begin };
    if (window.AolaStart) window.AolaStart.install(cfg);
    const preset = window.AolaStart ? window.AolaStart.preset() : { mode: cfg.mode, name: "", pass: "" };
    let chosen = null;
    if (preset) {
      const r = await begin(preset);
      if (r.error) throw new Error(r.error);
      chosen = preset.name ? { name: preset.name, pass: preset.pass || "" } : null;
    }
    // The login asks who plays: the preset 奥拉 (read once: the password is not kept in the
    // page after that), else {choose: true}, and it shows its start screen.
    window.aolaRevivalAccount = () => {
      if (chosen) {
        const c = chosen;
        chosen = null;
        return c;
      }
      return begun ? null : { choose: true };
    };
    // The game asks the page's mode (the 信息卡: 改密码 on a shared server only).
    window.aolaRevivalMode = () => (begun ? cfg.mode : "");
    for (const src of cfg.pageScripts || []) {
      say("Loading page script " + src);
      await new Promise((resolve) => {
        const s = document.createElement("script");
        s.src = src;
        s.onload = resolve;
        s.onerror = () => {
          console.warn("[aola] page script missing: " + src);
          resolve();
        };
        document.head.appendChild(s);
      });
    }
    // A mod played as a game of its own (cfg.standalone): the loader skips its start page (it does
    // when the page's query names an account, getQS "u"), and the game asks for the mod.
    if (cfg.standalone) {
      const qs = window.getQS;
      window.getQS = (k) => (k === "u" ? "standalone" : typeof qs === "function" ? qs(k) : null);
      window.aolaRevivalStandalone = () => cfg.standalone;
      if (cfg.standalone.name) document.title = String(cfg.standalone.name);
      // Its cover (made as the page began: loading) goes once the mod's first room is shown.
      window.aolaRevivalReady = () => loading && loading.done();
    }
    // The 百田大剧场: the page script's video functions open the game's own (theatre.js).
    if (window.AolaTheatre) window.AolaTheatre.install();
    if (cfg.beforeRuffle) cfg.beforeRuffle();

    say("Loading Ruffle…");
    step(0.08);
    window.RufflePlayer = window.RufflePlayer || {};
    window.RufflePlayer.config = {
      autoplay: "on",
      unmuteOverlay: "hidden",
      splashScreen: false,
      letterbox: "on",
      upgradeToHttps: secure,
      allowScriptAccess: true,
      socketProxy,
      // Draw device text (names, chat) with the system's fonts, e.g. SimSun.
      deviceFontRenderer: "canvas",
      playerVersion: 32,
      logLevel: cfg.verbose ? "info" : "warn",
      publicPath: "ruffle/",
      // The game's own links to 百田's pages (官网, 充值, the forum) open nothing: no page of
      // theirs is fetched. Its javascript: calls to the page are not links (allowScriptAccess).
      openUrlMode: "deny",
    };
    await new Promise((resolve, reject) => {
      const s = document.createElement("script");
      s.src = "ruffle/ruffle.js" + (cfg.build ? `?v=${encodeURIComponent(cfg.build)}` : "");
      s.onload = resolve;
      s.onerror = () => reject(new Error("ruffle/ruffle.js missing: build the site with `npm run build`"));
      document.head.appendChild(s);
    });

    const player = window.RufflePlayer.newest().createPlayer();
    player.id = cfg.playerId || "game";
    // aola.js finds the movie as document["myFlashEmbed"] outside IE.
    document[(cfg.playerId || "game") + "Embed"] = player;
    player.style.width = cfg.width + "px";
    player.style.height = cfg.height + "px";
    document.getElementById("stage").appendChild(player);
    window.aolaPlayer = player;
    say("Loading " + cfg.bootUrl);
    step(0.12);
    const opts = { url: cfg.bootUrl, parameters: cfg.flashvars, base: cfg.base };
    await (typeof player.ruffle === "function" ? player.ruffle().load(opts) : player.load(opts));
    say("Running " + cfg.bootUrl + " (game clock " + cfg.date + ")");
    step(0.15);
  } catch (e) {
    say("Error: " + e.message, true);
    console.error(e);
  }

  /**
   * The cover of a mod played as a game of its own, over the stage until done(), with the loading
   * bar: step(f) the page's steps (0–0.15 of it), then each file of the game loaded (resource timing:
   * what the page fetched of www.9aola.com) against solo.files.
   */
  function coverWithBar(solo) {
    const stage = document.getElementById("stage");
    if (!stage) return null;
    const cover = document.createElement("div");
    cover.id = "cover";
    cover.style.cssText = "position:absolute;left:0;top:0;width:100%;height:100%;z-index:5;display:flex;align-items:flex-end;justify-content:center;" +
      "background:#0b1b3a center/cover no-repeat";
    if (solo.cover) cover.style.backgroundImage = `url("${String(solo.cover).replace(/"/g, "")}")`;
    // The game's bar: a golden capsule, its words in white over it.
    const bar = document.createElement("div");
    bar.style.cssText = "position:relative;width:46%;max-width:440px;height:18px;margin-bottom:12.5%;border-radius:10px;" +
      "background:#5c3a00;border:2px solid #fff3c4;box-shadow:0 0 0 2px #c27c00,0 2px 6px rgba(0,0,0,.5);overflow:hidden";
    const fill = document.createElement("div");
    fill.style.cssText = "position:absolute;left:0;top:0;bottom:0;width:0;border-radius:8px;transition:width .25s;" +
      "background:linear-gradient(#fff7b0,#ffd21f 50%,#f4a300)";
    const words = document.createElement("div");
    words.style.cssText = "position:absolute;left:0;right:0;top:0;bottom:0;font:12px/18px SimSun,'宋体','Microsoft YaHei',sans-serif;color:#fff;" +
      "text-align:center;white-space:nowrap;text-shadow:0 0 2px #7a4a00,0 0 2px #7a4a00,0 0 1px #7a4a00";
    bar.appendChild(fill);
    bar.appendChild(words);
    cover.appendChild(bar);
    stage.style.position = "relative";
    stage.appendChild(cover);
    const name = String(solo.name || "游戏");
    const expected = Math.max(1, Number(solo.files) || 250);
    let page = 0;
    let seen = 0;
    let finished = false;
    const show = () => {
      const f = finished ? 1 : Math.min(0.99, page + (1 - 0.15) * Math.min(1, seen / expected));
      fill.style.width = (f * 100).toFixed(1) + "%";
      words.textContent = `正在进入${name}……  ${Math.floor(f * 100)}%` + (seen ? `  [${finished ? expected : Math.min(seen, expected)}/${expected}]` : "");
    };
    try {
      performance.setResourceTimingBufferSize(10000);
      new PerformanceObserver((list) => {
        for (const e of list.getEntries()) if (/\/\/www\.9aola\.com\//.test(e.name)) seen++;
        window.aolaFilesSeen = seen;
        show();
      }).observe({ type: "resource", buffered: true });
    } catch (e) {}
    show();
    return {
      step(f) { page = Math.max(page, f); show(); },
      done() {
        finished = true;
        show();
        setTimeout(() => cover.remove(), 300);
      },
    };
  }
})();
