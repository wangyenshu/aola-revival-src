package mmo.fbteam.fbsiwude.sceneplayer.scene05
{
   import flash.display.SimpleButton;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class SiwudePlayer5_1FightAnt extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var antArray:Array = new Array();
      
      private var scene:SceneBase;
      
      public function SiwudePlayer5_1FightAnt()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc5_:SimpleButton = null;
         this.type = param1;
         this.scene = SceneManager.getInstance().loadedSceneInfo.scene;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightAntEnd);
         var _loc4_:int = 0;
         while(_loc4_ < 4)
         {
            _loc5_ = this.scene.container.getChildByName("ant" + (_loc4_ + 1).toString()) as SimpleButton;
            this.antArray.push(_loc5_);
            ClickAndHitHelper.instance.registerTarget(_loc5_);
            _loc5_.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.clickAntAction);
            _loc4_++;
         }
      }
      
      private function clickAntAction(param1:ClickAndHitEvent) : void
      {
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(1);
      }
      
      private function fightAntEnd(param1:PetFightEvent) : void
      {
         if(param1.params.id != 1)
         {
            return;
         }
         if(param1.params.isWin)
         {
            this.removeListen();
            this.movieFinish(-1,this.type);
         }
      }
      
      private function removeListen() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.antArray.length)
         {
            (this.antArray[_loc1_] as SimpleButton).removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.clickAntAction);
            if(this.scene.container.contains(this.antArray[_loc1_]))
            {
               DisplayUtil.stopAndRemove(this.antArray[_loc1_]);
            }
            _loc1_++;
         }
      }
      
      public function dispose() : void
      {
         this.removeListen();
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightAntEnd);
      }
   }
}

