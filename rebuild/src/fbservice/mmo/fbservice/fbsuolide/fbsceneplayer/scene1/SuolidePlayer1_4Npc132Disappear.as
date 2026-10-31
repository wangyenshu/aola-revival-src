package mmo.fbservice.fbsuolide.fbsceneplayer.scene1
{
   import flash.display.MovieClip;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   
   public class SuolidePlayer1_4Npc132Disappear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var anubisDisappear:MovieClip = null;
      
      public function SuolidePlayer1_4Npc132Disappear()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playAnubisDisappearMovie();
      }
      
      private function playAnubisDisappearMovie() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.AnubisDisappear") as Class;
         this.anubisDisappear = new _loc1_();
         this.addModalDialogMovieToScene(this.anubisDisappear,this.anubisDisappearFinished);
      }
      
      private function anubisDisappearFinished() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.anubisDisappear);
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

