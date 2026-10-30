package mmo.revival.book
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
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
    * REBUILT catalog book (the 2013 book frame was in the lost
    * catalog/bookclubservice; drawn here). Shows the original page art
    * (PageInfo: file catalog/<name><n>.swf, class <prefix><n>_<p>) one page at a
    * time with page turning, the player's 晶币 and a close button. Clicks on the
    * page go to onPageClick (buttons named btnBuy_<type>_<id>[_<count>] etc.).
    */
   public class BookView extends Sprite
   {
      private static var current:BookView;

      public var onPageClick:Function;
      public var onClosed:Function;
      private var book:BookInfo;
      private var index:int;
      private var holder:Sprite;
      private var page:DisplayObject;
      private var pageText:TextField;
      private var moneyText:TextField;
      private var loading:TextField;
      private var token:int;

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
         LayerManager.getBaseTop().addChild(this);
         if (PlayerManager.getInstance().myPlayer) PlayerManager.getInstance().myPlayer.stop();
         SocketClient.instance.addEventListener("onScoreUpdated", onMoney);
         SocketClient.instance.addEventListener(SocketClientEvent.onGetTotalScore, onMoney);
         if (UserInfo.score < 0) SocketClient.instance.getTotalScore(SocketClient.instance.myUserId);
         showMoney();
         go(Math.max(0, Math.min(index, book.pageCount - 1)));
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

         loading = label(14, 0xFFFFFF, true);
         loading.text = "正在翻开" + (book.name || "商品册") + "……";
         loading.x = (960 - loading.width) / 2;
         loading.y = 260;
         addChild(loading);

         var bar:Sprite = new Sprite();
         var m:Matrix = new Matrix();
         m.createGradientBox(420, 36, Math.PI / 2);
         bar.graphics.lineStyle(2, 0xFFFFFF);
         bar.graphics.beginGradientFill(GradientType.LINEAR, [0x4FB3F0, 0x1F6FBF], [1, 1], [0, 255], m);
         bar.graphics.drawRoundRect(0, 0, 420, 36, 30, 30);
         bar.graphics.endFill();
         bar.x = (960 - 420) / 2;
         bar.y = 514;
         bar.filters = [new DropShadowFilter(2, 90, 0, 0.4, 4, 4)];
         addChild(bar);

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

         var money:Sprite = new Sprite();
         money.graphics.lineStyle(2, 0xFFFFFF);
         money.graphics.beginFill(0xF6B21B);
         money.graphics.drawRoundRect(0, 0, 150, 30, 26, 26);
         money.graphics.endFill();
         money.x = 24;
         money.y = 517;
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
         close.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); close_(); });
         addChild(close);
      }

      private function close_():void
      {
         close();
      }

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
         pageText.text = (index + 1) + " / " + book.pageCount;
         pageText.x = (420 - pageText.width) / 2;
         var info:PageInfo = book.page[index] as PageInfo;
         var my:int = ++token;
         loading.visible = true;
         var show:Function = function(d:*):void
         {
            if (my != token || parent == null) return;
            loading.visible = false;
            if (!ApplicationDomain.currentDomain.hasDefinition(info.className))
            {
               RLog.log("book: no page class " + info.className + " in " + info.fileName);
               return;
            }
            try
            {
               var C:Class = getDefinitionByName(info.className) as Class;
               setPage(new C() as DisplayObject);
            }
            catch (e:Error)
            {
               RLog.error("book page " + info.className, e);
            }
         };
         if (ApplicationDomain.currentDomain.hasDefinition(info.className)) show(null);
         else ResScheduler.getResource(info.fileName, show, info.className, function(e:*):void
         {
            if (my == token) { loading.text = "这一页丢失了"; loading.visible = true; }
         });
      }

      private function setPage(d:DisplayObject):void
      {
         if (page != null)
         {
            page.removeEventListener(MouseEvent.CLICK, onClick, true);
            if (page is MovieClip) MovieClip(page).stop();
            if (page.parent) page.parent.removeChild(page);
         }
         page = d;
         var b:Object = page.getBounds(page);
         page.x = Math.round((960 - b.width) / 2 - b.left);
         page.y = Math.round((520 - b.height) / 2 - b.top);
         holder.addChild(page);
         page.addEventListener(MouseEvent.CLICK, onClick, true);
      }

      private function onClick(e:MouseEvent):void
      {
         var t:DisplayObject = e.target as DisplayObject;
         while (t != null && t != page)
         {
            if (t.name && t.name.indexOf("instance") != 0)
            {
               if (t.name.indexOf("btnClose") == 0) { e.stopImmediatePropagation(); close(); return; }
               if (onPageClick != null && onPageClick(t.name) === true) { e.stopImmediatePropagation(); return; }
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
         moneyText.text = "晶币  " + (UserInfo.score < 0 ? "…" : String(UserInfo.score));
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("onScoreUpdated", onMoney);
         SocketClient.instance.removeEventListener(SocketClientEvent.onGetTotalScore, onMoney);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
         if (onClosed != null) onClosed();
      }
   }
}
