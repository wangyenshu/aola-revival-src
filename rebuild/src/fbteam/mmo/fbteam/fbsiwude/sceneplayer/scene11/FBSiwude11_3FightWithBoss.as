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
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   
   public class FBSiwude11_3FightWithBoss extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var general:SimpleButton = null;
      
      private var ipf:IPetFight = null;
      
      public function FBSiwude11_3FightWithBoss()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
         this.general = this.sceneInfo.scene.container.getChildByName("btn_general") as SimpleButton;
         this.general.addEventListener(MouseEvent.CLICK,this.onFight);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
      }
      
      private function onFight(param1:MouseEvent) : void
      {
         this.fight();
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if("fbsiwude11_step4_end" == param1.params.action)
         {
            this.fight();
         }
      }
      
      private function fight() : void
      {
         this.ipf.fightInCopy(2);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(Boolean(param1.isWin) && param1.id == 2)
         {
            this.movieFinish(-1,this.type);
         }
      }
      
      public function dispose() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         this.general.removeEventListener(MouseEvent.CLICK,this.onFight);
      }
   }
}

