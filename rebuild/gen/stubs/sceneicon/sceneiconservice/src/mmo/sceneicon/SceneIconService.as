package mmo.sceneicon
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.sceneicon.*;
   import mmo.interfaces.sceneicon.ISceneIconService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SceneIconService. Module sceneicon/sceneiconservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.sceneicon.ISceneIconService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SceneIconService extends EventDispatcher implements ISceneIconService
   {
      public function SceneIconService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("SceneIconService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
