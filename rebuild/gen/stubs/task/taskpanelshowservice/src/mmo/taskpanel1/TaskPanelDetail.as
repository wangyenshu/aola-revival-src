package mmo.taskpanel1
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IShowTaskPanel;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TaskPanelDetail. Module task/taskpanelshowservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.IShowTaskPanel) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TaskPanelDetail extends EventDispatcher implements IShowTaskPanel
   {
      public function TaskPanelDetail()
      {
         super();
      }

      public function showTaskPanel(param1:int) : void
      {
         RLog.stub("TaskPanelDetail.showTaskPanel");
      }

      public function showPanel() : void
      {
         RLog.stub("TaskPanelDetail.showPanel");
      }

   }
}
