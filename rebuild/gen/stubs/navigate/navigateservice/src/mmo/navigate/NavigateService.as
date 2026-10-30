package mmo.navigate
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.navigate.*;
   import mmo.interfaces.navigate.INavigateService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for NavigateService. Module navigate/navigateservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.navigate.INavigateService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class NavigateService extends EventDispatcher implements INavigateService
   {
      public function NavigateService()
      {
         super();
      }

      public function goToDuoDuoCar() : void
      {
         RLog.stub("NavigateService.goToDuoDuoCar");
      }

      public function goToChargeAoCoin() : void
      {
         RLog.stub("NavigateService.goToChargeAoCoin");
      }

      public function goToBlueDiamond() : void
      {
         RLog.stub("NavigateService.goToBlueDiamond");
      }

      public function goToChargeForFriends() : void
      {
         RLog.stub("NavigateService.goToChargeForFriends");
      }

      public function goToUrl(param1:String, param2:String, param3:int = 0, param4:String = "_blank") : void
      {
         RLog.stub("NavigateService.goToUrl");
      }

   }
}
