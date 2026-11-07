package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /** REBUILT (the era FullTip's art): 1 the 饲料机 is full, 2 it is someone else's. */
   public class FodderFull extends MovieClip
   {
      public var btnClose:SimpleButton;
      public var btnOk:SimpleButton;
      public var tipmc:MovieClip;

      public function FodderFull(which:int)
      {
         super();
         stop();
         if (tipmc != null) tipmc.gotoAndStop(which);
         var self:FodderFull = this;
         var close:Function = function(e:MouseEvent):void { ModalDialogManager.getInstance().removeModalDialog(self); };
         btnClose.addEventListener(MouseEvent.CLICK, close);
         btnOk.addEventListener(MouseEvent.CLICK, close);
      }
   }
}
