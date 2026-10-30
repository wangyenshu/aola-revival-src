// A look at the steps of the 2012 story quests: for each step (the first
// STEPS of every quest, default 3), make it the one being done (dev command
// tasktest <step>), go to the scene of its NPC conversation, click the NPC
// and see that the step's conversation opens (or that the quest's script
// opened one by itself). Errors the scene's scripts throw are counted.
//
//   node server/test/e2e/boot2013.mjs --out work/e2e-stepsmoke --seconds 7200 --query dev=1 \
//     --scenario server/test/e2e/scenarios/stepsmoke.mjs
//
// QUESTS=1742,1750 or QUESTS=1700-1999 limits the quests; STEPS=all takes
// every step. The steps and conversations are those of tools/gen_tasks.py.

import { clickNpc, closeTalk } from "./lib.mjs";
import { appendFileSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const gen = (p) => readFileSync(new URL(`../../../../rebuild/gen/${p}`, import.meta.url), "utf8");
const ERRORS = /Error #\d+|ReferenceError|TypeError|VerifyError|taskext .*(error|cannot load)/;

export default async function stepsmoke(h) {
  const data = gen("taskdata/mmo/taskdefines/TaskData.as");
  const talkSrc = gen("tasknpc/mmo/tasknpc/TaskTalkData.as");
  const overlay = readFileSync(fileURLToPath(new URL("../../../../rebuild/static/www.9aola.com/", import.meta.url)) + "config.xml%3F201301241", "utf8");
  const rooms = new Set([...overlay.matchAll(/<r [^>]*nm="([^"]+)"/g)].map((m) => m[1]));
  const steps = {};
  for (const m of data.matchAll(/"(\d+)": new TaskDefine\(\d+, 0, "([\d,]+)"\)/g)) steps[m[1]] = m[2].split(",");
  const quests = [...data.matchAll(/"(\d+)": new TaskStarter\(/g)].map((m) => m[1]);
  const talks = {};
  for (const m of talkSrc.matchAll(/talk\["(\d+)_(\d+)_([A-Za-z0-9]+)"\]/g)) {
    if (rooms.has(m[3])) (talks[m[2]] ??= []).push({ npc: m[1], scene: m[3] });
  }
  const want = (process.env.QUESTS || "").split(",").filter(Boolean);
  const inWant = (q) =>
    !want.length ||
    want.some((w) => (w.includes("-") ? Number(q) >= Number(w.split("-")[0]) && Number(q) <= Number(w.split("-")[1]) : w === q));
  const per = process.env.STEPS === "all" ? 1e9 : Number(process.env.STEPS || 3);
  const clearAll = async () => {
    for (let i = 0; i < 3 && String(await h.hook("talk")); i++) await closeTalk(h);
    const card = String(await h.hook("where", "cardClose"));
    if (card && card !== "none" && !card.startsWith("error")) {
      const [x, y] = card.split(",").map(Number);
      await h.click(x + 20, y + 16);
      await h.sleep(600);
    }
    await h.revival("clearmodal");
  };

  await h.until(() => h.hook("scene"), "starland", 90);
  await h.sleep(3000);
  if (/指挥中心/.test(String(await h.hook("talk")))) await closeTalk(h);
  await h.revival("addpet", "4");
  await h.sleep(1500);
  const results = [];
  let seen = h.lines.length;
  const newErrors = () => {
    const errs = h.lines.slice(seen).filter((l) => ERRORS.test(l));
    seen = h.lines.length;
    return errs;
  };
  for (const q of quests) {
    if (!inWant(q)) continue;
    for (const s of (steps[q] || []).slice(0, per)) {
      const t = (talks[s] || [])[0];
      if (!t) {
        results.push(`SKIP ${q}/${s}: no conversation in a scene`);
        continue;
      }
      // Whatever the step before left open (a film, a quiz, a game window, the player card).
      await clearAll();
      await h.revival("tasktest", s);
      await h.until(() => h.hook("tasks"), new RegExp(`:${s}\\b`), 15);
      await h.sleep(800);
      await h.revival("goto", t.scene);
      const there = await h.until(() => h.hook("scene"), t.scene, 40);
      await h.until(() => h.hook("busy"), "0", 30);
      await h.sleep(5000);
      // A script may open the step's conversation as the scene comes.
      let said = String(await h.hook("talk"));
      let how = "by itself";
      if (!said || said === "none") {
        for (let i = 0; i < 2 && String(await h.hook("talk")); i++) await closeTalk(h);
        const r = there ? await clickNpc(h, t.npc) : "not in scene";
        said = r === "ok" ? String((await h.until(() => h.hook("talk"), undefined, 8)) || "") : "";
        how = r === "ok" ? `npc ${t.npc}` : `npc ${t.npc} ${r}`;
        if (there && (!said || said === "none")) {
          // The click may have hit the player standing in front (the player card) or missed: ask the NPC itself.
          await clearAll();
          const d = await h.revival("npc", t.npc);
          said = d === "ok" ? String((await h.until(() => h.hook("talk"), undefined, 8)) || "") : "";
          how = `npc ${t.npc} (${d === "ok" ? "by the test hook" : d})`;
        }
      }
      const errs = newErrors();
      const ok = Boolean(said) && said !== "none" && !said.startsWith("error");
      results.push(`${ok ? (errs.length ? "ERR " : "OK  ") : "FAIL"} ${q}/${s} ${t.scene} ${how}: ${ok ? said.slice(0, 60) : await h.hook("top")}${errs.length ? " | " + errs.slice(0, 2).join(" / ").slice(0, 200) : ""}`);
      h.log(results.at(-1));
      // As they come, so a run cut short keeps what it saw (RESULTS=<file>).
      if (process.env.RESULTS) appendFileSync(process.env.RESULTS, results.at(-1) + "\n");
      if (!ok || errs.length) await h.shot(`${q}-${s}-${t.scene}`);
      for (let i = 0; i < 3 && String(await h.hook("talk")); i++) await closeTalk(h);
      if (/taskTransportPanel/.test(String(await h.hook("top")))) await h.click(585, 334);
    }
  }
  h.log(`stepsmoke:\n${results.join("\n")}`);
  const count = (k) => results.filter((r) => r.startsWith(k)).length;
  h.log(`${count("OK")} ok, ${count("ERR")} with script errors, ${count("FAIL")} failed, ${count("SKIP")} skipped of ${results.length}`);
}
