package mmo.activity
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.activity.*;
   import mmo.interfaces.activity.IActivityService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ActivityService. Module activityres/activityservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.activity.IActivityService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ActivityService extends EventDispatcher implements IActivityService
   {
      public function ActivityService()
      {
         super();
      }

      public function getModule(param1:Object) : Object
      {
         RLog.stub("ActivityService.getModule");
         return {};
      }

      public function init() : void
      {
         RLog.stub("ActivityService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
