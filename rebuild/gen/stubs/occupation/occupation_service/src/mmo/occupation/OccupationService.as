package mmo.occupation
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.occupation.*;
   import mmo.interfaces.occupation.IOccupationService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for OccupationService. Module occupation/occupation_service.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.occupation.IOccupationService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class OccupationService extends EventDispatcher implements IOccupationService
   {
      private var _myOccupationInfo:*;
      public function OccupationService()
      {
         super();
      }

      public function isMember(param1:int) : Boolean
      {
         RLog.stub("OccupationService.isMember");
         return false;
      }

      public function showAllOccupationPanel() : void
      {
         RLog.stub("OccupationService.showAllOccupationPanel");
      }

      public function get myOccupationInfo() : Array
      {
         RLog.stub("OccupationService.myOccupationInfo");
         return this._myOccupationInfo as Array;
      }

      public function showOccupationTaskPanel(param1:int) : void
      {
         RLog.stub("OccupationService.showOccupationTaskPanel");
      }

      public function init() : void
      {
         RLog.stub("OccupationService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
