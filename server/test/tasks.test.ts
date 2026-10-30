import assert from "node:assert/strict";
import { test } from "node:test";
import { TaskUpdate, finishStep, installTasks, isNewPlayer, startTask, taskList, type TaskOwner } from "../src/game/sfs2013/tasks.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

type Msg = [string, Record<string, unknown>];

function harness(owner: TaskOwner) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  let now = 1000;
  installTasks(world, { load: async () => owner, save: async () => {}, now: () => now++ });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = { params, reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { call };
}

test("a new player starts the newbie quest at login", async () => {
  const owner: TaskOwner = { score: 2000 };
  assert.equal(isNewPlayer(owner), true);
  const { call } = harness(owner);
  const [[cmd, reply]] = await call("TaskExtension.10-0");
  assert.equal(cmd, "10-0");
  assert.deepEqual((reply.t as { s: string }[]).map((e) => e.s), ["135,0,0", "136,0,0"]);
  assert.equal(isNewPlayer(owner), false);
});

test("a player who already has 亚比 is not given the quest", async () => {
  const owner: TaskOwner = { pets: [{}] };
  const { call } = harness(owner);
  const [[, reply]] = await call("TaskExtension.10-0");
  assert.deepEqual(reply.t, []);
});

test("steps go in order; a step not being done is ignored", () => {
  const rec: TaskOwner = {};
  startTask(rec, 135, 1);
  assert.deepEqual(finishStep(rec, 138, 2).changes, []);
  const r = finishStep(rec, 136, 3);
  assert.deepEqual(
    r.changes.map((c) => [c.t.ti, c.t.st, c.ty]),
    [
      [136, 1, TaskUpdate.FINISH],
      [137, 0, TaskUpdate.ADD],
    ],
  );
});

test("finishing 135 starts 140, finishing 140 starts 150, 150 pays 晶币 and HELLO experience", () => {
  const rec: TaskOwner = { score: 1000, robot: { name: "HELLO", exp: 0, follow: true } };
  startTask(rec, 135, 1);
  for (const s of [136, 137, 138]) finishStep(rec, s, 2);
  const end135 = finishStep(rec, 139, 3);
  assert.deepEqual(
    end135.changes.map((c) => [c.t.ti, c.ty]),
    [
      [139, TaskUpdate.FINISH],
      [135, TaskUpdate.FINISH],
      [140, TaskUpdate.ADD],
      [142, TaskUpdate.ADD],
    ],
  );
  for (const s of [142, 143, 144, 145, 146]) finishStep(rec, s, 4);
  const end140 = finishStep(rec, 147, 5);
  assert.deepEqual(end140.changes.slice(-2).map((c) => c.t.ti), [150, 152]);
  const end150 = finishStep(rec, 152, 6);
  assert.equal(end150.score, 3000);
  assert.equal(rec.robot!.exp, 3000);
  assert.ok(taskList(rec).every((e) => e.s.split(",")[1] === "1"));
});

test("clientStep pushes onTaskUpdate (10-1) and the new 晶币", async () => {
  const owner: TaskOwner = { score: 0, robot: { name: "HELLO", exp: 0, follow: true }, tasks: { 150: { st: 0, ex: 0, ad: 1, fd: 0 }, 152: { st: 0, ex: 0, ad: 1, fd: 0 } } };
  const { call } = harness(owner);
  const out = await call("TaskExtension.10-2", { ti: 152, ty: 11 });
  assert.deepEqual(out.map(([c]) => c), ["10-1", "10-1", "onScoreUpdated"]);
  assert.deepEqual(out[2][1], { score: 2000 });
});

test("the HELLO is added once", async () => {
  const owner: TaskOwner = {};
  const { call } = harness(owner);
  const [[, a]] = await call("RobotExtension.2-11");
  assert.equal(a.has, 1);
  owner.robot!.exp = 5;
  const [[, b]] = await call("RobotExtension.2-11");
  assert.equal(b.exp, 5);
});

test("test runs can skip to a step", async () => {
  const { skipTo } = await import("../src/game/sfs2013/tasks.ts");
  const rec: TaskOwner = {};
  skipTo(rec, 145, 7);
  assert.equal(rec.tasks![135].st, 1);
  assert.equal(rec.tasks![139].st, 1);
  assert.equal(rec.tasks![140].st, 0);
  assert.equal(rec.tasks![144].st, 1);
  assert.equal(rec.tasks![145].st, 0);
  assert.equal(rec.tasks![146], undefined);
  assert.equal(rec.tasks![150], undefined);
});
