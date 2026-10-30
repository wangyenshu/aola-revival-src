package mmo.honour
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.honour.*;
   import mmo.interfaces.honour.IHonourService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HonourService. Module honour/honourservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.honour.IHonourService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HonourService extends EventDispatcher implements IHonourService
   {
      public function HonourService()
      {
         super();
      }

      public function getHonourConfig() : Array
      {
         RLog.stub("HonourService.getHonourConfig");
         return [];
      }

      public function showPanel(param1:String) : void
      {
         RLog.stub("HonourService.showPanel");
      }

      public function init() : void
      {
         RLog.stub("HonourService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
