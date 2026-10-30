package mmo.occupationwork
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.occupationwork.*;
   import mmo.interfaces.occupationwork.IOccupationWorkService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for OccupationWorkService. Module occupationwork.occupationworkservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.occupationwork.IOccupationWorkService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class OccupationWorkService extends EventDispatcher implements IOccupationWorkService
   {
      public function OccupationWorkService()
      {
         super();
      }

      public function cancelaction() : void
      {
         RLog.stub("OccupationWorkService.cancelaction");
      }

      public function removeTimer() : void
      {
         RLog.stub("OccupationWorkService.removeTimer");
      }

      public function addTimer() : void
      {
         RLog.stub("OccupationWorkService.addTimer");
      }

      public function getWorkBonus(param1:int) : void
      {
         RLog.stub("OccupationWorkService.getWorkBonus");
      }

      public function reFreshTimer(param1:int) : void
      {
         RLog.stub("OccupationWorkService.reFreshTimer");
      }

      public function canDoWork(param1:int) : void
      {
         RLog.stub("OccupationWorkService.canDoWork");
      }

      public function setaction(param1:String) : void
      {
         RLog.stub("OccupationWorkService.setaction");
      }

      public function init() : void
      {
         RLog.stub("OccupationWorkService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
