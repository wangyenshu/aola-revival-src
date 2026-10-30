package mmo.revival.book
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.reader.BConfigReader;
   import mmo.reader.config.BookInfo;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.loader.layer.LayerManager;

   /**
    * REBUILT: opens a book of the era book list (BConfigReader) in a BookView
    * and turns its page buttons into the 2013 actions: btnBuy_<type>_<id>[_<n>]
    * and btnMBuy_ (members) buy through BuyMaterialService<type>,
    * btnjumppage_<n> turns to a page, btnClose closes.
    */
   public class BookOpener
   {
      public static function open(no:String, pageIndex:int, catalog:Boolean):BookView
      {
         var r:BConfigReader = BConfigReader.instence;
         r.loadConfig();
         var book:BookInfo = catalog ? r.getCatalog(no) : r.getBook(no);
         if (book == null) book = catalog ? r.getBook(no) : r.getCatalog(no);
         if (book == null || book.pageCount == 0)
         {
            RLog.log("book: " + no + " has no era pages");
            RNotice.show(LayerManager.getBaseTop(), "这本册子的内容已经找不到了。");
            return null;
         }
         var view:BookView = BookView.open(book, pageIndex);
         var busy:Boolean = false;
         view.onPageClick = function(name:String):Boolean
         {
            var buy:Boolean = name.indexOf("btnBuy_") == 0 || name.indexOf("btnMBuy_") == 0;
            if (buy)
            {
               if (busy) return true;
               var parts:Array = name.substr(name.indexOf("_") + 1).split("_");
               var info:BuyMaterialInfo = new BuyMaterialInfo(int(parts[0]), int(parts[1]), 1, parts.length > 2 ? int(parts[2]) : 1);
               busy = true;
               ServiceContainer.instance.tryGetBuyMaterialService(info.type, function(svc:IBuyMaterial, o:Object):void
               {
                  svc.logSourceKey(no);
                  svc.buy(info, function(ok:Boolean):void { busy = false; view.showMoney(); });
               });
               return true;
            }
            if (name.indexOf("btnjumppage_") == 0)
            {
               view.go(int(name.split("_")[1]) - 1);
               return true;
            }
            return false;
         };
         return view;
      }
   }
}
