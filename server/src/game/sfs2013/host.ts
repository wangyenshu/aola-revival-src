// The 2013 game server, whatever hosts it: the page itself (src/browser/entry.ts, one player),
// a Node process (src/node/multi.ts) or a Cloudflare Durable Object (src/cloudflare/worker.ts),
// for many. The host gives a Store for the saves and a way to read the game's JSON tables;
// it hands every connection (a WebSocket from Ruffle's socketProxy, a TCP socket) to attach.

import { GameClock } from "../../core/clock.ts";
import { Emulator, type Link, type Session } from "../../core/emulator.ts";
import { MemoryRecorder, type Recorder } from "../../core/recorder.ts";
import { LiveRecordStore, type Store } from "../../core/store.ts";
import type { AccountOptions } from "./accounts.ts";
import { addUserFromFile, changePassword, createUser, deleteUser, exportSave, importSave, installSfs2013, listUsers, renameUser, type LocalRole } from "./game.ts";
import type { SaveFile } from "./saves.ts";
import { SFS2013_FRAMING, sfs2013Codec, type World } from "./server.ts";

export interface GameHostOptions {
  store: Store;
  /** A JSON table next to the game files (www.9aola.com/<path>: revival/materials.json …). */
  loadJson: (path: string) => Promise<unknown>;
  /** Anchor of the game clock (China time). */
  date?: string;
  /** A shared server: passwords and sign-up (accounts.ts). */
  accounts?: AccountOptions;
  /** Test commands of the automated walk-throughs. Never on a server for players. */
  dev?: boolean;
  recorder?: Recorder;
  /** Answer <policy-file-request/> (a Flash projector over TCP). */
  answerPolicy?: boolean;
  /** The 工具箱 and mods' gifts (game.ts; default: open). */
  toolbox?: boolean;
  /** Players may 导入存档 over their 奥拉 (game.ts importSave; default: as toolbox). */
  imports?: boolean;
}

export interface GameHost {
  emulator: Emulator;
  world: World;
  /** A new connection; the host feeds it what arrives and closes it when the client goes. */
  attach(link: Link, port?: number): Session;
  detach(session: Session): void;
  /**
   * 改名字 (the start screen; in the game, now: its game ends first and the page logs in again):
   * null if done, else why not. addr: the client's address (the password lock's).
   */
  rename(from: string, to: string, pass?: string, addr?: string, now?: boolean): Promise<string | null>;
  /** 改密码 (a shared server, in the game): the 奥拉's own password, then the new one; null if done. */
  changePassword(name: string, pass: string, to: string, addr?: string): Promise<string | null>;
  /** The page's own 奥拉 (单机模式's 选择奥拉: web/accounts.js). */
  users(): Promise<LocalRole[]>;
  createUser(name: string): Promise<string | null>;
  deleteUser(name: string): Promise<string | null>;
  addUser(file: unknown, opts?: { from?: string; as?: string; replace?: boolean }): Promise<{ name?: string; error?: string; names?: string[]; conflict?: string }>;
  /** 导出存档: the 奥拉 as a 存档 file (saves.ts). */
  exportSave(name: string, pass?: string, addr?: string): Promise<{ save?: SaveFile; error?: string }>;
  /** 导入存档: an 奥拉 of a 存档 file over this one (its game ended first). */
  importSave(name: string, pass: string | undefined, file: unknown, from?: string, addr?: string): Promise<{ error?: string; names?: string[] }>;
  /** Players may import saves here. */
  readonly imports: boolean;
  /** How many 奥拉 are in the game. */
  online(): number;
}

export function createGameHost(o: GameHostOptions): GameHost {
  let world: World | undefined;
  const emulator = new Emulator({
    framing: SFS2013_FRAMING,
    codec: sfs2013Codec,
    clock: new GameClock(o.date ?? "2012-08-15"),
    // The players' records live: one object a player, whoever's handler changes it (store.ts).
    store: new LiveRecordStore(o.store, ["user/"], 1000, (key) => {
      // A player in the game keeps his record live.
      try {
        return !!world?.online(decodeURIComponent(key.slice("user/".length)));
      } catch {
        return false;
      }
    }),
    recorder: o.recorder ?? new MemoryRecorder(),
    answerPolicy: o.answerPolicy ?? false,
  });
  const w = installSfs2013(emulator, { loadJson: o.loadJson, dev: o.dev, accounts: o.accounts, toolbox: o.toolbox });
  world = w;
  const playing = (name: string) => [...emulator.sessions].some((s) => w.player(s)?.name === name);
  const imports = o.imports ?? o.toolbox ?? true;
  // The game of an 奥拉 ends (its connection closes: the leave hooks run, as when the page goes);
  // whether it was on.
  const end = (name: string) => {
    let was = false;
    for (const s of [...emulator.sessions]) {
      if (w.player(s)?.name !== name) continue;
      was = true;
      s.close();
    }
    return was;
  };
  return {
    emulator,
    world: w,
    attach: (link, port = 9339) => emulator.attach(link, port),
    detach: (s) => emulator.detach(s),
    rename: (from, to, pass, addr, now) => renameUser(emulator, from, to, { pass, addr, accounts: o.accounts, online: playing, end: now ? end : undefined }),
    changePassword: (name, pass, to, addr) => changePassword(emulator, name, pass, to, { addr, accounts: o.accounts }),
    users: () => listUsers(emulator),
    createUser: (name) => createUser(emulator, name),
    deleteUser: (name) => deleteUser(emulator, name, end),
    addUser: (file, a = {}) => addUserFromFile(emulator, file, { ...a, end }),
    exportSave: (name, pass, addr) => exportSave(emulator, name, { pass, addr, accounts: o.accounts }),
    importSave: (name, pass, file, from, addr) => importSave(emulator, name, file, { pass, addr, from, accounts: o.accounts, imports, end }),
    imports,
    online: () => [...emulator.sessions].filter((s) => w.player(s)).length,
  };
}
