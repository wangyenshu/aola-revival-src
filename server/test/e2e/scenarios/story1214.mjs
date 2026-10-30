// The first two 2012 story quests of 巨人山脉, 1214 传说中的美丽山脉 and 1219
// 奇怪的山脉, played through with their original scripts (taskext/task1214 and
// task1219, March 2012):
//
//   npm run e2e:story    (screenshots in work/e2e-story/)
//
// The newbie quest is skipped with the dev command tasktest (and the first
// 亚比 given with addPM); the mini game of step 1218 is played with the Space
// key, the things to find in 小熊之家 are clicked where the scene has them, the
// ladder of 1225 is put together by dragging. STORY_FROM=<step> starts later
// (e.g. STORY_FROM=1221 in 小熊之家).

export default async function story(h) {
  const FROM = Number(process.env.STORY_FROM || 0);
  const talk = () => h.hook("talk");
  const replies = (cmd) => h.count(new RegExp(`xt reply ${cmd}$`));
  /** The things each step of 1219 has you click in the scene, by their names in the scene SWF. */
  const CLICKS = { 1222: ["mc_paper"], 1223: ["mc_stone", "mc_light"], 1224: ["mc_wood", "mc_saw", "mc_nail"], 1225: ["mc_paper"] };
  /** Page position of a stage position (the game sits at 20,16 on the test page). */
  const page = (xy) => xy.split(",").map(Number).map((v, i) => v + (i ? 16 : 20));
  const say = async (re, name, seconds = 40) => {
    const t = await h.until(talk, re, seconds);
    h.log(`talk ${name}: ${t}`);
    if (!t) {
      await h.shot(`${name}-missing`);
      throw new Error(`no conversation ${name} (${re})`);
    }
    await h.sleep(500);
    await h.shot(name);
    return t;
  };
  /** Go on through a conversation: the first choice each time, until it closes. */
  const through = async (pick = 0) => {
    for (let i = 0; i < 25; i++) {
      await h.sleep(700);
      const r = await h.revival("talk", String(pick));
      if (r === "closed" || r === "none") return;
    }
  };
  const scene = async (want, seconds = 60) => {
    const s = await h.until(() => h.hook("scene"), want, seconds);
    await h.until(() => h.hook("busy"), "0", 30);
    await h.sleep(2500);
    h.log(`scene ${s || "not " + want}`);
    if (!s) throw new Error("not in " + want + " but " + (await h.hook("scene")));
    return s;
  };
  const step = async (n, seconds = 30) => {
    const r = await h.until(() => h.hook("tasks"), new RegExp(`:${n}\\b`), seconds);
    h.log(`step ${n}: ${r || "not reached; " + (await h.hook("tasks"))}`);
    return r;
  };
  /** The task transport panel: 立即前往. */
  const transport = async (name) => {
    const on = await h.until(() => h.hook("top"), /taskTransportPanel/, 20);
    await h.sleep(800);
    await h.shot(`go-${name}`);
    if (!on) throw new Error("no transport panel for " + name);
    await h.click(415, 334);
  };

  await h.until(() => h.hook("scene"), "starland", 90);
  await h.sleep(3000);
  // A new player is greeted by the HELLO (the newbie quest's first call): close it.
  if (/指挥中心/.test(String(await talk()))) await h.click(822, 402);
  await h.revival("addpet", "4");
  await h.sleep(1500);
  await h.revival("tasktest", String(FROM || 1214));
  await h.sleep(2000);
  h.log(`tasks: ${await h.hook("tasks")}`);
  if (FROM >= 1220) {
    await h.revival("goto", "giantcordillera2");
    await scene("giantcordillera2");
    return await part1219();
  }
  // The task panel lists it under 可接.
  await h.click(955, 48);
  await h.sleep(3000);
  await h.shot("taskpanel");
  await h.click(885, 70);

  await h.revival("goto", "giantcordillera1");
  await scene("giantcordillera1");
  await h.shot("giantcordillera1");
  await h.revival("npc", "608");
  await say(/黑色的云团/, "1214-start");
  await through();
  await step(1215);
  await transport("maintown2");
  await scene("maintown2");
  await say(/巨大的人形山脉/, "1215");
  await through();
  await step(1216);
  await transport("library");
  await scene("library");
  await h.revival("npc", "43");
  await say(/小南|巨人山脉/, "1216");
  await through();
  await step(1217);
  await transport("helloschool");
  await scene("helloschool");
  await h.revival("npc", "14");
  await say(/./, "1217");
  await through();
  await step(1218);
  await transport("giantcordillera1");
  await scene("giantcordillera1");
  await say(/./, "1218");
  await through();
  await h.sleep(8000);
  await h.shot("1218-movie");
  await say(/./, "1218-2", 60);
  await through();
  await h.sleep(4000);
  await h.shot("1218-game");
  // The mini game (Task1218_2): 确定, then Space as fast as you can to pump up the HELLO.
  await h.click(522, 368);
  await h.sleep(500);
  for (let i = 0; i < 30; i++) {
    await h.page.keyboard.press("Space");
    await h.sleep(120);
    if (i === 10) await h.shot("1218-pumping");
  }
  await h.sleep(3000);
  h.log(`mini game: ${/action 1214_1218_gamewin/.test(h.lines.join("\n")) ? "won" : "not won"}`);
  await h.sleep(9000);
  await h.shot("1218-won");
  await scene("giantcordillera2", 90);
  await h.shot("giantcordillera2");
  await part1219();

  /** 1219 奇怪的山脉, which begins by itself in 小熊之家. */
  async function part1219() {
    await follow(1226, 300);
    // 1226: 伊尼 (284) will not talk until you have beaten his 亚比 (371).
    const started = replies("2401");
    const ended = replies("2403");
    // (Started at 1226, nothing has made 伊尼 speak yet: talk to him.)
    const talkTo = FROM === 1226 ? go({ giantcordillera2: "284" }) : async () => {};
    await follow(1227, 240, async () => {
      if (replies("2401") > started && replies("2403") === ended) await battle(ended);
      else await talkTo();
    });
    // 1227: out through the gap the arrow shows, down to 巨人山脚, where 伊尼 waits.
    await follow(1228, 180, go({ giantcordillera2: [775, 191] }));
    // 1228: back up to 小熊之家 (the arrow at 865,220) and talk to 伊尼 there.
    await follow(1229, 240, go({ giantcordillera1: [885, 236], giantcordillera2: "284" }));
    // 1229: 伊尼's plan, the film, and 1219's reward.
    await follow((tasks) => !/1219/.test(tasks), 240, go({ giantcordillera2: "284" }));
    await h.sleep(8000);
    await h.shot("1219-done");
    h.log(`tasks at the end: ${await h.hook("tasks")}`);
  }

  /**
   * Each round, in the scenes named: click a stage point [x, y] (at most every
   * 10 s), or an NPC by id (once: talking to it again starts its conversation over).
   */
  function go(where) {
    let last = 0;
    let talked = false;
    return async () => {
      if (Date.now() - last < 10000 || (await h.hook("busy")) !== "0") return;
      const sc = String(await h.hook("scene"));
      const what = where[sc];
      if (what === undefined) return;
      last = Date.now();
      if (Array.isArray(what)) {
        h.log(`go: click ${what} in ${sc}`);
        await h.click(what[0] + 20, what[1] + 16);
      } else if (!talked) talked = (await h.revival("npc", what)) === "ok";
    };
  }

  /**
   * Play on until step `until` is being done (or `seconds` pass): answer every
   * conversation (first choice), close notices, click what the step has you
   * find, put the ladder together; `extra` runs each round.
   */
  async function follow(until, seconds, extra) {
    const reached = typeof until === "function" ? until : (tasks, now) => now >= until;
    const end = Date.now() + seconds * 1000;
    const clicked = {};
    let last = "";
    while (Date.now() < end) {
      const tasks = String(await h.hook("tasks"));
      const m = tasks.match(/1219:(\d+)/);
      const now = m ? Number(m[1]) : 0;
      if (tasks !== last) {
        h.log(`steps: ${tasks}`);
        await h.shot(`step${now || "-"}`);
        last = tasks;
      }
      if (reached(tasks, now)) return true;
      const t = String(await talk());
      if (t && t !== "none" && !t.startsWith("error")) {
        h.log(`talk: ${t}`);
        await through();
        continue;
      }
      // A notice (NewDialog: 知道了 / 确定 is btnOK or btnOk).
      const ok = [await h.hook("where", "btnOK"), await h.hook("where", "btnOk")].find((v) => v && v !== "none" && !String(v).startsWith("error"));
      if (ok) {
        await h.shot("dialog");
        h.log(`dialog: ok at ${ok}`);
        const [x, y] = page(String(ok));
        await h.click(x, y);
        await h.sleep(1200);
        continue;
      }
      if ((await h.hook("where", "mc_material0")) !== "none") {
        await ladder();
        continue;
      }
      if (extra) await extra();
      // The one clicked longest ago first, so that each gets its turn.
      for (const name of [...(CLICKS[now] ?? [])].sort((a, b) => (clicked[a] ?? 0) - (clicked[b] ?? 0))) {
        if (clicked[name] && Date.now() - clicked[name] < 8000) continue;
        const at = await h.hook("where", name);
        if (at === "none" || String(at).startsWith("error")) {
          if (!clicked[name + "?"]) h.log(`no ${name} to click: ${await h.hook("bounds", name)}`);
          clicked[name + "?"] = 1;
          continue;
        }
        clicked[name] = Date.now();
        h.log(`click ${name} at ${at}`);
        const [x, y] = page(String(at));
        await h.click(x, y);
        await h.sleep(2500);
        break;
      }
      await h.sleep(1500);
    }
    h.log(`step ${until} not reached: ${await h.hook("tasks")}`);
    await h.shot(`no-${typeof until === "function" ? "end" : until}`);
    throw new Error(`step ${until} not reached`);
  }

  /** BuildLadder (1225): drag each piece mc_material<i> onto its place mc_materialok<i>. */
  async function ladder() {
    await h.shot("ladder");
    for (let i = 0; i < 5; i++) {
      const from = await h.hook("where", `mc_material${i}`);
      const to = await h.hook("origin", `mc_materialok${i}`);
      if (from === "none" || to === "none") continue;
      const [fx, fy] = page(String(from));
      const [tx, ty] = page(String(to));
      await h.page.mouse.move(fx, fy);
      await h.page.mouse.down();
      for (let k = 1; k <= 10; k++) {
        await h.page.mouse.move(fx + ((tx - fx) * k) / 10, fy + ((ty - fy) * k) / 10);
        await h.sleep(40);
      }
      await h.page.mouse.up();
      await h.sleep(600);
      h.log(`ladder piece ${i}: ${from} -> ${to}`);
    }
    await h.shot("ladder-done");
    await h.sleep(4000);
  }

  /** A battle: attack with the first skill until it ends (2403), then close the result. */
  async function battle(ended) {
    await h.sleep(6000);
    await h.shot("battle");
    for (let n = 0; replies("2403") === ended && n < 30; n++) {
      await h.click(907, 175);
      await h.sleep(5000);
    }
    await h.sleep(2500);
    await h.shot("battle-end");
    h.log(`battle: ${replies("2403") > ended ? "over" : "still on"}`);
    for (const [x, y] of [
      [500, 411],
      [500, 343],
      [500, 280],
    ]) {
      await h.click(x, y);
      await h.sleep(1500);
    }
  }
}
