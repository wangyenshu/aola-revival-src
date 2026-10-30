package mmo.taskextmanager
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.task.ext.*;
   import mmo.interfaces.task.ext.ITaskExtManager;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TaskExtManager. Module task/taskextmanager.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.task.ext.ITaskExtManager) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TaskExtManager extends EventDispatcher implements ITaskExtManager
   {
      public function TaskExtManager()
      {
         super();
      }

      public function clearTask() : void
      {
         RLog.stub("TaskExtManager.clearTask");
      }

      public function initTask() : void
      {
         RLog.stub("TaskExtManager.initTask");
      }

      public function init() : void
      {
         RLog.stub("TaskExtManager.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
