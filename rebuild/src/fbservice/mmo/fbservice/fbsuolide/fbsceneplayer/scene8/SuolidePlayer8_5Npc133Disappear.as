package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer8_5Npc133Disappear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var landing2:MovieClip = null;
      
      private var falao2:MovieClip = null;
      
      private var zhang:MovieClip = null;
      
      public function SuolidePlayer8_5Npc133Disappear()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playNpc133Disappear();
      }
      
      private function getPars() : void
      {
      }
      
      private function playNpc133Disappear() : void
      {
         this.removeModalDialogMovieByName("fb8_appear_landing");
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_landing2") as Class;
         this.landing2 = new _loc1_() as MovieClip;
         this.landing2.addFrameScript(this.landing2.totalFrames - 1,this.landing_leave);
         this.landing2.x = 775;
         this.landing2.y = 331;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.landing2);
         this.landing2.gotoAndPlay(1);
      }
      
      private function landing_leave() : void
      {
         this.landing2.stop();
         this.removeModalDialogMovieByName("fb8_leave");
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_falao2") as Class;
         this.falao2 = new _loc1_() as MovieClip;
         this.falao2.x = 503;
         this.falao2.y = 288;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.falao2);
         _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_zhang") as Class;
         this.zhang = new _loc1_() as MovieClip;
         this.zhang.x = 425;
         this.zhang.y = 284;
         this.zhang.name = "fb8_zhang";
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.zhang);
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

