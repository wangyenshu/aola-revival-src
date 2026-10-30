// The 家园 and the 百田大剧场, as a player: 回家 leads to the garden; the
// 植树盆 offers the eight trees; plant a 月亮树, give it 雨露 and 养料 (it
// grows a level) and see it in the pot; 我的家 leads into the 小屋 with the
// control bar back; the theatre scene opens the films over the game and one
// plays. npm run e2e:garden
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
  for (let i = 0; i < 40 && !(await h.page.evaluate(() => !!document.getElementById("aolaTheatre"))); i++) await h.sleep(500);
  if (!(await h.page.evaluate(() => !!document.getElementById("aolaTheatre")))) throw new Error("the theatre did not open its films");
  await h.page.evaluate(() => document.querySelector("#aolaTheatre .film")?.click());
  await h.sleep(6000);
  const playing = await h.page.evaluate(() => {
    const v = document.querySelector("#aolaTheatre video");
    return v ? v.currentTime : -1;
  });
  h.log(`theatre: the film at ${playing.toFixed(1)} s`);
  await h.shot("theatre");
  if (!(playing > 0)) throw new Error("the film does not play");
  await h.page.evaluate(() => window.clearDiv());
  h.log("garden scenario passed");
}
