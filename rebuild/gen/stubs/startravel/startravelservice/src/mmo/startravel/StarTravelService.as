package mmo.startravel
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.startravel.*;
   import mmo.interfaces.startravel.IStarTravelService;
   import mmo.interfaces.startravel.data.IStarTravelDate;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for StarTravelService. Module startravel/startravelservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.startravel.IStarTravelService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class StarTravelService extends EventDispatcher implements IStarTravelService
   {
      private var _travelLeftTimes:int = 0;
      private var _travelState:int = 0;
      public function StarTravelService()
      {
         super();
      }

      public function getIntroductionByType(param1:int, param2:Object) : String
      {
         RLog.stub("StarTravelService.getIntroductionByType");
         return "";
      }

      public function getTotalTravelTime() : int
      {
         RLog.stub("StarTravelService.getTotalTravelTime");
         return 0;
      }

      public function get travelLeftTimes() : int
      {
         RLog.stub("StarTravelService.travelLeftTimes");
         return this._travelLeftTimes;
      }

      public function get travelState() : int
      {
         RLog.stub("StarTravelService.travelState");
         return this._travelState;
      }

      public function getNeedMoneyByShipType(param1:int) : int
      {
         RLog.stub("StarTravelService.getNeedMoneyByShipType");
         return 0;
      }

      public function getStarTravelData() : IStarTravelDate
      {
         RLog.stub("StarTravelService.getStarTravelData");
         return null;
      }

      public function showActivityPanel() : void
      {
         RLog.stub("StarTravelService.showActivityPanel");
      }

      public function init() : void
      {
         RLog.stub("StarTravelService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
