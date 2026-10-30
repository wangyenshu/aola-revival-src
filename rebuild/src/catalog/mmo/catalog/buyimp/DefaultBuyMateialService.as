package mmo.catalog.buyimp
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.revival.book.BuyFlow;

   /**
    * REBUILT catalog/catalogservice: the BuyMaterialService<type> services
    * (ServiceConfig: 0 clothes, 1 furniture, 2/3 items, 4 shoot cards, 5 pet
    * eggs, 9 plants, 10 plant items) all buy through BuyFlow.
    */
   public class DefaultBuyMateialService extends EventDispatcher implements IBuyMaterial
   {
      protected var sourceKey:String = "0";

      public function DefaultBuyMateialService()
      {
         super();
      }

      public function logSourceKey(key:String):void
      {
         sourceKey = key;
      }

      public function buy(info:BuyMaterialInfo, callback:Function, thisObject:* = null):void
      {
         BuyFlow.buy(info, function(ok:Boolean):void
         {
            if (callback != null) callback.apply(thisObject, [ok]);
         });
      }
   }
}
