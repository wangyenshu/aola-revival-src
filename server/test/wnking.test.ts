import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import { ABYSS, installGodBosses } from "../src/game/sfs2013/godbosses.ts";
import { installPlanetActs } from "../src/game/sfs2013/planetacts.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";
import { WNK_FINAL, WNK_ITEM_ROWS, WNK_SIDES, WNK_STARS, installWnKing, type WnkOwner } from "../src/game/sfs2013/wnking.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};

function harness(opts: { strong?: boolean } = {}) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {}, handlers } as unknown as World;
  const o: WnkOwner & { score: number; xingbi: number } = { id: 10001, name: "小奥拉", xingbi: 500, items: {}, score: 100 };
  o.pets = [makePet(tables, opts.strong === false ? 1 : 1300, opts.strong === false ? 5 : 100, "d", 1)];
  o.nextPetId = 1;
  let day = "2013-02-21";
  installBattles(world, { load: async () => o, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => day, rng: () => 0.5, now: () => 1_000_000 });
  installWnKing(world, { me: async () => o, save: async () => {}, today: () => day });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = {
      params,
      player: { name: o.name, room: { name: "bailingstar4" } },
      reply: (b: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, b]),
    } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  const get = (out: Msg[], cmd: string) => out.find(([c]) => c === cmd)?.[1] as Record<string, any> | undefined;
  const start = (t: number, id: number) => call("PetExtension.54_22", { type: 99, handler: "holiday.NWKChallenge", t, id });
  /** Fight the battle open now with the strongest skill until it ends (keep: the player's 亚比 healed each turn). */
  const fight = async (keep = true) => {
    const all: Msg[] = [];
    for (let n = 0; n < 300 && !all.some(([c]) => c === "2403" || c === "2404"); n++) {
      const usable = o.pets![0].hp > 0 ? o.pets![0].skills.filter((s) => s.pp > 0) : [];
      if (!usable.length) break;
      const sk = usable.sort((a, b) => (tables.pm.skills[String(b.id)]?.p ?? 0) - (tables.pm.skills[String(a.id)]?.p ?? 0))[0];
      all.push(...(await call("PocketMonsterExtension.1401", { skillId: sk.id })));
      if (keep) for (const p of o.pets!) {
        p.hp = 99999;
        for (const s of p.skills) s.pp = s.max;
      }
    }
    return all;
  };
  return { o, call, get, start, fight, handlers, world, setDay: (d: string) => (day = d) };
}

test("狼王的分身: a win gives its 剑魂; three 剑魂 call 狼王 once", async () => {
  const h = harness();
  assert.deepEqual(h.get(await h.call("HolidayExtension.nwk0219-1"), "nwk0219-1"), { got0: false, got1: false, won: false, f: false, t: 0 });
  assert.equal(h.get(await h.start(1, 0), "54_22")!.res, true);
  const end = await h.fight();
  assert.equal(h.get(end, "2403")!.isWin, true);
  assert.equal(h.o.items!["2"]["565"], 1);
  assert.equal(h.get(await h.start(1, 0), "54_22")!.res, false, "had already");
  assert.equal(h.get(await h.call("SynthesizeExtension.57_8", { id: 337, num: 1 }), "57_8")!.res, 0, "two missing");
  h.o.items!["2"]["566"] = 1;
  h.o.items!["2"]["567"] = 1;
  const call = await h.call("SynthesizeExtension.57_8", { id: 337, num: 1 });
  assert.deepEqual(h.get(call, "57_8"), { res: 1, id: 337 });
  assert.equal(h.o.items!["5"]["1121"], 1);
  for (const i of WNK_SIDES[1].items) assert.equal(h.o.items!["2"][String(i)], undefined);
  assert.equal(h.get(await h.call("HolidayExtension.nwk0219-1"), "nwk0219-1")!.got1, true);
  assert.equal(h.get(await h.start(1, 1), "54_22")!.res, false, "called");
  h.o.items!["2"] = { "565": 1, "566": 1, "567": 1 };
  assert.equal(h.get(await h.call("SynthesizeExtension.57_8", { id: 337, num: 1 }), "57_8")!.res, 0, "once only");
});

test("幽之分身: a loss lights one 幽之星 a day, the third brings 幽之封印", async () => {
  const h = harness({ strong: false });
  for (let d = 1; d <= WNK_STARS; d++) {
    h.setDay(`2013-02-2${d}`);
    // A second loss the same day lights nothing (the third day's loss brings the 封印: no second fight).
    for (let k = 0; k < (d < WNK_STARS ? 2 : 1); k++) {
      h.o.pets![0].hp = 1;
      assert.equal(h.get(await h.start(0, 0), "54_22")!.res, true);
      const end = await h.fight(false);
      assert.ok(end.some(([c]) => c === "2404" || (c === "2403" && !(end.find(([x]) => x === "2403")![1] as any).isWin)), "lost");
    }
    assert.equal(h.get(await h.call("HolidayExtension.nwk0219-2", { type: 0 }), "nwk0219-2")!.cnt, d, "one a day");
  }
  assert.equal(h.o.items!["2"]["707"], 1);
});

test("王之分身 knocks out a 亚比 every five rounds; 灵之分身 heals each round", async () => {
  const h = harness();
  await h.start(1, 1);
  let all: Msg[] = [];
  // The weakest skill, so that the 分身 stands five rounds.
  const weakest = () => h.o.pets![0].skills.filter((s) => s.pp > 0).sort((a, b) => (tables.pm.skills[String(a.id)]?.p ?? 0) - (tables.pm.skills[String(b.id)]?.p ?? 0))[0];
  for (let n = 0; n < 5; n++) {
    const sk = weakest();
    all.push(...(await h.call("PocketMonsterExtension.1401", { skillId: sk.id })));
    if (all.some(([c]) => c === "2403" || c === "2404")) break;
    if (n < 4) h.o.pets![0].hp = 99999;
  }
  assert.ok(all.some(([, b]) => /秒杀了/.test(String((b as any).desc ?? ""))), "秒杀 on the fifth round");
  await h.call("PocketMonsterExtension.1404");
  const g = harness();
  await g.start(1, 2);
  all = await g.fight();
  assert.ok(all.some(([, b]) => /恢复了部分体力/.test(String((b as any).desc ?? ""))));
});

test("终极试炼: both kings called, five tries a day, both kings in one battle", async () => {
  const h = harness();
  assert.equal(h.get(await h.start(2, 0), "54_22")!.res, false, "not both called");
  h.o.wnk = { got: [true, true] };
  assert.equal(h.get(await h.start(2, 0), "54_22")!.res, true);
  const end = await h.fight();
  assert.ok(end.some(([c, m]) => c === "2413" && (m as any).extInfo?.foe), "夜王 comes out after 狼王");
  assert.equal(h.get(end, "2403")!.isWin, true);
  assert.deepEqual(h.get(await h.call("HolidayExtension.nwk0219-3"), "nwk0219-3"), { c: 1, won: true });
  for (let i = 1; i < WNK_FINAL.tries; i++) {
    assert.equal(h.get(await h.start(2, 0), "54_22")!.res, true);
    await h.call("PocketMonsterExtension.1404");
  }
  assert.equal(h.get(await h.start(2, 0), "54_22")!.res, false, "no tries left");
  h.setDay("2013-02-22");
  assert.equal(h.get(await h.call("HolidayExtension.nwk0219-3"), "nwk0219-3")!.c, 0);
});

test("57_8 reaches each exchange with the server's modules installed in order", async () => {
  const h = harness();
  installGodBosses(h.world, { me: async () => h.o as never, save: async () => {}, today: () => "2013-02-21", rng: () => 0.5 });
  installWnKing(h.world, { me: async () => h.o, save: async () => {}, today: () => "2013-02-21" });
  installPlanetActs(h.world, {
    load: async () => h.o as never, find: async () => undefined, save: async () => {}, tables: async () => tables,
    now: () => 0, today: () => "2013-02-21", givePet: async () => [], rng: () => 0.5,
  });
  h.o.items!["2"] = { "636": 1, "637": 1, "638": 1, "707": 1, "708": 1, "709": 1 };
  assert.equal(h.get(await h.call("SynthesizeExtension.57_8", { id: ABYSS.synth, num: 1 }), "57_8")!.res, 1, "魂石");
  assert.deepEqual(h.get(await h.call("SynthesizeExtension.57_8", { id: 367, num: 1 }), "57_8"), { res: 1, id: 367 });
  assert.equal(h.o.items!["5"]["1123"], 1);
});

test("the 剑魂 and 封印 are sold for 星币, as the August 2013 table has them", () => {
  assert.deepEqual(Object.keys(WNK_ITEM_ROWS).sort(), ["565", "566", "567", "707", "708", "709"]);
  for (const [price, , rmb, maxQ, vip] of Object.values(WNK_ITEM_ROWS)) {
    assert.equal(price, 0);
    assert.ok([70, 100, 130].includes(rmb));
    assert.equal(maxQ, 1);
    assert.equal(vip, 0);
  }
});
