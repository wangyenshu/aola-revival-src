package mmo.house.b000247
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.material.plant.Plant;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * REBUILT: the empty 植树盆's choice of the owner's 树苗 (bought in the 种植手册, the 种植园's
    * 树苗售卖): one is chosen and planted (the server's revival_garden "plant"). Each 树苗 shows
    * its tree's small picture (plant/y<id>'s _B, the shop's) and how many one has. Drawn in the
    * look of the rebuilt panels.
    */
   public class SaplingPicker extends Sprite
   {
      private static const W:int = 470;
      private static const H:int = 300;
      private static var current:SaplingPicker;

      /** saplings [{id, n}]; plant(id) plants one; shop() opens the 种植手册. */
      public static function show(saplings:Array, plant:Function, shop:Function):void
      {
         hide();
         current = new SaplingPicker(saplings, plant, shop);
         LayerManager.getBaseTop().addChild(current);
      }

      public static function hide():void
      {
         if (current != null && current.parent != null) current.parent.removeChild(current);
         current = null;
      }

      public function SaplingPicker(saplings:Array, plant:Function, shop:Function)
      {
         super();
         name = "saplingPicker";
         addChild(RUI.dim(hide));
         var box:Sprite = RUI.panel(W, H, "选择树苗", hide, "saplingClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         box.addChild(RUI.well(16, 54, W - 32, 180));
         var n:int = 0;
         for each (var s:Object in saplings)
         {
            if (s == null || int(s.n) <= 0 || n >= 8) continue;
            var cell:Sprite = cellFor(int(s.id), int(s.n), plant);
            cell.x = 28 + (n % 4) * 106;
            cell.y = 64 + int(n / 4) * 84;
            box.addChild(cell);
            n++;
         }
         if (n == 0)
         {
            var none:TextField = RUI.text(14, 0x557799, false);
            none.text = "还没有树苗。";
            none.x = (W - none.width) / 2;
            none.y = 130;
            box.addChild(none);
         }
         var buy:Sprite = RUI.button("买树苗", function():void
         {
            hide();
            shop();
         }, 96, 30, 0xFFC45A, 0xF07812, "saplingShop");
         buy.x = (W - 96) / 2;
         buy.y = 250;
         box.addChild(buy);
      }

      private static function cellFor(id:int, count:int, plant:Function):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.name = "sapling" + id;
         cell.buttonMode = true;
         cell.graphics.lineStyle(2, 0xF2C27A);
         cell.graphics.beginFill(0xFFF8E6);
         cell.graphics.drawRoundRect(0, 0, 96, 76, 12, 12);
         cell.graphics.endFill();
         var holder:Sprite = new Sprite();
         holder.mouseEnabled = holder.mouseChildren = false;
         holder.x = 48;
         holder.y = 52;
         cell.addChild(holder);
         TreeArt.load(id, "_B", function(C:Class):void
         {
            var pic:DisplayObject = new C() as DisplayObject;
            if (pic != null && holder.numChildren == 0) holder.addChild(TreeArt.fit(pic, 70, 46, true));
         });
         var p:Plant = TreeArt.plant(id);
         var label:TextField = RUI.text(12, 0x8A3B00, true);
         label.mouseEnabled = false;
         label.text = (p ? p.name : String(id)) + " ×" + count;
         label.x = (96 - label.width) / 2;
         label.y = 55;
         cell.addChild(label);
         try { TipsManager.getInstance().addTips(cell, "种下" + (p ? p.name : "")); } catch (e:Error) {}
         cell.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { cell.filters = [new GlowFilter(0xFFB400, 1, 8, 8, 2)]; });
         cell.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { cell.filters = []; });
         cell.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            hide();
            plant(id);
         });
         return cell;
      }
   }
}
