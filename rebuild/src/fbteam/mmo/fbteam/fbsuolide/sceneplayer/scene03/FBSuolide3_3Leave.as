package mmo.fbteam.fbsuolide.sceneplayer.scene03
{
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide3_3Leave extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene3TempTypes.FBSuolide3_3Leave};
      
      public function FBSuolide3_3Leave()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.leave,this.sysData,"fb_suolide3_talk_2_end");
      }
      
      private function leave() : void
      {
         this.finishStep();
         if(TeamHelper.isCaptain())
         {
            SceneManager.getInstance().loadFB("fbsuolide4","fbsuolide","阿努比斯之门",TeamHelper.getTeamKey());
         }
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

