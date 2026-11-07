# Supported content

This document lists what the revival supports. Names are given in Chinese,
as in the game; room ids (`aixiscene2`) are those of the 2013 `config.xml`.

Status marks used below:

- **可用**: works as in 2012, or as close to it as the surviving files allow.
- **部分**: some of it works; the note says what does not.
- **不可用**: the button exists but shows 这个功能还在修复中 or a message, or
  the place's surviving file has no button for it.

Values the 2013 server decided (levels, rewards, odds, limits) are lost and
were reconstructed; [IMPLEMENTATION.md](IMPLEMENTATION.md) explains how.

## Overview

| Area | Supported |
| --- | --- |
| Places | 57 places of the November 2012 world map; the 334 rooms of the 2013 `config.xml` (副本 rooms included) and 30 rooms of the 2011–12 story quests |
| NPCs | 460 NPCs placed in 203 rooms; every NPC the 2012 world map names for its place |
| Quests | the newbie quest and 182 quests (story arcs of 2010–2013, side quests, guide quests) |
| Bosses | 42 entries of 守护者 and event bosses, 11 NPC challenges, the 道馆 masters, 黑星堡垒, 时空隧道, the 四大副本 bosses |
| 四大副本 | 幻影冰宫, 倒立金字塔, 蚁族王朝, 恐龙博物馆, three modes each |
| Mini games | 85 of the 87 game rooms of the 2013 config |
| 亚比 | 1,604 species in the 图鉴 (1–1651); battles, catching, skills, evolution, eggs, following, riding |
| Added by the revival | the 工具箱 and the 沙盒 ([GUIDE.md](GUIDE.md)) |

## Places and NPCs

Every place of the November 2012 world map opens (the map is the one 百田
published on its guide page). The 工具箱's 传送 reaches every room, including
those of the 2011–12 story quests that had left the map by 2013.

NPCs come in two kinds:

- **常驻 NPC** stand in their room all the time.
- **任务 NPC** appear only while a quest has something for them to say, as in
  the original client. This includes the 达斯特 generals and other quest
  characters that appear in many rooms.

The numbers are NPC ids (`tasknpc/npc<id>`). Many rooms are later redrawings
(2014 and after) of the 2012 rooms; where a later room places NPCs that no 2012
quest uses, they never appear.

| 地点 | 场景 | 常驻 NPC | 任务 NPC（有任务时出现） |
| --- | --- | --- | --- |
| M7星云 | 古代遗迹 `msevenstar1` | — | 宇宙侠 (481)、幻灵 (849)、圣光 (850) |
|  | 龙族圣殿 `msevenstar2` | — | 贝贝龙 (573)、苍蓝 (574)、碎风 (596)、红莲 (626)、凌云 (627)、寒霜 (662)、幻灵 (755)、冰爆巨兽 (694)、震地巨兽 (695)、巨岩 (697)、零宇 (775)、雷泽 (790)、地裂 (811)、圣光 (841) |
|  | 黑暗星穴 `msevenstar3` | — | — |
| 指挥中心 | 指挥中心 `maintown2` | 司令官麦哲伦 (9) | 星语 (220) |
| 传送核心 | 传送核心 `maintown1` | 异星使者维克 (13) | — |
| 极速俱乐部 | 极速俱乐部 `fastclub` | 治安官哈德 (26) | 治安官哈德 (430) |
| 主题公园 | 主题公园 `themepark` | — | 神秘人 (428)、章鱼哥 (429)、馋嘴巴 (568)、勇士果果 (661)、小萤萤 (570)、猪小皮 (633)、瓜瓜鸡 (634)、猪猪超人 (635)、萌萌 (676)、希萌 (677)、叮叮 (691)、当当 (692)、皮蛋蛋 (712)、妙妙 (756)、奇奇 (685)、贝贝龙 (573)、小幻 (828)、小幻 (829) |
| 生态园 | 生态园 `ecologicalpark` | 咪卡 (400) | 哈鲁达 (8)、菲莉 (66)、绿光兽 (450)、读书虫 (550)、萌萌 (676)、仔仔 (466)、三只小雁 (785) |
| 奥拉广场 | 奥拉广场 `starland` | 芭芭拉 (35) | 奥斯卡 (72)、小依舞 (104)、动起来 (426)、小刺猬 (414)、神秘人 (428)、爱哭鬼 (565)、读书虫 (564)、丸少爷 (580)、小南姐姐 (585)、猪小皮 (624)、猪小皮 (633)、炎之魔将 (572)、米果果 (659)、神秘的黑影 (672)、萌萌 (676)、叮叮 (691)、当当 (692)、妙妙 (756)、哈鲁达 (8) |
| HELLO学院 | HELLO学院 `helloschool` | 普伦博士 (14) | 霹雳 (91) |
|  | 科学院 `science` | — | 小兔 (412) |
| 十字大道 | 十字大道 `crossroad` | — | 哈米 (561)、爱哭鬼 (565)、读书虫 (564)、哈米 (567) |
|  | 爱心协会 `loveassociation` | 绯雪 (42) | — |
|  | 图书馆 `library` | 布拉德 (10)、小南姐姐 (43) | 小奥拉 (279)、哈鲁达 (8)、蓝宝星 (415)、小芽星 (416) |
|  | 奥拉展馆 `xianxiazhanguan` | — | — |
| 太空港 | 太空港 `teambattleoutside` | — | 哈鲁达 (8)、小猫 (405)、咪卡 (404)、黑达战士 (21)、仔仔 (466)、读书虫 (550)、星耀 (57)、日耀 (555) |
| 银河商会 | 银河商会 `employmenttown` | 塞恩斯 (465)、乔布斯 (723) | 爱哭鬼 (549)、读书虫 (550)、叮叮 (691)、当当 (692) |
| 蓝宝石要塞 | 蓝宝石要塞 `bluesquare` | 军需官亨特 (142)、训练官卢卡斯 (148)、骑士团卫兵 (145)、机械师马赫 (172) | 飞飞龙 (867)、星语 (220)、提琴卡卡 (291)、小号卡卡 (292)、萨克斯卡卡 (293)、宇宙侠 (481)、贝贝龙 (573)、飞飞龙 (872) |
| 奥拉之树 | 奥拉之树 `aolatree` | 萨鲁奇 (44) | 咪卡 (404)、哈鲁达 (8)、蓝宝星 (415)、小芽星 (416)、仔仔 (466)、菲莉 (66)、米果果 (659)、黑达烧饼 (510)、小幻 (828)、多克特 (46)、幻炎 (831)、炎风 (182) |
| 奥拉运动场 | 奥拉运动场 `gymnasium` | 动起来 (426) | — |
| 战斗星域 | 银河冠军擂台 `spacetimechallenge` | — | 库斯特 (380)、海之妖将 (548)、炎之魔将 (572)、可兰 (648)、神秘的黑影 (672)、风之灵将 (673)、瑞斯 (894) |
| 流星购物街 | 流星购物街 `starshopping` | — | — |
|  | 服装店 `clothesshop` | 依依 (31) | 妮可 (71)、萌萌 (676) |
|  | 家具店 `furnitureshop` | 安娜 (32) | 罗伯特 (70)、米娜 (410)、萌萌 (676) |
|  | 道具店 `toolshop` | 米娜 (3) | 咪卡 (404)、萌萌 (676) |
|  | 种植园 `plantpark` | 爱德华 (452) | — |
| 亚比研究中心 | 亚比研究中心 `yabistudy` | — | 托尔索 (150)、贝鲁特 (11) |
|  | 亚比训练室 `yabitrain` | 研究员罗兰 (382) | — |
|  | 科学院 `science` | — | 小兔 (412) |
| 星光游乐场 | 星光游乐场 `amusementpark` | 乐乐兔 (239) | 卡卡 (265)、黑达战士 (21) |
| 欢乐岛 | 欢乐岛 `summerhotspring` | — | — |
| 百田大剧场 | 大剧院 `theatre` | — | — |
| 亚比协会 | 亚比协会 `yabiunion` | 泰勒 (827) | 小幻 (823) |
| 费尔区 | 费尔村落 `feier1` | 村长希普 (67) | 菲莉 (66)、比利 (68)、SR战士 (53) |
|  | 火山山脚 `feier2` | — | 菲莉 (66)、比利 (68)、黑达战士 (21)、炎蘑菇 (78)、烈焰鸟 (80)、赤火鸟 (171) |
|  | 火山山口 `feier3` | — | 摩格 (75)、比利 (68)、赤火鸟 (171) |
|  | 烈焰洞穴 `feier4` | — | 菲莉 (66)、比利 (68)、烈焰鸟 (80)、赤火鸟 (171) |
|  | 火山洞 `volcano` | — | 艾尔利克 (343) |
| 比特区 | 机械废墟 `bite1` | — | 机甲勇士 (98)、霹雳 (91)、垃圾清理机器人 (96) |
|  | 数码城 `bite2` | — | 数码钟守卫 (93)、数码塔守卫 (95)、数码塔守卫 (102)、霹雳 (91)、小依舞 (104)、多克特 (46)、邪恶霹雳 (109)、组装机器人 (110) |
|  | 机械工厂 `bite3` | — | 霹雳 (91)、强袭SR (108) |
|  | 数码研究室 `bite4` | — | 诺贝尔 (90)、强袭SR (108)、霹雳 (91) |
| 海文花园 | 天空大陆 `haiwen1` | — | 彩虹预言者 (117)、飞行战士 (118)、哈鲁达 (8)、安吉儿 (120)、帕丁 (119)、毛毛球 (113)、小鼠蝠 (114)、达斯特侦查兵 (59)、卡卡 (265) |
|  | 晨光大陆 `haiwen2` | — | 安吉儿 (120)、变色蜥蜴 (112) |
|  | 暮光大陆 `haiwen3` | — | 帕丁 (119)、毛毛球 (113)、变色刺龙 (115) |
|  | 暮光禁地 `haiwen4` | — | 帕丁 (119)、尖翼蝠 (122)、尖翼蝠 (129)、尖翼蝠 (130)、毛毛球 (113)、圆尾蝎 (116) |
|  | 永恒之瀑 `haiwen5` | — | 毛毛球 (113)、小鼠蝠 (114)、帕丁 (119)、安吉儿 (120)、斗篷人 (138)、哈鲁达 (8) |
| 雷鸣大陆 | 雷鸣海滨 `leiming1` | — | 托尔索 (150)、电击小拳仔 (151)、研究员ET (149) |
|  | 雷鸣平原 `leiming2` | — | 托尔索 (150)、法拉帝 (154)、古力德 (54)、古尔德 (50)、菲莉 (66)、闪电星 (158) |
|  | 雷鸣山丘 `leiming3` | — | 研究员ET (149)、托尔索 (150)、菲莉 (66)、研究员ET (155)、雷云狮 (157) |
|  | 雷鸣悬崖 `leiming4` | — | 托尔索 (150)、雷鸣托尔索 (170)、古尔德 (50)、古力德 (54)、研究员ET (149)、菲莉 (66) |
| 沃尔特区 | 回音海岸 `woerte1` | — | 人鱼可可 (49)、泡泡闪光河豚 (51)、水冻宝宝 (217) |
|  | 水上都市 `woerte2` | 雷米 (48) | 古尔德 (50)、水冻宝宝 (217)、萨克斯卡卡 (293) |
|  | 水下广场 `woerte3` | 拉布 (52) | 人鱼可可 (49)、古尔德 (50)、古力德 (54)、巨人守卫 (55) |
|  | 贝壳城堡 `woerte4` | — | 人鱼可可 (49)、SR战士2 (60)、SR战士3 (61)、SR战士4 (62)、SR战士5 (63)、SR战士 (53) |
| 思伍德区 | 部落林地 `siwude1` | 杜克 (36)、卡波 (37)、卡托尔 (38) | 多克特 (46)、小号卡卡 (292)、亚比群 (440)、木面仔 (441) |
|  | 连接藤蔓 `siwude2` | 丽娅 (39) | 库飞尔 (40)、多克特 (46)、小花蝶 (174)、木面仔 (441) |
|  | 原始林地 `siwude3` | — | 卡波 (37)、扭啊扭 (41)、多克特 (46)、进化版木木鸟 (47)、木羊羊 (176)、芭比鹿 (222)、扭扭大王 (256)、木面仔 (441)、木面侠 (76) |
|  | 生命之树 `siwude4` | — | 杜克 (36)、终极木木鸟 (45)、多克特 (46) |
|  | 光影森林 `siwude6` | — | 小翼鸟 (173)、小花蝶 (174)、扭扭 (175)、木羊羊 (176) |
|  | 水木洞天 `siwude5` | — | 小翼鸟 (173)、多克特 (46)、木羊羊 (176) |
| 索里德区 | 索里德 `suolide` | — | — |
|  | 遗迹区域 `suolide1` | 鲁阿鲁 (23) | 猫王子哈里 (16)、斯多恩 (25)、电击小拳仔 (151)、沙克 (215)、可帕斯 (19) |
|  | 流沙区域 `suolide2` | — | 淘吉吉 (20)、猫王子哈里 (16)、沙克 (215)、震天石人 (216)、皮皮 (488) |
|  | 风暴之眼 `suolide3` | 索里克斯 (24) | 猫王子哈里 (16)、夜眼风魔 (34)、半沙拳手 (152)、电击小拳仔 (151) |
|  | 新世界 `suolide4` | 猫王子哈里 (16)、猫王艾维斯 (17)、随从哈夫 (18) | 哈鲁达 (8)、黑达战士 (21)、随从哈达 (22)、SR战士2 (60)、沙麒麟 (65)、木羊羊 (176)、沙克 (215)、木羊羊朋友 (417)、圆角羊 (418)、锐角羊龙 (419)、SR战士 (53) |
|  | 风暴沙漠 `suolide5` | — | 沙麒麟 (65) |
| 艾夕区 | 冰雕广场 `aixiscene1` | 吉蒂 (15) | 吉蒂 (2)、哈鲁达 (8)、库多兽 (212)、朵朵兔 (213)、绅士企鹅 (214)、卡卡 (265)、提琴卡卡 (291) |
|  | 冰河瀑布 `aixiscene2` | 欧巴爷爷 (7) | 吉蒂 (2)、寒冰玉兔 (12)、黑达战士 (21)、吉蒂 (15)、绅士企鹅 (214) |
|  | 奇迹冰殿 `aixiscene4` | — | 吉蒂 (2)、伊莎女王 (201)、哈鲁达 (8)、冰宫守卫 (81) |
|  | 寒冰洞 `aixiscene6` | — | 哈鲁达 (8)、冰拳艾司 (64) |
| 艺术之都 | 艺术广场 `yishuzhidu1` | — | 馆长阿提斯特 (185)、星际警探 (184)、数码魔方 (189)、达斯特侦查兵 (59)、浮云弟弟 (268)、浮云哥哥 (269)、赤月 (245)、提琴卡卡 (291)、小号卡卡 (292)、萨克斯卡卡 (293) |
|  | 艺术馆 `yishuzhidu2` | — | 馆长阿提斯特 (185)、星际警探 (184)、菲莉 (66)、弗洛拉 (194)、管家巴斯 (187)、基德 (188) |
|  | 艺术长廊 `yishuzhidu3` | — | 疯画家米高 (186)、管家巴斯 (187)、弗洛拉 (194)、星际警探 (184)、浮云弟弟 (268)、浮云哥哥 (269)、赤月 (245)、哈鲁达 (8)、提琴卡卡 (291)、小号卡卡 (292)、萨克斯卡卡 (293)、竖琴卡卡 (294)、音爵卡卡 (295) |
|  | 名画家小屋 `yishuzhidu4` | — | 基德 (188)、管家巴斯 (187)、弗洛拉 (194)、菲莉 (66)、星际警探 (184) |
|  | 小屋密室 `yishuzhidu5` | — | 弗洛拉 (194)、管家巴斯 (187)、星际警探 (184) |
|  | 喷泉水族馆 `aquarium` | — | 修普森曼 (403) |
|  | 博物馆大厅 `yishuzhidu6` | — | — |
| 发明岛 | 发明港口 `inventisland1` | — | 晕倒的人 (204)、纽顿 (205)、纽顿 (211)、达斯特侦查兵 (59) |
|  | 发明城 `inventisland2` | — | 纽顿 (205)、被苹果砸中的人 (206)、弗朗科林 (207)、研究员ET (149) |
|  | 实验室 `inventisland3` | — | 诺贝尔 (90)、管家巴斯 (187)、研究员ET (149) |
|  | 发明中心 `inventisland4` | — | 星际警探 (184)、警探队长 (209)、多克特 (46)、兰丁 (94)、管家巴斯 (187)、研究员ET (149)、弗朗科林 (207)、纽顿 (205)、弗洛拉 (194) |
|  | 武器基地 `inventisland5` | — | 弗洛拉 (194)、兰丁 (94) |
| 上古神殿 | 崩坏的上古神殿 `temple1` | — | 卡卡 (265)、小龙人 (359)、雪人 (411)、赤羽忍者 (518) |
|  | 日月之境 `temple2` | — | 炎风 (182)、木人桩 (193)、赤月 (245)、赤月 (183) |
|  | 木石之境 `temple3` | — | 炎风 (182)、黑影 (244) |
|  | 灵兽宫 `temple6` | 上古使者 (312) | — |
| 云端王国 | 奇草树林 `cloudstar1` | — | — |
|  | 魔法羽林 `cloudstar2` | — | 飞灵 (776) |
|  | 星芒小镇 `cloudstar3` | — | 水枪蟹 (780) |
|  | 索尔石城 `cloudstar4` | — | — |
|  | 参天瀑布 `cloudstar5` | — | 飞灵 (776) |
|  | 天神圣殿 `cloudstar6` | — | — |
| 大地迷城 | 迷城河畔 `mysticearth1` | — | — |
|  | 雏菊平原 `mysticearth2` | — | — |
|  | 伯爵城堡 `mysticearth3` | — | — |
|  | 零时迷城 `mysticearth4` | — | — |
| 海洋幻境 | 幻之结界 `mysticocean1` | — | — |
|  | 迦娜的梦境 `mysticocean2` | — | — |
|  | 外海之域 `mysticocean3` | — | — |
|  | 内海之域 `mysticocean4` | — | — |
| 六芒神殿 | 六芒前殿 `hexagrampalace1` | — | — |
|  | 灵力空间 `hexagrampalace2` | — | — |
|  | 奇灵神树 `hexagrampalace3` | — | 修罗 (517) |
|  | 六芒内殿 `hexagrampalace4` | — | — |
| 美食之星 | 冰淇淋大街 `catestar1` | — | 奥力奥 (420)、雪糕仔 (421)、绿茶雪糕仔 (422) |
|  | 松软蛋糕店 `catestar2` | — | 露可 (423)、露丝 (424)、蒙面人 (425) |
|  | 露可的美食小屋 `catestar3` | — | 露可 (423)、菲莉 (66) |
|  | 美食节广场 `catestar4` | — | 菲莉 (66)、奥力奥 (420)、露可 (423)、露丝 (424)、雪糕仔 (421) |
| 魔术之星 | 魔术广场 `magicstar1` | — | 扑克小呆 (484)、帽子小呆 (485)、安迪奶奶 (486) |
|  | 魔术馆 `magicstar2` | — | 安迪奶奶 (486)、摩么卡 (487)、多克特 (46) |
|  | 魔术小镇 `magicstar3` | — | — |
| 童话之星 | 童心小屋 `fairytalestar1` | — | 哈鲁达 (8)、童心 (462)、达鲁编号1 (477)、达鲁编号2 (478)、达鲁编号3 (479)、黑夜童心 (480) |
|  | 公主森林 `fairytalestar2` | — | 童心 (462)、白雪公主 (463)、丑小鸭 (464)、大灰狼 (471) |
|  | 丑小鸭世界 `fairytalestar3` | — | 哈鲁达 (8)、童心 (462)、丑小鸭 (464)、鸭老大 (467)、鸭老二 (468)、鸭老三 (469)、白天鹅 (470) |
|  | 小猪之家 `fairytalestar4` | — | 童心 (462)、大灰狼 (471)、呼呼 (472)、噜噜 (473)、嘟嘟 (474)、母狼 (476)、哈鲁达 (8) |
| 独角之星 | 皇宫外城 `unicornstar1` | — | 晕倒的亚比 (445)、多多王子 (446)、骑士战马 (447)、仙林独角兽 (448)、独角兽国王 (449)、先哲独角兽 (451)、神秘的独角兽 (453)、铠甲独角兽 (454) |
|  | 阳光荷塘 `unicornstar2` | — | 多多王子 (446)、神秘的独角兽 (453)、铠甲独角兽 (454)、先哲独角兽 (451)、先哲独角兽 (455) |
|  | 独角兽密林 `unicornstar3` | — | 多多王子 (446)、铠甲独角兽 (454)、先哲独角兽 (455)、飞天独角兽 (459) |
|  | 皇宫地牢 `unicornstar4` | — | 铠甲独角兽 (454)、多多王子 (446)、骑士战马 (447)、多多王子 (457)、哈鲁达 (456) |
|  | 皇宫大殿 `unicornstar5` | — | 仙林独角兽 (448)、独角兽国王 (449)、先哲独角兽 (455)、先哲独角兽 (451)、铠甲独角兽 (454)、多多王子 (457)、仙林独角兽 (461) |
| 海枯之星 | 观星海岸 `haikustar1` | — | — |
|  | 海枯之海 `haikustar2` | — | 达黑黑 (495) |
|  | 海枯小镇 `haikustar3` | — | 书恩 (501) |
|  | 海枯之山 `haikustar4` | — | — |
| 冰雪之星 | 怀特雪原 `bingxuestar1` | — | 迪恩 (520)、豆豆 (522)、黑色影子 (521)、圣诞小雪兔 (519)、迷幻之蝶 (531)、粉色蝴蝶 (532)、兰丁 (385) |
|  | 迪恩的小屋 `bingxuestar2` | — | 迪恩 (520)、豆豆 (522)、山神 (538)、兰丁 (385)、可帕斯 (19) |
|  | 暴雪冰山 `bingxuestar3` | — | 护花雪兔 (523)、山神 (538)、凯撒 (539)、修罗 (540)、豆豆 (522) |
|  | 虚幻之春 `bingxuestar4` | — | 黑色影子 (521)、粉色蝴蝶 (532)、迪恩 (520)、山神 (538)、修罗 (540) |
| 尖叫游乐园 | 尖叫游乐园 `screampark1` | — | — |
|  | 开心园区 `screampark2` | — | — |
|  | 恐怖鬼屋 `screampark3` | — | — |
|  | 幸福摩天轮 `screampark4` | — | — |
| 音乐之都 | 时代广场 `musicstar1` | — | 奇奇 (685)、路比 (705)、神秘人 (706)、粉丝A (707)、粉丝B (708) |
|  | 售票厅 `musicstar2` | — | 奇奇 (685)、路比 (705)、售票员 (709) |
|  | 世纪大舞台 `musicstar3` | — | 奥力奥 (420)、路比 (705)、非蒙 (710)、奇奇 (685) |
|  | 音之迷境 `musicstar4` | — | 奇奇 (685)、路比 (705)、非蒙 (710)、绿焰 (716)、夜王之魂 (717) |
| 白灵圣殿 | 白灵古道 `bailingstar1` | — | 奇奇 (685)、小米 (726)、洛洛 (725)、法师 (732)、白灵族人A (747)、白灵族人B (748)、白灵族人C (749) |
|  | 禁林 `bailingstar2` | — | 奇奇 (685)、小米 (726)、洛洛 (725)、通灵巫师 (620) |
|  | 凌云圣殿 `bailingstar3` | — | 奇奇 (685)、小米 (726)、洛洛 (725)、法师 (732)、红魔 (686)、狼王迪洛斯 (744)、绿焰 (716)、紫渊 (652)、烈焰凤凰 (754)、夜王狄米特 (750)、奥奇 (753) |
|  | 魂塔顶端 `bailingstar4` | — | 洛洛 (725)、狼王迪洛斯 (744)、夜王狄米特 (750)、修罗 (517) |
| 雅克星 | 伊索部落 `yakestar1` | — | 修罗 (540)、麦提 (581)、族长 (582)、族长侍卫 (583)、族长侍卫 (584)、菲莉 (66)、SR战士2 (60) |
|  | 乱石之丘 `yakestar2` | — | 修罗 (540)、麦提 (581)、菲莉 (66)、SR战士2 (60) |
|  | 族长之帐 `yakestar3` | — | 修罗 (540)、麦提 (581)、族长 (582)、族长侍卫 (583)、族长侍卫 (584)、巨锁石灵 (587) |
|  | 玛雅山 `yakestar4` | — | 麦提 (581)、族长 (582)、修罗 (540)、黑化麦爸 (590)、麦爸 (591)、神罗麦提 (589) |
| 糖果星 | 彩虹小城 `candystar1` | — | 小白吐 (592)、糖爷爷 (595)、糖先生 (606)、糖糖 (593) |
|  | 糖爷爷小店 `candystar2` | 糖爷爷 (595) | 小白吐 (592)、糖糖 (593) |
|  | 糖果工厂 `candystar3` | — | 小白吐 (592)、糖先生 (606)、小白吐 (610)、糖糖 (593) |
|  | 糖果博物馆 `candystar4` | — | 小白吐 (610)、TT兔部队 (607)、糖糖 (593) |
| 风车谷 | 风车城 `windmillstar1` | — | 亚伦 (617)、工厂守门人 (618)、贝琪 (619)、通灵巫师 (620)、群众A (621)、群众B (622)、亚伦 (623)、小老鼠 (625)、贝琪 (628)、馋嘴巴 (492) |
|  | 秘密基地 `windmillstar2` | — | 亚伦 (617)、贝琪 (619)、通灵巫师 (620)、贝琪 (628)、亚伦 (623)、小老鼠 (625)、通灵巫师A (629)、利克亚伦 (639)、百变贝琪 (640)、通灵巫师B (630) |
|  | 风之城堡 `windmillstar3` | — | 贝琪 (619)、亚伦 (623)、通灵巫师 (620)、贝琪 (628) |
|  | 风车谷底 `windmillstar4` | — | 通灵巫师 (620)、凯撒 (539)、贝琪 (628)、利克亚伦 (639)、百变贝琪 (640)、亚伦 (623)、小老鼠 (625)、通灵巫师A (629)、通灵巫师B (630) |
| 时钟之域 | 雕刻时光沙滩 `clockstar1` | — | 伊修 (559)、亚伦 (623)、泽时 (641)、泽分 (642)、阿凯 (660)、泽秒 (643) |
|  | 钟摆孤岛 `clockstar2` | — | 凯撒 (539)、修罗 (540)、通灵巫师 (620)、通灵巫师A (629)、通灵巫师B (630)、泽时 (641)、泽分 (642)、紫渊 (652)、泽秒 (643) |
|  | 时钟大殿 `clockstar3` | — | 修罗 (540)、泽时 (641)、泽分 (642)、泽秒 (643) |
|  | 明灭之轮 `clockstar4` | — | 凯撒 (539)、修罗 (540)、泽时 (641)、泽分 (642)、泽秒 (643) |
| 骑士王国 | 骑士学院 `knightstar1` | — | — |
|  | 教学楼 `knightstar2` | — | — |
|  | 黑森林 `knightstar3` | — | — |
|  | 地下密室 `knightstar4` | — | — |
| 惊雷道馆 | 惊雷道馆 `huanlei` | 幻雷 (833) | — |
| 炼火道馆 | 炼火道馆 `huanyan` | 幻炎 (831) | — |
| 御水道馆 | 御水道馆 `huanliu` | 幻流 (832) | — |
| 命运道馆 | 命运道馆 `huanming` | 幻冥 (836) | 哈鲁达 (8)、小幻 (828) |
| 光明道馆 | 光明道馆 `huanguang` | 幻光 (835) | 菲莉 (66)、小幻 (828) |
| 终极神殿 | 终极神殿 `huanfinal` | — | — |

其他场景（剧情任务的场景等，工具箱「选地图 → 其他场景」可以去）：

| 场景 | 常驻 NPC | 任务 NPC（有任务时出现） |
| --- | --- | --- |
| 寒冰矿场 `aixiscene3` | 查德 (6) | 亚诺 (4)、凯伦 (5)、哈鲁达 (8) |
| 水晶矿洞 `aixiscene5` | — | 飞天犬 (140)、雪雾怪 (141)、雪雾怪 (143)、雪雾怪 (144) |
| 选择之殿 `choicetemple` | — | 赤月 (383)、炎风 (384) |
| 制衣间 `clothesshop2` | 妮可 (106) | — |
| 魔方迷宫 `cubemansion` | 哈米 (124) | — |
| 钻石屋 `diamondisland1` | — | 莱特 (366)、古力德 (54)、威尔斯 (367) |
| 钻石大街 `diamondisland2` | — | 莱特 (366)、天使莱特 (374)、黑化拉贝尔 (369)、威尔斯 (367) |
| 钻石宝殿 `diamondisland3` | — | 拉贝尔 (86)、莱特 (366)、天使莱特 (374)、兰丁 (94)、弗洛拉 (194)、威尔斯 (367)、古力德 (54)、黑化拉贝尔 (369) |
| 光明崖 `diamondisland4` | — | 天使莱特 (374) |
| 虚无长廊 `emptyspace1` | — | 小宇宙 (249)、小星猴 (246)、猪阿饼 (247)、猪阿酱 (248)、风云 (253)、受伤的小猴子 (254)、大盗海狸 (260) |
| 修炼广场 `emptyspace2` | 风云 (253) | 大盗海狸 (260) |
| 通幽小路 `fbaixi3` | — | 受伤的村民 (88)、受伤的村民 (89) |
| 冰宫前殿 `fbaixi7` | — | 守门人 (85) |
| 冰风地带 `fbaixi8` | — | 尤莱亚 (84) |
| 风暴核心 `fbaixi9` | — | 尤莱亚 (84) |
| 下水道深处 `fbsiwude4` | — | 蚁仔 (159) |
| 莎华之间 `fbsuolide7` | — | 帕丁 (123)、曼珠沙华 (137) |
| 恶人山道 `fightkingwar2` | — | 刘备 (588) |
| 恶人山顶 `fightkingwar3` | 关羽 (599) | 刘备 (588) |
| 长坂坡 `fightkingwar4` | — | 刘备 (588)、赵云 (671) |
| 乱石战场 `fightkingwar5` | — | 刘备 (588)、张飞 (687) |
| 虎牢关 `fightkingwar7` | — | 刘备 (588) |
| 模拟空间 `fightlab` | 裁判 (439) | — |
| 斗魂平原 `fightspace1` | — | 小星猴 (246)、猪阿饼 (247)、猪阿酱 (248)、小猴子 (258)、神秘人 (259)、大盗海狸 (260) |
| 环宇核心 `fightspace2` | — | 饼饼 (263)、酱酱 (264)、星云大圣 (271)、麦斗王 (273) |
| 禁闭之门 `fightspace3` | — | 梅卡 (272) |
| 魔力工坊 `furnitureshop2` | 罗伯特 (105) | — |
| 巨人山脚 `giantcordillera1` | — | 小熊 (283)、伊尼 (284)、小蜜蜂 (286)、小犀 (608)、小猫 (287)、小蛇 (288) |
| 小熊之家 `giantcordillera2` | — | 小熊 (283)、伊尼 (284) |
| 巨人山腰 `giantcordillera3` | — | 托比 (289) |
| 科学研究所 `giantcordillera4` | — | 科学伊尼 (290) |
| 巨人山顶 `giantcordillera5` | — | 伊尼 (284)、神武月 (127)、科学伊尼 (290)、战无炎 (303) |
| 山脉核心 `giantcordillera6` | — | 伊尼 (284)、科学伊尼 (290)、黑化之魂 (318)、山脉之魂 (317)、托比 (289) |
| 快乐方舟 `happyark` | 雷米 (128) | — |
| HELLO学院 `helloschoolcopy` | 普伦博士 (300) | — |
| 缤纷泡泡街 `hubblebubblestreet1` | 彩虹预言者 (348) | 绿叶小粽 (345)、黄金小粽 (347) |
| 机械废墟 `junglecopy` | — | 普伦博士 (300) |
| 传送核心 `maintown1copy` | — | 修罗 (865)、哈鲁达 (8) |
| 奇迹谷底 `mantenxiagu1` | — | 犀牛小怪 (320)、小小鸟 (321)、犀牛战壕 (322)、月月鸟 (323)、犀牛鸟 (349)、小奥拉 (316) |
| 回忆之林 `mantenxiagu2` | — | 小嘟 (332)、嘟嘟护法 (333)、嘟嘟护法 (336)、嘟嘟长老 (334)、月鸟 (335)、月月鸟 (323)、犀牛鸟 (349)、弗洛拉 (194)、大鹏鸟 (338) |
| 小小鸟森林 `mantenxiagu3` | — | 鸟族战士 (339)、弗洛拉 (194)、异星使者维克 (13)、治安官哈德 (26)、拉贝尔 (86)、小小鸟 (321)、黑化巨翅金鹏 (350)、念 (351)、神武月 (379) |
| 深渊魔域 `msevenstar5` | — | 幻灵 (858) |
| 浮岛废墟 `msevenstar6` | — | 幻灵 (857)、幻灵 (858)、圣光 (860)、神秘人 (866) |
| 亚比精英赛场 `outstandingyabiarena` | 精英赛主持人 (299) | — |
| 飞碟美食塔 `restaurant` | — | 杰米 (73)、霹雳河豚 (74) |
| 科技厨房 `restaurant2` | 杰米 (107) | — |
| 时空隧道 `spacetime` | 月耀 (58) | — |
| 章鱼海湾 `starsea1` | 路杰斯 (352) | 潜水小鲸 (354)、星云鱼 (353)、菲莉 (355)、迪瑞恩 (356) |
| 海洋密室 `starsea2` | — | 潜水小鲸 (354)、菲莉 (355)、星云鱼 (353) |
| 星云宝地 `starsea3` | — | 小雨滴 (360)、潜水小鲸 (354)、菲莉 (355)、迪瑞恩 (356)、星云鱼 (353) |
| 星星广场 `starsquare` | 哈米 (124)、雷米 (128) | — |
| 战队要塞 `teambattlefort` | 指挥官瑞斯 (340) | — |
| 雪人祭坛 `temple15` | 冰晶女巫 (427) | — |
| 玄武大道 `temple4` | — | 玄武分身 (313) |
| 玄武大道 `temple8` | — | 玄武分身 (313) |
| 玄武大道第四重 `temple9` | — | 玄武灵兽 (314) |
| 念之大厅 `thinktowerofnian` | — | 念 (378)、神武月 (379)、战无炎 (303)、邪念 (401) |
| 道具店 `toolshopcopy` | 米娜 (301) | — |
| 堡垒登陆舱 `viparena1` | 蓝宝卫兵 (221) | — |
| 射击平台 `viparena4` | 蓝宝卫兵 (221) | — |
| 秘密实验室 `viparena7` | 蓝宝卫兵 (221) | — |
| 水帘洞 `waterhole` | — | 小星猴 (246)、大盗海狸 (260)、星云行者 (267)、小鱼儿 (270) |
| 明星赛事活动馆 `yabiexhibition` | 司仪魂斗鱼 (195) | — |
| 幽冥前殿 `youanmingzhou1` | — | 拉贝尔 (86)、神武月 (127)、拉贝尔 (376)、黑达战士 (377)、念 (378)、神武月 (379) |
| 幽冥大殿 `youanmingzhou2` | — | 炎风 (182)、赤月 (183)、神武月 (127)、黑化战无炎 (386)、念 (378)、赤月 (383)、炎风 (384)、兰丁 (385)、弗洛拉 (387)、拉贝尔 (376)、神武月 (379)、战无炎 (303) |
| 太阳之殿 `youanmingzhou3` | — | 炎风 (182)、战无炎 (303)、炎魔 (390) |
| 月亮之殿 `youanmingzhou4` | — | 赤月 (183)、神武月 (127)、赤月 (398)、金刚库巴 (87)、冰拳艾司 (64)、浮云尊者 (233)、浮云尊者 (399)、月魔 (391) |
| 命运之殿 `youanmingzhou5` | — | 战无炎 (303)、神武月 (127) |
| 太阳神殿 `zodiac0` | — | 阿波罗 (871)、飞飞龙 (872) |
| 响雷神殿 `zodiac1` | — | 飞飞龙 (872)、托尔 (873) |

### NPC challenges

The eleven NPCs of the 2013 `ChallengeConfig` accept a challenge from their
menu: three modes (新手训练, 小试身手, 勇士挑战), and one 欢乐弹珠 a day for a
win.

| NPC | Room |
| --- | --- |
| 异星使者维克 (13) | 传送核心 |
| 芭芭拉 (35) | 奥拉广场 |
| 骑士团卫兵 (145) | 蓝宝石要塞 |
| 普伦博士 (14) | HELLO学院 |
| 米娜 (3) | 道具店 |
| 治安官哈德 (26) | 极速俱乐部 |
| 军需官亨特 (142) | 蓝宝石要塞 |
| 安娜 (32) | 家具店 |
| 依依 (31) | 服装店 |
| 机械师马赫 (172) | 蓝宝石要塞 |
| 上古使者 (312) | 灵兽宫 |

## Functions of the places

The 功能 the 2012 world map lists for each place:

| 地点 | 功能 | 状态 |
| --- | --- | --- |
| 指挥中心 | 新手报到 | 可用 (the newbie quest) |
| 指挥中心 | 指挥航行、管理星球 | 不可用 (the room's surviving file is later and has no button for them) |
| 传送核心 | 异星传送枢纽 | 可用 (opens the world map) |
| 传送核心 | 冒险协会 | 不可用 |
| 传送核心 | 奥拉之辉融合 | 部分 (a step of the quests 257 and 258, whose scripts are lost) |
| 极速俱乐部 | 教官先锋队 | 不可用 (its talk works; joining does not) |
| 主题公园 | 舞会神秘来客、疯狂可乐盖、小问大冒险 | 不可用 (the redrawn room has no buttons for them; 小问大冒险's panel survives but is a timed game of several players) |
| 生态园 | 捕捉小动物 (动物捕捉: its panel with 购买道具 and the map of 大地乐园, 天空乐园, 海洋乐园, 狗狗之家; the 捕鱼 spot its 海洋乐园) | 可用 |
| 生态园 | 动物协会 | 不可用 |
| 生态园 | 狗狗之家 | 可用 (the fourth map of 动物捕捉) |
| 奥拉广场 | 财富小管家 | 可用 (the later machine's panel: 晶豆储蓄, 奥币铸造星币, 碎片铸造星币) |
| 奥拉广场 | 设置密码保护、最强训练师召集令 | 不可用 (the redrawn room has no buttons for them) |
| HELLO学院 | HELLO技能学习 | 可用 |
| 十字大道 | 爱心捐赠、爱心领取 | 可用 |
| 十字大道 | 星际兑换机 | 不可用 |
| 太空港 | 组建战队、执行战队任务、发布招募信息、战队荣誉排行 | 不可用 |
| 银河商会 | 职业亚比进化 | 可用 |
| 银河商会 | 星际航线 | 不可用 |
| 银河商会 | 乔布斯的宝藏 | 不可用 (its 2012 panel is lost) |
| 蓝宝石要塞 | 蓝宝石礼包派送 | 可用 |
| 蓝宝石要塞 | 亚比骑乘训练 | 可用 (训练官卢卡斯's 坐骑训练机, its panel of 2021; every 亚比 of the ride list is a 坐骑 without training, so it answers 你选择的亚比已经训练过了) |
| 蓝宝石要塞 | 财富小管家、祈愿图腾 | 部分 (the room is a later copy without them; the 财富小管家 works in 奥拉广场) |
| 奥拉之树 | 星愿气球、奥拉星历史漫画 | 可用 |
| 战斗星域 | 亚比对战空间 | 不可用 (the room's own function is lost; 亚比对战 is on the 信息卡 in 联机模式) |
| 流星购物街 | 购买服装、家具、道具和树苗 | 可用 |
| 亚比研究中心 | 亚比融合 (贝鲁特; the 元生体 hatch in their places' 孵化器)、神奇摇摇树 | 可用 |
| 亚比研究中心 | 亚比天赋改造 | 部分 (the 天赋改造机 opens the 天赋启迪 of January 2013; the 天赋改造 panel itself is lost) |
| 亚比研究中心 | 亚比训练 | 可用 (the pad of the two 亚比, as the HELLO's 亚比训练) |
| 亚比研究中心 | 亚比超进化 | 不可用 |
| 星光游乐场 | 欢乐券兑换 | 可用 |
| 欢乐岛 | 亚比成长计划、百田卡通大剧院 | 可用 |
| 欢乐岛 | 魔法秋游 | 不可用 (the room is of December 2012, after the 秋游, and has no button for it) |
| 百田大剧场 | 观看卡通片 | 可用 (the two 奥拉星 films that survive) |
| 亚比协会 | 亚比协会 | 不可用 |
| 上古神殿 | 龙族力量、小雪球成长记、赤羽修行者修炼台 | 不可用 (their panels are lost) |
| 大地迷城 | 挑战友人契约书 | 可用 |
| 糖果星 | 小白吐获得、守护者超T兔 | 可用 |
| 糖果星 | 糖糖获得 | 可用 (大战TT兔: each game gives 1 + 2 + … 积分 for the 关 passed; 20 积分 for 糖糖, once) |
| 骑士王国 | 骑士王座 | 可用 |
| M7星云 | 传说斗士、万龙之王 | 不可用 (唤醒传说斗士 of December 2012 was a button of 古代遗迹, whose surviving file is of August 2013; 万龙之王 was a 2012 充值活动) |
| 惊雷道馆 | 踢馆！挑战幻雷！、雷霆之塔 | 可用 |
| 惊雷道馆 | 幻雷的试炼 | 可用 |
| 炼火道馆 | 踢馆！挑战幻炎！ | 可用 |
| 炼火道馆 | 爆发力大冲击 | 可用 |
| 炼火道馆 | 最强力量PK战 | 不可用 (its panel opens empty; its fights, record, 祝福 and rewards are not answered) |
| 御水道馆 | 踢馆！挑战幻流！ | 可用 |
| 御水道馆 | 幻流特训营 | 可用 |
| 御水道馆 | 最强防御pk战 | 可用 (30 局 standing a number of rounds with the first 亚比; the day's rewards at 5, 10, 15, 20 局) |
| 命运道馆 | 踢馆！挑战幻冥！、命运玩偶 | 可用 |
| 命运道馆 | 玩偶迷阵 | 可用 (命运玩偶 one after another, 幻冥's 战斗祝福 on both sides; the run's 战斗力评价 and its rewards) |
| 光明道馆 | 踢馆！挑战幻光、友情的试炼 | 不可用 (need a team of two and a friend's 亚比) |
| 光明道馆 | 我的伙伴我做主 | 不可用 (its panel opens empty; its mini game's 积分 and the 幻光 bought for 10000 of them are not answered) |

### Activities of the planets

| 活动 | 地点 | 奖励 |
| --- | --- | --- |
| 摩么卡的养成 | 魔术之星 | 摩么卡 evolves into 魔幻摩卡 |
| 亚伦的养成 | 风车城 | 亚伦 evolves into 利克亚伦 |
| 巨锁石灵的机关 | 族长之帐 (雅克星) | 小石灵 |
| 召唤达黑黑, 猜弹珠 | 海枯之山 | 小黑黑 |
| 白京京之心 | 海枯之海 | 小京京 |
| 独角兽: 先哲, 铠甲, 仙林, 飞天独角兽 | 独角之星 | evolutions of 小独角兽, the 飞天 egg |
| 粗心的卡索 | 索尔石城 (云端王国) | 卡索 |
| 阿莫扭蛋机 | 大地迷城 | 阿莫 |
| 钓星星的波波嘟 | 海洋幻境 | 波波嘟 |
| 黑暗三连星 (鲁曼, 纳兹, 塞娅; 星魂法阵 for 星币) | 黑暗星穴 | 30 星魂 for the boss's egg (鲁迪, 纳德, 塞西) |
| 魔将挑战 (魔洛 Lv100, five tries a day; or 160 星币) | 深渊之门 | 格洛's egg |
| 修罗, 凯撒 (Lv100, then Lv120; the day's 15-minute 光之 / 暗之祝福; or 200 星币) | 奇灵神树 (修罗 offers them) | 伊修's, 阿凯's egg |
| 召唤奇灵王 (三色奇灵玉 from three trials or 星币, then the 终极挑战) | 奇灵神树 (修罗 offers it) | 小奇灵's egg |
| 天空之神 (two stages, then 拉诺斯, five tries a day; or 星币) | 天神圣殿 (拉诺斯 offers it) | 诺斯's egg |
| 地之神兽 施瓦辛格 (with one or two of 雏菊仙子, 莫莫亚特, 友人契约书, 多古拉伯爵; five tries a day; or 200 星币) | 零时迷城 (施瓦辛格 offers it) | 辛格's egg |
| 海洋之神 波塞冬 (five tries a day; or 200 星币) | 海洋神域 (波塞冬 offers it) | 波塞's egg |
| 魔龙之战 (赤翼魔龙王's three 分身 in turn, five tries a day; or the three 魂石 for 星币) | 深渊魔域 (赤翼魔龙王 offers it) | 小魔龙's egg |
| 狼王再现, 夜王回归 (February 2013: three 分身 each, Lv80, 90 and 100, for the three 剑魂 or 封印, or 70–130 星币 each; a lost fight with the first lights a 光之星 or 幽之星, one a day, and three give its item; then 召唤狼王 / 召唤夜王; with both, the 终极试炼 against the two kings at Lv100, five tries a day) | 魂塔顶端 (狼王迪洛斯 and 夜王狄米特 offer them) | 洛洛's, 小夜's egg |
| 武神战争: 黄巾军旗 (黄巾战魂 from 恶人山道's 黄巾小兵; 注入 to make a 黄巾小兵 张角 or 张梁), 关羽, 赵云, 张飞, 诸葛亮, 吕布, 刘备, 将军令 (five a day), 将军榜 | 武神大陆 | the generals' eggs |

The wild 亚比 of these planets drop the items the activities need (弹珠,
大力锤, 扭蛋币, 铠甲碎片, 糖果, 骑士卡, 黄巾战魂). The eggs of the activities go into the
亚比孵化器. The 四大灵兽's guide (挑战攻略 in 寒冰王座's way, 赤羽神功's room) shows each beast and
where it is challenged.

## Quests

### Newbie quest

Tasks 135, 140 and 150, after the official walkthrough of December 2011:

| Step | Where | What |
| --- | --- | --- |
| 136 | 指挥中心 | the HELLO sends the player to 司令官麦哲伦: the 达斯特 attack the ship |
| 137 | 指挥中心 | choose the first 亚比: 滴滴, 吉拉 or 兔小子 |
| 138 | 机械废墟 | the VS film, a lesson fight against the 达斯特's 达达 |
| 139 | 指挥中心 | 麦哲伦 on the 奥拉之辉, its story as three films (or skip) |
| 142 | 亚比研究中心 | 贝鲁特博士 sends the player for 亚比球 |
| 143 | 道具店 | buy 5 普通亚比球 from 米娜 |
| 144 | 亚比研究中心 | 贝鲁特 teaches catching |
| 145 | 冰河瀑布 | catch a 朵朵兔 |
| 146–147 | HELLO学院 | 普伦博士 gives the HELLO, the film of what a HELLO does |
| 152 | 指挥中心 | the ceremony; 2000 晶币 and HELLO experience |

### Story, side and guide quests

After the newbie quest the task panel offers these 182 quests. Each runs its
own original script (`taskext/task<id>`), with its films, comics and panels.
The newbie quest, 1214 and 1219 are played from start to end by the
automated tests; for the other quests the tests open the first step. Quests whose script needs a service the
revival does not have may stop partway; see [Known gaps](#known-gaps).

1411, 1416 and 1652 (the 蓝宝骑士 quests of 修普森曼 and 艾尔利克) were
withdrawn in November 2011 and so were not in the 2013 client; the revival
brings them back, with their conversations rewritten (marked RECONSTRUCTED).
The 幻龙星系 quests (3022–3346) lost their starting data in the later client;
their starts are reconstructed too.

| 编号 | 任务 | 系列 | 主线/支线 | 前置任务 |
| --- | --- | --- | --- | --- |
| 2 | 寻找辉之碎片 | 辉之碎片 | 主线 | — |
| 8 | 无法解开的封印 | 辉之碎片 | 主线 | 2 |
| 21 | 冰与火之力 | 辉之碎片 | 主线 | 8 |
| 56 | 猫王子的请求 | 猫王子与沙都 | 主线 | 150 |
| 59 | 干涸的河床 | 猫王子与沙都 | 主线 | 56 |
| 65 | 神秘的象形符号 | 猫王子与沙都 | 主线 | 59 |
| 71 | 索里克斯的迷题 | 猫王子与沙都 | 主线 | 65 |
| 76 | 王之考验的由来 | 猫王子与沙都 | 主线 | 88 |
| 81 | 沙都的守护神 | 猫王子与沙都 | 支线 | 76 |
| 88 | 鲁阿鲁的花之情结 | 猫王子与沙都 | 主线 | 71 |
| 160 | 思伍德区的辉之碎片 | 思伍德 | 主线 | 150 |
| 166 | 多克特的实验 | 思伍德 | 主线 | 160 |
| 178 | 扭扭军团登场 | 思伍德 | 支线 | 194 |
| 189 | 卡波的升云炮 | 思伍德 | 主线 | 166 |
| 194 | 终极进化的木木鸟 | 思伍德 | 主线 | 189 |
| 219 | 闪光泡泡珠的争夺 | 思伍德 | 主线 | 150 |
| 228 | 可恶的达斯特黑市 | 思伍德 | 主线 | 219 |
| 241 | 勇敢前进 | 思伍德 | 主线 | 228 |
| 250 | 正义与善良 | 思伍德 | 主线 | 241 |
| 267 | 我要等待烈焰鸟 | 烈焰鸟 | 主线 | 150 |
| 280 | 火山山脚的谜题 | 烈焰鸟 | 主线 | 267 |
| 333 | 奇迹般的烈焰鸟 | 烈焰鸟 | 主线 | 280 |
| 346 | 苏醒的千年传说 | 烈焰鸟 | 主线 | 333 |
| 698 | 谜之小翼鸟事件 | 谜之小翼鸟 | 支线 | 194 |
| 724 | 宇宙风暴-上古神殿 | 上古神殿 | 主线 | 150 |
| 749 | 大妖之怒-上古神殿 | 上古神殿 | 主线 | 724 |
| 787 | 木石之境 | 上古神殿 | 主线 | 749 |
| 805 | 分离 | 上古神殿 | 主线 | 787 |
| 1028 | 新的开始 | 上古神殿 | 主线 | 805 |
| 1034 | 遇见小宇宙 | 星云 | 支线 | 150 |
| 1039 | 奇异的星云 | 星云 | 主线 | 150 |
| 1050 | 拜师学艺 | 星云 | 主线 | 1039 |
| 1068 | 神秘的大盗 | 星云 | 主线 | 1050 |
| 1096 | 饼饼与酱酱的故事 | 星云 | 支线 | 150 |
| 1106 | 斗魂星云棒 | 星云 | 主线 | 1068 |
| 1119 | 真相 | 星云 | 主线 | 1155 |
| 1145 | 尘封的过去(海狸支线) | 星云 | 支线 | 1068 |
| 1155 | 大闹环宇核心 | 星云 | 主线 | 1106 |
| 1214 | 传说中的美丽山脉 | 巨人山脉 | 主线 | 150 |
| 1219 | 奇怪的山脉 | 巨人山脉 | 主线 | 1214 |
| 1230 | 巨人山脉的传说神秘卷轴 | 巨人山脉 | 支线 | 1219 |
| 1237 | 山脉传说 | 巨人山脉 | 主线 | 1219 |
| 1255 | 隐藏的高手 | 巨人山脉 | 主线 | 1237 |
| 1282 | 决战山顶 | 巨人山脉 | 主线 | 1255 |
| 1294 | 黑化之魂 | 巨人山脉 | 主线 | 1282 |
| 1321 | 挑战玄武 | 引导 | 引导 | 150 |
| 1343 | 蔓藤峡谷风云 | 蔓藤峡谷 | 主线 | 150 |
| 1378 | 回忆之林 | 蔓藤峡谷 | 主线 | 1343 |
| 1393 | 小小鸟的森林 | 蔓藤峡谷 | 主线 | 1378 |
| 1411 | 赤火斗士的意志 | 蓝宝骑士（赤火） | 主线 | 150 |
| 1416 | 赤火剑的力量 | 蓝宝骑士（赤火） | 主线 | 1411 |
| 1427 | 巨翅金鹏 | 蔓藤峡谷 | 主线 | 1393 |
| 1434 | 古老的传说 | 古老的传说 | 主线 | 150 |
| 1446 | 密室的秘密 | 古老的传说 | 主线 | 1434 |
| 1461 | 喜欢雨的亚比 | 古老的传说 | 支线 | 1446 |
| 1470 | 密室救人 | 古老的传说 | 主线 | 1446 |
| 1477 | 宝藏争夺战 | 古老的传说 | 主线 | 1470 |
| 1507 | 钻石岛危机 | 钻石岛 | 主线 | 150 |
| 1515 | 神秘的力量 | 钻石岛 | 主线 | 1507 |
| 1540 | 光明力量 | 钻石岛 | 主线 | 1515 |
| 1549 | 爱与光明 | 钻石岛 | 主线 | 1540 |
| 1561 | 幽暗冥州 | 幽暗冥州 | 主线 | 150 |
| 1570 | 营救神武月 | 幽暗冥州 | 主线 | 1561 |
| 1581 | 解救战无炎 | 幽暗冥州 | 主线 | 1570 |
| 1588 | 上古守护者试炼 | 幽暗冥州 | 主线 | 1581 |
| 1596 | 太阳之殿 | 幽暗冥州 | 主线 | 1588 |
| 1606 | 月亮之殿 | 幽暗冥州 | 主线 | 1596 |
| 1633 | 命运之殿 | 幽暗冥州 | 主线 | 1606 |
| 1641 | 与念决战 | 幽暗冥州 | 主线 | 1633 |
| 1652 | 纯白之翼的信念 | 蓝宝骑士（纯白之翼） | 主线 | 150 |
| 1711 | 大漠守护者 | 大漠守护者 | 支线 | 88 |
| 1742 | 一年一度的美食节 | 美食之星 | 主线 | 150 |
| 1750 | 奇怪的食材 | 美食之星 | 主线 | 1742 |
| 1764 | 露丝的阴谋？ | 美食之星 | 主线 | 1750 |
| 1772 | 寻找解药 | 美食之星 | 主线 | 1764 |
| 1806 | 设计菲莉 | 美食之星 | 主线 | 1772 |
| 1815 | 美食节的大决战 | 美食之星 | 主线 | 1806 |
| 1827 | 初遇多多王子 | 多多王子 | 主线 | 150 |
| 1835 | 硬闯皇宫 | 多多王子 | 主线 | 1827 |
| 1843 | 被诅咒的面具 | 支线 | 支线 | 194 |
| 1851 | 营救王子 | 多多王子 | 主线 | 1835 |
| 1859 | 逃出地牢 | 多多王子 | 主线 | 1851 |
| 1867 | 王子的决定 | 多多王子 | 主线 | 1859 |
| 1877 | 新的开始 | 多多王子 | 主线 | 1867 |
| 1891 | 童心的考验 | 童话之星 | 主线 | 150 |
| 1899 | 被抢走的童话之书 | 童话之星 | 主线 | 1891 |
| 1915 | 丑小鸭 | 童话之星 | 主线 | 1899 |
| 1924 | 三只小猪 | 童话之星 | 主线 | 1915 |
| 1934 | 童话之星大作战 | 童话之星 | 主线 | 1924 |
| 1946 | 童心的力量 | 童话之星 | 主线 | 1934 |
| 1959 | 摩么卡的魔术表演 | 魔术之星 | 主线 | 150 |
| 1969 | 突如其来的事故 | 魔术之星 | 主线 | 1959 |
| 1986 | 多克特的要挟 | 魔术之星 | 主线 | 1969 |
| 1995 | 智斗多克特 | 魔术之星 | 主线 | 1986 |
| 2010 | 海枯星的传说 | 海枯之星 | 主线 | 150 |
| 2018 | 可爱的白京京 | 海枯之星 | 主线 | 2010 |
| 2026 | 小镇破坏的真相 | 海枯之星 | 主线 | 2018 |
| 2032 | 海枯之星的故事 | 海枯之星 | 主线 | 2026 |
| 2046 | 海枯之山的秘密 | 海枯之星 | 主线 | 2032 |
| 2055 | 海枯之石 | 海枯之星 | 主线 | 2046 |
| 2072 | 透明的豆豆 | 豆豆 | 主线 | 150 |
| 2080 | 神秘消失的豆豆 | 豆豆 | 主线 | 2072 |
| 2088 | 繁花之地 | 豆豆 | 主线 | 2080 |
| 2097 | 黑色的影子 | 豆豆 | 主线 | 2088 |
| 2129 | 豆豆的身世 | 豆豆 | 主线 | 2097 |
| 2138 | 光与暗的传说 | 豆豆 | 主线 | 2129 |
| 2175 | 千年之战 | 凯撒 | 主线 | 150 |
| 2183 | 凯撒之力 | 凯撒 | 主线 | 150 |
| 2210 | 锻炼我们吧！修罗 | 凯撒 | 主线 | 150 |
| 2218 | 凯撒的计谋 | 凯撒 | 主线 | 150 |
| 2227 | 修罗的觉悟 | 凯撒 | 主线 | 150 |
| 2236 | 最后的决战 | 凯撒 | 主线 | 150 |
| 2289 | 倔强的麦提 | 神器 | 主线 | 150 |
| 2298 | 传说中的神器 | 神器 | 主线 | 2289 |
| 2314 | 神斧临世 | 神器 | 主线 | 2298 |
| 2322 | 黑暗能量 | 神器 | 主线 | 2314 |
| 2339 | 真相大白 | 神器 | 主线 | 2322 |
| 2347 | 神器的威力 | 神器 | 主线 | 2339 |
| 2364 | 宇宙最大的糖果工厂 | 糖果星 | 主线 | 150 |
| 2375 | 糖爷爷的主意 | 糖果星 | 主线 | 2364 |
| 2402 | 糖果工厂，我们来了！ | 糖果星 | 主线 | 2375 |
| 2411 | 糖果博物馆的阴谋 | 糖果星 | 主线 | 2402 |
| 2424 | 糖果博物馆开放了！ | 糖果星 | 主线 | 2411 |
| 2434 | 决战机器兔！ | 糖果星 | 主线 | 2424 |
| 2443 | 我要成为冒险王 | 冒险王 | 主线 | 150 |
| 2451 | 悬赏通缉令 | 冒险王 | 主线 | 2443 |
| 2468 | 怕光的通灵巫师 | 冒险王 | 主线 | 2451 |
| 2477 | 营救亚伦计划 | 冒险王 | 主线 | 2468 |
| 2499 | 谷底的秘密 | 冒险王 | 主线 | 2477 |
| 2507 | 可怕的复活报告 | 冒险王 | 主线 | 2499 |
| 2524 | 奇怪的时空错乱 | 时空 | 主线 | 150 |
| 2531 | 泽秒的秘密 | 时空 | 主线 | 2524 |
| 2544 | 真相大白 | 时空 | 主线 | 2531 |
| 2552 | 凯撒复活 | 时空 | 主线 | 2544 |
| 2583 | 兄弟团聚 | 时空 | 主线 | 2552 |
| 2592 | 时空大决战 | 时空 | 主线 | 2583 |
| 2620 | 学院里的风波 | 骑士学院 | 主线 | 150 |
| 2628 | 新来的罗格老师 | 骑士学院 | 主线 | 2620 |
| 2651 | 初识永夜族 | 骑士学院 | 主线 | 2628 |
| 2659 | 离奇消失的同学 | 骑士学院 | 主线 | 2651 |
| 2681 | 真实身份 | 骑士学院 | 主线 | 2659 |
| 2690 | 骑士的荣耀 | 骑士学院 | 主线 | 2681 |
| 2705 | 尖叫游乐园 | 尖叫游乐园 | 主线 | 150 |
| 2714 | 尖叫大赛开幕式 | 尖叫游乐园 | 主线 | 2705 |
| 2724 | 尖叫大赛开始啦 | 尖叫游乐园 | 主线 | 2714 |
| 2733 | 勇闯鬼屋 | 尖叫游乐园 | 主线 | 2724 |
| 2764 | 尖叫大赛总决赛 | 尖叫游乐园 | 主线 | 2733 |
| 2773 | 决战红魔 | 尖叫游乐园 | 主线 | 2764 |
| 2786 | 我要成为大明星 | 音乐之都 | 主线 | 150 |
| 2795 | 购票风波 | 音乐之都 | 主线 | 2786 |
| 2804 | 演唱会开始了 | 音乐之都 | 主线 | 2795 |
| 2812 | 打探内幕 | 音乐之都 | 主线 | 2804 |
| 2835 | 白灵族与永夜族 | 音乐之都 | 主线 | 2812 |
| 2843 | 大战绿焰 | 音乐之都 | 主线 | 2835 |
| 2871 | 奇奇回来啦 | 白灵圣殿 | 主线 | 150 |
| 2879 | 永夜魂塔的裂缝 | 白灵圣殿 | 主线 | 2871 |
| 2906 | 被袭击的白灵族 | 白灵圣殿 | 主线 | 2879 |
| 2914 | 猜猜夜王会是谁 | 白灵圣殿 | 主线 | 2906 |
| 2932 | 夜王复活 | 白灵圣殿 | 主线 | 2914 |
| 2940 | 狼王与夜王的决斗 | 白灵圣殿 | 主线 | 2932 |
| 2997 | 海底七夕大作战 | 海底七夕大作战 | 主线 | 2940 |
| 3022 | 云端王国·魔法羽林 | 幻龙星系·云端王国 | 主线 | 150 |
| 3049 | 云端王国·星芒小镇 | 幻龙星系·云端王国 | 主线 | 3022 |
| 3062 | 云端王国·索尔石城 | 幻龙星系·云端王国 | 主线 | 3049 |
| 3079 | 云端王国·参天瀑布 | 幻龙星系·云端王国 | 主线 | 3062 |
| 3091 | 云端王国·天神圣殿 | 幻龙星系·云端王国 | 主线 | 3079 |
| 3108 | 大地迷城·迷城河畔 | 幻龙星系·大地迷城 | 主线 | 150 |
| 3121 | 大地迷城·雏菊平原 | 幻龙星系·大地迷城 | 主线 | 3108 |
| 3132 | 大地迷城·伯爵城堡 | 幻龙星系·大地迷城 | 主线 | 3121 |
| 3148 | 大地迷城·零时迷城 | 幻龙星系·大地迷城 | 主线 | 3132 |
| 3174 | 海洋幻境·幻之结界 | 幻龙星系·海洋幻境 | 主线 | 150 |
| 3191 | 海洋幻境·迦娜的梦境 | 幻龙星系·海洋幻境 | 主线 | 3174 |
| 3208 | 海洋幻境·外海之域 | 幻龙星系·海洋幻境 | 主线 | 3191 |
| 3232 | 海洋幻境·内海之域 | 幻龙星系·海洋幻境 | 主线 | 3208 |
| 3252 | 海洋幻境·海洋神域 | 幻龙星系·海洋幻境 | 主线 | 3232 |
| 3307 | 白夜山·白昼峡谷 | 幻龙星系·白夜山 | 主线 | 150 |
| 3319 | 白夜山·迷境花园 | 幻龙星系·白夜山 | 主线 | 3307 |
| 3330 | 新的伙伴朵朵兔 | 引导 | 引导 | 150 |
| 3332 | 我想要亚比球 | 引导 | 引导 | 150 |
| 3336 | 亚比饮食小站 | 引导 | 引导 | 150 |
| 3338 | 赚钱引导 | 引导 | 引导 | 150 |
| 3346 | 白夜山·魔箭城 | 幻龙星系·白夜山 | 主线 | 3319 |

Not available: 神奇的霹雳 (418) and the first 奥拉大战 (911–977, January 2011),
whose definitions and conversations are lost.

## Bosses

### 守护者 and event bosses

Each boss stands in its room as its own picture (or dressed as its 亚比 where
the picture is lost), wakes, talks and fights as in the later client. A
click offers the fight; the forms are fought in order, a loss starts again
from the first, and beating the last form gives the 亚比蛋 of the boss's
line. Bosses cannot be caught. A 守护者 whose 2012 套装 is known (金刚库巴,
冰霜之王 and 12 others), and the generals of 武神大陆 (the 武神套装), sometimes
leave a part of it the player has not got (one win in five, RECONSTRUCTED),
shown at the end of the battle. In the 形态 column, the number before each
name is the battle id (variant × 10000 + species). The levels come from the
2013 boss table (`BossTimeHelper`) where a boss is in it; the others are
estimates.

| 守护者 | 场景 | 形态（亚比编号：等级） |
| --- | --- | --- |
| 冰拳艾司 | 寒冰洞 `aixiscene6` | 20087 冰拳艾司 Lv80 |
| 星光角斗士 | 星光游乐场 `amusementpark` | 20427 星光角斗士 Lv60 |
| 沙麒麟 | 风暴沙漠 `suolide5` | 10090 沙麒麟 Lv60，20090 沙麒麟 Lv80 |
| 木面侠 | 原始林地 `siwude3` | 10093 木面侠 Lv60，20093 木面侠 Lv80 |
| 山脉之魂 | 巨人山脚 `giantcordillera1` | 20418 山脉之魂 Lv100 |
| 火花龙 | 火山山脚 `feier2` | 10099 火花龙 Lv60，20099 火花龙 Lv80 |
| 合金猛将 | 数码城 `bite2` | 10102 合金猛将 Lv60，10102 合金猛将 Lv80，20102 合金猛将 Lv100 |
| 金刚库巴 | 贝壳城堡 `woerte4` | 10096 金刚库巴 Lv60，10096 金刚库巴 Lv80，20096 金刚库巴 Lv100 |
| 利刺大黄蜂 | 晨光大陆 `haiwen2` | 10108 利刺大黄蜂 Lv60，10108 利刺大黄蜂 Lv80，20108 利刺大黄蜂 Lv100 |
| 天使莱特 | 光明崖 `diamondisland4` | 10317 天使莱特 Lv80，20317 天使莱特 Lv100 |
| 雷纳瑞 | 雷鸣悬崖 `leiming4` | 10469 雷纳瑞 Lv100 |
| 魂斗鱼 | 雷鸣悬崖 `leiming4` | 10472 魂斗鱼 Lv100 |
| 浮云尊者 | 艺术广场 `yishuzhidu1` | 10475 浮云尊者 Lv100 |
| 浮云尊者 | 艺术广场 `yishuzhidu1` | 20475 浮云尊者 Lv100 |
| 童心 | 童心小屋 `fairytalestar1` | 30682 黑夜童心 Lv88，10682 黑夜童心 Lv100 |
| 神龟 | 海枯之海 `haikustar2` | 10715 远古灵龟 Lv80，20715 远古灵龟 Lv100 |
| 终极麦斗王 | 环宇核心 `fightspace2` | 14523 #4523 Lv100，11514 #1514 Lv80，11516 #1516 Lv80 |
| 暴雪山神 | 虚幻之春 `bingxuestar4` | 10757 暴雪山神 Lv80，20757 暴雪山神 Lv100 |
| 神罗麦提 | 玛雅山 `yakestar4` | 10840 神罗麦提 Lv80，20840 神罗麦提 Lv100 |
| 超T兔 | 糖果工厂 `candystar3` | 10865 超T兔 Lv80，20865 超T兔 Lv100 |
| 岩波斗魂者 | 索尔石城 `cloudstar4` | 11213 岩波斗魂者 Lv60，21213 岩波斗魂者 Lv80，31213 岩波斗魂者 Lv100 |
| 伊泽和迦娜 | 海洋神域 `mysticocean5` | 11320 伊泽 Lv100，11322 迦娜 Lv100 |
| 烈焰鸟 | 烈焰洞穴 `feier4` | 30278 烈焰鸟 Lv80 |
| 神武月 | 选择之殿 `choicetemple` | 10105 神武月 Lv80 |
| 战无炎 | 选择之殿 `choicetemple` | 10111 战无炎 Lv90 |
| 友人契约书 | 雏菊平原 `mysticearth2` | 11259 友人契约书 Lv100 |
| 猪猪超人 | 主题公园 `themepark` | 10884 猪猪超人 Lv100 |
| 满月巨灵 | 主题公园 `themepark` | 10639 满月巨灵 Lv100 |
| 赤魔导士 | 主题公园 `themepark` | 10796 赤魔导士 Lv80，20796 赤魔导士 Lv100 |
| 赤影飞狐 | 主题公园 `themepark` | 10771 赤影飞狐 Lv80，20771 赤影飞狐 Lv100 |
| 极速威锋 | 主题公园 `themepark` | 10633 极速威锋 Lv100 |
| 天之巨灵 | 主题公园 `themepark` | 10665 天之巨灵 Lv100 |
| 天女若希 | 主题公园 `themepark` | 10819 天女若希 Lv80，20819 天女若希 Lv100 |
| 翡冷翠 | 主题公园 `themepark` | 10995 翡冷翠 Lv100 |
| 年兽 | 梦剧场 `dreamhouse` | 10493 年兽 Lv100 |
| 时间之神 | 缤纷泡泡街 `hubblebubblestreet1` | 10112 小时 Lv80，20112 小时 Lv100 |
| 影刃 | 地府 `hell` | 10195 影刃 Lv80，20195 影刃 Lv100 |
| 鬼王 | 地府 `hell` | 11190 鬼王 Lv100 |
| 蓝羽灵者 | 迷境花园 `whitenight1` | 31394 蓝羽灵者 Lv60，21394 蓝羽灵者 Lv80，11394 蓝羽灵者 Lv100 |
| 多古拉伯爵 | 奥拉之树 `aolatree` | 11267 多古拉伯爵 Lv80，21267 多古拉伯爵 Lv100 |
| 猎空 | 挑战平台 `spacetimechallenge3` | 31697 猎空 Lv60，21697 猎空 Lv80，11697 猎空 Lv100 |

The event bosses of 2011–12 (主题公园's eight, 年兽, 时间之神, 影刃 and 鬼王,
友人契约书, 多古拉伯爵 the 万圣节守护者 of October 2012 at 奥拉之树) stand where their
events placed them. 蓝羽灵者 of 迷境花园 is of 11 January 2013. 猎空 came later
(August 2013, 银河冠军擂台, whose 2013 room is lost): it stands in 挑战平台.

### Other boss fights

| Where | Bosses |
| --- | --- |
| 道馆 踢馆 | 幻雷, 幻炎, 幻流 and 幻冥 at Lv100, each with its skill stone after a win |
| 念之塔 (黑暗念之塔, 幽冥大殿) | 水之封印, 火之封印, 冰之封印 and 雷之封印 with their puzzles, monsters and guardians (a chest each, once a day); with the four keys, 念之大厅: 念 Lv80, then 邪念 Lv90, and 小念's egg |
| 雷霆之塔 (惊雷道馆) | ten floors of electric 亚比 against the clock, 雷纳瑞 on the fourth, 幻雷 at the top |
| 黑星堡垒 | 震天石魔, 扭扭暗黑王, SR战士, 强袭SR, 电击八爪鱼, 黑暗守卫 on three floors (Lv50, 65, 80) |
| 时空隧道 | 100 floors of up to four 亚比 each, a BOSS厅 every tenth floor |
| 四大副本 | see below |
| Quests | the opponents of each quest's own script (达斯特's generals, task 亚比) |

## 四大副本

The four 副本 of 奥拉战记 (2011–12), entered from 艾夕区 (幻影冰宫, the ice
portal), 索里德区 (倒立金字塔), 思伍德区 (蚁族王朝) and 博物馆大厅 (恐龙博物馆).
Each has three modes (简单, 困难, 传奇) and five entries a day. A run is rated
by time (SSS to C); chests give 晶币 and 体力糖. The rooms' own scripts run
as they did: 幻影冰宫's gate and doors, 倒立金字塔's mummies, scales and
法老王, 蚁族王朝's games and 蚁将军, 恐龙博物馆's dinosaurs.

### 幻影冰宫（`fbaixi`，简单 / 困难 / 传奇：约 Lv30 / 55 / 75）

| 房间 | 野生亚比 | 战斗 | 首领 |
| --- | --- | --- | --- |
| 叹息小径 `fbaixi1` | 冰沙斗士×3 | — | — |
| 冰封路口 `fbaixi2` | 埃黑多夫×3、冰沙斗士×2 | — | — |
| 通幽小路 `fbaixi3` | 冰沙斗士×2、埃黑多夫×1、冰摩格×2、冰火巨人×1 | — | — |
| 冰霜断崖 `fbaixi4` | — | 变异库斯特 | 变异库斯特 |
| 冰封回廊 `fbaixi6` | 冰火巨人×3、冰摩格×2 | — | — |
| 冰风地带 `fbaixi8` | — | 尤莱亚 | 尤莱亚 |
| 风暴核心 `fbaixi9` | — | 拉贝尔幻影 | 拉贝尔幻影 |

### 倒立金字塔（`fbsuolide`，简单 / 困难 / 传奇：约 Lv35 / 60 / 80）

| 房间 | 野生亚比 | 战斗 | 首领 |
| --- | --- | --- | --- |
| 沙漏密室 `fbsuolide1` | — | 圣甲虫 | — |
| 石像迷阵 `fbsuolide2` | — | 石像守卫×9 | — |
| 木乃伊之棺 `fbsuolide3` | — | 帕克×3 | — |
| 阿努比斯之门 `fbsuolide4` | — | 阿努比斯 | 阿努比斯 |
| 土木战场 `fbsuolide6` | — | 扭扭大王、斯多王 | — |
| 莎华之间 `fbsuolide7` | — | 夜眼风魔、沙麒麟、曼珠沙华 | 曼珠沙华 |
| 法老王宫殿 `fbsuolide8` | — | 机械木乃伊 | 机械木乃伊 |
| 法老王宫殿 `fbsuolide9` | — | 法老王 | 法老王 |

### 蚁族王朝（`fbsiwude`，简单 / 困难 / 传奇：约 Lv40 / 65 / 85）

| 房间 | 野生亚比 | 战斗 | 首领 |
| --- | --- | --- | --- |
| 蚁穴前哨 `fbsiwude1` | — | 兵蚁×3 | — |
| 蚁兵基地 `fbsiwude2` | — | 兵蚁×3 | — |
| 蚁穴下水道 `fbsiwude3` | — | 牛角滴滴×3 | — |
| 下水道深处 `fbsiwude4` | — | 毒菇球、金刚蛤蟆、下水猛鳄 | 下水猛鳄 |
| 工蚁聚集地 `fbsiwude5` | — | 工蚁 | — |
| 蚁神守护大厅 `fbsiwude6` | — | 守护力士或守护法师 | 守护力士或守护法师 |
| 蚁神巨像 `fbsiwude9` | — | 蚁族圣斗士、蚁族魔斗士 | — |
| 蚁神殿前殿 `fbsiwude10` | — | 保斯、兰斯罗特、哥拉海德、贝德威尓 | — |
| 蚁神殿正殿 `fbsiwude11` | — | 兵蚁、蚁将军、变异蚁将军 | 蚁将军、变异蚁将军 |

### 恐龙博物馆（`fbyishuzhidu`，简单 / 困难 / 传奇：约 Lv40 / 65 / 85）

| 房间 | 野生亚比 | 战斗 | 首领 |
| --- | --- | --- | --- |
| 迅猛龙巢穴 `fbyishuzhidu1` | — | 迅猛龙 | — |
| 龙之谷 `fbyishuzhidu2` | — | 梁龙、翼龙、鱼龙 | — |
| 暴君王座 `fbyishuzhidu3` | — | 霸王龙 | 霸王龙 |
| 龙殇星墓 `fbyishuzhidu4` | — | 星辰毁灭者 | 星辰毁灭者 |

Rooms not listed have no fight of their own (puzzles, passages).

## Mini games

All game rooms of the 2013 `config.xml`. A game opens from its entrance
panel and pays 1 晶币 for every 10 points (at most 200 a game and 1,000 a
day). The 来源 column says whether the game file is a 2013 or earlier
upload or a later copy. Not every game was played to its end in testing.

| 游戏 | 房间 | 文件 | 来源 |
| --- | --- | --- | --- |
| 开心餐厅 | `gameRestaurant` | `game/restaurant` | 缺失 |
| 颜色诱惑 | `gameColorful` | `game/colorful` | 2013 年或更早 |
| 逃离金字塔游戏 | `gameFlyCat` | `game/flycat` | 后期文件 |
| 毛毛飞天记 | `gamePenguin` | `game/penguin` | 后期文件 |
| 猜灯谜 | `gameGuess` | `lanternsfestival/guessgame` | 2013 年或更早 |
| 亚比连连看 | `gameLlk` | `game/gamellk` | 后期文件 |
| 舞动全星 | `gameDance` | `game/dance` | 后期文件 |
| 张灯结彩 | `gameMakelantern` | `game/makelantern` | 2013 年或更早 |
| 团团圆圆 | `gameMakeGulePudding` | `game/makegulepudding` | 2013 年或更早 |
| 天降神饼 | `gamePickCookies` | `game/pickcookies` | 2013 年或更早 |
| 吉拉狮跳火圈（后期文件里是波鲁跳火圈：菲尔区的火圈，开始面板 `game/jumpfireringstartpanel` 缺失，重建） | `gameJumpFireRing` | `game/jumpfirering` | 后期文件 |
| 环保小卫士 | `gameRecycleGame` | `game/recyclegame` | 后期文件 |
| 奥拉大战达斯特 | `gameAolaVsDaserte` | `game/aolavsdaserte` | 缺失 |
| 小星猴走钢丝 | `gameRopedancer` | `game/ropedancer` | 2013 年或更早 |
| 滴滴快回家 | `gameDidiGoHome` | `game/didigohome` | 后期文件 |
| 兔小子拔萝卜（后期文件里是喵仔拔萝卜：思伍德区的萝卜，开始面板 `scene/siwude6_res` 后期文件） | `gamerabbit` | `game/rabbitgame` | 后期文件 |
| 粽子大作战 | `gameJumpPet` | `game/jumppet` | 2013 年或更早 |
| 抢龙鳞 | `gameRobDragon` | `game/robdragon` | 后期文件 |
| 端午龙舟赛 | `gameDragonBoat` | `game/dragonboat` | 2013 年或更早 |
| 亚比记一记 | `gameHelloYabijiyiji` | `game/yabijiyiji` | 2013 年或更早 |
| 消失的系别 | `gameHelloWhodisappear` | `game/whodisappear` | 2013 年或更早 |
| 由少到多 | `gameHelloLittle2more` | `game/littletomore` | 2013 年或更早 |
| 计时 | `gameHelloRuleanalyse` | `game/timeguessgame` | 2013 年或更早 |
| 动物保卫战 | `gamePvZ` | `game/pvz` | 后期文件 |
| 雪人跳舞 | `gameBearDance` | `game/beardance` | 后期文件 |
| 动物捕捉 | `gameCatchAnimal` | `game/catchanimal` | 后期文件 |
| 宇宙神射手 | `gameShootGame` | `game/shootgame` | 后期文件 |
| 卖蛋糕小达人 | `gameMakeCake` | `game/makecake` | 后期文件 |
| 灌篮高手 | `gameSlamDunk` | `game/slamdunk` | 后期文件 |
| 跳伞 | `gameYiNiJump` | `game/yinijump` | 后期文件 |
| 月饼小当家 | `gameMakeMooncake` | `game/makemooncake` | 2013 年或更早 |
| 欢乐满天飞 | `gameBlowBubble` | `game/blowbubble` | 2013 年或更早 |
| 天空保卫战 | `gameGuardNut` | `game/guardnut` | 后期文件 |
| 飞天独角兽 | `gameFlyingUnicorn` | `game/flyingunicorn` | 后期文件 |
| 减肥大作战 | `gameSwimming` | `game/swimming` | 后期文件 |
| 海底保卫战 | `gameSeaDefend` | `game/seadefend` | 后期文件 |
| 童话鬼屋 | `gameGhostHoliday` | `game/ghostholidaygame` | 2013 年或更早 |
| 对对碰 | `gameMatchThree` | `game/matchthree` | 后期文件 |
| 小小印花家 | `gameOneLine` | `game/onelinegame` | 后期文件 |
| 霓虹泡泡珠 | `gamePuzzleBobble` | `game/puzzlebobble` | 后期文件 |
| 冰之迷阵 | `gameBrickGame` | `game/brickgame` | 后期文件 |
| 忍术修炼 | `gameHitBrick` | `game/hitbrick` | 后期文件 |
| 勇闯冰雪溶洞 | `gameEatBeans` | `game/eatbeans` | 后期文件 |
| 礼物争夺战 | `gameZillionaire` | `game/zillionaire` | 2013 年或更早 |
| 伢牙乐营养全席 | `gameYaYaEatBeans` | `game/yayaeatbeans` | 2013 年或更早 |
| 星星能量 | `gameZuMa` | `game/zuma` | 后期文件 |
| 皇牌空战 | `gameCampBattleField` | `campbattlefield/campbattlefield` | 后期文件 |
| 欢乐萌果果 | `gameReunionGame` | `game/reuniongame` | 后期文件 |
| 元宵滚滚弹 | `gameTangyuanBall` | `game/tangyuanball` | 后期文件 |
| 飞越巨石阵 | `gameFlyStone` | `game/flystone` | 后期文件 |
| 3D赛车 | `gameMyCat` | `game/mycat` | 后期文件 |
| 大战TT兔 | `gameChocolateRabbit` | `game/chocolaterabbit` | 后期文件 |
| 爱心节游戏 | `gameLoveFes` | `game/lovefesgame` | 2013 年或更早 |
| 小猫快跑 | `gameAnimalRun` | `game/catrun` | 2013 年或更早 |
| 飞越时间海 | `gameFlyGame` | `game/flygame` | 后期文件 |
| 杂物大整理 | `gameCarfu` | `game/carfu` | 2013 年或更早 |
| 王子图书大作战 | `gameKrfBook` | `game/bookbattle` | 2013 年或更早 |
| 斗魂小星猴 | `gameFighting` | `game/fightinggame` | 后期文件 |
| 王子脆脆多 | `gameKaFuCookie` | `game/kafucookie` | 2013 年或更早 |
| 霹雳神枪手 | `gameFlyingDisk` | `game/flyingdisk` | 2013 年或更早 |
| 超武斗大会 | `gameBedlamFight` | `bedlamfight/bedlamfight` | 2013 年或更早 |
| 云霄飞车 | `gameCarSurf` | `game/carsurf` | 后期文件 |
| 路比跳音符 | `gameLubiJump` | `game/lubigame` | 后期文件 |
| 王子记忆翻牌 | `gameMemoryCard` | `game/memorycard` | 2013 年或更早 |
| 飞天奇奇 | `gameFlyingQiQi` | `game/flyingqiqi` | 后期文件 |
| 极限投篮王 | `gameYaYaSlamDunk` | `game/yayaslamdunk` | 2013 年或更早 |
| 炮打外星人 | `gameHitAlien` | `game/hitalien` | 2013 年或更早 |
| 疯狂的水果 | `gameFlyingFruit` | `game/flyingfruit` | 后期文件 |
| 卡尔夫赛马 | `gameHorseRace` | `game/horserace` | 2013 年或更早 |
| 香槟派对 | `gameHitGame` | `game/hitgame` | 后期文件 |
| 冰花天降 | `gameDropIcePieces` | `game/dropicepieces` | 2013 年或更早 |
| 天使大作战 | `gameThrowBalls` | `game/throwballs` | 后期文件 |
| 王子饼干泡泡珠 | `gamePrincePuzzleBobble` | `game/princepuzzlebobble` | 2013 年或更早 |
| 灵兽保卫战 | `gameLinThrowBall` | `game/linthrowball` | 后期文件 |
| 列卡捕鸟 | `gameEatBird` | `game/eatbird` | 后期文件 |
| 高空摘云 | `gamePickCloud` | `game/pickcloudgame` | 2013 年或更早 |
| 水上追逐战 | `gameIceskating` | `game/iceskating` | 后期文件 |
| 乐乐快跑 | `gameLeLeRun` | `game/lelerun` | 后期文件 |
| 捣蛋的契约书 | `gameCleanIce` | `game/cleanice` | 2013 年或更早 |
| 古堡大逃亡 | `gameCastleEscape` | `game/castleescape` | 2013 年或更早 |
| 魔法房子 | `gameTowerBoxx` | `game/towerboxx` | 后期文件 |
| 我的伙伴我做主 | `gameYabiHit` | `game/yabihit` | 后期文件 |
| 海灵灵大作战 | `gameHungryMonster` | `game/hungrymonster` | 后期文件 |
| 圣诞礼物盒 | `gameGoldPitman` | `game/goldpitman` | 后期文件 |
| 斑比向前冲 | `gameNinjaRush` | `game/ninja/ninjarush` | 后期文件 |
| 极限轰炸 | `gameLimitBomb` | `game/limitbomb` | 后期文件 |
| 酷跑星世界 | `gameParkour` | `game/parkour/parkour` | 后期文件 |
| 对决无双 | `gameMatchThree4Activity` | `game/matchthree4activity` | 后期文件 |

Also available outside the table: 斑比向前冲 (2017, in 奥拉运动场), 极限轰炸
(June 2013, its 2017 copy, at the fighter in 指挥中心) and 酷跑星世界 (2014–15,
in 星光游乐场), all later games, and the 欢乐弹珠机. 极限轰炸's 排行榜 and 军衔奖励
work; a 军衔奖励 row gives its 经验 and 晶币 but not the third thing it shows
(items and clothes of June 2013 the January 2013 client does not know), and a
run pays 晶豆, as its end panel says.

## Other systems

### 亚比

- Battles against wild 亚比 in 124 rooms (幽冥大殿's 金银球, 小金小银 and, now and
  then, 金银童子 among them), task 亚比, bosses and NPCs: skills,
  attributes, statuses, items, switching, escaping, the boss films.
  A turn has 30 seconds (counted at the top of the battle screen); when they
  run out the screen uses the first skill with uses left, or waits if none
  has (the next 亚比 when a fallen one is to be replaced). The battle screen's
  聊天 page and chat line speak to the room. The mouse over a 亚比 shows its
  属性等级 (攻击 防御 特攻 特防 速度 命中 闪避 暴击 raised or lowered, at most 6
  either way) on the later battle module's own panel (the 2013 one is lost).
- Catching with 亚比球 (the 2013 balls and their rules).
- Experience, levels, effort points, learning skills, evolution.
- The 亚比 bag: details, healing, 更换技能 (choose four of the learnt skills).
- The 亚比仓库 (from the 家园 and the HELLO's 远程亚比仓库) in its 2012 look (the
  January 2012 tutorial's picture of it): 亚比仓库 / 精英仓库 / 放生仓库, the 系
  icons, 按时间顺序 / 按等级顺序, pages of nine, and for the 亚比 chosen 技能 /
  能力 / 信息, 展示 (shown in the 家园 at once), 训练 (the 亚比特训: a 亚比 of the
  仓库 and one of four lessons, 一天 to 七天; the HELLO's 亚比训练), 设为精英 /
  取消精英, 放入背包, 放生 (kept seven days in the 放生仓库, RECONSTRUCTED), and its
  昵称 (the pen by its name). The bag's box button puts a 亚比 back (放回仓库).
- Following: the 亚比 walks behind its owner (as its walking figure, or its
  picture where none exists).
- Riding (坐骑): one of the 34 亚比 of the 2013 ride list, for 蓝宝骑士.
- The 亚比孵化器 in the 家园: 亚比蛋 from bosses and from the 收费亚比蛋商品册.
- 亚比融合 (贝鲁特 in 亚比研究中心): two 亚比 and a material make a 元生体, which
  hatches in the 孵化器 of its place (艾夕区奇迹冰殿, 索里德区新世界, 巨人山顶,
  奇迹谷底, 生命之树, 水下广场, 烈焰洞穴) in 24 or 72 hours.
- 天赋启迪 (the 天赋改造机 in 亚比研究中心): raising a 亚比's 天赋 with 启迪能量
  or 星币.
- The 亚比图鉴 (the 图鉴 button under 任务, its 2012 icon: the garden's, from the
  January 2012 tutorial picture): the later game's panel (2017) on
  the 2013 files, with the 亚比 up to 1651 (those after January 2013 from the
  later game's files, for the 工具箱). A 亚比 is 发现 once fought and 收集 once
  owned ("亚比图鉴有了新的记录" over the player after the fight); 最新发现 shows
  the 亚比 of the 24 January 2013 update. Its 收集 rewards (a 2017 event) are
  not there.
- 亚比道具 (the bag's 道具 tab): every item of 2013 that is used on a 亚比.
- 战术卡 (the bag's 战术卡 tab): the 35 cards of 2013, one in each place
  (A, B, C) of a 亚比, adding to its stats; a 亚比 BOSS beaten sometimes gives
  one (RECONSTRUCTED). 亚比装扮 is not there: the 2013 files have no list of
  the 亚比's clothes.

### Shops and money

- The catalog books: 道具商品册, 服装 (星语流行服饰, 时尚精品服饰), 家具商品册,
  种植手册, 射击卡手册, 收费亚比蛋商品册, and the 收费 books of the 商城, in their
  own frames (the desk with page numbers and money each 商品册 carries; the 周刊's
  and handbooks' containers); a close is added only to a book without its own.
- 晶币 for ordinary goods; 星币 for the real-money goods (half price for
  蓝宝石).
- 礼包 open when bought: what each held goes into the bag, its 经验 to the
  HELLO's 经验分配器 (the lists are RECONSTRUCTED from the bags' 2013
  descriptions and catalog pages; a 亚比服装, HELLO服装 or 家园种植 thing in a
  bag is left out).
- The 收费亚比蛋商品册 (its January 2013 first page is lost): one page with
  every 2013 亚比蛋 that has a price, six at a time over 13 pages of its own,
  on the art of its 2016 copy.
- The 兜兜回收器 (buy-back) in 道具店, 服装店, 家具店 and 种植园.
- The shops' lift (点我前往其他楼层) between 种植园, 家具店 and 服装店.
- The 财富小管家 in 奥拉广场: 晶豆 savings with interest, 奥币 and 流星碎片 made into 星币.

### Home

- The 家园 (garden of 2012): the 植树盆 with the eight trees of 2012 and its
  2012 tree panel (雨露 and 养料 for 50 晶币, 采摘, 植物心声 with the last
  visitors, the 盆栽道具 from 极速雨露 to 铲子, a 守护亚比 against pickers, 收为家具
  for a grown tree with no fruit to come; the 树苗 bought in the 种植园's 树苗售卖 (the
  种植手册) are kept, and the empty pot lets the owner choose which to plant), the 亚比孵化器, the 经验分配器 (hands the HELLO's
  experience to a 亚比; its 2012 panel, 确认 box and LEVEL UP box, from the
  January 2012 tutorial), 我的荣誉 (the owner's 徽章: the 280 honours of the era,
  those the record can count got from what it holds), the 亚比仓库, the 留言板
  (友谊留言板: messages left by visitors, the owner's 寄语), 健身房 (亚比训练),
  最近访问 (足迹), and the 亚比 its owner 展示; its bar's 地图, 背包, 好友, 周刊,
  勋章 (the player card's 勋章 page: 勇气, 大地, 生命, 海洋 and 烈焰勋章 come with their
  星辉任务), 图鉴 and 放映厅 (奥拉星's films); the strip under the garden: the owner's
  徽章分数, 人气 and friends, the cards of the player and the player's friends by
  徽章分数 (a card goes to that one's 家园), 刷新, the 商城, the sound switch and the
  clock.
- The 小屋 (空间舱 and the other house types): furniture from the catalog,
  decorating, storage; the trees made furniture (收为家具) put down there.
- The 动物园: forty animals that grow, can be fed and harvested, and may turn
  into 亚比; the 手册, selling grown animals; its 2012 panels on their art: the
  动物仓库 strip (幼仔, 成熟动物, 道具), an animal's panel (收获, 道具, 玩耍, 放生),
  动物园信息, and the 饲料机 with the era's rules (it holds 800 points of 饲料, each
  growing animal eats 6 an hour, an empty machine leaves them hungry and not
  growing; filled with gathered things such as 炎冰 or for 晶币).
- On a shared server: friends' homes (家园, 小屋, 动物园), 摘果子 there, the
  足迹, and messages on each other's 留言板 (docs/MULTIPLAYER.md).

### Interface and world

- The control bar of December 2011 with its phrases, faces, actions, chat
  log and music switch (its icons cut from the 2012 house tutorial film's
  picture of the bar); the player card and wardrobe; the 物品 panel.
- The world map of November 2012.
- Walking round obstacles; other players and their 亚比 drawn in rooms.
- Each room's music, and battle music; the game's music up to the end of 2014
  (100 pieces, those after January 2013 from the later game's files), any of
  them played from the 工具箱.
- The HELLO walking behind the player; its menu's skills with the 2012
  icons of the HELLO's own panels.
- Gathering in the 27 rooms with gathering points.
- 射击 with 射击卡 and their effects.
- The 奥拉周刊 of every week from July 2010 (126 issues) and the 亚比手册 in the
  图书馆.
- The 百田大剧场 with the films that survive: 奥拉星2周年 (July 2012) and the
  战队 film, played in the game (their FLVs).
- 欢乐岛's hot spring with its costumes (seen by the others in the room) and
  experience.
- The 生态园 games 动物保卫战, 天空保卫战 and 海底保卫战, with their progress.
- 战斗星域's rooms (试炼平台, 挑战平台, 亚比精英赛场, 时空隧道, 堡垒外沿).

## Known gaps

- With other players (联机模式, docs/MULTIPLAYER.md): 好友, 组队, visiting
  homes, chat, 射击, 亚比对战 and mods together work; team battles (several
  players against one boss, a team in a 副本 or 时空隧道: the 2013 screen for
  them is lost), 战队, 兵团 and trading do not.
- Daily tasks, the NPC guide.
- Most time-limited activities of 2012–13 (their panels show
  这个功能还在修复中). Not recovered, their files lost: 星际寻宝, the 四灵兽挑战 and the
  终极道馆 (only later re-runs of 2013–15 survive: the 四灵兽挑战 file is the
  September 2013 one); 黑炎龙 (January 2013: only a 2015 panel
  much changed survives, and 夜影之渊's button for it is lost); 永夜三巨头 (红魔, 绿焰, 紫渊:
  a team of two or more, its team panel lost). The titles some activities gave (修罗终结者,
  奇灵王者, 镇蜀大将军) are not kept.
- The job unions (冒险协会, 动物协会, 亚比协会), 星际兑换机, 星际航线,
  上古神殿's panels, 模拟空间.
- Quests that call services that are still stand-ins may stop partway.
- 风暴星系's two mini games, 天降神饼 (斗魂平原) and 斗魂小星猴 (虚无长廊): the
  games and their start panels are there, but the surviving (later) files of
  the two rooms no longer have their entrances.
- Several rooms are later redrawings, because the January 2013 files are
  lost: 奥拉广场 (on the July 2012 art), 主题公园 (on the June 2012 art),
  亚比研究中心 (2014 art), 奥拉之树 (2014–24 art) and others with later art
  but their 2012 function.
