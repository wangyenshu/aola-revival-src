package mmo.revival.book
{
   import mmo.common.member.MemberManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.reader.BConfigReader;
   import mmo.reader.config.BookInfo;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.loader.layer.LayerManager;
   import mmo.common.dialog.NewDialog;

   /**
    * REBUILT: opens a book of the era book list (BConfigReader) in a BookView
    * and turns its page buttons into the 2013 actions: btnBuy_<type>_<id>[_<n>]
    * and btnMBuy_ (members) buy through BuyMaterialService<type>, btnSetBuy_<套装> the whole
    * 套装 (BuyMaterialService0's buySet),
    * btnjumppage_<n> turns to a page, btnClose closes.
    */
   public class BookOpener
   {
      private static const EGG_BOOK:String = "catalog201006";

      private static function member():Boolean
      {
         try { return MemberManager.instance.isMember(); } catch (e:Error) {}
         return false;
      }

      public static function open(no:String, pageIndex:int, catalog:Boolean):BookView
      {
         var r:BConfigReader = BConfigReader.instence;
         r.loadConfig();
         var book:BookInfo = catalog ? r.getCatalog(no) : r.getBook(no);
         if (book == null) book = catalog ? r.getBook(no) : r.getCatalog(no);
         // The 收费亚比蛋商品册: its rebuilt first page lists every egg of 2013 that has a price
         // (catalog/egg1, its own pages), so the book is that page alone (its other pages sell
         // some of the same eggs again).
         if (book != null && book.no == EGG_BOOK && book.page.length > 1) book.page = book.page.slice(0, 1);
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
               if (name.indexOf("btnMBuy_") == 0 && !member())
               {
                  NewDialog.showMessage("这件商品只有蓝宝石才能购买哦！");
                  return true;
               }
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
            if (name.indexOf("btnSetBuy_") == 0)
            {
               // 购买全套: the 套装 of that id (ClothesData's ClothesSuit), by catalogservice's
               // BuyMaterialService0 (BuyFlow.buySet there).
               if (busy) return true;
               busy = true;
               var suit:int = int(name.split("_")[1]);
               ServiceContainer.instance.tryGetBuyMaterialService(0, function(svc:IBuyMaterial, o:Object):void
               {
                  svc.logSourceKey(no);
                  Object(svc).buySet(suit, function(ok:Boolean):void { busy = false; view.showMoney(); });
               });
               return true;
            }
            if (name.indexOf("btnjumppage_") == 0)
            {
               // The era BookManagerBase.JumpPage: pageIndex = n, counted from 0 (the cover is _0).
               view.go(int(name.split("_")[1]));
               return true;
            }
            return false;
         };
         return view;
      }
   }
}
