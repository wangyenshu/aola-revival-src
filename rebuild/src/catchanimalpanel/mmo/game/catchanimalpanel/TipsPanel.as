package mmo.game.catchanimalpanel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /**
    * REBUILT (the later copy's code on its art, symbol 26): no 能源石 (frame 1) or no 糖果
    * (frame 2); its 去购买 opens CatchShop (the lost 动物乐园购买册's place).
    */
   public class TipsPanel extends Sprite
   {
      public var panel:MovieClip;

      private var start:StartPanel;

      public function TipsPanel(which:int = 1, from:StartPanel = null)
      {
         super();
         name = "catchTips";
         start = from;
         panel.gotoAndStop(which);
         addEventListener(MouseEvent.CLICK, onClick);
      }

      private function onClick(e:MouseEvent):void
      {
         switch (e.target.name)
         {
            case "btnClose":
            case "btnOk":
               ModalDialogManager.getInstance().removeModalDialog(this);
               break;
            case "btnBuy":
               ModalDialogManager.getInstance().removeModalDialog(this);
               CatchShop.show(start);
               break;
         }
      }
   }
}
