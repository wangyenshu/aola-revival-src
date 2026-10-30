package mmo.bookclub
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.reader.BConfigReader;
   import mmo.reader.config.BookInfo;
   import mmo.revival.book.BookOpener;

   /**
    * REBUILT catalog/bookclubservice: SellBookService (ServiceConfig
    * "SellBookService"), the shop catalogs scenes open with showPage, e.g.
    * 服装店's 星语流行服饰 counter: showPage("catalog201002").
    */
   public class SellBookService extends EventDispatcher implements IBookClubService
   {
      public function SellBookService()
      {
         super();
      }

      public function showPage(no:String, pageIndex:int = 0):void
      {
         BookOpener.open(no, pageIndex, true);
      }

      public function showPageBy2Index(no:String, fileIndex:int, classIndex:int):void
      {
         var book:BookInfo = BConfigReader.instence.getCatalog(no);
         var i:int = book ? book.getPageIndex(fileIndex, classIndex) : 0;
         BookOpener.open(no, i < 0 ? 0 : i, true);
      }

      public function showLastPage(no:String):void
      {
         var book:BookInfo = BConfigReader.instence.getCatalog(no);
         BookOpener.open(no, book ? book.lastPageIndex : 0, true);
      }

      public function openLog(key:String):void
      {
      }
   }
}
