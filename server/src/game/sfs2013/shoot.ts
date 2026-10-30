// 射击 for the 2013 server: ShootExtension (64_x), the commands of the shoot
// module's ShootClient (the later module, rebuilt against the 2013 interfaces).
//
//   64_5 {}                                     -> {cards: [{i, q}]}   shoot cards owned
//   64_1 {cardId, target, targetType, x, y, mine}  fire: everyone in the room gets
//        64_2 {info, hit} (info: key, from, cardId, target, targetType, x, y, roomId, mine);
//        a card used up is taken (onAmountUpdated with a negative amount), and a player
//        hit wears the card's effect, in his user variable shoot_effect
//        ("name;effects worn;effect added;effects taken off"), for the card's seconds.
//   64_3 {targetType, hit, key}                 the target's own check of a hit (the
//        original server asked the hit player's client first); the revival counts every
//        shot as a hit and does not wait for it.
//
// The 2013 server is lost (RECONSTRUCTED). Cards come from materials.json type 4
// (tools/gen_materials.py --shoot): [price, sale, rmb, maxQuantity, vip, name, effect, seconds].
// Everyone has 光能射线 and 冰冻射线 (cards 1, 2); cards one may own only one of are never used up,
// the others (射击卡 bought in the 道具店, maxQuantity 9999) one per shot.

import type { Session } from "../../core/emulator.ts";
import type { World, XtContext } from "./server.ts";

export const SHOOT_EXT = "ShootExtension";
/**
 * Cards every player has and never uses up: 光能射线 (1) and 冰冻射线 (2, the
 * 寒冰射线 players remember; story scenes ask for it to put out fires, e.g.
 * 火山 and the 海枯之星 quests). In 2013 冰冻射线 cost 40 晶币 once; giving it
 * away is a choice of this revival.
 */
export const FREE_CARDS: Record<string, number> = { "1": 1, "2": 1 };
/** ShootTargetTypes.Player. */
const TARGET_PLAYER = 2;

export type CardRow = [number, number, number, number, number, string, number?, number?];

export interface ShootOwner {
  name: string;
  items?: Record<string, Record<string, number>>;
}

export interface ShootDeps {
  me(ctx: XtContext): Promise<ShootOwner>;
  save(o: ShootOwner): Promise<void>;
  cards(): Promise<Record<string, CardRow>>;
  /** Timers, so tests can run them. */
  later?(ms: number, fn: () => void): void;
}

export function cardsOf(o: ShootOwner): Record<string, number> {
  const c = ((o.items ??= {})["4"] ??= {});
  for (const [id, q] of Object.entries(FREE_CARDS)) if (!c[id]) c[id] = q;
  return c;
}

export function installShoot(world: World, deps: ShootDeps): void {
  const later = deps.later ?? ((ms, fn) => void setTimeout(fn, ms));
  let shots = 0;
  /** Player name -> effect id -> when it ends (ms), for what shoot_effect says. */
  const worn = new Map<string, Map<number, number>>();

  world.xt(`${SHOOT_EXT}.64_5`, async (ctx) => {
    const o = await deps.me(ctx);
    const c = cardsOf(o);
    await deps.save(o);
    ctx.reply({ cards: Object.entries(c).filter(([, q]) => q > 0).map(([i, q]) => ({ i: Number(i), q })) });
  });

  world.xt(`${SHOOT_EXT}.64_3`, () => {});

  world.xt(`${SHOOT_EXT}.64_1`, async (ctx) => {
    const p = ctx.params;
    const cardId = Number(p.cardId) | 0;
    const o = await deps.me(ctx);
    const owned = cardsOf(o);
    const row = (await deps.cards())[String(cardId)];
    if (!row || !(owned[cardId] > 0)) return;
    const [, , , maxQ, , , effect = 0, seconds = 0] = row;
    if (maxQ > 1) {
      owned[cardId] -= 1;
      if (owned[cardId] <= 0) delete owned[cardId];
      await deps.save(o);
      ctx.reply({ amount: `4_${cardId}_0_-1` }, "onAmountUpdated");
    }
    const target = String(p.target ?? "");
    const targetType = Number(p.targetType) | 0;
    const info = {
      key: `${ctx.player.name}_${++shots}`,
      from: ctx.player.name,
      cardId,
      target,
      targetType,
      x: Number(p.x) | 0,
      y: Number(p.y) | 0,
      roomId: ctx.player.room?.id ?? 0,
      mine: p.mine ?? null,
    };
    ctx.broadcast({ info, hit: true }, "64_2");
    if (targetType !== TARGET_PLAYER || effect <= 0 || seconds <= 0) return;
    const s = sessionOf(world, target);
    if (!s) return;
    const mine = worn.get(target) ?? new Map<number, number>();
    worn.set(target, mine);
    const until = Date.now() + seconds * 1000;
    mine.set(effect, until);
    world.setUserVars(s, { shoot_effect: `${target};${[...mine.keys()].join(",")};${effect};` });
    later(seconds * 1000, () => {
      if (mine.get(effect) !== until) return; // hit again since: that one takes it off
      mine.delete(effect);
      world.setUserVars(s, { shoot_effect: `${target};${[...mine.keys()].join(",")};0;${effect}` });
    });
  });
}

function sessionOf(world: World, name: string): Session | undefined {
  for (const r of world.rooms.values()) for (const m of r.members) if (world.player(m)?.name === name) return m;
  return undefined;
}
