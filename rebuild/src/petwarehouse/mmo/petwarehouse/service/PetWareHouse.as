package mmo.petwarehouse.service
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.revival.RUI;

   /**
    * REBUILT pet/petwarehouse (service PetWareHouse, IShowPanel): the 亚比仓库.
    * The January 2013 module is lost; the later one is a 2026 rework. The
    * commands are the era PetClient's: viewPMInLocation (1213 -> 2213, loc 0
    * the bag, 1 the 仓库, twelve to a page) and sendPmToFromStorage (1224 ->
    * 2224 {result}, loc where the 亚比 goes). The panel is drawn in the look of
    * the rebuilt player card: the six of the bag on the left, the 仓库 on the
    * right; a click on a 亚比 moves it to the other side. Pictures: the
    * original peticon/peticon<id>.swf.
    */
   public class PetWareHouse extends EventDispatcher implements IShowPanel
   {
      private static const W:int = 680;
      private static const H:int = 430;
      private static const COLS:int = 4;
      private static const PER_PAGE:int = 12;

      private var root:Sprite;
      private var bagGrid:Sprite;
      private var storeGrid:Sprite;
      private var pageText:TextField;
      private var countText:TextField;
      private var page:int;
      private var pages:int = 1;
      private var busy:Boolean;

      public function PetWareHouse()
      {
         super();
      }

      public function showPanel():void
      {
         if (root != null && root.parent != null) return;
         build();
         SocketClient.instance.addEventListener("2213", onList);
         SocketClient.instance.addEventListener("2224", onMoved);
         ask(0);
         ask(1);
      }

      private function build():void
      {
         root = new Sprite();
         root.name = "petWarehouse";
         root.addChild(RUI.dim(close));
         var box:Sprite = RUI.panel(W, H, "亚比仓库", close, "warehouseClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         root.addChild(box);
         box.addChild(RUI.well(16, 56, 200, H - 110));
         box.addChild(RUI.well(228, 56, W - 244, H - 110));
         var t1:TextField = RUI.text(15, RUI.BLUE, true);
         t1.text = "背包";
         t1.x = 96;
         t1.y = 62;
         box.addChild(t1);
         var t2:TextField = RUI.text(15, RUI.BLUE, true);
         t2.text = "仓库";
         t2.x = 228 + (W - 244) / 2 - 16;
         t2.y = 62;
         box.addChild(t2);
         countText = RUI.text(12, 0x557799, false);
         countText.x = W - 120;
         countText.y = 64;
         box.addChild(countText);
         bagGrid = new Sprite();
         bagGrid.x = 16 + (200 - (2 * 92 - 10)) / 2;
         bagGrid.y = 86;
         box.addChild(bagGrid);
         storeGrid = new Sprite();
         storeGrid.x = 228 + (W - 244 - (COLS * 92 - 10)) / 2;
         storeGrid.y = 86;
         box.addChild(storeGrid);
         var prev:Sprite = RUI.smallButton("◀", function():void { if (page > 0) ask(1, page - 1); }, 34, 24, "warehousePrev");
         prev.x = 228 + (W - 244) / 2 - 80;
         prev.y = H - 48;
         box.addChild(prev);
         pageText = RUI.text(13, RUI.BLUE, true);
         pageText.y = H - 45;
         box.addChild(pageText);
         var next:Sprite = RUI.smallButton("▶", function():void { if (page < pages - 1) ask(1, page + 1); }, 34, 24, "warehouseNext");
         next.x = 228 + (W - 244) / 2 + 46;
         next.y = H - 48;
         box.addChild(next);
         var tip:TextField = RUI.text(12, 0x557799, false);
         tip.text = "点一下亚比，就能在背包和仓库之间放来放去";
         tip.x = 24;
         tip.y = H - 44;
         box.addChild(tip);
         LayerManager.getBaseTop().addChild(root);
      }

      private function ask(loc:int, p:int = -1):void
      {
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1213", {pmType: 0, page: p < 0 ? page : p, loc: loc, order: 0, asc: true});
      }

      private function onList(e:SocketClientEvent):void
      {
         if (root == null) return;
         var o:Object = e.params;
         var pets:Array = [];
         for each (var raw:Object in (o.pmList as Array) || [])
         {
            var b:PetBriefInfo = new PetBriefInfo();
            try { b.parseInfo(raw); pets.push(b); } catch (err:Error) { RLog.error("warehouse pet", err); }
         }
         if (int(o.loc) == 1)
         {
            page = int(o.page);
            pages = Math.max(1, int(o.pages));
            pageText.text = (page + 1) + " / " + pages;
            pageText.x = 228 + (W - 244) / 2 - pageText.width / 2 - 6;
            countText.text = "共 " + int(o.total) + " 只";
            fill(storeGrid, pets, COLS, PER_PAGE, 0);
         }
         else
         {
            fill(bagGrid, pets, 2, 6, 1);
         }
      }

      /** Slots of a grid; a click sends that 亚比 to `to` (1 仓库, 0 背包). */
      private function fill(grid:Sprite, pets:Array, cols:int, count:int, to:int):void
      {
         while (grid.numChildren) grid.removeChildAt(0);
         for (var i:int = 0; i < count; i++)
         {
            var slot:Sprite = new Sprite();
            slot.x = (i % cols) * 92;
            slot.y = int(i / cols) * 92;
            slot.graphics.lineStyle(2, 0xF2A23A);
            slot.graphics.beginFill(0xFFF8E8);
            slot.graphics.drawRoundRect(0, 0, 82, 82, 14, 14);
            slot.graphics.endFill();
            grid.addChild(slot);
            var p:PetBriefInfo = pets[i] as PetBriefInfo;
            if (p == null) continue;
            slot.name = (to == 1 ? "bagPet" : "storePet") + i;
            slot.buttonMode = true;
            slot.mouseChildren = false;
            var pic:Sprite = new Sprite();
            pic.x = 41;
            pic.y = 34;
            slot.addChild(pic);
            icon(pic, p.viewId > 0 ? p.viewId : p.raceId, 52);
            var n:TextField = RUI.text(12, RUI.BLUE, true);
            n.text = (p.nickname || p.name || "亚比").substr(0, 6);
            n.x = 41 - n.width / 2;
            n.y = 58;
            slot.addChild(n);
            var lv:TextField = RUI.text(11, 0xE8641B, true);
            lv.text = "Lv" + p.level;
            lv.x = 4;
            lv.y = 2;
            slot.addChild(lv);
            slot.addEventListener(MouseEvent.CLICK, move(p.id, to));
         }
      }

      private function move(id:int, to:int):Function
      {
         return function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (busy) return;
            busy = true;
            SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1224", {id: id, loc: to});
         };
      }

      private function onMoved(e:SocketClientEvent):void
      {
         busy = false;
         var r:int = int(e.params.result);
         if (r == -2) RNotice.show(LayerManager.getBaseTop(), "背包里已经有6只亚比了，先放一只进仓库吧！");
         else if (r == -3) RNotice.show(LayerManager.getBaseTop(), "背包里至少要留一只亚比哦！");
         if (r != 1) return;
         ask(0);
         ask(1);
         // The bag (PetDataService) reads the list again, so the 亚比背包 and battles see the change.
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("warehouse refresh", err); }
      }

      /** peticon/peticon<id>.swf: mmo.pet.peticon<id>_S. */
      private static function icon(into:DisplayObjectContainer, viewId:int, fit:int):void
      {
         var cls:String = "mmo.pet.peticon" + viewId + "_S";
         var put:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls) || into.stage == null && into.parent == null) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var pic:DisplayObject = new C() as DisplayObject;
            var b:Object = pic.getBounds(pic);
            var k:Number = Math.min(1.2, fit / Math.max(1, b.width), fit / Math.max(1, b.height));
            pic.scaleX = pic.scaleY = k;
            pic.x = -(b.left + b.width / 2) * k;
            pic.y = -(b.top + b.height / 2) * k;
            into.addChild(pic);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("peticon/peticon" + viewId, put, cls, function(e:* = null):void {});
      }

      private function close():void
      {
         SocketClient.instance.removeEventListener("2213", onList);
         SocketClient.instance.removeEventListener("2224", onMoved);
         if (root != null && root.parent != null) root.parent.removeChild(root);
         root = null;
         busy = false;
      }
   }
}
