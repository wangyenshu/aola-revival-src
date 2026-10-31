package mmo.fbservice.fbsuolide.fbsceneplayer.scene1
{
   import flash.display.MovieClip;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer1_2Npc132OutFromWall extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var anubisAppear:MovieClip = null;
      
      public function SuolidePlayer1_2Npc132OutFromWall()
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
         var _loc1_:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         var _loc2_:Class = _loc1_.applicationDomain.getDefinition("mmo.scene.fbsuolide.AnubisAppear1") as Class;
         this.anubisAppear = new _loc2_();
         this.addModalDialogMovieToScene(this.anubisAppear,this.anubisAppearFinished);
      }
      
      private function anubisAppearFinished() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.anubisAppear);
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

