// 礼包 (2013 ItemData type 11 GIFT_BAG, and the type 1 bags named 礼包): bought from the 收费道具商品册
// (catalog201005, btnMBuy_2_<id> / btnBuy_2_<id>), a bag is opened at once and what it holds goes into
// the bag. The 2013 client has no command to open one (MaterialClient knows none), so the 2013 server
// gave what a bag holds when it was bought; that server and its list are lost.
//
// What each bag holds is RECONSTRUCTED from its 2013 ItemData description, or, where that says
// nothing exact (271, 272, 299, 300, 321, 230), from what its catalog page shows; 限量超进化礼包 (337,
// "进化水晶助你轻松进化", sold by the 超进化机) holds the crystals of one of the later 超进化 (10
// 次级进化水晶 and 4 进化水晶, superevo.ts). Left out: what
// this revival has no data for (230's two 亚比服装, 299's HELLO服装 兔子头 and 亚比服装 半沙之子,
// 300's 5色满天星, 321's 家园种植 things). The 经验 of a bag goes to the HELLO's 经验分配器 (as
// quest 经验 does, RobotClient 2-12); before the player has a HELLO it waits for it (helloExp).
// The pages' "首次购买本礼包，额外获得1颗…龙珠" is first.
//
// Kinds: 0 clothes, 2 items, 4 射击卡, 5 亚比蛋 (id = race), 8 战术卡, 12 zoo animals (baby: 10000 +
// race, zoo.ts), 13 zoo 饲料 (zoo.ts uses one of the bag's before it asks 晶币).

import { MONEY_MAX } from "./money.ts";

/** [name, material type, id, how many]. */
export type Gift = [name: string, type: number, id: number, n: number];

export interface GiftBag {
  got: Gift[];
  /** 经验 for the HELLO's 经验分配器. */
  exp?: number;
  /** 晶币. */
  score?: number;
  /** The first one bought only. */
  first?: Gift;
}

const I = (name: string, id: number, n = 1): Gift => [name, 2, id, n];
const EGG = (name: string, race: number): Gift => [`${name}亚比蛋`, 5, race, 1];
const FORGET6 = (n: number): Gift[] =>
  ([[154, "攻击"], [155, "防御"], [156, "特攻"], [157, "特防"], [158, "速度"], [159, "体力"]] as const).map(([id, s]) => I(`遗忘喷雾-${s}`, id, n));
const NATURE5: Gift[] = ([[414, "攻击"], [415, "防御"], [416, "特攻"], [417, "特防"], [418, "速度"]] as const).map(([id, s]) => I(`性格改造-${s}`, id));
const EV6 = (n: number): Gift[] =>
  ([[524, "体力"], [525, "攻击"], [526, "防御"], [527, "特攻"], [528, "特防"], [529, "速度"]] as const).map(([id, s]) => I(`${s}果实`, id, n));

const EXP2 = (n: number) => I("双倍经验器", 43, n);
const EXP3 = (n: number) => I("三倍经验器", 378, n);
const AUTO = (n: number) => I("自动战斗仪", 44, n);
const LEARN2 = (n: number) => I("双倍学习器", 62, n);
const RADAR = (n: number) => I("寻宝雷达", 189, n);
const TALENT = (n: number) => I("天赋增强精华", 177, n);
const RESHAPE = (n: number) => I("性格重塑卡", 66, n);
const FIX = (n: number) => I("形态固化剂", 220, n);
const UNDO = (n: number) => I("还原喷雾", 193, n);
const DOWN = (n: number) => I("降级喷雾", 65, n);
const BALL = (n: number) => I("百分百亚比球", 64, n);
const BALL_DRAGON = (stars: string, id: number) => I(`${stars}星龙珠`, id);

export const GIFT_BAGS: Record<number, GiftBag> = {
  228: { got: [...FORGET6(1), LEARN2(2)], exp: 100000 },
  229: { got: [BALL(2), I("天赋重组胶囊", 506, 10), ["雪花射击卡", 4, 22, 100]], exp: 100000 },
  230: { got: [FIX(2), UNDO(2)] },
  231: { got: [EXP2(4), AUTO(1), BALL(1), RADAR(2)], exp: 100000 },
  243: { got: [TALENT(6), RADAR(3), RESHAPE(2)], exp: 100000 },
  271: { got: [BALL(2), LEARN2(2), EXP2(8), AUTO(4), RADAR(4), I("胜利奖章", 221, 200)], exp: 100000, first: BALL_DRAGON("六", 285) },
  272: { got: [...FORGET6(2), DOWN(4), LEARN2(2), TALENT(6)], exp: 100000, first: BALL_DRAGON("五", 284) },
  299: { got: [UNDO(5), FIX(4), DOWN(5), RESHAPE(4)], exp: 100000, first: BALL_DRAGON("七", 286) },
  300: { got: [EGG("酷波", 481)], exp: 100000, first: BALL_DRAGON("四", 283) },
  321: { got: [EGG("年兽", 493), AUTO(1), LEARN2(2), EXP2(2), TALENT(3)], exp: 200000 },
  337: { got: [I("次级进化水晶", 265, 10), I("进化水晶", 266, 4)] },
  462: { got: [I("天赋重组药剂", 178, 5), EXP2(2), RESHAPE(2), TALENT(2), LEARN2(1), AUTO(1)], exp: 60000 },
  463: { got: [["初级加速饲料", 13, 5, 4], ["中级加速饲料", 13, 6, 4], ["二星变异饲料", 13, 3, 4], ["小奶牛", 12, 10008, 1], ["小狸狸", 12, 10019, 1]], exp: 20000 },
  484: { got: [LEARN2(1), RADAR(1), RESHAPE(1), EGG("神蛋蛋", 765), EXP2(2)], exp: 110000 },
  487: { got: [EGG("元蛋蛋", 772), BALL(1)], exp: 100000 },
  497: { got: [EXP3(2), LEARN2(3), AUTO(3), RADAR(1), I("超级遗忘喷雾", 523)], exp: 190000 },
  498: { got: [BALL(2), TALENT(6), ...NATURE5, RESHAPE(2)], exp: 190000 },
  501: { got: [AUTO(1), DOWN(1), UNDO(1), EXP2(2), RADAR(2), RESHAPE(2)], exp: 100000 },
  502: {
    got: [["赤魔导士套装", 0, 1218, 1], ["", 0, 1219, 1], ["", 0, 1220, 1], ["", 0, 1221, 1], ["", 0, 1222, 1], ["", 0, 1223, 1], EGG("赤魔导士", 796)],
    exp: 120000,
  },
  503: { got: [["高级加速饲料", 13, 7, 2], ["三星变异饲料", 13, 4, 2], ["中级加速饲料", 13, 6, 4], ["趴趴熊", 12, 10036, 2]], exp: 120000 },
  512: { got: [RESHAPE(2), AUTO(2), EXP3(1), RADAR(1), DOWN(1), UNDO(1)], exp: 100000 },
  516: { got: [EXP2(3), AUTO(2), RESHAPE(1), FIX(1), UNDO(1)], exp: 100000 },
  521: { got: [EXP2(3), AUTO(2), TALENT(1), FIX(1), RADAR(1)], exp: 100000 },
  522: { got: [...EV6(17), I("超级遗忘喷雾", 523), DOWN(2)] },
  534: { got: [EXP2(4), AUTO(2), LEARN2(1), FIX(1), RESHAPE(1)], exp: 100000 },
  537: { got: [EXP2(3), AUTO(2), LEARN2(2), FIX(1), RESHAPE(1)], exp: 100000 },
  538: { got: [EGG("小灵龙", 994), I("性格改造-攻击", 414), TALENT(2), LEARN2(2)], exp: 100000 },
  540: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 100000 },
  542: { got: [EGG("奇奇", 1081), FIX(1), AUTO(1), EXP2(2)], exp: 150000 },
  554: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 100000 },
  562: { got: [I("灵之剑魂", 567), EXP3(2), AUTO(2), LEARN2(3)], exp: 150000 },
  563: { got: [I("王之剑魂", 566), FIX(1), TALENT(6)], exp: 150000 },
  564: { got: [I("光之剑魂", 565), BALL(1), RESHAPE(1), ...NATURE5], exp: 150000 },
  572: { got: [EGG("小米", 1166), FIX(1), AUTO(1), EXP2(2)], exp: 150000 },
  573: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 100000 },
  582: { got: [EXP3(2), AUTO(2), RADAR(2), TALENT(2)], exp: 100000 },
  588: { got: [EXP3(3), ...NATURE5, TALENT(6)], exp: 150000 },
  593: { got: [EGG("乐乐", 1239), FIX(1), RESHAPE(2)], exp: 150000 },
  594: { got: [EXP3(2), AUTO(2), LEARN2(2), TALENT(2)], exp: 100000 },
  601: { got: [EXP3(2), AUTO(2), RADAR(2), TALENT(2), LEARN2(3)], exp: 100000 },
  602: { got: [I("特攻果实", 527, 17), I("体力果实", 524, 17), EXP3(2), AUTO(2), LEARN2(2)], exp: 100000 },
  605: { got: [TALENT(2), AUTO(2), EXP3(2), I("攻击果实", 525, 17), I("防御果实", 526, 17)], exp: 88000 },
  606: { got: [AUTO(3), LEARN2(3), RADAR(3), EXP3(2), EXP2(2)], exp: 100000 },
  607: { got: [TALENT(6), ...NATURE5, ...FORGET6(1)], exp: 150000 },
  611: { got: [EGG("小幻", 1292), I("幻雷进化石", 616), I("幻雷•迅雷闪", 619), I("性格改造-特攻", 416)], exp: 100000 },
  612: { got: [EGG("小幻", 1292), I("幻炎进化石", 614), I("幻炎•爆炎斩", 617), I("性格改造-攻击", 414)], exp: 100000 },
  613: { got: [EGG("小幻", 1292), I("幻流进化石", 615), I("幻流•御流术", 618), I("性格改造-防御", 415)], exp: 100000 },
  626: { got: [TALENT(2), EXP3(2), AUTO(2), RADAR(2), RESHAPE(3)], exp: 100000 },
  630: { got: [TALENT(2), EXP3(2), AUTO(2), LEARN2(2), RESHAPE(3)], exp: 100000 },
  633: { got: [EXP3(2), EXP2(2), AUTO(2), RADAR(2), FIX(1)], exp: 100000 },
  634: { got: [LEARN2(4), I("特攻果实", 527, 30), I("速度果实", 529, 30), ...FORGET6(1), ["速度之勇者卡", 8, 24, 1]], exp: 150000 },
  635: { got: [TALENT(10), BALL(1), I("性格改造-特攻", 416, 5), ["超攻之勇者卡", 8, 33, 1]], exp: 200000 },
  644: { got: [EXP3(2), RESHAPE(2), LEARN2(2), RADAR(2), AUTO(3)], exp: 100000 },
  659: { got: [I("摇摇果实", 419, 50), I("高级摇摇果实", 664, 15), EXP2(2)] },
  660: { got: [I("摇摇果实", 419, 80), I("高级摇摇果实", 664, 40), EXP2(2)] },
  661: { got: [I("摇摇果实", 419, 100), I("高级摇摇果实", 664, 30), I("超级摇摇果实", 665), EXP3(2)] },
  662: { got: [RADAR(4)], score: 88888 },
};

export interface GiftOwner {
  items?: Record<string, Record<string, number>>;
  score?: number;
  robot?: { exp: number };
  /** A bag's 经验 bought before the HELLO came (normalise gives it to the HELLO). */
  helloExp?: number;
  /** The bags bought at least once (for their first-time 龙珠). */
  giftBags?: number[];
}

export interface Opened {
  /** onAmountUpdated parts ("type_id_0_n"). */
  amounts: string[];
  /** What came out, for the player ("三倍经验器×2"…). */
  got: string[];
  /** 晶币 changed (onScoreUpdated). */
  score: boolean;
}

/** Whether a material is a bag this file opens. */
export function isGiftBag(type: string | number, id: string | number): boolean {
  return String(type) === "2" && GIFT_BAGS[Number(id)] !== undefined;
}

/**
 * Open count bags of id: what they hold into o (an item at most cap(type, id) of it; clothes one).
 * undefined when id is no bag of this file.
 */
export function openGiftBag(o: GiftOwner, id: number, count = 1, cap?: (type: string, id: string) => number): Opened | undefined {
  const bag = GIFT_BAGS[id];
  if (!bag || count <= 0) return undefined;
  const out: Opened = { amounts: [], got: [], score: false };
  const delta = new Map<string, number>();
  const give = ([name, type, mi, n]: Gift, times: number) => {
    const t = String(type);
    const k = String(mi);
    const owned = ((o.items ??= {})[t] ??= {});
    const max = t === "0" ? 1 : Math.max(1, cap?.(t, k) ?? 9999);
    const before = owned[k] ?? 0;
    const after = Math.min(max, before + n * times);
    if (after > before) {
      owned[k] = after;
      delta.set(`${t}_${k}`, (delta.get(`${t}_${k}`) ?? 0) + after - before);
    }
    if (name) out.got.push(`${name}×${n * times}`);
  };
  const seen = (o.giftBags ??= []);
  if (bag.first && !seen.includes(id)) give(bag.first, 1);
  if (!seen.includes(id)) seen.push(id);
  for (const g of bag.got) give(g, count);
  if (bag.score) {
    o.score = Math.min(MONEY_MAX, (o.score ?? 0) + bag.score * count);
    out.score = true;
    out.got.push(`晶币×${bag.score * count}`);
  }
  if (bag.exp) {
    if (o.robot) o.robot.exp += bag.exp * count;
    else o.helloExp = (o.helloExp ?? 0) + bag.exp * count;
    out.got.push(`经验×${bag.exp * count}`);
  }
  out.amounts = [...delta].map(([k, n]) => `${k}_0_${n}`);
  return out;
}

/** The bags an older save holds, opened (a save from before bags opened when bought). */
export function openHeldGiftBags(o: GiftOwner): void {
  const items = o.items?.["2"];
  if (items) {
    for (const [k, n] of Object.entries(items)) {
      if (!isGiftBag(2, k) || !(n > 0)) continue;
      delete items[k];
      openGiftBag(o, Number(k), n);
    }
  }
  if (o.helloExp && o.robot) {
    o.robot.exp += o.helloExp;
    delete o.helloExp;
  }
}
