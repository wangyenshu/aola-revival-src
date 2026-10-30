package mmo.rmbshoppingmallservice
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMall;
   import mmo.interfaces.rmbshoppingmall.RmbShoppingMallTab;

   /**
    * REBUILT 商城 (RmbShoppingMallService, IRmbShoppingMall). The January 2013
    * mall panel and its code are lost (the live one is a 2023 redesign). The
    * goods it sold are in the era's 收费 catalog books, whose pages survive:
    * 收费服装商品册 (catalog201004), 收费道具商品册 (catalog201005),
    * 收费家具商品册 (catalog201010) and 收费亚比蛋商品册 (catalog201006). The
    * panel here (drawn) chooses one; the book opens through SellBookService.
    * showRmbShoppingPanel(tab) with a RmbShoppingMallTab opens that one's
    * book at once.
    */
   public class RmbShoppingMallService extends EventDispatcher implements IRmbShoppingMall
   {
      private static const BOOKS:Array = [
         ["服装", "catalog201004", RmbShoppingMallTab.CLOTHES_TAB],
         ["道具", "catalog201005", RmbShoppingMallTab.ITEM_TAB],
         ["家具", "catalog201010", RmbShoppingMallTab.FURNITURE_TAB],
         ["亚比蛋", "catalog201006", RmbShoppingMallTab.PETEGG_TAB]
      ];

      private var panel:Sprite;

      public function RmbShoppingMallService()
      {
         super();
      }

      public function get isShowing():Boolean
      {
         return panel != null && panel.stage != null;
      }

      public function showRmbShoppingPanel(tab:int = 0):void
      {
         for each (var b:Array in BOOKS)
         {
            if (tab != RmbShoppingMallTab.HOT_NEW_TAB && b[2] == tab)
            {
               openBook(b[1]);
               return;
            }
         }
         if (panel == null) panel = build();
         if (!isShowing) ModalDialogManager.getInstance().addModalDialog(panel);
      }

      private function close():void
      {
         if (isShowing) ModalDialogManager.getInstance().removeModalDialog(panel);
      }

      private function openBook(no:String):void
      {
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService, function(svc:IBookClubService, o:Object):void
         {
            svc.showPage(no);
         });
      }

      private function build():Sprite
      {
         var p:Sprite = new Sprite();
         p.name = "rmbMallPanel";
         var W:int = 420, H:int = 230;
         p.graphics.lineStyle(3, 0xFFFFFF);
         p.graphics.beginFill(0x2C8BE0);
         p.graphics.drawRoundRect(0, 0, W, H, 28, 28);
         p.graphics.endFill();
         p.graphics.lineStyle();
         p.graphics.beginFill(0xD8F0FF);
         p.graphics.drawRoundRect(12, 52, W - 24, H - 64, 18, 18);
         p.graphics.endFill();
         p.filters = [new GlowFilter(0x0B3C78, 0.8, 8, 8, 2)];
         var title:TextField = text("奥拉商城", 26, 0xFFFFFF, true);
         title.filters = [new GlowFilter(0x0B3C78, 1, 4, 4, 6)];
         title.x = 0;
         title.width = W;
         title.y = 10;
         p.addChild(title);
         for (var i:int = 0; i < BOOKS.length; i++)
         {
            var btn:Sprite = new Sprite();
            btn.name = "mallBook" + i;
            btn.buttonMode = true;
            btn.mouseChildren = false;
            btn.graphics.lineStyle(2, 0xFFFFFF);
            btn.graphics.beginFill(0xFF9A1F);
            btn.graphics.drawRoundRect(0, 0, 84, 120, 16, 16);
            btn.graphics.endFill();
            var label:TextField = text(BOOKS[i][0], 20, 0xFFFFFF, true);
            label.filters = [new GlowFilter(0x9A4A00, 1, 3, 3, 6)];
            label.width = 84;
            label.y = 44;
            btn.addChild(label);
            btn.x = 26 + i * 96;
            btn.y = 76;
            btn.addEventListener(MouseEvent.CLICK, onBook);
            p.addChild(btn);
         }
         var x:Sprite = new Sprite();
         x.name = "mallClose";
         x.buttonMode = true;
         x.graphics.lineStyle(2, 0xFFFFFF);
         x.graphics.beginFill(0xD9452B);
         x.graphics.drawCircle(0, 0, 14);
         x.graphics.endFill();
         x.graphics.lineStyle(3, 0xFFFFFF);
         x.graphics.moveTo(-5, -5); x.graphics.lineTo(5, 5);
         x.graphics.moveTo(5, -5); x.graphics.lineTo(-5, 5);
         x.x = W - 6;
         x.y = 6;
         x.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         p.addChild(x);
         return p;
      }

      private function onBook(e:MouseEvent):void
      {
         var i:int = int(String(Sprite(e.currentTarget).name).substr(8));
         close();
         openBook(BOOKS[i][1]);
      }

      private static function text(s:String, size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         var f:TextFormat = new TextFormat("SimSun", size, color, bold);
         f.align = TextFormatAlign.CENTER;
         t.defaultTextFormat = f;
         t.selectable = false;
         t.mouseEnabled = false;
         t.height = size + 10;
         t.text = s;
         return t;
      }
   }
}
