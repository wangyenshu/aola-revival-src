import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { installBattles, type Msg } from "../src/game/sfs2013/battle.ts";
import { ABYSS, GOD_PRICE, GOD_TRIES, POSEIDON, SCHWARZ, SKY, installGodBosses, type GodOwner } from "../src/game/sfs2013/godbosses.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import type { World, XtContext, XtHandler } from "../src/game/sfs2013/server.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};

function harness(rolls: number[] = [0.5, 0.5, 0.2, 0.8]) {
  const handlers = new Map<string, XtHandler>();
  const world = { xt: (k: string, h: XtHandler) => (handlers.set(k, h), world), setUserVars: () => {}, handlers } as unknown as World;
  const o: GodOwner & { score: number } = { id: 10001, name: "小奥拉", xingbi: 500, items: {}, score: 100 };
  o.pets = [makePet(tables, 1300, 100, "d", 1), makePet(tables, 1300, 100, "d", 2)];
  o.nextPetId = 2;
  let i = 0;
  const rng = () => rolls[i++ % rolls.length];
  let day = "2013-01-25";
  installBattles(world, { load: async () => o, save: async () => {}, tables: async () => tables, wild: async () => ({}), today: () => day, rng, now: () => 1_000_000 });
  installGodBosses(world, { me: async () => o, save: async () => {}, today: () => day, rng });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: Msg[] = [];
    const ctx = {
      params,
      player: { name: o.name, room: { name: "cloudstar6" } },
      reply: (b: Record<string, unknown>, cmd = key.split(".")[1]) => out.push([cmd, b]),
    } as unknown as XtContext;
    await handlers.get(key)!(ctx, key);
    return out;
  };
  const get = (out: Msg[], cmd: string) => out.find(([c]) => c === cmd)?.[1] as Record<string, any> | undefined;
  /** Fight the battle open now with the strongest skill until it ends. */
  const fight = async () => {
    const all: Msg[] = [];
    for (let n = 0; n < 300 && !all.some(([c]) => c === "2403" || c === "2404"); n++) {
      const usable = o.pets![0].hp > 0 ? o.pets![0].skills.filter((s) => s.pp > 0) : [];
      if (!usable.length) break;
      const sk = usable.sort((a, b) => (tables.pm.skills[String(b.id)]?.p ?? 0) - (tables.pm.skills[String(a.id)]?.p ?? 0))[0];
      all.push(...(await call("PocketMonsterExtension.1401", { skillId: sk.id })));
      for (const p of o.pets!) {
        p.hp = 9999;
        for (const s of p.skills) s.pp = s.max;
      }
    }
    return all;
  };
  return { o, call, get, fight, setDay: (d: string) => (day = d) };
}

test("天空之神: two stages, then 拉诺斯 (five tries a day); the first stage's 乐天 brings 茜点", async () => {
  const h = harness();
  assert.deepEqual(h.get(await h.call("HolidayExtension.20120928_F1"), "20120928_F1"), { proc: 0, left: GOD_TRIES, bought: false });
  const out = await h.call("PetExtension.54_22", { type: SKY.type });
  assert.equal(h.get(out, "54_22")!.res, true);
  const end = await h.fight();
  const helper = end.find(([c, m]) => c === "2413" && (m as any).extInfo?.foe);
  assert.ok(helper, "茜点 comes out after 乐天");
  assert.match(String((helper![1] as any).extInfo.desc), /茜点出战了/);
  assert.equal(h.get(end, "2403")!.isWin, true);
  assert.equal(h.o.gods!.sky!.proc, 1);
  // 天空之神 itself takes a try each time.
  h.o.gods!.sky!.proc = 2;
  for (let i = 0; i < GOD_TRIES; i++) {
    assert.equal(h.get(await h.call("PetExtension.54_22", { type: SKY.type }), "54_22")!.res, true);
    await h.call("PocketMonsterExtension.1404");
  }
  assert.equal(h.get(await h.call("PetExtension.54_22", { type: SKY.type }), "54_22")!.res, false, "no tries left today");
  h.setDay("2013-01-26");
  assert.equal(h.get(await h.call("HolidayExtension.20120928_F1"), "20120928_F1")!.left, GOD_TRIES);
});

test("星币力量: 200 星币 for the 亚比蛋, once", async () => {
  const h = harness();
  assert.equal(h.get(await h.call("HolidayExtension.20120928_F2"), "20120928_F2")!.res, 1);
  assert.equal(h.o.xingbi, 500 - GOD_PRICE);
  assert.equal(h.o.items!["5"][SKY.egg], 1);
  assert.equal(h.get(await h.call("HolidayExtension.20120928_F2"), "20120928_F2")!.res, -1);
  assert.equal(h.get(await h.call("PeriodicActiveExtension.sgc-2"), "sgc-2")!.res, 1);
  assert.equal(h.o.items!["5"][POSEIDON.egg], 1);
  assert.equal(h.get(await h.call("PeriodicActiveExtension.ega-3"), "ega-3")!.res, 101, "too few 星币 left");
  assert.equal(h.get(await h.call("PeriodicActiveExtension.sgc-1"), "sgc-1")!.buy, true);
});

test("施瓦辛格: the helpers drawn for the confirm come into the fight", async () => {
  const h = harness([0.9, 0, 0.4]);
  const rc = String(h.get(await h.call("PeriodicActiveExtension.ega-2"), "ega-2")!.rc);
  const drawn = rc.split(";").map((r) => Number(r.split(",")[0]));
  assert.equal(drawn.length, 2);
  for (const r of drawn) assert.ok(SCHWARZ.helpers.includes(r));
  assert.equal(h.get(await h.call("PetExtension.54_22", { type: SCHWARZ.type }), "54_22")!.res, true);
  assert.equal(h.get(await h.call("PeriodicActiveExtension.ega-1"), "ega-1")!.cnt, GOD_TRIES - 1);
});

test("魔龙之战: three 分身 in turn, then 召唤; the three 魂石 once", async () => {
  const h = harness();
  assert.deepEqual(h.get(await h.call("PeriodicActiveExtension.mdk1224-1"), "mdk1224-1"), { dcc: 0, st: 0 });
  assert.equal(h.get(await h.call("PeriodicActiveExtension.mdk1224-2"), "mdk1224-2")!.succ, false);
  h.o.gods = { abyss: { st: 3 } };
  assert.equal(h.get(await h.call("PetExtension.54_22", { type: ABYSS.type }), "54_22")!.res, false, "all three won");
  assert.equal(h.get(await h.call("PeriodicActiveExtension.mdk1224-2"), "mdk1224-2")!.succ, true);
  assert.equal(h.o.items!["5"][ABYSS.egg], 1);
  assert.equal(h.get(await h.call("SynthesizeExtension.57_8", { id: ABYSS.synth, num: 1 }), "57_8")!.res, 0, "no 魂石");
  h.o.items!["2"] = { "636": 1, "637": 1, "638": 1 };
  assert.equal(h.get(await h.call("SynthesizeExtension.57_8", { id: ABYSS.synth, num: 1 }), "57_8")!.res, 1);
  assert.equal(h.o.items!["5"][ABYSS.egg], 2);
  h.o.items!["2"] = { "636": 1, "637": 1, "638": 1 };
  assert.equal(h.get(await h.call("SynthesizeExtension.57_8", { id: ABYSS.synth, num: 1 }), "57_8")!.res, 0, "once only");
});
