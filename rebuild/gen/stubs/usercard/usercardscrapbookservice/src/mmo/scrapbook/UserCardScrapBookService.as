package mmo.scrapbook
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.usercard.*;
   import mmo.interfaces.usercard.IUserCardScrapBookService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserCardScrapBookService. Module usercard/usercardscrapbookservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.usercard.IUserCardScrapBookService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserCardScrapBookService extends EventDispatcher implements IUserCardScrapBookService
   {
      public function UserCardScrapBookService()
      {
         super();
      }

      public function getTiepaperPanel(param1:String) : void
      {
         RLog.stub("UserCardScrapBookService.getTiepaperPanel");
      }

      public function dispose() : void
      {
         RLog.stub("UserCardScrapBookService.dispose");
      }

   }
}
