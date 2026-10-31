package mmo.fbteam.fbaixi.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi4_1BossAppear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public static const NAME_BOSS:String = "mc_boss";
      
      private var bossComeOutMovie:MovieClip = null;
      
      public function FBAixi4_1BossAppear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.showBossComeOut();
      }
      
      private function showBossComeOut() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.BossComeOut") as Class;
         this.bossComeOutMovie = new _loc1_() as MovieClip;
         this.bossComeOutMovie.name = NAME_BOSS;
         this.bossComeOutMovie.x = 380;
         this.bossComeOutMovie.y = 350;
         this.bossComeOutMovie.addFrameScript(this.bossComeOutMovie.totalFrames - 1,this.stopBossCome);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.bossComeOutMovie);
      }
      
      private function stopBossCome() : void
      {
         this.bossComeOutMovie.stop();
         this.movieFinish();
      }
      
      public function dispose() : void
      {
      }
   }
}

