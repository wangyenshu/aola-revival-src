// Development handlers used by the end-to-end test: they let a known AS3
// socket client (web-socket-js's WebSocketMain.swf) complete a WebSocket
// handshake against the emulator and receive a greeting. Nothing here is part
// of 奥拉星; it proves the pipeline mirror -> Ruffle -> socket -> emulator works.
// Both the RFC 6455 handshake and the older hixie-76 one (which the 2013-era
// SWF in test/e2e/fixtures speaks) are supported.

import { concat, fromUtf8, utf8 } from "../core/bytes.ts";
import type { Emulator, Session } from "../core/emulator.ts";
import { md5 } from "./md5.ts";

const WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

async function sha1Base64(s: string): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-1", new TextEncoder().encode(s)));
  let bin = "";
  for (const b of digest) bin += String.fromCharCode(b);
  return btoa(bin);
}

function header(text: string, name: string): string | undefined {
  return new RegExp(`^${name}:[ \\t]*(.*?)\\r?$`, "im").exec(text)?.[1];
}

/** hixie-76: digits of the key as a number, divided by its count of spaces. */
function hixieKey(key: string): Uint8Array {
  const n = Number(key.replace(/\D/g, "")) / (key.split(" ").length - 1);
  const out = new Uint8Array(4);
  new DataView(out.buffer).setUint32(0, n);
  return out;
}

interface DemoState {
  buf: Uint8Array;
  mode?: "rfc6455" | "hixie76";
}

/** Answers a WebSocket upgrade, then sends a greeting and echoes text frames. */
export function installHandshakeDemo(emu: Emulator, greeting = "hello from the 2012 emulator"): void {
  const hello = () => `${greeting}; clock=${emu.clock.now().toISOString().slice(0, 10)}`;
  emu.onUnhandled(async (s: Session, msg) => {
    const st = (s.data.demo ??= { buf: new Uint8Array(0) }) as DemoState;
    st.buf = concat(st.buf, msg.raw);

    if (!st.mode) {
      const text = fromUtf8(st.buf);
      const end = text.indexOf("\r\n\r\n");
      if (end < 0) return;
      const headBytes = utf8(text.slice(0, end + 4)).length;
      const key = header(text, "Sec-WebSocket-Key");
      if (key) {
        st.mode = "rfc6455";
        st.buf = st.buf.slice(headBytes);
        s.sendBytes(
          utf8(
            "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n" +
              `Sec-WebSocket-Accept: ${await sha1Base64(key + WS_GUID)}\r\n\r\n`,
          ),
          "demo: rfc6455 upgrade",
        );
        s.sendBytes(concat(new Uint8Array([0x81, utf8(hello()).length]), utf8(hello())), "demo: greeting");
        return;
      }
      const k1 = header(text, "Sec-WebSocket-Key1");
      const k2 = header(text, "Sec-WebSocket-Key2");
      if (k1 && k2) {
        if (st.buf.length < headBytes + 8) return; // wait for the 8-byte key3
        const key3 = st.buf.slice(headBytes, headBytes + 8);
        st.buf = st.buf.slice(headBytes + 8);
        st.mode = "hixie76";
        const host = header(text, "Host") ?? "localhost";
        const origin = header(text, "Origin") ?? "null";
        const path = /^GET (\S+)/.exec(text)?.[1] ?? "/";
        s.sendBytes(
          concat(
            utf8(
              "HTTP/1.1 101 WebSocket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\n" +
                `Sec-WebSocket-Origin: ${origin}\r\nSec-WebSocket-Location: ws://${host}${path}\r\n\r\n`,
            ),
            md5(concat(hixieKey(k1), hixieKey(k2), key3)),
          ),
          "demo: hixie-76 upgrade",
        );
        s.sendBytes(concat(new Uint8Array([0]), utf8(hello()), new Uint8Array([0xff])), "demo: greeting");
        return;
      }
      s.note("demo: not a WebSocket upgrade");
      return;
    }

    if (st.mode === "hixie76") {
      // Frames: 0x00 <utf-8> 0xFF
      for (;;) {
        const endIdx = st.buf.indexOf(0xff);
        if (st.buf[0] !== 0x00 || endIdx < 0) break;
        const text = fromUtf8(st.buf.subarray(1, endIdx));
        st.buf = st.buf.slice(endIdx + 1);
        s.sendBytes(concat(new Uint8Array([0]), utf8("echo: " + text), new Uint8Array([0xff])), "demo: echo");
      }
      return;
    }

    // RFC 6455 client frames are masked (short frames only in this demo).
    const b = st.buf;
    if (b.length < 6) return;
    const len = b[1] & 0x7f;
    if (b.length < 6 + len) return;
    const mask = b.subarray(2, 6);
    const data = b.subarray(6, 6 + len).map((x, i) => x ^ mask[i % 4]);
    st.buf = b.slice(6 + len);
    const reply = utf8("echo: " + fromUtf8(data));
    s.sendBytes(concat(new Uint8Array([0x81, reply.length]), reply), "demo: echo");
  });
}
