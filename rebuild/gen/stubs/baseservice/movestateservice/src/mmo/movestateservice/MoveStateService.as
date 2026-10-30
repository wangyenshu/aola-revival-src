package mmo.movestateservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.movestate.*;
   import mmo.interfaces.movestate.IMoveStateService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MoveStateService. Module baseservice/movestateservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.movestate.IMoveStateService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MoveStateService extends EventDispatcher implements IMoveStateService
   {
      public function MoveStateService()
      {
         super();
      }

      public function setMovingState(param1:String, param2:int = -1, param3:Number = 1) : void
      {
         RLog.stub("MoveStateService.setMovingState");
      }

      public function unRide() : void
      {
         RLog.stub("MoveStateService.unRide");
      }

      public function walk() : void
      {
         RLog.stub("MoveStateService.walk");
      }

      public function fly(param1:int = -1, param2:Number = 1) : void
      {
         RLog.stub("MoveStateService.fly");
      }

      public function ride(param1:int) : void
      {
         RLog.stub("MoveStateService.ride");
      }

      public function init() : void
      {
         RLog.stub("MoveStateService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
