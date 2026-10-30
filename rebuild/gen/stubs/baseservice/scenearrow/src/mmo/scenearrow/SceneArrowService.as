package mmo.scenearrow
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.scenearrow.*;
   import mmo.interfaces.scenearrow.ISceneArrowService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SceneArrowService. Module baseservice/scenearrow.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.scenearrow.ISceneArrowService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SceneArrowService extends EventDispatcher implements ISceneArrowService
   {
      public function SceneArrowService()
      {
         super();
      }

      public function addArrows(param1:Array) : void
      {
         RLog.stub("SceneArrowService.addArrows");
      }

      public function removeAllArrow() : void
      {
         RLog.stub("SceneArrowService.removeAllArrow");
      }

      public function removeArrow(param1:String) : Boolean
      {
         RLog.stub("SceneArrowService.removeArrow");
         return false;
      }

      public function removeArrows(param1:Array) : int
      {
         RLog.stub("SceneArrowService.removeArrows");
         return 0;
      }

      public function init() : void
      {
         RLog.stub("SceneArrowService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
