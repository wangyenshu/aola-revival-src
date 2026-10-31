package mmo.fbservice.fbsuolide.fbsceneplayer.scene4
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer4_3Npc132Gift extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var anubis:SimpleButton = null;
      
      private var anubisBecomeStone:MovieClip = null;
      
      public function SuolidePlayer4_3Npc132Gift()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playAnubisBecomeStoneMovie();
      }
      
      private function playAnubisBecomeStoneMovie() : void
      {
         this.anubis = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("anubis") as SimpleButton;
         if(this.anubis != null)
         {
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.anubis);
         }
         this.removeObstruction();
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.AnubisBecomeStone") as Class;
         this.anubisBecomeStone = new _loc1_() as MovieClip;
         this.addModalDialogMovieToScene(this.anubisBecomeStone,this.anubisBecomeStoneFinished,-134,-2);
      }
      
      private function removeObstruction() : void
      {
         var _loc1_:MovieClip = this.getObstruction().getChildByName("maskByXiong") as MovieClip;
         this.getObstruction().removeChild(_loc1_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
      }
      
      private function anubisBecomeStoneFinished() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.anubisBecomeStone);
         NewDialog.showSucceedMessage("得到 圣甲虫之笛");
      }
      
      public function dispose() : void
      {
      }
   }
}

