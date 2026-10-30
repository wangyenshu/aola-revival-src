package mmo.activity130110.lightmagichouse
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.lightmagichouse.*;
   import mmo.interfaces.lightmagichouse.ILightMagicHouseService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for LightMagicHouseService. Module activityres/activity130110/lightmagichouse/lightmagichouseservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.lightmagichouse.ILightMagicHouseService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class LightMagicHouseService extends EventDispatcher implements ILightMagicHouseService
   {
      private var _isTraining:Boolean = false;
      public function LightMagicHouseService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("LightMagicHouseService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      public function showActivityPanel() : void
      {
         RLog.stub("LightMagicHouseService.showActivityPanel");
      }

      public function get isTraining() : Boolean
      {
         RLog.stub("LightMagicHouseService.isTraining");
         return this._isTraining;
      }

      public function updateCDState() : void
      {
         RLog.stub("LightMagicHouseService.updateCDState");
      }

   }
}
