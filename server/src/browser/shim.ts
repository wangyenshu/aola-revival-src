// In-page transport for a fully offline browser copy.
//
// Ruffle's web build has no raw TCP; its socketProxy option maps a game
// host:port to a WebSocket URL, and its wasm glue constructs that socket with
// the page's global `WebSocket` at call time. Replacing the global with this
// class (for matching URLs only) connects Ruffle straight to an emulator
// running in the same page: no server process, no network.

import type { Emulator } from "../core/emulator.ts";

export interface ShimOptions {
  /** Return the game port for URLs the emulator should take, else undefined. */
  match: (url: string) => number | undefined;
}

type Listener = (ev: Event) => void;

export function installInPageSockets(emu: Emulator, opts: ShimOptions): typeof WebSocket {
  const Real = globalThis.WebSocket;

  class InPageSocket extends EventTarget {
    static readonly CONNECTING = 0;
    static readonly OPEN = 1;
    static readonly CLOSING = 2;
    static readonly CLOSED = 3;
    readonly CONNECTING = 0;
    readonly OPEN = 1;
    readonly CLOSING = 2;
    readonly CLOSED = 3;
    readonly url: string;
    readonly protocol = "";
    readonly extensions = "";
    readyState = 0;
    binaryType: BinaryType = "blob";
    bufferedAmount = 0;
    onopen: Listener | null = null;
    onmessage: Listener | null = null;
    onclose: Listener | null = null;
    onerror: Listener | null = null;
    private session: ReturnType<Emulator["attach"]> | null = null;

    constructor(url: string | URL, _protocols?: string | string[]) {
      super();
      this.url = String(url);
      const port = opts.match(this.url)!;
      queueMicrotask(() => {
        // Open before attaching: a server that speaks first (the 2013 server
        // sends its policy file on connect) delivers during attach(), and
        // those bytes must not be dropped. Delivery is deferred with
        // setTimeout, so "open" still reaches the client before any message.
        this.readyState = 1;
        this.session = emu.attach(
          {
            remote: `in-page ${this.url}`,
            send: (bytes) => this.deliver(bytes),
            close: () => this.finish(1000, "server closed"),
          },
          port,
        );
        this.fire(new Event("open"), this.onopen);
      });
    }

    send(data: string | ArrayBufferLike | Blob | ArrayBufferView): void {
      if (this.readyState !== 1) throw new DOMException("socket is not open", "InvalidStateError");
      const s = this.session!;
      if (typeof data === "string") s.receive(new TextEncoder().encode(data));
      else if (data instanceof Blob) void data.arrayBuffer().then((b) => s.receive(new Uint8Array(b)));
      else if (ArrayBuffer.isView(data)) s.receive(new Uint8Array(data.buffer, data.byteOffset, data.byteLength).slice());
      else s.receive(new Uint8Array(data as ArrayBuffer).slice());
    }

    close(code = 1000, reason = ""): void {
      if (this.readyState >= 2) return;
      this.readyState = 2;
      const s = this.session;
      queueMicrotask(() => {
        s?.close();
        this.finish(code, reason);
      });
    }

    private deliver(bytes: Uint8Array): void {
      if (this.readyState !== 1) return;
      const copy = bytes.slice();
      const data = this.binaryType === "arraybuffer" ? copy.buffer : new Blob([copy]);
      setTimeout(() => this.fire(new MessageEvent("message", { data }), this.onmessage), 0);
    }

    private finish(code: number, reason: string): void {
      if (this.readyState === 3) return;
      this.readyState = 3;
      setTimeout(() => this.fire(new CloseEvent("close", { code, reason, wasClean: true }), this.onclose), 0);
    }

    private fire(ev: Event, handler: Listener | null): void {
      handler?.call(this, ev);
      this.dispatchEvent(ev);
    }
  }

  const Patched = new Proxy(Real, {
    construct(target, args: [string | URL, (string | string[])?]) {
      return opts.match(String(args[0])) !== undefined
        ? new InPageSocket(args[0], args[1])
        : Reflect.construct(target, args);
    },
  });
  (globalThis as { WebSocket: typeof WebSocket }).WebSocket = Patched;
  return Real;
}
