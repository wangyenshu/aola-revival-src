// The 四大副本 (奥拉战记, 2011–12): FBExtension (the 2013 FbClient, fb_1 … fb_8, and
// the later fb_9 the later choose panel asks) and the battles in the rooms
// (PetClient2.fightInCopy {id}, PetExtension 54_17). The client side is the later
// fbservice / fbteam modules and the 2016 choose panel on the 2013 libraries.
//
// The 2013 server and its tables are lost. What the client fixes is kept: the four
// 副本 and their rooms (FbID: 0 fbaixi 幻影冰宫, 1 fbsuolide 倒立金字塔, 2 fbsiwude
// 蚁族王朝, 3 fbyishuzhidu 恐龙博物馆), the three modes (简单, 困难, 传奇: the level the
// client asks), the replies' fields (succ, pms, fin/bn/gr/tm, gr "S;#;#", g/lt/bt),
// and, room by room, the fights. Each room's fbteam script (the rooms the team route
// walks: FbAixiConfig, FbSuolideConfig, FbSiwudeConfig, FbYishuzhiduConfig) says
// which fightInCopy(id) it starts, how many and when; the 亚比 behind each id is the
// one the room shows there (its scene's symbols: the clicked figure, the NPC whose
// talk starts the fight, whose head is the species' art):
//   幻影冰宫 wanderers (fb_3, FbWildPetConfig fbaixi1, 2, 3, 6): the tips name 埃黑多夫 and
//     冰沙斗士 for fbaixi2; fbaixi3 opens its first door after three of 10421 / 10415
//     (120421 / 120415 harder), its second when all are down; fbaixi6 when all are down.
//     fbaixi4: 变异库斯特 (NPC 602's talk names it), fbaixi8: 尤莱亚 (NPC 84), fbaixi9:
//     拉贝尔幻影, told 10999 / 120999.
//   倒立金字塔 fbsuolide1: the four 圣甲虫 (Monster1–4) 阿努比斯 calls, one fight; 2: the
//     石像迷阵, a fight for each statue flagstone turned (ids 1, 2 … one more after each
//     win: up to the nine of the grid); 3: the 木乃伊之棺, a mummy (帕克) in three of the
//     five coffins, ids 1–3; 4: 阿努比斯; 6: the wooden and the earthen ones, 扭扭大王 60 and
//     斯多王 72 (ScenePetAvatar); 7: the coin slot's 夜眼风魔 (1, 10 晶币) and 沙麒麟 (2, 100
//     晶币), 曼珠沙华 (3); 8: 机械木乃伊; 9: 法老王.
//   蚁族王朝 (team route 1–6, 9–11; 7 and 8 are not walked): fbsiwude1 and 2, three 兵蚁 each
//     (NPC 644); 3: three 牛角滴滴 at the doors (NPC 645); 4: 毒菇球 (npc_0, NPC 190),
//     金刚蛤蟆 (npc_1, 191), 下水猛鳄 (npc_2 by the chest, 192); 5: the 工蚁 (Ant); 6: the two
//     statues, 守护力士 and 守护法师 (NPC 162 / 163), one fight: one of the two in turn, by the
//     run of the day; 9: 蚁族圣斗士 (ant_0) and 魔斗士 (ant_1); 10: btnPet_1 保斯, 2 兰斯罗特,
//     3 哥拉海德, 4 贝德威尓; 11: the 蚁将军's 小弟 (1), the 蚁将军 (2), the 变异蚁将军 (3).
//   恐龙博物馆 fbyishuzhidu1: the 迅猛龙; 2: 梁龙 30401, 翼龙 30402, 鱼龙 30403 (the ids its
//     script checks); 3: 霸王龙; 4: the archer, 星辰毁灭者.
// RECONSTRUCTED: which wanderers stand in fbaixi1, 3 and 6 beyond what the doors count
// (冰沙斗士 at the gate; 冰火巨人 and 冰摩格, the ice palace's other 亚比), the species of
// fbsiwude11's 小弟 (the script names none; the 兵蚁 who guard the 蚁族王朝), the levels,
// the rewards, the rating, the entries a day.

export type FbRoom = {
  /** The room's wandering 亚比 (fb_3), species; the client places as many as it has spots for. */
  wild?: number[];
  /**
   * The room script's fights (fightInCopy(id)): species, or a full id (variant * 10000 + species) kept
   * as it is; a list: one of them, in turn by the run of the day (fbsiwude6's two statues, one fight).
   */
  fights?: Record<number, number | number[]>;
  /** The fights that are the room's boss: a few levels above the rest. */
  boss?: number[];
};

export type FbDef = { name: string; title: string; levels: [number, number, number]; rooms: Record<string, FbRoom> };

/** The fights first … last against one species (a room that numbers its fights one after another). */
const each = (first: number, last: number, species: number): Record<number, number> =>
  Object.fromEntries(Array.from({ length: last - first + 1 }, (_, i) => [first + i, species]));

/** The ids of the bosses whose species the 2013 tables lack (later 副本 bosses): the species that stands in for them in battle. */
export const FB_STANDIN: Record<number, number> = {};

/**
 * Bosses the 2013 tables lack, made for the battle (their battle sprites are on the CDN:
 * fightassets/pet999, 拉贝尔幻影 of the ice palace's 风暴核心): name, and the species whose
 * numbers they borrow (冰铠力士; RECONSTRUCTED).
 */
export const FB_EXTRA_SPECIES: Record<number, { n: string; like: number }> = { 999: { n: "拉贝尔幻影", like: 899 } };

export const FBS: FbDef[] = [
  {
    name: "fbaixi",
    title: "幻影冰宫",
    levels: [30, 55, 75],
    rooms: {
      // fbaixi3: the first three of 冰沙斗士 / 埃黑多夫 open the first door, all six the second.
      fbaixi1: { wild: [421, 421, 421] },
      fbaixi2: { wild: [415, 421, 415, 421, 415] },
      fbaixi3: { wild: [421, 415, 421, 466, 448, 466] },
      // 水晶密室's 变异库斯特, then 尤莱亚 and 拉贝尔幻影 in the 风暴核心.
      fbaixi4: { fights: { 1: 463 }, boss: [1] },
      fbaixi6: { wild: [448, 466, 448, 466, 448] },
      fbaixi8: { fights: { 1: 249 }, boss: [1] },
      fbaixi9: { fights: { 1: 999 }, boss: [1] },
    },
  },
  {
    name: "fbsuolide",
    title: "倒立金字塔",
    levels: [35, 60, 80],
    rooms: {
      fbsuolide1: { fights: { 1: 210 } },
      // 石像迷阵: a 石像守卫 for each statue flagstone turned, numbered on (the grid has nine).
      fbsuolide2: { fights: each(1, 9, 213) },
      // 木乃伊之棺: 帕克 in three of the five coffins.
      fbsuolide3: { fights: each(1, 3, 304) },
      fbsuolide4: { fights: { 1: 238 }, boss: [1] },
      // 土木战场: 扭扭大王 (wood) and 斯多王 (earth); the single 副本's script told them 30060 / 30072.
      fbsuolide6: { fights: { 1: 30060, 2: 30072 } },
      // 莎华之间: the coin slot's 夜眼风魔 (10 晶币) and 沙麒麟 (100), and 曼珠沙华.
      fbsuolide7: { fights: { 1: 81, 2: 90, 3: 272 }, boss: [3] },
      fbsuolide8: { fights: { 1: 340 }, boss: [1] },
      fbsuolide9: { fights: { 1: 240 }, boss: [1] },
    },
  },
  {
    name: "fbsiwude",
    title: "蚁族王朝",
    levels: [40, 65, 85],
    rooms: {
      // 蚁穴入口 and the searchlights: three 兵蚁 each.
      fbsiwude1: { fights: each(1, 3, 216) },
      fbsiwude2: { fights: each(1, 3, 216) },
      // 蚁穴下水道: three 牛角滴滴 at the doors.
      fbsiwude3: { fights: each(1, 3, 244) },
      // The 蚁将军's treasure: 毒菇球, 金刚蛤蟆, 下水猛鳄 (the boss of the place, by the chest).
      fbsiwude4: { fights: { 1: 241, 2: 242, 3: 243 }, boss: [3] },
      // 工蚁聚集地.
      fbsiwude5: { fights: { 1: 217 } },
      // 蚁神守护大厅: the two statues, 守护力士 and 守护法师; one fight, one of them in turn.
      fbsiwude6: { fights: { 1: [218, 219] }, boss: [1] },
      // 蚁神巨像: 蚁族圣斗士 and 魔斗士 on either side.
      fbsiwude9: { fights: { 1: 220, 2: 221 } },
      // The 女王守护骑士: 保斯, 兰斯罗特, 哥拉海德, 贝德威尓 (btnPet_1 … 4).
      fbsiwude10: { fights: { 1: 225, 2: 223, 3: 224, 4: 222 } },
      // The 蚁将军's 小弟, the 蚁将军, the 变异蚁将军 (FBSiwude11_5FightWithAberrance).
      fbsiwude11: { fights: { 1: 216, 2: 226, 3: 227 }, boss: [2, 3] },
    },
  },
  {
    name: "fbyishuzhidu",
    title: "恐龙博物馆",
    levels: [40, 65, 85],
    rooms: {
      // 迅猛龙, 龙之谷 (the script's 梁龙 30401, 翼龙 30402, 鱼龙 30403), 暴君王座's 霸王龙,
      // 龙殇墓地's 射手座 (星辰毁灭者).
      fbyishuzhidu1: { fights: { 1: 400 } },
      fbyishuzhidu2: { fights: { 1: 30401, 2: 30402, 3: 30403 } },
      fbyishuzhidu3: { fights: { 1: 404 }, boss: [1] },
      fbyishuzhidu4: { fights: { 1: 405 }, boss: [1] },
    },
  },
];

/** Entries a day for each 副本 (the panel's MAX_TIMES; RECONSTRUCTED). */
export const FB_TIMES = 5;

export const fbByName = (name: string): FbDef | undefined => FBS.find((f) => f.name === name);
export const fbOfRoom = (room: string): FbDef | undefined => FBS.find((f) => room.startsWith(f.name) && /^\d+$/.test(room.slice(f.name.length)));

/** The id a fight is told by (FIGHT_END raceId): variant 1 for 简单, 12 for the harder modes, as the client's checks read them. */
export function fbCode(species: number, mode: number): number {
  if (species >= 10000) return species;
  return (mode > 0 ? 12 : 1) * 10000 + species;
}

/** Add the bosses the 2013 tables lack (FB_EXTRA_SPECIES) to the species tables, once. */
export function ensureFbSpecies(pm: { species: Record<string, unknown> }): void {
  for (const [id, x] of Object.entries(FB_EXTRA_SPECIES)) {
    if (pm.species[id] || !pm.species[String(x.like)]) continue;
    pm.species[id] = { ...(pm.species[String(x.like)] as object), n: x.n, c: ["NA", "NA"], evo: "" };
  }
}

/** The species a coded id fights as (a boss the 2013 tables lack stands in as another). */
export function fbSpecies(code: number): number {
  const s = code >= 100000 ? code % 10000 : code >= 10000 ? code % 10000 : code;
  return FB_STANDIN[s] ?? s;
}

/**
 * A room's 亚比 at a mode: wanderers numbered 1… (fb_3) and the script's fights by their ids. run: the
 * run of the day (0 the first), which of a list a fight takes.
 */
export function fbRoomPets(def: FbDef, room: string, mode: number, run = 0): { id: number; code: number; lv: number }[] {
  const r = def.rooms[room];
  if (!r) return [];
  const base = def.levels[Math.max(0, Math.min(2, mode))];
  const deep = Number(room.slice(def.name.length)) || 1;
  const lv = (i: number) => Math.min(100, base + Math.floor(deep / 2) + (i % 3));
  if (r.wild) return r.wild.map((s, i) => ({ id: i + 1, code: fbCode(s, mode), lv: lv(i) }));
  return Object.entries(r.fights ?? {}).map(([k, f]) => {
    const id = Number(k);
    const s = Array.isArray(f) ? f[Math.max(0, run) % f.length] : f;
    return { id, code: fbCode(s, mode), lv: Math.min(100, lv(id) + (r.boss?.includes(id) ? 6 : 3)) };
  });
}

/** The rating of a run by its time (seconds; RECONSTRUCTED, the later client counts 11 minutes down). */
export function fbGrade(seconds: number): string {
  if (seconds <= 5 * 60) return "SSS";
  if (seconds <= 8 * 60) return "S";
  if (seconds <= 11 * 60) return "A";
  if (seconds <= 15 * 60) return "B";
  return "C";
}

const GRADE_ORDER = ["#", "C", "B", "A", "S", "SSS"];
export const betterGrade = (a: string, b: string) => (GRADE_ORDER.indexOf(b) > GRADE_ORDER.indexOf(a) ? b : a);

/** The 晶币 a finished run pays (RECONSTRUCTED): by mode, more for a better rating. */
export function fbPay(mode: number, grade: string): number {
  const base = [600, 1200, 2000][Math.max(0, Math.min(2, mode))];
  return Math.round(base * (1 + 0.25 * Math.max(0, GRADE_ORDER.indexOf(grade) - 1)));
}

/** Whether a run has beaten the boss of its 副本's last room (then it may finish: fb_4). */
export function fbBossBeaten(cur: NonNullable<FbRec["cur"]>): boolean {
  const def = FBS.find((d) => d.name === cur.name);
  if (!def) return false;
  const rooms = Object.entries(def.rooms).filter(([, r]) => r.boss?.length);
  if (!rooms.length) return true;
  const [last, room] = rooms[rooms.length - 1];
  const dead = cur.dead[last] ?? [];
  return room.boss!.every((id) => dead.includes(id));
}

export type FbRec = {
  day?: string;
  /** Entries used today, by 副本 id. */
  used?: Record<string, number>;
  /** Best rating by 副本 id: [简单, 困难, 传奇]. */
  best?: Record<string, string[]>;
  /** The run now: 副本, mode, its start (game clock ms), the 亚比 beaten by room, the chests opened, the run of the day (1…). */
  cur?: { id: number; name: string; lv: number; start: number; dead: Record<string, number[]>; chests: string[]; n?: number } | null;
};
