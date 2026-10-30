// The emulator core: sessions, handler dispatch, clock and storage.
// It never touches sockets; transports (TCP, WebSocket, in-page shim) feed it
// bytes through a Link. The same core runs in Node and inside the browser page.

import { GameClock } from "./clock.ts";
import { rawCodec, type Cmd, type Codec, type Message, type OutMessage } from "./codec.ts";
import { FrameSplitter, FramingError, type FramingSpec } from "./framing.ts";
import { isPolicyRequest, policyResponse } from "./policy.ts";
import { frameRecord, type Recorder, MemoryRecorder } from "./recorder.ts";
import { MemoryStore, type Store } from "./store.ts";

export interface Link {
  send(bytes: Uint8Array): void;
  close(): void;
  readonly remote: string;
}

export type Handler = (session: Session, msg: Message, emu: Emulator) => void | Promise<void>;

export interface EmulatorOptions {
  framing?: FramingSpec | null;
  codec?: Codec;
  clock?: GameClock;
  store?: Store;
  recorder?: Recorder;
  /** Answer <policy-file-request/> on game ports (real Flash Player needs it). */
  answerPolicy?: boolean;
}

export class Session {
  readonly id: number;
  readonly port: number;
  readonly link: Link;
  readonly emu: Emulator;
  /** Per-connection game state (user id, current map, …). */
  readonly data: Record<string, unknown> = {};
  closed = false;
  private readonly splitter: FrameSplitter;
  private first = true;

  constructor(id: number, port: number, link: Link, emu: Emulator) {
    this.id = id;
    this.port = port;
    this.link = link;
    this.emu = emu;
    this.splitter = new FrameSplitter(emu.framing);
  }

  /** Bytes arrived from the client. */
  receive(chunk: Uint8Array): void {
    if (this.closed || chunk.length === 0) return;
    if (this.first) {
      this.first = false;
      if (this.emu.answerPolicy && isPolicyRequest(chunk)) {
        this.note("policy request answered");
        this.link.send(policyResponse());
        this.close();
        return;
      }
    }
    let frames: Uint8Array[];
    try {
      frames = this.splitter.push(chunk);
    } catch (e) {
      if (!(e instanceof FramingError)) throw e;
      this.note(`framing error: ${e.message}; switch --framing or fix the spec`);
      this.emu.recorder.record(frameRecord(this.id, this.port, "in", chunk, "unframed bytes"));
      this.close();
      return;
    }
    for (const frame of frames) {
      this.emu.recorder.record(frameRecord(this.id, this.port, "in", frame));
      let msg: Message;
      try {
        msg = this.emu.codec.decode(frame);
      } catch (e) {
        this.note(`decode failed: ${(e as Error).message}`);
        continue;
      }
      this.emu.dispatch(this, msg);
    }
  }

  send(msg: OutMessage): void {
    this.sendBytes(this.emu.codec.encode(msg), msg.raw ? undefined : `cmd ${String(msg.cmd)}`);
  }

  sendBytes(bytes: Uint8Array, note?: string): void {
    if (this.closed) return;
    this.emu.recorder.record(frameRecord(this.id, this.port, "out", bytes, note));
    this.link.send(bytes);
  }

  note(text: string): void {
    this.emu.recorder.record(frameRecord(this.id, this.port, "event", null, text));
  }

  close(): void {
    if (this.closed) return;
    this.closed = true;
    this.link.close();
    this.emu.detach(this);
  }
}

export class Emulator {
  readonly framing: FramingSpec | null;
  readonly codec: Codec;
  readonly clock: GameClock;
  readonly store: Store;
  readonly recorder: Recorder;
  readonly answerPolicy: boolean;
  readonly sessions = new Set<Session>();
  private readonly handlers = new Map<string, Handler>();
  private readonly connectHooks: ((s: Session) => void)[] = [];
  private readonly closeHooks: ((s: Session) => void)[] = [];
  private fallback: Handler = (s, m) => s.note(`unhandled cmd ${String(m.cmd)}`);
  private nextId = 1;

  constructor(opts: EmulatorOptions = {}) {
    this.framing = opts.framing ?? null;
    this.codec = opts.codec ?? rawCodec;
    this.clock = opts.clock ?? new GameClock("2012-08-15");
    this.store = opts.store ?? new MemoryStore();
    this.recorder = opts.recorder ?? new MemoryRecorder();
    this.answerPolicy = opts.answerPolicy ?? true;
  }

  /** Register a handler for a command, optionally only on one port. */
  on(cmd: Cmd, handler: Handler, port?: number): this {
    this.handlers.set(`${port ?? "*"}:${String(cmd)}`, handler);
    return this;
  }

  /** Handler for every command nobody registered (default: log it). */
  onUnhandled(handler: Handler): this {
    this.fallback = handler;
    return this;
  }

  onConnect(hook: (s: Session) => void): this {
    this.connectHooks.push(hook);
    return this;
  }

  onClose(hook: (s: Session) => void): this {
    this.closeHooks.push(hook);
    return this;
  }

  /** A transport accepted a connection. */
  attach(link: Link, port: number): Session {
    const s = new Session(this.nextId++, port, link, this);
    this.sessions.add(s);
    s.note(`connected from ${link.remote}`);
    for (const h of this.connectHooks) h(s);
    return s;
  }

  detach(s: Session): void {
    if (!this.sessions.delete(s)) return;
    s.closed = true;
    s.note("closed");
    for (const h of this.closeHooks) h(s);
  }

  dispatch(s: Session, msg: Message): void {
    const key = String(msg.cmd);
    const h = this.handlers.get(`${s.port}:${key}`) ?? this.handlers.get(`*:${key}`) ?? this.fallback;
    Promise.resolve()
      .then(() => h(s, msg, this))
      .catch((e: unknown) => s.note(`handler for ${key} threw: ${(e as Error).stack ?? String(e)}`));
  }

  /** Send to every session matching the filter (e.g. everyone on the same map). */
  broadcast(msg: OutMessage, filter: (s: Session) => boolean = () => true): void {
    for (const s of this.sessions) if (filter(s)) s.send(msg);
  }
}
