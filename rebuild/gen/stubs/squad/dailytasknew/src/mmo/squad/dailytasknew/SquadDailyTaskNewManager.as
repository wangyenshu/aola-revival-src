package mmo.squad.dailytasknew
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.squad.*;
   import mmo.interfaces.squad.ISquadDailyTaskNewManager;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SquadDailyTaskNewManager. Module squad/dailytasknew.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.squad.ISquadDailyTaskNewManager) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SquadDailyTaskNewManager extends EventDispatcher implements ISquadDailyTaskNewManager
   {
      public function SquadDailyTaskNewManager()
      {
         super();
      }

      public function finishTaskByMoney() : void
      {
         RLog.stub("SquadDailyTaskNewManager.finishTaskByMoney");
      }

      public function showTaskPanel() : void
      {
         RLog.stub("SquadDailyTaskNewManager.showTaskPanel");
      }

      public function addBossToScene(param1:Boolean = true, param2:int = -1) : void
      {
         RLog.stub("SquadDailyTaskNewManager.addBossToScene");
      }

      public function getTaskBonus() : void
      {
         RLog.stub("SquadDailyTaskNewManager.getTaskBonus");
      }

      public function finishTaskBySendPet(param1:int) : void
      {
         RLog.stub("SquadDailyTaskNewManager.finishTaskBySendPet");
      }

      public function getNewTaskId(param1:int) : void
      {
         RLog.stub("SquadDailyTaskNewManager.getNewTaskId");
      }

      public function init() : void
      {
         RLog.stub("SquadDailyTaskNewManager.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
