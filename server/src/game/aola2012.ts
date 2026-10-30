// 奥拉星 2012 game logic lives here, written as the protocol is decoded.
//
// Build it along the boot path (doc, Phase 2 step 4), one milestone at a time:
//   M0  HTTP: boot page, version manifest, config files come from the mirror;
//       emulate any login/.jsp endpoint that shows up in the miss log.
//   M1  socket login -> user info -> enter first map (stand in the map)
//   M2  walk, chat, pet bag, wild battle, catch
//   M3  NPC tasks, shops, then activities by how fondly people remember them
//
// Pattern for each command, once the codec exists:
//
//   emu.on(LOGIN, async (s, msg) => {
//     const user = (await emu.store.get<User>(`user/${uid}`)) ?? newUser(uid);
//     s.data.uid = uid;
//     s.send({ cmd: LOGIN, seq: msg.seq, body: { ...user, serverTime: emu.clock.unix() } });
//   });
//
// Server-side numbers (damage, catch rate, drops, EXP curve) go in data files
// under ../../data/ with a note of the evidence each one is based on.

import type { Emulator } from "../core/emulator.ts";
import type { DynamicHandler } from "../node/http.ts";

export function installAola2012(emu: Emulator): void {
  emu.onConnect((s) => s.note(`listen mode: game clock reads ${emu.clock.now().toISOString()}`));
}

/** Emulated HTTP endpoints, keyed "host/path" (see the 404 log for what to add). */
export function aola2012Http(): Map<string, DynamicHandler> {
  return new Map<string, DynamicHandler>([
    // ["aola.100bt.com/play/login.jsp", async (req) => ({ body: "…" })],
  ]);
}
