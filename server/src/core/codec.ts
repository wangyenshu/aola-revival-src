// A codec turns one frame into a Message and back. The real 2012 codec is
// written once the client's packet reader/writer is understood (doc, Phase 2);
// until then the raw codec passes bytes through so everything is logged.

export type Cmd = string | number;

export interface Message {
  cmd: Cmd;
  /** Sequence or request id, if the protocol has one. */
  seq?: number;
  /** Decoded body: an object for JSON/AMF protocols, fields for binary ones. */
  body?: unknown;
  /** The exact frame bytes (header included). */
  raw: Uint8Array;
}

export interface OutMessage {
  cmd: Cmd;
  seq?: number;
  body?: unknown;
  /** Send these bytes as-is instead of encoding. */
  raw?: Uint8Array;
}

export interface Codec {
  readonly name: string;
  decode(frame: Uint8Array): Message;
  encode(msg: OutMessage): Uint8Array;
}

export const rawCodec: Codec = {
  name: "raw",
  decode: (frame) => ({ cmd: "raw", raw: frame }),
  encode: (msg) => {
    if (!msg.raw) throw new Error(`raw codec cannot encode cmd ${String(msg.cmd)} without raw bytes`);
    return msg.raw;
  },
};
