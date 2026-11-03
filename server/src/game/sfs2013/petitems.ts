// 亚比道具: the items of the bag used on a 亚比 (the pet bag's 道具 page, rebuilt
// pet/petitem) or used up over the next battles (the 经验器, 学习器 and 寻宝雷达).
//
//   MaterialExtension.14_12 useItem {ii, pi, pa, num} (MaterialClient.cmdUsePetItem)
//     -> 14_12 {res, ii, pi, msg}   res 1 used (one less in the bag, onAmountUpdated
//        first), 0 not (msg says why); the client then asks viewAllPM again.
//
// The items are those of the 2013 ItemData of types 5 (PET, also of the battle) and
// 7 (ONLY_NOT_BATTLE). What each does is what its 2013 description says; the
// checks are those of the later pet/petitem (the only copy of the module left),
// for the items the 2013 game had; the 2013 server's own replies are lost and its
// words are RECONSTRUCTED.
//
// Boosts counted down by wins (Boosts) and a 强化药剂 waiting for the next battle
// (PetRecord.buff) are read by battle.ts.

import type { World, XtContext } from "./server.ts";
import { learntFor, nameOf, skillOf, speciesOf, statsOf, type PetOwner, type PetRecord, type PetTables } from "./pets.ts";
import { BUFF_ROUNDS, gainExp, type Msg } from "./battle.ts";
import { NATURE_NAMES } from "./pmdata.ts";

/** Wins left of the items that work over the next battles. */
export interface Boosts {
  /** 双倍经验器 (43, 120, 499). */
  exp2?: number;
  /** 三倍经验器 (378). */
  exp3?: number;
  /** 双倍学习器 (62). */
  ev2?: number;
  /** 寻宝雷达 (189, 663). */
  radar?: number;
  /** 自动战斗仪 (44): battles in which the 亚比 fights by itself. */
  auto?: number;
}

export interface PetItemOwner extends PetOwner {
  items?: Record<string, Record<string, number>>;
  boosts?: Boosts;
}

export interface PetItemDeps {
  load(ctx: XtContext): Promise<PetItemOwner>;
  save(o: PetItemOwner): Promise<void>;
  tables(): Promise<PetTables>;
  /** After a 亚比 changed race: the follow variable of the room. */
  changedRace?(ctx: XtContext, o: PetItemOwner, pet: PetRecord): void;
}

const STAT_NAMES = ["体力", "攻击", "防御", "特攻", "特防", "速度"];

/** 体力糖 and the like: HP back. */
export const HP_ITEMS: Record<number, number> = { 30: 40, 60: 100, 61: 200, 102: 300, 263: 400, 390: 200, 354: 200, 355: 200 };
/** 活力豆: uses (PP) back for every skill carried. */
export const PP_ITEMS: Record<number, number> = { 31: 5, 103: 10, 104: 20, 391: 20 };
/** 解除…药剂 and 净化药剂: of the battle only (no status outlasts it). */
const CURES = [94, 95, 96, 97, 98, 99, 100, 101];
/** 初始亚比经验糖: experience for the starters' lines (吉拉, 滴滴, 兔小子). */
const STARTER_EXP: Record<number, number> = { 233: 500, 234: 3000, 235: 7000, 236: 12000, 237: 17000, 238: 22000, 239: 27000, 240: 32000, 241: 37000 };
const STARTER_RACES = [1, 2, 3, 500, 4, 5, 6, 501, 7, 8, 9, 502];
/** 摇摇果实. */
const FRUIT_EXP: Record<number, number> = { 419: 1000, 664: 5000, 665: 400000 };
/** 学习力 fruits: +5 to one (index into hp, atk, def, satk, sdef, spd). */
const EV_FRUITS: Record<number, number> = { 524: 0, 525: 1, 526: 2, 527: 3, 528: 4, 529: 5 };
/** 遗忘喷雾: one 学习力 to 0; 523 超级遗忘喷雾 all of them. */
const FORGET: Record<number, number> = { 154: 1, 155: 2, 156: 3, 157: 4, 158: 5, 159: 0 };
/** 性格改造: a 性格 of these four (the item's description). 66 性格重塑卡: any. */
const NATURE_SETS: Record<number, string[]> = {
  414: ["孤僻", "勇敢", "固执", "调皮"],
  415: ["悠闲", "淘气", "大胆", "无虑"],
  416: ["保守", "马虎", "稳重", "冷静"],
  417: ["温顺", "沉着", "狂妄", "慎重"],
  418: ["胆小", "开朗", "天真", "急躁"],
};
/** 强化药剂: [stat, points] for the next battle (its first 20 rounds). */
export const BUFF_ITEMS: Record<number, [number, number]> = { 381: [3, 260], 382: [4, 260], 383: [1, 260], 384: [2, 260], 385: [5, 200] };
/** Items used on no 亚比: what they count and for how many wins. */
const BOOST_ITEMS: Record<number, [keyof Boosts, number]> = {
  43: ["exp2", 50], 120: ["exp2", 20], 499: ["exp2", 50], 378: ["exp3", 50],
  62: ["ev2", 30], 189: ["radar", 20], 663: ["radar", 20], 44: ["auto", 100],
};
/** 2013 PetStoneData: EvolutionStone(item, fromRace, toRace). */
const EVO_STONES: Record<number, [number, number]> = {
  614: [1292, 1295], 615: [1292, 1297], 616: [1292, 1299], 620: [1292, 1308], 621: [1292, 1306],
  645: [371, 372], 646: [371, 373], 647: [371, 374], 648: [371, 375],
};
/** 2013 PetStoneData: SkillStone(item, race, skill, levelLimit). */
const SKILL_STONES: Record<number, [number, number, number]> = {
  617: [1296, 10284, 40], 618: [1298, 11297, 40], 619: [1300, 13262, 40], 622: [1309, 17260, 40], 623: [1307, 19065, 40],
  631: [105, 16235, 60], 632: [111, 16234, 60], 642: [1381, 14317, 60],
  649: [372, 2226, 60], 650: [373, 6215, 60], 651: [374, 9223, 60], 652: [375, 3221, 60], 657: [592, 8257, 40],
};

/** Every item this file knows (the 道具 page shows the bag's items of types 5 and 7). */
export const PET_ITEM_IDS: number[] = [
  ...Object.keys(HP_ITEMS), ...Object.keys(PP_ITEMS), ...CURES, ...Object.keys(STARTER_EXP), ...Object.keys(FRUIT_EXP),
  ...Object.keys(EV_FRUITS), ...Object.keys(FORGET), 523, 63, 65, 66, 193, 220, ...Object.keys(NATURE_SETS),
  ...Object.keys(BUFF_ITEMS), ...Object.keys(BOOST_ITEMS), ...Object.keys(EVO_STONES), ...Object.keys(SKILL_STONES),
].map(Number);

/** The first race of a 亚比's line (its evolution chain), or its own. */
function firstForm(t: PetTables, race: number): number {
  const chain = (speciesOf(t, race)?.evo ?? "")
    .split("#")
    .map((s) => Number(s.split("-")[1]))
    .filter((r) => r > 0);
  return chain.length && chain.includes(race) ? chain[0] : race;
}

/** Whether a 亚比 of this race still evolves with levels. */
function evolvesFurther(t: PetTables, race: number): boolean {
  const steps = (speciesOf(t, race)?.evo ?? "").split("#").map((s) => s.split("-").map(Number));
  const i = steps.findIndex(([, r]) => r === race);
  return i >= 0 && i + 1 < steps.length && steps[i + 1][0] > 0;
}

type Outcome = { ok: true; msg: string; msgs?: Msg[]; raceChanged?: boolean } | { ok: false; msg: string };
const no = (msg: string): Outcome => ({ ok: false, msg });

/** What one item does to a 亚比 (pet undefined for the items used on none). */
export function applyPetItem(t: PetTables, o: PetItemOwner, ii: number, pet: PetRecord | undefined, rng: () => number = Math.random): Outcome {
  const boost = BOOST_ITEMS[ii];
  if (boost) {
    const [key, wins] = boost;
    const b = (o.boosts ??= {});
    b[key] = (b[key] ?? 0) + wins;
    const what = { exp2: "战斗经验翻倍", exp3: "战斗经验翻三倍", ev2: "学习力提升加倍", radar: "战斗胜利后可以得到晶币", auto: "亚比会自己战斗" }[key];
    return { ok: true, msg: `接下来的${b[key]}场战斗胜利，${what}！` };
  }
  if (!pet) return no("请先选择一只亚比。");
  const name = pet.nick || nameOf(t, pet.race);
  const max = statsOf(pet, t);
  if (HP_ITEMS[ii]) {
    if (pet.hp >= max[0]) return no(`${name}的体力是满的，不需要恢复哦。`);
    const before = pet.hp;
    pet.hp = Math.min(max[0], pet.hp + HP_ITEMS[ii]);
    return { ok: true, msg: `${name}恢复了${pet.hp - before}点体力。` };
  }
  if (PP_ITEMS[ii]) {
    if (pet.skills.every((s) => s.pp >= s.max)) return no(`${name}的技能使用次数是满的，不需要恢复哦。`);
    for (const s of pet.skills) s.pp = Math.min(s.max, s.pp + PP_ITEMS[ii]);
    return { ok: true, msg: `${name}的技能使用次数恢复了！` };
  }
  if (CURES.includes(ii)) return no("这个药剂要在战斗中使用哦，战斗结束后亚比的异常状态就消失了。");
  const exp = STARTER_EXP[ii] ?? FRUIT_EXP[ii];
  if (exp) {
    if (STARTER_EXP[ii] && !STARTER_RACES.includes(pet.race)) return no("初始亚比经验糖只能对吉拉系列、滴滴系列和兔小子系列的亚比使用哦！");
    if (pet.level >= 100) return no(`${name}已经100级了，不需要再增加经验啦！`);
    const before = pet.race;
    const r = gainExp(t, pet, exp);
    return { ok: true, msg: `${name}获得了${exp}点经验！`, msgs: r.msgs, raceChanged: pet.race !== before };
  }
  pet.ev ??= [0, 0, 0, 0, 0, 0];
  const ev = pet.ev;
  if (EV_FRUITS[ii] !== undefined) {
    const i = EV_FRUITS[ii];
    const total = ev.reduce((a, b) => a + b, 0);
    if (total >= 510) return no(`${name}的学习力已经满510了哦！`);
    if (ev[i] >= 255) return no(`${name}的${STAT_NAMES[i]}学习力已经满255了哦！`);
    const add = Math.min(5, 255 - ev[i], 510 - total);
    ev[i] += add;
    return { ok: true, msg: `${name}的${STAT_NAMES[i]}学习力增加了${add}点！` };
  }
  if (FORGET[ii] !== undefined || ii === 523 || ii === 63) {
    if (ii !== 63 && pet.level >= 100) return no("遗忘喷雾不能对100级的亚比使用，请先用降级喷雾降到99级再使用。");
    if (FORGET[ii] !== undefined) {
      const i = FORGET[ii];
      if (ev[i] === 0) return no(`${name}的${STAT_NAMES[i]}学习力已经是0了。`);
      ev[i] = 0;
      return { ok: true, msg: `${name}的${STAT_NAMES[i]}学习力清空了。` };
    }
    if (ev.every((v) => v === 0)) return no(`${name}的学习力已经是0了。`);
    ev.fill(0);
    return { ok: true, msg: `${name}的学习力全部清空了。` };
  }
  if (ii === 65) {
    if (pet.level <= 1) return no("降级喷雾不能对1级的亚比使用。");
    pet.level--;
    pet.exp = 0;
    pet.hp = Math.min(pet.hp, statsOf(pet, t)[0]);
    return { ok: true, msg: `${name}降到了${pet.level}级。` };
  }
  if (ii === 193) {
    const first = firstForm(t, pet.race);
    if (first === pet.race && pet.level === 1) return no(`${name}已经是第一形态的1级亚比了。`);
    const before = pet.race;
    pet.race = first;
    pet.level = 1;
    pet.exp = 0;
    pet.fixed = undefined;
    pet.hp = Math.min(pet.hp, statsOf(pet, t)[0]);
    return { ok: true, msg: `${name}还原成了1级的${nameOf(t, first)}，性格、技能和学习力都保留着。`, raceChanged: before !== first };
  }
  if (ii === 220) {
    if (pet.fixed) return no(`${name}的形态已经固化了。`);
    if (!evolvesFurther(t, pet.race)) return no(`${name}已经不会再进化了，不需要固化形态哦。`);
    pet.fixed = true;
    return { ok: true, msg: `${name}的形态固化了！以后升级也不会再进化。` };
  }
  if (ii === 66 || NATURE_SETS[ii]) {
    const pool = (NATURE_SETS[ii] ?? NATURE_NAMES).filter((n) => n !== pet.character);
    const next = pool[Math.floor(rng() * pool.length)] ?? pet.character;
    const before = pet.character;
    pet.character = next;
    pet.hp = Math.min(pet.hp, statsOf(pet, t)[0]);
    return { ok: true, msg: `${name}的性格从${before}变成了${next}！` };
  }
  if (BUFF_ITEMS[ii]) {
    const [i, add] = BUFF_ITEMS[ii];
    pet.buff = { i, add };
    return { ok: true, msg: `${name}的下一场战斗中，前${BUFF_ROUNDS}回合${STAT_NAMES[i]}提升${add}点！（不能用在和其他奥拉的亚比的对战中）` };
  }
  const evo = EVO_STONES[ii];
  if (evo) {
    const [from, to] = evo;
    if (pet.race !== from) return no(`只有${nameOf(t, from)}才可以使用这块进化石哦！`);
    if (!speciesOf(t, to)) return no("这块进化石现在还不能使用。");
    pet.race = to;
    pet.learned = learntFor(t, to, pet.level, pet.skills);
    pet.hp = Math.min(statsOf(pet, t)[0], pet.hp);
    return { ok: true, msg: `${name}进化成了${nameOf(t, to)}！`, raceChanged: true };
  }
  const stone = SKILL_STONES[ii];
  if (stone) {
    const [race, skill, lv] = stone;
    if (pet.race !== race) return no(`只有${nameOf(t, race)}才可以学习这个技能哦！`);
    if (pet.level < lv) return no(`只有达到${lv}级或以上的${nameOf(t, race)}才可以学习这个技能哦！`);
    pet.learned ??= pet.skills.map((s) => s.id);
    if (pet.learned.includes(skill)) return no(`${name}已经学会${skillOf(t, skill).name}了。`);
    pet.learned.push(skill);
    const carried = pet.skills.length < 4;
    if (carried) pet.skills.push(skillOf(t, skill));
    return { ok: true, msg: `${name}学会了${skillOf(t, skill).name}！${carried ? "" : "可以在亚比背包的“更换技能”中带上它。"}` };
  }
  if (ii === 34 || ii === 35) return no("DNA芯片要在亚比克隆仪和亚比重组仪里使用哦。");
  return no("这个道具不能对亚比使用哦。");
}

export function installPetItems(world: World, deps: PetItemDeps): void {
  world.xt("MaterialExtension.14_12", async (ctx) => {
    const ii = Number(ctx.params.ii) | 0;
    const pi = Number(ctx.params.pi) | 0;
    const o = await deps.load(ctx);
    const t = await deps.tables();
    const reply = (res: number, msg: string) => ctx.reply({ res, ii, pi, msg });
    const bag = ((o.items ??= {})["2"] ??= {});
    if ((bag[String(ii)] ?? 0) < 1) return reply(0, "你没有这个道具哦。");
    const pet = pi > 0 ? [...(o.pets ?? []), ...(o.storage ?? [])].find((p) => p.id === pi) : undefined;
    if (pi > 0 && !pet) return reply(0, "找不到这只亚比。");
    const r = applyPetItem(t, o, ii, pet);
    if (!r.ok) return reply(0, r.msg);
    const left = bag[String(ii)] - 1;
    if (left > 0) bag[String(ii)] = left;
    else delete bag[String(ii)];
    await deps.save(o);
    ctx.reply({ amount: `2_${ii}_0_-1` }, "onAmountUpdated");
    for (const [cmd, body] of r.msgs ?? []) ctx.reply(body, cmd);
    if (r.raceChanged && pet) deps.changedRace?.(ctx, o, pet);
    reply(1, r.msg);
  });
}
