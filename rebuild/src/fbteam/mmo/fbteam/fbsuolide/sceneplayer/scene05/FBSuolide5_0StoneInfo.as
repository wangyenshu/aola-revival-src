package mmo.fbteam.fbsuolide.sceneplayer.scene05
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide5_0StoneInfo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var btn:SimpleButton = null;
      
      private var spFlagStone:Sprite = null;
      
      private var btnClose:SimpleButton = null;
      
      public function FBSuolide5_0StoneInfo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.flagstoneInfo();
      }
      
      private function flagstoneInfo() : void
      {
         this.btn = this.sceneInfo.scene.backGround.getChildByName("btn_flagstone") as SimpleButton;
         this.btn.addEventListener(MouseEvent.CLICK,this.onClickFlagStone);
         TipsManager.getInstance().addTips(this.btn,"天平介绍");
         var _loc1_:Class = SceneManager.getInstance().loadedSceneInfo.applicationDomain.getDefinition("mmo.scene.fbsuolide.fbsuolide5.FlagStone") as Class;
         this.spFlagStone = new _loc1_() as Sprite;
         this.btnClose = this.spFlagStone.getChildByName("btnclose") as SimpleButton;
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onClose);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         this.isClicking = false;
         ModalDialogManager.getInstance().removeModalDialog(this.spFlagStone);
      }
      
      private function onClickFlagStone(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         ModalDialogManager.getInstance().addModalDialog(this.spFlagStone,AlignType.MIDDLE_CENTER);
      }
      
      public function dispose() : void
      {
      }
   }
}

