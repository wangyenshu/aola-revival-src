package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /** REBUILT (the era SellAnimalPanel's art): grown animals sold for 晶币 (ZooExtension 97_21). */
   public class SellPanel extends MovieClip
   {
      public var addBtn:SimpleButton;
      public var delBtn:SimpleButton;
      public var btnOk:SimpleButton;
      public var btnCancel:SimpleButton;
      public var btnClose:SimpleButton;
      public var nameText:TextField;
      public var numText:TextField;
      public var priceText:TextField;
      public var moneyText:TextField;

      private var race:int;
      private var most:int;
      private var price:int;
      private var count:int = 1;
      private var done:Function;

      public function SellPanel(race:int, most:int, price:int, done:Function)
      {
         super();
         stop();
         this.race = race;
         this.most = Math.max(1, most);
         this.price = price;
         this.done = done;
         if (nameText != null) nameText.text = ZooKit.nameOf(race, true);
         if (priceText != null) priceText.text = String(price);
         addBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { count = Math.min(most, count + 1); show(); });
         delBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { count = Math.max(1, count - 1); show(); });
         btnOk.addEventListener(MouseEvent.CLICK, onOk);
         btnCancel.addEventListener(MouseEvent.CLICK, close);
         btnClose.addEventListener(MouseEvent.CLICK, close);
         show();
      }

      private function show():void
      {
         if (numText != null) numText.text = String(count);
         if (moneyText != null) moneyText.text = String(count * price);
      }

      private function onOk(e:MouseEvent):void
      {
         var self:SellPanel = this;
         ZooKit.ask("97_21", {raceId: race, num: count}, function(p:Object):void
         {
            if (int(p.res) != 1)
            {
               NewDialog.showFailMessage("卖出失败了。");
               return;
            }
            NewDialog.showSucceedMessage("你卖出了" + int(p.num) + "只" + ZooKit.nameOf(race, true) + "，得到" + int(p.got) + "晶币。");
            self.close();
            if (done != null) done();
         });
      }

      private function close(e:MouseEvent = null):void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}
