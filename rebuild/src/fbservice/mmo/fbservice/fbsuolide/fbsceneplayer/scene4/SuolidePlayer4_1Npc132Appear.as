package mmo.fbservice.fbsuolide.fbsceneplayer.scene4
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer4_1Npc132Appear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var anubisAppear:MovieClip = null;
      
      public function SuolidePlayer4_1Npc132Appear()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playAnubisAppearMovie();
      }
      
      private function playAnubisAppearMovie() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.AnubisAppear") as Class;
         this.anubisAppear = new _loc1_();
         this.addModalDialogMovieToScene(this.anubisAppear,this.anubisAppearFinished);
      }
      
      private function anubisAppearFinished() : void
      {
         this.anubisAppear.stop();
         this.movieFinish(-1,this.type);
         ModalDialogManager.getInstance().removeModalDialog(this.anubisAppear);
         var _loc1_:SimpleButton = null;
         var _loc2_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Anubis") as Class;
         _loc1_ = new _loc2_() as SimpleButton;
         _loc1_.name = "anubis";
         _loc1_.x = 482;
         _loc1_.y = 325;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc1_);
      }
      
      public function dispose() : void
      {
      }
   }
}

