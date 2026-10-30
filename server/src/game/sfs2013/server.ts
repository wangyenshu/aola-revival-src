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

export interface PlayerState {
  id: number;
  name: string;
  vars: Map<string, SfsVar>;
  room?: Room;
  lastPacket: number;
}

export interface Room {
  id: number;
  name: string;
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
  vars?: Record<string, unknown>;
  extra?: Record<string, unknown>;
}

export interface WorldOptions {
  /** Resolve a login to a player id/name (default: sequential ids, name as given). */
  login?: (zone: string, user: string, pass: string, session: Session) => Promise<LoginResult> | LoginResult;
  /** Called after a player joins a room. */
  onJoin?: (session: Session, player: PlayerState, room: Room) => void;
  /** Check client packet numbers (default true: mismatches are logged, not fatal). */
  checkPacketNumbers?: boolean;
}

const PLAYER = "sfs2013.player";

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
    emu.onConnect((s) => s.sendBytes(S.policy(), "sfs2013: policy (client discards it)"));
    emu.onClose((s) => this.leave(s, true));
    emu.onUnhandled((s, m) => this.handle(s, m.body as ClientMsg, m.seq ?? 0));
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
      r = { id: this.nextRoomId++, name, maxUsers: 100, vars: new Map(), members: new Set(), isTemp };
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
    for (const v of list) p.vars.set(v.name, v);
    if (p.room) this.sendRoom(p.room, S.userVarsUpdate(p.room.id, p.id, list));
    else s.sendBytes(S.userVarsUpdate(0, p.id, list));
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
        this.leave(s);
        s.sendBytes(S.logout());
        s.data[PLAYER] = undefined;
        return;
      case "hit":
        return;
      case "pubMsg":
        if (p?.room) this.sendRoom(p.room, S.pubMsg(p.room.id, p.id, msg.message));
        return;
      case "setUvars":
        if (!p) return;
        for (const v of msg.vars) {
          if (v.type === "x") p.vars.delete(v.name);
          else p.vars.set(v.name, v);
        }
        if (p.room) this.sendRoom(p.room, S.userVarsUpdate(p.room.id, p.id, msg.vars));
        return;
      case "setRvars":
        if (!p?.room) return;
        for (const v of msg.vars) {
          if (v.type === "x") p.room.vars.delete(v.name);
          else p.room.vars.set(v.name, v);
        }
        this.sendRoom(p.room, S.roomVarsUpdate(p.room.id, msg.vars));
        return;
      case "xt":
        return this.dispatchXt(s, msg.ext, msg.cmd, msg.params);
      default:
        s.note(`sfs2013: unhandled ${msg.kind}`);
    }
  }

  private async login(s: Session, zone: string, user: string, pass: string, packetNum: number): Promise<void> {
    const r = this.opts.login
      ? await this.opts.login(zone, user, pass, s)
      : { id: this.nextUserId++, name: user || `aola${this.nextUserId}` };
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
    this.leave(s);
    const room = this.room(name, isTemp);
    room.members.add(s);
    p.room = room;
    const users = [...room.members].map((m) => this.wireUser(this.player(m)!));
    s.sendBytes(S.joinOK({ id: room.id, name: room.name, maxUsers: room.maxUsers, vars: [...room.vars.values()] }, users), `joinOK ${name}`);
    this.sendRoom(room, S.userEnterRoom(room.id, this.wireUser(p)), s);
    this.opts.onJoin?.(s, p, room);
  }

  leave(s: Session, gone = false): void {
    const p = this.player(s);
    const room = p?.room;
    if (!p || !room) return;
    room.members.delete(s);
    p.room = undefined;
    this.sendRoom(room, S.userGone(room.id, p.id));
    if (room.isTemp && room.members.size === 0) this.rooms.delete(room.name);
    if (gone) s.data[PLAYER] = undefined;
  }

  private async dispatchXt(s: Session, ext: string, cmd: string, params: unknown): Promise<void> {
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
      reply: (obj, c) => s.sendBytes(S.ext({ _cmd: c ?? cmd, ...obj }), `xt reply ${c ?? cmd}`),
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
