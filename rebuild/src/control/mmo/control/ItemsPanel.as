package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.UserMaterial;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * The revival's 物品 (not of 2013; the bar's 物品 button): everything the
    * player has collected, by kind (道具, 亚比蛋, 种植, 射击卡), with each
    * thing's picture (its material service's getView, as the era panels
    * show them) and how many, its name and description in the tip.
    */
   public class ItemsPanel extends Sprite
   {
      private static const W:int = 560;
      private static const H:int = 420;
      private static const COLS:int = 6;
      private static const ROWS:int = 3;
      /** [label, material type] (mmo.interfaces.material.MaterialTypes). */
      private static const KINDS:Array = [["道具", 2], ["亚比蛋", 5], ["种植", 10], ["射击卡", 4]];
      private static var current:ItemsPanel;

      private var box:Sprite;
      private var grid:Sprite;
      private var tabs:Sprite;
      private var pageText:TextField;
      private var said:TextField;
      private var kind:int = 0;
      private var page:int = 0;
      private var listening:Array = [];

      public static function toggle():void
      {
         if (current != null && current.parent != null)
         {
            current.close();
            return;
         }
         current = new ItemsPanel();
         LayerManager.getBaseTop().addChild(current);
      }

      public function ItemsPanel()
      {
         super();
         name = "itemsPanel";
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "物品", close, "itemsClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         tabs = new Sprite();
         tabs.x = 24;
         tabs.y = 52;
         box.addChild(tabs);
         box.addChild(RUI.well(16, 88, W - 32, 262));
         grid = new Sprite();
         grid.x = 30;
         grid.y = 98;
         box.addChild(grid);
         pageText = RUI.text(13, RUI.BLUE, true);
         pageText.y = 360;
         box.addChild(pageText);
         var prev:Sprite = RUI.smallButton("◀", function():void { go(page - 1); }, 34, 24, "itemsPrev");
         prev.x = W / 2 - 90;
         prev.y = 358;
         box.addChild(prev);
         var next:Sprite = RUI.smallButton("▶", function():void { go(page + 1); }, 34, 24, "itemsNext");
         next.x = W / 2 + 56;
         next.y = 358;
         box.addChild(next);
         said = RUI.text(12, 0x557799, false, W - 40);
         said.x = 20;
         said.y = 388;
         box.addChild(said);
         drawTabs();
         go(0);
      }

      private function drawTabs():void
      {
         while (tabs.numChildren) tabs.removeChildAt(0);
         for (var i:int = 0; i < KINDS.length; i++)
         {
            var on:Boolean = i == kind;
            var b:Sprite = RUI.button(KINDS[i][0], pick(i), 86, 28, on ? 0xFFC45A : 0x9FD8FF, on ? 0xF07812 : 0x3A8FD8, "itemsKind" + i);
            b.x = i * 94;
            tabs.addChild(b);
         }
      }

      private function pick(i:int):Function
      {
         return function():void
         {
            kind = i;
            drawTabs();
            go(0);
         };
      }

      private function service():IMaterialService
      {
         try
         {
            var f:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            return f ? f.getService(int(KINDS[kind][1])) : null;
         }
         catch (e:Error) { RLog.error("items service", e); }
         return null;
      }

      private function go(p:int):void
      {
         stopListening();
         while (grid.numChildren) grid.removeChildAt(0);
         var svc:IMaterialService = service();
         var list:Array = [];
         try { if (svc) list = svc.getMyMaterials().filter(function(u:*, i:int, a:Array):Boolean { return u is UserMaterial && UserMaterial(u).quantity > 0; }); }
         catch (e:Error) { RLog.error("items list", e); }
         list.sortOn("materialId", Array.NUMERIC);
         var per:int = COLS * ROWS;
         var pages:int = Math.max(1, Math.ceil(list.length / per));
         page = Math.max(0, Math.min(p, pages - 1));
         pageText.text = (page + 1) + " / " + pages;
         pageText.x = W / 2 - pageText.width / 2;
         for (var i:int = 0; i < per && page * per + i < list.length; i++)
         {
            var cell:Sprite = cellFor(svc, list[page * per + i]);
            cell.x = (i % COLS) * 84;
            cell.y = int(i / COLS) * 84;
            grid.addChild(cell);
         }
         said.text = list.length ? "共 " + list.length + " 种。把鼠标放在物品上可以看到它的说明。" : "这里还没有东西。";
      }

      private function cellFor(svc:IMaterialService, um:UserMaterial):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.name = "item_" + um.materialId;
         cell.graphics.lineStyle(2, 0x7FBDE6);
         cell.graphics.beginFill(0xFFFFFF, 0.9);
         cell.graphics.drawRoundRect(0, 0, 76, 76, 14, 14);
         cell.graphics.endFill();
         var holder:Sprite = new Sprite();
         holder.mouseEnabled = holder.mouseChildren = false;
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
         var n:TextField = RUI.text(12, 0xC25A00, true);
         n.text = "×" + um.quantity;
         n.x = 72 - n.width;
         n.y = 56;
         cell.addChild(n);
         var nm:String = um.material ? um.material.name : String(um.materialId);
         var desc:String = "";
         try { if (um.material && um.material.hasOwnProperty("description")) desc = String(Object(um.material).description || ""); } catch (e2:Error) {}
         try { TipsManager.getInstance().addTips(cell, nm + (desc ? "\n" + desc : ""), 160); } catch (e3:Error) {}
         cell.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            said.text = nm + "  ×" + um.quantity + (desc ? "：" + desc : "");
         });
         return cell;
      }

      private static function place(holder:Sprite, view:DisplayObject):void
      {
         holder.addChild(view);
         DisplayUtil.scaleDisplay(view, 56, 56);
         DisplayUtil.middleDisplay(view, 76, 70);
      }

      private function stopListening():void
      {
         for each (var l:Array in listening) IMaterialService(l[0]).removeEventListener(MaterialServiceEvent.onGetView, l[1]);
         listening = [];
      }

      public function close():void
      {
         stopListening();
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
