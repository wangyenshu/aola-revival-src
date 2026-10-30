package mmo.offlinemsg
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.interfaces.notify.*;
   import mmo.interfaces.notify.IOfflineMsgService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for OfflineMsgService. Module baseservice/notify.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.notify.IOfflineMsgService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class OfflineMsgService extends EventDispatcher implements IOfflineMsgService, IServiceLocator, IService
   {
      private static var __instance:OfflineMsgService;

      public function OfflineMsgService()
      {
         super();
      }

      public function initOfflineMsgs() : void
      {
         RLog.stub("OfflineMsgService.initOfflineMsgs");
      }

      public function getInstance() : IService
      {
         if (__instance == null) __instance = new OfflineMsgService();
         return __instance;
      }

   }
}
