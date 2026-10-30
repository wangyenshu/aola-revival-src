package mmo.taskextmanager
{
   import flash.events.EventDispatcher;
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.ext.ITaskExtManager;
   import mmo.interfaces.task.ext.ITaskExtService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;

   /**
    * REBUILT task/taskextmanager (ServiceConfig "TaskExtManager",
    * ITaskExtManager): runs the task scripts. As in the later copy, a task
    * script is a module taskext/task<id> whose service class (mmo.task<id>.
    * Task<id>Service, an ITaskExtService built on TaskExtServiceBase) is made
    * afresh for every scene, once the scene's NPCs stand
    * (TaskEvent.ON_INITED_NPC), and cleared when the scene goes. The 2013
    * scene-to-script table (config tconfig) is lost; here every script of a
    * task being done runs in every scene and looks at the scene itself
    * (TaskDefines.exts). A task that starts in the middle of a scene gets
    * its script at once.
    */
   public class TaskExtManager extends EventDispatcher implements ITaskExtManager
   {
      private var running:Object = {};
      private var sceneReady:Boolean;

      public function TaskExtManager()
      {
         super();
      }

      public function init():void
      {
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_INITED_NPC, onInitedNpc);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_GET_TASKS, onTasks);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_USER_TASK_ADD, onTasks);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_USER_TASK_FINISH, onTaskFinish);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE, onUnload);
         sceneReady = SceneManager.getInstance().loadedSceneInfo != null && !SceneManager.getInstance().isLoading;
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
         if (sceneReady) initTask();
      }

      private function onInitedNpc(e:TaskEvent):void
      {
         sceneReady = true;
         initTask();
      }

      private function onTasks(e:TaskEvent):void
      {
         if (sceneReady) initTask();
      }

      private function onTaskFinish(e:TaskEvent):void
      {
         // A task that is over takes its script with it.
         var id:int = int(e.params.t.taskId);
         for (var k:String in running)
         {
            if (int(running[k].task) == id)
            {
               try { ITaskExtService(running[k].svc).clear(); } catch (err:Error) {}
               delete running[k];
            }
         }
      }

      private function onUnload(e:SceneManagerEvent):void
      {
         sceneReady = false;
         clearTask();
      }

      private static function exts():Array
      {
         try { return getDefinitionByName("mmo.taskdefines.TaskDefines").exts as Array || []; }
         catch (e:Error) {}
         return [];
      }

      public function initTask():void
      {
         var ts:Object = ServiceContainer.getService(ITaskService);
         if (ts == null || (ts.hasOwnProperty("ready") && !ts.ready)) return;
         for each (var x:Object in exts())
         {
            if (running[x.file] != null) continue;
            if (!ITaskService(ts).isUserTaskDoing(int(x.task))) continue;
            load(x);
         }
      }

      private function load(x:Object):void
      {
         running[x.file] = {task: x.task, svc: null};
         var sceneAtStart:Object = SceneManager.getInstance().loadedSceneInfo;
         ResScheduler.getResource(x.file, function(o:*):void
         {
            if (running[x.file] == null || SceneManager.getInstance().loadedSceneInfo != sceneAtStart) return;
            try
            {
               var C:Class = getDefinitionByName(x.cls) as Class;
               var svc:ITaskExtService = new C() as ITaskExtService;
               running[x.file].svc = svc;
               svc.init();
               RLog.log("taskext: " + x.cls + " running");
            }
            catch (err:Error)
            {
               RLog.error("taskext " + x.file, err);
            }
         }, "", function(e:* = null):void { RLog.log("taskext: cannot load " + x.file); });
      }

      public function clearTask():void
      {
         for (var k:String in running)
         {
            var svc:ITaskExtService = running[k].svc as ITaskExtService;
            if (svc != null)
            {
               try { svc.clear(); } catch (err:Error) { RLog.error("taskext clear " + k, err); }
            }
         }
         running = {};
      }
   }
}
