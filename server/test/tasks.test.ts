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

test("the HELLO's record carries the skills woken at the HELLO学院 (f), with or without a HELLO", async () => {
  const owner: TaskOwner = { robot: { name: "HELLO", exp: 0, follow: false }, area: { hello: { woken: [1, 4] } } };
  const [[, r]] = await harness(owner).call("RobotExtension.2-0");
  assert.equal(r.f, "01001");
  const [[, none]] = await harness({}).call("RobotExtension.2-0");
  assert.deepEqual(none, { has: 0, f: "00000" });
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
  const { registerTaskTables, skipTo, stepsByItems, stepsByPetWin, isQuestItem } = await import("../src/game/sfs2013/tasks.ts");
  registerTaskTables({
    defines: {
      "228": [0, "229,230"], "229": [14, "1|108:1"], "230": [11, ""],
      "59": [0, "61,62,63"], "61": [11, ""], "62": [101, "10322,2"], "63": [11, ""],
    },
    starters: { "228": { type: 11, pre: [], name: "可恶的达斯特黑市" }, "59": { type: 11, pre: [], name: "干涸的河床" } },
  });
  // What a quest's script may hand out (14_8): the items its steps wait for, nothing else.
  assert.equal(isQuestItem(108), true);
  assert.equal(isQuestItem(64), false, "百分百亚比球 is no quest item");
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

test("an item step finishes when it starts or on a hand-out that changes nothing, if the items are had (an attempt dropped)", async () => {
  const { registerTaskTables, skipTo, dropTask, settleTasks } = await import("../src/game/sfs2013/tasks.ts");
  registerTaskTables({
    defines: { "88": [0, "89,90,91"], "89": [11, ""], "90": [14, "0|181:1,182:1"], "91": [11, ""] },
    starters: { "88": { type: 11, pre: [], name: "种植的秘密" } },
  });
  const rec: TaskOwner & { items?: Record<string, Record<string, number>> } = {};
  skipTo(rec, 90, 1);
  rec.items = { "2": { "181": 1, "182": 1 } }; // handed out, kept (c 0)
  dropTask(rec, 88);
  startTask(rec, 88, 2);
  const step = finishStep(rec, 89, 3);
  // The client's step done starts 90, whose items the player still has: it finishes at once.
  const out = settleTasks(undefined, rec, step, 4);
  assert.deepEqual(out.filter(([c]) => c === "10-1").map(([, b]) => [(b.t as { ti: number }).ti, b.ty]), [[89, TaskUpdate.FINISH], [90, TaskUpdate.ADD], [90, TaskUpdate.FINISH], [91, TaskUpdate.ADD]]);
  assert.deepEqual(rec.items["2"], { "181": 1, "182": 1 }, "c 0: kept");
  // A save stuck at such a step: any settle (a hand-out that changes nothing) finishes it.
  skipTo(rec, 90, 5);
  assert.equal(settleTasks(undefined, rec, { changes: [] }, 6).some(([c, b]) => c === "10-1" && (b.t as { ti: number }).ti === 90), true);
});

test("every story quest with an end panel gives its 任务奖励, however its last step finishes", async () => {
  const { registerTaskTables, skipTo, questReward, settleTasks, stepsByPetWin, STORY_REWARD } = await import("../src/game/sfs2013/tasks.ts");
  registerTaskTables({
    defines: { "1843": [0, "1844,1845"], "1844": [11, ""], "1845": [101, "10093,1"], "1068": [0, "1069"], "1069": [11, ""], "3330": [0, "3331"], "3331": [11, ""] },
    starters: { "1843": { type: 11, pre: [], name: "木面仔的烦恼" }, "1068": { type: 11, pre: [], name: "x" }, "3330": { type: 11, pre: [], name: "y" } },
  });
  assert.deepEqual(questReward(1843), STORY_REWARD);
  assert.deepEqual(STORY_REWARD, { petExp: 5000, score: 3000, items: { "2": { "162": 80 } } });
  assert.deepEqual(questReward(1068), { petExp: 10000, jingdou: 100, items: { "2": { "162": 50 } } }, "晶豆, not 晶币");
  assert.equal(questReward(3330), undefined, "no end panel");
  assert.equal(questReward(150), undefined, "the newbie quest's bonus is its own");
  // Finished by a won fight (not 10-2): the reward is given all the same.
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const given: number[] = [];
  installTasks(world, { load: async () => ({}), save: async () => {}, now: () => 1, onFinish: (_r, t) => (given.push(t), [["gift", { t }]]) });
  const rec: TaskOwner = {};
  skipTo(rec, 1845, 1);
  const out = settleTasks(world, rec, stepsByPetWin(rec, 10093, 2), 3);
  assert.deepEqual(given, [1843]);
  assert.deepEqual(out.at(-1), ["gift", { t: 1843 }]);
});

test("a quest's team fight (54_22 type 17): only while its quest is being done, at the player's level", async () => {
  const { teamFight, NPC_TEAMS, TYPE_48_TEAMS, teamLevel } = await import("../src/game/sfs2013/questfights.ts");
  const { registerTaskTables, skipTo } = await import("../src/game/sfs2013/tasks.ts");
  registerTaskTables({ defines: { "1606": [0, "1610,1613"], "1610": [11, ""], "1613": [11, ""] }, starters: { "1606": { type: 11, pre: [], name: "月亮之殿" } } });
  const o = { pets: [{ level: 41 }, { level: 30 }] } as never as TaskOwner & { pets: { level: number }[] };
  assert.equal(teamFight(o as never, NPC_TEAMS[6]), "这个挑战现在还不能进行哦！", "not before its quest");
  skipTo(o, 1610, 1);
  assert.deepEqual(teamFight(o as never, NPC_TEAMS[6]), { race: 87, level: 41, team: [{ race: 96, level: 41 }] }, "冰拳艾司 then 金刚库巴");
  assert.deepEqual(teamFight(o as never, NPC_TEAMS[7]), { race: 327, level: 43, team: [] }, "月魔, two more");
  assert.equal(teamFight(o as never, NPC_TEAMS[99]), "这个挑战现在还不能进行哦！");
  assert.equal(teamLevel({ pets: [] } as never), 5);
  // Every team named by a surviving script, and 大地迷城's type 48.
  for (const n of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 29, 30, 31, 33, 34, 35, 38, 39, 42]) assert.ok(NPC_TEAMS[n], `team ${n}`);
  assert.equal(TYPE_48_TEAMS[2].team[0], 1426);
});
