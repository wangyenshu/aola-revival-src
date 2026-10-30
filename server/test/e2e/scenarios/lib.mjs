// Helpers shared by the scenarios.

/**
 * Click an NPC with the mouse, as a player does (the click walks the player
 * over and then opens the conversation), where the scene shows it
 * (Npc names its view npc_<id> and the picture in it npcArt: aimed at the
 * picture, not at a speech bubble that may be gone by then). "ok", or "none"
 * when it is not to be seen.
 */
export async function clickNpc(h, id) {
  // Its picture loads after it is placed: wait until it stands still where it is drawn.
  let at = "none";
  for (let i = 0; i < 15; i++) {
    const now = String(await h.hook("where", `npc_${id}/npcArt`));
    if (now === at && now !== "none" && !now.startsWith("error")) break;
    at = now;
    await h.sleep(800);
  }
  if (!at || at === "none" || at.startsWith("error")) {
    h.log(`npc ${id}: not in the scene`);
    return "none";
  }
  const [x, y] = at.split(",").map(Number);
  await h.click(x + 20, y + 16);
  h.log(`clicked npc ${id} at ${at}`);
  return "ok";
}

/** Close the open NPC conversation with its close button (talkClose), as a player does. */
export async function closeTalk(h) {
  const at = String(await h.hook("where", "talkClose"));
  if (!at || at === "none" || at.startsWith("error")) return false;
  const [x, y] = at.split(",").map(Number);
  await h.click(x + 20, y + 16);
  await h.sleep(600);
  return true;
}
