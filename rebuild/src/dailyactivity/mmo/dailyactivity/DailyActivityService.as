package mmo.dailyactivity
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
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
       * scene, name, file (dailyactivity/dailyboss<file>), class, x, y, kind (wake, still, film),
       * film class, npc, talk key, talk set (std, team, pig, feier, start, one), forms "race:level,…".
       */
      private static const BOSSES:Array = [
         ["aixiscene6", "冰拳艾司", 20087, "IceBoss", 0, 0, "wake", null, 64, "iceboss", "std", "20087:80"],
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
         ["fairytalestar1", "童心", 30682, "Boss10682", 0, 0, "still", null, 462, "themepark30682", "std", "30682:88,10682:100"],
         ["haikustar2", "神龟", 10715, "Boss10715", 0, 0, "still", null, 513, "boss10715", "std", "10715:80,20715:100"],
         ["fightspace2", "终极麦斗王", 14523, "BossInteraction.PigBoss", 187, 272, "still", null, 278, "courageDoorBoss", "pig", "14523:100,11514:80,11516:80"],
         ["bingxuestar4", "暴雪山神", 10757, "Boss10757", 0, 0, "film", "BossMovie10757", 538, "boss10757", "std", "10757:80,20757:100"],
         ["yakestar4", "神罗麦提", 10840, "Boss10840", 0, 0, "film", "Boss10840Movie", 589, "boss12702", "std", "10840:80,20840:100"],
         ["candystar3", "超T兔", 10865, "Boss10865", 0, 0, "still", null, 613, "boss12731", "std", "10865:80,20865:100"],
         ["cloudstar4", "石城守护者", 11213, "StoneBoss", 0, 0, "still", null, 1, "FirstWinTalk_1213", "one", "11213:60,21213:80,31213:100"],
         ["mysticocean5", "伊泽和迦娜", 11320, "Boss11320", 0, 0, "still", null, 842, "hello_before_OceanBoss", "one", "11320:100,11322:100"],
         ["feier4", "烈焰鸟", 30278, "Feier4boss", 640, 454, "wake", null, 80, "feier4boss", "feier", "30278:80"],
         ["choicetemple", "神武月", 10105, "Boss10105", 0, 0, "film", "BossInteraction.BossMovie10105", 127, "boss10105", "start", "10105:80,20105:100"],
         ["choicetemple", "战无炎", 10111, "Boss10111", 0, 0, "film", "BossInteraction.BossMovie10111", 303, "boss10111", "start", "10111:90"]
      ];

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
         for each (var b:Object in bossesOf(String(info.sceneName))) place(b, info.scene.container);
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
               view.x = 480;
               view.y = 300;
            }
            else
            {
               var at:Point = whereOf(b, view);
               view.x = at.x;
               view.y = at.y;
               if (view is MovieClip && b.kind == "wake") MovieClip(view).gotoAndStop(1);
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
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
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
         if (Math.abs(cx) > 220 || Math.abs(cy) > 220) return new Point(0, 0);
         if (int(b.x) != 0 || int(b.y) != 0) return new Point(int(b.x), int(b.y));
         var pts:Array = BossTimeHelper.points[b.scene] as Array;
         if (pts == null || pts.length == 0) return new Point(480, 320);
         var pt:Object = pts[Math.min(int(b.part), pts.length - 1)];
         var d:int = int(pt.d);
         return new Point(int(pt.x) + (d == ArrowType.ARROW_LEFT ? -70 : d == ArrowType.ARROW_RIGHT ? 70 : 0),
            int(pt.y) + (d == ArrowType.ARROW_DOWN ? 110 : d == ArrowType.ARROW_UP ? -30 : 60));
      }

      private function onUnload(e:SceneManagerEvent):void
      {
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
            }
            catch (e:Error) {}
         }
         shown = [];
         if (!fighting) active = null;
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
         if (b.kind == "film" && !b.filmed && b.film != null)
         {
            b.filmed = true;
            playFilm(b, function():void { talk(b); });
            return;
         }
         talk(b);
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
         if (mc == null || mc.totalFrames < 2)
         {
            then();
            return;
         }
         var layer:Sprite = new Sprite();
         layer.name = "guardianFilm";
         layer.graphics.beginFill(0x000000, 0.01);
         layer.graphics.drawRect(0, 0, 960, 560);
         layer.graphics.endFill();
         layer.addChild(mc);
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
            ns.showNpcPanelFreely("hello_before_boss" + b.forms[0].race, 1);
            return;
         }
         ns.showNpcPanelFreely(key, int(b.npc));
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
         var a:String = String(e.params.action || "");
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
            case "team": return what == "lose" ? k + "slose" : k + "win";
            case "pig": return what == "lose" ? "courageDoorBossLose" : "courageDoorBossWin";
            case "feier": return what == "lose" ? "feier4bossfailure" : "feier4bosssuccess";
            case "one": return null;
            case "start": return what == "final" ? k + "100" : what == "next" ? k + "Two" : k + "win";
         }
         return what == "final" ? k + "100" : what == "next" ? k + "failure" : k + "win";
      }
   }
}
