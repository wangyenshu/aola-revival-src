// Server side of the 2013 protocol: zone login, rooms (one per scene), user and
// room variables, public chat, and dispatch of extension requests to handlers.
// Behaviour follows SmartFoxServer 1.x, which the 2013 client library mirrors:
// variable updates and chat are echoed to everyone in the room, sender included.

import type { Codec, Message } from "../../core/codec.ts";
import type { Emulator, Session } from "../../core/emulator.ts";
import type { FramingSpec } from "../../core/framing.ts";
import {
  type ClientMsg,
  type SfsVar,
  type WireUser,
  S,
  decodeClientFrame,
  decodeVar,
  encodeVar,
  nextPacketNum,
} from "./protocol.ts";

/** int32 length counting the bytes after it. */
export const SFS2013_FRAMING: FramingSpec = {
  lengthOffset: 0,
  lengthBytes: 4,
  littleEndian: false,
  lengthIncludesHeader: false,
  headerBytes: 4,
  maxFrame: 1 << 20,
};

export const sfs2013Codec: Codec = {
  name: "sfs2013",
  decode(frame: Uint8Array): Message {
    const f = decodeClientFrame(frame);
    const cmd = f.msg.kind === "xt" || f.msg.kind === "xtB" ? `${f.msg.ext}.${f.msg.kind === "xt" ? f.msg.cmd : "bytes"}` : f.msg.kind;
    return { cmd, seq: f.packetNum, body: f.msg, raw: frame };
  },
  encode() {
    throw new Error("sfs2013: send with Session.sendBytes(S.*)");
  },
};

/** What an older page of the same 奥拉 is told when a new login takes over. */
export const REPLACED_TEXT = "你的奥拉在别的地方登录了，这里的连接已经断开。";

export interface PlayerState {
  id: number;
  name: string;
  vars: Map<string, SfsVar>;
  room?: Room;
  lastPacket: number;
  /** When this player last chatted (pubMsg), ms. */
  lastChat?: number;
}

/** The scene of a room (Room.scene; its name before "@"). */
export const sceneOfRoom = (r?: { name: string; scene?: string }): string => (r ? r.scene ?? r.name.split("@")[0] : "");

export interface Room {
  id: number;
  name: string;
  /** The scene it is a room of: its name before "@" (a 副本's or 时空隧道's room of one player, "fbaixi1@奥拉A"). */
  scene: string;
  maxUsers: number;
  vars: Map<string, SfsVar>;
  members: Set<Session>;
  isTemp: boolean;
}

export interface XtContext {
  session: Session;
  player: PlayerState;
  world: World;
  params: Record<string, unknown>;
  /** Send an extension response to this player; "_cmd" defaults to the request cmd. */
  reply(obj: Record<string, unknown>, cmd?: string): void;
  /** Send an extension response to everyone in the player's room. */
  broadcast(obj: Record<string, unknown>, cmd: string, includeSelf?: boolean): void;
}

export type XtHandler = (ctx: XtContext, cmd: string) => void | Promise<void>;

export interface LoginResult {
  id: number;
  name: string;
  /** Refused (a wrong password, a bad name): the client is told, and nobody logs in. */
  error?: string;
  vars?: Record<string, unknown>;
  extra?: Record<string, unknown>;
}

export interface WorldOptions {
  /** Resolve a login to a player id/name (default: sequential ids, name as given). */
  login?: (zone: string, user: string, pass: string, session: Session) => Promise<LoginResult> | LoginResult;
  /** A refused login is answered this much later (a shared server: guessing passwords is slow). */
  refuseDelayMs?: number;
  /** A connection that has not logged in this long after it came is closed (0: never). */
  loginWaitMs?: number;
  /** Called after a player joins a room. */
  onJoin?: (session: Session, player: PlayerState, room: Room) => void;
  /** Check client packet numbers (default true: mismatches are logged, not fatal). */
  checkPacketNumbers?: boolean;
}

const PLAYER = "sfs2013.player";
/** A room's name, at most (the longest of the game's: a team's mod room, "sandboxroom|…"). */
export const ROOM_NAME_MAX = 500;
/** Rooms at once, at most. */
export const ROOMS_MAX = 5000;
/** A chat line (pubMsg), at most. */
export const CHAT_MAX = 300;
/** A chat line from one session at most this often (ms). */
export const CHAT_EVERY_MS = 300;
/** A room variable's name and value, at most. */
export const RVAR_MAX = 256;
/** A player's user variables: at most this many, their names and values together at most UVAR_BYTES. */
export const UVARS_MAX = 64;
export const UVAR_BYTES = 8192;
/** Rooms that go when their last member leaves: homes, 沙盒 rooms, a player's 副本 rooms. */
const TEMP_ROOM = /_Home$|^sandboxroom[_|]|@/;

const utf8 = new TextEncoder();
/** The bytes variables take on the wire (their names and values as UTF-8). */
function varBytes(vars: Iterable<SfsVar>): number {
  let n = 0;
  for (const v of vars) n += utf8.encode(v.name).length + utf8.encode(String(v.value ?? "")).length;
  return n;
}

export class World {
  readonly rooms = new Map<string, Room>();
  readonly handlers = new Map<string, XtHandler>();
  private nextRoomId = 1;
  private nextUserId = 10001;
  private readonly emu: Emulator;
  private readonly opts: WorldOptions;

  constructor(emu: Emulator, opts: WorldOptions = {}) {
    this.emu = emu;
    this.opts = opts;
    emu.onConnect((s) => {
      s.sendBytes(S.policy(), "sfs2013: policy (client discards it)");
      // A connection that never logs in holds a place of the server's (and of its address's).
      if (this.opts.loginWaitMs) {
        const t = setTimeout(() => {
          if (!s.closed && !this.player(s)) {
            s.note("sfs2013: no login in time, closed");
            s.close();
          }
        }, this.opts.loginWaitMs);
        (t as { unref?: () => void }).unref?.();
      }
    });
    emu.onClose((s) => {
      if (this.player(s)) for (const h of this.leaveHooks) h(s);
      this.leave(s, true);
    });
    emu.onUnhandled((s, m) => this.handle(s, m.body as ClientMsg, m.seq ?? 0));
  }

  private readonly leaveHooks: ((s: Session) => void)[] = [];

  /** Called when a logged-in 奥拉's connection ends (before it leaves its room). */
  onLeaveGame(hook: (s: Session) => void): void {
    this.leaveHooks.push(hook);
  }

  private readonly joinHooks: ((s: Session, p: PlayerState, room: Room, from: string) => void)[] = [];

  /** Called when an 奥拉 has come into a room (from: the room it was in before, or ""). */
  onJoinRoom(hook: (s: Session, p: PlayerState, room: Room, from: string) => void): void {
    this.joinHooks.push(hook);
  }

  /** Register an extension handler: "SundriesExtension.70_12", or "SundriesExtension.*". */
  xt(key: string, handler: XtHandler): this {
    this.handlers.set(key, handler);
    return this;
  }

  player(s: Session): PlayerState | undefined {
    return s.data[PLAYER] as PlayerState | undefined;
  }

  room(name: string, isTemp = false): Room {
    let r = this.rooms.get(name);
    if (!r) {
      r = { id: this.nextRoomId++, name, scene: name.split("@")[0], maxUsers: 100, vars: new Map(), members: new Set(), isTemp };
      this.rooms.set(name, r);
    }
    return r;
  }

  roomById(id: number): Room | undefined {
    for (const r of this.rooms.values()) if (r.id === id) return r;
    return undefined;
  }

  wireUser(p: PlayerState): WireUser {
    return { id: p.id, name: p.name, vars: [...p.vars.values()] };
  }

  /** Change a player's user variables from the server side and tell the room (the player too). */
  setUserVars(s: Session, vars: Record<string, unknown>): void {
    const p = this.player(s);
    if (!p) return;
    const list = Object.entries(vars).map(([k, v]) => encodeVar(k, v));
    for (const v of list) {
      if (v.type === "x") p.vars.delete(v.name);
      else p.vars.set(v.name, v);
    }
    if (p.room) this.sendRoom(p.room, S.userVarsUpdate(p.room.id, p.id, list));
    else s.sendBytes(S.userVarsUpdate(0, p.id, list));
  }

  /** One user variable, set and told only when it changes (a following 亚比's "p", which several paths set). */
  setUserVarOnce(s: Session, name: string, value: unknown): void {
    const now = this.player(s)?.vars.get(name);
    const v = encodeVar(name, value);
    if (now && now.type === v.type && now.value === v.value) return;
    this.setUserVars(s, { [name]: value });
  }

  /** The session of the 奥拉 of that name in the game, if any. */
  online(name: string): Session | undefined {
    for (const s of this.emu.sessions) if (this.player(s)?.name === name) return s;
    return undefined;
  }

  /** Every 奥拉 in the game: name, id and room. */
  players(): { session: Session; player: PlayerState }[] {
    const out: { session: Session; player: PlayerState }[] = [];
    for (const s of this.emu.sessions) {
      const p = this.player(s);
      if (p) out.push({ session: s, player: p });
    }
    return out;
  }

  /** An extension message to one session from the server side (no request). */
  push(s: Session, cmd: string, obj: Record<string, unknown>): void {
    s.sendBytes(S.ext({ _cmd: cmd, ...obj }), `xt push ${cmd}`);
  }

  sendRoom(room: Room, bytes: Uint8Array, except?: Session, note?: string): void {
    for (const m of room.members) if (m !== except) m.sendBytes(bytes, note);
  }

  private async handle(s: Session, msg: ClientMsg, packetNum: number): Promise<void> {
    const p = this.player(s);
    if (p && this.opts.checkPacketNumbers !== false) {
      const want = nextPacketNum(p.lastPacket);
      if (packetNum !== want) s.note(`sfs2013: packet number ${packetNum}, expected ${want}`);
      p.lastPacket = packetNum;
    }
    switch (msg.kind) {
      case "login":
        return this.login(s, msg.zone, msg.user, msg.pass, packetNum);
      case "joinRoom":
        return this.join(s, msg.room, msg.isTemp);
      case "leaveRoom":
        this.leave(s);
        s.sendBytes(S.leaveRoom(msg.leave));
        return;
      case "logout":
        if (p) for (const h of this.leaveHooks) h(s);
        this.leave(s);
        s.sendBytes(S.logout());
        s.data[PLAYER] = undefined;
        return;
      case "hit":
        return;
      case "pubMsg": {
        // Bounded: a long line, or many at once, would reach everyone in the room many times over.
        if (!p?.room || msg.message.length > CHAT_MAX) return;
        const now = Date.now();
        if (now - (p.lastChat ?? 0) < CHAT_EVERY_MS) return;
        p.lastChat = now;
        this.sendRoom(p.room, S.pubMsg(p.room.id, p.id, msg.message));
        return;
      }
      case "setUvars": {
        // Bounded: each player's variables reach everyone who enters his room (joinOK).
        if (!p || msg.vars.length > UVARS_MAX) return;
        const next = new Map(p.vars);
        for (const v of msg.vars) {
          if (v.type === "x") next.delete(v.name);
          else next.set(v.name, v);
        }
        if (next.size > UVARS_MAX || varBytes(next.values()) > UVAR_BYTES) {
          s.note(`sfs2013: user variables of "${p.name}" over the limit, not set`);
          return;
        }
        p.vars = next;
        if (p.room) this.sendRoom(p.room, S.userVarsUpdate(p.room.id, p.id, msg.vars));
        return;
      }
      case "setRvars": {
        // Only in a room the client made (a home's, a 沙盒's, a 副本's: temp rooms): a scene's
        // variables are everyone's, and the 2013 client sets none there. Bounded in number and size.
        if (!p?.room || !p.room.isTemp) return;
        const vars = msg.vars.filter((v) => v.name.length <= RVAR_MAX && String(v.value ?? "").length <= RVAR_MAX).slice(0, 50);
        for (const v of vars) {
          if (v.type === "x") p.room.vars.delete(v.name);
          else if (p.room.vars.size < 50 || p.room.vars.has(v.name)) p.room.vars.set(v.name, v);
        }
        if (vars.length) this.sendRoom(p.room, S.roomVarsUpdate(p.room.id, vars));
        return;
      }
      case "xt":
        return this.dispatchXt(s, msg.ext, msg.cmd, msg.params);
      default:
        s.note(`sfs2013: unhandled ${msg.kind}`);
    }
  }

  /** Sessions whose login is being checked: one at a time a session. */
  private readonly loggingIn = new WeakSet<Session>();

  private async login(s: Session, zone: string, user: string, pass: string, packetNum: number): Promise<void> {
    // One login a session: another while one is checked, or once logged in, is not answered
    // (the 2013 client logs in once a connection).
    if (this.loggingIn.has(s) || this.player(s)) {
      s.note(`sfs2013: a second login on one connection ignored`);
      return;
    }
    this.loggingIn.add(s);
    let r: LoginResult;
    try {
      r = this.opts.login ? await this.opts.login(zone, user, pass, s) : { id: this.nextUserId++, name: user || `aola${this.nextUserId}` };
    } catch (err) {
      this.loggingIn.delete(s);
      throw err;
    }
    if (s.closed) return void this.loggingIn.delete(s);
    if (r.error) {
      s.note(`sfs2013: login of "${user}" refused: ${r.error}`);
      // A wrong password: the answer a second later, and no other try on this connection till
      // then (guessing one after another is slow).
      if (this.opts.refuseDelayMs) await new Promise((ok) => setTimeout(ok, this.opts.refuseDelayMs));
      this.loggingIn.delete(s);
      s.sendBytes(S.logKO(r.error), "logKO");
      return;
    }
    this.loggingIn.delete(s);
    // One session a name: a second login of the same 奥拉 (another tab, a reconnect) takes over;
    // the old page is told why before its connection closes (the rebuilt Social.as shows it).
    for (const other of this.emu.sessions) {
      if (other !== s && this.player(other)?.name === r.name) {
        for (const h of this.leaveHooks) h(other);
        this.leave(other, true);
        other.sendBytes(S.ext({ _cmd: "revival_replaced", msg: REPLACED_TEXT }), "revival_replaced");
        other.close();
      }
    }
    const p: PlayerState = { id: r.id, name: r.name, vars: new Map(), lastPacket: packetNum };
    for (const [k, v] of Object.entries(r.vars ?? {})) p.vars.set(k, encodeVar(k, v));
    s.data[PLAYER] = p;
    s.note(`sfs2013: ${r.name} (#${r.id}) logged in to zone "${zone}"`);
    s.sendBytes(
      S.ext({ _cmd: "logOK", id: r.id, n: r.name, lastLoginTime: this.emu.clock.now().getTime(), ...r.extra }),
      "logOK",
    );
  }

  join(s: Session, name: string, isTemp = false): void {
    const p = this.player(s);
    if (!p) {
      s.sendBytes(S.joinKO("not logged in"));
      return;
    }
    const from = p.room?.name ?? "";
    this.leave(s);
    // The rooms a client may name: not too long, and not without end. Any room goes when its last
    // member leaves (a scene's holds nothing of its own: its variables are set only in temp
    // rooms), so the rooms standing are those with someone in them, at most one a session plus
    // what rooms the one-player page keeps; one client cannot fill the table for all.
    if (name.length > ROOM_NAME_MAX || (!this.rooms.has(name) && this.rooms.size >= ROOMS_MAX)) {
      s.sendBytes(S.joinKO("no such room"));
      return;
    }
    // Which rooms are temporary is the server's rule (a client's flag would open room variables
    // in a scene; no 2013 module sets it).
    void isTemp;
    const room = this.room(name, TEMP_ROOM.test(name));
    const users = [...room.members, s].flatMap((m) => {
      const mp = this.player(m);
      return mp ? [this.wireUser(mp)] : [];
    });
    // Built before he is counted in: a reply that cannot be built leaves him out of the room.
    let ok: Uint8Array;
    try {
      ok = S.joinOK({ id: room.id, name: room.name, maxUsers: room.maxUsers, vars: [...room.vars.values()] }, users);
    } catch (err) {
      s.note(`sfs2013: joinOK ${name} not built: ${(err as Error).message}`);
      if (!room.members.size) this.rooms.delete(room.name);
      s.sendBytes(S.joinKO("no such room"));
      return;
    }
    room.members.add(s);
    p.room = room;
    s.sendBytes(ok, `joinOK ${name}`);
    this.sendRoom(room, S.userEnterRoom(room.id, this.wireUser(p)), s);
    this.opts.onJoin?.(s, p, room);
    for (const h of this.joinHooks) h(s, p, room, from);
  }

  leave(s: Session, gone = false): void {
    const p = this.player(s);
    const room = p?.room;
    if (!p || !room) return;
    room.members.delete(s);
    p.room = undefined;
    this.sendRoom(room, S.userGone(room.id, p.id));
    if (room.members.size === 0) this.rooms.delete(room.name);
    if (gone) s.data[PLAYER] = undefined;
  }

  /**
   * One player's extension requests run one after another, as on the 2013
   * server: handlers load the player's record, change it and save it, and two
   * at once (say a task step and a new 亚比) would lose one change.
   */
  private readonly xtQueues = new WeakMap<Session, Promise<void>>();

  private dispatchXt(s: Session, ext: string, cmd: string, params: unknown): Promise<void> {
    const run = (this.xtQueues.get(s) ?? Promise.resolve()).then(() => this.runXt(s, ext, cmd, params));
    this.xtQueues.set(
      s,
      run.catch(() => undefined),
    );
    return run;
  }

  private async runXt(s: Session, ext: string, cmd: string, params: unknown): Promise<void> {
    const p = this.player(s);
    const h = this.handlers.get(`${ext}.${cmd}`) ?? this.handlers.get(`${ext}.*`) ?? this.handlers.get("*");
    if (!p || !h) {
      s.note(`sfs2013: unhandled xt ${ext}.${cmd} ${JSON.stringify(params)?.slice(0, 300)}`);
      return;
    }
    const ctx: XtContext = {
      session: s,
      player: p,
      world: this,
      params: (params && typeof params === "object" ? params : {}) as Record<string, unknown>,
      reply: (obj, c) => {
        const name = c ?? cmd;
        if (name === "onAmountUpdated" && typeof obj.amount === "string") {
          // 亚比蛋 (type 5) are not told: the 2013 client's PetEggService (material/materialservice)
          // throws "not implement" for an egg it does not list (getNewUserMaterial), and the eggs
          // are read from the server where they are shown (the 孵化器's 1-2, the 物品's 1=1).
          const amount = obj.amount.split("#").filter((a) => !a.startsWith("5_")).join("#");
          if (!amount) return;
          obj = { ...obj, amount };
        }
        s.sendBytes(S.ext({ _cmd: name, ...obj }), `xt reply ${name}`);
      },
      broadcast: (obj, c, includeSelf = true) => {
        if (p.room) this.sendRoom(p.room, S.ext({ _cmd: c, ...obj }), includeSelf ? undefined : s, `xt broadcast ${c}`);
      },
    };
    await h(ctx, cmd);
  }
}

export function varsToObject(vars: Iterable<SfsVar>): Record<string, unknown> {
  const o: Record<string, unknown> = {};
  for (const v of vars) o[v.name] = decodeVar(v);
  return o;
}
