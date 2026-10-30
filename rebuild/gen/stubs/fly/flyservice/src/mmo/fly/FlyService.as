package mmo.fly
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fly.*;
   import mmo.interfaces.fly.IFlyService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FlyService. Module fly/flyservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fly.IFlyService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FlyService extends EventDispatcher implements IFlyService
   {
      public function FlyService()
      {
         super();
      }

      public function fly() : void
      {
         RLog.stub("FlyService.fly");
      }

      public function banFly(param1:String = null) : void
      {
         RLog.stub("FlyService.banFly");
      }

      public function cancelBan() : void
      {
         RLog.stub("FlyService.cancelBan");
      }

      public function isWearingFlySuit() : Boolean
      {
         RLog.stub("FlyService.isWearingFlySuit");
         return false;
      }

      public function isFlying(param1:String = null, param2:Boolean = true) : Boolean
      {
         RLog.stub("FlyService.isFlying");
         return false;
      }

      public function land(param1:Boolean = false) : void
      {
         RLog.stub("FlyService.land");
      }

      public function init() : void
      {
         RLog.stub("FlyService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
