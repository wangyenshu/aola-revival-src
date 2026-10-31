package mmo.fbservice.fbsuolide.fbsceneplayer.scene4
{
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer4_2FightAnubis extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var anubis:SimpleButton = null;
      
      public function SuolidePlayer4_2FightAnubis()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.getPars();
         this.fightWithAnubis();
      }
      
      private function getPars() : void
      {
         this.anubis = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("anubis") as SimpleButton;
         this.anubis.addEventListener(MouseEvent.CLICK,this.onclick);
      }
      
      private function fightWithAnubis() : void
      {
         this.isClicking = true;
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         _loc1_.fightInCopy(1);
      }
      
      private function removeFightListener() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         this.isClicking = false;
      }
      
      private function onEnterFail(param1:PetFightEvent) : void
      {
         this.removeFightListener();
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         this.removeFightListener();
         if(param1.isWin)
         {
            this.movieFinish(-1,this.type);
         }
      }
      
      private function onclick(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         param1.stopImmediatePropagation();
         this.fightWithAnubis();
      }
      
      public function dispose() : void
      {
         this.anubis.removeEventListener(MouseEvent.CLICK,this.onclick);
         this.removeFightListener();
      }
   }
}

