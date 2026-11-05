// The 家园 and the 百田大剧场, as a player: 回家 leads to the garden; the
// 植树盆 offers the eight trees; plant a 月亮树, give it 雨露 and 养料 (it
// grows a level) and see it in the pot; 我的家 leads into the 小屋 with the
// control bar back; the theatre scene opens its films and one plays (FLV).
// npm run e2e:garden
import { closeTalk } from "./lib.mjs";

async function where(h, name) {
  const at = String(await h.hook("where", name));
  return !at || at === "none" || at.startsWith("error") ? null : at.split(",").map(Number);
}

async function click(h, name) {
  const at = await where(h, name);
  if (!at) throw new Error("not on screen: " + name);
  await h.click(at[0] + 20, at[1] + 16);
}

async function waitFor(h, name, seconds = 15) {
  for (let i = 0; i < seconds * 2; i++) {
    if (await where(h, name)) return;
    await h.sleep(500);
  }
  throw new Error("did not appear: " + name);
}

export default async function (h) {
  await h.until(() => h.hook("scene"), "starland", 90);
  await h.sleep(3000);
  if (String(await h.hook("talk"))) await closeTalk(h);
  await h.hook("home");
  await waitFor(h, "garden_植树盆", 30);
  h.log("in the 家园");
  await h.shot("garden");
  await click(h, "garden_植树盆");
  await waitFor(h, "plantKind5");
  await h.shot("pot-shop");
  await click(h, "plantKind5");
  await h.sleep(500);
  await click(h, "plantBuy");
  await waitFor(h, "plantRain");
  await click(h, "plantRain");
  await h.sleep(1500);
  await click(h, "plantFat");
  await h.sleep(2000);
  await h.shot("pot-care");
  await click(h, "plantClose");
  await waitFor(h, "gardenTree");
  await h.shot("garden-tree");
  await click(h, "garden_我的家");
  await waitFor(h, "btn_home", 30);
  if (await where(h, "garden_植树盆")) throw new Error("still in the garden");
  h.log("in the 小屋");
  await h.shot("house");
  await h.hook("goto", "theatre");
  await waitFor(h, "film_anniversary2", 20);
  await click(h, "film_anniversary2");
  await h.sleep(8000);
  const time = String(await h.hook("text", "theatreTime"));
  const playing = /^(\d+):(\d+)/.exec(time);
  h.log(`theatre: ${time}`);
  await h.shot("theatre");
  if (!playing || Number(playing[1]) * 60 + Number(playing[2]) <= 0) throw new Error("the film does not play");
  await click(h, "theatreClose");
  h.log("garden scenario passed");
}
