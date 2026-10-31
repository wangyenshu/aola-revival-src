package mmo.fbteam.fbaixi.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi4_4BossDisappear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var bossGoAwayMovie:MovieClip = null;
      
      public function FBAixi4_4BossDisappear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.showBossGoAway();
      }
      
      private function showBossGoAway() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.BossGoAway") as Class;
         this.bossGoAwayMovie = new _loc1_() as MovieClip;
         this.bossGoAwayMovie.x = 380;
         this.bossGoAwayMovie.y = 350;
         this.bossGoAwayMovie.addFrameScript(this.bossGoAwayMovie.totalFrames - 1,this.onGoAwayEnd);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.bossGoAwayMovie);
      }
      
      private function onGoAwayEnd() : void
      {
         DisplayUtil.stopAndRemove(this.bossGoAwayMovie);
         this.movieFinish();
      }
      
      public function dispose() : void
      {
      }
   }
}

