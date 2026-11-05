// 亚比 battles for the 2013 server: wild 亚比 in scenes and 1v1 fights with
// them, on the battle commands of the 2013 PetClient (PocketMonsterExtension)
// and PetClient2 (PetExtension), the only parts of the 2013 battle protocol
// that survive:
//
//   54_7 GetLocationPetInfo {}            -> {pms: [{raceId, min, max, common, rate}]}  wild 亚比 of the room
//   54_2 startPKWithRobot {raceId, level, sw, id}
//        -> 2303 JOIN_BATTLE_JOINER {esc, sw, ch, pmmList: [PlayerBattleInfo]}  (or {msg} when refused)
//        -> 2401 START_BATTLE {id, type, pt, bs}
//   1401 useSkill {skillId, tarSId}       -> 2411 USE_SKILL per action
//   1402 useItem {itemId, tarSId}         -> 2412 USE_ITEM
//   1403 switchPM {pmId}                  -> 2413 SWITCH_PM {playerInfo, extInfo: {desc}}
//   1404 escape {}                        -> 2414 ESCAPE {reqSId, isEscape}
//   1405 catchPM {tarSId, itemId}         -> 2415 CATCH_PM {reqId, tarSId, pmId (0 failed), lv, lc}
//   1406 standby {isAuto}                 -> 2421 (the 亚比 does nothing this turn), then the wild 亚比's
//                                            turn: the battle screen's turn time ran out with no skill
//                                            that has uses left
//   after a turn: 2421 STATUS_UPDATE (burns, poison), then 2402 BATTLE_NEXT_TURN,
//   2422 BATTLE_PM_DYING (choose another 亚比) or 2403 FIN_BATTLE; a win also
//   sends 2241 PM_GAIN_EXP, 2242 PM_LEVELUP and 2234 PM_GAIN_NEW_SKILL.
//
// PlayerBattleInfo ({battleView: {pmCanBattle, clv, pmmId, slotId, pms, ccle,
// clu%, cnx, bag, pmList: [PetBriefInfo]}}) is the 2013 interface class; the
// fields of the other replies follow the later client that kept these command
// numbers (reqSId, srt 0 hit / 1 no effect / 2 miss / 3 could not act, cri,
// pmmList, pmId, lc …), with a "desc" text the rebuilt battle screen shows.
//
// The 2013 server is lost: the rules here (damage, accuracy, statuses read
// from the skill descriptions, catching, experience) are RECONSTRUCTED on the
// columns of the client's tables (pmdata.ts).

import { stepsByPetWin, type TaskOwner } from "./tasks.ts";
import { wildDrop, type ActsOwner } from "./planetacts.ts";
import { FB_TIMES, betterGrade, ensureFbSpecies, fbBossBeaten, fbByName, fbGrade, fbOfRoom, fbPay, fbRoomPets, fbSpecies, FBS, type FbRec } from "./fb.ts";
import {
  catchLevel,
  evolutionAt,
  expYield,
  skillsLearntAt,
  typeMultiplier,
  type PmSkill,
} from "./pmdata.ts";
import {
  briefOf,
  catchFields,
  expToNext,
  followVar,
  makePet,
  nameOf,
  normalisePet,
  skillOf,
  speciesOf,
  statsOf,
  type PetOwner,
  type PetRecord,
  type PetTables,
} from "./pets.ts";
import { PET_CARD, PET_CARDS, cardDrop } from "./petcards.ts";
import { installSandbox } from "./sandbox.ts";
import { applyFate, dollLevel, gymOf, gymWon, installGyms, towerFloorWon, GYM_DARK, GYM_LIGHT, GYM_MASTERS, GYM_THUNDER, GYM_TOWER, TOWER_FLOORS as THUNDER_FLOORS } from "./gyms.ts";
import { sceneOfRoom, type World, type XtContext } from "./server.ts";
import { registerFights } from "./fighting.ts";
import { markDic, MET, NEW_RECORD, OWNED } from "./petdic.ts";
import { ATTRS, BAD_STATUSES, readSkill, type Cond, type SkillEffects, type StatKey, type StatusName, type Timed } from "./skilltext.ts";
import { installDuels, type Duel } from "./duel.ts";
import type { Boosts, PetItemOwner } from "./petitems.ts";

// ---------------------------------------------------------------- skill effects

// What a skill does is read from its description (skilltext.ts): the 2013 rules are lost with
// the server, the descriptions are what the player is told.
export { STATUSES, type SkillEffects, type StageChange, type StatKey, type StatusName } from "./skilltext.ts";

const fxCache = new Map<string, SkillEffects>();
/** A skill's effects, read from its description once (the engine never changes them). */
export function parseEffects(desc: string): SkillEffects {
  let fx = fxCache.get(desc);
  if (!fx) {
    fx = readSkill(desc).fx;
    fxCache.set(desc, fx);
  }
  return fx;
}

const STAT_LABEL: Record<StatKey, string> = { atk: "攻击", def: "防御", satk: "特攻", sdef: "特防", spd: "速度", acc: "命中", eva: "闪避", crit: "暴击" };
const STAT_INDEX = { atk: 1, def: 2, satk: 3, sdef: 4, spd: 5 } as const;
const ALL_KEYS: StatKey[] = ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"];

// ---------------------------------------------------------------- fighters

type Stages = Record<StatKey, number>;
const noStages = (): Stages => ({ atk: 0, def: 0, satk: 0, sdef: 0, spd: 0, acc: 0, eva: 0, crit: 0 });

/** A lasting effect on a fighter (its holder), with the turns it has left. */
export interface Live extends Timed {
  left: number;
}

/** What a fighter did or has this turn only. */
interface TurnFlags {
  moved?: boolean;
  /** It moved before the other this turn. */
  first?: boolean;
  /** It was hurt by the other this turn. */
  hurt?: boolean;
  /** The damage it took this turn from 普通攻击 and from 特殊攻击 (a counter used after strikes back). */
  takenPhys?: number;
  takenSpec?: number;
  /** What its 每回合可以抵抗 shield took this turn. */
  absorbed?: number;
  protect?: boolean;
  shield?: NonNullable<SkillEffects["shield"]>;
  endure?: boolean;
  destiny?: boolean;
  grudge?: boolean;
  hold?: boolean;
  absorb?: boolean;
  /** The damaging skill it uses this turn (冷月寒霜 asks whether the other uses one). */
  damaging?: boolean;
}

export interface Fighter {
  slot: 0 | 1;
  pet: PetRecord;
  owner: number;
  stats: number[];
  types: [number, number];
  stages: Stages;
  /** 麻痹, 冰冻, 睡眠, 烧伤 or 中毒. */
  status?: StatusName;
  /** The turns the status has left, when its skill said (0: it lasts by its own rule). */
  statusLeft: number;
  sleep: number;
  confuse: number;
  bind: number;
  /** 害怕: the actions it misses. */
  fear: number;
  /** 衰弱: its turns so far (the HP it loses grows). */
  weak: number;
  /** 衰弱's turns left, when its skill said (0: till cured). */
  weakLeft?: number;
  /** 寄生: the other drains it each turn. */
  seeded: boolean;
  /** Turns it rests (下回合停止行动). */
  rest: number;
  /** The turn its rest begins (another's skill: 下回合). */
  restFrom?: number;
  /** Turns it cannot be switched out (束缚, 无法替换亚比). */
  trapped: number;
  /** A 强化药剂's points (stats[i] + add) until the round `until`. */
  buff?: { i: number; add: number; until: number };
  timed: Live[];
  /** The skill it gathers power for (本回合蓄力, 下回合攻击). */
  charging?: number;
  /** The turns of gathering still to come before the blow (蓄力N回合). */
  chargeLeft?: number;
  /** Points of 护盾 (嗜血之矛: the heal it could not take): they take the blows first, until used up. */
  armour?: number;
  /** It was hurt while it gathered power (魂葬破: 若蓄力时未受到伤害则伤害翻倍). */
  chargeHurt?: boolean;
  /** A skill used several turns in a row (连续攻击N回合); boost: its growth this turn (威力递增). */
  lock?: { id: number; left: number; after: "confuse" | "rest" | "heal" | "none"; healF?: number; boost?: number };
  turn: TurnFlags;
  /** Uses of each skill this battle (成功率越低 / 越高). */
  uses: Record<string, number>;
  /** The skills it used, to the last turn their effect lasts (七星灯 with 卧龙觉醒). */
  marks: Record<string, number>;
  /** Marks the other gave it (陶醉). */
  marked: string[];
  /** The skill it used last. */
  last?: number;
  /** 基础数值 raised this many times (龙腾四海), by pct each. */
  baseUp: { n: number; pct: number };
  /** 基础数值 lowered: points of 攻击 and 特攻, and the share of both (陶醉). */
  baseDown: { atk: number; satk: number; pct: number };
  /** Comes back with all its HP once when it falls (使用后被对方打败则满状态复活). */
  revive?: boolean;
}

export interface Battle {
  id: number;
  room: string;
  wild: Fighter;
  mine: Fighter;
  turn: number;
  canCatch: boolean;
  /** Waiting for the player to choose another 亚比 after one fell. */
  mustSwitch: boolean;
  over: boolean;
  /** Run once when the player wins (an NPC challenge's prize); its messages go out with the win. */
  onWin?: (o: PetOwner) => Msg[];
  /** Run once when the player loses or runs away (时空隧道: out of the tunnel); its messages go out first. */
  onLose?: (o: PetOwner) => Msg[];
  /**
   * The number the client asked to fight (a task 亚比's variant * 10000 + species): the
   * end of the battle reports it as raceId, which the quest scripts compare with the
   * one they asked for (PetFightEvent.raceId != this.petId: not their fight).
   */
  asked?: number;
  /** A 副本 room's 亚比 id (fightInCopy): sent back with the end, where fbteam takes it off the room. */
  copyId?: number;
  /** A 沙盒 fight (sandbox.ts): no experience, effort points or evolution for the win. */
  noAward?: boolean;
  /** 亚比对战 with another player (duel.ts): the battle of both, its commands are the duel's. */
  duel?: Duel;
  /** 全场 X系威力提升: the 属性 up and down, for some turns. */
  field?: { up: number; upPct: number; down?: number; downPct?: number; left: number };
  /** Effects that come at the end of a later turn (下回合结束时…, N回合后…). */
  delayed?: { slot: 0 | 1; left: number; kind: string; n?: number; f?: number; stats?: StatKey[]; delta?: number; chance?: number }[];
  /** The side whose next 亚比 comes out with all its HP (为自己下一只出场的亚比满状态回复). */
  nextHeal?: boolean[];
  /** The side a skill forces to switch (威吓: 强制对方单体替换亚比战斗); the battle's turn does it. */
  forceOut?: 0 | 1;
}

export type Msg = [cmd: string, body: Record<string, unknown>];

/** Rounds a 强化药剂 (petitems.ts) keeps its points: "在20回合内". */
export const BUFF_ROUNDS = 20;

/** A win's words for the end of the battle (onWin): 2403's note (the battle screen's result lines), not sent. */
export const NOTE = "revival_note";

export interface Rng {
  (): number;
}

export function fighter(slot: 0 | 1, pet: PetRecord, owner: number, t: PetTables): Fighter {
  const sp = speciesOf(t, pet.race);
  const stats = statsOf(pet, t);
  // A 强化药剂 used before (petitems.ts): its points for the first rounds of this battle.
  let buff: Fighter["buff"];
  if (slot === 0 && pet.buff) {
    buff = { ...pet.buff, until: BUFF_ROUNDS };
    stats[buff.i] += buff.add;
    delete pet.buff;
  }
  return {
    slot,
    pet,
    owner,
    stats,
    buff,
    types: sp ? sp.t : [0, 0],
    stages: noStages(),
    statusLeft: 0,
    sleep: 0,
    confuse: 0,
    bind: 0,
    fear: 0,
    weak: 0,
    seeded: false,
    rest: 0,
    trapped: 0,
    timed: [],
    turn: {},
    uses: {},
    marks: {},
    marked: [],
    baseUp: { n: 0, pct: 0 },
    baseDown: { atk: 0, satk: 0, pct: 0 },
  };
}

const stageMult = (s: number) => (s >= 0 ? (2 + s) / 2 : 2 / (2 - s));
const accMult = (s: number) => (s >= 0 ? (3 + s) / 3 : 3 / (3 - s));
const clampStage = (s: number) => Math.max(-6, Math.min(6, s));
/** The stages as the later client's PetBriefInfo.bal reads them (攻击 防御 特攻 特防 速度 命中 闪避 暴击). */
export const balOf = (st: Stages): string => [st.atk, st.def, st.satk, st.sdef, st.spd, st.acc, st.eva, st.crit].map(clampStage).join("#");

const live = (f: Fighter, kind: Timed["kind"]): Live[] => f.timed.filter((x) => x.kind === kind && x.left > 0);

/** A battle value with its 基础 changes, stages, 加倍 effects and 麻痹; noUps: raised stages do not count. */
function stat(f: Fighter, k: keyof typeof STAT_INDEX, noUps = false): number {
  let base = f.stats[STAT_INDEX[k]] * (1 + (f.baseUp.n * f.baseUp.pct) / 100);
  if (k === "atk" || k === "satk") base = base * (1 - f.baseDown.pct / 100) - f.baseDown[k];
  let v = Math.max(1, base) * stageMult(noUps ? Math.min(0, f.stages[k]) : f.stages[k]);
  for (const x of live(f, "statmult")) if (x.stats?.includes(k)) v *= x.mult ?? 1;
  if (k === "spd" && f.status === "麻痹") v /= 2;
  return Math.max(1, v);
}

function petName(t: PetTables, f: Fighter): string {
  return f.pet.nick || nameOf(t, f.pet.race);
}

/** Does the skill do anything to the other 亚比 (so it can miss, and plays on it)? */
function aimsAtFoe(sk: PmSkill, fx: SkillEffects): boolean {
  if (sk.k !== 2) return true;
  return !!(
    fx.dmg ||
    fx.statuses.some((s) => !s.self) ||
    fx.stages.some((s) => !s.self) ||
    fx.ppFoe ||
    fx.clearFoeUps ||
    fx.resetFoe ||
    fx.swapStages ||
    fx.stealStages ||
    fx.passDowns ||
    fx.passStatus ||
    fx.painSplit ||
    fx.swapHp ||
    fx.endeavor ||
    fx.ohko ||
    fx.ohkoIf ||
    fx.forceSwitch ||
    fx.trap ||
    fx.baseDown ||
    fx.timed.some((x) => x.who === "foe" && x.kind !== "power")
  );
}

/** A status skill that only changes its user (heals, raises its own stages): its effect plays on the user. */
function selfOnly(sk: PmSkill): boolean {
  return sk.k === 2 && !aimsAtFoe(sk, parseEffects(sk.d));
}

/**
 * The 亚比 with a trait some skills name (全场具有…特性的亚比): 马戏团 is the 七彩小丑 line of
 * 发明岛, the 亚比 of 闇月马戏团 (the skill's own learners); 超暗黑 is the 属性 超暗 (30, the
 * later client's PMAttributeMap).
 */
const TRAITS: Record<string, (f: Fighter) => boolean> = {
  马戏团: (f) => [175, 176, 177].includes(f.pet.race % 10000),
  超暗黑: (f) => f.types.includes(30),
};
/** A trait, or a 属性 ("数码系"). */
const hasTrait = (f: Fighter, name: string): boolean => {
  if (TRAITS[name]) return TRAITS[name](f);
  const attr = ATTRS[name.replace(/系$/, "")];
  return attr !== undefined && f.types.includes(attr);
};

const hpShare = (f: Fighter) => Math.max(0, f.pet.hp) / Math.max(1, f.stats[0]);

/**
 * The power (the client's doubled scale) of a skill that grows or shrinks with HP, on the Pokémon
 * rules the tables were modelled on (RECONSTRUCTED: the 2013 numbers are lost):
 * - "体力越少，威力越大" with no power in the table (威力 —): 抓狂 / 起死回生, by the HP left:
 *   40 from 68.75%, 80, 160, 200, 300, and 400 under 4.17%.
 * - "体力越多/越高，威力越大" or "越少，威力越低": 喷火 / 海潮, the power times the share of HP
 *   left (the table's power, or 300, at full HP).
 * - "对方剩余体力值越多，威力越大": 绞紧, 240 times the foe's share of HP.
 * - A table power with "越少越大" (恶魔之力 240): that power at full HP, up to twice it near none.
 */
export function hpPower(kind: "low" | "high" | "foeHigh", listed: number, att: Fighter, def: Fighter): number {
  const own = hpShare(att);
  if (kind === "foeHigh") return Math.max(2, 240 * hpShare(def));
  if (kind === "high") return Math.max(2, (listed > 1 ? listed : 300) * own);
  if (listed > 1) return listed * (2 - own);
  const steps: [number, number][] = [[0.6875, 40], [0.3542, 80], [0.2083, 160], [0.1042, 200], [0.0417, 300]];
  for (const [at, p] of steps) if (own >= at) return p;
  return 400;
}

/** 挣扎: what a 亚比 with no PP left does. */
const STRUGGLE: PmSkill = { n: "挣扎", p: 100, acc: 100, pp: 1, pri: 0, t: -1, k: 0, d: "自己承受伤害值的1/4" };

/** The turns a skill's effect lasts, as its words say (银光护盾 持续10回合), for the skills that ask for it. */
const markTurns = (d: string): number => {
  const m = d.match(/(\d+)\s*(?:个)?回合/);
  return m ? Number(m[1]) : 99;
};
const plain = (n: string) => n.replace(/[“”"]/g, "");

const STATUS_WORDS: Record<string, string> = { 麻痹: "麻痹了！", 冰冻: "被冻住了！", 睡眠: "睡着了！", 烧伤: "被烧伤了！", 中毒: "中毒了！" };

// ---------------------------------------------------------------- the engine

export class BattleEngine {
  readonly t: PetTables;
  readonly rng: Rng;

  constructor(t: PetTables, rng: Rng = Math.random) {
    this.t = t;
    this.rng = rng;
  }

  private chance(p: number): boolean {
    return p >= 100 || (p > 0 && this.rng() * 100 < p);
  }

  private int(a: number, b: number): number {
    return a + Math.floor(this.rng() * (b - a + 1));
  }

  start(id: number, room: string, owner: PetOwner, active: PetRecord, wild: PetRecord, canCatch: boolean): Battle {
    return {
      id,
      room,
      mine: fighter(0, active, owner.id, this.t),
      wild: fighter(1, wild, 0, this.t),
      turn: 0,
      canCatch,
      mustSwitch: false,
      over: false,
    };
  }

  skill(id: number): PmSkill {
    return id === 0 ? STRUGGLE : (this.t.pm.skills[String(id)] ?? { ...STRUGGLE, n: `技能${id}`, d: "" });
  }

  /** The wild 亚比's choice: a random skill with PP left. */
  wildChoice(b: Battle): number {
    const usable = b.wild.pet.skills.filter((s) => s.pp > 0);
    return usable.length ? usable[Math.floor(this.rng() * usable.length)].id : 0;
  }

  /** The skill a fighter uses this turn: the one it gathers power for or keeps using, else its choice. */
  choice(f: Fighter, id: number): number {
    return this.forcedOf(f) ?? id;
  }

  /** The skill f uses this turn by itself, not chosen (the one it gathers power for or keeps using). */
  forcedOf(f: Fighter): number | undefined {
    if (f.charging !== undefined) return f.charging;
    if (f.lock && f.lock.left > 0) return f.lock.id;
    return undefined;
  }

  /**
   * 连续攻击N回合 (lock, rollout), after its use this turn (hit: it landed): the turn counted, the
   * growth of its power for the next one, and after the last what comes then. The HP it healed.
   */
  private keepUp(att: Fighter, fx: SkillEffects, id: number, hit: boolean, lines: string[]): number {
    if (!fx.lock && !fx.rollout) return 0;
    const ro = fx.rollout;
    if (!att.lock || att.lock.id !== id) {
      const turns = fx.lock ? this.int(fx.lock.turns[0], fx.lock.turns[1]) : this.int(ro!.min ?? ro!.turns, ro!.turns);
      att.lock = { id, left: turns - 1, after: fx.lock?.after ?? "none", healF: fx.lock?.healF, boost: 0 };
    } else att.lock.left--;
    if (ro) att.lock.boost = hit || ro.always ? Math.min((att.lock.boost ?? 0) + 1, ro.turns - 1) : 0;
    if (att.lock.left > 0) return 0;
    const after = att.lock.after;
    att.lock = undefined;
    if (after === "confuse" && att.confuse === 0) this.applyStatus(att, "混乱", lines);
    if (after === "rest") att.rest = Math.max(att.rest, 1);
    if (after === "heal" && fx.lock?.healF) return this.heal(att, att.stats[0] * fx.lock.healF);
    return 0;
  }

  /** A new turn: what lasted only the last one ends. */
  startTurn(b: Battle): void {
    b.mine.turn = {};
    b.wild.turn = {};
  }

  private other(b: Battle, f: Fighter): Fighter {
    return f === b.mine ? b.wild : b.mine;
  }

  private has(f: Fighter, s: StatusName | "any"): boolean {
    if (s === "any") return !!f.status || f.confuse > 0 || f.bind > 0 || f.weak > 0 || f.seeded || f.fear > 0;
    if (s === "混乱") return f.confuse > 0;
    if (s === "束缚") return f.bind > 0;
    if (s === "害怕") return f.fear > 0;
    if (s === "衰弱") return f.weak > 0;
    if (s === "寄生") return f.seeded;
    return f.status === s;
  }

  /** Does cond hold for att using a skill on def? */
  private holds(c: Cond | undefined, b: Battle, att: Fighter, def: Fighter, ctx: { crit?: boolean; landed?: boolean; dmg?: number; hits?: number } = {}): boolean {
    if (!c) return true;
    const hp = (f: Fighter) => f.pet.hp / Math.max(1, f.stats[0]);
    if ("foeStatus" in c) return this.has(def, c.foeStatus);
    if ("selfStatus" in c) return c.selfStatus === "any" ? this.has(att, "any") : c.selfStatus.some((s) => this.has(att, s));
    if ("foeHpBelow" in c) return hp(def) < c.foeHpBelow;
    if ("selfHpBelow" in c) return hp(att) < c.selfHpBelow;
    if ("selfHpAbove" in c) return hp(att) > c.selfHpAbove;
    if ("foeHpMore" in c) return def.pet.hp > att.pet.hp;
    if ("foeHpLess" in c) return def.pet.hp < att.pet.hp;
    if ("second" in c) return !att.turn.first;
    if ("faster" in c) return stat(att, "spd") > stat(def, "spd");
    if ("slower" in c) return stat(att, "spd") < stat(def, "spd");
    if ("crit" in c) return !!ctx.crit;
    if ("landed" in c) return !!ctx.landed;
    if ("foeNoDamage" in c) return !def.turn.damaging;
    if ("hurt" in c) return !!att.turn.hurt === c.hurt;
    if ("hitsMultipleOf" in c) return (ctx.hits ?? 0) > 0 && (ctx.hits ?? 0) % c.hitsMultipleOf === 0;
    if ("nine" in c) return (ctx.dmg ?? 0) > 0 && (String(ctx.dmg).includes("9") || (ctx.dmg ?? 0) % 9 === 0);
    if ("mark" in c) return (att.marks[c.mark] ?? -1) >= b.turn;
    if ("chargeUnhurt" in c) return !att.chargeHurt;
    if ("foeMark" in c) return def.marked.includes(c.foeMark);
    return false;
  }

  /** What the heals of this act (or turn end) could not give, by fighter: the 回复 is shown whole. */
  private over = new Map<Fighter, number>();

  private heal(f: Fighter, n: number): number {
    const want = Math.max(0, Math.floor(n));
    const h = Math.min(Math.max(0, f.stats[0] - f.pet.hp), want);
    f.pet.hp += h;
    if (want > h) this.over.set(f, (this.over.get(f) ?? 0) + want - h);
    return h;
  }

  /** The part of f's heals the cap kept back, since it was last asked; it is forgotten. */
  private overflow(f: Fighter): number {
    const o = this.over.get(f) ?? 0;
    this.over.delete(f);
    return o;
  }

  private hurt(f: Fighter, n: number): number {
    const l = Math.max(0, Math.min(f.pet.hp, Math.floor(n)));
    f.pet.hp -= l;
    return l;
  }

  /** A change of stages; false when it could not be made (guarded, locked, at the limit). */
  private stage(f: Fighter, by: Fighter, stats: StatKey[], delta: number, lines: string[], mirrored = false): boolean {
    if (!stats.length || !delta) return false;
    const name = petName(this.t, f);
    if (live(f, "lockStages").length) {
      lines.push(`${name}的属性等级不会改变！`);
      return false;
    }
    if (delta < 0 && by !== f && live(f, "guard").length) {
      lines.push(`${name}的属性等级没有被削弱！`);
      return false;
    }
    let moved = false;
    for (const k of stats) {
      const v = clampStage(f.stages[k] + delta);
      if (v !== f.stages[k]) moved = true;
      f.stages[k] = v;
    }
    const label = ALL_KEYS.every((k) => stats.includes(k)) ? "全属性" : stats.map((k) => STAT_LABEL[k]).join("和");
    lines.push(moved ? `${name}的${label}${delta > 0 ? "提升" : "下降"}了！` : `${name}的${label}已经不能再${delta > 0 ? "提升" : "下降"}了！`);
    // 远古记忆: what f raises for itself, the other raises too.
    const o = this.cur && (this.cur.mine === f ? this.cur.wild : this.cur.mine);
    if (moved && delta > 0 && by === f && !mirrored && o && o !== f && o.pet.hp > 0 && live(o, "mirror").length) this.stage(o, o, stats, delta, lines, true);
    return moved;
  }

  /** The battle being played (for what one fighter's change does to the other). */
  private cur?: Battle;
  /** What a counter used after the blow took off the other this action. */
  private countered = 0;

  /** Give f a status (害怕 混乱 束缚 衰弱 寄生 beside the five); false when it does not take. */
  applyStatus(f: Fighter, s: StatusName, lines: string[], turns?: [number, number]): boolean {
    const name = petName(this.t, f);
    if (f.pet.hp <= 0) return false;
    if (live(f, "nostatus").some((x) => !x.only || x.only.includes(s))) return false;
    const n = turns ? this.int(turns[0], turns[1]) : 0;
    if (s === "害怕") {
      f.fear = Math.max(f.fear, n || 1);
      lines.push(`${name}害怕了！`);
      return true;
    }
    if (s === "混乱") {
      if (f.confuse > 0) return false;
      f.confuse = n || this.int(2, 4);
      lines.push(`${name}混乱了！`);
      return true;
    }
    if (s === "束缚") {
      if (f.bind > 0) return false;
      f.bind = n || this.int(4, 5);
      f.trapped = Math.max(f.trapped, f.bind);
      lines.push(`${name}被束缚住了！`);
      return true;
    }
    if (s === "衰弱") {
      if (f.weak > 0) return false;
      f.weak = 1;
      f.weakLeft = n;
      lines.push(`${name}衰弱了！`);
      return true;
    }
    if (s === "寄生") {
      if (f.seeded || f.types.includes(11)) return false;
      f.seeded = true;
      lines.push(`${name}被寄生了！`);
      return true;
    }
    if (f.status) return false;
    // Fire 亚比 do not burn, ice ones do not freeze, poison ones are not poisoned (属性 9, 14, 3).
    const immune = { 烧伤: 9, 冰冻: 14, 中毒: 3 } as Record<string, number>;
    if (immune[s] !== undefined && f.types.includes(immune[s])) return false;
    f.status = s;
    f.statusLeft = s === "睡眠" ? 0 : n;
    if (s === "睡眠") f.sleep = n || this.int(2, 4);
    lines.push(`${name}${STATUS_WORDS[s]}`);
    return true;
  }

  /** Take away all of f's statuses. */
  private cureAll(f: Fighter): void {
    f.status = undefined;
    f.statusLeft = 0;
    f.sleep = 0;
    f.confuse = 0;
    f.bind = 0;
    f.fear = 0;
    f.weak = 0;
    f.seeded = false;
  }

  /** One 亚比 uses a skill on the other; returns the 2411 report. */
  act(b: Battle, att: Fighter, def: Fighter, chosen: number): Msg {
    const t = this.t;
    const lines: string[] = [];
    const name = petName(t, att);
    this.cur = b;
    this.countered = 0;
    this.over.clear();
    const skillId = this.choice(att, chosen);
    const sk = this.skill(skillId);
    const fx = parseEffects(sk.d);
    const foeFirst = !!def.turn.moved;
    att.turn.moved = true;
    att.turn.first = !foeFirst;
    att.turn.damaging = sk.k !== 2 || !!fx.dmg;
    const report = (srt: number, extra: Record<string, unknown> = {}): Msg => {
      // The heals shown whole (回复 of 120 at 30 lost: +120), though the 体力 stops at its maximum.
      const shown: Record<string, unknown> = { ...extra };
      const whole = (key: string, f: Fighter) => {
        const o = this.overflow(f);
        if (o > 0) shown[key] = Number(shown[key] ?? 0) + o;
      };
      whole("selfHpInc", att);
      if (def !== att) whole("hpInc", def);
      return [
        "2411",
        { reqSId: att.slot, tarSId: def.slot, id: skillId, name: sk.n, k: sk.k, t: sk.t, self: selfOnly(sk), srt, cri: false, hits: 0, hpInc: 0, selfHpInc: 0, eff: 1, ...shown, desc: lines.join("\n"), pmmList: this.views(b) },
      ];
    };

    // Could it act at all? A 亚比 that cannot loses the power it gathered and the skill it kept up.
    const stopped = (why: string): Msg => {
      att.charging = undefined;
      att.lock = undefined;
      lines.push(why);
      return report(3);
    };
    if (att.rest > 0 && (att.restFrom ?? 0) <= b.turn) {
      att.rest--;
      return stopped(`${name}需要休息，无法行动！`);
    }
    if (att.fear > 0) {
      att.fear--;
      return stopped(`${name}害怕得不敢行动！`);
    }
    if (att.status === "睡眠") {
      if (--att.sleep > 0) return stopped(`${name}正在睡觉……`);
      att.status = undefined;
      lines.push(`${name}醒过来了！`);
    } else if (att.status === "冰冻") {
      if (att.statusLeft > 0 ? --att.statusLeft > 0 : !this.chance(20)) return stopped(`${name}被冻住了，无法行动！`);
      att.status = undefined;
      att.statusLeft = 0;
      lines.push(`${name}解冻了！`);
    } else if (att.status === "麻痹" && this.chance(25)) {
      return stopped(`${name}麻痹了，无法行动！`);
    }
    for (const x of live(att, "noact")) if (this.chance(x.chance ?? 0)) return stopped(`${name}无法行动！`);
    if (att.confuse > 0) {
      att.confuse--;
      if (att.confuse === 0) lines.push(`${name}不再混乱了！`);
      else if (this.chance(33)) {
        const dmg = Math.max(1, Math.floor((Math.floor((2 * att.pet.level) / 5 + 2) * 40 * stat(att, "atk")) / stat(att, "def") / 50 + 2));
        att.pet.hp = Math.max(0, att.pet.hp - dmg);
        att.lock = undefined;
        att.charging = undefined;
        lines.push(`${name}在混乱中攻击了自己！`);
        if (att.pet.hp <= 0) lines.push(`${name}倒下了！`);
        return report(3, { selfHpInc: -dmg });
      }
    }

    // The PP: one use (卧龙觉醒: more); none for the later turns of a skill kept up or released.
    const known = att.pet.skills.find((s) => s.id === skillId);
    const keptUp = (att.lock && att.lock.id === skillId && att.lock.left > 0) || att.charging === skillId;
    if (known && !keptUp) known.pp = Math.max(0, known.pp - (fx.ppCost ?? 1));
    lines.push(`${name}使用了${sk.n}！`);
    const uses = (att.uses[skillId] = (att.uses[skillId] ?? 0) + 1);
    const rolled = att.last === skillId;
    att.last = skillId;
    att.marks[plain(sk.n)] = b.turn + markTurns(sk.d);
    const grow = (p: number) => (fx.grow ? Math.min(100, p * Math.min(3, 1 + (uses - 1) * 0.5)) : p);

    // 蓄力: this turn only the words of this turn (本回合…); the blow comes next turn
    // (蓄力N回合: after N turns of it). The turns between, it goes on gathering by itself.
    if (fx.charge && att.charging === skillId && (att.chargeLeft ?? 0) > 0) {
      att.chargeLeft!--;
      lines.push(`${name}正在蓄力！`);
      return report(0, { k: 2, self: true });
    }
    if (fx.charge && att.charging === undefined) {
      att.charging = skillId;
      att.chargeLeft = (fx.chargeTurns ?? 1) - 1;
      att.chargeHurt = false;
      lines.push(`${name}正在蓄力！`);
      this.stagesOf(b, att, def, fx, lines, { hits: 0 });
      if (fx.shield) att.turn.shield = fx.shield;
      this.lasting(b, att, def, fx, lines, plain(sk.n));
      // The gathering plays on the user, not as a blow.
      return report(0, { k: 2, self: true });
    }
    // The blow after the gathering: what the skill did that turn is not done again.
    const releasing = att.charging === skillId;
    if (releasing) {
      att.charging = undefined;
      att.chargeLeft = undefined;
    }

    // 一场战斗使用次数越多，成功率越低.
    if (fx.fade && uses > 1 && !this.chance(100 / 2 ** (uses - 1))) {
      lines.push("但是失败了……");
      let selfHp = 0;
      if (fx.failHeal) selfHp = this.heal(att, fx.failHeal);
      return report(1, { selfHpInc: selfHp });
    }

    let selfHp = 0;
    // A skill kept up that did not land this turn: 连续攻击N回合 counts the turn all the same.
    const missed = () => {
      if (fx.rollout) selfHp += this.keepUp(att, fx, skillId, false, lines);
      else att.lock = undefined;
    };
    // Its cost, before it acts (先扣除自己…).
    if (fx.selfCost && this.chance(fx.selfCost.chance ?? 100)) {
      const c = fx.selfCost;
      const cost = c.n ?? Math.floor((c.current ? att.pet.hp : att.stats[0]) * (c.f ?? 0));
      selfHp -= this.hurt(att, Math.min(cost, att.pet.hp - 1));
    }

    // This turn's own guards come first (先发 protects): they do not need to hit.
    if (fx.protect && (!fx.protectIfFirst || att.turn.first)) att.turn.protect = true;
    if (fx.shield && !releasing) {
      const sh = fx.shield;
      // A counter (反击) used after the other's blow this turn (后发) strikes back at once.
      const taken = sh.kind === "phys" ? (att.turn.takenPhys ?? 0) : sh.kind === "spec" ? (att.turn.takenSpec ?? 0) : (att.turn.takenPhys ?? 0) + (att.turn.takenSpec ?? 0);
      if (sh.take === 1 && sh.reflect > 0 && taken > 0) {
        if (!sh.ifFirst && def !== att && def.pet.hp > 0) {
          const back = this.hurt(def, taken * sh.reflect);
          lines.push(`${name}反击了${back}点伤害！`);
          if (def.pet.hp <= 0) lines.push(`${petName(t, def)}倒下了！`);
          this.countered = back;
        }
      } else att.turn.shield = sh;
    }
    if (fx.endure === "revive") att.turn.endure = true;
    if (fx.endure === "reviveOnce") att.revive = true;
    if (fx.destiny) att.turn.destiny = true;
    if (fx.grudge) att.turn.grudge = true;
    if (fx.hold) att.turn.hold = true;
    if (fx.absorbHit) att.turn.absorb = true;

    const aims = aimsAtFoe(sk, fx) && def !== att;
    if (aims && def.pet.hp > 0) {
      const sure = fx.sure || live(att, "sure").length > 0;
      let acc = fx.acc ?? sk.acc;
      if (sk.k === 0) for (const x of live(att, "blind")) acc = Math.min(acc, x.phys ?? 100);
      if (!sure && acc < 101 && this.rng() >= (acc / 100) * accMult(att.stages.acc - def.stages.eva)) {
        missed();
        lines.push("没有命中！");
        return report(2, { selfHpInc: selfHp });
      }
      if (def.turn.protect && !fx.pierce) {
        missed();
        lines.push(`${petName(t, def)}挡住了攻击！`);
        return report(1, { selfHpInc: selfHp });
      }
    }

    let dmg = 0;
    let shown = 0;
    let cri = false;
    let mult = 1;
    let hits = 0;
    let crits = 0;
    let perHit: { hitDmg: number[]; hitCri: number[] } | undefined;
    let foeHeal = 0;
    if (aims && (sk.k !== 2 || fx.dmg || fx.ohko || fx.ohkoIf)) {
      mult = sk.t < 0 ? 1 : typeMultiplier(t.pm, sk.t, def.types);
      if (mult === 0 && !fx.dmg) {
        missed();
        lines.push("好像没有效果……");
        return report(1, { eff: 0, selfHpInc: selfHp });
      }
      const hit = this.strike(b, att, def, sk, fx, mult, rolled, lines);
      ({ dmg, shown, cri, hits, crits, foeHeal } = hit);
      // A 连击: each hit's number, shown one after another.
      if (hit.list.length > 1) perHit = { hitDmg: hit.list, hitCri: hit.criList };
      selfHp += hit.selfHp;
      if (hits > 1) lines.splice(lines.length - hit.after, 0, `连续攻击了${hits}次！`);
    }
    const ctx = { crit: cri, crits, dmg: shown, hits, landed: false };

    // What the damage brings the user: 吸取, 反作用, a crit's heal.
    const drainOnStatus = !!fx.drainCond && "landed" in fx.drainCond;
    if (dmg > 0) {
      let drain = live(att, "drain").reduce((s, x) => s + (x.f ?? 0), 0);
      for (const x of live(att, "drain")) if (x.once) x.left = 0;
      if (fx.drain && !drainOnStatus && this.holds(fx.drainCond, b, att, def, ctx)) drain += fx.drain;
      for (const p of fx.powerIf ?? []) if (p.drain !== undefined && this.holds(p.cond, b, att, def, ctx)) drain = Math.max(drain, p.drain);
      if (fx.dmgHeals !== undefined) selfHp += this.heal(att, fx.dmgHeals === "all" ? dmg : fx.dmgHeals);
      if (drain > 0) {
        const want = Math.floor(Math.max(1, dmg * drain));
        const h = this.heal(att, want);
        selfHp += h;
        if (h > 0) lines.push(`${name}回复了体力！`);
        // 溢出的回复量会转化为自己的护盾.
        if (fx.overShield && want > h && att.pet.hp > 0) {
          att.armour = (att.armour ?? 0) + want - h;
          lines.push(`${name}获得了${want - h}点护盾！`);
        }
      }
      if ((fx.recoil || sk === STRUGGLE) && this.chance(fx.recoilChance ?? 100)) {
        const r = Math.max(1, Math.floor(dmg * (fx.recoil ?? 0.25)));
        selfHp -= this.hurt(att, r);
        lines.push(`${name}受到了反作用伤害！`);
      }
      // 每次暴击均回复…: each crit of a 连击.
      if (fx.critHeal && crits) selfHp += this.heal(att, att.stats[0] * fx.critHeal * crits);
    }

    // PP.
    if (aims && fx.ppFoe && this.holds(fx.ppFoe.cond, b, att, def, ctx) && this.chance(fx.ppFoe.chance)) {
      const n = fx.ppFoe.n;
      const which = fx.ppFoe.last ? def.pet.skills.filter((s) => s.id === def.last) : def.pet.skills;
      for (const s of which) s.pp = n === "all" ? 0 : Math.max(0, s.pp - n);
      if (which.length) lines.push(`${petName(t, def)}的技能次数减少了！`);
    }
    if (fx.ppSelfAll) for (const s of att.pet.skills) s.pp = 0;
    if (fx.ppSelf && this.chance(fx.ppSelfChance ?? 100)) {
      for (const s of att.pet.skills) s.pp = Math.max(0, Math.min(s.max, s.pp + fx.ppSelf));
      lines.push(fx.ppSelf > 0 ? `${name}的技能次数回复了！` : `${name}的技能次数减少了！`);
    }

    // Statuses.
    let landed = sk.k !== 2 || dmg > 0;
    const rolls = fx.perHit ? Math.max(1, hits) : 1;
    let statusTried = false;
    let statusLanded = false;
    for (const s of fx.statuses) {
      const target = s.self ? att : def;
      if (!s.self && !aims) continue;
      if (s.cond && !("landed" in s.cond) && !this.holds(s.cond, b, att, def, ctx)) continue;
      if (s.cond && "landed" in s.cond && !statusLanded) continue;
      statusTried = true;
      let chance = s.chance;
      if (s.byLowHp) chance += (100 - chance) * (1 - att.pet.hp / Math.max(1, att.stats[0]));
      if (s.bySpeed) chance += 15 * Math.max(0, att.stages.spd);
      if (s.doubleIf && this.holds(s.doubleIf, b, att, def, ctx)) chance *= 2;
      if (s.condChance && this.holds(s.condChance.cond, b, att, def, ctx)) chance = Math.max(chance, s.condChance.chance);
      chance = grow(chance);
      let ok = false;
      for (let r = 0; r < rolls && !ok; r++) ok = this.chance(chance) && this.applyStatus(target, s.name, lines, s.turns);
      if (ok) {
        statusLanded = true;
        if (s.name === "束缚" && fx.bindHits && hits > 0) target.bind = target.trapped = hits;
      }
    }
    if (fx.hitStatus && fx.hitStatus[hits]) statusLanded = this.applyStatus(def, fx.hitStatus[hits], lines) || statusLanded;
    ctx.landed = statusLanded;
    landed ||= statusLanded;
    if (statusTried && !statusLanded && sk.k === 2 && !fx.stages.length) lines.push("好像没有效果……");
    if (statusLanded && drainOnStatus && fx.drain && dmg > 0) selfHp += this.heal(att, dmg * fx.drain);

    // Stages and what changes them.
    if (!releasing && this.stagesOf(b, att, def, fx, lines, ctx, grow, aims)) landed = true;

    // Healing, curing.
    let heal = 0;
    const ha = fx.healAfter;
    if (ha && (ha.cond && "landed" in ha.cond ? statusLanded : this.holds(ha.cond, b, att, def, ctx)) && this.chance(ha.chance)) {
      let f = ha.f;
      for (const p of fx.powerIf ?? []) if (p.heal !== undefined && this.holds(p.cond, b, att, def, ctx)) f = Math.max(f, p.heal);
      heal += this.heal(att, att.stats[0] * f);
    }
    if (fx.healFull) heal += this.heal(att, att.stats[0]);
    if (fx.healFlat && this.chance(fx.healChance ?? 100)) heal += this.heal(att, fx.healFlat);
    if (fx.healLost) heal += this.heal(att, (att.stats[0] - att.pet.hp) * fx.healLost);
    if (fx.healBoth) {
      heal += this.heal(att, att.stats[0] / 4);
      foeHeal += this.heal(def, def.stats[0] / 4);
    }
    if (heal > 0) {
      selfHp += heal;
      lines.push(`${name}回复了体力！`);
      landed = true;
    } else if ((fx.healAfter || fx.healFull || fx.healFlat) && sk.k === 2 && !fx.stages.length && !fx.statuses.length) lines.push("体力已经是满的了。");
    if (fx.cure && this.has(att, "any")) {
      this.cureAll(att);
      lines.push(`${name}的不良状态都消除了！`);
      landed = true;
    }
    if (fx.unstatus && att.status === fx.unstatus) {
      att.status = undefined;
      lines.push(`${name}的${fx.unstatus}状态解除了！`);
    }
    if (fx.sleepAfter && att.pet.hp > 0) {
      att.status = undefined;
      this.applyStatus(att, "睡眠", lines, [fx.sleepAfter + 1, fx.sleepAfter + 1]);
    }
    if (aims && fx.passStatus && att.status && !def.status) {
      def.status = att.status;
      def.sleep = att.sleep;
      def.statusLeft = att.statusLeft;
      lines.push(`${name}把${att.status}转移给了${petName(t, def)}！`);
      att.status = undefined;
      att.sleep = att.statusLeft = 0;
    }
    // 体力 swapped or shared.
    const share = (f: Fighter) => f.pet.hp / Math.max(1, f.stats[0]);
    if (aims && fx.swapHpRatio && share(att) < share(def) && this.chance(fx.swapHpRatio)) {
      const [a, d] = [share(att), share(def)];
      const before = [att.pet.hp, def.pet.hp];
      att.pet.hp = Math.max(1, Math.round(att.stats[0] * d));
      def.pet.hp = Math.max(1, Math.round(def.stats[0] * a));
      selfHp += att.pet.hp - before[0];
      shown -= def.pet.hp - before[1];
      lines.push("双方的体力调换了！");
    }
    if (aims && fx.painSplit && this.chance(fx.painSplitChance ?? 100) && (fx.painSplitChance === undefined || def.pet.hp > att.pet.hp)) {
      const avg = Math.floor((att.pet.hp + def.pet.hp) / 2);
      const before = [att.pet.hp, def.pet.hp];
      att.pet.hp = Math.min(att.stats[0], avg);
      def.pet.hp = Math.min(def.stats[0], avg);
      selfHp += att.pet.hp - before[0];
      shown -= def.pet.hp - before[1];
      lines.push("双方平分了体力！");
    }
    if (aims && fx.swapHp) {
      const before = [att.pet.hp, def.pet.hp];
      att.pet.hp = Math.min(att.stats[0], before[1]);
      def.pet.hp = Math.min(def.stats[0], before[0]);
      selfHp += att.pet.hp - before[0];
      shown -= def.pet.hp - before[1];
      lines.push("双方的体力调换了！");
    }

    // What lasts.
    if (!releasing && this.lasting(b, att, def, fx, lines, plain(sk.n))) landed = true;
    if (aims && fx.trap) def.trapped = Math.max(def.trapped, this.int(fx.trap[0], fx.trap[1]));
    if (aims && fx.forceSwitch && def.pet.hp > 0) {
      // A wild 亚比 has no team to switch to; a player's 亚比 goes back (the turn sends the next one).
      if (def.slot === 1 && !b.duel) lines.push("好像没有效果……");
      else {
        b.forceOut = def.slot;
        landed = true;
      }
    }
    if (fx.trait && !releasing) {
      let any_ = false;
      for (const f of def === att || fx.trait.side === "self" ? [att] : [att, def]) {
        if (f.pet.hp <= 0 || !hasTrait(f, fx.trait.name)) continue;
        any_ = true;
        if (fx.trait.statmult) {
          const m = fx.trait.statmult;
          f.timed = f.timed.filter((x) => !(x.kind === "statmult" && x.trait));
          f.timed.push({ who: "self", kind: "statmult", turns: m.turns, left: m.turns, stats: m.stats, mult: m.mult, trait: true });
          lines.push(`${petName(t, f)}的${m.stats.map((k) => STAT_LABEL[k]).join("和")}增加了！`);
        }
        if (fx.trait.power) {
          f.timed = f.timed.filter((x) => !(x.kind === "power" && x.trait));
          f.timed.push({ who: "self", kind: "power", turns: 99, mult: fx.trait.power, trait: true, left: 99 });
          lines.push(`${petName(t, f)}的伤害增加了！`);
        }
        if (fx.trait.stats) {
          const d = fx.trait.deltaMax !== undefined ? this.int(fx.trait.delta ?? 1, fx.trait.deltaMax) : (fx.trait.delta ?? 1);
          this.stage(f, f, fx.trait.stats, d, lines);
        }
      }
      if (any_) landed = true;
      else lines.push("好像没有效果……");
    }
    if (aims && fx.baseDown) {
      def.baseDown[fx.baseDown.stat] += fx.baseDown.n;
      lines.push(`${petName(t, def)}的${fx.baseDown.stat === "atk" ? "攻击" : "特攻"}降低了！`);
      landed = true;
    }
    if (fx.baseUp && att.baseUp.n < fx.baseUp.max) {
      att.baseUp = { n: att.baseUp.n + 1, pct: fx.baseUp.pct };
      lines.push(`${name}的能力增强了！`);
      landed = true;
    }
    if (aims && fx.markFoe && dmg > 0 && !def.marked.includes(fx.markFoe.name)) {
      def.marked.push(fx.markFoe.name);
      def.baseDown.pct = Math.min(90, def.baseDown.pct + fx.markFoe.downPct);
      lines.push(`${petName(t, def)}陶醉了！`);
    }
    if (fx.nextFullHeal || fx.reviveNext) (b.nextHeal ??= [])[att.slot] = true;

    // The turns after.
    if (fx.recharge && this.chance(fx.rechargeChance ?? 100)) att.rest = Math.max(att.rest, fx.rechargeTurns ?? 1);
    // 原子爆裂: the user or the other stops its next turn (not the user if the other is 麻痹, not
    // the other if it is 害怕).
    if (fx.eitherStops && aims && dmg > 0 && def.pet.hp > 0 && this.chance(fx.eitherStops)) {
      if (this.rng() < 0.5) {
        if (!this.has(def, "麻痹")) {
          att.rest = Math.max(att.rest, 1);
          lines.push(`${name}下回合停止行动！`);
        }
      } else if (!this.has(def, "害怕")) {
        def.rest = Math.max(def.rest, 1);
        def.restFrom = b.turn + 1;
        lines.push(`${petName(t, def)}下回合停止行动！`);
      }
    }
    selfHp += this.keepUp(att, fx, skillId, true, lines);
    if (fx.selfConfuse && att.confuse === 0) this.applyStatus(att, "混乱", lines);
    if (fx.sacrifice) att.pet.hp = 0;
    if (fx.bothFaint && aims) {
      shown += def.pet.hp;
      def.pet.hp = 0;
      att.pet.hp = 0;
    }
    if (fx.healOnKO && def.pet.hp <= 0 && att.pet.hp > 0) selfHp += this.heal(att, att.stats[0] * fx.healOnKO);

    if (def.pet.hp <= 0 && def !== att) lines.push(`${petName(t, def)}倒下了！`);
    if (att.pet.hp <= 0) lines.push(`${name}倒下了！`);
    const any = landed || sk.k !== 2 || selfHp !== 0 || fx.timed.length > 0 || !!fx.field || fx.protect || !!fx.shield;
    return report(any || this.countered > 0 ? 0 : 1, { cri, hits, hpInc: -(shown + this.countered) + foeHeal, selfHpInc: selfHp, eff: mult, ...perHit });
  }

  /** The damage of a damaging skill (all its hits) on def, with what def's guards make of it. */
  private strike(b: Battle, att: Fighter, def: Fighter, sk: PmSkill, fx: SkillEffects, mult: number, rolled: boolean, lines: string[]) {
    const t = this.t;
    // list: each hit's damage as shown (0: dodged or taken by a guard), criList: its 暴击.
    const out = { dmg: 0, shown: 0, cri: false, crits: 0, hits: 0, selfHp: 0, foeHeal: 0, after: 0, list: [] as number[], criList: [] as number[] };
    const mark = lines.length;
    const dn = petName(t, def);
    // Every chance is rolled for each hit of a 连击 on its own: its 暴击, the guard's 受到伤害时…
    // (玄灵甲's 50%), 每次攻击….
    // 连击: how many hits. Each hit meets def's guards on its own (玄灵甲: 每次受到伤害…).
    let n = fx.hits ? this.int(fx.hits[0], fx.hits[1]) : 1;
    for (const x of fx.extraHits ?? []) if (this.chance(x.chance)) n = Math.max(n, x.n);
    if (fx.hitsIf && this.holds(fx.hitsIf.cond, b, att, def)) n = fx.hitsIf.set ?? n + (fx.hitsIf.add ?? 0);
    // Damage not by the formula (points, levels, a share of the HP): one hit.
    let fixedDmg = -1;
    if (fx.dmg) {
      if (fx.dmgChance === undefined || this.chance(fx.dmgChance)) {
        const d = fx.dmg;
        let raw =
          d.kind === "flat" ? d.n
          : d.kind === "level" ? att.pet.level * (d.a + this.rng() * (d.b - d.a))
          : d.kind === "foeLevel" ? def.pet.level * d.mult
          : d.kind === "hpFrac" ? def.pet.hp * d.f
          : d.kind === "maxFrac" ? def.stats[0] * d.f
          : this.int(d.a, d.b);
        if (fx.dmgByType) raw *= mult > 1 ? 1.5 : mult < 1 ? 0.5 : 1;
        fixedDmg = Math.max(1, Math.floor(raw));
      }
      n = fixedDmg >= 0 ? 1 : 0;
    } else if (sk.k === 2) n = 1; // a 属性 skill's 秒杀 (命运硬币): no damage of its own
    // 秒杀: once, or each hit of a 连击 that says 每次攻击.
    let ohko = fx.ohko ?? 0;
    if (ohko && fx.ohkoDoubleIf && this.holds(fx.ohkoDoubleIf, b, att, def)) ohko *= 2;
    if (fx.ohkoIf && this.holds(fx.ohkoIf.cond, b, att, def) && (!fx.ohkoIf.lowerLevel || def.pet.level <= att.pet.level) && (fx.ohkoIf.hpBelow === undefined || def.pet.hp < fx.ohkoIf.hpBelow)) ohko = Math.max(ohko, fx.ohkoIf.chance);
    if (isGuardian(def.pet.race)) ohko /= 2;
    const ohkoEachHit = !!fx.hits && !!fx.perHit;
    let killed = false;
    // 普通攻击 (k 0) or 特殊攻击 (k 1); the damage of a 属性 skill (k 2: 扣除对方一半体力值) is neither.
    const phys = sk.k === 0;
    const spec = sk.k === 1;
    const kindOk = (x: { phys?: number; spec?: number }) => (phys ? x.phys : spec ? x.spec : undefined);
    const sh = fx.pierce ? undefined : def.turn.shield;
    const shieldOn = !!sh && (!sh.kind || (sh.kind === "phys" ? phys : spec)) && (!sh.ifFirst || !!def.turn.first);
    let reflect = 0;
    let dodged = 0;
    let blocked = 0;
    let soaked = 0;
    let shielded = 0;
    let armoured = 0;
    for (let i = 0; i < n && def.pet.hp > 0 && att.pet.hp > 0; i++) {
      let dmg = 0;
      let hitCri = false;
      if (fixedDmg >= 0) dmg = fixedDmg;
      else if (sk.k !== 2) {
        const r = this.damage(b, att, def, sk, fx, mult, rolled, i, this.rollCrit(b, att, def, fx));
        dmg = r.dmg;
        if (r.cri) {
          out.cri = true;
          out.crits++;
          hitCri = true;
        }
      }
      out.hits++;
      out.list.push(0);
      out.criList.push(hitCri ? 1 : 0);
      if (ohko && !killed && (i === 0 || ohkoEachHit)) {
        if (this.chance(ohko)) {
          killed = true;
          dmg = Math.max(dmg, def.pet.hp);
          lines.push("一击必杀！");
        }
      }
      if (fx.endeavor) dmg = Math.max(0, def.pet.hp - att.pet.hp);
      if (fx.falseSwipe) dmg = Math.min(dmg, def.pet.hp - 1);
      // def's guards, for this hit.
      if (!fx.pierce && live(def, "dodge").some((x) => kindOk(x) !== undefined && this.chance(kindOk(x)!))) {
        dodged++;
        continue;
      }
      if (shieldOn) {
        reflect += dmg * sh!.reflect;
        dmg = Math.floor(dmg * sh!.take);
        if (sh!.take === 0) blocked++;
      }
      for (const x of live(def, "screen")) {
        const f = kindOk(x);
        if (f !== undefined) dmg = Math.floor(dmg * f);
      }
      // 每回合自己可以抵抗N点伤害值: N a turn, however many hits.
      for (const x of fx.pierce ? [] : live(def, "absorb")) {
        const left = Math.max(0, (x.n ?? 0) - (def.turn.absorbed ?? 0));
        const take = Math.min(left, dmg);
        if (take <= 0) continue;
        dmg -= take;
        def.turn.absorbed = (def.turn.absorbed ?? 0) + take;
        shielded += take;
      }
      // 护盾 (嗜血之矛): its points take each blow first, till they are used up.
      if (!fx.pierce && (def.armour ?? 0) > 0 && dmg > 0) {
        const take = Math.min(def.armour!, dmg);
        def.armour! -= take;
        dmg -= take;
        armoured += take;
      }
      if (dmg > 0 && live(def, "doom").some((x) => this.chance(x.chance ?? 0))) {
        dmg = Math.max(dmg, def.pet.hp);
        lines.push("一击必杀！");
      }
      if (def.turn.absorb && dmg > 0) {
        out.foeHeal += this.heal(def, dmg);
        soaked++;
        continue;
      }
      if (def.turn.hold) dmg = Math.min(dmg, def.pet.hp - 1);
      out.shown += dmg;
      out.list[out.list.length - 1] = dmg;
      const lost = this.hurt(def, dmg);
      out.dmg += lost;
      if (lost > 0) {
        def.turn.hurt = true;
        if (phys) def.turn.takenPhys = (def.turn.takenPhys ?? 0) + lost;
        if (spec) def.turn.takenSpec = (def.turn.takenSpec ?? 0) + lost;
        if (def.charging !== undefined) def.chargeHurt = true;
      }
      // What comes back, for this hit (霸王之气: 每次受到攻击则返还50点).
      for (const x of live(def, "reflect")) if (lost > 0 || x.n) reflect += x.n ?? lost * (kindOk(x) ?? 0);
      // Falls, or comes back.
      if (def.pet.hp <= 0 && def.turn.endure) {
        def.pet.hp = def.stats[0];
        lines.push(`${dn}满状态复活了！`);
      } else if (def.pet.hp <= 0 && def.revive) {
        def.revive = false;
        def.pet.hp = def.stats[0];
        lines.push(`${dn}满状态复活了！`);
      }
      if (lost <= 0) continue;
      // def's 受到伤害时 effects, each hit.
      if (def.pet.hp > 0) {
        for (const x of live(def, "onhurt")) {
          if (!this.chance(x.chance ?? 100)) continue;
          if (x.stats?.length) this.stage(x.selfStage ? def : att, def, x.stats, x.delta ?? 0, lines);
          if (x.status) {
            const ss = x.bothStatus ? [x.status, x.statusAlt!] : [x.statusAlt && this.rng() < 0.5 ? x.statusAlt : x.status];
            for (const st of ss) this.applyStatus(att, st, lines);
          }
          if (x.n) for (const s2 of att.pet.skills) s2.pp = Math.max(0, s2.pp - x.n);
          if (x.once) x.left = 0;
        }
      }
      // att's 给对方造成伤害时 effects, each hit.
      for (const x of live(att, "hitHeal")) out.selfHp += this.heal(att, x.n ?? 0);
      for (const x of live(att, "onhit")) {
        if (!this.chance(x.chance ?? 0)) continue;
        if (x.n === 1) this.applyStatus(def, "害怕", lines);
        else if (x.n === 2) for (const k of ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
        else if (x.status) this.applyStatus(def, x.status, lines);
      }
    }
    if (ohko && !killed && fx.ohkoFailFaint) {
      out.selfHp -= this.hurt(att, att.pet.hp);
      lines.push(`${petName(t, att)}倒下了……`);
    }
    if (dodged) lines.push(dodged === out.hits ? `${dn}闪避了攻击！` : `${dn}闪避了${dodged}次攻击！`);
    if (blocked) lines.push(`${dn}挡住了伤害！`);
    if (shielded) lines.push(`${dn}抵挡了${shielded}点伤害！`);
    if (armoured) lines.push(`${dn}的护盾抵挡了${armoured}点伤害！${def.armour ? "" : `${dn}的护盾消失了！`}`);
    if (soaked) lines.push(`${dn}吸收了伤害！`);
    if (def.pet.hp <= 0 && def.turn.destiny) {
      out.selfHp -= this.hurt(att, att.pet.hp);
      lines.push("双方同归于尽！");
    }
    if (def.pet.hp <= 0 && def.turn.grudge) for (const s2 of att.pet.skills) s2.pp = 0;
    if (sh && sh.ifAlive && def.pet.hp <= 0) reflect = 0;
    if (reflect >= 1 && att.pet.hp > 0) {
      const back = this.hurt(att, reflect);
      out.selfHp -= back;
      lines.push(`${dn}反击了${back}点伤害！`);
    }
    if (out.cri) lines.push(out.crits > 1 ? `暴击${out.crits}次！` : "暴击！");
    if (out.hits - dodged > 0) {
      if (mult > 1) lines.push("效果拔群！");
      else if (mult < 1) lines.push("效果不理想……");
    }
    // The same line of each hit once, with how many times (兔小子的全属性下降了！×3).
    const mine = lines.splice(mark);
    for (let i = 0; i < mine.length; ) {
      let j = i + 1;
      while (j < mine.length && mine[j] === mine[i]) j++;
      lines.push(j - i > 1 ? `${mine[i]}×${j - i}` : mine[i]);
      i = j;
    }
    out.after = lines.length - mark;
    return out;
  }

  /** One hit by the formula. */
  /** 暴击 of one hit: sure when the description says, its chance, or by the 暴击 stage. */
  private rollCrit(b: Battle, att: Fighter, def: Fighter, fx: SkillEffects): boolean {
    if (fx.critIf && this.holds(fx.critIf, b, att, def)) return true;
    const timedCrit = Math.max(0, ...live(att, "crit").map((x) => x.chance ?? 0));
    const critStage = Math.min(4, Math.max(0, att.stages.crit + (fx.highCrit ? 1 : 0)));
    const p = Math.max(fx.critChance ?? 0, timedCrit, [100 / 16, 100 / 8, 100 / 4, 100 / 3, 100 / 2][critStage]);
    return this.rng() * 100 < p;
  }

  private damage(b: Battle, att: Fighter, def: Fighter, sk: PmSkill, fx: SkillEffects, mult: number, rolled: boolean, i: number, cri: boolean): { dmg: number; cri: boolean } {
    // The client shows doubled powers (单倍威力 / 双倍威力 columns); the classic formula takes the single one.
    let power = sk.p > 1 ? sk.p : 60;
    if (fx.powerRange) power = this.int(fx.powerRange[0], fx.powerRange[1]);
    const ctx0 = { crit: false };
    let fixed = fx.fixed && this.chance(fx.fixedChance ?? 100) ? fx.fixed : 0;
    if (fx.fixedRange) fixed += this.int(fx.fixedRange[0], fx.fixedRange[1]);
    for (const p of fx.powerIf ?? []) {
      if (p.drain !== undefined || p.heal !== undefined || !this.holds(p.cond, b, att, def, ctx0)) continue;
      if (p.set !== undefined) power = p.set;
      if (p.mult !== undefined) power *= p.mult;
      if (p.power !== undefined) power += p.power;
      if (p.add !== undefined) fixed += p.add;
    }
    if (fx.copyPower && def.last !== undefined) power += Math.max(0, this.skill(def.last).p) / 2;
    // 连续攻击N回合, 威力递增: its later turns.
    const grown = fx.rollout && att.lock && att.lock.id === att.last ? att.lock.boost ?? 0 : 0;
    if (fx.rollout && grown > 0) power = fx.rollout.add ? power + fx.rollout.add * grown : power * 2 ** grown;
    if (fx.perHitPower) power += fx.perHitPower * i;
    if (fx.powerByHp) power = hpPower(fx.powerByHp, sk.p, att, def);
    if (fx.powerBySpeed) {
      const r = stat(att, "spd") / stat(def, "spd");
      power *= Math.max(0.5, Math.min(2.5, fx.powerBySpeed === "fast" ? r : 1 / r));
    }
    for (const x of live(att, "power")) {
      if (x.attr !== undefined && x.attr !== sk.t) continue;
      if (x.mult) power *= x.mult;
      if (x.add) power += x.add;
    }
    for (const x of live(att, "extra")) if (x.chance !== -1) fixed += x.n ?? (x.a !== undefined ? this.int(x.a, x.b ?? x.a) : 0);
    if (b.field) {
      if (sk.t === b.field.up) power *= 1 + b.field.upPct / 100;
      if (b.field.down !== undefined && sk.t === b.field.down) power *= 1 - (b.field.downPct ?? 0) / 100;
    }
    power /= 2;
    const special = sk.k === 1;
    const a = stat(att, special ? "satk" : "atk");
    const noUps = !!fx.ignoreDef || (fx.ignoreUps !== undefined && this.chance(fx.ignoreUps));
    const d = stat(def, special ? "sdef" : "def", noUps) * (fx.ignoreDef ? 0.5 : 1);
    const base = Math.floor(Math.floor((Math.floor((2 * att.pet.level) / 5 + 2) * power * a) / d) / 50) + 2;
    if (cri) for (const x of live(att, "extra")) if (x.chance === -1) fixed += x.n ?? 0;
    const stab = sk.t >= 0 && (att.types[0] === sk.t || att.types[1] === sk.t) ? 1.5 : 1;
    const burn = att.status === "烧伤" && !special ? 0.5 : 1;
    let boost = 1;
    for (const x of fx.boost ?? []) {
      if (this.holds(x.cond, b, att, def) && this.chance(x.chance)) {
        boost = x.mult;
        break;
      }
    }
    const rand = 0.85 + this.rng() * 0.15;
    const dmg = Math.max(1, Math.floor(base * stab * mult * (cri ? 1.5 : 1) * burn * boost * rand)) + fixed;
    return { dmg, cri };
  }

  /** The skill's stage changes, and the moves of stages (clear, restore, copy, swap…); true when one was made. */
  private stagesOf(b: Battle, att: Fighter, def: Fighter, fx: SkillEffects, lines: string[], ctx: { crit?: boolean; crits?: number; landed?: boolean; dmg?: number; hits?: number }, grow = (p: number) => p, aims = true): boolean {
    let any = false;
    const toUser = fx.fate === undefined || this.chance(fx.fate);
    let failed = false;
    for (const ch of fx.stages) {
      if (fx.stagesIfCrit && !ctx.crit) continue;
      if (ch.cond && !this.holds(ch.cond, b, att, def, ctx)) continue;
      let f = ch.self ? att : def;
      if (!ch.self && (!aims || def === att)) continue;
      if (ch.self && !toUser) f = def;
      const chance = grow(ch.condChance && this.holds(ch.condChance.cond, b, att, def, ctx) ? ch.condChance.chance : ch.chance);
      // A 连击's 每次攻击…: each hit; 每次暴击…: each crit.
      const rolls = ch.cond && "crit" in ch.cond ? Math.max(1, ctx.crits ?? 1) : fx.perHit ? Math.max(1, ctx.hits ?? 1) : 1;
      for (let r = 0; r < rolls; r++) {
        if (f.pet.hp <= 0) break;
        if (!this.chance(chance)) {
          failed = true;
          continue;
        }
        let stats = ch.stats;
        if (ch.groups) stats = ch.groups[Math.floor(this.rng() * ch.groups.length)];
        if (ch.pick) {
          const pool = [...stats];
          const k = this.int(ch.pick[0], ch.pick[1]);
          stats = [];
          while (stats.length < k && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
        }
        let delta = ch.deltaMax !== undefined ? Math.sign(ch.delta) * this.int(Math.abs(ch.delta), Math.abs(ch.deltaMax)) : ch.delta;
        if (fx.stageDouble && this.chance(fx.stageDouble)) delta *= 2;
        const before = stats.map((k) => f.stages[k]);
        if (this.stage(f, att, stats, delta, lines)) {
          any = true;
          // 持续N回合: the change goes when the turns are over.
          if (ch.turns) f.timed.push({ who: "self", kind: "revert", turns: ch.turns, left: ch.turns, stats, deltas: stats.map((k, i) => f.stages[k] - before[i]) });
        }
      }
    }
    if (failed && fx.failCost) {
      this.hurt(att, fx.failCost);
      lines.push(`${petName(this.t, att)}失败了，受到了伤害！`);
    }
    const name = petName(this.t, def);
    if (aims && def !== att) {
      if (fx.clearFoeUps && this.chance(fx.clearFoeUps.chance)) {
        if (fx.copyFoeUps && this.chance(fx.copyFoeUps.chance)) for (const k of ALL_KEYS) if (def.stages[k] > 0) att.stages[k] = clampStage(att.stages[k] + def.stages[k]);
        for (const k of fx.clearFoeUps.stats ?? ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
        lines.push(`${name}提升的能力等级被清除了！`);
        any = true;
      } else if (fx.copyFoeUps && this.chance(fx.copyFoeUps.chance)) {
        for (const k of ALL_KEYS) if (fx.copyAll ? def.stages[k] !== 0 : def.stages[k] > 0) att.stages[k] = clampStage(fx.copyAll ? def.stages[k] : Math.max(att.stages[k], def.stages[k]));
        lines.push(`${petName(this.t, att)}复制了${name}的能力等级！`);
        any = true;
      }
      if (fx.resetFoe) for (const k of ALL_KEYS) def.stages[k] = 0;
      if (fx.swapStages) {
        const a = { ...att.stages };
        att.stages = { ...def.stages };
        def.stages = a;
        lines.push("双方交换了能力等级！");
        any = true;
      }
      if (fx.passDowns) {
        for (const k of ALL_KEYS) {
          if (att.stages[k] < 0) {
            def.stages[k] = clampStage(def.stages[k] + att.stages[k]);
            att.stages[k] = 0;
          }
        }
        lines.push(`${petName(this.t, att)}把被削弱的能力等级转移给了${name}！`);
        any = true;
      }
      if (fx.stealStages && (fx.stealStages.minDmg === undefined || (ctx.dmg ?? 0) > fx.stealStages.minDmg)) {
        for (const k of fx.stealStages.stats) {
          def.stages[k] = clampStage(def.stages[k] - fx.stealStages.delta);
          att.stages[k] = clampStage(att.stages[k] + fx.stealStages.delta);
        }
        any = true;
      }
    }
    if (fx.clearBothUps) for (const f of [att, def]) for (const k of ALL_KEYS) f.stages[k] = Math.min(0, f.stages[k]);
    if (fx.resetSelf) for (const k of ALL_KEYS) att.stages[k] = 0;
    if (fx.restoreOwn && this.chance(fx.restoreOwn.chance) && ALL_KEYS.some((k) => att.stages[k] < 0)) {
      for (const k of ALL_KEYS) att.stages[k] = Math.max(0, att.stages[k]);
      lines.push(`${petName(this.t, att)}被削弱的能力等级恢复了！`);
      any = true;
    }
    if (fx.swapOwnStages) {
      const s = att.stages;
      [s.atk, s.def, s.satk, s.sdef] = [s.def, s.atk, s.sdef, s.satk];
      any = true;
    }
    return any;
  }

  /** The skill's lasting effects onto their holders, the field, later turns; true when there was one. */
  private lasting(b: Battle, att: Fighter, def: Fighter, fx: SkillEffects, lines: string[], from: string): boolean {
    let any = false;
    const toUser = fx.fate === undefined || this.chance(fx.fate);
    for (const x of fx.timed) {
      const holders = x.who === "both" ? [att, def] : x.who === "self" ? [toUser ? att : def] : def === att ? [] : [def];
      for (const f of holders) {
        if (f.pet.hp <= 0) continue;
        // 不能和“X”同时存在: X's effects go.
        if (fx.exclusiveWith) f.timed = f.timed.filter((y) => y.from !== fx.exclusiveWith);
        // The same effect again from the same skill: its turns start over (不可叠加); one that
        // stacks (可以叠加使用，最多叠加N次) adds another, the oldest going past the most.
        const same = (y: Live) => y.from === from && y.kind === x.kind && y.attr === x.attr && y.left > 0 && y.n === x.n && y.f === x.f && y.mult === x.mult && y.status === x.status;
        if (x.stack) {
          const old = f.timed.filter(same);
          if (old.length >= x.stack) f.timed.splice(f.timed.indexOf(old[0]), 1);
        } else f.timed = f.timed.filter((y) => !same(y));
        const y: Live = { ...x, from, left: x.turnsMin !== undefined ? this.int(x.turnsMin, x.turns) : x.turns };
        if (y.flip) this.flip(y);
        f.timed.push(y);
        any = true;
      }
    }
    if (fx.field) {
      b.field = { ...fx.field, left: fx.field.turns };
      lines.push("场地的力量改变了！");
      any = true;
    }
    if (fx.delayed) {
      const d = fx.delayed;
      (b.delayed ??= []).push({ slot: d.who === "self" ? att.slot : def.slot, left: d.turns, kind: d.kind, n: d.n, f: d.f, stats: d.stats, delta: d.delta, chance: d.chance });
      any = true;
    }
    if (fx.healFoeEnd) (b.delayed ??= []).push({ slot: def.slot, left: 0, kind: "heal", n: fx.healFoeEnd });
    return any;
  }

  /** 龙之逆鳞: this turn against 普通攻击 or 特殊攻击, at random. */
  private flip(x: Live): void {
    const phys = this.rng() < 0.5;
    x.phys = phys ? 0.5 : undefined;
    x.spec = phys ? undefined : 0.5;
  }

  /** The end of a turn: statuses, the lasting effects and later-turn effects; 2421 reports. */
  endOfTurn(b: Battle): Msg[] {
    this.cur = b;
    this.over.clear();
    const out: Msg[] = [];
    const lostOf = new Map<Fighter, number>();
    const lineOf = new Map<Fighter, string[]>();
    const lose = (f: Fighter, n: number, line?: string) => {
      const l = this.hurt(f, n);
      lostOf.set(f, (lostOf.get(f) ?? 0) - l);
      if (line) lineOf.get(f)!.push(line);
      return l;
    };
    const gain = (f: Fighter, n: number, line?: string) => {
      const h = this.heal(f, n);
      lostOf.set(f, (lostOf.get(f) ?? 0) + h);
      if (line && h > 0) lineOf.get(f)!.push(line);
      return h;
    };
    for (const f of [b.mine, b.wild]) lineOf.set(f, []);
    for (const f of [b.mine, b.wild]) {
      if (f.pet.hp <= 0) continue;
      const o = this.other(b, f);
      const lines = lineOf.get(f)!;
      const name = petName(this.t, f);
      const max = f.stats[0];
      if (f.status === "烧伤" || f.status === "中毒") lose(f, Math.max(1, max / 8), `${name}受到了${f.status === "烧伤" ? "烧伤" : "毒"}的伤害！`);
      if (f.weak > 0) {
        lose(f, Math.max(1, (max * Math.min(8, f.weak)) / 16), `${name}受到了衰弱的伤害！`);
        f.weak++;
        if (f.weakLeft && --f.weakLeft === 0) {
          f.weak = 0;
          lines.push(`${name}不再衰弱了！`);
        }
      }
      if (f.seeded && o.pet.hp > 0) {
        const l = lose(f, Math.max(1, max / 8), `${name}被吸取了体力！`);
        gain(o, l);
      }
      if (f.bind > 0) {
        f.bind--;
        lose(f, Math.max(1, max / 16), f.bind > 0 ? `${name}受到了束缚的伤害！` : `${name}挣脱了束缚！`);
      }
      if (f.status && f.status !== "睡眠" && f.status !== "冰冻" && f.statusLeft > 0 && --f.statusLeft === 0) {
        lines.push(`${name}的${f.status}状态解除了！`);
        f.status = undefined;
      }
      if (f.trapped > 0) f.trapped--;
      for (const x of f.timed) {
        if (x.left <= 0 || f.pet.hp <= 0) continue;
        if ((x.while && !this.has(f, x.while)) || (x.whileOther && !this.has(o, x.whileOther))) {
          x.left = 0;
          continue;
        }
        switch (x.kind) {
          case "regen":
            if (this.chance(x.chance ?? 100)) gain(f, x.n ?? (x.lost ? (max - f.pet.hp) * (x.f ?? 0) : max * (x.f ?? 0)), `${name}回复了体力！`);
            break;
          case "leech": {
            if (x.attr !== undefined && f.types.includes(x.attr)) break;
            const l = lose(f, x.n ?? max * (x.f ?? 0), `${name}被吸取了体力！`);
            if (o.pet.hp > 0) gain(o, l, `${petName(this.t, o)}回复了体力！`);
            break;
          }
          case "dot":
            if (this.chance(x.chance ?? 100)) lose(f, x.n ?? (x.a !== undefined ? this.int(x.a, x.b ?? x.a) : max * (x.f ?? 0)), `${name}受到了伤害！`);
            break;
          case "gamble":
            if (this.chance(x.chance ?? 50)) {
              const l = lose(f, x.a !== undefined ? this.int(x.a, x.b ?? x.a) : (x.n ?? 0), `${name}受到了伤害！`);
              if (x.a !== undefined && o.pet.hp > 0) gain(o, l / 2);
            } else if (x.self && o.pet.hp > 0) {
              if (x.self < 0) lose(o, -x.self, `${petName(this.t, o)}受到了伤害！`);
              else gain(o, x.self, `${petName(this.t, o)}回复了体力！`);
            }
            break;
          case "stagesEachTurn":
            if (this.chance(x.chance ?? 100) && x.stats) {
              let stats = x.stats;
              if (x.pick) {
                const pool = [...stats];
                stats = [];
                while (stats.length < x.pick && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
              }
              this.stage(f, x.delta && x.delta < 0 ? o : f, stats, x.delta ?? 0, lines);
            }
            break;
          case "pphp": {
            const with_ = f.pet.skills.filter((s) => s.pp > 0);
            if (with_.length && f.pet.hp < max) {
              for (const s of with_) s.pp--;
              gain(f, x.n ?? 0, `${name}用技能次数回复了体力！`);
            }
            break;
          }
          case "ppdrain":
            for (const s of f.pet.skills) s.pp = Math.max(0, s.pp - (x.n ?? 1));
            lines.push(`${name}的技能次数减少了！`);
            break;
          case "painsplit":
            if (o.pet.hp > f.pet.hp && this.chance(x.chance ?? 100)) {
              const avg = Math.floor((f.pet.hp + o.pet.hp) / 2);
              gain(f, Math.min(f.stats[0], avg) - f.pet.hp);
              lose(o, o.pet.hp - Math.min(o.stats[0], avg));
              lines.push("双方平分了体力！");
            }
            break;
          case "screen":
            if (x.flip) this.flip(x);
            break;
          case "punish":
            if (!f.turn.damaging) lose(f, x.n ?? 0, `${name}受到了伤害！`);
            break;
          case "plague":
            if (x.status && this.chance(x.chance ?? 0)) this.applyStatus(f, x.status, lines);
            break;
        }
      }
    }
    // Later-turn effects.
    for (const d of b.delayed ?? []) {
      if (d.left-- > 0) continue;
      const f = d.slot === b.mine.slot ? b.mine : b.wild;
      if (f.pet.hp <= 0) continue;
      const name = petName(this.t, f);
      if (d.kind === "healFull") gain(f, f.stats[0], `${name}回复了体力！`);
      else if (d.kind === "rebirth") {
        gain(f, f.stats[0], `${name}满状态回复了！`);
        for (const s of f.pet.skills) s.pp = s.max;
        this.cureAll(f);
        const o = this.other(b, f);
        if (o.pet.hp > 0) this.applyStatus(o, "害怕", lineOf.get(o)!);
      } else if (d.kind === "stages" && d.stats) this.stage(f, f, d.stats, d.delta ?? 0, lineOf.get(f)!);
      else if (d.kind === "badStatus") {
        if (this.chance(d.chance ?? 100)) this.applyStatus(f, BAD_STATUSES[Math.floor(this.rng() * BAD_STATUSES.length)], lineOf.get(f)!);
      }
      else if (d.kind === "heal") gain(f, d.n ?? 0, `${name}回复了体力！`);
      else if (d.kind === "sleep") this.applyStatus(f, "睡眠", lineOf.get(f)!);
      else if (d.kind === "flat") lose(f, d.n ?? 0, `${name}受到了伤害！`);
      else if (d.kind === "hpFrac") lose(f, f.pet.hp * (d.f ?? 0), `${name}受到了伤害！`);
      else if (d.kind === "maxFrac") lose(f, f.stats[0] * (d.f ?? 0), `${name}受到了伤害！`);
      else if (d.kind === "kill") lose(f, f.pet.hp, `${name}的时间被吞噬了！`);
      else if (d.kind === "hpTo1") lose(f, f.pet.hp - 1);
    }
    if (b.delayed) b.delayed = b.delayed.filter((d) => d.left >= 0);
    // Turns run out.
    for (const f of [b.mine, b.wild]) {
      for (const x of f.timed) {
        if (x.left > 0) x.left--;
        // A stage change that lasted its turns goes.
        if (x.left <= 0 && x.kind === "revert" && x.stats && x.deltas) {
          x.stats.forEach((k, i) => (f.stages[k] = clampStage(f.stages[k] - (x.deltas![i] ?? 0))));
          lineOf.get(f)!.push(`${petName(this.t, f)}的能力等级恢复了。`);
        }
      }
      f.timed = f.timed.filter((x) => x.left > 0);
    }
    if (b.field && --b.field.left <= 0) {
      b.field = undefined;
      lineOf.get(b.mine)!.push("场地的力量消失了。");
    }
    for (const f of [b.mine, b.wild]) {
      const lines = lineOf.get(f)!;
      // The heals shown whole, as in a skill's report.
      const inc = (lostOf.get(f) ?? 0) + this.overflow(f);
      if (!lines.length && !inc) continue;
      if (f.pet.hp <= 0) lines.push(`${petName(this.t, f)}倒下了！`);
      out.push(["2421", { slotId: f.slot, hpInc: inc, desc: lines.join("\n"), pmmList: this.views(b) }]);
    }
    return out;
  }

  /** Who goes first: priority (先发, 后发), then speed. */
  firstMover(b: Battle, mySkill: number, wildSkill: number): Fighter {
    const pri = (f: Fighter, id: number) => {
      const sk = this.skill(this.choice(f, id));
      const fx = parseEffects(sk.d);
      return sk.pri + (fx.first || (fx.chargeFirst && f.charging !== undefined) ? 1 : 0) - (fx.last ? 1 : 0);
    };
    const pm = pri(b.mine, mySkill), pw = pri(b.wild, wildSkill);
    if (pm !== pw) return pm > pw ? b.mine : b.wild;
    const sm = stat(b.mine, "spd"), sw = stat(b.wild, "spd");
    if (sm !== sw) return sm > sw ? b.mine : b.wild;
    return this.rng() < 0.5 ? b.mine : b.wild;
  }

  /** A whole turn in which the player uses a skill. */
  skillTurn(b: Battle, mySkill: number): Msg[] {
    this.startTurn(b);
    const wildSkill = this.wildChoice(b);
    const first = this.firstMover(b, mySkill, wildSkill);
    const second = first === b.mine ? b.wild : b.mine;
    // The one moving second: does it use a damaging skill (冷月寒霜)?
    const secondSkill = this.skill(this.choice(second, second === b.mine ? mySkill : wildSkill));
    second.turn.damaging = secondSkill.k !== 2 || !!parseEffects(secondSkill.d).dmg;
    const out: Msg[] = [this.act(b, first, second, first === b.mine ? mySkill : wildSkill)];
    if (first.pet.hp > 0 && second.pet.hp > 0) out.push(this.act(b, second, first, second === b.mine ? mySkill : wildSkill));
    return out;
  }

  /** The wild 亚比 alone acts (after an item, a failed catch or a switch). */
  wildTurn(b: Battle): Msg[] {
    this.startTurn(b);
    if (b.wild.pet.hp <= 0 || b.mine.pet.hp <= 0) return [];
    return [this.act(b, b.wild, b.mine, this.wildChoice(b))];
  }

  /** PlayerBattleInfo of both sides. */
  views(b: Battle, bag?: PetRecord[], owner?: PetOwner): Record<string, unknown>[] {
    return [this.view(b, 0, bag, owner), this.view(b, 1)];
  }

  bag?: PetRecord[];
  ownerRef?: PetOwner;

  view(b: Battle, slot: 0 | 1, bag = this.bag, owner = this.ownerRef): Record<string, unknown> {
    const f = slot === 0 ? b.mine : b.wild;
    const st = [f.status, f.confuse > 0 ? "混乱" : "", f.bind > 0 ? "束缚" : "", f.fear > 0 ? "害怕" : "", f.weak > 0 ? "衰弱" : "", f.seeded ? "寄生" : "", f.armour ? `护盾${f.armour}` : ""].filter(Boolean).join(",");
    const forced = this.forcedOf(f);
    const list = slot === 0 && bag ? [f.pet, ...bag.filter((p) => p !== f.pet)] : [f.pet];
    const own = { id: f.owner };
    return {
      battleView: {
        pmCanBattle: list.filter((p) => p.hp > 0).length,
        ...(slot === 0 && owner ? catchFields(owner) : { clv: 0, ccle: 0, "clu%": 0, cnx: 0 }),
        pmmId: f.owner,
        slotId: slot,
        pms: list.map((p) => p.id).join("#"),
        bag: slot === 0,
        locaId: slot,
        // Not a 2013 field: how my 亚比's attribute fares against the wild one's (the 强效 / 普通 / 弱效 row).
        ...(slot === 0 ? { mu: typeMultiplier(this.t.pm, b.mine.types[0], b.wild.types) } : {}),
        // Not a 2013 field: the skill it uses this turn by itself (蓄力, 连续攻击N回合): no choice is asked.
        ...(forced !== undefined ? { forced } : {}),
        pmList: list.map((p) => briefOf(p, own, this.t, p === f.pet ? { st, bal: balOf(f.stages) } : undefined)),
      },
    };
  }
}

// ---------------------------------------------------------------- rewards

export interface WinResult {
  msgs: Msg[];
  evolvedTo?: number;
}

/** Experience, effort points, levels, new skills and evolution for the 亚比 that won. */
export function award(t: PetTables, pet: PetRecord, wildRace: number, wildLevel: number, boost: { exp?: number; ev?: number } = {}): WinResult {
  const wsp = speciesOf(t, wildRace);
  const gained = expYield(wsp, wildLevel) * (boost.exp ?? 1);
  if (wsp) {
    pet.ev ??= [0, 0, 0, 0, 0, 0];
    const total = pet.ev.reduce((a, b) => a + b, 0);
    let room = Math.max(0, 510 - total);
    wsp.ev.forEach((y, i) => {
      const add = Math.min(y * (boost.ev ?? 1), room, 255 - pet.ev![i]);
      if (add > 0) {
        pet.ev![i] += add;
        room -= add;
      }
    });
  }
  return gainExp(t, pet, gained);
}

/** Experience for a 亚比: its levels, evolutions and new skills, with the replies that tell the client (2241, 2242, 2234). */
export function gainExp(t: PetTables, pet: PetRecord, gained: number): WinResult {
  const msgs: Msg[] = [];
  pet.exp += gained;
  let evolvedTo: number | undefined;
  const ups: Msg[] = [];
  while (pet.level < 100 && pet.exp >= expToNext(pet, t)) {
    pet.exp -= expToNext(pet, t);
    const before = statsOf(pet, t);
    pet.level++;
    const sp = speciesOf(t, pet.race);
    const next = sp && !pet.fixed ? evolutionAt(sp, pet.race, pet.level) : 0;
    if (next && speciesOf(t, next)) {
      pet.race = next;
      evolvedTo = next;
    }
    const after = statsOf(pet, t);
    pet.hp = Math.min(after[0], pet.hp + Math.max(0, after[0] - before[0]));
    ups.push([
      "2242",
      {
        id: pet.id,
        lv: pet.level,
        raceId: pet.race,
        evolve: next || 0,
        abilityChange: {
          pmId: pet.id,
          oldHP: before[0], oldAtt: before[1], oldDef: before[2], oldSAtt: before[3], oldSDef: before[4], oldSpd: before[5],
          newHP: after[0], newAtt: after[1], newDef: after[2], newSAtt: after[3], newSDef: after[4], newSpd: after[5],
        },
      },
    ]);
    const learnt = speciesOf(t, pet.race) ? skillsLearntAt(speciesOf(t, pet.race)!, pet.level) : [];
    for (const id of learnt) {
      pet.learned ??= pet.skills.map((s) => s.id);
      if (pet.learned.includes(id)) continue;
      pet.learned.push(id);
      const carried = pet.skills.length < 4;
      if (carried) pet.skills.push(skillOf(t, id));
      ups.push(["2234", { id: pet.id, skillId: id, name: skillOf(t, id).name, used: carried }]);
    }
  }
  msgs.push(["2241", { id: pet.id, exp: gained, lv: pet.level, curExp: pet.exp, nx: Math.max(0, expToNext(pet, t) - pet.exp) }], ...ups);
  return { msgs, evolvedTo };
}

// ---------------------------------------------------------------- catching

/** Balls (ItemData type 6) and recovery items (type 5) of the 2013 item table. */
export const BALLS: Record<number, number> = { 32: 0.5, 67: 0.7, 68: 0.9, 64: 1 };
export const POTIONS: Record<number, number> = { 30: 40, 60: 100, 61: 200, 102: 300, 263: 400, 390: 200 };
export const PP_BEANS: Record<number, number> = { 31: 5, 103: 10, 104: 20, 391: 20 };
/** 解除…药剂 (94–99) and 净化药剂 (100, 101): the status each takes away ("all" for the 净化药剂). */
export const CURES: Record<number, StatusName | "寄生" | "all"> = { 94: "睡眠", 95: "混乱", 96: "寄生", 97: "烧伤", 98: "冰冻", 99: "中毒", 100: "all", 101: "all" };
/** "当亚比剩下极少体力时，可用于捕捉野外亚比": a ball works once the wild 亚比 is down to a fifth. */
export const CATCH_HP = 0.2;

/**
 * How much of its HP a wild 亚比 may still have for an ordinary ball to work:
 * a fifth for most, more for the easy ones (捕获度 under 7), any HP for the
 * 捕获度 0 朵朵兔, of which the 2011 walkthrough says "朵朵兔很容易捕捉，扔扔亚比球
 * 就可以". RECONSTRUCTED.
 */
export function catchHpLimit(t: PetTables, race: number): number {
  const c = Number(speciesOf(t, race)?.c[0]);
  return Number.isFinite(c) ? Math.max(CATCH_HP, 1 - c / 8) : CATCH_HP;
}

/** 捕捉难度 stars (1–5) from the species' 捕获度. */
export function catchStars(c: string): number {
  const n = Number(c);
  return Number.isFinite(n) ? Math.max(1, Math.min(5, 1 + Math.floor(n / 8))) : 5;
}

export function catchChance(t: PetTables, wild: Fighter, ball: number, clv: number): number {
  const base = BALLS[ball] ?? 0;
  if (base >= 1) return 1;
  if (wild.pet.hp > wild.stats[0] * catchHpLimit(t, wild.pet.race)) return 0;
  const c = Number(speciesOf(t, wild.pet.race)?.c[0]);
  const lf = Number.isFinite(c) ? Math.max(0.2, Math.min(1, 1 - Math.max(0, c - clv) * 0.05)) : 0;
  const st = wild.status === "睡眠" || wild.status === "冰冻" ? 0.1 : wild.status ? 0.05 : 0;
  return Math.min(1, (base + st) * lf);
}

// ---------------------------------------------------------------- wiring

export interface WildEntry {
  raceId: number;
  min: number;
  max: number;
  common: number;
  rate: number;
}

export interface BattleDeps {
  load: (ctx: XtContext) => Promise<PetOwner & { items?: Record<string, Record<string, number>> }>;
  /** Another player's record (亚比对战). */
  find?: (name: string) => Promise<(PetOwner & { items?: Record<string, Record<string, number>> }) | undefined>;
  save: (owner: PetOwner) => Promise<void>;
  tables: () => Promise<PetTables>;
  wild: () => Promise<Record<string, WildEntry[]>>;
  today: () => string;
  rng?: Rng;
  /** The game clock (task steps a win finishes are dated by it). */
  now?: () => number;
}

const PM = "PocketMonsterExtension";

/** PetFightTypes.FIGHT_IN_NPCCHALLENGE. */
const FIGHT_IN_NPCCHALLENGE = 14;
/**
 * The 守护者 of BossTimeHelper.bossTimeConfig (2013 interfaces): each scene's boss forms as
 * "race,race" (one after another; "#" a pair) with their levels; a form's index counts across
 * the pair as the rebuilt dailyactivity does.
 */
export const GUARDIANS: [string, string][] = [
  ["10317,20317", "80,100"], ["20087", "80"], ["20427", "60"], ["10090,20090", "60,80"], ["10093,20093", "60,80"],
  ["20418", "100"], ["10099,20099", "60,80"], ["10102,10102,20102", "60,80,100"], ["10096,10096,20096", "60,80,100"],
  ["10108,10108,20108", "60,80,100"], ["10469#10472", "100#100"], ["10475#20475", "100#100"], ["30682,10682", "88,100"],
  ["10715,20715", "80,100"], ["14523#11514#11516", "100#80#80"], ["10757,20757", "80,100"], ["10840,20840", "80,100"],
  ["10865,20865", "80,100"], ["11213,21213,31213", "60,80,100"],
  // Bosses of the 2013 world beside that table (the rebuilt dailyactivity): 伊泽 and 迦娜 (mysticocean5),
  // 烈焰鸟 (feier4), 神武月 and 战无炎 (choicetemple); their levels are RECONSTRUCTED. 神武月 is its
  // "一次机会" partner fight (10105, boss10105); the 满月 神武月 (20105, the later StartBoss of 哈米乐园)
  // is not in the 2013 world.
  ["11320,11322", "100,100"], ["30278", "80"], ["10105", "80"], ["10111", "90"],
  // The bosses of the 2011–12 events (dailyactivity, rows added in the revival; levels RECONSTRUCTED
  // but 天女若希's second form, Lv100 in the later BossTimeHelper).
  ["11259", "100"], ["10884", "100"], ["10639", "100"], ["10493", "100"], ["10112,20112", "80,100"], ["10195,20195", "80,100"],
  ["10633", "100"], ["10665", "100"], ["10796,20796", "80,100"], ["10771,20771", "80,100"], ["11190", "100"], ["10819,20819", "80,100"],
  ["10995", "100"],
  // 蓝羽灵者 (迷境花园, January 2013): three forms fought from its panel (RECONSTRUCTED levels).
  ["31394,21394,11394", "60,80,100"],
];

/** The 亚比 whose skill film the game has (petlearning/petlearning<race>: 艾尔利克 192 and 230). */
const FILM_RACES = new Set([192, 230]);

/** The boss forms of GUARDIANS: what 54_16 fights (any other id is no 守护者). */
const GUARDIAN_RACES = new Set(GUARDIANS.flatMap(([races]) => races.split(/[#,]/).map(Number)));
export const isGuardian = (race: number): boolean => GUARDIAN_RACES.has(race);

/**
 * Boss ids whose species is not id % 10000 (PetAssetsMap: 时间之神 10112 / 20112 are 114, not 112 小时).
 */
const BOSS_SPECIES: Record<number, number> = { 10112: 114, 20112: 114 };

/**
 * A boss's 亚比蛋 where its own line has none: 终极麦斗王's team (14523, then 猪阿饼 11514 and 猪阿酱
 * 11516, fought one after another) gives the 麦斗猪蛋 (520, the line of 麦斗队长 and 麦斗司令) when
 * its last 亚比 is beaten (RECONSTRUCTED: 麦斗王 523 himself is 无法获得; the 图鉴 names 斗魂空间 as
 * where the 麦斗 line is got). 0: no egg for that form (蓝羽灵者's first two; its last gives the 小羽灵蛋).
 */
export const BOSS_EGGS: Record<number, number> = { 11516: 520, 31394: 0, 21394: 0, 11394: 1393 };

/**
 * Bosses whose 亚比蛋 comes only with the first win of their last form, as their panels say: 蓝羽灵者
 * (“首次战胜就可以获得它哦”, the 小羽灵蛋 1393), 友人契约书 (“首次战胜友人契约书就可以获得亚比蛋”) and
 * 岩波斗魂者 (“首次战胜岩波斗魂者就可以获得亚比蛋”); their marks are then in 54_19's list.
 */
const FIRST_WIN_ONLY = new Set([11394, 11259, 31213]);

/**
 * Bosses' marks in 54_19's list once beaten: 友人契约书's panel shows the egg as got when "1257" is in
 * it, 岩波斗魂者's (dailyactivity/stonebosspanel) when "1211" (its egg) is, after its last form, 31213.
 */
const BOSS_MARKS: Record<number, number> = { 11259: 1257, 31213: 1211, 11394: 1393 };

/**
 * A 守护者 form's level (its race at that index), else that race's level wherever its row has it (the
 * rebuilt dailyactivity fights each of a "#" pair as a boss of its own, at index 0: 魂斗鱼 10472 and the
 * second 浮云尊者 20475 fought at Lv20), else 20 + 5 per index as before.
 */
export function guardianLevel(race: number, index: number): number {
  let anywhere = 0;
  for (const [races, levels] of GUARDIANS) {
    const rs = races.split(/[#,]/).map(Number);
    const ls = levels.split(/[#,]/).map(Number);
    if (rs[index] === race) return ls[index] ?? ls[0];
    const at = rs.indexOf(race);
    if (at >= 0 && !anywhere) anywhere = ls[at] ?? ls[0];
  }
  return anywhere || Math.min(100, 20 + 5 * index);
}

/**
 * Is this form the last of its boss (the end of its "," chain; each of a "#" pair is a boss of its
 * own)? Only beating the last form brings the boss's 亚比蛋 (RECONSTRUCTED: an egg for every form won
 * gave 岩波斗魂者's three a run, 沙麒麟's two). Not a 守护者 of the table: true.
 */
export function lastGuardianForm(race: number, index: number): boolean {
  for (const [races] of GUARDIANS) {
    for (const pair of races.split("#")) {
      const chain = pair.split(",").map(Number);
      const at = chain[index] === race ? index : chain.lastIndexOf(race);
      if (at >= 0) return at === chain.length - 1;
    }
  }
  return true;
}

/** The 亚比蛋 of the 2013 PetEggData (materials type 5): egg N hatches race N, the first form of a line. */
export const EGG_IDS = new Set([
  13, 37, 64, 73, 79, 82, 85, 88, 91, 94, 97, 100, 103, 106, 109, 112, 127, 130, 178, 193, 253, 265, 267, 276, 282, 285, 297, 315,
  337, 392, 409, 416, 425, 467, 470, 473, 482, 488, 515, 520, 602, 637, 663, 680, 705, 713, 755, 770, 786, 817, 839, 856, 858, 864,
  873, 890, 947, 1143, 1160, 1184, 1188, 1211, 1226, 1237, 1239, 1256, 1258, 1260, 1264, 1266, 1275, 1277, 1292, 1311, 1319, 1321,
  1337, 1340, 1393,
]);

/** The egg of a species' evolution line (its first form, when PetEggData has that egg), else 0. */
export function eggOfLine(t: { species: Record<string, { next?: number }> }, race: number): number {
  const prev = new Map<number, number>();
  for (const [id, sp] of Object.entries(t.species)) if (sp.next) prev.set(sp.next, Number(id));
  let r = race;
  for (let i = 0; i < 6 && !EGG_IDS.has(r) && prev.has(r); i++) r = prev.get(r)!;
  return EGG_IDS.has(r) ? r : 0;
}

/** PetFightTypes.FIGHT_IN_MEMBER_ARENA: the bosses of 黑星堡垒. */
export const FIGHT_IN_MEMBER_ARENA = 12;
/** 黑星堡垒's bosses' levels by room: floor 1 (viparena2, 3), 2 (5, 6), 3 (7) (RECONSTRUCTED). */
export const MEMBER_ARENA_LEVELS: Record<string, number> = { viparena2: 50, viparena3: 50, viparena5: 65, viparena6: 65, viparena7: 80 };
/** The NPC's 亚比 per mode (新手训练, 小试身手, 勇士挑战). RECONSTRUCTED. */
const NPC_LEVELS = [8, 18, 30];
/**
 * First stage of each challenge NPC's line (ChallengeConfig of the era
 * npcchallengeservice: 13 维克, 35 芭芭拉, 145 骑士团卫兵, 14 普伦博士, 3 米娜,
 * 26 哈德, 142 亨特, 32 安娜, 31 依依, 172 马赫, 312 上古使者). RECONSTRUCTED.
 */
const NPC_TEAM_BASE: Record<number, number> = { 13: 61, 35: 10, 145: 43, 14: 1, 3: 34, 26: 70, 142: 19, 32: 10, 31: 1, 172: 97, 312: 70 };

export interface NpcChallengeRecord {
  /** NPC id -> hardest mode won; NPC id -> the day its 欢乐弹珠 was given. */
  npcChallenge?: { won: Record<number, number>; gift: Record<number, string> };
}

/** The fight of newbie step 138 (taskext/task135 starts it against 达达, race 322). */
function tutorial(o: object, race: number): boolean {
  const tasks = (o as { tasks?: Record<string, { st: number }> }).tasks;
  return race === 322 && tasks?.["138"]?.st === 0;
}
const WEAK = "你的亚比很虚弱了，快去治疗它吧！\n点击亚比背包内的亚比恢复就可以治疗它哦！";

export function installBattles(world: World, deps: BattleDeps): void {
  const battles = new Map<number, Battle>();
  registerFights(world, battles);
  let nextBattle = 1;
  const send = (ctx: XtContext, msgs: Msg[]) => {
    for (const [cmd, body] of msgs) ctx.reply(body, cmd);
  };
  // 亚比对战 between players (duel.ts).
  const duels = installDuels(world, {
    battles,
    load: deps.load,
    find: async (name) => deps.find?.(name),
    tables: deps.tables,
    rng: deps.rng,
    nextId: () => nextBattle++,
  });

  // Wild 亚比 of the room.
  world.xt("PetExtension.54_7", async (ctx) => {
    const room = sceneOfRoom(ctx.player.room);
    // auto (not of 2013): battles left of a 自动战斗仪 (petitems.ts); the wild 亚比 module then
    // goes for the wild 亚比 of the room by itself.
    const auto = ((await deps.load(ctx)) as PetItemOwner).boosts?.auto ?? 0;
    ctx.reply({ pms: (await deps.wild())[room] ?? [], ...(auto ? { auto } : {}) });
  });

  const begin = async (
    ctx: XtContext,
    race: number,
    level: number,
    catchable: boolean,
    onWin?: Battle["onWin"],
    asked?: number,
    onLose?: Battle["onLose"],
    copyId?: number,
    /** 沙盒: the opponent's stats multiplied, and no award for the win. */
    sandbox?: { mul: number[] },
    /** The battle made, before it is sent (the 道馆: 幻冥's 命运 on the player's 亚比). */
    adjust?: (b: Battle) => void,
  ): Promise<boolean> => {
    const o = await deps.load(ctx);
    const t = await deps.tables();
    for (const p of o.pets ?? []) normalisePet(p, t);
    const old = battles.get(o.id);
    // A refused start: told in a 2303 with msg alone; false to the caller.
    const refuse = (msg: string) => (ctx.reply({ msg }, "2303"), false);
    if (old && !old.over) return refuse("你不能够在离开一个战场之前，加入另外一个战场！");
    const active = (o.pets ?? []).find((p) => p.hp > 0);
    if (!active) return refuse(WEAK);
    if (!speciesOf(t, race)) return refuse("这只亚比还不能对战哦！");
    const lesson = tutorial(o, race);
    const wildPet = makePet(t, race, lesson ? Math.min(level, 2) : level, deps.today());
    if (sandbox) {
      wildPet.mul = sandbox.mul;
      wildPet.hp = statsOf(wildPet, t)[0];
    }
    if (lesson) {
      // The newbie fight (task step 138) is a lesson, not a trial: the
      // 达斯特's 达达 is at most Lv2 and only attacks. RECONSTRUCTED; the
      // 2013 rule is lost.
      const hits = wildPet.skills.filter((s) => (t.pm.skills[String(s.id)]?.k ?? 0) !== 2);
      if (hits.length) wildPet.skills = hits;
    }
    const engine = new BattleEngine(t, deps.rng);
    const canCatch = catchable && Number.isFinite(Number(speciesOf(t, race)!.c[0]));
    const b = engine.start(nextBattle++, sceneOfRoom(ctx.player.room), o, active, wildPet, canCatch);
    b.onWin = onWin;
    b.onLose = onLose;
    b.asked = asked;
    b.copyId = copyId;
    b.noAward = !!sandbox;
    adjust?.(b);
    // 自动战斗仪 (44, petitems.ts): "开启后，在场景中会自动与野外怪对战。每个可使用100次": a wild
    // battle while it lasts is fought by the battle screen itself (auto), one use each.
    const boosts = (o as PetItemOwner).boosts;
    // (A wild 亚比 of the room: the one battle that may be caught.)
    const auto = !!boosts?.auto && catchable && !copyId && !sandbox;
    if (auto && boosts) {
      boosts.auto = (boosts.auto ?? 0) - 1;
      if (boosts.auto <= 0) delete boosts.auto;
      await deps.save(o);
    }
    battles.set(o.id, b);
    engine.bag = o.pets;
    engine.ownerRef = o;
    send(ctx, [
      // chp (not in the 2013 reply): the HP fraction from which balls work, for the 捕捉难度 hint.
      ["2303", { esc: true, sw: true, ch: canCatch, cd: catchStars(speciesOf(t, race)!.c[0]), chp: catchHpLimit(t, race), pmmList: engine.views(b) }],
      // boss: the opponent's id as the fight was asked for (variant * 10000 + species for the
      // bosses), by which the battle screen finds the boss's films (bossfightmovie/boss<id>).
      ["2401", { id: b.id, type: 0, pt: 0, bs: "", srt: 0, scene: b.room, boss: asked ?? race, ...(auto ? { auto: true, autoLeft: boosts?.auto ?? 0 } : {}) }],
    ]);
    // The 图鉴 (petdic.ts): the species met (not the 沙盒's).
    if (!sandbox && markDic(o, t, race, MET)) {
      await deps.save(o);
      send(ctx, [NEW_RECORD]);
    }
    return true;
  };

  // startPKWithRobot {raceId, level, sw, id}: a wild 亚比 of the room at one of its levels; tasks pass a level.
  // A story quest's 亚比 (IPetFight.fightWithTaskPet) is numbered variant * 10000 + species
  // (10322: 达达; 10869, 20869, 30869: three fights with the 通灵巫师). The 2013 server's task
  // 亚比 are lost: RECONSTRUCTED as the species at the level of the player's strongest 亚比 (at
  // least 5), two levels more for each further variant, not to be caught. A win counts for the
  // steps that ask for it (TaskDefine type 101, tasks.ts stepsByPetWin).
  // Task 亚比 asked by plain species (taskext/task1411's 艾尔利克 230; 盘龙池's 龙族大法师 305, whom
  // scene/temple12 fights by fightWithTaskPet(305): with no wild level it was a Lv5): fought as the
  // others, not caught.
  const TASK_PET_RACES = new Set([230, 305]);
  world.xt("PetExtension.54_2", async (ctx) => {
    const asked = Number(ctx.params.level);
    const id = Number(ctx.params.raceId);
    const onWin: Battle["onWin"] = (o) =>
      stepsByPetWin(o as TaskOwner, id, deps.now?.() ?? Date.now()).changes.map((c): Msg => ["10-1", { t: c.t, ty: c.ty }]);
    if (id >= 10000 || TASK_PET_RACES.has(id)) {
      const o = await deps.load(ctx);
      const top = Math.max(5, ...(o.pets ?? []).map((p) => p.level));
      const level = asked > 0 ? asked : top + 2 * (Math.floor(id / 10000) - 1);
      return void (await begin(ctx, id % 10000, Math.max(1, Math.min(100, level)), false, onWin, id));
    }
    // A wild 亚比 of this room: at the room's levels (the client's level is not taken), and
    // catchable. Any other species (a scene's or quest's fightWithPetByRaceId, at its level) is
    // fought but not caught: a client not the 2013 one could otherwise ask for any species at
    // Lv1 and catch it.
    const entry = ((await deps.wild())[sceneOfRoom(ctx.player.room)] ?? []).find((w) => w.raceId === id);
    const rng = deps.rng ?? Math.random;
    const level = entry ? entry.min + Math.floor(rng() * (entry.max - entry.min + 1)) : asked > 0 ? asked : 5;
    // The items some rooms' wild 亚比 drop for the planets' activities (planetacts.ts WILD_DROPS).
    const room = sceneOfRoom(ctx.player.room);
    await begin(ctx, id, Math.max(1, Math.min(100, level)), !!entry, (o) => [...onWin(o), ...(entry ? wildDrop(o as ActsOwner, room, id) : [])]);
  });

  // NPC challenge (the era npcchallenge/npcchallengeservice, PetFightTypes.FIGHT_IN_NPCCHALLENGE 14):
  //   54_22 {type: 14, npc, lv, npcId, name} -> 54_22 {res, canGet, canGet1}, then the fight as above.
  // res false when a harder mode is asked before the easier ones are won (the client then shows
  // npcChallenge_fail_<lv>); canGet: a win today brings one 欢乐弹珠 (item 343, "今天我身上的弹弹珠
  // 已经发完啦" once given). The 2013 server and the NPCs' teams are lost: each NPC fights with one
  // 亚比 of an evolution line, the next stage for each harder mode, at NPC_LEVELS (RECONSTRUCTED).
  // The 道馆 (gyms.ts): 踢馆 84 / 86 / 87 / 88 (幻冥 with its 命运), 命运玩偶's 亚比 (88 with a raceId),
  // 雷霆之塔's floors (85, the rebuilt timerFight). Not to be caught; 54_22 {res} first, as for the NPCs.
  const gymFight = async (ctx: XtContext, type: number) => {
    const refuse = (msg: string) => {
      ctx.reply({ res: false });
      ctx.reply({ msg }, "2303");
    };
    if (type === GYM_TOWER) {
      const layer = Number(ctx.params.layer) | 0;
      const run = gymOf(await deps.load(ctx)).tower;
      const floor = THUNDER_FLOORS[layer - 1];
      if (!run || !floor || layer !== run.floor + 1) return refuse("请先开启雷霆之塔的挑战！");
      ctx.reply({ res: true });
      return void (await begin(ctx, floor.race, floor.level, false, (o) => towerFloorWon(o, layer, deps.now?.() ?? Date.now())));
    }
    if (type === GYM_DARK && Number(ctx.params.raceId) > 0) {
      const raceId = Number(ctx.params.raceId) | 0;
      ctx.reply({ res: true });
      return void (await begin(ctx, raceId % 10000, dollLevel(raceId), false, undefined, raceId));
    }
    const master = GYM_MASTERS[type];
    if (!master) return refuse(type === GYM_LIGHT ? "友情的试炼需要好友的亚比一起参加哦！" : "这个挑战现在还不能进行哦！");
    const o = await deps.load(ctx);
    // 幻冥's 命运 (Dark_7) holds for this 踢馆 only.
    const fate = type === GYM_DARK ? gymOf(o).fate : undefined;
    if (fate) {
      delete gymOf(o).fate;
      await deps.save(o);
    }
    ctx.reply({ res: true });
    await begin(
      ctx,
      master.race,
      master.level,
      false,
      (owner) => {
        const b = battles.get(owner.id);
        gymWon(owner, type, b?.mine.pet.race ?? 0);
        return [];
      },
      undefined,
      undefined,
      undefined,
      undefined,
      fate ? (b) => {
        const st = applyFate(b.mine.stats, fate);
        b.mine.pet.hp = Math.min(st[0], Math.round((b.mine.pet.hp * st[0]) / Math.max(1, b.mine.stats[0])));
        b.mine.stats = st;
      } : undefined,
    );
  };

  world.xt("PetExtension.54_22", async (ctx) => {
    if (Number(ctx.params.type) === FIGHT_IN_MEMBER_ARENA) {
      // 黑星堡垒 (viparena, PetFightTypes.FIGHT_IN_MEMBER_ARENA 12): {mi, rm}, a floor's boss
      // numbered 70000 + species (70536 震天石魔 in viparena2). Its level by the room's floor,
      // not to be caught (RECONSTRUCTED: the 2013 server's bosses are lost).
      const mi = Number(ctx.params.mi) | 0;
      const level = MEMBER_ARENA_LEVELS[String(ctx.params.rm ?? "")] ?? 60;
      return void (await begin(ctx, mi % 10000, level, false, undefined, mi));
    }
    const type = Number(ctx.params.type);
    if (type >= GYM_THUNDER && type <= GYM_LIGHT) return gymFight(ctx, type);
    if (type !== FIGHT_IN_NPCCHALLENGE) {
      // A kind of fight not played here: the panel is told (2303 with msg: PetFightEvent.ENTER_FIGHT_FAIL),
      // else its FIGHT_END listener stayed and answered the next battle as its own.
      ctx.reply({ res: false });
      return ctx.reply({ msg: "这个挑战现在还不能进行哦！" }, "2303");
    }
    const npcId = Number(ctx.params.npcId) | 0;
    // The NPCs that challenge (their gifts are counted by NPC: a made-up one would be one more).
    if (NPC_TEAM_BASE[npcId] === undefined) {
      ctx.reply({ res: false, canGet: false, canGet1: false });
      return ctx.reply({ msg: "这个挑战现在还不能进行哦！" }, "2303");
    }
    const lv = Math.max(1, Math.min(3, Number(ctx.params.lv) | 0));
    const o = (await deps.load(ctx)) as PetOwner & NpcChallengeRecord;
    const t = await deps.tables();
    const rec = (o.npcChallenge ??= { won: {}, gift: {} });
    if (lv > (rec.won[npcId] ?? 0) + 1) return ctx.reply({ res: false, canGet: false, canGet1: false });
    const day = deps.today();
    const canGet = rec.gift[npcId] !== day;
    let race = NPC_TEAM_BASE[npcId];
    for (let i = 1; i < lv; i++) {
      const next = (t.species[String(race)] as { next?: number } | undefined)?.next;
      if (next && speciesOf(t, next)) race = next;
    }
    ctx.reply({ res: true, canGet, canGet1: canGet });
    await begin(ctx, race, NPC_LEVELS[lv - 1], false, (owner) => {
      const r = ((owner as PetOwner & NpcChallengeRecord).npcChallenge ??= { won: {}, gift: {} });
      r.won[npcId] = Math.max(r.won[npcId] ?? 0, lv);
      if (r.gift[npcId] === day) return [];
      r.gift[npcId] = day;
      const items = (((owner as { items?: Record<string, Record<string, number>> }).items ??= {})["2"] ??= {});
      // 上古使者 hands out 上古圣水 (379: npcChallenge_noItem_312 “今天我身上的上古圣水已经发完啦”), the others 欢乐弹珠.
      const gift = npcId === 312 ? 379 : 343;
      items[String(gift)] = (items[String(gift)] ?? 0) + 1;
      return [["onAmountUpdated", { amount: `2_${gift}_0_1` }]];
    });
  });

  // 时空隧道 (spacetime/spacetimeservice, the later service on the 2013 interfaces; TowerExtension,
  // the 2013 SpacetimeClient; the team tunnel's TeamTowerExtension "_t" commands get the same answers):
  //   56_1 getUserFloorInfo {}   -> {mf, cf, mtf, ctf}          floors reached, floor now (alone, in a team)
  //   56_2 goToFloor {fl}         -> {ca, en: [{raceId: "id"}], cf} a floor already reached
  //   56_6 continueFloor {}       -> the same, the floor now
  //   56_3 nextFloor {}           -> {result (1, -2 the last floor), ca, en, cf}  through the opened door
  //   56_5 startPK {enId}         -> {enId}, then the battle with that group of the floor
  //   56_7 (after a win)          -> {bonus: [{id: -1, type: 100 (晶币), num}]}, shown when the battle ends
  //   56_10 (after a loss)        -> {}: out of the tunnel (the service goes back to the room before)
  //   56_11 checkCanGetCase {}    -> {res}; 56_4 openCase {} -> {res, bonus}: the BOSS厅's chest
  // ca: the floor is a BOSS厅 (every tenth). The 2013 server's floors are lost: RECONSTRUCTED as up to
  // four single 亚比 a floor from those the tunnel's pictures show (spacetime/spacetimepet<n>), at
  // level 5 + 2 * floor (at most 100), one stronger 亚比 in a BOSS厅; TOWER_FLOORS floors.
  const TOWER_FLOORS = 100;
  type TowerRec = { mf: number; cf: number; en: string[]; alive: boolean[]; chest: boolean };
  const towerOf = (o: PetOwner): TowerRec => (((o as { tower?: TowerRec }).tower ??= { mf: 1, cf: 1, en: [], alive: [], chest: false }));
  const TOWER_POOL = [
    2, 3, 5, 6, 8, 9, 102, 105, 108, 201, 203, 204, 207, 208, 301, 302, 303, 304, 305, 408, 503, 504, 509, 601, 608, 701, 704,
    11, 12, 14, 15, 16, 17, 18, 111, 114, 218, 219, 317, 411, 414, 418, 512, 514, 516, 612, 615, 618, 619, 710, 711, 715,
    20, 21, 23, 24, 27, 29, 123, 126, 129, 220, 221, 222, 223, 224, 225, 227, 322, 325, 328, 329, 424, 427, 522, 526, 620, 621, 622,
    30, 31, 32, 33, 35, 36, 39, 132, 135, 138, 230, 232, 233, 238, 339, 430, 433, 436, 439, 533, 633, 639,
    41, 42, 44, 45, 47, 48, 141, 144, 147, 240, 241, 242, 243, 249, 340, 343, 346, 349, 442, 445, 542, 545, 548, 641, 643, 644,
    51, 54, 57, 59, 150, 153, 155, 156, 158, 159, 255, 258, 355, 358, 457, 551, 554, 557, 650, 653, 654, 655, 656,
    60, 62, 63, 66, 67, 68, 69, 162, 165, 168, 261, 265, 266, 267, 268, 364, 366, 367, 368, 460, 463, 469, 566, 569, 662, 665,
    71, 72, 75, 78, 171, 174, 177, 271, 278, 370, 371, 372, 373, 374, 375, 472, 475, 571, 574, 577, 672, 673, 678,
    81, 84, 87, 180, 183, 185, 189, 284, 287, 382, 383, 484, 487, 580, 583, 682,
    90, 93, 96, 99, 192, 195, 198, 293, 296, 299, 393, 394, 397, 398, 493, 499, 598, 697, 699,
  ];
  const isBossFloor = (f: number) => f % 10 === 0;
  const towerLevel = (f: number) => Math.min(100, 5 + 2 * f + (isBossFloor(f) ? 5 : 0));
  const towerFloor = async (o: PetOwner, f: number) => {
    const t = await deps.tables();
    const pool = TOWER_POOL.filter((r) => speciesOf(t, r));
    const rng = deps.rng ?? Math.random;
    const n = isBossFloor(f) ? 1 : 2 + Math.floor(rng() * 3);
    const rec = towerOf(o);
    rec.cf = f;
    rec.mf = Math.max(rec.mf, f);
    const forced = (rec as { force?: string[] }).force;
    rec.en = forced?.length ? forced : Array.from({ length: n }, () => String(pool[Math.floor(rng() * pool.length)]));
    delete (rec as { force?: string[] }).force;
    rec.alive = rec.en.map(() => true);
    rec.chest = false;
  };
  const floorReply = (rec: TowerRec) => ({ ca: isBossFloor(rec.cf), en: rec.en.map((r, i) => ({ raceId: rec.alive[i] ? r : "-1" })), cf: rec.cf });
  for (const [ext, sfx] of [["TowerExtension", ""], ["TeamTowerExtension", "_t"]] as const) {
    world.xt(`${ext}.56_1${sfx}`, async (ctx) => {
      const rec = towerOf(await deps.load(ctx));
      ctx.reply({ mf: rec.mf, cf: rec.cf, mtf: rec.mf, ctf: rec.cf }, `56_1${sfx}`);
    });
    world.xt(`${ext}.56_2${sfx}`, async (ctx) => {
      const o = await deps.load(ctx);
      const rec = towerOf(o);
      // Not to another floor in the middle of a fight (its win would count there).
      if (battles.has(o.id)) return ctx.reply(floorReply(rec), `56_2${sfx}`);
      const fl = Math.max(1, Math.min(rec.mf, Number(ctx.params.fl ?? ctx.params.floor ?? rec.cf) | 0 || rec.cf));
      await towerFloor(o, fl);
      await deps.save(o);
      ctx.reply(floorReply(rec), `56_2${sfx}`);
    });
    world.xt(`${ext}.56_6${sfx}`, async (ctx) => {
      const o = await deps.load(ctx);
      const rec = towerOf(o);
      if (!rec.en.length || !rec.alive.some(Boolean)) await towerFloor(o, rec.cf);
      await deps.save(o);
      ctx.reply(floorReply(rec), `56_6${sfx}`);
    });
    world.xt(`${ext}.56_3${sfx}`, async (ctx) => {
      const o = await deps.load(ctx);
      const rec = towerOf(o);
      if (rec.alive.some(Boolean) || battles.has(o.id)) return ctx.reply({ result: 0 }, `56_3${sfx}`);
      if (rec.cf >= TOWER_FLOORS) return ctx.reply({ result: -2 }, `56_3${sfx}`);
      await towerFloor(o, rec.cf + 1);
      await deps.save(o);
      ctx.reply({ result: 1, ...floorReply(rec) }, `56_3${sfx}`);
    });
    world.xt(`${ext}.56_5${sfx}`, async (ctx) => {
      const o = await deps.load(ctx);
      const rec = towerOf(o);
      const i = Number(ctx.params.enId) | 0;
      const race = Number(rec.en[i]);
      if (!race || !rec.alive[i]) return ctx.reply({ enId: -1 }, `56_5${sfx}`);
      ctx.reply({ enId: i }, `56_5${sfx}`);
      const f = rec.cf;
      await begin(ctx, race, towerLevel(f), false, (owner) => {
        const r = towerOf(owner);
        if (r.cf === f) r.alive[i] = false;
        const coins = 10 + 2 * f;
        (owner as { score?: number }).score = ((owner as { score?: number }).score ?? 0) + coins;
        return [
          [`56_7${sfx}`, { bonus: [{ id: -1, type: 100, num: coins }] }],
          ["onScoreUpdated", { score: (owner as { score?: number }).score }],
        ];
      }, undefined, () => [[`56_10${sfx}`, {}]]);
    });
    world.xt(`${ext}.56_10${sfx}`, async (ctx) => ctx.reply({}, `56_10${sfx}`));
    // For testing (the probes): the 亚比 of the next floor made, "393,111".
    world.xt(`${ext}.revival_tower${sfx}`, async (ctx) => {
      const o = await deps.load(ctx);
      (towerOf(o) as { force?: string[] }).force = String(ctx.params.en ?? "").split(",").filter(Boolean);
      await deps.save(o);
      ctx.reply({ ok: true }, `revival_tower${sfx}`);
    });
    world.xt(`${ext}.56_11${sfx}`, async (ctx) => {
      const rec = towerOf(await deps.load(ctx));
      ctx.reply({ res: isBossFloor(rec.cf) && !rec.alive.some(Boolean) && !rec.chest ? 1 : 0 }, `56_11${sfx}`);
    });
    world.xt(`${ext}.56_4${sfx}`, async (ctx) => {
      const o = await deps.load(ctx);
      const rec = towerOf(o);
      if (!isBossFloor(rec.cf) || rec.alive.some(Boolean) || rec.chest) return ctx.reply({ res: 0, bonus: [] }, `56_4${sfx}`);
      rec.chest = true;
      const items = ((o as { items?: Record<string, Record<string, number>> }).items ??= {});
      const bag = (items["2"] ??= {});
      const id = rec.cf >= 50 ? 61 : 60; // 高级 / 中级体力糖
      bag[String(id)] = (bag[String(id)] ?? 0) + 2;
      await deps.save(o);
      ctx.reply({ amount: `2_${id}_0_2` }, "onAmountUpdated");
      ctx.reply({ res: 1, bonus: [{ type: 2, id, num: 2 }] }, `56_4${sfx}`);
    });
  }

  // 四大副本 (fb.ts): FBExtension and the rooms' battles.
  //   fb_1 joinFb {id, name, lv}  -> {succ} (false with task / score when it cannot: no entries left)
  //   fb_2 leaveFb {}             -> {}
  //   fb_3 getFbWildPet {}        -> {pms: [{raceId, id, lv}]} the room's 亚比 not yet beaten
  //   54_17 fightInCopy {id}      -> the battle with the room's 亚比 of that id (wanderer or the script's fight)
  //   fb_4 tryFinFb {}            -> {fin, bn: [{type, id, num}], gr, tm}: the run's rating by its time, its pay
  //   fb_5 tryGetCase {}          -> {succ, bn}: a room's chest, once
  //   fb_6 bestPraise {id}        -> {gr: "简单;困难;传奇"} best ratings ("#" none)
  //   fb_7 resetScenePet {}       -> {}; fb_8 healHPAndPP {} -> {res}; fb_9 panel info {id} -> {g, lt, bt, gr}
  const FB = "FBExtension";
  const fbOf = (o: PetOwner): FbRec => {
    const r = ((o as { fb?: FbRec }).fb ??= {});
    if (r.day !== deps.today()) {
      r.day = deps.today();
      r.used = {};
    }
    return r;
  };
  const fbNow = () => deps.now?.() ?? Date.now();
  world.xt(`${FB}.fb_9`, async (ctx) => {
    const o = await deps.load(ctx);
    const r = fbOf(o);
    const id = Number(ctx.params.id) | 0;
    const best = r.best?.[id] ?? ["#", "#", "#"];
    ctx.reply({ id, g: best.some((g) => g !== "#"), lt: Math.max(0, FB_TIMES - (r.used?.[id] ?? 0)), bt: 0, gr: best.join(";") }, "fb_9");
  });
  world.xt(`${FB}.fb_6`, async (ctx) => {
    const r = fbOf(await deps.load(ctx));
    const id = Number(ctx.params.id) | 0;
    ctx.reply({ gr: (r.best?.[id] ?? ["#", "#", "#"]).join(";") }, "fb_6");
  });
  world.xt(`${FB}.fb_1`, async (ctx) => {
    const o = await deps.load(ctx);
    const r = fbOf(o);
    const asked = FBS[Number(ctx.params.id) | 0] ?? fbByName(String(ctx.params.name ?? ""));
    // Counted by the 副本 it is (a made-up id would be a new count each time).
    const def = asked && FBS.includes(asked) ? asked : undefined;
    const id = def ? FBS.indexOf(def) : -1;
    const used = r.used?.[id] ?? 0;
    if (!def || used >= FB_TIMES) return ctx.reply({ succ: false, task: false, score: false }, "fb_1");
    (r.used ??= {})[id] = used + 1;
    r.cur = { id, name: def.name, lv: Math.max(0, Math.min(2, Number(ctx.params.lv) | 0)), start: fbNow(), dead: {}, chests: [], n: used + 1 };
    await deps.save(o);
    ctx.reply({ succ: true }, "fb_1");
  });
  world.xt(`${FB}.fb_2`, async (ctx) => {
    const o = await deps.load(ctx);
    fbOf(o).cur = null;
    await deps.save(o);
    ctx.reply({}, "fb_2");
  });
  const fbHere = (o: PetOwner, ctx: XtContext) => {
    const cur = fbOf(o).cur;
    const room = sceneOfRoom(ctx.player.room);
    const def = fbOfRoom(room);
    if (!cur || !def || def.name !== cur.name) return null;
    // The run of the day picks which of a list a fight takes (fbsiwude6's two statues).
    return { cur, room, def, pets: fbRoomPets(def, room, cur.lv, (cur.n ?? 1) - 1) };
  };
  world.xt(`${FB}.fb_3`, async (ctx) => {
    const o = await deps.load(ctx);
    const here = fbHere(o, ctx);
    if (!here || !here.def.rooms[here.room]?.wild) return ctx.reply({ pms: [] }, "fb_3");
    const dead = here.cur.dead[here.room] ?? [];
    ctx.reply({ pms: here.pets.filter((p) => !dead.includes(p.id)).map((p) => ({ raceId: p.code, id: p.id, lv: p.lv })) }, "fb_3");
  });
  world.xt(`${FB}.fb_7`, async (ctx) => {
    const o = await deps.load(ctx);
    const here = fbHere(o, ctx);
    if (here) delete here.cur.dead[here.room];
    await deps.save(o);
    ctx.reply({}, "fb_7");
  });
  world.xt(`${FB}.fb_8`, async (ctx) => {
    const o = await deps.load(ctx);
    // Not between the turns of a fight (the fight's 亚比 are these).
    if (battles.has(o.id)) return ctx.reply({ res: false }, "fb_8");
    const t = await deps.tables();
    for (const p of o.pets ?? []) {
      normalisePet(p, t);
      p.hp = statsOf(p, t)[0];
      for (const sk of p.skills) sk.pp = sk.max;
    }
    await deps.save(o);
    ctx.reply({ res: true }, "fb_8");
  });
  world.xt(`${FB}.fb_5`, async (ctx) => {
    const o = await deps.load(ctx);
    const here = fbHere(o, ctx);
    if (!here || here.cur.chests.includes(here.room)) return ctx.reply({ succ: false, bn: [] }, "fb_5");
    here.cur.chests.push(here.room);
    const coins = 100 * (here.cur.lv + 1);
    (o as { score?: number }).score = ((o as { score?: number }).score ?? 0) + coins;
    const bag = (((o as { items?: Record<string, Record<string, number>> }).items ??= {})["2"] ??= {});
    const candy = here.cur.lv > 0 ? 61 : 60; // 中级 / 高级体力糖
    bag[String(candy)] = (bag[String(candy)] ?? 0) + 1;
    await deps.save(o);
    ctx.reply({ score: (o as { score?: number }).score }, "onScoreUpdated");
    ctx.reply({ amount: `2_${candy}_0_1` }, "onAmountUpdated");
    ctx.reply({ succ: true, bn: [{ type: 100, id: -1, num: coins }, { type: 2, id: candy, num: 1 }] }, "fb_5");
  });
  world.xt(`${FB}.fb_4`, async (ctx) => {
    const o = await deps.load(ctx);
    const r = fbOf(o);
    const cur = r.cur;
    // Finished once the last room's boss is beaten.
    if (!cur || !fbBossBeaten(cur)) return ctx.reply({ fin: false, bn: [], gr: "", tm: 0 }, "fb_4");
    const tm = Math.max(1, Math.round((fbNow() - cur.start) / 1000));
    const gr = fbGrade(tm);
    const best = ((r.best ??= {})[cur.id] ??= ["#", "#", "#"]);
    best[cur.lv] = betterGrade(best[cur.lv], gr);
    const coins = fbPay(cur.lv, gr);
    (o as { score?: number }).score = ((o as { score?: number }).score ?? 0) + coins;
    r.cur = null;
    await deps.save(o);
    ctx.reply({ score: (o as { score?: number }).score }, "onScoreUpdated");
    ctx.reply({ fin: true, bn: [{ type: 100, id: -1, num: coins }], gr, tm }, "fb_4");
  });
  world.xt("PetExtension.54_17", async (ctx) => {
    const o = await deps.load(ctx);
    const here = fbHere(o, ctx);
    const id = Number(ctx.params.id) | 0;
    const pet = here?.pets.find((p) => p.id === id);
    if (!here || !pet) return ctx.reply({ msg: "这里没有可以挑战的亚比。" }, "2303");
    ensureFbSpecies((await deps.tables()).pm);
    const room = here.room;
    await begin(ctx, fbSpecies(pet.code), pet.lv, false, (owner) => {
      const cur = fbOf(owner).cur;
      if (cur) (cur.dead[room] ??= []).includes(id) || cur.dead[room].push(id);
      return [];
    }, pet.code, undefined, id);
  });

  // fightWithBoss {raceId, index}: a 守护者 (dailyactivity/dailyactivityservice, rebuilt): one of the
  // forms of BossTimeHelper.bossTimeConfig, numbered variant * 10000 + species, at its level there;
  // no catching. The asked id comes back with the end of the fight, which the client checks.
  // A win brings the 守护者's 亚比蛋 (PetEggData: the egg of its line's first form, 88 沙麒麟亚比蛋
  // for 沙麒麟 90), into the eggs (type 5) the 家园's 亚比孵化器 hatches.
  // A skill learnt from its film (petlearning/petlearning<race>: 赤火剑 for 艾尔利克): PetExtension2
  // 54e_5 {pid, sid} -> 54e_5 {res}; the 亚比 knows the skill from then on (更换技能).
  world.xt("PetExtension2.54e_5", async (ctx) => {
    const o = await deps.load(ctx);
    const pet = (o.pets ?? []).find((p) => p.id === (Number(ctx.params.pid) | 0));
    const sid = Number(ctx.params.sid) | 0;
    // The films there are (petlearning<race>) teach their own 亚比, a skill of the tables.
    const t = await deps.tables();
    if (!pet || !sid || !FILM_RACES.has(pet.race) || !t.pm.skills[String(sid)]) return ctx.reply({ res: false }, "54e_5");
    pet.learned = [...new Set([...(pet.learned ?? []), sid])];
    await deps.save(o);
    ctx.reply({ res: true, pid: pet.id, sid }, "54e_5");
  });

  // 友人契约书's panel (activityres/activity121018/friendcontract): 54_19 {} -> {bo: "id,id"}, the
  // bosses' marks the player has won (1257: 友人契约书 beaten, its egg film then not shown again).
  world.xt("PetExtension.54_19", async (ctx) => {
    const o = await deps.load(ctx);
    ctx.reply({ bo: ((o as { bossMarks?: number[] }).bossMarks ?? []).join(",") }, "54_19");
  });

  world.xt("PetExtension.54_16", async (ctx) => {
    // A pair asked for at once ("11320#11322", fightWithTeamBoss) fights its first here.
    const asked = Number(String(ctx.params.raceId ?? "0").split("#")[0]) | 0;
    const index = Math.max(0, Number(ctx.params.index) | 0);
    if (!isGuardian(asked)) return ctx.reply({ msg: "这里没有可以挑战的守护者。" }, "2303");
    const t = await deps.tables();
    // The species of a boss form: variant * 10000 + species, or for 终极麦斗王's 14523 / 11514 / 11516
    // (PetAssetsMap) variant * 1000 + species.
    const species = BOSS_SPECIES[asked] ?? (speciesOf(t, asked % 10000) ? asked % 10000 : speciesOf(t, asked % 1000) ? asked % 1000 : asked % 10000);
    const egg = BOSS_EGGS[asked] ?? (asked === 14523 || asked === 11514 || !lastGuardianForm(asked, index) ? 0 : eggOfLine(t, species));
    const mark = BOSS_MARKS[asked];
    const onWin: Battle["onWin"] = (o) => {
      const out: Msg[] = [];
      const items = ((o as { items?: Record<string, Record<string, number>> }).items ??= {});
      // A 战术卡, now and then (petcards.ts).
      const card = cardDrop(deps.rng ?? Math.random);
      if (card) {
        const cards = (items[String(PET_CARD)] ??= {});
        cards[String(card)] = (cards[String(card)] ?? 0) + 1;
        out.push(["onAmountUpdated", { amount: `${PET_CARD}_${card}_0_1` }], [NOTE, { text: `获得了战术卡「${PET_CARDS[card].name}」！`, bn: { type: PET_CARD, id: card, num: 1 } }]);
      }
      let again = false;
      if (mark) {
        const marks = ((o as { bossMarks?: number[] }).bossMarks ??= []);
        again = marks.includes(mark);
        if (!again) marks.push(mark);
      }
      if (!egg || (again && FIRST_WIN_ONLY.has(asked))) return out;
      const eggs = (items["5"] ??= {});
      eggs[String(egg)] = (eggs[String(egg)] ?? 0) + 1;
      // The 2013 client is not told eggs by onAmountUpdated (server.ts leaves them out): the
      // end of the battle says it.
      return [...out, ["onAmountUpdated", { amount: `5_${egg}_0_1` }], [NOTE, { text: `获得了${nameOf(t, egg)}亚比蛋！`, bn: { type: 5, id: egg, num: 1 } }]];
    };
    await begin(ctx, species, guardianLevel(asked, index), false, onWin, asked);
  });

  /**
   * Run a player command inside the battle and finish the turn. A command that
   * was refused (no such item, a ball too early …) returns {refused}: those
   * replies go out alone and the turn is not used up.
   */
  type Outcome = Msg[] | "end" | { refused: Msg[] };
  const turn = (name: string, run: (ctx: XtContext, b: Battle, e: BattleEngine, o: PetOwner, t: PetTables) => Outcome | Promise<Outcome>) =>
    world.xt(`${PM}.${name}`, async (ctx) => {
      const o = await deps.load(ctx);
      const b = battles.get(o.id);
      if (!b || b.over) return ctx.reply({ msg: "战斗还没有开始" }, "2414");
      if (b.duel) return duels.command(name, ctx, b);
      const t = await deps.tables();
      // The battle holds the pet records of an earlier load: point it at this one's.
      const rebind = (f: Fighter) => {
        const fresh = (o.pets ?? []).find((p) => p.id === f.pet.id);
        if (fresh) {
          fresh.hp = f.pet.hp;
          fresh.skills = f.pet.skills;
          f.pet = fresh;
        }
      };
      rebind(b.mine);
      const e = new BattleEngine(t, deps.rng);
      e.bag = o.pets;
      e.ownerRef = o;
      const out = await run(ctx, b, e, o, t);
      if (out === "end") {
        await deps.save(o);
        return;
      }
      if (!Array.isArray(out)) return send(ctx, out.refused);
      out.push(...finish(b, e, o, t, ctx));
      await deps.save(o);
      send(ctx, out);
    });

  /** After the actions of a turn: residual damage, then the next turn, a forced switch, or the end. */
  const finish = (b: Battle, e: BattleEngine, o: PetOwner, t: PetTables, ctx: XtContext): Msg[] => {
    const out: Msg[] = [];
    // 威吓 of the wild 亚比: the player's 亚比 goes back and another one comes out, at random.
    if (b.forceOut === 0 && b.mine.pet.hp > 0 && b.wild.pet.hp > 0) {
      const others = (o.pets ?? []).filter((p) => p.hp > 0 && p !== b.mine.pet);
      const gone = b.mine.pet;
      if (others.length) {
        const next = others[Math.floor((deps.rng ?? Math.random)() * others.length)];
        b.mine = fighter(0, next, o.id, t);
        const desc = `${gone.nick || nameOf(t, gone.race)}被强制替换下场！\n${next.nick || nameOf(t, next.race)}出战了！`;
        out.push(["2413", { playerInfo: e.view(b, 0), extInfo: { desc, res: 1, forced: false } }]);
      } else out.push(["2421", { slotId: 0, hpInc: 0, desc: "没有可以替换的亚比。", pmmList: e.views(b) }]);
    }
    b.forceOut = undefined;
    if (b.wild.pet.hp > 0 && b.mine.pet.hp > 0) out.push(...e.endOfTurn(b));
    if (b.wild.pet.hp <= 0) {
      b.over = true;
      let radarCoins = 0;
      const pet = b.mine.pet;
      const before = pet.race;
      // The 经验器 and 学习器 of the bag (petitems.ts), each win one of their uses.
      const boosts = (o as PetItemOwner).boosts ?? {};
      const mult = { exp: boosts.exp3 ? 3 : boosts.exp2 ? 2 : 1, ev: boosts.ev2 ? 2 : 1 };
      const r: WinResult = b.noAward ? { msgs: [] } : award(t, pet, b.wild.pet.race, b.wild.pet.level, mult);
      out.push(...r.msgs);
      if (!b.noAward) {
        const used: string[] = [];
        for (const k of [mult.exp === 3 ? "exp3" : mult.exp === 2 ? "exp2" : "", mult.ev === 2 ? "ev2" : "", boosts.radar ? "radar" : ""] as (keyof Boosts | "")[]) {
          if (!k) continue;
          boosts[k] = Math.max(0, (boosts[k] ?? 0) - 1);
          if (!boosts[k]) delete boosts[k];
          used.push(k);
        }
        // 寻宝雷达: "战斗结束可获得很多晶币奖励"; how many is lost (RECONSTRUCTED: 50 and 5 a level of the wild 亚比).
        if (used.includes("radar")) {
          const rec = o as PetOwner & { score?: number };
          const coins = 50 + 5 * b.wild.pet.level;
          rec.score = Math.min(9_999_999, (rec.score ?? 0) + coins);
          out.push(["onScoreUpdated", { score: rec.score }]);
          radarCoins = coins;
        }
      }
      if (r.evolvedTo && o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
      // A win's own messages; NOTE ones are words for the end of the battle, not sent.
      const won = b.onWin ? b.onWin(o) : [];
      const notes = won.filter(([c]) => c === NOTE).map(([, m]) => String(m.text));
      // What a win brought (a boss's 亚比蛋): the client shows the 2013 MaterialGetPanel for each
      // once the battle is closed ("1 个 …亚比蛋 已经放入你的亚比孵化器").
      const bn = won.filter(([c, m]) => c === NOTE && m.bn).map(([, m]) => m.bn);
      out.push(...won.filter(([c]) => c !== NOTE));
      const desc = b.noAward ? "战斗胜利！" : `战斗胜利！${nameOf(t, before)}获得了经验。${radarCoins ? `寻宝雷达找到了${radarCoins}晶币！` : ""}`;
      // myFinalRaceId: the 亚比 that ended it (PetFightEvent.myFinalRaceId; the 道馆 panels give their stone for their own).
      out.push(["2403", { isWin: true, raceId: b.asked ?? b.wild.pet.race, id: b.copyId ?? 0, evolveFrom: r.evolvedTo ? before : 0, myFinalRaceId: before, desc, ...(notes.length ? { note: notes.join("\n") } : {}), ...(bn.length ? { bn } : {}), pmmList: e.views(b) }]);
      battles.delete(o.id);
      return out;
    }
    if (b.mine.pet.hp <= 0) {
      if ((o.pets ?? []).some((p) => p.hp > 0)) {
        b.mustSwitch = true;
        out.push(["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]);
        return out;
      }
      b.over = true;
      if (b.onLose) out.push(...b.onLose(o));
      out.push(["2403", { isWin: false, raceId: b.asked ?? b.wild.pet.race, id: b.copyId ?? 0, myFinalRaceId: b.mine.pet.race, desc: "你的亚比都倒下了……快带它们去治疗吧！", pmmList: e.views(b) }]);
      battles.delete(o.id);
      return out;
    }
    b.turn++;
    const bf = b.mine.buff;
    if (bf && b.turn > bf.until) {
      b.mine.stats[bf.i] = Math.max(1, b.mine.stats[bf.i] - bf.add);
      b.mine.buff = undefined;
    }
    out.push(["2402", { turn: b.turn, pmmList: e.views(b) }]);
    return out;
  };

  // useSkill {skillId, tarSId, isAuto, tarPSId, reqPSId}
  turn("1401", (_ctx, b, e) => {
    if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]] };
    const id = Number(_ctx.params.skillId);
    const usable = b.mine.pet.skills.filter((s) => s.pp > 0);
    const chosen = usable.find((s) => s.id === id) ? id : usable.length ? usable[0].id : 0;
    return e.skillTurn(b, chosen);
  });

  // standby {isAuto, reqPSId} (PetClient.standby): the turn's time ran out and no skill has uses left
  // (the later FightPanel's petAutoUseSkill): the 亚比 waits, the wild 亚比 acts.
  turn("1406", (_ctx, b, e, _o, t) => {
    if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]] };
    const pet = b.mine.pet;
    // A skill it uses by itself (蓄力, 连续攻击N回合) needs no PP.
    const forced = e.forcedOf(b.mine);
    if (forced !== undefined) return e.skillTurn(b, forced);
    return [["2421", { slotId: 0, hpInc: 0, desc: `${pet.nick || nameOf(t, pet.race)}什么也没有做。`, pmmList: e.views(b) }], ...e.wildTurn(b)];
  });

  // useItem {itemId, tarSId}: 体力糖 heal, 活力豆 give PP back; then the wild 亚比 acts.
  turn("1402", (ctx, b, e, o, t) => {
    const items = ((o as { items?: Record<string, Record<string, number>> }).items ??= {});
    const bag = (items["2"] ??= {});
    const id = Number(ctx.params.itemId);
    const pet = b.mine.pet;
    const name = pet.nick || nameOf(t, pet.race);
    const refuse = (desc: string): Outcome => ({ refused: [["2412", { reqSId: 0, itemId: id, res: -1, refused: true, desc, pmmList: e.views(b) }]] });
    if (b.mustSwitch || !(bag[id] > 0) || (!POTIONS[id] && !PP_BEANS[id] && !CURES[id])) return refuse("这个道具现在不能使用。");
    const f = b.mine;
    const cure = CURES[id];
    if (cure) {
      // Which of the 亚比's troubles the 药剂 takes away.
      const has = cure === "all" ? !!f.status || f.sleep > 0 || f.confuse > 0 || f.bind > 0 || f.fear > 0 || f.weak > 0 || f.seeded || (id === 101 && Object.values(f.stages).some((v) => v < 0))
        : cure === "睡眠" ? f.status === "睡眠" || f.sleep > 0
        : cure === "混乱" ? f.confuse > 0
        : cure === "寄生" ? f.seeded
        : f.status === cure;
      if (!has) return refuse(`${name}没有需要解除的状态。`);
    } else if (POTIONS[id] && pet.hp >= f.stats[0]) return refuse(`${name}的体力是满的。`);
    bag[id]--;
    if (bag[id] <= 0) delete bag[id];
    ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
    let hpInc = 0;
    let desc: string;
    if (cure) {
      if (cure === "all" || f.status === cure || (cure === "睡眠" && f.sleep > 0)) {
        f.status = undefined;
        f.statusLeft = 0;
      }
      if (cure === "all" || cure === "睡眠") f.sleep = 0;
      if (cure === "all" || cure === "混乱") f.confuse = 0;
      if (cure === "all" || cure === "寄生") f.seeded = false;
      if (cure === "all") f.bind = f.fear = f.weak = 0;
      if (id === 101) for (const k of Object.keys(f.stages) as StatKey[]) f.stages[k] = Math.max(0, f.stages[k]);
      desc = id === 101 ? `${name}的不利状态和能力下降都消除了！` : cure === "all" ? `${name}的不利状态都消除了！` : `${name}的${cure}状态解除了！`;
    } else if (POTIONS[id]) {
      hpInc = Math.min(b.mine.stats[0] - pet.hp, POTIONS[id]);
      pet.hp += hpInc;
      desc = `${name}回复了${hpInc}点体力！`;
    } else {
      for (const s of pet.skills) s.pp = Math.min(s.max, s.pp + PP_BEANS[id]);
      desc = `${name}的技能次数回复了！`;
    }
    return [["2412", { reqSId: 0, itemId: id, res: 1, hpInc, desc, pmmList: e.views(b) }], ...e.wildTurn(b)];
  });

  // switchPM {pmId}: another 亚比 comes out; unless the last one fell, the wild 亚比 acts.
  turn("1403", (ctx, b, e, o, t) => {
    const id = Number(ctx.params.pmId);
    const next = (o.pets ?? []).find((p) => p.id === id);
    if (!next || next.hp <= 0 || next.id === b.mine.pet.id) {
      return { refused: [["2413", { playerInfo: e.view(b, 0), extInfo: { desc: "这只亚比不能出战。", res: -1, refused: true } }]] };
    }
    const forced = b.mustSwitch;
    // 束缚 or 无法替换亚比 (a skill of the wild 亚比) keeps the 亚比 in, unless it fell.
    if (!forced && b.mine.trapped > 0) {
      return { refused: [["2413", { playerInfo: e.view(b, 0), extInfo: { desc: `${b.mine.pet.nick || nameOf(t, b.mine.pet.race)}无法替换！`, res: -1, refused: true } }]] };
    }
    b.mustSwitch = false;
    b.mine = fighter(0, next, o.id, t);
    // 为自己下一只出场的亚比满状态回复.
    if (b.nextHeal?.[0]) {
      b.nextHeal[0] = false;
      next.hp = b.mine.stats[0];
      for (const s of next.skills) s.pp = s.max;
    }
    const msg: Msg = ["2413", { playerInfo: e.view(b, 0), extInfo: { desc: `就决定是你了，${next.nick || nameOf(t, next.race)}！`, res: 1, forced } }];
    return forced ? [msg] : [msg, ...e.wildTurn(b)];
  });

  // escape {}: always works against wild 亚比.
  turn("1404", (ctx, b, _e, o) => {
    b.over = true;
    battles.delete(o.id);
    if (b.onLose) for (const [c, body] of b.onLose(o)) ctx.reply(body, c);
    ctx.reply({ reqSId: 0, isEscape: true, raceId: b.asked ?? b.wild.pet.race, desc: "成功逃跑了！" }, "2414");
    return "end";
  });

  // catchPM {tarSId, itemId}
  turn("1405", (ctx, b, e, o, t) => {
    const items = ((o as { items?: Record<string, Record<string, number>> }).items ??= {});
    const bag = (items["2"] ??= {});
    const ball = Number(ctx.params.itemId);
    const clv = catchLevel(o.catchExp ?? 0).clv;
    const fail = (desc: string, refused = false): Msg => ["2415", { reqId: o.id, tarSId: 1, itemId: ball, pmId: 0, lv: clv, lc: 0, refused, desc }];
    if (b.mustSwitch) return { refused: [fail("请先选择出战的亚比。", true)] };
    if (!b.canCatch) return { refused: [fail("这只亚比不能捕捉！", true)] };
    if (!(bag[ball] > 0) || BALLS[ball] === undefined) return { refused: [fail("你没有这种亚比球。", true)] };
    if (BALLS[ball] < 1 && b.wild.pet.hp > b.wild.stats[0] * catchHpLimit(t, b.wild.pet.race)) return { refused: [fail("亚比的体力还很多，现在还捉不到它哦！", true)] };
    bag[ball]--;
    if (bag[ball] <= 0) delete bag[ball];
    ctx.reply({ amount: `2_${ball}_0_-1` }, "onAmountUpdated");
    const rng = deps.rng ?? Math.random;
    if (rng() >= catchChance(t, b.wild, ball, clv)) return [fail("哎呀，亚比挣脱了！"), ...e.wildTurn(b)];
    // Caught: the wild 亚比 joins the bag, or the 仓库 when the bag is full.
    const caught = b.wild.pet;
    caught.id = o.nextPetId = (o.nextPetId ?? 0) + 1;
    caught.got = deps.today();
    caught.ev = [0, 0, 0, 0, 0, 0];
    const pets = (o.pets ??= []);
    const inBag = pets.length < 6;
    (inBag ? pets : (o.storage ??= [])).push(caught);
    const c = Number(speciesOf(t, caught.race)?.c[0]) || 1;
    o.catchExp = (o.catchExp ?? 0) + 10 + 5 * c;
    const lv = catchLevel(o.catchExp).clv;
    b.over = true;
    battles.delete(o.id);
    send(ctx, [
      ["2415", { reqId: o.id, tarSId: 1, itemId: ball, pmId: caught.id, raceId: caught.race, lv, lc: inBag ? 1 : 2, pet: briefOf(caught, o, t), desc: `捕捉成功！${nameOf(t, caught.race)}${inBag ? "进入了你的亚比背包" : "被送进了亚比仓库"}。` }],
      ["2403", { isWin: true, isCatched: true, raceId: caught.race, desc: "捕捉成功！", pmmList: e.views(b) }],
      ...(markDic(o, t, caught.race, OWNED) ? [NEW_RECORD] : []),
    ]);
    return "end";
  });

  // The 沙盒's fights (sandbox.ts): its opponents, not to be caught, no award.
  installGyms(world, { load: deps.load, save: deps.save, tables: deps.tables, today: deps.today, now: () => deps.now?.() ?? Date.now(), rng: deps.rng ?? Math.random });
  installSandbox(world, { load: deps.load, save: deps.save, tables: deps.tables, begin: (ctx, race, level, sandbox) => begin(ctx, race, level, false, undefined, undefined, undefined, undefined, sandbox) });

  // Leaving the room ends a battle left open (the client was closed mid-fight).
  world.xt(`${PM}.1307`, async (ctx) => {
    const o = await deps.load(ctx);
    const b = battles.get(o.id);
    if (b?.duel) duels.leave(b, o.id);
    else battles.delete(o.id);
    ctx.reply({}, "2308");
  });
  // A player's game ends: his battle goes (a duel is given up, duel.ts).
  world.onLeaveGame?.((s) => {
    const p = world.player(s);
    const b = p ? battles.get(p.id) : undefined;
    if (p && b && !b.duel) battles.delete(p.id);
  });
}
