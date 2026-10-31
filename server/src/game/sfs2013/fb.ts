// The 四大副本 (奥拉战记, 2011–12): FBExtension (the 2013 FbClient, fb_1 … fb_8, and
// the later fb_9 the later choose panel asks) and the battles in the rooms
// (PetClient2.fightInCopy {id}, PetExtension 54_17). The client side is the later
// fbservice / fbteam modules and the 2016 choose panel on the 2013 libraries.
//
// The 2013 server and its tables are lost. What the client code fixes is kept:
// the four 副本 and their rooms (FbID: 0 fbaixi 幻影冰宫, 1 fbsuolide 倒立金字塔,
// 2 fbsiwude 蚁族王朝, 3 fbyishuzhidu 恐龙博物馆), the three modes (简单, 困难, 传奇:
// the level the client asks), which rooms send 亚比 (fbteam FbWildPetConfig:
// fbaixi1, 2, 3, 6) and which fights each room's script starts (fightInCopy(1…4)),
// the ids some scripts check after a battle (幻影冰宫's door 亚比 10421 / 10415 and
// 120421 / 120415, its last boss 10999 / 120999; 恐龙博物馆's 梁龙 30401, 翼龙 30402,
// 鱼龙 30403), the replies' fields (succ, pms, fin/bn/gr/tm, gr "S;#;#", g/lt/bt).
// Which 亚比 stand in each room follows the 2010–11 guides (7k7k, 100bt, doyo; the
// research notes in docs/PLAN.md): 冰沙斗士 and 埃黑多夫 at the ice palace's gate,
// 冰火巨人 and 冰摩格, 变异库斯特, 尤莱亚 and 拉贝尔幻影; 圣甲虫, 石像守卫, 帕克,
// 阿努比斯, 扭扭大王 and 斯多王, 曼珠沙华, 机械木乃伊 and 法老王; 兵蚁, 工蚁, 守护力士,
// 守护法师 and 影刃, 下水猛鳄, 圣斗士 and 魔斗士, the four 天王, 蚁将军 and 变异蚁将军;
// 迅猛龙, 梁龙, 翼龙, 鱼龙, 霸王龙 and 星辰毁灭者. Where a room's fights are more than
// the guides name, and everything else (levels, rewards, the rating, the entries a
// day), RECONSTRUCTED.

export type FbRoom = {
  /** The room's wandering 亚比 (fb_3), species; the client places as many as it has spots for. */
  wild?: number[];
  /** The room script's fights (fightInCopy(id)): species, or a full id (variant * 10000 + species) kept as it is. */
  fights?: Record<number, number>;
};

export type FbDef = { name: string; title: string; levels: [number, number, number]; rooms: Record<string, FbRoom> };

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
      // 变异库斯特 (the upper branch), 尤莱亚, then 拉贝尔幻影 in the 风暴核心.
      fbaixi4: { fights: { 1: 463 } },
      fbaixi6: { wild: [448, 466, 448, 466, 448] },
      fbaixi8: { fights: { 1: 249 } },
      fbaixi9: { fights: { 1: 999 } },
    },
  },
  {
    name: "fbsuolide",
    title: "倒立金字塔",
    levels: [35, 60, 80],
    rooms: {
      // 沙漏密室's 圣甲虫, 石像迷阵's 石像守卫, 木乃伊之棺's 帕克, 阿努比斯之门.
      fbsuolide1: { fights: { 1: 210 } },
      fbsuolide2: { fights: { 1: 213 } },
      fbsuolide3: { fights: { 1: 304 } },
      fbsuolide4: { fights: { 1: 238 } },
      // 土木战场: the single 副本's script checks 30060 (扭扭大王, wood) and 30072 (斯多王, earth).
      fbsuolide6: { fights: { 1: 30060, 2: 30072 } },
      // 莎华之间: 曼珠沙华; its coin slot's 夜眼风魔 and 沙麒麟.
      fbsuolide7: { fights: { 1: 272, 2: 90, 3: 272 } },
      fbsuolide8: { fights: { 1: 340 } },
      fbsuolide9: { fights: { 1: 240 } },
    },
  },
  {
    name: "fbsiwude",
    title: "蚁族王朝",
    levels: [40, 65, 85],
    rooms: {
      // 蚁穴下水道's 兵蚁, 工蚁聚集地's 工蚁, 蚁神守护大厅's 守护力士, 守护法师 and 影刃.
      fbsiwude1: { fights: { 1: 216, 2: 216, 3: 216 } },
      fbsiwude2: { fights: { 1: 216, 2: 217, 3: 216, 4: 217, 5: 216, 6: 217 } },
      fbsiwude3: { fights: { 1: 217, 2: 217, 3: 217 } },
      fbsiwude4: { fights: { 1: 218, 2: 219, 3: 217 } },
      fbsiwude5: { fights: { 1: 217 } },
      fbsiwude6: { fights: { 1: 195 } },
      // 下水道深处's 毒菇球, 金刚蛤蟆 and 下水猛鳄.
      fbsiwude7: { fights: { 1: 241, 2: 242 } },
      fbsiwude8: { fights: { 1: 243 } },
      // 蚁神巨像: 圣斗士 and 魔斗士; the 四大天王.
      fbsiwude9: { fights: { 1: 220, 2: 221 } },
      fbsiwude10: { fights: { 1: 222, 2: 223, 3: 224, 4: 225 } },
      // 小蚁, the 蚁将军, then the 变异蚁将军 (FBSiwude11_5FightWithAberrance).
      fbsiwude11: { fights: { 1: 216, 2: 226, 3: 227 } },
    },
  },
  {
    name: "fbyishuzhidu",
    title: "恐龙博物馆",
    levels: [40, 65, 85],
    rooms: {
      // 迅猛龙巢穴, 龙之谷 (the script's 梁龙 30401, 翼龙 30402, 鱼龙 30403), 暴君王座's
      // 霸王龙, 龙殇墓地's 射手座 (星辰毁灭者).
      fbyishuzhidu1: { fights: { 1: 400 } },
      fbyishuzhidu2: { fights: { 1: 30401, 2: 30402, 3: 30403 } },
      fbyishuzhidu3: { fights: { 1: 404 } },
      fbyishuzhidu4: { fights: { 1: 405 } },
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

/** A room's 亚比 at a mode: wanderers numbered 1… (fb_3) and the script's fights by their ids. */
export function fbRoomPets(def: FbDef, room: string, mode: number): { id: number; code: number; lv: number }[] {
  const r = def.rooms[room];
  if (!r) return [];
  const base = def.levels[Math.max(0, Math.min(2, mode))];
  const deep = Number(room.slice(def.name.length)) || 1;
  const lv = (i: number) => Math.min(100, base + Math.floor(deep / 2) + (i % 3));
  if (r.wild) return r.wild.map((s, i) => ({ id: i + 1, code: fbCode(s, mode), lv: lv(i) }));
  return Object.entries(r.fights ?? {}).map(([id, s]) => ({ id: Number(id), code: fbCode(s, mode), lv: lv(Number(id)) + 3 }));
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

export type FbRec = {
  day?: string;
  /** Entries used today, by 副本 id. */
  used?: Record<string, number>;
  /** Best rating by 副本 id: [简单, 困难, 传奇]. */
  best?: Record<string, string[]>;
  /** The run now: 副本, mode, its start (game clock ms), the 亚比 beaten by room, the chests opened. */
  cur?: { id: number; name: string; lv: number; start: number; dead: Record<string, number[]>; chests: string[] } | null;
};
