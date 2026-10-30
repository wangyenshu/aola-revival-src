package mmo.notify.common
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for NotifyInit. Module msg/notifyinit.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.IInitService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class NotifyInit extends EventDispatcher implements IInitService
   {
      public function NotifyInit()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("NotifyInit.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
