package mmo.catalog
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.catalog.*;
   import mmo.interfaces.catalog.IBookService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BookService. Module catalog/catalogservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.catalog.IBookService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BookService extends EventDispatcher implements IBookService
   {
      public function BookService()
      {
         super();
      }

      public function showCatalog(param1:String) : void
      {
         RLog.stub("BookService.showCatalog");
      }

      public function showCatalogAt(param1:String, param2:int) : void
      {
         RLog.stub("BookService.showCatalogAt");
      }

   }
}
