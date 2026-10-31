package mmo.house.b020000
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * The zoo's 手册 (btnZooBook): the forty animals of the era ZooAnimalData,
    * young and grown, with where they live, how long they take to grow, what
    * they may turn into and where one gets them. The 2013 book is lost;
    * drawn in the look of the rebuilt panels.
    */
   public class ZooBook extends Sprite
   {
      private static const W:int = 620;
      private static const H:int = 470;
      private static var current:ZooBook;

      private var box:Sprite;
      private var detail:TextField;
      private var big:Sprite;

      public static function show():void
      {
         if (current != null) current.close();
         current = new ZooBook();
         LayerManager.getBaseTop().addChild(current);
      }

      public function ZooBook()
      {
         super();
         name = "zooBook";
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "动物手册", close, "zooBookClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         box.addChild(RUI.well(16, 54, W - 32, 296));
         var grid:Sprite = new Sprite();
         grid.x = 26;
         grid.y = 62;
         box.addChild(grid);
         for (var r:int = 1; r <= ZooData.RACES; r++)
         {
            var cell:Sprite = cellFor(r);
            cell.x = ((r - 1) % 10) * 57;
            cell.y = int((r - 1) / 10) * 70;
            grid.addChild(cell);
         }
         box.addChild(RUI.well(16, 358, W - 32, 98));
         big = new Sprite();
         big.x = 66;
         big.y = 446;
         box.addChild(big);
         detail = RUI.text(12, RUI.BLUE, false, W - 150);
         detail.x = 122;
         detail.y = 364;
         box.addChild(detail);
         detail.text = "点一只动物，看看它的样子和怎样得到它。";
      }

      private function cellFor(race:int):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.name = "zooBook_" + race;
         cell.buttonMode = true;
         cell.mouseChildren = false;
         cell.graphics.lineStyle(1.5, 0x7FBDE6);
         cell.graphics.beginFill(0xFFFFFF, 0.9);
         cell.graphics.drawRoundRect(0, 0, 52, 64, 10, 10);
         cell.graphics.endFill();
         var pic:Sprite = new Sprite();
         pic.x = 26;
         pic.y = 50;
         cell.addChild(pic);
         ZooData.picture(race, false, 42, pic);
         var t:TextField = RUI.text(10, 0x335577, false);
         t.text = ZooData.nameOf(race);
         t.x = (52 - t.width) / 2;
         t.y = 48;
         cell.addChild(t);
         try { TipsManager.getInstance().addTips(cell, ZooData.nameOf(race) + " → " + ZooData.nameOf(race, true)); } catch (e:Error) {}
         cell.addEventListener(MouseEvent.CLICK, function(ev:MouseEvent):void
         {
            ev.stopPropagation();
            show1(race);
         });
         return cell;
      }

      private function show1(race:int):void
      {
         ZooData.picture(race, true, 80, big);
         var a:Object = ZooData.animal(race);
         if (a == null) return;
         detail.text = a.name + " → " + a.matureName + "  " + ZooData.stars(race) + "    生活在" + a.position + "，" + a.matureTime + "小时长大\n"
            + "变异：" + ZooData.mutations(race) + "\n"
            + "获得：" + a.gainWay + "\n" + a.dec;
      }

      public function close():void
      {
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
