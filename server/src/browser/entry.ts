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

type SavesConfig = Omit<InPageConfig, "proxyPrefix" | "framing">;

/**
 * The 2013 game of this page (game/sfs2013/host.ts), saves in IndexedDB: made once, the first time
 * the page needs it — 选择奥拉's 奥拉 (openSaves) or the game itself (startInPage) — and kept.
 */
let opened: { host: ReturnType<typeof createGameHost>; memory: MemoryRecorder } | null = null;
function openHost(cfg: SavesConfig) {
  if (!opened) {
    // The last frames only (the walk-throughs read them; a long game would pile them up).
    const memory = new MemoryRecorder(FRAMES_KEPT);
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
    opened = { host, memory };
  }
  return opened;
}

/** What the page asks of its game (boot.js, start.js, saves.js): its 奥拉, their names, their files. */
function pageGame(o: NonNullable<typeof opened>) {
  const host = o.host;
  return {
    emulator: host.emulator,
    frames: o.memory.records,
    rename: (from: string, to: string, now = false) => host.rename(from, to, undefined, undefined, now),
    users: host.users,
    createUser: host.createUser,
    deleteUser: host.deleteUser,
    addUser: host.addUser,
    exportSave: (name: string) => host.exportSave(name),
    importSave: (name: string, file: unknown, from?: string) => host.importSave(name, undefined, file, from),
  };
}

/**
 * 单机模式's 奥拉 for 选择奥拉 (web/start.js), before the game starts: the page's game without its
 * sockets, so choosing 单机模式 and going back (返回) leaves the page as it was. startInPage then
 * goes on with the same game.
 */
export function openSaves(cfg: SavesConfig) {
  if (cfg.protocol !== "sfs2013" || cfg.demo) return null;
  return pageGame(openHost(cfg));
}

export function startInPage(cfg: InPageConfig) {
  const sfs = cfg.protocol === "sfs2013";
  if (sfs && !cfg.demo) {
    const o = openHost(cfg);
    installInPageSockets(o.host.emulator, {
      match: (url) => (url.startsWith(cfg.proxyPrefix) ? Number(url.slice(cfg.proxyPrefix.length)) || 0 : undefined),
    });
    return pageGame(o);
  }
  // The last frames only (the walk-throughs read them; a long game would pile them up).
  const memory = new MemoryRecorder(FRAMES_KEPT);
  const emu = new Emulator({
    framing: sfs ? SFS2013_FRAMING : parseFraming(cfg.framing ?? "raw"),
    codec: sfs ? sfs2013Codec : undefined,
    clock: new GameClock(cfg.date || undefined),
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

(globalThis as Record<string, unknown>).AolaEmulator = { startInPage, openSaves };
