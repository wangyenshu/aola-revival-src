package mmo.fbteam.fbsuolide.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide1_2Npc132OutFromWall extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var anubisAppear:MovieClip = null;
      
      private const sysData:Object = {"what":FBSuolide_Scene1TempTypes.FBSuolide1_2Npc132OutFromWall};
      
      public function FBSuolide1_2Npc132OutFromWall()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playAnubisAppearMovie,this.sysData,"fb_suolide1_talk_1_end");
      }
      
      private function playAnubisAppearMovie() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.AnubisAppear1") as Class;
         this.anubisAppear = new _loc1_();
         this.addModalDialogMovieToScene(this.anubisAppear,this.anubisAppearFinished);
      }
      
      private function anubisAppearFinished() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.anubisAppear);
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

