# 联机模式: a shared server

The page starts with a choice (web/start.js):

- **单机模式**: the game's server runs inside the page, for one 奥拉; saves stay
  in the browser. This is how the game always ran here.
- **联机模式**: the page connects to a shared server that you (or a friend)
  run. Write its address (for example `192.168.1.20:8080` or
  `https://aola.example.workers.dev`), the 奥拉's name and a password.
  **检查服务器** asks the server whether it is there and how many are on.
  The first login of a new name signs it up with that password (unless the
  server is closed to new names); **改名字** changes the name of an 奥拉 (with
  its password, while it is not in the game).

`?mode=server&server=<address>&name=<name>&pass=<password>` in the page's
address picks 联机模式 at once (the start screen is skipped).

The game files are private. Run a shared server for yourself and the friends
you play with, not for the public.

## Running it

### Node (any computer)

```sh
npm run build:swf && npm run build      # the site, dist/
node server/src/node/multi.ts --port 8080 --data work/server
```

The same port serves the page (dist/), the game (`/__socket/9339`, a
WebSocket) and the small API (`/__api/status`, `/__api/rename`). Open
`http://<that computer>:8080/`, choose 联机模式 and give it the same address.

| Option | |
| --- | --- |
| `--port N` | the port (default 8080, or `$PORT`) |
| `--bind ADDR` | the address to listen on (default `0.0.0.0`; `127.0.0.1` for this computer only) |
| `--data DIR` | the saves: one JSON file a key (default `work/server`, or `$AOLA_DATA`) |
| `--web DIR` | the site to serve too (default `dist`; `--web ""` serves only the game, the page then comes from elsewhere) |
| `--tables DIR` | where `www.9aola.com/revival/*.json` are (default `<web>/files`) |
| `--date DAY` | the game clock's day, China time (default 2012-08-15) |
| `--closed` | no new names: only 奥拉 already signed up may log in |
| `--max-players N` | at most N in the game at once (default 200) |
| `--no-toolbox` | close the 工具箱 (晶币, 亚比 … for nothing), mods' gifts of 亚比 and 导入存档 to the players, for a fair server; open by default, as in 单机模式 |
| `--adopt` | a save with no password in it (copied in from elsewhere) takes the password of its first login; off by default |

Saves copied in from elsewhere (a `user/<name>.json` with no password in it)
cannot be logged in to, unless the server runs with `--adopt`: then the first
login gives it its password. Copy in only your own. (Players can bring in a
save themselves: 存档 below.)

The `--data` folder must not be inside the `--web` folder (the site's files
are anyone's to download): the server refuses to start so.

Nothing in it is particular to a host: a VPS, a container, or a home PC
behind a tunnel run it the same. Back up the `--data` folder to keep the saves.
For a server reached over the internet, put it behind HTTPS (a reverse proxy
or a tunnel): the page on an `https://` address can only open `wss://`
sockets.

### Cloudflare (Workers and a Durable Object)

`server/src/cloudflare/worker.ts` is the same game on Cloudflare: the Worker
serves dist/ as static assets and hands `/__socket/` and `/__api/` to one
Durable Object, which holds the world and keeps the saves in its storage.

1. Build the site: `npm run build:swf && npm run build`.
2. Copy `server/src/cloudflare/wrangler.example.toml` to `wrangler.toml` at the
   repository's root and change `name` if you like.
3. `npx wrangler deploy` (it asks you to sign in to Cloudflare the first time).
4. Open the address it prints, choose 联机模式 and give it that address.

The Durable Object must be SQLite-backed (`new_sqlite_classes`, as in the
example): a player's save can be larger than the 128 KB a value of the older
storage may be. `AOLA_CLOSED`, `AOLA_DATE`, `AOLA_MAX_PLAYERS` and `AOLA_ADOPT` under
`[vars]` are the Node server's `--closed`, `--date`, `--max-players` and
`--adopt` ("1" for on); `AOLA_TOOLBOX` "0" is `--no-toolbox`.
A Cloudflare Access policy in front of the Worker keeps it to the people you
invite.

## Accounts, saves and passwords

- **No sign-up form**: the first login of a name nobody has signs it up with
  that password (not with `--closed`). Then only that password opens it, and
  one game a name: a second login ends the first. The start screen's
  联机模式 fields start empty (the browser remembers what was written there,
  the password only with 记住密码).
- **Saving** is the server's, as one plays: each change is written at once
  (Node: one JSON file a key in `--data`, `user/<name>.json` an 奥拉;
  Cloudflare: the Durable Object's storage). Back up `--data`.
- **改名字 and 改密码 in the game** (one's own 信息卡): a rename asks for the
  password, ends the game and comes back into it with the new name (no other
  奥拉 may have it); 改密码 asks for the password now and the new one, and the
  game goes on. 改名字 on the start screen works too (out of the game).
- **存档** (the 工具箱's 导出存档 / 导入存档, with the password): the same file
  as 单机模式's, so a save goes from one mode to the other and back. An import
  keeps the 奥拉's name, password and friends on this server, ends its game
  and reloads the page. `--no-toolbox` closes imports (a file can hold any
  亚比 and items, as the 工具箱 gives).
- **Passwords** are kept as salted PBKDF2-SHA256 hashes, never as typed, and
  never leave the server (nor do the saves, but to their own 奥拉's export).
  A wrong one is answered a second later, and five within ten minutes from
  one address lock the name there for a minute, whichever way they are tried
  (login, 改名字, 存档); the player from his own address is not locked out.
  There is no 忘记密码: an 奥拉 is a name and a password, nothing else.
  Over `http://` the password crosses the network as it is: put a server
  reached over a network you do not trust behind HTTPS. Whoever runs a
  server can read its saves: use a password of your own for it.
- **Nothing else is lost** against 单机模式: the same game runs on the server
  (the 工具箱 too, unless `--no-toolbox`).

## What works together

- **Seeing each other**: everyone in a scene sees the others walk, speak
  (发言, 表情, 动作) and shoot (射击); the name above each is the 奥拉's
  name. A click on another 奥拉 opens its 信息卡 (and its HELLO's own
  panel).
- **好友** (the bar's 好友): ask by name or from a 信息卡 (加为好友); the
  other answers 同意 or 拒绝, at once or later from the list. The list shows
  who is on and where (a scene, someone's 家园, 小屋 or 动物园, a 模组);
  **找他** goes there, **他家** to his 家园, **删除** ends the friendship.
  Where someone is, only friends and teammates are told; an ask to the same
  奥拉 again waits 10 seconds.
- **Homes**: a friend's 家园 (去他家 on a 信息卡, 他家 in the list), from
  there his 小屋 and his 动物园, as at home. A visitor sees what the owner has
  (the furniture, the trees, the zoo's animals) but changes nothing, except
  **摘果子**: one fruit of each fruiting a visitor, the last always left to the
  owner. The 小屋's **最近访问** (足迹) lists the last 20 visitors, with
  去他家; the footprints count every visit.
- **组队** (the bar's 组队, or 邀请组队 on a 信息卡): up to 3. The leader
  invites (an invitation holds 5 minutes; nobody joins uninvited); the
  members follow the leader from room to room (scenes, homes, 模组 rooms);
  队伍聊天 speaks to the team only; a leader who leaves passes the team on.
  Teams last while their members are on.
- **亚比对战** (亚比对战 on another 奥拉's 信息卡, both in the same place):
  the other agrees, and both fight on their own battle screens, each with his
  own 亚比 in front. Each turn waits for both (45 seconds, then a skill is
  chosen for whoever has not); a fallen 亚比 is replaced by its player; the
  side with none left loses, and 逃跑 gives up. Nothing is won or lost: both
  fight with copies of their bag, 体力 and PP full, for no experience or items.
- **模组 together**: a team whose members have loaded the same mod (the same
  id and version) plays its rooms together: in a team a mod's room is one room
  for the team, and the leader going into one takes the others along. A mod
  can share what happens with `sendTeam` / `onTeam` (docs/MODDING.md, 组队).
  Its fights are each player's own.
- **Battles are one player's**: bosses, 副本 and 时空隧道 are played alone,
  also in a team (a team does not follow its leader into a 副本 or 时空隧道,
  whose rooms are each player's own). The 2013 team battles (the 3v3 screen,
  every player and the boss on one screen) are lost with the 2013 battle
  screen, so there are none; 亚比对战 is the one battle between players.

Not there: team battles (组队BOSS, a team in a 副本 or 时空隧道, team fights in
mods), 战队 and 兵团, trading.

## How it is made

- `server/src/game/sfs2013/host.ts`: the game for any host (a Store, the
  tables, the connections). `src/node/multi.ts` and `src/cloudflare/worker.ts`
  only carry bytes and files to it.
- `accounts.ts`: names and passwords (PBKDF2-SHA256, salted). One game a
  name: a second login of the same 奥拉 ends the first.
- `social.ts`: 好友 (kept by player id, so a new name keeps its friends) and
  组队 (in memory), under the extensions the 2013 client numbers
  (`BuddyManagerExtension`, `TeamExtension`, `revival_*` commands).
- `house.ts`: the homes' rooms (`<owner>_<house>_Home`) and the 足迹.
- The players' records are kept live (`LiveRecordStore`): two players
  changing one record at once (a visitor picking fruit while the owner
  fights) both count.
- The client: `rebuild/src/control/mmo/control/Social.as` (what arrives
  without being asked, going where someone is), `FriendPanel.as`,
  `TeamPanel.as`; `ModRun.as` / `ModGame.as` for mods in a team.
- Tests: `server/test/multiplayer.test.ts` (two players over the real
  protocol), `cloudflare.test.ts`.
