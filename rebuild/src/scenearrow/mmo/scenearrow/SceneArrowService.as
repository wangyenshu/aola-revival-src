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
    * REBUILT STUB for SceneArrowService (written from the generated one of
    * tools/gen_stubs.py). Module baseservice/scenearrow.swf of January 2013 is
    * lost; this keeps the original class name and interface so code that looks
    * the service up keeps running; no arrows are shown. It also answers
    * removeArrowsByGroup, which the later copies of scenes call (星光游乐场's game
    * buttons) on the later interface: the call is made in the interface's
    * namespace, so the method is declared there.
    */
   public class SceneArrowService extends EventDispatcher implements ISceneArrowService
   {
      /** The later ISceneArrowService's namespace: its methods are called in it. */
      public namespace later = "mmo.interfaces.scenearrow:ISceneArrowService";

      later function removeArrowsByGroup(param1:String) : void
      {
         RLog.stub("SceneArrowService.removeArrowsByGroup");
      }

      public function removeArrowsByGroup(param1:String) : void
      {
         RLog.stub("SceneArrowService.removeArrowsByGroup");
      }

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
