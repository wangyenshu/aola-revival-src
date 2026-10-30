# 奥拉星 2012 revival: archive and implementation plan

28 October 2026. Exported from the shared plan doc; the doc is the copy that gets edited.

## Summary

The original January 2013 client now boots in Ruffle, logs in, stands in 奥拉广场 and walks into six original scenes; almost everything a player does after that is still missing. This plan does two things in order: first secure every file on the live CDN that dates from 2013 or earlier, because the operator can replace or remove them at any time; then list each missing system (pets, home, shops, the clickable things in scenes, the interface, tasks) with what survives, what is lost, what the server must answer, and the order to build it.

One rule decides every file:

1. An original from the January 2013 release, or an older unchanged one, is used as is.
2. A lost module is rebuilt in ActionScript 3 against the surviving 2013 interfaces and marked REBUILT in its source and metadata.
3. A later copy is used only for pure art or data whose structure matches, and each such use is listed.

## Archive of the live CDN

Every file the live server (`aola.100bt.com/play/`) still holds from 2010–2013 is now saved: 18,368 files, 1.7 GB, byte for byte and checked against the server's sizes. By upload year: 377 from 2010, 4,258 from 2011, 7,854 from 2012, 5,879 from 2013.

| Game area | Files | MB | Examples |
| --- | --: | --: | --- |
| Pets and battles | 6,044 | 894 | battle animations `fightres/pet/pet{n}`, battle sprites, 1,823 pet icons, eggs, pet cards |
| Quests and NPCs | 2,639 | 279 | 1,064 NPCs `tasknpc/npc{n}`, quest scripts `taskext/task{n}`, quest panels and art |
| Activities and mini games | 1,017 | 191 | 2010–13 events, arcade games |
| Clothes and avatar | 5,378 | 124 | worn graphics, shop views and icons for 2012 clothes |
| Shops, catalogs, items | 1,715 | 79 | 462 catalog pages, 944 item views |
| Scenes | 378 | 76 | every 2010–13 scene still on the server |
| Mail, notices, music, home, other | 1,197 | 74 | 87 music tracks, furniture, mail paper |

How it was done (tool: `tools/live_archive.py`):

1. **Finding names.** Nothing lists old files: the live manifest (49,584 entries) names only files changed since its baseline, and the original 2011 `scene/restaurant` is in no list at all. 130,892 paths were tried, gathered from the captured manifests of 2012–14, the configs, Wayback URLs, decompiled code, strings inside every SWF, the 2013 material ids, and numbered name patterns over the 2013 range. Strings in the newly saved files were scanned again until a round found almost nothing (1,335, then 530, then 15 new files).
2. **Dating.** One HEAD request per path. The CDN keeps original upload dates: `skin/a000002` shows 27 Dec 2011, the date Flash wrote inside it, and none of the 16,158 dated SWFs contradicts its upload date beyond the one-day China/UTC offset.
3. **Re-uploads.** A cutoff alone misses old files re-uploaded later, so the 5,843 files that 2012/13 sources name but that were uploaded from 2014 on were saved too, in `_later/`, and sorted by their own dates: 62 still hold 2012/13 content (mostly a re-upload on 17 Oct 2024), 4,448 are later versions, 1,333 carry no date.
4. **Inventory.** `_meta/live-cdn-inventory-2026-10-28.jsonl` records all 130,892 answers (71,073 exist), with today's live manifest and config beside it. A future run that sees a changed ETag shows exactly what the operator replaced.

The upload dates also re-judged the files the game already uses: 587 files kept as later copies are originals after all (for example `control/userpack`, 2 Aug 2010, and the 快乐方舟 scene, 13 Jan 2011), and 26 need review.

Where it lives: `aola_archive_2013` on your computer (2.2 GB including `_later`; `tools/make_aola_archive.py` rebuilds it from the CDN while the CDN lasts). The files the game serves are in this repository's `game/` (`tools/make_game_root.py`, see the README).

## What works today

Everything below was run end to end in Chromium with Ruffle 0.7.1 (test script `server/test/e2e/boot2013.mjs`).

| Step | How | Files |
| --- | --- | --- |
| Boot and start screen | Original page scripts, start.swf, loader, version manifest of 25 Jan 2013 | Wayback originals |
| Login | Rebuilt `user/login`: connects, logs in, hands over to the game | Rebuilt |
| Entering the game | Rebuilt `play` loads 92 of the 95 play modules in the original order and starts 91 services | 25 originals, 64 rebuilt or stand-ins, 3 later asset files |
| 奥拉广场 | Rebuilt scene code on the July 2012 art (`bigscene/starlandcopy`) | Rebuilt code, original art |
| Your character | Original 2012 avatar service draws clothes from `skin/` | 3,038 original clothes graphics, 386 later |
| Walking | Click to walk, stops at the scene's obstruction layer, position shared through the server | Rebuilt engine |
| Scene changes | 种植园, 服装店, 道具店, 飞碟美食塔, 快乐方舟, 银河商会 open their original 2012/13 scenes | Originals |
| Server | 2013 room protocol, login, rooms, user variables, 13 startup inventory replies, saves in the browser | Rebuilt emulator |

The engine was written from a census of the 392 surviving era SWFs: it provides the 36 engine classes they reference, with the override signatures their bytecode requires.

## What is missing

Of the 293 services the January 2013 client defines (`mmo.interfaces.ServiceConfig`), 122 have an era original; 155 survive only as later rebuilds, which call classes the 2013 libraries do not have; 16 are gone entirely. 170 of the 171 without an original currently run as generated stand-ins that do nothing. The surviving 2013 client libraries name 682 server commands in 74 extensions; the emulator answers 13.

| Area | 2013 services | Era originals | Later copy only | Gone | Server extensions it needs (commands) | Effort |
| --- | --: | --: | --: | --: | --- | --- |
| Pets and battles | 57 | 25 | 32 | 0 | PetExtension (22), PetFightExtension (5), PetEggExtension (8), FightRingExtension (6), TowerExtension (13) | Largest |
| Interface: toolbar, chat, map, friends, mail | 33 | 2 | 25 | 6 | BuddyManagerExtension (13), MailBoxExtension (8), UserExtension (9) | Large |
| Home, garden, zoo, robot | 20 | 8 | 12 | 0 | HouseExtension (7), MaterialManager (7), ZooExtension (27), PlantExtension (10), RobotExtension (21) | Large |
| Shops, catalogs, inventory | 36 | 20 | 16 | 0 | MaterialExtension (34), GiftBagExtension (7), OldGoodsExtension (5) | Medium |
| Tasks and NPC talk | 12 | 4 | 8 | 0 | DailyTaskExtension (7), GuideExtension (4), TodayDoneExtension (6) | Large |
| Activities, mini games, other | 135 | 63 | 62 | 10 | Holiday, Sundries, Family (118), games, towers | Long tail |

The material services (clothes, furniture, items, eggs, cards) all survive as one original module, which is why shops start from a strong base.

## Pets (亚比) and battles

Pets are the heart of 2012 奥拉星 and the biggest gap: the panels mostly survive, but the data service, the following pet, wild pets and the whole battle client exist only as later rebuilds, and the battle rules lived on the server.

| Part | 2013 module | State | What it does |
| --- | --- | --- | --- |
| Pet data | `pet/petdataservice` | Later copy (1,798 lines decompiled) | Holds the player's pets; every pet panel reads it |
| Species data | `pet/petdictionarydata` | Later copy (5,769 lines) | Stats, types, skills per species; the later copy is a superset |
| Pet bag, info, dictionary | `pet/petpackage`, `pet/petpanelservice`, `pet/petdictionary` | Originals | The panels players open |
| Following pet | `pet/petfollow` | Rebuilt (2013 PetClient2 54_8 / 54_9, user variable `p`) | The pet walking behind you |
| Wild pets in scenes | `pet/wildpetservice` | Later copy (2,992 lines) | Pets to catch, wandering in scenes |
| Battle entry | `pet/loginpetfightnew` (PetFightService) | Later copy (11,714 lines) | `IPetFight`: 29 entry points (wild, boss, task, tower, arena) |
| Battle screen | `pet/petfightnew` | Later copy only (2014+ format) | Turn UI, skill buttons, capture |
| Eggs, training, fusion | `pet/peteggonlinenew`, `pethatchegg`, `pettraining`, `petmix` | Originals | Hatching, training, fusion panels |
| Battle art | `fightassets/pet{n}`, `fightassets/effect{n}`, `petfightbackground/*` | Being archived | Sprites per species and per skill effect |

Server commands the client sends: PetExtension (22), PetFightExtension (5), PocketMonsterExtension, PetEggExtension (8), FightRingExtension (6), TowerExtension (13).

Plan, in order:

1. **Pet data.** Rebuild `PetDataService` against the 2013 `IPetDataService`, porting from the later copy and dropping post-2013 fields. Server: a pet table per player (species, level, exp, skills, nickname, and whatever growth values the 2013 panels display) and the PetExtension list and update commands.
2. **Species data.** Cut the later `petdictionarydata` down to species that existed by January 2013 (the 2013 manifest's `fightassets/pet{n}` list bounds the ids) and keep it as the server's reference table too.
3. **Starter pet.** The newbie quest gives the first 亚比 (`taskres/task150res_newbiefightstart` survives); until tasks exist, the server grants one at first login.
4. **Pet bag and panels.** Load the original panels against the rebuilt data service and fix what they call.
5. **Following pet.** Rebuild `PetFollowService` on the engine's `ScenePlayer` and a `FollowSlowlyStrategy` (done: the 亚比 wears its scene "clothes" from `PetClothesMap`, e.g. 吉拉 → 20123 → `skin/a000123`).
6. **Battles.** Rebuild the battle screen and `PetFightService` against `IPetFight` and the surviving `PetFightClient` protocol; write the server's turn engine (speed order, skill power, type chart, catch rate). The rules are not in any client file: reconstruct them from the later client's damage preview code and published guides, and record each source.
7. **Wild pets and catching**, then eggs, training and fusion.

Exit check: start a battle against a wild pet in an era scene that has one, win, catch it, see it in the bag and walking behind you.

## Home (小屋)

The home has no scene file: config.xml maps room `home` to an empty swf, and `house/houseloader` builds the room from the player's house record and furniture. The loader, decorator, menus and storage exist only as later copies; their contract survives as the 2013 `library/houseinterfaces` (IHouseService, IHouseLoader, decorate, operate, berth), and the furniture data and graphics survive as originals.

| Part | 2013 module | State |
| --- | --- | --- |
| Contract | `house/houseinterfaces` | Original library (loaded today) |
| Home service and loader | `house/houseservice`, `house/houseloader` | Rebuilt (home SWFs' base `house/housecommon` too) |
| Decorating, menus, storage | `house/furnituredecorator`, `house/housemenu`, `house/housestorage` | Rebuilt; menu and storage drawn by the later art |
| Visiting, guest book | `house/houseinteractive`, `house/messageboard` | Later copies |
| Home extensions | `house/houseext` | Original |
| Furniture data | `FurnitureData` in `library/materialdata` (503 items) | Original |
| Furniture graphics | `furniture/b{id}` | Being archived (554 names tried) |
| Garden | `yz/plantdecorator`, `yz/treemanager`; plant data and `yz/fruitexchangeservice` | Later copies; data and exchange original |
| Zoo | `zoo/zooservice`, `zoo/zoodataservice`; `zoo/petbreedingservice` | Originals; breeding later copy |
| Robot | `robot/robotdateservice`, `robotmes`, `robotskillservice`; `robot/robotdecorator`, `robotitem` | Originals; decorator and items later copies |

Server commands: HouseExtension (7: house info, change house), MaterialManager (7: set house and garden furniture, validate), UserFurntitureInfoExtension (4), NeighborExtension (3), MessageBoardExtension (11), ZooExtension (27), PlantExtension (10), RobotExtension (21).

Plan:

1. Rebuild `houseservice` and `houseloader` against `IHouseService` / `IHouseLoader`, porting from the later copies; the HOUSE door in 奥拉广场 then calls `loadHouse(userName)`.
2. Server: a house record per player (house type, placed furniture with x, y, layer, flip) and the HouseExtension and MaterialManager furniture commands; give new players the default furniture the 2013 data marks free.
3. Rebuild the decorator (drag, rotate, store) and storage panel.
4. Visiting other players and the guest book, once more than one player can be online (needs the Node server mode, not the in-page emulator).
5. Garden, zoo and robot, reusing their original services.

Exit check: click HOUSE, arrive in your own home, place a sofa from storage, leave and come back to find it where you put it.

## Shops and the clothes store

The 服装店 scene itself is original and loads today; what is missing is everything its buttons open. Shopping in 2012 meant paging through a catalog book, clicking an item and paying in 晶币; the book engine and the buy flow (`catalog/catalogservice`, `catalog/bookclubservice`) are later copies, while the page artwork (`catalog/costume{n}`, `catalog/clothes{n}`, `catalog/tool{n}`, `catalog/yabi{n}`) is being archived and the inventory services are original.

What the 服装店 objects call, read from the original scene code:

| Object in the scene | Calls | State |
| --- | --- | --- |
| 星语流行服饰 (counter) | SellBookService.showPage("catalog201002") | Later copy |
| 时尚精品服饰 (VIP rack) | SellBookService.showPage("catalog201004") | Later copy |
| Fitting panel | IShowDataPanel.showPanelByData("17") | Later copy |
| 兜兜回收器 (buy-back machine) | StuffBuyBack.showPanel() | Later copy |
| 依依留言簿 (guest book) | IFeedbackService | Later copy |
| 《奥拉服装设计优秀作品》 | `bookshelfpanel/bookshelf5` | Original panel |
| Game machine | IGameManager mini game | Later copy |
| Exit | 流星购物街 (`starshopping`) | Later copy (scene redesigned) |

What already works: the clothes data (3,558 items), the clothes service that wears them, the avatar renderer, and the graphics for 3,038 clothes in their 2012 form.

Server commands: MaterialExtension (34: buy, batch buy, buy back, use item), MaterialManager.cmdSetUserClothes (wear), GiftBagExtension (7), OldGoodsExtension (5); money in 晶币 (ScoreManager: getTotalScore, increaseScore, decreaseScore).

Plan:

1. Rebuild the catalog book (`BookService`, `SellBookService`) against `mmo.interfaces.catalog`, porting from the later copy; it pages through the archived catalog page SWFs.
2. Rebuild the buy flow (`BuyMaterialService*`, buy dialog) on the original material services.
3. Server: money, owned items, buying (price from the 2013 data), wearing (`cmdSetUserClothes` rewrites the "avatar" variable so others see the change).
4. Wardrobe: the clothes part of the user pack (`control/userpack`, original) to change outfits.
5. Tool shop and furniture shop on the same book engine; buy-back last.

Exit check: in 服装店, open 星语流行服饰, buy a shirt, wear it, and see it on your character in 奥拉广场.

## Clickable things in scenes

The scenes look complete but their objects mostly do nothing yet, because what they open is a stand-in. Across the 233 era scene files there are 308 click handlers, 25 walk-up-and-use targets, 220 exits and 355 tooltips; exits already work. The NPCs players remember are not in the scene files at all: `TaskNpcService` places them (`tasknpc/npc{n}`), and it is a later copy, which is why scenes look empty of characters.

Services the era scenes call, by how many scenes call them:

| Service | Scenes | 2013 module | State | What players see when it works |
| --- | --: | --- | --- | --- |
| SceneArrowService | 35 | `baseservice/scenearrow` | Later copy | Arrows pointing to quest targets |
| TeamService | 31 | `team/team` | Later copy | Team (队伍) checks before entering |
| TaskNpcService | 25 | `task/tasknpc` | Later copy | NPCs standing in scenes, their talk bubbles |
| PetFightService | 24 | `pet/loginpetfightnew` | Later copy | Battles started from scene objects |
| TaskService | 21 | `task/taskservice` | Later copy | Quest state that unlocks objects |
| GatherService | 25 | `gather/gather` | Original | Gathering points (fruit, ore) |
| GameManager | 16 | `game/gamemanager` | Later copy | Mini games behind arcade machines |
| MaterialGetPanel | 13 | `material/materialservice` | Original | “You got …” reward pop-ups |
| PetDataService | 12 | `pet/petdataservice` | Later copy | Checks on your pets |
| YaYaLeService | 12 | `activityres/yayaleservice` | Original | 佢牙乐 activity |
| RobArenaService | 11 | `robarena/robarenaservice` | Later copy | 夺牌竞技场 |
| RobotDataService, UnicornService, ItemService, ArrowGuideService | 6, 6, 6, 5 | various | Originals | Robot, unicorn star, items, guide arrows |

Scenes also load 35 panels directly (`activityres/…`, `bariconpanels/…`, `occupation/…`) and start 4 mini games by name. One scene classed as era references `activityres/activity150612/…`, so it is really a 2015 file without a date stamp; the archive's upload dates will reclassify such files.

Plan:

1. Make every dead click visible: stand-ins already log their first call; add an on-screen “还没有修复” notice naming the service, and a report of which scenes call which stand-in.
2. Rebuild TaskNpcService first: it brings the NPCs back into every scene and is shared with tasks.
3. Then SceneArrowService, TeamService (single-player team rules), GameManager, each ported from its later copy against the 2013 interface.
4. Give the original services (Gather, MaterialGetPanel, YaYaLe, Robot, Unicorn) their server commands.
5. Re-check every one of the 233 scenes with an automated walk-through: enter, click every tooltip object, record what opens, and list the failures.

Progress (October 2026): dead clicks on stand-ins now show 这个功能还在修复中; gathering works in the 27 scenes that have gathering points (the original GatherService, with a rebuilt beam effect and the server's 14_14 / 14_11); the play-time limit (antiaddiction) is rebuilt as never used up; upside-down scenes (海文3, 海文4) and the later engine helpers that re-uploaded scenes call are rebuilt. 67 of the 69 places on the world map open; summerhotspring and one other still need classes from lost activity modules.

## Interface: toolbar, chat, map, friends

The screen around the scene is almost entirely lost: of 33 interface services only `control/userpack` (the bag) and the user-card badge panel are originals. The 2013 bottom toolbar (`control/iconbar`, 130110) carried its own artwork, so the later copy shows a later bar; matching the 2012 look needs screenshots or video of the 2012 bar as the reference.

| Part | 2013 module | State | Notes |
| --- | --- | --- | --- |
| Bottom toolbar | `control/iconbar` | Later copy (6 classes) | Shortcut buttons; which ones the 2013 bar had is to be confirmed from 2012 references |
| Bag and wardrobe | `control/userpack` | Original | Opens from the toolbar |
| Chat input and bubbles | `talk/talk`, `baseservice/scenetalk`, `baseservice/face` | Later copies | Public chat goes over the room protocol (PubMsg), already emulated |
| World map | `map/map`, `map/somegalaxy1`, `map/galaxy5` | Later copies | `map/galaxy1` (star map) and `galaxy6` are undated era-format copies |
| Newbie map | `control/newbiemap`, `control/newbiemapext` | Later copies |  |
| Friends | `buddylist/buddylist`, `buddylist/buddydoc`; `buddylist/buddyagent` | Later copies; one gone | BuddyManagerExtension (13 commands) |
| Mail | `mailbox/mailboxservice`; `mailbox/mailbox` | Later copy; gone | MailBoxExtension (8) |
| Notices, offline messages | `baseservice/notify`, `notifyview`, `msg/notifyinit` | Later copies |  |
| Message centre | `baseservice/msgctrl`, `msgdoc`, `msgview` | Gone |  |
| Player card | `usercard/usercardservice` | Later copy | Click another player |
| Corner icons | `baseservice/iconservice`, `sceneicon/sceneiconservice` | Later copies | Activity icons top left and right |

Plan:

1. Collect visual references for the 2012–13 screen (Wayback captures of the news site, 4399 and 7k7k guide pages, video uploads from 2012) and record each source with its date.
2. Rebuild the toolbar against `IIconBarService`, using era art where it survives (`baricons/`, `bariconpanels/`, `library_res/common_res_*`) and drawing only what is missing, marked as such.
3. Chat: input box, bubbles over heads (the engine's player has `say()` ready), the 2013 bad-word list (`init/badwordsdat`, later copy of a data file).
4. World map: rebuild `map/map` around the era star map `map/galaxy1`; scene buttons go through `SceneManager.loadScene`.
5. Friends, mail and the player card once the Node server mode with several players is in use.

## Tasks, NPC talk and the newbie quest

Quests are split between a lost engine and surviving content: the 2013 task engine, NPC placement and task panel survive only as later copies, while each quest's own panel and art are separate files the archive collected (`taskpanel/tp{n}`, `tasknpc/npc{n}`, `taskres/…`). The newbie quest's scripts (`taskext/task135`, `task140`, `task150`) were replaced on the server by later versions; most story-quest scripts of 2011–12 were never replaced and survive as era files (the 巨人山脉 ones of 8 March 2012, for instance).

What runs now (M4):

| Part | Module | State |
| --- | --- | --- |
| Task engine | `task/taskservice` | REBUILT against `mmo.interfaces.task` and the 2013 TaskExtension protocol (10-0 tasks at login, 10-1 updates, 10-2 step done, 10-3 start, 10-4 drop, 10-5 task data) |
| Task definitions | `task/taskdefines` | REBUILT: tasks 135, 140, 150 and their steps, as the era task panels name them; the 2012 story quests from the later definitions (below) |
| Task scripts host | `task/taskextmanager` | REBUILT: per scene, the scripts the later scene table (config `tconfig`) names for a task being done or one that can start, kept until the scene goes; the rebuilt newbie scripts while their task is being done |
| Task transport | `task/tasktransportpanel` | REBUILT (lost): the 任务传送 panel scripts open to send the player on (立即前往 / 稍后再去) |
| Task icon and panel | `task/taskpanelnew` | REBUILT around the era `mmo.taskicon.TaskIcon` (任务, with a "!" when a task arrives) and the era panels `taskpanel/tp{n}` |
| NPCs and talk | `task/tasknpc` | REBUILT: task talk with choices, actions and scene changes, a bobbing "?" over an NPC with something to say |
| Newbie quest | `taskext/task135`, `task140`, `task150` | REBUILT (below) |

The newbie quest follows the official walkthrough of 19 December 2011 (`renwugonglue/3073`, saved under `refs/newbie-quest-2011`) and the era task panels:

| Step | Where | What |
| --- | --- | --- |
| 136 | anywhere, then 指挥中心 | the HELLO sends the new player to 司令官麦哲伦: the 达斯特 attack the ship |
| 137 | 指挥中心 | choose the first 亚比: 滴滴, 吉拉 or 兔小子 |
| 138 | 机械废墟 (junglecopy) | the VS film, then a lesson fight against the 达斯特's 达达; the film of the 达斯特 driven off |
| 139 | 指挥中心 | 麦哲伦 on the 奥拉之辉 (his line and both answers are those of the walkthrough's screenshot); its story as three era films, or skip it |
| 142 | 亚比研究中心 | 贝鲁特博士 sends the player for 亚比球 |
| 143 | 道具店 copy | buy 5 普通亚比球 from 米娜 (the 2013 buying panel) |
| 144 | 亚比研究中心 | 贝鲁特 teaches catching |
| 145 | 冰河瀑布 (aixiscene2) | catch a 朵朵兔; a red arrow points at one |
| 146 | HELLO学院 copy | 普伦博士 gives the HELLO |
| 147 | HELLO学院 copy | the era film of what a HELLO does |
| 152 | 指挥中心 | the ceremony film; 2000 晶币 and 3000 HELLO experience |

Words not seen in a screenshot are RECONSTRUCTED. The server keeps each player's tasks (`server/src/game/sfs2013/tasks.ts`): steps in order, 140 and 150 start when the one before ends, new players get 135 at login, the newbie fight is a lesson (the 达达 is at most Lv2 and only attacks; the 2013 rule is lost), and ordinary 亚比球 work on easy 亚比 before they are down to a fifth of their HP (on the 捕获度 0 朵朵兔 at any HP: the walkthrough says “朵朵兔很容易捕捉，扔扔亚比球就可以”). The HELLO is RobotExtension 2-11/2-0/2-12. `server/test/e2e/scenarios/newbie.mjs` plays the whole quest in the browser.

Later copies the quest uses, because no 2013 one survives: `tasknpc/npc1` (HELLO), `npc9` (麦哲伦), `npc11` (贝鲁特, live copy of 30 Nov 2017), `peticon/peticon1` (兔小子, live copy of 5 Mar 2020), `scene/maintown2` and `scene/yabistudy` (standing in for `maintown2copy` and `yabistudycopy`), `taskres/task147res_reword0–2`. The 朵朵兔's scene skin (`skin/a000059`) is in no archive: wild 亚比 without one stand in as their era large icon.

### The 2012 story quests

After the newbie quest the task panel lists the story quests of 2011–12 under 可接, and 前往 takes the player where each begins. They run their own scripts (`taskext/task{n}`), with the NPC conversations and definitions of the later client, because the 2013 ones are lost:

- `tools/gen_tasks.py` takes from the later `task/taskdefines` (24 January 2013 build, the copy in `game/`), `task/tasknpc` and config `tconfig` the quests whose script was made by the January 2013 release (its id is at most that of the newest era script), whose conversations survive for at least half their steps and whose scripts are all in `game/`, with every quest before them. 45 quests, 327 steps: 烈焰鸟 (267–346), 上古神殿 (724), the 星云 arc (1039–1155) and its side stories, 巨人山脉 (1214–1294), 蔓藤峡谷 (1343–1427), the 古老的传说 arc (1434–1477), 钻石岛 (1507–1549), 幽暗冥州 (1561–1641), and 1959, 2072, 2289. It writes `rebuild/gen/taskdata` (definitions, starters, panels, the scene table), `rebuild/gen/tasknpc/…/TaskTalkData.as` (764 task conversations, 26 start conversations) and `revival/tasks.json` for the emulator, which then keeps their steps like the newbie quest's.
- The scenes of most of these quests were off the map by November 2012, so neither the January 2013 `config.xml` nor the archive has them. `tools/story_files.py` adds what they need from the live CDN as later copies (re-exports of 2015–2019, the same rooms): 28 rooms (巨人山脉 `giantcordillera1–6`, 幽暗冥州 `youanmingzhou1–5`, 钻石岛 `diamondisland1–4`, 蔓藤峡谷 `mantenxiagu1–3`, 章鱼海湾 and its neighbours `starsea1–3`, 斗魂平原 to 禁闭之门 `fightspace1–3`, 虚无长廊 and 修炼广场 `emptyspace1–2`, 念之大厅, 水帘洞), with their rows of the live `config.xml` in the overlay, and 87 files in all (scenes, NPC pictures, task panels, scripts the 2013 client lacks, resources the scripts name), each listed in `game/FILES.jsonl` with `"added": "story quests"`.
- `tools/gen_npc_data.py` places the NPCs of those rooms from the later scene table; in the rooms of 2013 an NPC with only a later picture stands only while a story quest has something for it to say.

`server/test/e2e/scenarios/story1214.mjs` (`npm run e2e:story`) plays the first two quests of 巨人山脉 through, as a player would: 1214 传说中的美丽山脉 (小犀 at the mountain's foot, 麦哲伦, 小南 in the library, 普伦博士, the footprint, the film of the giant and the mini game of pumping up the HELLO with the Space key) and 1219 奇怪的山脉 (waking in 小熊之家, the blueprint, the stones and the hole in the roof, finding wood, saw and nails, dragging the ladder together, the fight with 伊尼, out to 巨人山脚 and back, 普伦博士's message), after which 1237 山脉传说 begins. `server/test/e2e/scenarios/storysmoke.mjs` goes to each of the 26 quests that begin with an NPC and opens its start conversation (all 26 open).

Engine pieces the story scripts needed, all in the rebuilt modules: scripts stay loaded until the scene goes (one waits for the reward of the task it has just finished); every scene announces its NPCs (TaskEvent.ON_INITED_NPC), with or without any of its own; the 任务传送 panel; task NPCs placed per scene; the emulator runs one player's requests one after another (two at once lost a change).

Still to do:

1. The HELLO in scenes and its ring menu (`init/robotmanager` survives only as a later copy), and handing out its experience (RobotExtension 2-13).
2. Play the other story quests through: 1214 and 1219 are checked end to end; the rest run on the same pieces, and some use services still stood in for (sending, items, other fights).
3. Daily tasks (`dailytask/dailytask`, DailyTaskExtension 7 commands), the NPC guide (`guide/npcguide`, original), gathering tasks (`task/taskgather`, original).

## Server emulation

The client's half of every conversation survives; the server's half does not, so each command is rebuilt from what the client sends and what its handler reads back. The 2013 room protocol (login, rooms, user variables, chat, extension calls in AMF3) already works; the work now is the 682 extension commands and the game state behind them.

How each command gets built:

1. **Generate a protocol catalogue** from the decompiled client: for every command constant, the extension, the parameters sent, the event the reply is dispatched as, and the fields the listening code reads (`param1.params.cl`, `.furnitures`, …). The 13 startup replies were found this way by hand; a tool makes it systematic and is the checklist for the rest.
2. **Answer with the right shape first** (empty lists, zero counts), so the client finishes loading and logs what it asks; fill in behaviour per subsystem as its milestone comes up.
3. **Rules the client never knew** (battle damage, catch rates, drop tables, task rewards, daily limits) are reconstructed from the client data (prices and item stats are in `library/materialdata`), the later client's code, and published 2012–13 guides; each rule records its source.

State to keep per player: id, name, outfit, 晶币 and other counters, owned items by type (clothes, items, furniture, cards, eggs, plants), pets, house layout, quest progress, friends, mail. Saves live in the browser (IndexedDB) for the offline copy, and in files for the Node server.

Two run modes stay supported: the in-page emulator (one player, no install) and the Node server (several players over the WebSocket bridge), which friends, visiting and shared chat need.

## Engine fidelity

The rebuilt engine passes every scene tried so far, but it was written from decompiled source, which hides one thing that matters: which namespace each member lives in. 快乐方舟 failed until `startVisionService` moved from protected to public, because the 2013 bytecode calls it in the public namespace. The same class of fault can hide in any of the 392 era files.

Work list:

1. **Namespace and signature audit.** Export the bytecode (pcode) of all 392 era SWFs, list every reference into `mmo.play.*` with its namespace (public, protected of which class, internal) and its call shape, and diff that against the rebuilt classes. Any mismatch is a crash waiting for the scene that uses it.
2. **Classes still thin or missing:**
   - `FlipSceneBase` (海文 3 and 4), `ScenePetAvatar`, `Player`'s moving states (riding, flying)
   - path finding behind `setMapArray()` (5 scenes walk around obstacles with it)
   - mini games: `DocGameBase`, `SceneManager.loadGame` / `unloadGame` (38 game SWFs subclass it)
   - instance dungeons: the `FBSceneBase` flow (41 scenes) with `loadFB` and team rules
   - `SceneCommandStep` commands, `BigSceneEvent.SCROLLRECT_CHANGE`, `ActionHelper`, `Panel_Helper`
3. **Automated scene walk-through** over all 233 era scenes: enter, stand, click each tooltip object, screenshot, record errors. Run it after every engine change.
4. **Ruffle gaps.** Track the AVM2 features Ruffle stubs that originals use (seen so far: weak-key Dictionary, `Loader` add-child timing, `System.totalMemoryNumber`) and keep a Ruffle version pinned per release.

## Milestones

Each milestone ends in something a player can do, checked by the automated test before the next starts; the order follows the core loop of 2012 play: town, shop, quest, first pet, battles, home.

| Milestone | Exit check | State |
| --- | --- | --- |
| M0 Archive | every live file from 2013 or earlier saved on your computer | done (`tools/make_aola_archive.py` rebuilds it locally) |
| M1 Town | log in, walk, and enter six original scenes | done |
| M2 Living scenes | NPCs in scenes, toolbar, chat bubbles over heads | done (the bar is drawn; its 2011 look is known from official screenshots) |
| M3 Shop and wardrobe | buy a shirt in 服装店 and wear it in 奥拉广场 | done |
| M4 Newbie quest | finish the 2012 quest and receive the first 亚比 | done: the whole quest (136–152) with its era panels and films, the first 亚比, the first fight and catch, the HELLO; 45 story quests of 2011–12 with their own scripts (1214 and 1219 checked end to end); the HELLO in scenes to do |
| M5 Battles | win a battle against a wild 亚比 and catch it | done for wild 亚比: they walk in 73 era scenes; win, lose, escape, items, switching, catching into the bag (battle screen after the official 2011–12 screenshots; rules reconstructed); bosses, PvP and arenas to do |
| M6 Home | place a sofa in 小屋; it is still there next visit | done for the 空间舱 (furniture, storage, saving); garden, visits, zoo to do |
| M7 Map and friends | world map; two players see and visit each other | world map done |
| M8 Long tail | activities, mini games, arenas and instances | |

M2 comes first because NPCs and the toolbar are shared by every later milestone; M5 is the largest single piece (battle screen plus the server's turn engine).

## Risks and open questions

| Risk | Effect | Mitigation |
| --- | --- | --- |
| The live CDN changes or closes | Era files that survive nowhere else disappear | Archive now (done in this pass) and keep the copy on your computer; re-run the archive tool every few months and diff |
| The cloud workspace is temporary | Anything left only there is lost | Every result is moved to your computer before a session ends |
| Server rules are gone | Battles, rewards and prices of services can only be reconstructed | Record a source for every rule; mark reconstructed numbers in the server code |
| Later copies pull the game forward | Porting a 2016 module brings 2016 features | Port behaviour, never content; strip post-2013 calls; list every later asset used |
| Lost interface art | The toolbar, map and panels cannot look exactly like 2012 without references | Collect dated 2012–13 screenshots and video before drawing anything |
| Undated files misclassed as era | A 2015 scene can pass as 2012 (one found) | Use upload dates from the archive to reclassify every file |
| Ruffle gaps | An original module may fail on a stubbed Flash feature | Automated scene walk-through; report or patch Ruffle |
| Scope | 135 activity and mini-game services | Finish the core loop (town, shop, quest, pet, battle, home) first |

Open questions:

- [ ] What did the 2013 server give a new player: outfit, 晶币, first pet? The revival uses the 酷蓝 set for now.
- [ ] Where were the exits of the January 2013 奥拉广场? Only the arrival keys of its neighbours survive.
- [ ] Which buttons did the January 2013 toolbar have?
- [ ] Is the real 6 Dec 2012 manifest anywhere? A copy named `versiondata.swf?121206` was today's live manifest and is not in `game/`.
- [ ] Is a single-player offline copy the goal, or the Node server with friends?
