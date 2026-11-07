package mmo.activity121220.abyssevil
{
   import mmo.common.ProgressFullSprite;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.interfaces.material.MaterialTypes;
   
   public class ItemBuyHandler
   {
      
      public function ItemBuyHandler()
      {
         super();
      }
      
      public static function buy(param1:int, param2:int, param3:Function = null, param4:Boolean = false) : void
      {
         var buyInfo:BuyMaterialInfo = null;
         var itemId:int = param1;
         var quantity:int = param2;
         var callBack:Function = param3;
         var ed:Boolean = param4;
         buyInfo = new BuyMaterialInfo(MaterialTypes.ITEM,itemId,quantity,1);
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService("BuyMaterialService2",function(param1:IBuyMaterial, param2:Object):void
         {
            var service:IBuyMaterial = param1;
            var args:Object = param2;
            ProgressFullSprite.close();
            service.buy(buyInfo,function(param1:Boolean):void
            {
               if(param1)
               {
                  callBack.apply();
               }
            });
         });
      }
   }
}

