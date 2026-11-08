package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Shape;
   import flash.display.Graphics;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.BlurFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.StaticText;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.getTimer;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModNpc;
   import mmo.revival.mod.IModRoom;

   /**
    * 蚁族的反击: a demo of API 4. The player is a 兵蚁 with a 工蚁 at his side. The 奥拉人
    * took the 蚁族王朝, made the 蚁将军 into the 变异蚁将军 and locked up the ants' champions;
    * now that the 奥拉人 are at war with the 达斯特人, their garrison is thin, and the ants
    * strike back. Each 奥拉 guard keeps one of the 蚁族王朝's creatures; beaten, the creature
    * joins (Lv100). Then the 变异蚁将军, the 传送核心's 小奥拉, and the 指挥中心: 兰丁, 弗洛拉, 拉贝尔.
    *
    * It shows: rooms on the game's scenes (scene) and music, NPCs of the game ("npc:<id>"),
    * the player as a 亚比 (playerLook), the mod's own 亚比 and 道具 (party): healing all is
    * refused, the 兵蚁 must stay in the bag and its fall ends the game; giveItem, partyState.
    * Three difficulties change the opponents' strength and the 体力糖 given.
    */
   public class AntWarMod extends Sprite implements IMod
   {
      private static const BINGYI:int = 216;
      private static const GONGYI:int = 217;
      private static const GENERAL:int = 226;
      private static const CANDY:int = 61;   // 高级体力糖
      private static const BEAN:int = 104;   // 高级活力豆
      private static const ANT_MUSIC:String = "music/siwudefb.mp3";
      private static const CITY_MUSIC:String = "music/centre.mp3";
      /** The 工蚁's picture in its words (and the story's). */
      private static const WORKER:String = "pet:217";

      /**
       * lv: added to the guards' levels; foe, boss: the opponents' stats in percent (bossHp their
       * 体力); candy, bean: at the start; win…: after each win (boss…: and after a boss). Tried
       * out with a plain player (balance.ts beside this mod: the campaign on the server's battle
       * engine, types and 体力糖 only): it wins 简单 most times, 普通 half the time and 困难
       * seldom, so that 普通 and 困难 ask for the allies' skills.
       */
      private static const MODES:Object = {
         easy: {name: "简单", team: 2, minLv: 80, topLv: 100, lv: -5, foe: 85, boss: 90, bossHp: 120, helper: 60, step: 5, candy: 8, bean: 8, winCandy: 2, winBean: 2, bossCandy: 2, bossBean: 2, chestCandy: 4, chestBean: 4},
         normal: {name: "普通", team: 4, minLv: 90, topLv: 110, lv: 0, foe: 100, boss: 110, bossHp: 170, helper: 70, step: 4, candy: 5, bean: 5, winCandy: 2, winBean: 2, bossCandy: 2, bossBean: 2, chestCandy: 3, chestBean: 3},
         hard: {name: "困难", team: 6, minLv: 100, topLv: 120, lv: 3, foe: 105, boss: 125, bossHp: 230, helper: 70, step: 5, candy: 4, bean: 4, winCandy: 1, winBean: 1, bossCandy: 1, bossBean: 1, chestCandy: 2, chestBean: 2}
      };

      /**
       * The rooms, joined as the scenes of the 蚁族王朝 副本 are (their own doors, Fbsiwude3's et1 and
       * et2 …): door, the piece of the scene that leads on to next; arrow, where the 副本 pointed the
       * way on ([x, y, rotation, facing right]); ways, a room with more than one way on (each {door,
       * to, arrow}); cleared, what the 副本's code did once the room's fights were won (play: pieces
       * played to their last frame, a gate opening; remove: pieces of the obstruction taken away);
       * spawn, where the player comes in at the start (else where the scene puts him); hide, pieces
       * that do not belong in the story.
       */
      private static const ROOMS:Array = [
         // In from the path at the upper left.
         {id: "ant1", scene: "fbsiwude1", name: "蚁穴前哨", next: "ant2", door: "et1", arrow: [850, 360, 0, true], spawn: [240, 110]},
         {id: "ant2", scene: "fbsiwude2", name: "蚁兵基地", next: "ant3", door: "pit", arrow: [820, 176, 0, true],
            hide: ["mc_pit", "light_0", "light_0_1", "light_1", "light_1_1", "light_2", "light_2_1", "light_3", "light_3_1"]},
         // Two ways on, as the scene's own doors lead: et1 at the top right to 工蚁聚集地 (the 副本's
         // arrow), et2 at the bottom right to 下水道深处 and on from there to 工蚁聚集地. Each behind one of
         // the vine gates its guards keep (gate).
         {id: "ant3", scene: "fbsiwude3", name: "蚁穴下水道", ways: [{door: "et1", to: "ant5", arrow: [800, 100, 0, true]}, {door: "et2", to: "ant4", arrow: [850, 445, 0, true]}]},
         // The 蚁将军's treasure (the 副本's chest: 高级体力糖 and 高级活力豆), opened once its guards are gone.
         {id: "ant4", scene: "fbsiwude4", name: "下水道深处", next: "ant5", door: "et1", arrow: [820, 220, 0, true], chest: "treasure"},
         {id: "ant5", scene: "fbsiwude5", name: "工蚁聚集地", next: "ant6", door: "et1", arrow: [288, 93, 0, true]},
         // In where the scene puts the player (as the 副本 did), on through the great door between the statues.
         {id: "ant6", scene: "fbsiwude6", name: "蚁神守护大厅", next: "ant9", door: "fbsiwude6_door", arrow: [320, 150, 0, true]},
         {id: "ant9", scene: "fbsiwude9", name: "蚁神巨像", next: "ant10", door: "et1", arrow: [379, 98, 0, true], cleared: {play: ["mc_gate"], remove: ["roadblock"]}},
         {id: "ant10", scene: "fbsiwude10", name: "蚁神殿前殿", spawn: [915, 515], next: "ant11", door: "et1", arrow: [150, 100, 35, false], cleared: {remove: ["hurdle"]}},
         // hide: the scene's fighters by the 蚁将军 (its 副本's), who would look like his guard here.
         {id: "ant11", scene: "fbsiwude11", name: "蚁神殿正殿", next: "core", hide: ["mc_fight"], freed: {mc_antQueen: "mutant"}},
         {id: "core", scene: "maintown1copy", name: "传送核心", next: "hq", door: "et1", city: true},
         // In at the foot of the walkway, the three of the 指挥中心 before him.
         {id: "hq", scene: "maintown2copy", name: "指挥中心", city: true, spawn: [475, 505]}
      ];

      /**
       * The 奥拉 guards. npc: the NPC of the game; race: its 亚比, the strongest it brings
       * (teamOf: more by difficulty; the NPCs with a 挑战 bring the
       * highest of theirs); captive: the creature it keeps, art: its pieces of the scene (hidden
       * once it is free), near: a piece of the scene it stands by when it has none of its own.
       */
      private static const GUARDS:Array = [
         // 蚁穴前哨: the post at the gate (the 兵蚁 who stood guard there are 奥拉 卫兵 now).
         {id: "tom", room: "ant1", npc: 82, name: "卫兵汤姆", race: 81, level: 48, at: "ant0",
            say: "站住！蚁穴前哨已经由奥拉军接管，蚂蚁不许靠近！", lost: "前哨守不住了……我去向尼克队长报告！"},
         {id: "kevin", room: "ant1", npc: 221, name: "蓝宝卫兵凯文", race: 183, level: 50, at: "ant2",
            say: "蓝宝卫队奉命驻守前哨，再往前一步，就别怪我不客气！", lost: "援军都调去前线了……可恶！"},
         {id: "nike", room: "ant1", npc: 28, name: "卫兵尼克", race: 36, level: 55, x: 600, y: 430, at: "ant1",
            say: "我是前哨队长尼克。部队虽然调走了，这里还轮不到你们撒野！", lost: "竟然败给一只兵蚁……全员撤回蚁兵基地！"},
         // 蚁兵基地.
         {id: "allen", room: "ant2", npc: 221, name: "蓝宝卫兵艾伦", race: 153, level: 56, at: "ant0",
            say: "前哨的人都撤回来了，原来是被你们打败的！", lost: "拦不住……快去通知杰克！"},
         {id: "sam", room: "ant2", npc: 28, name: "卫兵萨姆", race: 78, level: 58, at: "ant2",
            say: "蚁兵基地已经是奥拉军的营地了，回去！", lost: "撤退！往下水道撤！"},
         {id: "guard1", room: "ant2", npc: 82, name: "卫兵杰克", race: 18, level: 60, x: 560, y: 420, at: "ant1",
            say: "基地由我把守。想过去，先赢了我！", lost: "基地失守了……全员撤进下水道！"},
         // 蚁穴下水道 and 下水道深处: the creatures caught there.
         // Three 牛角滴滴, a guard at each cage; the first one freed joins, the others go home.
         {id: "roy", room: "ant3", front: true, npc: 82, name: "卫兵罗伊", race: 87, level: 62, captive: 244, art: ["npc_0"], gate: {play: ["door_0"], remove: ["ob_0"]},
            say: "这只牛角滴滴由我看着，不许靠近笼子！", lost: "这里守不住了……撤！"},
         {id: "jason", room: "ant3", front: true, frontDx: -95, npc: 221, name: "蓝宝卫兵杰森", race: 75, level: 63, captive: 244, art: ["npc_1"], gate: {play: ["door_1"], remove: ["ob_1"]},
            say: "下水道归蓝宝卫队看守，回去！", lost: "我这就去叫治安官……"},
         {id: "hade", room: "ant3", front: true, npc: 26, name: "治安官哈德", race: 72, level: 65, captive: 244, art: ["npc_2"], gate: {play: ["door_2"], remove: ["ob_2"]},
            say: "这只牛角滴滴是重要的俘虏，由我看管，谁也不许带走。", lost: "可恶……撤退，去下水道深处和亨特会合！"},
         {id: "guard2", room: "ant4", npc: 82, name: "卫兵马克", race: 189, level: 68, captive: 241, art: ["npc_0"], gate: {play: ["door_0"], remove: ["ob_0"]},
            say: "毒菇球是我们抓到的，退后！", lost: "打不过……撤退！"},
         {id: "hunter", room: "ant4", npc: 142, name: "军需官亨特", race: 21, level: 70, captive: 242, art: ["npc_1"], gate: {play: ["door_1"], remove: ["ob_1"]},
            say: "下水道的物资和俘虏都归我管，金刚蛤蟆也不例外。", lost: "物资来不及搬了……撤！"},
         {id: "lucas", room: "ant4", npc: 148, name: "训练官卢卡斯", race: 299, level: 72, captive: 243, art: ["npc_2"], gate: {remove: ["ob_2"]},
            say: "下水猛鳄要带回奥拉星做坐骑，你们别想阻止！", lost: "是我低估你们了……撤退！"},
         // 工蚁聚集地: the way on.
         {id: "mach", room: "ant5", npc: 172, name: "机械师马赫", race: 99, level: 75, x: 400, y: 215,
            say: "工蚁聚集地由我驻守。我的火花龙最克木属性，你们小心了！", lost: "火花龙都撑不住了……撤！"},
         // 蚁神守护大厅, 蚁神巨像, 蚁神殿前殿: the kingdom's warriors in the 奥拉 army's hands.
         {id: "knight1", room: "ant6", npc: 145, name: "骑士团卫兵罗兰", race: 45, level: 80, captive: 218, near: "btn_guard", side: -1,
            say: "守护力士由骑士团看押，不许靠近！", lost: "骑士团，后撤！去向团长报告！"},
         {id: "knight3", room: "ant6", npc: 146, name: "骑士团卫兵崔斯坦", race: 204, level: 80, captive: 219, near: "btn_guard", side: 1, stand: -1,
            say: "守护法师交给骑士团看管，谁也别想带走！", lost: "大厅守不住了……退到蚁神巨像！"},
         {id: "vick", room: "ant9", npc: 13, name: "异星使者维克", race: 63, level: 85, captive: 220, art: ["ant_0"],
            say: "蚁族圣斗士由我看守。回去吧，你们赢不了的。", lost: "蚁族……比我想象的更顽强。"},
         {id: "bluebrook", room: "ant9", npc: 221, name: "蓝宝卫兵布鲁克", race: 293, level: 85, captive: 221, art: ["ant_1"],
            say: "魔斗士由蓝宝卫队看守，退下！", lost: "蓝宝卫队……撤退！"},
         {id: "arthur", room: "ant10", npc: 147, name: "骑士团长亚瑟", race: 290, level: 90, captive: 225, hide: ["btnPet_1"], cage: [212, 254], side: 1,
            say: "我是骑士团长亚瑟。守护骑士保斯由我亲自看守。", lost: "好一支蚁族的队伍……骑士团，撤退！"},
         {id: "knight2", room: "ant10", npc: 146, name: "骑士团卫兵高文", race: 45, level: 90, captive: 223, hide: ["btnPet_2"], cage: [412, 306], side: -1,
            say: "兰斯罗特由我看守，退下！", lost: "团长，我守不住了……"},
         {id: "magellan", room: "ant10", npc: 9, name: "司令官麦哲伦", race: 236, level: 92, captive: 224, hide: ["btnPet_3"], cage: [608, 380], side: -1,
            say: "大部队虽然调去和达斯特人作战，我麦哲伦还在这里！", lost: "是我大意了……不该把部队全调走。"},
         {id: "lanbao", room: "ant10", npc: 221, name: "蓝宝卫兵雷恩", race: 33, level: 92, captive: 222, hide: ["btnPet_4"], cage: [804, 433], side: -1, standAt: [100, -50],
            say: "贝德威尔由蓝宝卫队看押，你们过不去！", lost: "守不住了……蓝宝卫队，撤！"},
         {id: "mutant", room: "ant11", race: 227, level: 100, boss: true, look: 227, art: ["btn_general"], name: "变异蚁将军",
            gift: GENERAL, say: "吼——！！奥拉人……命令……守住……蚁后……", lost: "我……我是……蚁族的……将军……"},
         // all: every 亚比 of race in the one battle, in a random order (each at the mode's boss strength).
         {id: "kid", room: "core", look: KULAN, name: "小奥拉", race: [502, 501, 500], all: true, top: true, level: 100, x: 470, y: 400, boss: true,
            say: "传送门那头怎么出来的是蚂蚁？……你们是从蚁族王朝一路打过来的？不行，我不能让你们过去！", lost: "竟然一路打到了这里……我这就去通知兰丁队长！"},
         {id: "landing", room: "hq", npc: 94, name: "兰丁", race: 1648, top: true, level: 100, x: 330, y: 430, boss: true,
            say: "我是兰丁。能一路打到指挥中心，你们确实有本事。想谈条件，先过我和菲尔这一关。", lost: "菲尔都挡不住你们……蚁族王朝的事，看来我们欠你们一个解释。"},
         {id: "flora", room: "hq", npc: 194, name: "弗洛拉", race: 1649, top: true, level: 100, x: 610, y: 430, boss: true,
            say: "我是弗洛拉。前线的消息我都听说了……来吧，让我看看你们为了家园能拼到什么地步。", lost: "可兰也撑不住了……为家园而战的决心，是我们小看了。"},
         {id: "rabel", room: "hq", npc: 86, name: "拉贝尔", race: 323, top: true, level: 100, x: 470, y: 330, boss: true, need: ["landing", "flora"],
            say: "我是拉贝尔，指挥中心由我负责。兰丁和弗洛拉都输了，那就由我和梅卡来做最后的了断。", lost: "梅卡，退下吧。再打下去，只会让更多人受伤。"}
      ];

      /** What each creature says when it is free: what it can do. */
      private static const THANKS:Object = {
         "244": "咕噜！谢谢你们！牛角滴滴虽然小，也想为王朝出一份力！",
         "242": "呱……总算出来了。奥拉人的账，金刚蛤蟆跟你们一起算！",
         "241": "被关了这么久，毒箭都快生锈了。走，带上我！",
         "243": "想把我带回奥拉星当坐骑？做梦！下水猛鳄跟你们走。",
         "218": "守护大厅失守，是我们守护者的耻辱。这一次，换我来守护你们。",
         "219": "谢谢你们。奥拉人在王朝做的每一件事，我都记得清清楚楚——走吧。",
         "220": "兵蚁，干得漂亮。这份情圣斗士记下了，这一战算我一个！",
         "221": "终于自由了。魔斗士的力量，就借给你们吧。",
         "225": "守护骑士保斯，向你们致谢。蚁神殿就在前面，我们一起把它夺回来！",
         "223": "火焰骑士兰斯罗特，重回战场！奥拉人欠我们的，今天一并讨回。",
         "224": "哥拉海德在此。正殿就在前面，将军和蚁后都在那里！",
         "222": "谢谢你们……将军被奥拉人变成了怪物，我们得赶快去救他。"
      };

      /** 工蚁's advice before the hardest fights, by guard. */
      /** 小奥拉: a new 奥拉 in the starting 酷蓝 clothes (the bare head and body, hair, cape, suit, trousers, boots, eyes). */
      private static const KULAN:String = "avatar:6;7;126;127;129;130;131;132";
      /** The 提示 of each room (then the advice for its guards still standing). */
      private static const ROOM_HINTS:Object = {
         "ant1": ["这里有三个奥拉卫兵，走近他们就会被拦下。每打赢一场，都能缴获高级体力糖和高级活力豆。",
            "体力不够时，打开亚比背包的「道具」用高级体力糖；技能次数用完了，用高级活力豆。兵蚁倒下游戏就结束，别让它硬撑。"],
         "ant2": ["打不过可以在战斗中逃跑，恢复好再来。",
            "属性相克：水克火、火克木、电克水和飞行、冰克木、土克火、机械克冰。被克的属性打过来只有一半威力。"],
         "ant3": ["这里有两条路：右上的路通往工蚁聚集地；右下的路通往下水道深处，那里关着三位伙伴，还有蚁将军藏下的宝箱，从那里也能走到工蚁聚集地。藤蔓挡着路，打败看守的守卫才会打开。",
            "三个守卫各看着一只牛角滴滴。治安官哈德的斯多王是土属性，卫兵罗伊的冰拳艾司是冰属性——冰克木，别让兵蚁和工蚁硬碰。",
            "救出的牛角滴滴是水属性，火属性的对手最怕它；它的寄生种子每回合吸走对手1/10的体力，但对木系无效。"],
         "ant4": ["三个守卫各看着一位伙伴。金刚蛤蟆（水）挨火属性攻击只受一半伤害；毒菇球的毒菇鸠箭能让对手中毒；下水猛鳄的树界降临每回合回复1/4体力。"],
         "ant5": ["机械师马赫的火花龙是火属性，克木属性的兵蚁和工蚁：让水属性的牛角滴滴、金刚蛤蟆出战。"],
         "ant6": ["守护力士（机械）的巨刃破邪连续5回合攻击，木属性的攻击对它只有一半威力；守护法师的真·噬魂能让对手的全部属性下降1级。"],
         "ant9": ["蚁族圣斗士（电）的闪电护盾让受到的特殊伤害减半；神秘仪式能牺牲自己，让下一只出场的亚比满状态回复。",
            "蚁族魔斗士的意念之盾让全队受到的普通攻击伤害减半，换亚比也有效；诱惑能让对手特攻下降两级。"],
         "ant10": ["四个守卫看守着四位骑士。保斯（土）的秽土转生能回复全部体力；兰斯罗特（火）的烈焰焚天威力巨大，但体力越少威力越低；哥拉海德（电）的闪电新星可能让对手麻痹；贝德威尔（冰）的冰雾海让对手无法替换亚比，每回合扣除它最大体力的1/16。"]
      };
      private static const ADVICE:Object = {
         "mutant": ["变异蚁将军是木属性：兰斯罗特的火、贝德威尔的冰打它都是双倍！",
            "它的将军KICK是普通攻击，蚁族魔斗士的意念之盾能让伤害减半；将军雷霆破和将军震地波是特殊攻击，蚁族圣斗士的闪电护盾能挡住一半。"],
         "kid": ["小奥拉会带着三只初始亚比，出场顺序每次都不一样：古渊露龙是水和飞行属性，电属性打它是<font color='#FF6600'>四倍</font>！魔焰吉拉是火属性，用水属性的伙伴；终结兔是木属性，用火或冰。",
            "终结兔是木系：寄生种子对它无效，别浪费技能次数。"],
         "landing": ["菲尔是火属性，招式全是普通攻击：先让蚁族魔斗士用意念之盾，伤害减半，换亚比也有效！",
            "保斯（土）和牛角滴滴、金刚蛤蟆（水）挨火属性攻击只受一半伤害，反击却是双倍。千万别让木属性的兵蚁正面挨打！",
            "菲尔的火灵燃烧会烧伤，还会每回合偷走我们的技能次数——多备些高级活力豆。"],
         "flora": ["可兰是木属性，也全是普通攻击：意念之盾照样有用。兰斯罗特的火、贝德威尔的冰都克她；守护力士是机械属性，木属性的攻击对它只有一半威力。",
            "可兰会用春木之歌、灵风之心回血。用贝德威尔的冰雾海让她每回合掉1/16的血，再让毒菇球把她毒倒，她回得再多也会被磨掉！",
            "注意：寄生种子对木系无效。她的风灵幻曲会让我们每回合掉属性，换下场就能解除。"],
         "rabel": ["梅卡是水属性，招式都是特殊攻击：圣斗士的闪电护盾让特殊伤害减半，电属性打她又是双倍！",
            "木属性的兵蚁、工蚁、蚁将军、下水猛鳄挨水属性攻击只受一半伤害，反击是双倍——这一战轮到我们木系出场了！",
            "梅卡的原·水源之力会让她全属性提升2级：守护法师的真·噬魂能把属性削回来，魔斗士的诱惑能让她特攻下降两级。",
            "魔斗士的狂暴诅咒能让梅卡混乱2~3回合：每回合有1/3的几率打不出招、反而攻击自己。它提升的攻击只会让她打自己更痛——她的招式都是特殊攻击。",
            "兵蚁大哥受伤了？让圣斗士或魔斗士用神秘仪式，下一只出场的兵蚁就能满状态回复！"]
      };

      private var game:IModGame;
      private var hud:TextField;
      private var hudBox:Sprite;
      private var hudHelp:Sprite;
      private var hudReset:Sprite;
      /** The cages of the room shown, by the guard whose fall opens them: [Sprite, …]. */
      private var cages:Object = {};
      /** The radius of a cage round a captive drawn as its 亚比. */
      private static const CAGE_R:Number = 50;
      /** Where the guards of the room shown stand (each clear of the others). */
      private var guardBoxes:Array = [];
      /** The guards of the room shown, keeping the way: [{g, npc, x, y}]. */
      private var watched:Array = [];
      /** A guard is talking or fighting with the player: no other steps in. */
      private var engaged:Boolean;
      /** Where the player stood when stopped. */
      private var engagedAt:Point;
      /** No guard steps in before then (getTimer): after the room is entered, or the player stepped back. */
      private var calmUntil:int;
      /** Where the player last stood out of every guard's reach (where a retreat goes). */
      private var safe:Point;
      /** How near a guard lets the player come (across; on the floor seen at an angle, less up and down). */
      private static const REACH:Number = 160;
      /** The floor seen at an angle: a guard's reach is shorter up and down (dy / SQUASH). */
      private static const SQUASH:Number = 0.8;
      /** Gone past a guard towards a way on (nearer it than the guard is) within this: stopped too. */
      private static const PASS:Number = 300;
      /** How far from the nearest way on the player came into the room (-1: not yet seen). */
      private var cameAt:Number = -1;
      /** Where the 奥拉 army's portal stands in 蚁神殿正殿 (its foot). */
      private static const PORTAL:Array = [820, 360];
      /** The 蚁族王朝 副本's arrows (fbteam/fbsiwude_res's ShowArrowhead). */
      private static const ARROW_FILE:String = "fbteam/fbsiwude_res";
      private static const ARROW_R:String = "mmo.scene.fbsiwude.ShowArrowhead_R";
      private static const ARROW_L:String = "mmo.scene.fbsiwude.ShowArrowhead_L";
      /** The way on stays left of this (the game's buttons on the right). */
      private static const DOOR_RIGHT:Number = 880;
      /** The way on of the room shown (no guard stands in it). */
      /** The room's ways on (their doors' rectangles): no guard stands in front of them. */
      private var doorBoxes:Array = [];
      /** Where the cages of the room shown stand (the last of each guard's), by guard. */
      private var cageFeet:Object = {};
      /** The cages' bounds in the room shown, by guard. */
      private var cageRects:Object = {};
      /** The captives drawn as their 亚比 in the room shown, by guard. */
      private var captiveNpcs:Object = {};
      /** The 卫兵 posted in the room shown, by the guard they run with. */
      private var posted:Object = {};

      public function get info():Object
      {
         return {id: "antwar", name: "蚁族的反击", author: "aola-revival", version: "1.0",
            description: "扮演兵蚁，夺回蚁族王朝。"};
      }

      public function start(game:IModGame):void
      {
         this.game = game;
         for each (var r:Object in ROOMS) defineRoom(r);
         game.playerLook(BINGYI, "兵蚁");
         if (!game.getData("mode") || game.getData("over"))
         {
            game.enter("ant1");
            return;
         }
         game.party(partyDef(false), function(st:Object):void
         {
            game.enter(String(game.getData("room") || "ant1"));
         });
      }

      // ---------------------------------------------------------------- state

      private function get mode():Object
      {
         return MODES[String(game.getData("mode"))] || MODES.normal;
      }

      private function beaten(id:String):Boolean
      {
         var b:Object = game.getData("beaten") || {};
         return Boolean(b[id]);
      }

      private function markBeaten(id:String):void
      {
         var b:Object = game.getData("beaten") || {};
         b[id] = true;
         game.setData("beaten", b);
      }

      private function guardsOf(roomId:String):Array
      {
         return GUARDS.filter(function(g:Object, i:int, a:Array):Boolean { return g.room == roomId; });
      }

      private function roomCleared(roomId:String):Boolean
      {
         for each (var g:Object in guardsOf(roomId)) if (!beaten(g.id)) return false;
         return true;
      }

      /**
       * What it uses beyond its rooms, for the export (tools/mod-sdk/export.mjs asks it): every
       * 亚比 of every team in every mode, the creatures freed, the NPCs, the 道具 it gives, its music.
       */
      public function uses():Object
      {
         var races:Object = {};
         var npcs:Object = {};
         races[BINGYI] = races[GONGYI] = races[GENERAL] = true;
         npcs[160] = true;
         for each (var g:Object in GUARDS)
         {
            if (g.npc) npcs[g.npc] = true;
            if (g.captive) races[g.captive] = true;
            if (g.gift) races[g.gift] = true;
            if (g.look is int) races[g.look] = true;
            for each (var m:Object in MODES)
               for each (var r:int in (g.race is Array ? g.race : [g.race]))
                  for each (var e:Object in teamOf(g, r, m)) races[e.race] = true;
         }
         var list:Function = function(set:Object):Array
         {
            var out:Array = [];
            for (var k:String in set) out.push(int(k));
            return out.sort(Array.NUMERIC);
         };
         return {races: list(races), npcs: list(npcs), items: [CANDY, BEAN], music: [ANT_MUSIC, CITY_MUSIC]};
      }

      private function partyDef(fresh:Boolean):Object
      {
         var m:Object = mode;
         var items:Object = {};
         items[CANDY] = m.candy;
         items[BEAN] = m.bean;
         return {
            // The 工蚁 first: it is the one that goes out first.
            pets: [{race: GONGYI, level: 100, follow: true}, {race: BINGYI, level: 100, keep: true}],
            items: items,
            noHeal: "这台HELLO是从奥拉人那里缴获的，它的治疗模块被锁住了！只能用高级体力糖给亚比恢复体力。",
            keepText: "兵蚁倒下了……蚁族的反击失败了。",
            // A 蓝宝石's HELLO: its 远程亚比仓库 for the friends freed beyond the bag's six.
            vip: true,
            fresh: fresh
         };
      }

      // ---------------------------------------------------------------- rooms

      private function defineRoom(r:Object):void
      {
         game.room(r.id, {
            name: r.name,
            scene: r.scene,
            music: r.city ? CITY_MUSIC : ANT_MUSIC,
            spawns: r.spawn ? {start: r.spawn} : null,
            build: function(room:IModRoom):void { buildRoom(r, room); }
         });
      }

      private function buildRoom(r:Object, room:IModRoom):void
      {
         if (game.getData("mode") && !game.getData("over")) game.setData("room", r.id);
         addHud(room);
         // The ways on: the scene's own doors, open once the room's guards are beaten.
         doorBoxes = [];
         var ways:Array = r.ways || (r.next && r.door ? [{door: r.door, to: r.next, arrow: r.arrow}] : []);
         for each (var way:Object in ways)
         {
            var d:DisplayObject = room.part(way.door);
            var b:Rectangle = d != null ? d.getBounds(DisplayObject(room)) : null;
            if (b == null) continue;
            // Clear of the game's buttons down the right-hand side (图鉴, 工具箱, 沙盒).
            if (b.right > DOOR_RIGHT) b.x -= b.right - DOOR_RIGHT;
            b.width = Math.max(40, b.width);
            b.height = Math.max(40, b.height);
            doorBoxes.push(b);
         }
         // The chest first: the doors over it (its picture may reach under a door's arrow).
         if (r.chest) chest(room, r.chest);
         for (var wi:int = 0; wi < ways.length && wi < doorBoxes.length; wi++) addWay(room, r, ways[wi].to, doorBoxes[wi], ways[wi].arrow as Array);
         // The 副本's gates: open where their guard is beaten already, and the room's own once it is clear.
         for each (var gg:Object in guardsOf(r.id)) if (gg.gate && beaten(gg.id)) openWay(room, gg.gate, false);
         if (r.cleared && roomCleared(r.id)) openWay(room, r.cleared, false);
         if (r.id == "ant11" && beaten("mutant")) portal(room);
         for each (var hn:String in r.hide || []) { var hp:DisplayObject = room.part(hn); if (hp) hp.visible = false; }
         // Pieces of the scene gone once a guard falls (the 蚁后's cage).
         for (var fn:String in r.freed || {}) { var fp:DisplayObject = room.part(fn); if (fp && beaten(r.freed[fn])) fp.visible = false; }
         cages = {};
         cageRects = {};
         cageFeet = {};
         guardBoxes = [];
         posted = {};
         captiveNpcs = {};
         watched = [];
         engaged = false;
         safe = null;
         cameAt = -1;
         calmUntil = getTimer() + 1500;
         var waiting:Array = [];
         for each (var g:Object in guardsOf(r.id))
         {
            var pg:Object = placeGuard(room, g);
            if (pg != null) waiting.push(pg);
         }
         for each (var w:Object in waiting) spawnGuard(room, w);
         // The guards keep the way: whoever comes near is stopped and challenged.
         var eye:Sprite = new Sprite();
         var look:Function = function(e:Event):void { watch(room); };
         eye.addEventListener(Event.ENTER_FRAME, look);
         room.add(eye, 0, 0, "back");
         room.onLeave(function():void { eye.removeEventListener(Event.ENTER_FRAME, look); });
         if (r.id == "ant1" && !game.getData("mode")) game.after(0.8, chooseMode);
         else if (r.id == "ant1" && !game.getData("intro")) game.after(0.8, intro);
      }

      /** A way on: door b to room to, once the room's guards are beaten; its arrow. */
      private function addWay(room:IModRoom, r:Object, to:String, b:Rectangle, arrow:Array):void
      {
         room.door(b.x, b.y, b.width, b.height, "", function():void
         {
            if (!roomCleared(r.id)) worker("这里的守卫还没解决，先别急着走。");
            else game.enter(to);
         }, false);
         wayOn(room, b, arrow);
      }

      /**
       * What the 副本's code did as a way opened (a guard's gate, a room cleared): pieces played to
       * their last frame (shown so at once unless animated) and pieces of the obstruction taken away.
       */
      private function openWay(room:IModRoom, what:Object, animated:Boolean):void
      {
         for each (var pn:String in what.play || [])
         {
            var mc:MovieClip = room.part(pn) as MovieClip;
            if (mc == null || mc.totalFrames < 2) continue;
            if (!animated || mc.currentFrame >= mc.totalFrames) { mc.gotoAndStop(mc.totalFrames); continue; }
            var last:Function = function(clip:MovieClip):Function
            {
               return function(e:Event):void { if (clip.currentFrame >= clip.totalFrames) { clip.stop(); clip.removeEventListener(Event.ENTER_FRAME, arguments.callee); } };
            };
            mc.addEventListener(Event.ENTER_FRAME, last(mc));
            mc.gotoAndPlay(2);
         }
         for each (var on:String in what.remove || []) { var op:DisplayObject = room.part(on); if (op && op.parent) op.parent.removeChild(op); }
      }

      /**
       * The way on (door b): an arrow on the floor before it, pointing to it, drawn as the map
       * draws its things (a dark outline, warm colours) and lying on the floor seen at an angle.
       */
      private function wayOn(room:IModRoom, b:Rectangle, spot:Array = null):void
      {
         // The 副本's own arrow where it stood; else one drawn on the floor.
         if (spot != null)
         {
            game.gameArt(ARROW_FILE, spot[3] ? ARROW_R : ARROW_L, function(art:DisplayObject):void
            {
               if (game.currentRoom != room) return;
               if (art == null) { drawnArrow(room, b); return; }
               var holder:Sprite = new Sprite();
               holder.mouseEnabled = holder.mouseChildren = false;
               holder.rotation = spot[2];
               holder.addChild(art);
               room.add(holder, Math.min(spot[0], DOOR_RIGHT - 30), spot[1], "front");
               var fade:Function = function(e:Event):void { holder.alpha = roomCleared(room.id) ? 1 : 0.45; };
               holder.addEventListener(Event.ENTER_FRAME, fade);
               room.onLeave(function():void { holder.removeEventListener(Event.ENTER_FRAME, fade); });
            });
            return;
         }
         drawnArrow(room, b);
      }

      private function drawnArrow(room:IModRoom, b:Rectangle):void
      {
         var to:Point = new Point(b.x + b.width / 2, b.y + b.height / 2);
         var from:Point = new Point(room.roomWidth / 2, 330);
         // On the floor, before the door: from the door's foot towards the room's middle.
         var at:Point = null;
         for (var k:Number = 0; k <= 1; k += 0.05)
         {
            var c:Point = new Point(to.x + (from.x - to.x) * (0.15 + k * 0.6), Math.min(b.bottom, to.y + 20) + (from.y - to.y) * (0.15 + k * 0.6));
            if (!room.blocked(c.x, c.y) && !room.blocked(c.x - 30, c.y) && !room.blocked(c.x + 30, c.y)) { at = c; break; }
         }
         if (at == null) at = new Point(to.x, Math.min(b.bottom, 520));
         var angle:Number = Math.atan2((to.y - at.y) / 0.55, to.x - at.x);
         var arrow:Sprite = new Sprite();
         arrow.mouseEnabled = arrow.mouseChildren = false;
         var face:Shape = new Shape();
         var g:Graphics = face.graphics;
         var pts:Array = [[-26, -8], [6, -8], [6, -20], [30, 0], [6, 20], [6, 8], [-26, 8]];
         var m:Function = function(p:Array):Point
         {
            var x:Number = p[0] * Math.cos(angle) - p[1] * Math.sin(angle);
            var y:Number = p[0] * Math.sin(angle) + p[1] * Math.cos(angle);
            return new Point(x, y * 0.55);
         };
         // Its shadow, then the arrow: dark outline, a warm fill, a lighter edge.
         g.beginFill(0x000000, 0.25);
         g.drawEllipse(-30, -9, 60, 22);
         g.endFill();
         for each (var layer:Array in [[5, 0x5A2A00, 0xF29A1F], [0, 0, 0xFFD45A]])
         {
            if (layer[0]) g.lineStyle(layer[0], layer[1], 1, false, "normal", "round", "round");
            else g.lineStyle();
            g.beginFill(layer[2]);
            var first:Point = m(pts[0]);
            if (!layer[0]) first = new Point(first.x * 0.7, first.y * 0.7 - 1);
            g.moveTo(first.x, first.y);
            for (var i:int = 1; i <= pts.length; i++)
            {
               var q:Point = m(pts[i % pts.length]);
               if (!layer[0]) q = new Point(q.x * 0.7, q.y * 0.7 - 1);
               g.lineTo(q.x, q.y);
            }
            g.endFill();
         }
         arrow.addChild(face);
         room.add(arrow, at.x, at.y, "back");
         // It moves a little towards the door and back.
         var t:int = 0;
         var dx:Number = Math.cos(angle) * 5, dy:Number = Math.sin(angle) * 5 * 0.55;
         var bob:Function = function(e:Event):void
         {
            var w:Number = Math.sin(++t / 7);
            face.x = dx * w;
            face.y = dy * w;
            // Faint while the room's guards still keep the way.
            arrow.alpha = roomCleared(room.id) ? 1 : 0.45;
         };
         arrow.addEventListener(Event.ENTER_FRAME, bob);
         room.onLeave(function():void { arrow.removeEventListener(Event.ENTER_FRAME, bob); });
      }

      /** The room's chest (its piece of the scene: frame 1 shut, 2 shining, 3 open), opened once. */
      private function chest(room:IModRoom, part:String):void
      {
         var box:MovieClip = room.part(part) as MovieClip;
         if (box == null) return;
         var key:String = "chest_" + room.id;
         var show:Function = function():void
         {
            try { box.gotoAndStop(game.getData(key) ? 3 : roomCleared(room.id) ? 2 : 1); } catch (e:Error) {}
         };
         show();
         var shine:Function = function(e:Event):void { if (!game.getData(key) && roomCleared(room.id) && box.currentFrame == 1) show(); };
         box.addEventListener(Event.ENTER_FRAME, shine);
         room.onLeave(function():void { box.removeEventListener(Event.ENTER_FRAME, shine); });
         var b:Rectangle = box.getBounds(DisplayObject(room));
         // Not over a way on (下水道深处's GO is beside it).
         for each (var db:Rectangle in doorBoxes) if (b.intersects(db) && db.x > b.x) b.width = Math.max(30, db.x - b.x);
         room.door(b.x, b.y, b.width, b.height, "", function():void
         {
            if (game.getData(key)) { worker("宝箱已经空了。"); return; }
            if (!roomCleared(room.id)) { worker("那是蚁将军的宝箱！可守卫还盯着呢，先把他们打倒。"); return; }
            game.setData(key, true);
            show();
            var m:Object = mode;
            game.giveItem(CANDY, m.chestCandy);
            game.giveItem(BEAN, m.chestBean);
            worker("是蚁将军藏下的物资！奥拉人还没来得及搬走。");
         }, false);
      }

      /**
       * The 奥拉 army's portal in 蚁神殿正殿, open once the 变异蚁将军 has fallen: a ring of light on
       * the floor's edge, walked into to reach 奥拉星's 传送核心.
       */
      private function portal(room:IModRoom):void
      {
         var at:Point = new Point(PORTAL[0], PORTAL[1]);
         for (var r:int = 0; r <= 120 && room.blocked(at.x, at.y); r += 6) at = new Point(PORTAL[0] - r, PORTAL[1] + r * 0.4);
         var p:Sprite = new Sprite();
         p.mouseEnabled = p.mouseChildren = false;
         var glow:Shape = new Shape();
         glow.graphics.beginFill(0x000000, 0.3);
         glow.graphics.drawEllipse(-52, -10, 104, 22);
         glow.graphics.endFill();
         p.addChild(glow);
         var ring:Shape = new Shape();
         var g:Graphics = ring.graphics;
         for each (var layer:Array in [[14, 0x1E5FB3, 0.35], [8, 0x47B8FF, 0.8], [3, 0xE6FBFF, 1]])
         {
            g.lineStyle(layer[0], layer[1], layer[2]);
            g.drawEllipse(-40, -128, 80, 124);
         }
         g.lineStyle();
         g.beginFill(0x7FD8FF, 0.28);
         g.drawEllipse(-36, -124, 72, 116);
         g.endFill();
         p.addChild(ring);
         var swirl:Shape = new Shape();
         swirl.y = -66;
         for (var i:int = 0; i < 3; i++)
         {
            swirl.graphics.lineStyle(2, 0xFFFFFF, 0.55 - i * 0.15);
            var a0:Number = i * Math.PI * 2 / 3;
            swirl.graphics.moveTo(Math.cos(a0) * 6, Math.sin(a0) * 9);
            for (var t:Number = 0; t <= 1.6; t += 0.1)
               swirl.graphics.lineTo(Math.cos(a0 + t * 3) * (6 + t * 18), Math.sin(a0 + t * 3) * (9 + t * 30));
         }
         p.addChild(swirl);
         room.add(p, at.x, at.y, "players");
         var spin:Function = function(e:Event):void { swirl.rotation += 4; ring.alpha = 0.85 + Math.sin(swirl.rotation / 20) * 0.15; };
         p.addEventListener(Event.ENTER_FRAME, spin);
         room.onLeave(function():void { p.removeEventListener(Event.ENTER_FRAME, spin); });
         room.door(at.x - 45, at.y - 130, 90, 140, "", function():void { game.enter("core"); }, false);
      }

      /** The pieces of c that hold words (a speech bubble of the scene), hidden. */
      private static function hideWords(c:DisplayObjectContainer):void
      {
         if (c == null) return;
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var d:DisplayObject = c.getChildAt(i);
            if (holdsWords(d)) d.visible = false;
         }
      }

      private static function holdsWords(d:DisplayObject):Boolean
      {
         if (d is TextField || d is StaticText) return true;
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c == null) return false;
         for (var i:int = 0; i < c.numChildren; i++) if (holdsWords(c.getChildAt(i))) return true;
         return false;
      }

      /** Where a piece of the scene is, in the room: its bounds, or null. */
      private static function boundsOf(room:IModRoom, name:String):Rectangle
      {
         var p:DisplayObject = room.part(name);
         return p != null ? p.getBounds(DisplayObject(room)) : null;
      }

      /** A cage round a piece of the scene (by its name), opened when guard `by` falls. */
      private function cageOver(room:IModRoom, by:String, part:String):void
      {
         var piece:DisplayObject = room.part(part);
         var b:Rectangle = boundsOf(room, part);
         if (piece == null || b == null || b.width < 4) return;
         cageAt(room, by, piece, new Point(b.x + b.width / 2, b.bottom - 2), b.width / 2 + 10, b.height + 6, null);
      }

      /**
       * A round cage standing on the floor at foot (in the room) round figure (a captive or a piece
       * of the scene), opened when guard `by` falls: a: its radius; h: its bars' height; label: a
       * name written under it. It takes the figure's depth: its back just behind the figure, its
       * front just before it, so that whoever walks behind the figure is behind the cage too.
       */
      private function cageAt(room:IModRoom, by:String, figure:DisplayObject, foot:Point, a:Number, h:Number, label:String):void
      {
         var b:Number = Math.round(a * 0.3);
         var dome:Number = Math.min(28, a * 0.38);
         var back:Sprite = new Sprite();
         var front:Sprite = new Sprite();
         var inBack:Sprite = new Sprite();
         var inFront:Sprite = new Sprite();
         back.addChild(inBack);
         front.addChild(inFront);
         inBack.addChild(cageShadow(a, b));
         inBack.addChild(cageHalf(a, b, h, dome, false));
         inFront.addChild(cageHalf(a, b, h, dome, true));
         if (label)
         {
            var t:TextField = new TextField();
            t.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF, true);
            t.autoSize = "center";
            t.selectable = false;
            t.text = label;
            t.filters = [new GlowFilter(0x0B2440, 1, 3, 3, 6)];
            t.x = -t.width / 2;
            t.y = b + 9;
            inFront.addChild(t);
         }
         for each (var c:Sprite in [back, front]) c.mouseEnabled = c.mouseChildren = false;
         var parent:DisplayObjectContainer = figure != null ? figure.parent : null;
         if (parent == null)
         {
            room.add(back, foot.x, foot.y, "back");
            room.add(front, foot.x, foot.y, "front");
         }
         else
         {
            var r:DisplayObject = DisplayObject(room);
            var p0:Point = parent.globalToLocal(r.localToGlobal(foot));
            var p1:Point = parent.globalToLocal(r.localToGlobal(new Point(foot.x + 100, foot.y)));
            var k:Number = (p1.x - p0.x) / 100;
            if (!(k > 0.01)) k = 1;
            back.x = front.x = p0.x;
            back.y = figure.y - 0.5;
            front.y = figure.y + 0.5;
            back.scaleX = back.scaleY = front.scaleX = front.scaleY = k;
            inBack.y = (p0.y - back.y) / k;
            inFront.y = (p0.y - front.y) / k;
            var i:int = parent.getChildIndex(figure);
            parent.addChildAt(back, i);
            parent.addChildAt(front, i + 2);
         }
         (cages[by] ||= []).push(back, front);
         cageFeet[by] = foot;
         (cageRects[by] ||= []).push(new Rectangle(foot.x - a - 6, foot.y - h - dome - 10, 2 * a + 12, h + dome + b + (label ? 34 : 16)));
      }

      /** The cage's shadow on the floor. */
      private static function cageShadow(a:Number, b:Number):Shape
      {
         var s:Shape = new Shape();
         s.graphics.beginFill(0x000000, 0.4);
         s.graphics.drawEllipse(-a - 10, -b - 4, 2 * (a + 10), 2 * (b + 4) + 6);
         s.graphics.endFill();
         s.filters = [new BlurFilter(14, 8, 2)];
         return s;
      }

      /**
       * Half of a round cage, round 0, 0 (where it stands), the floor's circle seen from above at
       * an angle (radii a, b): its back (the plate, the bars and rings round the far side) or its
       * front (the plate's rim, the near bars and rings, the lock).
       */
      private static function cageHalf(a:Number, b:Number, h:Number, dome:Number, front:Boolean):Shape
      {
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         var t0:Number = front ? 0 : Math.PI;
         var t1:Number = t0 + Math.PI;
         if (!front)
         {
            g.lineStyle(1.5, 0x1A1D24, 1);
            g.beginFill(0x454B58);
            g.drawEllipse(-a - 4, -b - 2, 2 * (a + 4), 2 * (b + 2));
            g.endFill();
            g.lineStyle(1, 0x8A93A6, 0.55);
            g.drawEllipse(-a + 3, -b + 1, 2 * (a - 3), 2 * (b - 1));
         }
         else
         {
            // The plate's rim, its side seen.
            g.lineStyle(1, 0x15171C, 1);
            g.beginFill(0x2C3039);
            g.moveTo(a + 4, 0);
            var j:int;
            for (j = 0; j <= 24; j++) g.lineTo((a + 4) * Math.cos(Math.PI * j / 24), (b + 2) * Math.sin(Math.PI * j / 24));
            for (j = 24; j >= 0; j--) g.lineTo((a + 4) * Math.cos(Math.PI * j / 24), (b + 2) * Math.sin(Math.PI * j / 24) + 7);
            g.lineTo(a + 4, 0);
            g.endFill();
            g.lineStyle(1.2, 0x9AA3B5, 0.8);
            arc(g, 0, 0, a + 4, b + 2, 0.15, Math.PI - 0.15);
         }
         // The bars, each with its rib of the dome: those round the far side behind, the rest before.
         var n:int = Math.max(12, Math.round(Math.PI * 2 * a / 19));
         if (n % 2) n++;
         for (var i:int = 0; i < n; i++)
         {
            var t:Number = (i + 0.5) * Math.PI * 2 / n;
            if ((Math.sin(t) > 0) != front) continue;
            var x:Number = a * Math.cos(t);
            var y:Number = b * Math.sin(t);
            g.lineStyle(front ? 4.5 : 3.2, front ? 0x252932 : 0x3B404C, front ? 1 : 0.9);
            g.moveTo(x, y);
            g.lineTo(x, y - h);
            g.curveTo(x, y - h - dome, 0, -h - dome);
            if (front)
            {
               g.lineStyle(1.3, 0xB6BFCF, 0.85);
               g.moveTo(x - 1.3, y - 2);
               g.lineTo(x - 1.3, y - h + 2);
            }
         }
         // The rings: a low one and the top one.
         for each (var ry:Number in [-14, -h])
         {
            g.lineStyle(ry == -h ? 6 : 4, front ? 0x3A3F4B : 0x434855, 1);
            arc(g, 0, ry, a, b, t0, t1);
            if (front)
            {
               g.lineStyle(1.5, 0xA9B2C3, 0.8);
               arc(g, 0, ry - 1.5, a, b, t0 + 0.12, t1 - 0.12);
            }
         }
         if (front)
         {
            // The ring at its top, and the lock.
            g.lineStyle(3, 0x3A3F4B);
            g.drawCircle(0, -h - dome - 6, 5);
            var ly:Number = b - h * 0.45;
            g.lineStyle(3, 0xB8860B);
            g.drawCircle(0, ly - 7, 6);
            g.lineStyle(1, 0x5A3D00);
            g.beginFill(0xE0B22E);
            g.drawRoundRect(-9, ly - 3, 18, 15, 5, 5);
            g.endFill();
            g.lineStyle();
            g.beginFill(0x5A3D00);
            g.drawCircle(0, ly + 3, 2);
            g.endFill();
         }
         return s;
      }

      /** Part of the ellipse round cx, cy (radii a, b) from angle t0 to t1, as a line. */
      private static function arc(g:Graphics, cx:Number, cy:Number, a:Number, b:Number, t0:Number, t1:Number):void
      {
         var steps:int = 28;
         g.moveTo(cx + a * Math.cos(t0), cy + b * Math.sin(t0));
         for (var i:int = 1; i <= steps; i++)
         {
            var t:Number = t0 + (t1 - t0) * i / steps;
            g.lineTo(cx + a * Math.cos(t), cy + b * Math.sin(t));
         }
      }

      /** Where a cage of radius a can stand near x, y: its whole floor on the floor of the room. */
      private static function floorFor(room:IModRoom, x:Number, y:Number, a:Number):Point
      {
         var b:Number = a * 0.3;
         for (var r:int = 0; r <= 90; r += 6)
         {
            for (var k:int = 0; k < (r == 0 ? 1 : 16); k++)
            {
               var px:Number = x + r * Math.cos(k * Math.PI / 8);
               var py:Number = y + r * Math.sin(k * Math.PI / 8);
               if (!room.blocked(px, py) && !room.blocked(px - a, py) && !room.blocked(px + a, py)
                  && !room.blocked(px, py - b) && !room.blocked(px, py + b + 6)
                  && !room.blocked(px - a * 0.7, py + b * 0.7) && !room.blocked(px + a * 0.7, py + b * 0.7))
                  return new Point(px, py);
            }
         }
         return new Point(x, y);
      }

      /**
       * A guard's cage and captive (its pieces of the scene or its 亚比), and where it would stand:
       * {g, x, y, own (its cages' bounds)}, or null (beaten, or nowhere to be). The guards are put
       * once every cage of the room is there (spawnGuard: none of them in front of a cage).
       */
      private function placeGuard(room:IModRoom, g:Object):Object
      {
         var done:Boolean = beaten(g.id);
         for each (var hp:String in g.hide || []) { var hd:DisplayObject = room.part(hp); if (hd) hd.visible = false; }
         // A guard posted at a place of the scene (where a 兵蚁 stood): there, the 兵蚁 hidden.
         if (g.at)
         {
            var spot:Rectangle = boundsOf(room, g.at);
            var was:DisplayObject = room.part(g.at);
            if (was != null) was.visible = false;
            if (spot != null) { g = copy(g); g.x = spot.x + spot.width / 2; g.y = spot.bottom; }
         }
         // The captive's pieces of the scene: gone once it is free.
         var art:Rectangle = null;
         for each (var a:String in g.art || [])
         {
            var p:DisplayObject = room.part(a);
            if (p == null) continue;
            if (done) p.visible = false;
            else if (art == null) art = p.getBounds(DisplayObject(room));
         }
         if (done) return null;
         if (art != null && g.captive) for each (var a1:String in g.art || []) cageOver(room, g.id, a1);
         var x:Number = g.x || 480;
         var y:Number = g.y || 420;
         var side:int = g.side || 0;
         if (art != null)
         {
            if (!side) side = art.x + art.width / 2 < room.roomWidth / 2 ? 1 : -1;
            x = art.x + art.width / 2 + side * (art.width / 2 + 50);
            y = art.bottom;
         }
         else if (g.near || g.cage)
         {
            // The captive, drawn as its 亚比, in a cage: by a piece of the scene, or where it says;
            // the guard beside it.
            var cx:Number, cy:Number;
            if (g.cage) { cx = g.cage[0]; cy = g.cage[1]; side = side || 1; }
            else
            {
               var n:Rectangle = boundsOf(room, g.near);
               if (n == null) return null;
               cx = n.x + n.width / 2 + side * (n.width / 2 + 60);
               cy = n.bottom;
            }
            var stand:Point = floorFor(room, cx, cy, CAGE_R);
            var held:IModNpc = room.npc({look: g.captive, x: stand.x, y: stand.y,
               onClick: function():void { worker("笼子锁着，钥匙在" + g.name + "身上。先打败他！"); }});
            var at:DisplayObject = DisplayObject(held);
            cageAt(room, g.id, at, new Point(at.x, at.y), CAGE_R, 118, "被俘的" + nameOf(g.captive));
            captiveNpcs[g.id] = held;
            // stand: the guard's side of the cage, when not the cage's own side of the piece.
            x = at.x + (g.stand ? g.stand : side) * 95;
            y = at.y + 8;
         }
         if (g.boss && g.look)
         {
            // The 变异蚁将军 itself: the scene's figure of it gives way to the 亚比.
            for each (var a2:String in g.art || []) { var q:DisplayObject = room.part(a2); if (q) q.visible = false; }
         }
         var own:Rectangle = null;
         for each (var r:Rectangle in cageRects[g.id] || []) own = own ? own.union(r) : r.clone();
         return {g: g, x: x, y: y, own: own, foot: cageFeet[g.id]};
      }

      /**
       * The guard, beside its cage: on the floor, and clear of every cage of the room (with the
       * captive's name under it) and of the other guards, at the spot nearest its side of its cage.
       */
      private function spawnGuard(room:IModRoom, pg:Object):void
      {
         var g:Object = pg.g;
         var x:Number = pg.x, y:Number = pg.y;
         var R:Rectangle = pg.own as Rectangle;
         if (R != null)
         {
            var px:Number = x >= R.x + R.width / 2 ? R.right + 48 : R.left - 48;
            var py:Number = pg.foot ? Point(pg.foot).y : R.bottom;
            // front: before its cage (a little to one side, the creature still seen; frontDx: how far).
            if (g.front) { px = R.x + R.width / 2 + (g.frontDx != null ? Number(g.frontDx) : 34); py += 50; }
            // standAt: where by its cage it would rather stand ([dx from the cage's middle, dy from its foot]).
            if (g.standAt) { px = R.x + R.width / 2 + Number(g.standAt[0]); py += Number(g.standAt[1]); }
            var best:Number = Number.MAX_VALUE;
            for (var cx:Number = R.left - 260; cx <= R.right + 260; cx += 8)
            {
               for (var cy:Number = R.top + 40; cy <= R.bottom + 150; cy += 8)
               {
                  var d:Number = (cx - px) * (cx - px) + (cy - py) * (cy - py);
                  if (d >= best || !standable(room, cx, cy, g.front ? g.id : null)) continue;
                  best = d;
                  x = cx;
                  y = cy;
               }
            }
         }
         guardBoxes.push(new Rectangle(x - 40, y - 115, 80, 115));
         var w:Object = {g: g, x: x, y: y, toDoor: doorBoxes.length ? toDoor(new Point(x, y)) : null};
         var npc:IModNpc = room.npc({
            name: g.name,
            look: g.look ? g.look : "npc:" + g.npc,
            x: x,
            y: y,
            scale: g.look is int ? 1.3 : 1,
            tip: "点击挑战",
            onClick: function():void { if (!engaged) engage(room, w); }
         });
         w.npc = npc;
         watched.push(w);
      }

      /** Whether a guard can stand at x, y: on the floor, in front of no cage, beside no other guard. */
      private function standable(room:IModRoom, x:Number, y:Number, mine:String = null):Boolean
      {
         if (x < 40 || x > room.roomWidth - 40 || y < 130 || y > 500) return false;
         if (room.blocked(x, y) || room.blocked(x - 24, y) || room.blocked(x + 24, y)) return false;
         var box:Rectangle = new Rectangle(x - 40, y - 115, 80, 115);
         for (var by:String in cageRects)
         {
            if (by == mine) continue;
            for each (var cr:Rectangle in cageRects[by]) if (box.intersects(new Rectangle(cr.x, cr.y, cr.width, cr.height + 18))) return false;
         }
         for each (var other:Rectangle in guardBoxes) if (other.intersects(box)) return false;
         for each (var db:Rectangle in doorBoxes) if (box.intersects(new Rectangle(db.x - 10, db.y - 10, db.width + 20, db.height + 30))) return false;
         return true;
      }

      /** The 工蚁's words (not the game's message box, which shows the HELLO). */
      private function worker(text:String):void
      {
         game.talk({name: "工蚁", picture: WORKER}, [text]);
      }

      private static function copy(o:Object):Object
      {
         var c:Object = {};
         for (var k:String in o) c[k] = o[k];
         return c;
      }

      private function nameOf(race:int):String
      {
         var names:Object = {"244": "牛角滴滴", "242": "金刚蛤蟆", "241": "毒菇球", "243": "下水猛鳄", "218": "守护力士", "219": "守护法师",
            "220": "蚁族圣斗士", "221": "蚁族魔斗士", "225": "保斯", "223": "兰斯罗特", "224": "哥拉海德", "222": "贝德威尔", "226": "蚁将军"};
         return names[String(race)] || "亚比";
      }

      // ---------------------------------------------------------------- fights

      // ---------------------------------------------------------------- the guards keep the way

      /** Each frame: a guard the player has come near stops them and challenges them. */
      private function watch(room:IModRoom):void
      {
         if (game.currentRoom != room || !game.getData("intro") || game.getData("over") || game.getData("done")) return;
         var p:Point = room.player;
         if (p == null) return;
         var here:Number = doorBoxes.length ? toDoor(p) : 0;
         if (cameAt < 0) cameAt = here;
         var near:Object = null;
         for each (var w:Object in watched)
         {
            if (beaten(w.g.id)) continue;
            var dx:Number = p.x - w.x;
            var dy:Number = (p.y - w.y) / SQUASH;
            var dd:Number = dx * dx + dy * dy;
            // Near it, or slipping past it to the way it keeps.
            var within:Boolean = dd < REACH * REACH;
            // Slipping past it to the way it keeps: nearer that door than the guard, and gone on
            // towards it from where the player came in.
            var passing:Boolean = dd < PASS * PASS && w.toDoor != null && here < Number(w.toDoor) - 30 && here < cameAt - 40;
            // Within its reach on entering the room: it steps in once the player has been out of it.
            if (w.armed == undefined) w.armed = !within;
            if (!within) w.armed = true;
            if (near == null && ((within && w.armed) || passing)) near = w;
         }
         if (engaged)
         {
            // The conversation was shut without an answer, and the player walked off: free again.
            if (engagedAt != null && Point.distance(p, engagedAt) > 40) engaged = false;
            return;
         }
         if (near == null) { safe = p.clone(); return; }
         if (getTimer() < calmUntil) return;
         engage(room, near);
      }

      /** How far p is from the nearest way on of the room shown (their doors' middles). */
      private function toDoor(p:Point):Number
      {
         var best:Number = Number.MAX_VALUE;
         for each (var b:Rectangle in doorBoxes) best = Math.min(best, Point.distance(p, new Point(b.x + b.width / 2, b.y + b.height / 2)));
         return best;
      }

      /** The guard w stops the player and challenges them. */
      private function engage(room:IModRoom, w:Object):void
      {
         engaged = true;
         var p:Point = room.player;
         engagedAt = p != null ? p.clone() : null;
         if (p != null) room.walkTo(p.x, p.y);
         challenge(w.g, w.npc, function():void { stepBack(room, w); });
      }

      /** Not fighting now (or lost): the player steps back, well out of the guard's reach. */
      private function stepBack(room:IModRoom, w:Object):void
      {
         engaged = false;
         calmUntil = getTimer() + 2500;
         if (game.currentRoom != room) return;
         var p:Point = room.player;
         var from:Point = safe != null ? safe : p;
         if (from == null) return;
         // Away from the guard, the way the player came (on the floor seen at an angle).
         var dx:Number = from.x - w.x;
         var dy:Number = (from.y - w.y) / SQUASH;
         var len:Number = Math.max(1, Math.sqrt(dx * dx + dy * dy));
         for (var d:Number = REACH + 60; d >= REACH + 10; d -= 10)
         {
            var t:Point = new Point(w.x + dx / len * d, w.y + dy / len * d * SQUASH);
            if (!room.blocked(t.x, t.y)) { room.walkTo(t.x, t.y); return; }
         }
         if (safe != null) room.walkTo(safe.x, safe.y);
      }

      private function challenge(g:Object, npc:IModNpc, away:Function):void
      {
         for each (var need:String in g.need || [])
         {
            if (!beaten(need))
            {
               npc.talk(["先赢了兰丁和弗洛拉，再来找我。"], away);
               return;
            }
         }
         var ask:Function = function():void
         {
            npc.talk([{text: g.say, choices: [
               ["战斗！", function():void { fight(g, npc, away); }],
               ["先准备一下", away]
            ]}]);
         };
         ask();
      }

      private function fight(g:Object, npc:IModNpc, away:Function):void
      {
         var m:Object = mode;
         var pct:int = g.boss ? m.boss : m.foe;
         var race:int = g.race is Array ? g.race[int(Math.random() * g.race.length)] : int(g.race);
         game.fight(teamOf(g, race, m), function(win:Boolean):void
         {
            game.partyState(function(st:Object):void { afterFight(g, npc, win, st, away); });
         }, false, true);
      }

      /**
       * Whom g brings, weakest first, sent out one after another in one battle (fight: together):
       * m.team 亚比 (简单 2, 普通 4, 困难 6), none below m.minLv (80, 90, 100), every one at its highest
       * form. An 奥拉 guard: its own 亚比 and those of the guards beside it in the list; the 变异蚁将军:
       * the 蚁将军's 兵蚁 before it; 小奥拉: his three; the three of the 指挥中心: their one.
       */
      private function teamOf(g:Object, race:int, m:Object):Array
      {
         var pct:int = g.boss ? m.boss : m.foe;
         // top: 小奥拉 and the three of the 指挥中心, at the mode's own level (简单 100, 普通 110, 困难 120).
         var level:int = g.top ? int(m.topLv) : g.boss ? g.level : Math.min(100, g.level + int(m.lv));
         var cap:int = g.top ? int(m.topLv) : 100;
         // The strongest (out last) at the mode's strength (foe, boss); those before it weaker (helper).
         var one:Function = function(r:int, lv:int, main:Boolean = false):Object
         {
            var q:int = main ? pct : int(m.helper);
            // Never below the mode's least level (简单 80, 普通 90, 困难 100).
            return {race: r, level: Math.max(int(m.minLv), Math.min(cap, lv)), hp: main && g.boss ? m.bossHp : q, at: q, de: q, sa: q, sd: q, sp: q};
         };
         var n:int = Math.max(1, int(m.team));
         if (g.id == "mutant")
         {
            var minions:Array = [];
            for (var k:int = 1; k < n; k++) minions.unshift(one(BINGYI, 97 - k));
            return minions.concat([one(race, level, true)]);
         }
         if (g.all)
         {
            // Every one of its 亚比, in a random order.
            var order:Array = (g.race as Array).concat();
            for (var s:int = order.length - 1; s > 0; s--) { var j:int = int(Math.random() * (s + 1)); var tmp:* = order[s]; order[s] = order[j]; order[j] = tmp; }
            return order.map(function(r:*, i:int, a:Array):Object { var o:Object = one(int(r), level, true); o.hp = o.at; return o; });
         }
         if (g.boss) return [one(race, level, true)];
         // Every one at its highest form: its own 亚比 (out last), then those of the guards beside it
         // in the list, nearest first (the one before, the one after …), each once.
         var i:int = GUARDS.indexOf(g);
         var finals:Array = [race];
         var add:Function = function(o:Object):void
         {
            if (o != null && !o.boss && !(o.race is Array) && finals.indexOf(int(o.race)) < 0) finals.push(int(o.race));
         };
         for (var d:int = 1; finals.length < n && d < GUARDS.length; d++) { add(i - d >= 0 ? GUARDS[i - d] : null); add(GUARDS[i + d]); }
         // Weakest first, each a step of levels below the next (step).
         var st:int = int(m.step);
         var team:Array = [];
         for (var k:int = Math.min(n, finals.length) - 1; k >= 0; k--) team.push(one(int(finals[k]), level - k * st, k == 0));
         return team;
      }

      private function afterFight(g:Object, npc:IModNpc, win:Boolean, st:Object, away:Function):void
      {
         var keep:Object = null;
         for each (var p:Object in st.pets || []) if (p.keep) keep = p;
         if (!win)
         {
            if (keep == null || int(keep.hp) <= 0) gameOver();
            else
            {
               away();
               worker("先撤回来，整顿好再上！");
            }
            return;
         }
         markBeaten(g.id);
         // The 副本's gate this guard kept opens, and the room's own once it is clear.
         var here0:IModRoom = game.currentRoom;
         if (here0 != null && g.gate) openWay(here0, g.gate, true);
         var rd:Object = null;
         for each (var rr:Object in ROOMS) if (here0 != null && rr.id == here0.id) rd = rr;
         if (here0 != null && rd != null && rd.cleared && roomCleared(rd.id)) openWay(here0, rd.cleared, true);
         // Held till the words after the win are read (no other guard steps in meanwhile).
         engaged = true;
         engagedAt = game.currentRoom ? game.currentRoom.player : null;
         if (npc != null) npc.remove();
         var room0:IModRoom = game.currentRoom;
         for each (var c:Sprite in cages[g.id] || []) if (room0) room0.remove(c);
         delete cages[g.id];
         // The reward in the game's own windows (as a boss's 亚比蛋), not in anyone's words.
         var m:Object = mode;
         game.giveItem(CANDY, m.winCandy + (g.boss ? m.bossCandy : 0));
         game.giveItem(BEAN, m.winBean + (g.boss ? m.bossBean : 0));
         var guardSays:Function = function(then:Function):void
         {
            // An NPC of the game: its picture; an 奥拉 dressed by the mod: as it stood.
            if (g.lost && (g.npc || npc)) game.talk({name: g.name, picture: g.npc ? "npc:" + g.npc : npc.view}, [g.lost], then);
            else then();
         };
         // A creature of which one has joined already (the 牛角滴滴): it thanks them and goes home.
         var joined:Boolean = false;
         for each (var o:Object in GUARDS) if (o.id != g.id && o.captive == g.captive && beaten(o.id)) joined = true;
         if (g.captive && joined)
         {
            guardSays(function():void
            {
               game.talk({name: nameOf(g.captive), picture: "pet:" + g.captive}, ["咕噜！谢谢你们！我这就回去告诉同伴们，王朝有救了！"], function():void { afterWin(g); });
            });
            return;
         }
         if (g.captive)
         {
            game.givePet(g.captive, 100);
            guardSays(function():void
            {
               game.talk({name: nameOf(g.captive), picture: "pet:" + g.captive}, [THANKS[String(g.captive)] || "谢谢你们！",
                  "<font color='#FF6600'>" + nameOf(g.captive) + "（Lv100）加入了队伍！</font>"], function():void { afterWin(g); });
            });
            return;
         }
         if (g.gift)
         {
            game.givePet(g.gift, 100);
            game.talk({name: nameOf(g.gift), picture: "npc:160"}, [g.lost,
               "……我这是怎么了？奥拉人在我身上做了实验，后面的事，我什么都记不清了……只记得他们命令我守着蚁后。",
               "蚁后！蚁后还被关着！"], function():void
            {
               // The 蚁后's cage opens: her words, as she stood in it, and she is gone from it.
               var here0:IModRoom = game.currentRoom;
               var queen:DisplayObject = here0 ? here0.part("mc_antQueen") : null;
               // No more 救命: her speech bubble goes.
               hideWords(queen as DisplayObjectContainer);
               game.talk({name: "蚁后", picture: queen}, ["兵蚁，工蚁，还有我的将军……谢谢你们。",
                  "奥拉人在正殿里架了一座传送门，他们的补给和援兵都是从那里来的。门的另一头，就是奥拉星的传送核心。",
                  "只要他们的指挥中心还在下命令，奥拉人迟早会再打回来。去那里，让他们亲口答应撤军吧。"], function():void
               {
                  if (queen) queen.visible = false;
                  game.talk({name: nameOf(g.gift), picture: "npc:160"}, ["这一次，换我和你们并肩作战。",
                     "<font color='#FF6600'>蚁将军（Lv100）加入了队伍！</font>"], function():void { afterWin(g); });
               });
            });
            return;
         }
         guardSays(function():void { afterWin(g); });
      }

      private function afterWin(g:Object):void
      {
         engaged = false;
         calmUntil = getTimer() + 1500;
         refreshHud();
         // The freed one has joined: its figure leaves the room.
         var here:IModRoom = game.currentRoom;
         for each (var a:String in g.art || []) { var d:DisplayObject = here ? here.part(a) : null; if (d) d.visible = false; }
         if (captiveNpcs[g.id]) { IModNpc(captiveNpcs[g.id]).remove(); delete captiveNpcs[g.id]; }
         if (g.id == "mutant")
         {
            var queen1:DisplayObject = here ? here.part("mc_antQueen") : null;
            if (queen1) queen1.visible = false;
            game.talk({name: "工蚁", picture: WORKER}, ["蚁后说的传送门……在那儿！兵蚁大哥，我们走！"], function():void { if (here) portal(here); });
         }
         else if (g.id == "kid")
         {
            game.talk({name: "工蚁", picture: WORKER}, ["那个奥拉人跑去报信了。指挥中心就在前面——这回，该和他们的头儿当面谈谈了。"], function():void { game.enter("hq"); });
         }
         else if (g.id == "rabel") ending();
         else if (game.currentRoom != null && roomCleared(game.currentRoom.id) && g.room != "hq")
         {
            worker("这里清干净了，继续前进！");
         }
      }

      // ---------------------------------------------------------------- story

      private function chooseMode():void
      {
         var pick:Function = function(id:String):Function
         {
            return function():void
            {
               resetRun();
               game.setData("mode", id);
               game.party(partyDef(true), function(st:Object):void
               {
                  if (st == null) { worker("队伍没能组建起来。"); return; }
                  refreshHud();
                  intro();
               });
            };
         };
         game.talk({name: "工蚁", picture: WORKER}, [
            "兵蚁大哥，你总算醒了。三个月前，奥拉人的军队攻进了蚁族王朝。蚁将军带着我们拼死抵抗，最后还是被俘虏了。",
            "奥拉人在将军身上做了实验，把他变成了只听命令的<font color='#FF6600'>变异蚁将军</font>，让他守在蚁神殿正殿，看着被关起来的<font color='#FF6600'>蚁后</font>。王朝的勇士们，也一个个被关进了笼子。",
            "现在奥拉人和达斯特人开战，主力都调去了前线，留在王朝的守军不多——这是我们唯一的机会。",
            {text: "这一仗，你打算怎么打？", choices: [
               ["简单：守卫各带2只亚比，体力糖充足", pick("easy")],
               ["普通：守卫各带4只亚比，要用好每一位伙伴的技能", pick("normal")],
               ["困难：守卫各带6只亚比，体力糖很少", pick("hard")]
            ]}
         ]);
      }

      private function intro():void
      {
         game.setData("intro", true);
         game.talk({name: "工蚁", picture: WORKER}, [
            "我跟你一起去。从今天起，我就是你的搭档。",
            "路上我缴获了一台奥拉人的HELLO，可它的治疗模块被锁住了。受了伤只能吃<font color='#FF6600'>高级体力糖</font>，技能用光了就用<font color='#FF6600'>高级活力豆</font>——奥拉人的营地里存着不少，打赢了就能缴获。",
            "我们一路打过去：打败守卫，救出被关的同伴，一直打到蚁神殿正殿，把将军和蚁后救出来。",
            "还有，<font color='#FF0000'>你是这场反击的主心骨。你要是倒下，一切就结束了。</font>（兵蚁要一直留在亚比背包里。）",
            "前哨有三个奥拉卫兵把守，走近就会被拦下。先拿下前哨！"
         ]);
      }

      private function gameOver():void
      {
         game.setData("over", true);
         game.talk({name: "工蚁", picture: WORKER}, [
            "兵蚁大哥！兵蚁大哥——！",
            {text: "兵蚁倒下了……蚁族的反击失败了。要重新开始吗？", choices: [
               ["重新开始", function():void { restart(); }],
               ["离开", function():void { game.endParty(); game.leave(); }]
            ]}
         ]);
      }

      private function ending():void
      {
         game.setData("done", true);
         var m:Object = mode;
         game.talk({name: "拉贝尔", picture: "npc:86"}, [
            "占领蚁族王朝，是我们为了对付达斯特人做的决定。我们只想着守住那条补给线，却忘了那里本来是你们的家。",
            "我以指挥中心的名义答应你们：奥拉军立刻撤出蚁族王朝，关闭传送门，被关押的蚁族全部放回。",
            "至于你们的将军……对不起。我会让研究员想办法，彻底消除实验留下的影响。"
         ], function():void
         {
            game.talk({name: "工蚁", picture: WORKER}, [
               "兵蚁大哥……我们真的做到了。",
               "回家吧。蚁后和大家，都在等我们。",
               {text: "<font color='#FF6600'>通关！（难度：" + m.name + "）</font><br>伙伴和道具都留着，王朝里可以随便走走；想换个难度从头再来，随时点「重来」。", choices: [
                  ["回到蚁族王朝", function():void { game.enter("ant1"); }],
                  ["换个难度从头再来", function():void { restart(); }]
               ]}
            ]);
         });
      }

      /** From the start again: the first room shown anew (every guard, cage and gate back), the difficulty asked. */
      private function restart():void
      {
         resetRun();
         game.setData("mode", undefined);
         game.enter("ant1");
      }

      /** What one game keeps: none of it (the guards beaten, the chests opened, where it was). */
      private function resetRun():void
      {
         game.setData("beaten", {});
         game.setData("over", undefined);
         game.setData("done", undefined);
         game.setData("intro", undefined);
         game.setData("room", "ant1");
         for each (var r:Object in ROOMS) if (r.chest) game.setData("chest_" + r.id, undefined);
      }

      // ---------------------------------------------------------------- the strip at the top right

      private function addHud(room:IModRoom):void
      {
         hudBox = new Sprite();
         hud = new TextField();
         hud.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF, true);
         hud.autoSize = "left";
         hud.selectable = false;
         hud.mouseEnabled = false;
         hud.x = 8;
         hud.y = 6;
         hudBox.addChild(hud);
         hudHelp = hudButton("提示", 0xF5A623, 0x4A2400, function():void { hint(); });
         hudBox.addChild(hudHelp);
         hudReset = hudButton("重来", 0x8FB8E0, 0x0B2440, function():void
         {
            game.talk({name: "工蚁", picture: WORKER}, [{text: "要从头再来吗？现在的进度会全部清空。", choices: [
               ["从头再来", function():void { restart(); }],
               ["取消", null]
            ]}]);
         });
         hudBox.addChild(hudReset);
         // A solid strip: a press on it (or its buttons) does not reach the room, so the player
         // does not walk there.
         for each (var type:String in [MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK])
            hudBox.addEventListener(type, function(e:MouseEvent):void { e.stopPropagation(); });
         hudBox.y = 8;
         room.add(hudBox, 0, 8, "screen");
         refreshHud();
      }

      /** A small button of the strip at the top right. */
      private static function hudButton(text:String, fill:uint, ink:uint, onClick:Function):Sprite
      {
         var b:Sprite = new Sprite();
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("_sans", 12, ink, true);
         t.autoSize = "left";
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = text;
         t.x = 8;
         t.y = 2;
         b.graphics.beginFill(fill);
         b.graphics.drawRoundRect(0, 0, t.width + 16, 22, 6, 6);
         b.graphics.endFill();
         b.addChild(t);
         b.buttonMode = true;
         b.mouseChildren = false;
         b.y = 5;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onClick(); });
         return b;
      }

      private function refreshHud():void
      {
         if (hud == null || game == null) return;
         var m:Object = game.getData("mode") ? mode : null;
         hud.text = m ? (game.getData("done") ? "已通关：" : "难度：") + m.name : "";
         hud.visible = m != null;
         // As wide as its words, at the top right.
         hudHelp.x = hud.visible ? hud.x + hud.width + 8 : 6;
         hudReset.x = hudHelp.x + hudHelp.width + 6;
         var w:Number = hudReset.x + hudReset.width + 6;
         hudBox.graphics.clear();
         hudBox.graphics.beginFill(0x0B2440, 0.55);
         hudBox.graphics.drawRoundRect(0, 0, w, 32, 8, 8);
         hudBox.graphics.endFill();
         // Clear of the game's 任务 button at the top right.
         hudBox.x = 900 - w;
      }

      /** The room's 提示: who still stands here, the room's own words, the advice for them. */
      private function hint():void
      {
         var r:IModRoom = game.currentRoom;
         var left:Array = r ? guardsOf(r.id).filter(function(g:Object, i:int, a:Array):Boolean { return !beaten(g.id); }) : [];
         var pages:Array = [];
         if (game.getData("done")) pages.push("蚁族王朝已经夺回来了。伙伴和道具都还在，可以到处走走；想换个难度从头再来，点「重来」。");
         else if (left.length == 0) pages.push("这里已经没有守卫了，从出口前进吧！");
         else
         {
            var names:Array = left.map(function(g:Object, i:int, a:Array):String { return g.name; });
            pages.push("这里还有奥拉守卫：" + names.join("、") + "。走近他们（或者点击他们），就会和他们交手。");
            if (r && ROOM_HINTS[r.id]) pages = pages.concat(ROOM_HINTS[r.id]);
            for each (var g2:Object in left) if (ADVICE[g2.id]) pages = pages.concat(ADVICE[g2.id]);
         }
         game.talk({name: "工蚁", picture: WORKER}, pages);
      }
   }
}
