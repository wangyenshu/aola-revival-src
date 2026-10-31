package mmo.scene.library
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.catalog.IBookService;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.weekly.WeeklyIssues;

   /**
    * REBUILT: the library's shelf of 奥拉周刊 back issues (the 2012 往期周刊;
    * its panel is lost), drawn in the look of the rebuilt panels: every
    * issue the catalog list has (weekly<n>, rebuild/gen/bconfig), newest
    * first, and the era books 亚比手册 (book201004) and 蓝宝石最新消息
    * (book201012). A click opens the issue as WeeklyService opens the
    * current one (IBookService.showCatalog).
    */
   public class LibraryShelf extends Sprite
   {
      private static const W:int = 620;
      private static const H:int = 440;
      private static const COLS:int = 6;
      private static const ROWS:int = 5;
      private static var current:LibraryShelf;

      private var box:Sprite;
      private var grid:Sprite;
      private var pageText:TextField;
      private var page:int;
      private var issues:Array;

      public static function show():void
      {
         if (current != null) current.close();
         current = new LibraryShelf();
         LayerManager.getBaseTop().addChild(current);
      }

      public function LibraryShelf()
      {
         super();
         name = "libraryShelf";
         issues = WeeklyIssues.ISSUES.concat().sort(Array.NUMERIC | Array.DESCENDING);
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "往期周刊", close, "shelfClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         var books:Array = [["亚比手册", "book201004"], ["蓝宝石最新消息", "book201012"]];
         for (var i:int = 0; i < books.length; i++)
         {
            var b:Sprite = RUI.button(books[i][0], openBook(books[i][1]), 140, 28, 0x9FD8FF, 0x3A8FD8, "shelfBook" + i);
            b.x = 24 + i * 150;
            b.y = 50;
            box.addChild(b);
         }
         var note:TextField = RUI.text(12, 0x557799, false);
         note.text = "奥拉周刊 " + issues.length + " 期";
         note.x = W - 24 - note.width;
         note.y = 56;
         box.addChild(note);
         box.addChild(RUI.well(16, 88, W - 32, 290));
         grid = new Sprite();
         grid.x = 28;
         grid.y = 98;
         box.addChild(grid);
         pageText = RUI.text(13, RUI.BLUE, true);
         pageText.y = 390;
         box.addChild(pageText);
         var prev:Sprite = RUI.smallButton("◀", function():void { go(page - 1); }, 34, 24, "shelfPrev");
         prev.x = W / 2 - 90;
         prev.y = 388;
         box.addChild(prev);
         var next:Sprite = RUI.smallButton("▶", function():void { go(page + 1); }, 34, 24, "shelfNext");
         next.x = W / 2 + 56;
         next.y = 388;
         box.addChild(next);
         go(0);
      }

      private function go(p:int):void
      {
         while (grid.numChildren) grid.removeChildAt(0);
         var per:int = COLS * ROWS;
         var pages:int = Math.max(1, Math.ceil(issues.length / per));
         page = Math.max(0, Math.min(p, pages - 1));
         pageText.text = (page + 1) + " / " + pages;
         pageText.x = W / 2 - pageText.width / 2;
         for (var i:int = 0; i < per && page * per + i < issues.length; i++)
         {
            var n:int = issues[page * per + i];
            var b:Sprite = RUI.button("第" + n + "期", openIssue(n), 88, 46, 0xFFE09A, 0xF0A030, "issue_" + n);
            b.x = (i % COLS) * 94;
            b.y = int(i / COLS) * 56;
            grid.addChild(b);
         }
      }

      private function openIssue(n:int):Function
      {
         return function():void
         {
            close();
            ServiceContainer.instance.tryGetService(IBookService, function(svc:IBookService, o:Object):void
            {
               try { svc.showCatalog("weekly" + n); } catch (e:Error) { RLog.error("shelf weekly" + n, e); }
            });
         };
      }

      private function openBook(no:String):Function
      {
         return function():void
         {
            close();
            ServiceContainer.instance.tryGetService(ServiceNames.HandBookService, function(svc:Object, o:Object):void
            {
               try { svc.showPage(no); } catch (e:Error) { RLog.error("shelf " + no, e); }
            });
         };
      }

      public function close():void
      {
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
