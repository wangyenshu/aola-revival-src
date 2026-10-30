package mmo.commoditybag
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.commoditybag.*;
   import mmo.interfaces.commoditybag.ICommoditybagService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for CommoditybagService. Module commoditybag/commoditybagservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.commoditybag.ICommoditybagService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class CommoditybagService extends EventDispatcher implements ICommoditybagService
   {
      public function CommoditybagService()
      {
         super();
      }

      public function showGetCommodityPanel(param1:int, param2:int = 1, param3:Boolean = false, param4:Boolean = false) : void
      {
         RLog.stub("CommoditybagService.showGetCommodityPanel");
      }

      public function getCommodityArr() : Array
      {
         RLog.stub("CommoditybagService.getCommodityArr");
         return [];
      }

      public function checkCommoditybagByItemId(param1:int) : Boolean
      {
         RLog.stub("CommoditybagService.checkCommoditybagByItemId");
         return false;
      }

   }
}
