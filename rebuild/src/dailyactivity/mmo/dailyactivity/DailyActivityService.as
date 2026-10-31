package mmo.dailyactivity
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.text.TextField;
   import mmo.interfaces.DailyActivity.BossTimeHelper;
   import mmo.interfaces.DailyActivity.IDailyActivity;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.arrowguide.ArrowType;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REBUILT dailyactivity/dailyactivityservice: the 守护者, the bosses of the
    * areas (BossTimeHelper.bossTimeConfig of the 2013 interfaces: 19 scenes,
    * each boss's forms as race ids and levels, "a,b,c" one after another and
    * "a#b" a pair). The January 2013 module is lost: in 2013 the server named
    * the room's boss in the room variable "boss" and the module drew it from
    * dailyactivity/dailyboss<id> (lost too) with a talk whose 挑战 called
    * IPetFight.fightWithBoss(raceId, index) (PetExtension 54_16). Here each
    * boss stands where the era arrow guide points (BossTimeHelper.points),
    * dressed as its 亚比 (PetClothesMap), and a click offers its forms to
    * fight (RECONSTRUCTED). getPetStates answers false, as the stand-in did.
    */
   public class DailyActivityService extends EventDispatcher implements IDailyActivity
   {
      private var shown:Array = [];
      private var panel:Sprite;

      public function DailyActivityService()
      {
         super();
      }

      public function init():void
      {
         var sm:SceneManager = SceneManager.getInstance();
         sm.addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
         sm.addEventListener(SceneManagerEvent.UNLOAD_SCENE, onUnload);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
         if (sm.loadedSceneInfo != null) onSceneInited(null);
      }

      public function getPetStates(param1:int):Boolean
      {
         return false;
      }

      /** The bosses of a scene: [{scene, name, part, forms: [{race, level, index}]}]. */
      public static function bossesOf(sceneName:String):Array
      {
         var out:Array = [];
         try
         {
            var cfg:XML = BossTimeHelper.bossTimeConfig;
            var node:XMLList = cfg.daily[0].boss[0].scene.(@name == sceneName);
            if (node.length() == 0) return out;
            var races:Array = String(node[0].@race).split("#");
            var levels:Array = String(node[0].@level).split("#");
            var name:String = String(node[0].@ext);
            var index:int = 0;
            for (var p:int = 0; p < races.length; p++)
            {
               var rs:Array = String(races[p]).split(",");
               var ls:Array = String(levels[p] || levels[0]).split(",");
               var forms:Array = [];
               for (var k:int = 0; k < rs.length; k++) forms.push({race: int(rs[k]), level: int(ls[k] || ls[0]), index: index++});
               out.push({scene: sceneName, name: name, part: p, forms: forms});
            }
         }
         catch (e:Error) { RLog.error("guardians " + sceneName, e); }
         return out;
      }

      private function onSceneInited(e:SceneManagerEvent):void
      {
         clear();
         var info:* = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null || info.inHouse) return;
         var name:String = info.sceneName;
         var bosses:Array = bossesOf(name);
         if (bosses.length == 0) return;
         var points:Array = BossTimeHelper.points[name] as Array || [];
         for (var i:int = 0; i < bosses.length; i++)
         {
            var b:Object = bosses[i];
            var pt:Object = points[Math.min(i, points.length - 1)] || {x: 480, y: 300, d: ArrowType.ARROW_DOWN};
            var a:BossAvatar = new BossAvatar(b, int(b.forms[0].race) % 10000, pick);
            // The arrow points at the boss from above, below or a side.
            var d:int = int(pt.d);
            a.x = int(pt.x) + (d == ArrowType.ARROW_LEFT ? -70 : d == ArrowType.ARROW_RIGHT ? 70 : 0);
            a.y = int(pt.y) + (d == ArrowType.ARROW_DOWN ? 110 : d == ArrowType.ARROW_UP ? -30 : 60);
            try
            {
               info.scene.container.addChild(a);
               shown.push(a);
            }
            catch (err:Error) { RLog.error("guardian " + name, err); }
         }
         RLog.log("guardians: " + bosses.length + " in " + name);
      }

      private function onUnload(e:SceneManagerEvent):void
      {
         clear();
      }

      private function clear():void
      {
         closePanel();
         for each (var a:BossAvatar in shown)
         {
            try
            {
               if (a.parent) a.parent.removeChild(a);
               a.dispose();
            }
            catch (e:Error) {}
         }
         shown = [];
      }

      /** Which form to fight: each with its level, 挑战 starts the fight. */
      private function pick(b:Object):void
      {
         closePanel();
         var forms:Array = b.forms as Array;
         var W:int = 380;
         var H:int = 120 + forms.length * 40;
         panel = new Sprite();
         panel.name = "guardianPanel";
         panel.addChild(RUI.dim(closePanel));
         var box:Sprite = RUI.panel(W, H, "守护者 " + b.name, closePanel, "guardianClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 20;
         panel.addChild(box);
         var said:TextField = RUI.text(13, RUI.BLUE, false, W - 40);
         said.x = 20;
         said.y = 56;
         said.text = "我是这里的守护者，打败我，证明你的实力吧！";
         box.addChild(said);
         for (var i:int = 0; i < forms.length; i++)
         {
            var f:Object = forms[i];
            var t:TextField = RUI.text(15, 0x8A3B00, true);
            t.text = "第" + (i + 1) + "形态   Lv" + f.level;
            t.x = 40;
            t.y = 90 + i * 40;
            box.addChild(t);
            var go:Sprite = RUI.button("挑战", fight(f), 90, 30, 0xFFC45A, 0xF07812, "guardianFight_" + f.index);
            go.x = W - 140;
            go.y = 84 + i * 40;
            box.addChild(go);
         }
         LayerManager.getBaseTop().addChild(panel);
      }

      private function fight(f:Object):Function
      {
         return function():void
         {
            closePanel();
            var ipf:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
            if (ipf != null) ipf.fightWithBoss(String(f.race), int(f.index));
         };
      }

      private function closePanel():void
      {
         if (panel != null && panel.parent != null) panel.parent.removeChild(panel);
         panel = null;
      }
   }
}
