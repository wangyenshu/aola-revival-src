package mmo.dailyactivity
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.DailyActivity.BossTimeHelper;
   import mmo.interfaces.DailyActivity.IDailyActivity;
   import mmo.interfaces.arrowguide.ArrowType;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.revival.RLog;

   /**
    * REBUILT dailyactivity/dailyactivityservice: the 守护者, the bosses of the
    * areas. The January 2013 module is lost; this follows the later one
    * (livesrc dailyactivity, BossConfig and its interactions) on the 2013
    * engine. Each boss stands in its scene as its own picture,
    * dailyactivity/dailyboss<race> (taken from the CDN: most are the files of
    * 2011–12), and plays as it did: the sleeping ones (frame 1 with a
    * wakeUpMovie) wake up at the first click and stand ready (frame 2); 神武月,
    * 战无炎, 暴雪山神 and 神罗麦提 play their film first. Then the boss talks
    * (its conversations of the later task/tasknpc, FreeTalkData): with no
    * 亚比 of level 60 the HELLO warns first; 挑战 (gotofight…) fights its form
    * (IPetFight.fightWithBoss, PetExtension 54_16); a win leads to the next
    * form and its talk, the last form's win to its farewell, a loss back to
    * the first. A win brings the 亚比蛋 of the boss's line (the server).
    *
    * The bosses of BossTimeHelper.bossTimeConfig (2013 interfaces), with
    * 天使莱特, 山脉之魂 and 终极麦斗王 in their scenes of the later config,
    * and those the 2013 world had beside it: 伊泽 and 迦娜 (mysticocean5),
    * 烈焰鸟 (feier4), 神武月 and 战无炎 (choicetemple), whose levels are
    * RECONSTRUCTED. Where a picture is lost, the boss stands dressed as its
    * 亚比 (BossAvatar).
    */
   public class DailyActivityService extends EventDispatcher implements IDailyActivity
   {
      /**
       * scene, name, file (dailyactivity/dailyboss<file>), class, x, y, kind (wake, still, film, book, panel, ask,
       * stone, wand), film class (for panel and stone: "file|class" of the panel), npc, talk key, talk set (std,
       * team, pig, feier, start, one), forms "race:level,…".
       */
      private static const BOSSES:Array = [
         // 冰拳艾司 on the snowy stone stand before the 冰晶 shrine, at the later BossConfig's spot for its
         // "iceboss" (370, 170; behind the crystals at the arrow guide's point it was hidden).
         ["aixiscene6", "冰拳艾司", 20087, "IceBoss", 370, 170, "wake", null, 64, "iceboss", "std", "20087:80"],
         ["amusementpark", "星光角斗士", 20427, "Boss10427", 0, 0, "wake", null, 324, "boss10427", "std", "20427:60"],
         ["suolide5", "沙麒麟", 10090, "SandBoss", 0, 0, "wake", null, 65, "sandboss", "std", "10090:60,20090:80"],
         ["siwude3", "木面侠", 10093, "TreeBoss", 0, 0, "wake", null, 76, "treeboss", "std", "10093:60,20093:80"],
         ["giantcordillera1", "山脉之魂", 20418, "Boss20418", 0, 0, "wake", null, 317, "boss20418", "std", "20418:100"],
         ["feier2", "火花龙", 10099, "FireBoss", 0, 0, "wake", null, 103, "fireboss", "std", "10099:60,20099:80"],
         ["bite2", "合金猛将", 10102, "BiteBoss", 0, 0, "wake", null, 111, "biteboss", "std", "10102:60,10102:80,20102:100"],
         ["woerte4", "金刚库巴", 10096, "WaterBoss", 0, 0, "wake", null, 87, "waterboss", "std", "10096:60,10096:80,20096:100"],
         ["haiwen2", "利刺大黄蜂", 10108, "HaiwenBoss", 0, 0, "wake", null, 169, "haiwenboss", "std", "10108:60,10108:80,20108:100"],
         ["diamondisland4", "天使莱特", 10317, "Boss10317", 0, 0, "wake", null, 374, "boss10317", "std", "10317:80,20317:100"],
         ["leiming4", "雷纳瑞", 10469, "Boss10469", 690, 184, "still", null, 224, "leiming4Teamboss", "team", "10469:100"],
         ["leiming4", "魂斗鱼", 10472, "Boss10472", 273, 175, "still", null, 223, "leiming4Teamboss", "team", "10472:100"],
         ["yishuzhidu1", "浮云尊者", 104751, "Boss104751", 285, 295, "still", null, 399, "yishuzhidu1Teamboss", "team", "10475:100"],
         ["yishuzhidu1", "浮云尊者", 104752, "Boss104752", 569, 298, "still", null, 399, "yishuzhidu1Teamboss", "team", "20475:100"],
         ["fairytalestar1", "童心", 30682, "Boss10682", 0, 0, "book", null, 462, "themepark30682", "std", "30682:88,10682:100"],
         ["haikustar2", "神龟", 10715, "Boss10715", 0, 0, "still", null, 513, "boss10715", "std", "10715:80,20715:100"],
         ["fightspace2", "终极麦斗王", 14523, "BossInteraction.PigBoss", 187, 272, "still", null, 278, "courageDoorBoss", "pig", "14523:100,11514:80,11516:80"],
         ["bingxuestar4", "暴雪山神", 10757, "Boss10757", 0, 0, "wand", "BossMovie10757", 538, "boss10757", "std", "10757:80,20757:100"],
         ["yakestar4", "神罗麦提", 10840, "Boss10840", 0, 0, "film", "Boss10840Movie", 589, "boss12702", "std", "10840:80,20840:100"],
         ["candystar3", "超T兔", 10865, "Boss10865", 0, 0, "still", null, 613, "boss12731", "std", "10865:80,20865:100"],
         ["cloudstar4", "岩波斗魂者", 11213, "StoneBoss", 0, 0, "stone", "dailyactivity/stonebosspanel|mmo.stoneboss.StoneBossPanel", 786, null, "one", "11213:60,21213:80,31213:100"],
         ["mysticocean5", "伊泽和迦娜", 11320, "Boss11320", 0, 0, "still", null, 842, "hello_before_OceanBoss", "one", "11320:100,11322:100"],
         ["feier4", "烈焰鸟", 30278, "Feier4boss", 640, 454, "wake", null, 80, "feier4boss", "feier", "30278:80"],
         // 神武月 gives "一次机会" to become a partner (boss10105: a win boss10105100, a loss boss10105win).
         // The 满月 神武月 (20105, the later BossConfig's StartBoss, dailyboss20105) is left out: its talks
         // (startboss…) make it the guardian of 哈米乐园, a later place, and standing beside the first it
         // put two 神武月 in the hall.
         ["choicetemple", "神武月", 10105, "Boss10105", 0, 0, "film", "BossInteraction.BossMovie10105", 127, "boss10105", "start", "10105:80"],
         ["choicetemple", "战无炎", 10111, "Boss10111", 0, 0, "film", "BossInteraction.BossMovie10111", 303, "boss10111", "start", "10111:90"],
         // The bosses of the 2011–12 events: where their events put them (the 奥拉周刊 pages of their
         // weeks, whose GO buttons name the scene, and 百田's guides).
         // 友人契约书 (mysticearth2, from October 2012) was still there in January 2013; the others
         // came back in 2013 only through 绝版乐园's panel. 主题公园 was the 守护者's stage of 2011–12:
         // 极速威锋 (奥运守护者, September 2011), 满月巨灵 (中秋, September 2011), 天之巨灵 (天王星守护者,
         // October 2011), 赤影飞狐 (新年, December 2011), 赤魔导士 (新春, January 2012), 天女若希
         // (Valentine 2012), 猪猪超人 (March 2012), 翡冷翠 (端午 2012); they were never there all at
         // once, and stand apart where one can walk (the scene's obstruction): on the sun stage, and
         // 极速威锋, 翡冷翠 on the star platform, none before another (RECONSTRUCTED spots).
         ["mysticearth2", "友人契约书", 11259, "Boss11259", 0, 0, "panel", "activityres/activity121018/friendcontract|mmo.activity121018.friendcontract.FriendContractPanel", 821, null, "one", "11259:100"],
         ["themepark", "猪猪超人", 10884, "Boss10884", 854, 293, "still", null, 635, "boss10886", "one", "10884:100"],
         ["themepark", "满月巨灵", 10639, "Boss10639", 297, 316, "film", "BossMovie10639", 435, "themeparkMoonboss", "std", "10639:100"],
         ["themepark", "赤魔导士", 10796, "Boss10796", 0, 0, "still", null, 563, "boss10796", "std", "10796:80,20796:100"],
         ["themepark", "赤影飞狐", 10771, "Boss10771", 0, 0, "film", "BossMovie10771", 546, "boss10771", "std", "10771:80,20771:100"],
         ["themepark", "极速威锋", 10633, "Boss10633", 0, 0, "film", "BossMovie10633", 433, "themeparkTeamboss", "team", "10633:100"],
         ["themepark", "天之巨灵", 10665, "Boss10665", 730, 145, "film", "BossMovie10665", 460, "themepark10665", "std", "10665:100"],
         ["themepark", "天女若希", 10819, "Boss10819", 0, 0, "still", null, 586, "boss12619", "std", "10819:80,20819:100"],
         // 翡冷翠 (端午 2012, fought at the top of the 粽子塔 entered from 主题公园; its picture and
         // talks are lost): in the park, dressed as its 亚比 (RECONSTRUCTED).
         ["themepark", "翡冷翠", 10995, "Boss10995", 162, 418, "ask", null, 0, null, "one", "10995:100"],
         ["dreamhouse", "年兽", 10493, "Boss10493", 480, 320, "film", "BossMovie10493", 242, "dreamhouseTeamboss", "std", "10493:100"],
         // 多古拉伯爵, the 万圣节守护者 of 2012: its card of the 守护者 calendar (dailyactivitybossres/boss1266,
         // 24 October 2012) names 挑战地点 奥拉之树, 10月26日—11月1日. Its picture in the scene is lost: it
         // stands dressed as its 亚比; forms and levels RECONSTRUCTED (its boss rows 11267 and 21267).
         ["aolatree", "多古拉伯爵", 11267, "Boss11267", 700, 350, "ask", null, 0, null, "one", "11267:80,21267:100"],
         // 猎空, the 守护者 of 银河冠军擂台 from August 2013 (later than this world: asked for by its
         // players). The later BossTimeHelper fights its three forms 31697, 21697, 11697 at 60, 80, 100
         // in spacetimechallenge, whose 2013 scene is lost (the 战斗星域 stand-in, BattleZoneHub): it
         // stands in 挑战平台 instead, as its picture dailyactivity/dailyboss31697 (the tornado).
         ["spacetimechallenge3", "猎空", 31697, "Boss31697", 0, 0, "ask", null, 0, null, "one", "31697:60,21697:80,11697:100"],
         // 时间之神, the 时间守护者 of the 泡泡节 (缤纷泡泡街, from 27 May 2011): the clock of the
         // street's fountain is turned to call it (its film, the same clock, plays over the street's);
         // then it stands by the clock (spot RECONSTRUCTED).
         ["hubblebubblestreet1", "时间之神", 10112, "Boss10112", 410, 200, "clock", "Boss10112Movie", 342, "boss10112", "std", "10112:80,20112:100"],
         ["hell", "影刃", 10195, "ShadowBoss", 741, 248, "still", null, 156, "shadowboss", "std", "10195:80,20195:100"],
         ["hell", "鬼王", 11190, "Boss11190", 254, 238, "ask", null, 0, null, "one", "11190:100"],
         // 蓝羽灵者, the 守护者 of 迷境花园 from 11 January 2013 (dailyboss31394 of 10 January 2013,
         // with its GardenPanel): the first click wakes it, then a click opens its panel, whose 挑战
         // fights its three forms (the later GardenInteraction); levels RECONSTRUCTED.
         ["whitenight1", "蓝羽灵者", 31394, "Boss31394", 757, 456, "garden", "dailyactivity/dailyboss31394|mmo.dailyactivity.GardenPanel", 882, "boss", "garden", "31394:60,21394:80,11394:100"]
      ];

      /**
       * Pictures drawn in scene coordinates moved aside where bosses of different
       * events now stand together: in 主题公园 onto ground one can walk, apart (极速威锋 stood
       * where 赤魔导士 stands; 赤魔导士 and 赤影飞狐 off the stage's front, over the water);
       * 猎空's (drawn for spacetimechallenge) off 挑战平台's middle.
       */
      private static const SHIFTED:Object = {"10633": [-495, 37], "31697": [110, -30], "10796": [0, -102], "10771": [2, -131], "10819": [-10, -1]};

      /** Bosses whose picture dailyactivity/dailyboss<file> is lost (they stand dressed as their 亚比): not asked for. */
      private static const NO_PICTURE:Object = {"10884": true, "11190": true, "10995": true, "11267": true};

      private var shown:Array = [];
      /** The boss last clicked: the talks' 挑战 fight it. */
      private var active:Object;
      private var fighting:Boolean;

      public function DailyActivityService()
      {
         super();
      }

      public function init():void
      {
         var sm:SceneManager = SceneManager.getInstance();
         sm.addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
         sm.addEventListener(SceneManagerEvent.UNLOAD_SCENE, onUnload);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, onAction);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onFightEnd);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
         if (sm.loadedSceneInfo != null) onSceneInited(null);
      }

      public function getPetStates(param1:int):Boolean
      {
         return false;
      }

      /** The bosses of a scene, each {scene, name, file, cls, x, y, kind, film, npc, talk, set, forms: [{race, level, index}], form}. */
      public static function bossesOf(sceneName:String):Array
      {
         var out:Array = [];
         for each (var r:Array in BOSSES)
         {
            if (r[0] != sceneName) continue;
            var forms:Array = [];
            var parts:Array = String(r[11]).split(",");
            for (var k:int = 0; k < parts.length; k++)
            {
               var f:Array = String(parts[k]).split(":");
               forms.push({race: int(f[0]), level: int(f[1]), index: k});
            }
            out.push({scene: r[0], name: r[1], file: r[2], cls: r[3], x: r[4], y: r[5], kind: r[6], film: r[7], npc: r[8], talk: r[9], talks: r[10],
               forms: forms, form: 0, awake: false, filmed: false, part: out.length});
         }
         return out;
      }

      private function onSceneInited(e:SceneManagerEvent):void
      {
         clear();
         var info:* = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null || info.inHouse) return;
         try
         {
            PlanetMenus.onScene(String(info.sceneName));
            DaHeiHeiSummon.onScene(String(info.sceneName), info.scene);
         }
         catch (pe:Error) { RLog.error("planet activities", pe); }
         for each (var b:Object in bossesOf(String(info.sceneName)))
         {
            // The book of 黑夜童心 lies on the table: the boss's picture (the same book, which
            // opens and lets 童心 out) goes over the scene, as the later module put it
            // (foreGround). The scene's own book stays where it is under it, so the book is
            // still on the table once the picture's has opened and gone (the later module
            // moved it away, and the book vanished with the film); a click on it talks to 童心.
            if (b.kind == "book")
            {
               keepSceneItem(b, info.scene.container);
               place(b, info.scene.foreGround);
            }
            // 暴雪山神 (Boss10757Strategy of the later module): the scene's own totem in its
            // foreground (bossitem, a button that does nothing, with the bubble 圣诞守护者——山神大人来啦！)
            // makes way for the boss's picture, the same totem with its wand, over the scene.
            else if (b.kind == "wand")
            {
               hideSceneItem(b, info.scene.foreGround);
               if (b.item == null) hideSceneItem(b, info.scene);
               place(b, info.scene.foreGround);
            }
            else
            {
               place(b, info.scene.container);
               // 时间之神: the street's clock (eess, the fountain's) calls it.
               if (b.kind == "clock") keepSceneItem(b, info.scene, "eess");
            }
         }
      }

      private function place(b:Object, into:Sprite):void
      {
         var cls:String = "mmo.dailyactivity." + b.cls;
         var put:Function = function(... a):void
         {
            var view:Sprite = null;
            try
            {
               if (ApplicationDomain.currentDomain.hasDefinition(cls))
               {
                  var C:Class = getDefinitionByName(cls) as Class;
                  view = new C() as Sprite;
               }
            }
            catch (err:Error) { RLog.error("guardian " + b.name, err); }
            if (view == null)
            {
               // The picture is lost: the boss dressed as its 亚比.
               view = new BossAvatar(b, int(b.forms[0].race) % 10000, null);
               view.x = int(b.x) != 0 ? int(b.x) : 480;
               view.y = int(b.y) != 0 ? int(b.y) : 300;
            }
            else
            {
               var at:Point = whereOf(b, view);
               view.x = at.x;
               view.y = at.y;
               // 岩波斗魂者 (StoneBoss) waits on its first frame: left playing, it ran its
               // awakening (frame 2, mc) and frame 3 over and over and kept shining.
               if (view is MovieClip && (b.kind == "wake" || b.kind == "panel" || b.kind == "stone" || b.kind == "garden")) MovieClip(view).gotoAndStop(1);
               // 伊泽和迦娜 (two frames: a glowing button, then the two standing): left playing it
               // flickered between them, and a click in the button's frame found nothing under 迦娜.
               if (view is MovieClip && b.cls == "Boss11320") MovieClip(view).gotoAndStop(MovieClip(view).totalFrames);
               // 时间之神 comes when the clock is turned.
               if (b.kind == "clock" && !b.filmed) view.visible = false;
               // 暴雪山神's totem loops its wand until the film has played (its last frame: the 山神 standing).
               if (view is MovieClip && b.kind == "wand" && MovieClip(view).totalFrames > 2)
               {
                  var loop:MovieClip = MovieClip(view);
                  loop.addFrameScript(loop.totalFrames - 2, function():void { if (!b.filmed) loop.gotoAndPlay(1); });
                  loop.gotoAndPlay(1);
               }
               // 黑夜童心's book: the picture's own dark mark under its opening book (beside mcbook.mc)
               // is left out, so the scene's book shows on the table once the picture's has opened.
               if (b.kind == "book")
               {
                  try
                  {
                     var mb:Sprite = Object(view).mcbook as Sprite;
                     for (var bi:int = 0; mb != null && bi < mb.numChildren; bi++) if (mb.getChildAt(bi).name != "mc") mb.getChildAt(bi).visible = false;
                  }
                  catch (e4:Error) {}
               }
               // 天女若希 (the 2016 picture): awake, without its sleeping part.
               if (b.cls == "Boss10819")
               {
                  try { MovieClip(Object(view).mc).gotoAndStop(2); Object(view).p.visible = false; } catch (e3:Error) {}
               }
            }
            view.name = "guardian_" + b.part;
            view.buttonMode = true;
            b.view = view;
            try { TipsManager.getInstance().addTips(view, "守护者 " + b.name); } catch (e2:Error) {}
            into.addChild(view);
            shown.push(b);
            ClickAndHitHelper.instance.registerTarget(view, true, 120);
            view.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, function(ev:ClickAndHitEvent):void { clicked(b); });
            RLog.log("guardian: " + b.name + " in " + b.scene);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls) || NO_PICTURE[b.file]) put();
         else ResScheduler.getResource("dailyactivity/dailyboss" + b.file, put, "", function(e:* = null):void
         {
            RLog.log("guardian: no picture dailyboss" + b.file);
            put();
         });
      }

      /**
       * Where a boss picture goes. Most are drawn in scene coordinates (天使莱特
       * stands at 784, 215 inside its file) and go at 0, 0; others are drawn
       * round their own middle (合金猛将): those stand at the given point, or
       * where the era arrow guide points at the boss (BossTimeHelper.points).
       * A sleeping boss is judged by its awake picture (frame 2).
       */
      private static function whereOf(b:Object, view:Sprite):Point
      {
         var mc:MovieClip = view as MovieClip;
         if (mc != null && b.kind == "wake" && mc.totalFrames > 1) mc.gotoAndStop(2);
         var r:Rectangle = view.getBounds(view);
         if (mc != null && b.kind == "wake") mc.gotoAndStop(1);
         var cx:Number = r.x + r.width / 2, cy:Number = r.y + r.height / 2;
         if (Math.abs(cx) > 220 || Math.abs(cy) > 220)
         {
            var sh:Array = SHIFTED[String(b.file)] as Array;
            return sh != null ? new Point(sh[0], sh[1]) : new Point(0, 0);
         }
         if (int(b.x) != 0 || int(b.y) != 0) return new Point(int(b.x), int(b.y));
         var pts:Array = BossTimeHelper.points[b.scene] as Array;
         if (pts == null || pts.length == 0) return new Point(480, 320);
         var pt:Object = pts[Math.min(int(b.part), pts.length - 1)];
         var d:int = int(pt.d);
         return new Point(int(pt.x) + (d == ArrowType.ARROW_LEFT ? -70 : d == ArrowType.ARROW_RIGHT ? 70 : 0),
            int(pt.y) + (d == ArrowType.ARROW_DOWN ? 110 : d == ArrowType.ARROW_UP ? -30 : 60));
      }

      /**
       * 黑夜童心: the scene's own book on the table (bossitem, a button that did
       * nothing) stays and answers a click as the boss does (the boss's picture
       * over it opens its book, mcbook.mc, and 童心 comes out; then it talks).
       */
      private function keepSceneItem(b:Object, into:DisplayObjectContainer, name:String = "bossitem"):void
      {
         var item:InteractiveObject = findNamed(into, name, 3) as InteractiveObject;
         if (item == null) return;
         b.kept = item;
         ClickAndHitHelper.instance.registerTarget(item, true, 120);
         item.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, function(ev:ClickAndHitEvent):void { clicked(b); });
      }

      /**
       * 暴雪山神 (Boss10757Strategy of the later module): the scene's own totem
       * (bossitem, a button that does nothing) is moved out of the way and the
       * boss's picture, the same totem with its wand, stands in its place.
       */
      private static function hideSceneItem(b:Object, into:DisplayObjectContainer):void
      {
         var item:DisplayObject = findNamed(into, "bossitem", 3);
         if (item == null) return;
         item.y -= 2000000;
         b.item = item;
      }

      /** The first display object of that name in `into`, looking `depth` levels down. */
      private static function findNamed(into:DisplayObjectContainer, name:String, depth:int):DisplayObject
      {
         if (into == null) return null;
         var hit:DisplayObject = into.getChildByName(name);
         if (hit != null || depth <= 0) return hit;
         for (var i:int = 0; i < into.numChildren; i++)
         {
            hit = findNamed(into.getChildAt(i) as DisplayObjectContainer, name, depth - 1);
            if (hit != null) return hit;
         }
         return null;
      }

      private function onUnload(e:SceneManagerEvent):void
      {
         DaHeiHeiSummon.clear();
         clear();
      }

      private function clear():void
      {
         for each (var b:Object in shown)
         {
            try
            {
               var v:Sprite = b.view as Sprite;
               if (v == null) continue;
               ClickAndHitHelper.instance.remove(v);
               if (v.parent) v.parent.removeChild(v);
               if (v is BossAvatar) BossAvatar(v).dispose();
               if (b.item != null) DisplayObject(b.item).y += 2000000;
               if (b.kept != null) ClickAndHitHelper.instance.remove(b.kept);
            }
            catch (e:Error) {}
         }
         shown = [];
         if (!fighting) active = null;
         SocketClient.instance.removeEventListener("2303", onBattleJoined);
         panelShown = null;
      }

      // ---------------------------------------------------------------- click: wake up, film, talk

      private function clicked(b:Object):void
      {
         active = b;
         var view:MovieClip = b.view as MovieClip;
         if (b.kind == "wake" && !b.awake && view != null)
         {
            var wake:MovieClip = view.getChildByName("wakeUpMovie") as MovieClip;
            b.awake = true;
            if (wake != null && wake.totalFrames > 1)
            {
               wake.addFrameScript(wake.totalFrames - 1, function():void
               {
                  wake.stop();
                  view.gotoAndStop(2);
               });
               wake.gotoAndPlay(2);
               return;
            }
            view.gotoAndStop(2);
            return;
         }
         if (b.kind == "panel")
         {
            // 友人契约书: the first click plays its own animation, then its panel opens (as the
            // later BossInteraction did); the panel's 开始挑战 fights it (fightWithBoss).
            if (b.playing) return;
            if (!b.awake && view != null && view.totalFrames > 1)
            {
               b.awake = true;
               b.playing = true;
               view.addFrameScript(view.totalFrames - 1, function():void
               {
                  view.stop();
                  b.playing = false;
                  openPanel(b);
               });
               view.gotoAndPlay(2);
               return;
            }
            openPanel(b);
            return;
         }
         if (b.kind == "stone" && view != null)
         {
            // 岩波斗魂者 (StoneBossInteraction of the later module): the first click wakes it
            // (frame 2: its mc plays once), then it stands awake (frame 3) and a click opens
            // its panel (dailyactivity/stonebosspanel), whose 挑战 fights its three forms.
            if (view.currentFrame < 3)
            {
               if (view.currentFrame == 2) return;
               view.mouseEnabled = view.mouseChildren = false;
               var awake:Function = function():void
               {
                  view.mouseEnabled = view.mouseChildren = true;
                  view.gotoAndStop(3);
               };
               view.addFrameScript(1, function():void
               {
                  view.addFrameScript(1, null);
                  var mc:MovieClip = view.getChildByName("mc") as MovieClip;
                  if (mc == null || mc.totalFrames < 2) { awake(); return; }
                  mc.addFrameScript(mc.totalFrames - 1, function():void { mc.stop(); awake(); });
                  mc.gotoAndPlay(1);
               });
               view.gotoAndStop(2);
               return;
            }
            openPanel(b);
            return;
         }
         if (b.kind == "clock" && !b.filmed)
         {
            // 时间之神 (the 泡泡节's 时间守护者): the clock is turned (its film, the clock with its
            // hands spinning, over the street's own, which is hidden meanwhile), then it stands there.
            b.filmed = true;
            var clock:DisplayObject = b.kept as DisplayObject;
            if (clock != null) clock.visible = false;
            playFilm(b, function():void
            {
               if (clock != null) clock.visible = true;
               if (b.view != null) DisplayObject(b.view).visible = true;
               talk(b);
            });
            return;
         }
         if (b.kind == "garden" && view != null)
         {
            // 蓝羽灵者 (GardenInteraction): the first click wakes it (frame 2, whose clip ends on
            // frame 3, awake); then a click opens its panel.
            if (view.currentFrame < 3)
            {
               if (view.currentFrame == 1) view.gotoAndStop(2);
               return;
            }
            openPanel(b);
            return;
         }
         if (b.kind == "wand" && !b.filmed && view != null)
         {
            // 暴雪山神 (Boss10757Strategy): the totem's wand calls the film (BossMovie10757);
            // after it the 山神 stands where the totem was (the picture's last frame) and talks.
            b.filmed = true;
            view.stop();
            playFilm(b, function():void
            {
               view.gotoAndStop(view.totalFrames);
               talk(b);
            });
            return;
         }
         if (b.kind == "ask")
         {
            // A boss whose talks are lost (鬼王): asked plainly.
            var ask:* = NewDialog.getCofirmDialog("要挑战" + b.name + "吗？它可是很厉害的哦！");
            ask.addEventListener(ModalDialogEvent.OK, function(ev:*):void { fight(); });
            ask.show();
            return;
         }
         if (b.kind == "book" && !b.awake && view != null)
         {
            var book:MovieClip = null;
            try { book = MovieClip(MovieClip(view.getChildByName("mcbook")).getChildByName("mc")); } catch (e0:Error) {}
            b.awake = true;
            if (book != null && book.totalFrames > 1)
            {
               book.addFrameScript(book.totalFrames - 1, function():void
               {
                  book.stop();
                  talk(b);
               });
               book.gotoAndPlay(2);
               return;
            }
         }
         if (b.kind == "film" && !b.filmed && b.film != null)
         {
            b.filmed = true;
            playFilm(b, function():void { talk(b); });
            return;
         }
         talk(b);
      }

      private function openPanel(b:Object):void
      {
         // One panel at a time: a second click while it loads or shows (or while the boss's own
         // animation still plays) opened another over it, and the one left under the battle
         // covered it.
         if (b.opening || (panelShown != null && panelShown.stage != null)) return;
         b.opening = true;
         var parts:Array = String(b.film).split("|");
         ResScheduler.getResource(String(parts[0]), function(... a):void
         {
            try
            {
               var C:Class = getDefinitionByName(String(parts[1])) as Class;
               var panel:Object = new C();
               panel.showPanel();
               panelShown = panel as DisplayObject;
               if (b.kind == "garden") showGardenPanel(b, panel as DisplayObject);
               // Before the battle module's own listener (priority): see onBattleJoined.
               SocketClient.instance.addEventListener("2303", onBattleJoined, false, 100);
            }
            catch (err:Error) { RLog.error("guardian panel " + b.name, err); }
            b.opening = false;
         }, "", function(e:* = null):void
         {
            b.opening = false;
            RLog.log("guardian: no panel " + parts[0]);
         });
      }

      /**
       * 蓝羽灵者's GardenPanel (its showPanel is empty: the lost GardenInteraction showed
       * it): over the scene, its win mark shown once the boss has been beaten (54_19's
       * list holds 1393, its egg, as 岩波斗魂者's holds 1211).
       */
      private function showGardenPanel(b:Object, panel:DisplayObject):void
      {
         if (panel == null) return;
         try
         {
            var win:DisplayObject = Object(panel).win as DisplayObject;
            if (win != null) win.visible = false;
         }
         catch (e0:Error) {}
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(panel);
         var onMarks:Function = function(e:*):void
         {
            SocketClient.instance.removeEventListener("54_19", onMarks);
            var bo:String = "";
            try { bo = String(e.params.bo || ""); } catch (e1:Error) {}
            b.won = ("," + bo + ",").indexOf(",1393,") >= 0;
            try { if (Object(panel).win != null) Object(panel).win.visible = b.won; } catch (e2:Error) {}
         };
         SocketClient.instance.addEventListener("54_19", onMarks);
         SocketClient.instance.sendXtMessage("PetExtension", "54_19", {});
      }

      /** The panel of 友人契约书 or 岩波斗魂者 while it is open. */
      private var panelShown:DisplayObject;

      /**
       * A battle is joined (2303) from a boss's panel: the panel goes first, as the
       * later engine's enterFight cleared every panel (ModalDialogManager.clearAll)
       * before it switched to the fighting layer. Left open on the top layer it
       * covered the battle, which could then not be played (and every later fight
       * was refused: 不能够在离开一个战场之前加入另外一个战场); closed after the battle
       * module had switched layers, the dialog manager switched back to the scene
       * (the panels open with a change of layer). Its own listeners stay:
       * 岩波斗魂者's shows itself again after the battle, 友人契约书's plays its egg
       * film after a first win. A refusal (2303 with msg alone) leaves it open.
       */
      private function onBattleJoined(e:* = null):void
      {
         try { if (e != null && e.params != null && e.params.msg != null && e.params.pmmList == null) return; } catch (pe:Error) {}
         var p:DisplayObject = panelShown;
         if (p != null && p.stage != null)
         {
            try { ModalDialogManager.getInstance().removeModalDialog(p); } catch (err:Error) { RLog.error("guardian panel", err); }
         }
      }

      private function playFilm(b:Object, then:Function):void
      {
         var cls:String = "mmo.dailyactivity." + b.film;
         var mc:MovieClip = null;
         try
         {
            if (ApplicationDomain.currentDomain.hasDefinition(cls))
            {
               var C:Class = getDefinitionByName(cls) as Class;
               mc = new C() as MovieClip;
            }
         }
         catch (e:Error) {}
         // 时间之神's film is a one-frame clip whose animation is its child mc.
         if (mc != null && mc.totalFrames < 2 && mc.getChildByName("mc") is MovieClip && MovieClip(mc.getChildByName("mc")).totalFrames > 1)
         {
            var outer:MovieClip = mc;
            mc = MovieClip(outer.getChildByName("mc"));
            var holder:Sprite = new Sprite();
            holder.addChild(outer);
            // Over the street's clock (缤纷泡泡街's eess, drawn 5 px lower than the film's).
            if (b.kind == "clock") holder.y = -5;
            playClip(holder, mc, then);
            return;
         }
         if (mc == null || mc.totalFrames < 2)
         {
            then();
            return;
         }
         playClip(mc, mc, then);
      }

      /** Shows `shown` over the scene until `clip` reaches its last frame (or its skip button is pressed). */
      private function playClip(shown:Sprite, mc:MovieClip, then:Function):void
      {
         var layer:Sprite = new Sprite();
         layer.name = "guardianFilm";
         layer.graphics.beginFill(0x000000, 0.01);
         layer.graphics.drawRect(0, 0, 960, 560);
         layer.graphics.endFill();
         layer.addChild(shown);
         LayerManager.getBaseTop().addChild(layer);
         var done:Boolean = false;
         var end:Function = function(... a):void
         {
            if (done) return;
            done = true;
            mc.stop();
            if (layer.parent) layer.parent.removeChild(layer);
            then();
         };
         mc.addFrameScript(mc.totalFrames - 1, end);
         var skip:DisplayObject = mc.getChildByName("skip");
         if (skip != null) skip.addEventListener(MouseEvent.CLICK, end);
         mc.gotoAndPlay(1);
      }

      private function talk(b:Object):void
      {
         var key:String = mainTalk(b);
         var ns:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         if (ns == null) return;
         // No 亚比 of level 60 yet: the HELLO warns first (its 我想先试一试 opens the boss's talk).
         if (b.form == 0 && topLevel() < 60)
         {
            ns.showNpcPanelFreely(helloOf(b), 1);
            return;
         }
         ns.showNpcPanelFreely(key, int(b.npc));
      }

      /** The bosses that have a HELLO warning of their own (FreeTalkData hello_before_boss<race>). */
      private static const HELLOS:String = ",10090,10093,10096,10099,10102,10105,10108,10111,10112,10195,10317,10427,10469,10475,10493,10639,10665,"
         + "10715,10796,12619,12702,12731,20087,20105,20418,20427,30278,30682,10112,10195,10493,10639,10665,";

      /**
       * The HELLO's warning before a boss: its own, or the one of its talk
       * (神罗麦提 talks as boss12702), else the words they all share (暴雪山神
       * has none of its own: the generic text answered 一直在路上……).
       */
      private static function helloOf(b:Object):String
      {
         var race:String = String(b.forms[0].race);
         if (HELLOS.indexOf("," + race + ",") >= 0) return "hello_before_boss" + race;
         var t:String = String(b.talk);
         if (t.indexOf("boss") == 0 && HELLOS.indexOf("," + t.substr(4) + ",") >= 0) return "hello_before_" + t;
         return "hello_before_boss30682";
      }

      private static function mainTalk(b:Object):String
      {
         if (b.talks == "pig") return "courageDoorBossTalk";
         if (b.talks == "start" && b.form > 0) return b.talk + "Two";
         return String(b.talk);
      }

      private static function topLevel():int
      {
         var top:int = 0;
         try
         {
            var svc:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
            for each (var p:* in (svc ? svc.getMyPets() : []))
            {
               var info:PetBriefInfo = p as PetBriefInfo;
               if (info != null && info.level > top) top = info.level;
            }
         }
         catch (e:Error) {}
         return top;
      }

      private function onAction(e:TaskEvent):void
      {
         if (active == null || e.params == null) return;
         // The bosses with a panel of their own (友人契约书, 岩波斗魂者) fight from it: their
         // talks' nextFight is the panel's, not a second fight from here.
         if (active.kind == "panel" || active.kind == "stone") return;
         var a:String = String(e.params.action || "");
         if (active.kind == "garden")
         {
            // Its panel's 挑战 (begin_bossfight31394) fights the first form; the talks after a
            // won form (boss31394failure, boss21394failure) go on (gotofight31394).
            if (a == "begin_bossfight" + active.file) { active.form = 0; fight(); }
            else if (a == "gotofight" + active.file) fight();
            return;
         }
         if (a.indexOf("begin_bossfight") == 0)
         {
            var ns:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
            if (ns != null) ns.showNpcPanelFreely(mainTalk(active), int(active.npc));
            return;
         }
         if (a.indexOf("gotofight") == 0 || a.indexOf("begin_gotofight") == 0 || a.indexOf("FightOceanBoss") == 0 || a == "nextFight" || a == "fightWithBigPig") fight();
      }

      private function fight():void
      {
         var f:Object = active.forms[Math.min(int(active.form), active.forms.length - 1)];
         var ipf:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         if (ipf == null) return;
         fighting = true;
         active.asked = int(f.race);
         ipf.fightWithBoss(String(f.race), int(f.index));
      }

      private function onFightEnd(e:PetFightEvent):void
      {
         if (!fighting || active == null) return;
         fighting = false;
         if (e.raceId != 0 && e.raceId != int(active.asked)) return;
         var b:Object = active;
         var last:Boolean = b.form >= b.forms.length - 1;
         var key:String;
         if (e.isWin && !last && b.talks == "pig")
         {
            // 终极麦斗王 and his two pigs were one team (BossTimeHelper "14523#11514#11516"):
            // the next comes on at once, without words in between.
            b.form = b.form + 1;
            var t:Timer = new Timer(1200, 1);
            t.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void { if (active == b) fight(); });
            t.start();
            return;
         }
         if (b.talks == "garden")
         {
            var beaten:int = int(b.forms[Math.min(int(b.form), b.forms.length - 1)].race);
            if (e.isWin && !last)
            {
               b.form = b.form + 1;
               var gs:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
               if (gs != null) gs.showNpcPanelFreely("boss" + beaten + "failure", int(b.npc));
               return;
            }
            // The last form beaten (its film once, the first time) or a loss: back to the panel.
            b.form = 0;
            var again:Function = function():void { if (b.view != null && DisplayObject(b.view).stage != null) openPanel(b); };
            if (e.isWin && !b.won)
            {
               b.won = true;
               ResScheduler.getResource("dailyactivity/boss" + b.file + "movie", function(... r):void
               {
                  var fb:Object = {film: "Boss" + b.file + "Movie", kind: "film"};
                  playFilm(fb, again);
               }, "", function(err:* = null):void { again(); });
               return;
            }
            again();
            return;
         }
         if (e.isWin)
         {
            key = after(b, last ? "final" : "next");
            b.form = last ? 0 : b.form + 1;
         }
         else
         {
            key = after(b, "lose");
            b.form = 0;
         }
         var ns:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         if (ns != null && key != null) ns.showNpcPanelFreely(key, int(b.npc));
      }

      /** The talk after a battle: final (the last form beaten), next (more forms to fight), lose. */
      private static function after(b:Object, what:String):String
      {
         var k:String = String(b.talk);
         switch (String(b.talks))
         {
            // The later TeamBossInteraction: <talk>win on a loss, <talk>slose on a win.
            case "team": return what == "lose" ? k + "win" : k + "slose";
            // Named from the boss's side: courageDoorBossWin (he won: 不自量力的小奥拉…) after a
            // loss, courageDoorBossLose (he lost: 感谢你，你让我脱离了念的控制…) after the last win.
            case "pig": return what == "lose" ? "courageDoorBossWin" : "courageDoorBossLose";
            case "feier": return what == "lose" ? "feier4bossfailure" : "feier4bosssuccess";
            case "one": return null;
            case "start": return what == "final" ? k + "100" : what == "next" ? k + "Two" : k + "win";
         }
         return what == "final" ? k + "100" : what == "next" ? k + "failure" : k + "win";
      }
   }
}
