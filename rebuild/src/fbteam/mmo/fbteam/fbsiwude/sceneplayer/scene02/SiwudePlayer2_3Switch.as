package mmo.fbteam.fbsiwude.sceneplayer.scene02
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class SiwudePlayer2_3Switch extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var mcPit:MovieClip = null;
      
      private var myPlayer:PlayerBase = null;
      
      private var _type:String = null;
      
      public function SiwudePlayer2_3Switch()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.myPlayer = PlayerManager.getInstance().myPlayer;
         this.mcPit = this.sceneInfo.scene.container.getChildByName("mc_pit") as MovieClip;
         this.playMovie();
      }
      
      private function playMovie() : void
      {
         this.mcPit.addFrameScript(this.mcPit.totalFrames - 1,function():void
         {
            mcPit.stop();
            movieFinish(-1,_type);
            loadScene();
         });
         this.mcPit.gotoAndPlay(2);
      }
      
      private function loadScene() : void
      {
         var _loc1_:String = null;
         if(TeamHelper.isCaptain())
         {
            _loc1_ = TeamHelper.getTeamKey();
            SceneManager.getInstance().loadFB("fbsiwude3","fbsiwude","蚁穴下水道",_loc1_);
         }
      }
      
      public function dispose() : void
      {
         this.myPlayer = null;
         this.mcPit = null;
      }
   }
}

