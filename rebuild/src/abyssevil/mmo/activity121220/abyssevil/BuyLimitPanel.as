package mmo.activity121220.abyssevil
{
   import flash.display.DisplayObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   
   public class BuyLimitPanel extends Sprite implements IDispose, IShowPanel
   {
      
      public var btnok:SimpleButton;
      
      public function BuyLimitPanel()
      {
         super();
      }
      
      public function dispose() : void
      {
         removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      public function showPanel() : void
      {
         addEventListener(MouseEvent.CLICK,this.onClick);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = DisplayObject(param1.target).name;
         switch(_loc2_)
         {
            case "btnok":
               this.ok();
         }
      }
      
      private function ok() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}

