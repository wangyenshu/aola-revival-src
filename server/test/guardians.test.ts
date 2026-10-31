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
