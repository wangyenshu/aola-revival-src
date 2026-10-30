package mmo.dailyactivity
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.DailyActivity.*;
   import mmo.interfaces.DailyActivity.IDailyActivity;
   import mmo.interfaces.IInitService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for DailyActivityService. Module dailyactivity/dailyactivityservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.DailyActivity.IDailyActivity) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class DailyActivityService extends EventDispatcher implements IDailyActivity
   {
      public function DailyActivityService()
      {
         super();
      }

      public function getPetStates(param1:int) : Boolean
      {
         RLog.stub("DailyActivityService.getPetStates");
         return false;
      }

      public function init() : void
      {
         RLog.stub("DailyActivityService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
