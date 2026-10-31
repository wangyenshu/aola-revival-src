// Tasks for the rebuilt 2013 task/taskservice (TaskExtension) and the
// HELLO the newbie quest hands out (RobotExtension).
//
// The 2013 server is lost. The commands are those of the client's TaskClient
// (the later copy of task/taskservice keeps the same ones):
//   10-0 initTasks  {}            -> {t: [{s: "taskId,state,extData", a, f}], ou}
//   10-1 onTaskUpdate (pushed)    <- {t: {ti, st, ex, ad, fd}, ty}
//   10-2 clientStep {ti, ty}      a step the client has seen done
//   10-3 clientStart {ti, ty}     the client asks to start a task
//   10-4 dropTask {ti}
//   10-5 clientSetData {ti, ed}   a number the task keeps (UserTask.extData)
// UserTask.state: 0 doing, 1 finished, 2 dropped (the 2013 UserTask).
//
// Which tasks exist and what they give is in task/taskdefines on the client.
// The newbie quest is RECONSTRUCTED (TASK_DEFS); the 2012 story quests whose
// scripts survive come from revival/tasks.json (tools/gen_tasks.py, the
// later client's tables), added with registerTaskTables().

import type { World, XtContext } from "./server.ts";

export interface UserTaskRec {
  st: number;
  ex: number;
  ad: number;
  fd: number;
}

export interface TaskDef {
  /** Steps in order; each is a client step (TaskStepType.CLIENT, 11). */
  steps: number[];
  /** Tasks that must be finished first. */
  pre?: number[];
  /** Started by the server as soon as its pre-tasks are finished (TaskStarter type 12). */
  auto?: boolean;
  /** Given when the task is finished. */
  bonus?: { score?: number; robotExp?: number };
}

/**
 * The newbie quest of January 2013, RECONSTRUCTED from what survives: the
 * task panels taskpanel/tp135, tp140, tp150 (one picture per step: 136; 142
 * 贝鲁特, 143 米娜, 144 贝鲁特, 145 朵朵兔, 146 and 147 普伦博士; 152 麦哲伦;
 * reward of 150: 3000 HELLO experience and 2000 晶币), the era task
 * resources named after steps 136–139, 145–147, 150 and 152, the copy
 * scenes that point the way while 142–147 are being done, and the official
 * walkthrough of 19 December 2011 (renwugonglue/3073). Steps 137–139 (the
 * first 亚比, the fight against the 达斯特, the story of the 奥拉之辉) have
 * no panel of their own; their numbers come from the resources.
 */
export const TASK_DEFS: Record<number, TaskDef> = {
  135: { steps: [136, 137, 138, 139] },
  140: { steps: [142, 143, 144, 145, 146, 147], pre: [135], auto: true },
  150: { steps: [152], pre: [140], auto: true, bonus: { score: 2000, robotExp: 3000 } },
};

/** revival/tasks.json: the later client's TaskDefine and TaskStarter rows of the story quests. */
export interface TaskTables {
  defines: Record<string, [number, string]>;
  starters: Record<string, { type: number; pre: number[]; name: string }>;
}

/**
 * Add the story quests: steps of every task (TaskDefine type 0), its
 * pre-tasks, and whether the server starts it itself (TaskStarter type 12,
 * TASK_FINISH) or the client asks (11, CLIENT). The newbie quest keeps its
 * own definitions.
 */
export function registerTaskTables(t: TaskTables): void {
  for (const [id, d] of Object.entries(t.defines ?? {})) {
    if (d[0] === STEP_ITEMS || d[0] === STEP_BEAT_PET) STEP_RULES[Number(id)] = { type: d[0], param: d[1] };
  }
  for (const [id, st] of Object.entries(t.starters ?? {})) {
    const ti = Number(id);
    if (TASK_DEFS[ti]) continue;
    const d = t.defines[id];
    if (!d || d[0] !== 0) continue;
    TASK_DEFS[ti] = { steps: d[1].split(",").filter(Boolean).map(Number), pre: st.pre, auto: st.type === 12 };
  }
}

/**
 * Steps the server finishes itself (TaskDefine types of the later tables):
 * 14 "c|item:n,item:n": once the player has those items (道具, material type
 * 2), which the quest's script hands out with GatherClient.collectItem; with
 * c 1 the items are taken back then. 101 "pet,n": once the player has beaten
 * that task 亚比 n times (IPetFight.fightWithTaskPet). The 2013 server is
 * lost: both rules are RECONSTRUCTED from the tables and the scripts, which
 * wait for the step to finish after giving the item or winning the fight.
 */
export const STEP_ITEMS = 14;
export const STEP_BEAT_PET = 101;
export const STEP_RULES: Record<number, { type: number; param: string }> = {};

/** Owners whose items the item steps look at (material type -> id -> count). */
export interface ItemOwner extends TaskOwner {
  items?: Record<string, Record<string, number>>;
}

/** Item steps being done whose items the player now has: they finish (the items taken when the step says so). */
export function stepsByItems(rec: ItemOwner, now: number): TaskResult & { taken: [number, number][] } {
  const out: TaskResult & { taken: [number, number][] } = { changes: [], taken: [] };
  for (const [id, rule] of Object.entries(STEP_RULES)) {
    if (rule.type !== STEP_ITEMS || !isDoing(rec, Number(id))) continue;
    const [take, list] = rule.param.split("|");
    const need = (list ?? "").split(",").filter(Boolean).map((x) => x.split(":").map(Number) as [number, number]);
    const bag = rec.items?.["2"] ?? {};
    if (!need.length || need.some(([ii, n]) => (bag[ii] ?? 0) < n)) continue;
    if (take === "1") {
      for (const [ii, n] of need) {
        bag[ii] -= n;
        if (bag[ii] <= 0) delete bag[ii];
        out.taken.push([ii, n]);
      }
    }
    const r = finishStep(rec, Number(id), now);
    out.changes.push(...r.changes);
    if (r.score !== undefined) out.score = r.score;
  }
  return out;
}

/** A task 亚比 beaten: the steps that ask for it count the win, and finish when there are enough. */
export function stepsByPetWin(rec: TaskOwner, pet: number, now: number): TaskResult {
  const out: TaskResult = { changes: [] };
  for (const [id, rule] of Object.entries(STEP_RULES)) {
    const step = Number(id);
    if (rule.type !== STEP_BEAT_PET || !isDoing(rec, step)) continue;
    const [want, times] = rule.param.split(",").map(Number);
    if (want !== pet) continue;
    const r = book(rec)[step];
    r.ex = (r.ex | 0) + 1;
    if (r.ex < (times || 1)) {
      out.changes.push({ t: view(step, r), ty: TaskUpdate.UPDATE });
      continue;
    }
    const f = finishStep(rec, step, now);
    out.changes.push(...f.changes);
    if (f.score !== undefined) out.score = f.score;
  }
  return out;
}

/** The first task of a new player. */
export const NEWBIE_TASK = 135;

/** onTaskUpdate types. The 2013 values are lost; the rebuilt client uses these. */
export const TaskUpdate = { UPDATE: 0, ADD: 1, FINISH: 2, ADD_FINISH: 3, RESET: 4, DROP: 5 } as const;

export interface TaskOwner {
  tasks?: Record<string, UserTaskRec>;
  pets?: unknown[];
  score?: number;
  robot?: RobotRecord;
}

export interface RobotRecord {
  name: string;
  /** Experience the HELLO keeps for handing out to 亚比 (RobotClient 2-12 / 2-13). */
  exp: number;
  /** Whether it walks behind the player (RobotClient 2-1 follow / 2-2 unfollow). */
  follow: boolean;
  /** The day it came, "yyyy-mm-dd" (its star sign on its card). */
  born?: string;
  /** Its clothes (a robot clothes id; "" for the default look). */
  avatar?: string;
}

/**
 * The user variable "r" of a player whose HELLO follows him, as the HELLO
 * code reads it: "type,level,avatar,hellobaby" (type 0, the HELLO).
 */
export function robotVar(r: RobotRecord): string {
  return `0,1,${r.avatar ?? ""},`;
}

export interface TaskChange {
  t: { ti: number; st: number; ex: number; ad: number; fd: number };
  ty: number;
}

export interface TaskResult {
  changes: TaskChange[];
  score?: number;
  robotExp?: number;
}

const parentOf = (step: number): number | undefined => {
  for (const [id, d] of Object.entries(TASK_DEFS)) if (d.steps.includes(step)) return Number(id);
  return undefined;
};

const view = (ti: number, r: UserTaskRec) => ({ ti, st: r.st, ex: r.ex, ad: r.ad, fd: r.fd });

function book(rec: TaskOwner): Record<string, UserTaskRec> {
  return (rec.tasks ??= {});
}

export function isFinished(rec: TaskOwner, ti: number): boolean {
  return rec.tasks?.[ti]?.st === 1;
}

export function isDoing(rec: TaskOwner, ti: number): boolean {
  return rec.tasks?.[ti]?.st === 0;
}

/** Start task `ti` (its first step with it). Nothing happens if it cannot start. */
export function startTask(rec: TaskOwner, ti: number, now: number): TaskResult {
  const def = TASK_DEFS[ti];
  const out: TaskResult = { changes: [] };
  if (!def) return out;
  const b = book(rec);
  if (b[ti] && b[ti].st !== 2) return out;
  if (def.pre?.some((p) => !isFinished(rec, p))) return out;
  b[ti] = { st: 0, ex: 0, ad: now, fd: 0 };
  out.changes.push({ t: view(ti, b[ti]), ty: TaskUpdate.ADD });
  const first = def.steps[0];
  if (first !== undefined) {
    b[first] = { st: 0, ex: 0, ad: now, fd: 0 };
    out.changes.push({ t: view(first, b[first]), ty: TaskUpdate.ADD });
  }
  return out;
}

/** Step `step` is done: the next step starts, or the task finishes (bonus, then the tasks it opens). */
export function finishStep(rec: TaskOwner, step: number, now: number): TaskResult {
  const out: TaskResult = { changes: [] };
  const parent = parentOf(step);
  if (parent === undefined || !isDoing(rec, step) || !isDoing(rec, parent)) return out;
  const b = book(rec);
  b[step] = { ...b[step], st: 1, fd: now };
  out.changes.push({ t: view(step, b[step]), ty: TaskUpdate.FINISH });
  const def = TASK_DEFS[parent];
  const next = def.steps[def.steps.indexOf(step) + 1];
  if (next !== undefined) {
    b[next] = { st: 0, ex: 0, ad: now, fd: 0 };
    out.changes.push({ t: view(next, b[next]), ty: TaskUpdate.ADD });
    return out;
  }
  b[parent] = { ...b[parent], st: 1, fd: now };
  if (def.bonus?.score) {
    rec.score = (rec.score ?? 0) + def.bonus.score;
    out.score = rec.score;
  }
  if (def.bonus?.robotExp) {
    if (rec.robot) rec.robot.exp += def.bonus.robotExp;
    out.robotExp = def.bonus.robotExp;
  }
  out.changes.push({ t: view(parent, b[parent]), ty: TaskUpdate.FINISH });
  for (const [id, d] of Object.entries(TASK_DEFS)) {
    if (d.auto && d.pre?.includes(parent)) {
      const started = startTask(rec, Number(id), now);
      out.changes.push(...started.changes);
    }
  }
  return out;
}

export function dropTask(rec: TaskOwner, ti: number): TaskResult {
  const out: TaskResult = { changes: [] };
  const def = TASK_DEFS[ti];
  const b = book(rec);
  if (!def || !b[ti] || b[ti].st !== 0) return out;
  b[ti].st = 2;
  for (const s of def.steps) delete b[s];
  out.changes.push({ t: view(ti, b[ti]), ty: TaskUpdate.DROP });
  return out;
}

export function setTaskData(rec: TaskOwner, ti: number, ed: number): TaskResult {
  const out: TaskResult = { changes: [] };
  const r = rec.tasks?.[ti];
  if (!r || r.st !== 0) return out;
  r.ex = ed | 0;
  out.changes.push({ t: view(ti, r), ty: TaskUpdate.UPDATE });
  return out;
}

/** The task list as 10-0 sends it, one entry per task. */
export function taskList(rec: TaskOwner): { s: string; a: number; f: number }[] {
  return Object.entries(rec.tasks ?? {}).map(([ti, r]) => ({ s: `${ti},${r.st},${r.ex}`, a: r.ad, f: r.fd }));
}

/** A new player (no task, no 亚比) starts the newbie quest. */
export function isNewPlayer(rec: TaskOwner): boolean {
  return Object.keys(rec.tasks ?? {}).length === 0 && (rec.pets ?? []).length === 0;
}

export interface TaskDeps {
  load(ctx: XtContext): Promise<TaskOwner>;
  save(rec: TaskOwner): Promise<void>;
  now(): number;
  /** Resolves once the story quests' tables are in (registerTaskTables). */
  ready?: Promise<unknown>;
  /** Answer the test command revival_task (web/?dev=1). */
  dev?: boolean;
}

/**
 * Test runs: the tasks before (pre-tasks, and theirs) finished, and `step`
 * being done with the steps before it finished. Given a task instead of a
 * step, only its pre-tasks are finished, so it can start.
 */
export function skipTo(rec: TaskOwner, step: number, now: number): TaskResult {
  const out: TaskResult = { changes: [] };
  const b = book(rec);
  const parent = TASK_DEFS[step] ? step : parentOf(step);
  if (parent === undefined) return out;
  const chain: number[] = [];
  const visit = (t: number) => {
    for (const p of TASK_DEFS[t]?.pre ?? []) {
      if (chain.includes(p)) continue;
      visit(p);
      chain.push(p);
    }
  };
  visit(parent);
  for (const t of chain) {
    for (const s of [...(TASK_DEFS[t]?.steps ?? []), t]) {
      b[s] = { st: 1, ex: 0, ad: now, fd: now };
      out.changes.push({ t: view(s, b[s]), ty: TaskUpdate.ADD_FINISH });
    }
  }
  // Past step 146 a player has the HELLO 普伦博士 gives there.
  if (b[146]?.st === 1 && !rec.robot) rec.robot = { name: "HELLO", exp: 0, follow: true, born: new Date(now).toISOString().slice(0, 10) };
  if (parent === step) return out;
  const d = TASK_DEFS[parent];
  const at = d.steps.indexOf(step);
  b[parent] = { st: 0, ex: 0, ad: now, fd: 0 };
  out.changes.push({ t: view(parent, b[parent]), ty: TaskUpdate.ADD });
  d.steps.forEach((s, i) => {
    if (i > at) {
      delete b[s];
      return;
    }
    b[s] = { st: i < at ? 1 : 0, ex: 0, ad: now, fd: i < at ? now : 0 };
    out.changes.push({ t: view(s, b[s]), ty: i < at ? TaskUpdate.ADD_FINISH : TaskUpdate.ADD });
  });
  return out;
}

export function installTasks(world: World, deps: TaskDeps): void {
  const load = async (ctx: XtContext) => {
    await deps.ready?.catch(() => undefined);
    return deps.load(ctx);
  };
  const push = (ctx: XtContext, r: TaskResult) => {
    for (const c of r.changes) ctx.reply({ t: c.t, ty: c.ty }, "10-1");
    if (r.score !== undefined) ctx.reply({ score: r.score }, "onScoreUpdated");
  };

  world.xt("TaskExtension.10-0", async (ctx) => {
    const rec = await load(ctx);
    if (isNewPlayer(rec)) {
      startTask(rec, NEWBIE_TASK, deps.now());
      await deps.save(rec);
    }
    ctx.reply({ t: taskList(rec), ou: false });
  });
  world.xt("TaskExtension.10-3", async (ctx) => {
    const rec = await load(ctx);
    const r = startTask(rec, Number(ctx.params.ti), deps.now());
    if (r.changes.length) await deps.save(rec);
    push(ctx, r);
  });
  world.xt("TaskExtension.10-2", async (ctx) => {
    const rec = await load(ctx);
    const r = finishStep(rec, Number(ctx.params.ti), deps.now());
    if (r.changes.length) await deps.save(rec);
    push(ctx, r);
    // Later scripts send it through ActClientSender.sendMessage, which waits (behind a loading
    // spinner) for a reply of the same command.
    ctx.reply({ ti: Number(ctx.params.ti), res: r.changes.length ? 1 : 0 }, "10-2");
  });
  world.xt("TaskExtension.10-4", async (ctx) => {
    const rec = await load(ctx);
    const r = dropTask(rec, Number(ctx.params.ti));
    if (r.changes.length) await deps.save(rec);
    push(ctx, r);
  });
  world.xt("TaskExtension.10-5", async (ctx) => {
    const rec = await load(ctx);
    const r = setTaskData(rec, Number(ctx.params.ti), Number(ctx.params.ed));
    if (r.changes.length) await deps.save(rec);
    push(ctx, r);
  });

  if (deps.dev) {
    world.xt("TaskExtension.revival_task", async (ctx) => {
      const rec = await load(ctx);
      const r = skipTo(rec, Number(ctx.params.ti), deps.now());
      await deps.save(rec);
      push(ctx, r);
    });
  }

  // ---------------------------------------------------------------- HELLO
  // RobotClient (era library): 2-11 addRobot {}, 2-0 getRobot {un?}, 2-1
  // follow {}, 2-2 unfollow {}, 2-12 getExp {}. The replies' fields are those
  // the era HELLO cards read (robot/robotanothermes: n name, a clothes, b
  // birthday, e energy, f skills), the rest RECONSTRUCTED (init/robotmanager,
  // which shows the HELLO in scenes, survives only as a later copy): the
  // HELLO is called "HELLO" until renamed. A following HELLO is the user
  // variable "r", so everyone in the room sees it.
  const robotView = (r: RobotRecord | undefined) =>
    r ? { has: 1, n: r.name, a: r.avatar ?? "", b: r.born ?? "2012-08-15", e: 100, f: "", t: 0, exp: r.exp, fl: r.follow ? 1 : 0 } : { has: 0 };
  const today = () => new Date(deps.now()).toISOString().slice(0, 10);
  world.xt("RobotExtension.2-11", async (ctx) => {
    const rec = await deps.load(ctx);
    if (!rec.robot) {
      rec.robot = { name: "HELLO", exp: 0, follow: true, born: today() };
      await deps.save(rec);
      world.setUserVars(ctx.session, { r: robotVar(rec.robot) });
    }
    ctx.reply({ res: 1, ...robotView(rec.robot) });
  });
  world.xt("RobotExtension.2-0", async (ctx) => {
    const rec = await deps.load(ctx);
    ctx.reply(robotView(rec.robot));
  });
  world.xt("RobotExtension.2-1", async (ctx) => {
    const rec = await deps.load(ctx);
    if (!rec.robot) return ctx.reply({ res: 0 });
    if (!rec.robot.follow) {
      rec.robot.follow = true;
      await deps.save(rec);
    }
    world.setUserVars(ctx.session, { r: robotVar(rec.robot) });
    ctx.reply({ res: 1, ...robotView(rec.robot) });
  });
  world.xt("RobotExtension.2-2", async (ctx) => {
    const rec = await deps.load(ctx);
    if (rec.robot?.follow) {
      rec.robot.follow = false;
      await deps.save(rec);
    }
    world.setUserVars(ctx.session, { r: null });
    ctx.reply({ res: 1 });
  });
  world.xt("RobotExtension.2-12", async (ctx) => {
    const rec = await deps.load(ctx);
    ctx.reply({ exp: rec.robot?.exp ?? 0 });
  });
}
