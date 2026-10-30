package mmo.cardexchange
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.cardexchange.*;
   import mmo.interfaces.cardexchange.ICardExchangeService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for CardExchangeService. Module cardexchange/cardexchangeservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.cardexchange.ICardExchangeService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class CardExchangeService extends EventDispatcher implements ICardExchangeService
   {
      public function CardExchangeService()
      {
         super();
      }

      public function showExhangePanel(param1:String, param2:Function = null, param3:Object = null) : *
      {
         RLog.stub("CardExchangeService.showExhangePanel");
         return null;
      }

      public function dispose() : void
      {
         RLog.stub("CardExchangeService.dispose");
      }

      public function init() : void
      {
         RLog.stub("CardExchangeService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
