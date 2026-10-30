package mmo.buddylist.buddylist
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.buddy.*;
   import mmo.interfaces.buddy.IBuddyListService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BuddyListService. Module buddylist/buddylist.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.buddy.IBuddyListService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BuddyListService extends EventDispatcher implements IBuddyListService
   {
      public function BuddyListService()
      {
         super();
      }

      public function closePanel(param1:String) : void
      {
         RLog.stub("BuddyListService.closePanel");
      }

      public function showPanel(param1:String, param2:Object = null) : void
      {
         RLog.stub("BuddyListService.showPanel");
      }

   }
}
