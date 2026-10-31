package mmo.fbservice.fbsuolide.fbsceneplayer.scene1
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer1_1Npc16Come extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var catPrinceCome:MovieClip = null;
      
      public function SuolidePlayer1_1Npc16Come()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playCatPrinceComeMovie();
      }
      
      private function playCatPrinceComeMovie() : void
      {
         var _loc1_:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         var _loc2_:Class = _loc1_.applicationDomain.getDefinition("mmo.scene.fbsuolide.CatPrinceCome") as Class;
         this.catPrinceCome = new _loc2_();
         this.addModalDialogMovieToScene(this.catPrinceCome,this.catPrinceComeFinished);
         PlayerManager.getInstance().myPlayer.jumpTo(341,417);
      }
      
      private function catPrinceComeFinished() : void
      {
         var _loc1_:IFbService = ServiceContainer.instance.getService(IFbService) as IFbService;
         var _loc2_:DisplayObject = _loc1_.addFollower(29999);
         ModalDialogManager.getInstance().removeModalDialog(this.catPrinceCome);
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

