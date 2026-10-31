package mmo.fbteam.fbsiwude.sceneplayer.scene11
{
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
   
   public class FBSiwude11_2FightWithLittle extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var btnNpc:SimpleButton = null;
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var ipf:IPetFight = null;
      
      public function FBSiwude11_2FightWithLittle()
      {
         super();
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnNpc = this.sceneInfo.scene.container.getChildByName("btn_general") as SimpleButton;
         this.btnNpc.addEventListener(MouseEvent.CLICK,this.onClick);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.taskNpcService.showNpcPanelFreely("fbsiwude11_step2",160);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if("fbsiwude11_step2_end" == param1.params.action)
         {
            this.fight();
         }
      }
      
      private function fight() : *
      {
         this.ipf.fightInCopy(1);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:int = int(param1.id);
         if(Boolean(param1.isWin) && 1 == _loc2_)
         {
            this.finishStep();
         }
      }
      
      public function dispose() : void
      {
         this.btnNpc.removeEventListener(MouseEvent.CLICK,this.onClick);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
   }
}

