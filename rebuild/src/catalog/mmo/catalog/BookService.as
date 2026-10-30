package mmo.catalog
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.catalog.IBookService;
   import mmo.revival.book.BookOpener;

   /** REBUILT catalog/catalogservice: BookService, catalogs opened with showCatalog(no). */
   public class BookService extends EventDispatcher implements IBookService
   {
      public function BookService()
      {
         super();
      }

      public function showCatalog(no:String):void
      {
         BookOpener.open(no, 0, true);
      }

      public function showCatalogAt(no:String, pageIndex:int):void
      {
         BookOpener.open(no, pageIndex, true);
      }
   }
}
