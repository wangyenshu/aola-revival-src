package mmo.rmbshoppingmallservice
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.rmbshoppingmall.*;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMall;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for RmbShoppingMallService. Module rmbshoppingmallservice/rmbshoppingmallservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.rmbshoppingmall.IRmbShoppingMall) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class RmbShoppingMallService extends EventDispatcher implements IRmbShoppingMall
   {
      private var _isShowing:Boolean = false;
      public function RmbShoppingMallService()
      {
         super();
      }

      public function showRmbShoppingPanel(param1:int = 0) : void
      {
         RLog.stub("RmbShoppingMallService.showRmbShoppingPanel");
      }

      public function get isShowing() : Boolean
      {
         RLog.stub("RmbShoppingMallService.isShowing");
         return this._isShowing;
      }

   }
}
