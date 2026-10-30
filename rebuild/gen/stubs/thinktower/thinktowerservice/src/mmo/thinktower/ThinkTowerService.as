package mmo.thinktower
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.thinktower.*;
   import mmo.interfaces.thinktower.IThinkTower;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ThinkTowerService. Module thinktower/thinktowerservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.thinktower.IThinkTower) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ThinkTowerService extends EventDispatcher implements IThinkTower
   {
      private var _icecount:int = 0;
      public function ThinkTowerService()
      {
         super();
      }

      public function setSceneInteract(param1:int, param2:Array, param3:Function) : void
      {
         RLog.stub("ThinkTowerService.setSceneInteract");
      }

      public function get icecount() : int
      {
         RLog.stub("ThinkTowerService.icecount");
         return this._icecount;
      }

      public function set icecount(param1:int) : *
      {
         this._icecount = param1;
      }

      public function showEnterPanel() : void
      {
         RLog.stub("ThinkTowerService.showEnterPanel");
      }

      public function setControlBarMode(param1:Boolean) : void
      {
         RLog.stub("ThinkTowerService.setControlBarMode");
      }

      public function dispose() : void
      {
         RLog.stub("ThinkTowerService.dispose");
      }

   }
}
