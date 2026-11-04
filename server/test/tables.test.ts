// The site's tables (revival/*.json, game.ts siteTable): kept once had; a miss (the split setup
// reads them over the network) is asked again later, not kept empty until a restart.
import assert from "node:assert/strict";
import { test } from "node:test";
import { siteTable } from "../src/game/sfs2013/game.ts";

test("a table the site did not give is asked again after a while, then kept", async () => {
  let clock = 0;
  let asked = 0;
  let up = false;
  const empty = {};
  const t = siteTable<Record<string, number>>(
    async () => {
      asked++;
      if (!up) throw new Error("unreachable");
      return { a: 1 };
    },
    empty,
    1000,
    () => clock,
  );
  assert.equal(await t(), empty, "the site out of reach: the empty table");
  assert.equal(asked, 1);
  clock = 500;
  assert.equal(await t(), empty);
  assert.equal(asked, 1, "not asked again at once");
  up = true;
  clock = 1500;
  assert.deepEqual(await t(), { a: 1 }, "asked again later: had");
  clock = 99999;
  const kept = await t();
  assert.deepEqual(kept, { a: 1 });
  assert.equal(asked, 2, "kept: not asked again");
  // Asked together: one request.
  let calls = 0;
  const u = siteTable(async () => (calls++, { b: 2 }), {});
  await Promise.all([u(), u(), u()]);
  assert.equal(calls, 1);
  // A missing file (undefined) or something not a table is a miss too.
  const v = siteTable(async () => undefined, empty, 1000, () => 0);
  assert.equal(await v(), empty);
});
