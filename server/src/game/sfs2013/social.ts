// 好友 and 组队 for a shared server (the one-player page answers them too: its only 奥拉 has
// nobody to meet). The 2013 client's own modules for them are lost or later copies that do not
// run on its libraries (buddylist 2025, team 2016); the rebuilt panels (control: FriendPanel,
// TeamPanel) speak these RECONSTRUCTED commands, under the extensions the 2013 client numbers.
//
// BuddyManagerExtension
//   revival_friends {}              -> {list: [{id, name, online, room}], asks: [{id, name}]}
//   revival_friend_add {name}       -> {res, msg}; the other, if in the game: revival_friend_ask {id, name}
//   revival_friend_answer {id, ok}  -> {res, msg}; both friends then (ok); the asker: revival_friend_added
//   revival_friend_del {id}         -> {res}
//   revival_where {name}            -> {name, online, room}   where a friend or teammate is (找他); others: not on
// TeamExtension (组队: up to TEAM_MAX, in memory: a team ends with its last member's game)
//   revival_team {}                 -> {team}                  team: {leader, members: [name]} or null
//   revival_team_make {}            -> {team}
//   revival_team_invite {name}      -> {res, msg}; the other: revival_team_ask {leader}
//   revival_team_join {leader}      -> {team} to every member (revival_team); only with that leader's invitation
//   revival_team_leave {}           -> {team: null}; the others: revival_team; a leader's going passes it on
//   revival_team_go {room}          the leader went to a room: the members get revival_team_go {room, leader}
//                                   (not into a 副本's or 时空隧道's room, "<room>@<name>": those are played alone)
//   revival_team_say {text}         -> every member: revival_team_said {name, text}
//   revival_team_mod {mod, ver, event, data}  a mod's event (IModGame.sendTeam): the other members
//                                   get revival_team_mod {from, mod, ver, event, data}
//
// In a team, the rooms of a mod are the team's (ModRun.teamRoom: "sandboxroom|leader|mod|version|room"),
// so revival_team_go takes the members into the leader's mod room when they run the same mod.
//
// Friends are kept by player id (rename-proof: user ids stay, names may change); the id ->
// name index is "uid/<id>", written at each login.

import type { Session } from "../../core/emulator.ts";
import type { World, XtContext } from "./server.ts";

export const TEAM_MAX = 3;
/** A team's invitation holds this long. */
export const INVITE_MS = 5 * 60 * 1000;
/** One ask (好友 or 组队) from one player to another at most this often. */
export const ASK_EVERY_MS = 10 * 1000;
/** A mod's team event: its data, as JSON text, at most (ModGame.sendTeam: 4096). */
export const MOD_EVENT_MAX = 4096;

export interface SocialOwner {
  id: number;
  name: string;
  /** Friends (ids). */
  friends?: number[];
  /** Asks to be friends not answered yet (ids of the askers). */
  friendAsks?: number[];
}

export interface SocialDeps {
  load(ctx: XtContext): Promise<SocialOwner>;
  save(o: SocialOwner): Promise<void>;
  byName(name: string): Promise<SocialOwner | undefined>;
  nameOf(id: number): Promise<string | undefined>;
}

export interface Team {
  leader: string;
  members: string[];
}

const FRIENDS_MAX = 100;

export function installSocial(world: World, deps: SocialDeps): { teamOf(name: string): Team | undefined } {
  const where = (name: string) => {
    const s = world.online(name);
    const room = s ? world.player(s)?.room?.name ?? "" : "";
    return { online: !!s, room };
  };
  const pushTo = (name: string, cmd: string, obj: Record<string, unknown>) => {
    const s = world.online(name);
    if (s) world.push(s, cmd, obj);
  };
  // An ask (好友, 组队) from one to another at most every ASK_EVERY_MS: no burying someone in dialogs.
  const asked = new Map<string, number>();
  const mayAsk = (from: string, to: string, kind: string) => {
    const k = `${kind}\u0000${from}\u0000${to}`, now = Date.now();
    if (now - (asked.get(k) ?? -Infinity) < ASK_EVERY_MS) return false;
    if (asked.size > 10000) asked.clear();
    asked.set(k, now);
    return true;
  };

  world.xt("BuddyManagerExtension.revival_friends", async (ctx) => {
    const o = await deps.load(ctx);
    const list = [];
    for (const id of o.friends ?? []) {
      const name = await deps.nameOf(id);
      if (name) list.push({ id, name, ...where(name) });
    }
    list.sort((a, b) => Number(b.online) - Number(a.online) || a.name.localeCompare(b.name));
    const asks = [];
    for (const id of o.friendAsks ?? []) {
      const name = await deps.nameOf(id);
      if (name) asks.push({ id, name });
    }
    ctx.reply({ list, asks }, "revival_friends");
  });

  world.xt("BuddyManagerExtension.revival_friend_add", async (ctx) => {
    const reply = (res: number, msg: string) => ctx.reply({ res, msg }, "revival_friend_add");
    const o = await deps.load(ctx);
    const name = String(ctx.params.name ?? "").trim();
    if (!name || name === o.name) return reply(0, "不能加自己为好友哦。");
    const other = await deps.byName(name);
    if (!other) return reply(0, `没有叫“${name}”的奥拉。`);
    if ((o.friends ?? []).includes(other.id)) return reply(0, `${name}已经是你的好友了。`);
    if ((o.friends ?? []).length >= FRIENDS_MAX) return reply(0, "你的好友已经满了。");
    if ((other.friends ?? []).length >= FRIENDS_MAX) return reply(0, `${name}的好友已经满了。`);
    // Asked by the other before: friends at once.
    if ((o.friendAsks ?? []).includes(other.id)) return befriend(ctx, o, other, reply);
    if (!mayAsk(o.name, other.name, "friend")) return reply(0, "刚刚已经邀请过了，等对方回答吧。");
    other.friendAsks = [...new Set([...(other.friendAsks ?? []), o.id])].slice(-50);
    await deps.save(other);
    pushTo(other.name, "revival_friend_ask", { id: o.id, name: o.name });
    reply(1, `已经向${name}发出好友邀请，等待对方同意。`);
  });

  const befriend = async (ctx: XtContext, o: SocialOwner, other: SocialOwner, reply: (res: number, msg: string) => void) => {
    if ((o.friends ?? []).length >= FRIENDS_MAX || (other.friends ?? []).length >= FRIENDS_MAX) {
      o.friendAsks = (o.friendAsks ?? []).filter((id) => id !== other.id);
      await deps.save(o);
      return reply(0, "好友已经满了。");
    }
    o.friends = [...new Set([...(o.friends ?? []), other.id])];
    other.friends = [...new Set([...(other.friends ?? []), o.id])];
    o.friendAsks = (o.friendAsks ?? []).filter((id) => id !== other.id);
    other.friendAsks = (other.friendAsks ?? []).filter((id) => id !== o.id);
    await deps.save(o);
    await deps.save(other);
    pushTo(other.name, "revival_friend_added", { id: o.id, name: o.name });
    reply(1, `${other.name}和你成为好友了！`);
  };

  world.xt("BuddyManagerExtension.revival_friend_answer", async (ctx) => {
    const reply = (res: number, msg: string) => ctx.reply({ res, msg }, "revival_friend_answer");
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    if (!(o.friendAsks ?? []).includes(id)) return reply(0, "这个邀请已经过期了。");
    const name = await deps.nameOf(id);
    const other = name ? await deps.byName(name) : undefined;
    if (!other || ctx.params.ok !== true && ctx.params.ok !== 1 && ctx.params.ok !== "1" && ctx.params.ok !== "true") {
      o.friendAsks = (o.friendAsks ?? []).filter((x) => x !== id);
      await deps.save(o);
      return reply(1, "已经拒绝了。");
    }
    return befriend(ctx, o, other, reply);
  });

  world.xt("BuddyManagerExtension.revival_friend_del", async (ctx) => {
    const o = await deps.load(ctx);
    const id = Number(ctx.params.id) | 0;
    o.friends = (o.friends ?? []).filter((x) => x !== id);
    await deps.save(o);
    const name = await deps.nameOf(id);
    const other = name ? await deps.byName(name) : undefined;
    if (other) {
      other.friends = (other.friends ?? []).filter((x) => x !== o.id);
      await deps.save(other);
    }
    ctx.reply({ res: 1, id }, "revival_friend_del");
  });

  // Where a friend or a teammate is (not just anyone's).
  world.xt("BuddyManagerExtension.revival_where", async (ctx) => {
    const name = String(ctx.params.name ?? "");
    const me = ctx.player.name;
    const t = teamOf(me);
    let known = !!t && t.members.includes(name);
    if (!known) {
      const [o, other] = [await deps.load(ctx), await deps.byName(name)];
      known = !!other && (o.friends ?? []).includes(other.id);
    }
    ctx.reply(known ? { name, ...where(name) } : { name, online: false, room: "" }, "revival_where");
  });

  // ---------------------------------------------------------------- 组队

  const teams = new Map<string, Team>();
  const teamOf = (name: string) => teams.get(name);
  const newTeam = (leader: string): Team => ({ leader, members: [leader] });
  /** A 副本's or 时空隧道's room (one player's, "<room>@<name>"): the team does not follow there. */
  const alone = (room: string) => room.includes("@");
  /** Invitations not answered yet: the one invited -> the leaders who asked (and when). */
  const invites = new Map<string, Map<string, number>>();
  const invited = (name: string, leader: string) => {
    const at = invites.get(name)?.get(leader);
    return at != null && Date.now() - at < INVITE_MS;
  };
  const tell = (t: Team) => {
    for (const m of t.members) pushTo(m, "revival_team", { team: t });
  };
  const leave = (name: string) => {
    const t = teams.get(name);
    if (!t) return;
    teams.delete(name);
    t.members = t.members.filter((m) => m !== name);
    pushTo(name, "revival_team", { team: null });
    if (t.members.length === 0) return;
    if (t.leader === name) t.leader = t.members[0];
    // One left alone is no team.
    if (t.members.length === 1) {
      teams.delete(t.members[0]);
      pushTo(t.members[0], "revival_team", { team: null });
      return;
    }
    tell(t);
  };
  // A member's game ends: out of the team.
  world.onLeaveGame((s: Session) => {
    const p = world.player(s);
    if (!p) return;
    leave(p.name);
    invites.delete(p.name);
  });

  world.xt("TeamExtension.revival_team", (ctx) => ctx.reply({ team: teamOf(ctx.player.name) ?? null }, "revival_team"));
  world.xt("TeamExtension.revival_team_make", (ctx) => {
    const me = ctx.player.name;
    let t = teamOf(me);
    if (!t) {
      t = newTeam(me);
      teams.set(me, t);
    }
    ctx.reply({ team: t }, "revival_team");
  });
  world.xt("TeamExtension.revival_team_invite", (ctx) => {
    const reply = (res: number, msg: string) => ctx.reply({ res, msg }, "revival_team_invite");
    const me = ctx.player.name;
    const name = String(ctx.params.name ?? "").trim();
    if (!name || name === me) return reply(0, "不能邀请自己哦。");
    if (!world.online(name)) return reply(0, `${name}现在不在奥拉星上。`);
    if (teamOf(name)) return reply(0, `${name}已经在一个队伍里了。`);
    let t = teamOf(me);
    if (!t) {
      t = newTeam(me);
      teams.set(me, t);
      ctx.reply({ team: t }, "revival_team");
    }
    if (t.leader !== me) return reply(0, "只有队长才能邀请队员哦。");
    if (t.members.length >= TEAM_MAX) return reply(0, `队伍最多${TEAM_MAX}个人。`);
    if (!mayAsk(me, name, "team")) return reply(0, "刚刚已经邀请过了，等对方回答吧。");
    let mine = invites.get(name);
    if (!mine) invites.set(name, (mine = new Map()));
    mine.set(me, Date.now());
    pushTo(name, "revival_team_ask", { leader: me });
    reply(1, `已经邀请${name}加入队伍。`);
  });
  world.xt("TeamExtension.revival_team_join", (ctx) => {
    const me = ctx.player.name;
    const leader = String(ctx.params.leader ?? "");
    // Only with an invitation of that leader (each is used once).
    if (!invited(me, leader)) return ctx.reply({ team: teamOf(me) ?? null, msg: "这个邀请已经过期了。" }, "revival_team");
    invites.get(me)?.delete(leader);
    const t = teamOf(leader);
    if (!t || t.leader !== leader) return ctx.reply({ team: teamOf(me) ?? null, msg: "这个队伍已经解散了。" }, "revival_team");
    // In it already (a second invitation answered): nothing to change.
    if (teamOf(me) === t) return ctx.reply({ team: t }, "revival_team");
    if (t.members.length >= TEAM_MAX) return ctx.reply({ team: teamOf(me) ?? null, msg: "队伍已经满了。" }, "revival_team");
    if (teamOf(me)) leave(me);
    // Leaving the old team may have ended this one (the leader alone in it).
    if (teams.get(leader) !== t) return ctx.reply({ team: null, msg: "这个队伍已经解散了。" }, "revival_team");
    t.members.push(me);
    teams.set(me, t);
    tell(t);
    // To the leader's room.
    const room = world.online(leader) ? world.player(world.online(leader)!)?.room?.name : "";
    if (room && !alone(room)) world.push(ctx.session, "revival_team_go", { room, leader });
  });
  world.xt("TeamExtension.revival_team_leave", (ctx) => leave(ctx.player.name));
  world.xt("TeamExtension.revival_team_go", (ctx) => {
    const me = ctx.player.name;
    const t = teamOf(me);
    if (!t || t.leader !== me) return;
    // The room the leader is in (not any he names: a member could be sent into a stranger's
    // home, or a mod room of a mod he does not run).
    const room = ctx.player.room?.name ?? "";
    if (!room || alone(room) || String(ctx.params.room ?? "") !== room) return;
    for (const m of t.members) if (m !== me) pushTo(m, "revival_team_go", { room, leader: me });
  });
  // A mod's team event (IModGame.sendTeam): to the other members; their page hands it to the
  // same mod (id and version), if it runs there.
  /** Team events and lines one after another: at most this many a second from one member. */
  const paced = new Map<string, { at: number; n: number }>();
  const pace = (name: string, perSecond: number) => {
    const now = Date.now();
    const p = paced.get(name);
    if (!p || now - p.at >= 1000) {
      paced.set(name, { at: now, n: 1 });
      if (paced.size > 10000) paced.clear();
      return true;
    }
    return ++p.n <= perSecond;
  };
  world.xt("TeamExtension.revival_team_mod", (ctx) => {
    const t = teamOf(ctx.player.name);
    if (!t || !pace(ctx.player.name, 20)) return;
    const mod = String(ctx.params.mod ?? ""), ver = String(ctx.params.ver ?? "");
    const event = String(ctx.params.event ?? "").slice(0, 64), data = String(ctx.params.data ?? "null");
    if (!t || !mod || mod.length > 32 || ver.length > 20 || !event || data.length > MOD_EVENT_MAX) return;
    for (const m of t.members) if (m !== ctx.player.name) pushTo(m, "revival_team_mod", { from: ctx.player.name, mod, ver, event, data });
  });
  world.xt("TeamExtension.revival_team_say", (ctx) => {
    const t = teamOf(ctx.player.name);
    const text = String(ctx.params.text ?? "").slice(0, 80);
    if (!t || !text || !pace(ctx.player.name, 3)) return;
    for (const m of t.members) pushTo(m, "revival_team_said", { name: ctx.player.name, text });
  });

  return { teamOf };
}
