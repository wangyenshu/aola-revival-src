// The 2013 game server, whatever hosts it: the page itself (src/browser/entry.ts, one player),
// a Node process (src/node/multi.ts) or a Cloudflare Durable Object (src/cloudflare/worker.ts),
// for many. The host gives a Store for the saves and a way to read the game's JSON tables;
// it hands every connection (a WebSocket from Ruffle's socketProxy, a TCP socket) to attach.

import { SAVE_RECORD_MAX } from "./saves.ts";
import { GameClock } from "../../core/clock.ts";
import { Emulator, type Link, type Session } from "../../core/emulator.ts";
import { MemoryRecorder, type Recorder } from "../../core/recorder.ts";
import { LiveRecordStore, type Store } from "../../core/store.ts";
import type { AccountOptions } from "./accounts.ts";
import { addUserFromFile, changePassword, createUser, deleteUser, exportSave, forgetToken, importSave, installSfs2013, listUsers, registerUser, rememberUser, renameUser, type LocalRole } from "./game.ts";
import type { SaveFile } from "./saves.ts";
import { SFS2013_FRAMING, sfs2013Codec, type World } from "./server.ts";

export interface GameHostOptions {
  store: Store;
  /** A JSON table next to the game files (www.9aola.com/<path>: revival/materials.json …). */
  loadJson: (path: string) => Promise<unknown>;
  /** A day the game clock starts at at each start (China time; core/clock.ts); none: the real time. */
  date?: string;
  /** A shared server: passwords and sign-up (accounts.ts). */
  accounts?: AccountOptions;
  /** Test commands of the automated walk-throughs. Never on a server for players. */
  dev?: boolean;
  /** A mod played as a game of its own: its new 奥拉 skip the newbie quest (game.ts). */
  standalone?: boolean;
  recorder?: Recorder;
  /** Answer <policy-file-request/> (a Flash projector over TCP). */
  answerPolicy?: boolean;
  /** The 工具箱 and mods' gifts (game.ts; default: open). */
  toolbox?: boolean;
  /** Players may 导入存档 over their 奥拉 (game.ts importSave; default: as toolbox). */
  imports?: boolean;
  /** At most this many in the game at once (a shared server). */
  maxPlayers?: number;
}

/**
 * Connections a shared server takes that have not logged in (yet): all of them (PENDING_MAX, or
 * half the game's places if more), and of one address; and the connections of one address in all
 * (a family behind one router, a few tabs each). A connection not logged in is closed after
 * LOGIN_WAIT_MS (game.ts; again after a login refused), so a page that opens many and never logs
 * in holds few places, and those briefly; the game's places (maxPlayers) are counted at the login.
 * The 2013 client connects on 进入 and logs in at once, so a connection is one not logged in for
 * a moment only; one refused here is back on its start screen within 20 seconds (the rebuilt
 * login gives up a login not answered: login/Main.as), and 进入 tries again (the client does not
 * reconnect by itself, so a restart brings no storm of them).
 */
export const PENDING_MAX = 40;
export const pendingMax = (maxPlayers?: number) => Math.max(PENDING_MAX, Math.ceil((maxPlayers ?? 0) / 2));
export const PENDING_PER_ADDRESS = 4;
export const PER_ADDRESS = 12;

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
  /** 注册 (the start screen of 联机模式): a new 奥拉 and its password; null if done. */
  register(name: string, pass: string, addr?: string): Promise<string | null>;
  /** 记住密码: a token for the page to keep instead of the password. */
  remember(name: string, pass: string, addr?: string): Promise<{ token?: string; error?: string }>;
  forget(name: string, token: string): Promise<void>;
  /** Whether the server takes new names (注册). */
  readonly registers: boolean;
  /**
   * Whether a new connection from this address is taken now (a shared server's host asks before
   * it attaches one): null if so, else why not ("full", "address").
   */
  admit(remote: string): "full" | "address" | null;
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
    clock: new GameClock(o.date || undefined),
    // The players' records live: one object a player, whoever's handler changes it (store.ts).
    store: new LiveRecordStore(o.store, ["user/"], 1000, (key) => {
      // A player in the game keeps his record live.
      try {
        return !!world?.online(decodeURIComponent(key.slice("user/".length)));
      } catch {
        return false;
      }
    }, SAVE_RECORD_MAX),
    recorder: o.recorder ?? new MemoryRecorder(),
    answerPolicy: o.answerPolicy ?? false,
  });
  const w = installSfs2013(emulator, { loadJson: o.loadJson, dev: o.dev, accounts: o.accounts, toolbox: o.toolbox, standalone: o.standalone, maxPlayers: o.maxPlayers });
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
    register: (name, pass, addr) => registerUser(emulator, name, pass, { addr, accounts: o.accounts }),
    remember: (name, pass, addr) => rememberUser(emulator, name, pass, { addr, accounts: o.accounts }),
    forget: (name, token) => forgetToken(emulator, name, token),
    registers: !!o.accounts?.required && !!o.accounts.register,
    admit: (remote) => {
      let pending = 0, mine = 0, minePending = 0;
      for (const s of emulator.sessions) {
        const inGame = !!w.player(s);
        if (!inGame) pending++;
        if (s.link.remote !== remote) continue;
        mine++;
        if (!inGame) minePending++;
      }
      if (mine >= PER_ADDRESS || minePending >= PENDING_PER_ADDRESS) return "address";
      const most = pendingMax(o.maxPlayers);
      if (pending >= most || emulator.sessions.size >= (o.maxPlayers ?? Infinity) + most) return "full";
      return null;
    },
    imports,
    online: () => w.playing(),
  };
}
