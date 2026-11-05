// Who is in a fight now (battle.ts keeps the fights): what changes a player's 亚比 outside a fight
// (healing, items, the skills carried) waits till it is over, for the fight's 亚比 are those.
import type { World } from "./server.ts";

const fights = new WeakMap<World, { has(id: number): boolean }>();

/** battle.ts: the fights of this world, by the owner's id. */
export function registerFights(world: World, byOwner: { has(id: number): boolean }): void {
  fights.set(world, byOwner);
}

/** Is the player of this id in a fight now? */
export function inFight(world: World, id: number): boolean {
  return fights.get(world)?.has(id) ?? false;
}
