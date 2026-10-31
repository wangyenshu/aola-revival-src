package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class FBSuolide8_7ExitAppear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var exitsuolide8:MovieClip = null;
      
      public function FBSuolide8_7ExitAppear()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.playExitAppear();
      }
      
      private function getPars() : void
      {
      }
      
      private function playExitAppear() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_exitsuolide8") as Class;
         this.exitsuolide8 = new _loc1_() as MovieClip;
         this.exitsuolide8.alpha = 0;
         this.exitsuolide8.x = 867;
         this.exitsuolide8.y = 161;
         this.exitsuolide8.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.exitsuolide8);
         ClickAndHitHelper.instance.registerTarget(this.exitsuolide8);
         this.exitsuolide8.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         TipsManager.getInstance().addTips(this.exitsuolide8,"通往下一场景");
      }
      
      private function onHitExit(param1:ClickAndHitEvent) : void
      {
         this.exitsuolide8.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         this.finishStep();
         SceneManager.getInstance().loadFB("fbsuolide9","fbsuolide","法老王宫殿",TeamHelper.getTeamKey());
      }
      
      public function dispose() : void
      {
         if(this.exitsuolide8 != null)
         {
            ClickAndHitHelper.instance.remove(this.exitsuolide8);
            this.exitsuolide8.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         }
      }
   }
}

