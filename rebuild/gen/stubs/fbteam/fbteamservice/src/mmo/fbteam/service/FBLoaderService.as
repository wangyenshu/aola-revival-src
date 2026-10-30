package mmo.fbteam.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fbteam.*;
   import mmo.interfaces.fbteam.IFBLoaderService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FBLoaderService. Module fbteam/fbteamservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fbteam.IFBLoaderService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FBLoaderService extends EventDispatcher implements IFBLoaderService
   {
      public function FBLoaderService()
      {
         super();
      }

      public function leaveFb(param1:Object) : void
      {
         RLog.stub("FBLoaderService.leaveFb");
      }

      public function joinFb(param1:int, param2:String, param3:int, param4:Object) : void
      {
         RLog.stub("FBLoaderService.joinFb");
      }

      public function reset() : void
      {
         RLog.stub("FBLoaderService.reset");
      }

      public function init() : void
      {
         RLog.stub("FBLoaderService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
