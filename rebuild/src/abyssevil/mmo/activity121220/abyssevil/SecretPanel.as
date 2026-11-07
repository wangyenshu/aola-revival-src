package mmo.activity121220.abyssevil
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   
   public class SecretPanel extends Sprite implements IDispose, IShowPanel
   {
      
      private var btnClose:SimpleButton;
      
      public function SecretPanel()
      {
         super();
         this.btnClose = getChildByName("btnclose") as SimpleButton;
      }
      
      public function dispose() : void
      {
         this.btnClose.removeEventListener(MouseEvent.CLICK,this.onClickClose);
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function showPanel() : void
      {
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onClickClose);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }
   }
}

