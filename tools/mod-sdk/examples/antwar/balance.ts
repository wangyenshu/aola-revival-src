// 蚁族的反击's balance: the campaign played on the server's battle engine by a plain player (it
// takes the 亚比 whose type suits the opponent best, uses 体力糖 and 活力豆, runs when only the 兵蚁
// is left, tries a fight three times; it uses no skill for its effect), per difficulty. Its tables
// are AntWarMod.as's (MODES and GUARDS): keep them the same when tuning.
//   node tools/mod-sdk/examples/antwar/balance.ts [easy|normal|hard] [runs] [-v]
import { readFile } from "node:fs/promises";
import { Emulator } from "../../../../server/src/core/emulator.ts";
import { MemoryRecorder } from "../../../../server/src/core/recorder.ts";
import { installSfs2013 } from "../../../../server/src/game/sfs2013/game.ts";
import { SFS2013_FRAMING, sfs2013Codec, type XtContext, type XtHandler } from "../../../../server/src/game/sfs2013/server.ts";

const site = new URL("../../../../rebuild/static/www.9aola.com/", import.meta.url);
const MODES: Record<string, any> = {
  easy: { team: 2, lv: -5, foe: 85, boss: 90, bossHp: 120, candy: 8, bean: 4, winCandy: 2, winBean: 1, bossCandy: 2 },
  normal: { team: 4, lv: 0, foe: 100, boss: 110, bossHp: 170, candy: 5, bean: 3, winCandy: 2, winBean: 1, bossCandy: 2 },
  hard: { team: 6, lv: 5, foe: 110, boss: 125, bossHp: 230, candy: 3, bean: 2, winCandy: 1, winBean: 1, bossCandy: 1 },
};
const G = [
  ["tom", 81, 48], ["kevin", 183, 50], ["nike", 36, 55], ["allen", 153, 56], ["sam", 78, 58], ["guard1", 18, 60],
  ["roy", 87, 62], ["jason", 75, 63], ["hade", 72, 65, 244], ["guard2", 189, 68, 241], ["hunter", 21, 70, 242], ["lucas", 299, 72, 243],
  ["mach", 99, 75], ["knight1", 45, 80, 218], ["knight3", 204, 80, 219], ["vick", 63, 85, 220], ["bluebrook", 293, 85, 221],
  ["arthur", 290, 90, 225], ["knight2", 45, 90, 223], ["magellan", 236, 92, 224], ["lanbao", 33, 92, 222],
  ["mutant", 227, 100, 226, true], ["kid", [502, 501, 500], 100, 0, true], ["landing", 1648, 100, 0, true], ["flora", 1649, 100, 0, true], ["rabel", 323, 100, 0, true],
] as const;

const mode = process.argv[2] ?? "normal";
const runs = Number(process.argv[3] ?? 3);
const verbose = process.argv.includes("-v");
const m = MODES[mode];

const pm = JSON.parse(await readFile(new URL("revival/pmdata.json", site), "utf8"));
const eff = (a: number, d: number[]) => d.reduce((x, t) => x * (pm.chart[String(a)]?.[String(t)] ?? 1), 1);
const types = (race: number) => pm.species[String(race)].t as number[];

async function campaign(seed: number) {
  const emu = new Emulator({ framing: SFS2013_FRAMING, codec: sfs2013Codec, recorder: new MemoryRecorder(), answerPolicy: false });
  const world = installSfs2013(emu, { dev: true, loadJson: async (p) => JSON.parse(await readFile(new URL(p, site), "utf8")) }) as unknown as { handlers: Map<string, XtHandler> };
  const NAME = "sim";
  const KEY = `user/${encodeURIComponent(NAME)}`;
  await emu.store.set(KEY, { id: 10001, name: NAME, pets: [], nextPetId: 1 });
  const call = async (key: string, params: Record<string, unknown> = {}) => {
    const out: [string, Record<string, any>][] = [];
    const ctx = { params, player: { name: NAME, room: { name: "sandboxroom" } }, session: { data: {} }, reply: (b: any, c = key.split(".")[1]) => out.push([c, b]), broadcast: () => {} } as unknown as XtContext;
    await world.handlers.get(key)!(ctx, key);
    return out;
  };
  const rec = async () => (await emu.store.get<any>(KEY))!;
  const mod = async (p: Record<string, unknown>) => (await call("SundriesExtension.revival_mod", { mod: "antwar", ...p })).find(([c]) => c === "revival_mod")![1];
  await mod({ op: "party", def: JSON.stringify({ pets: [{ race: 217, level: 100 }, { race: 216, level: 100, keep: true }], items: { 61: m.candy, 104: m.bean }, noHeal: "x", keepText: "x", fresh: true }) });
  const items = async () => (await rec()).items["2"] as Record<string, number>;
  const log: string[] = [];
  for (const [id, raceDef, level, captive, boss] of G) {
    const race = Array.isArray(raceDef) ? raceDef[seed % 3] : (raceDef as number);
    const pct = boss ? m.boss : m.foe;
    // AntWarMod.teamOf.
    const L = boss ? level : Math.min(100, level + m.lv);
    const one = (r2: number, l2: number, main = false) => ({ race: r2, level: Math.max(1, Math.min(100, l2)), hp: main && boss ? m.bossHp : pct, at: pct, de: pct, sa: pct, sd: pct, sp: pct });
    let enemies = [one(race, L, true)];
    const gi = G.findIndex((g) => g[0] === id);
    if (id === "mutant") for (let k = 1; k < m.team; k++) enemies.unshift(one(216, 97 - k));
    else if (!boss) {
      const partner = G[gi > 0 ? gi - 1 : gi + 1];
      const pr = partner[4] ? race : (partner[1] as number);
      enemies = [one(pr - 2, L - 9), one(race - 2, L - 8), one(pr - 1, L - 6), one(race - 1, L - 5), one(pr, L - 3), one(race, L, true)].slice(6 - Math.min(6, m.team));
    }
    const lv = JSON.stringify({ format: "aola-revival-level", version: 1, heal: false, enemies });
    let won = false;
    for (let attempt = 0; attempt < 3 && !won; attempt++) {
      // Heal outside the fight with 体力糖 (the bag's 道具) the hurt ones, keeping two for the fights.
      let r = await rec();
      for (const p of r.pets) {
        const max = (await mod({ op: "state" })).pets.find((q: any) => q.id === p.id).maxHp;
        for (let k = 0; k < 3 && p.hp < max * (p.race === 216 ? 0.7 : 0.4) && ((await items())["61"] ?? 0) > 2; k++) {
          await call("MaterialExtension.14_12", { ii: 61, pi: p.id });
          p.hp = (await rec()).pets.find((q: any) => q.id === p.id).hp;
        }
      }
      // Lead: the best counter among the living (not the 兵蚁 if another will do).
      r = await rec();
      const foeT = types(race);
      const score = (p: any) => {
        const mine = types(p.race);
        const atk = Math.max(...p.skills.filter((s: any) => (pm.skills[String(s.id)]?.p ?? 0) > 0).map((s: any) => eff(pm.skills[String(s.id)].t, foeT)), 0.5);
        const def = Math.max(...foeT.map((t: number) => eff(t, mine)));
        return (atk / def) * (p.hp > 0 ? 1 : 0) * (p.race === 216 ? 0.7 : 1);
      };
      // The bag: the 兵蚁 and the five best for this opponent (the 仓库's swapped in, as the HELLO's 远程仓库 allows).
      const all = [...r.pets, ...(r.storage ?? [])].filter((p: any) => p.race !== 216).sort((a: any, b: any) => score(b) - score(a));
      const want = new Set(all.slice(0, 5).map((p: any) => p.id));
      for (const p of r.pets) if (p.race !== 216 && !want.has(p.id)) await call("PocketMonsterExtension.1224", { id: p.id, loc: 1 });
      for (const p of r.storage ?? []) if (want.has(p.id)) await call("PocketMonsterExtension.1224", { id: p.id, loc: 0 });
      r = await rec();
      const living = r.pets.filter((p: any) => p.hp > 0);
      if (!living.length) break;
      living.sort((a: any, b: any) => score(b) - score(a));
      await call("PocketMonsterExtension.1221", { id: living[0].id });
      (globalThis as any).__cur = living[0].id;
      const start = await call("SundriesExtension.revival_sandbox", { lv, i: 0 });
      if (!start.some(([c]) => c === "2303" || c === "2401")) break;
      let end: any;
      for (let n = 0; n < 200 && !end; n++) {
        r = await rec();
        const st = await mod({ op: "state" });
        const out = await (async () => {
          // The pet out: the battle's mine (first living in the order the server keeps; read from state).
          const cur = r.pets.find((p: any) => p.id === (globalThis as any).__cur) ?? r.pets.find((p: any) => p.hp > 0);
          const max = st.pets.find((q: any) => q.id === cur.id).maxHp;
          const it = await items();
          if (cur.hp < max * 0.35 && (it["61"] ?? 0) > 0 && (cur.race === 216 || r.pets.filter((p: any) => p.hp > 0).length <= 2)) return call("PocketMonsterExtension.1402", { itemId: 61 });
          const usable = cur.skills.filter((s: any) => s.pp > 0 && (pm.skills[String(s.id)]?.p ?? 0) > 0);
          if (!usable.length && (it["104"] ?? 0) > 0) return call("PocketMonsterExtension.1402", { itemId: 104 });
          const best = (usable.length ? usable : cur.skills).sort((a: any, b: any) => pm.skills[String(b.id)].p * eff(pm.skills[String(b.id)].t, foeT) - pm.skills[String(a.id)].p * eff(pm.skills[String(a.id)].t, foeT))[0];
          return call("PocketMonsterExtension.1401", { skillId: best.id });
        })();
        end = out.find(([c]) => c === "2403")?.[1];
        if (out.some(([c]) => c === "2422")) {
          r = await rec();
          const next = r.pets.filter((p: any) => p.hp > 0).sort((a: any, b: any) => score(b) - score(a))[0];
          (globalThis as any).__cur = next.id;
          await call("PocketMonsterExtension.1403", { pmId: next.id });
          // Only the 兵蚁 left: it runs (a player would).
          if (next.race === 216) {
            const esc = await call("PocketMonsterExtension.1405", {});
            end = esc.find(([c]) => c === "2403")?.[1] ?? { isWin: false };
          }
        }
      }
      (globalThis as any).__cur = undefined;
      r = await rec();
      const keep = r.pets.find((p: any) => p.race === 216);
      won = !!end?.isWin;
      if (!won && (!keep || keep.hp <= 0)) {
        log.push(`${id}: LOST (兵蚁 fell) attempt ${attempt + 1}`);
        return { done: false, at: id, log };
      }
      if (!won) log.push(`${id}: lost, retry`);
    }
    if (!won) return { done: false, at: id, log };
    const it = await items();
    await mod({ op: "item", id: 61, n: m.winCandy + (boss ? m.bossCandy : 0) });
    await mod({ op: "item", id: 104, n: m.winBean });
    if (captive) await call("SundriesExtension.revival_mod", { mod: "antwar", op: "give", race: captive, level: 100 });
    const r = await rec();
    log.push(`${id} (${race}) won; candy ${it["61"] ?? 0} bean ${it["104"] ?? 0}; hp ${r.pets.map((p: any) => p.race + ":" + p.hp).join(" ")}`);
  }
  return { done: true, log };
}

let wins = 0;
const stops: Record<string, number> = {};
for (let i = 0; i < runs; i++) {
  const res = await campaign(i);
  if (res.done) wins++;
  else stops[res.at!] = (stops[res.at!] ?? 0) + 1;
  if (verbose || i === 0) console.log(res.log.join("\n"));
}
console.log(mode, "finished", wins, "/", runs, "stopped at", JSON.stringify(stops));
