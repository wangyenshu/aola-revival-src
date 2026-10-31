package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide8_4AndroidDestroy extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene8TempTypes.FBSuolide8_4AndroidDestroy};
      
      private var p1:MovieClip = null;
      
      private var p2:MovieClip = null;
      
      private var mummy_machine:MovieClip = null;
      
      private var leave:MovieClip = null;
      
      public function FBSuolide8_4AndroidDestroy()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playAndroidDestroy,this.sysData,"fb_suolide8_talk_3_end");
      }
      
      private function getPars() : void
      {
         this.p1 = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("fb8_p1") as MovieClip;
         this.p2 = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("fb8_p2") as MovieClip;
         this.mummy_machine = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("fb8_mummy_machine") as MovieClip;
      }
      
      private function playAndroidDestroy() : void
      {
         DisplayUtil.stopAndRemove(this.p1);
         DisplayUtil.stopAndRemove(this.p2);
         DisplayUtil.stopAndRemove(this.mummy_machine);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_leave") as Class;
         this.leave = new _loc1_() as MovieClip;
         this.leave.name = "fb8_leave";
         this.addMovieToScene(this.leave,this.leave8,0,0);
      }
      
      private function leave8() : void
      {
         this.leave.stop();
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

