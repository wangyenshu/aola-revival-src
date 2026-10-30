package mmo.bookclub
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.reader.BConfigReader;
   import mmo.reader.config.BookInfo;
   import mmo.revival.book.BookOpener;

   /** REBUILT catalog/bookclubservice: HandBookService, the handbooks (亚比手册, 奥拉手册…). */
   public class HandBookService extends EventDispatcher implements IBookClubService
   {
      public function HandBookService()
      {
         super();
      }

      public function showPage(no:String, pageIndex:int = 0):void
      {
         BookOpener.open(no, pageIndex, false);
      }

      public function showPageBy2Index(no:String, fileIndex:int, classIndex:int):void
      {
         var book:BookInfo = BConfigReader.instence.getBook(no);
         var i:int = book ? book.getPageIndex(fileIndex, classIndex) : 0;
         BookOpener.open(no, i < 0 ? 0 : i, false);
      }

      public function openLog(key:String):void
      {
      }
   }
}
