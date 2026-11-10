// 亚比超进化 for the 2013 server: the 超进化机 of the 亚比研究中心 (pet/superevolution, config of
// 7 February 2013; rebuilt on its copy of 2015) and its 超进化手册 (book201103):
//
//   PetExtension2 54e_1 {pid, t}  -> {res, pid, raceId}   0 done: the 亚比 pid (in the bag) becomes its
//                                                         fourth form; the materials go (onAmountUpdated)
//                                    {res: 1, msg}        not done (msg says why)
//
// The same command evolves the 小独角兽 (planetacts.ts) and the union 亚比 (areafuncs.ts), installed
// before: a 亚比 that has no 超进化 is left to them.
//
// What each 超进化 takes is the 2015 module's table (SuperEvolutionConfig), which the 超进化手册's
// 超进化方程式 of 2011–2013 show the same (catalog/superevolution1–5): 30 次级进化水晶 (265), 10
// 进化水晶 (266) and two items for the three starters, 10 and 4 and two items for the later ones,
// one 炎之结晶 (335) for 烈焰鸟. The rules are the machine's own (超进化规则说明) and the 2012 奥拉周刊's
// (亚比超进化之后…会由1级开始升级; 进化水晶可以将60级以上的亚比，进化到第4形态): level 60 or more; the
// 亚比 comes back at level 1 with its new form's skills of that level, its 学习力 cleared, its 天赋
// (individual values) and 性格 kept.

import type { World, XtContext } from "./server.ts";
import { followVar, learntFor, skillOf, speciesOf, statsOf, type PetRecord, type PetTables } from "./pets.ts";
import { skillsAt } from "./pmdata.ts";

export const ITEM = "2";
export const SUPER_LEVEL = 60;

/** fourth form -> [first race, its materials [item id, count]]. */
export const SUPER_EVOLUTIONS: Record<number, [from: number, need: [number, number][]]> = {
  502: [9, [[265, 30], [266, 10], [91, 1], [133, 1]]], // 露西亚 -> 古渊露龙
  500: [3, [[265, 30], [266, 10], [88, 1], [213, 1]]], // 大师兔 -> 终结兔
  501: [6, [[265, 30], [266, 10], [93, 1], [200, 1]]], // 爆焰吉拉 -> 魔焰吉拉
  506: [278, [[335, 1]]], // 烈焰鸟 -> 烈焰凤凰
  1159: [566, [[265, 10], [266, 4], [91, 1], [86, 1]]], // 利牙海狮 -> 极冰海牙
  1380: [487, [[265, 10], [266, 4], [87, 1], [124, 1]]], // 尖钻虎王 -> 金刚虎王
  505: [12, [[265, 10], [266, 4], [86, 1], [200, 1]]], // 寒冰玉兔 -> 寒冰公主
  1134: [54, [[265, 10], [266, 4], [133, 1], [200, 1]]], // 白古丁 -> 白羽公主
  209: [24, [[265, 10], [266, 4], [88, 1], [200, 1]]], // 花冠狮 -> 花冠公主
};

/** The fourth form a race may become, if any. */
export function superTarget(race: number): number | undefined {
  for (const [to, [from]] of Object.entries(SUPER_EVOLUTIONS)) if (from === race) return Number(to);
  return undefined;
}

export interface SuperOwner {
  pets?: PetRecord[];
  items?: Record<string, Record<string, number>>;
  followPet?: number;
}

export interface SuperDeps<O extends SuperOwner> {
  load: (ctx: XtContext) => Promise<O>;
  save: (o: O) => Promise<void>;
  tables: () => Promise<PetTables>;
}

/** The 超进化 of one 亚比, or why not (the materials are taken; the caller saves). */
export function superEvolve(t: PetTables, o: SuperOwner, pet: PetRecord): { to: number; amounts: string[] } | { msg: string } {
  const to = superTarget(pet.race);
  if (to === undefined || !speciesOf(t, to)) return { msg: "这只亚比不能超进化哦！" };
  if (pet.level < SUPER_LEVEL) return { msg: `你的亚比还没有达到${SUPER_LEVEL}级，不能进行超进化哦！` };
  const items = ((o.items ??= {})[ITEM] ??= {});
  const need = SUPER_EVOLUTIONS[to][1];
  if (need.some(([id, n]) => (items[String(id)] ?? 0) < n)) return { msg: "超进化的材料还不够哦！" };
  const amounts: string[] = [];
  for (const [id, n] of need) {
    const left = (items[String(id)] ?? 0) - n;
    if (left > 0) items[String(id)] = left;
    else delete items[String(id)];
    amounts.push(`${ITEM}_${id}_0_${-n}`);
  }
  pet.race = to;
  pet.level = 1;
  pet.exp = 0;
  pet.ev = [0, 0, 0, 0, 0, 0];
  pet.fixed = undefined;
  pet.buff = undefined;
  const sp = speciesOf(t, to);
  if (sp && sp.learn.length) {
    pet.skills = skillsAt(sp, 1).map((id) => skillOf(t, id));
    pet.learned = learntFor(t, to, 1, pet.skills);
  }
  pet.hp = statsOf(pet, t)[0];
  return { to, amounts };
}

export function installSuperEvo<O extends SuperOwner>(world: World, deps: SuperDeps<O>): void {
  const before = world.handlers?.get("PetExtension2.54e_1");
  world.xt("PetExtension2.54e_1", async (ctx, cmd) => {
    const o = await deps.load(ctx);
    const pet = o.pets?.find((p) => p.id === (Number(ctx.params.pid) | 0));
    if (before && !(pet && superTarget(pet.race) !== undefined)) return before(ctx, cmd);
    if (!pet) return ctx.reply({ res: 1, msg: "背包里没有这只亚比哦！" }, "54e_1");
    const t = await deps.tables();
    const r = superEvolve(t, o, pet);
    if ("msg" in r) return ctx.reply({ res: 1, msg: r.msg }, "54e_1");
    await deps.save(o);
    for (const amount of r.amounts) ctx.reply({ amount }, "onAmountUpdated");
    if (o.followPet === pet.id) world.setUserVarOnce(ctx.session, "p", followVar(pet));
    ctx.reply({ res: 0, pid: pet.id, raceId: pet.race }, "54e_1");
  });
}
