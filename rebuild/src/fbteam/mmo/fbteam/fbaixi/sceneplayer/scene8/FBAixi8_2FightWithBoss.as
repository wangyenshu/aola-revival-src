package mmo.fbteam.fbaixi.sceneplayer.scene8
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi8_2FightWithBoss extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var mcBoss:MovieClip = null;
      
      public function FBAixi8_2FightWithBoss()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this.initBoss();
      }
      
      private function initBoss() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.BossYou") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         _loc2_.x = 480;
         _loc2_.y = 400;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc2_);
         this.mcBoss = _loc2_;
         this.mcBoss.buttonMode = true;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         this.mcBoss.addEventListener(MouseEvent.CLICK,this.onClickBoss);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if(param1.params.action == "fbaixi8_talk1_end")
         {
            this.tryFightWithBoss();
         }
      }
      
      private function onClickBoss(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.taskNpcService.showNpcPanelFreely("fbaixi8_talk1",84,1);
      }
      
      private function tryFightWithBoss() : void
      {
         this.mcBoss.mouseChildren = false;
         this.mcBoss.mouseEnabled = false;
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc1_.fightInCopy(1);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(param1.isWin)
         {
            this.removeFightEvents();
            DisplayUtil.stopAndRemove(this.mcBoss);
            this.movieFinish();
            return;
         }
         this.mcBoss.mouseChildren = true;
         this.mcBoss.mouseEnabled = true;
      }
      
      private function removeFightEvents() : void
      {
         this.mcBoss.removeEventListener(MouseEvent.CLICK,this.onClickBoss);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      public function dispose() : void
      {
         this.removeFightEvents();
         DisplayUtil.stopAndRemove(this.mcBoss);
      }
   }
}

