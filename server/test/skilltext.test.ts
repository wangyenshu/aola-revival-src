import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { BattleEngine, balOf } from "../src/game/sfs2013/battle.ts";
import { makePet, type PetTables } from "../src/game/sfs2013/pets.ts";
import { ALL_STATS, readSkill } from "../src/game/sfs2013/skilltext.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};
const skillNamed = (n: string) => Number(Object.entries(tables.pm.skills).find(([, s]) => s.n === n)![0]);

test("every skill of the 图鉴's 亚比 is read to the last word", () => {
  const left: string[] = [];
  for (const id of Object.keys(tables.species)) {
    for (const [, sid] of tables.pm.species[id]?.learn ?? []) {
      const s = tables.pm.skills[String(sid)];
      if (!s) continue;
      const { unread } = readSkill(s.d);
      if (unread) left.push(`${s.n}: ${unread}`);
    }
  }
  assert.deepEqual([...new Set(left)], []);
});

test("全属性 is all eight: 攻击, 防御, 特攻, 特防, 速度, 命中, 闪避 and 暴击", () => {
  assert.deepEqual(readSkill("提升自己全属性2级").fx.stages, [{ self: true, stats: ALL_STATS, delta: 2, chance: 100 }]);
  assert.deepEqual(ALL_STATS, ["atk", "def", "satk", "sdef", "spd", "acc", "eva", "crit"]);
});

/** 梅卡 Lv100 against a 小冰犬: the player's skill, the wild 亚比's 噼啪乱击. */
function fight(skills: string[], seed = 3) {
  let s = seed;
  const e = new BattleEngine(tables, () => ((s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x80000000));
  const mine = makePet(tables, 323, 100, "d", 1);
  const wild = makePet(tables, 43, 60, "d");
  mine.skills = skills.map((n) => ({ id: skillNamed(n), name: n, pp: 10, max: 10 }));
  wild.skills = [{ id: 1016, name: "噼啪乱击", pp: 30, max: 30 }];
  const b = e.start(1, "x", { id: 1, name: "a" }, mine, wild, true);
  return { e, b, mine, wild, use: (i: number) => [...e.skillTurn(b, mine.skills[i].id), ...e.endOfTurn(b)] };
}

test("梅卡's 原· skills: half the foe's HP, 全属性 (all eight) +2, half the damage back, 冰冻", () => {
  const f = fight(["原·流水灯", "原·水源之力"]);
  const hp = f.wild.hp;
  f.use(0);
  assert.equal(f.wild.hp, hp - Math.floor(hp / 2));
  f.use(1);
  assert.equal(balOf(f.b.mine.stages), "2#2#2#2#2#2#2#2");
  const g = fight(["原·似水流年"]);
  g.mine.hp = 100;
  g.wild.level = 100;
  g.wild.hp = 5000;
  g.b.wild.stats[0] = 5000;
  const [r] = g.use(0);
  assert.ok(Number(r[1].selfHpInc) > 0, "it drains");
});

test("回血, 护盾, PP: lasting heals, a shield that takes 50 a hit, PP taken", () => {
  const regen = fight(["圣疗"]);
  regen.mine.hp = 100;
  const msgs = regen.use(0);
  assert.ok(msgs.some(([c, m]) => c === "2421" && Number(m.hpInc) > 0 && m.slotId === 0), "圣疗 heals at the turn's end");
  const shield = fight(["银光护盾"]);
  shield.use(0);
  assert.equal(shield.b.mine.timed.find((x) => x.kind === "absorb")?.n, 50);
  const pp = fight(["焚天魔焰"]);
  pp.wild.hp = pp.b.wild.stats[0] = 99999;
  let emptied = false;
  for (let i = 0; i < 12 && !emptied; i++) {
    pp.mine.skills[0].pp = 10;
    pp.use(0);
    emptied = pp.wild.skills[0].pp === 0;
  }
  assert.ok(emptied, "25%概率扣光对方所有技能PP");
});

test("charging, 束缚 keeps the 亚比 in, 恢复性睡眠", () => {
  const c = fight(["潜水攻击"]);
  const hp = c.wild.hp;
  c.use(0);
  assert.equal(c.wild.hp, hp, "this turn it gathers power");
  assert.equal(c.b.mine.charging, c.mine.skills[0].id);
  c.use(0);
  assert.ok(c.wild.hp < hp, "next turn it hits");
  const t = fight(["角斗"]);
  t.use(0);
  assert.ok(t.b.wild.bind > 0 && t.b.wild.trapped > 0);
  const r = fight(["恢复性睡眠"]);
  r.mine.hp = 10;
  r.use(0);
  assert.equal(r.b.mine.status, "睡眠");
  assert.ok(r.mine.hp > 10);
});

test("体力越少威力越大 and the like: the Pokémon rules the tables follow", async () => {
  const { hpPower } = await import("../src/game/sfs2013/battle.ts");
  assert.equal(readSkill("攻击对方单体，自己损失体力越少，威力越大").fx.powerByHp, "high");
  assert.equal(readSkill("自己剩余体力值越少，威力越大").fx.powerByHp, "low");
  assert.equal(readSkill("攻击对方全体，自己体力值越少，威力越低").fx.powerByHp, "high");
  const at = (hp: number, max = 100) => ({ pet: { hp }, stats: [max] }) as unknown as Parameters<typeof hpPower>[2];
  // 威力 — and 越少越大 (破天拳): 抓狂 / 起死回生, 40 at full HP up to 400.
  assert.equal(hpPower("low", -1, at(100), at(1)), 40);
  assert.equal(hpPower("low", -1, at(30), at(1)), 160);
  assert.equal(hpPower("low", -1, at(2), at(1)), 400);
  // 越少越低 with the table's 300 (烈焰焚天): 300 at full HP, less as it falls.
  assert.equal(hpPower("high", 300, at(100), at(1)), 300);
  assert.equal(hpPower("high", 300, at(50), at(1)), 150);
  // 对方剩余体力值越多 (风逝).
  assert.equal(hpPower("foeHigh", -1, at(1), at(100)), 240);
});

test("蓄力: this turn the gathering, next turn the blow without PP; a 亚比 that cannot act loses it", () => {
  const f = fight(["潜水攻击"]);
  const [gather] = f.use(0);
  assert.match(String(gather[1].desc), /正在蓄力/);
  assert.equal(gather[1].self, true);
  assert.equal(f.mine.skills[0].pp, 9);
  const hp = f.wild.hp;
  f.use(0);
  assert.ok(f.wild.hp < hp);
  assert.equal(f.mine.skills[0].pp, 9, "the blow costs no PP");
  assert.equal(f.b.mine.charging, undefined);
  const g = fight(["潜水攻击"]);
  g.use(0);
  g.b.mine.fear = 1;
  g.use(0);
  assert.equal(g.b.mine.charging, undefined, "害怕 on the blow's turn: the power is lost");
  const s = fight(["魂葬破"]);
  s.use(0);
  assert.equal(s.b.mine.chargeHurt, true, "hit while it gathered: no doubling");
});

test("全场 with a trait: 闇月马戏团 for the 七彩小丑 line, 昏暗 for 超暗黑, 数码领域 for one's own 数码系", () => {
  let s = 5;
  const e = new BattleEngine(tables, () => ((s = (s * 1103515245 + 12345) & 0x7fffffff) / 0x80000000));
  const clown = makePet(tables, 176, 50, "d", 1);
  clown.skills = [{ id: skillNamed("闇月马戏团"), name: "", pp: 10, max: 10 }];
  const b = e.start(1, "x", { id: 1, name: "a" }, clown, makePet(tables, 43, 50, "d"), true);
  e.act(b, b.mine, b.wild, clown.skills[0].id);
  assert.equal(b.mine.stages.spd, 1, "the 马戏团 亚比: 速度 +1");
  assert.equal(b.mine.timed.find((x) => x.kind === "power")?.mult, 1.5, "伤害 +50%");
  assert.equal(b.wild.stages.spd, 0, "小冰犬 is not of the 马戏团");
  const meka = makePet(tables, 323, 50, "d", 1);
  const c = e.start(1, "x", { id: 1, name: "a" }, meka, makePet(tables, 43, 50, "d"), true);
  const [, r] = e.act(c, c.mine, c.wild, skillNamed("闇月马戏团"));
  assert.match(String(r.desc), /没有效果/);
  const dark = makePet(tables, 320, 50, "d", 1); // 雷帝神, 属性 超暗 (30)
  const d = e.start(1, "x", { id: 1, name: "a" }, dark, makePet(tables, 43, 50, "d"), true);
  e.act(d, d.mine, d.wild, skillNamed("昏暗"));
  assert.ok(d.mine.stages.eva >= 1 && d.mine.stages.eva <= 2);
});

test("命运硬币, 速战意念's 4 turns, 幽夜玫瑰's plain drain", () => {
  const coin = readSkill("1/3概率秒杀对方单体，2/3自己死亡，对守护无效").fx;
  assert.equal(coin.ohkoFailFaint, true);
  const g = fight(["速战意念", "龟息"]);
  g.use(0);
  assert.equal(g.b.mine.stages.spd, 3);
  for (let i = 0; i < 2; i++) g.use(1);
  assert.equal(g.b.mine.stages.spd, 3, "for 4 turns, the turn it is used the first");
  g.use(1);
  assert.equal(g.b.mine.stages.spd, 0, "then back");
  const rose = readSkill("攻击对方单体，吸取伤害值的30%来回复自己； 如果对方处于睡眠状态，则吸取伤害值的60%来回复自己").fx;
  assert.equal(rose.drain, 0.3);
  assert.deepEqual(rose.powerIf, [{ cond: { foeStatus: "睡眠" }, drain: 0.6 }]);
});

test("威吓: no effect on a wild 亚比; on the player's 亚比 it asks the turn for a switch", () => {
  const f = fight(["威吓"]);
  const [, r] = f.e.act(f.b, f.b.mine, f.b.wild, skillNamed("威吓"));
  assert.match(String(r.desc), /没有效果/);
  assert.equal(f.b.forceOut, undefined);
  f.e.act(f.b, f.b.wild, f.b.mine, skillNamed("威吓"));
  assert.equal(f.b.forceOut, 0);
});

/** A turn of the guarding skill (before or, 后发, after the other's blow), then the other's blow. */
function guarded(skill: string, attack: number) {
  const e = new BattleEngine(tables, () => 0.5);
  const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 50, "d", 1), makePet(tables, 1, 50, "d"), true);
  for (const f of [b.mine, b.wild]) {
    f.stats = [3000, 100, 100, 100, 100, 100];
    f.pet.hp = 3000;
  }
  const id = skillNamed(skill);
  e.startTurn(b);
  const after = readSkill(tables.pm.skills[String(id)].d).fx.last;
  if (after) e.act(b, b.wild, b.mine, attack);
  e.act(b, b.mine, b.wild, id);
  if (!after) e.act(b, b.wild, b.mine, attack);
  return { took: 3000 - b.mine.pet.hp, back: 3000 - b.wild.pet.hp, b, e };
}
const PHYS = 1045; // 冲击腿, 普通攻击
const SPEC = 13001; // 电之打击, 特殊攻击

test("guards against 普通攻击 or 特殊攻击, and counters, also used after the blow (后发)", () => {
  const plain = guarded("白眼", PHYS).took;
  const plainSpec = guarded("白眼", SPEC).took;
  // 意念庇护: 特殊攻击 only; 力念庇护: 普通攻击 only.
  assert.equal(guarded("意念庇护", SPEC).took, 0);
  assert.equal(guarded("意念庇护", PHYS).took, plain);
  assert.equal(guarded("力念庇护", PHYS).took, 0);
  assert.equal(guarded("力念庇护", SPEC).took, plainSpec);
  // 浑天盾: 1.5 times a 普通攻击 back, nothing of a 特殊攻击.
  assert.equal(guarded("浑天盾", PHYS).back, Math.floor(plain * 1.5));
  assert.equal(guarded("浑天盾", SPEC).back, 0);
  // 零界反转 (后发): the blow taken this turn, 1.5 times back; 回影反射 (后发): 特殊攻击 only, doubled.
  assert.equal(guarded("零界反转", PHYS).back, Math.floor(plain * 1.5));
  assert.equal(guarded("回影反射", SPEC).back, plainSpec * 2);
  assert.equal(guarded("回影反射", PHYS).back, 0);
  // 封魔秘诀: the other's 普通攻击 hardly hits.
  assert.equal(guarded("封魔秘诀", PHYS).took, 0);
  // 正电极盾 and 负电极盾 do not stand together.
  const g = guarded("正电极盾", SPEC);
  g.e.act(g.b, g.b.mine, g.b.wild, skillNamed("负电极盾"));
  assert.deepEqual(g.b.mine.timed.map((x) => x.from), ["负电极盾", "负电极盾"]);
});

test("停止行动: the user's next turn, N turns then what comes after, the other's next turn", () => {
  const stops = (sid: number, seq: number[], turns: number) => {
    let i = 0;
    const e = new BattleEngine(tables, () => seq[i++ % seq.length]);
    const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 50, "d", 1), makePet(tables, 1, 50, "d"), true);
    for (const f of [b.mine, b.wild]) {
      f.stats = [99999, 100, 100, 100, 100, 100];
      f.pet.hp = 99999;
    }
    const row: string[] = [];
    for (let t = 0; t < turns; t++) {
      e.startTurn(b);
      const [, a] = e.act(b, b.mine, b.wild, t === 0 ? sid : 1203);
      const [, c] = e.act(b, b.wild, b.mine, 1203);
      e.endOfTurn(b);
      b.turn++;
      row.push((a.srt === 3 ? "停" : "动") + (c.srt === 3 ? "停" : "动"));
    }
    return { row: row.join(" "), b };
  };
  assert.equal(stops(skillNamed("狮子流星落"), [0], 3).row, "动动 停动 动动", "下回合自己停止行动");
  assert.equal(stops(skillNamed("霜冻风暴"), [0.99], 5).row, "动动 停动 停动 停动 动动", "使用后自己停止行动3回合");
  assert.equal(stops(skillNamed("疾风迅雷脚"), [0], 5).row, "动动 动动 动动 停动 动动", "连续攻击对方3回合，之后自己停止行动1回合");
  const q = stops(skillNamed("潜龙勿用"), [0], 3);
  assert.equal(q.row, "动动 停动 停动");
  assert.equal(q.b.mine.stages.atk, 3, "全属性 +3 after the 2 turns");
  assert.equal(stops(skillNamed("神圣涅槃"), [0], 4).row, "动动 停动 停动 动停", "2回合后令对方害怕");
  assert.equal(stops(skillNamed("原子爆裂"), [0, 0, 0, 0, 0.9, 0.9, 0.9, 0.9], 3).row, "动动 动停 动动", "the other's next turn");
});

test("连击: each hit meets the guards (玄灵甲, 霸王之气 each hit; 银光护盾's 50 a turn)", () => {
  const into = (guard: string) => {
    const e = new BattleEngine(tables, () => 0);
    const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 50, "d", 1), makePet(tables, 1, 50, "d"), true);
    for (const f of [b.mine, b.wild]) {
      f.stats = [99999, 100, 100, 100, 100, 100];
      f.pet.hp = 99999;
    }
    e.startTurn(b);
    e.act(b, b.mine, b.wild, skillNamed(guard));
    const [, r] = e.act(b, b.wild, b.mine, skillNamed("回旋踢")); // 1回合攻击对方单体4次
    return { r, b };
  };
  const plain = into("白眼").r;
  assert.equal(plain.hits, 4);
  assert.equal(into("玄灵甲").b.wild.stages.atk, -4, "全属性 -1 for each of the 4 hits");
  assert.equal(into("霸王之气").r.selfHpInc, -200, "50 back for each hit");
  assert.equal(into("银光护盾").r.hpInc, Number(plain.hpInc) + 50, "50 a turn, not 50 a hit");
});

test("连击: each hit rolls its own chances (玄灵甲's 50%, the 暴击)", () => {
  let seed = 12345;
  const rng = () => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x80000000);
  const drops = new Set<number>();
  const crits = new Set<number>();
  for (let i = 0; i < 400; i++) {
    const e = new BattleEngine(tables, rng);
    const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 50, "d", 1), makePet(tables, 1, 50, "d"), true);
    for (const f of [b.mine, b.wild]) {
      f.stats = [99999, 100, 100, 100, 100, 100];
      f.pet.hp = 99999;
    }
    e.startTurn(b);
    e.act(b, b.mine, b.wild, skillNamed("玄灵甲"));
    const [, r] = e.act(b, b.wild, b.mine, skillNamed("回旋踢"));
    if (r.srt === 2) continue;
    drops.add(-b.wild.stages.atk);
    const m = String(r.desc).match(/暴击(\d+)次|暴击！/);
    crits.add(m ? (m[1] ? Number(m[1]) : 1) : 0);
  }
  for (const k of [1, 2, 3]) assert.ok(drops.has(k), `玄灵甲 lowered ${k} times of 4 (not all or none)`);
  assert.ok(crits.has(1), "one 暴击 of 4 hits (not all or none)");
});

test("连击: each hit's damage goes with the report (shown one after another)", () => {
  const e = new BattleEngine(tables, () => 0.5);
  const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, 1, 50, "d", 1), makePet(tables, 1, 50, "d"), true);
  for (const f of [b.mine, b.wild]) {
    f.stats = [99999, 100, 100, 100, 100, 100];
    f.pet.hp = 99999;
  }
  const [, r] = e.act(b, b.mine, b.wild, skillNamed("回旋踢"));
  const list = r.hitDmg as number[];
  assert.equal(list.length, 4);
  assert.equal(list.reduce((a, d) => a + d, 0), -Number(r.hpInc));
  assert.equal((r.hitCri as number[]).length, 4);
  const [, one] = e.act(b, b.mine, b.wild, 1016);
  assert.equal(one.hitDmg, undefined, "one hit: one number");
});

/** Two sturdy 兔小子 (no 属性: every skill hits plainly); the rng 0.5 throughout. */
function sturdy(race = 1) {
  const e = new BattleEngine(tables, () => 0.5);
  const b = e.start(1, "x", { id: 1, name: "a" }, makePet(tables, race, 60, "d", 1), makePet(tables, 1, 50, "d"), true);
  for (const f of [b.mine, b.wild]) {
    f.stats = [99999, 100, 100, 100, 100, 100];
    f.pet.hp = 99999;
    f.types = [-1, -1];
  }
  const turn = (id: number, miss = false) => {
    e.startTurn(b);
    b.wild.stages.eva = miss ? 6 : 0;
    const [, r] = e.act(b, b.mine, b.wild, id);
    b.wild.stages.eva = 0;
    b.turn++;
    return r;
  };
  return { e, b, turn };
}

test("回复 is shown whole; 嗜血之矛's heal past the full 体力 becomes 护盾, which takes the blows first", () => {
  const { e, b, turn } = sturdy(320);
  b.mine.stats[1] = 2000;
  b.mine.pet.hp = b.mine.stats[0] - 30;
  const r = turn(skillNamed("嗜血之矛"));
  const want = Math.floor(-Number(r.hpInc) * 0.6);
  assert.equal(r.selfHpInc, want, "the whole 60%, though only 30 were lost");
  assert.equal(b.mine.pet.hp, b.mine.stats[0]);
  assert.equal(b.mine.armour, want - 30);
  assert.match(String(r.desc), new RegExp(`获得了${want - 30}点护盾`));
  const st = (e.view(b, 0) as { battleView: { pmList: { pmSView: { st: string } }[] } }).battleView.pmList[0].pmSView.st;
  assert.match(st, new RegExp(`护盾${want - 30}`));
  e.startTurn(b);
  const [, hit] = e.act(b, b.wild, b.mine, 1016);
  assert.equal(b.mine.pet.hp, b.mine.stats[0], "the 护盾 took it");
  assert.ok(b.mine.armour! < want - 30);
  assert.match(String(hit.desc), /护盾抵挡了\d+点伤害/);
});

test("蓄力 and 连续攻击N回合: the view names the skill that goes on by itself; it needs no PP", () => {
  const { e, b, turn } = sturdy();
  const soul = skillNamed("魂葬破");
  const view = () => (e.view(b, 0) as { battleView: { forced?: number } }).battleView.forced;
  turn(soul);
  assert.equal(view(), soul);
  turn(skillNamed("冲击腿"));
  assert.equal(view(), undefined, "the blow came: the choice is free again");
  assert.deepEqual(readSkill("蓄力2回合下回合爆发出无法阻挡的伤害").fx.chargeTurns, 2);
  const snake = skillNamed("狂蟒三重击");
  turn(snake);
  assert.equal(view(), snake);
  turn(snake);
  assert.equal(view(), snake);
  turn(snake);
  assert.equal(view(), undefined);
});

test("连续攻击N回合: the power grows each turn and starts again with the next use; a miss takes it back", () => {
  const dmg = (picks: string[], misses: number[] = []) => {
    const { turn } = sturdy();
    return picks.map((n, i) => -Number(turn(skillNamed(n), misses.includes(i + 1)).hpInc) || 0);
  };
  const [a, b2, c, d] = dmg(["狂蟒三重击", "狂蟒三重击", "狂蟒三重击", "狂蟒三重击"]);
  assert.ok(b2 > a * 1.8 && c > b2 * 1.8, "each turn doubled");
  assert.equal(d, a, "a new use starts from its own power");
  const [, missed, after] = dmg(["迅杀", "迅杀", "迅杀"], [2]);
  assert.equal(missed, 0);
  assert.equal(after, dmg(["迅杀"])[0], "攻击失误则清除加倍效果");
  const [s1, , s3] = dmg(["星诺火纹", "星诺火纹", "星诺火纹"], [2]);
  assert.ok(s3 > s1, "不管命中与否，每回合威力增加30");
  const plain = dmg(["冲击腿", "狂蟒三重击"])[1];
  const boosted = dmg(["千军万马", "狂蟒三重击"])[1];
  assert.ok(boosted > plain * 2.5, "使用千军万马后威力大大提升 (and its 攻击+1)");
});

test("the quest opponents 邪恶霹雳, 组合机器人, 苹果智能炮, 风筝雷电射线 have the skills of their battle rows", () => {
  const names = (race: number) => tables.pm.species[String(race)].learn.map(([, s]) => tables.pm.skills[String(s)].n);
  assert.deepEqual(names(332), ["霹雳穿甲炮", "雷神之怒", "聚能粒子炮", "燃烧的意志"]);
  assert.deepEqual(names(334), ["霹雳穿甲炮", "超导V型斩", "聚能粒子炮"]);
  assert.deepEqual(names(360), ["激发力量", "噼啪乱击", "合击"]);
  assert.deepEqual(names(361), ["激发力量", "噼啪乱击", "合击"]);
  assert.equal(makePet(tables, 360, 30, "d").skills.length, 3);
});

test("the computer's 亚比 out of PP takes a 高级活力豆 (its turn), then fights on; never 挣扎", () => {
  const { e, b } = sturdy();
  b.wild.pet.skills = [{ id: 1016, name: "噼啪乱击", pp: 0, max: 30 }];
  const hp = b.mine.pet.hp;
  const [bean, mine] = e.skillTurn(b, skillNamed("冲击腿"));
  assert.equal(bean[0], "2412");
  assert.equal(bean[1].reqSId, 1);
  assert.match(String(bean[1].desc), /使用了高级活力豆/);
  assert.equal(b.wild.pet.skills[0].pp, 20, "可恢复战斗中的亚比技能使用次数20次");
  assert.equal(mine[0], "2411", "the player's skill still comes");
  assert.equal(b.mine.pet.hp, hp, "the bean was its turn: no blow");
  const [next] = e.wildTurn(b);
  assert.equal(next[1].name, "噼啪乱击");
  assert.equal(b.wild.pet.skills[0].pp, 19);
});
