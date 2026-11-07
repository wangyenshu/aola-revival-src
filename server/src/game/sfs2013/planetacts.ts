// The activities of the 2012 story planets for the 2013 server: the commands their panels
// (most of them the files of 2011–12, a few later uploads) send, with the reply fields they read.
// Every reply goes out under the request's own cmd unless said otherwise.
//
// 摩么卡的养成 (魔术之星, momekaevolution/momekaevolutionpanel) and 亚伦的养成 (风车城,
// activityres/yalunevolution): the panel fights a task 亚比 (20699, 10895) and after a win asks
//   PetExtension2 54e_20 {pid, t: 1}  -> {res}  0: the 亚比 pid evolves (摩么卡 698 -> 魔幻摩卡 699,
//                                               亚伦 894 -> 利克亚伦 895); else "各种奇奇怪怪的问题"
// 巨锁石灵的机关 (族长之帐, otherpanel/yakestarrarepetpanel):
//   PetExtension2 54e_23 {}  -> {c, t}   locks opened so far, ms until the next may be opened
//   PetExtension2 54e_24 {}  -> {succ}   open one (one every 10 minutes); the fifth of a round brings
//                                         小石灵 (832; GettedPanel shows its egg)
// 达黑黑 (海枯之山, rarepets/raredaheihei: NPC 516's 猜弹珠, GuessBallGameScene):
//   PeriodicActiveExtension 91_47 {}       -> {c}    games won
//   PeriodicActiveExtension 91_46 {num, w} -> {get}  a game: num 弹珠 (item 476) are 达黑黑's, w won;
//                                                    the tenth win brings 小黑黑 (335)
// 白京京之心 (海枯之海, bringupres/fishbringupservice and fishbringuppanel):
//   PeriodicActiveExtension 91_48 {}  -> {c, l}  times said “矮老虎哟”, when last ("Y-M-D H:M:S" or "")
//   PeriodicActiveExtension 91_49 {}  -> {get}   say it again (10 minutes apart); the fourth brings
//                                                 小京京 (336; FishGainPanel shows its egg)
// 粗心的卡索 (索尔石城, activityres/foodball):
//   HolidayExtension 20120914_Fu1 {}  -> {got, sign}         sign: bit i set when stone word i is found
//   HolidayExtension 20120914_Fu2 {}  -> {stone, bn}         break a stone with a 大力锤 (item 590):
//                                                             stone 0–7 the word inside (-1 none left);
//                                                             bn the reward [{type, id, num}] once all
//                                                             eight are found (卡索, 1209)
// 阿莫扭蛋机 (大地迷城, activityres/amomanager, amopanel):
//   HolidayExtension 20121012_A1 {}   -> {state}             bit i: joke i got; 255 all (the joke book)
//   HolidayExtension 20121012_A2 {}   -> {res, joke, bn}     one 扭蛋币 (item 597): a joke (0–7, -1 none)
//                                                             or a bonus bn [{type: 101 经验 | 100 晶币,
//                                                             num}]; the eighth joke brings 阿莫 (1247)
// 钓星星的波波嘟 (海洋幻境, activityres/activity121108/bobodu, bobodures):
//   PeriodicActiveExtension gofish-1 {}     -> {id, bn}   a catch: id 0–5 笑脸星星, 普通亚比球, 晶币,
//                                                          高级体力糖, 经验, 中级活力豆 (6: nothing; after
//                                                          FISH_PER_DAY casts a day, always nothing)
//   PeriodicActiveExtension gofish-2 {}     -> {res}      20 笑脸星星 (item 610) for 波波嘟 (1286), once a day
//   PeriodicActiveExtension gofish-3 {num}  -> {res}      1: num 笑脸星星 bought, 2 星币 each
// The 独角兽 of 独角之星 (unicorn/unicornservice, its panels, unicorn/skyunicornservice):
//   PetExtension2 54e_1 {pid, t}            -> {res}   0: 小独角兽 651 evolves, t 1 先哲 (655; 先哲之书,
//                                                       水晶球, 法杖 458–460 used), 2 铠甲 (656; its four
//                                                       parts 454–457 used)
//   SynthesizeExtension 57_8 {id, num}       -> {res}   1: a 铠甲 part made (186–189 -> 454–457) from 5
//                                                       铠甲碎片 (461)
//   PeriodicActiveExtension 91_31 {id}       -> {res}   the 先哲 treasure id (1–3 -> item 458–460) after
//                                                       the fight with its soul (10655)
//   PeriodicActiveExtension 91_34 {}         -> {c, td} days the 仙林果实 was tended (of 3), today done
//   PeriodicActiveExtension 91_35 {}         -> {res}   tend it today (with a 小独角兽 following)
//   PeriodicActiveExtension 91_36 {id}       -> {res}   仙林独角兽 (654) from the 小独角兽 id after 3 days
//   PeriodicActiveExtension 91_33 {}         -> {es, ad} 小独角兽 got from NPC 459, 飞天 egg adopted
//   PeriodicActiveExtension 91_32 {}         -> {res}   NPC 459's 小独角兽 (651), once
//   PeriodicActiveExtension 91_37 {}         -> {res}   adopt the 飞天独角兽's egg: 2 already adopted,
//                                                       1 now (two of 铠甲/先哲/仙林 raised), 0 not yet
//   PeriodicActiveExtension 91_38 {n}        -> {sum, nl}  the egg of n: 亲密度, "name#nick,…" who played
//   PeriodicActiveExtension 91_39 {n}        -> {res}   play with it: 1 one more, 2 played today, 3 three
//                                                       eggs today
//   PeriodicActiveExtension 91_40 {}         -> {res}   hatch it at 15: 飞天独角兽 (653)
//
// The 2013 server is lost; RECONSTRUCTED here: the rewards the panels show as eggs (MaterialTypes
// PET_EGG 102: 小石灵, 小黑黑, 小京京, 阿莫, 波波嘟, 卡索, 小独角兽) come as the 亚比 itself at
// Lv1, as no 2013 egg table has them; which reward comes with what chance; once-only and daily
// limits beyond those the panels state; 飞天独角兽's 亲密度 from its owner too (a revival has no
// friends to visit), three times a day; the items the wild 亚比 of the rooms drop (wildDrop, after a
// won fight: 弹珠 from the 海豆 of 海枯之山, 大力锤 from 石苗龟, 扭蛋币 from 火刺球, 铠甲碎片 from the 小玩具马
// line of 皇宫外城 and 皇宫地牢; where is the panels' own word, how many is not).

import type { World, XtContext } from "./server.ts";
import { followVar, type PetRecord, type PetTables } from "./pets.ts";
import { gainExp } from "./battle.ts";

type Msg = [string, Record<string, unknown>];

export interface ActsRec {
  /** 巨锁石灵的机关: locks opened, when the next may be (ms). */
  lock?: { c: number; next: number };
  /** 达黑黑's 猜弹珠: games won, 小黑黑 given. */
  mora?: { w: number; got?: boolean };
  /** 白京京之心: times said, last (ms). */
  heart?: { c: number; last: number };
  /** 粗心的卡索: words found (bits), reward given. */
  food?: { sign: number; got?: boolean };
  /** 阿莫扭蛋机: jokes got (bits). */
  amo?: { state: number };
  /** 波波嘟 got on that day. */
  bobodu?: { day: string };
  /** 钓星星: the casts of the day. */
  fish?: { day: string; n: number };
  /** 仙林果实: days tended, the last day. */
  xianlin?: { c: number; day: string };
  /**
   * 飞天独角兽: 小独角兽 from NPC 459, egg adopted, 亲密度, who played with the egg ("name#nick"), who
   * played with it today, how often this player played today (with any egg), hatched.
   */
  sky?: { es?: boolean; ad?: boolean; love: number; nl: string[]; played?: { day: string; names: string[] }; day?: string; plays?: number; hatched?: boolean };
}

export interface ActsOwner {
  name: string;
  score?: number;
  xingbi?: number;
  items?: Record<string, Record<string, number>>;
  pets?: PetRecord[];
  storage?: PetRecord[];
  followPet?: number;
  planetActs?: ActsRec;
}

export interface PlanetActsDeps {
  load: (ctx: XtContext) => Promise<ActsOwner>;
  find: (name: string) => Promise<ActsOwner | undefined>;
  save: (o: ActsOwner) => Promise<void>;
  tables: () => Promise<PetTables>;
  now: () => number;
  today: () => string;
  /** A new 亚比 of that race into the bag (or the 仓库); the replies that tell the client. */
  givePet: (o: ActsOwner, race: number, level: number) => Promise<Msg[]>;
  rng?: () => number;
}

export const ITEM = "2";
/** Special evolutions of 54e_20 t 1 (the panels' own level checks: 摩么卡 50, 亚伦 40). */
export const SPECIAL_EVOLUTION: Record<number, [number, number]> = { 698: [699, 50], 894: [895, 40] };
export const LOCK_WAIT_MS = 10 * 60 * 1000;
export const HEART_WAIT_MS = 10 * 60 * 1000;
export const HEART_TIMES = 4;
export const MORA_WINS = 10;
export const MARBLE = 476;
export const HAMMER = 590;
export const AMO_COIN = 597;
export const SMILE_STAR = 610;
export const ARMOR_FRAG = 461;
/** 57_8's 铠甲 parts: exchange id -> item. */
export const ARMOR_PARTS: Record<number, number> = { 186: 454, 187: 455, 188: 456, 189: 457 };
export const SAGE_TREASURES = [458, 459, 460];
export const SKY_LOVE = 15;
export const SKY_PLAYS_PER_DAY = 3;
/** The 亚比 the rewards bring (RECONSTRUCTED: the 亚比 at Lv1, see above). */
export const REWARD_PET = { lock: 832, mora: 335, heart: 336, food: 1209, amo: 1247, bobodu: 1286, unicorn: 651 } as const;
/** AmoPanel.bonusArr: the bonuses it knows. */
export const AMO_BONUS = [
  { type: 101, num: 200 },
  { type: 101, num: 500 },
  { type: 100, num: 100 },
  { type: 100, num: 200 },
];
/** Casts a day that can catch something (RECONSTRUCTED). */
export const FISH_PER_DAY = 20;
/** BoboduInteraction's catches 0–5: [type, id, num]; 6 nothing (RECONSTRUCTED amounts and weights). */
export const FISH_CATCH: [number, number, number, number][] = [
  [2, SMILE_STAR, 1, 40],
  [2, 32, 1, 12],
  [100, -1, 50, 12],
  [2, 61, 1, 8],
  [101, -1, 100, 12],
  [2, 103, 1, 8],
  [0, 0, 0, 8],
];

/**
 * Items the wild 亚比 of a room drop after a won fight: room -> race -> [item, count] (RECONSTRUCTED;
 * the panels name where: “与海枯之山的水水海豆和惊惊海豆战斗” (惊惊海豆 more often), “在索尔石城与
 * 石苗龟战斗”, “和火刺球战斗获得扭蛋币”, “铠甲碎片可以通过打败皇宫外城和皇宫地牢的小玩具马系列亚比获得”).
 */
export const WILD_DROPS: Record<string, Record<number, [number, number]>> = {
  haikustar4: { 705: [MARBLE, 1], 706: [MARBLE, 2] },
  cloudstar4: { 1203: [HAMMER, 1] },
  mysticearth1: { 1245: [AMO_COIN, 1] },
  mysticearth2: { 1245: [AMO_COIN, 1] },
  mysticearth3: { 1245: [AMO_COIN, 1] },
  mysticearth4: { 1245: [AMO_COIN, 1] },
  unicornstar1: { 645: [ARMOR_FRAG, 1], 646: [ARMOR_FRAG, 1] },
  unicornstar4: { 647: [ARMOR_FRAG, 1] },
  // 小白吐获得 and 骑士王座 (areafuncs.ts): 糖果 (513) “won from the 布布兔”, 骑士卡 (531) from the 小骑兵.
  candystar1: { 844: [513, 1] },
  candystar3: { 844: [513, 1] },
  knightstar1: { 932: [531, 1] },
  // 武神大陆's 黄巾战魂 (fightking.ts): "在恶人山道击败黄巾小兵就有几率获得黄巾战魂" (one a win: RECONSTRUCTED).
  fightkingwar2: { 853: [509, 1] },
};

const actsOf = (o: ActsOwner): ActsRec => (o.planetActs ??= {});
const itemsOf = (o: ActsOwner, type = ITEM) => ((o.items ??= {})[type] ??= {});
export const countOf = (o: ActsOwner, id: number) => o.items?.[ITEM]?.[String(id)] ?? 0;

/** Change an item by n (not below 0, not above 9999 by adding); the onAmountUpdated that tells the client, if any. */
export function addItem(o: ActsOwner, id: number, n: number): Msg[] {
  const items = itemsOf(o);
  const before = items[String(id)] ?? 0;
  const after = n > 0 ? Math.min(Math.max(before, 9999), before + n) : Math.max(0, before + n);
  if (after === before) return [];
  if (after) items[String(id)] = after;
  else delete items[String(id)];
  return [["onAmountUpdated", { amount: `${ITEM}_${id}_0_${after - before}` }]];
}

/** The items a won fight against a wild 亚比 of that race in that room brings (WILD_DROPS). */
export function wildDrop(o: ActsOwner, room: string, race: number): Msg[] {
  const d = WILD_DROPS[room]?.[race];
  return d ? addItem(o, d[0], d[1]) : [];
}

/** "Y-M-D H:M:S" in local time, as FishBringUpService.parseToDate reads it. */
export function clockText(ms: number): string {
  const d = new Date(ms);
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}

const allPets = (o: ActsOwner) => [...(o.pets ?? []), ...(o.storage ?? [])];
const petById = (o: ActsOwner, id: unknown) => (o.pets ?? []).find((p) => p.id === (Number(id) | 0));

/** Evolve a 亚比 into `to` (its follow variable updated when it follows). */
function evolve(world: World, ctx: XtContext, o: ActsOwner, pet: PetRecord, to: number): void {
  pet.race = to;
  if (o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
}

/** Rewards [{type, id, num}] of 100 (晶币) and 101 (experience for the first 亚比). */
async function payBonus(deps: PlanetActsDeps, o: ActsOwner, bn: { type: number; num: number }[]): Promise<Msg[]> {
  const out: Msg[] = [];
  for (const b of bn) {
    if (b.type === 100) {
      o.score = (o.score ?? 0) + b.num;
      out.push(["onScoreUpdated", { score: o.score }]);
    } else if (b.type === 101 && o.pets?.[0]) {
      out.push(...gainExp(await deps.tables(), o.pets[0], b.num).msgs);
    }
  }
  return out;
}

export function installPlanetActs(world: World, deps: PlanetActsDeps): void {
  const rng = deps.rng ?? Math.random;
  const send = (ctx: XtContext, msgs: Msg[]) => {
    for (const [cmd, body] of msgs) ctx.reply(body, cmd);
  };

  // ------------------------------------------------ 摩么卡 and 亚伦: 54e_20
  world.xt("PetExtension2.54e_20", async (ctx) => {
    const o = await deps.load(ctx);
    const pet = petById(o, ctx.params.pid);
    const to = pet ? SPECIAL_EVOLUTION[pet.race] : undefined;
    if (!pet || !to || pet.level < to[1]) return ctx.reply({ res: 1 }, "54e_20");
    evolve(world, ctx, o, pet, to[0]);
    await deps.save(o);
    ctx.reply({ res: 0, pid: pet.id, raceId: pet.race }, "54e_20");
  });

  // ------------------------------------------------ 巨锁石灵的机关: 54e_23, 54e_24
  world.xt("PetExtension2.54e_23", async (ctx) => {
    const lock = actsOf(await deps.load(ctx)).lock ?? { c: 0, next: 0 };
    ctx.reply({ c: lock.c, t: Math.max(0, lock.next - deps.now()) }, "54e_23");
  });
  world.xt("PetExtension2.54e_24", async (ctx) => {
    const o = await deps.load(ctx);
    const a = actsOf(o);
    const lock = (a.lock ??= { c: 0, next: 0 });
    if (deps.now() < lock.next) return ctx.reply({ succ: false }, "54e_24");
    lock.c++;
    lock.next = deps.now() + LOCK_WAIT_MS;
    const succ = lock.c % 5 === 0;
    const msgs = succ ? await deps.givePet(o, REWARD_PET.lock, 1) : [];
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ succ }, "54e_24");
  });

  // ------------------------------------------------ 达黑黑's 猜弹珠: 91_47, 91_46
  world.xt("PeriodicActiveExtension.91_47", async (ctx) => {
    ctx.reply({ c: actsOf(await deps.load(ctx)).mora?.w ?? 0 }, "91_47");
  });
  world.xt("PeriodicActiveExtension.91_46", async (ctx) => {
    const o = await deps.load(ctx);
    const mora = (actsOf(o).mora ??= { w: 0 });
    const num = Math.max(1, Math.min(4, Number(ctx.params.num) | 0));
    if (countOf(o, MARBLE) < num) return ctx.reply({ get: false }, "91_46");
    const msgs = addItem(o, MARBLE, -num);
    const won = ctx.params.w === true || ctx.params.w === "true" || ctx.params.w === 1;
    if (won) mora.w++;
    let get = false;
    if (won && mora.w >= MORA_WINS && !mora.got) {
      mora.got = true;
      get = true;
      mora.w = 0;
      msgs.push(...(await deps.givePet(o, REWARD_PET.mora, 1)));
    }
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ get }, "91_46");
  });

  // ------------------------------------------------ 白京京之心: 91_48, 91_49
  world.xt("PeriodicActiveExtension.91_48", async (ctx) => {
    const h = actsOf(await deps.load(ctx)).heart;
    ctx.reply({ c: h?.c ?? 0, l: h?.last ? clockText(h.last) : "" }, "91_48");
  });
  world.xt("PeriodicActiveExtension.91_49", async (ctx) => {
    const o = await deps.load(ctx);
    const h = (actsOf(o).heart ??= { c: 0, last: 0 });
    if (h.c >= HEART_TIMES || (h.last && deps.now() - h.last < HEART_WAIT_MS)) return ctx.reply({ get: false }, "91_49");
    h.c++;
    h.last = deps.now();
    const get = h.c >= HEART_TIMES;
    const msgs = get ? await deps.givePet(o, REWARD_PET.heart, 1) : [];
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ get }, "91_49");
  });

  // ------------------------------------------------ 粗心的卡索: 20120914_Fu1, _Fu2
  world.xt("HolidayExtension.20120914_Fu1", async (ctx) => {
    const f = actsOf(await deps.load(ctx)).food;
    ctx.reply({ got: !!f?.got, sign: f?.sign ?? 0 }, "20120914_Fu1");
  });
  world.xt("HolidayExtension.20120914_Fu2", async (ctx) => {
    const o = await deps.load(ctx);
    const f = (actsOf(o).food ??= { sign: 0 });
    if (f.got || countOf(o, HAMMER) <= 0) return ctx.reply({ stone: -1, bn: [] }, "20120914_Fu2");
    const msgs = addItem(o, HAMMER, -1);
    // One stone in three holds a word not found yet (RECONSTRUCTED), the others any word.
    const missing = [0, 1, 2, 3, 4, 5, 6, 7].filter((i) => !(f.sign & (1 << i)));
    const stone = missing.length && rng() < 1 / 3 ? missing[Math.floor(rng() * missing.length)] : Math.floor(rng() * 8);
    f.sign |= 1 << stone;
    let bn: { type: number; id: number; num: number }[] = [];
    if (f.sign === 255) {
      f.got = true;
      bn = [{ type: 102, id: REWARD_PET.food, num: 1 }];
      msgs.push(...(await deps.givePet(o, REWARD_PET.food, 1)));
    }
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ stone, bn: bn.length ? bn : null }, "20120914_Fu2");
  });

  // ------------------------------------------------ 阿莫扭蛋机: 20121012_A1, _A2
  world.xt("HolidayExtension.20121012_A1", async (ctx) => {
    ctx.reply({ state: actsOf(await deps.load(ctx)).amo?.state ?? 0 }, "20121012_A1");
  });
  world.xt("HolidayExtension.20121012_A2", async (ctx) => {
    const o = await deps.load(ctx);
    const amo = (actsOf(o).amo ??= { state: 0 });
    if (amo.state === 255 || countOf(o, AMO_COIN) <= 0) return ctx.reply({ res: false, joke: -1, bn: [] }, "20121012_A2");
    const msgs = addItem(o, AMO_COIN, -1);
    let joke = -1;
    let bn: { type: number; num: number }[] = [];
    const missing = [0, 1, 2, 3, 4, 5, 6, 7].filter((i) => !(amo.state & (1 << i)));
    if (rng() < 0.5 && missing.length) {
      joke = missing[Math.floor(rng() * missing.length)];
      amo.state |= 1 << joke;
      if (amo.state === 255) msgs.push(...(await deps.givePet(o, REWARD_PET.amo, 1)));
    } else {
      bn = [AMO_BONUS[Math.floor(rng() * AMO_BONUS.length)]];
      msgs.push(...(await payBonus(deps, o, bn)));
    }
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: true, joke, bn }, "20121012_A2");
  });

  // ------------------------------------------------ 钓星星的波波嘟: gofish-1, gofish-2, gofish-3
  world.xt("PeriodicActiveExtension.gofish-1", async (ctx) => {
    const o = await deps.load(ctx);
    const a = actsOf(o);
    if (a.fish?.day !== deps.today()) a.fish = { day: deps.today(), n: 0 };
    if (a.fish.n >= FISH_PER_DAY) return ctx.reply({ id: FISH_CATCH.length - 1, bn: null }, "gofish-1");
    a.fish.n++;
    const total = FISH_CATCH.reduce((s, c) => s + c[3], 0);
    let r = rng() * total;
    let id = FISH_CATCH.length - 1;
    for (let i = 0; i < FISH_CATCH.length; i++) {
      if ((r -= FISH_CATCH[i][3]) < 0) {
        id = i;
        break;
      }
    }
    const [type, item, num] = FISH_CATCH[id];
    const msgs: Msg[] = [];
    let bn: { type: number; id: number; num: number }[] | null = null;
    if (type === 2) {
      const got = addItem(o, item, num);
      if (got.length) {
        msgs.push(...got);
        bn = [{ type, id: item, num }];
      }
    } else if (type === 100 || type === 101) {
      msgs.push(...(await payBonus(deps, o, [{ type, num }])));
      bn = [{ type, id: item, num }];
    }
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ id, bn }, "gofish-1");
  });
  world.xt("PeriodicActiveExtension.gofish-2", async (ctx) => {
    const o = await deps.load(ctx);
    const a = actsOf(o);
    if (countOf(o, SMILE_STAR) < 20 || a.bobodu?.day === deps.today()) return ctx.reply({ res: false }, "gofish-2");
    const msgs = addItem(o, SMILE_STAR, -20);
    a.bobodu = { day: deps.today() };
    msgs.push(...(await deps.givePet(o, REWARD_PET.bobodu, 1)));
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: true }, "gofish-2");
  });
  world.xt("PeriodicActiveExtension.gofish-3", async (ctx) => {
    const o = await deps.load(ctx);
    const num = Math.max(0, Math.min(99, Number(ctx.params.num) | 0));
    if (!num || (o.xingbi ?? 0) < num * 2) return ctx.reply({ res: 0 }, "gofish-3");
    o.xingbi = (o.xingbi ?? 0) - num * 2;
    const msgs = addItem(o, SMILE_STAR, num);
    await deps.save(o);
    ctx.reply({ xingbi: o.xingbi }, "onXingBiUpdate");
    send(ctx, msgs);
    ctx.reply({ res: 1 }, "gofish-3");
  });

  // ------------------------------------------------ 独角兽: 54e_1, 57_8, 91_31, 91_34–36
  world.xt("PetExtension2.54e_1", async (ctx) => {
    const o = await deps.load(ctx);
    const pet = petById(o, ctx.params.pid);
    const t = Number(ctx.params.t) | 0;
    const need = t === 1 ? SAGE_TREASURES : t === 2 ? Object.values(ARMOR_PARTS) : [];
    if (!pet || pet.race !== REWARD_PET.unicorn || !need.length || need.some((id) => countOf(o, id) <= 0)) return ctx.reply({ res: 1 }, "54e_1");
    const msgs: Msg[] = [];
    for (const id of need) msgs.push(...addItem(o, id, -1));
    evolve(world, ctx, o, pet, t === 1 ? 655 : 656);
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: 0, pid: pet.id, raceId: pet.race }, "54e_1");
  });
  world.xt("SynthesizeExtension.57_8", async (ctx) => {
    const o = await deps.load(ctx);
    const part = ARMOR_PARTS[Number(ctx.params.id) | 0];
    if (!part || countOf(o, ARMOR_FRAG) < 5 || countOf(o, part) > 0) return ctx.reply({ res: 0 }, "57_8");
    const msgs = [...addItem(o, ARMOR_FRAG, -5), ...addItem(o, part, 1)];
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: 1 }, "57_8");
  });
  world.xt("PeriodicActiveExtension.91_31", async (ctx) => {
    const o = await deps.load(ctx);
    const item = SAGE_TREASURES[(Number(ctx.params.id) | 0) - 1];
    if (!item || countOf(o, item) > 0) return ctx.reply({ res: false }, "91_31");
    const msgs = addItem(o, item, 1);
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: true }, "91_31");
  });
  world.xt("PeriodicActiveExtension.91_34", async (ctx) => {
    const x = actsOf(await deps.load(ctx)).xianlin;
    ctx.reply({ c: x?.c ?? 0, td: x?.day === deps.today() }, "91_34");
  });
  world.xt("PeriodicActiveExtension.91_35", async (ctx) => {
    const o = await deps.load(ctx);
    const x = (actsOf(o).xianlin ??= { c: 0, day: "" });
    const follow = (o.pets ?? []).find((p) => p.id === o.followPet);
    if (x.day === deps.today() || x.c >= 3 || follow?.race !== REWARD_PET.unicorn) return ctx.reply({ res: false, c: x.c }, "91_35");
    x.c++;
    x.day = deps.today();
    await deps.save(o);
    ctx.reply({ res: true, c: x.c }, "91_35");
  });
  world.xt("PeriodicActiveExtension.91_36", async (ctx) => {
    const o = await deps.load(ctx);
    const x = (actsOf(o).xianlin ??= { c: 0, day: "" });
    const pet = petById(o, ctx.params.id);
    if (!pet || pet.race !== REWARD_PET.unicorn || x.c < 3) return ctx.reply({ res: false }, "91_36");
    x.c = 0;
    evolve(world, ctx, o, pet, 654);
    await deps.save(o);
    ctx.reply({ res: true }, "91_36");
  });

  // ------------------------------------------------ 飞天独角兽: 91_32, 91_33, 91_37–40
  const sky = (o: ActsOwner) => (actsOf(o).sky ??= { love: 0, nl: [] });
  world.xt("PeriodicActiveExtension.91_33", async (ctx) => {
    const s = sky(await deps.load(ctx));
    ctx.reply({ es: !!s.es, ad: !!s.ad || !!s.hatched }, "91_33");
  });
  world.xt("PeriodicActiveExtension.91_32", async (ctx) => {
    const o = await deps.load(ctx);
    const s = sky(o);
    if (s.es) return ctx.reply({ res: false }, "91_32");
    s.es = true;
    const msgs = await deps.givePet(o, REWARD_PET.unicorn, 1);
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: true }, "91_32");
  });
  world.xt("PeriodicActiveExtension.91_37", async (ctx) => {
    const o = await deps.load(ctx);
    const s = sky(o);
    if (s.ad && !s.hatched) return ctx.reply({ res: 2 }, "91_37");
    const raised = new Set(allPets(o).map((p) => p.race).filter((r) => r === 654 || r === 655 || r === 656));
    if (s.hatched || raised.size < 2) return ctx.reply({ res: 0 }, "91_37");
    s.ad = true;
    await deps.save(o);
    ctx.reply({ res: 1 }, "91_37");
  });
  world.xt("PeriodicActiveExtension.91_38", async (ctx) => {
    const owner = String(ctx.params.n ?? "") || ctx.player.name;
    const o = owner === ctx.player.name ? await deps.load(ctx) : await deps.find(owner);
    const s = o?.planetActs?.sky;
    ctx.reply({ sum: s?.love ?? 0, nl: (s?.nl ?? []).join(",") }, "91_38");
  });
  world.xt("PeriodicActiveExtension.91_39", async (ctx) => {
    const me = await deps.load(ctx);
    const ownerName = String(ctx.params.n ?? "") || me.name;
    const o = ownerName === me.name ? me : await deps.find(ownerName);
    if (!o) return ctx.reply({ res: 0 }, "91_39");
    const s = sky(o);
    const mine = sky(me);
    const today = deps.today();
    if (mine.day !== today) {
      mine.day = today;
      mine.plays = 0;
    }
    if ((mine.plays ?? 0) >= SKY_PLAYS_PER_DAY) return ctx.reply({ res: 3 }, "91_39");
    // Each player once a day with someone else's egg; the owner up to three times (RECONSTRUCTED).
    if (s.played?.day !== today) s.played = { day: today, names: [] };
    if (o !== me && s.played.names.includes(me.name)) return ctx.reply({ res: 2 }, "91_39");
    mine.plays = (mine.plays ?? 0) + 1;
    // The egg's side: its owner's record. Someone else's is changed on a copy read again just
    // before it is saved, with nothing awaited between (a copy read earlier, kept over the save
    // of one's own record, would put back what its owner had changed meanwhile on a server
    // with several players).
    const bump = (egg: ReturnType<typeof sky>): boolean => {
      if (egg.played?.day !== today) egg.played = { day: today, names: [] };
      if (!egg.played.names.includes(me.name)) egg.played.names.push(me.name);
      const counted = !!egg.ad && !egg.hatched && egg.love < SKY_LOVE;
      if (counted) egg.love++;
      const tag = `${me.name}#${me.name}`;
      if (!egg.nl.includes(tag)) egg.nl = [...egg.nl, tag].slice(-10);
      return counted;
    };
    me.score = (me.score ?? 0) + 20;
    let counted: boolean;
    if (o === me) {
      counted = bump(s);
      await deps.save(me);
    } else {
      await deps.save(me);
      const fresh = await deps.find(ownerName);
      counted = fresh ? bump(sky(fresh)) : false;
      if (fresh) await deps.save(fresh);
    }
    ctx.reply({ score: me.score }, "onScoreUpdated");
    ctx.reply({ res: counted ? 1 : 4 }, "91_39");
  });
  world.xt("PeriodicActiveExtension.91_40", async (ctx) => {
    const o = await deps.load(ctx);
    const s = sky(o);
    if (!s.ad || s.hatched || s.love < SKY_LOVE) return ctx.reply({ res: false }, "91_40");
    s.hatched = true;
    s.ad = false;
    const msgs = await deps.givePet(o, 653, 1);
    await deps.save(o);
    send(ctx, msgs);
    ctx.reply({ res: true }, "91_40");
  });
}
