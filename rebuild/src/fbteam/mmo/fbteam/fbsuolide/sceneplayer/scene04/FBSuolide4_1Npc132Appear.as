package mmo.fbteam.fbsuolide.sceneplayer.scene04
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide4_1Npc132Appear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var anubisAppear:MovieClip = null;
      
      public function FBSuolide4_1Npc132Appear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.playAnubisAppearMovie();
      }
      
      private function playAnubisAppearMovie() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.AnubisAppear") as Class;
         this.anubisAppear = new _loc1_();
         this.addModalDialogMovieToScene(this.anubisAppear,this.anubisAppearFinished);
      }
      
      private function anubisAppearFinished() : void
      {
         this.anubisAppear.stop();
         this.finishStep();
         ModalDialogManager.getInstance().removeModalDialog(this.anubisAppear);
         var _loc1_:SimpleButton = null;
         var _loc2_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Anubis") as Class;
         _loc1_ = new _loc2_() as SimpleButton;
         _loc1_.name = "anubis";
         _loc1_.x = 482;
         _loc1_.y = 325;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc1_);
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

