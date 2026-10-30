// Play 2012 story quests through as far as a player who always takes the
// first answer gets: start each quest at its NPC, go through every
// conversation, follow the 任务传送 panel, click on through films and comics
// (btnNext / btnClose), press the skill button in fights, and, when a step
// does not come by itself, go to the scene of the step's conversation and
// click its NPC. A step that has not moved on after STUCK seconds (a mini
// game, something to find in the scene) is noted and skipped with the dev
// command tasktest, so the rest of the quest is still seen.
//
//   QUESTS=1742,1750,1764 node server/test/e2e/boot2013.mjs --out work/e2e-play --seconds 3600 \
//     --query dev=1 --scenario server/test/e2e/scenarios/storyplay.mjs
//
// The report at the end: per step, how it was done (talk, script, fight,
// skipped) and the script errors seen.

import { clickNpc, closeTalk } from "./lib.mjs";
import { appendFileSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const gen = (p) => readFileSync(new URL(`../../../../rebuild/gen/${p}`, import.meta.url), "utf8");
const ERRORS = /Error #\d+|ReferenceError|TypeError|VerifyError|taskext .*(error|cannot load)/;
const BUTTONS = ["cardClose", "btnNext", "btnnext", "btnClose", "btnclose", "btnOK", "btnOk", "btn_ok", "btnok", "closeBtn", "btnSure", "btnsure"];

export default async function storyplay(h) {
  const data = gen("taskdata/mmo/taskdefines/TaskData.as");
  const talkSrc = gen("tasknpc/mmo/tasknpc/TaskTalkData.as");
  const overlay = readFileSync(fileURLToPath(new URL("../../../../rebuild/static/www.9aola.com/", import.meta.url)) + "config.xml%3F201301241", "utf8");
  const rooms = new Set([...overlay.matchAll(/<r [^>]*nm="([^"]+)"/g)].map((m) => m[1]));
  const steps = {};
  for (const m of data.matchAll(/"(\d+)": new TaskDefine\(\d+, 0, "([\d,]+)"\)/g)) steps[m[1]] = m[2].split(",").map(Number);
  const autoStart = new Set([...data.matchAll(/"(\d+)": new TaskStarter\(\d+, 12,/g)].map((m) => m[1]));
  const talks = {};
  const starts = {};
  for (const m of talkSrc.matchAll(/(talk|starts)\["(\d+)_(\d+)_([A-Za-z0-9]+)"\]/g)) {
    if (!rooms.has(m[4])) continue;
    ((m[1] === "talk" ? talks : starts)[m[3]] ??= []).push({ npc: m[2], scene: m[4] });
  }
  const quests = (process.env.QUESTS || "1742").split(",");
  const STUCK = Number(process.env.STUCK || 45) * 1000;
  const page = (xy) => String(xy).split(",").map(Number).map((v, i) => v + (i ? 16 : 20));
  const found = (v) => v && v !== "none" && !String(v).startsWith("error");
  const replies = (cmd) => h.count(new RegExp(`xt reply ${cmd}$`));
  const report = [];
  let seen = h.lines.length;
  const errors = () => {
    const e = h.lines.slice(seen).filter((l) => ERRORS.test(l));
    seen = h.lines.length;
    return e;
  };
  const stepOf = async (q) => {
    const m = String(await h.hook("tasks")).match(new RegExp(`\\b${q}:(-?\\d+)`));
    return m ? Number(m[1]) : 0;
  };
  const doing = async (q) => String(await h.hook("tasks")).split(" steps ")[0].split(",").includes(String(q));
  const through = async () => {
    for (let i = 0; i < 30; i++) {
      await h.sleep(600);
      const r = await h.revival("talk", "0");
      if (r === "closed" || r === "none") return;
    }
  };
  const settle = async () => {
    await h.until(() => h.hook("busy"), "0", 40);
    await h.sleep(2500);
  };
  /** One look round: true when something was done. */
  const act = async (q, s, tried) => {
    const t = String(await h.hook("talk"));
    if (found(t) && t !== "") {
      h.log(`talk: ${t.slice(0, 80)}`);
      await through();
      return "talk";
    }
    const top = String(await h.hook("top"));
    if (/taskTransportPanel/.test(top)) {
      await h.sleep(600);
      await h.click(415, 334);
      await settle();
      return "transport";
    }
    if (replies("2401") > replies("2403")) {
      await h.sleep(3000);
      for (let n = 0; replies("2401") > replies("2403") && n < 40; n++) {
        await h.click(907, 175);
        await h.sleep(4000);
      }
      await h.sleep(2500);
      for (const [x, y] of [[500, 411], [500, 343], [500, 280]]) {
        await h.click(x, y);
        await h.sleep(1200);
      }
      return "fight";
    }
    for (const b of BUTTONS) {
      const at = await h.hook("where", b);
      if (found(at)) {
        const [x, y] = page(at);
        await h.click(x, y);
        await h.sleep(1500);
        return "button " + b;
      }
    }
    // Go where the step's conversation is.
    const want = (talks[s] || [])[0];
    if (want && !tried.has(`${s}:${want.scene}:${want.npc}`)) {
      const here = String(await h.hook("scene"));
      if (here !== want.scene) {
        await h.revival("goto", want.scene);
        await h.until(() => h.hook("scene"), want.scene, 40);
        await settle();
        return "goto " + want.scene;
      }
      tried.add(`${s}:${want.scene}:${want.npc}`);
      const r = await clickNpc(h, want.npc);
      await h.sleep(2500);
      if (found(await h.hook("talk")) && String(await h.hook("talk"))) return "npc " + want.npc;
      // The click hit the player in front, or the NPC is hidden behind scene art: ask the NPC itself.
      const card = await h.hook("where", "cardClose");
      if (found(card)) {
        const [x, y] = page(card);
        await h.click(x, y);
        await h.sleep(600);
      }
      const d = await h.revival("npc", want.npc);
      await h.sleep(2000);
      return d === "ok" ? "npc " + want.npc + " (test hook)" : r === "ok" ? "npc " + want.npc : "";
    }
    return "";
  };

  await h.until(() => h.hook("scene"), "starland", 90);
  await h.sleep(3000);
  if (/指挥中心/.test(String(await h.hook("talk")))) await closeTalk(h);
  await h.revival("addpet", "4");
  await h.sleep(1500);
  await h.revival("tasktest", quests[0]);
  await h.sleep(2000);
  for (const q of quests) {
    // Start it.
    if (!(await doing(q))) {
      const st = (starts[q] || [])[0];
      if (st) {
        await h.revival("goto", st.scene);
        await h.until(() => h.hook("scene"), st.scene, 40);
        await settle();
        for (let i = 0; i < 3 && found(await h.hook("talk")) && String(await h.hook("talk")); i++) await through();
        if (!(await doing(q))) {
          await clickNpc(h, st.npc);
          await h.sleep(2500);
          await through();
        }
      }
      if (!(await h.until(() => doing(q), true, autoStart.has(q) ? 30 : 15))) {
        report.push(`${q}: did not start (${st ? `start talk ${st.npc} in ${st.scene}` : "no start talk"}); tasktest to its first step`);
        await h.revival("tasktest", String(steps[q][0]));
        await h.sleep(2000);
      }
    }
    let s = await stepOf(q);
    let since = Date.now();
    let how = [];
    const tried = new Set();
    h.log(`quest ${q} at ${s}`);
    for (let guard = 0; guard < 400; guard++) {
      if (!(await doing(q))) {
        report.push(`${q}/${s}: ${how.join(", ") || "-"}${errs()}`);
        report.push(`${q}: finished`);
        break;
      }
      const now = await stepOf(q);
      if (now !== s) {
        report.push(`${q}/${s}: ${how.join(", ") || "by itself"}${errs()}`);
        h.log(report.at(-1));
        if (process.env.RESULTS) appendFileSync(process.env.RESULTS, report.at(-1) + "\n");
        await h.shot(`${q}-${now}`);
        s = now;
        since = Date.now();
        how = [];
        continue;
      }
      const did = await act(q, s, tried);
      if (did) {
        if (!how.includes(did.split(" ")[0])) how.push(did.split(" ")[0]);
        if (!did.startsWith("goto")) since = Date.now() - STUCK / 2;
        continue;
      }
      if (Date.now() - since > STUCK) {
        const next = steps[q][steps[q].indexOf(s) + 1];
        await h.shot(`${q}-${s}-stuck`);
        report.push(`${q}/${s}: STUCK (${how.join(", ") || "nothing to do"}; on top ${String(await h.hook("top")).slice(0, 80)})${errs()}`);
        h.log(report.at(-1));
        for (let i = 0; i < 3 && String(await h.hook("talk")); i++) await closeTalk(h);
        await h.revival("clearmodal");
        if (next) {
          await h.revival("tasktest", String(next));
        } else {
          await h.revival("tasktest", String(quests[quests.indexOf(q) + 1] || q));
        }
        await h.sleep(2500);
        await h.revival("goto", "starland");
        await settle();
        s = await stepOf(q);
        since = Date.now();
        how = [];
        if (!next) break;
        continue;
      }
      await h.sleep(1500);
    }
  }
  function errs() {
    const e = errors();
    return e.length ? ` | ${e.length} errors: ${e.slice(0, 2).join(" / ").slice(0, 240)}` : "";
  }
  h.log(`storyplay:\n${report.join("\n")}`);
  const stuck = report.filter((r) => r.includes("STUCK")).length;
  h.log(`${report.filter((r) => r.endsWith("finished")).length} of ${quests.length} quests finished; ${stuck} steps skipped`);
}
