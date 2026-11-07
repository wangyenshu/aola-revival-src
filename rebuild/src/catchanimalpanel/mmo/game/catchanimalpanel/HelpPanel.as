package mmo.game.catchanimalpanel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;

   /** REBUILT 操作说明 (the later copy's code on its art, symbol 89): what each thing does, as tips. */
   public class HelpPanel extends Sprite
   {
      private static const SAY:Array = ["击中后可以消除小动物的敌意，以便进行驯养。", "驯服小动物的成功率比较低。", "驯服小动物的成功率较高。",
         "超受动物喜爱，使用后驯服动物一定成功。", "使用后可以保护飞行器不受动物攻击。", "使用后可以同时发射出3个音符。", "爆炸后产生大量的音符，能将所有的动物安抚哦。"];

      public var btnClose:SimpleButton;
      public var i1:MovieClip;
      public var i2:MovieClip;
      public var i3:MovieClip;
      public var i4:MovieClip;
      public var i5:MovieClip;
      public var i6:MovieClip;
      public var i7:MovieClip;

      public function HelpPanel()
      {
         super();
         name = "catchHelp";
         var me:HelpPanel = this;
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { ModalDialogManager.getInstance().removeModalDialog(me); });
         for (var i:int = 1; i <= 7; i++)
         {
            var icon:Sprite = getChildByName("i" + i) as Sprite;
            if (icon != null) TipsManager.getInstance().addTips(icon, SAY[i - 1]);
         }
      }
   }
}
