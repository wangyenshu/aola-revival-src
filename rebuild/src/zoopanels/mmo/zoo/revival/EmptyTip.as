package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /** REBUILT (the era EmptyTipPanel's art): how one gets 幼仔. */
   public class EmptyTip extends MovieClip
   {
      public var btnClose:SimpleButton;

      public function EmptyTip()
      {
         super();
         if (btnClose != null) btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { ModalDialogManager.getInstance().removeModalDialog(EmptyTip(e.currentTarget.parent)); });
      }
   }
}
