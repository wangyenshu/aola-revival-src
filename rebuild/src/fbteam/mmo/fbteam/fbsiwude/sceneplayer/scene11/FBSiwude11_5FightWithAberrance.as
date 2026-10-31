package mmo.fbteam.fbsiwude.sceneplayer.scene11
{
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.*;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamServiceEvent;
   
   public class FBSiwude11_5FightWithAberrance extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const finishData:Object = {"what":FBSiwude_Scene11TempTypes.FBAIXI11_5SHOWMOVIE_END};
      
      private var general:SimpleButton = null;
      
      private var teamService:ITeamService = null;
      
      private var finishCount:int = 0;
      
      public function FBSiwude11_5FightWithAberrance()
      {
         super();
         this.teamService = ServiceContainer.getService(ITeamService) as ITeamService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.general = this.sceneInfo.scene.container.getChildByName("btn_general") as SimpleButton;
         this.general.addEventListener(MouseEvent.CLICK,this.onFight);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.teamService.addEventListener(TeamServiceEvent.onMemberLeave,this.onMemberLeave);
      }
      
      private function onFight(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.fight();
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if("fbsiwude11_step6_end" == param1.params.action)
         {
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
            this.fight();
         }
      }
      
      private function fight() : void
      {
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc1_.fightInCopy(3);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(Boolean(param1.isWin) && param1.id == 3)
         {
            this.tryFinishStep();
         }
      }
      
      private function tryFinishStep() : void
      {
         this.general.removeEventListener(MouseEvent.CLICK,this.onFight);
         this.general.mouseEnabled = false;
         FBTeamSynchronizedClient.finishBack(this.finishData);
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBSiwude_Scene11TempTypes.FBAIXI11_5SHOWMOVIE_END == param1.what)
         {
            ++this.finishCount;
            this.checkFinish();
         }
      }
      
      private function onMemberLeave(param1:TeamServiceEvent) : void
      {
         this.checkFinish();
      }
      
      private function checkFinish() : void
      {
         if(TeamHelper.checkCount(this.finishCount))
         {
            this.finishStep();
         }
      }
      
      public function dispose() : void
      {
         this.general.removeEventListener(MouseEvent.CLICK,this.onFight);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.teamService.removeEventListener(TeamServiceEvent.onMemberLeave,this.onMemberLeave);
      }
   }
}

