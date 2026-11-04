// 亚比对战 between two players (a shared server; the era IPetFight.fightWithOther, whose 2013
// server is lost: RECONSTRUCTED). One asks from the other's 信息卡, the other agrees, and both
// fight on their own battle screens: each side sees its own 亚比 in front (slot 0) and the
// other's behind (slot 1), so the messages of one battle (canon: the inviter's side is slot 0)
// are turned round for the invited side. Each turn waits for both choices (a skill, or another
// 亚比), then the faster acts first, as against a wild 亚比. A 亚比 that falls is replaced by
// its player before the next turn; the side with none left loses. 逃跑 gives the fight up, as
// leaving the room or the game does. The battle screen gives a turn 30 seconds and then chooses
// itself (the first skill with uses left, else 1406 to wait; the next 亚比 for a fallen one); a
// player whose page does not (gone) has the same chosen by the server after CHOOSE_MS.
//
// It is a 切磋: both fight with copies of their bag, 体力 and PP full, and nothing they have
// changes (no experience, nothing lost, no items, no catching).
//
// PocketMonsterExtension
//   revival_duel_invite {name}       -> {res, msg}; the other: revival_duel_ask {from}
//   revival_duel_answer {from, ok}   -> both: the battle (2303, 2401 {pvp: true}); refused: the
//                                       inviter gets revival_duel_said {msg}
//   the battle commands as for wild 亚比: 1401 (skill), 1403 (switch), 1404 (give up), 1406 (wait);
//   1402 and 1405 refused.

import type { Session } from "../../core/emulator.ts";
import { BattleEngine, fighter, type Battle, type Fighter, type Msg, type Rng } from "./battle.ts";
import { nameOf, statsOf, type PetOwner, type PetRecord, type PetTables } from "./pets.ts";
import { sceneOfRoom, type World, type XtContext } from "./server.ts";

/** A choice not made in this long is made for the player (the page's own 30 seconds, and the time its films take). */
export const CHOOSE_MS = 45_000;
/** An invitation holds this long. */
export const DUEL_INVITE_MS = 60_000;

type Choice = { kind: "skill"; id: number } | { kind: "switch"; pid: number } | { kind: "wait" };

interface Side {
  id: number;
  name: string;
  session: Session;
  owner: PetOwner;
  pets: PetRecord[];
  choice?: Choice;
  /** Its 亚比 fell: another must come out before the next turn. */
  must: boolean;
}

export interface Duel {
  canon: Battle;
  sides: [Side, Side];
  timer?: ReturnType<typeof setTimeout>;
  over: boolean;
}

export interface DuelDeps {
  battles: Map<number, Battle>;
  load: (ctx: XtContext) => Promise<PetOwner>;
  find: (name: string) => Promise<PetOwner | undefined>;
  tables: () => Promise<PetTables>;
  rng?: Rng;
  nextId: () => number;
}

/** A 亚比 of the bag for the fight: a copy, 体力 and PP full. */
function fresh(p: PetRecord, t: PetTables): PetRecord {
  const c = structuredClone(p);
  delete c.buff;
  c.hp = statsOf(c, t)[0];
  for (const s of c.skills) s.pp = s.max;
  return c;
}

const SLOT_FIELDS = ["reqSId", "tarSId", "slotId", "locaId"];

export function installDuels(world: World, deps: DuelDeps) {
  const invites = new Map<string, Map<string, number>>();
  const lastAsk = new Map<string, number>();

  const sideOf = (d: Duel, id: number) => (d.sides[0].id === id ? 0 : 1);
  const fighterOf = (d: Duel, i: number): Fighter => (i === 0 ? d.canon.mine : d.canon.wild);
  const engine = (t: PetTables) => new BattleEngine(t, deps.rng);

  /** Side i's PlayerBattleInfo pair: its own 亚比 as slot 0. */
  const viewsFor = (d: Duel, i: number, e: BattleEngine): Record<string, unknown>[] => {
    const s = d.sides[i];
    const b = i === 0 ? d.canon : ({ ...d.canon, mine: d.canon.wild, wild: d.canon.mine } as Battle);
    return [e.view(b, 0, s.pets, s.owner), e.view(b, 1, s.pets, s.owner)];
  };

  /** A message of the canon battle, as side i sees it (now: its pmmList is taken now). */
  const asSide = (d: Duel, i: number, e: BattleEngine, [cmd, body]: Msg): Msg => {
    const out: Record<string, unknown> = { ...body };
    if (i === 1) for (const k of SLOT_FIELDS) if (out[k] === 0 || out[k] === 1) out[k] = 1 - (out[k] as number);
    if ("pmmList" in out) out.pmmList = viewsFor(d, i, e);
    return [cmd, out];
  };

  const sendTo = (d: Duel, i: number, msgs: Msg[]) => {
    const s = d.sides[i];
    if (s.session.closed) return;
    for (const [cmd, body] of msgs) world.push(s.session, cmd, body);
  };

  /** Both see it: the canon message turned for each, at this moment. */
  const both = (d: Duel, e: BattleEngine, out: [Msg[], Msg[]], m: Msg) => {
    out[0].push(asSide(d, 0, e, m));
    out[1].push(asSide(d, 1, e, m));
  };

  const notice = (d: Duel, i: number, e: BattleEngine, desc: string): Msg => ["2421", { slotId: 0, hpInc: 0, desc, pmmList: viewsFor(d, i, e) }];

  const end = (d: Duel, e: BattleEngine, winner: number | null, out: [Msg[], Msg[]], why = "") => {
    d.over = true;
    d.canon.over = true;
    if (d.timer) clearTimeout(d.timer);
    for (const i of [0, 1]) {
      const won = winner === i;
      const desc = why || (winner === null ? "平局！" : won ? "战斗胜利！" : "战斗失败！");
      out[i].push(["2403", { isWin: won, pvp: true, raceId: 0, id: 0, myFinalRaceId: fighterOf(d, i).pet.race, desc, pmmList: viewsFor(d, i, e) }]);
      if (deps.battles.get(d.sides[i].id) === d.canon) deps.battles.delete(d.sides[i].id);
    }
  };

  const healthy = (s: Side, but?: PetRecord) => s.pets.filter((p) => p.hp > 0 && p !== but);

  /** Another 亚比 of side i comes out. */
  const doSwitch = (d: Duel, i: number, pid: number, t: PetTables, e: BattleEngine, out: [Msg[], Msg[]], forced: boolean): boolean => {
    const s = d.sides[i];
    const next = s.pets.find((p) => p.id === pid);
    if (!next || next.hp <= 0 || next === fighterOf(d, i).pet) return false;
    const f = fighter(i as 0 | 1, next, s.id, t);
    if (i === 0) d.canon.mine = f;
    else d.canon.wild = f;
    s.must = false;
    const name = next.nick || nameOf(t, next.race);
    out[i].push(["2413", { playerInfo: viewsFor(d, i, e)[0], extInfo: { desc: `就决定是你了，${name}！`, res: 1, forced } }]);
    out[1 - i].push(["2413", { playerInfo: viewsFor(d, 1 - i, e)[1], extInfo: { desc: `${s.name}派出了${name}！`, res: 1, forced: true, foe: true } }]);
    return true;
  };

  const flush = (d: Duel, out: [Msg[], Msg[]]) => {
    sendTo(d, 0, out[0]);
    sendTo(d, 1, out[1]);
  };

  /**
   * A duel whose turn threw where no request is there to catch it (the timer, a player's going):
   * it ends without a winner, logged, rather than the error going loose (on Node, an unhandled
   * rejection would end the whole server).
   */
  const failed = (d: Duel, err: unknown) => {
    console.error(`[duel] ${d.sides[0].name} / ${d.sides[1].name}: ${(err as Error)?.stack ?? String(err)}`);
    d.over = true;
    d.canon.over = true;
    if (d.timer) clearTimeout(d.timer);
    for (const s of d.sides) if (deps.battles.get(s.id) === d.canon) deps.battles.delete(s.id);
    try {
      const msg: Msg = ["2403", { isWin: false, pvp: true, raceId: 0, id: 0, myFinalRaceId: 0, desc: "对战出错了，没有结果。", pmmList: [] }];
      flush(d, [[msg], [msg]]);
    } catch {}
  };
  const safely = (d: Duel, run: Promise<void>) => void run.catch((err) => failed(d, err));

  const arm = (d: Duel) => {
    if (d.timer) clearTimeout(d.timer);
    d.timer = setTimeout(() => safely(d, timeUp(d)), CHOOSE_MS);
  };

  /** The choices not made in time are made: the first skill with PP left (none: wait), or the next 亚比. */
  const timeUp = async (d: Duel) => {
    if (d.over) return;
    const t = await deps.tables();
    for (const i of [0, 1]) {
      const s = d.sides[i];
      if (s.choice) continue;
      if (s.must) {
        const next = healthy(s)[0];
        if (next) s.choice = { kind: "switch", pid: next.id };
      } else if (!d.sides.some((x) => x.must)) {
        const first = fighterOf(d, i).pet.skills.find((k) => k.pp > 0);
        s.choice = first ? { kind: "skill", id: first.id } : { kind: "wait" };
      }
    }
    step(d, t);
  };

  /** Once every choice needed is in: the switches owed, or the turn. */
  const step = (d: Duel, t: PetTables) => {
    if (d.over) return;
    const e = engine(t);
    const out: [Msg[], Msg[]] = [[], []];
    if (d.sides.some((s) => s.must)) {
      // Waiting for the fallen 亚比 to be replaced.
      if (d.sides.some((s) => s.must && !s.choice)) return;
      for (const i of [0, 1]) {
        const c = d.sides[i].choice;
        d.sides[i].choice = undefined;
        if (d.sides[i].must && c?.kind === "switch") doSwitch(d, i, c.pid, t, e, out, true);
      }
      nextTurn(d, e, out);
      flush(d, out);
      return;
    }
    if (!d.sides[0].choice || !d.sides[1].choice) return;
    const [c0, c1] = [d.sides[0].choice, d.sides[1].choice];
    d.sides[0].choice = d.sides[1].choice = undefined;
    // Switches go first, then the skills, the faster first.
    if (c0.kind === "switch") doSwitch(d, 0, c0.pid, t, e, out, false);
    if (c1.kind === "switch") doSwitch(d, 1, c1.pid, t, e, out, false);
    const skillOf = (i: number, c: Choice) => {
      if (c.kind !== "skill") return -1;
      const usable = fighterOf(d, i).pet.skills.filter((k) => k.pp > 0);
      return usable.find((k) => k.id === c.id) ? c.id : usable.length ? usable[0].id : 0;
    };
    const s0 = skillOf(0, c0), s1 = skillOf(1, c1);
    const acts: [Fighter, Fighter, number][] = [];
    if (s0 >= 0 && s1 >= 0) {
      const first = e.firstMover(d.canon, s0, s1);
      const second = first === d.canon.mine ? d.canon.wild : d.canon.mine;
      acts.push([first, second, first === d.canon.mine ? s0 : s1], [second, first, second === d.canon.mine ? s0 : s1]);
    } else if (s0 >= 0) acts.push([d.canon.mine, d.canon.wild, s0]);
    else if (s1 >= 0) acts.push([d.canon.wild, d.canon.mine, s1]);
    for (const [att, def, id] of acts) {
      if (att.pet.hp <= 0 || def.pet.hp <= 0) break;
      both(d, e, out, e.act(d.canon, att, def, id));
    }
    if (d.canon.mine.pet.hp > 0 && d.canon.wild.pet.hp > 0) for (const m of e.endOfTurn(d.canon)) both(d, e, out, m);
    // Who fell, and who has none left.
    const down = [0, 1].filter((i) => fighterOf(d, i).pet.hp <= 0);
    const out0 = down.filter((i) => healthy(d.sides[i]).length === 0);
    if (out0.length) {
      end(d, e, out0.length === 2 ? null : 1 - out0[0], out);
      flush(d, out);
      return;
    }
    if (down.length) {
      for (const i of down) {
        d.sides[i].must = true;
        out[i].push(["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: viewsFor(d, i, e) }]);
      }
      for (const i of [0, 1]) if (!down.includes(i)) out[i].push(notice(d, i, e, `等待${d.sides[1 - i].name}……`));
      arm(d);
      flush(d, out);
      return;
    }
    nextTurn(d, e, out);
    flush(d, out);
  };

  const nextTurn = (d: Duel, e: BattleEngine, out: [Msg[], Msg[]]) => {
    d.canon.turn++;
    for (const i of [0, 1]) out[i].push(["2402", { turn: d.canon.turn, pmmList: viewsFor(d, i, e) }]);
    arm(d);
  };

  /** A side gives up (逃跑, leaving the room or the game). */
  const giveUp = async (d: Duel, i: number) => {
    if (d.over) return;
    const e = engine(await deps.tables());
    const out: [Msg[], Msg[]] = [[], []];
    out[i].push(["2414", { reqSId: 0, isEscape: true, raceId: 0, desc: "认输了。" }]);
    end(d, e, 1 - i, out, "");
    // The one who gave up has had his 2414; his 2403 is not sent.
    out[i] = out[i].filter(([c]) => c !== "2403");
    out[1 - i] = out[1 - i].map(([c, b]): Msg => (c === "2403" ? [c, { ...b, desc: `${d.sides[i].name}认输了。` }] : [c, b]));
    flush(d, out);
  };

  world.onLeaveGame?.((s) => {
    const p = world.player(s);
    if (!p) return;
    invites.delete(p.name);
    const b = deps.battles.get(p.id);
    const d = b?.duel;
    if (d && !d.over) safely(d, giveUp(d, sideOf(d, p.id)));
  });

  const fighting = (id: number) => {
    const b = deps.battles.get(id);
    return !!b && !b.over;
  };

  world.xt("PocketMonsterExtension.revival_duel_invite", async (ctx) => {
    const reply = (res: number, msg: string) => ctx.reply({ res, msg }, "revival_duel_invite");
    const me = ctx.player.name;
    const name = String(ctx.params.name ?? "").trim();
    const s = world.online(name);
    const other = s ? world.player(s) : undefined;
    if (!name || name === me) return reply(0, "不能和自己对战哦。");
    if (!other) return reply(0, `${name}现在不在奥拉星上。`);
    if (other.room?.name !== ctx.player.room?.name) return reply(0, `要和${name}在同一个地方才能对战哦。`);
    if (fighting(ctx.player.id)) return reply(0, "你正在战斗中。");
    if (fighting(other.id)) return reply(0, `${name}正在战斗中，等一下再邀请吧。`);
    const o = await deps.load(ctx);
    if (!(o.pets ?? []).some((p) => p.hp > 0)) return reply(0, "你的亚比都很虚弱，先去治疗它们吧！");
    const k = `${me}\u0000${name}`;
    if (Date.now() - (lastAsk.get(k) ?? -Infinity) < 10_000) return reply(0, "刚刚已经邀请过了，等对方回答吧。");
    if (lastAsk.size > 10000) lastAsk.clear();
    lastAsk.set(k, Date.now());
    let mine = invites.get(name);
    if (!mine) invites.set(name, (mine = new Map()));
    mine.set(me, Date.now());
    world.push(s!, "revival_duel_ask", { from: me });
    reply(1, `已经邀请${name}进行亚比对战，等待对方同意。`);
  });

  world.xt("PocketMonsterExtension.revival_duel_answer", async (ctx) => {
    const me = ctx.player.name;
    const from = String(ctx.params.from ?? "");
    const at = invites.get(me)?.get(from);
    invites.get(me)?.delete(from);
    const fs = world.online(from);
    const fp = fs ? world.player(fs) : undefined;
    const said = (msg: string) => fs && world.push(fs, "revival_duel_said", { msg });
    const ok = ctx.params.ok === true || ctx.params.ok === 1 || ctx.params.ok === "1" || ctx.params.ok === "true";
    if (at == null || Date.now() - at > DUEL_INVITE_MS) return ctx.reply({ res: 0, msg: "这个邀请已经过期了。" }, "revival_duel_answer");
    if (!ok) {
      said(`${me}拒绝了你的对战邀请。`);
      return ctx.reply({ res: 1, msg: "" }, "revival_duel_answer");
    }
    if (!fp || !fs) return ctx.reply({ res: 0, msg: `${from}已经离开了。` }, "revival_duel_answer");
    if (fighting(fp.id) || fighting(ctx.player.id)) {
      said(`${me}正在战斗中，对战没有开始。`);
      return ctx.reply({ res: 0, msg: "现在不能开始对战。" }, "revival_duel_answer");
    }
    const [a, b] = [await deps.find(from), await deps.load(ctx)];
    const t = await deps.tables();
    if (!a || !b) return ctx.reply({ res: 0, msg: "现在不能开始对战。" }, "revival_duel_answer");
    const bagA = (a.pets ?? []).filter((p) => p.hp > 0).map((p) => fresh(p, t));
    const bagB = (b.pets ?? []).filter((p) => p.hp > 0).map((p) => fresh(p, t));
    if (!bagA.length || !bagB.length) {
      said("有一方的亚比都很虚弱，对战没有开始。");
      return ctx.reply({ res: 0, msg: "有一方的亚比都很虚弱，对战没有开始。" }, "revival_duel_answer");
    }
    ctx.reply({ res: 1, msg: "" }, "revival_duel_answer");
    const e = engine(t);
    const canon = e.start(deps.nextId(), sceneOfRoom(ctx.player.room), a, bagA[0], bagB[0], false);
    canon.wild = fighter(1, bagB[0], b.id, t);
    const d: Duel = {
      canon,
      sides: [
        { id: a.id, name: from, session: fs, owner: a, pets: bagA, must: false },
        { id: b.id, name: me, session: ctx.session, owner: b, pets: bagB, must: false },
      ],
      over: false,
    };
    canon.duel = d;
    deps.battles.set(a.id, canon);
    deps.battles.set(b.id, canon);
    for (const i of [0, 1]) {
      sendTo(d, i, [
        ["2303", { esc: true, sw: true, ch: false, cd: 1, pvp: { vs: d.sides[1 - i].name }, pmmList: viewsFor(d, i, e) }],
        ["2401", { id: canon.id, type: 0, pt: 0, bs: "", srt: 0, scene: canon.room, boss: 0, pvp: true }],
      ]);
    }
    arm(d);
  });

  /** A battle command of a player in a duel (battle.ts routes them here). */
  const command = async (name: string, ctx: XtContext, b: Battle) => {
    const d = b.duel!;
    const i = sideOf(d, ctx.player.id);
    const s = d.sides[i];
    const t = await deps.tables();
    const e = engine(t);
    const me = (msgs: Msg[]) => sendTo(d, i, msgs);
    if (d.over) return me([["2414", { msg: "战斗已经结束了" }]]);
    if (name === "1404") return giveUp(d, i);
    if (name === "1402") return me([["2412", { reqSId: 0, itemId: Number(ctx.params.itemId), res: -1, refused: true, desc: "对战中不能使用道具。", pmmList: viewsFor(d, i, e) }]]);
    if (name === "1405") return me([["2415", { reqId: s.id, tarSId: 1, itemId: Number(ctx.params.itemId), pmId: 0, lv: 0, lc: 0, refused: true, desc: "不能捕捉别人的亚比！" }]]);
    if (name === "1403") {
      const pid = Number(ctx.params.pmId);
      const next = s.pets.find((p) => p.id === pid);
      const mustOther = d.sides[1 - i].must;
      if (!next || next.hp <= 0 || next === fighterOf(d, i).pet || s.choice || (mustOther && !s.must)) {
        return me([["2413", { playerInfo: viewsFor(d, i, e)[0], extInfo: { desc: "这只亚比现在不能出战。", res: -1, refused: true } }]]);
      }
      s.choice = { kind: "switch", pid };
    } else if (name === "1401" || name === "1406") {
      if (s.must) return me([["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: viewsFor(d, i, e) }]]);
      if (s.choice || d.sides[1 - i].must) return;
      s.choice = name === "1401" ? { kind: "skill", id: Number(ctx.params.skillId) } : { kind: "wait" };
    } else return;
    const waiting = d.sides.some((x) => x.must) ? d.sides.some((x) => x.must && !x.choice) : !d.sides[1 - i].choice;
    if (waiting) me([notice(d, i, e, `等待${d.sides[1 - i].name}……`)]);
    step(d, t);
  };

  /** Leaving the room in a duel gives it up. */
  const leave = (b: Battle, id: number) => {
    const d = b.duel;
    if (d && !d.over) safely(d, giveUp(d, sideOf(d, id)));
  };

  return { command, leave };
}
