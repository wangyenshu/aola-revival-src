package mmo.pet.dataservice
{
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;

   /**
    * REBUILT fallback for a player without 亚比 who is not in the newbie quest
    * (taskext/task135 gives the first 亚比 there): he is offered the three 初始亚比
    * of the species table (兔小子 1, 吉拉 4, 滴滴 7) by HELLO (NPC 1), in the
    * original NPC conversation panel; the choice is sent as PetClient.addPM.
    */
   public class StarterOffer
   {
      private static var data:PetDataService;
      private static var offered:Boolean;
      private static var postponed:Boolean;

      public static function watch(d:PetDataService):void
      {
         data = d;
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onScene);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, onAction);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_GET_TASKS, onScene);
         if (SceneManager.getInstance().loadedSceneInfo) onScene(null);
      }

      private static function onScene(e:* = null):void
      {
         if (offered || data == null || data.getMyPets().length > 0) return;
         // A player in the newbie quest gets the first 亚比 from 麦哲伦 (taskext/task135, step 137).
         var ts:Object = ServiceContainer.getService(ITaskService);
         if (ts == null || (ts.hasOwnProperty("ready") && !ts.ready)) return;
         if (ITaskService(ts).isUserTaskDoing(135)) return;
         // After "我再想想", HELLO asks again in 奥拉广场 only.
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (postponed && (info == null || info.sceneName != SceneManager.DEFAULT_SCENE)) return;
         offered = true;
         try
         {
            var npc:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
            npc.showNpcPanelFreelyByXml(
               <config>
                  <context npcId="1" str="#username#，欢迎来到奥拉星！每一位小奥拉都会有一只亚比伙伴。选一只做你的第一只亚比吧！">
                     <choice str="草系的兔小子" action="revival_starter_1"/>
                     <choice str="火系的吉拉" action="revival_starter_4"/>
                     <choice str="水系的滴滴" action="revival_starter_7"/>
                     <choice str="我再想想" action="revival_starter_later"/>
                  </context>
               </config>, 1);
         }
         catch (err:Error)
         {
            RLog.error("starter offer", err);
            offered = false;
         }
      }

      private static function onAction(e:TaskEvent):void
      {
         var a:String = String(e.params.action);
         if (a.indexOf("revival_starter_") != 0) return;
         if (a == "revival_starter_later")
         {
            offered = false;
            postponed = true;
            return;
         }
         var race:int = int(a.substr("revival_starter_".length));
         if (race > 0 && data.getMyPets().length == 0)
         {
            PetClient.instance.addPM(race, 5);
            SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED, onScene);
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION, onAction);
         }
      }
   }
}
