package mmo.fbteam.fbsiwude.sceneplayer.scene06
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   
   public class SiwudePlayer6_1Fight extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var btnGuard:MovieClip;
      
      private var door:SimpleButton;
      
      private var tasknpcService:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      
      public function SiwudePlayer6_1Fight()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.door = this.sceneInfo.scene.backGround.getChildByName("fbsiwude6_door") as SimpleButton;
         this.door.visible = false;
         this.btnGuard = this.sceneInfo.scene.backGround.getChildByName("btn_guard") as MovieClip;
         this.btnGuard.addEventListener(MouseEvent.CLICK,this.onClickGuard);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         var _loc2_:String = param1.params.action as String;
         if(_loc2_ == "fbsiwude6_beforefight_0_end")
         {
            this.fight();
         }
      }
      
      private function onClickGuard(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.tasknpcService.showNpcPanelFreely("fbsiwude6_beforefight_0",162);
      }
      
      private function fight() : void
      {
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc1_.fightInCopy(1);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(Boolean(param1.isWin) && param1.id == 1)
         {
            this.finishStep();
         }
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this.btnGuard.removeEventListener(MouseEvent.CLICK,this.onClickGuard);
      }
   }
}

