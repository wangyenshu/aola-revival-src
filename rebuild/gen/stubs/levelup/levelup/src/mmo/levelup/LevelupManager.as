package mmo.levelup
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.fight.*;
   import mmo.interfaces.pet.fight.ILevelUp;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for LevelUpService. Module levelup/levelup.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.fight.ILevelUp) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class LevelupManager extends EventDispatcher implements ILevelUp
   {
      public function LevelupManager()
      {
         super();
      }

      public function showGainExp() : void
      {
         RLog.stub("LevelupManager.showGainExp");
      }

      public function showLevelUp() : void
      {
         RLog.stub("LevelupManager.showLevelUp");
      }

      public function showExpPanelAfterFight(param1:Boolean, param2:Boolean = false) : void
      {
         RLog.stub("LevelupManager.showExpPanelAfterFight");
      }

      public function clearDataWhileAuto() : void
      {
         RLog.stub("LevelupManager.clearDataWhileAuto");
      }

      public function showReplaceSkill() : void
      {
         RLog.stub("LevelupManager.showReplaceSkill");
      }

      public function dispose() : void
      {
         RLog.stub("LevelupManager.dispose");
      }

      public function init() : void
      {
         RLog.stub("LevelupManager.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
