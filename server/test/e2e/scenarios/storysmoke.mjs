// A quick look at every 2012 story quest that starts by talking to an NPC:
// with the quests before it finished (dev command tasktest), go to the scene,
// talk to the NPC and see that its start conversation opens.
//
//   node server/test/e2e/boot2013.mjs --out work/e2e-storysmoke --seconds 1500 --query dev=1 \
//     --actions "38:500,520;46:500,520" --scenario server/test/e2e/scenarios/storysmoke.mjs
//
// The list is the start conversations (npc_task_scene) of tools/gen_tasks.py.

import { readFileSync } from "node:fs";

export default async function smoke(h) {
  const src = readFileSync(new URL("../../../../rebuild/gen/tasknpc/mmo/tasknpc/TaskTalkData.as", import.meta.url), "utf8");
  // In task order: tasktest finishes the quests before, and those come first.
  const starts = [...src.matchAll(/starts\["(\d+)_(\d+)_([a-z0-9]+)"\]/g)]
    .map((m) => ({ npc: m[1], task: m[2], scene: m[3] }))
    .sort((a, b) => a.task - b.task);
  const only = process.env.SMOKE_ONLY ? process.env.SMOKE_ONLY.split(",") : null;
  const results = [];
  await h.until(() => h.hook("scene"), "starland", 90);
  await h.sleep(3000);
  if (/指挥中心/.test(String(await h.hook("talk")))) await h.click(822, 402);
  for (const s of starts) {
    if (only && !only.includes(s.task)) continue;
    await h.revival("tasktest", s.task);
    await h.sleep(1500);
    await h.revival("goto", s.scene);
    const there = await h.until(() => h.hook("scene"), s.scene, 40);
    await h.until(() => h.hook("busy"), "0", 30);
    await h.sleep(4000);
    // Whatever the scene opened by itself first.
    for (let i = 0; i < 3 && String(await h.hook("talk")); i++) {
      await h.click(822, 402);
      await h.sleep(800);
    }
    const r = there ? await h.revival("npc", s.npc) : "not in scene";
    const t = r === "ok" ? await h.until(() => h.hook("talk"), undefined, 15) : false;
    const ok = Boolean(t);
    results.push(`${ok ? "OK  " : "FAIL"} ${s.task} ${s.scene} npc ${s.npc}: ${t || r}`);
    h.log(results.at(-1));
    await h.shot(`${s.task}-${s.scene}`);
    if (t) await h.click(822, 402);
    await h.sleep(1000);
    // Close a transport panel or anything else left open.
    if (/taskTransportPanel/.test(String(await h.hook("top")))) await h.click(585, 334);
  }
  h.log(`smoke:\n${results.join("\n")}`);
  const fails = results.filter((r) => r.startsWith("FAIL")).length;
  h.log(`${results.length - fails} of ${results.length} start conversations open`);
}
