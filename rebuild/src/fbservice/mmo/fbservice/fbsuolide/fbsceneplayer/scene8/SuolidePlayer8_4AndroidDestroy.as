package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer8_4AndroidDestroy extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var p1:MovieClip = null;
      
      private var p2:MovieClip = null;
      
      private var mummy_machine:MovieClip = null;
      
      private var leave:MovieClip = null;
      
      public function SuolidePlayer8_4AndroidDestroy()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playAndroidDestroy();
      }
      
      private function getPars() : void
      {
         this.p1 = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("fb8_p1") as MovieClip;
         this.p2 = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("fb8_p2") as MovieClip;
         this.mummy_machine = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("fb8_mummy_machine") as MovieClip;
      }
      
      private function playAndroidDestroy() : void
      {
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.p1);
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.p2);
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.mummy_machine);
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_leave") as Class;
         this.leave = new _loc1_() as MovieClip;
         this.leave.name = "fb8_leave";
         this.addModalDialogMovieToScene(this.leave,this.leave8,0,0);
      }
      
      private function leave8() : void
      {
         this.leave.stop();
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

