package mmo.fbexchange
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.fb.*;
   import mmo.interfaces.fb.IFbExchangeService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FbExchangeService. Module fbservice/fbexchange.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fb.IFbExchangeService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FbExchangeService extends EventDispatcher implements IFbExchangeService
   {
      public function FbExchangeService()
      {
         super();
      }

      public function showExchangePanel(param1:int) : void
      {
         RLog.stub("FbExchangeService.showExchangePanel");
      }

   }
}
