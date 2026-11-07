package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Shape;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.BlurFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
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
         easy: {name: "简单", lv: -5, foe: 85, boss: 90, bossHp: 120, candy: 8, bean: 4, winCandy: 2, winBean: 1, bossCandy: 2},
         normal: {name: "普通", lv: 0, foe: 100, boss: 110, bossHp: 170, candy: 5, bean: 3, winCandy: 1, winBean: 1, bossCandy: 2},
         hard: {name: "困难", lv: 5, foe: 110, boss: 125, bossHp: 230, candy: 3, bean: 2, winCandy: 1, winBean: 1, bossCandy: 1}
      };

      /** The rooms in order; door: the piece of the scene that leads on. */
      private static const ROOMS:Array = [
         {id: "ant1", scene: "fbsiwude1", name: "蚁穴前哨", next: "ant2", door: "et1"},
         {id: "ant2", scene: "fbsiwude2", name: "蚁兵基地", next: "ant3", door: "pit"},
         {id: "ant3", scene: "fbsiwude3", name: "蚁穴下水道", next: "ant4", door: "et2"},
         {id: "ant4", scene: "fbsiwude4", name: "下水道深处", next: "ant5", door: "et1"},
         {id: "ant5", scene: "fbsiwude5", name: "工蚁聚集地", next: "ant6", door: "et1"},
         {id: "ant6", scene: "fbsiwude6", name: "蚁神守护大厅", next: "ant9", door: "et1"},
         {id: "ant9", scene: "fbsiwude9", name: "蚁神巨像", next: "ant10", door: "et1"},
         {id: "ant10", scene: "fbsiwude10", name: "蚁神殿前殿", next: "ant11", door: "et1"},
         // hide: the scene's fighters by the 蚁将军 (its 副本's), who would look like his guard here.
         {id: "ant11", scene: "fbsiwude11", name: "蚁神殿正殿", next: "core", hide: ["mc_fight"]},
         {id: "core", scene: "maintown1", name: "传送核心", next: "hq", door: "et1", city: true},
         {id: "hq", scene: "maintown2", name: "指挥中心", city: true}
      ];

      /**
       * The 奥拉 guards. npc: the NPC of the game; race: its 亚比 (the NPCs with a 挑战 bring the
       * highest of theirs); captive: the creature it keeps, art: its pieces of the scene (hidden
       * once it is free), near: a piece of the scene it stands by when it has none of its own.
       */
      private static const GUARDS:Array = [
         {id: "nike", room: "ant1", npc: 28, name: "卫兵尼克", race: 36, level: 55, x: 600, y: 430, at: "ant1",
            say: "站住！蚁族的残兵也敢回来？", lost: "这只兵蚁好厉害……我得去报告司令官！"},
         {id: "guard1", room: "ant2", npc: 82, name: "卫兵杰克", race: 18, level: 60, x: 560, y: 420, at: "ant1",
            say: "探照灯早就发现你们了！", lost: "守不住了，快撤！"},
         {id: "hade", room: "ant3", npc: 26, name: "治安官哈德", race: 72, level: 65, captive: 244, art: ["npc_0", "npc_1", "npc_2"],
            say: "这几只牛角滴滴归我看管，谁也别想带走！", lost: "我的斯多王……竟然输给了一只兵蚁？"},
         {id: "hunter", room: "ant4", npc: 142, name: "军需官亨特", race: 21, level: 70, captive: 242, art: ["npc_1"],
            say: "下水道的宝贝都登记在册了，金刚蛤蟆也是！", lost: "账本……我的账本……"},
         {id: "guard2", room: "ant4", npc: 82, name: "卫兵马克", race: 189, level: 70, captive: 241, art: ["npc_0"],
            say: "毒菇球是我们的战利品！", lost: "撤！快撤！"},
         {id: "lucas", room: "ant4", npc: 148, name: "训练官卢卡斯", race: 299, level: 72, captive: 243, art: ["npc_2"],
            say: "下水猛鳄正在接受骑乘训练，你们别来捣乱！", lost: "训练……只好以后再说了。"},
         {id: "mach", room: "ant5", npc: 172, name: "机械师马赫", race: 99, level: 75, x: 520, y: 400,
            say: "我的火花龙专烧木属性的小虫子！", lost: "火花龙怕水……我怎么没想到！"},
         {id: "knight1", room: "ant6", npc: 145, name: "骑士团卫兵罗兰", race: 45, level: 80, captive: 218, near: "btn_guard", side: -1,
            say: "守护力士已经被骑士团接管了！", lost: "骑士团的荣誉……"},
         {id: "knight3", room: "ant6", npc: 146, name: "骑士团卫兵崔斯坦", race: 204, level: 80, captive: 219, near: "btn_guard", side: 1,
            say: "守护法师交给骑士团看管，谁也别想带走！", lost: "这只兵蚁……比骑士还勇敢。"},
         {id: "vick", room: "ant9", npc: 13, name: "异星使者维克", race: 63, level: 85, captive: 220, art: ["ant_0"],
            say: "蚁族圣斗士由我来看守，你们回去吧。", lost: "蚁族……比我想象的更顽强。"},
         {id: "bluebrook", room: "ant9", npc: 221, name: "蓝宝卫兵布鲁克", race: 293, level: 85, captive: 221, art: ["ant_1"],
            say: "魔斗士由蓝宝卫队看守，退下！", lost: "蓝宝卫队……撤退！"},
         {id: "arthur", room: "ant10", npc: 147, name: "骑士团长亚瑟", race: 290, level: 90, captive: 225, hide: ["btnPet_1"], cage: [212, 254], side: 1,
            say: "守护骑士保斯，现在是我的俘虏。", lost: "好剑术……不，好爪子！"},
         {id: "knight2", room: "ant10", npc: 146, name: "骑士团卫兵高文", race: 45, level: 90, captive: 223, hide: ["btnPet_2"], cage: [412, 306], side: -1,
            say: "兰斯罗特的火焰已经被我们封住了！", lost: "封印……被解开了！"},
         {id: "magellan", room: "ant10", npc: 9, name: "司令官麦哲伦", race: 236, level: 92, captive: 224, hide: ["btnPet_3"], cage: [608, 380], side: -1,
            say: "大部队虽然调走了，我麦哲伦还在！", lost: "大意了……该把部队留下的。"},
         {id: "lanbao", room: "ant10", npc: 221, name: "蓝宝卫兵雷恩", race: 33, level: 92, captive: 222, hide: ["btnPet_4"], cage: [804, 433], side: -1,
            say: "贝德威尔的冰雾海？在我这儿不管用！", lost: "好冷……我的鲨鱼王冻住了！"},
         {id: "mutant", room: "ant11", race: 227, level: 100, boss: true, look: 227, art: ["btn_general"], name: "变异蚁将军",
            gift: GENERAL, say: "吼——！！奥拉人……命令……消灭……入侵者……", lost: "我……我是……蚁族的……将军……"},
         {id: "kid", room: "core", npc: 279, name: "小奥拉", race: [502, 501, 500], level: 100, x: 470, y: 400, boss: true,
            say: "一只兵蚁闯进了传送核心？我的初始亚比可不是吃素的！", lost: "哇，好强！我、我去告诉兰丁队长！"},
         {id: "landing", room: "hq", npc: 94, name: "兰丁", race: 1648, level: 100, x: 330, y: 430, boss: true,
            say: "菲尔的火焰能烧光木属性的蚂蚁。想过我这一关，就拿出真本事吧！", lost: "……这样的对手，值得尊敬。"},
         {id: "flora", room: "hq", npc: 194, name: "弗洛拉", race: 1649, level: 100, x: 610, y: 430, boss: true,
            say: "可兰的体力可是很厚的哦！", lost: "可兰……我们输了。"},
         {id: "rabel", room: "hq", npc: 86, name: "拉贝尔", race: 323, level: 100, x: 470, y: 330, boss: true, need: ["landing", "flora"],
            say: "我是拉贝尔。你们打败了兰丁和弗洛拉，就让我和梅卡来做最后的了断吧！", lost: "……我们输了。奥拉人会撤出蚁族王朝。"}
      ];

      /**
       * The scene's own figures that do not fit the story: the 兵蚁 who stood guard at the gate
       * and under the searchlights are 奥拉 卫兵 now (the room's guard stands at one of the places,
       * these at the others, and run once it is beaten). by: the guard whose fall frees them.
       */
      private static const POSTED:Array = [
         {room: "ant1", at: "ant0", npc: 82, name: "卫兵汤姆", by: "nike", say: "尼克队长，有蚂蚁！"},
         {room: "ant1", at: "ant2", npc: 221, name: "蓝宝卫兵凯文", by: "nike", say: "这里是奥拉人的地盘了！"},
         {room: "ant2", at: "ant0", npc: 221, name: "蓝宝卫兵艾伦", by: "guard1", say: "探照灯，照那边！"},
         {room: "ant2", at: "ant2", npc: 28, name: "卫兵萨姆", by: "guard1", say: "别让它们靠近陷阱！"}
      ];

      /** What each creature says when it is free: what it can do. */
      private static const THANKS:Object = {
         "244": "咕噜！牛角滴滴是水属性，火属性的家伙最怕我们。我还会寄生种子，每回合吸走对手1/10的体力——不过它对木系无效哦！",
         "242": "呱！金刚蛤蟆也是水属性：火属性的攻击打在我身上只有一半威力，我打它们却是双倍！",
         "241": "毒菇鸠箭一次射出9支毒箭，让对手中毒，一回合一回合地掉血。对付会回血的对手最合适！",
         "243": "下水猛鳄重获自由！树界降临每回合回复我1/4体力，寄生种子吸取对手体力，生命海洋还能边打边回血。",
         "218": "我的巨刃破邪连续5回合攻击，一回合比一回合猛。机械属性专克冰属性，木属性的攻击对我只有一半威力！",
         "219": "我的真·噬魂能削弱对手的全部属性1级。对手用技能给自己加强？我来把它打回去！",
         "220": "我是电属性，水和飞行属性最怕电！闪电护盾让我受到的特殊攻击减半，催眠曲能让对手睡着。还有神秘仪式：牺牲我，让下一只出场的亚比满状态回复——兵蚁大哥受伤时就用它！",
         "221": "意念之盾让我方全体受到的普通攻击伤害减半，换亚比也有效！诱惑让对手特攻下降两级，恶魔遗言能牺牲我自己，削弱对手的攻击和特攻各两级。",
         "225": "我的秽土转生能回复全部体力，沙缚柩能束缚对手。土属性不怕火焰，打火属性的对手还是双倍！",
         "223": "烈焰焚天威力巨大，木属性的敌人最怕火！不过我体力越少威力越低，要趁满体力时出手。",
         "224": "闪电新星一回合能打好几次，每次都可能让对手麻痹！电属性克水属性。",
         "222": "冰雾海让对手无法替换亚比，每回合扣除它最大体力值的1/16；钻石星尘还能把对手冻住。冰属性克木属性！"
      };

      /** 工蚁's advice before the hardest fights, by guard. */
      private static const ADVICE:Object = {
         "mutant": ["变异蚁将军是木属性：兰斯罗特的火、贝德威尔的冰打它都是双倍！",
            "它的将军KICK是普通攻击，蚁族魔斗士的意念之盾能让伤害减半；将军雷霆破和将军震地波是特殊攻击，蚁族圣斗士的闪电护盾能挡住一半。"],
         "kid": ["小奥拉的初始亚比每次都不一样：古渊露龙是水和飞行属性，电属性打它是<font color='#FF6600'>四倍</font>！魔焰吉拉是火属性，用水属性的伙伴；终结兔是木属性，用火或冰。",
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
            "兵蚁大哥受伤了？让圣斗士或魔斗士用神秘仪式，下一只出场的兵蚁就能满状态回复！"]
      };

      private var game:IModGame;
      private var hud:TextField;
      /** The cages of the room shown, by the guard whose fall opens them: [Sprite, …]. */
      private var cages:Object = {};
      /** The radius of a cage round a captive drawn as its 亚比. */
      private static const CAGE_R:Number = 50;
      /** Where the guards of the room shown stand (each clear of the others). */
      private var guardBoxes:Array = [];
      /** The way on of the room shown (no guard stands in it). */
      private var doorBox:Rectangle;
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
         if (!game.getData("mode") || game.getData("over") || game.getData("done"))
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

      private function rescued():int
      {
         var n:int = 0;
         for each (var g:Object in GUARDS) if (g.captive && beaten(g.id)) n++;
         return n;
      }

      private function captives():int
      {
         var n:int = 0;
         for each (var g:Object in GUARDS) if (g.captive) n++;
         return n;
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
            build: function(room:IModRoom):void { buildRoom(r, room); }
         });
      }

      private function buildRoom(r:Object, room:IModRoom):void
      {
         if (game.getData("mode") && !game.getData("over") && !game.getData("done")) game.setData("room", r.id);
         addHud(room);
         // The way on: the scene's own door, open once the room's guards are beaten.
         var d:DisplayObject = r.door ? room.part(r.door) : null;
         if (d != null && r.next)
         {
            var b:Rectangle = d.getBounds(DisplayObject(room));
            room.door(b.x, b.y, Math.max(40, b.width), Math.max(40, b.height), "前进", function():void
            {
               if (!roomCleared(r.id)) worker("先打败这里的奥拉守卫！");
               else game.enter(r.next);
            }, false);
         }
         for each (var hn:String in r.hide || []) { var hp:DisplayObject = room.part(hn); if (hp) hp.visible = false; }
         cages = {};
         doorBox = d != null ? d.getBounds(DisplayObject(room)) : null;
         cageRects = {};
         cageFeet = {};
         guardBoxes = [];
         posted = {};
         captiveNpcs = {};
         var waiting:Array = [];
         for each (var g:Object in guardsOf(r.id))
         {
            var pg:Object = placeGuard(room, g);
            if (pg != null) waiting.push(pg);
         }
         for each (var w:Object in waiting) spawnGuard(room, w);
         for each (var p:Object in POSTED) if (p.room == r.id) placePosted(room, p);
         if (r.id == "ant1" && !game.getData("mode")) game.after(0.8, chooseMode);
         else if (r.id == "ant1" && !game.getData("intro")) game.after(0.8, intro);
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

      /** One of the 卫兵 who took the 兵蚁's places: at that place (the 兵蚁 there hidden) until the room's guard falls. */
      private function placePosted(room:IModRoom, p:Object):void
      {
         var b:Rectangle = boundsOf(room, p.at);
         var piece:DisplayObject = room.part(p.at);
         if (piece != null) piece.visible = false;
         if (beaten(p.by) || b == null) return;
         var npc:IModNpc = room.npc({name: p.name, look: "npc:" + p.npc, x: b.x + b.width / 2, y: b.bottom,
            onClick: function():void { npc.say(p.say, 3); }});
         (posted[p.by] ||= []).push(npc);
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
               onClick: function():void { worker("先打败看守它的" + g.name + "！"); }});
            var at:DisplayObject = DisplayObject(held);
            cageAt(room, g.id, at, new Point(at.x, at.y), CAGE_R, 118, "被俘的" + nameOf(g.captive));
            captiveNpcs[g.id] = held;
            x = at.x + side * 95;
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
            var best:Number = Number.MAX_VALUE;
            for (var cx:Number = R.left - 260; cx <= R.right + 260; cx += 8)
            {
               for (var cy:Number = R.top + 40; cy <= R.bottom + 150; cy += 8)
               {
                  var d:Number = (cx - px) * (cx - px) + (cy - py) * (cy - py);
                  if (d >= best || !standable(room, cx, cy)) continue;
                  best = d;
                  x = cx;
                  y = cy;
               }
            }
         }
         guardBoxes.push(new Rectangle(x - 40, y - 115, 80, 115));
         var npc:IModNpc = room.npc({
            name: g.name,
            look: g.look ? g.look : "npc:" + g.npc,
            x: x,
            y: y,
            scale: g.look ? 1.3 : 1,
            tip: "点击挑战",
            onClick: function():void { challenge(g, npc); }
         });
      }

      /** Whether a guard can stand at x, y: on the floor, in front of no cage, beside no other guard. */
      private function standable(room:IModRoom, x:Number, y:Number):Boolean
      {
         if (x < 40 || x > room.roomWidth - 40 || y < 130 || y > 500) return false;
         if (room.blocked(x, y) || room.blocked(x - 24, y) || room.blocked(x + 24, y)) return false;
         var box:Rectangle = new Rectangle(x - 40, y - 115, 80, 115);
         for each (var list:Array in cageRects)
            for each (var cr:Rectangle in list) if (box.intersects(new Rectangle(cr.x, cr.y, cr.width, cr.height + 18))) return false;
         for each (var other:Rectangle in guardBoxes) if (other.intersects(box)) return false;
         if (doorBox != null && box.intersects(new Rectangle(doorBox.x - 10, doorBox.y - 10, doorBox.width + 20, doorBox.height + 30))) return false;
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

      private function challenge(g:Object, npc:IModNpc):void
      {
         for each (var need:String in g.need || [])
         {
            if (!beaten(need))
            {
               npc.talk(["想挑战我？先打败兰丁和弗洛拉吧。"]);
               return;
            }
         }
         var ask:Function = function():void
         {
            npc.talk([g.say, {text: "要和" + g.name + "战斗吗？", choices: [
               ["战斗！", function():void { fight(g, npc); }],
               ["先准备一下", null]
            ]}]);
         };
         // Before the hardest fights: 工蚁's advice the first time (and from 提示).
         var tips:Array = ADVICE[g.id] as Array;
         var seen:Object = game.getData("advised") || {};
         if (tips != null && !seen[g.id])
         {
            seen[g.id] = true;
            game.setData("advised", seen);
            game.talk({name: "工蚁", picture: WORKER}, ["等一下！" + tips[0]].concat(tips.slice(1)), ask);
            return;
         }
         ask();
      }

      private function fight(g:Object, npc:IModNpc):void
      {
         var m:Object = mode;
         var pct:int = g.boss ? m.boss : m.foe;
         var race:int = g.race is Array ? g.race[int(Math.random() * g.race.length)] : int(g.race);
         var foe:Object = {race: race, level: g.boss ? g.level : Math.min(100, g.level + int(m.lv)), hp: g.boss ? m.bossHp : pct, at: pct, de: pct, sa: pct, sd: pct, sp: pct};
         game.fight([foe], function(win:Boolean):void
         {
            game.partyState(function(st:Object):void { afterFight(g, npc, win, st); });
         }, false);
      }

      private function afterFight(g:Object, npc:IModNpc, win:Boolean, st:Object):void
      {
         var keep:Object = null;
         for each (var p:Object in st.pets || []) if (p.keep) keep = p;
         if (!win)
         {
            if (keep == null || int(keep.hp) <= 0) gameOver();
            else worker("暂时撤退了。用高级体力糖给亚比恢复体力（亚比背包 → 道具），再来挑战吧！");
            return;
         }
         markBeaten(g.id);
         if (npc != null) npc.remove();
         var room0:IModRoom = game.currentRoom;
         for each (var c:Sprite in cages[g.id] || []) if (room0) room0.remove(c);
         delete cages[g.id];
         for each (var pq:IModNpc in posted[g.id] || []) pq.remove();
         delete posted[g.id];
         var m:Object = mode;
         var candy:int = m.winCandy + (g.boss ? m.bossCandy : 0);
         game.giveItem(CANDY, candy);
         game.giveItem(BEAN, m.winBean);
         var got:String = "获得了高级体力糖×" + candy + "、高级活力豆×" + m.winBean + "！";
         var room:IModRoom = game.currentRoom;
         if (g.captive)
         {
            game.givePet(g.captive, 100);
            game.talk({name: nameOf(g.captive), picture: "pet:" + g.captive}, [g.lost ? "<font color='#3366CC'>" + g.name + "：</font>" + g.lost : got,
               THANKS[String(g.captive)] || "谢谢你们！",
               "<font color='#FF6600'>" + nameOf(g.captive) + "（Lv100）加入了队伍！</font>" + got], function():void { afterWin(g); });
            return;
         }
         if (g.gift)
         {
            game.givePet(g.gift, 100);
            game.talk({name: nameOf(g.gift), picture: "npc:160"}, [g.lost,
               "我……终于清醒了。谢谢你们，蚁族的勇士。奥拉人的实验让我失去了理智……",
               "带上我吧！我们一起去奥拉星，让奥拉人永远离开蚁族王朝！",
               "<font color='#FF6600'>蚁将军（Lv100）加入了队伍！</font>" + got], function():void { afterWin(g); });
            return;
         }
         game.talk({name: g.name, picture: "npc:" + g.npc}, [g.lost, got], function():void { afterWin(g); });
      }

      private function afterWin(g:Object):void
      {
         refreshHud();
         // The freed one has joined: its figure leaves the room.
         var here:IModRoom = game.currentRoom;
         for each (var a:String in g.art || []) { var d:DisplayObject = here ? here.part(a) : null; if (d) d.visible = false; }
         if (captiveNpcs[g.id]) { IModNpc(captiveNpcs[g.id]).remove(); delete captiveNpcs[g.id]; }
         if (g.id == "mutant")
         {
            game.talk({name: "工蚁", picture: WORKER}, ["蚁族王朝夺回来了！可是奥拉人还会回来的……",
               "兵蚁大哥，我们穿过传送核心，直接去奥拉星的指挥中心，让他们签下停战协议吧！"], function():void { game.enter("core"); });
         }
         else if (g.id == "kid")
         {
            game.talk({name: "工蚁", picture: WORKER}, ["前面就是指挥中心了！兰丁、弗洛拉和拉贝尔都在那里。"], function():void { game.enter("hq"); });
         }
         else if (g.id == "rabel") ending();
         else if (game.currentRoom != null && roomCleared(game.currentRoom.id) && g.room != "hq")
         {
            worker("这里的奥拉守卫都被打败了，前进吧！");
         }
      }

      // ---------------------------------------------------------------- story

      private function chooseMode():void
      {
         var pick:Function = function(id:String):Function
         {
            return function():void
            {
               game.setData("mode", id);
               game.setData("beaten", {});
               game.setData("over", undefined);
               game.setData("done", undefined);
               game.setData("intro", undefined);
               game.setData("room", "ant1");
               game.party(partyDef(true), function(st:Object):void
               {
                  if (st == null) { worker("队伍没能组建起来。"); return; }
                  refreshHud();
                  intro();
               });
            };
         };
         game.talk({name: "工蚁", picture: WORKER}, [
            "兵蚁大哥，你还记得吗？奥拉人闯进了蚁族王朝，俘虏了蚁将军，用奇怪的实验把他变成了<font color='#FF6600'>变异蚁将军</font>，还把蚁族的勇士们一个个关了起来。",
            "现在，奥拉人正在和达斯特人打仗，大部分兵力都调走了，驻守蚁族王朝的守军十分空虚——这是我们反击的好机会！",
            {text: "选择难度：", choices: [
               ["简单：体力糖充足，对手较弱", pick("easy")],
               ["普通：要用好每一位伙伴的技能", pick("normal")],
               ["困难：对手更强，体力糖很少", pick("hard")]
            ]}
         ]);
      }

      private function intro():void
      {
         game.setData("intro", true);
         game.talk({name: "工蚁", picture: WORKER}, [
            "兵蚁大哥，我是工蚁，从今天起和你一起战斗！",
            "我在战场上缴获了一台奥拉人的HELLO，可它的治疗模块被锁住了，只能用<font color='#FF6600'>高级体力糖</font>给亚比恢复体力，用<font color='#FF6600'>高级活力豆</font>恢复技能次数。打赢一场，就能找到更多。",
            "奥拉守卫关押着蚁族王朝的伙伴们。打败守卫，伙伴就会加入我们（都是Lv100）！注意它们的属性：水克火、火克木、电克水、冰克木、土克火……",
            "最重要的是：<font color='#FF0000'>你是蚁族的希望，千万不能倒下！你一倒下，反击就失败了。</font>你也不能离开亚比背包哦。",
            "先打败门口的卫兵尼克，然后前进！"
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
            "兵蚁，你和你的伙伴们赢了。奥拉人会遵守约定，撤出蚁族王朝，把蚁将军的部下全部放回去。",
            "也许……我们本该从一开始就做朋友，而不是敌人。"
         ], function():void
         {
            game.talk({name: "工蚁", picture: WORKER}, [
               "兵蚁大哥，我们终于夺回了自己的家园！听说大家要把我们的名字，刻在蚁神巨像的脚下呢……",
               {text: "<font color='#FF6600'>通关！（难度：" + m.name + "，救出的伙伴：" + rescued() + "/" + captives() + "）</font>", choices: [
                  ["再玩一次", function():void { restart(); }],
                  ["离开", function():void { game.endParty(); game.leave(); }]
               ]}
            ]);
         });
      }

      private function restart():void
      {
         game.setData("mode", undefined);
         game.setData("over", undefined);
         game.setData("done", undefined);
         game.setData("beaten", {});
         if (game.currentRoom != null && game.currentRoom.id == "ant1") chooseMode();
         else game.enter("ant1");
      }

      // ---------------------------------------------------------------- the strip at the top right

      private function addHud(room:IModRoom):void
      {
         var box:Sprite = new Sprite();
         box.graphics.beginFill(0x0B2440, 0.65);
         box.graphics.drawRoundRect(0, 0, 250, 40, 14, 14);
         box.graphics.endFill();
         hud = new TextField();
         hud.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF, true);
         hud.width = 170;
         hud.height = 36;
         hud.x = 8;
         hud.y = 3;
         hud.mouseEnabled = false;
         hud.filters = [new GlowFilter(0x0B2440, 1, 2, 2, 4)];
         box.addChild(hud);
         var help:Sprite = new Sprite();
         help.graphics.beginFill(0xFFB400);
         help.graphics.drawRoundRect(0, 0, 56, 26, 10, 10);
         help.graphics.endFill();
         var ht:TextField = new TextField();
         ht.defaultTextFormat = new TextFormat("_sans", 13, 0x5A2A00, true);
         ht.text = "提示";
         ht.width = 56;
         ht.height = 22;
         ht.x = 14;
         ht.y = 3;
         ht.mouseEnabled = false;
         help.addChild(ht);
         help.buttonMode = true;
         help.x = 186;
         help.y = 7;
         help.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { hint(); });
         box.addChild(help);
         room.add(box, 660, 8, "screen");
         refreshHud();
      }

      private function refreshHud():void
      {
         if (hud == null || game == null) return;
         var m:Object = game.getData("mode") ? mode : null;
         hud.text = (m ? "难度：" + m.name : "蚁族的反击") + "\n救出的伙伴：" + rescued() + "/" + captives();
      }

      private function hint():void
      {
         var r:IModRoom = game.currentRoom;
         var left:Array = r ? guardsOf(r.id).filter(function(g:Object, i:int, a:Array):Boolean { return !beaten(g.id); }) : [];
         var pages:Array = [];
         if (left.length > 0)
         {
            var names:Array = left.map(function(g:Object, i:int, a:Array):String { return g.name; });
            pages.push("这里还有奥拉守卫：" + names.join("、") + "。点击他们就能挑战。");
         }
         else pages.push("这里已经没有守卫了，从出口前进吧！");
         for each (var g2:Object in left) if (ADVICE[g2.id]) pages = pages.concat(ADVICE[g2.id]);
         pages.push("体力不够时，打开亚比背包的「道具」，用高级体力糖；技能用完了就用高级活力豆。打不过可以逃跑，回复好再来。");
         pages.push("记住属性相克：水克火、火克木、电克水和飞行、冰克木、土克火、机械克冰。被克的属性打过来只有一半威力，还有的招式对某些属性完全无效，比如寄生种子对木系无效。");
         game.talk({name: "工蚁", picture: WORKER}, pages);
      }
   }
}
