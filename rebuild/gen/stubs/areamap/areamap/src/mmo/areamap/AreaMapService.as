package mmo.areamap
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.areamap.*;
   import mmo.interfaces.areamap.IAreaMapService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for AreaMapService. Module areamap/areamap.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.areamap.IAreaMapService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class AreaMapService extends EventDispatcher implements IAreaMapService
   {
      public function AreaMapService()
      {
         super();
      }

      public function checkIsMapBtnEnable() : Boolean
      {
         RLog.stub("AreaMapService.checkIsMapBtnEnable");
         return false;
      }

      public function showPanel() : void
      {
         RLog.stub("AreaMapService.showPanel");
      }

   }
}
