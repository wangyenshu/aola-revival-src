package mmo.taskservice
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.data.TaskDefine;
   import mmo.interfaces.task.data.TaskStarter;
   import mmo.interfaces.task.data.TaskStepType;
   import mmo.interfaces.task.data.UserTask;
   import mmo.interfaces.task.data.UserTaskStarter;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;

   /**
    * REBUILT task/taskservice (ServiceConfig "TaskService", ITaskService).
    * The January 2013 module is lost; this follows the later copy's
    * structure: the definitions come from task/taskdefines
    * (mmo.taskdefines.TaskDefines: defines, starters), the player's tasks
    * from the server (TaskClient 10-0, then 10-1 updates), and TaskEvent
    * carries everything to the rest of the game: ON_CLIENT_STEP and
    * ON_CLIENT_START from NPC conversations and task scripts go to the
    * server; ON_USER_TASK_ADD / UPDATE / FINISH / DROP come back. A task
    * finished shows 任务完成, as in the screenshots of December 2011.
    */
   public class TaskService extends EventDispatcher implements ITaskService
   {
      /** 10-1 types; the 2013 constants are lost (the rebuilt server uses the same). */
      public static const TYPE_UPDATE:int = 0;
      public static const TYPE_ADD:int = 1;
      public static const TYPE_FINISH:int = 2;
      public static const TYPE_ADD_FINISH:int = 3;
      public static const TYPE_RESET:int = 4;
      public static const TYPE_DROP:int = 5;

      private var userTasks:Object = {};
      private var defines:Object = {};
      private var starters:Object = {};
      private var scenes:Object = {};
      private var _ready:Boolean;
      private var inited:Boolean;

      public function TaskService()
      {
         super();
      }

      public function get ready():Boolean
      {
         return _ready;
      }

      public function init():void
      {
         SocketClient.instance.addEventListener(TaskClient.onTaskUpdate, onTaskUpdate);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_CLIENT_STEP, onClientStepEvent);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_CLIENT_START, onClientStartEvent);
         SimpleCustomLoader.loadSingleResource("task/taskdefines", "mmo.taskdefines.TaskDefines", LoadingSpriteType.NONE, "",
            function(o:Object):void { onDefines(); });
      }

      private function onDefines():void
      {
         try
         {
            var c:Object = getDefinitionByName("mmo.taskdefines.TaskDefines");
            defines = c.defines;
            starters = c.starters;
            scenes = c.scenes || {};
         }
         catch (e:Error)
         {
            RLog.error("taskservice: task/taskdefines", e);
         }
         SocketClient.instance.addEventListener(TaskClient.cmdInitTasks, onInitTasks);
         TaskClient.instance.initTasks();
      }

      private function onInitTasks(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(TaskClient.cmdInitTasks, onInitTasks);
         var list:Array = e.params.t as Array || [];
         for each (var row:Object in list)
         {
            for each (var one:String in String(row.s).split("/"))
            {
               var a:Array = one.split(",");
               var t:UserTask = new UserTask();
               t.taskId = int(a[0]);
               t.state = int(a[1]);
               t.extData = a.length > 2 ? int(a[2]) : 0;
               t.acceptDate = Number(row.a);
               t.finishDate = Number(row.f);
               userTasks[t.taskId] = t;
            }
         }
         _ready = true;
         RLog.log("taskservice: " + list.length + " tasks; doing " + getDoingTaskIds().join(","));
         if (!inited)
         {
            inited = true;
            dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
         }
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_GET_TASKS, {}));
      }

      private function onTaskUpdate(e:SocketClientEvent):void
      {
         var t:UserTask = UserTask.parse(e.params.t);
         var ty:int = int(e.params.ty);
         RLog.log("taskservice: task " + t.taskId + " state " + t.state + " (" + ty + ")");
         switch (ty)
         {
            case TYPE_UPDATE:
               userTasks[t.taskId] = t;
               fire(TaskEvent.ON_USER_TASK_UPDATE, t);
               break;
            case TYPE_ADD:
               userTasks[t.taskId] = t;
               fire(TaskEvent.ON_USER_TASK_ADD, t);
               break;
            case TYPE_FINISH:
            case TYPE_ADD_FINISH:
               userTasks[t.taskId] = t;
               fire(TaskEvent.ON_USER_TASK_FINISH, t);
               var d:TaskDefine = defines[t.taskId] as TaskDefine;
               if (d != null && d.type == 0) showFinished();
               break;
            case TYPE_RESET:
               delete userTasks[t.taskId];
               fire(TaskEvent.ON_TASK_RESET, t);
               break;
            case TYPE_DROP:
               userTasks[t.taskId] = t;
               dropSteps(t.taskId);
               fire(TaskEvent.ON_USER_TASK_DROP, t);
               break;
         }
      }

      private static function fire(type:String, t:UserTask):void
      {
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(type, {t: t}));
      }

      private function dropSteps(id:int):void
      {
         var d:TaskDefine = defines[id] as TaskDefine;
         if (d == null || d.extData == "") return;
         for each (var s:String in d.extData.split(",")) delete userTasks[int(s)];
      }

      private function onClientStepEvent(e:TaskEvent):void
      {
         var id:int = int(e.params.taskId);
         if (isUserTaskDoing(id)) TaskClient.instance.clientStep(id, TaskStepType.CLIENT);
      }

      private function onClientStartEvent(e:TaskEvent):void
      {
         var id:int = int(e.params.taskId);
         if (isTaskCanStart(id)) TaskClient.instance.clientStart(id, TaskStepType.CLIENT);
      }

      /** 任务完成: the big words of the December 2011 screenshots, drawn. */
      private function showFinished():void
      {
         var top:Sprite = LayerManager.getBaseTop();
         if (top == null) return;
         var s:Sprite = new Sprite();
         s.mouseEnabled = s.mouseChildren = false;
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("黑体", 64, 0xFFE95C, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.text = "任务完成";
         t.filters = [new GlowFilter(0x1A4E9C, 1, 8, 8, 12), new GlowFilter(0xFFFFFF, 1, 14, 14, 3), new DropShadowFilter(4, 90, 0x000000, 0.5, 6, 6)];
         t.x = -t.width / 2;
         t.y = -t.height / 2;
         s.addChild(t);
         s.x = 480;
         s.y = 230;
         s.scaleX = s.scaleY = 0.3;
         top.addChild(s);
         var frame:int = 0;
         s.addEventListener(Event.ENTER_FRAME, function(e:Event):void
         {
            frame++;
            if (frame <= 8) s.scaleX = s.scaleY = 0.3 + 0.8 * frame / 8;
            else if (frame <= 12) s.scaleX = s.scaleY = 1.1 - 0.1 * (frame - 8) / 4;
            else if (frame > 60) s.alpha = Math.max(0, 1 - (frame - 60) / 15);
            if (frame > 75)
            {
               s.removeEventListener(Event.ENTER_FRAME, arguments.callee);
               if (s.parent) s.parent.removeChild(s);
            }
         });
      }

      // ---------------------------------------------------------------- ITaskService

      public function getTaskSceneByTaskId(id:int):String
      {
         return scenes[id] != null ? String(scenes[id]) : "";
      }

      public function isTaskCanStart(id:int):Boolean
      {
         return starters[id] != null && isPreTaskFinish(id) && isTaskNotStart(id);
      }

      public function isTaskNotStart(id:int):Boolean
      {
         var t:UserTask = getUserTask(id);
         return t == null || t.isDrop();
      }

      public function getUserTask(id:int):UserTask
      {
         return userTasks[id] as UserTask;
      }

      public function getTaskDoingStep(id:int):int
      {
         var d:TaskDefine = defines[id] as TaskDefine;
         if (d == null || d.type != 0) return -1;
         for each (var s:String in d.extData.split(","))
         {
            if (isUserTaskDoing(int(s))) return int(s);
         }
         return -1;
      }

      public function getNewTaskOrder():Array { return []; }
      public function getOtherTaskOrder():Array { return []; }
      public function getFbTaskOrder():Array { return []; }

      public function getMainTaskOrder():Array
      {
         var ids:Array = [];
         for (var k:String in starters) ids.push(int(k));
         return ids.sort(Array.NUMERIC);
      }

      public function isUserTaskFinish(id:int):Boolean
      {
         var t:UserTask = getUserTask(id);
         return t != null && t.isFinish();
      }

      public function isUserTaskDoing(id:int):Boolean
      {
         var t:UserTask = getUserTask(id);
         return t != null && t.isDoing();
      }

      public function getTaskDefinesByType(type:int):Array
      {
         var out:Array = [];
         for each (var d:TaskDefine in defines) if (d.type == type) out.push(d.clone());
         return out;
      }

      public function getTaskStartersByType(type:int):Array
      {
         var out:Array = [];
         for each (var s:TaskStarter in starters) if (s.taskDefine.type == type) out.push(s.clone());
         return out;
      }

      public function isPreTaskFinish(id:int):Boolean
      {
         var s:TaskStarter = getTaskStarter(id);
         if (s == null || s.preTask == null) return true;
         for each (var p:* in s.preTask) if (!isUserTaskFinish(int(p))) return false;
         return true;
      }

      public function getDoingTaskIds():Array
      {
         var out:Array = [];
         for (var k:String in starters) if (isUserTaskDoing(int(k))) out.push(int(k));
         return out.sort(Array.NUMERIC);
      }

      /** The starter of a task, or of the task a step belongs to. */
      public function getTaskStarter(id:int):TaskStarter
      {
         var s:TaskStarter = starters[id] as TaskStarter;
         if (s == null)
         {
            for (var k:String in defines)
            {
               var d:TaskDefine = defines[k] as TaskDefine;
               if (d.type == 0 && ("," + d.extData + ",").indexOf("," + id + ",") >= 0)
               {
                  s = starters[k] as TaskStarter;
                  break;
               }
            }
         }
         return s ? s.clone() : null;
      }

      public function getUserTaskStartersByArea(area:int):Array
      {
         var out:Array = [];
         for (var k:String in starters)
         {
            var s:TaskStarter = starters[k] as TaskStarter;
            if (s.area == area) out.push(new UserTaskStarter(getUserTask(int(k)), s.clone()));
         }
         return out;
      }

      public function getTaskDefine(id:int):TaskDefine
      {
         var d:TaskDefine = defines[id] as TaskDefine;
         return d ? d.clone() : null;
      }

      public function checkTaskAtFinishStep(id:int):Boolean
      {
         var d:TaskDefine = defines[id] as TaskDefine;
         if (d == null || d.type != 0) return false;
         var steps:Array = d.extData.split(",");
         return isUserTaskDoing(int(steps[steps.length - 1]));
      }

      public function clientSetData(id:int, ed:int):Boolean
      {
         if (!isUserTaskDoing(id)) return false;
         TaskClient.instance.clientSetData(id, ed);
         return true;
      }

      public function dropTask(id:int):void
      {
         TaskClient.instance.dropTask(id);
      }

      public function getNewAndDoingUserTaskStarters():Array
      {
         var out:Array = [];
         for (var k:String in starters)
         {
            var id:int = int(k);
            if (isUserTaskDoing(id) || isTaskCanStart(id)) out.push(new UserTaskStarter(getUserTask(id), TaskStarter(starters[k]).clone()));
         }
         return out;
      }

      public function getTaskStarters():Object
      {
         var o:Object = {};
         for (var k:String in starters) o[k] = starters[k];
         return o;
      }
   }
}
