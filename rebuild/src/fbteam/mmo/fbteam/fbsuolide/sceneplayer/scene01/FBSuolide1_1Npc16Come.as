package mmo.fbteam.fbsuolide.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide1_1Npc16Come extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var catPrinceCome:MovieClip = null;
      
      public function FBSuolide1_1Npc16Come()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.playCatPrinceComeMovie();
      }
      
      private function playCatPrinceComeMovie() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.CatPrinceCome") as Class;
         this.catPrinceCome = new _loc1_();
         this.addModalDialogMovieToScene(this.catPrinceCome,this.catPrinceComeFinished);
         TeamHelper.jumpTo(new Point(341,417));
      }
      
      private function catPrinceComeFinished() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.catPrinceCome);
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

