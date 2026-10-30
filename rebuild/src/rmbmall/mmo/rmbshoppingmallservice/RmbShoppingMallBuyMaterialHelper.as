package mmo.rmbshoppingmallservice
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMallBuyMaterialHelper;
   import mmo.revival.RLog;

   /**
    * REBUILT RmbShoppingMallBuyMaterialHelper (the 2013 module is lost): what
    * scenes and panels buy "from the 商城" goes through the catalog's buying
    * (IBuyMaterial of the material type), which sells for 晶币 what has a
    * 晶币 price and says so for real-money goods.
    */
   public class RmbShoppingMallBuyMaterialHelper extends EventDispatcher implements IRmbShoppingMallBuyMaterialHelper
   {
      public function RmbShoppingMallBuyMaterialHelper()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      public function buyClothesByIdArray(ids:Array, source:String = "IRMB"):void
      {
         for each (var id:int in ids) buyMaterialById(0, id, 1, source);
      }

      public function buyMaterialByName(name:String, source:String = "IRMB"):void
      {
         RLog.log("rmbmall: buy by name " + name + " (no table of names in the revival)");
      }

      public function buyMaterialById(type:int, id:int, quantity:int = 1, source:String = "IRMB"):void
      {
         ServiceContainer.instance.tryGetBuyMaterialService(type, function(svc:IBuyMaterial, o:Object):void
         {
            svc.logSourceKey(source);
            svc.buy(new BuyMaterialInfo(type, id, quantity, 1), function(ok:Boolean):void {});
         });
      }
   }
}
