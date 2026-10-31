package mmo.fbteam.fbaixi.sceneplayer.scene9
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi9_1BossAppear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var bossMovie:MovieClip;
      
      public function FBAixi9_1BossAppear()
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
         this.bossMovie = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("labeier") as MovieClip;
         this.bossMovie.addFrameScript(this.bossMovie.totalFrames - 1,this.stopBossAppear);
         this.bossMovie.gotoAndPlay(2);
      }
      
      private function stopBossAppear() : void
      {
         this.bossMovie.stop();
         this.movieFinish();
      }
      
      public function dispose() : void
      {
      }
   }
}

