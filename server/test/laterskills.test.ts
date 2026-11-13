// The words of the skills of 2013–14 (skilltext.ts) and what the battle does with them.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { BattleEngine } from "../src/game/sfs2013/battle.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import { readSkill } from "../src/game/sfs2013/skilltext.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};
const skillNamed = (n: string) => Number(Object.entries(tables.pm.skills).find(([, s]) => s.n === n)![0]);
const read = (d: string) => {
  const r = readSkill(d);
  assert.equal(r.unread, "", d);
  return r.fx;
};

/** A battle against 兔小子 where every chance comes (rng 0) or none does (0.99). */
function fight(skill: string, rng = () => 0) {
  const e = new BattleEngine(tables, rng);
  const mine = makePet(tables, 323, 100, "d", 1);
  const wild = makePet(tables, 1, 60, "d");
  mine.skills = [{ id: skillNamed(skill), name: skill, pp: 10, max: 10 }];
  wild.skills = [{ id: 1016, name: "噼啪乱击", pp: 30, max: 30 }];
  wild.hp = 99999;
  const b = e.start(1, "x", { id: 1, name: "a" }, mine, wild, true);
  b.wild.stats[0] = 99999;
  return { e, b, mine, wild };
}

test("若/每次 <a condition>，则 …: the words after it, each under it", () => {
  assert.deepEqual(read("攻击对方单体2次，若暴击则令对方麻痹").statuses, [{ name: "麻痹", chance: 100, cond: { crit: true } }]);
  const fx = read("若对方已混乱或睡眠则造成1.5倍伤害，若伤害超过350则令对方睡眠");
  assert.deepEqual(fx.powerIf, [
    { cond: { foeStatus: "混乱" }, mult: 1.5 },
    { cond: { foeStatus: "睡眠" }, mult: 1.5 },
  ]);
  assert.deepEqual(fx.statuses, [{ name: "睡眠", chance: 100, cond: { dmgOver: 350 } }]);
  // 对已X目标 is 若对方已X则; 秒杀已X的目标 likewise.
  assert.deepEqual(read("命中则令对方混乱，对已混乱目标造成3倍伤害").powerIf, [{ cond: { foeStatus: "混乱" }, mult: 3 }]);
  assert.deepEqual(read("60%概率秒杀已烧伤的目标").ohkoIf, { chance: 60, cond: { foeStatus: "烧伤" } });
  // A lasting effect under one is placed only when it holds.
  const g = read("攻击对方单体，若对方已束缚则保护自己属性等级2回合不被削弱，若对方已衰弱则有20%概率吸取对方全属性等级1级");
  assert.deepEqual(g.timed, [{ who: "self", kind: "guard", turns: 2, placeIf: { foeStatus: "束缚" } }]);
  assert.equal(g.stealStages?.chance, 20);
  assert.deepEqual(
    read("命中则提升自己攻击和命中1级，战王圣域中额外提升速度1级").stages.find((x) => x.cond),
    { self: true, stats: ["spd"], delta: 1, chance: 100, cond: { field: "战王" } },
  );
});

test("the lasting effects: each blow taken or given, each round, the next turn", () => {
  assert.deepEqual(read("提升自己防御和特防等级1级，使用后4回合内每次受到攻击有30%概率令对方中毒").timed, [
    { who: "self", kind: "onhurt", turns: 4, chance: 30, status: "中毒" },
  ]);
  assert.deepEqual(read("使用后3回合每回合提升攻击、速度等级1级").timed, [{ who: "self", kind: "stagesEachTurn", turns: 3, chance: 100, stats: ["atk", "spd"], delta: 1 }]);
  assert.deepEqual(read("命中则每回合削弱对方特防1-2级，持续4回合").timed, [{ who: "foe", kind: "stagesEachTurn", turns: 4, chance: 100, stats: ["sdef"], delta: -1, deltaMax: -2 }]);
  assert.deepEqual(read("本回合提升自己攻击和闪避等级1级，下回合的攻击必定命中并且会将伤害值的1/2用来回复自己体力值").timed, [
    { who: "self", kind: "sure", turns: 2 },
    { who: "self", kind: "drain", turns: 2, f: 0.5 },
  ]);
  assert.deepEqual(read("攻击对方单体，50%概率提升自己攻击和暴击等级1级或削弱对方防御和闪避等级1级").stages, [
    { self: true, stats: ["atk", "crit"], delta: 1, chance: 50, or: { self: false, stats: ["def", "eva"], delta: -1 } },
  ]);
});

test("对方每次受到烧伤伤害则…: each time the burn hurts it, its 双防 go to the user", () => {
  const f = fight("★先锋炽焰");
  f.e.skillTurn(f.b, f.mine.skills[0].id);
  assert.equal(f.b.wild.status, "烧伤");
  const [def, mineDef] = [f.b.wild.stages.def, f.b.mine.stages.def];
  f.e.endOfTurn(f.b);
  assert.equal(f.b.wild.stages.def, def - 1);
  assert.equal(f.b.mine.stages.def, mineDef + 1);
});

test("若对方已烧伤则额外吸取对方200点体力值: only on a burnt foe", () => {
  const fx = readSkill(tables.pm.skills[String(skillNamed("炎龙灭世"))].d).fx;
  assert.deepEqual(fx.stealHp, { n: 200, cond: { foeStatus: "烧伤" } });
  const f = fight("炎龙灭世");
  const plain = f.e.skillTurn(f.b, f.mine.skills[0].id);
  assert.ok(!plain.some(([, m]) => String(m.desc ?? "").includes("吸取了")));
  const g = fight("炎龙灭世");
  g.b.wild.status = "烧伤";
  g.b.wild.statusLeft = 5;
  g.b.mine.pet.hp = 1;
  const out = g.e.skillTurn(g.b, g.mine.skills[0].id);
  assert.ok(out.some(([, m]) => String(m.desc ?? "").includes("吸取了")), JSON.stringify(out.map(([, m]) => m.desc)));
});

test("later words: 技能威力N%, 免疫伤害 by a chance, 回合末 heals, a heal only when hurt", () => {
  assert.deepEqual(read("先发，提升自己技能威力30%并免疫异常状态，持续3回合").timed, [
    { who: "self", kind: "power", turns: 3, mult: 1.3 },
    { who: "self", kind: "nostatus", turns: 3 },
  ]);
  assert.deepEqual(read("先发，使用后每回合提升自己速度和命中1级并有20%概率免疫伤害，持续10回合").timed[0], { who: "self", kind: "dodge", turns: 10, phys: 20, spec: 20 });
  assert.deepEqual(read("先发，提升自身伤害抗性30%并回合末回复15%最大体力值，持续3回合").timed[1], { who: "self", kind: "regen", turns: 3, f: 0.15 });
  assert.deepEqual(read("提升自己全属性1级，使用时未受到伤害则额外提升暴击2级，若已受到伤害则回复300点体力值").healFlatIf, { n: 300, cond: { hurt: true } });
});

test("超奥义 words: 护盾, 斩杀, marks with layers, skills set off by name, the generic animation", () => {
  new BattleEngine(tables, () => 0); // makes the skills set off by name known
  const words = (id: number) => readSkill(tables.pm.skills[String(id)].d);
  // 岩海之心: a 护盾 of half the most 体力; when it breaks the other is frozen.
  const shell = words(26117).fx;
  assert.deepEqual(shell.makeShield, { kind: "max", f: 0.5 });
  assert.deepEqual(shell.timed.find((x) => x.kind === "onbreak")?.status, "冰冻");
  // 修罗奥魂诀: 斩杀500点体力以下, 100 more for each round out.
  assert.deepEqual(words(30071).fx.execute, { n: 500, grow: 100 });
  // 星神古魂: 3 layers; under half its 体力 a layer heals 40% and raises all by 1.
  const ancient = words(33056).fx;
  assert.deepEqual(ancient.stacks, [{ who: "self", name: "星神古魂", n: 3 }]);
  const hp = ancient.timed.find((x) => x.kind === "stackHp")!;
  assert.deepEqual([hp.mark, hp.below, hp.then?.healAfter?.f, hp.then?.stages[0]?.delta], ["古魂", 0.5, 0.4, 1]);
  // 奇迹逆转 sets off 玄王甲: its 保护属性 and 倒置 of its own lowered stages come with it.
  const turn = words(33057).fx;
  assert.equal(turn.healFlat, 1000);
  assert.deepEqual(turn.invert, { self: "down" });
  assert.ok(turn.timed.some((x) => x.kind === "guard"));
  // A skill with no animation of its own plays the later generic one.
  assert.equal(tables.pm.skills["30071"].ge, 10002900);
});

test("marks in battle: 星神古魂's layer heals once its 体力 is under half", () => {
  const f = fight("星神古魂");
  // The 超奥义 is used as a skill of the four here.
  f.e.skillTurn(f.b, f.mine.skills[0].id);
  assert.equal(f.b.mine.stacks?.["星神古魂"], 3);
  f.b.mine.pet.hp = Math.floor(f.b.mine.stats[0] * 0.3);
  const before = f.b.mine.pet.hp;
  f.e.endOfTurn(f.b);
  assert.equal(f.b.mine.stacks?.["星神古魂"], 2);
  assert.ok(f.b.mine.pet.hp > before);
});

test("every 超奥义 is read to the last word", () => {
  new BattleEngine(tables, () => 0);
  const ids = [...new Set(Object.values(tables.pm.species).filter((s) => s.ao).map((s) => s.ao!))];
  assert.equal(ids.length, 59);
  const left = ids.map((id) => [tables.pm.skills[String(id)].n, readSkill(tables.pm.skills[String(id)].d).unread]).filter(([, u]) => u);
  assert.deepEqual(left, []);
});

/** A battle of a 亚比 of that species against 兔小子, with that one skill. */
function fightAs(race: number, skillId: number, rng = () => 0) {
  const e = new BattleEngine(tables, rng);
  const mine = makePet(tables, race, 100, "d", 1);
  const wild = makePet(tables, 1, 60, "d");
  mine.skills = [{ id: skillId, name: tables.pm.skills[String(skillId)].n, pp: 10, max: 10 }];
  wild.skills = [{ id: 1016, name: "噼啪乱击", pp: 30, max: 30 }];
  wild.hp = 99999;
  const b = e.start(1, "x", { id: 1, name: "a" }, mine, wild, true);
  b.wild.stats[0] = 99999;
  return { e, b };
}
const raceOf = (ao: number) => Number(Object.entries(tables.pm.species).find(([, s]) => s.ao === ao)![0]);

test("超奥义 in battle: 元素领域's elements, 煌炎阳's doubled marks, 禅's heals that hurt, 诅咒", () => {
  // 元素领域: an element each round; a blow taken (every chance comes) uses one for a status.
  const el = fightAs(raceOf(33072), 33072);
  el.e.skillTurn(el.b, 33072);
  el.e.endOfTurn(el.b);
  const held = Object.entries(el.b.mine.stacks ?? {}).filter(([k]) => k.endsWith("元素"));
  assert.equal(held.reduce((n, [, v]) => n + v, 0) >= 1, true);
  el.e.skillTurn(el.b, 33072);
  assert.ok(el.b.wild.status, "the attacker took a status from an element");
  // 煌炎阳: the other's 古魂印记 doubled, one more with each layer given.
  const g = fightAs(raceOf(33055), 33055);
  g.b.wild.stacks = { 古魂印记: 2 };
  g.e.skillTurn(g.b, 33055);
  assert.equal(g.b.wild.stacks.古魂印记, 4);
  assert.ok(g.b.mine.timed.some((x) => x.kind === "stackGive" && x.n === 1));
  // 禅: 停止行动 and 束缚; meanwhile its heals hurt it.
  const z = fightAs(raceOf(32073), 32073);
  z.e.skillTurn(z.b, 32073);
  const hp = z.b.wild.pet.hp;
  (z.e as unknown as { heal(f: unknown, n: number): number }).heal(z.b.wild, 100);
  assert.equal(z.b.wild.pet.hp, hp - 100);
  // 诅咒 (狂风暴雨: at the lowest 速度, 40% of 诅咒 instead): a quarter of the most 体力 a round.
  const c = fightAs(raceOf(26052), 26052);
  c.e.skillTurn(c.b, 26052);
  c.b.wild.stages.spd = -6;
  c.e.endOfTurn(c.b);
  assert.ok(c.b.wild.timed.some((x) => x.from === "诅咒"));
  const before = c.b.wild.pet.hp;
  c.e.endOfTurn(c.b);
  assert.ok(c.b.wild.pet.hp < before);
  assert.match(String((c.e.view(c.b, 1) as { battleView: { pmList: { pmSView: { st?: string } }[] } }).battleView.pmList[0].pmSView.st), /诅咒/);
});

test("skill backgrounds: 夜之域 for its 3 rounds, a 战界奥义 while its 亚比 is out", () => {
  const n = fightAs(1123, 17243);
  n.e.skillTurn(n.b, 17243);
  const bg = (f: typeof n) => (f.e.view(f.b, 0) as { battleView: { bg?: string } }).battleView.bg;
  assert.equal(bg(n), "65");
  n.e.endOfTurn(n.b);
  n.e.endOfTurn(n.b);
  assert.equal(bg(n), "65");
  n.e.endOfTurn(n.b);
  assert.equal(bg(n), undefined);
  const z = fightAs(raceOf(33072), 33072);
  z.e.skillTurn(z.b, 33072);
  for (let i = 0; i < 5; i++) z.e.endOfTurn(z.b);
  assert.equal(bg(z), "s_2_33072");
});

test("异常状态 in the view: each with its rounds left, on both sides (磁爆漩涡 binds both)", () => {
  assert.deepEqual(read("先发，重置双方属性并令双方束缚，50%概率令对方麻痹").statuses.map((x) => [x.name, !!x.self]), [["束缚", false], ["束缚", true], ["麻痹", false]]);
  const f = fightAs(2033, 13306);
  f.e.skillTurn(f.b, 13306);
  const sts = (slot: 0 | 1) => (f.e.view(f.b, slot) as { battleView: { pmList: { pmSView: { sts?: [string, number][] } }[] } }).battleView.pmList[0].pmSView.sts ?? [];
  for (const slot of [0, 1] as const) {
    const bind = sts(slot).find(([n]) => n === "束缚");
    assert.ok(bind && bind[1] > 0, `slot ${slot}: ${JSON.stringify(sts(slot))}`);
  }
  // Every chance comes: the other is paralysed as well.
  assert.ok(sts(1).some(([n]) => n === "麻痹"));
});

test("the 图鉴 lists the 亚比 that only fight: 究极 forms, 图腾, bosses' forms", () => {
  const dict = readFileSync(new URL("../../rebuild/gen/petdict/mmo/pet/petdictionarydata/PetDictionaryData.as", import.meta.url), "utf8");
  const row = (id: number) => dict.match(new RegExp(`^\\s*"${id}":new PetDictionaryDataItem\\((.*)\\)`, "m"))?.[1] ?? "";
  // 神照修罗王's 究极 form, by the 究极 table.
  const to = Number(Object.values(tables.pm.jiuji ?? {}).find((j) => tables.pm.species[String(j.to)]?.n && row(j.to))?.to);
  assert.ok(to > 0);
  assert.match(row(to), /究极变身而成。/);
  assert.ok(tables.species[String(to)], "and in pets.json");
  // Every species of the pet table has a row.
  const missing = Object.keys(tables.pm.species).filter((k) => !row(Number(k)));
  assert.deepEqual(missing, []);
});

test("风起云涌 leaves the other 1 PP a skill; 玩偶之家 makes the next 玩偶傀儡线's status sure", () => {
  const w = fightAs(399, 14233);
  w.e.skillTurn(w.b, 14233);
  assert.ok(w.b.wild.pet.skills.every((s) => s.pp <= 1));
  // No chance comes but the sure one.
  const d = fightAs(1310, 17257, () => 0.6);
  d.b.mine.pet.skills.push({ id: 17256, name: "玩偶傀儡线", pp: 10, max: 10 });
  d.e.skillTurn(d.b, 17257);
  assert.ok(d.b.mine.timed.some((x) => x.kind === "nextUse"));
  d.e.skillTurn(d.b, 17256);
  assert.ok(d.b.wild.status || d.b.wild.confuse > 0, "a status landed");
  assert.ok(!d.b.mine.timed.some((x) => x.kind === "nextUse" && x.left > 0), "once");
});
