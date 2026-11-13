// 圣域 (the later battle's fields, 2014) and the 圣域技能 that work in them, from the pet table's
// PMWeather rows (revival/pmdata.json "weather", tools/gen_pmdata.py --upto): their front text and
// their BuffXML (the later server's own buffs, numbered: 306 makes the field, 308 / 240 act at the end
// of each round on the 亚比 of some 属性, 322 when one comes out, 160 / 366 power, 304 / 328 the
// damage taken, 375 a floor under which damage does nothing; 310 a 圣域技能: x its chance at the start
// of a round, y the field it needs, z1 its rounds; 232 on each blow it lands, 234 on each blow it
// takes …). The later server is lost: the rows' numbers are kept, what the XML does not say
// (一定概率 of a skill that summons a field, the heal of 幻灵, how 圣战 grows) is RECONSTRUCTED.
//
// One field at a time: a 亚比 whose 特性 makes one brings it when it comes out (阳炎 and 月华, 自动循环
// 激活, again every 5 rounds while it stays out), a skill "召唤X圣域" brings its own; a new field puts
// out the old one. The 圣域技能 a 亚比 learns at Lv60 (its row's 圣域技能 column) tries at the start
// of each round, when the field it needs is out.

import type { StatKey, StatusName, Timed } from "./skilltext.ts";

/** The 属性 numbers the fields name. */
const FIRE = 9, WATER = 10, WOOD = 11, ICE = 14, ANCIENT = 15, DARK = 16, LIGHT = 18, HOLY = 20, ARMS = 21, KING = 22;
/** 幻灵家族: the 亚比 whose 特性 is 幻灵特性 (PMWeather 235). */
export const HUANLING = "235";

export interface FieldRule {
  /** At the end of each round, on each 亚比 standing (its 属性 and 特性 decide). */
  end?: (types: [number, number], traits: string[]) => FieldAct | undefined;
  /** When it comes out (or the field comes) while the field is out. */
  enter?: (types: [number, number]) => FieldAct | undefined;
  /** Power of a skill of this 属性: times (mult) or points added (add). */
  power?: { attr: number; mult?: number; add?: number };
  /** The share of damage a 亚比 takes, by its 属性 / 特性. */
  taken?: (types: [number, number], traits: string[]) => number;
  /** Damage the attacker does, by its 属性. */
  dealt?: (types: [number, number]) => number;
  /** Damage under this many points does nothing to the 亚比 of this 属性 (万王: 王系, 100). */
  floor?: { attr: number; n: number };
  /** 圣战: the less 体力 the attacker has, the more it does. */
  hpBoost?: boolean;
  /** 烈焰: a burn's damage takes 1 PP off each skill too. */
  burnPP?: boolean;
}

export interface FieldAct {
  status?: StatusName;
  chance?: number;
  stats?: StatKey[];
  delta?: number;
  heal?: [number, number];
  /** PP of each skill. */
  pp?: number;
  /** Its 属性等级 cannot be lowered for some rounds (君芒). */
  guard?: number;
}

const is = (t: [number, number], a: number) => t[0] === a || t[1] === a;

/** The fields of the 亚比 to 2395 and the skills that summon them, by PMWeather id. */
export const FIELDS: Record<string, FieldRule> = {
  // 阳炎: 每回合末，上古系和火系以外亚比均有25%概率烧伤 (308 x 9, z 9,15; 187 rate 25).
  "1001": { end: (t) => (is(t, FIRE) || is(t, ANCIENT) ? undefined : { status: "烧伤", chance: 25 }) },
  // 月华: 上古系和冰系以外 25% 冰冻.
  "1002": { end: (t) => (is(t, ICE) || is(t, ANCIENT) ? undefined : { status: "冰冻", chance: 25 }) },
  // 幻灵: 幻灵家族 30% less damage (328 y 0.3), each round's end some 体力 back (329 y "20,100").
  "1023": {
    end: (_t, tr) => (tr.includes(HUANLING) ? { heal: [20, 100] } : undefined),
    taken: (_t, tr) => (tr.includes(HUANLING) ? 0.7 : 1),
  },
  // 剑心: 圣灵系 and 神兵系 30% 特攻 and 暴击 +1 (199 x 0,0,1,0,0,0,0,1, rate 30).
  "1028": { end: (t) => (is(t, HOLY) || is(t, ARMS) ? { stats: ["satk", "crit"], delta: 1, chance: 30 } : undefined) },
  // 君芒: 王系 30% 下2回合内属性不会被降低 (203 round 2).
  "1033": { end: (t) => (is(t, KING) ? { guard: 2, chance: 30 } : undefined) },
  // 天眼: 光明系 上场时 命中 and 速度 +1 (322 y 18; 199 0,0,0,0,1,1), 光明系 power +40% (160 x 18 y 40).
  "1035": { enter: (t) => (is(t, LIGHT) ? { stats: ["spd", "acc"], delta: 1 } : undefined), power: { attr: LIGHT, mult: 1.4 } },
  // 烈焰: 火系以外 30% 烧伤, a burn then costs 1 PP of each skill (222 x -1); 火系 each round +1 PP (222 x 1).
  "1037": { end: (t) => (is(t, FIRE) ? { pp: 1 } : { status: "烧伤", chance: 30 }), burnPP: true },
  // 圣战: 全场亚比血量越少造成伤害越高 (340).
  "1038": { hpBoost: true },
  // 森罗: 木系 25% less damage (304 ratio 75), each round's end 100–250 back (263 x 100,250).
  "1049": { end: (t) => (is(t, WOOD) ? { heal: [100, 250] } : undefined), taken: (t) => (is(t, WOOD) ? 0.75 : 1) },
  // 天武: 神兵系 skills 100 more power (366 x 21 y 100).
  "1050": { power: { attr: ARMS, add: 100 } },
  // 洪流: 水系 上场 命中 +1; 非水系 上场 速度 -1 and each round's end 速度 -1 (322, 308 z 10).
  "1056": {
    enter: (t) => (is(t, WATER) ? { stats: ["acc"], delta: 1 } : { stats: ["spd"], delta: -1 }),
    end: (t) => (is(t, WATER) ? undefined : { stats: ["spd"], delta: -1 }),
  },
  // 战王: 光明系 25% less damage taken (304 x 18 ratio 75), 暗黑系 25% more done (160 x 16 y 25).
  "1057": { taken: (t) => (is(t, LIGHT) ? 0.75 : 1), dealt: (t) => (is(t, DARK) ? 1.25 : 1) },
  // 万王: 王系 免疫100点以下伤害 (375 x 100 y 22).
  "1060": { floor: { attr: KING, n: 100 } },
};

/** A field's name as the skills call it (召唤万王圣域): the row's name. */
export function fieldByName(weather: Record<string, { n: string; k: number }> | undefined, name: string): string | undefined {
  for (const [id, w] of Object.entries(weather ?? {})) if ((w.k === 2 || w.k === 3) && w.n === name && FIELDS[id]) return id;
  return undefined;
}

/** The fields a 亚比's 特性 (species column f, "1001" or "235#1023") makes. */
export function fieldsOfTrait(f: string | undefined): string[] {
  return (f ?? "").split("#").filter((w) => FIELDS[w]);
}

/** The 特性 of the type 自动循环激活圣域 (PMWeather type 3) come back every this many rounds. */
export const AUTO_EVERY = 5;

/** What a 圣域技能 does when it comes: on the holder at once, and the lasting part (Timed). */
export interface SyRule {
  /** The field it needs. */
  field: string;
  /** Its chance at the start of each round (310 x). */
  chance: number;
  /** Rounds it lasts (310 z1). */
  turns: number;
  /** The state's name, for the words. */
  state: string;
  /** At once on the holder. */
  self?: { stats?: StatKey[]; delta?: number; deltaMax?: number; doubleUps?: boolean; cure?: boolean; full?: boolean; hpOne?: boolean };
  /** At once on the other 亚比. */
  foe?: { status: StatusName };
  /** The lasting effects (engine Timed kinds), on the holder. */
  timed?: Omit<Timed, "who" | "turns">[];
}

const T = (x: Omit<Timed, "who" | "turns">) => x;

/** The 圣域技能 of the 亚比 to 2395 (PMWeather type 1), by id. */
export const SY_SKILLS: Record<string, SyRule> = {
  // 炎灼八荒 (no XML: the 阳炎 skill of 炎魔将; its words' numbers, half the 圣域技能's chance).
  "1003": { field: "1001", chance: 50, turns: 3, state: "灼炎", timed: [T({ kind: "nostatus", only: ["烧伤"] }), T({ kind: "onhit", chance: 20, stats: ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"], delta: -1 })] },
  "1024": { field: "1023", chance: 50, turns: 2, state: "雷神", timed: [T({ kind: "onhit", chance: 40, status: "麻痹" })] },
  "1025": { field: "1023", chance: 40, turns: 2, state: "炎神", timed: [T({ kind: "reflect", phys: 1 / 3, spec: 1 / 3 })] },
  "1026": { field: "1023", chance: 40, turns: 2, state: "海神", timed: [T({ kind: "onhurt", chance: 40, stats: ["def", "sdef"], delta: 1, selfStage: true })] },
  "1027": { field: "1028", chance: 50, turns: 1, state: "剑帝", timed: [T({ kind: "nostatus" })] },
  "1029": { field: "1002", chance: 80, turns: 3, state: "霜锋", timed: [T({ kind: "nostatus", only: ["冰冻"] }), T({ kind: "onhit", chance: 20, stats: ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"], delta: 1, selfStage: true })] },
  "1030": { field: "1023", chance: 50, turns: 2, state: "天神", timed: [T({ kind: "onhit", chance: 100, stats: ["crit"], delta: 1, deltaMax: 2, selfStage: true })] },
  "1031": { field: "1023", chance: 50, turns: 3, state: "冥神", timed: [T({ kind: "onhurt", chance: 50, rest: 1 })] },
  "1032": { field: "1033", chance: 50, turns: 1, state: "君王", self: { doubleUps: true } },
  "1034": { field: "1035", chance: 50, turns: 3, state: "真神", self: { stats: ["spd", "eva"], delta: 2 }, timed: [T({ kind: "sure" })] },
  "1036": { field: "1060", chance: 50, turns: 3, state: "狮王", timed: [T({ kind: "onhit", chance: 100, steal: 100 })] },
  "1039": { field: "1023", chance: 50, turns: 3, state: "死神", timed: [T({ kind: "onhurt", chance: 10, ko: true })] },
  "1040": { field: "1037", chance: 40, turns: 2, state: "红莲", timed: [T({ kind: "regen", n: 200 }), T({ kind: "power", attr: 9, mult: 1.3 })] },
  "1041": { field: "1037", chance: 40, turns: 2, state: "炽天", timed: [T({ kind: "extra", n: 30 })] },
  "1042": { field: "1037", chance: 40, turns: 2, state: "魔炎", timed: [T({ kind: "double", chance: 70 })] },
  "1043": { field: "1038", chance: 25, turns: 1, state: "圣武", self: { hpOne: true }, timed: [T({ kind: "untouchable" })] },
  "1044": { field: "1037", chance: 40, turns: 2, state: "斗炎", timed: [T({ kind: "onhurt", chance: 100, status: "烧伤", heal: 150 })] },
  "1045": { field: "1049", chance: 40, turns: 1, state: "神木", self: { stats: ["spd"], delta: 1, deltaMax: 2 } },
  "1046": { field: "1049", chance: 30, turns: 1, state: "回春", timed: [T({ kind: "soak" })] },
  "1047": { field: "1049", chance: 30, turns: 1, state: "金甲", timed: [T({ kind: "upsTwice" })] },
  "1048": { field: "1049", chance: 25, turns: 1, state: "涤尘", self: { cure: true, full: true } },
  "1051": { field: "1050", chance: 40, turns: 1, state: "希望之神", timed: [T({ kind: "nostatus" }), T({ kind: "hold" })] },
  "1052": { field: "1056", chance: 25, turns: 2, state: "定海", timed: [T({ kind: "extra", bySpeed: true })] },
  "1053": { field: "1056", chance: 25, turns: 2, state: "龟波", timed: [T({ kind: "extra", f: 1 / 6 })] },
  "1054": { field: "1056", chance: 25, turns: 2, state: "深洋", timed: [T({ kind: "onhit", chance: 30, stats: ["def", "sdef"], delta: -1 })] },
  "1055": { field: "1056", chance: 40, turns: 2, state: "无限之泉", timed: [T({ kind: "onhurt", chance: 100, status: "衰弱", stats: ["spd"], delta: -1 })] },
  "1058": { field: "1057", chance: 20, turns: 1, state: "永夜", foe: { status: "害怕" } },
  "1059": { field: "1060", chance: 50, turns: 2, state: "灵王", timed: [T({ kind: "onhurt", chance: 100, stats: ["eva"], delta: 1, selfStage: true, heal: 100 })] },
  "1061": { field: "1060", chance: 20, turns: 1, state: "万王", timed: [T({ kind: "onhit", chance: 100, n: 2 })] },
  "1062": { field: "1057", chance: 100, turns: 1, state: "光羽", timed: [T({ kind: "onhurt", chance: 20, heal: 99999 })] },
  "1063": { field: "1057", chance: 20, turns: 1, state: "白灵", foe: { status: "麻痹" } },
};

/** A 亚比's 圣域技能 at its level: the rule and its row's name, or undefined. */
export function syOf(sy: string | undefined, level: number): { id: string; rule: SyRule } | undefined {
  if (!sy) return undefined;
  const [lv, id] = sy.split("-");
  const rule = SY_SKILLS[id];
  return rule && level >= Number(lv) ? { id, rule } : undefined;
}
