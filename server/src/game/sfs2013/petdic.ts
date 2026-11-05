// The 亚比图鉴 (pet/petdictionary): which species the player has met and owned.
//
//   PetExtension 54_5 {}           -> 54_5 {res}: 10 characters (the panel skips them), then one per
//                                     species from 1: 0 unknown, 1 met, 2 owned
//   PetExtension2 54e_11 {}        -> 54e_11 {l, p}: the 最新亚比 ("id,id,…") and whether the player
//                                     has not looked at them yet (l, the panel opens on them)
//   PetExtension2 54e_12 {}           the player has looked at them
//   push LatePMChartNotify {}         a species is new in the 图鉴: the 2013 pet/petdictinitservice
//                                     shows "亚比图鉴有了新的记录" over the player (after the fight)
//
// The panel is the later client's (pet/petdictionary, 2017) on the 2013 libraries; the commands are
// its, the rules RECONSTRUCTED: met is a fight against the species, owned a 亚比 of it in the bag or
// the 仓库 (or caught).
import type { PetOwner, PetTables } from "./pets.ts";
import type { World, XtContext } from "./server.ts";

export interface DicOwner extends PetOwner {
  /** One character per species from 1: "0", "1" met, "2" owned. */
  dic?: string;
  /** The 最新亚比 looked at. */
  dicLatest?: boolean;
}

export const MET = 1;
export const OWNED = 2;

/** The 最新亚比 of the 24 January 2013 update (their era icons are of that day; 1423 came a week later). */
export const LATEST_PETS = [1417, 1418, 1419, 1420, 1421, 1422, 1424, 1425, 1426];

const tops = new WeakMap<object, number>();

/** The highest species of the 图鉴. */
export function dicTop(t: PetTables): number {
  let top = tops.get(t.species);
  if (top === undefined) {
    top = 0;
    for (const k of Object.keys(t.species)) {
      const n = Number(k);
      if (n < 10000 && n > top) top = n;
    }
    tops.set(t.species, top);
  }
  return top;
}

/** Raise a species' mark; true when it is new to the 图鉴 (was unknown, or met and now owned). */
export function markDic(o: DicOwner, t: PetTables, race: number, state: number): boolean {
  if (!Number.isInteger(race) || race < 1 || race > dicTop(t) || !t.species[String(race)]) return false;
  const s = o.dic ?? "";
  if (Number(s.charAt(race - 1) || "0") >= state) return false;
  o.dic = s.padEnd(race - 1, "0").slice(0, race - 1) + String(state) + s.slice(race);
  return true;
}

/** The 54_5 marks, with the 亚比 the player has now counted as owned. */
export function dicMarks(o: DicOwner, t: PetTables): string {
  for (const p of [...(o.pets ?? []), ...(o.storage ?? [])]) markDic(o, t, p.race, OWNED);
  return "0".repeat(10) + (o.dic ?? "").padEnd(dicTop(t), "0");
}

export const NEW_RECORD: [string, Record<string, unknown>] = ["LatePMChartNotify", {}];

export interface PetDicDeps {
  load: (ctx: XtContext) => Promise<PetOwner>;
  save: (o: PetOwner) => Promise<void>;
  tables: () => Promise<PetTables>;
}

export function installPetDic(world: World, deps: PetDicDeps): void {
  world.xt("PetExtension.54_5", async (ctx) => {
    const o = (await deps.load(ctx)) as DicOwner;
    const before = o.dic;
    const res = dicMarks(o, await deps.tables());
    if (o.dic !== before) await deps.save(o);
    ctx.reply({ res }, "54_5");
  });
  world.xt("PetExtension2.54e_11", async (ctx) => {
    const o = (await deps.load(ctx)) as DicOwner;
    const t = await deps.tables();
    const p = LATEST_PETS.filter((r) => t.species[String(r)]);
    ctx.reply({ l: o.dicLatest || !p.length ? 0 : 1, p: p.join(",") }, "54e_11");
  });
  world.xt("PetExtension2.54e_12", async (ctx) => {
    const o = (await deps.load(ctx)) as DicOwner;
    if (o.dicLatest) return;
    o.dicLatest = true;
    await deps.save(o);
  });
}
