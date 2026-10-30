// Scene music and the control bar's music switch, heard through the audio
// probe (server/test/e2e/audio-probe.js taps what reaches the speakers):
//
//   npm run e2e:music
//
// 奥拉广场, 道具店 and 巨人山脚 each play their own track (config.xml mu);
// the switch stops the music and starts it again.

import { closeTalk } from "./lib.mjs";

export default async function music(h) {
  const loud = async () => {
    const taps = await h.page.evaluate(() => (window.__audio ? window.__audio() : []));
    return Math.max(0, ...taps.map((t) => t.rms));
  };
  /** The loudest of a few samples over three seconds. */
  const listen = async (name) => {
    let max = 0;
    for (let i = 0; i < 4; i++) {
      max = Math.max(max, await loud());
      await h.sleep(800);
    }
    const track = [...h.lines].reverse().find((l) => l.includes("[rebuilt] music:"));
    h.log(`${name}: loudness ${max.toFixed(3)}; ${track ? track.replace(/.*music: /, "") : "no track"}`);
    return max;
  };
  const fail = [];
  await h.until(() => h.hook("scene"), "starland", 90);
  await h.sleep(5000);
  if (String(await h.hook("talk"))) await closeTalk(h);
  for (const sc of ["starland", "toolshop", "giantcordillera1"]) {
    if (sc !== "starland") {
      await h.revival("goto", sc);
      await h.until(() => h.hook("scene"), sc, 40);
      await h.sleep(6000);
    }
    if ((await listen(sc)) < 0.01) fail.push(`${sc} is silent`);
  }
  await h.click(904 + 20, 547 + 16);
  await h.sleep(3000);
  if ((await listen("switched off")) > 0.001) fail.push("the switch did not stop the music");
  await h.click(904 + 20, 547 + 16);
  await h.sleep(5000);
  if ((await listen("switched on")) < 0.01) fail.push("the switch did not start the music again");
  if (fail.length) throw new Error(fail.join("; "));
}
