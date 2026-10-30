package mmo.taskservice
{
   import mmo.framework.comm.SocketClient;

   /**
    * REBUILT. The task commands (TaskExtension), as the later copy of
    * task/taskservice still sends them: 10-0 initTasks, 10-1 onTaskUpdate
    * (pushed), 10-2 clientStep {ti, ty}, 10-3 clientStart {ti, ty}, 10-4
    * dropTask {ti}, 10-5 clientSetData {ti, ed}.
    */
   public class TaskClient
   {
      private static const EXT:String = "TaskExtension";
      public static const cmdInitTasks:String = "10-0";
      public static const onTaskUpdate:String = "10-1";
      private static const cmdClientStep:String = "10-2";
      private static const cmdClientStart:String = "10-3";
      private static const cmdDropTask:String = "10-4";
      private static const cmdClientSetData:String = "10-5";

      private static var _instance:TaskClient;

      public static function get instance():TaskClient
      {
         if (_instance == null) _instance = new TaskClient();
         return _instance;
      }

      private function send(cmd:String, o:Object):void
      {
         SocketClient.instance.sendXtMessage(EXT, cmd, o);
      }

      public function initTasks():void { send(cmdInitTasks, {}); }
      public function clientStep(ti:int, ty:int):void { send(cmdClientStep, {ti: ti, ty: ty}); }
      public function clientStart(ti:int, ty:int):void { send(cmdClientStart, {ti: ti, ty: ty}); }
      public function dropTask(ti:int):void { send(cmdDropTask, {ti: ti}); }
      public function clientSetData(ti:int, ed:int):void { send(cmdClientSetData, {ti: ti, ed: ed}); }
   }
}
