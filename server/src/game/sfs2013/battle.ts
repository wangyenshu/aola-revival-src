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
import type { World, XtContext } from "./server.ts";

// ---------------------------------------------------------------- skill effects

export type StatKey = "atk" | "def" | "satk" | "sdef" | "spd" | "acc" | "eva" | "crit";
export const STATUSES = ["麻痹", "害怕", "冰冻", "睡眠", "烧伤", "中毒", "混乱", "束缚"] as const;
export type StatusName = (typeof STATUSES)[number];

const STAT_WORDS: Record<string, StatKey[]> = {
  攻击: ["atk"],
  防御: ["def"],
  特攻: ["satk"],
  特防: ["sdef"],
  速度: ["spd"],
  命中: ["acc"],
  闪避: ["eva"],
  暴击: ["crit"],
  全属性: ["atk", "def", "satk", "sdef", "spd"],
};
const STAT_LABEL: Record<StatKey, string> = { atk: "攻击", def: "防御", satk: "特攻", sdef: "特防", spd: "速度", acc: "命中", eva: "闪避", crit: "暴击" };

export interface StageChange {
  self: boolean;
  stats: StatKey[];
  delta: number;
  chance: number;
}

export interface SkillEffects {
  status?: { name: StatusName; chance: number };
  stages: StageChange[];
  drain?: number;
  recoil?: number;
  heal?: number;
  hits?: [number, number];
  sure?: boolean;
  highCrit?: boolean;
  first?: boolean;
  recharge?: boolean;
  fixed?: number;
  ohko?: number;
  selfConfuse?: boolean;
  boost?: { chance: number; mult: number };
}

const STAT_RE = "(?:攻击|防御|特攻|特防|速度|命中|闪避|暴击|全属性)";
const pct = (s: string | undefined) => (s ? Math.min(100, Number(s)) : 100);

/** Read a skill's effects from its description ("30％概率令对方单体麻痹", "提升自己攻击和速度的等级各1级"…). */
export function parseEffects(desc: string): SkillEffects {
  const e: SkillEffects = { stages: [] };
  const d = desc.replace(/％/g, "%").replace(/～/g, "~");
  let m: RegExpMatchArray | null;
  if ((m = d.match(/(?:(\d+)%概率)?(?:命中则)?令对方(?:单体|全体)?(麻痹|害怕|冰冻|睡眠|烧伤|中毒|混乱|束缚)/))) {
    e.status = { name: m[2] as StatusName, chance: pct(m[1]) };
  } else if ((m = d.match(/(\d+)%概率令对方(麻痹|害怕|冰冻|睡眠|烧伤|中毒|混乱|束缚)/))) {
    e.status = { name: m[2] as StatusName, chance: pct(m[1]) };
  }
  // Stage changes, clause by clause; a clause without a target takes the previous one's.
  let lastSelf: boolean | undefined;
  let lastUp: boolean | undefined;
  for (const clause of d.split(/[，,；;。]/)) {
    const re = new RegExp(
      `(?:(\\d+)%概率)?(提升|削弱|降低)?(自己|对方单体|对方全体|对方|全场|我方全体)?的?(${STAT_RE}(?:(?:和|、)${STAT_RE})*)(?:的)?(?:等级)?(?:各)?(下降|提升)?(\\d+)级`,
    );
    const s = clause.match(re);
    if (!s || (!s[2] && !s[5] && lastUp === undefined)) continue;
    const up = s[2] ? s[2] === "提升" : s[5] ? s[5] === "提升" : lastUp!;
    const who = s[3];
    const self = who ? who === "自己" || who === "我方全体" : (lastSelf ?? up);
    const stats = s[4].split(/和|、/).flatMap((w) => STAT_WORDS[w] ?? []);
    e.stages.push({ self, stats, delta: (up ? 1 : -1) * Number(s[6]), chance: pct(s[1]) });
    lastSelf = self;
    lastUp = up;
  }
  if ((m = d.match(/(?:令)?(对方单体|对方)(速度|攻击|防御|特攻|特防|命中)等级下降(\d+)级/)) && !e.stages.length) {
    e.stages.push({ self: false, stats: STAT_WORDS[m[2]], delta: -Number(m[3]), chance: 100 });
  }
  if ((m = d.match(/将伤害值的(一半|(\d+)%)(?:转化来|用来)回复/))) e.drain = m[1] === "一半" ? 0.5 : Number(m[2]) / 100;
  if ((m = d.match(/自己承受伤害值的(\d+)\/(\d+)/))) e.recoil = Number(m[1]) / Number(m[2]);
  if (!/每回合/.test(d)) {
    if (/回复自己一半的体力/.test(d)) e.heal = 0.5;
    else if ((m = d.match(/回复自己最大体力值的(\d+)\/(\d+)/))) e.heal = Number(m[1]) / Number(m[2]);
  }
  if ((m = d.match(/攻击对方(?:单体|全体)?(\d+)~(\d+)次/) ?? d.match(/爆发(\d+)~(\d+)次/))) e.hits = [Number(m[1]), Number(m[2])];
  else if ((m = d.match(/\d+回合内攻击对方(?:单体)?(\d+)次/))) e.hits = [Number(m[1]), Number(m[1])];
  if (/必定命中/.test(d)) e.sure = true;
  if (/容易暴击/.test(d)) e.highCrit = true;
  if (/^先发|；先发|先发；/.test(d)) e.first = true;
  if (/下回合自己停止行动|次回合自己无法行动/.test(d)) e.recharge = true;
  if ((m = d.match(/附加(\d+)点伤害/))) e.fixed = Number(m[1]);
  if ((m = d.match(/(\d+)%概率秒杀/))) e.ohko = Number(m[1]);
  if (/命中后自己混乱/.test(d)) e.selfConfuse = true;
  if ((m = d.match(/(\d+)%概率发动(\d+(?:\.\d+)?)倍/))) e.boost = { chance: Number(m[1]), mult: Number(m[2]) };
  return e;
}

// ---------------------------------------------------------------- fighters

type Stages = Record<StatKey, number>;
const noStages = (): Stages => ({ atk: 0, def: 0, satk: 0, sdef: 0, spd: 0, acc: 0, eva: 0, crit: 0 });

export interface Fighter {
  slot: 0 | 1;
  pet: PetRecord;
  owner: number;
  stats: number[];
  types: [number, number];
  stages: Stages;
  status?: StatusName;
  sleep: number;
  confuse: number;
  bind: number;
  flinch: boolean;
  recharge: boolean;
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
}

export type Msg = [cmd: string, body: Record<string, unknown>];

export interface Rng {
  (): number;
}

function fighter(slot: 0 | 1, pet: PetRecord, owner: number, t: PetTables): Fighter {
  const sp = speciesOf(t, pet.race);
  return {
    slot,
    pet,
    owner,
    stats: statsOf(pet, t),
    types: sp ? sp.t : [0, 0],
    stages: noStages(),
    sleep: 0,
    confuse: 0,
    bind: 0,
    flinch: false,
    recharge: false,
  };
}

const stageMult = (s: number) => (s >= 0 ? (2 + s) / 2 : 2 / (2 - s));
const accMult = (s: number) => (s >= 0 ? (3 + s) / 3 : 3 / (3 - s));
const clampStage = (s: number) => Math.max(-6, Math.min(6, s));

function stat(f: Fighter, k: "atk" | "def" | "satk" | "sdef" | "spd"): number {
  const i = { atk: 1, def: 2, satk: 3, sdef: 4, spd: 5 }[k];
  let v = f.stats[i] * stageMult(f.stages[k]);
  if (k === "spd" && f.status === "麻痹") v /= 2;
  return Math.max(1, v);
}

function petName(t: PetTables, f: Fighter): string {
  return f.pet.nick || nameOf(t, f.pet.race);
}

/** A status skill that only changes its user (heals, raises its own stages): its effect plays on the user. */
function selfOnly(sk: PmSkill): boolean {
  if (sk.k !== 2) return false;
  const fx = parseEffects(sk.d);
  return !fx.status && fx.stages.every((s) => s.self);
}

/** 挣扎: what a 亚比 with no PP left does. */
const STRUGGLE: PmSkill = { n: "挣扎", p: 100, acc: 100, pp: 1, pri: 0, t: -1, k: 0, d: "自己承受伤害值的1/4" };

// ---------------------------------------------------------------- the engine

export class BattleEngine {
  readonly t: PetTables;
  readonly rng: Rng;

  constructor(t: PetTables, rng: Rng = Math.random) {
    this.t = t;
    this.rng = rng;
  }

  private chance(p: number): boolean {
    return p >= 100 || this.rng() * 100 < p;
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

  /** One 亚比 uses a skill on the other; returns the 2411 report. */
  act(b: Battle, att: Fighter, def: Fighter, skillId: number): Msg {
    const t = this.t;
    const lines: string[] = [];
    const name = petName(t, att);
    const report = (srt: number, extra: Record<string, unknown> = {}): Msg => [
      "2411",
      { reqSId: att.slot, tarSId: def.slot, id: skillId, name: this.skill(skillId).n, k: this.skill(skillId).k, t: this.skill(skillId).t, self: selfOnly(this.skill(skillId)), srt, cri: false, hits: 0, hpInc: 0, selfHpInc: 0, eff: 1, ...extra, desc: lines.join("\n"), pmmList: this.views(b) },
    ];

    // Could it act at all?
    if (att.recharge) {
      att.recharge = false;
      lines.push(`${name}需要休息，无法行动！`);
      return report(3);
    }
    if (att.flinch) {
      att.flinch = false;
      lines.push(`${name}害怕得不敢行动！`);
      return report(3);
    }
    if (att.status === "睡眠") {
      if (--att.sleep > 0) {
        lines.push(`${name}正在睡觉……`);
        return report(3);
      }
      att.status = undefined;
      lines.push(`${name}醒过来了！`);
    } else if (att.status === "冰冻") {
      if (!this.chance(20)) {
        lines.push(`${name}被冻住了，无法行动！`);
        return report(3);
      }
      att.status = undefined;
      lines.push(`${name}解冻了！`);
    } else if (att.status === "麻痹" && this.chance(25)) {
      lines.push(`${name}麻痹了，无法行动！`);
      return report(3);
    }
    if (att.confuse > 0) {
      att.confuse--;
      if (att.confuse === 0) lines.push(`${name}不再混乱了！`);
      else if (this.chance(33)) {
        const dmg = Math.max(1, Math.floor((Math.floor((2 * att.pet.level) / 5 + 2) * 40 * stat(att, "atk")) / stat(att, "def") / 50 + 2));
        att.pet.hp = Math.max(0, att.pet.hp - dmg);
        lines.push(`${name}在混乱中攻击了自己！`);
        if (att.pet.hp <= 0) lines.push(`${name}倒下了！`);
        return report(3, { selfHpInc: -dmg });
      }
    }

    const sk = this.skill(skillId);
    const known = att.pet.skills.find((s) => s.id === skillId);
    if (known) known.pp = Math.max(0, known.pp - 1);
    const fx = parseEffects(sk.d);
    lines.push(`${name}使用了${sk.n}！`);

    const targetsFoe = sk.k !== 2 || !!fx.status || fx.stages.some((s) => !s.self);
    if (targetsFoe && !fx.sure && sk.acc < 101) {
      const hit = (sk.acc / 100) * accMult(att.stages.acc - def.stages.eva);
      if (this.rng() >= hit) {
        lines.push("没有命中！");
        return report(2);
      }
    }

    let dmg = 0;
    let cri = false;
    let mult = 1;
    let hits = 0;
    let selfHp = 0;
    if (sk.k !== 2) {
      mult = sk.t < 0 ? 1 : typeMultiplier(t.pm, sk.t, def.types);
      if (mult === 0) {
        lines.push("好像没有效果……");
        return report(1, { eff: 0 });
      }
      const n = fx.hits ? this.int(fx.hits[0], fx.hits[1]) : 1;
      for (let i = 0; i < n && def.pet.hp - dmg > 0; i++) {
        const r = this.damage(att, def, sk, fx, mult);
        dmg += r.dmg;
        cri ||= r.cri;
        hits++;
      }
      if (fx.ohko && this.chance(fx.ohko)) {
        dmg = def.pet.hp;
        lines.push("一击必杀！");
      }
      dmg = Math.min(dmg, def.pet.hp);
      def.pet.hp -= dmg;
      if (hits > 1) lines.push(`连续攻击了${hits}次！`);
      if (cri) lines.push("暴击！");
      if (mult > 1) lines.push("效果拔群！");
      else if (mult < 1) lines.push("效果不理想……");
      if (fx.drain && dmg > 0) {
        const heal = Math.min(att.stats[0] - att.pet.hp, Math.max(1, Math.floor(dmg * fx.drain)));
        att.pet.hp += heal;
        selfHp += heal;
        if (heal > 0) lines.push(`${name}回复了体力！`);
      }
      if ((fx.recoil || sk === STRUGGLE) && dmg > 0) {
        const r = Math.min(att.pet.hp, Math.max(1, Math.floor(dmg * (fx.recoil ?? 0.25))));
        att.pet.hp -= r;
        selfHp -= r;
        lines.push(`${name}受到了反作用伤害！`);
      }
      if (fx.recharge) att.recharge = true;
      if (fx.selfConfuse && att.confuse === 0) {
        att.confuse = this.int(2, 4);
        lines.push(`${name}混乱了！`);
      }
    } else if (fx.heal) {
      const heal = Math.min(att.stats[0] - att.pet.hp, Math.floor(att.stats[0] * fx.heal));
      att.pet.hp += heal;
      selfHp += heal;
      lines.push(heal > 0 ? `${name}回复了体力！` : "体力已经是满的了。");
    }

    // Statuses and stage changes (secondary for damaging skills).
    let landed = sk.k !== 2;
    if (fx.status && def.pet.hp > 0) {
      const ok = this.chance(fx.status.chance) && this.applyStatus(def, fx.status.name, lines);
      landed ||= ok;
      if (!ok && sk.k === 2) lines.push("好像没有效果……");
    }
    for (const ch of fx.stages) {
      const f = ch.self ? att : def;
      if (f.pet.hp <= 0 || !this.chance(ch.chance)) continue;
      for (const k of ch.stats) f.stages[k] = clampStage(f.stages[k] + ch.delta);
      const label = ch.stats.length >= 5 ? "全属性" : ch.stats.map((k) => STAT_LABEL[k]).join("和");
      lines.push(`${petName(t, f)}的${label}${ch.delta > 0 ? "提升" : "下降"}了！`);
      landed = true;
    }
    if (def.pet.hp <= 0) lines.push(`${petName(t, def)}倒下了！`);
    if (att.pet.hp <= 0) lines.push(`${name}倒下了！`);
    return report(landed || sk.k !== 2 || fx.heal ? 0 : 1, { cri, hits, hpInc: -dmg, selfHpInc: selfHp, eff: mult });
  }

  private damage(att: Fighter, def: Fighter, sk: PmSkill, fx: SkillEffects, mult: number): { dmg: number; cri: boolean } {
    // The client shows doubled powers (单倍威力 / 双倍威力 columns); the classic formula takes the single one.
    const power = sk.p > 1 ? sk.p / 2 : 30;
    const special = sk.k === 1;
    const a = stat(att, special ? "satk" : "atk");
    const d = stat(def, special ? "sdef" : "def");
    const base = Math.floor(Math.floor((Math.floor((2 * att.pet.level) / 5 + 2) * power * a) / d) / 50) + 2;
    const critStage = Math.min(4, Math.max(0, att.stages.crit + (fx.highCrit ? 1 : 0)));
    const cri = this.rng() < [1 / 16, 1 / 8, 1 / 4, 1 / 3, 1 / 2][critStage];
    const stab = sk.t >= 0 && (att.types[0] === sk.t || att.types[1] === sk.t) ? 1.5 : 1;
    const burn = att.status === "烧伤" && !special ? 0.5 : 1;
    const boost = fx.boost && this.chance(fx.boost.chance) ? fx.boost.mult : 1;
    const rand = 0.85 + this.rng() * 0.15;
    const dmg = Math.max(1, Math.floor(base * stab * mult * (cri ? 1.5 : 1) * burn * boost * rand)) + (fx.fixed ?? 0);
    return { dmg, cri };
  }

  /** Fire 亚比 do not burn, ice ones do not freeze, poison ones are not poisoned (属性 9, 14, 3). */
  private applyStatus(f: Fighter, s: StatusName, lines: string[]): boolean {
    const name = petName(this.t, f);
    if (s === "害怕") {
      f.flinch = true;
      return true;
    }
    if (s === "混乱") {
      if (f.confuse > 0) return false;
      f.confuse = this.int(2, 4);
      lines.push(`${name}混乱了！`);
      return true;
    }
    if (s === "束缚") {
      if (f.bind > 0) return false;
      f.bind = this.int(4, 5);
      lines.push(`${name}被束缚住了！`);
      return true;
    }
    if (f.status) return false;
    const immune = { 烧伤: 9, 冰冻: 14, 中毒: 3 } as Record<string, number>;
    if (immune[s] !== undefined && f.types.includes(immune[s])) return false;
    f.status = s;
    if (s === "睡眠") f.sleep = this.int(2, 4);
    lines.push(`${name}${{ 麻痹: "麻痹了！", 冰冻: "被冻住了！", 睡眠: "睡着了！", 烧伤: "被烧伤了！", 中毒: "中毒了！" }[s]}`);
    return true;
  }

  /** Burns, poison and binding at the end of a turn: 2421 reports. */
  endOfTurn(b: Battle): Msg[] {
    const out: Msg[] = [];
    for (const f of [b.mine, b.wild]) {
      if (f.pet.hp <= 0) continue;
      f.flinch = false;
      let lost = 0;
      const lines: string[] = [];
      const name = petName(this.t, f);
      if (f.status === "烧伤" || f.status === "中毒") {
        lost += Math.max(1, Math.floor(f.stats[0] / 8));
        lines.push(`${name}受到了${f.status === "烧伤" ? "烧伤" : "毒"}的伤害！`);
      }
      if (f.bind > 0) {
        f.bind--;
        lost += Math.max(1, Math.floor(f.stats[0] / 16));
        lines.push(f.bind > 0 ? `${name}受到了束缚的伤害！` : `${name}挣脱了束缚！`);
      }
      if (!lines.length) continue;
      lost = Math.min(lost, f.pet.hp);
      f.pet.hp -= lost;
      if (f.pet.hp <= 0) lines.push(`${name}倒下了！`);
      out.push(["2421", { slotId: f.slot, hpInc: -lost, desc: lines.join("\n"), pmmList: this.views(b) }]);
    }
    return out;
  }

  /** Who goes first: priority (先发), then speed. */
  firstMover(b: Battle, mySkill: number, wildSkill: number): Fighter {
    const pri = (id: number) => this.skill(id).pri + (parseEffects(this.skill(id).d).first ? 1 : 0);
    const pm = pri(mySkill), pw = pri(wildSkill);
    if (pm !== pw) return pm > pw ? b.mine : b.wild;
    const sm = stat(b.mine, "spd"), sw = stat(b.wild, "spd");
    if (sm !== sw) return sm > sw ? b.mine : b.wild;
    return this.rng() < 0.5 ? b.mine : b.wild;
  }

  /** A whole turn in which the player uses a skill. */
  skillTurn(b: Battle, mySkill: number): Msg[] {
    const wildSkill = this.wildChoice(b);
    const first = this.firstMover(b, mySkill, wildSkill);
    const second = first === b.mine ? b.wild : b.mine;
    const out: Msg[] = [this.act(b, first, second, first === b.mine ? mySkill : wildSkill)];
    if (first.pet.hp > 0 && second.pet.hp > 0) out.push(this.act(b, second, first, second === b.mine ? mySkill : wildSkill));
    return out;
  }

  /** The wild 亚比 alone acts (after an item, a failed catch or a switch). */
  wildTurn(b: Battle): Msg[] {
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
    const st = [f.status, f.confuse > 0 ? "混乱" : "", f.bind > 0 ? "束缚" : ""].filter(Boolean).join(",");
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
        pmList: list.map((p) => briefOf(p, own, this.t, p === f.pet ? { st } : undefined)),
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
export function award(t: PetTables, pet: PetRecord, wildRace: number, wildLevel: number): WinResult {
  const wsp = speciesOf(t, wildRace);
  const gained = expYield(wsp, wildLevel);
  if (wsp) {
    pet.ev ??= [0, 0, 0, 0, 0, 0];
    const total = pet.ev.reduce((a, b) => a + b, 0);
    let room = Math.max(0, 510 - total);
    wsp.ev.forEach((y, i) => {
      const add = Math.min(y, room, 255 - pet.ev![i]);
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
    const next = sp ? evolutionAt(sp, pet.race, pet.level) : 0;
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
export const POTIONS: Record<number, number> = { 30: 40, 60: 100, 61: 200 };
export const PP_BEANS: Record<number, number> = { 31: 5, 103: 10, 104: 20 };
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
  // 烈焰鸟 (feier4), 神武月 and 战无炎 (choicetemple); their levels are RECONSTRUCTED.
  ["11320,11322", "100,100"], ["30278", "80"], ["10105,20105", "80,100"], ["10111", "90"],
];

/** A 守护者 form's level (its race at that index), else 20 + 5 per index as before. */
export function guardianLevel(race: number, index: number): number {
  for (const [races, levels] of GUARDIANS) {
    const rs = races.split(/[#,]/).map(Number);
    const ls = levels.split(/[#,]/).map(Number);
    if (rs[index] === race) return ls[index] ?? ls[0];
  }
  return Math.min(100, 20 + 5 * index);
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
const NPC_TEAM_BASE: Record<number, number> = { 13: 61, 35: 10, 145: 43, 14: 1, 3: 34, 26: 70, 142: 19, 32: 10, 31: 1, 172: 99, 312: 70 };

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
  let nextBattle = 1;
  const send = (ctx: XtContext, msgs: Msg[]) => {
    for (const [cmd, body] of msgs) ctx.reply(body, cmd);
  };

  // Wild 亚比 of the room.
  world.xt("PetExtension.54_7", async (ctx) => {
    const room = ctx.player.room?.name ?? "";
    ctx.reply({ pms: (await deps.wild())[room] ?? [] });
  });

  const begin = async (ctx: XtContext, race: number, level: number, catchable: boolean, onWin?: Battle["onWin"], asked?: number, onLose?: Battle["onLose"]) => {
    const o = await deps.load(ctx);
    const t = await deps.tables();
    for (const p of o.pets ?? []) normalisePet(p, t);
    const old = battles.get(o.id);
    if (old && !old.over) return ctx.reply({ msg: "你不能够在离开一个战场之前，加入另外一个战场！" }, "2303");
    const active = (o.pets ?? []).find((p) => p.hp > 0);
    if (!active) return ctx.reply({ msg: WEAK }, "2303");
    if (!speciesOf(t, race)) return ctx.reply({ msg: "这只亚比还不能对战哦！" }, "2303");
    const lesson = tutorial(o, race);
    const wildPet = makePet(t, race, lesson ? Math.min(level, 2) : level, deps.today());
    if (lesson) {
      // The newbie fight (task step 138) is a lesson, not a trial: the
      // 达斯特's 达达 is at most Lv2 and only attacks. RECONSTRUCTED; the
      // 2013 rule is lost.
      const hits = wildPet.skills.filter((s) => (t.pm.skills[String(s.id)]?.k ?? 0) !== 2);
      if (hits.length) wildPet.skills = hits;
    }
    const engine = new BattleEngine(t, deps.rng);
    const canCatch = catchable && Number.isFinite(Number(speciesOf(t, race)!.c[0]));
    const b = engine.start(nextBattle++, ctx.player.room?.name ?? "", o, active, wildPet, canCatch);
    b.onWin = onWin;
    b.onLose = onLose;
    b.asked = asked;
    battles.set(o.id, b);
    engine.bag = o.pets;
    engine.ownerRef = o;
    send(ctx, [
      // chp (not in the 2013 reply): the HP fraction from which balls work, for the 捕捉难度 hint.
      ["2303", { esc: true, sw: true, ch: canCatch, cd: catchStars(speciesOf(t, race)!.c[0]), chp: catchHpLimit(t, race), pmmList: engine.views(b) }],
      // boss: the opponent's id as the fight was asked for (variant * 10000 + species for the
      // bosses), by which the battle screen finds the boss's films (bossfightmovie/boss<id>).
      ["2401", { id: b.id, type: 0, pt: 0, bs: "", srt: 0, scene: b.room, boss: asked ?? race }],
    ]);
  };

  // startPKWithRobot {raceId, level, sw, id}: a wild 亚比 of the room at one of its levels; tasks pass a level.
  // A story quest's 亚比 (IPetFight.fightWithTaskPet) is numbered variant * 10000 + species
  // (10322: 达达; 10869, 20869, 30869: three fights with the 通灵巫师). The 2013 server's task
  // 亚比 are lost: RECONSTRUCTED as the species at the level of the player's strongest 亚比 (at
  // least 5), two levels more for each further variant, not to be caught. A win counts for the
  // steps that ask for it (TaskDefine type 101, tasks.ts stepsByPetWin).
  world.xt("PetExtension.54_2", async (ctx) => {
    const asked = Number(ctx.params.level);
    const id = Number(ctx.params.raceId);
    const onWin: Battle["onWin"] = (o) =>
      stepsByPetWin(o as TaskOwner, id, deps.now?.() ?? Date.now()).changes.map((c): Msg => ["10-1", { t: c.t, ty: c.ty }]);
    if (id >= 10000) {
      const o = await deps.load(ctx);
      const top = Math.max(5, ...(o.pets ?? []).map((p) => p.level));
      const level = asked > 0 ? asked : top + 2 * (Math.floor(id / 10000) - 1);
      return begin(ctx, id % 10000, Math.max(1, Math.min(100, level)), false, onWin, id);
    }
    const entry = ((await deps.wild())[ctx.player.room?.name ?? ""] ?? []).find((w) => w.raceId === id);
    const rng = deps.rng ?? Math.random;
    const level = entry ? entry.min + Math.floor(rng() * (entry.max - entry.min + 1)) : asked > 0 ? asked : 5;
    await begin(ctx, id, Math.max(1, Math.min(100, level)), true, onWin);
  });

  // NPC challenge (the era npcchallenge/npcchallengeservice, PetFightTypes.FIGHT_IN_NPCCHALLENGE 14):
  //   54_22 {type: 14, npc, lv, npcId, name} -> 54_22 {res, canGet, canGet1}, then the fight as above.
  // res false when a harder mode is asked before the easier ones are won (the client then shows
  // npcChallenge_fail_<lv>); canGet: a win today brings one 欢乐弹珠 (item 343, "今天我身上的弹弹珠
  // 已经发完啦" once given). The 2013 server and the NPCs' teams are lost: each NPC fights with one
  // 亚比 of an evolution line, the next stage for each harder mode, at NPC_LEVELS (RECONSTRUCTED).
  world.xt("PetExtension.54_22", async (ctx) => {
    if (Number(ctx.params.type) === FIGHT_IN_MEMBER_ARENA) {
      // 黑星堡垒 (viparena, PetFightTypes.FIGHT_IN_MEMBER_ARENA 12): {mi, rm}, a floor's boss
      // numbered 70000 + species (70536 震天石魔 in viparena2). Its level by the room's floor,
      // not to be caught (RECONSTRUCTED: the 2013 server's bosses are lost).
      const mi = Number(ctx.params.mi) | 0;
      const level = MEMBER_ARENA_LEVELS[String(ctx.params.rm ?? "")] ?? 60;
      return begin(ctx, mi % 10000, level, false, undefined, mi);
    }
    if (Number(ctx.params.type) !== FIGHT_IN_NPCCHALLENGE) return ctx.reply({ res: false });
    const npcId = Number(ctx.params.npcId) | 0;
    const lv = Math.max(1, Math.min(3, Number(ctx.params.lv) | 0));
    const o = (await deps.load(ctx)) as PetOwner & NpcChallengeRecord;
    const t = await deps.tables();
    const rec = (o.npcChallenge ??= { won: {}, gift: {} });
    if (lv > (rec.won[npcId] ?? 0) + 1) return ctx.reply({ res: false, canGet: false, canGet1: false });
    const day = deps.today();
    const canGet = rec.gift[npcId] !== day;
    let race = NPC_TEAM_BASE[npcId] ?? NPC_TEAM_BASE[13];
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
      items["343"] = (items["343"] ?? 0) + 1;
      return [["onAmountUpdated", { amount: "2_343_0_1" }]];
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
    rec.en = Array.from({ length: n }, () => String(pool[Math.floor(rng() * pool.length)]));
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
      if (rec.alive.some(Boolean)) return ctx.reply({ result: 0 }, `56_3${sfx}`);
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
        r.alive[i] = false;
        const coins = 10 + 2 * f;
        (owner as { score?: number }).score = ((owner as { score?: number }).score ?? 0) + coins;
        return [
          [`56_7${sfx}`, { bonus: [{ id: -1, type: 100, num: coins }] }],
          ["onScoreUpdated", { score: (owner as { score?: number }).score }],
        ];
      }, undefined, () => [[`56_10${sfx}`, {}]]);
    });
    world.xt(`${ext}.56_10${sfx}`, async (ctx) => ctx.reply({}, `56_10${sfx}`));
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

  // fightWithBoss {raceId, index}: a 守护者 (dailyactivity/dailyactivityservice, rebuilt): one of the
  // forms of BossTimeHelper.bossTimeConfig, numbered variant * 10000 + species, at its level there;
  // no catching. The asked id comes back with the end of the fight, which the client checks.
  // A win brings the 守护者's 亚比蛋 (PetEggData: the egg of its line's first form, 88 沙麒麟亚比蛋
  // for 沙麒麟 90), into the eggs (type 5) the 家园's 亚比孵化器 hatches.
  world.xt("PetExtension.54_16", async (ctx) => {
    // A pair asked for at once ("11320#11322", fightWithTeamBoss) fights its first here.
    const asked = Number(String(ctx.params.raceId ?? "0").split("#")[0]) | 0;
    const index = Math.max(0, Number(ctx.params.index) | 0);
    const t = await deps.tables();
    // The species of a boss form: variant * 10000 + species, or for 终极麦斗王's 14523 / 11514 / 11516
    // (PetAssetsMap) variant * 1000 + species.
    const species = speciesOf(t, asked % 10000) ? asked % 10000 : speciesOf(t, asked % 1000) ? asked % 1000 : asked % 10000;
    const egg = eggOfLine(t, species);
    const onWin: Battle["onWin"] = egg
      ? (o) => {
          const eggs = (((o as { items?: Record<string, Record<string, number>> }).items ??= {})["5"] ??= {});
          eggs[String(egg)] = (eggs[String(egg)] ?? 0) + 1;
          return [["onAmountUpdated", { amount: `5_${egg}_0_1` }]];
        }
      : undefined;
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
    if (b.wild.pet.hp > 0 && b.mine.pet.hp > 0) out.push(...e.endOfTurn(b));
    if (b.wild.pet.hp <= 0) {
      b.over = true;
      const pet = b.mine.pet;
      const before = pet.race;
      const r = award(t, pet, b.wild.pet.race, b.wild.pet.level);
      out.push(...r.msgs);
      if (r.evolvedTo && o.followPet === pet.id) world.setUserVars(ctx.session, { p: followVar(pet) });
      if (b.onWin) out.push(...b.onWin(o));
      out.push(["2403", { isWin: true, raceId: b.asked ?? b.wild.pet.race, evolveFrom: r.evolvedTo ? before : 0, desc: `战斗胜利！${nameOf(t, before)}获得了经验。`, pmmList: e.views(b) }]);
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
      out.push(["2403", { isWin: false, raceId: b.asked ?? b.wild.pet.race, desc: "你的亚比都倒下了……快带它们去治疗吧！", pmmList: e.views(b) }]);
      battles.delete(o.id);
      return out;
    }
    b.turn++;
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

  // useItem {itemId, tarSId}: 体力糖 heal, 活力豆 give PP back; then the wild 亚比 acts.
  turn("1402", (ctx, b, e, o, t) => {
    const items = ((o as { items?: Record<string, Record<string, number>> }).items ??= {});
    const bag = (items["2"] ??= {});
    const id = Number(ctx.params.itemId);
    const pet = b.mine.pet;
    const name = pet.nick || nameOf(t, pet.race);
    if (b.mustSwitch || !(bag[id] > 0) || (!POTIONS[id] && !PP_BEANS[id])) {
      return { refused: [["2412", { reqSId: 0, itemId: id, res: -1, refused: true, desc: "这个道具现在不能使用。", pmmList: e.views(b) }]] };
    }
    bag[id]--;
    if (bag[id] <= 0) delete bag[id];
    ctx.reply({ amount: `2_${id}_0_-1` }, "onAmountUpdated");
    let hpInc = 0;
    let desc: string;
    if (POTIONS[id]) {
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
    b.mustSwitch = false;
    b.mine = fighter(0, next, o.id, t);
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
    ]);
    return "end";
  });

  // Leaving the room ends a battle left open (the client was closed mid-fight).
  world.xt(`${PM}.1307`, async (ctx) => {
    const o = await deps.load(ctx);
    battles.delete(o.id);
    ctx.reply({}, "2308");
  });
}
