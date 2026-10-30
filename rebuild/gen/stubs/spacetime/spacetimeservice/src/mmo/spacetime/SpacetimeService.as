package mmo.spacetime
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.spacetime.*;
   import mmo.interfaces.spacetime.ISpacetimeService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SpacetimeService. Module spacetime/spacetimeservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.spacetime.ISpacetimeService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SpacetimeService extends EventDispatcher implements ISpacetimeService
   {
      private var _liveNpcCount:*;
      public function SpacetimeService()
      {
         super();
      }

      public function getCurrentUserTeamFloor() : int
      {
         RLog.stub("SpacetimeService.getCurrentUserTeamFloor");
         return 0;
      }

      public function updataInfo(param1:String, param2:Function = null, ... rest) : void
      {
         RLog.stub("SpacetimeService.updataInfo");
      }

      public function getMaxUserFloor() : int
      {
         RLog.stub("SpacetimeService.getMaxUserFloor");
         return 0;
      }

      public function set liveNpcCount(param1:int) : void
      {
         this._liveNpcCount = param1;
      }

      public function getMaxUserTeamFloor() : int
      {
         RLog.stub("SpacetimeService.getMaxUserTeamFloor");
         return 0;
      }

      public function get liveNpcCount() : int
      {
         RLog.stub("SpacetimeService.liveNpcCount");
         return this._liveNpcCount;
      }

      public function showSelectPanel() : void
      {
         RLog.stub("SpacetimeService.showSelectPanel");
      }

      public function getCurrentUserFloor() : int
      {
         RLog.stub("SpacetimeService.getCurrentUserFloor");
         return 0;
      }

      public function init() : void
      {
         RLog.stub("SpacetimeService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
