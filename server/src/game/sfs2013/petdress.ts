// 亚比装扮: the clothes a 亚比 wears (the 2011 pet clothes, kept in the 2013 tables).
//
//   MaterialExtension 61_5 {uid}   -> 61_5 {pd: [{id, qt, uq}]}: the pieces owned (qt) and worn (uq),
//                                     as the 2013 material/petclothesservice reads them
//   PetExtension 54_24 {pi, dr}    -> 54_24 {res, pi, dr, msg}: 亚比 pi wears dr ("30002;30003", ""
//                                     for none; PetClient2.setPetAvatar)
//
// The pieces are the 2013 ClothesData's PetClothes (30001–30011), each for one 亚比 (raceId), as
// PetDressInfosMap lists the ten that can wear them; their parts (ClothesPartsDatas) sit on that
// 亚比's walking figure and big picture (skin/, skinview/a0300NN). What a 亚比 wears is its pmSView
// "drs" and the dress field of the following 亚比 ("p", 54_8). The 2011 dressing panel and the
// server's replies are lost: the rules here are RECONSTRUCTED (a piece is worn by one 亚比 at a time).
import type { PetOwner, PetRecord } from "./pets.ts";
import type { World, XtContext } from "./server.ts";

/** The pet clothes of the 2013 ClothesData: id -> name and the 亚比 (race) it is for. */
export const PET_CLOTHES: Record<number, { n: string; race: number }> = {
  30001: { n: "糖果蝴蝶眼镜", race: 10 },
  30002: { n: "绅士披风", race: 255 },
  30003: { n: "绅士礼帽", race: 255 },
  30004: { n: "飞行员头盔", race: 54 },
  30005: { n: "索里德头巾", race: 282 },
  30006: { n: "焰魔棒", race: 293 },
  30007: { n: "麋鹿小帽", race: 189 },
  30008: { n: "印第安羽毛帽", race: 72 },
  30009: { n: "可爱雪白头花", race: 58 },
  30010: { n: "水晶糖果花", race: 236 },
  30011: { n: "七彩披肩", race: 19 },
};

/** Most of one piece a player keeps. */
export const PET_CLOTHES_MAX = 99;

export interface DressOwner extends PetOwner {
  /** 亚比装扮 owned: id -> how many. */
  petClothes?: Record<string, number>;
}

/** The pieces of dr ("30002;30003") the 亚比 of `race` can wear, each once, in id order. */
export function dressFor(race: number, dr: string | undefined): number[] {
  const ids = String(dr ?? "")
    .split(/[;,#]/)
    .map(Number)
    .filter((id) => PET_CLOTHES[id]?.race === race);
  return [...new Set(ids)].sort((a, b) => a - b);
}

/** What a 亚比 wears now ("" for none): a form it evolved into wears none of its old pieces. */
export function wornOf(p: Pick<PetRecord, "race"> & { drs?: string }): string {
  return dressFor(p.race, p.drs).join(";");
}

function allPets(o: PetOwner): PetRecord[] {
  return [...(o.pets ?? []), ...(o.storage ?? [])];
}

/** How many of piece `id` the player's 亚比 wear (but `except`). */
function wornCount(o: PetOwner, id: number, except?: PetRecord): PetRecord[] {
  return allPets(o).filter((p) => p !== except && dressFor(p.race, (p as { drs?: string }).drs).includes(id));
}

/** 61_5's list: every piece owned, with how many are worn. */
export function petClothesList(o: DressOwner): { id: number; qt: number; uq: number }[] {
  return Object.entries(o.petClothes ?? {})
    .map(([k, n]) => ({ id: Number(k), qt: Math.max(0, Number(n) | 0) }))
    .filter((x) => PET_CLOTHES[x.id] && x.qt > 0)
    .sort((a, b) => a.id - b.id)
    .map((x) => ({ ...x, uq: Math.min(x.qt, wornCount(o, x.id).length) }));
}

/** One of every piece more (the 工具箱), PET_CLOTHES_MAX at most; how many kinds grew. */
export function giveAllPetClothes(o: DressOwner): number {
  const m = (o.petClothes ??= {});
  let n = 0;
  for (const id of Object.keys(PET_CLOTHES)) {
    const had = Number(m[id]) | 0;
    if (had < PET_CLOTHES_MAX) {
      m[id] = had + 1;
      n++;
    }
  }
  return n;
}

export interface PetDressDeps {
  load: (ctx: XtContext) => Promise<DressOwner>;
  save: (o: DressOwner) => Promise<void>;
  /** The 亚比 follows its owner: its room sees what it wears. */
  following: (ctx: XtContext, o: DressOwner, p: PetRecord) => void;
  /** A 亚比's name for the replies. */
  nameOf: (p: PetRecord) => Promise<string>;
}

export function installPetDress(world: World, deps: PetDressDeps): void {
  world.xt("MaterialExtension.61_5", async (ctx) => {
    const o = await deps.load(ctx);
    ctx.reply({ pd: petClothesList(o) }, "61_5");
  });

  world.xt("PetExtension.54_24", async (ctx) => {
    const o = await deps.load(ctx);
    const pi = Number(ctx.params.pi) | 0;
    const pet = allPets(o).find((p) => p.id === pi) as (PetRecord & { drs?: string }) | undefined;
    const fail = (msg: string) => ctx.reply({ res: 0, pi, dr: pet ? wornOf(pet) : "", msg }, "54_24");
    if (!pet) return fail("没有找到这只亚比。");
    const asked = String(ctx.params.dr ?? "")
      .split(/[;,#]/)
      .filter(Boolean)
      .map(Number);
    const dr = dressFor(pet.race, asked.join(";"));
    if (dr.length !== new Set(asked).size) return fail("这只亚比穿不了这件装扮。");
    for (const id of dr) {
      const own = Number(o.petClothes?.[String(id)]) | 0;
      const others = wornCount(o, id, pet);
      if (own <= 0) return fail(`你还没有${PET_CLOTHES[id].n}。`);
      if (others.length >= own) return fail(`${PET_CLOTHES[id].n}穿在${await deps.nameOf(others[0])}身上，先给它脱下吧。`);
    }
    pet.drs = dr.join(";");
    if (!pet.drs) delete pet.drs;
    await deps.save(o);
    deps.following(ctx, o, pet);
    ctx.reply({ res: 1, pi, dr: wornOf(pet), msg: "" }, "54_24");
  });
}
