package mmo.catalog.dialogs
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.DialogBase;
   import mmo.common.dialog.NewDialog;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.uicomponent.UseNumericComponent;
   import mmo.revival.RMaterialView;

   /**
    * The 购买 dialog of catalog/catalogservice (the art of its copy under the 2013 URL; that copy's
    * ConfirmBuyBase written again for the 2013 libraries, whose DialogBase and UseNumericComponent
    * it was made for): name, 单价, 购买数量, 总价, what 蓝宝石 saves, 购买 and 取消. The prices are
    * BuyFlow's (晶币, or 星币 for goods of real money, half for 蓝宝石); the later copy's sale
    * banners (七折, 三折) are left out.
    */
   public class ConfirmBuyBase extends DialogBase
   {
      public var buyInfo:BuyMaterialInfo;

      protected var usenum:UseNumericComponent;
      protected var unit:int;
      protected var starCoins:Boolean;
      protected var saving:int;

      public function ConfirmBuyBase(info:BuyMaterialInfo, unit:int, starCoins:Boolean, member:Boolean, saving:int)
      {
         super();
         buyInfo = info;
         this.unit = unit;
         this.starCoins = starCoins;
         this.saving = saving;
         var q:DisplayObjectContainer = getChildByName("_quantity") as DisplayObjectContainer;
         var mc:DisplayObjectContainer = q != null ? q.getChildByName("mc_usenum") as DisplayObjectContainer : null;
         usenum = new UseNumericComponent();
         if (mc != null) usenum.registerComponent(mc);
         var off:DisplayObject = getChildByName("_offprice");
         if (off != null) off.visible = false;
         var discount:MovieClip = getChildByName("discountLabel") as MovieClip;
         var blue:DisplayObject = getChildByName("btnBlue");
         if (discount != null) discount.gotoAndStop(member ? 1 : 2);
         if (member && blue != null) blue.visible = false;
         else if (blue != null) blue.addEventListener(MouseEvent.CLICK, onBlue);
         // Its icons: frame 2 晶币, frame 1 星币.
         for each (var n:String in ["_price", "unitprice", "_offprice"])
         {
            var holder:DisplayObjectContainer = getChildByName(n) as DisplayObjectContainer;
            var icon:MovieClip = holder != null ? holder.getChildByName("icon") as MovieClip : null;
            if (icon != null) icon.gotoAndStop(starCoins ? 1 : 2);
         }
         addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
      }

      private function onBlue(e:MouseEvent):void
      {
         NewDialog.showMessage("蓝宝石可以在工具箱里开通哦！");
      }

      protected function text(holder:String, field:String, s:String):void
      {
         var h:DisplayObjectContainer = getChildByName(holder) as DisplayObjectContainer;
         var t:TextField = h != null ? h.getChildByName(field) as TextField : null;
         if (t != null) t.text = s;
      }

      protected function updatePrice(qty:int):void
      {
         text("unitprice", "txt", String(unit));
         text("_price", "txt", String(unit * Math.max(1, qty)));
         var discount:MovieClip = getChildByName("discountLabel") as MovieClip;
         var save:int = saving * Math.max(1, qty);
         if (discount != null)
         {
            var t:TextField = discount.getChildByName("xingBiOffPrice") as TextField;
            if (t != null) t.text = String(save);
            if (save <= 0)
            {
               discount.visible = false;
               var blue:DisplayObject = getChildByName("btnBlue");
               if (blue != null) blue.visible = false;
            }
         }
      }

      /** The picture, fitted into the square (once it has loaded). */
      protected function addIconView(view:DisplayObject):void
      {
         RMaterialView.into(view, getChildByName("viewContianer") as DisplayObjectContainer, 20);
      }

      protected function remove(name:String):void
      {
         var d:DisplayObject = getChildByName(name);
         if (d != null) DisplayUtil.stopAndRemove(d);
      }

      private function onRemove(e:Event):void
      {
         removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
         usenum.dispose();
      }
   }
}
