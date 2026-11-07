// The clothes some bosses of 2012 left behind for the winner, now and then: one part of their suit
// the player does not have yet (the suits of the 2013 ClothesData, material type 0).
//
// 守护者服装: "绝版守护者组团来贺周年庆啦！猪猪超人、极速威锋、时间之神、赤魔导士都来了，挑战成功可以获得
// 守护者亚比蛋，还有可能拿到守护者服装哦！！" (奥拉周刊 103, July 2012); "现在战胜金刚库巴还有机会获得守护者
// 服装哦！" (activityres/petvote, October 2012). The 守护者 of the revival's table (battle.ts GUARDIANS,
// fought with 54_16) whose own suit the 2013 data has, by species: those five, and 天使莱特, 冰拳艾司,
// 沙麒麟, 木面侠, 黑夜童心, 神武月, 战无炎, 天女若希, whose suits carry their names (inferred: no page of
// theirs that survives names the drop).
// 武神服装: "收集各位武神将军掉落的武神服装，就能获得稀有称号——武神战将" (奥拉周刊 104, August 2012): the
// 武神套装 (uploaded 2 August 2012) from the generals of 武神大陆 (fightking.ts).
//
// The 2012 server is lost: the chance (COSTUME_CHANCE a win) is RECONSTRUCTED; the title is not kept
// (the revival has no titles).

import type { Msg } from "./battle.ts";

/** battle.ts NOTE: words and a bonus for the end of the battle (kept here: battle.ts imports this module). */
const NOTE = "revival_note";

export const COSTUME_CHANCE = 0.2;

/** Suits of the 2013 ClothesData: id -> [name, {part: name}]. */
export const SUITS: Record<number, [string, Record<number, string>]> = {
  115: ["时间之神套装", { 732: "时间守护头盔", 733: "时间之神守护装", 734: "时间之神下装", 735: "时间之神守护靴" }],
  118: ["天使莱特套装", { 756: "天使莱特头盔", 757: "天使莱特护甲", 758: "天使莱特铅笔裤", 759: "天使莱特之靴", 760: "天使莱特之翼", 761: "天使莱特守护剑" }],
  123: ["神武月套装", { 785: "神武古银发", 786: "月牙彩绘", 787: "月华披风", 788: "月华长裤", 789: "月华之靴", 790: "月华杖" }],
  125: ["战无炎套装", { 796: "赤炎彩绘", 797: "赤炎之发", 798: "赤炎披风", 799: "赤炎之靴", 800: "赤炎锋刃" }],
  133: ["冰拳艾司套装", { 853: "冰刺寒发", 854: "冰刺闪电脸妆", 855: "冰刺铠甲", 856: "冰刺长裤", 857: "冰刺长靴" }],
  138: ["沙麒麟套装", { 881: "麒麟沙尘发", 882: "沙麒麟之角", 883: "麒麟长刺甲", 884: "沙麒麟长裤", 885: "麒麟长刺靴", 886: "麒麟阔斧" }],
  146: ["极速威锋套装", { 937: "极速威锋帽", 938: "极速蓝光服", 939: "极速火焰裤", 940: "极速滑轮鞋" }],
  153: ["木面侠套装", { 978: "木叶假面", 979: "青木侠士盔甲", 980: "木叶长裤", 981: "木叶侠士靴", 982: "木叶花剑" }],
  162: ["金刚库巴套装", { 1032: "库巴爆炸绿发", 1033: "库巴金刚刺甲", 1034: "库巴坚甲裤", 1035: "库巴绿宝靴", 1036: "库巴利刺坚盾" }],
  166: ["黑夜童心套装", { 1057: "童话双色帽", 1058: "童话枫叶长袍", 1059: "双色条纹裤", 1060: "童话V形靴", 1061: "三色童话笔" }],
  195: ["赤魔导士套装", { 1218: "赤魔之冠", 1219: "导士之金发", 1220: "赤魔獠牙披风", 1221: "赤魔权杖", 1222: "金甲长裤", 1223: "赤魔之靴" }],
  216: ["猪猪超人套装", { 1353: "猪猪无敌头盔", 1354: "猪猪超人服", 1355: "超人长裤", 1356: "猪猪动感靴", 1357: "呼噜小怪兽" }],
  258: ["武神套装", { 1619: "武神头盔", 1620: "武神战甲", 1621: "武神长裤", 1622: "武神战靴", 1623: "武神利剑" }],
  266: ["天女若希套装", { 1664: "若希头盔", 1665: "若希长发", 1666: "若希长羽裙", 1667: "若希长羽靴", 1668: "若希魔法杖", 1669: "若希羽翼" }],
};

/** 守护者 by species -> its suit. 时间之神 is fought in its first form, 小时 (10112, 20112). */
export const GUARDIAN_SUITS: Record<number, number> = {
  112: 115, 114: 115, 317: 118, 105: 123, 111: 125, 87: 133, 90: 138, 633: 146, 93: 153, 96: 162, 682: 166, 796: 195,
  884: 216, 819: 266,
};

/** The generals of 武神大陆 (fightking.ts GENERALS): 关羽, 赵云, 张飞, 诸葛亮, 吕布, 刘备. */
export const WUSHEN_SUIT = 258;
export const WUSHEN_RACES = [860, 931, 955, 976, 1108, 1225];

export interface CostumeOwner {
  items?: Record<string, Record<string, number>>;
}

/**
 * After a win against a boss of a suit: by chance, one part of it the player lacks (into the
 * wardrobe, onAmountUpdated type 0, and the end of the battle shows it). Nothing once all are had.
 */
export function costumeDrop(o: CostumeOwner, suit: number | undefined, rng: () => number, chance = COSTUME_CHANCE): Msg[] {
  const s = suit === undefined ? undefined : SUITS[suit];
  if (!s) return [];
  const clothes = ((o.items ??= {})["0"] ??= {});
  const lacking = Object.keys(s[1]).map(Number).filter((id) => !clothes[String(id)]);
  if (!lacking.length || rng() >= chance) return [];
  const id = lacking[Math.floor(rng() * lacking.length) % lacking.length];
  clothes[String(id)] = 1;
  return [["onAmountUpdated", { amount: `0_${id}_0_1` }], [NOTE, { text: `获得了${s[1][id]}！`, bn: { type: 0, id, num: 1 } }]];
}
