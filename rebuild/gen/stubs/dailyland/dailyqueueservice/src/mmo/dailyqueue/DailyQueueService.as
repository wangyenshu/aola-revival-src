package mmo.dailyqueue
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.dailyqueue.*;
   import mmo.interfaces.dailyqueue.IDailyQueue;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for DailyQueueService. Module dailyland/dailyqueueservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.dailyqueue.IDailyQueue) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class DailyQueueService extends EventDispatcher implements IDailyQueue
   {
      public function DailyQueueService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("DailyQueueService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
