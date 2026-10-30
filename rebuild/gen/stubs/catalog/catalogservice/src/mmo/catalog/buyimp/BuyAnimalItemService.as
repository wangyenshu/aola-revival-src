package mmo.catalog.buyimp
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.catalog.*;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BuyMaterialService13. Module catalog/catalogservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.catalog.IBuyMaterial) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BuyAnimalItemService extends EventDispatcher implements IBuyMaterial
   {
      public function BuyAnimalItemService()
      {
         super();
      }

      public function logSourceKey(param1:String) : void
      {
         RLog.stub("BuyAnimalItemService.logSourceKey");
      }

      public function buy(param1:BuyMaterialInfo, param2:Function, param3:* = null) : void
      {
         RLog.stub("BuyAnimalItemService.buy");
      }

   }
}
