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
//   {op: "party", mod, def}           -> {op, tag, res, msg,  the mod's own 亚比 and 道具 instead of the
//                                         pets, items}        player's (API 4; def below), the player's put
//                                                             aside until "unparty" (or the next login)
//   {op: "unparty", mod}              -> {op, tag, res}       the player's own back, the mod's kept for it
//   {op: "state", mod}                -> {op, tag, res,       the 亚比 and 道具 as they are now (party: the
//                                         party, pets, items, mod's own are out; vip: the player is a 蓝宝石)
//                                         vip}
//   {op: "item", mod, id, n}          -> {op, tag, res, msg,  n of the 道具 id (type 2) more (or fewer)
//                                         count}
//
// A party's def (JSON text): {pets: [{race, level, keep, follow}], items: {id: n}, fresh, keepText,
// noHeal, vip}. keep: the 亚比 that must stay in the bag, whose fall ends a fight as lost (keepText the
// battle's words then); follow: the one that follows the player; noHeal: healing all (the bag's
// 恢复, the HELLO's 亚比治疗, the 治疗 of the panels) is refused with these words; fresh: a new party
// even if the mod has one kept; vip: the player is a 蓝宝石 while the party is out (the HELLO's
// 远程亚比仓库 for the party's 仓库), no longer after it unless he was one before. While a party is out, the mod's fights (sandbox.ts) heal nobody
// when noHeal is set.
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
/** Mods' species a server keeps at once (in memory until it restarts), at most. */
export const MOD_SPECIES_MAX = 2000;
/** One mod's own species, at most (the server's room for them is everyone's). */
export const MOD_SPECIES_PER_MOD = 100;
/** The mod species one player makes known, at most, all his mods together. */
export const MOD_SPECIES_PER_PLAYER = 100;
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
/** Which player made each mod species known first (race -> name): a player's are counted together, whatever mod ids he gives. */
const makers = new WeakMap<PetTables, Map<number, string>>();
const makersOf = (t: PetTables) => {
  let m = makers.get(t);
  if (!m) makers.set(t, (m = new Map()));
  return m;
};

/** A mod's own 亚比 and 道具 (type 2), as kept while they are not out. */
export interface ModPartyState {
  pets: PetRecord[];
  storage: PetRecord[];
  released?: PetRecord[];
  items: Record<string, number>;
  keep?: number;
  keepText?: string;
  noHeal?: string;
  /** The pet id following the player. */
  follow?: number;
}

/** The party out: the mod's, its rules, and the player's own put aside. */
export interface ModParty {
  mod: string;
  /** The pet id that must stay in the bag (its fall ends a fight). */
  keep?: number;
  keepText?: string;
  /** Healing all is refused, with these words. */
  noHeal?: string;
  /** The party made the player a 蓝宝石 (def.vip; he was none): no more when it ends. */
  vip?: boolean;
  aside: { pets: PetRecord[]; storage: PetRecord[]; released: PetRecord[]; items: Record<string, number>; followPet?: number; showPet?: number };
}

export interface ModRec extends PetOwner {
  /** Saved data by mod id (JSON text). */
  modData?: Record<string, string>;
  /** A mod's 亚比 put aside while their mod is not running: where each was (pet.mod: its mod). */
  modPets?: { pet: PetRecord; bag: boolean }[];
  /** The mod's own 亚比 and 道具 out (IModGame.party), and those of each mod kept. */
  modParty?: ModParty;
  modParties?: Record<string, ModPartyState>;
  items?: Record<string, Record<string, number>>;
  /** 蓝宝石 (game.ts). */
  vip?: boolean;
  /** 展示 in the 亚比仓库 (pets.ts). */
  showPet?: number;
}

/** A party's 亚比 at most, and 道具 counts. */
export const PARTY_MAX = 12;
export const ITEM_COUNT_MAX = 999;

/** The player's own 亚比 and 道具 back (the mod's kept for it); false when no party is out. */
export function endModParty(rec: ModRec): boolean {
  const p = rec.modParty;
  if (!p) return false;
  // 亚比 got while it was out that are not the party's (a quest's, an egg's, the 工具箱's …): the player's.
  const ours = (list: PetRecord[] | undefined) => (list ?? []).filter((q) => q.party === p.mod);
  const theirs = (list: PetRecord[] | undefined) => (list ?? []).filter((q) => q.party !== p.mod);
  for (const q of [...theirs(rec.pets), ...theirs(rec.storage)]) (p.aside.pets.length < BAG_MAX ? p.aside.pets : p.aside.storage).push(q);
  p.aside.released.push(...theirs(rec.released));
  (rec.modParties ??= {})[p.mod] = {
    pets: ours(rec.pets),
    storage: ours(rec.storage),
    released: ours(rec.released),
    items: rec.items?.["2"] ?? {},
    keep: p.keep,
    keepText: p.keepText,
    noHeal: p.noHeal,
    follow: rec.followPet,
  };
  rec.pets = p.aside.pets;
  rec.storage = p.aside.storage;
  rec.released = p.aside.released;
  (rec.items ??= {})["2"] = p.aside.items;
  rec.followPet = p.aside.followPet ?? 0;
  rec.showPet = p.aside.showPet ?? 0;
  if (p.vip) rec.vip = false;
  delete rec.modParty;
  return true;
}

/** The rules of the party out, for the other modules (battle, pets): keep, noHeal. */
export const partyOf = (o: object): ModParty | undefined => (o as ModRec).modParty;

export interface ModDeps<R extends ModRec> {
  load: (ctx: XtContext) => Promise<R>;
  save: (rec: R) => Promise<void>;
  tables: () => Promise<PetTables>;
  today: () => string;
  /** A mod may give 亚比 (off where the 工具箱 is closed: game.ts toolbox). */
  gifts?: boolean;
  /** Whether a 道具 (type 2) is the game's. */
  isItem?: (id: number) => Promise<boolean>;
  /** The 亚比 following the player changed (null: none): the room's follow variable. */
  follow?: (ctx: XtContext, rec: R, pet: PetRecord | null) => void;
  /** Fills a pet's derived fields (HP) as the bag shows them. */
  maxHp?: (pet: PetRecord, t: PetTables) => number;
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
      // The species are the server's, everyone's (their fights, the 图鉴): where the 工具箱 is closed
      // a client does not add them (its stats would be anyone's to fight and win experience from).
      if (deps.gifts === false) return reply({ res: 0, msg: "这个服务器上，模组不能加自己的亚比。" });
      const sp = parseModSpecies(p.def, t);
      if (typeof sp === "string") return reply({ res: 0, msg: sp });
      const owner = ownersOf(t).get(sp.id);
      if (owner !== undefined && owner !== mod) return reply({ res: 0, msg: `编号${sp.id}已被模组${owner}使用` });
      if (owner === undefined && ownersOf(t).size >= MOD_SPECIES_MAX) return reply({ res: 0, msg: "这个服务器上模组的亚比已经太多了。" });
      if (owner === undefined && [...ownersOf(t).values()].filter((m) => m === mod).length >= MOD_SPECIES_PER_MOD) return reply({ res: 0, msg: "这个模组的亚比已经太多了。" });
      // One player's, whatever mod ids he gives (else twenty made-up ids would fill the server's).
      if (owner === undefined && [...makersOf(t).values()].filter((n) => n === ctx.player.name).length >= MOD_SPECIES_PER_PLAYER) return reply({ res: 0, msg: "你加的模组亚比已经太多了。" });
      if (owner === undefined) makersOf(t).set(sp.id, ctx.player.name);
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
    if (op === "party" || op === "unparty" || op === "state" || op === "item") {
      if (!isModId(mod)) return reply({ res: 0, msg: "模组的编号不对" });
      const t = await deps.tables();
      const state = () => {
        const view = (p: PetRecord, bag: boolean) => ({ id: p.id, race: p.race, level: p.level, hp: p.hp, maxHp: deps.maxHp ? deps.maxHp(p, t) : p.hp, bag, keep: rec.modParty?.keep === p.id });
        return {
          party: rec.modParty?.mod === mod,
          pets: [...(rec.pets ?? []).map((p) => view(p, true)), ...(rec.storage ?? []).map((p) => view(p, false))],
          items: { ...(rec.items?.["2"] ?? {}) },
          vip: !!rec.vip,
        };
      };
      // The room's players see the 蓝宝石 (mtype) as the toolbox's change does (game.ts).
      const tellVip = () => world.setUserVars?.(ctx.session, { mtype: rec.vip ? 4 : 0 });
      const followNow = () => deps.follow?.(ctx, rec, (rec.pets ?? []).find((p) => p.id === rec.followPet) ?? null);
      // The 道具 the game shows (its 物品, the bag's) follow the swap: told as changes of each count.
      const itemsNow = () => ({ ...(rec.items?.["2"] ?? {}) });
      const tellItems = (before: Record<string, number>) => {
        const after = itemsNow();
        const changes: string[] = [];
        for (const id of new Set([...Object.keys(before), ...Object.keys(after)])) {
          const d = (after[id] ?? 0) - (before[id] ?? 0);
          if (d) changes.push(`2_${id}_0_${d}`);
        }
        if (changes.length) ctx.reply({ amount: changes.join("#") }, "onAmountUpdated");
      };
      if (op === "state") return reply({ res: 1, ...state() });
      if (op === "unparty") {
        if (rec.modParty?.mod === mod) {
          const before = itemsNow();
          const vip = !!rec.vip;
          endModParty(rec);
          await deps.save(rec);
          followNow();
          tellItems(before);
          if (vip !== !!rec.vip) tellVip();
        }
        return reply({ res: 1, vip: !!rec.vip });
      }
      if (op === "item") {
        if (deps.gifts === false) return reply({ res: 0, msg: "这个服务器上，模组不能送道具。" });
        const id = Math.floor(Number(p.id));
        const n = Math.max(-ITEM_COUNT_MAX, Math.min(ITEM_COUNT_MAX, Math.floor(Number(p.n)) || 0));
        if (!(id > 0) || !(await (deps.isItem?.(id) ?? Promise.resolve(true)))) return reply({ res: 0, msg: "游戏里没有这个道具" });
        const bag = ((rec.items ??= {})["2"] ??= {});
        const before = bag[String(id)] ?? 0;
        const now = Math.max(0, Math.min(ITEM_COUNT_MAX, before + n));
        if (now) bag[String(id)] = now;
        else delete bag[String(id)];
        await deps.save(rec);
        if (now !== before) ctx.reply({ amount: `2_${id}_0_${now - before}` }, "onAmountUpdated");
        return reply({ res: 1, count: now });
      }
      // party
      if (deps.gifts === false) return reply({ res: 0, msg: "这个服务器上，模组不能带自己的亚比。" });
      let def: Record<string, unknown>;
      try {
        def = JSON.parse(String(p.def ?? "{}")) ?? {};
      } catch {
        return reply({ res: 0, msg: "队伍的定义不对" });
      }
      const fresh = def.fresh === true;
      const itemsBefore = itemsNow();
      if (rec.modParty && rec.modParty.mod !== mod) endModParty(rec);
      if (rec.modParty?.mod === mod && !fresh) {
        followNow();
        return reply({ res: 1, ...state() });
      }
      const kept = fresh ? undefined : rec.modParties?.[mod];
      let made: ModPartyState;
      if (kept) made = kept;
      else {
        const list = Array.isArray(def.pets) ? def.pets.slice(0, PARTY_MAX) : [];
        if (!list.length) return reply({ res: 0, msg: "队伍里没有亚比" });
        made = { pets: [], storage: [], items: {} };
        for (const d of list as Record<string, unknown>[]) {
          const race = Math.floor(Number(d?.race));
          const level = Math.max(1, Math.min(MOD_LEVEL_MAX, Math.floor(Number(d?.level)) || 1));
          if (!Object.hasOwn(t.pm.species, String(race))) return reply({ res: 0, msg: `游戏里没有亚比${race}` });
          if (isModRace(race) && ownersOf(t).get(race) !== mod) return reply({ res: 0, msg: "这个亚比不是这个模组的" });
          const pet = newPet(rec, t, race, level, deps.today());
          if (isModRace(race)) pet.mod = mod;
          if (pet.iv) pet.iv = pet.iv.map((v) => Math.min(MAX_IV, v));
          (made.pets.length < BAG_MAX ? made.pets : made.storage).push(pet);
          if (d.keep === true && made.keep === undefined) made.keep = pet.id;
          if (d.follow === true) made.follow = pet.id;
        }
        for (const [id, n] of Object.entries((def.items ?? {}) as Record<string, unknown>)) {
          const k = Math.floor(Number(id));
          const v = Math.max(0, Math.min(ITEM_COUNT_MAX, Math.floor(Number(n)) || 0));
          if (k > 0 && v > 0 && (await (deps.isItem?.(k) ?? Promise.resolve(true)))) made.items[String(k)] = v;
        }
        made.keepText = def.keepText ? String(def.keepText).slice(0, 100) : undefined;
        made.noHeal = def.noHeal ? String(def.noHeal).slice(0, 100) : undefined;
      }
      if (rec.modParty?.mod === mod) {
        // fresh: the party out is dropped; the player's own stay aside (with those he got meanwhile).
        const aside = rec.modParty.aside;
        for (const q of [...(rec.pets ?? []), ...(rec.storage ?? [])]) if (q.party !== mod) (aside.pets.length < BAG_MAX ? aside.pets : aside.storage).push(q);
        for (const q of rec.released ?? []) if (q.party !== mod) aside.released.push(q);
        delete rec.modParty.keep;
      } else {
        rec.modParty = {
          mod,
          aside: { pets: rec.pets ?? [], storage: rec.storage ?? [], released: rec.released ?? [], items: rec.items?.["2"] ?? {}, followPet: rec.followPet, showPet: rec.showPet },
        };
        rec.showPet = 0;
      }
      // Each of them the party's (those kept from before this mark too).
      for (const q of [...made.pets, ...made.storage, ...(made.released ?? [])]) q.party = mod;
      rec.modParty.keep = made.keep;
      rec.modParty.keepText = made.keepText;
      rec.modParty.noHeal = made.noHeal;
      const vipNow = def.vip === true && !rec.vip;
      if (vipNow) {
        rec.modParty.vip = true;
        rec.vip = true;
      }
      rec.pets = made.pets;
      rec.storage = made.storage;
      rec.released = made.released ?? [];
      (rec.items ??= {})["2"] = made.items;
      rec.followPet = (rec.pets ?? []).some((q) => q.id === made.follow) ? made.follow : 0;
      if (rec.modParties) delete rec.modParties[mod];
      await deps.save(rec);
      followNow();
      tellItems(itemsBefore);
      if (vipNow) tellVip();
      return reply({ res: 1, ...state() });
    }
    if (op === "give") {
      if (deps.gifts === false) return reply({ res: 0, msg: "这个服务器上，模组不能送亚比。" });
      if (!isModId(mod)) return reply({ res: 0, msg: "模组的编号不对" });
      const t = await deps.tables();
      const race = Math.floor(Number(p.race));
      const level = Math.max(1, Math.min(MOD_LEVEL_MAX, Math.floor(Number(p.level)) || 1));
      if (!Object.hasOwn(t.pm.species, String(race))) return reply({ res: 0, msg: "游戏里没有这个亚比" });
      if (isModRace(race) && ownersOf(t).get(race) !== mod) return reply({ res: 0, msg: "这个亚比不是这个模组的" });
      const pet = newPet(rec, t, race, level, deps.today());
      if (isModRace(race)) pet.mod = mod;
      // Given while its party is out: the party's.
      if (rec.modParty?.mod === mod) pet.party = mod;
      if (pet.iv) pet.iv = pet.iv.map((v) => Math.min(MAX_IV, v));
      if ((rec.pets ??= []).length < BAG_MAX) rec.pets.push(pet);
      else (rec.storage ??= []).push(pet);
      await deps.save(rec);
      return reply({ res: 1, id: pet.id });
    }
    reply({ res: 0, msg: "unknown op" });
  });
}
