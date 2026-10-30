package mmo.ad
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.ad.*;
   import mmo.interfaces.ad.IAdService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for AdService. Module news/newsservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.ad.IAdService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class AdService extends EventDispatcher implements IAdService
   {
      public function AdService()
      {
         super();
      }

      public function showAdvertisement(param1:String, param2:String, param3:Function = null, param4:Object = null) : *
      {
         RLog.stub("AdService.showAdvertisement");
         return null;
      }

      public function showPanel(param1:String, param2:Object = null) : void
      {
         RLog.stub("AdService.showPanel");
      }

      public function init() : void
      {
         RLog.stub("AdService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      public function dispose() : void
      {
         RLog.stub("AdService.dispose");
      }

   }
}
