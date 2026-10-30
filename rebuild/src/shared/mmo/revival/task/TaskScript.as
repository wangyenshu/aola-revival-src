package mmo.revival.task
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.IEventDispatcher;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.material.clothes.UserClothes;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.data.TaskDefine;
   import mmo.interfaces.task.ext.IResourceInitialler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT base of the newbie task scripts (taskext/task135, task140,
    * task150), in the shape the 2013 TaskExtServiceBase runs: made afresh for
    * every scene, init() then dispose(). It keeps the listeners it adds and
    * the NPC conversations it sets, and calls refresh() when the scene is
    * ready and whenever a step of its task starts, so a script only has to
    * say what happens in which scene at which step.
    */
   public class TaskScript implements IResourceInitialler
   {
      protected var tasks:ITaskService;
      protected var npcs:ITaskNpcService;
      protected var taskId:int;
      private var listeners:Array = [];
      private var talkNpcs:Object = {};
      private var timers:Array = [];
      private var shown:Object = {};
      private var disposed:Boolean;

      public function TaskScript(taskId:int)
      {
         this.taskId = taskId;
         tasks = ServiceContainer.getService(ITaskService) as ITaskService;
         npcs = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      }

      public function init():void
      {
         listen(TaskEventDispatcher.instance, TaskEvent.ON_TASK_ACTION, function(e:TaskEvent):void { onAction(String(e.params.action)); });
         listen(TaskEventDispatcher.instance, TaskEvent.ON_USER_TASK_ADD, function(e:TaskEvent):void
         {
            var id:int = int(e.params.t.taskId);
            if (isMyStep(id)) delay(200, refresh);
         });
         refresh();
      }

      public function dispose():void
      {
         disposed = true;
         for each (var l:Array in listeners) IEventDispatcher(l[0]).removeEventListener(l[1], l[2]);
         listeners = [];
         for each (var t:Timer in timers) t.stop();
         timers = [];
         for (var k:String in talkNpcs) setTalk(int(k), null);
      }

      /** What this scene should show for the step being done. */
      protected function refresh():void {}

      protected function onAction(a:String):void {}

      // ---------------------------------------------------------------- helpers

      protected function get scene():String
      {
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         return info ? String(info.sceneName) : "";
      }

      protected function get step():int
      {
         return tasks ? tasks.getTaskDoingStep(taskId) : -1;
      }

      protected function isMyStep(id:int):Boolean
      {
         var d:TaskDefine = tasks ? tasks.getTaskDefine(taskId) : null;
         return id == taskId || (d != null && ("," + d.extData + ",").indexOf("," + id + ",") >= 0);
      }

      /** The step is done (TaskEvent.ON_CLIENT_STEP, as an NPC choice with taskId sends it). */
      protected function finish(stepId:int):void
      {
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP, {taskId: stepId}));
      }

      /** Show a conversation now. */
      protected function say(npcId:int, xml:XML):void
      {
         if (npcs != null) npcs.showNpcPanelFreelyByXml(xml, npcId);
      }

      /**
       * Show a conversation now, once a session for this key: the reminders
       * ("司令官麦哲伦还在指挥中心等你呢！") do not come back in every scene; the
       * NPC keeps the conversation for a click (setTalk).
       */
      protected function sayOnce(key:String, npcId:int, xml:XML):void
      {
         if (said[key]) return;
         said[key] = true;
         say(npcId, xml);
      }

      private static var said:Object = {};

      /** Show a conversation now, once in this scene for this key (it comes back in the next visit). */
      protected function sayHere(key:String, npcId:int, xml:XML):void
      {
         if (shown[key]) return;
         shown[key] = true;
         say(npcId, xml);
      }

      /** While set, a click on the NPC opens this conversation (the NPC shows a "?"). */
      protected function setTalk(npcId:int, xml:XML):void
      {
         if (npcs == null) return;
         try { Object(npcs).setTaskTalk(npcId, xml); } catch (e:Error) { RLog.error("task talk", e); }
         if (xml == null) delete talkNpcs[npcId];
         else talkNpcs[npcId] = true;
      }

      protected function addNpc(npcId:int, viewId:int, x:int, y:int):void
      {
         if (npcs != null && npcs.getNpcView(npcId) == null) npcs.addNpcToScene(npcId, viewId, taskId, x, y);
      }

      protected function go(sceneName:String):void
      {
         delay(50, function():void { SceneManager.getInstance().loadScene(sceneName); });
      }

      protected function listen(target:IEventDispatcher, type:String, fn:Function):void
      {
         target.addEventListener(type, fn);
         listeners.push([target, type, fn]);
      }

      /** PetFightEvent.FIGHT_END {isWin, isCatched, raceId, isEscape}, while this script runs. */
      protected function onFightEnd(fn:Function):void
      {
         listen(CommonEventDispatcher.instance, PetFightEvent.FIGHT_END, function(e:PetFightEvent):void { fn(e.params || {}); });
      }

      protected function delay(ms:int, fn:Function):void
      {
         var t:Timer = new Timer(ms, 1);
         t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
         {
            if (!disposed) fn();
         });
         timers.push(t);
         t.start();
      }

      /**
       * 0, 1 or 2 by the starting outfit the player wears (clothes 126, 71,
       * 92), which picks the version of the task comics, as the later task
       * scripts do (findPlayerColor).
       */
      protected static function color():int
      {
         try
         {
            var info:AvatarInfo = Player(PlayerManager.getInstance().myPlayer).getAvatar();
            for each (var c:UserClothes in info.getClothes())
            {
               if (c.materialId == 126) return 0;
               if (c.materialId == 71) return 1;
               if (c.materialId == 92) return 2;
            }
         }
         catch (e:Error) {}
         return 0;
      }

      /** The wild 亚比 of this race standing in the scene (pet/wildpetservice names them wildpet<n>). */
      protected static function wildPet(raceId:int):DisplayObject
      {
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         var layer:DisplayObjectContainer = info && info.scene ? info.scene.playerLayer : null;
         if (layer == null) return null;
         for (var i:int = 0; i < layer.numChildren; i++)
         {
            var d:DisplayObject = layer.getChildAt(i);
            if (d.name.indexOf("wildpet") == 0 && Object(d).hasOwnProperty("race") && int(Object(d).race) == raceId) return d;
         }
         return null;
      }
   }
}
