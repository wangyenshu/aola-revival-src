package mmo.taskservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.task.*;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.data.TaskDefine;
   import mmo.interfaces.task.data.TaskStarter;
   import mmo.interfaces.task.data.UserTask;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TaskService. Module task/taskservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.task.ITaskService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TaskService extends EventDispatcher implements ITaskService
   {
      public function TaskService()
      {
         super();
      }

      public function getTaskSceneByTaskId(param1:int) : String
      {
         RLog.stub("TaskService.getTaskSceneByTaskId");
         return "";
      }

      public function isTaskCanStart(param1:int) : Boolean
      {
         RLog.stub("TaskService.isTaskCanStart");
         return false;
      }

      public function isTaskNotStart(param1:int) : Boolean
      {
         RLog.stub("TaskService.isTaskNotStart");
         return false;
      }

      public function getUserTask(param1:int) : UserTask
      {
         RLog.stub("TaskService.getUserTask");
         return null;
      }

      public function getTaskDoingStep(param1:int) : int
      {
         RLog.stub("TaskService.getTaskDoingStep");
         return 0;
      }

      public function getNewTaskOrder() : Array
      {
         RLog.stub("TaskService.getNewTaskOrder");
         return [];
      }

      public function isUserTaskFinish(param1:int) : Boolean
      {
         RLog.stub("TaskService.isUserTaskFinish");
         return false;
      }

      public function getTaskDefinesByType(param1:int) : Array
      {
         RLog.stub("TaskService.getTaskDefinesByType");
         return [];
      }

      public function getOtherTaskOrder() : Array
      {
         RLog.stub("TaskService.getOtherTaskOrder");
         return [];
      }

      public function getTaskStartersByType(param1:int) : Array
      {
         RLog.stub("TaskService.getTaskStartersByType");
         return [];
      }

      public function isPreTaskFinish(param1:int) : Boolean
      {
         RLog.stub("TaskService.isPreTaskFinish");
         return false;
      }

      public function getDoingTaskIds() : Array
      {
         RLog.stub("TaskService.getDoingTaskIds");
         return [];
      }

      public function getTaskStarter(param1:int) : TaskStarter
      {
         RLog.stub("TaskService.getTaskStarter");
         return null;
      }

      public function getUserTaskStartersByArea(param1:int) : Array
      {
         RLog.stub("TaskService.getUserTaskStartersByArea");
         return [];
      }

      public function getTaskDefine(param1:int) : TaskDefine
      {
         RLog.stub("TaskService.getTaskDefine");
         return null;
      }

      public function getFbTaskOrder() : Array
      {
         RLog.stub("TaskService.getFbTaskOrder");
         return [];
      }

      public function checkTaskAtFinishStep(param1:int) : Boolean
      {
         RLog.stub("TaskService.checkTaskAtFinishStep");
         return false;
      }

      public function clientSetData(param1:int, param2:int) : Boolean
      {
         RLog.stub("TaskService.clientSetData");
         return false;
      }

      public function getMainTaskOrder() : Array
      {
         RLog.stub("TaskService.getMainTaskOrder");
         return [];
      }

      public function dropTask(param1:int) : void
      {
         RLog.stub("TaskService.dropTask");
      }

      public function isUserTaskDoing(param1:int) : Boolean
      {
         RLog.stub("TaskService.isUserTaskDoing");
         return false;
      }

      public function getNewAndDoingUserTaskStarters() : Array
      {
         RLog.stub("TaskService.getNewAndDoingUserTaskStarters");
         return [];
      }

      public function getTaskStarters() : Object
      {
         RLog.stub("TaskService.getTaskStarters");
         return {};
      }

      public function init() : void
      {
         RLog.stub("TaskService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
