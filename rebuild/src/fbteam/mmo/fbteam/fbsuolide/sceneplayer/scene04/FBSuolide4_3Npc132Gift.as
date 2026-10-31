package mmo.fbteam.fbsuolide.sceneplayer.scene04
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide4_3Npc132Gift extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene4TempTypes.FBSuolide4_3Npc132Gift};
      
      private var anubis:SimpleButton = null;
      
      private var anubisBecomeStone:MovieClip = null;
      
      public function FBSuolide4_3Npc132Gift()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playAnubisBecomeStoneMovie,this.sysData,"fb_suolide4_talk_2_end");
      }
      
      private function playAnubisBecomeStoneMovie() : void
      {
         this.anubis = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("anubis") as SimpleButton;
         if(this.anubis != null)
         {
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.anubis);
         }
         this.removeObstruction();
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.AnubisBecomeStone") as Class;
         this.anubisBecomeStone = new _loc1_() as MovieClip;
         this.addMovieToScene(this.anubisBecomeStone,this.anubisBecomeStoneFinished,-134,-2);
      }
      
      private function removeObstruction() : void
      {
         var _loc1_:MovieClip = this.getObstruction().getChildByName("maskByXiong") as MovieClip;
         this.getObstruction().removeChild(_loc1_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
      }
      
      private function anubisBecomeStoneFinished() : void
      {
         DisplayUtil.stopAndRemove(this.anubisBecomeStone);
         if(TeamHelper.isCaptain())
         {
            NewDialog.showSucceedMessage("得到 圣甲虫之笛");
         }
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

