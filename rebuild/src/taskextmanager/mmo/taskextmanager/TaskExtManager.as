package mmo.taskextmanager
{
   import flash.events.EventDispatcher;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
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
    * (TaskEvent.ON_INITED_NPC), and cleared when the scene goes.
    *
    * Which scripts a scene needs: for the 2012 story quests, the scene table
    * the later client keeps in config tconfig (TaskDefines.sceneExts, the
    * 2013 one is lost): an entry loads while one of its taskIds is being
    * done or one of its starterIds can start, as the later TaskExtInfo
    * decides. The rebuilt newbie quest's scripts (TaskDefines.exts) run in
    * every scene while their task is being done and look at the scene
    * themselves. A task that starts in the middle of a scene gets its script
    * at once.
    *
    * A task action said while the scene's scripts are not there yet (between a
    * scene going and its scripts running) is held and said again once they run:
    * a task's mini game says how it went when the scene it came from is back
    * (冰之迷阵, game/brickgame: "Task26_Game_Win" on SCENE_INITED), while the
    * scene's scripts are still loading (the 2013 engine kept the scene and its
    * scripts under the game; here it is entered again).
    */
   public class TaskExtManager extends EventDispatcher implements ITaskExtManager
   {
      private var running:Object = {};
      private var sceneReady:Boolean;
      /** Task actions said before the scene's scripts ran: {params, at}. */
      private var held:Array = [];
      private var replaying:Boolean;
      private static const HELD_MS:int = 20000;

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
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, function(e:TaskEvent):void
         {
            RLog.log("taskext: action " + (e.params ? e.params.action : ""));
            if ((!sceneReady || loading()) && !replaying && e.params != null) held.push({params: e.params, at: getTimer()});
         });
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
         // A rebuilt newbie script goes with its task. A script of the scene
         // table stays until the scene goes, as in the later manager: it may
         // still wait for the reward panel of the task it has just finished
         // (TaskEvent.ON_BONUS_PANEL_CLOSE).
         var id:int = int(e.params.t.taskId);
         for (var k:String in running)
         {
            if (!running[k].scene && int(running[k].task) == id)
            {
               try { ITaskExtService(running[k].svc).clear(); } catch (err:Error) {}
               delete running[k];
            }
         }
         // Tasks that can start now may want their scripts here.
         if (sceneReady) initTask();
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

      private static function sceneExts(scene:String):Array
      {
         try { return getDefinitionByName("mmo.taskdefines.TaskDefines").sceneExts[scene] as Array || []; }
         catch (e:Error) {}
         return [];
      }

      /** The later TaskExtInfo.needInit: one of its tasks is being done, or one it starts can start. */
      private static function needInit(ts:ITaskService, e:Object):Boolean
      {
         for each (var t:int in e.taskIds) if (ts.isUserTaskDoing(t)) return true;
         for each (var s:int in e.starterIds) if (ts.isTaskCanStart(s)) return true;
         return false;
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
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info == null) return;
         for each (var e:Object in sceneExts(info.sceneName))
         {
            if (running[e.file] != null || !needInit(ITaskService(ts), e)) continue;
            var leader:int = int(String(e.file).replace(/\D/g, ""));
            load({file: e.file, cls: e.cls, task: leader, scene: true});
         }
         sayHeld();
      }

      /** A script of the scene still loading. */
      private function loading():Boolean
      {
         for (var k:String in running) if (!running[k].done) return true;
         return false;
      }

      /** The actions held, said again once every script of the scene runs (or could not load). */
      private function sayHeld():void
      {
         if (held.length == 0 || !sceneReady) return;
         for (var k:String in running) if (!running[k].done) return;
         var list:Array = held;
         held = [];
         replaying = true;
         try
         {
            for each (var h:Object in list)
            {
               if (getTimer() - int(h.at) > HELD_MS) continue;
               RLog.log("taskext: action said again " + h.params.action);
               TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_TASK_ACTION, h.params));
            }
         }
         finally
         {
            replaying = false;
         }
      }

      private function load(x:Object):void
      {
         running[x.file] = {task: x.task, scene: x.scene == true, svc: null, done: false};
         var sceneAtStart:Object = SceneManager.getInstance().loadedSceneInfo;
         ResScheduler.getResource(x.file, function(o:*):void
         {
            if (running[x.file] == null || SceneManager.getInstance().loadedSceneInfo != sceneAtStart) return;
            running[x.file].done = true;
            try
            {
               var C:Class = getDefinitionByName(x.cls) as Class;
               var svc:ITaskExtService = new C() as ITaskExtService;
               running[x.file].svc = svc;
               // Its listeners for the scene's start hear it now (SceneManager.catchSceneInited).
               var sm:SceneManager = SceneManager.getInstance();
               sm.catchSceneInited();
               try { svc.init(); }
               finally { sm.releaseSceneInited(); }
               RLog.log("taskext: " + x.cls + " running");
            }
            catch (err:Error)
            {
               RLog.error("taskext " + x.file, err);
            }
            sayHeld();
         }, "", function(e:* = null):void
         {
            RLog.log("taskext: cannot load " + x.file);
            if (running[x.file] != null) running[x.file].done = true;
            sayHeld();
         });
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
