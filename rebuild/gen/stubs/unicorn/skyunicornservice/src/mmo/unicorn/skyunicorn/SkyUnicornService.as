package mmo.unicorn.skyunicorn
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.unicorn.*;
   import mmo.interfaces.unicorn.ISkyUnicornService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SkyUnicornService. Module unicorn/skyunicornservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.unicorn.ISkyUnicornService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SkyUnicornService extends EventDispatcher implements ISkyUnicornService
   {
      public function SkyUnicornService()
      {
         super();
      }

      public function addMyFollower() : void
      {
         RLog.stub("SkyUnicornService.addMyFollower");
      }

      public function initSkyUnicornSceneInteraction() : void
      {
         RLog.stub("SkyUnicornService.initSkyUnicornSceneInteraction");
      }

      public function removeMyFollower() : void
      {
         RLog.stub("SkyUnicornService.removeMyFollower");
      }

      public function init() : void
      {
         RLog.stub("SkyUnicornService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
