package mmo.weekly
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.weekly.*;
   import mmo.interfaces.weekly.IWeeklyService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for WeeklyService. Module baseservice/weekly.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.weekly.IWeeklyService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class WeeklyService extends EventDispatcher implements IWeeklyService
   {
      public function WeeklyService()
      {
         super();
      }

      public function showLastestWeekly(param1:int = -1, param2:String = "104") : void
      {
         RLog.stub("WeeklyService.showLastestWeekly");
      }

      public function init() : void
      {
         RLog.stub("WeeklyService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
