package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer8_1MummyAppear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var Coffin:MovieClip = null;
      
      private var Mummy_appaer:MovieClip = null;
      
      public function SuolidePlayer8_1MummyAppear()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playMummyAppear();
      }
      
      private function getPars() : void
      {
         this.Coffin = this.sceneInfo.scene.backGround.getChildByName("fbsuolide8_coffin") as MovieClip;
      }
      
      private function playMummyAppear() : void
      {
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.removeChild(this.Coffin);
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_mummy_appaer") as Class;
         this.Mummy_appaer = new _loc1_() as MovieClip;
         this.Mummy_appaer.name = "fbsuolide8_mummy_appaer";
         this.Mummy_appaer.addFrameScript(this.Mummy_appaer.totalFrames - 1,this.mummyAppaerEnd);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.Mummy_appaer);
         Tool.instence.addTransparency();
         this.Mummy_appaer.gotoAndPlay(1);
      }
      
      private function mummyAppaerEnd() : void
      {
         this.Mummy_appaer.stop();
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

