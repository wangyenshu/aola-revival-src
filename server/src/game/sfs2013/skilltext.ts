// What a skill does, read from its description (the 2013 skill rules are lost with the server;
// the descriptions, from the later pet/pmservice tables, are what the player is told). The
// description is read clause by clause: each reader takes the words it understands, and
// unread() gives what is left (tools: the check of every skill of the 图鉴's 亚比).
//
// 1 against 1 (the wild 亚比 of the 2013 game): 全体 / 对方全场 / 自己以外的全场 is the one opponent,
// 我方全体 the user; 攻击全场 / 给全场亚比造成伤害 (千杀水翔, 爆炎龙卷, 躁动冲撞) the opponent and the
// user too, as the descriptions tell them apart from 自己以外的全场 (wholeField); "对守护无效" and the
// like (bosses) are not told apart.

export type StatKey = "atk" | "def" | "satk" | "sdef" | "spd" | "acc" | "eva" | "crit";
export const STATUSES = ["麻痹", "害怕", "冰冻", "睡眠", "烧伤", "中毒", "混乱", "束缚", "衰弱", "寄生"] as const;
export type StatusName = (typeof STATUSES)[number];
/** The statuses "任意一种不良/异常状态" picks from. */
export const BAD_STATUSES: StatusName[] = ["麻痹", "冰冻", "睡眠", "烧伤", "中毒", "混乱"];

/** 属性 numbers (the battle screen's ATTR_NAMES). */
export const ATTRS: Record<string, number> = {
  普通: 0, 格斗: 1, 飞行: 2, 毒: 3, 爬行: 4, 土: 5, 虫: 6, 数码: 7, 机械: 8, 火: 9, 水: 10, 木: 11, 电: 12,
  神秘: 13, 冰: 14, 上古: 15, 暗黑: 16, 光明: 18, 龙: 19, 圣灵: 20, 神兵: 21, 王: 22,
};

/** 全属性: all eight 属性等级, 攻击 防御 特攻 特防 速度 命中 闪避 暴击. */
export const ALL_STATS: StatKey[] = ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"];
/** The five battle values (双攻、双防和速度). */
export const FIVE_STATS: StatKey[] = ["atk", "def", "satk", "sdef", "spd"];

const STAT_WORDS: Record<string, StatKey[]> = {
  攻击: ["atk"], 普攻: ["atk"], 防御: ["def"], 普防: ["def"], 特攻: ["satk"], 特防: ["sdef"], 速度: ["spd"],
  命中: ["acc"], 闪避: ["eva"], 暴击: ["crit"], 全属性: ALL_STATS, 双攻: ["atk", "satk"], 双防: ["def", "sdef"],
};
const STAT_RE = "(?:全属性|攻击|普攻|防御|普防|特攻|特防|速度|命中|闪避|暴击|双攻|双防)";
const STAT_LIST = `${STAT_RE}(?:(?:和|、|及|与)${STAT_RE})*`;
const ST = "(?:麻痹|害怕|冰冻|睡眠|烧伤|中毒|混乱|束缚|衰弱|寄生)";

export interface StageChange {
  self: boolean;
  stats: StatKey[];
  delta: number;
  chance: number;
  /** Random stats out of `stats`: how many ([a, b]). */
  pick?: [number, number];
  /** A random delta in [delta, deltaMax]. */
  deltaMax?: number;
  /** The change lasts this many turns, then goes (速战意念). */
  turns?: number;
  /** Only when this holds. */
  cond?: Cond;
  /** Another chance when this holds (霜月流星: 80% on a frozen foe). */
  condChance?: { cond: Cond; chance: number };
  /** One of these groups of values (炎魔闪: 防御+特防 or 攻击+特攻). */
  groups?: StatKey[][];
}

export type Cond =
  | { foeStatus: StatusName | "any" }
  | { selfStatus: StatusName[] | "any" }
  | { foeHpBelow: number }
  | { selfHpBelow: number }
  | { selfHpAbove: number }
  | { foeHpMore: true }
  | { foeHpLess: true }
  | { second: true }
  | { faster: true }
  | { slower: true }
  | { crit: true }
  /** The skill's own status landed (冰川崩裂: 造成冰冻时). */
  | { landed: true }
  /** The foe uses no damaging skill this turn. */
  | { foeNoDamage: true }
  /** The user was hurt this turn before it acted (龙怒), or was not (断水). */
  | { hurt: boolean }
  | { hitsMultipleOf: number }
  /** The damage dealt has a 9 in it or is a multiple of 9 (雷动九州). */
  | { nine: true }
  /** It was not hurt while it gathered power (魂葬破). */
  | { chargeUnhurt: true }
  /** The user used that skill and its effect lasts (七星灯 with 卧龙觉醒). */
  | { mark: string }
  /** The foe carries that mark (陶醉). */
  | { foeMark: string };

export interface Timed {
  who: "self" | "foe" | "both";
  turns: number;
  /** One of the kinds below, with its numbers. */
  kind:
    | "regen" // 每回合回复: n (points) or f (of the most HP) or lost (of what is lost), chance
    | "leech" // 每回合吸取对方: n or f, the user heals it
    | "dot" // 每回合扣除: n, [a, b] or f, chance
    | "gamble" // 哀之章 / 迷之章: chance on the foe (n), else back on the user (self n, or heal)
    | "screen" // 伤害减半 / 只承受: phys, spec (fraction taken)
    | "dodge" // 概率免受 / 闪避: phys, spec chance
    | "reflect" // 反击 / 返击: phys, spec fraction, or n points
    | "absorb" // 每回合可以抵抗 n 点
    | "guard" // 属性能力等级不能被削弱
    | "nostatus" // 不会陷入异常状态
    | "trap" // 无法替换亚比
    | "noact" // 每回合 chance 无法行动
    | "power" // 技能威力: add (points) or mult, attr (only that 属性)
    | "crit" // 暴击概率: chance
    | "onhit" // 给对方造成伤害时: flinch chance, or clear chance
    | "statmult" // 防御 / 速度 加倍 (stats: mult)
    | "stagesEachTurn" // 回合结束时: random stat of `stats`, delta, chance (天舞宝轮, 绝对领域)
    | "pphp" // 曙光: 1 PP of every skill into n HP
    | "hitHeal" // 吸收漩涡: n HP each hit
    | "extra" // 每次攻击附加 n 点伤害值
    | "sure" // 必定命中
    | "onhurt" // 受到伤害时: chance of stages (on the holder when selfStage), a status on the attacker, its PP
    | "lockStages" // 属性等级无法被提升或降低
    | "drain" // 能将伤害值的 f 转化来回复自己
    | "doom" // 若对方受到伤害，chance 被秒杀
    | "ppdrain" // 每回合扣除对方所有PP n 点
    | "plague" // 回合结束时: chance of status on the holder
    | "painsplit" // 回合结束时: chance to share the HP when the other has more (黄金天秤)
    | "mirror" // the other's raised stages are raised for the holder too (远古记忆)
    | "punish" // 回合结束时: n HP off the holder if it used no damaging skill (战争饥渴)
    | "revert" // when it ends: its stage change is undone (速战意念)
    | "blind"; // the holder's 普通攻击 hit by phys % (封魔秘诀: 很难命中)
  n?: number;
  a?: number;
  b?: number;
  f?: number;
  chance?: number;
  phys?: number;
  spec?: number;
  attr?: number;
  mult?: number;
  add?: number;
  lost?: boolean;
  self?: number;
  stats?: StatKey[];
  delta?: number;
  status?: StatusName;
  statusAlt?: StatusName;
  /** Ends when the 亚比 is switched out (替换亚比解除). */
  endsOnSwitch?: boolean;
  /** onhurt: the stages are the holder's (else the attacker's). */
  selfStage?: boolean;
  /** onhurt: both statuses (饺气: 混乱和中毒), not one of them. */
  bothStatus?: boolean;
  /** Only while the holder has this status (it ends with it). */
  while?: StatusName;
  /** Only while the other 亚比 has this status. */
  whileOther?: StatusName;
  /** stagesEachTurn: random values of `stats`, this many. */
  pick?: number;
  /** Ends after it worked once. */
  once?: boolean;
  /** A trait's boost (闇月马戏团): one at a time. */
  trait?: boolean;
  /** The turns are a random number from turnsMin to turns. */
  turnsMin?: number;
  /** It may be used again while it lasts, up to this many at once (曙光). */
  stack?: number;
  /** revert: how much each of `stats` moved. */
  deltas?: number[];
  /** screen: each turn against 普通 or 特殊攻击, at random (龙之逆鳞). */
  flip?: boolean;
  /** The skill it came from. */
  from?: string;
  /** nostatus: only these statuses (幻境: 睡眠和害怕). */
  only?: StatusName[];
}

export interface SkillEffects {
  status?: StatusRoll;
  /** The statuses of the skill, each rolled apart (穿石之矛: 20%混乱, 20%束缚). */
  statuses: StatusRoll[];
  stages: StageChange[];
  drain?: number;
  drainCond?: Cond;
  /** 溢出的回复量会转化为自己的护盾: what the heal could not give becomes points of 护盾. */
  overShield?: boolean;
  recoil?: number;
  recoilChance?: number;
  /** 攻击全场 / 给全场亚比造成伤害: the whole field, the user too (the same blow on itself). */
  wholeField?: boolean;
  heal?: number;
  hits?: [number, number];
  /** A 连击's secondary effect ("每次攻击有10%概率…", "每次命中都会…") rolls for each hit. */
  perHit?: boolean;
  sure?: boolean;
  highCrit?: boolean;
  first?: boolean;
  /** 后发: moves after the other. */
  last?: boolean;
  recharge?: boolean;
  rechargeChance?: number;
  fixed?: number;
  fixedChance?: number;
  fixedRange?: [number, number];
  ohko?: number;
  selfConfuse?: boolean;
  boost?: { chance: number; mult: number; cond?: Cond }[];
  /** The skill's accuracy instead of the table's (八方雷动: 命中很低). */
  acc?: number;
  // ---- the damage itself
  /** The damage, not by the formula: points, the user's or foe's level times, half the foe's HP… */
  dmg?:
    | { kind: "flat"; n: number }
    | { kind: "level"; a: number; b: number }
    | { kind: "foeLevel"; mult: number }
    | { kind: "hpFrac"; f: number }
    | { kind: "maxFrac"; f: number }
    | { kind: "range"; a: number; b: number };
  /** The damage dealt by dmg also heals the user (n points, or all of it). */
  dmgHeals?: number | "all";
  /** When cond holds: power times mult, power set, fixed damage added, or another drain. */
  powerIf?: { cond: Cond; mult?: number; set?: number; add?: number; drain?: number; power?: number; heal?: number }[];
  powerRange?: [number, number];
  /** Power by the HP: "low" (the less, the more), "high" (the more, the more), "foeHigh". */
  powerByHp?: "low" | "high" | "foeHigh";
  powerBySpeed?: "fast" | "slow";
  /**
   * 连续攻击N回合: the skill goes on by itself its N turns (min~N), its power growing each turn:
   * double, or +add. A miss takes the growth back to the start (攻击失误则清除加倍效果), save
   * when it grows whether it hits or not (always: 不管命中与否).
   */
  rollout?: { turns: number; add?: number; min?: number; always?: boolean };
  falseSwipe?: boolean;
  endeavor?: boolean;
  painSplit?: boolean;
  painSplitChance?: number;
  swapHp?: boolean;
  ohkoIf?: { chance: number; lowerLevel?: boolean; hpBelow?: number; cond?: Cond };
  ignoreDef?: boolean;
  /** Nothing stops it: protects, dodges and shields (无法阻挡). */
  pierce?: boolean;
  critIf?: Cond;
  critChance?: number;
  extraHits?: { chance: number; n: number }[];
  /** After the hit: heal a fraction of the most HP (chance). */
  healAfter?: { f: number; chance: number; cond?: Cond };
  /** Before it acts: costs a fraction of the most HP, or points. */
  selfCost?: { f?: number; n?: number; current?: boolean; chance?: number };
  sacrifice?: boolean;
  bothFaint?: boolean;
  /** The foe's defence values lowered (令对方防御值减半: as 2 levels). */
  // ---- PP
  ppFoe?: { n: number | "all"; last?: boolean; chance: number; cond?: Cond };
  ppSelf?: number;
  ppSelfAll?: boolean;
  // ---- healing and statuses of the user
  healFull?: boolean;
  healFlat?: number;
  healChance?: number;
  cure?: boolean;
  sleepAfter?: number;
  // ---- stages beside stages[]
  clearFoeUps?: { chance: number; stats?: StatKey[] };
  restoreOwn?: { chance: number };
  resetFoe?: boolean;
  resetSelf?: boolean;
  swapStages?: boolean;
  copyFoeUps?: { chance: number };
  passDowns?: boolean;
  stealStages?: { stats: StatKey[]; delta: number; minDmg?: number };
  /** 防御与攻击，特防与特攻 swap their stages. */
  swapOwnStages?: boolean;
  // ---- lasting things
  timed: Timed[];
  field?: { up: number; upPct: number; down?: number; downPct?: number; turns: number };
  charge?: boolean;
  chargeFirst?: boolean;
  /** 蓄力N回合: the turns of gathering before the blow (1 when not said). */
  chargeTurns?: number;
  lock?: { turns: [number, number]; after: "confuse" | "rest" | "heal" | "none"; healF?: number };
  protect?: boolean;
  endure?: "revive" | "reviveOnce";
  destiny?: boolean;
  /**
   * At the end of a later turn: rebirth is 满状态回复 and the other 害怕 (神圣涅槃), stages its
   * stage change (潜龙勿用), badStatus one of the bad statuses by chance.
   */
  delayed?: {
    who: "self" | "foe";
    turns: number;
    kind: "healFull" | "sleep" | "flat" | "hpFrac" | "maxFrac" | "kill" | "hpTo1" | "rebirth" | "stages" | "badStatus";
    n?: number;
    f?: number;
    stats?: StatKey[];
    delta?: number;
    chance?: number;
  };
  /** By this chance the user or the other (half and half) stops its next turn (原子爆裂). */
  eitherStops?: number;
  trap?: [number, number];
  forceSwitch?: boolean;
  nextFullHeal?: boolean;
  reviveNext?: boolean;
  /** After a KO of the foe: heal this fraction of the most HP. */
  healOnKO?: number;
  /** 解除自己冰冻状态 (or 烧伤). */
  unstatus?: StatusName;
  /** 本回合受到伤害时至少为自己保留1点体力值. */
  hold?: boolean;
  /** Each use in a battle less sure (protect, hold). */
  fade?: boolean;
  /** dmg lands only by this chance (鬼火: 一定概率). */
  dmgChance?: number;
  /** Its stage changes only on a crit (暴击后). */
  stagesIfCrit?: boolean;
  /** 回复敌我双方的体力值. */
  healBoth?: boolean;
  /** 本回合自己若被对方打败，则扣除对方所有技能的PP. */
  grudge?: boolean;
  /** 本回合: the damage taken this turn heals instead (混沌吸收). */
  absorbHit?: boolean;
  /** The user rests this many turns after (霜冻风暴: 3). */
  rechargeTurns?: number;
  ohkoDoubleIf?: Cond;
  /** 重置双方提升的能力等级. */
  clearBothUps?: boolean;
  /** This turn: of the foe's damage the user takes `take` and sends `reflect` back (水晶之镜, 反击). */
  shield?: { take: number; reflect: number; kind?: "phys" | "spec"; ifFirst?: boolean; ifAlive?: boolean };
  /** A protect that fails heals this much (使用失败则回复). */
  failHeal?: number;
  /** The stages fail by 1 - their chance: then this much HP is lost (七十二变). */
  failCost?: number;
  /** 将自己不良状态转移给对方. */
  passStatus?: boolean;
  /** 按比例调换双方体力 when the user's share is lower: chance. */
  swapHpRatio?: number;
  /** Each crit heals this fraction of the most HP (龙虎乱舞). */
  critHeal?: number;
  /** Heals this fraction of the HP lost (龙神庇护). */
  healLost?: number;
  /** 束缚 for as many turns as hits (黏黏黏). */
  bindHits?: boolean;
  /** A status by the number of hits (镜像世界). */
  hitStatus?: Record<number, StatusName>;
  /** At the end of the turn the foe heals this much (灵魂超度). */
  healFoeEnd?: number;
  /** 双攻、双防和速度基础数值 up by pct, at most max times a battle. */
  baseUp?: { pct: number; max: number };
  /** The foe's 基础 value lowered by n points. */
  baseDown?: { stat: "atk" | "satk"; n: number };
  /** By this chance the foe's raised defence stages do not count. */
  ignoreUps?: number;
  /** By this chance the stage changes count twice. */
  stageDouble?: number;
  /** More hits when this holds (奥特冰刃: 若对方处于冰冻，可多攻击2次), or this many. */
  hitsIf?: { cond: Cond; add?: number; set?: number };
  /** Copies all the foe's stages (回忆收集), not only its raised ones. */
  copyAll?: boolean;
  /** The stage changes, regen… go to the user by this chance, else to the foe (命运). */
  fate?: number;
  /** Fixed damage, halved when the foe resists the skill's 属性, ×1.5 when weak to it. */
  dmgByType?: boolean;
  /** Its chances grow with each use in a battle. */
  grow?: boolean;
  /** Gives the foe a mark that lowers its 双攻基础数值 by downPct (陶醉). */
  markFoe?: { name: string; downPct: number };
  /** Uses this many PP. */
  ppCost?: number;
  /** Adds half the power of the foe's last skill. */
  copyPower?: boolean;
  /** For each 亚比 in the fight with this trait (马戏团, 超暗黑): its damage times power, its stages. */
  trait?: { name: string; side?: "self" | "all"; power?: number; stats?: StatKey[]; delta?: number; deltaMax?: number; statmult?: { stats: StatKey[]; mult: number; turns: number } };
  /** 秒杀 that fails kills the user (命运硬币). */
  ohkoFailFaint?: boolean;
  /** ppSelf only by this chance. */
  ppSelfChance?: number;
  /** The lasting effects of this skill go when it comes (不能和“X”同时存在). */
  exclusiveWith?: string;
  /** protect only when the user moves first. */
  protectIfFirst?: boolean;
  /** Its damage-power grows by `add` for each hit (大道无形). */
  perHitPower?: number;
}

export interface StatusRoll {
  name: StatusName;
  chance: number;
  turns?: [number, number];
  self?: boolean;
  cond?: Cond;
  /** The chance grows as the user's HP falls (魔电闪). */
  byLowHp?: boolean;
  /** The chance grows with the user's 速度 stage (火烧千里). */
  bySpeed?: boolean;
  /** The chance doubles when this holds (灵冰幻舞). */
  doubleIf?: Cond;
  /** Another chance when this holds (斗破轩辕: 50% on a crit). */
  condChance?: { cond: Cond; chance: number };
}

// ---------------------------------------------------------------- reading

const CN: Record<string, string> = { 一: "1", 二: "2", 两: "2", 三: "3", 四: "4", 五: "5", 六: "6", 七: "7", 八: "8", 九: "9", 十: "10" };
const FRACS: Record<string, string> = { 四分之一: "1/4", 三分之一: "1/3", 二分之一: "1/2", 三分之二: "2/3", 八分之一: "1/8" };

/** The description as the readers take it: half-width signs, digits for 一二两三…, the synonyms. */
export function normalise(desc: string): string {
  let d = String(desc || "")
    .replace(/％/g, "%")
    .replace(/[～〜]/g, "~")
    .replace(/(\d)\s*[-－—]\s*(\d)/g, "$1~$2")
    .replace(/[（]/g, "(")
    .replace(/[）]/g, ")")
    .replace(/[：]/g, ":")
    .replace(/[“”"]/g, "")
    .replace(/[３]/g, "3")
    .replace(/机率/g, "概率")
    .replace(/回避/g, "闪避")
    .replace(/对手/g, "对方")
    .replace(/催眠/g, "睡眠")
    .replace(/先发后至/g, "先发")
    .replace(/普攻攻击/g, "普通攻击")
    .replace(/普通攻击和特殊攻击|特殊攻击和普通攻击|普通和特殊/g, "普通攻击与特殊攻击")
    .replace(/等级的等级/g, "的等级")
    .replace(/(\d)等级/g, "$1级")
    .replace(/(\d)个等级/g, "$1级")
    .replace(/(\d+)\s*个回合/g, "$1回合")
    .replace(/，(?:此)?技能威力(?=加倍|提升至\d)/g, "，威力")
    .replace(/(\d+)%(?=削弱|提升|令|使|降低)/g, "$1%概率")
    .replace(/次回合自己无法行动/g, "下回合自己停止行动")
    .replace(/若暴击，(?:则)?(?=提升)/g, "暴击后");
  for (const [k, v] of Object.entries(FRACS)) d = d.split(k).join(v);
  d = d.replace(/([一二两三四五六七八九十])(级|回合|次|点|倍|种|个)/g, (_m, a: string, b: string) => CN[a] + b);
  d = d
    .replace(new RegExp(`(\\d级)和(?=${STAT_RE})`, "g"), "$1，")
    .replace(/停止1回合|不能行动1回合/g, "停止行动1回合");
  // A list of values written with commas: "特攻，命中，速度和暴击" -> "特攻、命中、速度和暴击".
  for (let i = 0; i < 4; i++) d = d.replace(new RegExp(`(${STAT_RE})[，,](?=${STAT_RE})`, "g"), "$1、");
  return d;
}

const num = (s: string | undefined, dflt = 0) => (s === undefined || s === "" ? dflt : Number(s));
const frac = (s: string) => {
  if (s === "一半" || s === "1/2") return 0.5;
  if (s === "全部" || s === "所有") return 1;
  const m = s.match(/^(\d+)\/(\d+)$/);
  if (m) return Number(m[1]) / Number(m[2]);
  const p = s.match(/^(\d+(?:\.\d+)?)%$/);
  if (p) return Number(p[1]) / 100;
  return Number(s) || 0;
};
const pct = (s: string | undefined) => (s ? Math.min(100, Number(s)) : 100);
const statsOf = (list: string): StatKey[] => [...new Set(list.split(/和|、|及|与/).flatMap((w) => STAT_WORDS[w] ?? []))];
const statusOf = (s: string): StatusName => s as StatusName;

/** Words that only say what kind of skill it is, or where its limits are (bosses, switching). */
const FILLER = [
  /攻击对方(?:单体|全体|全场|随机目标|单个)?(?:亚比)?/g,
  /给对方(?:单体|全体|全场)?(?:亚比)?造成伤害/g,
  /给(?:全场|对方全体)亚比造成伤害/g,
  /攻击(?:自己以外的)?全场(?:亚比)?/g,
  /攻击自己以外的全场亚比/g,
  /对方每个目标均有/g,
  /威力(?:十分)?巨大|破坏力巨大|威力不可小觑|难以想象、极其恐怖的破坏力|威力很大/g,
  /(?:对|对于)?(?:某些|大多数|大部分)?(?:BOSS|boss|守护者?|守护的?)(?:会产生抵抗|无效|效果会削弱|效果减半|的概率和效果会削弱|回复效果减半|效果会减半)/g,
  /(?:可是)?(?:对|对于)(?:某些|大多数|大部分)?(?:BOSS|boss|守护者?)[^，；。]*/g,
  /可是|回复效果减半|当回合|直至病毒死亡|攻击等级越高，概率越高|自己速度等级越高效果越强|若对方是青龙守护，则伤害和效果概率加倍|对对方单体造成伤害/g,
  /(?:替换|交换|更换)亚比(?:有效|无效)/g,
  /对守护(?:者)?无效/g,
  /我方全体(?:亚比|队员)?|我方单个亚比|以后|不需要任何解释的强大|恢复效果不能叠加|自己等级越高(?:伤害|威力)越(?:高|大)|命中次数越多，威力越大|威力递增/g,
  /宁教我负天下人，休教天下人负我|老骥伏枥，志在千里，烈士暮年，壮心不已|向对方全体亚比派发大量福袋|通过命运的力量/g,
  /(?:替换|交换)亚比(?:有效|无效|可解除|解除(?:此)?效果|后(?:效果)?消失)/g,
  /不可叠加(?:使用)?|不能叠加|效果不能叠加|可以叠加使用|可接力/g,
  /(?:持续|5回合)?有效/g,
  /向对方单体扔出两把刷子/g,
  /将周围的水分变为无数根水针来/g,
  /孤好梦中杀人|周公吐哺，天下归心|觉醒技|通过命运的力量|传说中|吞噬对方的时间/g,
  /至少能为对方亚比|再用亚比球捕捉会比较容易成功/g,
  /给对方单体造成巨大伤害|撞击对方全体|对属性攻击无效|保护自己|额外/g,
  /(?:持续|在)?\d+回合(?:内|有效)?/g,
  /对方单体|对方全体|单体/g,
  /(?:对某些守护)?效果较弱|自己速度越快，成功概率越高|使用1次/g,
  /本回合|使用后|命中后|命中则|命中|攻击|并且|并|且|但|同时|另外|则|的|，|；|。|,|;|\.|、|!|！|\s/g,
];

class Reader {
  readonly d: string;
  private left: string;
  constructor(desc: string) {
    this.d = normalise(desc);
    this.left = this.d;
  }

  /** Every match of re in what is left: fn(match); the words are taken (they are read). */
  take(re: RegExp, fn: (m: RegExpMatchArray) => void | false): boolean {
    const g = new RegExp(re.source, re.flags.includes("g") ? re.flags : re.flags + "g");
    let any = false;
    for (const m of [...this.left.matchAll(g)]) {
      if (fn(m) === false) continue;
      any = true;
      this.left = this.left.slice(0, m.index!) + "＿".repeat(m[0].length) + this.left.slice(m.index! + m[0].length);
    }
    return any;
  }

  /** Is re in the words left? */
  has(re: RegExp): boolean {
    return re.test(this.left);
  }

  /** The words no reader took (fillers aside). */
  unread(): string {
    let s = this.left;
    for (const f of FILLER) s = s.replace(f, "");
    return s.replace(/＿+/g, " ").replace(/\s+/g, " ").trim();
  }
}

/** Read a description: its effects, and the words not read. */
export function readSkill(desc: string): { fx: SkillEffects; unread: string } {
  const r = new Reader(desc);
  const e: SkillEffects = { stages: [], statuses: [], timed: [] };
  // The whole field (not 自己以外的全场, not 对方全场): the user is hit too. The words stay for FILLER.
  if (/攻击全场|给全场亚比造成伤害/.test(desc)) e.wholeField = true;
  const cond = (s: string): Cond | undefined => {
    let m: RegExpMatchArray | null;
    if ((m = s.match(/对方(?:被|处于)?(麻痹|冰冻|睡眠|烧伤|中毒|混乱|束缚|衰弱|寄生)/))) return { foeStatus: statusOf(m[1]) };
    if (/自己(?:中毒、麻痹或烧伤|处于异常状态)/.test(s)) return { selfStatus: /异常/.test(s) ? "any" : ["中毒", "麻痹", "烧伤"] };
    if ((m = s.match(/对方体力值(?:小于|低于|少于)(1\/2|一半|1\/4)/))) return { foeHpBelow: frac(m[1]) };
    if ((m = s.match(/自(?:己|身)(?:剩余)?体力值?(?:小于|低于|少于)(1\/2|一半|1\/4)/))) return { selfHpBelow: frac(m[1]) };
    if ((m = s.match(/自(?:己|身)(?:剩余)?体力值?(?:大于|高于|多于)(1\/2|一半)/))) return { selfHpAbove: frac(m[1]) };
    if (/对方体力值(?:多过|比)自己多|对方体力值多于自己/.test(s)) return { foeHpMore: true };
    if (/对方体力值比自己少/.test(s)) return { foeHpLess: true };
    if (/自己后出手|^后发$/.test(s)) return { second: true };
    if (/自己速度比对方慢/.test(s)) return { slower: true };
    if (/自己(?:出手)?速度(?:快过|比)对方(?:快)?/.test(s)) return { faster: true };
    if (/暴击/.test(s)) return { crit: true };
    return undefined;
  };

  const turnsOf = (s: string, dflt: number) => {
    const m = s.match(/(?:持续|在|接下来)?(\d+)回合|(\d+)回合内|持续(\d+)回合/);
    return m ? num(m[1] ?? m[2] ?? m[3]) : dflt;
  };
  // 不能和“X”同时存在: X's lasting effects go when this one comes (正电极盾 and 负电极盾).
  {
    const x = r.d.match(/不能和(?:技能)?(\S{2,6}?)(?:效果)?同时存在/);
    if (x) e.exclusiveWith = x[1];
  }
  // ---- one skill's words, read before the general readers take a part of them
  r.take(/1\/3概率秒杀对方单体，2\/3自己死亡/, () => {
    e.ohkoIf = { chance: 100 / 3 };
    e.ohkoFailFaint = true;
  });
  r.take(new RegExp(`^(提升|削弱)(自己|对方单体)(${STAT_LIST})等级(\\d+)级，持续(\\d+)回合$`), (m) => {
    e.stages.push({ self: m[2] === "自己", stats: statsOf(m[3]), delta: (m[1] === "提升" ? 1 : -1) * num(m[4]), chance: 100, turns: num(m[5]) });
  });
  r.take(/(\d+)%概率回复自己所有PP(\d+)点/, (m) => {
    e.ppSelf = num(m[2]);
    e.ppSelfChance = num(m[1]);
  });
  r.take(/(\d+)回合内附加(\d+)~(\d+)点伤害值?/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: num(m[1]), a: num(m[2]), b: num(m[3]) }));
  r.take(/令对方衰弱，对方损失的体力值会逐渐增加(?:，持续(\d+)回合)?/, (m) => void e.statuses.push({ name: "衰弱", chance: 100, ...(m[1] ? { turns: [num(m[1]), num(m[1])] as [number, number] } : {}) }));
  r.take(/若对方体力值比自己多，则有(\d+)%概率平分双方体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "painsplit", turns: num(m[2]), chance: num(m[1]) }));
  r.take(/我方全体(数码)系亚比防御值增加(\d+)%，特防值增加\d+%，持续(\d+)回合/, (m) => {
    e.trait = { name: m[1] + "系", side: "self", statmult: { stats: ["def", "sdef"], mult: 1 + num(m[2]) / 100, turns: num(m[3]) } };
  });
  r.take(/使用后(\d+)回合内，每回合将自己所有PP值1点转化来回复(\d+)点体力值，可以叠加使用，最多叠加(\d+)次/, (m) => void e.timed.push({ who: "self", kind: "pphp", turns: num(m[1]), n: num(m[2]), stack: num(m[3]) }));
  r.take(/(\d+)回合内，对方提升能力等级也会给自己提升/, (m) => void e.timed.push({ who: "self", kind: "mirror", turns: num(m[1]) }));
  r.take(/持续(\d+)回合，自己属性能力等级不能被削弱；若对方提升它的属性能力等级，同样也会加给自己/, (m) => {
    e.timed.push({ who: "self", kind: "guard", turns: num(m[1]) });
    e.timed.push({ who: "self", kind: "mirror", turns: num(m[1]) });
  });
  r.take(/(?:使用后)?自身战斗力瞬间破表，额外增强自己双攻、双防和速度基础数值的(\d+)%，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "statmult", turns: num(m[2]), stats: FIVE_STATS, mult: 1 + num(m[1]) / 100 }));
  r.take(new RegExp(`(\\d+)%概率令对方(${ST})，若暴击则(\\d+)%概率令对方(?:${ST})`), (m) => void e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]), condChance: { cond: { crit: true }, chance: num(m[3]) } }));
  r.take(/使用后(\d+)回合内，若当回合对方不使用攻击技能，则当回合结束时扣除对方(\d+)点体力值/, (m) => void e.timed.push({ who: "foe", kind: "punish", turns: num(m[1]), n: num(m[2]) }));
  r.take(/恢复自己所有被削弱的属性能力等级并清除自己的不良状态，且(\d+)~(\d+)回合内不受不良状态影响/, (m) => {
    e.restoreOwn = { chance: 100 };
    e.cure = true;
    e.timed.push({ who: "self", kind: "nostatus", turns: num(m[2]), turnsMin: num(m[1]) });
  });
  r.take(/(?:使用后，)?(\d+)%概率闪避特殊攻击技能造成的伤害，持续(\d+)~(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num(m[3]), turnsMin: num(m[2]), spec: num(m[1]) }));
  r.take(/连续攻击对方(\d+)~(\d+)回合，威力每回合递增/, (m) => void (e.rollout = { turns: num(m[2]), min: num(m[1]) }));
  r.take(new RegExp(`(\\d+)%概率令对方(${ST})同时(${ST})`), (m) => {
    e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]) }, { name: statusOf(m[3]), chance: 100, cond: { landed: true } });
  });
  // Skills that work with another one (its name: the user used it, and its effect lasts).
  const mk = (n: string): Cond => ({ mark: n.replace(/[“”"]/g, "") });
  r.take(/若存在技能(\S+?)的效果，此技能威力可以再增加(\d+)/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), power: num(m[2]) }));
  r.take(/使用后能给\S+?类的技能附加特殊效果|并且下次使用\S+?技能效果提升/, () => undefined);
  r.take(/有(\S+?)效果存在的话，能将伤害值的(1\/3)转化来回复自己体力值/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), drain: frac(m[2]) }));
  r.take(/有(\S+?)效果存在的话，有一定概率令对方处于各种异常状态/, (m) => {
    for (const st of BAD_STATUSES) e.statuses.push({ name: st, chance: 30 / BAD_STATUSES.length, cond: mk(m[1]) });
  });
  r.take(/恢复被降低的属性/, () => void (e.restoreOwn = { chance: 100 }));
  r.take(/有(\S+?)存在的话，回复效果提升至(1\/2)/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), heal: frac(m[2]) }));
  r.take(new RegExp(`(\\d+)%概率削弱对方(${STAT_LIST})(\\d+)级；有(\\S+?)存在的话，额外增加(\\d+)%概率`), (m) => {
    e.stages.push({ self: false, stats: statsOf(m[2]), delta: -num(m[3]), chance: num(m[1]), condChance: { cond: mk(m[4]), chance: num(m[1]) + num(m[5]) } });
  });
  r.take(/有(\S+?)存在的话，增加(\d+)次攻击/, (m) => void (e.hitsIf = { cond: mk(m[1]), add: num(m[2]) }));
  r.take(/消耗(\d+)倍的技能PP提升\S+的效果/, (m) => void (e.ppCost = num(m[1])));
  r.take(/使用(\S+?)后技能威力可提升至(\d+)/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), set: num(m[2]) }));
  r.take(/使用技能(\S+?)后，本技能威力提升(\d+)%/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1]), mult: 1 + num(m[2]) / 100 }));
  r.take(/命中则令对方获得(陶醉)标记，对方双攻基础数值减少(\d+)%；若对方已陶醉则(?:(\d+)%概率(提升自身双防等级1级|令对方混乱)|将伤害值的(\d+)%转化来回复自己)/, (m) => {
    e.markFoe = { name: m[1], downPct: num(m[2]) };
    const c: Cond = { foeMark: m[1] };
    if (m[5]) (e.powerIf ??= []).push({ cond: c, drain: num(m[5]) / 100 });
    else if (/混乱/.test(m[4])) e.statuses.push({ name: "混乱", chance: num(m[3]), cond: c });
    else e.stages.push({ self: true, stats: ["def", "sdef"], delta: 1, chance: num(m[3]), cond: c });
  });
  r.take(/先复制对方上回合使用的技能的威力的一半，加上本技能的威力/, () => void (e.copyPower = true));
  r.take(/削弱对方全体(光明)与(暗黑)技能威力的(\d+)%，效果持续(\d+)回合/, (m) => {
    for (const a of [m[1], m[2]]) e.timed.push({ who: "foe", kind: "power", turns: num(m[4]), mult: 1 - num(m[3]) / 100, attr: ATTRS[a] });
  });
  r.take(/使用后，下次出手攻击对方时，吸取(\d+)%体力值用来回复自己/, (m) => void e.timed.push({ who: "self", kind: "drain", turns: 99, f: num(m[1]) / 100, once: true }));
  r.take(/若自己速度快过对方，则无视对方本回合攻击/, () => {
    e.protect = true;
    e.protectIfFirst = true;
  });
  r.take(/(?:使用后)?受到伤害则减半，并额外提升自己伤害能力(\d+)%，持续(\d+)回合/, (m) => {
    e.timed.push({ who: "self", kind: "screen", turns: num(m[2]), phys: 0.5, spec: 0.5 });
    e.timed.push({ who: "self", kind: "power", turns: num(m[2]), mult: 1 + num(m[1]) / 100 });
  });
  r.take(/使用后受到伤害则减半，每次受到伤害都有(\d+)%概率削弱对方全属性(\d+)级，持续(\d+)回合/, (m) => {
    e.timed.push({ who: "self", kind: "screen", turns: num(m[3]), phys: 0.5, spec: 0.5 });
    e.timed.push({ who: "self", kind: "onhurt", turns: num(m[3]), chance: num(m[1]), stats: ALL_STATS, delta: -num(m[2]) });
  });
  r.take(/使用后(\d+)回合内，?自己受到特殊攻击时伤害减半；若受到普通攻击，则将受到伤害的(\d+\/\d+)返击对方/, (m) => {
    e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), spec: 0.5 });
    e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]) });
  });
  r.take(/使用后(\d+)回合内受到普通或特殊攻击，都有(\d+)%概率令对方(烧伤)或者(睡眠)/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num(m[1]), chance: num(m[2]), status: statusOf(m[3]), statusAlt: statusOf(m[4]) }));
  r.take(/扣除对方单体(\d+)点体力值，自己回复(\d+)点体力值/, (m) => {
    e.dmg = { kind: "flat", n: num(m[1]) };
    e.dmgHeals = num(m[2]);
  });
  r.take(/若对方(烧伤)，自己回复(\d+\/\d+)体力值/, (m) => void (e.healAfter = { f: frac(m[2]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
  r.take(/提升我方全体伤害(\d+)%，闪避等级(\d+)级/, (m) => {
    e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num(m[1]) / 100 });
    e.stages.push({ self: true, stats: ["eva"], delta: num(m[2]), chance: 100 });
  });
  r.take(new RegExp(`使用后，每回合提升自己(?:的)?(${STAT_LIST})(?:的)?等级各?(\\d+)级(?:，并提升自己伤害抵抗能力(\\d+)%)?，持续(\\d+)回合`), (m) => {
    e.timed.push({ who: "self", kind: "stagesEachTurn", turns: num(m[4]), stats: statsOf(m[1]), delta: num(m[2]), chance: 100 });
    if (m[3]) e.timed.push({ who: "self", kind: "screen", turns: num(m[4]), phys: 1 - num(m[3]) / 100, spec: 1 - num(m[3]) / 100 });
  });
  r.take(/(?:使用后接下来(\d+)回合，)?(?:自己|我方全体)?(光明|飞行)系技能威力提升(\d+)%，伤害抵抗(?:能力)?提升(\d+)%(?:，持续(\d+)回合)?/, (m) => {
    const turns = num(m[1] || m[5], turnsOf(r.d, 3));
    e.timed.push({ who: "self", kind: "power", turns, mult: 1 + num(m[3]) / 100, attr: ATTRS[m[2]] });
    e.timed.push({ who: "self", kind: "screen", turns, phys: 1 - num(m[4]) / 100, spec: 1 - num(m[4]) / 100 });
  });
  r.take(/(\d+)%概率作用给自己，(\d+)%概率作用给对方/, (m) => void (e.fate = num(m[1])));
  r.take(/每回合恢复(\d+)体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num(m[2]), n: num(m[1]) }));
  r.take(/我方剩余体力值越少，对方剩余体力值越多，威力越大/, () => void (e.powerByHp = "low"));
  r.take(/对方剩余体力值越多，?威力越大/, () => void (e.powerByHp = "foeHigh"));
  r.take(/(?:本回合不行动|本回合停止行动|本回合休息，提升暴击率)，下回合(先发)?(?:自动)?攻击对方(?:单体)?/, (m) => {
    e.charge = true;
    if (m[1]) e.chargeFirst = true;
    if (/暴击/.test(m[0])) e.highCrit = true;
  });
  r.take(/下回合攻击对方(\d+)~(\d+)次/, (m) => {
    e.charge = true;
    e.hits = [num(m[1]), num(m[2])];
  });
  r.take(/给(?:自己的伤害|每次攻击)附加(\d+)点伤害值，持续(\d+)(?:回合|次攻击|次)/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: num(m[2]), n: num(m[1]) }));
  r.take(/使用后(\d+)回合内，每回合将自己所有PP值1点转化来回复(\d+)点体力值(?:，可以叠加使用)?(?:，最多叠加\d+次)?/, (m) => void e.timed.push({ who: "self", kind: "pphp", turns: num(m[1]), n: num(m[2]) }));
  r.take(/若暴击，(?:则)?令对方(麻痹|害怕|混乱)/, (m) => void e.statuses.push({ name: statusOf(m[1]), chance: 100, cond: { crit: true } }));
  r.take(new RegExp(`若暴击，每次暴击提升自身(${STAT_LIST})(\\d+)级`), (m) => void e.stages.push({ self: true, stats: statsOf(m[1]), delta: num(m[2]), chance: 100, cond: { crit: true } }));
  r.take(/若造成的伤害值含9或为9的倍数，则(?:将伤害值的(\d+)%转化来回复自己|必定令对方(混乱))/, (m) => {
    if (m[1]) {
      e.drain = num(m[1]) / 100;
      e.drainCond = { nine: true };
    } else e.statuses.push({ name: statusOf(m[2]), chance: 100, cond: { nine: true } });
  });
  r.take(/若自己处于(束缚)状态，则将造成伤害的(1\/2)转化来回复自己/, (m) => {
    e.drain = frac(m[2]);
    e.drainCond = { selfStatus: [statusOf(m[1])] };
  });
  r.take(/若对方处于(烧伤)状态，则威力提升为(\d+(?:\.\d+)?)倍/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[1]) }, mult: num(m[2]) }));
  r.take(/(?:使用后)?自身战斗力瞬间破表，额外增强自己双攻、双防和速度基础数值的(\d+)%/, (m) => void (e.baseUp = { pct: num(m[1]), max: 1 }));
  r.take(/无视对方本回合攻击|无视当回合对方的伤害|闪避对方的攻击/, () => void (e.protect = true));
  r.take(/本回合若被对方打败，则立即恢复到生命最大值/, () => void (e.endure = "revive"));
  r.take(/使用后防御与攻击、特防与特攻属性等级交换/, () => void (e.swapOwnStages = true));
  r.take(/一场战斗使用次数越高，成功率越高/, () => void (e.grow = true));
  r.take(/扣除对方剩余体力值的(1\/2)来转化回复自己的体力值/, (m) => {
    e.dmg = { kind: "hpFrac", f: frac(m[1]) };
    e.dmgHeals = "all";
  });
  r.take(/(\d+)\/(\d+)概率令对方(害怕|麻痹|混乱)/, (m) => void e.statuses.push({ name: statusOf(m[3]), chance: (num(m[1]) * 100) / num(m[2]) }));
  r.take(/(?:并)?解除自己(冰冻|烧伤)状态/, (m) => void (e.unstatus = statusOf(m[1])));
  r.take(/给对方单体造成(\d+)伤害值；微弱伤害减半，克制伤害变为原来的(\d+(?:\.\d+)?)倍/, (m) => {
    e.dmg = { kind: "flat", n: num(m[1]) };
    e.dmgByType = true;
  });
  r.take(/持续(\d+)回合进入隐身状态，(\d+)%概率无视对方的特殊攻击，自己攻击等级下降(\d+)级，但受到普通攻击的伤害会加倍/, (m) => {
    e.timed.push({ who: "self", kind: "dodge", turns: num(m[1]), spec: num(m[2]) });
    e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), phys: 2 });
    e.stages.push({ self: true, stats: ["atk"], delta: -num(m[3]), chance: 100 });
  });
  r.take(/替换亚比则会立即解除隐身状态/, () => undefined);
  r.take(/使用后(\d+)回合内，若受到伤害，则将伤害的(1\/3)返还给对方，并有(1\/3)的概率令对方(害怕)/, (m) => {
    e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]), spec: frac(m[2]) });
    e.timed.push({ who: "self", kind: "onhurt", turns: num(m[1]), chance: frac(m[3]) * 100, status: statusOf(m[4]) });
  });
  r.take(/令自身束缚(\d+)回合，\d+回合内每回合回复自身(\d+)点体力值/, (m) => {
    e.statuses.push({ name: "束缚", chance: 100, turns: [num(m[1]), num(m[1])], self: true });
    e.timed.push({ who: "self", kind: "regen", turns: num(m[1]), n: num(m[2]) });
  });
  r.take(/若对方烧伤，则将对方烧伤的体力值用来回复自己/, () => void e.timed.push({ who: "foe", kind: "leech", turns: 99, f: 1 / 8, while: "烧伤" }));
  r.take(/若对方害怕则吸取对方体力最大值的(1\/10)用来回复自己体力值/, () => undefined);
  r.take(/发动时此技能威力提升至(\d+)倍，但是命中很低/, (m) => {
    (e.boost ??= []).push({ chance: 100, mult: num(m[1]) });
    e.acc = 30;
  });
  r.take(/但是只有一半的命中率/, () => void (e.acc = 50));
  r.take(/自己速度比对方(慢|快)，则威力加倍，否则减半/, (m) => {
    const slow = m[1] === "慢";
    (e.powerIf ??= []).push({ cond: slow ? { slower: true } : { faster: true }, mult: 2 }, { cond: slow ? { faster: true } : { slower: true }, mult: 0.5 });
  });
  r.take(/若对方体力值比自己多，则发动2倍威力；若对方体力值比自己少，则发动1\/2倍威力/, () => {
    (e.powerIf ??= []).push({ cond: { foeHpMore: true }, mult: 2 }, { cond: { foeHpLess: true }, mult: 0.5 });
  });
  r.take(/自己体力值少于一半时，威力加倍；自己体力值小于1\/4时，威力提升至4倍/, () => {
    (e.powerIf ??= []).push({ cond: { selfHpBelow: 0.25 }, mult: 4 }, { cond: { selfHpBelow: 0.5 }, mult: 2 });
  });
  r.take(/(\d+)%概率秒杀对方，若对方处于(烧伤)状态，则秒杀概率翻倍/, (m) => {
    e.ohko = num(m[1]);
    e.ohkoDoubleIf = { foeStatus: statusOf(m[2]) };
  });
  r.take(/若对方处于(烧伤|冰冻|麻痹|睡眠)状态，有(\d+)%概率秒杀对方/, (m) => void (e.ohkoIf = { chance: num(m[2]), cond: { foeStatus: statusOf(m[1]) } }));
  r.take(/命中后(\d+)%概率秒杀对方且停止行动1回合|(\d+)%概率秒杀对方，秒杀后停止行动1回合/, (m) => {
    e.ohko = num(m[1] ?? m[2]);
    e.recharge = true;
  });
  r.take(/每次攻击都有(\d+)%的?概率直接秒杀对方/, (m) => void (e.ohko = num(m[1])));
  r.take(/秒杀体力值少于(\d+)点的对方/, (m) => void (e.ohkoIf = { chance: 100, hpBelow: num(m[1]) }));
  r.take(/回复自己全部体力值和技能PP/, () => {
    e.healFull = true;
    e.ppSelf = 99;
  });
  r.take(/消耗自己所有PP值，完全回复自己体力值并清除所有不良状态和被削弱的属性能力等级/, () => {
    e.ppSelfAll = true;
    e.healFull = true;
    e.cure = true;
    e.restoreOwn = { chance: 100 };
  });
  r.take(/恢复自己所有被削弱的属性能力等级并清除自己的不良状态，且(\d+)~(\d+)回合内不受不良状态影响/, (m) => {
    e.restoreOwn = { chance: 100 };
    e.cure = true;
    e.timed.push({ who: "self", kind: "nostatus", turns: num(m[2]) });
  });
  r.take(/若自己受到对方攻击，则令对方(混乱)和(中毒)/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 1, chance: 100, status: statusOf(m[1]), statusAlt: statusOf(m[2]), bothStatus: true }));
  r.take(/自己(?:速度|速度值)与对方(?:速度|速度值)比值越(大|小)，威力越(大|小)/, (m) => void (e.powerBySpeed = (m[1] === "大") === (m[2] === "大") ? "fast" : "slow"));
  r.take(/(?:(\d+)%概率)?复制对方(?:提升的)?(?:属性)?能力等级(?:效果)?(?:给自己)?/, (m) => void (e.copyFoeUps = { chance: pct(m[1]) }));
  r.take(/复制对方的能力等级/, () => {
    e.copyFoeUps = { chance: 100 };
    e.copyAll = true;
  });
  r.take(/(\d+)%概率夺取对方提升的属性能力等级加给自己，之后必定清除对方提升的属性能力等级/, (m) => {
    e.copyFoeUps = { chance: num(m[1]) };
    e.clearFoeUps = { chance: 100 };
  });
  r.take(/回合结束时为自己回复(\d+)(?:点)?体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: 1, n: num(m[1]) }));
  r.take(/一场战斗使用(?:多次|越多)，?则?(?:闪避)?成功率(?:会下降|逐渐降低)/, () => void (e.fade = true));
  r.take(new RegExp(`极大概率能够成功提升自己(${STAT_LIST})的等级各(\\d+)级，失败则扣除自己(\\d+)点体力值`), (m) => {
    e.stages.push({ self: true, stats: statsOf(m[1]), delta: num(m[2]), chance: 90 });
    e.failCost = num(m[3]);
  });
  r.take(/(?:先发；)?自己若受到伤害，则对方所有PP减少(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num(m[2]), chance: 100, n: num(m[1]) }));
  r.take(/若自己受到(?:伤害|攻击)，(?:有(\d+)%概率)?(?:则)?扣除对方(?:全部技能PP|所有PP)(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num(m[3]), chance: pct(m[1]), n: num(m[2]) }));
  r.take(/每回合扣除自己体力值(\d+)点，随机削弱对方1种属性的等级(\d+)级，持续(\d+)回合/, (m) => {
    e.timed.push({ who: "self", kind: "dot", turns: num(m[3]), n: num(m[1]) });
    e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: num(m[3]), stats: ALL_STATS, delta: -num(m[2]), chance: 100, pick: 1 });
  });
  r.take(/清除双方所有的?(?:属性)?能力等级/, () => {
    e.resetFoe = true;
    e.resetSelf = true;
  });
  r.take(/将自己不良状态转移给对方/, () => void (e.passStatus = true));
  r.take(/若自己剩余体力值与满体力的比值小于对方，有(\d+)%概率按比例调换双方体力/, (m) => void (e.swapHpRatio = num(m[1])));
  r.take(/若对方处于(烧伤)状态，每回合削弱对方(攻击)等级(\d+)级，持续削弱回合数=烧伤回合数/, (m) => void e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: 99, stats: statsOf(m[2]), delta: -num(m[3]), chance: 100, while: statusOf(m[1]) }));
  r.take(/若当回合抵挡对方伤害，并将对方造成伤害值的(1\/2)反击对方|若先发，当回合抵挡对方伤害，并将对方造成伤害值的(1\/2)反击对方/, (m) => void (e.shield = { take: 0, reflect: frac(m[1] ?? m[2]), ifFirst: true }));
  r.take(/(?:本回合)?(?:命中则)?(?:本回合)?(?:自己)?(?:承受|受到)伤害减半/, () => void (e.shield = { take: 0.5, reflect: 0 }));
  r.take(/此回合自己免受(普通攻击与特殊攻击|特殊攻击|普通攻击)造成的伤害/, (m) => void (e.shield = { take: 0, reflect: 0, ...(m[1] === "特殊攻击" ? { kind: "spec" as const } : m[1] === "普通攻击" ? { kind: "phys" as const } : {}) }));
  r.take(/若本回合受到攻击则令对方攻击无效/, () => void (e.shield = { take: 0, reflect: 0 }));
  r.take(/下回合(?:先发)?(?:自动)?攻击对方(?:单体)?(?![\d~])/, (m) => {
    e.charge = true;
    if (/先发/.test(m[0])) e.chargeFirst = true;
  });
  r.take(/使用后进入装弹状态，停止行动1回合，然后发射威力巨大的子弹攻击对方/, () => void (e.charge = true));
  r.take(/令冰冻中的对方所有技能PP每回合减少(\d+)点，持续到冰冻效果解除/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num(m[1]), while: "冰冻" }));
  r.take(/束缚时每回合所有技能PP值-(\d+)/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num(m[1]), while: "束缚" }));
  r.take(new RegExp(`(\\d+)%概率削弱对方(?:单体)?(${STAT_LIST})(?:的)?等级各?(\\d+)级，(?:若)?对方(冰冻|烧伤)(?:时)?，?削弱概率(?:会)?增加至(\\d+)%`), (m) => {
    e.stages.push({ self: false, stats: statsOf(m[2]), delta: -num(m[3]), chance: num(m[1]), condChance: { cond: { foeStatus: statusOf(m[4]) }, chance: num(m[5]) } });
  });
  r.take(new RegExp(`对方(麻痹|冰冻|烧伤|睡眠|混乱)时，(\\d+)%概率削弱对方(${STAT_LIST})(\\d+)级`), (m) => {
    e.stages.push({ self: false, stats: statsOf(m[3]), delta: -num(m[4]), chance: num(m[2]), cond: { foeStatus: statusOf(m[1]) } });
  });
  r.take(new RegExp(`(\\d+)%概率削弱对方(?:单体)?(${STAT_LIST})(?:等级)?(\\d+)级；?，?若(暴击|自己速度快过对方)(?:，)?(?:命中)?则?(\\d+)%(?:概率)?削弱对方(?:单体)?(?:${STAT_LIST})(?:等级)?\\d+级`), (m) => {
    const c: Cond = m[4] === "暴击" ? { crit: true } : { faster: true };
    e.stages.push({ self: false, stats: statsOf(m[2]), delta: -num(m[3]), chance: num(m[1]), condChance: { cond: c, chance: num(m[5]) } });
  });
  r.take(new RegExp(`(\\d+)%概率令对方(${ST})，若暴击则(\\d+)%概率令对方(?:${ST})`), (m) => {
    e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]), doubleIf: { crit: true } });
  });
  r.take(new RegExp(`(\\d+)%概率令对方(${ST})并束缚对方(\\d+)~(\\d+)回合；若对方处于(冰冻)状态，则概率翻倍`), (m) => {
    e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]), doubleIf: { foeStatus: statusOf(m[5]) } });
    e.statuses.push({ name: "束缚", chance: num(m[1]), turns: [num(m[3]), num(m[4])], doubleIf: { foeStatus: statusOf(m[5]) } });
  });
  r.take(new RegExp(`(\\d+)%概率令对方单体(冰冻)，造成冰冻时自己回复(\\d+\\/\\d+)体力值`), (m) => {
    e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]) });
    e.healAfter = { f: frac(m[3]), chance: 100, cond: { landed: true } };
  });
  r.take(new RegExp(`(\\d+)%概率令对方睡眠，若成功令对方睡眠则提升自身(${STAT_LIST})等级各(\\d+)级`), (m) => {
    e.statuses.push({ name: "睡眠", chance: num(m[1]) });
    e.stages.push({ self: true, stats: statsOf(m[2]), delta: num(m[3]), chance: 100, cond: { landed: true } });
  });
  r.take(new RegExp(`若对方处于(?:不良|异常)状态，有?(\\d+)%概率令对方(${ST})`), (m) => void e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]), cond: { foeStatus: "any" } }));
  r.take(new RegExp(`若对方(?:已)?(麻痹|束缚)，(?:则)?额外提升自己(${STAT_LIST})等级(\\d+)级`), (m) => void e.stages.push({ self: true, stats: statsOf(m[2]), delta: num(m[3]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
  r.take(new RegExp(`如果对方处于(混乱|烧伤)状态，则削弱对方(${STAT_LIST})的等级各(\\d+)级`), (m) => void e.stages.push({ self: false, stats: statsOf(m[2]), delta: -num(m[3]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
  r.take(/(?:若|如果)对方处于(烧伤)状态，则扣除对方所有技能(?:的)?PP(?:值)?(\d+)点/, (m) => void (e.ppFoe = { n: num(m[2]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
  r.take(/若对方(?:已)?(麻痹)则附加(\d+)点固定伤害/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[1]) }, add: num(m[2]) }));
  r.take(/若对方处于(睡眠)状态，(\d+)%概率发动(\d+(?:\.\d+)?)倍威力/, (m) => void (e.boost ??= []).push({ chance: num(m[2]), mult: num(m[3]), cond: { foeStatus: statusOf(m[1]) } }));
  r.take(/如果对方处于(混乱)状态，则发动(\d+(?:\.\d+)?)倍伤害/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[1]) }, mult: num(m[2]) }));
  r.take(/若对方此回合不使用伤害型技能，则可发动(\d+(?:\.\d+)?)倍威力/, (m) => void (e.powerIf ??= []).push({ cond: { foeNoDamage: true }, mult: num(m[1]) }));
  r.take(/若本回合受到伤害则必定令对方(混乱)/, (m) => void e.statuses.push({ name: statusOf(m[1]), chance: 100, cond: { hurt: true } }));
  r.take(new RegExp(`若本回合未受到伤害，则降低对方单体(${STAT_LIST})各(\\d+)级`), (m) => void e.stages.push({ self: false, stats: statsOf(m[1]), delta: -num(m[2]), chance: 100, cond: { hurt: false } }));
  r.take(/若本回合未受到伤害，则回合结束时扣除对方(\d+)点体力值/, (m) => void (e.delayed = { who: "foe", turns: 0, kind: "flat", n: num(m[1]) }));
  r.take(/若对方处于(冰冻|混乱|麻痹)(?:状态)?，?(?:则)?可多攻击(\d+)次/, (m) => void (e.hitsIf = { cond: { foeStatus: statusOf(m[1]) }, add: num(m[2]) }));
  r.take(/若对方(束缚)，则必定攻击(\d+)次/, (m) => void (e.hitsIf = { cond: { foeStatus: statusOf(m[1]) }, set: num(m[2]) }));
  r.take(/若暴击，每次暴击均回复自身体力最大值的(\d+\/\d+)/, (m) => void (e.critHeal = frac(m[1])));
  r.take(/自己剩余体力值越少回复体力值越多/, () => void (e.healLost = 0.5));
  r.take(/并束缚对方，束缚回合数等于黏住的次数/, () => {
    e.statuses.push({ name: "束缚", chance: 100 });
    e.bindHits = true;
  });
  r.take(/随机召唤1~10块数码幻镜攻击对方单体；召唤幻镜数量为3时，令对方害怕；召唤幻镜数量为6时，令对方混乱；召唤幻镜数量为9时，令对方麻痹/, () => {
    e.hits = [1, 10];
    e.hitStatus = { 3: "害怕", 6: "混乱", 9: "麻痹" };
  });
  r.take(/向敌方扔出(\d+)~(\d+)个气球爆弹|射出(\d+)支毒箭攻击对方单体/, (m) => void (e.hits = m[3] ? [num(m[3]), num(m[3])] : [num(m[1]), num(m[2])]));
  r.take(/每支毒箭有/, () => void (e.perHit = true));
  r.take(/回合结束时回复对方体力值(\d+)点/, (m) => void (e.healFoeEnd = num(m[1])));
  r.take(/(?:使用后)?额外增强自己双攻、双防和速度基础数值的?(\d+)%，1场战斗最多增强(\d+)次/, (m) => void (e.baseUp = { pct: num(m[1]), max: num(m[2]) }));
  r.take(/令对方单体基础(攻击|特攻)值减少(\d+)点/, (m) => void (e.baseDown = { stat: m[1] === "攻击" ? "atk" : "satk", n: num(m[2]) }));
  r.take(/(\d+)%概率无视对方(?:防御|特防)提升的等级/, (m) => void (e.ignoreUps = num(m[1])));
  r.take(/一定概率令提升效果翻倍/, () => void (e.stageDouble = 30));
  r.take(/(\d+)%概率令自己或对方下回合停止行动1回合，若对方麻痹则自己下回合不会停止行动(?:，若对方害怕则对方下回合不会停止行动)?/, (m) => void (e.eitherStops = num(m[1])));
  r.take(/每次攻击威力增加(\d+)/, (m) => void (e.perHitPower = num(m[1])));
  r.take(/(?:先发；)?(?:连续攻击对方(?:单体)?(\d+)回合)，每回合威力增加(\d+)/, (m) => void (e.rollout = { turns: num(m[1]), add: num(m[2]) }));
  r.take(/每回合末均有(\d+)%概率令自己(混乱)/, (m) => void e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]), self: true }));
  r.take(/连续(\d+)~(\d+)回合攻击对方(?:单体)?(?!随机)/, (m) => void (e.lock = { turns: [num(m[1]), num(m[2])], after: "none" }));
  r.take(/连续(?:攻击对方(?:单体)?(\d+)回合|(\d+)回合攻击对方(?:单体)?)，(?:威力十分巨大，)?之后自己(?:休息|停止行动)1回合/, (m) => void (e.lock = { turns: [num(m[1] ?? m[2]), num(m[1] ?? m[2])], after: "rest" }));
  r.take(/连续攻击对方单体(\d+)回合，(?=每次攻击)/, (m) => void (e.lock = { turns: [num(m[1]), num(m[1])], after: "none" }));
  // N回合自己停止行动，N回合后…: the user stops those turns; what comes after, at their end.
  r.take(/(\d+)回合自己停止行动，(\d+)回合后提升自己全属性(\d+)级/, (m) => {
    e.recharge = true;
    e.rechargeTurns = num(m[1]);
    e.delayed = { who: "self", turns: num(m[2]), kind: "stages", stats: ALL_STATS, delta: num(m[3]) };
  });
  r.take(/(先回复自己所有体力值，)?(\d+)回合自己停止行动，(\d+)回合后满状态回复并令对方害怕/, (m) => {
    if (m[1]) e.healFull = true;
    e.recharge = true;
    e.rechargeTurns = num(m[2]);
    e.delayed = { who: "self", turns: num(m[3]), kind: "rebirth" };
  });
  r.take(/(\d+)%概率(?:会)?使自己下回合处于异常状态/, (m) => void (e.delayed = { who: "self", turns: 0, kind: "badStatus", chance: num(m[1]) }));
  r.take(new RegExp(`(?:受到伤害|每回合受到伤害|每次受到伤害)(?:时|则)?，?(?:都有)?(?:(\\d+)%概率)?(提升|削弱)(自己|自身|对方)?(?:的)?(${STAT_LIST})(?:的)?(?:等级)?(?:各)?(\\d+)级(?:，持续(\\d+)回合)?`), (m) => {
    const self = m[3] !== "对方";
    e.timed.push({ who: "self", kind: "onhurt", turns: m[6] ? num(m[6]) : turnsOf(r.d, 5), chance: pct(m[1]), stats: statsOf(m[4]), delta: (m[2] === "提升" ? 1 : -1) * num(m[5]), selfStage: self });
  });
  r.take(new RegExp(`(?:(\\d+)回合内)?受到伤害(?:时)?，(?:(\\d+)%概率)?(?:提升自己)?(${STAT_LIST})(?:和(${STAT_LIST}))?的?等级(?:各)?提升(\\d+)级(?:，持续(\\d+)回合)?`), (m) => {
    e.timed.push({ who: "self", kind: "onhurt", turns: num(m[6] || m[1], 5), chance: pct(m[2]), stats: statsOf(m[3] + (m[4] ? "和" + m[4] : "")), delta: num(m[5]), selfStage: true });
  });
  r.take(new RegExp(`(?:受到伤害|每次受到伤害)(?:时)?(?:都有)?(\\d+)%概率(提升自己)(${STAT_LIST})等级(\\d+)级，持续(\\d+)回合`), (m) => {
    e.timed.push({ who: "self", kind: "onhurt", turns: num(m[5]), chance: num(m[1]), stats: statsOf(m[3]), delta: num(m[4]), selfStage: true });
  });
  r.take(new RegExp(`(?:使用后(\\d+)回合内，)?(?:每次)?受到伤害(?:时|都有)?(\\d+)%概率令对方(?:进入)?(${ST}|异常状态)`), (m) => {
    const any = m[3] === "异常状态";
    e.timed.push({ who: "self", kind: "onhurt", turns: num(m[1], turnsOf(r.d, 5)), chance: num(m[2]), status: any ? "麻痹" : statusOf(m[3]), ...(any ? { statusAlt: "睡眠" as StatusName } : {}) });
  });
  r.take(/使用后(\d+)回合内每次受到攻击则返还(\d+)点伤害给对方/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), n: num(m[2]) }));
  r.take(/使用后(\d+)回合内，若受到伤害，则将伤害的(1\/3)返还给对方/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]), spec: frac(m[2]) }));
  r.take(/使用后(\d+)回合内，将受到伤害的(\d+\/\d+)返还给对方，自身承受(\d+\/\d+)/, (m) => {
    e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]), spec: frac(m[2]) });
    e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), phys: frac(m[3]), spec: frac(m[3]) });
  });
  r.take(/使用后接下来(\d+)回合，反击受到伤害的(\d+\/\d+)给对方，若自己被击败则无法反击/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]), spec: frac(m[2]) }));
  r.take(/(?:额外)?提升(?:自己|自身)?(?:的)?(?:抵抗伤害能力|伤害抵抗能力|伤害抵抗)(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 3), phys: 1 - num(m[1]) / 100, spec: 1 - num(m[1]) / 100 }));
  r.take(/(?:额外)?提升(?:自己|我方全体)(?:的)?(?:伤害值的|伤害能力|伤害)(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num(m[1]) / 100 }));
  r.take(/提升(水)系、(火)系技能威力(\d+)%/, (m) => {
    for (const a of [m[1], m[2]]) e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num(m[3]) / 100, attr: ATTRS[a] });
  });
  r.take(/(?:使用后)?(?:接下来的?(\d+)回合，)?给?(?:技能糖果炮弹的)?(?:下个回合的)?每次攻击附加(\d+)点伤害(?:值)?(?:和(\d+)%概率(害怕))?(?:，持续(\d+)回合)?/, (m) => {
    const turns = m[1] ? num(m[1]) : m[5] ? num(m[5]) : 2;
    e.timed.push({ who: "self", kind: "extra", turns, n: num(m[2]) });
    if (m[3]) e.timed.push({ who: "self", kind: "onhit", turns, chance: num(m[3]), n: 1 });
  });
  r.take(/每次暴击附加(\d+)点伤害值/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: 1, n: num(m[1]), chance: -1 }));
  r.take(/接下来(\d+)回合，每回合攻击对方时均有(\d+)%概率令对方(麻痹)/, (m) => void e.timed.push({ who: "self", kind: "onhit", turns: num(m[1]), chance: num(m[2]), n: 3, status: statusOf(m[3]) }));
  r.take(/使用后(\d+)回合内，每回合有(\d+)%概率令对方单体(害怕)/, (m) => void e.timed.push({ who: "foe", kind: "plague", turns: num(m[1]), chance: num(m[2]), status: statusOf(m[3]) }));
  r.take(/使用后每次攻击有(\d+)%概率令对方害怕，并将伤害值的(\d+)%转化来回复自己，每回合结束时扣除自己(\d+)点体力值，持续(\d+)回合/, (m) => {
    const turns = num(m[4]);
    e.timed.push({ who: "self", kind: "onhit", turns, chance: num(m[1]), n: 1 });
    e.timed.push({ who: "self", kind: "drain", turns, f: num(m[2]) / 100 });
    e.timed.push({ who: "self", kind: "dot", turns, n: num(m[3]) });
  });
  r.take(new RegExp(`使用后(\\d+)回合内，提升自己(${STAT_LIST})等级各(\\d+)级，使用任何技能必定命中，每回合末扣除自己体力值(\\d+)点`), (m) => {
    const turns = num(m[1]);
    e.stages.push({ self: true, stats: statsOf(m[2]), delta: num(m[3]), chance: 100 });
    e.timed.push({ who: "self", kind: "sure", turns });
    e.timed.push({ who: "self", kind: "dot", turns, n: num(m[4]) });
  });
  r.take(new RegExp(`使用后，每回合提升自己(?:的)?(${STAT_LIST})(?:的)?等级各?(\\d+)级(?:，并提升自己伤害抵抗能力(\\d+)%)?，持续(\\d+)回合`), (m) => {
    e.timed.push({ who: "self", kind: "stagesEachTurn", turns: num(m[4]), stats: statsOf(m[1]), delta: num(m[2]), chance: 100 });
    if (m[3]) e.timed.push({ who: "self", kind: "screen", turns: num(m[4]), phys: 1 - num(m[3]) / 100, spec: 1 - num(m[3]) / 100 });
  });
  r.take(new RegExp(`且对方(束缚)时，每回合提升自己(${STAT_LIST})等级(\\d+)级`), (m) => void e.timed.push({ who: "self", kind: "stagesEachTurn", turns: 99, stats: statsOf(m[2]), delta: num(m[3]), chance: 100, whileOther: statusOf(m[1]) }));
  r.take(new RegExp(`且(衰弱)时对方每回合随机下降(\\d+)种属性`), (m) => void e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: 99, stats: ALL_STATS, delta: -1, chance: 100, pick: num(m[2]), while: statusOf(m[1]) }));
  r.take(new RegExp(`(?:令对方(?:单体)?)?(\\d+)~(\\d+)回合(${ST})`), (m) => void e.statuses.push({ name: statusOf(m[3]), chance: 100, turns: [num(m[1]), num(m[2])] }));
  r.take(new RegExp(`(\\d+)%概率束缚对方(?:单体)?(?:(\\d+)~(\\d+)回合)?`), (m) => void e.statuses.push({ name: "束缚", chance: num(m[1]), ...(m[2] ? { turns: [num(m[2]), num(m[3])] as [number, number] } : {}) }));
  r.take(/一定概率麻痹对方单体，自己剩余体力值越少概率越高/, () => void e.statuses.push({ name: "麻痹", chance: 20, byLowHp: true }));
  r.take(/自己体力值越低，睡眠成功率越高/, () => void e.statuses.push({ name: "睡眠", chance: 20, byLowHp: true }));
  r.take(new RegExp(`自己损失体力越多，令对方(${ST})的概率越大`), (m) => void e.statuses.push({ name: statusOf(m[1]), chance: 10, byLowHp: true }));
  r.take(/令对方单体烧伤，自己速度提升的等级越高，烧伤对方的概率越高/, () => void e.statuses.push({ name: "烧伤", chance: 30, bySpeed: true }));
  r.take(new RegExp(`(?:(\\d+)%概率|一定概率)令对方(?:单体)?(?:处于)?(${ST})(?:、(${ST}))?(?:、(${ST}))?(?:或者|或)(${ST})`), (m) => {
    const names = [m[2], m[3], m[4], m[5]].filter(Boolean) as StatusName[];
    const chance = m[1] ? num(m[1]) : 30;
    for (const n of names) e.statuses.push({ name: n, chance: chance / names.length });
  });
  r.take(new RegExp(`(?:(\\d+)%概率|一定概率)(?:令|使)?对方(?:单体|全体|全场)?(?:处于|进入)?(?:任意1种|各种)?(?:不良或异常|不良|异常)状态`), (m) => {
    const chance = m[1] ? num(m[1]) : 30;
    for (const s of BAD_STATUSES) e.statuses.push({ name: s, chance: chance / BAD_STATUSES.length });
  });
  r.take(new RegExp(`(\\d+)%概率随机削弱对方(${STAT_RE})、(${STAT_RE})或(${STAT_RE})等级(\\d+)级`), (m) => {
    e.stages.push({ self: false, stats: statsOf(`${m[2]}和${m[3]}和${m[4]}`), delta: -num(m[5]), chance: num(m[1]), pick: [1, 1] });
  });
  r.take(/(\d+)%概率(?:削弱|降低)对方防御\+特防或攻击\+特攻(\d+)级/, (m) => {
    e.stages.push({ self: false, stats: [], delta: -num(m[2]), chance: num(m[1]), groups: [["def", "sdef"], ["atk", "satk"]] });
  });
  r.take(/(\d+)%概率扣光对方所有技能(?:的)?PP(?:点数)?|(\d+)%概率清除对方所有技能PP值/, (m) => void (e.ppFoe = { n: "all", chance: num(m[1] ?? m[2]) }));
  r.take(/(\d+)%概率清除对方所有技能PP(\d+)点/, (m) => void (e.ppFoe = { n: num(m[2]), chance: num(m[1]) }));
  r.take(/命中后消耗自己所有技能的PP/, () => void (e.ppSelfAll = true));
  r.take(/额外消耗自身所有技能PP值(\d+)点/, (m) => void (e.ppSelf = -num(m[1])));
  r.take(/回复自己所有PP值(\d+)点和(\d+)点体力值/, (m) => {
    e.ppSelf = num(m[1]);
    e.healFlat = num(m[2]);
  });
  r.take(/随机扣除对方单体的体力值和所有技能PP/, () => {
    e.dmg = { kind: "range", a: 50, b: 300 };
    e.ppFoe = { n: 2, chance: 100 };
  });
  r.take(/(?:先发；)?使用后接下来(\d+)回合，自己技能暴击概率提升至(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num(m[1]), chance: num(m[2]) }));
  r.take(/(\d+)回合内，?(?:自己的)?(?:属性)?(?:能力)?等级不会被削弱|(?:接下来)?(\d+)回合内?，自己的能力等级不会被削弱/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num(m[1] ?? m[2]) }));
  r.take(/持续(\d+)回合，自己属性能力等级不能被削弱(?:；若对方提升它的属性能力等级，同样也会加给自己)?/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num(m[1]) }));
  r.take(/(\d+)回合内，对方提升能力等级也会给自己提升/, () => void (e.copyFoeUps = { chance: 100 }));
  r.take(/(?:\d+回合内对方|两回合内对方)属性等级无法被提升或降低/, () => void e.timed.push({ who: "foe", kind: "lockStages", turns: 2 }));
  r.take(/(\d+)回合内对方属性等级无法被提升或降低/, (m) => void e.timed.push({ who: "foe", kind: "lockStages", turns: num(m[1]) }));
  r.take(/全场属性等级无法被提升或降低，持续(\d+)回合/, (m) => void e.timed.push({ who: "both", kind: "lockStages", turns: num(m[1]) }));
  r.take(/(?:若自己不死，则)?每回合扣除对方(\d+)点体力值/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: 99, n: num(m[1]) }));
  r.take(/(?:若|另外，)?自身不死，每回合扣除对方所有PP值(\d+)(?:~(\d+))?点|若自己不死，每回合扣除对方所有PP值(\d+)点/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num(m[1] ?? m[3]) }));
  r.take(/(\d+)%概率令对方(?:单体)?害怕，对方害怕的同时，会吸取(1\/2)伤害值来回复自己/, (m) => {
    e.statuses.push({ name: "害怕", chance: num(m[1]) });
    e.drain = frac(m[2]);
    e.drainCond = { landed: true };
  });
  r.take(/若对方处于(麻痹)状态，将伤害值的(\d+)%转化来回复自己体力值/, (m) => {
    e.drain = num(m[2]) / 100;
    e.drainCond = { foeStatus: statusOf(m[1]) };
  });
  r.take(/若对方(睡眠)则将伤害值的(\d+)%转化来回复自己体力值/, (m) => {
    e.drain = num(m[2]) / 100;
    e.drainCond = { foeStatus: statusOf(m[1]) };
  });
  r.take(/将伤害值的(\d+)%转化来回复自己；若对方已(麻痹)则将伤害值的(\d+)%转化来回复自己/, (m) => {
    e.drain = num(m[1]) / 100;
    (e.powerIf ??= []).push({ cond: { foeStatus: statusOf(m[2]) }, drain: num(m[3]) / 100 });
  });
  r.take(/自己速度越快，给对方单体造成的伤害越多，自己回复的体力值也越多/, () => {
    e.powerBySpeed = "fast";
    e.drain = 0.5;
  });
  r.take(/(?:使用后，)?(\d+)%概率闪避(?:特殊攻击与普通攻击|普通攻击与特殊攻击)技能造成的伤害，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num(m[2]), phys: num(m[1]), spec: num(m[1]) }));
  r.take(/持续(\d+)回合进入隐身状态，(\d+)%概率无视对方的特殊攻击/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num(m[1]), spec: num(m[2]) }));
  r.take(/使用后自己进入隐身状态，(\d+)%概率闪避对方的伤害/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: turnsOf(r.d, 3), phys: num(m[1]), spec: num(m[1]) }));
  r.take(/(\d+)%概率令自己停止行动1回合|(\d+)%概率自己停止行动1回合/, (m) => {
    e.recharge = true;
    e.rechargeChance = num(m[1] ?? m[2]);
  });
  r.take(/命中后自己停止行动1回合/, () => void (e.recharge = true));
  r.take(/若击败对方，回合结束时回复自己(一半|\d+\/\d+)的?体力值/, (m) => void (e.healOnKO = frac(m[1])));
  r.take(/造成伤害等于自己等级的(\d+(?:\.\d+)?)倍/, (m) => void (e.dmg = { kind: "level", a: num(m[1]), b: num(m[1]) }));
  r.take(/(?:自己|自身)?(?:需要)?承受伤害值的(\d+\/\d+)/, (m) => void (e.recoil = frac(m[1])));
  r.take(/自己承受(\d+\/\d+)伤害/, (m) => void (e.recoil = frac(m[1])));
  r.take(/(?<!每回合)(?:自己|自身)(?:回复|恢复)(\d+\/\d+)(?:的)?体力值/, (m) => void (e.healAfter = { f: frac(m[1]), chance: 100 }));
  r.take(/(?<!每回合|否则)(?:自己|自身)(?:回复|恢复)(\d+)点体力值/, (m) => void (e.healFlat = num(m[1])));
  r.take(/(\d+)%概率回复自己(\d+)点体力值/, (m) => {
    e.healFlat = num(m[2]);
    e.healChance = num(m[1]);
  });
  r.take(/回复最大体力值(\d+\/\d+)/, (m) => {
    e.heal = frac(m[1]);
    e.healAfter = { f: frac(m[1]), chance: 100 };
  });
  r.take(/每回合结束时扣除自己(\d+)点体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "dot", turns: num(m[2]), n: num(m[1]) }));
  r.take(/(?:自己|自身)(?:剩余)?体力值越多造成的伤害值越高|自己最大体力值越高则造成伤害越大/, (m) => {
    if (/剩余/.test(m[0])) e.powerByHp = "high";
  });
  r.take(/自身体力值越少威力越高/, () => void (e.powerByHp = "low"));
  r.take(/对方(攻击)和(特攻)等级越低，威力越大/, () => undefined);
  r.take(/自己双防越高，伤害越高，令对方害怕的概率越高|并有一定概率令对方害怕/, (m) => (/并有/.test(m[0]) ? void e.statuses.push({ name: "害怕", chance: 30 }) : undefined));
  r.take(/(?:在)?自己危在旦夕的时候，能发挥秒杀对方单体的巨大威力/, () => void (e.powerByHp = "low"));
  r.take(/1回合内攻击对方(?:单体)?(\d+)~(\d+)次，?(?:威力递增)?/, (m) => void (e.hits = [num(m[1]), num(m[2])]));
  r.take(/(?:自己|我方全体)?(?:“)?(光明|飞行)系(?:”)?技能威力提升(\d+)%，伤害抵抗(?:能力)?提升(\d+)%(?:，持续(\d+)回合)?/, (m) => {
    const turns = num(m[4], turnsOf(r.d, 3));
    e.timed.push({ who: "self", kind: "power", turns, mult: 1 + num(m[2]) / 100, attr: ATTRS[m[1]] });
    e.timed.push({ who: "self", kind: "screen", turns, phys: 1 - num(m[3]) / 100, spec: 1 - num(m[3]) / 100 });
  });
  r.take(/下回合使用(火|木)系技能威力(?:增加|上升)(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "power", turns: 2, mult: 1 + num(m[2]) / 100, attr: ATTRS[m[1]] }));
  r.take(/接下来(\d+)回合提升我方全体队员抵抗普通攻击伤害的(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), phys: 1 - num(m[2]) / 100 }));
  r.take(/提升我方全体伤害(\d+)%，闪避等级(\d+)级/, (m) => {
    e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num(m[1]) / 100 });
    e.stages.push({ self: true, stats: ["eva"], delta: num(m[2]), chance: 100 });
  });
  // 全场 with a trait: each 亚比 in the fight that has it (the user, the foe, or both).
  r.take(/提升全场(超暗黑)亚比闪避(\d+)~(\d+)级/, (m) => void (e.trait = { name: m[1], stats: ["eva"], delta: num(m[2]), deltaMax: num(m[3]) }));
  r.take(/全场具有(\S+?)特性的亚比伤害增加(\d+)%，速度增加(\d+)级/, (m) => void (e.trait = { name: m[1], power: 1 + num(m[2]) / 100, stats: ["spd"], delta: num(m[3]) }));
  r.take(/(?:(\d+)%概率)?令对方停止行动1回合/, (m) => void e.statuses.push({ name: "害怕", chance: pct(m[1]) }));
  r.take(/使用后直到自己受到伤害，才削弱对方(攻击和特攻)的等级各(\d+)级/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 99, chance: 100, stats: statsOf(m[1]), delta: -num(m[2]), selfStage: false, n: 0, once: true }));
  r.take(/若自己出手速度快过对方，则恢复自己体力最大值的(\d+\/\d+)/, (m) => void (e.healAfter = { f: frac(m[1]), chance: 100, cond: { faster: true } }));
  r.take(/使用后防御与攻击，特防与特攻属性等级交换/, () => void (e.swapOwnStages = true));
  r.take(/若攻击次数为3的倍数，则提升自己(攻击和命中)等级各(\d+)级/, (m) => void e.stages.push({ self: true, stats: statsOf(m[1]), delta: num(m[2]), chance: 100, cond: { hitsMultipleOf: 3 } }));
  r.take(/若伤害超过(\d+)，则将对方的(防御和特防)的等级各(\d+)级转化给自己/, (m) => void (e.stealStages = { stats: statsOf(m[2]), delta: num(m[3]), minDmg: num(m[1]) }));

  // ---- order and accuracy
  r.take(/本回合休息，提升暴击率，下回合攻击对方单体/, () => {
    e.charge = true;
    e.highCrit = true;
  });
  r.take(/下回合必定命中(?:对方单体)?/, () => void e.timed.push({ who: "self", kind: "sure", turns: 2 }));
  r.take(/^先发|先发(?=；|，|;|,)/, () => void (e.first = true));
  r.take(/(?:^|；|;|，)后发(?=；|，|;|,|$)/, () => void (e.last = true));
  r.take(/必定命中|必中技除外/, (m) => (m[0] === "必定命中" ? void (e.sure = true) : undefined));
  r.take(/容易暴击|本回合提升暴击概率|暴击概率提升|自己提升暴击等级|提升暴击率/, () => void (e.highCrit = true));
  r.take(/一场战斗使用(?:次数越多|多次)，?(?:则)?成功率(?:会)?(?:越低|降低)(?:；使用失败则回复自己(\d+)点体力值?)?/, (m) => {
    e.fade = true;
    if (m[1]) e.failHeal = num(m[1]);
  });
  r.take(/(?:本回合)?受到伤害时至少为自己保留1点体力值/, () => void (e.hold = true));
  r.take(/无视对方攻击/, () => void (e.protect = true));

  // ---- power by circumstances
  r.take(/(?:若|当)?([^，；]*?)(?:时|的话)?，?(?:则|可)?(?:发动|威力)?(?:加倍|(\d+(?:\.\d+)?)倍威力|提升至(\d+(?:\.\d+)?)倍|威力加倍|威力提升至(\d+)|可发动(\d+(?:\.\d+)?)倍(?:威力|伤害))/, (m) => {
    const c = cond(m[1]);
    if (!c) return false;
    const mult = m[2] ? num(m[2]) : m[3] ? num(m[3]) : m[5] ? num(m[5]) : m[4] ? undefined : 2;
    (e.powerIf ??= []).push(m[4] ? { cond: c, set: num(m[4]) } : { cond: c, mult });
  });
  r.take(/若对方体力值比自己多，则发动2倍威力；若对方体力值比自己少，则发动1\/2倍威力/, () => {
    (e.powerIf ??= []).push({ cond: { foeHpMore: true }, mult: 2 }, { cond: { foeHpLess: true }, mult: 0.5 });
  });
  r.take(/自己体力值少于一半时，威力加倍；自己体力值小于1\/4时，威力提升至4倍/, () => {
    (e.powerIf ??= []).push({ cond: { selfHpBelow: 0.25 }, mult: 4 }, { cond: { selfHpBelow: 0.5 }, mult: 2 });
  });
  r.take(/令被束缚中的对方，承受(\d+(?:\.\d+)?)倍的伤害/, (m) => void (e.powerIf ??= []).push({ cond: { foeStatus: "束缚" }, mult: num(m[1]) }));
  r.take(/若对方处于(麻痹|烧伤)状态，(?:则)?必定暴击对方/, (m) => void (e.critIf = { foeStatus: statusOf(m[1]) }));
  r.take(/(?:自己)?(?:剩余)?(?:体力值?|损伤的体力值|损失体力)越(?:少|多|高|低)，?(?:技能)?(?:威力|附加伤害)越(?:大|高|多|低)|自己体力越少，威力越低|自己危在旦夕的时候，能发挥秒杀对方单体的巨大威力|自己当前的体力值越高，威力越大/, (m) => {
    const t = m[0];
    if (/秒杀/.test(t)) e.powerByHp = "low";
    // 损失的体力 grows as the HP falls: 损失越多 is the HP less, 损失越少 the HP more.
    else if (/损伤|损失/.test(t)) e.powerByHp = /越多/.test(t) ? "low" : "high";
    else if (/越(?:少|低)，(?:技能)?(?:威力|附加伤害)越(?:大|高|多)/.test(t)) e.powerByHp = "low";
    else e.powerByHp = "high";
  });
  r.take(/对方剩余体力值越多(?:威力越大)?|我方剩余体力值越少，对方剩余体力值越多，威力越大/, (m) => void (e.powerByHp = /我方/.test(m[0]) ? "low" : "foeHigh"));
  r.take(/(?:自己)?(?:与对方)?的?速度(?:比值|越快|等级越高|与对方速度比值越大)[^，；]*?(?:威力|伤害)越(?:大|高|多|小)|自己速度越快，爆发的威力也越大|我方速度等级与对方速度等级之差越大，伤害越高|对方速度等级越低，威力越大/, (m) => {
    e.powerBySpeed = /越小(?:威力越大)?$|比值越小威力越大/.test(m[0]) && !/越大，威力越小/.test(m[0]) ? "slow" : /越大，威力越小/.test(m[0]) ? "slow" : "fast";
  });
  r.take(/自己与对方的速度比值越小威力越大/, () => void (e.powerBySpeed = "slow"));
  r.take(/(?:自己|我方)?(?:攻击|特攻|双防等级)(?:与对方(?:攻击|特攻))?(?:比值)?越(?:大|高)，?(?:则)?(?:威力|伤害)?越(?:大|高)|自己(?:当前)?(?:普通)?攻击越高(?:则)?造成伤害越大|自己特攻越高，伤害越高/, () => undefined);
  r.take(/无视对方(?:防御|特防)/, () => void (e.ignoreDef = true));
  r.take(/(\d+)%概率无视对方(?:防御|特防)提升的等级/, () => undefined);
  r.take(/连续(?:攻击对方(?:单体)?)?(\d+)回合(?:攻击对方(?:单体)?)?，?(?:每(?:回合|次)威力加倍|威力(?:每回合)?(?:增加|递增)|不管命中与否，每回合威力增加(\d+))/, (m) => void (e.rollout = { turns: num(m[1]), add: m[2] ? num(m[2]) : undefined, ...(/不管命中与否/.test(m[0]) ? { always: true } : {}) }));
  r.take(/连续攻击对方(\d+)~(\d+)回合，威力每回合递增/, (m) => void (e.rollout = { turns: num(m[2]) }));
  // After the user's own 元素庇护 or 千军万马 in this battle (RECONSTRUCTED: 大大提升 as double).
  r.take(/(?:使用(?:技能)?)?(元素庇护)后?威力(?:再)?加倍|使用(千军万马)后威力大大提升/, (m) => void (e.powerIf ??= []).push({ cond: mk(m[1] ?? m[2]), mult: 2 }));
  // The default of 连续攻击N回合 (rollout).
  r.take(/攻击失误则清除加倍效果/, () => undefined);
  r.take(/至少(?:能)?为(?:对方亚比|其)保留1点体力值/, () => void (e.falseSwipe = true));
  r.take(/若对方体力值多过自己，则将对方的体力值减为与自己相同/, () => void (e.endeavor = true));
  r.take(/(?:若对方体力值比自己多，则有(\d+)%概率)?平分(?:自己和对方单体|双方)的?(?:当前)?体力值/, (m) => {
    e.painSplit = true;
    if (m[1]) e.painSplitChance = num(m[1]);
  });
  r.take(/调换双方的体力值/, () => void (e.swapHp = true));

  // ---- lasting effects
  const endsOnSwitch = (s: string) => /(?:替换|交换)亚比(?:可)?解除|交换亚比解除效果|替换亚比后消失/.test(r.d) || /解除/.test(s);
  r.take(/下回合自己使用(\S{1,2}?)系技能威力加倍/, (m) => void e.timed.push({ who: "self", kind: "power", turns: 2, mult: 2, attr: ATTRS[m[1]] }));
  r.take(/给(?:自己的伤害|每次攻击)附加(\d+)点伤害值，持续(\d+)(?:回合|次攻击|次)/, (m) => void e.timed.push({ who: "self", kind: "extra", turns: num(m[2]), n: num(m[1]) }));
  r.take(/自己受到伤害则自动提升(速度)等级(\d+)级(?:，持续(\d+)回合)?/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: m[3] ? num(m[3]) : 5, stats: statsOf(m[1]), delta: num(m[2]), chance: 100, selfStage: true }));
  r.take(/(\d+)%概率令攻击自己的对方进入(睡眠)状态/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 3, chance: num(m[1]), status: statusOf(m[2]) }));
  r.take(/(?:使用后)?受到伤害则减半，并额外提升自己伤害能力(\d+)%，持续(\d+)回合/, (m) => {
    e.timed.push({ who: "self", kind: "screen", turns: num(m[2]), phys: 0.5, spec: 0.5 });
    e.timed.push({ who: "self", kind: "power", turns: num(m[2]), mult: 1 + num(m[1]) / 100 });
  });
  r.take(/提升自己伤害抵抗能力(\d+)%，每回合回复自己(\d+)点体力值，持续(\d+)回合/, (m) => {
    e.timed.push({ who: "self", kind: "screen", turns: num(m[3]), phys: 1 - num(m[1]) / 100, spec: 1 - num(m[1]) / 100 });
    e.timed.push({ who: "self", kind: "regen", turns: num(m[3]), n: num(m[2]) });
  });
  r.take(/下回合先发攻击，扣除对方单体(\d+)点体力值/, (m) => {
    e.charge = true;
    e.chargeFirst = true;
    e.dmg = { kind: "flat", n: num(m[1]) };
  });
  r.take(/连续攻击对方(\d+)回合，之后提升自己/, (m) => {
    e.lock = { turns: [num(m[1]), num(m[1])], after: "none" };
    return false;
  });
  r.take(/连续攻击对方(\d+)回合，之后/, (m) => void (e.lock = { turns: [num(m[1]), num(m[1])], after: "none" }));
  r.take(/(?:本回合)?自己回复(\d+)点体力值保护自己/, (m) => void (e.healFlat = num(m[1])));
  r.take(/一定概率扣除对方单体(1\/4)体力值/, (m) => {
    e.dmg = { kind: "hpFrac", f: frac(m[1]) };
    e.dmgChance = 50;
  });
  r.take(/自己速度比对方慢，则威力加倍，否则减半/, () => void (e.powerIf ??= []).push({ cond: { slower: true }, mult: 2 }, { cond: { faster: true }, mult: 0.5 }));
  r.take(/每次受到攻击都有(\d+)%概率令对方(睡眠)，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num(m[3]), chance: num(m[1]), status: statusOf(m[2]) }));
  r.take(/使用后(\d+)回合内受到普通或特殊攻击，都有(\d+)%概率令对方(烧伤)或者(睡眠)/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num(m[1]), chance: num(m[2]), status: statusOf(m[3]), statusAlt: statusOf(m[4]) }));
  r.take(/暴击后(?=提升)/, () => void (e.stagesIfCrit = true));
  r.take(/回复敌我双方的体力值/, () => void (e.healBoth = true));
  r.take(/重置双方提升的能力等级，(\d+)%概率令对方当回合攻击难以命中/, (m) => {
    e.clearBothUps = true;
    e.timed.push({ who: "self", kind: "dodge", turns: 1, phys: num(m[1]), spec: num(m[1]) });
  });
  r.take(/(?:使用后)?接下来(\d+)回合，能将伤害值的(\d+)%转化来回复自己|使用后(\d+)回合内，能将伤害值的(\d+)%转化来回复自己/, (m) => void e.timed.push({ who: "self", kind: "drain", turns: num(m[1] ?? m[3]), f: num(m[2] ?? m[4]) / 100 }));
  r.take(/每回合扣除对方单体最大体力值的(\d+\/\d+)，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: num(m[2]), f: frac(m[1]) }));
  r.take(/接下来(\d+)回合若对方受到伤害，都可能被秒杀/, (m) => void e.timed.push({ who: "foe", kind: "doom", turns: num(m[1]), chance: 10 }));
  r.take(new RegExp(`对方每受到(烧伤|冰冻|束缚)伤害1次，就(提升自己|降低对方)(${STAT_LIST})(?:的)?等级(?:各)?(\\d+)级`), (m) => {
    const up = m[2] === "提升自己";
    e.timed.push({ who: up ? "self" : "foe", kind: "stagesEachTurn", turns: 99, stats: statsOf(m[3]), delta: (up ? 1 : -1) * num(m[4]), chance: 100, ...(up ? { whileOther: statusOf(m[1]) } : { while: statusOf(m[1]) }) });
  });
  r.take(/若对方处于(烧伤)状态，秒杀概率翻倍/, (m) => void (e.ohkoDoubleIf = { foeStatus: statusOf(m[1]) }));
  r.take(/(?:本回合)?自己若被对方打败，则扣除对方所有技能的PP/, () => void (e.grudge = true));
  r.take(/连续攻击对方(?:单体)?(\d+)回合，(?=每回合均有)/, (m) => void (e.lock = { turns: [num(m[1]), num(m[1])], after: "none" }));
  r.take(/每回合均有(?=\d+%概率令对方)/, () => undefined);
  r.take(/使用后本回合自己只承受对方一半的伤害，反击另一半伤害；?自己被击败(?:则)?无法反击/, () => void (e.shield = { take: 0.5, reflect: 0.5, ifAlive: true }));
  r.take(/提升我方全体伤害(\d+)%，(?=闪避)/, (m) => void e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 3), mult: 1 + num(m[1]) / 100 }));
  r.take(/若对方(烧伤)，自己回复(\d+\/\d+)体力值/, (m) => void (e.healAfter = { f: frac(m[2]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
  r.take(/(\d+)回合内自己不受(睡眠)和(害怕)的状态影响/, (m) => void e.timed.push({ who: "self", kind: "nostatus", turns: num(m[1]), only: [statusOf(m[2]), statusOf(m[3])] }));
  r.take(/回合结束时消耗自己体力值到1点/, () => void (e.delayed = { who: "self", turns: 0, kind: "hpTo1" }));
  r.take(/但是必定能被普通系技能攻击命中且伤害加倍/, () => undefined);
  r.take(/(?:另外，)?自身不死，每回合扣除对方所有PP值(\d+)点/, (m) => void e.timed.push({ who: "foe", kind: "ppdrain", turns: 99, n: num(m[1]) }));
  r.take(/然后连续攻击对方(?:单体)?(\d+)回合/, (m) => void (e.lock = { turns: [num(m[1]), num(m[1])], after: "none" }));
  r.take(/被冰冻时，速度等级每回合削弱(\d+)级/, (m) => void e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: 99, stats: ["spd"], delta: -num(m[1]), chance: 100, while: "冰冻" }));
  r.take(/随机攻击对方(\d+)~(\d+)回合/, (m) => void (e.lock = { turns: [num(m[1]), num(m[2])], after: "none" }));
  r.take(/完全吸收对方的伤害值来回复自己体力/, () => void (e.absorbHit = true));
  r.take(/使用后自己停止行动(\d+)回合/, (m) => {
    e.recharge = true;
    e.rechargeTurns = num(m[1]);
  });
  // regen
  r.take(/(?:3回合内|使用后3回合内)?每回合(?:自己)?(?:为我方全体|自己|自动)?(?:回复|恢复)(?:自己|该亚比|亚比)?(?:(\d+)点|最大体力值的(\d+\/\d+)|(\d+)点体力值|(\d+)体力值|(\d+\/\d+)体力值)?(?:体力值)?(?:，?(?:持续)?(\d+)回合(?:有效)?)?/, (m) => {
    const n = m[1] ?? m[3] ?? m[4];
    const turns = m[6] ? num(m[6]) : turnsOf(r.d, /无限/.test(r.d) ? 999 : 5);
    const f = m[2] ?? m[5];
    e.timed.push({ who: "self", kind: "regen", turns, ...(n ? { n: num(n) } : { f: f ? frac(f) : 1 / 16 }), endsOnSwitch: endsOnSwitch(m[0]) });
  });
  r.take(/(?:持续(\d+)回合)?(?:回复|恢复)(\d+)点体力值/, () => false);
  r.take(/每?回合结束时(?:回复|恢复)(?:最大体力值的)?(\d+\/\d+)(?:最大体力值?)?/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: turnsOf(r.d, 3), f: frac(m[1]) }));
  r.take(/每回合结束时回复1\/10最大体力/, () => void e.timed.push({ who: "self", kind: "regen", turns: 5, f: 0.1 }));
  r.take(/(?:回合末回复的体力值=已损失体力值\/8|自己体力值损失越多回复越多|每回合结束时回复自己的体力值，自己的剩余体力值越少，回复量越多)，?(?:持续(\d+)回合)?/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: m[1] ? num(m[1]) : turnsOf(r.d, 5), f: 1 / 8, lost: true }));
  r.take(/每回合均有(\d+)%概率回复自己所有体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: turnsOf(r.d, 5), f: 1, chance: num(m[1]) }));
  r.take(/每回合恢复(\d+)体力值，持续(\d+)回合，75%概率作用给自己，25%概率作用给对方/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num(m[2]), n: num(m[1]), chance: 75 }));
  r.take(/持续(\d+)回合回复(\d+)点体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num(m[1]), n: num(m[2]) }));
  r.take(/(\d+)回合内每回合回复自身(\d+)点体力值/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num(m[1]), n: num(m[2]) }));
  r.take(/回合结束时恢复一定体力值/, () => void e.timed.push({ who: "self", kind: "regen", turns: 5, f: 1 / 16 }));
  r.take(/回合结束时(?:为自己|回复对方体力值)(?:回复)?(\d+)点体力值?/, (m) => (/对方/.test(m[0]) ? undefined : void e.timed.push({ who: "self", kind: "regen", turns: 1, n: num(m[1]) })));
  // leech
  r.take(/每回合(?:吸取|扣除)对方单体(?:最大体力值的(\d+\/\d+)|(\d+)点体力值)用来回复自己(?:体力值)?(?:，?持续(\d+)回合)?(?:，对木系无效)?/, (m) => {
    e.timed.push({ who: "foe", kind: "leech", turns: m[3] ? num(m[3]) : 99, ...(m[2] ? { n: num(m[2]) } : { f: frac(m[1]) }), ...(/木系无效/.test(m[0]) ? { attr: ATTRS.木 } : {}) });
  });
  r.take(/扣除对方(\d+\/\d+)的最大体力值来回复自己体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "leech", turns: num(m[2]), f: frac(m[1]) }));
  r.take(/若对方处于睡眠中，夺取(\d+\/\d+)体力值用来回复自己/, (m) => {
    e.dmg = { kind: "hpFrac", f: frac(m[1]) };
    e.dmgHeals = "all";
    (e.powerIf ??= []).push({ cond: { foeStatus: "睡眠" }, mult: 1 });
  });
  // damage over time on the foe (or both)
  r.take(/(?:令对方单体)?(\d+)~(\d+)回合无法替换亚比，且每回合(?:扣除|损伤)最大体力值的(\d+\/\d+)/, (m) => {
    e.trap = [num(m[1]), num(m[2])];
    e.timed.push({ who: "foe", kind: "dot", turns: num(m[2]), f: frac(m[3]) });
  });
  r.take(/(?:令对方单体)?无法替换亚比，每回合扣除最大体力值的(\d+\/\d+)/, (m) => {
    e.trap = [5, 5];
    e.timed.push({ who: "foe", kind: "dot", turns: 5, f: frac(m[1]) });
  });
  r.take(/使用后(\d+)~(\d+)回合对方不能替换亚比，且每回合损伤最大体力值的(\d+\/\d+)/, (m) => {
    e.trap = [num(m[1]), num(m[2])];
    e.timed.push({ who: "foe", kind: "dot", turns: num(m[2]), f: frac(m[3]) });
  });
  r.take(/束缚对方单体，禁止对方替换亚比|束缚对方(?=$|，)/, () => {
    e.statuses.push({ name: "束缚", chance: 100 });
    e.trap = [4, 5];
  });
  r.take(/(?:若自己不死，)?每回合给对方(?:单体)?造成(\d+)点伤害值?(?:，持续(\d+)回合)?/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: m[2] ? num(m[2]) : 99, n: num(m[1]) }));
  r.take(/令对方单体每回合随机损失(\d+)~(\d+)点体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: num(m[3]), a: num(m[1]), b: num(m[2]) }));
  r.take(/每回合结束时，均有(\d+)%概率令扣除对方单体最大体力值的(\d+)%，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: num(m[3]), f: num(m[2]) / 100, chance: num(m[1]) }));
  r.take(/令睡眠中的对方每回合扣除最大体力值的(\d+\/\d+)/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: 99, f: frac(m[1]), while: "睡眠" }));
  r.take(/(?:数码系亚比扣除自己最大体力值的1\/2，)?对方单体每回合扣除最大体力值的(\d+\/\d+)/, (m) => {
    e.timed.push({ who: "foe", kind: "dot", turns: 5, f: frac(m[1]) });
    if (/数码系/.test(m[0])) e.selfCost = { f: 0.5 };
  });
  r.take(/每回合扣除对方单体最大体力值的(\d+\/\d+)，无限回合/, (m) => void e.timed.push({ who: "foe", kind: "dot", turns: 999, f: frac(m[1]) }));
  r.take(/双方每回合均扣除自己最大体力值的(\d+\/\d+)，持续(\d+)回合/, (m) => void e.timed.push({ who: "both", kind: "dot", turns: num(m[2]), f: frac(m[1]) }));
  r.take(/每回合扣除双方体力值(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "both", kind: "dot", turns: num(m[2]), n: num(m[1]) }));
  r.take(/(\d+)回合，(\d+)%概率扣除对方单体(\d+)点体力值，否则扣除自己(\d+)点体力值/, (m) => void e.timed.push({ who: "foe", kind: "gamble", turns: num(m[1]), chance: num(m[2]), n: num(m[3]), self: -num(m[4]) }));
  r.take(/(\d+)%概率扣除对方单体(\d+)点体力值，否则自己回复(\d+)点体力值，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "gamble", turns: num(m[4]), chance: num(m[1]), n: num(m[2]), self: num(m[3]) }));
  r.take(/(\d+)%概率扣除对方单体一半的体力值，否则扣除自己一半的体力值/, (m) => {
    e.dmg = { kind: "hpFrac", f: 0.5 };
    e.painSplitChance = num(m[1]); // used as the gamble's chance (死神镰刀)
  });
  r.take(/每回合扣除自己体力值(\d+)点，随机削弱对方一种属性的等级(\d+)级，持续(\d+)回合/, (m) => {
    e.timed.push({ who: "self", kind: "dot", turns: num(m[3]), n: num(m[1]) });
    e.timed.push({ who: "foe", kind: "stagesEachTurn", turns: num(m[3]), stats: ALL_STATS, delta: -num(m[2]), chance: 100 });
  });
  r.take(/回合结束时随机提升自己(防御或特防)等级(\d+)级(?:，持续(\d+)回合)?/, (m) => void e.timed.push({ who: "self", kind: "stagesEachTurn", turns: m[3] ? num(m[3]) : turnsOf(r.d, 4), stats: statsOf(m[1].replace("或", "和")), delta: num(m[2]), chance: 100 }));
  r.take(/(\d+)回合内双方亚比每回合随机下降全属性1级/, (m) => void e.timed.push({ who: "both", kind: "stagesEachTurn", turns: num(m[1]), stats: ALL_STATS, delta: -1, chance: 100 }));
  r.take(/(?:回合结束时有一定几率|一定几率)扣除自身最大生命值(\d+\/\d+)/, (m) => void e.timed.push({ who: "self", kind: "dot", turns: 1, f: frac(m[1]), chance: 30 }));
  r.take(/使用后(\d+)回合内，每回合将自己所有PP值1点转化来回复(\d+)点体力值(?:，最多叠加\d+次)?/, (m) => void e.timed.push({ who: "self", kind: "pphp", turns: num(m[1]), n: num(m[2]) }));
  r.take(/(?:使用后)?(\d+)回合内，每攻击对方1次，就回复自己(\d+)点体力值/, (m) => void e.timed.push({ who: "self", kind: "hitHeal", turns: num(m[1]), n: num(m[2]) }));
  r.take(/扔出骰子的点数越大，给对方造成伤害越大，自己回复的体力值也越多，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "gamble", turns: num(m[1]), chance: 100, a: 20, b: 120, self: 1 }));
  // screens, dodges, reflections, absorbs
  r.take(/我方全体受到(普通|特殊)攻击的伤害减半，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: num(m[2]), ...(m[1] === "普通" ? { phys: 0.5 } : { spec: 0.5 }) }));
  r.take(/(?:自己受到普通或特殊攻击时伤害减半|自己只承受一半普通攻击与特殊攻击造成的伤害|抵抗普通攻击与特殊攻击类型造成伤害的一半)/, () => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 3), phys: 0.5, spec: 0.5 }));
  r.take(/(?:接下来\d+个回合)?提升我方全体队员抵抗普通攻击伤害的(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 4), phys: 1 - num(m[1]) / 100 }));
  r.take(/自己抵抗对方造成伤害的(\d+)%，甚至抵抗秒杀/, (m) => void e.timed.push({ who: "self", kind: "screen", turns: turnsOf(r.d, 3), phys: 1 - num(m[1]) / 100, spec: 1 - num(m[1]) / 100 }));
  r.take(/连续攻击对方单体2回合，期间只承受对方2\/3的伤害/, () => {
    e.lock = { turns: [2, 2], after: "none" };
    e.timed.push({ who: "self", kind: "screen", turns: 2, phys: 2 / 3, spec: 2 / 3 });
  });
  r.take(/(?:使用后)?(\d+)回合内，自己受到特殊攻击时伤害减半；若受到普通攻击，则将受到伤害的(\d+\/\d+)返击对方/, (m) => {
    e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), spec: 0.5 });
    e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]) });
  });
  r.take(/使用后(\d+)回合内，将对方(特殊|普通)攻击(\d+\/\d+)的伤害反击回去，自己只承受伤害的(\d+\/\d+)(?:；不能和.*同时存在(?:效果)?.*)?/, (m) => {
    const k = m[2] === "普通" ? "phys" : "spec";
    e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), [k]: frac(m[3]) });
    e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), [k]: frac(m[4]) });
  });
  r.take(/使用后(\d+)回合内，将所受伤害的(\d+\/\d+)返还给对方，自身承受(\d+\/\d+)/, (m) => {
    e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: frac(m[2]), spec: frac(m[2]) });
    e.timed.push({ who: "self", kind: "screen", turns: num(m[1]), phys: frac(m[3]), spec: frac(m[3]) });
  });
  r.take(/(\d+)回合内将受到的伤害值的(\d+)%反击对方单体/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num(m[1]), phys: num(m[2]) / 100, spec: num(m[2]) / 100 }));
  r.take(/反弹受到普通攻击的(\d+(?:\.\d+)?)倍伤害给对方/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: 5, phys: num(m[1]) }));
  r.take(/若5回合内不受普通攻击，浑天.*$/, () => undefined);
  r.take(/自己受到伤害则反弹(\d+)点伤害给对方，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "reflect", turns: num(m[2]), n: num(m[1]) }));
  r.take(/每回合自己可以抵抗(\d+)点伤害值，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "absorb", turns: num(m[2]), n: num(m[1]) }));
  r.take(/(\d+)%概率自己免受(普通|特殊)攻击造成的伤害，持续(\d+)回合(?:，不能和技能.*效果同时存在)?/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: num(m[3]), ...(m[2] === "普通" ? { phys: num(m[1]) } : { spec: num(m[1]) }) }));
  r.take(/(?:使用后，)?(\d+)%概率(?:闪避|躲过)(特殊攻击与普通攻击技能|特殊攻击技能|对方的攻击)(?:造成的伤害)?，持续(\d+)(?:~(\d+))?回合/, (m) => {
    const both = !/^特殊攻击技能$/.test(m[2]);
    e.timed.push({ who: "self", kind: "dodge", turns: num(m[4] || m[3]), spec: num(m[1]), ...(both ? { phys: num(m[1]) } : {}) });
  });
  r.take(/使用后(?:3回合内)?(\d+)%概率令对方的攻击无效/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: 3, phys: num(m[1]), spec: num(m[1]) }));
  r.take(/使用后3回合内30%概率令对方的攻击无效/, () => void e.timed.push({ who: "self", kind: "dodge", turns: 3, phys: 30, spec: 30 }));
  r.take(/使用后自己进入隐身状态，(\d+)%概率闪避对方的伤害，但是必定能被普通系技能攻击命中/, (m) => void e.timed.push({ who: "self", kind: "dodge", turns: 3, phys: num(m[1]), spec: num(m[1]) }));
  r.take(/每回合自动随机产生对普通攻击或者特殊攻击的抵抗/, () => void e.timed.push({ who: "self", kind: "screen", turns: 5, phys: 0.5, flip: true }));
  // stage guards, no statuses
  r.take(/(?:保护我方全体，)?(?:持续)?(\d+)回合(?:内)?(?:，)?(?:自己)?(?:属性能力等级|全属性)(?:不能|不可|不会)被削弱|自己属性能力等级不会被削弱，持续(\d+)回合|(?:接下来)?(\d+)回合(?:自己)?全属性不(?:能|可)被削弱/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num(m[1] ?? m[2] ?? m[3]) }));
  r.take(/持续(\d+)回合，自己属性能力等级不能被削弱(?:；若对方提升它的属性能力等级，同样也会加给自己)?/, (m) => void e.timed.push({ who: "self", kind: "guard", turns: num(m[1]) }));
  r.take(/两回合内对方属性等级无法被提升或降低/, () => undefined);
  r.take(/使用后自己不会陷入异常状态，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "nostatus", turns: num(m[1]) }));
  r.take(/免疫烧伤/, () => undefined);
  // power and crit boosts of the user
  r.take(/给自己的普通攻击与特殊攻击技能附加(\d+)威力，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "power", turns: num(m[2]), add: num(m[1]) }));
  r.take(/提升自身所有技能威力(\d+)点，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "power", turns: num(m[2]), add: num(m[1]) }));
  r.take(/(?:技能)?威力提升至(\d+(?:\.\d+)?)倍/, (m) => void e.timed.push({ who: "self", kind: "power", turns: turnsOf(r.d, 4), mult: num(m[1]) }));
  r.take(/(?:使用后接下来(\d+)回合，)?(?:我方全体)?(光明|飞行)系技能威力提升(\d+)%，伤害抵抗(?:能力)?提升(\d+)%(?:，持续(\d+)回合)?/, (m) => {
    const turns = num(m[1] || m[5], 3);
    e.timed.push({ who: "self", kind: "power", turns, mult: 1 + num(m[3]) / 100, attr: ATTRS[m[2]] });
    e.timed.push({ who: "self", kind: "screen", turns, phys: 1 - num(m[4]) / 100, spec: 1 - num(m[4]) / 100 });
  });
  r.take(/下回合使用(木)系技能威力上升(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "power", turns: 2, mult: 1 + num(m[2]) / 100, attr: ATTRS[m[1]] }));
  r.take(/使用后(\d+)回合内，使得自己的每次攻击均有(\d+)%概率暴击对方/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num(m[1]), chance: num(m[2]) }));
  r.take(/使用后接下来(\d+)回合，自己技能暴击概率提升至(\d+)%/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num(m[1]), chance: num(m[2]) }));
  r.take(/使用后，接下来(\d+)个?回合暴击等级提升至6级/, (m) => void e.timed.push({ who: "self", kind: "crit", turns: num(m[1]), chance: 50 }));
  r.take(/使用后接下来(\d+)回合，给对方造成伤害时附加(\d+)%概率害怕效果/, (m) => void e.timed.push({ who: "self", kind: "onhit", turns: num(m[1]), chance: num(m[2]), n: 1 }));
  r.take(/使用后(\d+)回合内，自己给对方造成伤害时，都有(\d+)%概率清除对方提升的属性能力等级/, (m) => void e.timed.push({ who: "self", kind: "onhit", turns: num(m[1]), chance: num(m[2]), n: 2 }));
  r.take(/使用后(\d+)回合内，自己的(防御和速度)加倍/, (m) => void e.timed.push({ who: "self", kind: "statmult", turns: num(m[1]), stats: statsOf(m[2]), mult: 2 }));
  r.take(/(?:使用后)?(\d+)回合内，受到伤害则提升自身(防御和特防)的等级各(\d+)级/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: num(m[1]), stats: statsOf(m[2]), delta: num(m[3]), chance: 100, selfStage: true }));
  r.take(/若自己受到(?:伤害|攻击)，(?:有(\d+)%概率)?(?:则)?扣除对方(?:全部技能PP|所有PP)(\d+)点，持续(\d+)回合/, () => undefined);
  r.take(/(?:使用后)?(\d+)回合内，?若当回合对方不使用攻击技能，则当回合结束时扣除对方(\d+)点体力值/, () => undefined);
  // no acting
  r.take(/令对方单体每回合均有(\d+)%概率无法进行攻击，持续(\d+)回合/, (m) => void e.timed.push({ who: "foe", kind: "noact", turns: num(m[2]), chance: num(m[1]) }));
  r.take(/(\d+)回合内，每回合均有(\d+\/\d+)概率令对方单体无法使用技能/, (m) => void e.timed.push({ who: "foe", kind: "noact", turns: num(m[1]), chance: frac(m[2]) * 100 }));
  r.take(/令对方单体(\d+)~(\d+)回合内使用普通攻击技能必定很难命中/, (m) => void e.timed.push({ who: "foe", kind: "blind", turnsMin: num(m[1]), turns: num(m[2]), phys: 25 }));
  // field
  r.take(/(?:全场|10回合内，全场)(\S{1,3}?)系(?:技能)?威力(?:提升|上升)(\d+)%(?:，(\S{1,2}?)系威力削弱(\d+)%)?(?:，(?:持续)?(\d+)回合(?:有效)?)?/, (m) => {
    const up = ATTRS[m[1]];
    if (up === undefined) return false;
    e.field = { up, upPct: num(m[2]), ...(m[3] && ATTRS[m[3]] !== undefined ? { down: ATTRS[m[3]], downPct: num(m[4]) } : {}), turns: m[5] ? num(m[5]) : turnsOf(r.d, 5) };
  });
  r.take(/每回合结束时(\d+)%概率令对方全场(麻痹)/, (m) => void e.timed.push({ who: "foe", kind: "plague", turns: turnsOf(r.d, 5), chance: num(m[1]), status: statusOf(m[2]) }));
  // multi-turn skills
  r.take(/(?:本回合不行动，下回合自动攻击对方单体|本回合停止行动，下回合先发攻击对方单体|本回合聚集能量，下回合给予对方致命打击|蓄力(\d+)回合下回合爆发出无法阻挡的伤害)/, (m) => {
    if (m[1] && num(m[1]) > 1) e.chargeTurns = num(m[1]);
    if (/无法阻挡/.test(m[0])) {
      e.sure = true;
      e.pierce = true;
    }
    e.charge = true;
    if (/先发/.test(m[0])) e.chargeFirst = true;
  });
  r.take(/若蓄力时未受到伤害则伤害翻倍/, () => void (e.powerIf ??= []).push({ cond: { chargeUnhurt: true }, mult: 2 }));
  r.take(/连续(\d+)~(\d+)个?回合攻击对方随机目标(?:，命中后自己陷入混乱|，之后自己陷入混乱)?|连续攻击对方随机单体(\d+)~(\d+)回合，之后自己陷入混乱/, (m) => void (e.lock = { turns: [num(m[1] ?? m[3]), num(m[2] ?? m[4])], after: "confuse" }));
  r.take(/连续(\d+)回合(?:向敌方扔出威力巨大的飞刀|攻击对方(?:单体)?)?，?(?:威力十分巨大)?，?之后自己(?:休息|停止行动)1回合/, (m) => void (e.lock = { turns: [num(m[1]), num(m[1])], after: "rest" }));
  r.take(/连续攻击对方单体2回合，第2回合结束时回复自己(\d+\/\d+)体力值/, (m) => void (e.lock = { turns: [2, 2], after: "heal", healF: frac(m[1]) }));
  r.take(/连续3回合攻击对方单体，威力每回合增加/, () => void (e.rollout = { turns: 3 }));
  // this turn
  r.take(/本回合闪避对方的攻击|当回合闪避对方的攻击|本回合闪避对方攻击/, () => void (e.protect = true));
  r.take(/一场战斗使用次数越多，成功率越低(?:；使用失败则回复自己(\d+)点体力值?)?/, (m) => (m[1] ? void (e.failHeal = num(m[1])) : undefined));
  r.take(/若自己速度快过对方，则无视对方本回合攻击/, () => void (e.protect = true));
  r.take(/将本回合受到对方(特殊|普通)攻击的伤害，加倍反击对方/, (m) => void (e.shield = { take: 1, reflect: 2, kind: m[1] === "普通" ? "phys" : "spec" }));
  r.take(/若(?:没死亡|自己不死)，(?:则)?将(?:承受的伤害|本回合承受伤害的|本回合受到的伤害)(加倍|(\d+(?:\.\d+)?)倍)反击(?:给)?对方/, (m) => void (e.shield = { take: 1, reflect: m[2] ? num(m[2]) : 2, ifAlive: true }));
  r.take(/若自己先出手，则将本回合受到攻击的(\d+(?:\.\d+)?)倍，反击对方/, (m) => void (e.shield = { take: 1, reflect: num(m[1]), ifFirst: true }));
  r.take(/将自己受到伤害的(\d+(?:\.\d+)?)倍反击对方全体/, (m) => void (e.shield = { take: 1, reflect: num(m[1]) }));
  r.take(/本回合自己若被对方打败，则双方同归于尽/, () => void (e.destiny = true));
  r.take(/自己本回合若死亡，则自己满状态复活/, () => void (e.endure = "revive"));
  r.take(/使用后被对方打败则满状态复活/, () => void (e.endure = "reviveOnce"));
  // later turns
  r.take(/(?:令对方单体)?下回合结束时睡眠/, () => void (e.delayed = { who: "foe", turns: 1, kind: "sleep" }));
  r.take(/下回合结束时，?(?:回复自己所有体力值|完全回复自己体力值)/, () => void (e.delayed = { who: "self", turns: 1, kind: "healFull" }));
  r.take(/下回合结束时，对方体力值减少(\d+)点/, (m) => void (e.delayed = { who: "foe", turns: 1, kind: "flat", n: num(m[1]) }));
  r.take(/(\d+)回合后，扣除对方(?:亚比)?(1\/2)的体力值/, (m) => void (e.delayed = { who: "foe", turns: num(m[1]), kind: "hpFrac", f: frac(m[2]) }));
  r.take(/(\d+)回合后，对方全体扣除最大体力值的(1\/2)/, (m) => void (e.delayed = { who: "foe", turns: num(m[1]), kind: "maxFrac", f: frac(m[2]) }));
  r.take(/(\d+)回合后，对方单体将因为时间被完全吞噬而死亡/, (m) => void (e.delayed = { who: "foe", turns: num(m[1]), kind: "kill" }));
  r.take(/下回合结束时，自己体力值降为1点/, () => void (e.delayed = { who: "self", turns: 1, kind: "hpTo1" }));
  r.take(/(\d+)回合后提升自己全属性(\d+)级/, (m) => void (e.delayed = { who: "self", turns: num(m[1]), kind: "stages", stats: ALL_STATS, delta: num(m[2]) }));
  // switching
  r.take(/强制对方单体替换亚比战斗|若本回合未受到伤害则强制对方单体替换亚比战斗/, () => void (e.forceSwitch = true));
  r.take(/(?:令对方单体)?(\d+)~(\d+)回合无法替换亚比|使用后无法替换亚比/, (m) => (m[1] ? void (e.trap = [num(m[1]), num(m[2])]) : undefined));
  r.take(/使用后无法替换亚比/, () => undefined);
  // the turn after
  r.take(/(?:(\d+)%概率|一定概率|有一定概率)?(?:令)?(?:自己)?下回合(?:自己)?(?:停止行动|无法行动)(?:1回合)?|命中后(?:有一定概率)?自己停止行动(?:1回合)?|使用后(?:自己)?停止行动1回合|之后自己停止行动1回合/, (m) => {
    e.recharge = true;
    if (m[1]) e.rechargeChance = num(m[1]);
    else if (/一定概率/.test(m[0])) e.rechargeChance = 30;
  });
  r.take(/(\d+)%概率下回合自己停止?行?动?|(\d+)%概率(?:会)?使自己下回合.*$/, (m) => {
    e.recharge = true;
    e.rechargeChance = num(m[1] ?? m[2]);
  });
  r.take(/(\d+)%概率令自己或对方下回合停止行动1回合，若对方麻痹则自己下回合不会停止行动/, (m) => void (e.eitherStops = num(m[1])));
  r.take(/(\d+)%概率扣除自己(\d+)体力值/, (m) => void (e.selfCost = { n: num(m[2]), chance: num(m[1]) }));
  r.take(new RegExp(`若对方(混乱)则额外提升自己(${STAT_LIST})等级(\\d+)级`), (m) => void e.stages.push({ self: true, stats: statsOf(m[2]), delta: num(m[3]), chance: 100, cond: { foeStatus: statusOf(m[1]) } }));
  r.take(new RegExp(`(\\d+)%概率会使自己处于(${ST})或(${ST})状态`), (m) => {
    e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]) / 2, self: true }, { name: statusOf(m[3]), chance: num(m[1]) / 2, self: true });
  });

  // What only names the kind of skill or its art, and words that change nothing in a 1 against 1.
  r.take(/(?:以后)?每回合回复该亚比最大体力值的(\d+\/\d+)，持续(\d+)回合/, (m) => void e.timed.push({ who: "self", kind: "regen", turns: num(m[2]), f: frac(m[1]) }));
  r.take(/无限回合，直至病毒死亡|无限回合/, () => undefined);
  r.take(/将束缚时造成的伤害值用来回复自己/, () => void e.timed.push({ who: "foe", kind: "leech", turns: 5, f: 1 / 16 }));

  // ---- 秒杀 and sure kills
  r.take(/(\d+)%概率秒杀(?:对方)?/, (m) => void (e.ohko = num(m[1])));
  r.take(/(?:一定概率)?秒杀(?:对|对方)?(?:同等级或低等级|等级小于或等于自己)的(?:对方|亚比)?/, () => void (e.ohkoIf = { chance: 30, lowerLevel: true }));
  r.take(/秒杀体力值小于(\d+)的对方/, (m) => void (e.ohkoIf = { chance: 100, hpBelow: num(m[1]) }));
  r.take(/若对方体力值少于(\d+)，则直接秒杀/, (m) => void (e.ohkoIf = { chance: 100, hpBelow: num(m[1]) }));
  r.take(/命中后敌我双方同归于尽/, () => void (e.bothFaint = true));
  r.take(/牺牲(?:自己|当前亚比)/, () => void (e.sacrifice = true));
  r.take(/令自己以外的亚比防御值减半/, () => void e.stages.push({ self: false, stats: ["def"], delta: -2, chance: 100 }));
  r.take(/为自己下一只出场的亚比满状态回复/, () => void (e.nextFullHeal = true));

  // ---- the damage, when it is not the formula's
  r.take(/(?:给对方(?:单体)?)?造成(?:的)?伤害(?:=|为|是)?(?:自己|我方)等级(?:×|\*|的)(\d+(?:\.\d+)?)(?:~(\d+(?:\.\d+)?))?倍?(?:的伤害)?/, (m) => void (e.dmg = { kind: "level", a: num(m[1]), b: num(m[2] || m[1]) }));
  r.take(/给对方单体造成自己等级(\d+(?:\.\d+)?)倍的伤害/, (m) => void (e.dmg = { kind: "level", a: num(m[1]), b: num(m[1]) }));
  r.take(/造成(?:的)?伤害(?:是|为|=)?对方等级的(\d+)倍/, (m) => void (e.dmg = { kind: "foeLevel", mult: num(m[1]) }));
  r.take(/(?:给对方(?:单体)?)?造成(\d+)(?:点)?伤害值?/, (m) => void (e.dmg = { kind: "flat", n: num(m[1]) }));
  r.take(/(?:50%概率)?扣除对方(?:单体|全体)?(?:剩余)?(?:的)?(一半|1\/2|1\/4|\d+%)(?:的)?体力值(?:来转化回复自己的体力值|来回复自己)?/, (m) => {
    const f = frac(m[1]);
    e.dmg = { kind: "hpFrac", f };
    if (/回复/.test(m[0])) e.dmgHeals = "all";
  });
  r.take(/扣除对方(?:单体|全体)?剩余体力值的(\d+%)/, (m) => void (e.dmg = { kind: "hpFrac", f: frac(m[1]) }));
  r.take(/扣除对方单体最大体力值的(\d+\/\d+)转化来回复自己体力值/, (m) => {
    e.dmg = { kind: "maxFrac", f: frac(m[1]) };
    e.dmgHeals = "all";
  });
  r.take(/扣除对方单体(\d+)点体力值，自己回复(\d+)点体力值/, (m) => {
    e.dmg = { kind: "flat", n: num(m[1]) };
    e.dmgHeals = num(m[2]);
  });
  r.take(/随机扣除对方(?:单体)?(\d+)~(\d+)的?体力值(用来回复自己)?/, (m) => {
    e.dmg = { kind: "range", a: num(m[1]), b: num(m[2]) };
    if (m[3]) e.dmgHeals = "all";
  });
  r.take(/(?:附加|随机附加)(\d+)~(\d+)点(?:固定)?伤害值?/, (m) => void (e.fixedRange = [num(m[1]), num(m[2])]));
  r.take(/(?:(\d+)%概率)?附加(\d+)点伤害值?/, (m) => {
    e.fixed = num(m[2]);
    if (m[1]) e.fixedChance = num(m[1]);
  });
  r.take(/若自己速度比对方快，则必定附加(\d+)点固定伤害/, () => undefined);
  r.take(/(?:随机爆发|威力)(\d+)~(\d+)(?:的威力)?/, (m) => void (e.powerRange = [num(m[1]), num(m[2])]));
  r.take(/随机爆发1~500的威力/, () => void (e.powerRange = [1, 500]));

  // ---- chances of more damage or hits
  r.take(/(\d+)%概率(?:发动|打出|发挥|造成)(\d+(?:\.\d+)?)倍(?:威力|伤害)?/, (m) => void (e.boost ??= []).push({ chance: num(m[1]), mult: num(m[2]) }));
  r.take(/一定概率发动1\.2倍威力，或者2倍威力，甚至3倍威力/, () => void (e.boost ??= []).push({ chance: 20, mult: 1.2 }, { chance: 10, mult: 2 }, { chance: 5, mult: 3 }));
  r.take(/发动时此技能威力提升至(\d+)倍，但是命中很低|发动时此威力提升至(\d+)倍，但是命中很低/, (m) => void (e.boost ??= []).push({ chance: 100, mult: num(m[1]) }));
  r.take(/但是只有一半的命中率/, () => undefined);
  r.take(/(\d+)%概率(?:1回合内)?发动(\d+)次攻击(?:效果)?/, (m) => void (e.extraHits ??= []).push({ chance: num(m[1]), n: num(m[2]) }));
  r.take(/1回合内，一定概率发动多次攻击效果，每次威力减半/, () => void (e.extraHits ??= []).push({ chance: 30, n: 2 }));
  r.take(/(\d+)%概率暴击(?:对方单体)?/, (m) => void (e.critChance = num(m[1])));

  // ---- 连击 (as before)
  {
    const h = r.d;
    if (!/下回合(?:内)?攻击/.test(h) && !/%概率\d*回合内?发动/.test(h)) {
      r.take(/(?:\d+回合内?)?(?:连续)?(?:攻击|撞击)对方(?:单体|全体|全场)?(\d+)~(\d+)次/, (m) => void (e.hits = [num(m[1]), num(m[2])]));
      r.take(/(?:\d+回合内?)?(?:爆发|发动)(\d+)~(\d+)次(?:攻击)?/, (m) => void (e.hits ??= [num(m[1]), num(m[2])]));
      r.take(/\d+回合内?(?:攻击|撞击)对方(?:单体|全体|全场)?(\d+)次/, (m) => (Number(m[1]) > 1 ? void (e.hits ??= [num(m[1]), num(m[1])]) : false));
      r.take(/\d+回合内?发动(\d+)次攻击/, (m) => (Number(m[1]) > 1 ? void (e.hits ??= [num(m[1]), num(m[1])]) : false));
    }
    if (e.hits && /每次(?:攻击|命中)/.test(h)) e.perHit = true;
  }
  r.take(/每次(?:攻击|命中)?(?:均|都)?(?:会|有|可以)?/, () => undefined);

  // ---- drain, recoil, heal after the hit
  r.take(/(?:若暴击，则|自己体力值少于一半时，会|对方被冰冻时，|如果对方处于睡眠状态，则|若对方处于睡眠状态，则)?(?:吸取|将|给对方)?(?:造成(?:的)?)?(?:伤害值?|攻击值|对敌人造成伤害|全部伤害值)(?:的)?(一半|\d+\/\d+|\d+%|4倍)?(?:转化来|用来|来)?回复(?:自己)?(?:的)?(?:体力值?)?/, (m) => {
    const t = m[0];
    const f = m[1] === "4倍" ? 4 : m[1] ? frac(m[1]) : 1;
    const c = /暴击/.test(t) ? ({ crit: true } as Cond) : /少于一半/.test(t) ? ({ selfHpBelow: 0.5 } as Cond) : /冰冻/.test(t) ? ({ foeStatus: "冰冻" } as Cond) : /睡眠/.test(t) ? ({ foeStatus: "睡眠" } as Cond) : undefined;
    if (c && e.drain !== undefined && /如果/.test(t)) {
      // A second, better drain under a condition (幽夜玫瑰: 30%, 60% on a sleeping foe).
      e.healAfter = undefined;
      (e.powerIf ??= []).push({ cond: c, drain: f });
      return;
    }
    e.drain = f;
    if (c) e.drainCond = c;
  });
  r.take(/伤害的(\d+%)转化回复自己/, (m) => void (e.drain = frac(m[1])));
  r.take(/回复对敌人造成伤害的一半的体力值/, () => void (e.drain = 0.5));
  r.take(/溢出的回复量会转化为自己的护盾/, () => void (e.overShield = true));
  r.take(/(?:(\d+)%概率)?(?:自身|自己)承受(?:造成|给)?(?:伤害值?|伤害)的(\d+\/\d+)/, (m) => {
    e.recoil = frac(m[2]);
    if (m[1]) e.recoilChance = num(m[1]);
  });
  r.take(/自己承受(\d+\/\d+)的伤害/, (m) => void (e.recoil = frac(m[1])));
  r.take(/命中后扣除自己(\d+\/\d+)体力值/, (m) => void (e.selfCost = { f: frac(m[1]), current: true }));
  r.take(/(?:先)?扣除(?:自己|自身)(?:最大体力值的)?(\d+\/\d+|一半)(?:最大体力值)?/, (m) => void (e.selfCost = { f: frac(m[1]) }));
  r.take(/扣除自身当前体力值(\d+\/\d+)/, (m) => void (e.selfCost = { f: frac(m[1]), current: true }));
  r.take(/(?:先)?扣除自己(\d+)(?:点)?体力值|扣除自己体力值(\d+)点/, (m) => void (e.selfCost = { n: num(m[1] ?? m[2]) }));
  r.take(/消耗自己最大体力值的(\d+\/\d+)/, (m) => void (e.selfCost = { f: frac(m[1]) }));
  r.take(/(?:(\d+)%概率)?(?:回复|恢复)(?:自己|自身)?(?:体力最大值的|最大体力值的)?(\d+\/\d+|一半|\d+%)(?:(?:最大)?(?:的)?体力值?)?/, (m) => {
    const f = frac(m[2]);
    e.healAfter = { f, chance: pct(m[1]) };
    if (!m[1]) e.heal = f;
  });
  r.take(/若自己出手速度快过对方，则恢复自己体力最大值的(\d+\/\d+)/, (m) => void (e.healAfter = { f: frac(m[1]), chance: 100, cond: { faster: true } }));
  r.take(/(\d+)%概率回复自己所有体力值/, (m) => void (e.healAfter = { f: 1, chance: num(m[1]) }));
  r.take(/(?:回复|恢复|完全回复)(?:自己|我方全体|自身)?(?:所有|全部)体力值?/, () => void (e.healFull = true));
  r.take(/回复自己全部体力值和技能PP/, () => {
    e.healFull = true;
    e.ppSelf = 99;
  });
  r.take(/(?:回复|恢复)(?:自己|我方全体(?:亚比)?|自身|其)?(\d+)(?:点)?体力值?/, (m) => void (e.healFlat = num(m[1])));
  r.take(/治愈我方(?:全体|单个亚比)，?(?:回复(?:亚比|其)?(一半)体力值)?/, (m) => {
    e.cure = true;
    if (m[1]) e.healAfter = { f: 0.5, chance: 100 };
  });
  r.take(/(\d+)回合进入睡眠状态|自己进入睡眠状态/, (m) => void (e.sleepAfter = m[1] ? num(m[1]) : 2));
  r.take(/(?:清除|净化)(?:我方全体|自己)(?:所有)?(?:异常|不良)状态|清除自己烧伤、冰冻、寄生和中毒的状态|并清除自己不良状态|清除所有不良状态/, () => void (e.cure = true));
  r.take(/若对方死亡则自己满状态回复/, () => void (e.healOnKO = 1));
  r.take(/若击败对方，回合结束时回复自己(一半|\d+\/\d+)的?体力值/, (m) => void (e.healOnKO = frac(m[1])));

  // ---- PP
  r.take(/(?:若对方处于(睡眠|衰弱|烧伤)(?:状态)?，(?:则|可|有)?)?(?:(\d+)%概率)?(?:扣光对方所有技能的PP|扣除(?:睡眠中的)?对方(?:单体)?(?:所有|全部)?(?:技能)?PP(?:值)?(\d+)点|令对方单体所有技能的PP减少(\d+)点|扣除对方全部技能PP(\d+)点|扣除对方所有PP(\d+)点)/, (m) => {
    const n = m[3] ?? m[4] ?? m[5] ?? m[6];
    const c: Cond | undefined = m[1] ? { foeStatus: statusOf(m[1]) } : /睡眠中的/.test(m[0]) ? { foeStatus: "睡眠" } : undefined;
    e.ppFoe = { n: n ? num(n) : "all", chance: pct(m[2]), cond: c };
  });
  r.take(/(?:(\d+)%概率)?(?:令|扣除)?对方(?:单体)?(?:最后使用(?:的)?技能的?)PP(?:值)?(?:减少)?(\d+)点/, (m) => void (e.ppFoe = { n: num(m[2]), last: true, chance: pct(m[1]) }));
  r.take(/(?:并)?(?:扣除)?(?:对方)?最后使用技能的PP值(\d+)点/, (m) => void (e.ppFoe = { n: num(m[1]), last: true, chance: 100 }));
  r.take(/(?:(\d+)%概率)?(?:自己)?(?:增加|回复|恢复)(?:自己|我方全体亚比)?(?:所有)?(?:技能)?PP值?(\d+)点/, (m) => void (e.ppSelf = num(m[2])));
  r.take(/我方全体亚比回复PP值(\d+)点/, (m) => void (e.ppSelf = num(m[1])));
  r.take(/(?:消耗|额外消耗)(?:自己|自身)?(?:所有|全部)(?:技能)?PP值?(?:(\d+)点)?/, (m) => (m[1] ? void (e.ppSelf = -num(m[1])) : void (e.ppSelfAll = true)));
  r.take(/如果对方睡眠，则清除对方上次使用的技能的全部PP/, () => void (e.ppFoe = { n: "all", last: true, chance: 100, cond: { foeStatus: "睡眠" } }));

  // ---- statuses
  r.take(/(?:令)?(?:自身|自己)束缚(\d+)回合/, () => undefined);
  r.take(/令对方衰弱，对方损失的体力值会逐渐增加/, () => void e.statuses.push({ name: "衰弱", chance: 100 }));
  r.take(/(?:如果对方攻击自己，)?有(\d+)%概率也陷入睡眠/, (m) => void e.timed.push({ who: "self", kind: "onhurt", turns: 3, chance: num(m[1]), status: "睡眠" }));
  r.take(/(?:(\d+)%概率)?(?:令)?(?:自己|自身)(?:陷入|处于)?(混乱|睡眠|麻痹)/, (m) => void e.statuses.push({ name: statusOf(m[2]), chance: pct(m[1]), self: true }));
  r.take(/(\d+)%概率(混乱)自己/, (m) => void e.statuses.push({ name: "混乱", chance: num(m[1]), self: true }));
  r.take(/(?:之后)?自己陷入混乱|命中后自己(?:陷入)?混乱/, () => void (e.selfConfuse = true));
  r.take(/(?:(\d+)%概率|一定概率)?(?:令|使)?对方(?:单体|全体|全场)?(?:处于)?(?:任意一种|各种)(?:不良|异常|不良或异常)状态/, (m) => {
    const chance = m[1] ? num(m[1]) : 30;
    for (const s of BAD_STATUSES) e.statuses.push({ name: s, chance: chance / BAD_STATUSES.length });
  });
  r.take(new RegExp(`(\\d+)%概率令对方(?:单体)?(${ST})或(${ST})`), (m) => {
    e.statuses.push({ name: statusOf(m[2]), chance: num(m[1]) / 2 }, { name: statusOf(m[3]), chance: num(m[1]) / 2 });
  });
  r.take(/附加一定概率的(中毒)、(冰冻)或者(烧伤)/, (m) => {
    for (const s of [m[1], m[2], m[3]]) e.statuses.push({ name: statusOf(s), chance: 10 });
  });
  r.take(new RegExp(`(?:(\\d+)%(?:的)?(?:概率)?|一定概率|必定|命中则)?(?:令|使|让)?(?:对方)?(?:单体|全体|全场)?(?:处于|进入|陷入)?(${ST})(?:状态)?(?:对方)?(?:单体)?(?:(\\d+)~(\\d+)回合|(\\d+)回合)?`), (m) => {
    // Not "若对方处于睡眠状态" (a condition), nor "免疫烧伤" or "清除…状态".
    const before = r.d.slice(Math.max(0, m.index! - 3), m.index!);
    if (/若|处|被|疫|除|化|于$/.test(before) && !m[1]) return false;
    const name = statusOf(m[2]);
    const turns: [number, number] | undefined = m[3] ? [num(m[3]), num(m[4])] : m[5] ? [num(m[5]), num(m[5])] : undefined;
    const chance = m[1] ? num(m[1]) : /一定概率/.test(m[0]) ? 30 : 100;
    e.statuses.push({ name, chance, ...(turns ? { turns } : {}) });
  });
  r.take(/(?:30%概率)?令对方停止行动(\d+)(?:~(\d+))?回合/, (m) => void e.statuses.push({ name: "害怕", chance: /30%/.test(m[0]) ? 30 : 100, turns: [num(m[1]), num(m[2] || m[1])] }));
  r.take(/(\d+)%概率令对方停止行动1回合/, (m) => void e.statuses.push({ name: "害怕", chance: num(m[1]) }));
  r.take(/能令对方惊醒/, () => undefined);
  r.take(/一定概率麻痹对方单体，自己剩余体力值越少概率越高/, () => void e.statuses.push({ name: "麻痹", chance: 30 }));
  r.take(/自己体力值越低，睡眠成功率越高/, () => void e.statuses.push({ name: "睡眠", chance: 60 }));

  // ---- stages
  r.take(/(?:(\d+)%概率)?(?:清除|消除|清空)对方(?:单体|全体)?(?:所有能力的|提升的|增益)?(防御和特防|攻击和特攻|防御|特防|攻击)?(?:提升)?(?:的)?(?:属性能力|能力|属性)?(?:等级|能力效果)(?:效果)?/, (m) => {
    const stats = m[2] ? statsOf(m[2]) : undefined;
    e.clearFoeUps = { chance: pct(m[1]), stats };
  });
  r.take(/(?:(\d+)%概率)?(?:恢复|回复|清除)(?:自己|我方全体)被削弱的(?:属性)?(?:能力)?等级/, (m) => void (e.restoreOwn = { chance: pct(m[1]) }));
  r.take(/将对方属性等级重置为0/, () => void (e.resetFoe = true));
  r.take(/将自己的能力等级重置为0/, () => void (e.resetSelf = true));
  r.take(/交换(?:双方|敌我双方)的?(?:属性)?能力(?:的)?等级/, () => void (e.swapStages = true));
  r.take(/(?:(\d+)%概率)?复制对方(?:提升的)?(?:能力等级|属性)(?:给自己)?/, (m) => void (e.copyFoeUps = { chance: pct(m[1]) }));
  r.take(/将自己被削弱的(?:属性)?能力等级转移给对方/, () => void (e.passDowns = true));
  r.take(/将对方(攻击和命中)的等级各1级转化给自己/, (m) => void (e.stealStages = { stats: statsOf(m[1]), delta: 1 }));
  r.take(/令对方单体(防御|特防)值减半/, (m) => void e.stages.push({ self: false, stats: statsOf(m[1]), delta: -2, chance: 100 }));
  r.take(/随机提升自己任意(\d+)种属性能力等级(\d+)级/, (m) => void e.stages.push({ self: true, stats: ALL_STATS, delta: num(m[2]), chance: 100, pick: [num(m[1]), num(m[1])] }));
  r.take(/随机提升自己(特攻和速度)各(\d+)~(\d+)级/, (m) => void e.stages.push({ self: true, stats: statsOf(m[1]), delta: num(m[2]), deltaMax: num(m[3]), chance: 100 }));
  r.take(/(?:(\d+)%概率)?削弱对方(?:单体)?(?:攻击、特攻、防御和特防中的)?任意(\d+)(?:~(\d+))?种属性(\d+)级/, (m) => void e.stages.push({ self: false, stats: m[0].includes("攻击、特攻") ? ["atk", "satk", "def", "sdef"] : ALL_STATS, delta: -num(m[4]), chance: pct(m[1]), pick: [num(m[2]), num(m[3] || m[2])] }));
  r.take(/(\d+)%概率提升自己速度等级(\d+)~(\d+)级/, (m) => void e.stages.push({ self: true, stats: ["spd"], delta: num(m[2]), deltaMax: num(m[3]), chance: num(m[1]) }));
  r.take(/(?:削弱|降低)双方的(防御|特防)等级(\d+)级/, (m) => {
    e.stages.push({ self: false, stats: statsOf(m[1]), delta: -num(m[2]), chance: 100 });
    e.stages.push({ self: true, stats: statsOf(m[1]), delta: -num(m[2]), chance: 100 });
  });
  r.take(/(?:削弱|降低)全场(?:亚比)?(命中)等级(\d+)级/, (m) => {
    e.stages.push({ self: false, stats: statsOf(m[1]), delta: -num(m[2]), chance: 100 });
    e.stages.push({ self: true, stats: statsOf(m[1]), delta: -num(m[2]), chance: 100 });
  });
  {
    let lastSelf: boolean | undefined;
    let lastUp: boolean | undefined;
    let lastChance: number | undefined;
    const stageRe = new RegExp(
      `(?:(\\d+)%概率|(\\d+)\\/(\\d+)概率|(一定概率))?(?:令)?(提升|削弱|降低|提高|增加|削减)?(自己|自身|对方单体|对方全体|对方|其|我方全体|全场)?的?(${STAT_LIST})(?:的)?(?:等级)?(?:各)?(下降|提升|上升|削弱)?(\\d+)(?:~(\\d+))?级`,
    );
    r.take(stageRe, (m) => {
      const [, p1, p2, p3, some, verb, who, list, after, n, nMax] = m;
      if (!verb && !after && lastUp === undefined) return false;
      const up = verb ? verb !== "削弱" && verb !== "降低" && verb !== "削减" : after ? after !== "下降" && after !== "削弱" : lastUp!;
      const self = who ? who === "自己" || who === "自身" || who === "我方全体" : (lastSelf ?? up);
      const chance = p1 ? num(p1) : p2 ? (num(p2) * 100) / num(p3) : some ? 30 : (lastChance ?? 100);
      e.stages.push({ self, stats: statsOf(list), delta: (up ? 1 : -1) * num(n), chance, ...(nMax ? { deltaMax: num(nMax) } : {}) });
      lastSelf = self;
      lastUp = up;
      if (p1 || p2 || some) lastChance = chance;
    });
  }
  // 将其增加到自身 (归心): what the foe lost, the user gains.
  r.take(/将其增加到自身/, () => {
    const down = e.stages.find((s) => !s.self && s.delta < 0);
    if (down) e.stages.push({ self: true, stats: down.stats, delta: -down.delta, chance: down.chance });
  });

  e.status = e.statuses.find((s) => !s.self && !s.cond);
  return { fx: e, unread: r.unread() };
}

/** Read a skill's effects from its description ("30％概率令对方单体麻痹", "提升自己攻击和速度的等级各1级"…). */
export function parseEffects(desc: string): SkillEffects {
  return readSkill(desc).fx;
}
