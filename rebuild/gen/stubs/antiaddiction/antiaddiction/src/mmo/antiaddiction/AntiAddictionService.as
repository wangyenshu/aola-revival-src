package mmo.antiaddiction
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.antiaddiction.*;
   import mmo.interfaces.antiaddiction.IAntiAddiction;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for AntiAddictionService. Module antiaddiction/antiaddiction.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.antiaddiction.IAntiAddiction) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class AntiAddictionService extends EventDispatcher implements IAntiAddiction
   {
      public function AntiAddictionService()
      {
         super();
      }

      public function getAvailableTime() : int
      {
         RLog.stub("AntiAddictionService.getAvailableTime");
         return 0;
      }

      public function start(param1:DisplayObject) : void
      {
         RLog.stub("AntiAddictionService.start");
      }

      public function isOverHalfTime() : Boolean
      {
         RLog.stub("AntiAddictionService.isOverHalfTime");
         return false;
      }

      public function pause() : void
      {
         RLog.stub("AntiAddictionService.pause");
      }

      public function getLoginTime() : int
      {
         RLog.stub("AntiAddictionService.getLoginTime");
         return 0;
      }

      public function resume() : void
      {
         RLog.stub("AntiAddictionService.resume");
      }

      public function isHoliday() : Boolean
      {
         RLog.stub("AntiAddictionService.isHoliday");
         return false;
      }

      public function init() : void
      {
         RLog.stub("AntiAddictionService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
