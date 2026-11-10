package mmo.superevolution
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Matrix;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;
   import mmo.revival.RLog;

   /**
    * REBUILT pet/superevolution (the 超进化机; config of 7 February 2013: pet/superevolution v130131,
    * that file lost): the code of its copy of 2015 on the 2013 libraries, on that copy's art. The
    * 2015 machine shows 14 超进化 on two pages; the 2013 one had the nine of then (SuperEvolutionConfig
    * .ERA), so its cards are those of the art put in that order, eight to a page, the 2015 art's
    * "?" cards after them (RECONSTRUCTED: the 2013 layout is lost). A card opens the 超进化 (EvoPanel);
    * 超进化手册 opens book201103; the gift is the 2013 限量超进化礼包 (item 337, for 蓝宝石), where the
    * 2015 machine sold a later 礼包.
    */
   public class SuperEvolutionPanel extends MovieClip
   {
      public var cijiIcon:MovieClip;
      public var chaoIcon:MovieClip;
      public var jinhuaTxt:TextField;
      public var cijiTxt:TextField;
      public var btnClose:SimpleButton;
      public var btnNext:SimpleButton;
      public var btnPrevious:SimpleButton;
      public var btnBuy265:SimpleButton;
      public var btnBuy266:SimpleButton;
      public var btnBook:SimpleButton;
      public var btnGiftBag:SimpleButton;
      public var pet_2267:SimpleButton;
      public var pet_2255:SimpleButton;
      public var pet_2051:SimpleButton;
      public var pet_2052:SimpleButton;
      public var pet_502:SimpleButton;
      public var pet_500:SimpleButton;
      public var pet_501:SimpleButton;
      public var pet_506:SimpleButton;
      public var pet_1159:SimpleButton;
      public var pet_1380:SimpleButton;
      public var pet_505:SimpleButton;
      public var pet_1134:SimpleButton;
      public var pet_209:SimpleButton;
      public var pet_1451:SimpleButton;

      /** The cards' places (their top left), as the art has them: four across, two down. */
      private static const COLS:Array = [155.25, 328.1, 500.85, 673.55];
      private static const ROWS:Array = [151.85, 316.8];
      /** Where each card of the art is: [frame, column, row]. */
      private static const HOME:Object = {
         502: [1, 0, 1], 500: [1, 1, 1], 501: [1, 2, 1], 506: [1, 3, 1],
         1159: [2, 0, 0], 1380: [2, 1, 0], 505: [2, 2, 0], 1134: [2, 3, 0], 209: [2, 0, 1]
      };
      private static const PER_PAGE:int = 8;
      private static const GIFT:int = 337;

      private var cards:Sprite = new Sprite();
      private var buttons:Object = {};
      private var question:BitmapData;
      private var page:int;
      private var prev:SimpleButton;

      public function SuperEvolutionPanel()
      {
         super();
         gotoAndStop(1);
         arrange();
         refreshItem();
         addEventListener(MouseEvent.CLICK, clickBtn);
         SocketClient.instance.addEventListener("onAmountUpdated", onAmount);
         addEventListener(Event.REMOVED_FROM_STAGE, dispose);
      }

      /**
       * The cards of both frames taken into one layer (this stays on frame 1), each moved by the
       * distance between its place in the art and its place here; the "?" card is a picture of
       * frame 2's.
       */
      private function arrange():void
      {
         // Frame 2 first: going back to frame 1 makes frame 1's cards anew, so those are taken after.
         var id:*;
         gotoAndStop(2);
         for (id in HOME) if (HOME[id][0] == 2) take(int(id));
         var p:DisplayObject = getChildByName("btnPrevious");
         if (p is SimpleButton)
         {
            prev = SimpleButton(p);
            var px:Number = prev.x, py:Number = prev.y;
            removeChild(prev);
            prev.x = px;
            prev.y = py;
         }
         // The "?" card (frame 2's last place) as a picture.
         // (the gift's picture reaches over that place: out of the picture)
         var gift:DisplayObject = getChildByName("btnGiftBag");
         if (gift != null) gift.visible = false;
         try
         {
            question = new BitmapData(156, 156, true, 0);
            question.draw(this, new Matrix(1, 0, 0, 1, -(COLS[3] - 4), -(ROWS[1] - 4)));
         }
         catch (e:Error) { question = null; }
         if (gift != null) gift.visible = true;
         gotoAndStop(1);
         for (id in HOME) if (HOME[id][0] == 1) take(int(id));
         for each (var hide:String in ["pet_2267", "pet_2255", "pet_2051", "pet_2052"])
         {
            var h:DisplayObject = getChildByName(hide);
            if (h != null) h.visible = false;
         }
         addChild(cards);
         if (prev != null) addChild(prev);
         showPage(0);
      }

      private function take(id:int):void
      {
         var b:SimpleButton = getChildByName("pet_" + id) as SimpleButton;
         if (b == null) return;
         var x:Number = b.x, y:Number = b.y;
         removeChild(b);
         // Relative to its card's place.
         b.x = x - COLS[HOME[id][1]];
         b.y = y - ROWS[HOME[id][2]];
         buttons[id] = b;
      }

      private function showPage(n:int):void
      {
         page = n;
         while (cards.numChildren) cards.removeChildAt(0);
         var era:Array = SuperEvolutionConfig.ERA;
         for (var i:int = 0; i < PER_PAGE; i++)
         {
            var k:int = n * PER_PAGE + i;
            var c:int = i % 4, r:int = int(i / 4);
            var b:SimpleButton = k < era.length ? buttons[era[k]] : null;
            if (b != null)
            {
               var holder:Sprite = new Sprite();
               holder.x = COLS[c];
               holder.y = ROWS[r];
               holder.addChild(b);
               cards.addChild(holder);
            }
            else if (question != null)
            {
               var q:Bitmap = new Bitmap(question);
               q.x = COLS[c] - 4;
               q.y = ROWS[r] - 4;
               cards.addChild(q);
            }
         }
         var pages:int = Math.ceil(era.length / PER_PAGE);
         if (btnNext != null) btnNext.visible = page < pages - 1;
         if (prev != null) prev.visible = page > 0;
      }

      private function onAmount(e:SocketClientEvent):void
      {
         refreshItem();
      }

      private function refreshItem():void
      {
         cijiTxt.text = String(count(265));
         cijiTxt.mouseEnabled = false;
         jinhuaTxt.text = String(count(266));
         jinhuaTxt.mouseEnabled = false;
      }

      private function clickBtn(e:MouseEvent):void
      {
         var name:String = e.target is DisplayObject ? DisplayObject(e.target).name : "";
         if (name == "btnClose") closePanel();
         else if (name.indexOf("pet_") == 0) new EvoPanel(int(name.substr(4)), refreshItem).showPanel();
         else if (name == "btnBook")
         {
            ProgressFullSprite.show();
            ServiceContainer.instance.tryGetService(ServiceNames.HandBookService, function(svc:IBookClubService, o:Object):void
            {
               ProgressFullSprite.close();
               svc.showPage("book201103");
            });
         }
         else if (name == "btnGiftBag") buyGift();
         else if (name == "btnNext") showPage(page + 1);
         else if (name == "btnPrevious") showPage(page - 1);
         else if (name.indexOf("btnBuy") == 0) whereFrom(int(name.substr(6)));
      }

      private function buyGift():void
      {
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetBuyMaterialService(2, function(svc:IBuyMaterial, o:Object):void
         {
            ProgressFullSprite.close();
            svc.logSourceKey("superevolution");
            svc.buy(new BuyMaterialInfo(2, GIFT, 1, 1), function(ok:Boolean):void { refreshItem(); });
         });
      }

      /** How many of an item the player has. */
      public static function count(id:int):int
      {
         try
         {
            var u:UserItem = (ServiceContainer.getService(IItemService) as IItemService).getMyItemById(id);
            return u == null ? 0 : u.quantity;
         }
         catch (e:Error) {}
         return 0;
      }

      /** Where an item comes from: its 2013 description (the crystals: 许愿图腾 of 蓝宝石要塞). */
      public static function whereFrom(id:int):void
      {
         var item:Item = null;
         try { item = (ServiceContainer.getService(IItemService) as IItemService).getItemById(id); } catch (e:Error) {}
         if (item != null) NewDialog.showMessage(item.name + "：" + item.description);
      }

      /** The 图鉴's page of a 亚比 (its IntroPanel, once the 图鉴 is loaded). */
      public static function showDicPage(race:int):void
      {
         var intro:String = "mmo.pet.petdictionary.view.imp.IntroPanel";
         ServiceContainer.instance.tryGetService("PetDictionary", function(svc:IService, o:Object):void
         {
            try
            {
               Object(svc).showPanel();
               var dom:ApplicationDomain = ApplicationDomain.currentDomain;
               if (dom.hasDefinition(intro))
               {
                  var C:Object = dom.getDefinition(intro);
                  if (C.instance != null) C.instance.show(race);
               }
            }
            catch (err:Error) { RLog.error("superevolution 图鉴", err); }
         });
      }

      public function showPanel():void
      {
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }

      private function closePanel():void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }

      private function dispose(e:Event = null):void
      {
         removeEventListener(Event.REMOVED_FROM_STAGE, dispose);
         removeEventListener(MouseEvent.CLICK, clickBtn);
         SocketClient.instance.removeEventListener("onAmountUpdated", onAmount);
      }
   }
}
