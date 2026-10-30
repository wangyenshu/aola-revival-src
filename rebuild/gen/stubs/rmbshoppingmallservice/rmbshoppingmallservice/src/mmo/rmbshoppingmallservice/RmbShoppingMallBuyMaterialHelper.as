package mmo.rmbshoppingmallservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.rmbshoppingmall.*;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMallBuyMaterialHelper;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for RmbShoppingMallBuyMaterialHelper. Module rmbshoppingmallservice/rmbshoppingmallservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.rmbshoppingmall.IRmbShoppingMallBuyMaterialHelper) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class RmbShoppingMallBuyMaterialHelper extends EventDispatcher implements IRmbShoppingMallBuyMaterialHelper
   {
      public function RmbShoppingMallBuyMaterialHelper()
      {
         super();
      }

      public function buyClothesByIdArray(param1:Array, param2:String = "IRMB") : void
      {
         RLog.stub("RmbShoppingMallBuyMaterialHelper.buyClothesByIdArray");
      }

      public function buyMaterialByName(param1:String, param2:String = "IRMB") : void
      {
         RLog.stub("RmbShoppingMallBuyMaterialHelper.buyMaterialByName");
      }

      public function buyMaterialById(param1:int, param2:int, param3:int = 1, param4:String = "IRMB") : void
      {
         RLog.stub("RmbShoppingMallBuyMaterialHelper.buyMaterialById");
      }

      public function init() : void
      {
         RLog.stub("RmbShoppingMallBuyMaterialHelper.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
