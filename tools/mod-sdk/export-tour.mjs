// The export's tour (tools/mod-sdk/export.mjs runs it in server/test/e2e/boot2013.mjs): a mod
// played as a game of its own (?standalone=…) is walked through, so that the files its rooms, its
// conversations, a battle and the bag load are seen and kept in the export:
//   - its conversations are answered with their first choice (a difficulty, a "yes");
//   - each room it has defined is shown (the test hook modenter);
//   - a battle against EXPORT_RACE is begun and run from;
//   - the bag, the 物品 panel and the HELLO's menu are opened and closed.
export default async function run(h) {
  const room = () => h.hook("modroom");
  // "<mod> <room>" once the mod shows a room (before that: "none …", "<mod> -", or an error while
  // the game itself is still loading).
  if (!(await h.until(room, /^(?!none |error)\S+ (?!-$)\S+$/, 300))) {
    h.log("export tour: the mod did not show a room");
    return;
  }
  const answer = async (times) => {
    for (let i = 0; i < times; i++) {
      const t = String(await h.hook("talk", "0"));
      if (t === "none" || t === "closed") return;
      await h.sleep(700);
    }
  };
  await h.sleep(4000);
  await answer(25);
  const rooms = String(await h.hook("modrooms")).split(",").filter((r) => r && r !== "none" && !r.startsWith("error"));
  h.log("export tour: rooms " + rooms.join(" "));
  for (const r of rooms) {
    await h.revival("modenter", r);
    await h.until(room, new RegExp(` ${r}$`), 90);
    await h.sleep(7000);
    await answer(10);
  }
  const race = Number(process.env.EXPORT_RACE) || 1;
  const lv = JSON.stringify({ format: "aola-revival-level", version: 1, heal: false, enemies: [{ race, level: 5 }] });
  await h.revival("xt", `SundriesExtension.revival_sandbox lv=${lv} i=0`);
  await h.sleep(15000);
  await h.revival("xt", "PocketMonsterExtension.1405");
  await h.sleep(8000);
  await h.revival("clearmodal");
  for (const panel of ["pet", "items"]) {
    await h.revival(panel, "");
    await h.sleep(5000);
    await h.revival("clearmodal");
  }
  await h.revival("xt", "RobotExtension.2-11");
  await h.sleep(5000);
  h.log("export tour: done");
}
