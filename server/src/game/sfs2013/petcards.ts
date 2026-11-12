// 战术卡 (PetCard, MaterialTypes.PET_CARD 8) for the 2013 server: a 亚比 wears up to three, one
// of each type (A, B, C: PetCardTypes 0, 1, 2), and each adds to (or takes from) its stats.
// The cards are the January 2013 materialdata PetCardData (name, type, grade, and the six
// numbers it adds: 体力, 速度, 攻击, 防御, 特攻, 特防). The 2013 server and the bag's page for
// them are lost: what the commands answer, that a card worn is out of the inventory (and back
// when taken off), and where cards come from (a 亚比 BOSS beaten, CARD_DROP percent) are
// RECONSTRUCTED.
//
//   MaterialExtension.61_7 {}          -> {cards: [{id, qt, uq}]}   the cards one has (PetCardService)
//   PetExtension.54_25 {cid, pid}      -> {res, pid, cid, cards: [A, B, C], msg}   put card cid on 亚比 pid
//                                         (its type's place; the card there goes back), or, worn
//                                         there already, take it off. res 1 done, 0 refused.
// A card worn or taken off changes the inventory as onAmountUpdated "8_<id>_0_<±1>" says, and
// the 亚比's stats (pets.ts statsOf: cardBonus).

import { inFight } from "./fighting.ts";
import type { World, XtContext } from "./server.ts";

export const PET_CARD = 8;
/** A 亚比 BOSS beaten gives a 战术卡 this often, in percent (RECONSTRUCTED). */
export const CARD_DROP = 25;

export interface CardDef {
  name: string;
  /** PetCardTypes: 0 A, 1 B, 2 C (the place it is worn in). */
  type: number;
  /** 0 斗士, 1 武者, 2 勇者. */
  color: number;
  hp: number;
  sp: number;
  at: number;
  de: number;
  sa: number;
  sd: number;
}

export const PET_CARDS: Record<number, CardDef> = {
  1: { name: "忠诚之斗士卡", type: 0, color: 0, hp: 20, sp: -10, at: 0, de: 0, sa: 0, sd: 0 },
  2: { name: "敏感之斗士卡", type: 0, color: 0, hp: -10, sp: 20, at: 0, de: 0, sa: 0, sd: 0 },
  3: { name: "孤僻之斗士卡", type: 1, color: 0, hp: 0, sp: 0, at: 20, de: -10, sa: 0, sd: 0 },
  4: { name: "调皮之斗士卡", type: 1, color: 0, hp: 0, sp: 0, at: 20, de: 0, sa: 0, sd: -10 },
  5: { name: "固执之斗士卡", type: 1, color: 0, hp: 0, sp: 0, at: 20, de: 0, sa: -10, sd: 0 },
  6: { name: "无虑之斗士卡", type: 2, color: 0, hp: 0, sp: 0, at: 0, de: 20, sa: 0, sd: -10 },
  7: { name: "体力之武者卡", type: 0, color: 1, hp: 25, sp: 0, at: 0, de: 0, sa: 0, sd: 0 },
  8: { name: "速度之武者卡", type: 0, color: 1, hp: 0, sp: 25, at: 0, de: 0, sa: 0, sd: 0 },
  9: { name: "攻击之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 25, de: 0, sa: 0, sd: 0 },
  10: { name: "特攻之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 25, sd: 0 },
  11: { name: "防御之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 25, sa: 0, sd: 0 },
  12: { name: "特防之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 0, sd: 25 },
  13: { name: "强悍之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 15, de: 15, sa: 0, sd: 0 },
  14: { name: "智谋之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 15, sd: 15 },
  15: { name: "铁壁之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 15, sa: 0, sd: 15 },
  16: { name: "体力之勇者卡", type: 0, color: 2, hp: 80, sp: 0, at: 0, de: 0, sa: 0, sd: 0 },
  17: { name: "敏感之武者卡", type: 0, color: 1, hp: -30, sp: 35, at: 0, de: 0, sa: 0, sd: 0 },
  18: { name: "孤僻之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 35, de: -25, sa: 0, sd: 0 },
  19: { name: "洞察之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: 35, sd: -25 },
  20: { name: "淘气之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 50, sa: -20, sd: 0 },
  21: { name: "沉着之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: -20, de: 0, sa: 0, sd: 50 },
  22: { name: "防御之勇者卡", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 80, sa: 0, sd: 0 },
  23: { name: "特防之勇者卡", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 0, sa: 0, sd: 80 },
  24: { name: "速度之勇者卡", type: 0, color: 2, hp: 0, sp: 60, at: 0, de: 0, sa: 0, sd: 0 },
  25: { name: "固执之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: 35, de: 0, sa: -25, sd: 0 },
  26: { name: "保守之武者卡", type: 1, color: 1, hp: 0, sp: 0, at: -25, de: 0, sa: 35, sd: 0 },
  27: { name: "无虑之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 50, sa: 0, sd: -20 },
  28: { name: "温顺之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: -20, sa: 0, sd: 50 },
  29: { name: "铁壁之勇者卡", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 45, sa: 0, sd: 45 },
  30: { name: "强体之勇者卡", type: 0, color: 2, hp: 100, sp: 0, at: -40, de: 0, sa: -40, sd: 0 },
  31: { name: "大胆之勇者卡", type: 2, color: 2, hp: 0, sp: 0, at: -50, de: 90, sa: 0, sd: 0 },
  32: { name: "慎重之勇者卡", type: 2, color: 2, hp: 0, sp: 0, at: 0, de: 0, sa: -50, sd: 90 },
  33: { name: "超攻之勇者卡", type: 1, color: 2, hp: 0, sp: 0, at: 40, de: 0, sa: 40, sd: 0 },
  34: { name: "大胆之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: -20, de: 40, sa: 0, sd: 0 },
  35: { name: "慎重之武者卡", type: 2, color: 1, hp: 0, sp: 0, at: 0, de: 0, sa: -20, sd: 40 },
};

/** What a 亚比's 战术卡 add to its stats, in statsOf's order: 体力, 攻击, 防御, 特攻, 特防, 速度. */
export function cardBonus(cards: readonly number[] | undefined): number[] {
  const add = [0, 0, 0, 0, 0, 0];
  for (const id of cards ?? []) {
    const c = PET_CARDS[id];
    if (!c) continue;
    add[0] += c.hp;
    add[1] += c.at;
    add[2] += c.de;
    add[3] += c.sa;
    add[4] += c.sd;
    add[5] += c.sp;
  }
  return add;
}

/** A 亚比's three places (A, B, C), 0 where none is worn. */
export function cardsOf(pet: { cards?: number[] }): number[] {
  return [0, 1, 2].map((i) => Number(pet.cards?.[i]) || 0);
}

/** A 战术卡 at random (a 亚比 BOSS beaten), CARD_DROP percent of the time; 0 otherwise. */
export function cardDrop(rng: () => number = Math.random): number {
  if (rng() * 100 >= CARD_DROP) return 0;
  const ids = Object.keys(PET_CARDS).map(Number);
  // The 勇者 cards (grade 2) a third as often as the others.
  const weights = ids.map((id) => (PET_CARDS[id].color === 2 ? 1 : 3));
  let r = rng() * weights.reduce((a, b) => a + b, 0);
  for (let i = 0; i < ids.length; i++) if ((r -= weights[i]) < 0) return ids[i];
  return ids[ids.length - 1];
}

export interface CardOwner {
  items?: Record<string, Record<string, number>>;
  pets?: { id: number; hp: number; cards?: number[] }[];
}

export interface CardDeps<R extends CardOwner> {
  load: (ctx: XtContext) => Promise<R>;
  save: (o: R) => Promise<void>;
  /** The 亚比's 体力 at most, cards and all (pets.ts maxHpOf). */
  maxHp: (o: R, pet: NonNullable<R["pets"]>[number]) => Promise<number>;
}

export function installPetCards<R extends CardOwner>(world: World, deps: CardDeps<R>): void {
  world.xt("MaterialExtension.61_7", async (ctx) => {
    const o = await deps.load(ctx);
    const have = o.items?.[String(PET_CARD)] ?? {};
    const cards = Object.entries(have)
      .filter(([id, n]) => n > 0 && PET_CARDS[Number(id)])
      .map(([id, n]) => ({ id: Number(id), qt: n, uq: 0 }));
    ctx.reply({ cards }, "61_7");
  });

  world.xt("PetExtension.54_25", async (ctx) => {
    const o = await deps.load(ctx);
    const pid = Number(ctx.params.pid) | 0, cid = Number(ctx.params.cid) | 0;
    const pet = (o.pets ?? []).find((p) => p.id === pid);
    const reply = (res: number, msg: string, cards: number[] = pet ? cardsOf(pet) : [0, 0, 0]) =>
      ctx.reply({ res, pid, cid, cards, msg }, "54_25");
    if (!pet) return reply(0, "背包里没有这只亚比。");
    // cid 0: only what it wears.
    if (cid === 0) return reply(1, "");
    // Not in a fight (its 亚比 are the bag's own: a card changes its 体力 and stats).
    if (inFight(world, (o as { id?: number }).id ?? -1)) return reply(0, "战斗还没有结束，现在不能换战术卡。");
    const def = PET_CARDS[cid];
    if (!def) return reply(0, "没有这种战术卡。");
    const have = ((o.items ??= {})[String(PET_CARD)] ??= {});
    const cards = cardsOf(pet);
    const changed: [number, number][] = [];
    let msg: string;
    if (cards[def.type] === cid) {
      cards[def.type] = 0;
      changed.push([cid, 1]);
      msg = `取下了「${def.name}」。`;
    } else {
      if (!((have[String(cid)] ?? 0) > 0)) return reply(0, "你没有这张战术卡。");
      const before = cards[def.type];
      cards[def.type] = cid;
      changed.push([cid, -1]);
      if (before) changed.push([before, 1]);
      msg = `装上了「${def.name}」。`;
    }
    for (const [id, d] of changed) {
      const n = (have[String(id)] ?? 0) + d;
      if (n > 0) have[String(id)] = n;
      else delete have[String(id)];
    }
    pet.cards = cards.some(Boolean) ? cards : undefined;
    // Its 体力 within its new most.
    pet.hp = Math.min(pet.hp, await deps.maxHp(o, pet));
    await deps.save(o);
    for (const [id, d] of changed) ctx.reply({ amount: `${PET_CARD}_${id}_0_${d}` }, "onAmountUpdated");
    reply(1, msg, cards);
  });
}
