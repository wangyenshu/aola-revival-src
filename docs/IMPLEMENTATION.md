# Implementation

This document describes how the revival works: the page, the server
emulator, the rebuilt client and each game system. Building and testing
are in [DEVELOPMENT.md](DEVELOPMENT.md).

## Overview

```
dist/index.html + boot.js
 ├── service worker (sw.js)
 │     answers every request for www.9aola.com, aola.100bt.com and the other
 │     original hosts from dist/files/
 ├── server emulator (emulator.js)
 │     the 2013 game server in TypeScript; saves in IndexedDB
 └── Ruffle (ruffle/)
       runs the original start.swf, which loads the loader, login, play.swf
       and the game modules from their original URLs; the client's socket to
       127.0.0.1:9339 goes through Ruffle's socket proxy to the emulator
       (单机模式, started when it is chosen) or a shared server (联机模式)
```

The client is the January 2013 client wherever its files survive. Where a
module is lost, a replacement is compiled from ActionScript sources against
the surviving 2013 libraries, so that the original modules around it work
unchanged. The server is lost entirely; the emulator answers each request
in the format the client's code reads.

## Rules for every file

1. An original of the 25 January 2013 release, or an older unchanged file,
   is used as it is.
2. A lost module is rebuilt against the 2013 interfaces. Its source says
   REBUILT.
3. A later copy is used only where nothing older survives. Later code is
   adapted to the 2013 libraries; later art and data are used where their
   structure matches. Every later file is listed as such in
   `game/FILES.jsonl`.
4. A value the client does not contain (battle formulas, rewards, levels,
   prices in 星币, the placement of a lost door) is reconstructed from the
   client's tables, later code and dated guides, and marked RECONSTRUCTED in
   the code with its source.

Markers in source comments:

| Marker | Meaning |
| --- | --- |
| REBUILT | written for the revival in place of a lost module or class |
| REVIVAL | an addition of the revival (not in the 2013 game) or a fix to a later file |
| RECONSTRUCTED | a value or behaviour the surviving files do not give |
| LATER | code or art from a file uploaded after January 2013 |
| ERA | code of a 2013 or earlier file, recompiled (for example to fix a fault) |

## Game files

`game/` holds the files at the paths the client asks for,
`www.9aola.com/<path>%3F<version>`. The version is the one in the 2013-01-25
manifest (`versiondata.swf?201301241`) or the loader's default, `1210`.
`game/FILES.jsonl` lists each file with its size, SHA-1, origin and source:

| Origin | Files | Size | What |
| --- | --: | --: | --- |
| `era` | 15,215 | 933 MB | uploaded to the CDN on or before the release, or found to be unchanged older files |
| `later` | 4,073 | 426 MB | uploaded after the release, used where no older copy survives |
| `capture` | 142 | 17 MB | Wayback Machine captures: the boot chain, the 2013 site's pictures, the November 2012 map |

The files come from an archive of the live CDN
([ARCHIVE.md](ARCHIVE.md)) and earlier Wayback captures, selected by
`tools/make_game_root.py`. Curation tools added files later (story quest
rooms, catalog pages, the 奥拉周刊, boss pictures); each addition is listed
with `"added"` in `FILES.jsonl`. The build never downloads game files.

The static build renames `%` to `~` (`start.swf%3F120830` becomes
`start.swf~3F120830`), because static hosts do not serve names with a
literal `%3F`. `dist/files/index.json` lists every file.

## The page

`web/index.html` holds the game in a frame styled after the 2012–13 official
site; `?bare=1` shows the game alone (used by the automated tests).
`web/config.js` sets:

- `bootUrl`: `http://www.9aola.com/start.swf?120830`, the entry SWF;
- `pageScripts`: the original page scripts `qs.js` and `js/aola.js`, which
  provide the functions the client calls through ExternalInterface;
- `hosts`: the original hosts the service worker answers;
- `sockets`: the game server address the client connects to,
  `127.0.0.1:9339`;
- `mode`: `inpage` (the emulator runs in the page) or `server` (sockets go to
  the Node server's WebSocket bridge);
- `date`: none (the game clock is the real time), or the page's `?date=` (a day the clock
  starts at at each page load, for trying a day of the era).

`web/boot.js` registers the service worker, waits until it controls the
page, starts the emulator, loads the page scripts and starts Ruffle with a
socket proxy that hands the client's connections to the emulator. On an
`https` page it rewrites the original `http://` URLs to `https://`, because
the browser would block mixed content before the service worker sees it.
Ruffle runs with `openUrlMode: "deny"`, so the game's links to 百田's pages
open nothing. `?dev=1` enables test commands in the emulator.

`web/theatre.js` answers the client's video calls (`showVideoPlayer` and
others) by opening the game's 百田大剧场 (`control/TheatrePanel`, which plays
the surviving FLVs). The screens before the game and the account panels are drawn in the game (so
they show in fullscreen): the login's 进入奥拉星 (单机模式 / 联机模式) and 选择奥拉
(`login/StartScreen`, `RolesScreen`), and the 工具箱's 存档 and the 信息卡's
改名字 / 改密码 (`shared/mmo/revival/SavePanels`), with Flash's own dialogs for
the files. The page does their work through ExternalInterface: `web/start.js`
(what the start screen remembers; 单机模式's 奥拉) and `web/saves.js` (存档,
names and passwords), in both modes (the page's own game, or the shared
server's `/__api/`). Ruffle's sockets go to one address, which `boot.js` routes
when the login connects: to the in-page game, or to the chosen server. 单机模式's game (and its
one-tab lock) starts on 选择奥拉's 进入; before that 选择奥拉 works on the page's saves without it
(`AolaEmulator.openSaves`, the same game without its sockets), so 返回 leaves the page as it was
and 联机模式 can be chosen next. In 联机模式 a new 奥拉 is made on 注册 (`login/RegisterScreen`:
the address, the name, the password twice; `web/start.js` `register`, the server's
`/__api/register`), never by a login; 记住密码 keeps a token of the server's
(`/__api/remember`) in place of the password, and `?pass=` is not read.

### The service worker

`server/src/browser/sw.ts`, built to `dist/sw.js`, intercepts requests for
the configured hosts and answers them from `dist/files/` using
`index.json`: the file with the requested version if it is listed, else the
file of that path without a version. It sets the content type from the
file's real extension (a static host cannot tell it from
`aola.js~3F20121227`), passes range requests on and
answers `crossdomain.xml` itself. Requests for other origins are answered as
missing, so nothing is fetched from other sites. Without an index (the Node
server), it tries each file root in turn.
`server/src/core/mirrorPath.ts` holds the URL-to-file rules shared with the
build and the Node server (Python copy: `tools/mirrorpath.py`).

## The server emulator

`server/src/` is TypeScript. The same code runs in the page (bundled by
esbuild into `dist/emulator.js`) and in Node (`npm start`).

### Core

| File | Purpose |
| --- | --- |
| `core/emulator.ts` | sessions, transports, the request queue (one player's requests run one after another) |
| `core/framing.ts`, `codec.ts` | message framing and decoding |
| `core/amf3.ts` | AMF3 encoder and decoder for extension calls |
| `core/clock.ts` | the game clock (see "The game clock" below) |
| `core/locks.ts` | work on named things one after another (an account's name, a record everyone writes) |
| `core/addr.ts` | a client's address as the limits count it (an IPv6 one by its /64) |
| `core/plain.ts` | a bounded plain copy of what a client sent, and bounded text of it for logs |
| `core/store.ts` | key-value store interface (IndexedDB in the page, JSON files in Node, a Durable Object's storage on Cloudflare, whose keys are listed a page at a time: its list brings the values); a player's record is made JSON once a save (measured, and written as that text: `setText`) |
| `core/recorder.ts` | logs of the traffic for debugging |
| `browser/entry.ts`, `idbStore.ts`, `shim.ts` | the in-page start, IndexedDB store, the socket proxy for Ruffle |
| `node/main.ts`, `http.ts`, `transports.ts`, `fileStore.ts` | the Node dev server: HTTP mirror, WebSocket bridge, raw TCP ports, the policy file |
| `node/multi.ts`, `cloudflare/worker.ts` | the shared server of 联机模式 on Node and on Cloudflare (docs/MULTIPLAYER.md) |

### The 2013 protocol

`game/sfs2013/protocol.ts` implements the wire format of the 2013 client
libraries (`library/socketserver.swf`, `library/socketclient.swf`), a
variant of SmartFoxServer 1.x: an int32 length, a packet number and a salt
byte from the client, then system messages (login, join room, leave room,
public message, user and room variables) or extension calls
(`XtReq`: extension id, command, AMF3 parameters). Replies to extension calls
are AMF3 objects with a `_cmd` field.

`game/sfs2013/server.ts` is the server: the `aola` zone, rooms created on
demand by name (one per scene; the 沙盒 uses one room per player), user
variables echoed to the room (`avatar`, `p` for the following 亚比, `r` for
the HELLO, `mtype` for 蓝宝石), and dispatch of extension calls by
extension name and command (`PetExtension.54_16`). The variables the server
keeps (`avatar`, `c`, `nn`, `mtype`, `p`, `r`, `hs`, `shoot_effect`, `ms`) are
set only by the server: a client's setUvars of them is dropped. A session's
requests are limited (`RATES`: all of them, extension requests, setUvars, room
joins, and the commands a module bounds with `world.limit`); what is over is
dropped, and a session that keeps on is closed. AMF3 values are bounded in
size and depth (`AMF3_MAX_COST`, `AMF3_MAX_DEPTH`; a reference that would
repeat a value counts as the value).

### Game modules

| File | Commands and state |
| --- | --- |
| `game.ts` | login replies, the player record, inventory, buying and selling, money, the 工具箱, riding, quest items |
| `pets.ts`, `pmdata.ts` | 亚比: creation, stats, skills, experience, evolution, the bag and the 仓库 |
| `battle.ts` | battles: wild 亚比, task 亚比, bosses, NPC challenges, 黑星堡垒, 时空隧道, 副本 fights, the 沙盒 |
| `tasks.ts` | quest progress, steps the server finishes itself, rewards |
| `house.ts`, `plants.ts`, `zoo.ts`, `eggs.ts` | the 小屋, the 植树盆, the 动物园 and 生态园 games, the 亚比孵化器 |
| `shoot.ts` | 射击 cards and effects |
| `minigames.ts`, `parkour.ts` | mini game scores, 斑比向前冲, 极限轰炸, 酷跑星世界 |
| `fb.ts` | the 四大副本 |
| `gyms.ts` | the 道馆 |
| `planetacts.ts`, `areafuncs.ts` | the planets' activities, the functions of the places |
| `sevenstar.ts`, `kingbosses.ts`, `fightking.ts` | 黑暗三连星 and 魔将挑战; 修罗, 凯撒 and 召唤奇灵王; 武神大陆 (their fights through `54_22` and `addActFight`) |
| `wnking.ts` | 狼王再现 and 夜王回归 (February 2013): the 分身's fights, the 光之星 / 幽之星, 召唤狼王 / 召唤夜王, the 终极试炼 |
| `costumes.ts` | the 2012 套装 the 守护者 and 武神大陆's generals leave a part of |
| `godbosses.ts` | 天空之神 (拉诺斯), 施瓦辛格, 波塞冬 and 魔龙之战 (赤翼魔龙王), with the helpers that come out after the boss (`ActFight.team`) |
| `yabistudy.ts` | 亚比研究中心's 亚比融合 (and its 孵化器) and 天赋启迪 |
| `superevo.ts` | 亚比超进化 (the 超进化机, `PetExtension2.54e_1` after the 小独角兽's and the union 亚比's): the nine 超进化 of early 2013 and what each takes |
| `sandbox.ts`, `mods.ts` | the 沙盒's fights; mods' saved data, 亚比, gifts and parties (their own 亚比 and 道具) |
| `petcards.ts`, `petitems.ts`, `giftbags.ts` | 战术卡, 亚比道具, what each 礼包 holds |
| `host.ts`, `accounts.ts`, `api.ts`, `saves.ts` | the game for any host (the connections it takes: `admit`); names and passwords (the lock on wrong ones, 注册 and its limits, the tokens of 记住密码); the shared server's small API; 存档 files, and the page's own 奥拉 |
| `wins.ts`, `fighting.ts`, `money.ts` | the fights a session has won lately (for the requests that follow a win); who is in a fight now; the bounds of money |
| `social.ts`, `duel.ts` | 好友, 组队, where a friend is; 亚比对战 between players |

Each player is one record: name, outfit, 晶币, 星币, 晶豆, items by type,
亚比 (bag and 仓库), house and furniture, garden and zoo, quests, bosses
beaten, daily counters. In the page the records are JSON values in the
IndexedDB database `aola-revival`, store `kv`; the Node server writes JSON
files under `work/`.

### The game clock

`core/clock.ts` is the real time, in every host (the page's game, the Node
server, the Worker): days go on between visits and across restarts, and a
timer set in one visit ends when its time comes, whether the game is open or
not. Days are China days (`chinaDay`: a "once a day" starts again at midnight
China time, as on the original servers; the 神奇摇摇树's day at 6:00, 极限轰炸's
week on Monday). The client reads the same time: `DateUtil.getServerTime()`
gives China time whatever the player's time zone, so its own clock, and the
activities that open at certain hours, are China's real hours.

`--date DAY` (`AOLA_DATE`, the page's `?date=2012-08-15` or
`?date=2012-08-15T13:00`) starts the clock at that day at each start instead,
for trying a day of the era (its dated activities) or the automated
walk-throughs; it goes back at every start, so it is not for playing.

Records saved while the clock was the anchored one (earlier versions of the revival) hold
2012 times. The first time the real clock reads such a record (`toRealClock`,
once: `realClock`), the times that would lose something 14 years on become now:
a 亚比 let go keeps its days in the 放生仓库, a 财富小管家 box starts its term, a
timed quest being done its time. What only gets ready (eggs, the 融合孵化器,
plants, the zoo's animals) is ready.

The client's activities that open only at certain times (the served files not
replaced by a rebuilt module), in China time:

| Module | Open |
| --- | --- |
| 黑暗之王崛起 (`activityres/activity120927/darkmanjueqi`) | its fights' 活动时间 12:00–13:59 |
| 拍卖 (`vendue/vendue`) | 12:00–20:00; prices changed before 20:00 |
| Story quests 1666, 1672, 1678 (August 2011) | their steps 14:00–17:59 |
| 龙军团 (`baricons/dragonarmyicon`, `bariconpanels/dragonarmypanel`) | Friday–Sunday 13–15 and 19–21, other days 19–21 |
| 咕咕七 (`scene/princestar4` FindGuGuQiPanel) | 27 July – 2 August, 13–15 |
| 亚比投票 (`activityres/petvote`) | the 21st–23rd at 14, 16, 19; the 24th–27th at 19 (any month) |
| Christmas quest 2124 | December, up to the 25th |
| 木头人 (`activityres/woodpanel`) | from the 2nd, July to December (its check of the month and day) |
| 小独角兽 (`unicorn/littleunicorncatch`), 梦幻小屋 (`scene/dreamhouse`) | every few minutes; at :00, :20, :40 |

None checks the year, so each opens on its days every year. The timed quests
(30 or 40 minutes from their acceptance: 1619, 2148, 2252, 2277, 2393, 2458,
2483, 2892, 3169) count from the quest's acceptance. The rebuilt modules
(`rebuild/src`) gate nothing by the hour, and the server's own handlers only
黑暗三连星's level (`sevenstar.ts`, by China hour).

### Reconstructed rules

The 2013 server's rules are lost. The main reconstructions:

- **Stats and battles**: the client's 亚比 tables have the columns of the
  Pokémon games they were modelled on (base stats, effort yields, base
  experience, experience groups, catch values), so the classic formulas for
  those columns are used (`pmdata.ts`). What a skill does is read from its
  description (`skilltext.ts`), clause by clause, and the battle engine does
  it: stat changes (全属性 is all eight 属性等级: 攻击, 防御, 特攻, 特防, 速度, 命中, 闪避 and 暴击), statuses,
  priority, damage that is not the formula's (half the foe's HP, levels,
  points), draining, healing, PP, shields and counters, effects that last
  some turns, charging and multi-turn skills. Every description of the
  图鉴's 亚比 is read to the last word; how much a "一定概率" is, or how
  strong "越少越大" grows, is a guess. 混乱 lasts 2 or 3 of the confused one's
  actions (or a skill's own 回合), each with a 1/3 chance that it hits itself
  instead (a 40-power blow of its own 攻击, its 攻击等级 counted) — the rule
  the later 奥拉星 states (the 2013 one is lost). A skill that attacks 全场
(千杀水翔, 爆炎龙卷, 躁动冲撞: the descriptions tell it from 自己以外的全场 and
对方全场) hits the user too, the same blow against its own 属性. A 回复 is shown whole, though the 体力
  stops at its maximum; 嗜血之矛's heal past it becomes 护盾 points, which take
  the next blows. A 蓄力 or 连续攻击N回合 skill goes on by itself (the player
  chooses nothing on those turns); a 连续攻击N回合 skill's power grows each
  turn of the N, starts again with its next use, and a miss takes the growth
  back (save 不管命中与否); "使用千军万马后威力大大提升" doubles it. With no PP
  left, the player's 亚比 uses 挣扎; the computer's (wild ones, bosses, 副本,
  时空隧道, quests, 道馆) take a 高级活力豆 instead, of which they have no end:
  their turn goes on it (20 uses back on every skill) and they fight on.
  A 自动战斗仪 battle ends by itself, won or lost, and gives every 亚比 of the
  bag all its 体力 and PP back, so that the next one can come. Its 亚比 uses
  the hardest blow against this foe (power, 属性, same-属性 bonus and accuracy;
  `autoChoice`, skill `-1`); the battle screen's 停止自动战斗 hands the turns to
  the player and stops the device (its battles kept; `revival_auto`), 开启自动战斗
  starts it again.
- **Catching**: an ordinary 亚比球 works once a wild 亚比 is down to a fifth
  of its HP, earlier for easy species, at any HP for the 朵朵兔 (as the 2011
  walkthrough says); better balls raise the chance.
- **Task 亚比**: fight at the level of the player's strongest 亚比 (two more
  for each further variant) and cannot be caught.
- **Bosses**: levels from the 2013 `BossTimeHelper` table where present,
  estimates otherwise; only beating the last form gives the egg.
- **Rewards and limits**: mini games pay 1 晶币 per 10 points (200 a game,
  1,000 a day); 副本 levels, chests, pay and rating; the 道馆 skill stones;
  the 财富小管家's interest (its later panel's words); prices in 星币 for
  real-money goods (half for 蓝宝石).
- **套装 parts**: a 守护者 of a known 套装 (its 2012 costume, from the
  material table's names) or a general of 武神大陆 leaves a part of it not
  yet had one win in five (`COSTUME_CHANCE`).
- **大战TT兔**: 1 + 2 + … 积分 for the 关 passed (what its end panel shows),
  20 of them for 糖糖 (the game's own text), once.
- **礼包**: opened when bought (the 2013 client has no command to open
  one); what each holds comes from its 2013 description or catalog page.

Each rule carries a RECONSTRUCTED comment with its source in the code.

## The rebuilt client

### Boot chain

| Step | File | State |
| --- | --- | --- |
| Start page and entry | `start.swf`, `loader.swf?201301241`, `versiondata.swf?201301241` | originals (Wayback captures) |
| Start screen | `user/yunyingres`, `user/yunyingstart` | originals, the January 2013 campaign removed (`tools/clean_start.py`) |
| Libraries | `library/common?130124` | original, with `PanelProxy.dispose` letting go of its panel before disposing it (a panel that removed itself went round without end; `tools/patch_scripts.py`) |
| Login | `user/login` | REBUILT: the revival's 进入奥拉星 and 选择奥拉 screens (the 2013 account form is lost), then connects, logs in to the zone, fills `UserInfo`, hands over to `play` as the original did |
| Game | `play.swf?130110` | REBUILT: creates the `ServiceContainer`, loads the `<play>` modules of `config.xml` in the original order, starts every service, enters the first scene |

### The engine

The 2013 scene engine (`mmo.play.*`, part of the lost `play.swf`) is
rebuilt in `rebuild/src/control/mmo/play/` and compiled into `play.swf`.
`tools/engine_census.py` lists every engine member the 392 surviving era
SWFs use, with the exact override signatures and namespaces, which the
rebuilt classes match.

| Class | Purpose |
| --- | --- |
| `SceneManager` | loads scenes and mini games, joins the scene's server room, keeps the scene history, dispatches the scene events; stand-ins for scenes that cannot run (`STAND_INS`, `BattleZoneHub`) |
| `SceneBase`, `AbstractScene`, `DocSceneBase` | the scene API the 2012–13 scenes use: layers (`background`, `obstruction`, `overlap`, `foreground`, `topground`), entry points, entrances, walk targets, wide scenes that scroll |
| `BigSceneBase`, `FBSceneBase`, `FlipSceneBase` | wide scenes, 副本 rooms, upside-down scenes |
| `PathGrid` | A* on a 10 px grid of the obstruction layer, 8 neighbours, no corner cutting, the path pulled tight |
| `PlayerBase`, `Player`, `ScenePlayer`, `PlayerManager` | players in the scene: walking, depth sorting, avatars, names, the following 亚比 |
| `MouseControlStrategy`, `ClickAndHitHelper` | click to walk; walk up to a target, then act |
| `ScenePatches` | fixes to later scenes, applied when a scene is shown: doors moved back or drawn where later copies lost them, NPC menus, buttons whose later handler is missing |

The namespace `mmo.play.scene.revival` holds the members the revival adds
to engine classes, so that they cannot clash with names the original code
uses.

### Modules

The rebuilt modules in `rebuild/src/`, one folder per module:

| Folder | Module |
| --- | --- |
| `control` | the control bar (its icons cut from the 2012 picture of it in the 小屋 tutorial film, `ShotIcons`, at their 2012 places), the engine classes (see above), the 工具箱, the 沙盒, the 物品 panel (in 副本 and for mods played alone; elsewhere the 信息卡's 道具), the place picker, the debug hook |
| `play`, `login` | the boot modules |
| `shared` | code compiled into several modules: `mmo.revival.*` (logging, JSON, base64, UI drawing, `RDef`, `RMaterialView`: a material's picture as it loads), the mod API `mmo.revival.mod` |
| `scenes` | rebuilt scenes: 奥拉广场 and 流星购物街 (`starland`), 主题公园, 亚比研究中心, 奥拉之树, 生态园, 十字大道, 图书馆, 欢乐岛, 烈焰洞穴 (`feier4`), 崩坏的上古神殿 (`temple1`), 道具店, 奇草树林, the 沙盒 room |
| `tasknpc`, `taskservice`, `taskdefines`, `taskextmanager`, `taskpanelnew`, `tasktransport`, `taskext` | NPCs, conversations and the quest engine; the newbie quest's scripts |
| `pet`, `petpackage`, `newpetpackage`, `petwarehouse`, `petfollow`, `petride`, `peteggservice`, `pethatchegg`, `petskillmes`, `pmservice`, `petfight`, `wildpet`, `peticonservice`, `peticonfill` | 亚比 data, the 亚比 tables (PMService), the bag (and the "PetPackage" service that opens it), the 仓库, following, riding, eggs, the battle screen and battle entry, wild 亚比, 亚比 pictures |
| `dailyactivity` | the 守护者 and event bosses, the planets' activities |
| `fbservice`, `fbteam`, `fbchoosepanel` | the 四大副本 (later code on the 2013 interfaces) |
| `spacetime` | 时空隧道 (later code) |
| `catalog`, `bconfig`, `buyback`, `rmbmall` | the catalog books, the buy flow (catalog/catalogservice on the art of its copy under the 2013 URL: its ConfirmBuy and ConfirmBuyClothes dialogs), the 兜兜回收器, the 商城; the 超进化手册 (book201103) is a guide book of `gen_bconfig.py` (`GUIDES`: its later page files count when every 道具 and 亚比 they name is of 2013) |
| `catalogpages` | the 收费亚比蛋商品册's first page (catalog/egg1), on its 2016 art |
| `house`, `housecommon`, `garden`, `zoo` | the 小屋 (with yz/plantdecorator: the trees made furniture), the 家园, the 动物园 |
| `zoopanels` | the 动物园's 2012 panels on their art (their later code cannot run on the 2013 files): the 动物仓库 (zoo/zoores_1), 动物园信息 (zoo/zoores), an animal's panel (zoo/petbreedingservice), each a module `zoo/revival/*` |
| `treemanager`, `treepanelres`, `plantitemview` | the 植树盆's 2012 tree panel and films (yz/treemanager, on the art of its later copy), its 盆栽道具 and 守护亚比 panels (yz/panel_res, April 2012 art), the 盆栽道具's pictures (plantitem/view1 … view7, the era files lost: drawn from the 种植手册 and the tree manager's art) |
| `gamemanager`, `parkour`, `catchanimalpanel` | mini games; 酷跑星世界; 动物捕捉's panel (its later art, the lost 动物乐园购买册 drawn) |
| `shoot`, `shooteffect` | 射击 (later code on the 2013 interfaces) |
| `usercard`, `face`, `scenetalk`, `helloicon`, `robotmanager`, `map`, `weekly`, `notifyview`, `scenearrow`, `sceneinit`, `antiaddiction`, `yakestarpanel` | the 人物信息卡 (drawn after the January 2012 游戏帮助's picture: 人物信息, 服装, 道具, VIP物品, 勋章), faces, chat, the HELLO, the world map, the 奥拉周刊, notices, scene arrows, scene music, the play-time limit (never reached), 巨锁石灵's panel |
| `starcoin` | fortunemanager/starcoin (the later copy): the 星币 machine's exchange panel (奥币铸造星币, 碎片铸造星币, the 财富小管家's 晶豆储蓄), its code on the 2013 libraries without the real-money 购买星币 panel; fortunemanager/fortunemanager (later) is served as it is |
| `wnking` | 狼王再现 and 夜王回归 (activity130221/wolfandnightking, 2016) on the 2013 libraries |
| `petridepanel` | 亚比骑乘训练 (pet/petridepanel, its 2021 copy) on the 2013 libraries |
| `petui` | pet/petUIservice: the choice of a 亚比 (天赋启迪's 选择亚比, a 超进化's), in the chooser the 2012 modules share (character 29 of activityres/breakegg) |
| `superevolution` | pet/superevolution (the 超进化机, config of 7 February 2013, lost) on the art of its 2015 copy: the 2013 超进化 only, their cards laid out anew |
| `petitem` | the bag's 道具 page (pet/petitem on its later art), with that art's 我要使用 (QuantitySelectePanel) |
| `tipsres` | library_res/common_res_tips: the views of every tip (TipsView, TipsViewBig …) on the art of its later copy, whose code called what the 2013 libraries lack |
| `helloskillicons` | the HELLO menu's skill icons, from the HELLO's own panels of 2012 (`robot/revival/helloskillicons`) |
| `abyssevil` | 魔龙之战's panel (activity121220/abyssevilmainpanel, 2015) on the 2013 libraries, without the later buff bar |

### Stand-ins

For every 2013 service whose module is lost and not yet rebuilt,
`tools/gen_stubs.py` generated a class with the original name and interface
(`rebuild/gen/stubs/`, 147 modules). Every method returns an empty value and
logs its first call (`[rebuilt] stub called: …` in the browser console). A
click that reaches a stand-in shows 这个功能还在修复中. A rebuilt module is listed in
`rebuild/build/no-stub.txt`, or its stand-in, installed after it, takes its place.

### Using later code

Some modules survive only as later uploads (2014 and after), which call classes
the 2013 libraries do not have. They are handled in these ways:

- **Recompiled**: the decompiled later code is compiled against the 2013
  libraries, with later-only calls replaced or removed and marked
  (`shoot`, `fbservice`, `fbteam`, `spacetime`, `parkour`, several scenes, and the mini game
  疯狂的水果, `rebuild/src/games/flyingfruit`).
- **Later interfaces kept**: where a later script calls a method through a
  later interface, the rebuilt service defines that method in the later
  interface's AVM2 namespace, so the unchanged script finds it.
- **Later classes in play.swf**: a few later classes the later mini games use are written
  again in `rebuild/src/control` (`mmo.interfaces.game.GameResultWrapper`,
  `mmo.common.datastructure.ConfuseNumber` of 飞天独角兽 and 毛毛飞天记,
  `mmo.loader.SimpleCLParam` and `SimpleCLLoader`), so those games find them.
- **Renamed calls**: `tools/abc_rename.py` renames one string in a SWF's
  bytecode; 22 later mini games call `SocketClient.startGame`, which the 2013
  library lacks, and now call a harmless method instead (`hasEventListener`;
  `getBuddyByName` for the eight with a `startGame` of their own, 冰之迷阵 and 霓虹泡泡珠
  among them); 卖蛋糕小达人 and 对决无双 name `SimpleCLLoader` for the later
  `SimpleCustomLoader.loadSingleRes`.
- **Transplanted**: `tools/swf_transplant.py` puts compiled code into an
  original SWF's art, binding the art's symbols to the new classes (the art's
  own classes are renamed `…Revived` so they do not shadow the new ones).
- **Filled pictures**: `tools/peticon_fill.py` gives `peticon` files without
  a small picture one made from their large picture.

### Build output

`npm run build:swf` writes 286 files into `build/rebuilt/` at their 2013 URLs.
The static build serves `build/rebuilt/` above `game/`: a rebuilt file
replaces the original of the same path.

## Data

The modules and the emulator read tables generated once from the decompiled
2013 and later modules. They are committed, so building needs no decompiler.

| Output | Tool | Contents |
| --- | --- | --- |
| `rebuild/gen/tasknpc/` | `gen_npc_data.py` | NPC placement per scene, named conversations |
| `rebuild/gen/taskdata/`, `tasknpc/TaskTalkData.as`, `rebuild/static/…/revival/tasks.json` | `gen_tasks.py` | quest definitions, starters, steps, conversations, the scene table of quest scripts |
| `rebuild/gen/petdict/`, `revival/pets.json` | `gen_pets.py` | the 亚比 dictionary and species data |
| `revival/pmdata.json` | `gen_pmdata.py` | battle data: base stats, skills, learnsets, attribute chart, experience curves |
| `rebuild/gen/wildpet/`, `revival/wildpets.json` | `gen_wildpets.py`, `map_pets.py` | wild 亚比 per room, levels, battle backgrounds |
| `rebuild/gen/bconfig/` | `gen_bconfig.py` | the catalog books and their pages |
| `revival/materials.json` | `gen_materials.py` | prices and buy-back prices |
| `rebuild/gen/petmes/` | `gen_petmes.py` | 亚比 and skill names, evolution lines, egg pictures |
| `rebuild/gen/pmservice/` | `gen_pmservice.py` | the rows of the 2013 PMCustomData: 亚比, skills, attributes, experience |
| `rebuild/gen/stubs/` | `gen_stubs.py` | the stand-in services |
| `rebuild/static/…/config.xml%3F201301241` | `config_overlay.py` | the 2013 `config.xml` with the story quest rooms, the game rooms and the 沙盒 room added |

## Systems

### Scenes

Each scene SWF provides a `DocSceneBase` whose scene class extends
`SceneBase`. `SceneManager.loadScene` loads the SWF, builds the scene, joins
the server room of the same name, places the players and calls the scene's
`onJoinRoom`. Entrances are walk targets: a click walks the player to the
door, and arrival loads the next scene with an entry key. `ScenePatches`
then applies per-scene fixes; `FbEntrances` adds the 副本 doors that the
later copies of their rooms lost.

Scene music (`init/sceneinit`, `SceneMusic`) plays the room's music from
`config.xml`, keeps it across rooms that share it, switches to battle music
during a battle and remembers the music switch.

### NPCs and quests

`task/tasknpc` places NPCs per scene (`SceneNpcData`), draws them from
`tasknpc/npc<id>`, and opens conversations with choices, actions and scene
changes. Scene NPCs are always shown; task NPCs only while a quest has a
conversation for them. Names and greetings come from the later
`task/tasknpcdefine` data.

`task/taskservice` keeps quest state with the 2013 TaskExtension protocol
(10-0 to 10-5). `task/taskextmanager` loads each scene's quest scripts
(`taskext/task<id>`, mostly original) from the scene table and keeps them
until the scene is left. The conversations come from the later client
(`TaskTalkData`), because the 2013 tables are lost. The server finishes two
kinds of steps itself, as the scripts expect: a step that needs items (once
the player has them) and a step that needs a task 亚比 beaten.

The newbie quest's scripts (135, 140, 150) were replaced on the CDN by later
versions and are rebuilt after the official walkthrough of December 2011.

### 亚比 and battles

The battle screen (`pet/petfightnew`) and battle entry
(`pet/loginpetfightnew`, `IPetFight`) are rebuilt after official 2011–12
screenshots, on the 2013 PetClient protocol: `54_2` starts a fight, `1401`
to `1405` are the player's actions, `2401` to `2422` the server's replies.
Battle sprites are `fightassets/pet<race>`; a 亚比 without a sprite is shown
as its large picture, and sprites without a back view are mirrored. Skill
animations are `fightassets/effect<skill>`, for every skill of the 亚比 data;
219 of them were uploaded later in 2013 (February to December: 星诺力量, the
圣灵星诺 line's skills …) and are taken from the archive like the others; 20
skills have no animation anywhere and are shown without one. Boss
films (`bossfightmovie/boss<id>`) play when the battle opens and at the HP
thresholds the later client used. After a 道具, by the player or by the computer's
亚比 (its 高级活力豆 when out of PP), a short movie plays over the 亚比 that
took it and the battle goes on when it ends, as in the later client
(`UseItemMovieHelper`): green for 体力糖 and the 药剂, blue for 活力豆. The
2013 movie was in the lost battle module and the later one
(`pet/fightasyncres/reverthpmovie`, `revertppmovie`) is not kept, so it is
drawn in code: a flash round the 亚比, a column of light rising over it, rings
at its feet, sparks, the 亚比 glowing; about two seconds.

Wild 亚比 (`pet/wildpetservice`) walk in 124 rooms; the list per room comes
from the November 2012 world map and the later location table, and for the
story rooms of 风暴星系 from `tools/data/wildpets-extra.json` (its sources per
亚比). The
following 亚比 wears its walking figure (`PetClothesMap` → `skin/a0<id>`)
or, without one, its large picture. Riding (`pet/petride`) is the engine's own:
the player's actions turn to their riding rows (`ddzr`, `ddwr`: the "r" of
ActionInfo, `RidingMovingState`), where the clothes sit higher and the ride
clothes (`skin/a0100xx`, `SkinInfoForRidingPet`) draw the 坐骑, its stand movie
while standing; the server shares it as the `ms` user variable (`ride;<speed>`,
`walk`), which the 2013 SocketClient tells every client as `onMovingStateChanged`.
The ride clothes of the 9 坐骑 the later client added (10081–10089, the later materialdata's
parts) are added to the 2013 clothes service when `pet/petride` starts, on every client.

### Bosses

`dailyactivity/dailyactivityservice` places the 守护者 and event bosses with
their own pictures (`dailyactivity/dailyboss<id>`), wakes them, plays their
films and talks (from the later conversation tables) and starts their
fights (`IPetFight.fightWithBoss`, `54_16`). The table of bosses, scenes and
forms is at the top of `DailyActivityService.as`; the server's is `GUARDIANS`
in `battle.ts`, and the wins count for 我的荣誉's 胜利数量 (`bossWins`).

The 念之塔 (黑暗念之塔) is the seals' scenes of 2011–12 (`scene/thinktowerof*`)
with `thinktower/thinktowerservice` (the later module's code compiled
against the 2013 interfaces, on its art) and its panel
`thinktower/enterpanel`; 幽冥大殿 (`scene/youanmingzhou2`, its later code on its
art) opens the panel. The server is `thinktower.ts` (`MentalHallExtension`).

The activities' fights (`PetClient2.startFight`, `54_22 {type, …}`) are added by
their modules with `addActFight` (`battle.ts`): the opponent, its level, what a
win gives, and for some a change to the player's 亚比 before the battle (修罗's and
凯撒's 祝福, 武神大陆's 将军令). The panels stay the era ones: 黑暗三连星 and 魔将挑战
(`sevenstar.ts`; 魔将挑战's two lost films are stand-ins of two empty frames,
`tools/blank_sprites.py`), 修罗 and 凯撒 of January 2013 and 召唤奇灵王 (its February
2013 copy compiled against the 2013 libraries) at 奇灵神树, whose 修罗 offers them
(`kingbosses.ts`), and 武神大陆's (`fightking.ts`; 吕布's and 刘备's from their 2014
copies). The gods of the 幻龙星系 (`godbosses.ts`): 天空之神, 施瓦辛格 and 波塞冬 from their
2014 copies, 魔龙之战 from its 2015 copy; their rooms' surviving files have the panels'
openers but no button any more, and the bosses stand where `baseservice/scenearrow`'s arrows
show the buttons were (拉诺斯 in 天神圣殿, whose 2012 room has none) and offer the panels
(the rebuilt `TaskNpcService` places them, `ScenePatches` gives their choice). An
activity's boss may bring helpers that come out one after another (`ActFight.team`, sent
as the opponent's switch, `2413` with `foe`). The 道馆's 最强防御PK战 (局 won by standing
their rounds, `Battle.insist`, sent by the rebuilt `insistFight`) and 玩偶迷阵 are
`gyms.ts`'s. 狼王再现 and 夜王回归 (`wnking.ts`) are the module of their 2016 copy
(`activity130221/wolfandnightking`) compiled against the 2013 libraries without its
later features, on the art of its own and its 2013–16 panels, opened by 狼王迪洛斯 and
夜王狄米特 at 魂塔顶端; their fights come through `addHandlerFight` (`54_22 {type: 99,
handler}`), and a 分身's trick (one of the player's 亚比 felled every fifth round, or
health back each round) is `Battle.boss`. The battle screen puts the open panels away when a battle starts
(`ModalDialogManager.clearAll`, as the era fight did); they show themselves again
at its end.

### 四大副本

The 2013 `fbservice` and `fbteam` modules are lost; their 2025 copies are
compiled against the 2013 interfaces, and the choose panel is rebuilt on its
2016 art. A run goes through the later `FBLoaderService` and `FBTeamService`
as a team of one; the rooms' own scripts run as they did. The server
(`fb.ts`, FBExtension `fb_1` to `fb_9`, fights through `54_17`) keeps the
rooms' 亚比 and fights, the modes, the entries a day and the rating.

### Mini games

`game/gamemanager` is the later GameManager on the 2013 interfaces: it
shows a game's entrance panel and loads the game into the scene layer
(`SceneManager.loadGame`). The score is sent with the client's own
encryption and paid in 晶币 by the server.

### Shops and money

The catalog books (`catalog/*`) page through the archived page SWFs; the
pages to show and their order come from `rebuild/gen/bconfig`. The buy flow
uses the original material services. 晶币 pay for ordinary goods; goods
priced in real money in 2012 are paid in 星币, which only the 工具箱 gives.
A page's 全套购买 (`btnSetBuy_<套装>`) buys the 2013 ClothesSuit's clothes one
lacks in one `buyBatchMaterial` (`61_4`, "tp,mi,qt;…", RECONSTRUCTED).

### Home, garden and zoo

The 家园 (`furniture/b000247`) is rebuilt from the January 2012 tutorial
picture of the garden, which shows the whole screen: the scene takes that
picture at run time without the tutorial's labels. Its bar (`GardenBar`)
draws over the picture's strip, its friends' cards on copies of the
picture's one sample card; the server is `garden.ts` (`revival_gardenbar`,
and the 友谊留言板 of `house/messageboard`, the later module's code on its
art). 我的荣誉 is the era `honour/honourservice` with the April 2013
`honour/honour_res` and the 280 `honouricon` pictures; the server is
`honour.ts`. The bar's 勋章 is the player card's 勋章 page (`usercard/usercard_badge`,
its later copy), its 勋章 from the server's `70-1` (`honour.ts`). The 植树盆 offers
the owner's 树苗 (`SaplingPicker`; bought in the 种植手册, kept by `plants.ts`); a tree's
panel is the rebuilt `yz/treemanager` (kept out of the stand-ins, `no-stub.txt`). A player's avatar in a picture (the garden's cards, the zoo's
动物园信息) is the rebuilt `useravatar/useravatarservice` (`mmo.revival.RAvatar`). The 小屋 is built by the
rebuilt `house/houseloader` from the player's house record. The 动物园
(`furniture/b020000`) stands on the art of a later copy with code for the
2013 engine.

### The 工具箱 and the 沙盒

Both are in the control module (`ToolboxPanel`, `SandboxPanel`,
`SandboxRun`) and talk to the server through `SundriesExtension`
(`revival_toolbox`, `revival_sandbox`, `revival_mod`). The 沙盒 runs mods:
SWF files written against the interfaces of `mmo.revival.mod`
(`rebuild/src/shared`). `ModRun` (control) loads a mod into an application
domain of its own and implements `IModGame`; `scene/sandboxroom`, a
code-only scene, shows a mod's rooms (`SandboxRoom` implements `IModRoom`).
A mod's 亚比 pictures reach the game's modules through `mmo.revival.RDef`,
which the bag, the 仓库, the battle screen, following and the rebuilt
`peticonservice` ask before the application domain. A 沙盒 team fought
"together" is one battle whose other opponents wait in `Battle.foes` (each
comes out as the one before falls, the end names the first, which the client
waits for). A mod's party with `vip` sets the 蓝宝石 of the record while it is
out (`ModParty.vip`: given back by `endModParty`), and the client's
`MemberManager` follows the reply. [MODDING.md](MODDING.md) has the API and
the details.

## Ruffle

The site uses Ruffle 0.7.1 from npm. Points to know:

- `FileReference.save` drops non-ASCII file names, so files the 沙盒 saves
  have ASCII names.
- The client's links are disabled (`openUrlMode: "deny"`).
- Sockets go through Ruffle's `socketProxy` to the emulator.

Faults in the client that Ruffle exposes are worked around in the rebuilt
modules, not in Ruffle.
