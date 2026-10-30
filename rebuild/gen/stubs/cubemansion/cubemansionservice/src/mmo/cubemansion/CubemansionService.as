package mmo.cubemansion
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.cubemansionservice.*;
   import mmo.interfaces.cubemansionservice.ICubemansionService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for CubemansionService. Module cubemansion/cubemansionservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.cubemansionservice.ICubemansionService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class CubemansionService extends EventDispatcher implements ICubemansionService
   {
      private var _isArrivedState:*;
      public function CubemansionService()
      {
         super();
      }

      public function set isArrivedState(param1:Boolean) : void
      {
         this._isArrivedState = param1;
      }

      public function get isArrivedState() : Boolean
      {
         RLog.stub("CubemansionService.isArrivedState");
         return this._isArrivedState;
      }

      public function getCandy() : void
      {
         RLog.stub("CubemansionService.getCandy");
      }

      public function init() : void
      {
         RLog.stub("CubemansionService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
