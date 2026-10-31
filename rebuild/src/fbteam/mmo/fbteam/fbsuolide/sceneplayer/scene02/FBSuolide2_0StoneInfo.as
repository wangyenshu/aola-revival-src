package mmo.fbteam.fbsuolide.sceneplayer.scene02
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   
   public class FBSuolide2_0StoneInfo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSuolide2_0StoneInfo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.flagstoneInfo(true,param2,param3);
      }
      
      private function flagstoneInfo(param1:Boolean, param2:Function, param3:Object) : void
      {
         var _loc4_:SimpleButton = this.sceneInfo.scene.backGround.getChildByName("btn_flagstone") as SimpleButton;
         if(param1)
         {
            _loc4_.addEventListener(MouseEvent.CLICK,this.onClickFlagStone);
            TipsManager.getInstance().addTips(_loc4_,"石像迷阵介绍");
         }
         else
         {
            _loc4_.removeEventListener(MouseEvent.CLICK,this.onClickFlagStone);
            TipsManager.getInstance().removeTips(_loc4_);
         }
      }
      
      private function onClickFlagStone(param1:MouseEvent) : void
      {
         var cls:Class;
         var flagStone:Sprite = null;
         var e:MouseEvent = param1;
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         cls = FBConfig.instence.getClass("mmo.scene.fbsuolide.fbsuolide2.FlagStone") as Class;
         flagStone = new cls() as Sprite;
         flagStone.addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
         {
            ModalDialogManager.getInstance().removeModalDialog(flagStone);
            isClicking = false;
         });
         ModalDialogManager.getInstance().addModalDialog(flagStone,AlignType.MIDDLE_CENTER);
      }
      
      public function dispose() : void
      {
      }
   }
}

