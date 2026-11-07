// 亚比 (pets) for the 2013 server: PocketMonsterExtension, the numeric
// protocol of the 2013 PetClient (requests 1xxx, replies 2xxx), with the reply
// shapes the 2013 interface classes parse (PlayerBriefInfo, PetBriefInfo,
// PetDetailedInfo, SkillInfo).
//
// The 2013 server's numbers are lost. Species, stats, skills and experience
// curves come from the client's own tables (revival/pets.json from
// tools/gen_pets.py, revival/pmdata.json from tools/gen_pmdata.py); the
// formulas that turn them into a 亚比 are RECONSTRUCTED (pmdata.ts).

import {
  EMPTY_PMDATA,
  MAX_IV,
  NATURE_NAMES,
  NATURES,
  calcStats,
  catchLevel,
  expNeed,
  allSkillsAt,
  skillsAt,
  type PmData,
  type PmSpecies,
} from "./pmdata.ts";
import type { World, XtContext } from "./server.ts";
import { inFight } from "./fighting.ts";
import { cardBonus } from "./petcards.ts";

export interface PetSkill {
  id: number;
  name: string;
  pp: number;
  max: number;
}

export interface PetRecord {
  id: number;
  race: number;
  level: number;
  /** Experience gathered towards the next level. */
  exp: number;
  hp: number;
  nick?: string;
  character: string;
  /** Skills carried into battle (at most 4). */
  skills: PetSkill[];
  /** Every skill learnt (ids), carried or not. */
  learned?: number[];
  /** Individual values 0–31, hp first. */
  iv?: number[];
  /** Effort points, hp first. */
  ev?: number[];
  got: string;
  /** 沙盒 opponents only: their stats multiplied (hp first), as the player set them (sandbox.ts). */
  mul?: number[];
  /** A mod's 亚比 (mods.ts): the id of the mod that made its species. */
  mod?: string;
  /** 形态固化剂 (petitems.ts): levels no longer evolve it. */
  fixed?: boolean;
  /** 强化药剂 (petitems.ts) waiting for its next battle: stat index (hp first) and points. */
  buff?: { i: number; add: number };
  /** 战术卡 worn (petcards.ts): ids in the places A, B, C (0 none). */
  cards?: number[];
  /** 设为精英 in the 亚比仓库: it shows in the 精英仓库 as well. */
  elite?: boolean;
  /** In the 放生仓库: when it was let go (ms). */
  relAt?: number;
}

/** Fields of UserRecord the pet code uses. */
export interface PetOwner {
  id: number;
  name: string;
  pets?: PetRecord[];
  /** 亚比 that did not fit in the bag (仓库). */
  storage?: PetRecord[];
  /** 放生仓库: 亚比 let go, kept RELEASE_KEEP_MS before they are gone for good. */
  released?: PetRecord[];
  nextPetId?: number;
  followPet?: number;
  /** 展示 in the 亚比仓库: the 亚比 shown in the owner's 家园 (0 none). */
  showPet?: number;
  /** Experience of the 捕捉等级. */
  catchExp?: number;
}

/**
 * How long the 放生仓库 keeps a 亚比 let go. The 2012 tutorial (houseteachpetstore) says only
 * "放生的亚比一段时间后就无法找回": RECONSTRUCTED as seven days.
 */
export const RELEASE_KEEP_MS = 7 * 24 * 3600 * 1000;

/** The 放生仓库 without the 亚比 kept long enough; true when some went. */
export function dropOldReleased(o: PetOwner, now: number): boolean {
  const before = o.released?.length ?? 0;
  if (!before) return false;
  o.released = o.released!.filter((p) => now - (p.relAt ?? 0) < RELEASE_KEEP_MS);
  return o.released.length !== before;
}

export type SpeciesTable = Record<string, { n: string; a: number; e: number; next: number; sk: string[] }>;


/** Fallback growth when a species is missing from pmdata: [base, per level]. */
const GROWTH: [number, number][] = [
  [20, 3],
  [10, 2],
  [10, 2],
  [10, 2],
  [10, 2],
  [10, 2],
];

export interface PetTables {
  species: SpeciesTable;
  pm: PmData;
}

export function speciesOf(t: PetTables, race: number): PmSpecies | undefined {
  return t.pm.species[String(race)];
}

export function nameOf(t: PetTables, race: number): string {
  return t.pm.species[String(race)]?.n ?? t.species[String(race)]?.n ?? `亚比${race}`;
}

export function statsOf(p: Pick<PetRecord, "race" | "level" | "iv" | "ev"> & { character?: string; mul?: number[]; cards?: number[] }, t?: PetTables): number[] {
  const sp = t ? speciesOf(t, p.race) : undefined;
  const base = sp ? calcStats(sp, p.level, p.iv, p.ev, p.character) : GROWTH.map(([b, k]) => b + k * p.level);
  const mul = p.mul ? base.map((v, i) => Math.max(1, Math.round(v * (p.mul![i] ?? 1)))) : base;
  if (!p.cards?.some(Boolean)) return mul;
  // 战术卡 worn (petcards.ts).
  const add = cardBonus(p.cards);
  return mul.map((v, i) => Math.max(1, v + add[i]));
}

export function maxHpOf(p: PetRecord, t: PetTables): number {
  return statsOf(p, t)[0];
}

export function expToNext(p: Pick<PetRecord, "race" | "level">, t?: PetTables): number {
  return expNeed(t?.pm ?? EMPTY_PMDATA, t ? speciesOf(t, p.race) : undefined, p.level);
}

export function skillOf(t: PetTables, id: number, pp?: number): PetSkill {
  const s = t.pm.skills[String(id)];
  const max = s?.pp ?? 20;
  return { id, name: s?.n ?? `技能${id}`, pp: pp ?? max, max };
}

/** The skills a 亚比 of this race knows at this level (pmdata learnset, or the old name list). */
function skillsFor(t: PetTables, race: number, level: number): PetSkill[] {
  const sp = speciesOf(t, race);
  if (sp && sp.learn.length) return skillsAt(sp, level).map((id) => skillOf(t, id));
  const names = t.species[String(race)]?.sk ?? [];
  const n = Math.max(2, Math.min(4, 1 + Math.floor(level / 5)));
  return names.slice(0, n).map((name, i) => ({ id: race * 100 + i + 1, name, pp: 20, max: 20 }));
}

function randomIv(): number[] {
  return Array.from({ length: 6 }, () => Math.floor(Math.random() * (MAX_IV + 1)));
}

function randomNature(): string {
  return NATURE_NAMES[Math.floor(Math.random() * NATURE_NAMES.length)];
}

/** Every skill a 亚比 of this race knows at this level (its learnset so far; the carried ones otherwise). */
export function learntFor(t: PetTables, race: number, level: number, carried: PetSkill[]): number[] {
  const sp = speciesOf(t, race);
  const all = sp && sp.learn.length ? allSkillsAt(sp, level) : [];
  return [...new Set([...all, ...carried.map((s) => s.id)])];
}

export function makePet(t: PetTables, race: number, level: number, today: string, id = 0, character?: string): PetRecord {
  const skills = skillsFor(t, race, level);
  const p: PetRecord = {
    id,
    race,
    level,
    exp: 0,
    hp: 0,
    character: character ?? randomNature(),
    skills,
    // A 亚比 given at a high level (the 工具箱, a task) knows every skill of its line up to it.
    learned: learntFor(t, race, level, skills),
    iv: randomIv(),
    ev: [0, 0, 0, 0, 0, 0],
    got: today,
  };
  p.hp = statsOf(p, t)[0];
  return p;
}

export function newPet(owner: PetOwner, t: PetTables, race: number, level: number, today: string): PetRecord {
  const id = (owner.nextPetId = (owner.nextPetId ?? 0) + 1);
  return makePet(t, race, level, today, id);
}

/**
 * Saves from before the battle data had made-up skills (race*100+n) and no
 * individual values: give them their species' real skills and keep the rest.
 */
export function normalisePet(p: PetRecord, t: PetTables): boolean {
  let changed = false;
  if (!p.iv) {
    p.iv = [31, 31, 31, 31, 31, 31];
    p.ev = [0, 0, 0, 0, 0, 0];
    changed = true;
  }
  // The first saves had made-up 性格 names (温和, 坚强, 活泼): give them one of the table's.
  if (!NATURES[p.character]) {
    p.character = randomNature();
    changed = true;
  }
  const sp = speciesOf(t, p.race);
  if (sp && p.skills.some((s) => !t.pm.skills[String(s.id)])) {
    p.skills = skillsFor(t, p.race, p.level);
    p.learned = p.skills.map((s) => s.id);
    changed = true;
  }
  const max = statsOf(p, t)[0];
  if (p.hp > max) {
    p.hp = max;
    changed = true;
  }
  return changed;
}

function sView(p: PetRecord, owner: Pick<PetOwner, "id">, t: PetTables) {
  const st = statsOf(p, t);
  return {
    i: p.id,
    ch: p.character,
    c0: Math.min(p.hp, st[0]),
    lv: p.level,
    s0: `${st[0]}#0`,
    nm: nameOf(t, p.race),
    nick: p.nick ?? "",
    r: p.race,
    f: 0,
    st: "",
    st2: "",
    cr1: 0,
    cr2: 0,
    sks: p.skills.map((s) => s.id).join(","),
    m: owner.id,
    pcp: '<pcp r="0" sc=""/>',
    drs: "",
    // Not a 2013 field: the 亚比's first attribute, for the rebuilt battle screen.
    t: speciesOf(t, p.race)?.t[0] ?? t.species[String(p.race)]?.a ?? 0,
  };
}

/** SkillInfo list; the attribute (t), kind (k), power (pw) and description (d) ride along for the rebuilt battle screen. */
export function skillList(p: PetRecord, t: PetTables) {
  return p.skills.map((s) => {
    const d = t.pm.skills[String(s.id)];
    return { id: s.id, name: s.name, pp: `${s.pp}/${s.max}`, ssi: 0, used: true, t: d?.t ?? 0, k: d?.k ?? 0, pw: d?.p ?? 0, d: d?.d ?? "" };
  });
}

export function briefOf(p: PetRecord, owner: Pick<PetOwner, "id">, t: PetTables, extra?: { st?: string; bal?: string }) {
  const v = sView(p, owner, t);
  if (extra?.st) v.st = extra.st;
  // In a battle: its 属性等级 (PetBriefInfo.attributeLevelArr, "攻击#防御#特攻#特防#速度#命中#闪避#暴击").
  if (extra?.bal) (v as typeof v & { bal?: string }).bal = extra.bal;
  return { pmSView: v, skills: skillList(p, t), eqp: [] };
}

export function detailOf(p: PetRecord, owner: PetOwner, t: PetTables) {
  const st = statsOf(p, t);
  const v = sView(p, owner, t);
  const need = expToNext(p, t);
  const sp = speciesOf(t, p.race);
  const iv = p.iv ?? [31, 31, 31, 31, 31, 31];
  const ev = p.ev ?? [0, 0, 0, 0, 0, 0];
  return {
    pmPView: {
      ...v,
      curExp: p.exp,
      curHp: v.c0,
      curAtt: st[1],
      curDef: st[2],
      curSAtt: st[3],
      curSDef: st[4],
      curSpd: st[5],
      s1: `${st[1]}#0`,
      s2: `${st[2]}#0`,
      s3: `${st[3]}#0`,
      s4: `${st[4]}#0`,
      s5: `${st[5]}#0`,
      nx: Math.max(0, need - p.exp),
      totalRace: sp ? sp.s.reduce((a, b) => a + b, 0) : st.reduce((a, b) => a + b, 0),
      speciality: "",
      lc: 0,
      d: p.got,
      "lu%": Math.floor((p.exp / need) * 100),
      i0: iv[0], i1: iv[1], i2: iv[2], i3: iv[3], i4: iv[4], i5: iv[5],
      e0: ev[0], e1: ev[1], e2: ev[2], e3: ev[3], e4: ev[4], e5: ev[5],
      cle: p.exp,
      t: sp?.t[0] ?? t.species[String(p.race)]?.a ?? 0,
    },
    skills: skillList(p, t),
    eqp: [],
  };
}

/** PlayerBriefInfo / PlayerBattleInfo catch-level fields. */
export function catchFields(o: PetOwner) {
  const c = catchLevel(o.catchExp ?? 0);
  return { clv: c.clv, ccle: c.ccle, "clu%": c.pct, cnx: c.cnx };
}

export interface PetDeps {
  load: (ctx: XtContext) => Promise<PetOwner>;
  save: (owner: PetOwner) => Promise<void>;
  tables: () => Promise<PetTables>;
  today: () => string;
  /** addPM (1201) may give any 亚比 (the 工具箱 open, or the walk-throughs' dev commands); else the starters only. */
  anyPet?: boolean;
  /** The time (ms; Date.now without): the 放生仓库's days. */
  now?: () => number;
}

/** The first 亚比 (task 135's StarterPanel): 兔小子, 吉拉, 滴滴 at Lv5, to a player with none. */
const STARTERS = new Set([1, 4, 7]);

const EXT = "PocketMonsterExtension";

export const NO_FOLLOW = "0#0#0";

/** The "p" user variable of a player whose 亚比 follows them. */
export function followVar(p: PetRecord): string {
  return `${p.race},${p.race},${p.id},,,0`;
}

export function installPets(world: World, deps: PetDeps): void {
  const list = (o: PetOwner) => (o.pets ??= []);
  const loadAll = async (ctx: XtContext) => {
    const o = await deps.load(ctx);
    const t = await deps.tables();
    let changed = false;
    for (const p of [...list(o), ...(o.storage ?? [])]) changed = normalisePet(p, t) || changed;
    if (changed) await deps.save(o);
    return { o, t };
  };

  // loadPMMaster -> PlayerBriefInfo
  world.xt(`${EXT}.1101`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const pets = list(o);
    ctx.reply(
      {
        simpleView: {
          curPM: pets[0] ? briefOf(pets[0], o, t) : undefined,
          pmCanBattle: pets.filter((p) => p.hp > 0).length,
          pmmId: o.id,
          slotId: 0,
          pmExp: 0,
        },
        ...catchFields(o),
      },
      "2101",
    );
  });

  // viewAllPM -> {pmList, pms: "currentId#", cui, prv}
  world.xt(`${EXT}.1212`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const pets = list(o);
    ctx.reply({ pmList: pets.map((p) => briefOf(p, o, t)), pms: pets[0] ? `${pets[0].id}#` : "", cui: 0, prv: [] }, "2212");
  });

  // 亚比仓库 (pet/petwarehouse; the 2013 module is lost, the commands are the era PetClient's; the
  // 2012 panel's tabs, 系 filter and sorting are its January 2012 tutorial's, houseteachpetstore):
  //   1213 viewPMInLocation {pmType, page, loc, order, asc, size?}
  //        -> 2213 {pmType, loc, page, totalPage, pages, total, pmList}
  //        pages count from 1 (the era panels that pick a 亚比 of the 仓库, pet/pettraining,
  //        pet/petmix and pet/petrefactor, ask for page 1 with loc 2 and read pmType, page,
  //        totalPage and pmList back, nine to a page)
  //        loc 0 the bag, 1 and 2 the 仓库, 3 the 放生仓库 (let go, not gone yet), 4 the 精英仓库
  //        (its 精英; the revival's number)
  //        pmType 0 every 亚比, n those of 属性 n; order 1 by when it was got, 2 by level; asc
  //        size: to a page (the revival's; STORAGE_PAGE without); each item's pmSView has el
  //        (精英 1), sh (展示 1) and, in the 放生仓库, rl (days it is kept still)
  //   1224 sendPmToFromStorage {id, loc} -> 2224 {result, id, loc}   loc: where it goes (1 仓库, 0 bag);
  //        a 亚比 of the 放生仓库 comes back so too
  //        result 1 done, -1 no such 亚比, -2 the bag is full, -3 the last 亚比 of the bag stays
  //   1225 setExcellentPM {id, e} -> 2225 {result, id, e}   精英 or not (result 1, -1 no such 亚比)
  // The 2013 rules are lost: RECONSTRUCTED (the bag holds 6 as everywhere in the client).
  const STORAGE_PAGE = 9;
  const now = () => (deps.now ? deps.now() : Date.now());
  const attrOf = (t: PetTables, p: PetRecord) => speciesOf(t, p.race)?.t[0] ?? t.species[String(p.race)]?.a ?? 0;
  const located = (o: PetOwner, loc: number): PetRecord[] =>
    loc === 1 || loc === 2 ? (o.storage ??= []) : loc === 4 ? (o.storage ?? []).filter((p) => p.elite) : loc === 3 ? (o.released ?? []) : list(o);
  world.xt(`${EXT}.1213`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    if (dropOldReleased(o, now())) await deps.save(o);
    const loc = Number(ctx.params.loc) | 0;
    const type = Number(ctx.params.pmType) | 0;
    const order = Number(ctx.params.order) | 0;
    const asc = ctx.params.asc === undefined ? true : ctx.params.asc === true || ctx.params.asc === "true" || Number(ctx.params.asc) === 1;
    const size = Math.max(1, Math.min(60, Number(ctx.params.size) | 0 || STORAGE_PAGE));
    let all = located(o, loc).slice();
    if (type > 0) all = all.filter((p) => attrOf(t, p) === type);
    if (order === 2) all.sort((a, b) => a.level - b.level || a.id - b.id);
    if ((order === 1 || order === 2) && !asc) all.reverse();
    const pages = Math.max(1, Math.ceil(all.length / size));
    const page = Math.max(1, Math.min(pages, Number(ctx.params.page) | 0));
    const shown = loc === 0 ? all : all.slice((page - 1) * size, page * size);
    const left = (p: PetRecord) => Math.max(0, Math.ceil((RELEASE_KEEP_MS - (now() - (p.relAt ?? 0))) / (24 * 3600 * 1000)));
    const pmList = shown.map((p) => {
      const b = briefOf(p, o, t);
      return { ...b, pmSView: { ...b.pmSView, el: p.elite ? 1 : 0, sh: o.showPet === p.id ? 1 : 0, ...(loc === 3 ? { rl: left(p) } : {}) } };
    });
    ctx.reply({ pmType: type, loc, page, totalPage: pages, pages, total: all.length, pmList }, "2213");
  });
  world.xt(`${EXT}.1224`, async (ctx) => {
    const o = await deps.load(ctx);
    dropOldReleased(o, now());
    const id = Number(ctx.params.id);
    const loc = Number(ctx.params.loc) | 0;
    const bag = list(o);
    const store = (o.storage ??= []);
    const gone = (o.released ??= []);
    const answer = (result: number) => ctx.reply({ result, id, loc }, "2224");
    const back = gone.findIndex((p) => p.id === id);
    if (back >= 0) {
      if (loc === 0 && bag.length >= 6) return answer(-2);
      const [p] = gone.splice(back, 1);
      delete p.relAt;
      (loc === 0 ? bag : store).push(p);
      await deps.save(o);
      return answer(1);
    }
    const from = loc === 1 ? bag : store;
    const to = loc === 1 ? store : bag;
    const i = from.findIndex((p) => p.id === id);
    if (i < 0) return answer(-1);
    if (loc === 0 && bag.length >= 6) return answer(-2);
    if (loc === 1 && bag.length <= 1) return answer(-3);
    const [p] = from.splice(i, 1);
    to.push(p);
    if (loc === 1 && o.followPet === id) o.followPet = 0;
    await deps.save(o);
    answer(1);
  });
  world.xt(`${EXT}.1225`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id);
    const e = ctx.params.e === true || ctx.params.e === "true" || Number(ctx.params.e) === 1;
    const p = [...list(o), ...(o.storage ?? [])].find((x) => x.id === id);
    if (!p) return ctx.reply({ result: -1, id, e }, "2225");
    if (e) p.elite = true;
    else delete p.elite;
    await deps.save(o);
    ctx.reply({ result: 1, id, e }, "2225");
  });

  // 放生 (from the 亚比仓库): revival_release {id} -> revival_release {result, id}
  //   result 1 let go (into the 放生仓库, gone for good after RELEASE_KEEP_MS), -1 no such 亚比,
  //   -3 the last 亚比 of the bag stays
  world.xt(`${EXT}.revival_release`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id);
    const answer = (result: number) => ctx.reply({ result, id }, "revival_release");
    const bag = list(o);
    const store = (o.storage ??= []);
    const inBag = bag.findIndex((p) => p.id === id);
    const inStore = store.findIndex((p) => p.id === id);
    if (inBag < 0 && inStore < 0) return answer(-1);
    if (inBag >= 0 && bag.length <= 1) return answer(-3);
    const [p] = inBag >= 0 ? bag.splice(inBag, 1) : store.splice(inStore, 1);
    p.relAt = now();
    delete p.elite;
    (o.released ??= []).push(p);
    dropOldReleased(o, now());
    if (o.followPet === id) o.followPet = 0;
    if (o.showPet === id) o.showPet = 0;
    await deps.save(o);
    answer(1);
  });

  // 亚比昵称 (the 亚比仓库's pen by the name): revival_nick {id, nick} -> revival_nick {result, id, nick}
  //   result 1 done ("" gives back the 亚比's own name), -1 no such 亚比, -2 too long or not allowed
  world.xt(`${EXT}.revival_nick`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id);
    const nick = String(ctx.params.nick ?? "").replace(/\s+/g, "").slice(0, 32);
    const p = [...list(o), ...(o.storage ?? [])].find((x) => x.id === id);
    if (!p) return ctx.reply({ result: -1, id, nick }, "revival_nick");
    if ([...nick].length > 6 || /[<>&"'\\]/.test(nick)) return ctx.reply({ result: -2, id, nick }, "revival_nick");
    if (nick) p.nick = nick;
    else delete p.nick;
    await deps.save(o);
    ctx.reply({ result: 1, id, nick }, "revival_nick");
  });

  // 展示 (the 亚比仓库's): revival_show {id} -> revival_show {result, id}   the 亚比 shown in the
  // owner's 家园 (furniture/b000247 shows it from revival_garden's info); id 0 or the one shown: none.
  world.xt(`${EXT}.revival_show`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    const has = id > 0 && [...list(o), ...(o.storage ?? [])].some((x) => x.id === id);
    if (id > 0 && !has) return ctx.reply({ result: -1, id }, "revival_show");
    o.showPet = id > 0 && o.showPet !== id ? id : 0;
    await deps.save(o);
    ctx.reply({ result: 1, id: o.showPet }, "revival_show");
  });

  // viewSinglePM {id} -> {pm: PetDetailedInfo}   (a 亚比 of the 放生仓库 too, for its page there)
  // The 2010 panels of the 亚比特训 (pet/pettraining, pet/petbetraining) read their own names
  // of the same things: id, name, level, next (experience still to go), character, getDate.
  world.xt(`${EXT}.1211`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const p = [...list(o), ...(o.storage ?? []), ...(o.released ?? [])].find((x) => x.id === Number(ctx.params.id));
    if (!p) return ctx.reply({ msg: "没有这只亚比" }, "2211");
    const d = detailOf(p, o, t);
    const era = { id: p.id, name: p.nick || d.pmPView.nm, level: p.level, next: d.pmPView.nx, character: p.character, getDate: p.got };
    ctx.reply({ pm: { ...d, pmPView: { ...d.pmPView, el: p.elite ? 1 : 0, sh: o.showPet === p.id ? 1 : 0, ...era } } }, "2211");
  });

  // addPM {raceId, level, type}: the revival's first-亚比 choice gives the starter this way (and
  // the walk-throughs' dev commands, any 亚比). Where the 工具箱 is closed, nothing else: a client
  // is not the 2013 one for sure, and this would give any 亚比 at any level.
  world.xt(`${EXT}.1201`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const race = Number(ctx.params.raceId);
    if (!t.species[String(race)] && !t.pm.species[String(race)]) return ctx.reply({ msg: "没有这种亚比" }, "2201");
    const pets = list(o);
    let level = Math.max(1, Math.min(100, Number(ctx.params.level) || 5));
    if (!deps.anyPet) {
      if (!STARTERS.has(race) || pets.length > 0 || (o.storage?.length ?? 0) > 0) return ctx.reply({ msg: "这个服务器关闭了工具箱。" }, "2201");
      level = 5;
    }
    const p = newPet(o, t, race, level, deps.today());
    if (pets.length >= 6) {
      // A full bag: to the 亚比仓库, as a catch with a full bag goes (RECONSTRUCTED).
      (o.storage ??= []).push(p);
      await deps.save(o);
      return ctx.reply({ msg: `${nameOf(t, race)}已经放进了亚比仓库` }, "2201");
    }
    pets.push(p);
    await deps.save(o);
    ctx.reply({ pm: detailOf(p, o, t) }, "2201");
  });

  // setCurPM {id}: the first pet of the list fights first.
  world.xt(`${EXT}.1221`, async (ctx) => {
    const o = await deps.load(ctx);
    const pets = list(o);
    const i = pets.findIndex((x) => x.id === Number(ctx.params.id));
    if (i > 0) [pets[0], pets[i]] = [pets[i], pets[0]];
    await deps.save(o);
    ctx.reply({ id: Number(ctx.params.id) }, "2221");
  });

  // viewAllSkill {id} -> every skill the 亚比 has learnt.
  world.xt(`${EXT}.1231`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const p = list(o).find((x) => x.id === Number(ctx.params.id));
    if (!p) return ctx.reply({ id: Number(ctx.params.id), skills: [] }, "2231");
    const carried = new Set(p.skills.map((s) => s.id));
    // Saves of 亚比 made at a high level before they learnt their whole line get it now.
    const all = learntFor(t, p.race, p.level, p.skills);
    if (all.some((id) => !(p.learned ?? []).includes(id))) {
      p.learned = [...new Set([...(p.learned ?? []), ...all])];
      await deps.save(o);
    }
    const ids = [...new Set([...(p.learned ?? []), ...carried])];
    ctx.reply(
      {
        id: p.id,
        skills: ids.map((id) => {
          const d = t.pm.skills[String(id)];
          return { ...skillOf(t, id), pp: `${p.skills.find((s) => s.id === id)?.pp ?? skillOf(t, id).max}/${skillOf(t, id).max}`, used: carried.has(id), power: d?.p ?? 0, kind: d?.k ?? 0, desc: d?.d ?? "" };
        }),
      },
      "2231",
    );
  });

  // setUsedSkill {id, sks: "a,b,c,d"}: which learnt skills to carry.
  world.xt(`${EXT}.1232`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const p = list(o).find((x) => x.id === Number(ctx.params.id));
    const ids = String(ctx.params.sks ?? "").split(",").map(Number).filter((n) => n > 0);
    // Each skill once (one carried twice would be two PP pools of it), and not in a fight.
    if (!p || inFight(world, o.id) || ids.length === 0 || ids.length > 4 || new Set(ids).size !== ids.length || ids.some((id) => !(p.learned ?? []).includes(id) && !p.skills.some((s) => s.id === id))) {
      return ctx.reply({ id: Number(ctx.params.id), res: -1 }, "2232");
    }
    p.skills = ids.map((id) => p.skills.find((s) => s.id === id) ?? skillOf(t, id));
    await deps.save(o);
    ctx.reply({ id: p.id, sks: ids.join(","), res: 1 }, "2232");
  });

  // Revival: heal every pet (the 2013 HELLO/亚比治疗 went through other services).
  world.xt(`${EXT}.revival_heal`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    if (inFight(world, o.id)) return ctx.reply({ ok: 0 });
    for (const p of list(o)) {
      p.hp = statsOf(p, t)[0];
      for (const s of p.skills) s.pp = s.max;
    }
    await deps.save(o);
    ctx.reply({ ok: 1 });
  });

  // The following 亚比 (PetClient2, "PetExtension"): 54_8 {pi} lets one follow,
  // 54_9 {} sends it back into the bag. Everyone in the room is told (the 2013
  // PetFollowManager listens for both) and the player's "p" user variable
  // carries it to later arrivals: "raceId,viewId,petId,dress,ind,indLv", "0#0#0"
  // for none.
  world.xt(`PetExtension.54_8`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.pi);
    const p = list(o).find((x) => x.id === id);
    if (!p) return;
    o.followPet = id;
    await deps.save(o);
    world.setUserVars(ctx.session, { p: followVar(p) });
    ctx.broadcast({ name: o.name, pRId: p.race, pVId: p.race, pId: p.id, dr: "", ind: "", indLv: 0 }, "54_8", true);
  });

  world.xt(`PetExtension.54_9`, async (ctx) => {
    const o = await deps.load(ctx);
    o.followPet = -1;
    await deps.save(o);
    world.setUserVars(ctx.session, { p: NO_FOLLOW });
    ctx.broadcast({ name: o.name }, "54_9", true);
  });

  // 亚比技能排序 (the HELLO menu's): PetClient2.setSortSkill 54_21 {id, sks} — the ids of the
  // skills it carries in their new order ("," or "#" between them) -> 54_21 {res, id}. Only a
  // new order of the same skills is taken. RECONSTRUCTED (the reply of 2013 is lost).
  world.xt(`PetExtension.54_21`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    const pet = [...list(o), ...(o.storage ?? [])].find((p) => p.id === id);
    const ids = String(ctx.params.sks ?? "").split(/[,#]/).filter(Boolean).map(Number);
    const same = pet && ids.length === pet.skills.length && [...ids].sort().join() === pet.skills.map((s) => s.id).sort().join();
    if (!pet || !same) return ctx.reply({ res: 0, id }, "54_21");
    pet.skills = ids.map((sid) => pet.skills.find((s) => s.id === sid)!);
    await deps.save(o);
    ctx.reply({ res: 1, id }, "54_21");
  });
}
