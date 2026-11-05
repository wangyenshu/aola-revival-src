# Player guide

This guide covers playing the revival: starting, the control bar, saves, and
the two tools the revival adds to the game, the 工具箱 and the 沙盒. What the
game contains is listed in [FEATURES.md](FEATURES.md).

## Starting

Open the site. The page starts a service worker and the server emulator and
shows its own start screen (单机模式 / 联机模式: 进入), then the original
one; click 开始游戏 and, in 单机模式, make an 奥拉 on the 选择奥拉 screen
(新建奥拉). You arrive in 奥拉广场, where the newbie quest begins: the HELLO sends
you to 司令官麦哲伦 in the 指挥中心, you choose your first 亚比 (滴滴, 吉拉 or
兔小子), fight, buy 亚比球, catch a 朵朵兔 and receive the HELLO. After the
quest the task panel (任务, top right) lists the story quests under 可接, and
its 前往 button takes you to where each one begins.

The game runs at its original size of 960 × 560. Its clock starts on
15 August 2012 each time the page is opened and then runs at normal speed.

## Saves

Progress is saved automatically. In 单机模式 it is in the browser's
IndexedDB, separately for each site address: clearing the site's data in the
browser deletes it, and a different browser or computer starts from the
beginning. In 联机模式 it is on the server (docs/MULTIPLAYER.md).

### 选择奥拉 (单机模式)

In 单机模式 the start screen only asks for the mode. After 开始游戏, the 选择奥拉
screen shows this browser's 奥拉: up to three, each with its own name (no two
the same).

| On a card | |
| --- | --- |
| 进入 | play this 奥拉 (the one played last is marked 上次玩的) |
| 改名 | a new name, written in the card; refused if another 奥拉 here has it |
| 导出 | a file of this 奥拉 |
| 删除 | asked in the card (删除 / 取消, with 先导出一份); it cannot be undone |
| 新建奥拉 (an empty place) | a new 奥拉: write its name |

导入奥拉 takes a 存档 file (of either mode) as one more 奥拉: a file with several
asks which one; a name this browser already has asks whether to replace that
奥拉's game with the file's (替换) or to bring it in under a new name. With three
奥拉 here, delete one first. 全部导出 writes every 奥拉 of this browser into one
file.

### Name and password in the game

Your own 信息卡 (the bar's 信息卡) has 改名字 and, in 联机模式, 改密码. 改名字
takes a new name (refused if another 奥拉 has it; in 联机模式 the password is
asked), ends the game and comes back into it with the new name. 改密码 asks for
the password now and the new one twice; the game goes on.

### 存档 in the 工具箱

To keep or move this 奥拉's save, use 存档 in the 工具箱. Both modes write the
same kind of file (`aola-revival-save`), and either mode reads a file of
either:

- 导出存档 downloads a file of the 奥拉 you play (in 联机模式 the password is
  asked).
- 导入存档 reads a file and replaces this 奥拉's game with the file's (its name,
  and in 联机模式 its password and friends, stay); a file with several 奥拉 asks
  which one. The game ends and comes back. A server's owner can close 导入存档
  (`--no-toolbox`). To bring a file in as another 奥拉 of this browser, use
  导入奥拉 on the 选择奥拉 screen.

## The control bar

| Button | What it does |
| --- | --- |
| 地图 (bottom left) | The world map of November 2012; click a place to go there. In a 副本 it opens the 副本's map, in 黑星堡垒 it leaves. |
| 发言 | Ready-made phrases to say. |
| 表情 | Faces shown over your head. |
| 动作 | Actions your character performs. |
| 射击 | Shooting with 射击卡. 光能射线 and 冰冻射线 are free; the other cards are bought in 道具店 and used up one per shot. |
| Chat box | Type and send a message. The button beside it shows the recent chat. |
| 信息卡 | Your player card with the wardrobe: click clothes to put them on or take them off. |
| 好友, 组队, 战队 | 好友 and 组队 in 联机模式 (docs/MULTIPLAYER.md); 战队 is not available. |
| 亚比 | The 亚比 bag: details, 恢复 (heal), 更换技能, 坐骑, 跟随, the 亚比仓库. In the 仓库 a click moves a 亚比 between the bag and the 仓库; 放生 (added by the revival), then a click on a 亚比, asks 是否放生该亚比？: 是 releases it for good, 否 does nothing. The last 亚比 of the bag cannot be released. |
| 物品 | Everything collected: 道具, 亚比蛋, 种植, 射击卡. |
| 回家 | Your 家园 (garden); 我的家 there leads into the 小屋. |
| 商城 (cart) | The 收费 catalogs (服装, 道具, 家具, 亚比蛋), bought with 星币. |
| ♪ | Music on or off. |
| 任务 (top right) | The task panel. |
| 图鉴 (under 任务) | The 亚比图鉴: every 亚比, by 属性 or by name; those you have fought (发现) and owned (收集) show their details. |
| 工具箱, 沙盒 (right) | The revival's tools, described below. |

Money: 晶币 are earned in the game (battles, mini games, quests). 星币 stand
in for the real-money currency of 2012; the revival has no payment, so 星币
come only from the 工具箱. 蓝宝石 (the membership) halves 星币 prices and
opens members-only goods; it is switched on in the 工具箱.

## 工具箱

The 工具箱 was not in the 2013 game. It is meant for testing and for players
who want to skip collecting. Open it with the 工具箱 button on the right of
the screen.

| Section | Use |
| --- | --- |
| 晶币, 星币, 晶豆 | Enter an amount and click 增加. Each total is capped at 9,999,999. 晶豆 is a later currency; the server keeps it but no 2013 shop uses it. |
| 亚比经验 | Enter an amount and click 增加. The experience goes to the first 亚比 of the bag, which levels up, learns skills and evolves as after a battle. |
| 成为蓝宝石 / 取消蓝宝石 | Switch the 蓝宝石 membership on or off. |
| 领取亚比 | Enter the 亚比's 图鉴 number (编号, 1 to 1651) and a level from 1 to 100, then click 领取. The name appears next to the number. The 亚比 goes into the bag, or into the 亚比仓库 when the bag already holds six. It knows every skill its line learns up to that level. |
| 传送 | Type a place's Chinese name (for example 艺术馆) or its room id and click 传送, or click 选地图 to pick from the places of the world map. 选地图 → 其他场景 lists every other room of the game, including the rooms of the story quests that were no longer on the map in 2013. |
| 存档 | 导出存档 and 导入存档, see [Saves](#saves). |

### 亚比 after January 2013 (1427–1651)

The 2013 game had 亚比 up to 1426. The revival adds the next ones, up to 1651
(223 more, 小炎 1427 to 路威杰 1651; 1476 and 1617 are not numbers of a 亚比), from the later game's tables: their 图鉴 rows,
stats, skills and evolutions, battle sprites, small and large pictures, and
walking figures. They are not found in the wild or given by any activity:
领取亚比 in the 工具箱 is the way to get them. They fight, follow (in their own
walking figures), evolve and learn skills as the others do. 320, 323, 605,
1002 and 1423 of the 2013 亚比, which had no walking figure then, follow in
the ones the later game gave them. The 坐骑 the later game added up to 1651
(1101, 1122, 1350, 1423, 1426, 1430, 1448, 1461, 1599) can be ridden as the
2013 坐骑 are.

### 亚比 marked 无法获得

The 2013 亚比图鉴 marks 55 亚比 as 无法获得 (cannot be obtained): enemies of
the 四大副本, 达斯特's 亚比, quest opponents and bosses. In the original game
players could only fight them. With 领取亚比 in the 工具箱 you can get any of
them by number, like any other 亚比.

Following and battles work for all 55:

- **跟随**: three of them (415 埃黑多夫, 448 冰火巨人, 466 冰摩格) have walking
  figures and follow you as those. The others have no walking figure in the
  game files and follow you as their large 图鉴 picture.
- **战斗**: all 55 have battle sprites and battle data, so they can fight in
  every kind of battle. Their skills are the ones the 2013 tables list. As
  enemies they needed few: many know only one to three skills, and 360
  苹果智能炮 and 361 风筝雷电射线 have none, so they cannot attack.

They cannot be caught in the wild or in the 副本 (the tables give them no
catch rate), and the column 可学技能 counts the skills their line learns.

| 编号 | 亚比 | 地区 | 图鉴里的获得方式 | 可学技能 | 跟随形象 |
| --- | --- | --- | --- | --: | --- |
| 118 | 骑士战马 | — | 无法获得。 | 1 | 图鉴大图 |
| 210 | 圣甲虫 | 索里德区 | 奥拉战记——倒立金字塔里的亚比，无法获得。 | 4 | 图鉴大图 |
| 213 | 石像守卫 | 索里德区 | 奥拉战记——倒立金字塔里的亚比，无法获得。 | 3 | 图鉴大图 |
| 216 | 兵蚁 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 1 | 图鉴大图 |
| 217 | 工蚁 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 2 | 图鉴大图 |
| 218 | 守护力士 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 1 | 图鉴大图 |
| 219 | 守护法师 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 1 | 图鉴大图 |
| 222 | 贝德威尓 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 2 | 图鉴大图 |
| 223 | 兰斯罗特 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 1 | 图鉴大图 |
| 224 | 哥拉海德 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 1 | 图鉴大图 |
| 225 | 保斯 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 2 | 图鉴大图 |
| 227 | 变异蚁将军 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 4 | 图鉴大图 |
| 239 | 狂暴天狼 | — | 达斯特大将迪瑞恩的亚比，无法获得。 | 4 | 图鉴大图 |
| 240 | 法老王 | 索里德区 | 奥拉战记——倒立金字塔里的亚比，无法获得。 | 4 | 图鉴大图 |
| 241 | 毒菇球 | 思伍德区 | 奥拉战记——倒立金字塔里的亚比，无法获得。 | 1 | 图鉴大图 |
| 242 | 金刚蛤蟆 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 2 | 图鉴大图 |
| 243 | 下水猛鳄 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 4 | 图鉴大图 |
| 244 | 牛角滴滴 | 思伍德区 | 奥拉战记——蚁族王朝里的亚比，无法获得。 | 4 | 图鉴大图 |
| 245 | 斗魂星云棒 | — | 斗魂星云棒幻化成的亚比，无法获得。 | 1 | 图鉴大图 |
| 269 | 威尔斯 | — | 达斯特的亚比，无法获得。 | 1 | 图鉴大图 |
| 270 | 木人桩 | 上古神殿 | 在上古神殿的“大妖之怒”任务中出现过，无法获得。 | 3 | 图鉴大图 |
| 272 | 曼珠沙华 | 索里德区 | 奥拉战记——倒立金字塔里的亚比，无法获得。 | 3 | 图鉴大图 |
| 301 | 达鲁 | — | 达斯特大将哈鲁达的亚比，无法获得。 | 16 | 图鉴大图 |
| 304 | 帕克 | — | 达斯特大将可帕斯的亚比，无法获得。 | 16 | 图鉴大图 |
| 307 | 利飞 | — | 达斯特大将菲莉的亚比，无法获得。 | 4 | 图鉴大图 |
| 319 | 科克 | — | 达斯特大将多克特的亚比，无法获得。 | 4 | 图鉴大图 |
| 322 | 达达 | — | 达斯特军队的亚比，无法获得。 | 16 | 图鉴大图 |
| 324 | 钢铁达鲁 | — | 无法获得。 | 1 | 图鉴大图 |
| 325 | 巨人守卫 | — | 达斯特大将古力德的亚比，无法获得。 | 16 | 图鉴大图 |
| 326 | 炎魔 | — | 太阳之殿的考官，无法获得。 | 1 | 图鉴大图 |
| 327 | 月魔 | — | 月亮之殿的考官，无法获得。 | 1 | 图鉴大图 |
| 328 | SR战士 | — | 达斯特军队的亚比，无法获得。 | 16 | 图鉴大图 |
| 329 | 强袭SR | — | 达斯特军队的亚比，无法获得。 | 16 | 图鉴大图 |
| 332 | 邪恶霹雳 | 比特区 | 多克特研制出的霹雳，在“神奇的霹雳”任务中出现过，无法获得。 | 16 | 图鉴大图 |
| 333 | 钢铁科克 | — | 无法获得。 | 2 | 图鉴大图 |
| 334 | 组合机器人 | 比特区 | 多克特组装出的机械人，在“神奇的霹雳”任务中出现过，无法获得。 | 16 | 图鉴大图 |
| 340 | 机械木乃伊 | 索里德区 | 奥拉战记——倒立金字塔里的亚比，无法获得。 | 4 | 图鉴大图 |
| 360 | 苹果智能炮 | — | 发明岛的纽顿的亚比，无法获得。 | 0 | 图鉴大图 |
| 361 | 风筝雷电射线 | — | 发明岛的弗朗科林的亚比，无法获得。 | 0 | 图鉴大图 |
| 369 | 暗影甲龙 | — | 达斯特军团的先锋将领，无法获得。 | 16 | 图鉴大图 |
| 400 | 迅猛龙 | 艺术之都 | 奥拉战记——恐龙博物馆里的亚比，无法获得。 | 1 | 图鉴大图 |
| 401 | 梁龙 | 艺术之都 | 奥拉战记——恐龙博物馆里的亚比，无法获得。 | 1 | 图鉴大图 |
| 402 | 翼龙 | 艺术之都 | 奥拉战记——恐龙博物馆里的亚比，无法获得。 | 1 | 图鉴大图 |
| 403 | 鱼龙 | 艺术之都 | 奥拉战记——恐龙博物馆里的亚比，无法获得。 | 1 | 图鉴大图 |
| 404 | 霸王龙 | 艺术之都 | 奥拉战记——恐龙博物馆里的亚比，无法获得。 | 1 | 图鉴大图 |
| 405 | 星辰毁灭者 | 艺术之都 | 奥拉战记——恐龙博物馆里的亚比，无法获得。 | 2 | 图鉴大图 |
| 415 | 埃黑多夫 | 艾夕区 | 奥拉战记——幻影冰宫里的亚比，无法获得。 | 16 | 行走形象 |
| 448 | 冰火巨人 | 艾夕区 | 奥拉战记——幻影冰宫里的亚比，无法获得。 | 16 | 行走形象 |
| 461 | 黑化念 | — | 风暴星系的终极BOSS，无法获得。 | 3 | 图鉴大图 |
| 462 | 黑化巨翅金鹏 | — | 一只被黑暗力量控制的亚比，无法获得。 | 2 | 图鉴大图 |
| 466 | 冰摩格 | 艾夕区 | 奥拉战记——幻影冰宫里的亚比，无法获得。 | 16 | 行走形象 |
| 523 | 麦斗王 | 斗魂空间 | 一只被黑暗力量控制的亚比，无法获得。 | 2 | 图鉴大图 |
| 527 | 奈乌达斯 | — | 达斯特军团的先锋将领，无法获得。 | 4 | 图鉴大图 |
| 609 | 伊德鲁拉 | — | 达斯特军团的先锋将领，无法获得。 | 16 | 图鉴大图 |
| 735 | 护花雪兔 | — | 保护冰凌花的使者，无法获得。 | 2 | 图鉴大图 |

## 沙盒

The 沙盒 was not in the 2013 game either. It sets up custom battles and
runs mods. Open it with the 沙盒 button under the 工具箱. Its panel has two
pages.

Rules for every 沙盒 fight: winning brings nothing (no experience, effort
points, evolution or catching). A mod can give 亚比 itself, as the 工具箱
can. The server checks every value of a 关卡 and refuses one it cannot read.

### 对手关卡: a list of opponents

A 关卡 here is up to 10 opponents fought one after another.

1. Enter a name for the 关卡.
2. Click 添加对手 for each opponent and fill in its row:
   - 编号: the 亚比's 图鉴 number (any 亚比 that can fight);
   - 等级: 1 to 999 (above 100 the stats keep growing by the same formulas);
   - 体力%, 攻击%, 防御%, 特攻%, 特防%, 速度%: each stat in percent of its
     normal value at that level, from 1 to 10000. 100 leaves it unchanged.
3. 每场前恢复体力 chooses whether your bag is healed before each fight.
4. Click 开始挑战. A loss ends the 关卡.

删 removes a row, 清空 removes all. 导出关卡 saves the 关卡 to a file and
导入关卡 loads one, so 关卡 can be kept and shared. The last 关卡 is
remembered.

### 模组: mods

A mod is a program for the 沙盒, written in ActionScript 3 and compiled to
a SWF file. Mods make rooms of their own with characters who talk and give
choices, play animations, set up fights, and can add new 亚比 with their own
pictures, stats and skills. How to write one is in [MODDING.md](MODDING.md).

1. Click 载入 next to one of the examples the site comes with, or 导入模组 to
   choose a mod's `.swf` file (at most 16 MB). It is listed under 已载入的模组.
   Several mods can be loaded at once (up to 8); two that use the same 亚比
   number cannot, and the panel says which one is in the way.
2. Click 开始 next to a mod. The 沙盒 panel closes and the mod begins,
   usually in a room of its own. 移除 next to a mod (or next to an example's
   载入) unloads it, and leaves its room if you are in it.
3. In a mod's rooms, click the floor to walk, a door to walk to it and go
   through, a character to talk to it or fight it. 离开沙盒 (top left)
   returns to where you opened the 沙盒.

Each player is alone in the 沙盒's rooms. A mod keeps its progress on the
server (at most 64 KB per mod). 亚比 a mod gives go to the bag, or to the
仓库 when the bag is full. A 亚比 the mod made itself (numbers 900001–999999)
is known to the game only while that mod is running: after a reload it is
put aside until the mod is started again.

A mod is a program and runs with the game's rights, so it could change your
save. Only load mods whose source you have read or whose author you trust.
