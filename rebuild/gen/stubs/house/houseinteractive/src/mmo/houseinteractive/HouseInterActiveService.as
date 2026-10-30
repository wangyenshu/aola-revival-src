package mmo.houseinteractive
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.houseinterfaces.*;
   import mmo.houseinterfaces.IHouseInterActiveService;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HouseInterActiveService. Module house/houseinteractive.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.IHouseInterActiveService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HouseInterActiveService extends EventDispatcher implements IHouseInterActiveService
   {
      public function HouseInterActiveService()
      {
         super();
      }

      public function addActive() : void
      {
         RLog.stub("HouseInterActiveService.addActive");
      }

   }
}
