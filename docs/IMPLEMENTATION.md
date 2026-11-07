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
- `date`: the game clock anchor, 2012-08-15 China time.

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
when the login connects: to the in-page game, or to the chosen server.

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
| `core/clock.ts` | the game clock |
| `core/store.ts` | key-value store interface (IndexedDB in the page, JSON files in Node) |
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
extension name and command (`PetExtension.54_16`).

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
| `yabistudy.ts` | 亚比研究中心's 亚比融合 (and its 孵化器) and 天赋启迪 |
| `sandbox.ts`, `mods.ts` | the 沙盒's fights; mods' saved data, 亚比 and gifts |
| `petcards.ts`, `petitems.ts`, `giftbags.ts` | 战术卡, 亚比道具, what each 礼包 holds |
| `host.ts`, `accounts.ts`, `api.ts`, `saves.ts` | the game for any host; names and passwords (the lock on wrong ones); the shared server's small API; 存档 files, and the page's own 奥拉 |
| `social.ts`, `duel.ts` | 好友, 组队, where a friend is; 亚比对战 between players |

Each player is one record: name, outfit, 晶币, 星币, 晶豆, items by type,
亚比 (bag and 仓库), house and furniture, garden and zoo, quests, bosses
beaten, daily counters. In the page the records are JSON values in the
IndexedDB database `aola-revival`, store `kv`; the Node server writes JSON
files under `work/`.

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
  strong "越少越大" grows, is a guess. A 回复 is shown whole, though the 体力
  stops at its maximum; 嗜血之矛's heal past it becomes 护盾 points, which take
  the next blows. A 蓄力 or 连续攻击N回合 skill goes on by itself (the player
  chooses nothing on those turns); a 连续攻击N回合 skill's power grows each
  turn of the N, starts again with its next use, and a miss takes the growth
  back (save 不管命中与否); "使用千军万马后威力大大提升" doubles it. With no PP
  left, the player's 亚比 uses 挣扎; the computer's (wild ones, bosses, 副本,
  时空隧道, quests, 道馆) take a 高级活力豆 instead, of which they have no end:
  their turn goes on it (20 uses back on every skill) and they fight on.
  A 自动战斗仪 battle ends by itself, won or lost, and gives every 亚比 of the
  bag all its 体力 and PP back, so that the next one can come.
- **Catching**: an ordinary 亚比球 works once a wild 亚比 is down to a fifth
  of its HP, earlier for easy species, at any HP for the 朵朵兔 (as the 2011
  walkthrough says); better balls raise the chance.
- **Task 亚比**: fight at the level of the player's strongest 亚比 (two more
  for each further variant) and cannot be caught.
- **Bosses**: levels from the 2013 `BossTimeHelper` table where present,
  estimates otherwise; only beating the last form gives the egg.
- **Rewards and limits**: mini games pay 1 晶币 per 10 points (200 a game,
  1,000 a day); 副本 levels, chests, pay and rating; the 道馆 skill stones;
  the 财富小管家's interest (from 百田's guide); prices in 星币 for
  real-money goods (half for 蓝宝石).
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
| `control` | the control bar, the engine classes (see above), the 工具箱, the 沙盒, the 物品 panel, the place picker, the debug hook |
| `play`, `login` | the boot modules |
| `shared` | code compiled into several modules: `mmo.revival.*` (logging, JSON, base64, UI drawing, `RDef`), the mod API `mmo.revival.mod` |
| `scenes` | rebuilt scenes: 奥拉广场 and 流星购物街 (`starland`), 主题公园, 亚比研究中心, 奥拉之树, 生态园, 十字大道, 图书馆, 欢乐岛, 烈焰洞穴 (`feier4`), 崩坏的上古神殿 (`temple1`), 道具店, 奇草树林, the 沙盒 room |
| `tasknpc`, `taskservice`, `taskdefines`, `taskextmanager`, `taskpanelnew`, `tasktransport`, `taskext` | NPCs, conversations and the quest engine; the newbie quest's scripts |
| `pet`, `petpackage`, `newpetpackage`, `petwarehouse`, `petfollow`, `petride`, `peteggservice`, `pethatchegg`, `petskillmes`, `pmservice`, `petfight`, `wildpet`, `peticonservice`, `peticonfill` | 亚比 data, the 亚比 tables (PMService), the bag (and the "PetPackage" service that opens it), the 仓库, following, riding, eggs, the battle screen and battle entry, wild 亚比, 亚比 pictures |
| `dailyactivity` | the 守护者 and event bosses, the planets' activities |
| `fbservice`, `fbteam`, `fbchoosepanel` | the 四大副本 (later code on the 2013 interfaces) |
| `spacetime` | 时空隧道 (later code) |
| `catalog`, `bconfig`, `buyback`, `rmbmall` | the catalog books, the buy flow, the 兜兜回收器, the 商城 |
| `catalogpages` | the 收费亚比蛋商品册's first page (catalog/egg1), on its 2016 art |
| `house`, `housecommon`, `garden`, `zoo` | the 小屋, the 家园, the 动物园 |
| `gamemanager`, `parkour` | mini games; 酷跑星世界 |
| `shoot`, `shooteffect` | 射击 (later code on the 2013 interfaces) |
| `usercard`, `face`, `scenetalk`, `helloicon`, `robotmanager`, `map`, `weekly`, `notifyview`, `scenearrow`, `sceneinit`, `fortunemanager`, `antiaddiction`, `yakestarpanel` | the player card, faces, chat, the HELLO, the world map, the 奥拉周刊, notices, scene arrows, scene music, the 财富小管家, the play-time limit (never reached), 巨锁石灵's panel |

### Stand-ins

For every 2013 service whose module is lost and not yet rebuilt,
`tools/gen_stubs.py` generated a class with the original name and interface
(`rebuild/gen/stubs/`, 147 modules). Every method returns an empty value and
logs its first call (`[rebuilt] stub called: …` in the browser console). A
click that reaches a stand-in shows 这个功能还在修复中.

### Using later code

Some modules survive only as later uploads (2014 and after), which call classes
the 2013 libraries do not have. They are handled in these ways:

- **Recompiled**: the decompiled later code is compiled against the 2013
  libraries, with later-only calls replaced or removed and marked
  (`shoot`, `fbservice`, `fbteam`, `spacetime`, `parkour`, several scenes).
- **Later interfaces kept**: where a later script calls a method through a
  later interface, the rebuilt service defines that method in the later
  interface's AVM2 namespace, so the unchanged script finds it.
- **Renamed calls**: `tools/abc_rename.py` renames one string in a SWF's
  bytecode; 14 later mini games call `SocketClient.startGame`, which the 2013
  library lacks, and now call a harmless method instead.
- **Transplanted**: `tools/swf_transplant.py` puts compiled code into an
  original SWF's art, binding the art's symbols to the new classes (the art's
  own classes are renamed `…Revived` so they do not shadow the new ones).
- **Filled pictures**: `tools/peticon_fill.py` gives `peticon` files without
  a small picture one made from their large picture.

### Build output

`npm run build:swf` writes 257 files into `build/rebuilt/` at their 2013 URLs.
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
as its large picture, and sprites without a back view are mirrored. Boss
films (`bossfightmovie/boss<id>`) play when the battle opens and at the HP
thresholds the later client used.

Wild 亚比 (`pet/wildpetservice`) walk in 123 rooms; the list per room comes
from the November 2012 world map and the later location table. The
following 亚比 wears its walking figure (`PetClothesMap` → `skin/a0<id>`)
or, without one, its large picture. Riding (`pet/petride`) draws the ride's
two layers under and over the raised rider.

### Bosses

`dailyactivity/dailyactivityservice` places the 守护者 and event bosses with
their own pictures (`dailyactivity/dailyboss<id>`), wakes them, plays their
films and talks (from the later conversation tables) and starts their
fights (`IPetFight.fightWithBoss`, `54_16`). The table of bosses, scenes and
forms is at the top of `DailyActivityService.as`.

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

### Home, garden and zoo

The 家园 (`furniture/b000247`) is rebuilt from the January 2012 tutorial
picture of the garden, which shows the whole screen: the scene takes that
picture at run time without the tutorial's labels. The 小屋 is built by the
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
`peticonservice` ask before the application domain. [MODDING.md](MODDING.md)
has the API and the details.

## Ruffle

The site uses Ruffle 0.7.1 from npm. Points to know:

- `FileReference.save` drops non-ASCII file names, so files the 沙盒 saves
  have ASCII names.
- The client's links are disabled (`openUrlMode: "deny"`).
- Sockets go through Ruffle's `socketProxy` to the emulator.

Faults in the client that Ruffle exposes are worked around in the rebuilt
modules, not in Ruffle.
