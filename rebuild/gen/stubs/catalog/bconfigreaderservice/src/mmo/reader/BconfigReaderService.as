package mmo.reader
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.catalog.*;
   import mmo.interfaces.catalog.IBconfigReaderService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BconfigReaderService. Module catalog/bconfigreaderservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.catalog.IBconfigReaderService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BconfigReaderService extends EventDispatcher implements IBconfigReaderService
   {
      public function BconfigReaderService()
      {
         super();
      }

      public function isRead(param1:String) : Boolean
      {
         RLog.stub("BconfigReaderService.isRead");
         return false;
      }

      public function setRead(param1:String) : void
      {
         RLog.stub("BconfigReaderService.setRead");
      }

      public function init() : void
      {
         RLog.stub("BconfigReaderService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
