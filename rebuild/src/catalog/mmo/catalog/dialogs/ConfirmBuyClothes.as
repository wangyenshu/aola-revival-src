package mmo.catalog.dialogs
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   import mmo.interfaces.catalog.BuyMaterialInfo;

   /** 购买 of clothes (symbol 161), one at a time: a piece, or a whole 套装 (购买全套) at its prices added up. */
   public class ConfirmBuyClothes extends ConfirmBuyBase
   {
      public var mutbynuit:MovieClip;
      public var _offprice:MovieClip;
      public var btnOK:SimpleButton;
      public var unitprice:MovieClip;
      public var btnCancel:SimpleButton;
      public var discountLabel:MovieClip;
      public var viewContianer:MovieClip;
      public var _name:MovieClip;
      public var txtdiscounttips:TextField;
      public var _price:MovieClip;
      public var _quantity:MovieClip;
      public var btnBlue:SimpleButton;

      public function ConfirmBuyClothes(info:BuyMaterialInfo, view:DisplayObject, name:String, unit:int, starCoins:Boolean, member:Boolean, saving:int)
      {
         super(info, unit, starCoins, member, saving);
         text("_name", "txtname", name);
         usenum.setLimit(1, 1);
         remove("_quantity");
         remove("mutbynuit");
         remove("txtdiscounttips");
         info.quantity = 1;
         updatePrice(1);
         addIconView(view);
      }
   }
}
