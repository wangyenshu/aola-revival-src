// The small JSON API of a shared server (Node: src/node/multi.ts, Cloudflare:
// src/cloudflare/worker.ts), for the page's start screen:
//   GET  /__api/status                       -> {ok, online, name, imports}
//   POST /__api/rename {name, pass, to}      -> {ok} or {ok: false, error}   (改名字)
// and for the 工具箱's 存档 (web/saves.js), one 奥拉's save as a file (saves.ts):
//   POST /__api/save/export {name, pass}     -> {ok, save} or {ok: false, error}
//   POST /__api/save/import {name, pass, save, from?}  -> {ok} or {ok: false, error, names?}
//                                              (names: the 奥拉 of a file of several, to choose from)
// A wrong password is answered a second later (and counts towards the name's lock, accounts.ts).

import type { GameHost } from "./host.ts";
import { SAVE_BODY_MAX } from "./saves.ts";

export interface ApiResult {
  status: number;
  body: Record<string, unknown>;
}

/** A request's body, at most (a rename is a few dozen bytes). */
export const API_BODY_MAX = 4096;

/** The body a request to this path may have, at most (an import carries a save file). */
export const apiBodyMax = (pathname: string) => (pathname === "/__api/save/import" ? SAVE_BODY_MAX : API_BODY_MAX);

/** A wrong password's answer waits this long (one after another, guessing is slow). */
export const WRONG_PASS_DELAY_MS = 1000;
const wrongPass = (error: string | undefined) => error === "密码不对哦。";
const later = (ms: number) => new Promise((ok) => setTimeout(ok, ms));

/** addr: the client's address, as its game connection gives it ("ws <ip>": the password lock's). */
export async function handleApi(host: GameHost, pathname: string, method: string, body: string, addr = ""): Promise<ApiResult> {
  if (method === "OPTIONS") return { status: 204, body: {} };
  if (pathname === "/__api/status") return { status: 200, body: { ok: true, online: host.online(), name: "aola-revival", imports: host.imports } };
  if (method !== "POST" || !["/__api/rename", "/__api/save/export", "/__api/save/import"].includes(pathname)) {
    return { status: 404, body: { ok: false, error: "not found" } };
  }
  let p: { name?: unknown; pass?: unknown; to?: unknown; save?: unknown; from?: unknown };
  try {
    p = JSON.parse(body || "{}");
  } catch {
    p = null as never;
  }
  if (!p || typeof p !== "object") return { status: 400, body: { ok: false, error: "请求不对。" } };
  const name = String(p.name ?? ""), pass = String(p.pass ?? "");
  const refused = async (error: string, extra: Record<string, unknown> = {}): Promise<ApiResult> => {
    if (wrongPass(error)) await later(WRONG_PASS_DELAY_MS);
    return { status: 400, body: { ok: false, error, ...extra } };
  };
  if (pathname === "/__api/rename") {
    const error = await host.rename(name, String(p.to ?? ""), pass, addr);
    return error ? refused(error) : { status: 200, body: { ok: true } };
  }
  if (pathname === "/__api/save/export") {
    const r = await host.exportSave(name, pass, addr);
    return r.error || !r.save ? refused(r.error ?? "没有导出。") : { status: 200, body: { ok: true, save: r.save } };
  }
  const r = await host.importSave(name, pass, p.save, p.from == null ? undefined : String(p.from), addr);
  return r.error ? refused(r.error, r.names ? { names: r.names } : {}) : { status: 200, body: { ok: true } };
}
