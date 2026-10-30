package mmo.tasknpc
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.geom.Point;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.task.*;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TaskNpcService. Module task/tasknpc.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.task.ITaskNpcService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TaskNpcService extends EventDispatcher implements ITaskNpcService
   {
      public function TaskNpcService()
      {
         super();
      }

      public function showNpcPanel(param1:int, param2:int, param3:String) : void
      {
         RLog.stub("TaskNpcService.showNpcPanel");
      }

      public function removeNpcFromScene(param1:int) : void
      {
         RLog.stub("TaskNpcService.removeNpcFromScene");
      }

      public function showNpcPanelFreelyByXml(param1:XML, param2:int, param3:int = 1) : void
      {
         RLog.stub("TaskNpcService.showNpcPanelFreelyByXml");
      }

      public function getSceneNpcInfo(param1:String) : Array
      {
         RLog.stub("TaskNpcService.getSceneNpcInfo");
         return [];
      }

      public function addSeveralNpcToScene(param1:Array) : void
      {
         RLog.stub("TaskNpcService.addSeveralNpcToScene");
      }

      public function showHelloPanel(param1:int) : void
      {
         RLog.stub("TaskNpcService.showHelloPanel");
      }

      public function getNpcView(param1:int) : DisplayObject
      {
         RLog.stub("TaskNpcService.getNpcView");
         return null;
      }

      public function initNpc() : void
      {
         RLog.stub("TaskNpcService.initNpc");
      }

      public function addNpcInteraction(param1:int, param2:String, param3:String) : void
      {
         RLog.stub("TaskNpcService.addNpcInteraction");
      }

      public function removeNpcInteraction(param1:int, param2:String) : void
      {
         RLog.stub("TaskNpcService.removeNpcInteraction");
      }

      public function changeNpcView(param1:int, param2:int, param3:Point = null) : void
      {
         RLog.stub("TaskNpcService.changeNpcView");
      }

      public function removeSeveralNpcToScene(param1:Array) : void
      {
         RLog.stub("TaskNpcService.removeSeveralNpcToScene");
      }

      public function addNpcToScene(param1:int, param2:int, param3:int, param4:int, param5:int) : void
      {
         RLog.stub("TaskNpcService.addNpcToScene");
      }

      public function showNpcPanelFreely(param1:String, param2:int, param3:int = 1) : void
      {
         RLog.stub("TaskNpcService.showNpcPanelFreely");
      }

      public function showSystemPanel(param1:*) : void
      {
         RLog.stub("TaskNpcService.showSystemPanel");
      }

      public function init() : void
      {
         RLog.stub("TaskNpcService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
