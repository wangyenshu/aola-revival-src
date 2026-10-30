package mmo.pm.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.pm.data.PMCustomData;
   import mmo.interfaces.pet.pm.services.*;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PMService. Module pet/pmservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.pm.services.IPMService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PMService extends EventDispatcher implements IPMService
   {
      private var _customData:*;
      public function PMService()
      {
         super();
      }

      public function get customData() : PMCustomData
      {
         RLog.stub("PMService.customData");
         return this._customData as PMCustomData;
      }

      public function init() : void
      {
         RLog.stub("PMService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
