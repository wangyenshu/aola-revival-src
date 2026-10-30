package mmo.notify
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.interfaces.notify.*;
   import mmo.interfaces.notify.INotifyService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for NotifyService. Module baseservice/notify.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.notify.INotifyService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class NotifyService extends EventDispatcher implements INotifyService, IServiceLocator, IService
   {
      private static var __instance:NotifyService;

      public function NotifyService()
      {
         super();
      }

      public function contain(param1:String) : Boolean
      {
         RLog.stub("NotifyService.contain");
         return false;
      }

      public function addSysNotify(param1:String, param2:String = null) : Object
      {
         RLog.stub("NotifyService.addSysNotify");
         return {};
      }

      public function popMessage(param1:int) : void
      {
         RLog.stub("NotifyService.popMessage");
      }

      public function addFightMessage(param1:Object, param2:int) : void
      {
         RLog.stub("NotifyService.addFightMessage");
      }

      public function addMemberMessage(param1:Object, param2:int) : void
      {
         RLog.stub("NotifyService.addMemberMessage");
      }

      public function addNotifyMessage(param1:Object, param2:int, param3:String = null, param4:int = 1) : void
      {
         RLog.stub("NotifyService.addNotifyMessage");
      }

      public function getMessageCount(param1:int) : int
      {
         RLog.stub("NotifyService.getMessageCount");
         return 0;
      }

      public function removeNotify(param1:String) : void
      {
         RLog.stub("NotifyService.removeNotify");
      }

      public function getInstance() : IService
      {
         if (__instance == null) __instance = new NotifyService();
         return __instance;
      }

   }
}
