package mmo.play.task
{
   import mmo.common.ProgressFullSprite;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.ext.IResourceInitialler;
   import mmo.play.scene.FaceDirectionTypes;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.scene.SceneManager;

   /**
    * LATER class (the live play.swf's mmo.play.task.NewBaseTaskInitialler,
    * decompiled), adapted to the January 2013 runtime: the table-driven quest
    * runner of tasks 2298 and 2314, whose scripts survive only as their 2018
    * uploads. Their conversations name actions "type_task_key[_more…]":
    * "play", "show" and "enter" (a movie, comic or panel of the quest's
    * FILE_DATA), "switch" (a scene), "fight", "finish" (the step), and
    * "starttask"; after each, the NPCs and the conversation the quest's table
    * names for it. Left out, as the 2013 client has no such things: the
    * later quest review (OpenReviewTaskConfig: never reviewing), its bullet
    * comments (ITaskBarrageService) and the statistics log (SundriesClient).
    * The names of the protected members are the later ones: the scripts
    * extend this class.
    */
   public class NewBaseTaskInitialler implements IResourceInitialler
   {
      private static const DEFAULT_X_TASK_ID:String = "x";

      protected var _sceneMgr:SceneManager = SceneManager.getInstance();

      protected var _taskEventDpr:TaskEventDispatcher = TaskEventDispatcher.instance;

      protected var _taskNpcService:ITaskNpcService = ServiceContainer.getService(ServiceNames.TaskNpcService) as ITaskNpcService;

      protected var _taskService:ITaskService = ServiceContainer.getService(ServiceNames.TaskService) as ITaskService;

      protected var _taskhelper:TaskHelper;

      private var _config:ITaskInitiallerConfig;

      private var _startId:int;

      private var _endId:int;

      public function NewBaseTaskInitialler(config:ITaskInitiallerConfig)
      {
         super();
         this._config = config;
         this._taskhelper = new TaskHelper();
         this._taskhelper.setFileRes(this._config.getFileData());
         this._startId = this._config.getStartTaskId();
         this._endId = this._config.getEndTaskId();
      }

      public function init():void
      {
         this._taskEventDpr.addEventListener(TaskEvent.ON_USER_TASK_ADD, this.onTaskAdd);
         this._taskEventDpr.addEventListener(TaskEvent.ON_TASK_ACTION, this.onTaskAction);
         this._taskEventDpr.addEventListener(TaskEvent.ON_BONUS_PANEL_CLOSE, this.onBonusPanelClosed);
         this.initTask();
         this.tryToShowNpcPanel();
      }

      protected function onTaskAdd(e:TaskEvent):void
      {
         ProgressFullSprite.close();
         var id:int = int(e.params.t.taskId);
         if (id == this._startId + 1)
         {
            this.removeAllNpcOnScene();
            this.addManyNpcsByTaskId(id);
         }
         if (id > this._startId && id <= this._endId)
         {
            this.showNpcPanel(this._config.getNpcPanelKeyByTaskId(id));
         }
      }

      protected function onTaskAction(e:TaskEvent):void
      {
         var action:String = String(e.params.action);
         var id:int = int(action.split("_")[1]);
         if (id >= this._startId && id <= this._endId)
         {
            this.doSomeThings(action);
         }
      }

      protected function doSomeThings(action:String, onDoThings:Function = null):void
      {
         var actionArr:Array = action.split("_");
         var startTaskIndex:int = actionArr.indexOf("starttask");
         if (startTaskIndex > 0 && actionArr.length > startTaskIndex + 1)
         {
            actionArr[startTaskIndex + 1] = DEFAULT_X_TASK_ID;
            action = actionArr.join("_");
         }
         var type:String = actionArr[0];
         var taskid:int = int(actionArr[1]);
         var key:String = actionArr[2];
         var callback:Function = function():void
         {
            if (actionArr.length > 4)
            {
               doSomeThings(actionArr[3] + "_" + taskid + "_" + actionArr.slice(4).join("_"), onDoThings);
               return;
            }
            if (actionArr[actionArr.length - 1] == "finish")
            {
               finishTask(taskid);
               if (taskid != _config.getEndTaskId())
               {
                  addManyNpcsByTaskId(taskid + 1);
               }
            }
            else
            {
               showNpcPanel(_config.getNpcPanelKeyByResName(key));
               addManyNpcsByAction(key);
            }
            if (onDoThings != null)
            {
               onDoThings.apply();
            }
         };
         switch (type)
         {
            case "fight":
               this._taskhelper.fight(this._config.getFightHandlerByFightObjectKey(key), callback);
               break;
            case "finish":
               this.finishTask(taskid);
               if (onDoThings != null)
               {
                  onDoThings.apply();
               }
               if (taskid != this._config.getEndTaskId())
               {
                  this.addManyNpcsByTaskId(taskid + 1);
               }
               break;
            case "switch":
               this._taskhelper.switchSceneTo(key, callback);
               break;
            case "log":
               if (actionArr.length >= 4)
               {
                  callback.apply();
               }
               break;
            case "starttask":
               TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_START, {taskId: taskid}));
               if (actionArr.length > 4)
               {
                  callback.apply();
               }
               break;
            default:
               this.removeAllNpcOnScene();
               this._taskhelper.getResAndPlay(type, key, taskid, callback);
         }
      }

      protected function onBonusPanelClosed(e:TaskEvent):void
      {
         if (int(e.params.taskId) == this._startId)
         {
            this._taskEventDpr.removeEventListener(TaskEvent.ON_BONUS_PANEL_CLOSE, this.onBonusPanelClosed);
            if (this._config.isShowFinishPanel())
            {
               this._taskhelper.showTaskFinishPanel();
            }
         }
      }

      private function initTask():void
      {
         var id:int = this._startId;
         if (this._taskService.isUserTaskDoing(this._startId))
         {
            id = int(this._taskService.getTaskDoingStep(this._startId));
         }
         this.addManyNpcsByTaskId(id);
      }

      private function tryToShowNpcPanel():void
      {
         var ext:Object = this._sceneMgr.loadedSceneInfo.extInfo;
         if (ext == null || !ext.hasOwnProperty("taskIdFromTP") || this._startId != ext.taskIdFromTP)
         {
            return;
         }
         if (this._taskService.isTaskCanStart(this._startId))
         {
            this.showNpcPanel(this._config.getNpcPanelKeyByTaskId(this._startId));
         }
      }

      private function forceGoScene(scene:String):void
      {
         var ext:SceneExtInfo = new SceneExtInfo();
         ext.taskIdFromTP = this._startId;
         SceneManager.getInstance().loadScene(scene, "default", true, false, FaceDirectionTypes.FACELEFTDOWN, ext);
      }

      protected function addManyNpcsByAction(key:String):void
      {
         this.addNpcsToScene(this._config.getNpcsAfterAction(key));
      }

      private function addManyNpcsByTaskIdAndCurrScene(id:int, scene:String):void
      {
         this.addNpcsToScene(this._config.getNpcsByTaskIdAndScene(id, scene), id);
      }

      private function addManyNpcsOnlyByTaskId(id:int):void
      {
         this.addNpcsToScene(this._config.getNpcsByTaskId(id), id);
      }

      protected function addManyNpcsByTaskId(id:int):void
      {
         var scene:String = this._sceneMgr.loadedSceneInfo.sceneName;
         if (this._config.getNpcsByTaskIdAndScene(id, scene) != null)
         {
            this.addManyNpcsByTaskIdAndCurrScene(id, scene);
         }
         else
         {
            this.addManyNpcsOnlyByTaskId(id);
         }
      }

      protected function addNpcsToScene(list:Array, taskId:int = -1):void
      {
         if (list == null) return;
         for each (var row:Array in list)
         {
            if (row.length > 2) this.addNpcToScene(row[0], row[1], row[2]);
            else this.addNpcToScene(row[0], row[1]);
         }
      }

      private function addNpcToScene(npcId:int, viewId:int = 1, posIndex:int = 0):void
      {
         var scene:String = this._sceneMgr.loadedSceneInfo.sceneName;
         var where:Object = this._config.getNpcPosByScene(scene, npcId.toString());
         var pos:Object = where ? where[posIndex] : null;
         if (pos == null) return;
         this._taskNpcService.addNpcToScene(npcId, viewId, -1, pos.x, pos.y);
      }

      protected function finishTask(id:int):void
      {
         if (id == this._endId)
         {
            this.removeAllNpcOnScene();
         }
         else
         {
            ProgressFullSprite.show();
            var list:Array = this._config.getNpcsByTaskIdAndScene(id, this._sceneMgr.loadedSceneInfo.sceneName);
            if (list == null)
            {
               list = this._config.getNpcsByTaskId(id);
            }
            this.removeNpcFromScene(list);
         }
         this._taskEventDpr.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP, {taskId: id}));
      }

      protected function removeAllNpcOnScene():void
      {
         this.removeNpcFromScene(this._config.getAllNpc());
      }

      protected function removeNpcFromScene(list:Array):void
      {
         for each (var id:int in list || [])
         {
            this._taskNpcService.removeNpcFromScene(id);
         }
      }

      protected function showNpcPanel(key:String):void
      {
         if (key == null)
         {
            return;
         }
         var parts:Array = key.split("_");
         this._taskNpcService.showNpcPanel(parseInt(parts[0]), parseInt(parts[1]), key.slice(key.indexOf(parts[2])));
      }

      public function dispose():void
      {
         this._taskEventDpr.removeEventListener(TaskEvent.ON_USER_TASK_ADD, this.onTaskAdd);
         this._taskEventDpr.removeEventListener(TaskEvent.ON_TASK_ACTION, this.onTaskAction);
         this._taskEventDpr.removeEventListener(TaskEvent.ON_BONUS_PANEL_CLOSE, this.onBonusPanelClosed);
      }
   }
}
