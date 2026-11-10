package mmo.revival.book
{
   import mmo.common.dialog.NewDialog;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.ColorMatrixFilter;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.display.GradientType;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.reader.config.BookInfo;
   import mmo.reader.config.PageInfo;
   import mmo.revival.RLog;

   /**
    * REBUILT catalog book (the 2013 book frame was in the lost catalog/bookclubservice). Its
    * frame is the book's own, as the later bookclubservice and catalogservice took it:
    *   - a 商品册 of the era has a <prefix>PageBar in its first file (<file>1): the desk under
    *     the pages with their 上一页 / 下一页 (btnPrevPage, btnNextPage), the page numbers
    *     (btnPage0–6, seven to a group, btnPrevGroup / btnNextGroup), the money (yellowM 晶币,
    *     blueM 星币, jingdouM 晶豆) and maybe its close (btnClose); the pages go in its
    *     "container" (SellBookService.onGetBar). The 收费道具 and 收费家具 books' first files
    *     are lost: they take the desk of the book of their kind (道具, 家具) without its row
    *     of money (it would lie over their prices), RECONSTRUCTED.
    *   - a 周刊 has a <prefix>1_Container (catalogservice BookService), a handbook a
    *     <prefix>Container (HandBookService): its "container" holds the pages, "txtpage" the
    *     page number.
    *   - else the page alone, in stage coordinates, with the drawn 上一页 / 下一页 bar and the
    *     player's 晶币 here, for pages without their own.
    * A close is drawn only when neither the frame nor the page has its own (btnClose…, any case).
    * Clicks on the page go to onPageClick (buttons named btnBuy_<type>_<id>[_<count>] etc.).
    */
   public class BookView extends Sprite
   {
      private static var current:BookView;
      /** The books whose first file is lost, and the desk of their kind. */
      private static const BORROW:Object = {
         "mmo.itemcatalog.Tool": ["catalog/item1", "mmo.itemcatalog.ItemPageBar"],
         "mmo.funiturecatalog.RMBFurniture": ["catalog/jiaju1", "mmo.funiturecatalog.FurniturePageBar"]
      };
      private static const GROUP:int = 7;
      /** Files loaded here already (their classes are known, or known missing). */
      private static var loaded:Object = {};

      public var onPageClick:Function;
      public var onClosed:Function;
      private var book:BookInfo;
      private var index:int = -1;
      private var holder:Sprite;
      private var frame:DisplayObjectContainer;
      private var pageParent:DisplayObjectContainer;
      private var mode:String = "none";
      private var group:int;
      private var page:DisplayObject;
      private var pageText:TextField;
      private var moneyText:TextField;
      private var loading:TextField;
      private var token:int;
      /** The drawn 上一页 / 下一页 bar, 晶币 and close button: for pages without their own. */
      private var bar:Sprite;
      private var money:Sprite;
      private var closeBtn:Sprite;

      public static function open(book:BookInfo, index:int):BookView
      {
         if (current != null) current.close();
         current = new BookView(book, index);
         return current;
      }

      public function BookView(book:BookInfo, index:int)
      {
         super();
         this.book = book;
         build();
         // Over what is shown: a panel that took the layers over (the 图鉴's 属性克制 opens a handbook) is on the fight layer.
         (LayerManager.getCurrentLayer() == LayerManager.BASE_LAYER ? LayerManager.getBaseTop() : LayerManager.getFightingTop()).addChild(this);
         if (PlayerManager.getInstance().myPlayer) PlayerManager.getInstance().myPlayer.stop();
         SocketClient.instance.addEventListener("onScoreUpdated", onMoney);
         SocketClient.instance.addEventListener(SocketClientEvent.onGetTotalScore, onMoney);
         SocketClient.instance.addEventListener("onXingBiUpdate", onMoney);
         if (UserInfo.score < 0) SocketClient.instance.getTotalScore(SocketClient.instance.myUserId);
         addEventListener(MouseEvent.CLICK, onClick, true);
         showMoney();
         var start:int = Math.max(0, Math.min(index, book.pageCount - 1));
         findFrame(frames(), function():void { go(start); });
      }

      private function build():void
      {
         var dim:Sprite = new Sprite();
         dim.graphics.beginFill(0x000000, 0.45);
         dim.graphics.drawRect(0, 0, 960, 560);
         dim.graphics.endFill();
         dim.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         addChild(dim);

         holder = new Sprite();
         addChild(holder);
         pageParent = holder;

         loading = label(14, 0xFFFFFF, true);
         loading.text = "正在翻开" + (book.name || "商品册") + "……";
         loading.x = (960 - loading.width) / 2;
         loading.y = 260;
         addChild(loading);

         bar = new Sprite();
         var m:Matrix = new Matrix();
         m.createGradientBox(420, 36, Math.PI / 2);
         bar.graphics.lineStyle(2, 0xFFFFFF);
         bar.graphics.beginGradientFill(GradientType.LINEAR, [0x4FB3F0, 0x1F6FBF], [1, 1], [0, 255], m);
         bar.graphics.drawRoundRect(0, 0, 420, 36, 30, 30);
         bar.graphics.endFill();
         bar.x = (960 - 420) / 2;
         bar.y = 514;
         bar.filters = [new DropShadowFilter(2, 90, 0, 0.4, 4, 4)];
         bar.visible = false;
         // A book of one page has nothing to turn to (the 收费亚比蛋商品册: its page turns itself).
         if (book.pageCount > 1) addChild(bar);

         var prev:Sprite = button("◀ 上一页", function():void { go(index - 1); });
         prev.name = "bookPrev";
         prev.x = 14;
         prev.y = 8;
         bar.addChild(prev);
         pageText = label(14, 0xFFFFFF, true);
         pageText.y = 8;
         bar.addChild(pageText);
         var next:Sprite = button("下一页 ▶", function():void { go(index + 1); });
         next.name = "bookNext";
         next.x = 420 - next.width - 14;
         next.y = 8;
         bar.addChild(next);

         money = new Sprite();
         money.graphics.lineStyle(2, 0xFFFFFF);
         money.graphics.beginFill(0xF6B21B);
         money.graphics.drawRoundRect(0, 0, 230, 30, 26, 26);
         money.graphics.endFill();
         money.x = 24;
         money.y = 517;
         money.visible = false;
         addChild(money);
         moneyText = label(14, 0xFFFFFF, true);
         moneyText.filters = [new GlowFilter(0x9A5A00, 1, 3, 3, 6)];
         moneyText.x = 12;
         moneyText.y = 5;
         money.addChild(moneyText);

         var close:Sprite = new Sprite();
         close.buttonMode = true;
         close.graphics.lineStyle(2.5, 0xFFFFFF);
         close.graphics.beginFill(0xD9452B);
         close.graphics.drawCircle(0, 0, 15);
         close.graphics.endFill();
         close.graphics.lineStyle(3, 0xFFFFFF);
         close.graphics.moveTo(-6, -6); close.graphics.lineTo(6, 6);
         close.graphics.moveTo(6, -6); close.graphics.lineTo(-6, 6);
         close.name = "bookClose";
         close.x = 924;
         close.y = 36;
         close.visible = false;
         close.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); close_(); });
         addChild(close);
         closeBtn = close;
      }

      private function close_():void
      {
         close();
      }

      // ---------------------------------------------------------------- the frame

      /** Where the book's frame may be: [file, class, mode]. */
      private function frames():Array
      {
         var out:Array = [];
         var first:PageInfo = book.page[0] as PageInfo;
         for each (var p:PageInfo in book.page) if (p.fileNameIndex == 1) { first = p; break; }
         var split:Boolean = first != null && first.fileName != book.file;
         if (split) out.push([book.file + "1", book.classPrefix + "PageBar", "bar"]);
         if (BORROW[book.classPrefix]) out.push([BORROW[book.classPrefix][0], BORROW[book.classPrefix][1], "borrowed"]);
         if (first != null) out.push([first.fileName, book.classPrefix + "1_Container", "container"]);
         if (split) out.push([book.file + "1", book.classPrefix + "Container", "container"]);
         return out;
      }

      /** The first of the frames there is (loading their files as needed), then done(). */
      private function findFrame(list:Array, done:Function):void
      {
         if (parent == null) return;
         if (list.length == 0)
         {
            useFrame(null, "none", done);
            return;
         }
         var f:Array = list.shift();
         var file:String = f[0], cls:String = f[1];
         if (ApplicationDomain.currentDomain.hasDefinition(cls))
         {
            useFrame(cls, f[2], done);
            return;
         }
         if (loaded[file])
         {
            findFrame(list, done);
            return;
         }
         // Without a class name: a missing one would leave the 2013 ResScheduler's loader taken.
         ResScheduler.getResource(file, function(d:* = null):void
         {
            loaded[file] = true;
            if (ApplicationDomain.currentDomain.hasDefinition(cls)) useFrame(cls, f[2], done);
            else findFrame(list, done);
         }, "", function(e:* = null):void
         {
            loaded[file] = true;
            findFrame(list, done);
         });
      }

      private function useFrame(cls:String, kind:String, done:Function):void
      {
         if (parent == null) return;
         if (cls != null)
         {
            try
            {
               var C:Class = getDefinitionByName(cls) as Class;
               var f:DisplayObjectContainer = new C() as DisplayObjectContainer;
               if (f != null)
               {
                  frame = f;
                  mode = kind;
                  if (f is MovieClip) MovieClip(f).stop();
                  holder.addChild(f);
                  pageParent = (f.getChildByName("container") as DisplayObjectContainer) || f;
                  RLog.log("book " + book.no + ": frame " + cls);
               }
            }
            catch (e:Error) { RLog.error("book frame " + cls, e); }
         }
         if (mode == "borrowed")
         {
            // Another book's desk: its row of money would lie over this book's pages (their prices).
            mode = "bar";
            hideMoneyRow();
         }
         if (mode == "bar") wireBar();
         // While the first page loads (or if it is lost), a way out.
         closeBtn.visible = !has(frame, ["btnclose"]);
         done();
      }

      private function wireBar():void
      {
         for each (var n:String in ["yellowM", "blueM", "jingdouM"])
         {
            var t:TextField = frame.getChildByName(n) as TextField;
            if (t != null) t.selectable = false;
         }
         for (var i:int = 0; i < GROUP; i++)
         {
            var b:MovieClip = frame.getChildByName("btnPage" + i) as MovieClip;
            if (b == null) continue;
            b.gotoAndStop(1);
            b.buttonMode = true;
            b.mouseChildren = false;
         }
         showMoney();
      }

      /** The desk's money (yellowM, blueM, jingdouM) and the coins drawn beside them. */
      private function hideMoneyRow():void
      {
         var row:Rectangle = null;
         for each (var n:String in ["yellowM", "blueM", "jingdouM"])
         {
            var t:DisplayObject = frame.getChildByName(n);
            if (t == null) continue;
            var b:Rectangle = t.getBounds(frame);
            row = row == null ? b : row.union(b);
         }
         if (row == null) return;
         row.inflate(30, 8);
         for (var i:int = 0; i < frame.numChildren; i++)
         {
            var d:DisplayObject = frame.getChildAt(i);
            if (d == pageParent || d.name.indexOf("btn") == 0) continue;
            var c:Rectangle = d.getBounds(frame);
            if (row.contains(c.x + c.width / 2, c.y + c.height / 2) && c.height < 40) d.visible = false;
         }
      }

      private function named(n:String):DisplayObject
      {
         return frame != null ? frame.getChildByName(n) : null;
      }

      private static function gray(d:DisplayObject, off:Boolean):void
      {
         if (d == null) return;
         d.filters = off ? [new ColorMatrixFilter([0.3, 0.59, 0.11, 0, 0, 0.3, 0.59, 0.11, 0, 0, 0.3, 0.59, 0.11, 0, 0, 0, 0, 0, 1, 0])] : [];
         if (d is InteractiveObject) InteractiveObject(d).mouseEnabled = !off;
      }

      /** The desk's page numbers, its group and its turning buttons, for page `index`. */
      private function showBar():void
      {
         var groups:int = Math.max(1, Math.ceil(book.pageCount / GROUP));
         group = Math.max(0, Math.min(groups - 1, group));
         for (var i:int = 0; i < GROUP; i++)
         {
            var b:MovieClip = named("btnPage" + i) as MovieClip;
            if (b == null) continue;
            var n:int = group * GROUP + i;
            b.visible = n < book.pageCount;
            b.gotoAndStop(n == index ? 2 : 1);
            var t:TextField = b.getChildByName("txtPage") as TextField;
            if (t != null)
            {
               t.mouseEnabled = false;
               t.text = String(n + 1);
            }
         }
         gray(named("btnPrevGroup"), group == 0);
         gray(named("btnNextGroup"), group >= groups - 1);
         gray(named("btnPrevPage"), index <= 0);
         gray(named("btnNextPage"), index >= book.pageCount - 1);
      }

      // ---------------------------------------------------------------- pages

      private static function label(size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         return t;
      }

      private static function button(text:String, f:Function):Sprite
      {
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         var t:TextField = label(14, 0xFFFFFF, true);
         t.text = text;
         b.addChild(t);
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
         b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { t.textColor = 0xFFE066; });
         b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { t.textColor = 0xFFFFFF; });
         return b;
      }

      public function go(i:int):void
      {
         if (book.pageCount == 0 || i < 0 || i >= book.pageCount) return;
         index = i;
         group = int(index / GROUP);
         pageText.text = (index + 1) + " / " + book.pageCount;
         pageText.x = (420 - pageText.width) / 2;
         var txt:TextField = named("txtpage") as TextField;
         if (txt != null) txt.text = (index + 1) + "/" + book.pageCount;
         if (mode == "bar") showBar();
         var info:PageInfo = book.page[index] as PageInfo;
         var my:int = ++token;
         // The last page's "lost" must not stay on while this one loads.
         loading.text = "正在打开这一页……";
         loading.x = (960 - loading.width) / 2;
         loading.visible = true;
         var show:Function = function(d:* = null):void
         {
            if (my != token || parent == null) return;
            loaded[info.fileName] = true;
            if (!ApplicationDomain.currentDomain.hasDefinition(info.className))
            {
               RLog.log("book: no page class " + info.className + " in " + info.fileName);
               lost();
               return;
            }
            loading.visible = false;
            try
            {
               var C:Class = getDefinitionByName(info.className) as Class;
               setPage(new C() as DisplayObject);
            }
            catch (e:Error)
            {
               RLog.error("book page " + info.className, e);
               lost();
            }
         };
         var lost:Function = function(e:* = null):void
         {
            if (my != token) return;
            loading.text = "这一页丢失了";
            loading.x = (960 - loading.width) / 2;
            loading.visible = true;
            if (!has(frame, ["btnclose"])) closeBtn.visible = true;
         };
         if (ApplicationDomain.currentDomain.hasDefinition(info.className)) show(null);
         else if (loaded[info.fileName]) lost();
         // Without a class name: a missing one would leave the 2013 ResScheduler's loader taken
         // (it throws before it lets the loader go), and no book would open after it.
         else ResScheduler.getResource(info.fileName, show, "", lost);
      }

      private function setPage(d:DisplayObject):void
      {
         if (page != null)
         {
            if (page is MovieClip) MovieClip(page).stop();
            if (page.parent) page.parent.removeChild(page);
         }
         page = d;
         if (mode != "none")
         {
            // In the frame's container, where the book drew them.
            page.x = 0;
            page.y = 0;
         }
         else
         {
            // The pages are drawn in stage coordinates (the original BookService
            // puts them at 0, 0 of a full-screen container): those stay there,
            // even with a piece far off the stage (tool55: a cloud left over from
            // an animation); a page drawn about another origin is centred.
            var b:Rectangle = page.getBounds(page);
            if (inStage(b) || (page is DisplayObjectContainer && mostlyInStage(DisplayObjectContainer(page))))
            {
               page.x = 0;
               page.y = 0;
            }
            else
            {
               page.x = Math.round((960 - b.width) / 2 - b.left);
               page.y = Math.round((520 - b.height) / 2 - b.top);
            }
         }
         // Under the desk's buttons (the frame's container lies under them).
         pageParent.addChild(page);
         var own:DisplayObjectContainer = page as DisplayObjectContainer;
         var turns:Boolean = has(own, ["btnback", "btnnext"]) || has(frame, ["btnback", "btnnext"]);
         var closes:Boolean = has(own, ["btnclose"]) || has(frame, ["btnclose"]);
         // The drawn ones only where the book has none of its own (the 周刊 and handbooks sell
         // nothing: the 晶币 would cover their 上一页).
         bar.visible = mode == "none" && !turns;
         money.visible = mode == "none" && !turns;
         closeBtn.visible = !closes;
         if (mode == "container") for each (var n:String in ["btnback", "btnnext"]) if (named(n)) gray(named(n), n == "btnback" ? index <= 0 : index >= book.pageCount - 1);
      }

      /** Has c (deep) a child whose name starts with one of the prefixes (any case)? */
      private static function has(c:DisplayObjectContainer, prefixes:Array):Boolean
      {
         if (c == null) return false;
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var d:DisplayObject = c.getChildAt(i);
            var n:String = d.name ? d.name.toLowerCase() : "";
            for each (var p:String in prefixes) if (n.indexOf(p) == 0 && n.indexOf("btnnextgroup") != 0 && n.indexOf("btnnextpage") != 0) return true;
            if (d is DisplayObjectContainer && has(DisplayObjectContainer(d), prefixes)) return true;
         }
         return false;
      }

      private static function inStage(b:Rectangle):Boolean
      {
         return b.left >= -40 && b.top >= -40 && b.right <= 1000 && b.bottom <= 600;
      }

      /** Most of a page's pieces have their middle on the stage. */
      private static function mostlyInStage(p:DisplayObjectContainer):Boolean
      {
         var on:int = 0;
         for (var i:int = 0; i < p.numChildren; i++)
         {
            var cb:Rectangle = p.getChildAt(i).getBounds(p);
            var cx:Number = cb.x + cb.width / 2;
            var cy:Number = cb.y + cb.height / 2;
            if (cx >= 0 && cx <= 960 && cy >= 0 && cy <= 560) on++;
         }
         return p.numChildren > 0 && on * 2 > p.numChildren;
      }

      /** Clicks on the frame and the page: their own buttons, then onPageClick. */
      private function onClick(e:MouseEvent):void
      {
         var t:DisplayObject = e.target as DisplayObject;
         while (t != null && t != this && t != holder)
         {
            var n:String = t.name || "";
            var low:String = n.toLowerCase();
            if (n && n.indexOf("instance") != 0 && t != closeBtn && t != bar && t.parent != bar)
            {
               var done:Boolean = true;
               if (low.indexOf("btnclose") == 0) close();
               else if (n == "btnPrevGroup") { group--; showBar(); }
               else if (n == "btnNextGroup") { group++; showBar(); }
               else if (n == "btnPrevPage" || low.indexOf("btnback") == 0) go(index - 1);
               else if (n == "btnNextPage" || low.indexOf("btnnext") == 0) go(index + 1);
               else if (/^btnPage\d$/.test(n) && t.parent == frame) go(group * GROUP + int(n.charAt(7)));
               else if (n == "btnReturn" || low == "btnhomepage") go(0);
               else if (n.indexOf("btnjumppage_") == 0 && n.split("_").length >= 3) go(Math.max(0, book.getPageIndex(int(n.split("_")[1]), int(n.split("_")[2]))));
               else if (n == "btnBlue") NewDialog.showMessage("蓝宝石可以在工具箱里开通哦！");
               else if (n == "btnStarCoin" || n == "btnbuysth") NewDialog.showMessage("星币可以在工具箱里得到哦！");
               else done = onPageClick != null && onPageClick(n) === true;
               if (done)
               {
                  e.stopImmediatePropagation();
                  return;
               }
            }
            t = t.parent;
         }
      }

      private function onMoney(e:*):void
      {
         showMoney();
      }

      public function showMoney():void
      {
         var score:String = UserInfo.score < 0 ? "…" : String(UserInfo.score);
         moneyText.text = "晶币  " + score + "    星币  " + UserInfo.xingbi;
         var put:Function = function(n:String, s:String):void
         {
            var t:TextField = named(n) as TextField;
            if (t != null) t.text = s;
         };
         var jd:Object = null;
         try { jd = Object(UserInfo)["jingdou"]; } catch (e:Error) {}
         put("yellowM", score);
         put("blueM", String(UserInfo.xingbi));
         put("jingdouM", jd == null ? "0" : String(jd));
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("onScoreUpdated", onMoney);
         SocketClient.instance.removeEventListener(SocketClientEvent.onGetTotalScore, onMoney);
         SocketClient.instance.removeEventListener("onXingBiUpdate", onMoney);
         removeEventListener(MouseEvent.CLICK, onClick, true);
         if (page is MovieClip) MovieClip(page).stop();
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
         if (onClosed != null) onClosed();
      }
   }
}
