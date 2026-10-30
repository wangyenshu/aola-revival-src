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
      await new Promise((r) => navigator.serviceWorker.addEventListener("controllerchange", r, { once: true }));
    }

    let socketProxy;
    if (cfg.mode === "inpage") {
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
      socketProxy = cfg.sockets.map((s) => ({ host: s.host, port: s.port, proxyUrl: `ws://${location.host}/__socket/${s.port}` }));
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
