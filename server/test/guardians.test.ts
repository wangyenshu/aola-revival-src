import assert from "node:assert/strict";
import { test } from "node:test";
import { guardianLevel, MEMBER_ARENA_LEVELS } from "../src/game/sfs2013/battle.ts";

test("the 守护者 forms fight at their BossTimeHelper levels", () => {
  assert.equal(guardianLevel(10090, 0), 60); // 沙麒麟, first form
  assert.equal(guardianLevel(20090, 1), 80); // 沙麒麟, second form
  assert.equal(guardianLevel(20102, 2), 100); // 合金猛将's third form
  assert.equal(guardianLevel(10472, 1), 100); // 魂斗鱼's pair, the second
  assert.equal(guardianLevel(11516, 2), 80); // 终极麦斗王's trio
  assert.equal(guardianLevel(12345, 3), 35); // not a 守护者: as before
});

test("黑星堡垒's bosses are stronger floor by floor", () => {
  assert.ok(MEMBER_ARENA_LEVELS.viparena2 < MEMBER_ARENA_LEVELS.viparena5);
  assert.ok(MEMBER_ARENA_LEVELS.viparena5 < MEMBER_ARENA_LEVELS.viparena7);
});

test("a 守护者 win brings the egg of its line", async () => {
  const { eggOfLine } = await import("../src/game/sfs2013/battle.ts");
  const species = { 88: { next: 89 }, 89: { next: 90 }, 90: {}, 1319: { next: 1320 }, 1320: {} } as Record<string, { next?: number }>;
  assert.equal(eggOfLine({ species }, 90), 88); // 沙麒麟 -> 沙麒麟亚比蛋
  assert.equal(eggOfLine({ species }, 1320), 1319); // 伊泽 -> 小泽亚比蛋
  assert.equal(eggOfLine({ species }, 536), 0); // 震天石魔: no egg
});

test("终极麦斗王's team: its last 亚比 gives the 麦斗猪蛋", async () => {
  const { BOSS_EGGS } = await import("../src/game/sfs2013/battle.ts");
  assert.equal(BOSS_EGGS[11516], 520);
});

test("蓝羽灵者: three forms from its panel, the 小羽灵蛋 only for its last", async () => {
  const { BOSS_EGGS } = await import("../src/game/sfs2013/battle.ts");
  assert.deepEqual([guardianLevel(31394, 0), guardianLevel(21394, 1), guardianLevel(11394, 2)], [60, 80, 100]);
  assert.equal(BOSS_EGGS[31394], 0);
  assert.equal(BOSS_EGGS[21394], 0);
  assert.equal(BOSS_EGGS[11394], 1393);
});

test("each of a pair fought as a boss of its own keeps its level (魂斗鱼, the second 浮云尊者)", () => {
  assert.equal(guardianLevel(10472, 0), 100);
  assert.equal(guardianLevel(20475, 0), 100);
  // 神武月 and the 满月 神武月 (StartBoss) are two bosses
  assert.equal(guardianLevel(10105, 0), 80);
  assert.equal(guardianLevel(20105, 0), 100);
});

test("only the last form of a 守护者 brings its egg", async () => {
  const { lastGuardianForm } = await import("../src/game/sfs2013/battle.ts");
  assert.equal(lastGuardianForm(10090, 0), false); // 沙麒麟 Lv60
  assert.equal(lastGuardianForm(20090, 1), true); // 沙麒麟 Lv80
  assert.equal(lastGuardianForm(10102, 1), false); // 合金猛将's second (same id as the first)
  assert.equal(lastGuardianForm(20102, 2), true);
  assert.equal(lastGuardianForm(11213, 0), false); // 岩波斗魂者
  assert.equal(lastGuardianForm(31213, 2), true);
  assert.equal(lastGuardianForm(10472, 0), true); // 魂斗鱼, its own boss
  assert.equal(lastGuardianForm(10884, 0), true); // 猪猪超人, one form
  assert.equal(lastGuardianForm(12345, 0), true); // not in the table
});
