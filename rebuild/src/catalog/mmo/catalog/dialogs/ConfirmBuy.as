package mmo.catalog.dialogs
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.uicomponent.UIComponentEvent;

   /** 购买 of one kind of goods (symbol 163): 购买数量 from 1 to the most one may still have. */
   public class ConfirmBuy extends ConfirmBuyBase
   {
      public var mutbynuit:MovieClip;
      public var _offprice:MovieClip;
      public var btnOK:SimpleButton;
      public var unitprice:MovieClip;
      public var btnCancel:SimpleButton;
      public var discountLabel:MovieClip;
      public var viewContianer:MovieClip;
      public var _name:MovieClip;
      public var _price:MovieClip;
      public var _quantity:MovieClip;
      public var btnBlue:SimpleButton;

      private var changed:Function;

      public function ConfirmBuy(info:BuyMaterialInfo, view:DisplayObject, name:String, unit:int, most:int, starCoins:Boolean, member:Boolean, saving:int, changed:Function = null)
      {
         super(info, unit, starCoins, member, saving);
         this.changed = changed;
         text("_name", "txtname", name);
         if (info.unitage > 1) text("mutbynuit", "unit", String(info.unitage));
         else remove("mutbynuit");
         info.quantity = 1;
         usenum.setLimit(1, Math.max(1, most));
         updatePrice(info.realQuantity);
         addIconView(view);
         usenum.addEventListener(UIComponentEvent.UPDATE, onCount);
      }

      private function onCount(e:UIComponentEvent):void
      {
         buyInfo.quantity = usenum.value;
         updatePrice(buyInfo.realQuantity);
         if (changed != null) changed();
      }
   }
}
