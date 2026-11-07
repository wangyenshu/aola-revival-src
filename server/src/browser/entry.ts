// Bundled to web/emulator.js. Starts the emulator inside the page and routes
// Ruffle's proxied sockets to it.

import { GameClock } from "../core/clock.ts";
import { Emulator } from "../core/emulator.ts";
import { parseFraming } from "../core/framing.ts";
import { ConsoleRecorder, MemoryRecorder, TeeRecorder } from "../core/recorder.ts";
import { installAola2012 } from "../game/aola2012.ts";
import { installHandshakeDemo } from "../game/devHandlers.ts";
import { createGameHost } from "../game/sfs2013/host.ts";
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
  /** A mod played as a game of its own (web/config.js standalone): no newbie quest. */
  standalone?: boolean;
}

/** Frames the page keeps (window.aola.frames). */
export const FRAMES_KEPT = 5000;

export function startInPage(cfg: InPageConfig) {
  // The last frames only (the walk-throughs read them; a long game would pile them up).
  const memory = new MemoryRecorder(FRAMES_KEPT);
  const sfs = cfg.protocol === "sfs2013";
  if (sfs && !cfg.demo) {
    // The 2013 game for the one player of this page (game/sfs2013/host.ts), saves in IndexedDB.
    const host = createGameHost({
      store: new IdbStore(),
      // Game data next to the game files (the service worker serves www.9aola.com from the mirror roots).
      // Through the service worker; over https on an https page (mixed content is blocked).
      loadJson: (path) =>
        fetch(`${location.protocol === "https:" ? "https" : "http"}://www.9aola.com/${path}`).then((r) => (r.ok ? r.json() : undefined)),
      date: cfg.date,
      dev: cfg.dev,
      standalone: cfg.standalone,
      recorder: cfg.verbose ? new TeeRecorder(memory, new ConsoleRecorder()) : memory,
    });
    installInPageSockets(host.emulator, {
      match: (url) => (url.startsWith(cfg.proxyPrefix) ? Number(url.slice(cfg.proxyPrefix.length)) || 0 : undefined),
    });
    // What the page asks of its game (boot.js, accounts.js, saves.js): its 奥拉, their names, their files.
    return {
      emulator: host.emulator,
      frames: memory.records,
      rename: (from: string, to: string, now = false) => host.rename(from, to, undefined, undefined, now),
      users: host.users,
      createUser: host.createUser,
      deleteUser: host.deleteUser,
      addUser: host.addUser,
      exportSave: (name: string) => host.exportSave(name),
      importSave: (name: string, file: unknown, from?: string) => host.importSave(name, undefined, file, from),
    };
  }
  const emu = new Emulator({
    framing: sfs ? SFS2013_FRAMING : parseFraming(cfg.framing ?? "raw"),
    codec: sfs ? sfs2013Codec : undefined,
    clock: new GameClock(cfg.date ?? "2012-08-15"),
    store: new IdbStore(),
    recorder: cfg.verbose ? new TeeRecorder(memory, new ConsoleRecorder()) : memory,
    answerPolicy: false,
  });
  if (cfg.demo) installHandshakeDemo(emu);
  else installAola2012(emu);
  installInPageSockets(emu, {
    match: (url) => (url.startsWith(cfg.proxyPrefix) ? Number(url.slice(cfg.proxyPrefix.length)) || 0 : undefined),
  });
  return { emulator: emu, frames: memory.records, rename: async () => "这个页面不能改名字。" };
}

(globalThis as Record<string, unknown>).AolaEmulator = { startInPage };
