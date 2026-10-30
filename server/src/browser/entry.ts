// Bundled to web/emulator.js. Starts the emulator inside the page and routes
// Ruffle's proxied sockets to it.

import { GameClock } from "../core/clock.ts";
import { Emulator } from "../core/emulator.ts";
import { parseFraming } from "../core/framing.ts";
import { ConsoleRecorder, MemoryRecorder, TeeRecorder } from "../core/recorder.ts";
import { installAola2012 } from "../game/aola2012.ts";
import { installHandshakeDemo } from "../game/devHandlers.ts";
import { installSfs2013 } from "../game/sfs2013/game.ts";
import { IdbStore } from "./idbStore.ts";
import { SFS2013_FRAMING, sfs2013Codec } from "../game/sfs2013/server.ts";
import { installInPageSockets } from "./shim.ts";

export interface InPageConfig {
  /** Prefix of the fake proxy URLs, e.g. "ws://in-page.aola/" + port. */
  proxyPrefix: string;
  date?: string;
  framing?: string;
  demo?: boolean;
  verbose?: boolean;
  /** "sfs2013" = the 2013 client protocol; otherwise raw listen mode. */
  protocol?: string;
  /** Test commands (PocketMonsterExtension.revival_give) for the automated walk-throughs. */
  dev?: boolean;
}

export function startInPage(cfg: InPageConfig) {
  const memory = new MemoryRecorder();
  const sfs = cfg.protocol === "sfs2013";
  const emu = new Emulator({
    framing: sfs ? SFS2013_FRAMING : parseFraming(cfg.framing ?? "raw"),
    codec: sfs ? sfs2013Codec : undefined,
    clock: new GameClock(cfg.date ?? "2012-08-15"),
    store: new IdbStore(),
    recorder: cfg.verbose ? new TeeRecorder(memory, new ConsoleRecorder()) : memory,
    answerPolicy: false,
  });
  if (cfg.demo) installHandshakeDemo(emu);
  else if (sfs)
    installSfs2013(emu, {
      // Game data next to the game files (the service worker serves www.9aola.com from the mirror roots).
      // Through the service worker; over https on an https page (mixed content is blocked).
      loadJson: (path) =>
        fetch(`${location.protocol === "https:" ? "https" : "http"}://www.9aola.com/${path}`).then((r) => (r.ok ? r.json() : undefined)),
      dev: cfg.dev,
    });
  else installAola2012(emu);
  installInPageSockets(emu, {
    match: (url) => (url.startsWith(cfg.proxyPrefix) ? Number(url.slice(cfg.proxyPrefix.length)) || 0 : undefined),
  });
  return { emulator: emu, frames: memory.records };
}

(globalThis as Record<string, unknown>).AolaEmulator = { startInPage };
