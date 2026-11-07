// 我的荣誉 (the 徽章 of honour/honour_res's 我的徽章收集, HonourPanel; the 家园's 我的荣誉 opens it
// for the garden's owner) for the 2013 server. The commands are the era AchievementClient's:
//
//   76_7 {un, idlist}  -> {page, score, honor, rank, nn}   the panel's first page
//   76_8 {un, idlist}  -> {page}                           another page
//
//   idlist  the honours of the page, "id,id,…" (honour/honourservice's HonourConfig, 0–279)
//   page    "id=v,…": v "-1" got, else how far towards it (the panel greys the picture and its
//           tip shows v of the honour's time)
//   score   徽章分数: 钻石 40, 金 20, 银 10, 铜 5 (the panel's own lines), the honour's level
//           4, 3, 2, 1 (HonourConfig: 收集数量 10/100/1000/3000 are levels 1–4)
//   honor   how many of each level got, "铜,银,金,钻石" (p0–p3: the panel writes p3 by its 钻石)
//
// The 2013 server is lost and so is what it counted: which honours can be got here, and from
// what, is RECONSTRUCTED from what the record holds (HONOURS). The others (already 绝版 in 2013,
// or counting what is not kept: 擂台, 对战, 时空隧道, 小游戏, 职业) stay at 0.
//
// 勋章 (the era BadgeService's, materialdata BadgeData; the 家园 bar's 勋章 shows them in
// usercard/usercard_badge's BadgePanel):
//
//   70-1 {un}  -> {b: [{bi, gd}]}   the player's 勋章: id and when got (ms)
//
// Got from the 星辉任务 that give the 徽章 of the same name (STAR_TASKS: 勇气, 大地, 生命, 海洋,
// 烈焰), when that task was done; the others' tasks are not found (BADGE_TASKS, RECONSTRUCTED).

import { PLANTS, type PlantRec } from "./plants.ts";
import type { World } from "./server.ts";
import { zooLevel } from "./zoo.ts";

/** What an honour counts (HONOURS). */
type Rule =
  | "caught" // 收集数量: 亚比 got in all (the ids given out)
  | "full" // 满级亚比: 亚比 at level 100
  | "friends" // 好友数量
  | "love" // 爱心天使: 晶币 given to the 爱心协会
  | "trees" // 家园种植: trees at their last level
  | "zoo" // 动物园: the zoo's level
  | `task:${number}` // 星辉任务: the task that gives the badge done
  | `boss:${string}`; // 守护者: wins against it (bossWins)

/** [id, level (1 铜 … 4 钻石), how many, rule] */
const HONOURS: [number, number, number, Rule][] = [
  [1, 1, 10, "caught"], [2, 2, 100, "caught"], [3, 3, 1000, "caught"], [4, 4, 3000, "caught"],
  [5, 1, 1, "full"], [6, 2, 6, "full"], [7, 3, 20, "full"], [8, 4, 50, "full"],
  [33, 1, 10, "friends"], [34, 2, 200, "friends"], [35, 3, 500, "friends"],
  [40, 1, 1, "love"], [41, 2, 9000, "love"], [42, 3, 54000, "love"], [43, 4, 300000, "love"],
  [44, 1, 1, "trees"], [45, 2, 2, "trees"], [46, 3, 4, "trees"], [47, 4, 8, "trees"],
  [161, 1, 6, "zoo"], [162, 2, 16, "zoo"], [163, 3, 26, "zoo"],
];

// 星辉任务: the badge's honour -> the task the talk that gives it ends (the era task talks,
// TaskTalkData: "我现在特别授予你“生命徽章”" and the task of the answer after it). 勇气徽章: 完成新手任务
// (task 150, as the later garden checks it). Badges whose talk is not found are left out.
const STAR_TASKS: [number, number][] = [
  [145, 150], [147, 80], [148, 200], [149, 259], [150, 352], [174, 1824], [181, 1890], [186, 1954],
  [197, 2006], [206, 2146], [210, 2245], [226, 2358], [230, 2442], [239, 2516], [240, 2602], [241, 2700],
  [245, 2783], [249, 2852], [260, 3102], [267, 3158], [269, 3261],
];
for (const [id, task] of STAR_TASKS) HONOURS.push([id, 2, 1, `task:${task}`]);

/** BadgeData's 勋章 -> the task of the 星辉 徽章 of its name (honours 145, 147–150). */
export const BADGE_TASKS: [number, number][] = [[3, 150], [2, 80], [4, 200], [5, 259], [7, 352]];

// 守护者: three honours each (挑战…胜利 1, 10, 100 times; levels 1–3), the first id and the name.
const BOSSES: [number, string][] = [
  [77, "冰拳艾司"], [80, "沙麒麟"], [83, "木面侠"], [86, "金刚库巴"], [89, "火花龙"], [92, "合金猛将"], [95, "神武月"],
  [98, "烈焰鸟"], [101, "影刃"], [104, "雷纳瑞"], [107, "魂斗鱼"], [110, "浮云尊者"], [113, "年兽"], [116, "麦斗猪"],
  [119, "山脉之魂"], [122, "星光角斗士"], [139, "天使莱特"], [157, "战无炎"], [164, "极速威锋"], [171, "大黄蜂"],
  [175, "满月巨灵"], [178, "天之巨灵"], [183, "黑夜童心"], [198, "远古灵龟"], [203, "暴雪山神"], [207, "赤影飞狐"],
  [211, "赤魔导士"], [214, "时间之神"], [220, "天女若希"], [223, "神罗麦提"], [227, "超T兔"], [231, "猪猪超人"],
  [246, "翡冷翠"], [251, "鬼王"], [254, "岩波斗魂者"], [261, "友人契约书"], [264, "多古拉伯爵"], [270, "伊泽"],
  [273, "迦娜"], [276, "蓝羽灵者"],
];
for (const [id, name] of BOSSES) {
  HONOURS.push([id, 1, 1, `boss:${name}`], [id + 1, 2, 10, `boss:${name}`], [id + 2, 3, 100, `boss:${name}`]);
}

/** The honours of the panel (HonourConfig): ids 0 … HONOUR_COUNT − 1. */
export const HONOUR_COUNT = 280;
/** 徽章分数 of a level (the panel: 钻石 40, 金 20, 银 10, 铜 5). */
const POINTS = [0, 5, 10, 20, 40];

/** The fields of a record the honours read. */
export interface HonourOwner {
  name: string;
  nextPetId?: number;
  pets?: { level: number }[];
  storage?: { level: number }[];
  friends?: number[];
  plants?: PlantRec[];
  zoo?: { exp: number };
  tasks?: Record<string, { st: number; fd?: number }>;
  area?: { donate?: { total?: number } };
  /** Wins against each 守护者, by its name (battle.ts, fightWithBoss). */
  bossWins?: Record<string, number>;
}

function count(o: HonourOwner, rule: Rule): number {
  switch (rule) {
    case "caught":
      return Math.max((o.nextPetId ?? 1) - 1, (o.pets?.length ?? 0) + (o.storage?.length ?? 0));
    case "full":
      return [...(o.pets ?? []), ...(o.storage ?? [])].filter((p) => p.level >= 100).length;
    case "friends":
      return o.friends?.length ?? 0;
    case "love":
      return o.area?.donate?.total ?? 0;
    case "trees":
      return (o.plants ?? []).filter((p) => {
        const kind = PLANTS[p.plantId];
        return !!kind && p.level >= kind.levels.length - 1;
      }).length;
    case "zoo":
      return o.zoo ? zooLevel(o.zoo.exp ?? 0).lv : 0;
  }
  if (rule.startsWith("task:")) return o.tasks?.[rule.slice(5)]?.st === 1 ? 1 : 0;
  if (rule.startsWith("boss:")) return o.bossWins?.[rule.slice(5)] ?? 0;
  return 0;
}

/** Each honour's progress: -1 got, else how far (only those that can be got here are listed). */
export function honourProgress(o: HonourOwner): Map<number, number> {
  const out = new Map<number, number>();
  for (const [id, , need, rule] of HONOURS) {
    const n = count(o, rule);
    out.set(id, n >= need ? -1 : n);
  }
  return out;
}

/** 徽章分数 and how many of each level are got ([铜, 银, 金, 钻石]). */
export function honourScore(o: HonourOwner): { score: number; got: number[] } {
  const progress = honourProgress(o);
  const got = [0, 0, 0, 0];
  let score = 0;
  for (const [id, level] of HONOURS) {
    if (progress.get(id) !== -1) continue;
    score += POINTS[level];
    got[level - 1]++;
  }
  return { score, got };
}

/** The 勋章 got: [{bi, gd}] in BadgeData order. */
export function badges(o: HonourOwner): { bi: number; gd: number }[] {
  return BADGE_TASKS.filter(([, task]) => o.tasks?.[String(task)]?.st === 1)
    .map(([bi, task]) => ({ bi, gd: o.tasks![String(task)].fd ?? 0 }))
    .sort((a, b) => a.bi - b.bi);
}

export interface HonourDeps {
  find(name: string): Promise<HonourOwner | undefined>;
}

export function installHonour(world: World, deps: HonourDeps): void {
  const page = async (un: string, idlist: unknown) => {
    const o = await deps.find(un);
    const progress = o ? honourProgress(o) : new Map<number, number>();
    const ids = String(idlist ?? "")
      .split(",")
      .map((s) => Number(s) | 0)
      .filter((id) => id >= 0 && id < HONOUR_COUNT);
    return { o, page: ids.map((id) => `${id}=${progress.get(id) ?? 0}`).join(",") };
  };
  world.xt("AchievementExtension.76_7", async (ctx) => {
    const un = String(ctx.params.un ?? ctx.player.name);
    const { o, page: p } = await page(un, ctx.params.idlist);
    const { score, got } = o ? honourScore(o) : { score: 0, got: [0, 0, 0, 0] };
    ctx.reply({ page: p, score, honor: got.join(","), rank: 0, nn: o?.name ?? un }, "76_7");
  });
  world.xt("SundriesExtension.70-1", async (ctx) => {
    const o = await deps.find(String(ctx.params.un ?? ctx.player.name));
    ctx.reply({ b: o ? badges(o) : [] }, "70-1");
  });
  world.xt("AchievementExtension.76_8", async (ctx) => {
    const un = String(ctx.params.un ?? ctx.player.name);
    ctx.reply({ page: (await page(un, ctx.params.idlist)).page }, "76_8");
  });
}
