// 究极亚比 (battle.ts change / unchange, command 1407) and 圣域 (shengyu.ts) in battles.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { BattleEngine } from "../src/game/sfs2013/battle.ts";
import { makePet, statsOf, type PetTables } from "../src/game/sfs2013/pets.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};
/** Always the lowest roll: every chance comes. */
const sure = () => 0;
/** Never a chance (rolls 0.99). */
const never = () => 0.99;

function battle(mine: number, wild: number, rng = never, level = 60) {
  const e = new BattleEngine(tables, rng);
  const me = makePet(tables, mine, level, "d", 1);
  const foe = makePet(tables, wild, level, "d");
  const b = e.start(1, "x", { id: 1, name: "a" }, me, foe, true);
  return { e, b, me, foe };
}

test("究极: 神照修罗王 becomes its 三阶 form for 6 rounds after the one it changes in, then itself again, and can change again", () => {
  const { e, b, me } = battle(2160, 1);
  const hp = me.hp;
  const own = statsOf(me, tables);
  assert.equal(e.canChange(b, b.mine), true);
  const [cmd, body] = e.change(b, b.mine);
  assert.equal(cmd, "2417");
  assert.equal(body.raceId, 2161);
  assert.equal(b.mine.pet.race, 2161);
  assert.notEqual(b.mine.pet, me, "the form is a copy: the record kept is not touched");
  assert.equal(me.race, 2160);
  assert.deepEqual(b.mine.pet.skills.map((s) => s.id).sort(), [19157, 19158, 20088, 20089]);
  // 三阶: 体力 +800, 攻击 +800, 防御 +850.
  assert.equal(b.mine.stats[0], own[0] + 800);
  assert.equal(b.mine.stats[1], own[1] + 800);
  assert.equal(b.mine.stats[2], own[2] + 850);
  assert.equal(b.mine.pet.hp, hp + 800);
  assert.equal(e.canChange(b, b.mine), false, "not while in its form");
  assert.deepEqual(body.up, [800, 800, 850, 0, 0, 0], "the points, for the movie of them");
  for (let i = 0; i < 6; i++) {
    e.endOfTurn(b);
    assert.equal(b.mine.pet.race, 2161, `round ${i + 1}`);
  }
  const out = e.endOfTurn(b);
  assert.equal(b.mine.pet, me);
  assert.equal(b.mine.pet.race, 2160);
  assert.ok(out.some(([, x]) => String(x.desc).includes("究极结束")));
  // The later button is 究极变身 again once the form is over: no once a battle.
  assert.equal(e.canChange(b, b.mine), true, "again");
  const jj = (e.view(b, 0).battleView as { jj: Record<string, unknown> }).jj;
  assert.deepEqual([jj.can, jj.left, "used" in jj], [true, 0, false]);
  assert.equal(e.change(b, b.mine)[1].raceId, 2161);
});

test("究极: when the form ends, the record kept has the same share of its 体力", () => {
  const { e, b, me } = battle(2160, 1);
  const max = statsOf(me, tables)[0];
  e.change(b, b.mine);
  b.mine.pet.hp = Math.floor(b.mine.stats[0] / 2);
  e.unchange(b.mine);
  assert.ok(Math.abs(me.hp - max / 2) <= 1, `${me.hp} of ${max}`);
  const r = battle(2160, 1);
  r.e.change(r.b, r.b.mine);
  r.b.mine.pet.hp = 1;
  r.e.unchange(r.b.mine);
  assert.equal(r.me.hp, 1, "standing, it keeps at least 1");
  const k = battle(2160, 1);
  k.e.change(k.b, k.b.mine);
  k.b.mine.pet.hp = 0;
  k.e.unchange(k.b.mine);
  assert.equal(k.me.hp, 0, "fallen in its form, it is fallen");
});

test("契约 (辉月战骑): 坐骑召唤 — its whole 体力 back, 60% 伤害抗性, 速度 +3, for the battle; 皇犽 strikes after each attack", () => {
  const { e, b, me } = battle(2382, 340, sure, 100);
  me.hp = 10;
  const [cmd, body] = e.change(b, b.mine);
  assert.equal(cmd, "2417");
  assert.equal(body.qiyue, true);
  assert.equal(b.mine.pet.race, 2383);
  assert.equal(b.mine.pet.hp, b.mine.stats[0], "回复最大体力值100%");
  assert.equal(b.mine.stages.spd, 3);
  assert.ok(String(body.desc).includes("满月血脉"));
  assert.deepEqual(b.mine.pet.skills.map((s) => s.id), me.skills.map((s) => s.id), "its own skills");
  const jj = (e.view(b, 0).battleView as { jj: Record<string, unknown> }).jj;
  assert.deepEqual([jj.k, jj.on, jj.sn, jj.can], [2, true, "满月血脉", false]);
  // 60% less from a blow: the same blow on it in and out of its 契约.
  const blow = b.wild.pet.skills.find((s) => tables.pm.skills[String(s.id)].k !== 2 && tables.pm.skills[String(s.id)].p > 0)!.id;
  // The same two 亚比 both times (makePet rolls their values).
  const pet = makePet(tables, 2382, 100, "d", 1);
  const foe = makePet(tables, 340, 100, "d");
  const hit = () => {
    const e2 = new BattleEngine(tables, sure);
    const b2 = e2.start(1, "x", { id: 1, name: "a" }, structuredClone(pet), structuredClone(foe), true);
    return { e: e2, b: b2 };
  };
  const plain = hit();
  const before = plain.b.mine.pet.hp;
  plain.e.act(plain.b, plain.b.wild, plain.b.mine, blow);
  const lostPlain = before - plain.b.mine.pet.hp;
  const rode = hit();
  rode.e.change(rode.b, rode.b.mine);
  const full = rode.b.mine.pet.hp;
  rode.e.act(rode.b, rode.b.wild, rode.b.mine, blow);
  const lostRode = full - rode.b.mine.pet.hp;
  assert.ok(lostPlain > 0 && Math.abs(lostRode - Math.floor(lostPlain * 0.4)) <= Math.max(2, lostPlain * 0.05), `${lostRode} of ${lostPlain}`);
  // 每回合攻击结束时，皇犽额外造成350点 (and 60%: the other's raised levels cleared).
  b.wild.stages.atk = 2;
  const own = b.mine.pet.skills.find((s) => tables.pm.skills[String(s.id)].k !== 2)!.id;
  const [, r] = e.act(b, b.mine, b.wild, own);
  assert.ok(String(r.desc).includes("皇犽额外造成了"), String(r.desc));
  assert.equal(b.wild.stages.atk, 0);
  // The whole battle: 9999 rounds, no 剩余回合 shown (the client shows the 契约技能's name).
  assert.equal(b.mine.form?.left, 9999);
});

test("究极: the 战骑 stop at 二阶; a 亚比 with no 究极 cannot change", () => {
  assert.equal(tables.pm.jiuji?.["2382"].lv, 2);
  const { e, b } = battle(1, 2);
  assert.equal(e.jiujiOf(b.mine), undefined);
  assert.equal(e.canChange(b, b.mine), false);
});

test("圣域: 圣域·幻极 brings 幻灵圣域 when it comes out, and the 幻灵家族 take 30% less there", () => {
  const { e, b } = battle(2107, 2090, never);
  e.startTurn(b);
  const out = e.roundStart(b);
  assert.equal(b.sy?.id, "1023");
  assert.ok(out.some(([, x]) => String(x.desc).includes("幻灵圣域降临了")));
  const v = e.view(b, 0).battleView as { sy?: { id: string; n: string } };
  assert.deepEqual([v.sy?.id, v.sy?.n], ["1023", "幻灵"]);
});

test("圣域: the field comes as its 亚比 arrives, before any skill (煌炎战神's 阳炎 at the start, 圣域·幻极 switched in)", () => {
  const { e, b } = battle(2050, 1, never);
  const out = e.arrivals(b);
  assert.equal(b.sy?.id, "1001", "at the start, before the first round");
  assert.ok(out.some(([c, x]) => c === "2421" && String(x.desc).includes("阳炎圣域降临了")));
  assert.deepEqual(e.arrivals(b), [], "once");
  e.startTurn(b);
  assert.ok(!e.roundStart(b).some(([, x]) => String(x.desc).includes("降临")), "not again with the first skill");
  // Switched in: 圣域·幻极's 幻灵 at once.
  const s = battle(1, 2, never);
  s.e.arrivals(s.b);
  assert.equal(s.b.sy, undefined);
  const next = makePet(tables, 2107, 60, "d", 2);
  s.b.mine = { ...s.b.mine, pet: next, cameRound: undefined } as typeof s.b.mine;
  s.b.mine.types = [4, 4] as [number, number];
  assert.ok(s.e.arrivals(s.b).some(([, x]) => String(x.desc).includes("幻灵圣域降临了")));
  assert.equal((s.b as { sy?: { id: string } }).sy?.id, "1023");
});

test("圣域技能: 圣域·幻雷 (Lv60) in 幻灵圣域 goes into 雷神 for 2 rounds: its blows may paralyse", () => {
  const { e, b } = battle(2107, 2090, sure);
  e.startTurn(b);
  const out = e.roundStart(b);
  assert.ok(out.some(([, x]) => String(x.desc).includes("幻雷碎天")), JSON.stringify(out.map(([, x]) => x.desc)));
  const st = b.wild.timed.filter((x) => x.from === "圣域技能1024");
  assert.equal(st.length, 1);
  assert.deepEqual([st[0].kind, st[0].status, st[0].left], ["onhit", "麻痹", 2]);
});

test("圣域: a field's round's end (阳炎: 上古系 and 火系 aside, a burn 25% of the time)", () => {
  const { e, b } = battle(2050, 1, sure);
  e.startTurn(b);
  e.roundStart(b);
  assert.equal(b.sy?.id, "1001");
  e.endOfTurn(b);
  assert.equal(b.wild.status, "烧伤", "兔小子 is 普通系");
  assert.notEqual(b.mine.status, "烧伤", "煌炎战神 is 上古系");
});

test("圣域: a skill that summons one (狮王之戟: 万王圣域), and 万王's floor for 王系", () => {
  const { e, b } = battle(2101, 1, sure);
  b.mine.pet.skills = [{ id: 5258, name: "狮王之戟", pp: 10, max: 10 }];
  e.skillTurn(b, 5258);
  assert.equal(b.sy?.id, "1060");
});

test("超奥义: 乾坤修罗神's 修罗奥魂诀 beside its four skills, once a battle, shown in its view", () => {
  const { e, b } = battle(2590, 1);
  const ao = e.aoyiOf(b.mine);
  assert.equal(ao, 30071);
  assert.equal(tables.pm.skills["30071"].ao, 0, "强袭奥义");
  const v = e.view(b, 0).battleView as { ao?: { id: number; n: string; t: number; used: boolean } };
  assert.deepEqual([v.ao?.id, v.ao?.n, v.ao?.t, v.ao?.used], [30071, "修罗奥魂诀", 0, false]);
  assert.equal(e.canAoyi(b, b.mine), true);
  e.useAoyi(b, b.mine);
  const out = e.skillTurn(b, 30071);
  assert.ok(out.some(([c, x]) => c === "2411" && x.id === 30071), "it acts with it");
  assert.equal(b.mine.pet.skills.every((s) => s.pp === s.max), true, "no PP of the four is spent");
  assert.equal(e.canAoyi(b, b.mine), false, "once a battle");
  assert.equal((e.view(b, 0).battleView as { ao?: { used: boolean } }).ao?.used, true);
  // A 亚比 with no 超奥义 has none; nor the wild side's view.
  const plain = battle(1, 2);
  assert.equal(plain.e.aoyiOf(plain.b.mine), undefined);
  assert.equal((e.view(b, 1).battleView as { ao?: unknown }).ao, undefined);
});

test("究极: the view tells the rounds of 聚能 left and the 亚比 the form came from", () => {
  const { e, b } = battle(2160, 1);
  const jj = () => (e.view(b, 0).battleView as { jj: { wait: number; from: number; left: number } }).jj;
  assert.deepEqual([jj().wait, jj().from], [0, 2160], "三阶: no 聚能");
  e.change(b, b.mine);
  assert.deepEqual([jj().from, jj().left], [2160, 6]);
});
