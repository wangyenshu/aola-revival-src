// The newbie quest of winter 2012/13 (tasks 135, 140, 150) played through
// with the test hooks of the rebuilt control:
//
//   node test/e2e/boot2013.mjs --mirror … --out … --seconds 1200 --query dev=1 \
//     --actions "38:500,520;46:500,520" --scenario test/e2e/scenarios/newbie.mjs
//
// Each step waits for what the game shows (an NPC's words, a scene, a
// battle reply) instead of a fixed time, and leaves a screenshot.
// NEWBIE_FROM=143 (or 145, 146 …) plays 136–137 for the first 亚比, then
// jumps there with the dev command tasktest.

import { clickNpc } from "./lib.mjs";

export default async function newbie(h) {
  const talk = () => h.hook("talk");
  const say = async (re, picks, name, seconds = 60) => {
    const t = await h.until(talk, re, seconds);
    h.log(`talk ${name}: ${t}`);
    if (!t) {
      await h.shot(`${name}-missing`);
      throw new Error(`no conversation ${name} (${re})`);
    }
    await h.sleep(500);
    await h.shot(name);
    for (const p of picks) {
      await h.sleep(800);
      await h.revival("talk", String(p));
    }
  };
  const scene = async (want, seconds = 60) => {
    const s = await h.until(() => h.hook("scene"), want, seconds);
    await h.until(() => h.hook("busy"), "0", 30);
    await h.sleep(1500);
    h.log(`scene ${s || "not " + want}`);
    return s;
  };
  const goto = async (name, landsIn = name) => {
    await h.revival("goto", name);
    return scene(landsIn);
  };
  const comic = async (name, skip = true) => {
    const on = await h.until(() => h.hook("top"), /revivalComic/, 40);
    if (!on) return h.log(`comic ${name}: not shown`);
    await h.sleep(2500);
    await h.shot(`comic-${name}`);
    if (skip) await h.click(925, 546);
    await h.until(async () => !/revivalComic/.test(await h.hook("top")), undefined, skip ? 15 : 90);
    h.log(`comic ${name}: done`);
  };
  const step = async (n, seconds = 30) => {
    const r = await h.until(() => h.hook("tasks"), new RegExp(`:${n}\\b`), seconds);
    h.log(`step ${n}: ${r || "not reached; " + (await h.hook("tasks"))}`);
    return r;
  };
  const replies = (cmd) => h.count(new RegExp(`xt reply ${cmd}$`));
  /** Fight until the battle reply 2403 comes: attack with the first skill, or throw balls. */
  const fight = async (name, mode = "attack", seconds = 150) => {
    const started = replies("2401");
    const ended = replies("2403");
    if (!(await h.until(async () => replies("2401") > started, undefined, 40))) throw new Error(`battle ${name} did not start`);
    await h.sleep(6000);
    await h.shot(`fight-${name}`);
    const end = Date.now() + seconds * 1000;
    let n = 0;
    while (replies("2403") === ended && Date.now() < end) {
      if (mode === "catch" && n > 0) {
        // 捕捉, once the wheel takes commands (the balls show), then the first ball.
        let ball = "none";
        for (let k = 0; k < 6 && ball === "none"; k++) {
          await h.click(956, 41);
          await h.sleep(1200);
          ball = String(await h.hook("where", "fightSlot0"));
        }
        if (ball !== "none" && !ball.startsWith("error")) {
          const [x, y] = ball.split(",").map(Number);
          await h.click(x + 20, y + 16);
        }
      } else await h.click(907, 175);
      n++;
      await h.sleep(5000);
      if (n === 2) await h.shot(`fight-${name}-2`);
    }
    await h.sleep(2500);
    await h.shot(`fight-${name}-end`);
    h.log(`battle ${name}: ${replies("2403") > ended ? "over" : "still on"} after ${n} moves`);
    // 知道了 (a caught 亚比), then the result panel.
    for (const [x, y] of [
      [500, 411],
      [500, 343],
      [500, 280],
    ]) {
      await h.sleep(1500);
      await h.click(x, y);
    }
  };

  // 136: the HELLO sends the new player to the 指挥中心; 麦哲伦 tells of the attack.
  await say(/指挥中心/, [0], "136go", 120);
  await scene("maintown2");
  await say(/终于来了/, [0], "136");
  // 137: the first 亚比.
  await say(/初始亚比/, [0], "137");
  await h.sleep(2500);
  await h.shot("137-starters");
  await h.click(500, 316);
  await h.sleep(800);
  await h.click(500, 509);
  await step(138);
  const from = Number(process.env.NEWBIE_FROM || 0);
  if (from) {
    await h.sleep(2000);
    await h.revival("tasktest", String(from));
    await step(from);
    return later(from);
  }
  // 138: the 机械废墟 and the fight with 达达.
  await say(/机械废墟/, [0], "138");
  await scene("junglecopy");
  await say(/达斯特的士兵/, [0], "138fight");
  for (let tries = 0; tries < 3; tries++) {
    await fight("dada");
    const next = await h.until(
      async () => ((await h.hook("top")).includes("revivalComic") ? "comic" : /再试一次/.test(await talk()) ? "again" : ""),
      undefined,
      40,
    );
    h.log(`after the fight: ${next}`);
    if (next !== "again") break;
    await say(/再试一次/, [0], "138again");
  }
  await comic("groupfight");
  // 139: back to 麦哲伦; the story of the 奥拉之辉, then off to 贝鲁特.
  await step(139);
  await say(/回指挥中心向司令官/, [0], "139go");
  await scene("maintown2");
  await say(/奥拉之辉已经破碎/, [0], "139");
  await comic("openbook");
  await comic("heroinfo");
  await comic("haluda");
  await say(/奥拉之辉已经破碎/, [1], "139again");
  await say(/学好各方面的知识/, [0], "139b");
  await say(/贝鲁特是研究亚比的高手/, [0], "139c");
  await scene("sciencecopy");
  await step(142);
  return later(142);

  async function later(from) {
    if (from <= 142) {
      // The task icon and panel.
      await h.click(955, 48);
      await h.sleep(2500);
      await h.shot("taskpanel");
      await h.click(885, 70); // its ✕
      // 142: 贝鲁特 in the 亚比研究中心.
      await goto("yabistudycopy", "yabistudy");
      await say(/欢迎来到亚比研究中心/, [0, 0, 0], "142");
      await scene("starlandcopy");
    }
    if (from <= 143) {
      // 143: five 亚比球 from 米娜.
      await goto("toolshopcopy");
      await clickNpc(h, "301");
      await say(/买亚比球就来找我/, [0], "143");
      await h.sleep(3000);
      await h.shot("143-buy");
      await h.click(434, 365); // 购买
      await h.sleep(2500);
      await h.shot("143-bought");
      if (process.env.NEWBIE_DEBUG) {
        await h.revival("top");
        h.log(await h.hook("layers", "2"));
      }
      await h.click(500, 329); // 确定 under 购买成功
      if (!(await h.until(talk, /亚比球收好啦/, 8))) {
        h.log("143: no buying panel answer; the dev server gives the balls");
        await h.click(564, 365); // 取消
        await h.revival("give", "32");
        await h.sleep(1500);
        await clickNpc(h, "301");
        await say(/买亚比球就来找我/, [0], "143retry");
      }
      await say(/亚比球收好啦/, [0], "143done");
      await scene("sciencecopy");
      // 144: catching, taught by 贝鲁特.
      await goto("yabistudycopy", "yabistudy");
      await say(/亚比球都买回来/, [0, 0, 0], "144");
    }
    if (from <= 145) {
      if (from === 145) {
        await h.revival("give", "32");
        await goto("yabistudycopy", "yabistudy");
      }
      // 145: catch a 朵朵兔 at the 冰河瀑布.
      await say(/冰河瀑布/, [0], "145");
      await scene("aixiscene2");
      await say(/朵朵兔很容易捕捉/, [0], "145hint");
      await h.sleep(3000);
      await h.shot("145-arrow");
      await h.sleep(6000);
      await h.shot("145-arrow-later");
      h.log(`wild 亚比: ${await h.hook("wild")}`);
      for (let tries = 0; tries < 4 && !(await h.hook("tasks")).includes("140:146"); tries++) {
        const wild = await h.until(() => h.hook("wild"), /:10@/, 30);
        const m = String(wild).match(/wildpet(\d+):10@/);
        if (!m) throw new Error("no 朵朵兔 in aixiscene2: " + wild);
        await h.revival("clickwild", m[1]);
        try {
          await fight("duoduotu", "catch");
        } catch (err) {
          h.log(`145: ${err.message}; another try`);
        }
        await h.sleep(3000);
      }
      await step(146);
      // 146: 普伦博士 gives the HELLO.
      await say(/普伦博士想要教给你/, [0], "146go");
      await scene("sciencecopy");
    }
    if (from <= 147) {
      await goto("helloschoolcopy");
      await say(/我是HELLO学院的院长/, [0, 0, 0], "146");
      // 147: what the HELLO can do; back to 麦哲伦.
      await say(/分配给亚比/, [0], "147");
      await comic("hellouse");
      await say(/快去指挥中心向司令官麦哲伦报告/, [0], "147done");
      await scene("maintown2");
    }
    if (from === 152) await goto("maintown2");
    // 152: the ceremony.
    await step(152);
    await say(/你回来了/, [0], "152");
    await comic("reword");
    await say(/小勇士/, [], "152end");
    await h.revival("talk", "0");
    await h.sleep(3000);
    await h.shot("end");
    h.log(`tasks at the end: ${await h.hook("tasks")}`);
  }
}
