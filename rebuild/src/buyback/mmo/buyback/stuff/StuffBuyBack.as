package mmo.buyback.stuff
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.UserMaterial;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REBUILT buyback/stuffbuyback: the 兜兜回收器 of 道具店, 服装店 and 家具店
    * (the era scenes open the service StuffBuyBack, IShowPanel). The 2013
    * panel is lost (the live one, of 2021, sells by index and needs later
    * services). This lists what the player has, by kind (道具, 服装, 家具,
    * 射击卡), that has a buyback price in the 2013 material data
    * (Material.sale), and sells one or all of a thing for it in 晶币 through
    * the era MaterialClient.buyBack (MaterialExtension 61_2). Worn clothes
    * are kept. Drawn in the look of the rebuilt panels.
    */
   public class StuffBuyBack extends EventDispatcher implements IShowPanel
   {
      private static const W:int = 600;
      private static const H:int = 440;
      private static const COLS:int = 6;
      private static const ROWS:int = 3;
      private static const KINDS:Array = [["道具", 2], ["服装", 0], ["家具", 1], ["射击卡", 4]];

      private var root:Sprite;
      private var box:Sprite;
      private var tabs:Sprite;
      private var grid:Sprite;
      private var pageText:TextField;
      private var said:TextField;
      private var kind:int;
      private var page:int;
      private var chosen:UserMaterial;
      private var listening:Array = [];

      public function StuffBuyBack()
      {
         super();
      }

      public function showPanel():void
      {
         if (root != null && root.parent != null) return;
         root = new Sprite();
         root.name = "stuffBuyBack";
         root.addChild(RUI.dim(close));
         box = RUI.panel(W, H, "兜兜回收器", close, "buyBackClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         root.addChild(box);
         tabs = new Sprite();
         tabs.x = 24;
         tabs.y = 52;
         box.addChild(tabs);
         box.addChild(RUI.well(16, 88, W - 32, 266));
         grid = new Sprite();
         grid.x = 34;
         grid.y = 96;
         box.addChild(grid);
         pageText = RUI.text(13, RUI.BLUE, true);
         pageText.y = 362;
         box.addChild(pageText);
         var prev:Sprite = RUI.smallButton("◀", function():void { go(page - 1); }, 34, 24, "buyBackPrev");
         prev.x = 30;
         prev.y = 360;
         box.addChild(prev);
         var next:Sprite = RUI.smallButton("▶", function():void { go(page + 1); }, 34, 24, "buyBackNext");
         next.x = 120;
         next.y = 360;
         box.addChild(next);
         var one:Sprite = RUI.button("卖出1个", function():void { sell(false); }, 96, 30, 0xFFC45A, 0xF07812, "buyBackOne");
         one.x = W - 230;
         one.y = 358;
         box.addChild(one);
         var all:Sprite = RUI.button("全部卖出", function():void { sell(true); }, 96, 30, 0xFFC45A, 0xF07812, "buyBackAll");
         all.x = W - 124;
         all.y = 358;
         box.addChild(all);
         said = RUI.text(13, 0x8A3B00, true, W - 40);
         said.x = 20;
         said.y = 400;
         box.addChild(said);
         LayerManager.getBaseTop().addChild(root);
         SocketClient.instance.addEventListener("61_2", onSold);
         pick(0);
      }

      private function pick(k:int):void
      {
         kind = k;
         while (tabs.numChildren) tabs.removeChildAt(0);
         for (var i:int = 0; i < KINDS.length; i++)
         {
            var on:Boolean = i == kind;
            var b:Sprite = RUI.button(KINDS[i][0], tab(i), 90, 28, on ? 0xFFC45A : 0x9FD8FF, on ? 0xF07812 : 0x3A8FD8, "buyBackKind" + i);
            b.x = i * 98;
            tabs.addChild(b);
         }
         chosen = null;
         go(0);
      }

      private function tab(i:int):Function
      {
         return function():void { pick(i); };
      }

      private function service():IMaterialService
      {
         try
         {
            var f:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            return f ? f.getService(int(KINDS[kind][1])) : null;
         }
         catch (e:Error) { RLog.error("buyback service", e); }
         return null;
      }

      private static function priceOf(u:UserMaterial):int
      {
         try { return u.material ? int(Object(u.material).sale) : 0; } catch (e:Error) {}
         return 0;
      }

      private function sellable():Array
      {
         var svc:IMaterialService = service();
         var out:Array = [];
         try
         {
            for each (var u:* in (svc ? svc.getMyMaterials() : []))
            {
               var um:UserMaterial = u as UserMaterial;
               if (um != null && um.quantity > 0 && priceOf(um) > 0) out.push(um);
            }
         }
         catch (e:Error) { RLog.error("buyback list", e); }
         out.sortOn("materialId", Array.NUMERIC);
         return out;
      }

      private function go(p:int):void
      {
         stopListening();
         while (grid.numChildren) grid.removeChildAt(0);
         var list:Array = sellable();
         var per:int = COLS * ROWS;
         var pages:int = Math.max(1, Math.ceil(list.length / per));
         page = Math.max(0, Math.min(p, pages - 1));
         pageText.text = (page + 1) + " / " + pages;
         pageText.x = 75 - pageText.width / 2 + 10;
         var svc:IMaterialService = service();
         for (var i:int = 0; i < per && page * per + i < list.length; i++)
         {
            var cell:Sprite = cellFor(svc, list[page * per + i]);
            cell.x = (i % COLS) * 90;
            cell.y = int(i / COLS) * 86;
            grid.addChild(cell);
         }
         if (chosen == null) said.text = list.length ? "选一样东西，兜兜会按回收价付给你晶币。" : "这里没有兜兜能回收的东西。";
      }

      private function cellFor(svc:IMaterialService, um:UserMaterial):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.name = "buyBack_" + um.materialId;
         cell.buttonMode = true;
         cell.mouseChildren = false;
         var on:Boolean = chosen != null && chosen.materialId == um.materialId;
         cell.graphics.lineStyle(2, on ? 0xF07812 : 0x7FBDE6);
         cell.graphics.beginFill(on ? 0xFFF1C9 : 0xFFFFFF, 0.95);
         cell.graphics.drawRoundRect(0, 0, 80, 80, 14, 14);
         cell.graphics.endFill();
         var holder:Sprite = new Sprite();
         cell.addChild(holder);
         var view:DisplayObject = null;
         try { view = svc.getView(um.materialId); } catch (e:Error) {}
         if (view != null) place(holder, view);
         else
         {
            var id:int = um.materialId;
            var later:Function = function(ev:MaterialServiceEvent):void
            {
               if (ev.params == null || int(ev.params.id) != id || !(ev.params.view is DisplayObject)) return;
               svc.removeEventListener(MaterialServiceEvent.onGetView, later);
               if (holder.numChildren == 0 && cell.parent != null) place(holder, DisplayObject(ev.params.view));
            };
            svc.addEventListener(MaterialServiceEvent.onGetView, later);
            listening.push([svc, later]);
         }
         var n:TextField = RUI.text(11, 0xC25A00, true);
         n.text = "×" + um.quantity;
         n.x = 76 - n.width;
         n.y = 62;
         cell.addChild(n);
         var price:int = priceOf(um);
         var name:String = um.material ? um.material.name : String(um.materialId);
         try { TipsManager.getInstance().addTips(cell, name + "\n回收价 " + price + " 晶币"); } catch (e2:Error) {}
         cell.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            chosen = um;
            said.text = name + "  ×" + um.quantity + "    回收价每个 " + price + " 晶币";
            go(page);
         });
         return cell;
      }

      private static function place(holder:Sprite, view:DisplayObject):void
      {
         holder.addChild(view);
         DisplayUtil.scaleDisplay(view, 60, 60);
         DisplayUtil.middleDisplay(view, 80, 72);
      }

      private function sell(all:Boolean):void
      {
         if (chosen == null)
         {
            said.text = "先选一样东西吧。";
            return;
         }
         SocketClient.instance.sendXtMessage("MaterialExtension", "61_2", {tp: int(KINDS[kind][1]), mi: chosen.materialId, qt: all ? chosen.quantity : 1});
      }

      private function onSold(e:SocketClientEvent):void
      {
         var r:int = int(e.params.result);
         said.text = r == 1 ? "兜兜付给你 " + int(e.params.score) + " 晶币！" : r == -2 ? "没有那么多了。" : "这样东西兜兜不回收（穿在身上的衣服要先换下来）。";
         if (r == 1 && chosen != null && chosen.quantity <= 0) chosen = null;
         go(page);
      }

      private function stopListening():void
      {
         for each (var l:Array in listening) IMaterialService(l[0]).removeEventListener(MaterialServiceEvent.onGetView, l[1]);
         listening = [];
      }

      private function close():void
      {
         stopListening();
         SocketClient.instance.removeEventListener("61_2", onSold);
         if (root != null && root.parent != null) root.parent.removeChild(root);
         root = null;
      }
   }
}
