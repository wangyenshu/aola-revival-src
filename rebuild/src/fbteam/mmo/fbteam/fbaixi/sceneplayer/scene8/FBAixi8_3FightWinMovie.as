package mmo.fbteam.fbaixi.sceneplayer.scene8
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi8_3FightWinMovie extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var mc:MovieClip = null;
      
      public function FBAixi8_3FightWinMovie()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.showFightWinMovieClicp();
      }
      
      private function showFightWinMovieClicp() : void
      {
         var cls:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.DropDown") as Class;
         this.mc = new cls() as MovieClip;
         this.mc.addFrameScript(this.mc.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(mc);
            movieFinish();
            loadScene();
         });
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.mc);
      }
      
      private function loadScene() : void
      {
         if(TeamHelper.isCaptain())
         {
            SceneManager.getInstance().loadFB("fbaixi9","fbaixi","风暴核心",TeamHelper.getTeamKey());
         }
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this.mc);
      }
   }
}

