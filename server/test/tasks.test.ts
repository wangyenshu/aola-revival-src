import assert from "node:assert/strict";
import { test } from "node:test";
import { TaskUpdate, finishStep, installTasks, isNewPlayer, startTask, taskList, type TaskOwner } from "../src/game/sfs2013/tasks.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

type Msg = [string, Record<string, unknown>];

function harness(owner: TaskOwner) {
  const handlers = new Map<string, XtHandler>();
  const vars: Record<string, unknown>[] = [];
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: (_s: unknown, v: Record<string, unknown>) => vars.push(v) } as unknown as World;
  let now = 1000;
  installTasks(world, { load: async () => owner, save: async () => {}, now: () => now++ });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = { params, reply: (o: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { call, vars };
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

test("clientStep pushes onTaskUpdate (10-1) and the new 晶币, then answers 10-2", async () => {
  const owner: TaskOwner = { score: 0, robot: { name: "HELLO", exp: 0, follow: true }, tasks: { 150: { st: 0, ex: 0, ad: 1, fd: 0 }, 152: { st: 0, ex: 0, ad: 1, fd: 0 } } };
  const { call } = harness(owner);
  const out = await call("TaskExtension.10-2", { ti: 152, ty: 11 });
  // The last reply is for the later ActClientSender, which locks the screen until it comes.
  assert.deepEqual(out.map(([c]) => c), ["10-1", "10-1", "onScoreUpdated", "10-2"]);
  assert.deepEqual(out[2][1], { score: 2000 });
  assert.equal(out[3][1].ti, 152);
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

test("the HELLO follows: the user variable r, gone when it stops", async () => {
  const owner: TaskOwner = { robot: { name: "HELLO", exp: 0, follow: false } };
  const { call, vars } = harness(owner);
  const [[, r]] = await call("RobotExtension.2-1");
  assert.equal(r.res, 1);
  assert.equal(owner.robot!.follow, true);
  assert.deepEqual(vars.at(-1), { r: "0,1,," });
  await call("RobotExtension.2-2");
  assert.equal(owner.robot!.follow, false);
  assert.deepEqual(vars.at(-1), { r: null });
  const [[, none]] = await harness({}).call("RobotExtension.2-1");
  assert.equal(none.res, 0);
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

test("the story quests come from revival/tasks.json; a type 12 starter follows its pre-task", async () => {
  const { registerTaskTables, TASK_DEFS, skipTo } = await import("../src/game/sfs2013/tasks.ts");
  registerTaskTables({
    defines: { "1214": [0, "1215,1216"], "1215": [11, ""], "1216": [11, ""], "1219": [0, "1220"], "1220": [11, ""] },
    starters: { "1214": { type: 11, pre: [150], name: "传说中的美丽山脉" }, "1219": { type: 12, pre: [1214], name: "奇怪的山脉" } },
  });
  assert.deepEqual(TASK_DEFS[1214].steps, [1215, 1216]);
  const rec: TaskOwner = {};
  assert.deepEqual(startTask(rec, 1214, 1).changes, [], "not before the newbie quest");
  skipTo(rec, 1214, 2);
  assert.equal(rec.tasks![150].st, 1);
  assert.equal(rec.tasks![1214], undefined, "can start, not started");
  assert.deepEqual(startTask(rec, 1214, 3).changes.map((c) => c.t.ti), [1214, 1215]);
  finishStep(rec, 1215, 4);
  const end = finishStep(rec, 1216, 5);
  assert.deepEqual(end.changes.slice(-3).map((c) => [c.t.ti, c.ty]), [[1214, TaskUpdate.FINISH], [1219, TaskUpdate.ADD], [1220, TaskUpdate.ADD]]);
});

test("an item step finishes once the script has handed out its items; a fight step once its task 亚比 is beaten", async () => {
  const { registerTaskTables, skipTo, stepsByItems, stepsByPetWin } = await import("../src/game/sfs2013/tasks.ts");
  registerTaskTables({
    defines: {
      "228": [0, "229,230"], "229": [14, "1|108:1"], "230": [11, ""],
      "59": [0, "61,62,63"], "61": [11, ""], "62": [101, "10322,2"], "63": [11, ""],
    },
    starters: { "228": { type: 11, pre: [], name: "可恶的达斯特黑市" }, "59": { type: 11, pre: [], name: "干涸的河床" } },
  });
  const rec: TaskOwner & { items?: Record<string, Record<string, number>> } = {};
  skipTo(rec, 229, 1);
  assert.deepEqual(stepsByItems(rec, 2).changes, [], "no 人鱼鳞片 yet");
  rec.items = { "2": { "108": 1 } };
  const got = stepsByItems(rec, 3);
  assert.deepEqual(got.changes.map((c) => [c.t.ti, c.ty]), [[229, TaskUpdate.FINISH], [230, TaskUpdate.ADD]]);
  assert.deepEqual(got.taken, [[108, 1]], "c 1: the scale is taken back");
  assert.equal(rec.items["2"]["108"], undefined);

  skipTo(rec, 62, 4);
  assert.deepEqual(stepsByPetWin(rec, 322, 5).changes, [], "another 亚比 does not count");
  assert.deepEqual(stepsByPetWin(rec, 10322, 6).changes.map((c) => [c.t.ti, c.ty, c.t.ex]), [[62, TaskUpdate.UPDATE, 1]]);
  assert.deepEqual(stepsByPetWin(rec, 10322, 7).changes.map((c) => [c.t.ti, c.ty]), [[62, TaskUpdate.FINISH], [63, TaskUpdate.ADD]]);
});
