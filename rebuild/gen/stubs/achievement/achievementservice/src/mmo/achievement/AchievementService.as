package mmo.achievement
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.achievement.*;
   import mmo.interfaces.achievement.IAchievementService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for AchievementService. Module achievement/achievementservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.achievement.IAchievementService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class AchievementService extends EventDispatcher implements IAchievementService
   {
      public function AchievementService()
      {
         super();
      }

      public function showPanel(param1:int) : void
      {
         RLog.stub("AchievementService.showPanel");
      }

      public function init() : void
      {
         RLog.stub("AchievementService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
