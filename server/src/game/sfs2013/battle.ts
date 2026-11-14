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

import { MONEY_MAX } from "./money.ts";
import { recordWin } from "./wins.ts";
import { settleTasks, stepsByPetWin, type TaskOwner } from "./tasks.ts";
import { wildDrop, type ActsOwner } from "./planetacts.ts";
import { FB_TIMES, betterGrade, ensureFbSpecies, fbBossBeaten, fbByName, fbGrade, fbOfRoom, fbPay, fbRoomPets, fbSpecies, FBS, type FbRec } from "./fb.ts";
import {
  catchLevel,
  evolutionAt,
  expYield,
  skillsLearntAt,
  typeMultiplier,
  type PmJiuji,
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
import { costumeDrop, GUARDIAN_SUITS, WUSHEN_RACES, WUSHEN_SUIT } from "./costumes.ts";
import { installSandbox } from "./sandbox.ts";
import { applyFate, dollLevel, DARK_DOLLS, gymOf, gymWon, installGyms, mazeDoll, rollFate, towerFloorWon, waterAttacker, waterRunEnd, GYM_DARK, WATER_BLESS, WATER_ROUNDS, GYM_LIGHT, GYM_MASTERS, GYM_THUNDER, GYM_TOWER, TOWER_FLOORS as THUNDER_FLOORS } from "./gyms.ts";
import { sceneOfRoom, type World, type XtContext } from "./server.ts";
import { registerFights } from "./fighting.ts";
import { markDic, MET, NEW_RECORD, OWNED } from "./petdic.ts";
import { ATTRS, BAD_STATUSES, nameSkills, readSkill, type Cond, type SkillEffects, type StatKey, type StatusName, type Timed } from "./skilltext.ts";
import { installDuels, type Duel } from "./duel.ts";
import { AUTO_EVERY, FIELDS, fieldByName, fieldsOfTrait, syOf, type FieldAct, type FieldRule } from "./shengyu.ts";
import type { Boosts, PetItemOwner } from "./petitems.ts";

// ---------------------------------------------------------------- skill effects

// What a skill does is read from its description (skilltext.ts): the 2013 rules are lost with
// the server, the descriptions are what the player is told.
export { STATUSES, type SkillEffects, type StageChange, type StatKey, type StatusName } from "./skilltext.ts";

const fxCache = new Map<string, SkillEffects>();
/** A skill's effects, read from its description once (the engine never changes them). */
let namedSet = false;

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
  /** How many times it has worked (cap). */
  used?: number;
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
  /** It lost 体力 this turn, from anything (曹魏武王: 每当自身体力流失). */
  lostHp?: boolean;
}

export interface Fighter {
  slot: 0 | 1;
  /** Its skill's changes made at the round's end (神圣考验: by whether it was hit). */
  endStages?: import("./skilltext.ts").StageChange[];
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
  /** Layers of the later skills' marks on it (复原印记, 星神古魂, 逆火之印 …). */
  stacks?: Record<string, number>;
  /** The skill it used last. */
  last?: number;
  /** 基础数值 raised this many times (龙腾四海), by pct each. */
  baseUp: { n: number; pct: number };
  /** 基础数值 lowered: points of 攻击 and 特攻, and the share of both (陶醉). */
  baseDown: { atk: number; satk: number; pct: number };
  /** Comes back with all its HP once when it falls (使用后被对方打败则满状态复活). */
  revive?: boolean;
  /**
   * 究极: pet is a battle-only copy of `from` in its 究极 form for `left` more rounds (fresh: the
   * round it changed in, not counted), with `up` added to its numbers; `from` is the record kept.
   */
  form?: { from: PetRecord; left: number; up: number[]; fresh: boolean; qy?: PmJiuji["qy"] };
  /** Its 究极 was used this battle. */
  formUsed?: boolean;
  /** The round it came out in, once its 特性's field and the field's 上场 effect were seen to. */
  cameRound?: number;
  /** 圣武霸体: its 体力 before it went down to 1, back at the start of the next round. */
  hpBack?: number;
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
  /** Fought by the 自动战斗仪: at its end every 亚比 of the bag has all its 体力 and PP back. */
  auto?: boolean;
  /** A battle the 自动战斗仪 may fight (a wild 亚比 of the room, caught or not). */
  autoMay?: boolean;
  /** The opponents still to come after the one fighting (an activity's boss with its helpers). */
  foes?: PetRecord[];
  /** 最强防御PK战: the rounds to stand (won once they are over, the 亚比 standing); no switching. */
  insist?: number;
  /** A mod's party (mods.ts): the player's 亚比 whose fall ends the battle as lost, and the words then. */
  keep?: number;
  keepText?: string;
  /** 亚比对战 with another player (duel.ts): the battle of both, its commands are the duel's. */
  duel?: Duel;
  /** 全场 X系威力提升: the 属性 up and down, for some turns. */
  field?: { up: number; upPct: number; down?: number; downPct?: number; left: number };
  /** 圣域 (shengyu.ts): the field out (PMWeather id), the side that made it, the round. */
  sy?: { id: string; slot: 0 | 1; at: number };
  /** The 亚比 (record ids) that used their 超奥义 this battle. */
  aoyiUsed?: number[];
  /** A skill's background (SKILL_BACKGROUNDS): its key, the 亚比 that made it (record id, side), the rounds left. */
  bg?: { key: string; slot: 0 | 1; pet: number; left: number };
  /** Effects that come at the end of a later turn (下回合结束时…, N回合后…). */
  delayed?: { slot: 0 | 1; left: number; kind: string; n?: number; f?: number; stats?: StatKey[]; delta?: number; chance?: number }[];
  /** The side whose next 亚比 comes out with all its HP (为自己下一只出场的亚比满状态回复). */
  nextHeal?: boolean[];
  /** The side a skill forces to switch (威吓: 强制对方单体替换亚比战斗); the battle's turn does it. */
  forceOut?: 0 | 1;
  /**
   * An activity boss's own trait, at the end of each round: knocks out the player's 亚比 every
   * killEvery rounds ("每5回合会秒掉你一只亚比"), gets back healFrac of its 体力 ("每回合会恢复部分血量").
   */
  boss?: { killEvery?: number; healFrac?: number };
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

/** Does f have that status (害怕 混乱 束缚 衰弱 寄生 beside the five)? */
function hasStatus(f: Fighter, s: StatusName | "any"): boolean {
  if (s === "any") return !!f.status || f.confuse > 0 || f.bind > 0 || f.weak > 0 || f.seeded || f.fear > 0;
  if (s === "混乱") return f.confuse > 0;
  if (s === "束缚") return f.bind > 0;
  if (s === "害怕") return f.fear > 0;
  if (s === "衰弱") return f.weak > 0;
  if (s === "寄生") return f.seeded;
  return f.status === s;
}

/** Two names of one mark (古魂 and 古魂印记, 雷印 and 龙鳞雷印). */
const sameMark = (a: string, b: string) => a === b || a.endsWith(b) || b.endsWith(a) || a.replace(/印记$/, "") === b.replace(/印记$/, "");

/** The layers of a mark f carries (by any of its names). */
const layersOf = (f: Fighter, name: string): number => {
  const st = f.stacks ?? {};
  const k = Object.keys(st).find((x) => sameMark(x, name));
  return k ? st[k] : 0;
};

/** Is f in that state (风暴, 巨大化, 狂战 …)? */
const inState = (f: Fighter, name: string) => f.timed.some((y) => y.kind === "state" && y.left > 0 && !!y.mark && sameMark(y.mark, name));

/** A lasting effect that counts now: its turns left, and what it waits on (a 护盾, a state, a status, a mark). */
const active = (f: Fighter, x: Live): boolean =>
  x.left > 0 && (!x.whileShield || (f.armour ?? 0) > 0) && (!x.whileState || inState(f, x.whileState)) && (!x.ifStatus || hasStatus(f, x.ifStatus)) && (!x.whileMark || layersOf(f, x.whileMark) > 0);

const live = (f: Fighter, kind: Timed["kind"]): Live[] => f.timed.filter((x) => x.kind === kind && active(f, x));

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
    fx.stealHp ||
    fx.ppRange ||
    fx.badStatuses ||
    fx.invert?.foe ||
    fx.stacksDouble?.who === "foe" ||
    fx.curse ||
    fx.clearFoeTimed ||
    fx.breakMark ||
    fx.statPts?.some((p) => p.who === "foe") ||
    fx.stages.some((s) => s.or && !s.or.self) ||
    fx.passDowns ||
    fx.passStatus ||
    fx.painSplit ||
    fx.swapHp ||
    fx.endeavor ||
    fx.ohko ||
    fx.ohkoIf ||
    fx.bossKill ||
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

/**
 * The skills that change the battle's background, by the key of the later client's
 * skillbackground/skillbackground_<key> (its NewFightBSConfig keys): 夜之域 the starry night
 * (65), 星神之域 the star cloud (460), and the 战界奥义 their own fields (s_2_<skill>). Not
 * 2013 data: the server's choice of key is lost; these are the keys of the later files.
 */
const SKILL_BACKGROUNDS: Record<number, string> = { 17243: "65", 33001: "460" };
const ZHANJIE_BACKGROUNDS = new Set([26052, 27083, 28052, 30109, 30115, 30121, 30132, 30139, 30162, 31057, 31071, 31084, 31089, 32057, 32058, 32068, 33055, 33067, 33072, 33110, 34061, 34126, 36005]);
const backgroundOf = (id: number): string | undefined => SKILL_BACKGROUNDS[id] ?? (ZHANJIE_BACKGROUNDS.has(id) ? `s_2_${id}` : undefined);

/** 挣扎: what a 亚比 with no PP left does. */
const STRUGGLE: PmSkill = { n: "挣扎", p: 100, acc: 100, pp: 1, pri: 0, t: -1, k: 0, d: "自己承受伤害值的1/4" };

/** The turns a skill's effect lasts, as its words say (银光护盾 持续10回合), for the skills that ask for it. */
const markTurns = (d: string): number => {
  const m = d.match(/(\d+)\s*(?:个)?回合/);
  return m ? Number(m[1]) : 99;
};
const plain = (n: string) => n.replace(/[“”"]/g, "");

const STATUS_WORDS: Record<string, string> = { 麻痹: "麻痹了！", 冰冻: "被冰冻了！", 睡眠: "睡着了！", 烧伤: "被烧伤了！", 中毒: "中毒了！" };

// ---------------------------------------------------------------- the engine

export class BattleEngine {
  readonly t: PetTables;
  readonly rng: Rng;

  constructor(t: PetTables, rng: Rng = Math.random) {
    this.t = t;
    this.rng = rng;
    // The skills others set off by name (触发技能X), for the reader.
    if (t.pm.named && !namedSet) {
      nameSkills(Object.fromEntries(Object.entries(t.pm.named).map(([n, id]) => [n, t.pm.skills[String(id)]?.d ?? ""])));
      namedSet = true;
      fxCache.clear();
    }
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

  /**
   * The 自动战斗仪's choice for the player's 亚比 (RECONSTRUCTED: the 2013 rule is lost): the skill
   * with uses left that hits hardest by its power, its 属性 against the foe's, the same-属性 bonus
   * and its accuracy, one of the nearly best at random; a status skill only with no blow at all.
   */
  autoChoice(b: Battle): number {
    const usable = b.mine.pet.skills.filter((s) => s.pp > 0);
    if (!usable.length) return 0;
    const score = (id: number): number => {
      const sk = this.skill(id);
      if (sk.k === 2 || !(sk.p > 0)) return 0;
      const mult = sk.t < 0 ? 1 : typeMultiplier(this.t.pm, sk.t, b.wild.types);
      const stab = sk.t >= 0 && (b.mine.types[0] === sk.t || b.mine.types[1] === sk.t) ? 1.5 : 1;
      return sk.p * mult * stab * Math.min(100, sk.acc > 0 ? sk.acc : 100) / 100;
    };
    const scored = usable.map((s) => ({ id: s.id, v: score(s.id) }));
    const best = Math.max(...scored.map((x) => x.v));
    const pool = best > 0 ? scored.filter((x) => x.v >= best * 0.9) : scored;
    return pool[Math.floor(this.rng() * pool.length)].id;
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

  // ---------------------------------------------------------------- 究极 (pmdata jiuji)

  /** The 究极 of the 亚比 fighting (its line's row at the top 等级), when its form is known. */
  jiujiOf(f: Fighter) {
    const j = this.t.pm.jiuji?.[String(f.form ? f.form.from.race : f.pet.race)];
    return j && speciesOf(this.t, j.to) ? j : undefined;
  }

  /** Rounds of 聚能 still to wait before the 究极 can be used (the later button's 聚能中). */
  chargeLeft(b: Battle, f: Fighter): number {
    if (f.form || !this.jiujiOf(f)) return 0;
    return Math.max(0, (f.cameRound ?? 0) + (this.jiujiOf(f)?.store ?? 0) - b.turn);
  }

  /**
   * Can the player's 亚比 change now: a 究极 亚比 standing in its own form, out for its 聚能回合数 (0 for
   * every line: at once). Again after a form ends: the later button (BigSkillMCHandler_ChangeView)
   * is 究极变身 again once the form is over, there is no once a battle. Not in a duel (the later
   * client's PK had its own rules).
   */
  canChange(b: Battle, f: Fighter): boolean {
    return f.slot === 0 && !b.duel && !f.form && f.pet.hp > 0 && !!this.jiujiOf(f) && b.turn >= (f.cameRound ?? 0) + (this.jiujiOf(f)?.store ?? 0);
  }

  /**
   * 究极进化: the 亚比 becomes its 究极 form (its species: the same base numbers, its own 4 skills)
   * for its 究极回合数, its 体力, 攻击 … raised by the row's points (三阶). The record kept is not
   * touched: the form is a copy; when it ends the record has the same share of its 体力.
   * RECONSTRUCTED: the later server is lost; the client shows the form while isChangingView, for
   * changeViewRound + persistRound rounds, and the row's points.
   */
  change(b: Battle, f: Fighter): Msg {
    const j = this.jiujiOf(f)!;
    const from = f.pet;
    const sp = speciesOf(this.t, j.to)!;
    const name = from.nick || nameOf(this.t, from.race);
    if (j.k === 2 && j.qy) {
      // 契约 (零夜战骑, 辉月战骑: jiujiType 2): 坐骑召唤 — its mount under it for the whole battle, its own
      // skills and numbers, 回复最大体力值 N%, 伤害抗性 N%, 速度等级 +N, and its 契约技能 while it rides.
      const copy: PetRecord = { ...from, race: j.to };
      f.pet = copy;
      f.form = { from, left: j.keep, up: [0, 0, 0, 0, 0, 0], fresh: true, qy: j.qy };
      f.formUsed = true;
      f.stats = statsOf(copy, this.t);
      f.types = sp.t;
      const lines = [`${name}召唤了坐骑！`, j.qy.d];
      if (j.qy.hp > 0) this.heal(f, (f.stats[0] * j.qy.hp) / 100);
      if (j.qy.spd) this.stage(f, f, ["spd"], j.qy.spd, []);
      lines.push(`${j.qy.sn}：${j.qy.sd}`);
      return ["2417", { reqSId: f.slot, res: 1, raceId: j.to, from: from.race, left: j.keep, qiyue: true, desc: lines.join("\n"), pmmList: this.views(b) }];
    }
    const ids = [...new Set(sp.learn.map(([, id]) => id))].slice(-4);
    const copy: PetRecord = { ...from, race: j.to, skills: ids.map((id) => skillOf(this.t, id)) };
    copy.hp = from.hp + (j.up[0] ?? 0);
    f.pet = copy;
    f.form = { from, left: j.keep, up: j.up, fresh: true };
    f.formUsed = true;
    f.stats = statsOf(copy, this.t).map((v, i) => v + (j.up[i] ?? 0));
    f.types = sp.t;
    const desc = `${name}究极变身成了${nameOf(this.t, j.to)}！\n${j.d}`;
    return ["2417", { reqSId: f.slot, res: 1, raceId: j.to, from: from.race, left: j.keep, up: j.up, desc, pmmList: this.views(b) }];
  }

  /**
   * 越…越… (Scale; the words give no numbers, RECONSTRUCTED): a factor from what it goes by —
   * 15% a 属性等级 (at least a quarter), the value against the other's (1/2 to 2 times), up to twice
   * as the 体力 goes, half more each use (3 times at most), half more each 不良状态 — on the power,
   * the chances, the heals, the 伤害抵抗能力, the hits or the levels the skill changes.
   */
  private scaled(att: Fighter, def: Fighter, fx: SkillEffects, uses: number): SkillEffects {
    const out: SkillEffects = { ...fx, stages: fx.stages.map((x) => ({ ...x })), statuses: fx.statuses.map((x) => ({ ...x })), timed: fx.timed.map((x) => ({ ...x })) };
    const avg = (xs: number[]) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
    for (const sc of fx.scale ?? []) {
      const sub = sc.by.who === "foe" ? def : att;
      const oth = sub === att ? def : att;
      const keys = sc.by.stats ?? [];
      let f = 1;
      switch (sc.by.kind) {
        case "stage":
        case "stageDiff": {
          let lv = sc.by.kind === "stage" ? avg(keys.map((k) => sub.stages[k])) : avg(keys.map((k) => att.stages[k] - def.stages[k]));
          if (!sc.up) lv = -lv;
          f = Math.max(0.25, 1 + 0.15 * lv);
          break;
        }
        case "value": {
          // Values: the five (命中, 闪避, 暴击 have none: their levels instead).
          const five = keys.filter((k): k is "atk" | "def" | "satk" | "sdef" | "spd" => ["atk", "def", "satk", "sdef", "spd"].includes(k));
          const r = five.length ? avg(five.map((k) => stat(sub, k) / Math.max(1, stat(oth, k)))) : Math.max(0.25, 1 + 0.15 * avg(keys.map((k) => sub.stages[k])));
          f = Math.min(2, Math.max(0.5, sc.up ? r : 1 / Math.max(0.01, r)));
          break;
        }
        case "hp": {
          const share = sub.pet.hp / Math.max(1, sub.stats[0]);
          f = sc.up ? 1 + share : 2 - share;
          break;
        }
        case "uses":
          f = Math.min(3, 1 + 0.5 * (uses - 1));
          break;
        case "bad":
          f = 1 + 0.5 * BAD_STATUSES.filter((x) => this.has(sub, x)).length;
          break;
      }
      if (!sc.inc) f = 1 / f;
      const ch = (c: number) => (c >= 100 ? c : Math.min(100, c * f));
      switch (sc.on) {
        case "power":
          out.powerScale = (out.powerScale ?? 1) * f;
          break;
        case "chance":
          for (const x of out.statuses) x.chance = ch(x.chance);
          for (const x of out.stages) x.chance = ch(x.chance);
          for (const x of out.timed) if (x.chance !== undefined) x.chance = ch(x.chance);
          if (out.ohko) out.ohko = ch(out.ohko);
          if (out.ohkoIf) out.ohkoIf = { ...out.ohkoIf, chance: ch(out.ohkoIf.chance) };
          if (out.clearFoeUps) out.clearFoeUps = { ...out.clearFoeUps, chance: ch(out.clearFoeUps.chance) };
          if (out.boost) out.boost = out.boost.map((x) => ({ ...x, chance: ch(x.chance) }));
          break;
        case "heal":
          if (out.drain !== undefined) out.drain *= f;
          if (out.healAfter) out.healAfter = { ...out.healAfter, f: out.healAfter.f * f };
          if (out.healFlat !== undefined) out.healFlat = Math.round(out.healFlat * f);
          if (out.stealHp) out.stealHp = { ...out.stealHp, n: Math.round(out.stealHp.n * f) };
          for (const x of out.timed) if (x.kind === "regen") {
            if (x.n !== undefined) x.n = Math.round(x.n * f);
            if (x.f !== undefined) x.f *= f;
          }
          break;
        case "resist":
          for (const x of out.timed) if (x.kind === "screen") {
            if (x.phys !== undefined && x.phys < 1) x.phys = Math.max(0, 1 - (1 - x.phys) * f);
            if (x.spec !== undefined && x.spec < 1) x.spec = Math.max(0, 1 - (1 - x.spec) * f);
          }
          break;
        case "hits":
          if (out.hits) out.hits = [out.hits[0], Math.max(out.hits[0], Math.round(out.hits[1] * f))];
          break;
        case "stages":
          for (const x of out.stages) if (!x.self) x.delta = Math.sign(x.delta) * Math.min(6, Math.max(1, Math.round(Math.abs(x.delta) * f)));
          break;
      }
    }
    return out;
  }

  /** A lasting effect's status: one of its statusPick, or of status and statusAlt, at random. */
  private pickStatus(x: Timed): StatusName {
    if (x.statusPick?.length) return x.statusPick[Math.min(x.statusPick.length - 1, Math.floor(this.rng() * x.statusPick.length))];
    return x.statusAlt && this.rng() < 0.5 ? x.statusAlt : x.status!;
  }

  /** A 契约技能's words (满月血脉, 新月血脉): the mount's blow after each attack, its chances. */
  private mountRule(sd: string): { mount: string; extra: number; clearUps: number; guard: number } {
    const m = sd.match(/攻击结束时，(\S+?)额外造成(\d+)点/);
    return {
      mount: m?.[1] ?? "坐骑",
      extra: m ? Number(m[2]) : 0,
      clearUps: Number(sd.match(/(\d+)%概率清空对方增益属性/)?.[1] ?? 0),
      guard: Number(sd.match(/(\d+)%概率保护自身属性/)?.[1] ?? 0),
    };
  }

  /** The mark f has that the words name (古魂: its 星神古魂; 印记: the only one it has). */
  private markKey(f: Fighter, name: string): string {
    const keys = Object.keys(f.stacks ?? {});
    return keys.find((k) => k === name) ?? keys.find((k) => k.endsWith(name) || name.endsWith(k)) ?? (name === "印记" && keys.length === 1 ? keys[0] : name);
  }

  /** Layers of a mark on f (by: the one who gives them: its 每次附带印记时额外多附带N层; f's 每次获得X翻倍). */
  private addStack(f: Fighter, name: string, n: number, lines: string[], by?: Fighter): void {
    if (n <= 0 || f.pet.hp <= 0) return;
    for (const x of live(f, "stackGain")) if (x.mark && sameMark(x.mark, name)) n *= x.mult ?? 1;
    if (by && by !== f) for (const x of live(by, "stackGive")) if (x.mark && sameMark(x.mark, name)) n += x.n ?? 0;
    const st = (f.stacks ??= {});
    const key = Object.keys(st).find((k) => sameMark(k, name)) ?? name;
    st[key] = (st[key] ?? 0) + n;
    lines.push(`${petName(this.t, f)}获得了${n}层${name}！`);
  }

  /** What f's marks set off: at N layers (当X达N层时: its own, or onOther the other's), or under N% of its 体力 (当自身体力低于N%时). */
  private stackChecks(b: Battle, f: Fighter, lines: string[]): void {
    const st = f.stacks ?? {};
    for (const x of live(f, "stackAt")) {
      const on = x.onOther ? this.other(b, f) : f;
      const ost = on.stacks ?? {};
      const key = this.markKey(on, x.mark!);
      const have = ost[key] ?? 0;
      if (have < (x.n ?? 1) || on.pet.hp <= 0) continue;
      ost[key] = x.consume === -1 ? 0 : Math.max(0, have - (x.consume ?? 0));
      lines.push(`${petName(this.t, on)}的${x.mark}发动了！`);
      if (x.then) this.applyThen(b, f, x.then, lines);
    }
    for (const x of live(f, "stackHp")) {
      const key = this.markKey(f, x.mark!);
      if ((st[key] ?? 0) <= 0 || f.pet.hp <= 0 || f.pet.hp >= f.stats[0] * (x.below ?? 0.5)) continue;
      st[key] -= x.consume ?? 1;
      lines.push(`${petName(this.t, f)}消耗了1层${x.mark}！`);
      if (x.then) this.applyThen(b, f, x.then, lines);
    }
  }

  /** The effects a mark sets off, on f (and the other for what is on it). */
  private applyThen(b: Battle, f: Fighter, fx: SkillEffects, lines: string[]): void {
    const o = this.other(b, f);
    for (const c of fx.stages) {
      if (!this.chance(c.chance)) continue;
      const on = c.self ? f : o;
      if (on.pet.hp > 0) this.stage(on, f, c.stats, c.delta, lines);
    }
    for (const r of fx.statuses) if (o.pet.hp > 0 && this.chance(r.chance)) this.applyStatus(o, r.name, lines, r.turns);
    if (fx.healFull) this.heal(f, f.stats[0]);
    if (fx.healAfter && this.chance(fx.healAfter.chance)) this.heal(f, f.stats[0] * fx.healAfter.f);
    if (fx.healFlat) this.heal(f, fx.healFlat);
    if (fx.cure && this.has(f, "any")) {
      this.cureAll(f);
      lines.push(`${petName(this.t, f)}的不良状态都消除了！`);
    }
    if (fx.resetSelf) for (const k of ALL_KEYS) f.stages[k] = 0;
    if (fx.resetFoe && o.pet.hp > 0) for (const k of ALL_KEYS) o.stages[k] = 0;
    if (fx.clearFoeTimed && o.pet.hp > 0 && o.timed.length) {
      o.timed = [];
      lines.push(`${petName(this.t, o)}身上的持续效果被清空了！`);
    }
    if (fx.curse && o.pet.hp > 0 && this.chance(fx.curse.chance)) this.curse(o, lines);
    if (fx.statPts) this.statPoints(f, o, fx.statPts, lines);
    for (const sx of fx.stacks ?? []) for (const on of sx.who === "both" ? [f, o] : [sx.who === "self" ? f : o]) this.addStack(on, sx.name, sx.n, lines, f);
    if (fx.ppRange && o.pet.hp > 0 && this.chance(fx.ppRange.chance)) {
      const n = this.int(fx.ppRange.a, fx.ppRange.b);
      for (const s of o.pet.skills) s.pp = Math.max(0, s.pp - n);
      lines.push(`${petName(this.t, o)}的技能次数减少了！`);
    }
    for (const x of fx.timed) {
      const on = x.who === "foe" ? o : f;
      if (on.pet.hp > 0) on.timed.push({ ...x, left: x.turns, from: x.kind === "state" ? x.mark : "印记" } as Live);
      if (x.kind === "state" && on.pet.hp > 0) lines.push(`${petName(this.t, on)}进入了${x.mark}状态！`);
    }
  }

  /** A 护盾 just broken: what its holder's 当护盾被打破时 effects do. */
  private shieldBroken(b: Battle, f: Fighter, by: Fighter, lines: string[]): void {
    for (const x of live(f, "onbreak")) {
      if (x.stats && x.delta) this.stage(f, f, x.stats, x.delta, lines);
      if (x.status && by.pet.hp > 0) this.applyStatus(by, x.status, lines);
      if (x.then) this.applyThen(b, f, x.then, lines);
    }
  }

  // ---------------------------------------------------------------- 超奥义 (pmdata species ao)

  /** The 超奥义 of the 亚比 fighting (its species' row, the later AoYiConfig.getAoYiSkillId). */
  aoyiOf(f: Fighter): number | undefined {
    const id = speciesOf(this.t, f.pet.race)?.ao;
    return id && this.t.pm.skills[String(id)] ? id : undefined;
  }

  /**
   * Can the player's 亚比 use its 超奥义 now: standing, not used by this 亚比 this battle (每场战斗超奥义
   * 仅可使用一次). Every 亚比 of the line has it (the 工具箱's are whole; the later isGetAoYiSkill came
   * from an activity). Not in a duel.
   */
  canAoyi(b: Battle, f: Fighter): boolean {
    const rec = f.form ? f.form.from : f.pet;
    return f.slot === 0 && !b.duel && f.pet.hp > 0 && !!this.aoyiOf(f) && !(b.aoyiUsed ?? []).includes(rec.id);
  }

  /** It uses its 超奥义 this turn (no PP: once a battle). */
  useAoyi(b: Battle, f: Fighter): void {
    (b.aoyiUsed ??= []).push((f.form ? f.form.from : f.pet).id);
  }

  /** The record kept: the form's share of its 体力, of its own (at least 1 while standing). RECONSTRUCTED. */
  syncForm(f: Fighter): void {
    if (!f.form) return;
    const max = statsOf(f.form.from, this.t)[0];
    f.form.from.hp = f.pet.hp <= 0 ? 0 : Math.max(1, Math.min(max, Math.round((f.pet.hp * max) / Math.max(1, f.stats[0]))));
  }

  /** Back from 究极 (its rounds over, switched out, fallen, the battle over). */
  unchange(f: Fighter): void {
    if (!f.form) return;
    this.syncForm(f);
    const from = f.form.from;
    f.form = undefined;
    f.pet = from;
    f.stats = statsOf(from, this.t);
    f.types = speciesOf(this.t, from.race)?.t ?? f.types;
  }

  // ---------------------------------------------------------------- 圣域 (shengyu.ts)

  fieldRule(b: Battle): FieldRule | undefined {
    return b.sy ? FIELDS[b.sy.id] : undefined;
  }

  private traits(f: Fighter): string[] {
    return (speciesOf(this.t, f.pet.race)?.f ?? "").split("#").filter(Boolean);
  }

  /** What a field does to f (its 上场 or round's-end act): its lines. */
  private fieldAct(b: Battle, f: Fighter, act: FieldAct | undefined, lines: string[]): number {
    if (!act || f.pet.hp <= 0 || !this.chance(act.chance ?? 100)) return 0;
    let hp = 0;
    if (act.status) this.applyStatus(f, act.status, lines);
    if (act.stats?.length) this.stage(f, act.delta! < 0 ? this.other(b, f) : f, act.stats, act.delta ?? 0, lines);
    if (act.heal) hp += this.heal(f, this.int(act.heal[0], act.heal[1]));
    if (act.pp) {
      for (const s of f.pet.skills) s.pp = Math.min(s.max, s.pp + act.pp);
      lines.push(`${petName(this.t, f)}的技能次数增加了！`);
    }
    if (act.guard) {
      f.timed = f.timed.filter((x) => !(x.kind === "guard" && x.from === "君芒"));
      f.timed.push({ who: "self", kind: "guard", turns: act.guard, left: act.guard, from: "君芒" });
      lines.push(`${petName(this.t, f)}的属性等级${act.guard}回合内不会被降低！`);
    }
    return hp;
  }

  /** A field comes out (another goes): the words, and its 上场 act on both 亚比. */
  private makeField(b: Battle, id: string, slot: 0 | 1, lines: string[]): void {
    const w = this.t.pm.weather?.[id];
    if (!FIELDS[id] || b.sy?.id === id) return;
    b.sy = { id, slot, at: b.turn };
    lines.push(`${w?.n ?? "圣域"}圣域降临了！`);
    for (const f of [b.mine, b.wild]) this.fieldAct(b, f, FIELDS[id].enter?.(f.types), lines);
  }

  /** A skill's 召唤X圣域 (一定概率: RECONSTRUCTED, half the time). */
  summonField(b: Battle, att: Fighter, name: string, chance: number, lines: string[]): void {
    const id = fieldByName(this.t.pm.weather, name);
    if (id && this.chance(chance)) this.makeField(b, id, att.slot, lines);
  }

  /** A 亚比 out on the field: its 特性's field comes (else it meets the field's 上场 act). */
  private arrive(b: Battle, f: Fighter, lines: string[]): number {
    f.cameRound = b.turn;
    const own = fieldsOfTrait(speciesOf(this.t, f.pet.race)?.f);
    if (own.length) {
      this.makeField(b, own[0], f.slot, lines);
      return 0;
    }
    return this.fieldAct(b, f, this.fieldRule(b)?.enter?.(f.types), lines);
  }

  /**
   * The 亚比 just come out (the battle's start, a switch, the next of a team): their fields as they
   * arrive, as the later battle brings a 圣域 with its 亚比 (煌炎战神's 天武圣域 the moment it is out,
   * not with its first skill). The words as reports of their own (2421).
   */
  arrivals(b: Battle): Msg[] {
    const out: Msg[] = [];
    this.cur = b;
    for (const f of [b.mine, b.wild]) {
      if (f.pet.hp <= 0 || f.cameRound !== undefined) continue;
      const lines: string[] = [];
      const hp = this.arrive(b, f, lines);
      lines.push(...this.healLines.splice(0));
      if (lines.length) out.push(["2421", { slotId: f.slot, hpInc: hp, desc: lines.join("\n"), pmmList: this.views(b) }]);
    }
    return out;
  }

  /**
   * The start of a round: a 亚比 just out brings its 特性's field (or meets the field's 上场 act);
   * the 自动循环激活 fields of the 亚比 out come back every 5 rounds; 圣武霸体's 体力 comes back; each
   * 亚比's 圣域技能 tries. The words as a report of their own (2421).
   */
  roundStart(b: Battle): Msg[] {
    const out: Msg[] = [];
    this.cur = b;
    this.over.clear();
    for (const f of [b.mine, b.wild]) {
      if (f.pet.hp <= 0) continue;
      const lines: string[] = [];
      let hp = 0;
      const name = petName(this.t, f);
      if (f.hpBack !== undefined) {
        hp += this.heal(f, f.hpBack - f.pet.hp);
        f.hpBack = undefined;
        lines.push(`${name}的体力恢复了！`);
      }
      // 新月血脉: 每回合有N%概率保护自身属性 (this round its levels cannot be lowered).
      const guard = f.form?.qy ? this.mountRule(f.form.qy.sd).guard : 0;
      if (guard && this.chance(guard)) {
        f.timed = f.timed.filter((x) => x.from !== "契约");
        f.timed.push({ who: "self", kind: "guard", turns: 1, left: 1, from: "契约" });
        lines.push(`${name}的属性等级本回合不会被削弱！`);
      }
      const own = fieldsOfTrait(speciesOf(this.t, f.pet.race)?.f);
      if (f.cameRound === undefined) hp += this.arrive(b, f, lines);
      else if (own.length && this.t.pm.weather?.[own[0]]?.k === 3 && b.sy?.id !== own[0] && b.turn > f.cameRound && (b.turn - f.cameRound) % AUTO_EVERY === 0) {
        this.makeField(b, own[0], f.slot, lines);
      }
      const sy = syOf(speciesOf(this.t, f.pet.race)?.sy, f.pet.level);
      // Not again while its state lasts (it came every other round, a report and a pause each time).
      const inSy = !!sy && f.timed.some((x) => x.from === `圣域技能${sy.id}` && x.left > 0);
      if (sy && !inSy && b.sy?.id === sy.rule.field && this.chance(sy.rule.chance)) {
        const r = sy.rule;
        const w = this.t.pm.weather?.[sy.id];
        lines.push(`${name}发动了圣域技能「${w?.n ?? ""}」，进入了${r.state}状态！`);
        if (r.self?.stats) this.stage(f, f, r.self.stats, r.self.deltaMax ? this.int(r.self.delta ?? 1, r.self.deltaMax) : r.self.delta ?? 0, lines);
        if (r.self?.doubleUps) {
          for (const k of Object.keys(f.stages) as StatKey[]) if (f.stages[k] > 0) f.stages[k] = clampStage(f.stages[k] * 2);
          lines.push(`${name}已提升的能力等级翻倍了！`);
        }
        if (r.self?.cure) this.cureAll(f);
        if (r.self?.full) hp += this.heal(f, f.stats[0]);
        if (r.self?.hpOne && f.pet.hp > 1) {
          f.hpBack = f.pet.hp;
          hp -= this.hurt(f, f.pet.hp - 1);
        }
        if (r.foe) this.applyStatus(this.other(b, f), r.foe.status, lines);
        const from = `圣域技能${sy.id}`;
        f.timed = f.timed.filter((x) => x.from !== from);
        for (const x of r.timed ?? []) f.timed.push({ ...x, who: "self", turns: r.turns, left: r.turns, from });
      }
      lines.push(...this.healLines.splice(0));
      if (lines.length) out.push(["2421", { slotId: f.slot, hpInc: hp, desc: lines.join("\n"), pmmList: this.views(b) }]);
    }
    return out;
  }

  private other(b: Battle, f: Fighter): Fighter {
    return f === b.mine ? b.wild : b.mine;
  }

  private has(f: Fighter, s: StatusName | "any"): boolean {
    return hasStatus(f, s);
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
    if ("foeMark" in c) return def.marked.includes(c.foeMark) || layersOf(def, c.foeMark) > 0;
    if ("state" in c) return inState(att, c.state);
    if ("hitsIn" in c) return (ctx.hits ?? 0) >= c.hitsIn[0] && (ctx.hits ?? 0) <= c.hitsIn[1];
    if ("foeSpdLower" in c) return def.stages.spd < att.stages.spd;
    if ("killed" in c) return def.pet.hp <= 0;
    if ("first" in c) return !!att.turn.first;
    if ("dmgOver" in c) return (ctx.dmg ?? 0) > c.dmgOver;
    if ("dmgUnder" in c) return (ctx.dmg ?? 0) < c.dmgUnder;
    if ("field" in c) return !!b.sy && b.sy.id === fieldByName(this.t.pm.weather, c.field);
    if ("noField" in c) return !b.sy || b.sy.id !== fieldByName(this.t.pm.weather, c.noField);
    return false;
  }

  /** What the heals of this act (or turn end) could not give, by fighter: the 回复 is shown whole. */
  private over = new Map<Fighter, number>();

  private heal(f: Fighter, n: number): number {
    // 期间对方增加的体力会被扣除: the heal hurts instead.
    if (n > 0 && live(f, "healHurt").length) return -this.hurt(f, n);
    // 体力回复效果提升N%.
    for (const x of live(f, "healMult")) n *= x.mult ?? 1;
    const want = Math.max(0, Math.floor(n));
    const h = Math.min(Math.max(0, f.stats[0] - f.pet.hp), want);
    f.pet.hp += h;
    if (want > h) this.over.set(f, (this.over.get(f) ?? 0) + want - h);
    if (h > 0) this.onHeal(f, h);
    return h;
  }

  /** The lines of what a heal set off (they go with the next report's words). */
  private healLines: string[] = [];
  private healing = false;

  /** 每次回复体力值时…: what the holder's heal sets off (stages, a 护盾 of the heal, a skill on the other). */
  private onHeal(f: Fighter, h: number): void {
    const b = this.cur;
    if (!b || this.healing || (f !== b.mine && f !== b.wild)) return;
    this.healing = true;
    try {
      const o = this.other(b, f);
      const lines = this.healLines;
      for (const x of live(f, "onheal")) {
        if (!this.chance(x.chance ?? 100)) continue;
        if (x.stats?.length) this.stage(x.selfStage ? f : o, f, x.stats, x.delta ?? 0, lines);
        if (x.f) {
          const pts = Math.floor(h * x.f);
          if (pts > 0) {
            f.armour = (f.armour ?? 0) + pts;
            lines.push(`${petName(this.t, f)}获得了${pts}点护盾！`);
          }
        }
        if (x.then) this.applyThen(b, x.thenOther ? o : f, x.then, lines);
      }
    } finally {
      this.healing = false;
    }
  }

  /** 诅咒 (the later status: 每回合扣除1/4最大体力值, its own words; 3 rounds RECONSTRUCTED); healOther: its damage heals the one who gave it. */
  private curse(f: Fighter, lines: string[], healOther = false): boolean {
    if (f.pet.hp <= 0 || f.timed.some((x) => x.from === "诅咒" && x.left > 0) || live(f, "nostatus").some((x) => !x.only)) return false;
    f.timed.push({ who: "self", kind: "dot", turns: 3, left: 3, f: 1 / 4, from: "诅咒", ...(healOther ? { healOther } : {}) });
    lines.push(`${petName(this.t, f)}被诅咒了！`);
    return true;
  }

  /** Points of the battle values (提升全数值N点, 吸取对方N点双防数值). */
  private statPoints(att: Fighter, def: Fighter, list: NonNullable<SkillEffects["statPts"]>, lines: string[]): void {
    for (const p of list) {
      const on = p.who === "self" ? att : def;
      const label = p.stats.length >= 5 ? "全属性" : p.stats.map((k) => STAT_LABEL[k]).join("和");
      for (const k of p.stats) {
        const i = STAT_INDEX[k as keyof typeof STAT_INDEX];
        if (i === undefined) continue;
        if (p.who === "foe") {
          def.stats[i] = Math.max(1, def.stats[i] - p.n);
          if (p.steal) att.stats[i] += p.n;
        } else on.stats[i] += p.n;
      }
      if (p.who === "foe" && p.steal) lines.push(`${petName(this.t, att)}吸取了${petName(this.t, def)}${p.n}点${label}数值！`);
      else lines.push(`${petName(this.t, on)}的${label}数值${p.who === "foe" ? "降低" : "提升"}了${p.n}点！`);
    }
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
    if (l > 0) f.turn.lostHp = true;
    return l;
  }

  /** A change of stages; false when it could not be made (guarded, locked, at the limit). */
  private stage(f: Fighter, by: Fighter, stats: StatKey[], delta: number, lines: string[], mirrored = false): boolean {
    if (!stats.length || !delta) return false;
    // 金甲风暴: what it raises for itself this round, twice.
    if (delta > 0 && by === f && live(f, "upsTwice").length) delta *= 2;
    const name = petName(this.t, f);
    if (live(f, "lockStages").length) {
      lines.push(`${name}的属性等级不会改变！`);
      return false;
    }
    if (delta > 0 && live(f, "noRise").length) {
      lines.push(`${name}的属性等级无法提升！`);
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
      // Its actions confused: 2 to 3 (or the skill's own turns), each a 1/3 chance of hitting
      // itself; the counter has one more, spent on the action that snaps out of it.
      f.confuse = (n || this.int(2, 3)) + 1;
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
    let fx = parseEffects(sk.d);
    // 下次使用X时… (玩偶之家): this use of X gives its statuses so instead, once.
    const nextUse = att.timed.find((x) => x.kind === "nextUse" && x.left > 0 && x.mark === sk.n);
    if (nextUse?.bad) {
      fx = { ...fx, status: undefined, statuses: [], badStatuses: nextUse.bad };
      nextUse.left = 0;
    }
    // 越…越…: the amounts as things stand now.
    if (fx.scale?.length) fx = this.scaled(att, def, fx, (att.uses[skillId] ?? 0) + 1);
    const foeFirst = !!def.turn.moved;
    att.turn.moved = true;
    att.turn.first = !foeFirst;
    att.turn.damaging = sk.k !== 2 || !!fx.dmg;
    const report = (srt: number, extra: Record<string, unknown> = {}): Msg => {
      // What the heals set off (每次回复体力值时…).
      if (this.healLines.length) lines.push(...this.healLines.splice(0));
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
        { reqSId: att.slot, tarSId: def.slot, id: skillId, name: sk.n, k: sk.k, t: sk.t, ...(sk.ge ? { ge: sk.ge } : {}), self: selfOnly(sk), srt, cri: false, hits: 0, hpInc: 0, selfHpInc: 0, eff: 1, ...shown, desc: lines.join("\n"), pmmList: this.views(b) },
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
      return stopped(`${name}害怕，无法行动！`);
    }
    if (att.status === "睡眠") {
      if (--att.sleep > 0) return stopped(`${name}睡着了，无法行动！`);
      att.status = undefined;
      lines.push(`${name}醒过来了！`);
    } else if (att.status === "冰冻") {
      if (att.statusLeft > 0 ? --att.statusLeft > 0 : !this.chance(20)) return stopped(`${name}被冰冻，无法行动！`);
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
        lines.push(`${name}混乱中攻击了自己！`);
        if (att.pet.hp <= 0) lines.push(`${name}倒下了！`);
        return report(3, { selfHpInc: -dmg });
      }
    }

    // 狂战 (神鬼战场): its 属性技能 of another 属性 fail.
    const rage = live(att, "state").find((x) => x.onlyAttr !== undefined);
    if (rage && sk.k === 2 && sk.t !== rage.onlyAttr) return stopped(`${name}处于${rage.mark}中，无法使用这个技能！`);

    // The PP: one use (卧龙觉醒: more); none for the later turns of a skill kept up or released;
    // twice under 非X系技能使用时消耗PP翻倍 (邪念幻境).
    const known = att.pet.skills.find((s) => s.id === skillId);
    const keptUp = (att.lock && att.lock.id === skillId && att.lock.left > 0) || att.charging === skillId;
    const tax = [att, def].some((F) => live(F, "ppTax").some((x) => x.attr !== sk.t)) ? 2 : 1;
    if (known && !keptUp) known.pp = Math.max(0, known.pp - (fx.ppCost ?? 1) * tax);
    lines.push(`${name}使用了${sk.n}！`);
    const uses = (att.uses[skillId] = (att.uses[skillId] ?? 0) + 1);
    const rolled = att.last === skillId;
    att.last = skillId;
    att.marks[plain(sk.n)] = b.turn + markTurns(sk.d);
    // 技能X效果概率翻倍 (希望曙光状态).
    const dbl = live(att, "state").some((x) => x.doubles === plain(sk.n)) ? 2 : 1;
    const grow = (p: number) => Math.min(100, (fx.grow ? Math.min(100, p * Math.min(3, 1 + (uses - 1) * 0.5)) : p) * dbl);
    // 任意超火系技能均可刷新炽火令的持续回合数.
    if (def !== att) for (const x of def.timed) if (x.refreshAttr !== undefined && x.refreshAttr === sk.t && x.left > 0) x.left = x.turns;
    // 全场使用X技能时则回复自身N点体力值 (邪念幻境).
    for (const F of def === att ? [att] : [att, def]) {
      for (const x of live(F, "useHeal")) if (x.attr === sk.t && F.pet.hp > 0 && this.heal(F, x.n ?? 0) > 0) lines.push(`${petName(t, F)}回复了体力！`);
    }
    // 出手前未受到伤害则引爆X…: the other's mark goes for what it brings.
    if (!att.turn.hurt && def !== att) {
      for (const x of live(att, "beforeAct")) {
        if (!x.mark || layersOf(def, x.mark) <= 0) continue;
        def.stacks![this.markKey(def, x.mark)] = 0;
        lines.push(`${name}引爆了${petName(t, def)}身上的${x.mark}！`);
        if (x.then) this.applyThen(b, att, x.then, lines);
      }
    }

    // BOSS绝杀 (龙态炎王 …: BOSS专有技能，100%秒杀对方全体，无视任何无效效果，不会受到任何反弹伤害，
    // 必定命中): the other falls, and the rest of its side with it (the player's bag, a boss's
    // helpers), whatever guards it (无敌, 免疫, 护盾, 闪避, 保护); nothing comes back.
    if (fx.bossKill && def !== att) {
      const lost = def.pet.hp;
      def.pet.hp = 0;
      def.turn.endure = false;
      def.revive = false;
      lines.push("秒杀！", `${petName(t, def)}倒下了！`);
      const rest = def === b.mine ? (this.bag ?? []).filter((p) => p.hp > 0 && p.id !== (def.form ? def.form.from : def.pet).id) : b.foes ?? [];
      for (const p of rest) p.hp = 0;
      if (def === b.wild) b.foes = [];
      if (rest.length) lines.push(def === b.mine ? "你的亚比全部倒下了！" : "对方的亚比全部倒下了！");
      return report(0, { hpInc: -lost });
    }

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
      lines.push("技能失败了……");
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
      const sure = fx.sure || live(att, "sure").length > 0 || live(def, "exposed").length > 0;
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
      // 攻击全场 (千杀水翔, 爆炎龙卷, 躁动冲撞): the whole field, the user in it too: the same blow
      // on itself, its 属性 against its own.
      if (fx.wholeField && att.pet.hp > 0) {
        const own = sk.t < 0 ? 1 : typeMultiplier(t.pm, sk.t, att.types);
        const d = own > 0 ? this.damage(b, att, att, sk, fx, own, rolled, 0, false).dmg : 0;
        if (d > 0) {
          selfHp -= this.hurt(att, d);
          lines.push(`${name}自己也被波及了！`);
        }
      }
      // 每次暴击均回复…: each crit of a 连击.
      if (fx.critHeal && crits) selfHp += this.heal(att, att.stats[0] * fx.critHeal * crits);
    }

    // PP.
    if (aims && fx.ppFoe && this.holds(fx.ppFoe.cond, b, att, def, ctx) && this.chance(fx.ppFoe.chance)) {
      const n = fx.ppFoe.n;
      const which = fx.ppFoe.last ? def.pet.skills.filter((s) => s.id === def.last) : def.pet.skills;
      for (const s of which) s.pp = n === "all" ? 0 : n === "to1" ? Math.min(s.pp, 1) : Math.max(0, s.pp - n);
      if (which.length) lines.push(`${petName(t, def)}的技能次数减少了！`);
    }
    // 吸取 / 扣除对方全部PP值N~N点: off each skill of the other (back to the user's when stolen).
    if (aims && fx.ppRange && this.holds(fx.ppRange.cond, b, att, def, ctx) && this.chance(fx.ppRange.chance)) {
      const n = this.int(fx.ppRange.a, fx.ppRange.b);
      let taken = 0;
      for (const s of def.pet.skills) {
        const k = Math.min(s.pp, n);
        s.pp -= k;
        taken += k;
      }
      if (taken) lines.push(`${petName(t, def)}的技能次数减少了！`);
      if (fx.ppRange.steal && taken) for (const s of att.pet.skills) s.pp = Math.min(s.max, s.pp + n);
    }
    if (fx.ppSelfAll) for (const s of att.pet.skills) s.pp = 0;
    if (fx.ppSelf && this.chance(fx.ppSelfChance ?? 100)) {
      for (const s of att.pet.skills) s.pp = Math.max(0, Math.min(s.max, s.pp + fx.ppSelf));
      lines.push(fx.ppSelf > 0 ? `${name}的技能次数回复了！` : `${name}的技能次数减少了！`);
    }

    // Statuses.
    let landed = sk.k !== 2 || dmg > 0;
    // 附加N种不良状态: n of them at random.
    if (aims && fx.badStatuses && def.pet.hp > 0 && this.chance(fx.badStatuses.chance)) {
      const pool = [...BAD_STATUSES];
      for (let i = 0; i < fx.badStatuses.n && pool.length; i++) this.applyStatus(def, pool.splice(Math.floor(this.rng() * pool.length), 1)[0], lines);
      landed = true;
    }
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
    // 若对方已X则必定回复: the heal's chance is sure while that holds.
    const sureHeal = !!fx.healSure && this.holds(fx.healSure, b, att, def, ctx);
    if (fx.healFlat && (sureHeal || this.chance(fx.healChance ?? 100))) heal += this.heal(att, fx.healFlat);
    if (fx.healLostIf && (sureHeal || this.chance(fx.healLostIf.chance))) heal += this.heal(att, (att.stats[0] - att.pet.hp) * fx.healLostIf.f);
    if (fx.healFlatIf && this.holds(fx.healFlatIf.cond, b, att, def, ctx)) heal += this.heal(att, fx.healFlatIf.n);
    if (fx.healLost) heal += this.heal(att, (att.stats[0] - att.pet.hp) * fx.healLost);
    // 获得N层X: marks with layers on the user or the other.
    for (const sx of fx.stacks ?? []) {
      for (const on of sx.who === "both" ? (def === att ? [att] : [att, def]) : [sx.who === "self" ? att : def]) if (on.pet.hp > 0) this.addStack(on, sx.name, sx.n, lines, att);
      landed = true;
    }
    if (fx.stacks?.length) this.stackChecks(b, att, lines);
    // 护盾 made by the skill.
    if (fx.makeShield) {
      const ms = fx.makeShield;
      let pts = ms.kind === "n" ? ms.n ?? 0 : ms.kind === "max" ? att.stats[0] * (ms.f ?? 0) : ms.kind === "dmg" ? dmg * (ms.f ?? 1)
        : ms.kind === "hp" ? att.pet.hp * (ms.f ?? 1) : (att.stats[0] - att.pet.hp) * (ms.f ?? 1);
      if (ms.cap) pts = Math.min(pts, ms.cap);
      pts = Math.floor(pts);
      if (pts > 0) {
        att.armour = (att.armour ?? 0) + pts;
        lines.push(`${petName(t, att)}获得了${pts}点护盾！`);
        landed = true;
      }
    }
    // 使对方身上X印记翻倍.
    if (aims && fx.stacksDouble && def !== att) {
      const on = fx.stacksDouble.who === "self" ? att : def;
      const st = on.stacks ?? {};
      const k = Object.keys(st).find((x) => sameMark(x, fx.stacksDouble!.name));
      if (k && st[k] > 0) {
        st[k] *= 2;
        lines.push(`${petName(t, on)}身上的${k}翻倍了！`);
        landed = true;
      }
    }
    // 消耗所有X，每层…: points of values and a heal for each layer (电能填充).
    for (const pl of fx.perLayer ?? []) {
      const n = layersOf(att, pl.name);
      if (n <= 0) continue;
      att.stacks![this.markKey(att, pl.name)] = 0;
      lines.push(`${name}消耗了${n}层${pl.name}！`);
      if (pl.stats && pl.n) this.statPoints(att, def, [{ who: "self", stats: pl.stats, n: pl.n * n }], lines);
      if (pl.healF) heal += this.heal(att, att.stats[0] * pl.healF * n);
      landed = true;
    }
    // 击破X: the other's mark goes; the user's 当X被击破时… come.
    if (aims && fx.breakMark && def !== att && layersOf(def, fx.breakMark) > 0) {
      def.stacks![this.markKey(def, fx.breakMark)] = 0;
      lines.push(`${petName(t, def)}的${fx.breakMark}被击破了！`);
      for (const x of live(att, "markBreak")) {
        if (!x.mark || !sameMark(x.mark, fx.breakMark) || def.pet.hp <= 0) continue;
        shown += this.hurt(def, (def.stats[0] - def.pet.hp) * (x.f ?? 0));
      }
      landed = true;
    }
    // 提升全数值N点 (若击杀对方…), 诅咒, 清空对方身上持续性效果.
    if (fx.statPts && this.holds(fx.statPtsIf, b, att, def, ctx) && (aims || fx.statPts.every((p) => p.who === "self"))) {
      this.statPoints(att, def, fx.statPts, lines);
      landed = true;
    }
    if (aims && fx.curse && def !== att && this.chance(grow(fx.curse.chance)) && this.curse(def, lines)) landed = true;
    if (aims && fx.clearFoeTimed && def !== att && def.timed.length) {
      def.timed = [];
      lines.push(`${petName(t, def)}身上的持续效果被清空了！`);
      landed = true;
    }
    // 斩杀: a foe left with little falls (more for each round the user has been out).
    if (aims && fx.execute && def !== att && def.pet.hp > 0) {
      const n = fx.execute.n + (fx.execute.grow ?? 0) * Math.max(0, b.turn - (att.cameRound ?? b.turn));
      if (def.pet.hp <= n) {
        def.pet.hp = 0;
        lines.push(`${petName(t, att)}斩杀了${petName(t, def)}！`);
        landed = true;
      }
    }
    // 吸取对方N点体力值: off the other, back to the user.
    if (aims && def !== att && fx.stealHp && def.pet.hp > 0 && this.holds(fx.stealHp.cond, b, att, def, ctx)) {
      const l = Math.min(def.pet.hp, fx.stealHp.f ? Math.floor(def.stats[0] * fx.stealHp.f) : fx.stealHp.n);
      def.pet.hp -= l;
      foeHeal -= l;
      lines.push(`${petName(this.t, att)}吸取了${petName(this.t, def)}的体力！`);
      heal += this.heal(att, l);
      landed = true;
    }
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

    // What lasts. A 潜能 or 战界奥义 that gives no turns: the whole battle.
    const whole = sk.ao !== undefined && sk.ao > 0 && !/\d+回合|回合内/.test(sk.d);
    if (!releasing && this.lasting(b, att, def, fx, lines, plain(sk.n), ctx, whole)) landed = true;
    if (aims && fx.trap) def.trapped = Math.max(def.trapped, this.int(fx.trap[0], fx.trap[1]));
    if (aims && fx.forceSwitch && def.pet.hp > 0 && this.chance(fx.forceSwitchChance ?? 100)) {
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
    // 有一定概率召唤X圣域.
    if (fx.summon && att.pet.hp > 0) this.summonField(b, att, fx.summon.name, fx.summon.chance, lines);

    // A skill's background: for its turns (夜之域 3, 星神之域 4), a 战界奥义's while its 亚比 is out.
    const bgKey = backgroundOf(skillId);
    if (bgKey && att.pet.hp > 0) b.bg = { key: bgKey, slot: att.slot, pet: att.pet.id, left: whole ? 999 : markTurns(sk.d) };
    // 契约技能 (满月血脉 / 新月血脉): 每回合攻击结束时，皇犽额外造成N点 (and 满月's chance to clear the
    // other's raised levels), after each of its attacks while it rides.
    if (att.form?.qy && def !== att && sk.k !== 2 && att.pet.hp > 0 && def.pet.hp > 0) {
      const mr = this.mountRule(att.form.qy.sd);
      if (mr.extra > 0) {
        const l = this.hurt(def, mr.extra);
        shown += l;
        lines.push(`${mr.mount}额外造成了${l}点伤害！`);
      }
      if (mr.clearUps && def.pet.hp > 0 && this.chance(mr.clearUps) && ALL_KEYS.some((k) => def.stages[k] > 0)) {
        for (const k of ALL_KEYS) if (def.stages[k] > 0) def.stages[k] = 0;
        lines.push(`${petName(t, def)}的增益属性被清空了！`);
      }
    }
    if (def.pet.hp <= 0 && def !== att) lines.push(`${petName(t, def)}倒下了！`);
    if (att.pet.hp <= 0) lines.push(`${name}倒下了！`);
    const any = landed || sk.k !== 2 || selfHp !== 0 || fx.timed.length > 0 || !!fx.field || fx.protect || !!fx.shield || !!fx.summon || fx.stages.some((x) => x.atEnd);
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
    // 攻击基础数值越高概率越高 (RECONSTRUCTED: a tenth of that value, at most 60%).
    const ohkoIfChance = fx.ohkoIf?.byBase ? Math.min(60, att.stats[STAT_INDEX[fx.ohkoIf.byBase]] / 10) : fx.ohkoIf?.chance ?? 0;
    if (fx.ohkoIf && this.holds(fx.ohkoIf.cond, b, att, def) && (!fx.ohkoIf.lowerLevel || def.pet.level <= att.pet.level) && (fx.ohkoIf.hpBelow === undefined || def.pet.hp < fx.ohkoIf.hpBelow)) ohko = Math.max(ohko, ohkoIfChance);
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
          lines.push("秒杀！");
        }
      }
      if (fx.endeavor) dmg = Math.max(0, def.pet.hp - att.pet.hp);
      if (fx.falseSwipe) dmg = Math.min(dmg, def.pet.hp - 1);
      // def's guards, for this hit (免疫拥有X的亚比的…攻击, 免疫双防数值之和低于我方的亚比技能).
      const dodgeOn = (x: Live) => (!x.ifFoeMark || layersOf(att, x.ifFoeMark) > 0) && (!x.ifWeaker || att.stats[2] + att.stats[4] < def.stats[2] + def.stats[4]);
      if (!fx.pierce && live(def, "dodge").some((x) => kindOk(x) !== undefined && dodgeOn(x) && this.chance(kindOk(x)!))) {
        dodged++;
        continue;
      }
      if (shieldOn) {
        reflect += dmg * sh!.reflect;
        dmg = Math.floor(dmg * sh!.take);
        if (sh!.take === 0) blocked++;
      }
      for (const x of live(def, "screen")) {
        // 提升自身超数码系抗性N%: only blows of that 属性.
        if (x.attr !== undefined && x.attr !== sk.t) continue;
        const f = kindOk(x);
        if (f !== undefined) dmg = Math.floor(dmg * f);
      }
      // 契约's 伤害抗性 (坐骑召唤: 60% at its top 等级) while it rides.
      if (def.form?.qy?.res && !fx.bossKill) dmg = Math.floor((dmg * (100 - def.form.qy.res)) / 100);
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
        // 当护盾被打破时…
        if (def.armour === 0) this.shieldBroken(b, def, att, lines);
      }
      if (dmg > 0 && live(def, "doom").some((x) => this.chance(x.chance ?? 0))) {
        dmg = Math.max(dmg, def.pet.hp);
        lines.push("秒杀！");
      }
      // 圣武霸体: no damage at all; 万王: 王系 免疫100点以下伤害.
      const fl = this.fieldRule(b)?.floor;
      // 免疫N点以下 / 以上伤害 (the later skills).
      const under = live(def, "under").some((x) => dmg <= (x.n ?? 0));
      const over = live(def, "over").some((x) => dmg > (x.n ?? Infinity));
      if (dmg > 0 && (under || over || live(def, "untouchable").length || (fl && def.types.includes(fl.attr) && dmg < fl.n))) {
        blocked++;
        continue;
      }
      if ((def.turn.absorb || live(def, "soak").some((x) => this.chance(x.chance ?? 100))) && dmg > 0) {
        out.foeHeal += this.heal(def, dmg);
        soaked++;
        continue;
      }
      if (def.turn.hold || live(def, "hold").length) dmg = Math.min(dmg, def.pet.hp - 1);
      out.shown += dmg;
      out.list[out.list.length - 1] = dmg;
      const before = def.pet.hp;
      const lost = this.hurt(def, dmg);
      out.dmg += lost;
      if (lost > 0) {
        def.turn.hurt = true;
        if (phys) def.turn.takenPhys = (def.turn.takenPhys ?? 0) + lost;
        if (spec) def.turn.takenSpec = (def.turn.takenSpec ?? 0) + lost;
        if (def.charging !== undefined) def.chargeHurt = true;
      }
      // What comes back, for this hit (霸王之气: 每次受到攻击则返还50点).
      for (const x of live(def, "reflect")) if ((lost > 0 || x.n) && this.chance(x.chance ?? 100)) reflect += x.n ?? lost * (kindOk(x) ?? 0) * (x.byLowHp ? 2 - hpShare(def) : 1);
      // Falls, or comes back.
      if (def.pet.hp <= 0 && def.turn.endure) {
        def.pet.hp = def.stats[0];
        lines.push(`${dn}满状态复活了！`);
      } else if (def.pet.hp <= 0 && def.revive) {
        def.revive = false;
        def.pet.hp = def.stats[0];
        lines.push(`${dn}满状态复活了！`);
      }
      // 受到致命伤害时N%概率触发X: it keeps 1 体力 and X comes.
      if (def.pet.hp <= 0) {
        const fatal = live(def, "onfatal").find((x) => this.chance(x.chance ?? 100));
        if (fatal) {
          def.pet.hp = 1;
          lines.push(`${dn}挺住了致命的伤害！`);
          if (fatal.then) this.applyThen(b, def, fatal.then, lines);
        }
      }
      if (lost <= 0) continue;
      // def's 受到伤害时 effects, each hit.
      if (def.pet.hp > 0) {
        for (const x of live(def, "onhurt")) {
          if (x.minFrac && lost <= def.stats[0] * x.minFrac) continue;
          if (x.minCurFrac && lost < before * x.minCurFrac) continue;
          if (x.below && def.pet.hp >= def.stats[0] * x.below) continue;
          if (x.minLost && lost <= x.minLost) continue;
          if (x.dmgEven && lost % 2 !== 0) continue;
          if (x.onlyKind && !(x.onlyKind === "phys" ? phys : spec)) continue;
          if (x.ifFoeMark && layersOf(att, x.ifFoeMark) <= 0) continue;
          if (x.cap !== undefined && (x.used ?? 0) >= x.cap) continue;
          if (x.useMark) {
            const key = this.markKey(def, x.useMark);
            if (!((def.stacks ?? {})[key] > 0)) continue;
            def.stacks![key]--;
            lines.push(`${dn}消耗了1层${x.useMark}！`);
          }
          // 对方身上印记越多，概率越高: so much for each layer.
          const ch = x.chanceByMark && x.ifFoeMark ? Math.min(100, x.chanceByMark * layersOf(att, x.ifFoeMark)) : (x.chance ?? 100);
          if (!this.chance(ch)) continue;
          x.used = (x.used ?? 0) + 1;
          if (x.hurtN && att.pet.hp > 0) {
            const l = this.hurt(att, x.hurtN);
            out.selfHp -= l;
            lines.push(`${petName(t, att)}受到了${l}点反伤！`);
          }
          if (x.hurtF && att.pet.hp > 0) {
            const l = this.hurt(att, att.stats[0] * x.hurtF);
            out.selfHp -= l;
            lines.push(`${petName(t, att)}受到了${l}点伤害！`);
          }
          if (x.curse && att.pet.hp > 0) this.curse(att, lines, !!x.healOther);
          // 令对方烧伤，冰冻或麻痹: one of them.
          if (x.pool?.length && x.kind === "onhurt" && att.pet.hp > 0) this.applyStatus(att, x.pool[Math.floor(this.rng() * x.pool.length)] as StatusName, lines);
          if (x.selfStack) this.addStack(def, x.selfStack, 1, lines);
          // 元素领域: a random element of its goes for 冰冻 (水), 烧伤 (火) or 麻痹 (雷).
          if (x.elements && att.pet.hp > 0) {
            const st = def.stacks ?? {};
            const ks = Object.keys(st).filter((k) => k.endsWith("元素") && st[k] > 0);
            if (ks.length) {
              const k = ks[Math.floor(this.rng() * ks.length)];
              st[k]--;
              lines.push(`${dn}消耗了1个${k}！`);
              const by: Record<string, StatusName> = { 水元素: "冰冻", 火元素: "烧伤", 雷元素: "麻痹" };
              if (by[k]) this.applyStatus(att, by[k], lines);
            }
          }
          if (x.then) this.applyThen(b, def, x.then, lines);
          if (x.stats?.length) {
            // 每次受到攻击提升任意属性N项: N of them at random.
            let stats = x.stats;
            if (x.pick) {
              const pool = [...stats];
              stats = [];
              while (stats.length < x.pick && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
            }
            this.stage(x.selfStage ? def : att, def, stats, x.deltaMax ? this.int(x.delta ?? 1, x.deltaMax) : x.delta ?? 0, lines);
          }
          if (x.status) {
            const ss = x.bothStatus ? [x.status, x.statusAlt!] : [this.pickStatus(x)];
            for (const st of ss) this.applyStatus(att, st, lines);
          }
          if (x.n) for (const s2 of att.pet.skills) s2.pp = Math.max(0, s2.pp - x.n);
          // 对方每次受到伤害都有N%概率清除提升的属性等级 (光明切割): the holder's own raised stages.
          if (x.clearOwnUps && ALL_KEYS.some((k) => def.stages[k] > 0)) {
            for (const k of ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
            lines.push(`${dn}提升的能力等级被清除了！`);
          }
          if (x.heal) out.foeHeal += this.heal(def, x.heal);
          if (x.rest && att.pet.hp > 0) {
            att.rest = Math.max(att.rest, x.rest);
            att.restFrom = b.turn + 1;
            lines.push(`${petName(t, att)}下回合无法行动！`);
          }
          if (x.ko && att.pet.hp > 0) {
            out.selfHp -= this.hurt(att, att.pet.hp);
            lines.push(`${petName(t, att)}被秒杀了！`);
          }
          if (x.once) x.left = 0;
        }
      }
      // att's 给对方造成伤害时 effects, each hit.
      for (const x of live(att, "hitHeal")) out.selfHp += this.heal(att, x.n ?? 0);
      for (const x of live(att, "onhit")) {
        if (x.ifFoeMark && layersOf(def, x.ifFoeMark) <= 0) continue;
        if (!this.chance(x.chance ?? 0)) continue;
        // 每次攻击带有X的目标则获得一定的护盾并概率回复… / 回复自身【N%最大体力值+N%伤害值】 / 令对方附加X.
        if (x.shieldF) {
          const pts = Math.floor(att.stats[0] * x.shieldF);
          att.armour = (att.armour ?? 0) + pts;
          lines.push(`${petName(t, att)}获得了${pts}点护盾！`);
        }
        if (x.healF || x.healDmg) out.selfHp += this.heal(att, att.stats[0] * (x.healF ?? 0) + lost * (x.healDmg ?? 0));
        if (x.stackFoe && def.pet.hp > 0) this.addStack(def, x.stackFoe, 1, lines, att);
        if (x.n === 1) this.applyStatus(def, "害怕", lines);
        else if (x.n === 2) for (const k of ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
        else if (x.status) this.applyStatus(def, this.pickStatus(x), lines);
        // 圣域技能: stages on each blow (霜锋, 天神, 深洋), 体力 taken (狮王).
        if (x.stats?.length) {
          // 每次攻击提升自己任意N项属性: N of them at random.
          let stats = x.stats;
          if (x.pick) {
            const pool = [...stats];
            stats = [];
            while (stats.length < x.pick && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
          }
          this.stage(x.selfStage ? att : def, att, stats, x.deltaMax ? this.int(x.delta ?? 1, x.deltaMax) : x.delta ?? 0, lines);
        }
        if (x.steal && def.pet.hp > 0) {
          const l = this.hurt(def, x.steal);
          out.dmg += l;
          out.selfHp += this.heal(att, l);
          lines.push(`${petName(t, att)}吸取了${l}点体力！`);
        }
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
      if (mult > 1) lines.push("属性克制！");
      else if (mult < 1) lines.push("属性微弱……");
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
    let fixed = fx.fixed && this.chance(fx.fixedChance ?? 100) ? (fx.fixedMax ? this.int(fx.fixed, fx.fixedMax) : fx.fixed) : 0;
    // 每次使用增加N点固定伤害，最多叠加M点.
    if (fx.fixedGrow) fixed += Math.min(fx.fixedGrow.max, fx.fixedGrow.n * (att.uses[att.last ?? 0] ?? 1));
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
    // 消耗所有X，每层使技能威力提升N: the user's layers of that mark.
    if (fx.stackPower) {
      const key = this.markKey(att, fx.stackPower.name);
      const have = att.stacks?.[key] ?? 0;
      power += fx.stackPower.per * have;
      if (fx.stackPower.consume && have) att.stacks![key] = 0;
    }
    if (fx.powerBySpeed) {
      const r = stat(att, "spd") / stat(def, "spd");
      power *= Math.max(0.5, Math.min(2.5, fx.powerBySpeed === "fast" ? r : 1 / r));
    }
    for (const x of live(att, "power")) {
      if (x.attr !== undefined && x.attr !== sk.t) continue;
      if (x.mult) power *= x.mult;
      if (x.add) power += x.add;
    }
    for (const x of live(att, "ptsEachTurn")) fixed += x.a ?? 0;
    for (const x of live(att, "extra")) {
      if (x.chance === -1) continue;
      if (x.bySpeed) fixed += Math.max(100, 100 - 60 * att.stages.spd);
      else if (x.f) fixed += Math.floor(def.stats[0] * x.f);
      else fixed += x.n ?? (x.a !== undefined ? this.int(x.a, x.b ?? x.a) : 0);
    }
    // 圣域: a 属性's power (天眼 光明系 ×1.4, 天武 神兵系 +100).
    const fr = this.fieldRule(b);
    if (fr?.power && sk.t === fr.power.attr) power = power * (fr.power.mult ?? 1) + (fr.power.add ?? 0);
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
    // 圣域: the damage a 亚比 takes or does by its 属性 / 特性 (幻灵, 森罗, 战王), 圣战's low 体力;
    // a 圣域技能's 2倍伤害 (致命魔炎).
    let field = 1;
    if (fr?.taken) field *= fr.taken(def.types, this.traits(def));
    if (fr?.dealt) field *= fr.dealt(att.types);
    if (fr?.hpBoost) field *= 2 - att.pet.hp / Math.max(1, att.stats[0]);
    for (const x of live(att, "double")) if (this.chance(x.chance ?? 0)) field *= 2;
    const rand = 0.85 + this.rng() * 0.15;
    const dmg = Math.max(1, Math.floor(base * stab * mult * (cri ? 1.5 * (fx.critBoost ?? 1) : 1) * burn * boost * (fx.powerScale ?? 1) * field * rand)) + fixed;
    return { dmg, cri };
  }

  /** The skill's stage changes, and the moves of stages (clear, restore, copy, swap…); true when one was made. */
  private stagesOf(b: Battle, att: Fighter, def: Fighter, fx: SkillEffects, lines: string[], ctx: { crit?: boolean; crits?: number; landed?: boolean; dmg?: number; hits?: number }, grow = (p: number) => p, aims = true): boolean {
    let any = false;
    const toUser = fx.fate === undefined || this.chance(fx.fate);
    let failed = false;
    // 重置…, then the changes (焚羽新生: 重置全场状态，提升全场亚比双防2级): the reset comes first.
    if (fx.resetFoe && aims && def !== att && this.chance(fx.resetFoeChance ?? 100)) for (const k of ALL_KEYS) def.stages[k] = 0;
    if (fx.resetSelf) for (const k of ALL_KEYS) att.stages[k] = 0;
    for (const ch of fx.stages) {
      if (fx.stagesIfCrit && !ctx.crit) continue;
      if (ch.atEnd) {
        (att.endStages ??= []).push(ch);
        continue;
      }
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
        // 随机提升…任意项属性共N级: N single levels at random.
        if (ch.spread) {
          for (let i = 0; i < ch.spread; i++) if (this.stage(f, att, [stats[Math.floor(this.rng() * stats.length)]], ch.delta, lines)) any = true;
          continue;
        }
        let delta = ch.deltaMax !== undefined ? Math.sign(ch.delta) * this.int(Math.abs(ch.delta), Math.abs(ch.deltaMax)) : ch.delta;
        // …或…: half the time the other change, on its own side.
        let on = f;
        if (ch.or && this.rng() < 0.5) {
          on = ch.or.self ? (toUser ? att : def) : def;
          if (!ch.or.self && (!aims || def === att)) continue;
          stats = ch.or.stats;
          delta = ch.or.delta;
        }
        if (fx.stageDouble && this.chance(fx.stageDouble)) delta *= 2;
        if (ch.doubleIf && this.holds(ch.doubleIf, b, att, def, ctx)) delta *= 2;
        const before = stats.map((k) => on.stages[k]);
        if (this.stage(on, att, stats, delta, lines)) {
          any = true;
          // 持续N回合: the change goes when the turns are over.
          if (ch.turns) on.timed.push({ who: "self", kind: "revert", turns: ch.turns, left: ch.turns, stats, deltas: stats.map((k, i) => on.stages[k] - before[i]) });
        }
      }
    }
    if (failed && fx.failCost) {
      this.hurt(att, fx.failCost);
      lines.push(`${petName(this.t, att)}失败了，受到了伤害！`);
    }
    const name = petName(this.t, def);
    if (aims && def !== att) {
      if (fx.clearFoeUps && this.holds(fx.clearFoeUps.cond, b, att, def, ctx) && this.chance(fx.clearFoeUps.chance)) {
        if (fx.copyFoeUps && this.chance(fx.copyFoeUps.chance)) for (const k of ALL_KEYS) if (def.stages[k] > 0) att.stages[k] = clampStage(att.stages[k] + def.stages[k]);
        for (const k of fx.clearFoeUps.stats ?? ALL_KEYS) def.stages[k] = Math.min(0, def.stages[k]);
        lines.push(`${name}提升的能力等级被清除了！`);
        any = true;
      } else if (fx.copyFoeUps && this.chance(fx.copyFoeUps.chance)) {
        for (const k of ALL_KEYS) if (fx.copyAll ? def.stages[k] !== 0 : def.stages[k] > 0) att.stages[k] = clampStage(fx.copyAll ? def.stages[k] : Math.max(att.stages[k], def.stages[k]));
        lines.push(`${petName(this.t, att)}复制了${name}的能力等级！`);
        any = true;
      }
      if (fx.swapStages && this.chance(fx.swapChance ?? 100)) {
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
      if (fx.stealStages && (fx.stealStages.minDmg === undefined || (ctx.dmg ?? 0) > fx.stealStages.minDmg) && this.holds(fx.stealStages.cond, b, att, def, ctx) && this.chance(fx.stealStages.chance ?? 100)) {
        const ss = fx.stealStages;
        // 吸取X外任意属性N级，每在场1回合额外再吸取1次: a random one, once more for each round out.
        const reps = ss.perRound ? 1 + Math.max(0, b.turn - (att.cameRound ?? b.turn)) : 1;
        for (let r = 0; r < reps; r++) {
          let stats = ss.stats;
          if (ss.pick) {
            const pool = [...stats];
            stats = [];
            while (stats.length < ss.pick! && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
          }
          // a~b级: so many at random; 若暴击则吸取效果翻倍.
          let d = ss.deltaMax !== undefined ? this.int(ss.delta, ss.deltaMax) : ss.delta;
          if (ss.doubleIf && this.holds(ss.doubleIf, b, att, def, ctx)) d *= 2;
          for (const k of stats) {
            def.stages[k] = clampStage(def.stages[k] - d);
            att.stages[k] = clampStage(att.stages[k] + d);
          }
        }
        if (ss.pick) lines.push(`${petName(this.t, att)}吸取了${name}的能力等级！`);
        any = true;
      }
    }
    if (fx.clearBothUps) for (const f of [att, def]) for (const k of ALL_KEYS) f.stages[k] = Math.min(0, f.stages[k]);
    if (fx.resetStats) for (const f of [att, def]) for (const k of fx.resetStats) f.stages[k] = 0;
    // 倒置: the stages turned over (all, or the raised / lowered ones).
    if (fx.invert) {
      const turn = (f: Fighter, w: "all" | "up" | "down" | undefined) => {
        if (!w) return;
        for (const k of ALL_KEYS) if (w === "all" || (w === "up" ? f.stages[k] > 0 : f.stages[k] < 0)) f.stages[k] = -f.stages[k];
        lines.push(`${petName(this.t, f)}的能力等级倒置了！`);
      };
      turn(att, fx.invert.self);
      if (def !== att) turn(def, fx.invert.foe);
      any = true;
    }
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
  private lasting(b: Battle, att: Fighter, def: Fighter, fx: SkillEffects, lines: string[], from: string, ctx: { crit?: boolean; landed?: boolean; dmg?: number; hits?: number } = {}, whole = false): boolean {
    let any = false;
    const toUser = fx.fate === undefined || this.chance(fx.fate);
    // Two effects of one kind from this one use both stay (吸取双防 and 清除增益, both on a burn).
    const placed = new Set<Live>();
    for (const x of fx.timed) {
      if (x.placeIf && !this.holds(x.placeIf, b, att, def, ctx)) continue;
      const holders = x.who === "both" ? [att, def] : x.who === "self" ? [toUser ? att : def] : def === att ? [] : [def];
      for (const f of holders) {
        if (f.pet.hp <= 0) continue;
        // 不能和“X”同时存在: X's effects go.
        if (fx.exclusiveWith) f.timed = f.timed.filter((y) => y.from !== fx.exclusiveWith);
        // The same effect again from the same skill: its turns start over (不可叠加); one that
        // stacks (可以叠加使用，最多叠加N次) adds another, the oldest going past the most.
        const same = (y: Live) => !placed.has(y) && y.from === from && y.kind === x.kind && y.attr === x.attr && y.left > 0 && y.n === x.n && y.f === x.f && y.mult === x.mult && y.status === x.status;
        if (x.stack) {
          const old = f.timed.filter(same);
          if (old.length >= x.stack) f.timed.splice(f.timed.indexOf(old[0]), 1);
        } else f.timed = f.timed.filter((y) => !same(y));
        const y: Live = { ...x, from, left: whole ? 99 : x.turnsMin !== undefined ? this.int(x.turnsMin, x.turns) : x.turns };
        if (whole) y.turns = 99;
        if (y.flip) this.flip(y);
        f.timed.push(y);
        placed.add(y);
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
      // Marks with layers: those gained each round (on either 亚比; one of a pool), those of a round
      // it was hurt in, and what comes at N layers or low 体力.
      for (const x of live(f, "stackEachTurn")) {
        const one = x.eitherSide && o.pet.hp > 0 && this.rng() < 0.5 ? o : f;
        const mark = x.pool ? x.pool[Math.floor(this.rng() * x.pool.length)] : x.mark!;
        for (const on of x.bothSides && o.pet.hp > 0 ? [f, o] : [one]) this.addStack(on, mark, this.int(x.a ?? 1, x.b ?? x.a ?? 1), lineOf.get(on)!, f);
      }
      for (const x of live(f, "hurtStack")) if (f.turn.hurt) this.addStack(f, x.mark!, x.n ?? 1, lines);
      // 神圣考验: what the round brought decides.
      for (const ch of f.endStages ?? []) {
        if (ch.cond && "hurt" in ch.cond && !!f.turn.hurt !== ch.cond.hurt) continue;
        if (this.chance(ch.chance)) this.stage(f, f, ch.stats, ch.delta, lines);
      }
      f.endStages = undefined;
      this.stackChecks(b, f, lines);
      if (f.pet.hp > 0 && o.pet.hp > 0 && live(o, "stackAt").some((x) => x.onOther)) this.stackChecks(b, o, lineOf.get(o)!);
      // 每回合概率进入X状态 / 每N回合再触发1次 / 使X的技能在回合末概率再触发1次.
      for (const x of live(f, "stateEachTurn")) if (x.then && this.chance(x.chance ?? 100)) this.applyThen(b, f, x.then, lines);
      for (const x of live(f, "every")) {
        const el = x.turns - x.left;
        if (el > 0 && x.n && el % x.n === 0 && x.then) {
          lines.push(`${name}的${x.from ?? ""}效果再次触发了！`);
          this.applyThen(b, f, x.then, lines);
        }
      }
      for (const x of live(f, "echo")) {
        if (!f.turn.moved || f.last === undefined || !x.mark) continue;
        const used = this.skill(f.last);
        if (!plain(used.n).startsWith(x.mark) || !this.chance(x.chance ?? 100)) continue;
        lines.push(`${used.n}再次触发了！`);
        this.applyThen(b, f, parseEffects(used.d), lines);
      }
      // 对方每次受到X伤害则… (ontick): what comes each time X hurts it.
      const tick = (st: StatusName) => {
        for (const x of f.timed) {
          if (x.kind !== "ontick" || x.left <= 0 || x.status !== st || f.pet.hp <= 0 || !this.chance(x.chance ?? 100)) continue;
          const delta = x.deltaMax !== undefined ? Math.sign(x.delta ?? 0) * this.int(Math.abs(x.delta ?? 0), Math.abs(x.deltaMax)) : (x.delta ?? 0);
          if (x.stealStats && x.stats) {
            for (const k of x.stats) {
              f.stages[k] = clampStage(f.stages[k] - delta);
              o.stages[k] = clampStage(o.stages[k] + delta);
            }
            lines.push(`${petName(this.t, o)}吸取了${name}的能力等级！`);
          } else if (x.stats) this.stage(x.selfStage ? f : o, o, x.stats, delta, lines);
          if (x.clear && ALL_KEYS.some((k) => f.stages[k] > 0)) {
            for (const k of ALL_KEYS) f.stages[k] = Math.min(0, f.stages[k]);
            lines.push(`${name}提升的能力等级被清除了！`);
          }
          if (x.a !== undefined) {
            const n = this.int(x.a, x.b ?? x.a);
            for (const s of f.pet.skills) s.pp = Math.max(0, s.pp - n);
            lines.push(`${name}的技能次数减少了！`);
          }
          if (x.anyStatus) this.applyStatus(f, BAD_STATUSES[Math.floor(this.rng() * BAD_STATUSES.length)], lines);
          // 并自身添加1层朱雀之印: on the one who gave it.
          if (x.selfStack && o.pet.hp > 0) this.addStack(o, x.selfStack, x.n ?? 1, lineOf.get(o)!);
        }
      };
      // 自己造成的不良状态造成伤害值的N%转化回复自己 (自然之魂): the other heals by the hurt its statuses do.
      const fed = (l: number) => {
        for (const x of live(o, "statusHeal")) if (o.pet.hp > 0 && l > 0) gain(o, l * (x.f ?? 1), `${petName(this.t, o)}回复了体力！`);
      };
      if (f.status === "烧伤" || f.status === "中毒") {
        fed(lose(f, Math.max(1, max / 8), `${name}受到了${f.status === "烧伤" ? "烧伤" : "毒"}的伤害！`));
        tick(f.status);
      }
      if (f.status === "冰冻") tick("冰冻");
      // 烈焰圣域: a burn's damage costs 1 PP of each skill too.
      if (f.status === "烧伤" && this.fieldRule(b)?.burnPP) {
        for (const s of f.pet.skills) s.pp = Math.max(0, s.pp - 1);
        lines.push(`${name}的技能次数减少了！`);
      }
      if (f.weak > 0) {
        fed(lose(f, Math.max(1, (max * Math.min(8, f.weak)) / 16), `${name}受到了衰弱的伤害！`));
        tick("衰弱");
        f.weak++;
        if (f.weakLeft && --f.weakLeft === 0) {
          f.weak = 0;
          lines.push(`${name}不再衰弱了！`);
        }
      }
      if (f.seeded && o.pet.hp > 0) {
        const l = lose(f, Math.max(1, max / 8), `${name}被吸取了体力！`);
        gain(o, l);
        fed(l);
        tick("寄生");
      }
      if (f.bind > 0) {
        f.bind--;
        fed(lose(f, Math.max(1, max / 16), f.bind > 0 ? `${name}受到了束缚的伤害！` : `${name}挣脱了束缚！`));
        tick("束缚");
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
        // Waiting on a state, a status or a mark: it does nothing this round, but lasts.
        if (!active(f, x)) continue;
        switch (x.kind) {
          case "regen":
            if (this.chance(x.chance ?? 100)) gain(f, x.n ?? (x.a !== undefined ? this.int(x.a, x.b ?? x.a) : x.lost ? (max - f.pet.hp) * (x.f ?? 0) : max * (x.f ?? 0)), `${name}回复了体力！`);
            break;
          case "leech": {
            if (x.attr !== undefined && f.types.includes(x.attr)) break;
            const l = lose(f, x.n ?? (x.cur ? f.pet.hp : max) * (x.f ?? 0), `${name}被吸取了体力！`);
            if (o.pet.hp > 0) gain(o, l, `${petName(this.t, o)}回复了体力！`);
            break;
          }
          case "dot":
            // 对冰系亚比无效.
            if (x.attr !== undefined && f.types.includes(x.attr)) break;
            if (this.chance(x.chance ?? 100)) {
              const l = lose(f, x.n ?? (x.a !== undefined ? this.int(x.a, x.b ?? x.a) : max * (x.f ?? 0)), x.from === "诅咒" ? `${name}受到了诅咒的伤害！` : `${name}受到了伤害！`);
              if (l > 0 && o.pet.hp > 0) {
                // 将诅咒造成的伤害值用于回复自身 / 将炽火令燃烧伤害的2倍转化为自身体力值.
                if (x.healOther) gain(o, l, `${petName(this.t, o)}回复了体力！`);
                for (const y of live(o, "dotHeal")) if (y.mark && x.from && sameMark(x.from, y.mark)) gain(o, l * (y.mult ?? 1), `${petName(this.t, o)}回复了体力！`);
              }
            }
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
            // 随机…任意项属性共N级 (魔·啸傲): N single levels at random; its 魔龙之印 make it likelier.
            if (x.spread && x.stats && this.chance((x.chance ?? 100) + (x.markChance ? 10 * layersOf(f, x.markChance) : 0))) {
              for (let i = 0; i < x.spread; i++) this.stage(f, f, [x.stats[Math.floor(this.rng() * x.stats.length)]], x.delta ?? 1, lines);
              break;
            }
            if (x.spread) break;
            if (this.chance(x.chance ?? 100) && x.stats) {
              let stats = x.stats;
              if (x.pick) {
                const pool = [...stats];
                const want = x.pickMax ? this.int(x.pick, x.pickMax) : x.pick;
                stats = [];
                while (stats.length < want && pool.length) stats.push(pool.splice(Math.floor(this.rng() * pool.length), 1)[0]);
              }
              const d = x.deltaMax !== undefined ? Math.sign(x.delta ?? 0) * this.int(Math.abs(x.delta ?? 0), Math.abs(x.deltaMax)) : (x.delta ?? 0);
              // 当速度等级削至最低时则效果变为N%概率令对方诅咒.
              if (x.atMinCurse !== undefined && d < 0 && stats.every((k) => f.stages[k] <= -6)) {
                if (this.chance(x.atMinCurse)) this.curse(f, lines);
                break;
              }
              this.stage(f, d < 0 ? o : f, stats, d, lines);
            }
            break;
          case "ptsEachTurn":
            // 每回合提升技能固伤N点和速度N点: the points stay; the fixed damage grows (counted by damage()).
            if (x.stats && x.n) this.statPoints(f, o, [{ who: "self", stats: x.stats, n: x.n }], lines);
            if (x.add) x.a = (x.a ?? 0) + x.add;
            break;
          case "stealEachTurn":
            // 每回合吸取抵抗能力N%: N% more resistance for the holder, N% less for the other, for the turns left.
            if (x.f && o.pet.hp > 0) {
              f.timed.push({ who: "self", kind: "screen", turns: x.left, left: x.left, phys: 1 - x.f, spec: 1 - x.f, from: "吸取抵抗" });
              o.timed.push({ who: "self", kind: "screen", turns: x.left, left: x.left, phys: 1 + x.f, spec: 1 + x.f, from: "吸取抵抗" });
              lines.push(`${name}吸取了${petName(this.t, o)}的伤害抵抗能力！`);
            }
            if (x.stats && o.pet.hp > 0 && this.chance(x.chance ?? 30)) {
              for (const k of x.stats) {
                o.stages[k] = clampStage(o.stages[k] - (x.delta ?? 1));
                f.stages[k] = clampStage(f.stages[k] + (x.delta ?? 1));
              }
              lines.push(`${name}吸取了${petName(this.t, o)}的能力等级！`);
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
          case "ppdrain": {
            const n = x.a !== undefined ? this.int(x.a, x.b ?? x.a) : (x.n ?? 1);
            for (const s of f.pet.skills) s.pp = Math.max(0, s.pp - n);
            lines.push(`${name}的技能次数减少了！`);
            break;
          }
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
            if (x.status && this.chance(x.chance ?? 0)) this.applyStatus(f, this.pickStatus(x), lines);
            break;
        }
      }
      // The field's round's-end act on this 亚比 (阳炎's burns, 森罗's heal, 洪流's 速度 …).
      const fr = this.fieldRule(b);
      if (fr?.end && f.pet.hp > 0) {
        const h = this.fieldAct(b, f, fr.end(f.types, this.traits(f)), lines);
        if (h > 0) {
          lostOf.set(f, (lostOf.get(f) ?? 0) + h);
          lines.push(`${name}回复了体力！`);
        }
      }
      // What its heals set off.
      lines.push(...this.healLines.splice(0));
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
      else if (d.kind === "hpTo1") {
        if (this.chance(d.chance ?? 100)) lose(f, f.pet.hp - 1, `${name}的体力只剩1点了！`);
      }
    }
    if (b.delayed) b.delayed = b.delayed.filter((d) => d.left >= 0);
    // An activity boss's trait (Battle.boss).
    if (b.boss && b.wild.pet.hp > 0) {
      const foe = petName(this.t, b.wild);
      if (b.boss.healFrac) gain(b.wild, b.wild.stats[0] * b.boss.healFrac, `${foe}恢复了部分体力！`);
      if (b.boss.killEvery && (b.turn + 1) % b.boss.killEvery === 0 && b.mine.pet.hp > 0) {
        lose(b.mine, b.mine.pet.hp, `${foe}秒杀了${petName(this.t, b.mine)}！`);
      }
    }
    // 每当自身体力流失，则回合末提升自身X技能威力N% (曹魏武王): for the rest of the battle.
    for (const f of [b.mine, b.wild]) {
      if (f.pet.hp <= 0 || !f.turn.lostHp) continue;
      for (const x of live(f, "hurtPower")) {
        f.timed.push({ who: "self", kind: "power", turns: 99, left: 100, mult: x.mult, attr: x.attr, from: "体力流失" });
        lineOf.get(f)!.push(`${petName(this.t, f)}的技能威力提升了！`);
      }
    }
    // Turns run out.
    for (const f of [b.mine, b.wild]) {
      for (const x of f.timed) {
        if (x.left > 0) x.left--;
        // 效果结束时，引爆对方全场X…: when it runs out, the other's mark goes for what it brings.
        if (x.left <= 0 && x.kind === "fuse" && x.then && x.mark && f.pet.hp > 0) {
          const o = this.other(b, f);
          if (o.pet.hp > 0 && layersOf(o, x.mark) > 0) {
            o.stacks![this.markKey(o, x.mark)] = 0;
            lineOf.get(f)!.push(`${petName(this.t, f)}引爆了${petName(this.t, o)}身上的${x.mark}！`);
            this.applyThen(b, f, x.then, lineOf.get(f)!);
          }
        }
        // A stage change that lasted its turns goes.
        if (x.left <= 0 && x.kind === "revert" && x.stats && x.deltas) {
          x.stats.forEach((k, i) => (f.stages[k] = clampStage(f.stages[k] - (x.deltas![i] ?? 0))));
          lineOf.get(f)!.push(`${petName(this.t, f)}的能力等级恢复了。`);
        }
      }
      f.timed = f.timed.filter((x) => x.left > 0);
    }
    // A skill's background goes with its turns, or with the 亚比 that made it.
    if (b.bg) {
      const by = b.bg.slot === 0 ? b.mine : b.wild;
      if (--b.bg.left <= 0 || by.pet.id !== b.bg.pet || by.pet.hp <= 0) b.bg = undefined;
    }
    if (b.field && --b.field.left <= 0) {
      b.field = undefined;
      lineOf.get(b.mine)!.push("场地的力量消失了。");
    }
    // 究极's rounds (not the round it changed in): over, back to its own form.
    for (const f of [b.mine, b.wild]) {
      if (!f.form || f.pet.hp <= 0) continue;
      if (f.form.fresh) f.form.fresh = false;
      else if (--f.form.left <= 0) {
        const was = petName(this.t, f);
        this.unchange(f);
        lineOf.get(f)!.push(`${was}的究极结束了，变回了${petName(this.t, f)}。`);
      }
    }
    lineOf.get(b.mine)!.push(...this.healLines.splice(0));
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
    const pre = this.roundStart(b);
    if (b.mine.pet.hp <= 0 || b.wild.pet.hp <= 0) return pre;
    // Out of PP, the computer's 亚比 takes a 高级活力豆 (items before skills); the player's skill comes after.
    if (this.needsBean(b.wild)) {
      const out: Msg[] = [...pre, this.useBean(b, b.wild)];
      if (b.mine.pet.hp > 0 && b.wild.pet.hp > 0) out.push(this.act(b, b.mine, b.wild, mySkill));
      return out;
    }
    const wildSkill = this.wildChoice(b);
    const first = this.firstMover(b, mySkill, wildSkill);
    const second = first === b.mine ? b.wild : b.mine;
    // The one moving second: does it use a damaging skill (冷月寒霜)?
    const secondSkill = this.skill(this.choice(second, second === b.mine ? mySkill : wildSkill));
    second.turn.damaging = secondSkill.k !== 2 || !!parseEffects(secondSkill.d).dmg;
    const out: Msg[] = [...pre, this.act(b, first, second, first === b.mine ? mySkill : wildSkill)];
    if (first.pet.hp > 0 && second.pet.hp > 0) out.push(this.act(b, second, first, second === b.mine ? mySkill : wildSkill));
    return out;
  }

  /** The wild 亚比 alone acts (after an item, a failed catch or a switch). */
  wildTurn(b: Battle): Msg[] {
    this.startTurn(b);
    if (b.wild.pet.hp <= 0 || b.mine.pet.hp <= 0) return [];
    const pre = this.roundStart(b);
    if (b.wild.pet.hp <= 0 || b.mine.pet.hp <= 0) return pre;
    if (this.needsBean(b.wild)) return [...pre, this.useBean(b, b.wild)];
    return [...pre, this.act(b, b.wild, b.mine, this.wildChoice(b))];
  }

  /**
   * The computer's 亚比 (wild ones, bosses, 副本, 时空隧道, quests, 道馆) with no PP left on any
   * skill: it has 高级活力豆 without end (RECONSTRUCTED: the 2013 server's rule is lost), so it
   * never falls back on 挣扎. Not when a skill goes on by itself (蓄力, 连续攻击: no PP needed).
   */
  needsBean(f: Fighter): boolean {
    return f.pet.skills.length > 0 && f.pet.skills.every((s) => s.pp <= 0) && this.forcedOf(f) === undefined;
  }

  /** It takes a 高级活力豆 (104: 可恢复战斗中的亚比技能使用次数20次): its turn goes on it. The 2412 report. */
  useBean(b: Battle, f: Fighter): Msg {
    for (const s of f.pet.skills) s.pp = Math.min(s.max, s.pp + PP_BEANS[BEAN]);
    const name = petName(this.t, f);
    return ["2412", { reqSId: f.slot, itemId: BEAN, res: 1, hpInc: 0, desc: `${name}使用了高级活力豆！\n${name}的技能次数回复了！`, pmmList: this.views(b) }];
  }

  /** PlayerBattleInfo of both sides. */
  views(b: Battle, bag?: PetRecord[], owner?: PetOwner): Record<string, unknown>[] {
    return [this.view(b, 0, bag, owner), this.view(b, 1)];
  }

  bag?: PetRecord[];
  ownerRef?: PetOwner;

  view(b: Battle, slot: 0 | 1, bag = this.bag, owner = this.ownerRef): Record<string, unknown> {
    const f = slot === 0 ? b.mine : b.wild;
    // Beside the era's: 诅咒 and the states of the later skills (风暴, 巨大化, 狂战 …).
    const states = [...new Set(f.timed.filter((x) => x.kind === "state" && x.left > 0 && x.mark).map((x) => x.mark!))];
    const cursed = f.timed.some((x) => x.from === "诅咒" && x.left > 0) ? "诅咒" : "";
    const st = [f.status, f.confuse > 0 ? "混乱" : "", f.bind > 0 ? "束缚" : "", f.fear > 0 ? "害怕" : "", f.weak > 0 ? "衰弱" : "", f.seeded ? "寄生" : "", cursed, ...states, f.armour ? `护盾${f.armour}` : ""].filter(Boolean).join(",");
    // Each 异常状态 with the rounds (or actions) it has left, 0 when it lasts till cured: the
    // battle screen's icons and their tips (剩余持续回合数).
    const sts: [string, number][] = [];
    if (f.status) sts.push([f.status, f.status === "睡眠" ? Math.max(0, f.sleep - 1) : f.status === "冰冻" ? Math.max(0, f.statusLeft - 1) : f.statusLeft]);
    if (f.confuse > 0) sts.push(["混乱", Math.max(0, f.confuse - 1)]);
    if (f.bind > 0) sts.push(["束缚", f.bind]);
    if (f.fear > 0) sts.push(["害怕", f.fear]);
    if (f.weak > 0) sts.push(["衰弱", f.weakLeft ?? 0]);
    if (f.seeded) sts.push(["寄生", 0]);
    const curse = f.timed.find((x) => x.from === "诅咒" && x.left > 0);
    if (curse) sts.push(["诅咒", curse.left]);
    const forced = this.forcedOf(f);
    const list = slot === 0 && bag ? [f.pet, ...bag.filter((p) => p.id !== f.pet.id)] : [f.pet];
    const own = { id: f.owner };
    const j = slot === 0 ? this.jiujiOf(f) : undefined;
    const ao = slot === 0 ? this.aoyiOf(f) : undefined;
    const w = b.sy ? this.t.pm.weather?.[b.sy.id] : undefined;
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
        // Not 2013 fields: 究极 (can change now, the form's rounds left, used) and the 圣域 out.
        // A 契约 (k 2): its 契约技能's name and words, and no rounds (the whole battle).
        ...(j ? { jj: { can: this.canChange(b, f), left: f.form?.left ?? 0, to: j.to, from: f.form ? f.form.from.race : f.pet.race, wait: this.chargeLeft(b, f), ...(j.k === 2 && j.qy ? { k: 2, on: !!f.form, sn: j.qy.sn, sd: j.qy.sd, qd: j.qy.d } : {}) } } : {}),
        // Not a 2013 field: the 超奥义 (its skill, name, type, power, words, used).
        ...(ao ? { ao: { id: ao, n: this.skill(ao).n, t: this.skill(ao).ao ?? 0, p: this.skill(ao).p, d: this.skill(ao).d, used: !this.canAoyi(b, f) } } : {}),
        ...(b.sy ? { sy: { id: b.sy.id, n: w?.n ?? "", d: w?.d ?? "" } } : {}),
        // Not a 2013 field: the background a skill of this side's 亚比 brought (夜之域, 战界奥义).
        ...(b.bg && b.bg.slot === slot && f.pet.id === b.bg.pet && f.pet.hp > 0 ? { bg: b.bg.key } : {}),
        pmList: list.map((p) => briefOf(p, own, this.t, p === f.pet ? { st, sts, bal: balOf(f.stages), hpAdd: f.form?.up[0] } : undefined)),
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
/** 高级活力豆, which the computer's 亚比 take when out of PP. */
const BEAN = 104;
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
  /** A fair server (the 工具箱 closed): the levels a client asks are bounded (FAIR_ABOVE). */
  fair?: boolean;
  /** The automated walk-throughs' test commands (?dev=1). Never on for players. */
  dev?: boolean;
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
 * An activity's fight of PetClient2.startFight (54_22 {type, …}), added by the activity's own module
 * (sevenstar.ts …): the opponent (species and level; asked, the boss's id the panel knows it by, for
 * its films), what a win or a loss brings (t: the tables, for 亚比 given at once). A string refuses
 * the fight with that message.
 */
export interface ActFight {
  race: number;
  level: number;
  asked?: number;
  onWin?: (o: PetOwner, t: PetTables) => Msg[];
  onLose?: (o: PetOwner, t: PetTables) => Msg[];
  /** The battle made, before it is sent (a blessing on the player's 亚比). */
  adjust?: (b: Battle) => void;
  /** 亚比 that come out one after another when the first falls (an activity boss's helpers). */
  team?: { race: number; level: number }[];
  /** The boss's trait (Battle.boss). */
  boss?: Battle["boss"];
}
export type ActFightSpec = (ctx: XtContext, o: PetOwner, t: PetTables) => Promise<ActFight | string> | ActFight | string;
const ACT_FIGHTS = new WeakMap<World, Map<number, ActFightSpec>>();

/** An activity's fight type for 54_22 (the activity modules install theirs). */
export function addActFight(world: World, type: number, spec: ActFightSpec): void {
  let m = ACT_FIGHTS.get(world);
  if (!m) ACT_FIGHTS.set(world, (m = new Map()));
  m.set(type, spec);
}
const HANDLER_FIGHTS = new WeakMap<World, Map<string, ActFightSpec>>();
/**
 * A fight of the activity panels of 2013 that start type 99 with the activity's handler
 * ({handler: "BW0118"}, {handler: "holiday.NWKChallenge", t, id}): each module adds its own.
 */
export function addHandlerFight(world: World, handler: string, spec: ActFightSpec): void {
  let m = HANDLER_FIGHTS.get(world);
  if (!m) {
    const all = (m = new Map());
    HANDLER_FIGHTS.set(world, all);
    addActFight(world, 99, (ctx, o, t) => {
      const h = all.get(String(ctx.params.handler ?? ""));
      return h ? h(ctx, o, t) : "这个挑战现在还不能进行哦！";
    });
  }
  m.set(handler, spec);
}
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
  // 多古拉伯爵 (the 万圣节守护者 of October 2012, at 奥拉之树): two forms, levels RECONSTRUCTED.
  ["11267,21267", "80,100"],
  // 猎空 (银河冠军擂台, August 2013, asked for by players): the later BossTimeHelper's forms and levels.
  ["31697,21697,11697", "60,80,100"],
  // 蓝羽灵者 (迷境花园, January 2013): three forms fought from its panel (RECONSTRUCTED levels).
  ["31394,21394,11394", "60,80,100"],
];

/** The 亚比 whose skill film the game has (petlearning/petlearning<race>: 艾尔利克 192 and 230). */
/**
 * The films of petlearning<race> and the one skill each teaches (Pet192LearnSkillPanel.skillId;
 * 艾尔利克's from the quest that opens its film, Task1417Initialler: learnSkill(230, 10224)).
 */
const FILM_SKILLS: Record<number, number> = { 192: 11244, 230: 10224 };

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
 * 猎空's last form gives the 猎空亚比蛋 (1696, of the August 2013 PetEggData: it hatches 猎小空), its
 * line being later than the species table the eggs are looked up in.
 */
export const BOSS_EGGS: Record<number, number> = { 11516: 520, 31394: 0, 21394: 0, 11394: 1393, 11697: 1696 };

/**
 * Bosses whose 亚比蛋 comes only with the first win of their last form, as their panels say: 蓝羽灵者
 * (“首次战胜就可以获得它哦”, the 小羽灵蛋 1393), 友人契约书 (“首次战胜友人契约书就可以获得亚比蛋”) and
 * 岩波斗魂者 (“首次战胜岩波斗魂者就可以获得亚比蛋”); their marks are then in 54_19's list.
 */
const FIRST_WIN_ONLY = new Set([11394, 11259, 31213]);

/**
 * Bosses' marks in 54_19's list once beaten: 友人契约书's panel shows the egg as got when "1257" is in
 * it, 岩波斗魂者's (dailyactivity/stonebosspanel) when "1211" (its egg) is, after its last form, 31213;
 * 猎空's (dailyactivity/bosspanel/shikarskybosspanel) shows 已战胜 when "1695" is.
 */
const BOSS_MARKS: Record<number, number> = { 11259: 1257, 31213: 1211, 11394: 1393, 11697: 1695 };

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

/**
 * The eggs of 守护者 the January 2013 PetEggData lacks, as the February and August 2013 ones have
 * them (年兽, 极速威锋, 赤魔导士, 猪猪超人, 翡冷翠亚比蛋): without them a win over those bosses brought
 * nothing. The client adds the same rows (rebuild control LaterEggs); they are not sold (materials).
 * 猎空's (1696, it hatches 猎小空) is given by BOSS_EGGS.
 */
export const LATER_EGGS = [491, 631, 795, 883, 994];

/** The 亚比蛋 of the 2013 PetEggData (materials type 5): egg N hatches race N, the first form of a line. */
export const EGG_IDS = new Set([
  13, 37, 64, 73, 79, 82, 85, 88, 91, 94, 97, 100, 103, 106, 109, 112, 127, 130, 178, 193, 253, 265, 267, 276, 282, 285, 297, 315,
  337, 392, 409, 416, 425, 467, 470, 473, 482, 488, 515, 520, 602, 637, 663, 680, 705, 713, 755, 770, 786, 817, 839, 856, 858, 864,
  873, 890, 947, 1143, 1160, 1184, 1188, 1211, 1226, 1237, 1239, 1256, 1258, 1260, 1264, 1266, 1275, 1277, 1292, 1311, 1319, 1321,
  1337, 1340, 1393, ...LATER_EGGS,
]);

/** The egg of a species' evolution line (its first form, when PetEggData has that egg), else 0. */
export function eggOfLine(t: { species: Record<string, { next?: number }> }, race: number): number {
  const prev = new Map<number, number>();
  for (const [id, sp] of Object.entries(t.species)) if (sp.next) prev.set(sp.next, Number(id));
  let r = race;
  for (let i = 0; i < 6 && !EGG_IDS.has(r) && prev.has(r); i++) r = prev.get(r)!;
  return EGG_IDS.has(r) ? r : 0;
}

/**
 * The species of a boss form: variant * 10000 + species, or for 终极麦斗王's 14523 / 11514 / 11516
 * (PetAssetsMap) variant * 1000 + species.
 */
export function guardianSpecies(t: PetTables, asked: number): number {
  return BOSS_SPECIES[asked] ?? (speciesOf(t, asked % 10000) ? asked % 10000 : speciesOf(t, asked % 1000) ? asked % 1000 : asked % 10000);
}

/**
 * The 亚比蛋 a win over this 守护者 form brings, else 0: the last form's, of its line or BOSS_EGGS;
 * none for 终极麦斗王's first two (麦斗王 and 战魂猛犸: the 麦斗猪蛋 comes with the last).
 */
export function guardianEgg(t: PetTables, asked: number, index: number): number {
  if (asked in BOSS_EGGS) return BOSS_EGGS[asked];
  if (asked === 14523 || asked === 11514 || !lastGuardianForm(asked, index)) return 0;
  return eggOfLine(t, guardianSpecies(t, asked));
}

/** A fair server: the levels a client asks for a fight, at most this over his strongest 亚比. */
export const FAIR_ABOVE = 5;

/** PetFightTypes.FIGHT_IN_MEMBER_ARENA: the bosses of 黑星堡垒. */
export const FIGHT_IN_MEMBER_ARENA = 12;
/** 黑星堡垒's bosses' levels by room: floor 1 (viparena2, 3), 2 (5, 6), 3 (7) (RECONSTRUCTED). */
export const MEMBER_ARENA_LEVELS: Record<string, number> = { viparena2: 50, viparena3: 50, viparena5: 65, viparena6: 65, viparena7: 80 };
/**
 * The bosses of each room of the 堡垒 (viparena/flooroneres, floortwores, floorthreeres: the
 * Scene0nInitialler's bossId, 70000 + species): a room fights only its own.
 */
export const MEMBER_ARENA_BOSSES: Record<string, number[]> = {
  viparena2: [70536],
  viparena3: [70560],
  viparena5: [70328],
  viparena6: [70329],
  viparena7: [70436, 70311],
};
/** The bosses whose win passes a floor (the scenes that then regPassLevel): 84_4 (game.ts). */
export const MEMBER_ARENA_PASS: Record<number, number[]> = { 1: [70536, 70560], 2: [70329], 3: [70311] };
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
    const boosts = ((await deps.load(ctx)) as PetItemOwner).boosts;
    const auto = boosts?.autoOff ? 0 : (boosts?.auto ?? 0);
    ctx.reply({ pms: (await deps.wild())[room] ?? [], ...(auto ? { auto } : {}) });
  });

  // revival_auto {on} (not of 2013): the 自动战斗仪 stopped (on 0: the battle screen's 停止自动战斗;
  // its battles left are kept) or going on (on 1; in a wild battle it takes this one, a use of it).
  // -> {on, left, auto}: whether the battle now under way fights by itself.
  world.xt("PetExtension.revival_auto", async (ctx) => {
    const o = await deps.load(ctx);
    const boosts = ((o as PetItemOwner).boosts ??= {});
    const on = Number(ctx.params.on) === 1;
    const b = battles.get(o.id);
    if (on && boosts.auto) {
      delete boosts.autoOff;
      if (b && !b.over && !b.auto && b.autoMay) {
        b.auto = true;
        boosts.auto -= 1;
        if (boosts.auto <= 0) delete boosts.auto;
      }
    } else if (!on) boosts.autoOff = true;
    await deps.save(o);
    ctx.reply({ on: on && !boosts.autoOff, left: boosts.auto ?? 0, auto: !!b?.auto && !b.over && on }, "revival_auto");
  });

  /** Why a battle cannot start for this player now (one is on; no 亚比 with 体力), else null. */
  const cannotBegin = (o: PetOwner): string | null => {
    const old = battles.get(o.id);
    if (old && !old.over) return "你不能够在离开一个战场之前，加入另外一个战场！";
    if (!(o.pets ?? []).some((p) => p.hp > 0)) return WEAK;
    return null;
  };
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
    sandbox?: { mul: number[]; keep?: number; keepText?: string; foes?: { race: number; level: number; mul: number[] }[] },
    /** The battle made, before it is sent (the 道馆: 幻冥's 命运 on the player's 亚比). */
    adjust?: (b: Battle) => void,
  ): Promise<boolean> => {
    const o = await deps.load(ctx);
    const t = await deps.tables();
    for (const p of o.pets ?? []) normalisePet(p, t);
    // A refused start: told in a 2303 with msg alone; false to the caller.
    const refuse = (msg: string) => (ctx.reply({ msg }, "2303"), false);
    const no = cannotBegin(o);
    if (no) return refuse(no);
    const active = (o.pets ?? []).find((p) => p.hp > 0)!;
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
    if (sandbox?.keep) {
      b.keep = sandbox.keep;
      b.keepText = sandbox.keepText;
    }
    // A 沙盒 team in one battle (sandbox.ts together): the others come out as each falls; the end
    // names the first (the one the client was told of).
    const team = (sandbox?.foes ?? []).filter((f) => speciesOf(t, f.race)).map((f) => {
      const p = makePet(t, f.race, f.level, deps.today());
      p.mul = f.mul;
      p.hp = statsOf(p, t)[0];
      return p;
    });
    if (team.length) {
      b.foes = team;
      b.asked ??= race;
    }
    adjust?.(b);
    // 自动战斗仪 (44, petitems.ts): "开启后，在场景中会自动与野外怪对战。每个可使用100次": a wild
    // battle while it lasts is fought by the battle screen itself (auto), one use each.
    const boosts = (o as PetItemOwner).boosts;
    // (A wild 亚比 of the room: the one battle that may be caught.)
    const auto = !!boosts?.auto && !boosts.autoOff && catchable && !copyId && !sandbox;
    b.auto = auto;
    b.autoMay = catchable && !copyId && !sandbox;
    if (auto && boosts) {
      boosts.auto = (boosts.auto ?? 0) - 1;
      if (boosts.auto <= 0) delete boosts.auto;
      await deps.save(o);
    }
    battles.set(o.id, b);
    engine.bag = o.pets;
    engine.ownerRef = o;
    // The 亚比 come out: a 圣域 of theirs is there from the start (in the views of 2303), its words after 2401.
    const came = engine.arrivals(b);
    send(ctx, [
      // chp (not in the 2013 reply): the HP fraction from which balls work, for the 捕捉难度 hint.
      ["2303", { esc: true, sw: true, ch: canCatch, cd: catchStars(speciesOf(t, race)!.c[0]), chp: catchHpLimit(t, race), pmmList: engine.views(b) }],
      // boss: the opponent's id as the fight was asked for (variant * 10000 + species for the
      // bosses), by which the battle screen finds the boss's films (bossfightmovie/boss<id>).
      // autoOff: a 自动战斗仪 with battles left that the player stopped (the screen offers it again).
      ["2401", { id: b.id, type: 0, pt: 0, bs: "", srt: 0, scene: b.room, boss: asked ?? race, ...(auto ? { auto: true, autoLeft: boosts?.auto ?? 0 } : boosts?.auto && b.autoMay ? { autoOff: true, autoLeft: boosts.auto } : {}) }],
      ...came,
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
  // Task 亚比 with a level of their own: 念 (40461) and 邪念 (20605) of 念之大厅 (thinktowerofthink); a
  // player's letter in 奥拉周刊 54 fought 念 "80级时都那么难打", then 邪念 (RECONSTRUCTED: 邪念 at 90).
  const TASK_PET_LEVELS: Record<number, number> = { 40461: 80, 20605: 90 };
  world.xt("PetExtension.54_2", async (ctx) => {
    const asked = Number(ctx.params.level);
    const id = Number(ctx.params.raceId);
    const onWin: Battle["onWin"] = (o) => {
      const now = deps.now?.() ?? Date.now();
      return settleTasks(world, o as TaskOwner, stepsByPetWin(o as TaskOwner, id, now), now);
    };
    // A fair server (the 工具箱 closed): a level a client asks is at most FAIR_ABOVE over his
    // strongest 亚比 (any species at Lv100 would be experience for nothing).
    const fairCap = async (level: number) => {
      if (!deps.fair) return level;
      const o = await deps.load(ctx);
      return Math.min(level, Math.max(5, ...(o.pets ?? []).map((p) => p.level)) + FAIR_ABOVE);
    };
    if (id >= 10000 || TASK_PET_RACES.has(id)) {
      const o = await deps.load(ctx);
      const top = Math.max(5, ...(o.pets ?? []).map((p) => p.level));
      const level = TASK_PET_LEVELS[id] ?? (asked > 0 ? await fairCap(asked) : top + 2 * (Math.floor(id / 10000) - 1));
      return void (await begin(ctx, id % 10000, Math.max(1, Math.min(100, level)), false, onWin, id));
    }
    // A wild 亚比 of this room: at the room's levels (the client's level is not taken), and
    // catchable. Any other species (a scene's or quest's fightWithPetByRaceId, at its level) is
    // fought but not caught: a client not the 2013 one could otherwise ask for any species at
    // Lv1 and catch it.
    const entry = ((await deps.wild())[sceneOfRoom(ctx.player.room)] ?? []).find((w) => w.raceId === id);
    const rng = deps.rng ?? Math.random;
    const level = entry ? entry.min + Math.floor(rng() * (entry.max - entry.min + 1)) : asked > 0 ? await fairCap(asked) : 5;
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
    // 最强防御PK战 (gyms.ts): the panel's insistFight, 54_22 {type: 85, lv, buff}.
    if (type === GYM_TOWER && ctx.params.layer === undefined && Number(ctx.params.lv) > 0) {
      const stage = Number(ctx.params.lv) | 0;
      const rounds = WATER_ROUNDS[stage - 1];
      if (!rounds) return refuse("这个挑战现在还不能进行哦！");
      const o = await deps.load(ctx);
      const first = (o.pets ?? [])[0];
      if (!first || first.hp <= 0) return refuse("你的首宠没有体力了，先治疗一下吧！");
      const g = gymOf(o);
      const bless = !!ctx.params.buff && (g.waterBless ?? 0) > 0;
      if (bless) g.waterBless = (g.waterBless ?? 0) - 1;
      await deps.save(o);
      const foe = waterAttacker(stage);
      const today = deps.today();
      ctx.reply({ res: true });
      return void (await begin(
        ctx,
        foe.race,
        foe.level,
        false,
        (owner) => (stage >= WATER_ROUNDS.length ? [waterRunEnd(gymOf(owner), stage, today)] : []),
        undefined,
        (owner) => [waterRunEnd(gymOf(owner), stage - 1, today)],
        undefined,
        undefined,
        (b) => {
          b.insist = rounds;
          if (bless) {
            const st = b.mine.stats.slice();
            st[2] += WATER_BLESS.def;
            st[4] += WATER_BLESS.def;
            st[0] += WATER_BLESS.hp;
            b.mine.stats = st;
            b.mine.pet.hp += WATER_BLESS.hp;
          }
        },
      ));
    }
    if (type === GYM_TOWER) {
      const layer = Number(ctx.params.layer) | 0;
      const run = gymOf(await deps.load(ctx)).tower;
      const floor = THUNDER_FLOORS[layer - 1];
      if (!run || !floor || layer !== run.floor + 1) return refuse("请先开启雷霆之塔的挑战！");
      ctx.reply({ res: true });
      return void (await begin(ctx, floor.race, floor.level, false, (o) => towerFloorWon(o, layer, deps.now?.() ?? Date.now())));
    }
    if (type === GYM_DARK && Number(ctx.params.raceId) > 0) {
      // 命运玩偶 only (their four numbers), at their own levels.
      const raceId = Number(ctx.params.raceId) | 0;
      if (!DARK_DOLLS.includes(raceId)) return refuse("这个挑战现在还不能进行哦！");
      ctx.reply({ res: true });
      return void (await begin(ctx, raceId % 10000, dollLevel(raceId), false, undefined, raceId));
    }
    // 玩偶迷阵 (gyms.ts): 54_22 {type: 88, id: 2}, the run's next 命运玩偶, 幻冥's 战斗祝福 on both.
    if (type === GYM_DARK && (Number(ctx.params.id) | 0) === 2) {
      const o = await deps.load(ctx);
      const g = gymOf(o);
      if (!g.maze || g.maze.over) g.maze = { start: deps.now?.() ?? Date.now(), num: 0, hurt: 0, over: false };
      const doll = mazeDoll(g.maze.num);
      const rng = deps.rng ?? Math.random;
      const fates = [rollFate(rng), rollFate(rng)];
      await deps.save(o);
      // The damage done to the doll, from the battle itself.
      const hurt = (owner: PetOwner) => {
        const b = battles.get(owner.id);
        return b ? Math.max(0, b.wild.stats[0] - Math.max(0, b.wild.pet.hp)) : 0;
      };
      ctx.reply({ res: true });
      return void (await begin(
        ctx,
        doll.race,
        doll.level,
        false,
        (owner) => {
          const run = gymOf(owner).maze;
          if (run) {
            run.num += 1;
            run.hurt += hurt(owner);
          }
          return [];
        },
        undefined,
        (owner) => {
          const run = gymOf(owner).maze;
          if (run) {
            run.hurt += hurt(owner);
            run.over = true;
          }
          return [];
        },
        undefined,
        undefined,
        (b) => {
          b.mine.stats = applyFate(b.mine.stats, fates[0]);
          b.wild.stats = applyFate(b.wild.stats, fates[1]);
          b.wild.pet.hp = b.wild.stats[0];
          b.mine.pet.hp = Math.min(b.mine.pet.hp, b.mine.stats[0]);
        },
      ));
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
      // The boss of the room the player is in (not the room or the species the client names).
      const mi = Number(ctx.params.mi) | 0;
      const rm = sceneOfRoom(ctx.player.room);
      if (!Object.hasOwn(MEMBER_ARENA_BOSSES, rm) || !MEMBER_ARENA_BOSSES[rm].includes(mi)) {
        ctx.reply({ res: false });
        return ctx.reply({ msg: "这个挑战现在还不能进行哦！" }, "2303");
      }
      const level = MEMBER_ARENA_LEVELS[rm] ?? 60;
      return void (await begin(ctx, mi % 10000, level, false, undefined, mi));
    }
    const type = Number(ctx.params.type);
    if (type >= GYM_THUNDER && type <= GYM_LIGHT) return gymFight(ctx, type);
    const act = ACT_FIGHTS.get(world)?.get(type);
    if (act) {
      const o = await deps.load(ctx);
      const t = await deps.tables();
      // What begin would refuse, before the activity counts its try (or takes 关羽's 魂) and saves.
      const no = cannotBegin(o);
      if (no) {
        ctx.reply({ res: false });
        return ctx.reply({ msg: no }, "2303");
      }
      const f = await act(ctx, o, t);
      if (typeof f === "string") {
        ctx.reply({ res: false });
        return ctx.reply({ msg: f }, "2303");
      }
      ctx.reply({ res: true });
      const team = (f.team ?? []).filter((m) => speciesOf(t, m.race)).map((m) => makePet(t, m.race, Math.max(1, Math.min(100, m.level)), deps.today()));
      const adjust = (b: Battle) => {
        if (team.length) b.foes = team;
        if (f.boss) b.boss = f.boss;
        f.adjust?.(b);
      };
      // 武神服装: the generals of 武神大陆 now and then leave a part of the 武神套装 (costumes.ts).
      const suit = WUSHEN_RACES.includes(f.race) ? WUSHEN_SUIT : undefined;
      const onWin = f.onWin || suit !== undefined ? (owner: PetOwner) => [...(f.onWin?.(owner, t) ?? []), ...costumeDrop(owner as never, suit, deps.rng ?? Math.random)] : undefined;
      return void (await begin(ctx, f.race, f.level, false, onWin, f.asked, f.onLose ? (owner) => f.onLose!(owner, t) : undefined, undefined, undefined, adjust));
    }
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
    // For testing (the probes, ?dev=1 only): the 亚比 of the next floor made, "393,111".
    if (deps.dev)
      world.xt(`${ext}.revival_tower${sfx}`, async (ctx) => {
        const o = await deps.load(ctx);
        (towerOf(o) as { force?: string[] }).force = String(ctx.params.en ?? "").split(",").filter((x) => /^\d{1,6}$/.test(x)).slice(0, 5);
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
    // The films there are (petlearning<race>) teach their own 亚比 their own skill, one of the
    // tables (a skill the battle does not know could not be used).
    const t = await deps.tables();
    if (!pet || !sid || FILM_SKILLS[pet.race] !== sid || !t.pm.skills[String(sid)]) return ctx.reply({ res: false }, "54e_5");
    pet.learned = [...new Set([...(pet.learned ?? []), sid])];
    await deps.save(o);
    ctx.reply({ res: true, pid: pet.id, sid }, "54e_5");
  });

  // 传送核心 (scene/maintown1): before 维克's talk 356 (the task action 13_356_checkPM) the room asks
  // 54e_19 {} -> {lv}, the highest level of the bag's 亚比 ("要有一只80级以上的亚比…"; RECONSTRUCTED).
  world.xt("PetExtension2.54e_19", async (ctx) => {
    const o = await deps.load(ctx);
    ctx.reply({ lv: Math.max(0, ...(o.pets ?? []).map((p) => p.level)) }, "54e_19");
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
    const species = guardianSpecies(t, asked);
    const egg = guardianEgg(t, asked, index);
    const mark = BOSS_MARKS[asked];
    const bossName = nameOf(t, species);
    const onWin: Battle["onWin"] = (o) => {
      const out: Msg[] = [];
      const items = ((o as { items?: Record<string, Record<string, number>> }).items ??= {});
      // Counted for 我的荣誉's 胜利数量 (honour.ts: 挑战…胜利 1, 10, 100 times).
      const wins = ((o as { bossWins?: Record<string, number> }).bossWins ??= {});
      wins[bossName] = (wins[bossName] ?? 0) + 1;
      // A 战术卡, now and then (petcards.ts).
      const card = cardDrop(deps.rng ?? Math.random);
      if (card) {
        const cards = (items[String(PET_CARD)] ??= {});
        cards[String(card)] = (cards[String(card)] ?? 0) + 1;
        out.push(["onAmountUpdated", { amount: `${PET_CARD}_${card}_0_1` }], [NOTE, { text: `获得了战术卡「${PET_CARDS[card].name}」！`, bn: { type: PET_CARD, id: card, num: 1 } }]);
      }
      // 守护者服装: now and then a part of the 守护者's suit (costumes.ts).
      out.push(...costumeDrop(o as never, GUARDIAN_SUITS[species], deps.rng ?? Math.random));
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
      const e = new BattleEngine(t, deps.rng);
      // The battle holds the pet records of an earlier load: point it at this one's (in 究极, the
      // record kept behind the form; the form itself is never saved).
      const rebind = (f: Fighter) => {
        e.syncForm(f);
        const own = f.form ? f.form.from : f.pet;
        const fresh = (o.pets ?? []).find((p) => p.id === own.id);
        if (fresh) {
          fresh.hp = own.hp;
          fresh.skills = own.skills;
          if (f.form) f.form.from = fresh;
          else f.pet = fresh;
        }
      };
      rebind(b.mine);
      e.bag = o.pets;
      e.ownerRef = o;
      const out = await run(ctx, b, e, o, t);
      e.syncForm(b.mine);
      if (out === "end") {
        await deps.save(o);
        return;
      }
      if (!Array.isArray(out)) return send(ctx, out.refused);
      out.push(...finish(b, e, o, t, ctx));
      await deps.save(o);
      send(ctx, out);
    });

  /**
   * The end of a battle the 自动战斗仪 fought, whatever its end: every 亚比 of the bag has all its 体力
   * and PP back (RECONSTRUCTED: the device's 2013 words say only that it fights by itself), so that
   * the next of its battles can come. The words that say so, or "".
   */
  const autoRestore = (b: Battle, o: PetOwner, t: PetTables): string => {
    if (!b.auto) return "";
    for (const p of o.pets ?? []) {
      p.hp = statsOf(p, t)[0];
      for (const s of p.skills) s.pp = s.max;
    }
    return "自动战斗仪回复了亚比的全部状态。";
  };

  /** After the actions of a turn: residual damage, then the next turn, a forced switch, or the end. */
  const finish = (b: Battle, e: BattleEngine, o: PetOwner, t: PetTables, ctx: XtContext): Msg[] => {
    const out: Msg[] = [];
    // 威吓 of the wild 亚比: the player's 亚比 goes back and another one comes out, at random.
    if (b.forceOut === 0 && b.mine.pet.hp > 0 && b.wild.pet.hp > 0) {
      e.unchange(b.mine);
      const others = (o.pets ?? []).filter((p) => p.hp > 0 && p !== b.mine.pet);
      const gone = b.mine.pet;
      if (others.length) {
        const next = others[Math.floor((deps.rng ?? Math.random)() * others.length)];
        b.mine = fighter(0, next, o.id, t);
        const desc = `${gone.nick || nameOf(t, gone.race)}被强制替换下场！\n${next.nick || nameOf(t, next.race)}出战了！`;
        out.push(["2413", { playerInfo: e.view(b, 0), extInfo: { desc, res: 1, forced: false } }], ...e.arrivals(b));
      } else out.push(["2421", { slotId: 0, hpInc: 0, desc: "没有可以替换的亚比。", pmmList: e.views(b) }]);
    }
    b.forceOut = undefined;
    // An activity boss's helper comes out when the one before it falls (Battle.foes).
    if (b.wild.pet.hp <= 0 && b.foes?.length) {
      const gone = b.wild.pet;
      const next = b.foes.shift()!;
      b.wild = fighter(1, next, 0, t);
      const desc = `${nameOf(t, gone.race)}倒下了！\n${nameOf(t, next.race)}出战了！`;
      out.push(["2413", { playerInfo: e.view(b, 1), extInfo: { desc, res: 1, forced: true, foe: true } }], ...e.arrivals(b));
    }
    if (b.wild.pet.hp > 0 && b.mine.pet.hp > 0) out.push(...e.endOfTurn(b));
    // 究极 ends with a fall or the battle's end: the record kept carries on.
    if (b.mine.pet.hp <= 0 || b.wild.pet.hp <= 0) e.unchange(b.mine);
    // 最强防御PK战: the rounds stood, the 局 is won.
    let stood = false;
    if (b.insist && b.mine.pet.hp > 0 && b.wild.pet.hp > 0 && b.turn + 1 >= b.insist) {
      b.wild.pet.hp = 0;
      stood = true;
    }
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
        for (const k of [mult.exp === 3 ? "exp3" : mult.exp === 2 ? "exp2" : "", mult.ev === 2 ? "ev2" : "", boosts.radar ? "radar" : ""] as (Exclude<keyof Boosts, "autoOff"> | "")[]) {
          if (!k) continue;
          boosts[k] = Math.max(0, (boosts[k] ?? 0) - 1);
          if (!boosts[k]) delete boosts[k];
          used.push(k);
        }
        // 寻宝雷达: "战斗结束可获得很多晶币奖励"; how many is lost (RECONSTRUCTED: 50 and 5 a level of the wild 亚比).
        if (used.includes("radar")) {
          const rec = o as PetOwner & { score?: number };
          const coins = 50 + 5 * b.wild.pet.level;
          rec.score = Math.min(MONEY_MAX, (rec.score ?? 0) + coins);
          out.push(["onScoreUpdated", { score: rec.score }]);
          radarCoins = coins;
        }
      }
      if (r.evolvedTo && o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
      // The session's win, for the claims that follow it (wins.ts: 98_1, 84_4, 91_31).
      recordWin(ctx.session, b.asked ?? b.wild.pet.race, sceneOfRoom(ctx.player?.room));
      // A win's own messages; NOTE ones are words for the end of the battle, not sent.
      const won = b.onWin ? b.onWin(o) : [];
      const notes = won.filter(([c]) => c === NOTE).map(([, m]) => String(m.text));
      // What a win brought (a boss's 亚比蛋): the client shows the 2013 MaterialGetPanel for each
      // once the battle is closed ("1 个 …亚比蛋 已经放入你的亚比孵化器").
      const bn = won.filter(([c, m]) => c === NOTE && m.bn).map(([, m]) => m.bn);
      out.push(...won.filter(([c]) => c !== NOTE));
      const desc = (stood ? `坚持了${b.insist}回合，防御成功！` : "") + (b.noAward ? "战斗胜利！" : `战斗胜利！${nameOf(t, before)}获得了经验。${radarCoins ? `寻宝雷达找到了${radarCoins}晶币！` : ""}`) + autoRestore(b, o, t);
      // myFinalRaceId: the 亚比 that ended it (PetFightEvent.myFinalRaceId; the 道馆 panels give their stone for their own).
      out.push(["2403", { isWin: true, raceId: b.asked ?? b.wild.pet.race, id: b.copyId ?? 0, evolveFrom: r.evolvedTo ? before : 0, myFinalRaceId: before, desc, ...(notes.length ? { note: notes.join("\n") } : {}), ...(bn.length ? { bn } : {}), pmmList: e.views(b) }]);
      battles.delete(o.id);
      return out;
    }
    if (b.mine.pet.hp <= 0) {
      const keepFell = b.keep !== undefined && b.mine.pet.id === b.keep;
      if (!b.insist && !keepFell && (o.pets ?? []).some((p) => p.hp > 0)) {
        b.mustSwitch = true;
        out.push(["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]);
        return out;
      }
      b.over = true;
      if (b.onLose) out.push(...b.onLose(o));
      const healed = autoRestore(b, o, t);
      const lostDesc = keepFell ? b.keepText || `${nameOf(t, b.mine.pet.race)}倒下了……` : healed ? `战斗失败了……${healed}` : "你的亚比都倒下了……快带它们去治疗吧！";
      out.push(["2403", { isWin: false, raceId: b.asked ?? b.wild.pet.race, id: b.copyId ?? 0, myFinalRaceId: b.mine.pet.race, desc: lostDesc, pmmList: e.views(b) }]);
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

  // The player's 亚比 does nothing this turn (its time ran out, or it has no PP left): the other acts.
  const idle = (b: Battle, e: BattleEngine, t: PetTables): Msg[] => {
    const pet = b.mine.pet;
    const name = pet.nick || nameOf(t, pet.race);
    const desc = pet.skills.every((s) => s.pp <= 0) ? `${name}的技能次数用完了，什么也没有做。` : `${name}什么也没有做。`;
    return [["2421", { slotId: 0, hpInc: 0, desc, pmmList: e.views(b) }], ...e.wildTurn(b)];
  };

  // useSkill {skillId, tarSId, isAuto, tarPSId, reqPSId}
  turn("1401", (_ctx, b, e, _o, t) => {
    if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]] };
    const id = Number(_ctx.params.skillId);
    const usable = b.mine.pet.skills.filter((s) => s.pp > 0);
    const forced = e.forcedOf(b.mine);
    // 超奥义 (the later BigSkillMCHandler_AoYi: UseBigSkillHandler, SkillType.AOYI_BIG): its own skill
    // beside the four, once a battle.
    if (forced === undefined && id > 0 && id === e.aoyiOf(b.mine) && e.canAoyi(b, b.mine)) {
      e.useAoyi(b, b.mine);
      return e.skillTurn(b, id);
    }
    // No PP left: the player's 亚比 does nothing this turn (no 挣扎); the other acts.
    if (!usable.length && forced === undefined) return idle(b, e, t);
    // The 自动战斗仪's turn (skillId -1): the battle chooses (autoChoice).
    if (id === -1 && b.auto) return e.skillTurn(b, forced ?? e.autoChoice(b));
    const chosen = usable.find((s) => s.id === id) ? id : usable.length ? usable[0].id : 0;
    return e.skillTurn(b, forced ?? chosen);
  });

  // 究极 (the later PetClient's changePMView, RQST_BATTLE_POWERUP 1407 {reqPSId, turn}; its answer
  // RSPN_BATTLE_POWERUP 2417): the player's 亚比 becomes its 究极 form; that is its act this
  // round, and the other 亚比 acts.
  turn("1407", (_ctx, b, e, _o, _t) => {
    if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]] };
    if (!e.canChange(b, b.mine)) {
      const why = !e.jiujiOf(b.mine) ? "这只亚比不能究极进化。" : b.mine.form ? "已经是究极形态了！" : "现在还不能究极进化。";
      return { refused: [["2417", { reqSId: 0, res: 0, refused: true, desc: why, pmmList: e.views(b) }]] };
    }
    e.startTurn(b);
    const pre = e.roundStart(b);
    const changed = e.change(b, b.mine);
    if (b.wild.pet.hp <= 0) return [...pre, changed];
    // The other's act (wildTurn without its own round start: the round has begun).
    if (e.needsBean(b.wild)) return [...pre, changed, e.useBean(b, b.wild)];
    return [...pre, changed, e.act(b, b.wild, b.mine, e.wildChoice(b))];
  });

  // standby {isAuto, reqPSId} (PetClient.standby): the turn's time ran out and no skill has uses left
  // (the later FightPanel's petAutoUseSkill): the 亚比 waits, the wild 亚比 acts.
  turn("1406", (_ctx, b, e, _o, t) => {
    if (b.mustSwitch) return { refused: [["2422", { slotId: 0, desc: "请选择下一只出战的亚比。", pmmList: e.views(b) }]] };
    // A skill it uses by itself (蓄力, 连续攻击N回合) needs no PP.
    const forced = e.forcedOf(b.mine);
    if (forced !== undefined) return e.skillTurn(b, forced);
    return idle(b, e, t);
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
    e.unchange(b.mine);
    b.mine = fighter(0, next, o.id, t);
    // 为自己下一只出场的亚比满状态回复.
    if (b.nextHeal?.[0]) {
      b.nextHeal[0] = false;
      next.hp = b.mine.stats[0];
      for (const s of next.skills) s.pp = s.max;
    }
    const msg: Msg = ["2413", { playerInfo: e.view(b, 0), extInfo: { desc: `${next.nick || nameOf(t, next.race)}出战！`, res: 1, forced } }];
    const came = e.arrivals(b);
    return forced ? [msg, ...came] : [msg, ...came, ...e.wildTurn(b)];
  });

  // escape {}: always works against wild 亚比.
  turn("1404", (ctx, b, _e, o, t) => {
    _e.unchange(b.mine);
    b.over = true;
    battles.delete(o.id);
    if (b.onLose) for (const [c, body] of b.onLose(o)) ctx.reply(body, c);
    ctx.reply({ reqSId: 0, isEscape: true, raceId: b.asked ?? b.wild.pet.race, desc: "成功逃跑了！" + autoRestore(b, o, t) }, "2414");
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
    e.unchange(b.mine);
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
    const healed = autoRestore(b, o, t);
    send(ctx, [
      ["2415", { reqId: o.id, tarSId: 1, itemId: ball, pmId: caught.id, raceId: caught.race, lv, lc: inBag ? 1 : 2, pet: briefOf(caught, o, t), desc: `捕捉成功！${nameOf(t, caught.race)}${inBag ? "进入了你的亚比背包" : "被送进了亚比仓库"}。` }],
      ["2403", { isWin: true, isCatched: true, raceId: caught.race, desc: "捕捉成功！" + healed, pmmList: e.views(b) }],
      ...(markDic(o, t, caught.race, OWNED) ? [NEW_RECORD] : []),
    ]);
    return "end";
  });

  // The 沙盒's fights (sandbox.ts): its opponents, not to be caught, no award.
  installGyms(world, { load: deps.load, save: deps.save, tables: deps.tables, today: deps.today, now: () => deps.now?.() ?? Date.now(), rng: deps.rng ?? Math.random, gainExp: (t, pet, n) => gainExp(t, pet, n).msgs });
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
