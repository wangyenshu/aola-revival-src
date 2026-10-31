// Wire format of the 2013 奥拉星 socket protocol, reconstructed from the surviving
// client libraries (library/socketserver.swf?1301301, library/socketclient.swf?130124):
//
// client -> server   int32 len | u8 packetNum | salt bytes (one: 0x1A) | payload
//                    (len counts packetNum + salt + payload; packetNum runs
//                     0, 1, 4, 13, 40, 121, 0, ... = n*3+1 wrapping at >=127)
//   payload          u8 type (0 sys, 1 ext) | i16 action | i32 roomId | fields
//   sys fields       Login(10016): utf zone, utf user, utf pass
//                    JoinRoom(10012): utf room, bool notSpectator, i32 leaveId,
//                                     bool isTemp, utf pass
//                    LeaveRoom(10013): i32 roomId · Logout(10017) · Hit(10011)
//                    PubMsg(10020): utf msg · SetUvars(10028): i16 n, n x (utf, char, utf)
//                    SetRvars(10027): bool, i16 n, n x (utf, char, utf, bool, bool)
//                    AsObj(10002): utf xml
//   ext fields       XtReq(10033): i16 extId, utf cmd, AMF3 params
//                    XtReqB(10034): raw bytes (first byte = extId)
//
// server -> client   int32 len | payload
//   payload          u8 handler (0 sys, 1 ext, 2 binary ext) | ...
//   sys              i16 action | i32 roomId | fields (see SysWriter)
//   ext              AMF3 object, "_cmd" names the response
//   first bytes      a cross-domain policy XML terminated by 0x00 (the client
//                    discards it; it expects "<" as the very first byte)
//
// bool = one byte, 49 ("1") true / 48 ("0") false. utf = u16 length + UTF-8.

import { amf3Decode, amf3Encode } from "../../core/amf3.ts";
import { concat } from "../../core/bytes.ts";

export const SALT = [26];

export const Up = {
  AsObj: 10002,
  Hit: 10011,
  JoinRoom: 10012,
  LeaveRoom: 10013,
  Login: 10016,
  Logout: 10017,
  PubMsg: 10020,
  SetRvars: 10027,
  SetUvars: 10028,
  XtReq: 10033,
  XtReqB: 10034,
} as const;

export const Down = {
  createRmKO: 20015,
  dataObj: 20016,
  dmnMsg: 20017,
  joinKO: 20018,
  joinOK: 20019,
  leaveRoom: 20020,
  logKO: 20021,
  logout: 20023,
  pubMsg: 20026,
  rVarsUpdate: 20034,
  uER: 20036,
  userGone: 20037,
  uVarsUpdate: 20039,
  xtRes: 20041,
  crossDomain: 20042,
  xtResB: 20043,
} as const;

/** ExtMap from the 2013 client (mmo.framework.comm.ExtMap), id -> name. */
export const EXT_NAMES: Record<number, string> = {
  0: "StartupExtension", 1: "UserExtension", 2: "TeamExtension", 3: "BuddyManagerExtension",
  4: "ScoreManager", 5: "Log", 6: "SurveyExtension", 7: "PlayBookExtension", 8: "OneOffExtension",
  9: "MemberExtension", 10: "GameRealTimeRankManager", 11: "GameMessageList", 12: "UserDisplayExtension",
  13: "PocketMonsterExtension", 14: "PetFightExtension", 15: "PetExtension", 16: "PetExtension2",
  17: "PetEggExtension", 18: "AntiAddictionExtension", 19: "TowerExtension", 20: "SynthesizeExtension",
  21: "MaterialExtension", 22: "RobotExtension", 23: "MatchExtension", 24: "FightRingExtension",
  25: "RobMedalArenaExtension", 26: "HouseExtension", 27: "UserFurntitureInfoExtension", 28: "ShootExtension",
  29: "TaskExtension", 30: "DailyTaskExtension", 31: "GiftBagExtension", 32: "AvatarExtension",
  33: "FollowExtension", 34: "SundriesExtension", 35: "FBExtension", 36: "AvocationExtension",
  37: "MidautumnGameExtension", 38: "MoveStateExtension", 39: "UserStateExtension", 40: "AchievementExtension",
  41: "NewAreaExtension", 42: "HolidayExtension", 43: "MailBoxExtension", 44: "PTowerExtension",
  45: "PMDailyCollectExtension", 46: "VipNickNameExtension", 47: "VipTowerExtension", 48: "PlantExtension",
  49: "PlantItemExtension", 50: "ConnectTestExtension", 52: "WisdomStarExtension", 53: "DonateExtension",
  54: "BalloonExtension", 55: "UserGameExtension", 56: "PlaneChessGameManager", 57: "PeriodicActiveExtension",
  58: "MagicCubicExtension", 59: "WarTeamExtension", 60: "WTBeatBossExtension", 61: "HouseOutSideExtension",
  62: "WarTeamTaskExtension", 63: "PiracyTowerExtension", 64: "MentalHallExtension", 65: "ZooExtension",
  66: "StateExtension", 67: "HotSpringExtension", 68: "MSExtension", 69: "LabExtension", 70: "KOFExtension",
  71: "FieldGameExtension", 72: "HbhBeatBossExtension", 73: "TeamTowerExtension", 74: "LuandouExtension",
  75: "Sundries2ndExtension", 76: "GalaxyExtension", 99: "TrainingExtension",
};

export type VarType = "b" | "n" | "s" | "x";
export interface SfsVar {
  name: string;
  type: VarType;
  value: string;
}

export function encodeVar(name: string, v: unknown): SfsVar {
  if (typeof v === "boolean") return { name, type: "b", value: v ? "1" : "0" };
  if (typeof v === "number") return { name, type: "n", value: String(v) };
  if (v === null || v === undefined) return { name, type: "x", value: "" };
  return { name, type: "s", value: String(v) };
}

export function decodeVar(v: SfsVar): unknown {
  if (v.type === "b") return v.value === "1";
  if (v.type === "n") return Number(v.value);
  if (v.type === "x") return null;
  return v.value;
}

// ───────────────────────── reading client frames ─────────────────────────

const dec = new TextDecoder("utf-8");
const enc = new TextEncoder();

export class Reader {
  private readonly view: DataView;
  readonly bytes: Uint8Array;
  pos = 0;
  constructor(bytes: Uint8Array) {
    this.bytes = bytes;
    this.view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  }
  get left(): number {
    return this.bytes.length - this.pos;
  }
  u8(): number {
    return this.view.getUint8(this.pos++);
  }
  i16(): number {
    const v = this.view.getInt16(this.pos);
    this.pos += 2;
    return v;
  }
  i32(): number {
    const v = this.view.getInt32(this.pos);
    this.pos += 4;
    return v;
  }
  bool(): boolean {
    return this.u8() === 49;
  }
  char(): string {
    return String.fromCharCode(this.u8());
  }
  utf(): string {
    const n = this.view.getUint16(this.pos);
    this.pos += 2;
    const s = dec.decode(this.bytes.subarray(this.pos, this.pos + n));
    this.pos += n;
    return s;
  }
  amf3(): unknown {
    const { value, end } = amf3Decode(this.bytes, this.pos);
    this.pos = end;
    return value;
  }
  rest(): Uint8Array {
    const b = this.bytes.slice(this.pos);
    this.pos = this.bytes.length;
    return b;
  }
}

export type ClientMsg =
  | { kind: "login"; roomId: number; zone: string; user: string; pass: string }
  | { kind: "joinRoom"; roomId: number; room: string; notSpectator: boolean; leaveId: number; isTemp: boolean; pass: string }
  | { kind: "leaveRoom"; roomId: number; leave: number }
  | { kind: "logout"; roomId: number }
  | { kind: "hit"; roomId: number }
  | { kind: "pubMsg"; roomId: number; message: string }
  | { kind: "setUvars"; roomId: number; vars: SfsVar[] }
  | { kind: "setRvars"; roomId: number; setOwnership: boolean; vars: (SfsVar & { persistent: boolean; priv: boolean })[] }
  | { kind: "asObj"; roomId: number; xml: string }
  | { kind: "xt"; roomId: number; extId: number; ext: string; cmd: string; params: unknown }
  | { kind: "xtB"; roomId: number; extId: number; ext: string; data: Uint8Array }
  | { kind: "unknown"; type: number; action: number; roomId: number; data: Uint8Array };

export interface ClientFrame {
  packetNum: number;
  msg: ClientMsg;
}

/** Decode one client frame (the 4-byte length included). */
export function decodeClientFrame(frame: Uint8Array, saltLen = SALT.length): ClientFrame {
  const r = new Reader(frame);
  r.i32();
  const packetNum = r.u8();
  r.pos += saltLen;
  const type = r.u8();
  const action = r.i16();
  const roomId = r.i32();
  let msg: ClientMsg;
  switch (action) {
    case Up.Login:
      msg = { kind: "login", roomId, zone: r.utf(), user: r.utf(), pass: r.utf() };
      break;
    case Up.JoinRoom:
      msg = { kind: "joinRoom", roomId, room: r.utf(), notSpectator: r.bool(), leaveId: r.i32(), isTemp: r.bool(), pass: r.utf() };
      break;
    case Up.LeaveRoom:
      msg = { kind: "leaveRoom", roomId, leave: r.i32() };
      break;
    case Up.Logout:
      msg = { kind: "logout", roomId };
      break;
    case Up.Hit:
      msg = { kind: "hit", roomId };
      break;
    case Up.PubMsg:
      msg = { kind: "pubMsg", roomId, message: r.utf() };
      break;
    case Up.SetUvars: {
      const n = r.i16();
      const vars: SfsVar[] = [];
      for (let i = 0; i < n; i++) vars.push({ name: r.utf(), type: r.char() as VarType, value: r.utf() });
      msg = { kind: "setUvars", roomId, vars };
      break;
    }
    case Up.SetRvars: {
      const setOwnership = r.bool();
      const n = r.i16();
      const vars: (SfsVar & { persistent: boolean; priv: boolean })[] = [];
      for (let i = 0; i < n; i++) {
        vars.push({ name: r.utf(), type: r.char() as VarType, value: r.utf(), persistent: r.bool(), priv: r.bool() });
      }
      msg = { kind: "setRvars", roomId, setOwnership, vars };
      break;
    }
    case Up.AsObj:
      msg = { kind: "asObj", roomId, xml: r.utf() };
      break;
    case Up.XtReq: {
      const extId = r.i16();
      msg = { kind: "xt", roomId, extId, ext: EXT_NAMES[extId] ?? `ext${extId}`, cmd: r.utf(), params: r.left ? r.amf3() : null };
      break;
    }
    case Up.XtReqB: {
      const data = r.rest();
      const extId = data[0];
      msg = { kind: "xtB", roomId, extId, ext: EXT_NAMES[extId] ?? `ext${extId}`, data: data.slice(1) };
      break;
    }
    default:
      msg = { kind: "unknown", type, action, roomId, data: r.rest() };
  }
  return { packetNum, msg };
}

/** Next expected packet number after `prev` (-1 before the first packet). */
export function nextPacketNum(prev: number): number {
  if (prev === -1) return 0;
  const n = prev * 3 + 1;
  return n >= 127 ? 0 : n;
}

// ───────────────────────── writing server frames ─────────────────────────

export class Writer {
  private parts: Uint8Array[] = [];
  private scratch = new DataView(new ArrayBuffer(8));
  u8(v: number): this {
    this.parts.push(new Uint8Array([v & 0xff]));
    return this;
  }
  i16(v: number): this {
    this.scratch.setInt16(0, v);
    this.parts.push(new Uint8Array(this.scratch.buffer.slice(0, 2)));
    return this;
  }
  i32(v: number): this {
    this.scratch.setInt32(0, v);
    this.parts.push(new Uint8Array(this.scratch.buffer.slice(0, 4)));
    return this;
  }
  bool(v: boolean): this {
    return this.u8(v ? 49 : 48);
  }
  char(c: string): this {
    return this.u8(c.charCodeAt(0));
  }
  utf(s: string): this {
    const b = enc.encode(s);
    if (b.length > 0xffff) throw new Error("utf string too long");
    this.parts.push(new Uint8Array([b.length >> 8, b.length & 0xff]), b);
    return this;
  }
  raw(b: Uint8Array): this {
    this.parts.push(b);
    return this;
  }
  vars(vars: SfsVar[]): this {
    this.i16(vars.length);
    for (const v of vars) this.utf(v.name).char(v.type).utf(v.value);
    return this;
  }
  /** The payload alone. */
  body(): Uint8Array {
    return concat(...this.parts);
  }
  /** The payload wrapped in its int32 length. */
  frame(): Uint8Array {
    const body = concat(...this.parts);
    const head = new Uint8Array(4);
    new DataView(head.buffer).setInt32(0, body.length);
    return concat(head, body);
  }
}

function sys(action: number, roomId: number): Writer {
  return new Writer().u8(0).i16(action).i32(roomId);
}

export interface WireUser {
  id: number;
  name: string;
  vars: SfsVar[];
}

export const S = {
  policy(): Uint8Array {
    const xml =
      '<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>';
    return concat(enc.encode(xml), new Uint8Array([0]));
  },
  /** Extension response: an AMF3 object whose "_cmd" names it. */
  ext(obj: Record<string, unknown>): Uint8Array {
    return new Writer().u8(1).raw(amf3Encode(obj)).frame();
  },
  extB(data: Uint8Array): Uint8Array {
    return new Writer().u8(2).raw(data).frame();
  },
  logKO(error: string): Uint8Array {
    return sys(Down.logKO, -1).utf(error).frame();
  },
  logout(): Uint8Array {
    return sys(Down.logout, -1).frame();
  },
  joinOK(room: { id: number; name: string; maxUsers: number; vars: SfsVar[] }, users: WireUser[], joinData = ""): Uint8Array {
    const w = sys(Down.joinOK, room.id).i32(room.id).utf(room.name).i32(room.maxUsers).utf(joinData).vars(room.vars);
    w.i16(users.length);
    for (const u of users) w.i32(u.id).utf(u.name).vars(u.vars);
    return w.frame();
  },
  joinKO(error: string): Uint8Array {
    return sys(Down.joinKO, -1).utf(error).frame();
  },
  userEnterRoom(roomId: number, u: WireUser, isInit = false, joinData = ""): Uint8Array {
    return sys(Down.uER, roomId).i32(u.id).utf(u.name).bool(isInit).utf(joinData).vars(u.vars).frame();
  },
  userGone(roomId: number, userId: number): Uint8Array {
    return sys(Down.userGone, roomId).i32(userId).frame();
  },
  leaveRoom(roomId: number): Uint8Array {
    return sys(Down.leaveRoom, roomId).i32(roomId).frame();
  },
  userVarsUpdate(roomId: number, userId: number, vars: SfsVar[]): Uint8Array {
    return sys(Down.uVarsUpdate, roomId).i32(userId).vars(vars).frame();
  },
  roomVarsUpdate(roomId: number, vars: SfsVar[]): Uint8Array {
    return sys(Down.rVarsUpdate, roomId).vars(vars).frame();
  },
  pubMsg(roomId: number, userId: number, message: string): Uint8Array {
    return sys(Down.pubMsg, roomId).i32(userId).utf(message).frame();
  },
  adminMsg(roomId: number, userId: number, message: string): Uint8Array {
    return sys(Down.dmnMsg, roomId).i32(userId).utf(message).frame();
  },
};

/** Build a client frame exactly as BinaryMsgWriter + writeBinaryToSocket do (for tests and tools). */
export function encodeClientFrame(packetNum: number, payload: Uint8Array, salt = SALT): Uint8Array {
  const head = new Uint8Array(4);
  new DataView(head.buffer).setInt32(0, payload.length + salt.length + 1);
  return concat(head, new Uint8Array([packetNum, ...salt]), payload);
}

export function clientPayload(type: number, action: number, roomId: number): Writer {
  return new Writer().u8(type).i16(action).i32(roomId);
}
