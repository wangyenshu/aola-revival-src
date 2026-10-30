package mmo.unwallow
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.unwallow.*;
   import mmo.interfaces.unwallow.IUnwallowService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UnwallowService. Module unwallow/unwallow.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.unwallow.IUnwallowService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UnwallowService extends EventDispatcher implements IUnwallowService
   {
      public function UnwallowService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("UnwallowService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
