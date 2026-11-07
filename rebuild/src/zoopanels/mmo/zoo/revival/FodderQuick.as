package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /** REBUILT (the era QuickAddPanel's art): 快速添加饲料, filling the machine for 晶币. */
   public class FodderQuick extends MovieClip
   {
      public var btnCancel:SimpleButton;
      public var btnClose:SimpleButton;
      public var btnOk:SimpleButton;
      public var moneyNum:TextField;

      public function FodderQuick(cost:int, ok:Function)
      {
         super();
         stop();
         moneyNum.text = String(cost);
         var self:FodderQuick = this;
         var close:Function = function(e:MouseEvent = null):void { ModalDialogManager.getInstance().removeModalDialog(self); };
         btnOk.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); ok(); });
         btnCancel.addEventListener(MouseEvent.CLICK, close);
         btnClose.addEventListener(MouseEvent.CLICK, close);
      }
   }
}
