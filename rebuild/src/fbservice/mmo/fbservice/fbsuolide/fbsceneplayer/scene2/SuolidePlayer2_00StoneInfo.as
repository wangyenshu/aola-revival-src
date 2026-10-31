package mmo.fbservice.fbsuolide.fbsceneplayer.scene2
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   
   public class SuolidePlayer2_00StoneInfo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      public function SuolidePlayer2_00StoneInfo()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.flagstoneInfo(param2,param3,param4);
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
         cls = Tool.instence.getClass("mmo.scene.fbsuolide.fbsuolide2.FlagStone") as Class;
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

