import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { installClockStar, type ClockOwner } from "../src/game/sfs2013/clockstar.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import { recordWin } from "../src/game/sfs2013/wins.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};

test("时钟大殿: the clocks say which are fixed (zb-1), a clock is fixed after its 通灵巫师 is beaten, then 泽秒 becomes 泽时", async () => {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVarOnce: () => {}, fights: new Map() } as unknown as World;
  const o: ClockOwner = { id: 1, name: "小奥拉" } as never;
  o.pets = [makePet(tables, 913, 50, "d", 1)];
  installClockStar(world, { load: async () => o, save: async () => {}, tables: async () => tables });
  const session = { data: {} } as never;
  const call = async (cmd: string, params: Record<string, unknown> = {}) => {
    const out: [string, Record<string, unknown>][] = [];
    const ctx = { params, session, reply: (b: Record<string, unknown>, c = cmd) => out.push([c, b]) } as unknown as XtContext;
    await handlers.get(`PeriodicActiveExtension.${cmd}`)!(ctx, cmd);
    return out;
  };
  assert.deepEqual(await call("zb-1"), [["zb-1", { fl: 0 }]], "none fixed: all three clickable");
  assert.equal((await call("zb-2", { id: 0 }))[0][1].res, 0, "no win, no fix");
  for (const id of [0, 1, 2]) {
    recordWin(session, 30869, "clockstar3");
    assert.equal((await call("zb-2", { id }))[0][1].res, 1);
  }
  assert.deepEqual(await call("zb-1"), [["zb-1", { fl: 7 }]]);
  o.pets!.unshift(makePet(tables, 1, 10, "d", 2));
  assert.deepEqual((await call("zb-3")).at(-1), ["zb-3", { res: 1 }], "only a 泽秒 first");
  o.pets!.shift();
  const out = await call("zb-3");
  assert.deepEqual(out.at(-1), ["zb-3", { res: 0, pid: o.pets![0].id, raceId: 915 }]);
  assert.equal(out[0][0], "2211", "the bag's 亚比 changes");
  assert.equal(o.pets![0].level, 1);
  assert.deepEqual(o.pets![0].ev, [0, 0, 0, 0, 0, 0]);
  assert.deepEqual(await call("zb-1"), [["zb-1", { fl: 0 }]], "the clocks start again");
});
