package mmo.hellohelper.helloicon
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.hellohelper.*;
   import mmo.interfaces.hellohelper.IHelloIconService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HelloIconService. Module hellohelper/helloiconservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.hellohelper.IHelloIconService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HelloIconService extends EventDispatcher implements IHelloIconService
   {
      public function HelloIconService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("HelloIconService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
