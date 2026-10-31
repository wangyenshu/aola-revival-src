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
  skillsAt,
  type PmData,
  type PmSpecies,
} from "./pmdata.ts";
import type { World, XtContext } from "./server.ts";

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
}

/** Fields of UserRecord the pet code uses. */
export interface PetOwner {
  id: number;
  name: string;
  pets?: PetRecord[];
  /** 亚比 that did not fit in the bag (仓库). */
  storage?: PetRecord[];
  nextPetId?: number;
  followPet?: number;
  /** Experience of the 捕捉等级. */
  catchExp?: number;
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

export function statsOf(p: Pick<PetRecord, "race" | "level" | "iv" | "ev"> & { character?: string }, t?: PetTables): number[] {
  const sp = t ? speciesOf(t, p.race) : undefined;
  if (sp) return calcStats(sp, p.level, p.iv, p.ev, p.character);
  return GROWTH.map(([b, k]) => b + k * p.level);
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
    learned: skills.map((s) => s.id),
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

/** SkillInfo list; the attribute (t), kind (k) and power (pw) ride along for the rebuilt battle screen. */
export function skillList(p: PetRecord, t: PetTables) {
  return p.skills.map((s) => {
    const d = t.pm.skills[String(s.id)];
    return { id: s.id, name: s.name, pp: `${s.pp}/${s.max}`, ssi: 0, used: true, t: d?.t ?? 0, k: d?.k ?? 0, pw: d?.p ?? 0 };
  });
}

export function briefOf(p: PetRecord, owner: Pick<PetOwner, "id">, t: PetTables, extra?: { st?: string }) {
  const v = sView(p, owner, t);
  if (extra?.st) v.st = extra.st;
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
}

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

  // 亚比仓库 (pet/petwarehouse; the 2013 module is lost, the commands are the era PetClient's):
  //   1213 viewPMInLocation {pmType, page, loc, order, asc} -> 2213 {loc, page, pages, total, pmList}
  //        loc 1 the 仓库 (STORAGE_PAGE to a page), loc 0 the bag
  //   1224 sendPmToFromStorage {id, loc} -> 2224 {result, id, loc}   loc: where it goes (1 仓库, 0 bag)
  //        result 1 done, -1 no such 亚比, -2 the bag is full, -3 the last 亚比 of the bag stays
  // The 2013 rules are lost: RECONSTRUCTED (the bag holds 6 as everywhere in the client).
  const STORAGE_PAGE = 12;
  world.xt(`${EXT}.1213`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const loc = Number(ctx.params.loc) | 0;
    const all = loc === 1 ? (o.storage ??= []) : list(o);
    const pages = Math.max(1, Math.ceil(all.length / STORAGE_PAGE));
    const page = Math.max(0, Math.min(pages - 1, Number(ctx.params.page) | 0));
    const shown = loc === 1 ? all.slice(page * STORAGE_PAGE, (page + 1) * STORAGE_PAGE) : all;
    ctx.reply({ loc, page, pages, total: all.length, pmList: shown.map((p) => briefOf(p, o, t)) }, "2213");
  });
  world.xt(`${EXT}.1224`, async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id);
    const loc = Number(ctx.params.loc) | 0;
    const bag = list(o);
    const store = (o.storage ??= []);
    const from = loc === 1 ? bag : store;
    const to = loc === 1 ? store : bag;
    const i = from.findIndex((p) => p.id === id);
    const answer = (result: number) => ctx.reply({ result, id, loc }, "2224");
    if (i < 0) return answer(-1);
    if (loc === 0 && bag.length >= 6) return answer(-2);
    if (loc === 1 && bag.length <= 1) return answer(-3);
    const [p] = from.splice(i, 1);
    to.push(p);
    if (loc === 1 && o.followPet === id) o.followPet = 0;
    await deps.save(o);
    answer(1);
  });

  // viewSinglePM {id} -> {pm: PetDetailedInfo}
  world.xt(`${EXT}.1211`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const p = [...list(o), ...(o.storage ?? [])].find((x) => x.id === Number(ctx.params.id));
    if (!p) return ctx.reply({ msg: "没有这只亚比" }, "2211");
    ctx.reply({ pm: detailOf(p, o, t) }, "2211");
  });

  // addPM {raceId, level, type}: tasks and the revival's first-亚比 choice give pets this way.
  world.xt(`${EXT}.1201`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
    const race = Number(ctx.params.raceId);
    if (!t.species[String(race)] && !t.pm.species[String(race)]) return ctx.reply({ msg: "没有这种亚比" }, "2201");
    const pets = list(o);
    const p = newPet(o, t, race, Math.max(1, Math.min(100, Number(ctx.params.level) || 5)), deps.today());
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
    if (!p || ids.length === 0 || ids.length > 4 || ids.some((id) => !(p.learned ?? []).includes(id) && !p.skills.some((s) => s.id === id))) {
      return ctx.reply({ id: Number(ctx.params.id), res: -1 }, "2232");
    }
    p.skills = ids.map((id) => p.skills.find((s) => s.id === id) ?? skillOf(t, id));
    await deps.save(o);
    ctx.reply({ id: p.id, sks: ids.join(","), res: 1 }, "2232");
  });

  // Revival: heal every pet (the 2013 HELLO/亚比治疗 went through other services).
  world.xt(`${EXT}.revival_heal`, async (ctx) => {
    const { o, t } = await loadAll(ctx);
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
}
