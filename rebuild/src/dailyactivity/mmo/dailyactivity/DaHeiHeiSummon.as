package mmo.dailyactivity
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.revival.RLog;

   /**
    * REBUILT: 召唤达黑黑 in 海枯之山 (haikustar4). The era scene wires its button
    * itself (ClickAndHitHelper.registerTarget(btn, false, 100, true), which the
    * rebuilt helper takes now) and its onClickDaHeiHei hides the button, plays
    * DaHeiHeiMovie and puts 达黑黑 (NPC 516) at 400, 150. Should that handler
    * stop before it hides the button (its SceneArrowService call, a stand-in),
    * this does the same after it: the player hides while the scene's own film
    * plays, then 达黑黑 stands there and rarepets/raredaheihei
    * (DaHeiHeiInitialler: its story, 猜弹珠) answers its menu (PlanetMenus).
    */
   public class DaHeiHeiSummon
   {
      private static var btn:InteractiveObject;
      private static var initialler:Object;
      /** The film playing, and the player it hides. */
      private static var film:MovieClip;
      private static var hidden:DisplayObject;

      public static function onScene(sceneName:String, scene:DisplayObjectContainer):void
      {
         clear();
         if (sceneName != "haikustar4" || scene == null) return;
         btn = findNamed(scene, "btn_daheihei", 4) as InteractiveObject;
         if (btn == null) return;
         ClickAndHitHelper.instance.registerTarget(btn, false, 100);
         // After the scene's own handler, should it be wired after all (it then hides the button first).
         btn.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, onSummon, false, -1);
      }

      public static function clear():void
      {
         if (btn != null)
         {
            try
            {
               ClickAndHitHelper.instance.remove(btn);
               btn.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, onSummon);
            }
            catch (e:Error) {}
            btn = null;
         }
         if (initialler != null)
         {
            try { initialler.dispose(); } catch (e2:Error) {}
            initialler = null;
         }
         // Left while the film played: it stops here (a removed clip plays on, and its last
         // frame would have put 达黑黑 into the next scene).
         if (film != null)
         {
            film.stop();
            if (film.parent) film.parent.removeChild(film);
            film = null;
         }
         if (hidden != null)
         {
            hidden.visible = true;
            hidden = null;
         }
      }

      private static function onSummon(e:ClickAndHitEvent):void
      {
         var info:* = SceneManager.getInstance().loadedSceneInfo;
         if (btn == null || !btn.visible || info == null || info.scene == null) return;
         btn.visible = false;
         var cls:String = "mmo.scene.haikustar.DaHeiHeiMovie";
         var mc:MovieClip = null;
         try
         {
            if (ApplicationDomain.currentDomain.hasDefinition(cls)) mc = new (getDefinitionByName(cls) as Class)() as MovieClip;
         }
         catch (err:Error) { RLog.error("daheihei film", err); }
         if (mc == null || mc.totalFrames < 2)
         {
            showNpc();
            return;
         }
         var me:DisplayObject = PlayerManager.getInstance().myPlayer as DisplayObject;
         if (me != null) me.visible = false;
         hidden = me;
         film = mc;
         var into:DisplayObjectContainer = (findNamed(info.scene, "foreground", 2) as DisplayObjectContainer) || info.scene.foreGround;
         into.addChild(mc);
         mc.addFrameScript(mc.totalFrames - 1, function():void
         {
            mc.stop();
            if (mc.parent) mc.parent.removeChild(mc);
            if (film != mc) return;
            film = null;
            if (me != null) me.visible = true;
            hidden = null;
            showNpc();
         });
         mc.gotoAndPlay(1);
      }

      private static function showNpc():void
      {
         var here:InteractiveObject = btn;
         ResScheduler.getResource("rarepets/raredaheihei", function(content:* = null):void
         {
            // Still in 海枯之山 (clear() has not run since).
            if (initialler == null && btn == here && here != null) initialler = content;
         }, "mmo.rarepets.daheihei.DaHeiHeiInitialler", function(e:* = null):void { RLog.log("daheihei: no rarepets/raredaheihei"); });
         var ns:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         if (ns != null) ns.addNpcToScene(516, 1, -1, 400, 150);
      }

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
   }
}
