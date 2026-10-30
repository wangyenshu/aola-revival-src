package mmo.bookclub
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.catalog.*;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HandBookService. Module catalog/bookclubservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.catalog.IBookClubService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HandBookService extends EventDispatcher implements IBookClubService
   {
      public function HandBookService()
      {
         super();
      }

      public function openLog(param1:String) : void
      {
         RLog.stub("HandBookService.openLog");
      }

      public function showPageBy2Index(param1:String, param2:int, param3:int) : void
      {
         RLog.stub("HandBookService.showPageBy2Index");
      }

      public function showPage(param1:String, param2:int = 0) : void
      {
         RLog.stub("HandBookService.showPage");
      }

   }
}
