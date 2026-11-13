// The story quests' fights with a character's team: PetFightTypes.FIGHT_WITH_NPC_TEAM (17), sent as
// PetExtension 54_22 {type: 17, npc} (taskext/task1549 … task3346; 黑暗之念's task1427 sends {}; the
// 幻龙星系 scripts' FightManager sends it for a "fight_<x>_3_<team>" of their conversations), a
// fight of 大地迷城 sent as {type: 48, id: 2} (task3148's FightManager, case 4), and 魔幻摩卡's of
// 魔法星 (task1995: {type: 21, r: "10699", l: "100"}). The scripts finish their step themselves
// (10-2) once the fight is won, or carry on either way (task1995).
//
// The 2013 server's teams are lost (the client only names them by number, 1 to 42). RECONSTRUCTED
// from the scripts: who speaks before the fight and is beaten in it (their conversations, the NPCs
// they take away after a win, the names of the scripts' fight functions: fightYueMo,
// teamFightWithSteelDaLu, fightToRobotRabbit …), each as its own 亚比 where it is one (月魔, 凯撒,
// 超T兔, 夜王狄米特 …), else its 亚比 (哈鲁达's SR战士, 古力德's three, the 通灵巫师). As the task 亚比 are
// (battle.ts 54_2), they fight at the level of the player's strongest 亚比 (at least 5; the
// quest's last foe two more), are not caught, and only while their quest is being done.

import type { World } from "./server.ts";
import { addActFight, type ActFight } from "./battle.ts";
import { isDoing, type TaskOwner } from "./tasks.ts";
import type { PetOwner } from "./pets.ts";

export const FIGHT_WITH_NPC_TEAM = 17;
/** 大地迷城's fight beside 施瓦辛格, 友人契约书 and 多古拉伯爵 against 黑炎龙 (task3148). */
export const FIGHT_TYPE_48 = 48;
/** A fight with a 亚比 a script names with its level (task1995: 魔幻摩卡 at Lv100). */
export const FIGHT_TYPE_21 = 21;

export interface NpcTeam {
  /** The quest whose script fights it. */
  quest: number;
  /** Who fights: the first, then the others one after another (species). */
  team: number[];
  /** The quest's great foe: two levels more. */
  boss?: boolean;
}

/** FIGHT_WITH_NPC_TEAM's teams by number (RECONSTRUCTED; 27, 28, 32, 36, 37, 40 and 41 are no surviving script's). */
export const NPC_TEAMS: Record<number, NpcTeam> = {
  // 蔓藤峡谷: 念 makes everyone its servants (1426; 维克, 哈德 and 念 leave after the win).
  1: { quest: 1427, team: [461] },
  // 念 again, weaker now (1554, 黑暗力量).
  2: { quest: 1549, team: [461] },
  // 幽暗冥洲: "让我来测试一下你们的实力吧！" (1572).
  3: { quest: 1570, team: [603] },
  // 黑化战无炎 (1584), then 念 itself (1586_fightNian).
  4: { quest: 1581, team: [111] },
  5: { quest: 1581, team: [604], boss: true },
  // 月亮之殿: the 守护者 月魔 makes (冰拳艾司, 金刚库巴; 1610), then 月魔 (1613).
  6: { quest: 1606, team: [87, 96] },
  7: { quest: 1606, team: [327], boss: true },
  // 念之领域: 念 (1645), then 邪念 (1646).
  8: { quest: 1641, team: [604] },
  9: { quest: 1641, team: [605], boss: true },
  // 哈鲁达's 优化SR战士 (1715 and again 1716).
  10: { quest: 1711, team: [328, 328] },
  // 木面仔 who will not wear the mask (fightWithMuMian, 1845).
  11: { quest: 1843, team: [91, 93] },
  // 哈鲁达 at the 独角兽 kingdom (fightWithHaluda2, 1875).
  12: { quest: 1867, team: [329, 328], boss: true },
  // "SR战士，消灭他们！" (1922, the 丑小鸭's story).
  13: { quest: 1915, team: [328, 329] },
  // 钢铁达鲁 (teamFightWithSteelDaLu, 1952).
  14: { quest: 1946, team: [324], boss: true },
  // 古力德 and his numbers for the 海枯之石 (2055).
  15: { quest: 2055, team: [503, 504, 328] },
  // 凯撒, with 神武月 and 战无炎 (2183), at 奇灵树 (2227), after 多克特's potion (2236), and once 修罗 is freed (2242).
  16: { quest: 2183, team: [728], boss: true },
  17: { quest: 2227, team: [728], boss: true },
  18: { quest: 2236, team: [728] },
  19: { quest: 2236, team: [728], boss: true },
  // 邪恶超T兔, 糖先生's machine (fightToRobotRabbit, 2438).
  20: { quest: 2434, team: [865], boss: true },
  // The 通灵巫师 of 风车谷 (2503, 2509), stronger in their dark place (2511).
  21: { quest: 2499, team: [869, 869] },
  22: { quest: 2507, team: [869, 869, 869] },
  23: { quest: 2507, team: [869, 869, 869], boss: true },
  // 凯撒 against 修罗 (2557), against 泽时 and 修罗 (2593), weakened by 修罗流光斩 (2595).
  24: { quest: 2552, team: [728], boss: true },
  25: { quest: 2592, team: [728] },
  26: { quest: 2592, team: [728], boss: true },
  // 红魔 of the 永夜族 (2912).
  29: { quest: 2906, team: [973], boss: true },
  // 夜王's three generals and the 通灵巫师 (2941), then 夜王狄米特 (2944).
  30: { quest: 2940, team: [973, 1086, 946, 869] },
  31: { quest: 2940, team: [1124], boss: true },
  // 黑皮 (3026), and 黑皮's many against 飞灵 and 乐乐 (3031).
  33: { quest: 3022, team: [1182] },
  34: { quest: 3022, team: [1183, 1182], boss: true },
  // 黑•拉诺斯, the 天空之神 taken by the dark (3093, 3094).
  35: { quest: 3091, team: [1234], boss: true },
  // 多古拉伯爵, who gave 辛格 to 古力德 (3132's fight_1245_3_38_WithComte).
  38: { quest: 3132, team: [1267], boss: true },
  // The 迦娜 and 波波嘟 of 伊泽's dream (3252's fight_3257_WithJanaAndBoBoDu).
  39: { quest: 3252, team: [1322, 1286], boss: true },
  // The 绿萝花 the dark sets on 风翼 and 铁迪 (3346's fight_3351_WithDarkPet).
  42: { quest: 3346, team: [1416, 1416, 1416], boss: true },
};

/** Type 48's: 黑炎龙 (task3148's fight_4_48_2_WithBlackDragon). */
export const TYPE_48_TEAMS: Record<number, NpcTeam> = {
  2: { quest: 3148, team: [1426], boss: true },
};

/** Type 21's: the 亚比 and level a script names, while its quest is being done. */
export const TYPE_21_FIGHTS: { quest: number; race: number; level: number }[] = [
  // 魔幻摩卡 of 魔法星 (2003): won or lost, the story goes on (200303 / 200302).
  { quest: 1995, race: 10699, level: 100 },
];

export const NOT_NOW = "这个挑战现在还不能进行哦！";

/** The level a quest's team fights at: the player's strongest 亚比's (at least 5), the boss two more. */
export function teamLevel(o: PetOwner, boss?: boolean): number {
  const top = Math.max(5, ...(o.pets ?? []).map((p) => p.level | 0));
  return Math.min(100, top + (boss ? 2 : 0));
}

/** The fight of a team, or why not: its quest must be being done. */
export function teamFight(o: PetOwner, team: NpcTeam | undefined): ActFight | string {
  if (!team || !isDoing(o as TaskOwner, team.quest)) return NOT_NOW;
  const level = teamLevel(o, team.boss);
  const [lead, ...rest] = team.team;
  return { race: lead, level, team: rest.map((race) => ({ race, level: teamLevel(o) })) };
}

export function installQuestFights(world: World): void {
  addActFight(world, FIGHT_WITH_NPC_TEAM, (ctx, o) => {
    // task1427 names no team: 念's, the only one fought so.
    const asked = ctx.params.npc ?? ctx.params.id;
    const n = asked === undefined || asked === "" ? 1 : Number(asked) | 0;
    return teamFight(o, Object.hasOwn(NPC_TEAMS, n) ? NPC_TEAMS[n] : undefined);
  });
  addActFight(world, FIGHT_TYPE_48, (ctx, o) => {
    const n = Number(ctx.params.id) | 0;
    return teamFight(o, Object.hasOwn(TYPE_48_TEAMS, n) ? TYPE_48_TEAMS[n] : undefined);
  });
  addActFight(world, FIGHT_TYPE_21, (ctx, o) => {
    const race = Number(ctx.params.r) | 0;
    const f = TYPE_21_FIGHTS.find((x) => x.race === race && isDoing(o as TaskOwner, x.quest));
    return f ? { race: f.race % 10000, level: f.level, asked: f.race } : NOT_NOW;
  });
}
