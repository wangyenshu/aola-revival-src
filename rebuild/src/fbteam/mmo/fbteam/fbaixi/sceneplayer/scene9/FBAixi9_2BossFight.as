package mmo.fbteam.fbaixi.sceneplayer.scene9
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi9_2BossFight extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var bossMovie:MovieClip;
      
      private var talkEndData:Object = {"what":FBAixi_Scene9TempTypes.FBAIXI9_2BOSSFIGHT};
      
      private var fightEndData:Object = {"what":FBAixi_Scene9TempTypes.FBAIXI9_2BOSSFIGHT};
      
      private var tryFinishCounter:int = 0;
      
      public function FBAixi9_2BossFight()
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
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         this.bossMovie = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("labeier") as MovieClip;
         this.bossMovie.addEventListener(MouseEvent.CLICK,this.showBossFightTalk);
         this.bossMovie.buttonMode = true;
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
      }
      
      private function showBossFightTalk(param1:MouseEvent) : void
      {
         var _loc2_:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         _loc2_.showNpcPanelFreely("fbaixi9_talk1",86);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         switch(param1.params.action)
         {
            case "fightwithla":
               FBTeamSynchronizedClient.notifyBack(this.talkEndData);
               this.fightWithBoss();
         }
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(FBAixi_Scene9TempTypes.FBAIXI9_2BOSSFIGHT == param1.what)
         {
            this.removeAndAddListener();
         }
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(FBAixi_Scene9TempTypes.FBAIXI9_2BOSSFIGHT == param1.what)
         {
            this.tryFinish();
         }
      }
      
      private function removeAndAddListener() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this.bossMovie.removeEventListener(MouseEvent.CLICK,this.showBossFightTalk);
         this.bossMovie.addEventListener(MouseEvent.CLICK,this.onClickBoss);
      }
      
      private function onClickBoss(param1:MouseEvent) : void
      {
         this.fightWithBoss();
      }
      
      private function fightWithBoss() : void
      {
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc1_.fightInCopy(1);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(10999 == param1.raceId || 120999 == param1.raceId)
         {
            if(param1.isWin)
            {
               CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
               this.bossMovie.removeEventListener(MouseEvent.CLICK,this.onClickBoss);
               this.bossMovie.buttonMode = false;
               FBTeamSynchronizedClient.finishBack(this.fightEndData);
            }
         }
      }
      
      private function tryFinish() : void
      {
         ++this.tryFinishCounter;
         if(TeamHelper.checkCount(this.tryFinishCounter))
         {
            this.movieFinish();
            this.tryFinishCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         this.bossMovie.removeEventListener(MouseEvent.CLICK,this.onClickBoss);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this.bossMovie.removeEventListener(MouseEvent.CLICK,this.showBossFightTalk);
      }
   }
}

