package mmo.fbteam.fbaixi.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.*;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi4_3BossFight extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const fightEndData1:Object = {"what":FBAixi_Scene4TempTypes.FBAIXI4_3BOSSFIGHT};
      
      private var boss:MovieClip = null;
      
      private var ipf:IPetFight = null;
      
      private var endCount:int = 0;
      
      private var taskNpcService:ITaskNpcService = null;
      
      public function FBAixi4_3BossFight()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.init();
      }
      
      private function init() : void
      {
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         this.boss = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName(FBAixi4_1BossAppear.NAME_BOSS) as MovieClip;
         this.boss.addEventListener(MouseEvent.CLICK,this.onClickBoss);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
      }
      
      private function onClickBoss(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.taskNpcService.showNpcPanelFreely("fbaixi4_talk1",602,1);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(Boolean(param1.isWin) && param1.id == 1)
         {
            this.boss.removeEventListener(MouseEvent.CLICK,this.onClickBoss);
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
            this.boss.mouseChildren = false;
            this.boss.mouseEnabled = false;
            FBTeamSynchronizedClient.notifyBack(this.fightEndData1);
         }
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         var _loc2_:String = param1.params.action as String;
         if(_loc2_ == "fbaixi4_talk1_end")
         {
            this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
            this.ipf.fightInCopy(1);
         }
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBAixi_Scene4TempTypes.FBAIXI4_3BOSSFIGHT == param1.what)
         {
            this.endCountAdd();
         }
      }
      
      private function endCountAdd() : void
      {
         ++this.endCount;
         if(TeamHelper.checkCount(this.endCount))
         {
            DisplayUtil.stopAndRemove(this.boss);
            this.movieFinish();
         }
      }
      
      public function dispose() : void
      {
         this.boss.removeEventListener(MouseEvent.CLICK,this.onClickBoss);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
      }
   }
}

