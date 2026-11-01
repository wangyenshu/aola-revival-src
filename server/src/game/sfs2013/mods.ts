// The 沙盒's mods (not of 2013; rebuilt control ModRun, docs/MODDING.md): the server side of a
// mod's 亚比, gifts and saved data. SundriesExtension.revival_mod, every reply with the request's
// op and tag:
//
//   {op: "data", mod}                 -> {op, tag, data}      the mod's saved data (JSON text, "" for none)
//   {op: "save", mod, data}           -> {op, tag, res}       keep it (JSON text, at most MOD_DATA_MAX bytes,
//                                                             MOD_DATA_TOTAL for all mods together)
//   {op: "species", mod, def}         -> {op, tag, res, msg,  a 亚比 of the mod (def: JSON text of
//                                         def, back}          {id, name, attr: [a, a], stats: [6], skills:
//                                                             [[level, skill]], exp}); 1 known (def: as the
//                                                             server keeps it; back: 亚比 given back), 0
//                                                             refused (also an id another mod has made known)
//   {op: "give", mod, race, level}    -> {op, tag, res, msg}  a 亚比 for the player (the game's or one
//                                                             the mod has made known), to the bag or the 仓库
//
// A mod's 亚比 (MOD_RACE_MIN–MOD_RACE_MAX) are known only while the page runs, once their mod has
// told them: at login those the player has are put aside (modPets) and given back when their
// mod is started again (and tells them). Each keeps the id of its mod (PetRecord.mod): another
// mod using the same number neither takes them back nor redefines them in that run. (The Node
// server shares the tables between its players: a species made known there is known to all
// until it restarts; mods are meant for the page's own server.)

import type { World, XtContext } from "./server.ts";
import { newPet, type PetOwner, type PetRecord, type PetTables } from "./pets.ts";
import { MAX_IV } from "./pmdata.ts";

export const MOD_RACE_MIN = 900001;
export const MOD_RACE_MAX = 999999;
/** Saved data: bytes (UTF-8) per mod, and for all mods of a player together. */
export const MOD_DATA_MAX = 65536;
export const MOD_DATA_TOTAL = 1048576;
export const MOD_LEVEL_MAX = 100;
/** The bag holds six (the 仓库 the rest). */
export const BAG_MAX = 6;

const MOD_ID_TEXT = /^[A-Za-z0-9_-]{1,32}$/;
/** A mod id: letters, digits, _ and -, and not a name objects have already (__proto__, constructor …). */
const isModId = (id: string) => MOD_ID_TEXT.test(id) && !(id in Object.prototype);
const encoder = new TextEncoder();
const bytes = (s: string) => encoder.encode(s).length;
/** Which mod made each mod species known in this run (race -> mod id), beside the tables. */
const owners = new WeakMap<PetTables, Map<number, string>>();
const ownersOf = (t: PetTables) => {
  let m = owners.get(t);
  if (!m) owners.set(t, (m = new Map()));
  return m;
};

export interface ModRec extends PetOwner {
  /** Saved data by mod id (JSON text). */
  modData?: Record<string, string>;
  /** A mod's 亚比 put aside while their mod is not running: where each was (pet.mod: its mod). */
  modPets?: { pet: PetRecord; bag: boolean }[];
}

export interface ModDeps<R extends ModRec> {
  load: (ctx: XtContext) => Promise<R>;
  save: (rec: R) => Promise<void>;
  tables: () => Promise<PetTables>;
  today: () => string;
}

export const isModRace = (race: number) => race >= MOD_RACE_MIN && race <= MOD_RACE_MAX;

/** At login: put aside the mod 亚比 the game does not know now (known: whether a race is). */
export function stashModPets(rec: ModRec, known: (race: number) => boolean): boolean {
  let moved = false;
  for (const [list, bag] of [[rec.pets, true], [rec.storage, false]] as [PetRecord[] | undefined, boolean][]) {
    if (!list) continue;
    for (let i = list.length - 1; i >= 0; i--) {
      const p = list[i];
      if (!isModRace(p.race) || known(p.race)) continue;
      list.splice(i, 1);
      (rec.modPets ??= []).push({ pet: p, bag });
      if (rec.followPet === p.id) delete rec.followPet;
      moved = true;
    }
  }
  return moved;
}

/** A mod's 亚比 from what the mod sent, or why it cannot be. */
export function parseModSpecies(text: unknown, t: PetTables): { id: number; name: string; attr: [number, number]; stats: number[]; learn: [number, number][]; exp: string } | string {
  let d: Record<string, unknown>;
  try {
    d = typeof text === "string" ? JSON.parse(text) : (text as Record<string, unknown>);
  } catch {
    return "不是亚比的定义";
  }
  if (!d || typeof d !== "object") return "不是亚比的定义";
  const id = Math.floor(Number(d.id));
  if (!isModRace(id)) return `模组亚比的编号是${MOD_RACE_MIN}–${MOD_RACE_MAX}`;
  const name = String(d.name ?? "").trim().slice(0, 12);
  if (!name) return "亚比没有名字";
  const attrs = Array.isArray(d.attr) ? d.attr.map((a) => Math.floor(Number(a))) : [];
  // The attributes are the chart's rows (its legend cells are no attributes).
  const charted = (a: number) => Number.isInteger(a) && a >= 0 && Object.hasOwn(t.pm.chart, String(a));
  if (attrs.length === 0 || !charted(attrs[0])) return "亚比的属性不是游戏的属性";
  const attr: [number, number] = [attrs[0], charted(attrs[1] ?? NaN) ? attrs[1] : attrs[0]];
  const stats = Array.isArray(d.stats) ? d.stats.map((v) => Math.floor(Number(v))) : [];
  if (stats.length !== 6 || stats.some((v) => !(v >= 1 && v <= 255))) return "亚比的种族值是6个1–255的数";
  const learn: [number, number][] = [];
  for (const s of Array.isArray(d.skills) ? d.skills : []) {
    const [lv, id2] = Array.isArray(s) ? [Math.floor(Number(s[0])), Math.floor(Number(s[1]))] : [1, Math.floor(Number(s))];
    if (!Object.hasOwn(t.pm.skills, String(id2))) return `技能${id2}不是游戏的技能`;
    learn.push([Math.max(0, Math.min(MOD_LEVEL_MAX, lv || 0)), id2]);
    if (learn.length >= 40) break;
  }
  if (learn.length === 0) return "亚比至少要会一个技能";
  learn.sort((a, b) => a[0] - b[0]);
  const exp = String(d.exp ?? "2");
  return { id, name, attr, stats, learn, exp: Object.hasOwn(t.pm.exp, exp) ? exp : "2" };
}

export function installMods<R extends ModRec>(world: World, deps: ModDeps<R>): void {
  world.xt("SundriesExtension.revival_mod", async (ctx) => {
    const p = ctx.params as Record<string, unknown>;
    const op = String(p.op ?? "");
    const reply = (o: Record<string, unknown>) => ctx.reply({ op, tag: p.tag ?? "", ...o });
    const mod = String(p.mod ?? "");
    const rec = await deps.load(ctx);
    if (op === "data") {
      return reply({ data: isModId(mod) && rec.modData && Object.hasOwn(rec.modData, mod) ? rec.modData[mod] : "" });
    }
    if (op === "save") {
      const data = String(p.data ?? "");
      if (!isModId(mod) || bytes(data) > MOD_DATA_MAX) return reply({ res: 0, msg: "too big" });
      const others = Object.entries(rec.modData ?? {}).reduce((n, [k, v]) => (k === mod ? n : n + bytes(v)), 0);
      if (others + bytes(data) > MOD_DATA_TOTAL) return reply({ res: 0, msg: "too much" });
      try {
        JSON.parse(data || "{}");
      } catch {
        return reply({ res: 0 });
      }
      (rec.modData ??= {})[mod] = data;
      await deps.save(rec);
      return reply({ res: 1 });
    }
    if (op === "species") {
      const t = await deps.tables();
      if (!isModId(mod)) return reply({ res: 0, msg: "模组的编号不对" });
      const sp = parseModSpecies(p.def, t);
      if (typeof sp === "string") return reply({ res: 0, msg: sp });
      const owner = ownersOf(t).get(sp.id);
      if (owner !== undefined && owner !== mod) return reply({ res: 0, msg: `编号${sp.id}已被模组${owner}使用` });
      ownersOf(t).set(sp.id, mod);
      t.pm.species[String(sp.id)] = {
        n: sp.name,
        s: sp.stats,
        ev: [0, 0, 0, 0, 0, 0],
        t: sp.attr,
        bx: 64,
        xt: sp.exp,
        c: ["NA", "NA"],
        evo: "",
        learn: sp.learn,
      };
      t.species[String(sp.id)] = { n: sp.name, a: sp.attr[0], e: 0, next: 0, sk: [] };
      // Its 亚比 the player has, put aside at login: back (those of this mod, or of no known mod).
      const ours = (m: { pet: PetRecord }) => m.pet.race === sp.id && (m.pet.mod === undefined || m.pet.mod === mod);
      const back = (rec.modPets ?? []).filter(ours);
      if (back.length) {
        rec.modPets = (rec.modPets ?? []).filter((m) => !ours(m));
        for (const m of back) {
          if (m.bag && (rec.pets ??= []).length < BAG_MAX) rec.pets.push(m.pet);
          else (rec.storage ??= []).push(m.pet);
        }
        await deps.save(rec);
      }
      const def = { id: sp.id, name: sp.name, attr: sp.attr, stats: sp.stats, skills: sp.learn, exp: sp.exp };
      return reply({ res: 1, back: back.length, def: JSON.stringify(def) });
    }
    if (op === "give") {
      const t = await deps.tables();
      const race = Math.floor(Number(p.race));
      const level = Math.max(1, Math.min(MOD_LEVEL_MAX, Math.floor(Number(p.level)) || 1));
      if (!Object.hasOwn(t.pm.species, String(race))) return reply({ res: 0, msg: "游戏里没有这个亚比" });
      if (isModRace(race) && ownersOf(t).get(race) !== mod) return reply({ res: 0, msg: "这个亚比不是这个模组的" });
      const pet = newPet(rec, t, race, level, deps.today());
      if (isModRace(race)) pet.mod = mod;
      if (pet.iv) pet.iv = pet.iv.map((v) => Math.min(MAX_IV, v));
      if ((rec.pets ??= []).length < BAG_MAX) rec.pets.push(pet);
      else (rec.storage ??= []).push(pet);
      await deps.save(rec);
      return reply({ res: 1, id: pet.id });
    }
    reply({ res: 0, msg: "unknown op" });
  });
}
