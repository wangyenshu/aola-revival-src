package mmo.zoo.revival
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.control.IControlService;
   import mmo.loader.layer.LayerManager;

   /**
    * REBUILT 动物仓库 of the zoo: the era ZooStorePanel (zoo/zoores_1, 2012) on its art, the
    * strip at the foot of the screen with its tabs 幼仔, 成熟动物, 道具, 装饰物 and 背景, eight
    * squares a page. A 幼仔 clicked goes into the zoo (97_5; the era dragged it to a place,
    * the server places it here); a grown animal is sold (卖出: SellPanel, 97_21); the 道具
    * are the zoo's 饲料 one has (97_11). The 装饰物 and 背景 of the era zoo are not there.
    */
   public class ZooStorePanel extends MovieClip
   {
      public var btnClose:SimpleButton;
      public var btnEmpty:SimpleButton;
      public var btnNext:SimpleButton;
      public var btnPrev:SimpleButton;
      public var pageText:TextField;
      public var tab0:MovieClip;
      public var tab1:MovieClip;
      public var tab2:MovieClip;
      public var tab3:MovieClip;
      public var tab4:MovieClip;

      private static const PAGE:int = 8;
      private static var current:ZooStorePanel;

      private var onPut:Function;
      private var tab:int = -1;
      private var list:Array = [];
      private var page:int;
      private var cards:Array = [];

      /** onPut(reply of 97_5): an animal went into the zoo. */
      public static function show(onPut:Function):void
      {
         hide();
         current = new ZooStorePanel(onPut);
         LayerManager.getBaseTop().addChild(current);
         controlVisible(false);
         var b:Rectangle = current.getBounds(current);
         current.x = Math.round((960 - b.width) / 2 - b.x);
         current.y = Math.round(560 - b.height - 6 - b.y);
      }

      public static function hide():void
      {
         if (current != null)
         {
            current.close();
            controlVisible(true);
         }
         current = null;
      }

      /** The control bar is put away while the strip is open (it stands where the bar is). */
      private static function controlVisible(v:Boolean):void
      {
         try
         {
            var c:Object = ServiceContainer.getService(IControlService);
            if (v) c.show();
            else c.hide();
         }
         catch (e:Error) {}
      }

      public static function get isOpen():Boolean
      {
         return current != null;
      }

      public function ZooStorePanel(onPut:Function)
      {
         super();
         stop();
         this.onPut = onPut;
         name = "zooStorePanel";
         TipsManager.getInstance().addTips(btnClose, "关闭仓库");
         btnEmpty.visible = false;
         btnEmpty.addEventListener(MouseEvent.CLICK, onEmpty);
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { hide(); });
         btnPrev.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if (page > 0) { page--; draw(); } });
         btnNext.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if ((page + 1) * PAGE < list.length) { page++; draw(); } });
         for (var i:int = 0; i < 5; i++)
         {
            var t:MovieClip = this["tab" + i] as MovieClip;
            t.buttonMode = true;
            t.mouseChildren = false;
            t.addEventListener(MouseEvent.CLICK, onTab);
         }
         choose(0);
      }

      private function onTab(e:MouseEvent):void
      {
         choose(int(String(e.currentTarget.name).substr(3)));
      }

      private function choose(i:int):void
      {
         tab = i;
         for (var k:int = 0; k < 5; k++) MovieClip(this["tab" + k]).gotoAndStop(k == i ? 2 : 1);
         list = [];
         page = 0;
         draw();
         var asked:int = tab;
         var fill:Function = function(rows:Array):void
         {
            if (asked != tab || stage == null) return;
            list = rows || [];
            draw();
         };
         if (tab == 0) ZooKit.ask("97_9", {}, function(p:Object):void { fill(p.babys as Array); });
         else if (tab == 1) ZooKit.ask("97_10", {}, function(p:Object):void { fill(p.matrues as Array); });
         else if (tab == 2) ZooKit.ask("97_11", {}, function(p:Object):void { fill(p.items as Array); });
      }

      private function draw():void
      {
         for each (var old:StoreCard in cards) old.dispose();
         cards = [];
         var pages:int = Math.max(1, Math.ceil(list.length / PAGE));
         if (pageText != null) pageText.text = (page + 1) + "/" + pages;
         btnEmpty.visible = tab == 0 && list.length == 0;
         var C:Class = card(tab);
         for (var i:int = 0; i < PAGE && C != null; i++)
         {
            var o:Object = list[page * PAGE + i];
            if (o == null) break;
            var c:StoreCard = new C() as StoreCard;
            if (tab == 2) c.setUp(o, int(o.id), int(o.num), ZooKit.ITEM, String(o.name || "饲料"));
            else c.setUp(o, int(o.raceId), int(o.num), tab == 0 ? ZooKit.BABY : ZooKit.MATURE, ZooKit.nameOf(int(o.raceId), tab == 1));
            c.name = "storeCard" + i;
            c.x = 181.7 + i * 82.1;
            c.y = 56.55;
            if (tab == 0) c.addEventListener(MouseEvent.CLICK, onBaby);
            var sell:SimpleButton = c.getChildByName("sellBtn") as SimpleButton;
            if (sell != null) sell.addEventListener(MouseEvent.CLICK, onSell);
            addChild(c);
            cards.push(c);
         }
      }

      private static function card(tab:int):Class
      {
         var n:String = ["BabyCard", "MatureCard", "ItemCard"][tab];
         if (n == null) return null;
         var full:String = "mmo.zoo.revival." + n;
         return ApplicationDomain.currentDomain.hasDefinition(full) ? ApplicationDomain.currentDomain.getDefinition(full) as Class : null;
      }

      private function onBaby(e:MouseEvent):void
      {
         var c:StoreCard = e.currentTarget as StoreCard;
         ZooKit.ask("97_5", {raceId: c.id}, function(p:Object):void
         {
            var r:int = int(p.res);
            if (r == -2) NewDialog.showMessage("动物园已经住满了，等动物长大收获了再放进来吧。");
            else if (r != 1) NewDialog.showMessage("没有这只幼仔了。");
            if (r == 1 && onPut != null) onPut(p);
            choose(0);
         });
      }

      private function onSell(e:MouseEvent):void
      {
         e.stopPropagation();
         var c:StoreCard = DisplayObject(e.currentTarget).parent as StoreCard;
         if (c == null) return;
         ModalDialogManager.getInstance().addModalDialog(new SellPanel(c.id, c.num, int(c.data.price), function():void { choose(1); }));
      }

      private function onEmpty(e:MouseEvent):void
      {
         ModalDialogManager.getInstance().addModalDialog(new EmptyTip());
      }

      private function close():void
      {
         for each (var c:StoreCard in cards) c.dispose();
         cards = [];
         TipsManager.getInstance().removeTips(btnClose);
         if (parent != null) parent.removeChild(this);
      }
   }
}
