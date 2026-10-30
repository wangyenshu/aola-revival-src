package mmo.taskpanelnew
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.task.*;
   import mmo.interfaces.task.ITaskPanelNewService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TaskPanelNewService. Module task/taskpanelnew.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.task.ITaskPanelNewService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TaskPanelNewService extends EventDispatcher implements ITaskPanelNewService
   {
      public function TaskPanelNewService()
      {
         super();
      }

      public function showPanel() : void
      {
         RLog.stub("TaskPanelNewService.showPanel");
      }

      public function init() : void
      {
         RLog.stub("TaskPanelNewService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
