package mmo.tasktransport
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.task.*;
   import mmo.interfaces.task.ITaskTransportService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TaskTransportPanelService. Module task/tasktransportpanel.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.task.ITaskTransportService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TaskTransportService extends EventDispatcher implements ITaskTransportService
   {
      public function TaskTransportService()
      {
         super();
      }

      public function showTransportPanel(param1:String = "maintown2", param2:String = null, param3:Object = null) : *
      {
         RLog.stub("TaskTransportService.showTransportPanel");
         return null;
      }

   }
}
