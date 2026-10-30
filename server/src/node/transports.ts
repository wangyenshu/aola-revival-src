// Node transports: raw TCP (Flash projector, Ruffle desktop), WebSocket
// (Ruffle web via socketProxy) and the port-843 policy server.

import net from "node:net";
import type http from "node:http";
import { WebSocketServer, type WebSocket } from "ws";
import type { Emulator } from "../core/emulator.ts";
import { isPolicyRequest, policyResponse } from "../core/policy.ts";

const u8 = (b: Buffer): Uint8Array => new Uint8Array(b.buffer, b.byteOffset, b.byteLength);

export function listenTcp(emu: Emulator, port: number, host: string): Promise<net.Server> {
  const server = net.createServer((sock) => {
    sock.setNoDelay(true);
    const session = emu.attach(
      {
        remote: `tcp ${sock.remoteAddress}:${sock.remotePort}`,
        send: (b) => sock.write(b),
        close: () => sock.end(),
      },
      sock.localPort ?? port,
    );
    sock.on("data", (d) => session.receive(u8(d)));
    sock.on("close", () => emu.detach(session));
    sock.on("error", () => emu.detach(session));
  });
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, host, () => resolve(server));
  });
}

/**
 * WebSocket endpoint on the HTTP server: ws://host:http_port/__socket/<game port>.
 * Ruffle web config: socketProxy: [{host: "<server ip>", port: 8001,
 *   proxyUrl: "ws://127.0.0.1:8080/__socket/8001"}]
 */
export function attachWebSocket(emu: Emulator, server: http.Server): WebSocketServer {
  const wss = new WebSocketServer({ noServer: true });
  server.on("upgrade", (req, socket, head) => {
    const m = /^\/__socket\/(\d+)/.exec(req.url ?? "");
    if (!m) {
      socket.destroy();
      return;
    }
    wss.handleUpgrade(req, socket, head, (ws: WebSocket) => {
      const session = emu.attach(
        {
          remote: `ws ${req.socket.remoteAddress}`,
          send: (b) => ws.send(b),
          close: () => ws.close(),
        },
        Number(m[1]),
      );
      ws.on("message", (data, isBinary) => {
        const buf = Array.isArray(data) ? Buffer.concat(data) : Buffer.from(data as ArrayBuffer);
        session.receive(isBinary ? u8(buf) : new TextEncoder().encode(buf.toString("utf8")));
      });
      ws.on("close", () => emu.detach(session));
      ws.on("error", () => emu.detach(session));
    });
  });
  return wss;
}

/** Flash Player asks port 843 for a socket policy before connecting anywhere. */
export function listenPolicy(port: number, host: string, log: (s: string) => void): Promise<net.Server> {
  const server = net.createServer((sock) => {
    sock.once("data", (d) => {
      if (isPolicyRequest(u8(d))) {
        sock.end(policyResponse());
        log(`policy served to ${sock.remoteAddress}`);
      } else sock.destroy();
    });
    sock.on("error", () => {});
  });
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, host, () => resolve(server));
  });
}
