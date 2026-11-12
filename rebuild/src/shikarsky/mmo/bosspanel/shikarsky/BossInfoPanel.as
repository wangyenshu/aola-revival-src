package mmo.bosspanel.shikarsky
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;

   /** 猎空's 挑战秘籍 (what it does in battle, the types it beats and is beaten by): its own code. */
   public class BossInfoPanel extends Sprite implements IDispose, IShowPanel
   {
      public var btnClose:SimpleButton;

      public function BossInfoPanel()
      {
         super();
         this.addEventListener(MouseEvent.CLICK, this.onClickPanel);
      }

      private function onClickPanel(e:MouseEvent):void
      {
         if (e.target.name == "btnClose") ModalDialogManager.getInstance().removeModalDialog(this);
      }

      public function dispose():void
      {
      }

      public function showPanel():void
      {
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this, AlignType.NONE, PanelEffect.NONE, true, 0, 0);
      }
   }
}
