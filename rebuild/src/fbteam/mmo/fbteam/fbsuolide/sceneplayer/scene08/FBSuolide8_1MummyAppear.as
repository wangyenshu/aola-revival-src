package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import mmo.fbteam.common.ScreenLock;
   import flash.display.MovieClip;
   import mmo.common.ProgressFullSprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide8_1MummyAppear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene8TempTypes.FBSuolide8_1MummyAppear};
      
      private var Coffin:MovieClip = null;
      
      private var Mummy_appaer:MovieClip = null;
      
      public function FBSuolide8_1MummyAppear()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playMummyAppear,this.sysData,"fb_suolide8_talk_1_end");
      }
      
      private function getPars() : void
      {
         this.Coffin = this.sceneInfo.scene.backGround.getChildByName("fbsuolide8_coffin") as MovieClip;
      }
      
      private function playMummyAppear() : void
      {
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.removeChild(this.Coffin);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_mummy_appaer") as Class;
         this.Mummy_appaer = new _loc1_() as MovieClip;
         this.Mummy_appaer.name = "fbsuolide8_mummy_appaer";
         this.Mummy_appaer.addFrameScript(this.Mummy_appaer.totalFrames - 1,this.mummyAppaerEnd);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.Mummy_appaer);
         if(TeamHelper.isCaptain())
         {
            ScreenLock.lock();
         }
         this.Mummy_appaer.gotoAndPlay(1);
      }
      
      private function mummyAppaerEnd() : void
      {
         if(TeamHelper.isCaptain())
         {
            ScreenLock.unlock();
         }
         this.Mummy_appaer.stop();
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

