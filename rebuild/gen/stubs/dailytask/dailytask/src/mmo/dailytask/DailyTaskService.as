package mmo.dailytask
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.dailytask.*;
   import mmo.interfaces.dailytask.IDailyTask;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for DailyTaskService. Module dailytask/dailytask.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.dailytask.IDailyTask) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class DailyTaskService extends EventDispatcher implements IDailyTask
   {
      private var _canCancelNum:int = 0;
      private var _progress:int = 0;
      public function DailyTaskService()
      {
         super();
      }

      public function getDoingTaskId() : int
      {
         RLog.stub("DailyTaskService.getDoingTaskId");
         return 0;
      }

      public function get canCancelNum() : int
      {
         RLog.stub("DailyTaskService.canCancelNum");
         return this._canCancelNum;
      }

      public function getTaskBonus(param1:int) : Object
      {
         RLog.stub("DailyTaskService.getTaskBonus");
         return {};
      }

      public function getTaskName(param1:int) : String
      {
         RLog.stub("DailyTaskService.getTaskName");
         return "";
      }

      public function startTask(param1:int) : void
      {
         RLog.stub("DailyTaskService.startTask");
      }

      public function getTaskDescription(param1:int) : String
      {
         RLog.stub("DailyTaskService.getTaskDescription");
         return "";
      }

      public function getTaskStatus(param1:int) : int
      {
         RLog.stub("DailyTaskService.getTaskStatus");
         return 0;
      }

      public function startFight() : void
      {
         RLog.stub("DailyTaskService.startFight");
      }

      public function doTask(param1:int = -1) : void
      {
         RLog.stub("DailyTaskService.doTask");
      }

      public function get progress() : int
      {
         RLog.stub("DailyTaskService.progress");
         return this._progress;
      }

      public function getTaskDefine(param1:int) : Object
      {
         RLog.stub("DailyTaskService.getTaskDefine");
         return {};
      }

      public function commitTask() : void
      {
         RLog.stub("DailyTaskService.commitTask");
      }

      public function getTaskDefines() : Array
      {
         RLog.stub("DailyTaskService.getTaskDefines");
         return [];
      }

      public function cancelTask() : void
      {
         RLog.stub("DailyTaskService.cancelTask");
      }

      public function init() : void
      {
         RLog.stub("DailyTaskService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
