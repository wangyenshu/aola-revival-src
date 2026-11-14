import assert from "node:assert/strict";
import { test } from "node:test";
import { PET_CLOTHES, dressFor, giveAllPetClothes, installPetDress, petClothesList, wornOf, type DressOwner } from "../src/game/sfs2013/petdress.ts";
import { followVar, type PetRecord } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const pet = (id: number, race: number, drs?: string) => ({ id, race, level: 30, exp: 0, hp: 50, character: "认真", skills: [], got: "2013-01-01", drs }) as PetRecord;

function setup(owner: DressOwner) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world) } as unknown as World;
  const follows: string[] = [];
  installPetDress(world, {
    load: async () => owner,
    save: async () => {},
    following: (_ctx, o, p) => void (o.followPet === p.id && follows.push(followVar(p))),
    nameOf: async (p) => p.nick || `亚比${p.race}`,
  });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string | undefined, Record<string, any>][] = [];
    const ctx = { params, player: { name: "a" }, reply: (o: Record<string, unknown>, c?: string) => out.push([c, o]) } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  return { call, follows };
}

test("the 2013 tables' 11 pieces of 亚比装扮, each for one of the ten 亚比 of PetDressInfosMap", () => {
  assert.equal(Object.keys(PET_CLOTHES).length, 11);
  assert.deepEqual([...new Set(Object.values(PET_CLOTHES).map((c) => c.race))].sort((a, b) => a - b), [10, 19, 54, 58, 72, 189, 236, 255, 282, 293]);
  // 活力企鹅 wears its cape and hat together; nobody wears another's piece, or one twice.
  assert.deepEqual(dressFor(255, "30003;30002;30002;30001"), [30002, 30003]);
  // Its earlier forms wear none of them.
  assert.equal(wornOf({ race: 254, drs: "30002" }), "");
});

test("owning, wearing and taking off 亚比装扮; the following 亚比 shows it", async () => {
  const owner: DressOwner = { id: 1, name: "a", pets: [pet(5, 255), pet(6, 10)], storage: [pet(7, 255)], followPet: 5 };
  const { call, follows } = setup(owner);
  assert.deepEqual((await call("MaterialExtension.61_5"))[0], ["61_5", { pd: [] }]);
  // Not owned yet.
  let r = await call("PetExtension.54_24", { pi: 5, dr: "30002" });
  assert.equal(r[0][1].res, 0);
  assert.equal(giveAllPetClothes(owner), 11);
  r = await call("PetExtension.54_24", { pi: 5, dr: "30002;30003" });
  assert.deepEqual(r[0], ["54_24", { res: 1, pi: 5, dr: "30002;30003", msg: "" }]);
  assert.deepEqual(follows, ["255,255,5,30002;30003,,0"]);
  const listed = (await call("MaterialExtension.61_5"))[0][1].pd;
  assert.equal(listed.length, 11);
  assert.deepEqual(listed.find((x: { id: number }) => x.id === 30002), { id: 30002, qt: 1, uq: 1 });
  // Another 活力企鹅 (in the 仓库) cannot wear the cape the first one has on.
  r = await call("PetExtension.54_24", { pi: 7, dr: "30002" });
  assert.deepEqual(r[0][1], { res: 0, pi: 7, dr: "", msg: "绅士披风穿在亚比255身上，先给它脱下吧。" });
  // A piece of another 亚比.
  assert.equal((await call("PetExtension.54_24", { pi: 6, dr: "30002" }))[0][1].res, 0);
  assert.equal((await call("PetExtension.54_24", { pi: 6, dr: "30001" }))[0][1].dr, "30001");
  // Off: the cape is free again.
  r = await call("PetExtension.54_24", { pi: 5, dr: "30003" });
  assert.equal(r[0][1].dr, "30003");
  assert.equal((await call("PetExtension.54_24", { pi: 7, dr: "30002" }))[0][1].res, 1);
  assert.equal((await call("PetExtension.54_24", { pi: 5, dr: "" }))[0][1].dr, "");
  assert.equal(owner.pets![0].drs, undefined);
  assert.deepEqual(follows.at(-1), "255,255,5,,,0");
  assert.equal((await call("PetExtension.54_24", { pi: 99, dr: "" }))[0][1].res, 0);
  assert.deepEqual(petClothesList(owner).filter((x) => x.uq), [{ id: 30001, qt: 1, uq: 1 }, { id: 30002, qt: 1, uq: 1 }]);
});
