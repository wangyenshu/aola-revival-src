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
  const say = (t) => {
    status.textContent = t;
    console.log("[aola] " + t);
  };

  try {
    if (!("serviceWorker" in navigator)) {
      throw new Error("Service workers are unavailable. Open this page from http://localhost or http://127.0.0.1, not file://.");
    }
    say("Starting the mirror service worker…");
    const swUrl =
      `sw.js?hosts=${encodeURIComponent(cfg.hosts.join(","))}&mirror=${encodeURIComponent(cfg.mirror)}` +
      (cfg.index ? `&index=${encodeURIComponent(cfg.index)}` : "");
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

    // 单机 or 联机, and which 奥拉 (start.js); the rebuilt login asks for it (aolaRevivalAccount).
    const choice = window.AolaStart ? await window.AolaStart.choose(cfg) : { mode: cfg.mode, name: "", pass: "" };
    if (choice.mode) cfg.mode = choice.mode;
    // What the page's panels ask about this game (saves.js): the mode, the 奥拉, the server's
    // HTTP address (no password: the 存档 panels of 联机模式 ask for it).
    const serverWs = cfg.mode === "inpage" ? "" : (window.AolaStart && choice.server ? window.AolaStart.wsBase(choice.server) : "") || `${secure ? "wss" : "ws"}://${location.host}`;
    window.aolaSession = { mode: cfg.mode, name: choice.name || "", server: serverWs.replace(/^ws/i, "http") };
    // Read once by the login: the password is not kept in the page after that. 单机模式 with no
    // 奥拉 named (the start screen): the 选择奥拉 screen (accounts.js), {wait: true} while it is up
    // (the login asks again).
    let chosen = choice.name ? { name: choice.name, pass: choice.pass || "" } : null;
    window.aolaRevivalAccount = () => {
      if (chosen) {
        const a = chosen;
        chosen = null;
        choice.pass = "";
        return a;
      }
      if (cfg.mode === "inpage" && window.AolaAccounts && window.aola && window.aola.users) {
        window.AolaAccounts.show(window.aola, (name) => {
          window.aolaSession.name = name;
          chosen = { name, pass: "" };
        });
        return { wait: true };
      }
      return null;
    };
    // The game asks the page's mode (the 信息卡: 改密码 on a shared server only).
    window.aolaRevivalMode = () => cfg.mode;
    let socketProxy;
    if (cfg.mode === "inpage") {
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
        if (!mine) throw new Error("单机模式已经在另一个标签页里打开了：请回到那个标签页玩，或者关掉它再刷新这一页。");
      }
      say("Starting the in-page emulator…");
      const prefix = "ws://in-page.aola/";
      window.aola = window.AolaEmulator.startInPage({
        proxyPrefix: prefix,
        date: cfg.date,
        framing: cfg.framing,
        demo: !!cfg.demo,
        verbose: !!cfg.verbose,
        protocol: cfg.protocol,
        // ?dev=1: test commands (items on request) for the automated walk-throughs.
        dev: !!cfg.dev || /[?&]dev=1(&|$)/.test(location.search),
      });
      socketProxy = cfg.sockets.map((s) => ({ host: s.host, port: s.port, proxyUrl: prefix + s.port }));
    } else {
      // A shared server: the address the start screen gave, else this page's own host.
      const base = serverWs;
      say("联机模式：" + base);
      socketProxy = cfg.sockets.map((s) => ({ host: s.host, port: s.port, proxyUrl: `${base}/__socket/${s.port}` }));
    }
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
    // The 百田大剧场: the page script's video functions open the game's own (theatre.js).
    if (window.AolaTheatre) window.AolaTheatre.install();
    if (cfg.beforeRuffle) cfg.beforeRuffle();

    say("Loading Ruffle…");
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
      s.src = "ruffle/ruffle.js";
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
    const opts = { url: cfg.bootUrl, parameters: cfg.flashvars, base: cfg.base };
    await (typeof player.ruffle === "function" ? player.ruffle().load(opts) : player.load(opts));
    say("Running " + cfg.bootUrl + " (game clock " + cfg.date + ")");
  } catch (e) {
    say("Error: " + e.message);
    console.error(e);
  }
})();
