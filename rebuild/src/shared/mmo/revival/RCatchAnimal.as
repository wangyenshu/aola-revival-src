package mmo.revival
{
   import flash.system.ApplicationDomain;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REVIVAL. 动物捕捉's panel (the rebuilt game/catchanimalpanel, StartPanel) from the places
    * that open it: the 生态园's 动物捕捉 and its fishing spot (海洋乐园 straight away), and
    * the 动物园's plane.
    */
   public class RCatchAnimal
   {
      private static const CLS:String = "mmo.game.catchanimalpanel.StartPanel";

      /** map: -1 the map of the four 乐园 after 进入; 0 大地, 1 天空, 2 海洋, 3 狗狗之家 at once. */
      public static function open(map:int = -1):void
      {
         var go:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(CLS)) { RLog.log("catchanimalpanel: no StartPanel"); return; }
            var C:Object = ApplicationDomain.currentDomain.getDefinition(CLS);
            try { C.open(map); } catch (e:Error) { RLog.error("catchanimalpanel", e); }
         };
         if (ApplicationDomain.currentDomain.hasDefinition(CLS)) go();
         // Without a class name: a missing one would leave the 2013 ResScheduler's loader taken.
         else ResScheduler.getResource("game/catchanimalpanel", go, "", function(e:* = null):void { RLog.log("catchanimalpanel: not loaded"); });
      }
   }
}
