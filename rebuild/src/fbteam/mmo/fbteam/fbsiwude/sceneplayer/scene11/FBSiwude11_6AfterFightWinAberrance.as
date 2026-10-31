package mmo.fbteam.fbsiwude.sceneplayer.scene11
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   
   public class FBSiwude11_6AfterFightWinAberrance extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var queen:MovieClip = null;
      
      public function FBSiwude11_6AfterFightWinAberrance()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.queen = this.sceneInfo.scene.backGround.getChildByName("mc_antQueen") as MovieClip;
         this.removeNpc();
         this.showEscapeMovie();
      }
      
      private function removeNpc() : void
      {
         var _loc1_:SimpleButton = this.sceneInfo.scene.container.getChildByName("btn_general") as SimpleButton;
         DisplayUtil.stopAndRemove(_loc1_);
      }
      
      private function showEscapeMovie() : void
      {
         var mc:MovieClip = null;
         var cl:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.Escape") as Class;
         mc = new cl() as MovieClip;
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            ModalDialogManager.getInstance().removeModalDialog(mc);
            addKeyAndMagicWater();
            finishStep();
         });
         ModalDialogManager.getInstance().addModalDialog(mc,AlignType.NONE,PanelEffect.NONE,true,0,0);
      }
      
      private function addKeyAndMagicWater() : void
      {
         DisplayUtil.stopAndRemove(this.queen);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.Key") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         _loc2_.stop();
         _loc2_.name = "key";
         _loc2_.mouseChildren = false;
         this.sceneInfo.scene.backGround.addChild(_loc2_);
         _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.MagicWater") as Class;
         var _loc3_:MovieClip = new _loc1_() as MovieClip;
         _loc3_.name = "magicWater";
         _loc3_.mouseChildren = false;
         _loc3_.mouseEnabled = false;
         this.sceneInfo.scene.backGround.addChild(_loc3_);
      }
      
      public function dispose() : void
      {
      }
   }
}

