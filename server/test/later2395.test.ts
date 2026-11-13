// The 亚比 to 2395 and their 超系 forms (the 工具箱 gives any of them), and the tables of 究极 and
// 圣域 that come with them (tools/gen_pmdata.py --upto 2395).
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import type { PetTables } from "../src/game/sfs2013/pets.ts";
import { makePet, statsOf } from "../src/game/sfs2013/pets.ts";
import { skillsAt } from "../src/game/sfs2013/pmdata.ts";

const revival = new URL("../../rebuild/static/www.9aola.com/revival/", import.meta.url);
const tables: PetTables = {
  species: JSON.parse(readFileSync(new URL("pets.json", revival), "utf8")),
  pm: JSON.parse(readFileSync(new URL("pmdata.json", revival), "utf8")),
};
const pm = { ...tables.pm, jiuji: tables.pm.jiuji ?? {}, weather: tables.pm.weather ?? {} };

test("every 亚比 the later table has to 2395 is there, with its skills", () => {
  for (const id of ["1652", "2000", "2090", "2160", "2161", "2378", "2395"]) assert.ok(pm.species[id], id);
  // Rows the table never had stay out (116, 117 …), and 1651 → 2395 is whole but for those.
  assert.equal(pm.species["116"], undefined);
  for (const sp of Object.values(pm.species)) for (const [, sid] of sp.learn) assert.ok(pm.skills[String(sid)], `${sp.n}: ${sid}`);
});

test("the 超系 forms of the 亚比 to 2395 come too (超龙星诺 of 龙星诺, 超巨岩 of 巨岩, 超暗 … of 赤翼魔龙王)", () => {
  for (const id of ["2391", "2401", "2577"]) assert.ok(pm.species[id], id);
  assert.equal(pm.species["2398"], undefined, "费曼 is the 超系 of 费仔 (2397): not kept");
  assert.equal(pm.species["2401"].t[0], 27, "超土");
});

test("each 究极 line is at its top 等级: 三阶 (6 turns), the two 战骑 二阶", () => {
  const lines = Object.entries(pm.jiuji);
  assert.equal(lines.length, 49);
  for (const [from, j] of lines) {
    assert.ok(pm.species[from] && pm.species[String(j.to)], from);
    assert.equal(j.lv, from === "2334" || from === "2382" ? 2 : 3, from);
  }
  assert.deepEqual(pm.jiuji["2160"], { ...pm.jiuji["2160"], to: 2161, lv: 3, keep: 6, up: [800, 800, 850, 0, 0, 0] });
  assert.equal(pm.jiuji["2395"].to, 2396, "虎烈张飞's 究极 form, 2396, is kept for it");
});

test("圣域: the 特性 that make one and the 圣域技能 learnt at Lv60 point at rows of the table", () => {
  const makers = Object.values(pm.species).filter((s) => s.f);
  const learnt = Object.values(pm.species).filter((s) => s.sy);
  assert.ok(makers.length >= 18 && learnt.length >= 31);
  for (const s of makers) for (const w of s.f!.split("#")) assert.ok(pm.weather[w], w);
  for (const s of learnt) {
    const [lv, w] = s.sy!.split("-");
    assert.equal(lv, "60");
    assert.equal(pm.weather[w]?.k, 1, w);
  }
  assert.equal(pm.weather["1023"].n, "幻灵");
});

test("a 亚比 of 2014 is made and has its numbers (圣域·幻雷 Lv60)", () => {
  const p = makePet(tables, 2090, 60, "d");
  assert.equal(p.skills.length, 4);
  assert.ok(statsOf(p, tables).every((v) => v > 0));
});

test("static check: every 亚比 is whole (属性, skills, 图鉴 row), at any level it has a skill", () => {
  const dict = readFileSync(new URL("../../rebuild/gen/petdict/mmo/pet/petdictionarydata/PetDictionaryData.as", import.meta.url), "utf8");
  const named = new Map([...dict.matchAll(/^\s*"(\d+)":new PetDictionaryDataItem\("\d+","([^"]*)"/gm)].map((m) => [m[1], m[2]]));
  const wrong: string[] = [];
  for (const [id, sp] of Object.entries(pm.species)) {
    if (sp.s.length !== 6 || sp.s.some((v) => v <= 0)) wrong.push(`${id} stats`);
    if (sp.t.some((t) => !pm.chart[String(t)])) wrong.push(`${id} 属性`);
    if (!sp.learn.length) wrong.push(`${id} no skills`);
    if (!tables.species[id]) wrong.push(`${id} not in pets.json`);
    if (!named.has(id)) wrong.push(`${id} no 图鉴 row`);
    for (const lv of [1, 20, 59, 100]) {
      const ids = skillsAt(sp, lv);
      if (!ids.length || new Set(ids).size !== ids.length) wrong.push(`${id} skills at ${lv}`);
    }
  }
  for (const [id, s] of Object.entries(pm.skills)) {
    if (!s.n || ![0, 1, 2].includes(s.k) || !pm.chart[String(s.t)] || !(s.pp > 0)) wrong.push(`skill ${id}`);
  }
  assert.deepEqual(wrong, []);
  // Rows of the later table out of order (天极鲸): the skills of its level all the same.
  const whale = pm.species["2076"];
  assert.ok(skillsAt(whale, 50).includes(16328), "the Lv50 skill, after the table's Lv60 row");
  // 暗行罗刹 learns its first at 50: below that it knows it.
  assert.deepEqual(skillsAt(pm.species["2227"], 10), [17333]);
});
