package mmo.wildpet
{
   import flash.events.EventDispatcher;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.fight.IWildPet;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;

   /**
    * REBUILT pet/wildpetservice (mmo.wildpet.WildPetService, IWildPet): the wild
    * 亚比 that walk about in a scene. The January 2013 module is lost; this
    * follows the later one's flow on the 2013 interface: two seconds after a
    * scene opens, PetClient2.GetLocationPetInfo (54_7) asks the server which
    * 亚比 live in the room ({pms: [{raceId, min, max, common, rate}]}); up to
    * four of them appear at the scene's points (WildPetLocationMap), common
    * ones in every slot and a rare one (common 0) now and then at its rate.
    * Walking into one starts a battle (WildPetAvatar); when the battle ends
    * they come back.
    */
   public class WildPetService extends EventDispatcher implements IWildPet
   {
      public static const WILD_PET_NUM:int = 4;
      private static const RADIUS:int = 50;

      private var appearTimer:Timer = new Timer(2000, 1);
      private var againTimer:Timer = new Timer(2000, 1);
      private var pets:Array = [];
      private var info:Array;
      private var infoScene:String;
      private var num:int;
      private var shown:Boolean = true;

      public function WildPetService()
      {
         super();
      }

      public function init():void
      {
         appearTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAppearTime);
         againTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAgainTime);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.TASK_SCENE_INITED, onEnterScene);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE, onUnloadScene);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_START, onFightStart);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onFightEnd);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      private function sceneName():String
      {
         var si:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         return si ? si.sceneName : null;
      }

      private function onEnterScene(e:SceneManagerEvent):void
      {
         appearTimer.reset();
         appearTimer.start();
      }

      private function onUnloadScene(e:SceneManagerEvent):void
      {
         appearTimer.stop();
         againTimer.stop();
         dispose();
         info = null;
      }

      private function onAppearTime(e:TimerEvent):void
      {
         // Every scene asks: the server knows which have wild 亚比.
         var points:Array = pointsOf(sceneName());
         if (points == null || points.length == 0) return;
         generatePet(Math.min(points.length, WILD_PET_NUM));
      }

      /**
       * Where wild 亚比 walk: the later client's points for the scene, or, for a
       * scene it has none for (the November 2012 map names 亚比 there), five
       * free spots of its obstruction spread over the first screen.
       */
      private function pointsOf(scene:String):Array
      {
         var points:Array = WildPetLocationMap.getLocations(scene);
         if (points != null) return points;
         var si:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (si == null || si.scene == null || si.scene.obStruction == null) return null;
         var out:Array = [];
         var tries:int = 0;
         var seed:int = 0;
         for (var k:int = 0; k < scene.length; k++) seed = (seed * 31 + scene.charCodeAt(k)) & 0xFFFF;
         while (out.length < 5 && tries < 400)
         {
            tries++;
            seed = (seed * 9301 + 49297) % 233280;
            var x:int = 120 + seed % 720;
            seed = (seed * 9301 + 49297) % 233280;
            var y:int = 260 + seed % 220;
            if (si.scene.isBlocked(x, y)) continue;
            var near:Boolean = false;
            for each (var p:Point in out) if (Point.distance(p, new Point(x, y)) < 110) near = true;
            if (!near) out.push(new Point(x, y));
         }
         return out.length > 0 ? out : null;
      }

      private function onFightStart(e:PetFightEvent):void
      {
         againTimer.stop();
         dispose();
      }

      private function onFightEnd(e:PetFightEvent):void
      {
         againTimer.reset();
         againTimer.start();
      }

      private function onAgainTime(e:TimerEvent):void
      {
         if (info != null && infoScene == sceneName()) place();
      }

      // ---------------------------------------------------------------- IWildPet

      public function generatePet(n:int):void
      {
         num = n;
         SocketClient.instance.addEventListener(PetClient2.cmdGetLocationPetInfo, onGetPetInfo);
         PetClient2.instance.GetLocationPetInfo();
      }

      private function onGetPetInfo(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(PetClient2.cmdGetLocationPetInfo, onGetPetInfo);
         info = (e.params.pms as Array) || [];
         infoScene = sceneName();
         place();
      }

      /** Up to `num` 亚比 at random points: common ones, and a rare one at its rate. */
      private function place():void
      {
         dispose();
         var commons:Array = [];
         var rares:Array = [];
         for each (var o:Object in info) (int(o.common) == 0 ? rares : commons).push(o);
         if (commons.length == 0) return;
         var points:Array = pointsOf(sceneName());
         if (points == null || points.length == 0) return;
         var n:int = Math.min(num > 0 ? num : WILD_PET_NUM, points.length);
         var chosen:Array = [];
         for (var i:int = 0; i < n; i++)
         {
            var pick:Object = i < commons.length ? commons[i] : commons[int(Math.random() * commons.length)];
            for each (var r:Object in rares)
            {
               if (Math.random() * 100 < Number(r.rate)) { pick = r; rares.splice(rares.indexOf(r), 1); break; }
            }
            chosen.push(pick);
         }
         for (i = 0; i < chosen.length; i++)
         {
            var at:Point = points.splice(int(Math.random() * points.length), 1)[0] as Point;
            var c:Object = chosen[i];
            var lv:String = int(c.min) != int(c.max) ? c.min + "～" + c.max : String(c.min);
            newPet(at, i, int(c.raceId), lv);
         }
         RLog.log("wildpet: " + chosen.length + " 亚比 in " + sceneName());
      }

      private function newPet(at:Point, i:int, raceId:int, level:String):void
      {
         var si:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (si == null || si.scene == null) return;
         var pet:WildPetAvatar = new WildPetAvatar("wildpet" + i, raceId, level);
         pet.x = at.x;
         pet.y = at.y;
         pet.visible = shown;
         si.scene.playerLayer.addChild(pet);
         pet.wander(at, RADIUS);
         pets.push(pet);
      }

      public function generatePetsAtCurrentScene(list:Array):void
      {
         dispose();
         for each (var o:Object in list || [])
         {
            if (o.point is Point) newPet(Point(o.point), pets.length, int(o.raceId), String(o.lv));
         }
      }

      public function setPetsInvisible():void
      {
         shown = false;
         for each (var p:WildPetAvatar in pets) p.visible = false;
      }

      public function setPetsVisible():void
      {
         shown = true;
         for each (var p:WildPetAvatar in pets) p.visible = true;
      }

      public function dispose():void
      {
         for each (var p:WildPetAvatar in pets) p.dispose();
         pets = [];
         SocketClient.instance.removeEventListener(PetClient2.cmdGetLocationPetInfo, onGetPetInfo);
      }
   }
}
