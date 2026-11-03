import assert from "node:assert/strict";
import { test } from "node:test";
import { CARD_DROP, PET_CARD, PET_CARDS, cardBonus, cardDrop, installPetCards, type CardOwner } from "../src/game/sfs2013/petcards.ts";
import { statsOf } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

function setup() {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const owner: CardOwner = { items: { "8": { "1": 1, "3": 2, "7": 1 } }, pets: [{ id: 5, hp: 100 }] };
  installPetCards(world, { load: async () => owner, save: async () => {}, maxHp: async (_o, p) => 100 + cardBonus(p.cards)[0] });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: "a" }, reply: (o: Record<string, unknown>, c?: string) => out.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { owner, call };
}

test("the 2013 战术卡: 35 cards, each of a place A, B or C", () => {
  assert.equal(Object.keys(PET_CARDS).length, 35);
  assert.deepEqual(PET_CARDS[1], { name: "忠诚之斗士卡", type: 0, color: 0, hp: 20, sp: -10, at: 0, de: 0, sa: 0, sd: 0 });
  assert.ok(Object.values(PET_CARDS).every((c) => [0, 1, 2].includes(c.type)));
  // 体力 +20, 速度 -10, in statsOf's order (体力, 攻击, 防御, 特攻, 特防, 速度).
  assert.deepEqual(cardBonus([1, 0, 0]), [20, 0, 0, 0, 0, -10]);
});

test("putting on, swapping and taking off 战术卡", async () => {
  const { owner, call } = setup();
  assert.deepEqual((await call("MaterialExtension.61_7"))[0][1].cards, [{ id: 1, qt: 1, uq: 0 }, { id: 3, qt: 2, uq: 0 }, { id: 7, qt: 1, uq: 0 }]);
  let r = await call("PetExtension.54_25", { pid: 5, cid: 1 });
  assert.deepEqual(r.at(-1)![1], { res: 1, pid: 5, cid: 1, cards: [1, 0, 0], msg: "装上了「忠诚之斗士卡」。" });
  assert.deepEqual(r[0], ["onAmountUpdated", { amount: `${PET_CARD}_1_0_-1` }]);
  assert.equal(owner.items!["8"]["1"], undefined);
  // Another A card in its place: the first goes back.
  r = await call("PetExtension.54_25", { pid: 5, cid: 7 });
  assert.deepEqual(r.at(-1)![1].cards, [7, 0, 0]);
  assert.equal(owner.items!["8"]["1"], 1);
  assert.equal(owner.items!["8"]["7"], undefined);
  // A B card beside it.
  r = await call("PetExtension.54_25", { pid: 5, cid: 3 });
  assert.deepEqual(r.at(-1)![1].cards, [7, 3, 0]);
  assert.equal(owner.items!["8"]["3"], 1);
  // The one worn, again: off. Its 体力 within the new most (100 without the 25 of card 7).
  owner.pets![0].hp = 125;
  r = await call("PetExtension.54_25", { pid: 5, cid: 7 });
  assert.deepEqual(r.at(-1)![1].cards, [0, 3, 0]);
  assert.equal(owner.pets![0].hp, 100);
  // Not owned, unknown, no such 亚比.
  assert.equal((await call("PetExtension.54_25", { pid: 5, cid: 2 })).at(-1)![1].res, 0);
  assert.equal((await call("PetExtension.54_25", { pid: 5, cid: 999 })).at(-1)![1].res, 0);
  assert.equal((await call("PetExtension.54_25", { pid: 6, cid: 3 })).at(-1)![1].res, 0);
  // Asking only.
  assert.deepEqual((await call("PetExtension.54_25", { pid: 5, cid: 0 })).at(-1)![1].cards, [0, 3, 0]);
});

test("a 亚比's stats with its cards; a boss's card now and then", () => {
  const plain = statsOf({ race: 1, level: 10 });
  const carded = statsOf({ race: 1, level: 10, cards: [1, 3, 0] });
  assert.deepEqual(carded.map((v, i) => v - plain[i]), [20, 20, -10, 0, 0, -10]);
  assert.equal(cardDrop(() => (CARD_DROP + 1) / 100), 0);
  assert.ok(PET_CARDS[cardDrop(() => 0)]);
});
