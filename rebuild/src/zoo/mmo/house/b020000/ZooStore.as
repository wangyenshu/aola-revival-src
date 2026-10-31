package mmo.house.b020000
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
   * The zoo's 动物仓库 (the 2013 one, zoo/zoores_1's ZooStorePanel, needs the
   * lost zoo scene's drag and drop): the 幼仔 caught in 动物捕捉 or won,
   * which go into the zoo with a click (ZooClient 97_9, 97_5), and the grown
   * animals harvested, sold for their price in 晶币 (97_10, 97_21). Drawn in
   * the look of the rebuilt panels.
   */
   public class ZooStore extends Sprite
   {
      private static const W:int = 560;
      private static const H:int = 420;
      private static var current:ZooStore;

      private var box:Sprite;
      private var tabs:Sprite;
      private var grid:Sprite;
      private var said:TextField;
      private var kind:int = 0;
      private var onPut:Function;

      /** onPut(reply) is told when an animal went into the zoo. */
      public static function show(onPut:Function):void
      {
         if (current != null) current.close();
         current = new ZooStore(onPut);
         LayerManager.getBaseTop().addChild(current);
      }

      public static function closeIfOpen():void
      {
         if (current != null) current.close();
      }

      public function ZooStore(onPut:Function)
      {
         super();
         this.onPut = onPut;
         name = "zooStore";
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "动物仓库", close, "zooStoreClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         tabs = new Sprite();
         tabs.x = 24;
         tabs.y = 52;
         box.addChild(tabs);
         box.addChild(RUI.well(16, 88, W - 32, 270));
         grid = new Sprite();
         grid.x = 30;
         grid.y = 98;
         box.addChild(grid);
         said = RUI.text(13, 0x8A3B00, true, W - 40);
         said.x = 20;
         said.y = 368;
         box.addChild(said);
         SocketClient.instance.addEventListener("97_9", onBabys);
         SocketClient.instance.addEventListener("97_10", onMatures);
         SocketClient.instance.addEventListener("97_5", onPutReply);
         SocketClient.instance.addEventListener("97_21", onSold);
         pick(0);
      }

      private function pick(k:int):void
      {
         kind = k;
         while (tabs.numChildren) tabs.removeChildAt(0);
         var names:Array = ["动物幼仔", "成年动物"];
         for (var i:int = 0; i < names.length; i++)
         {
            var on:Boolean = i == kind;
            var b:Sprite = RUI.button(names[i], tab(i), 100, 28, on ? 0xFFC45A : 0x9FD8FF, on ? 0xF07812 : 0x3A8FD8, "zooStoreTab" + i);
            b.x = i * 108;
            tabs.addChild(b);
         }
         while (grid.numChildren) grid.removeChildAt(0);
         said.text = "";
         ZooData.send(kind == 0 ? "97_9" : "97_10");
      }

      private function tab(i:int):Function
      {
         return function():void { pick(i); };
      }

      private function onBabys(e:SocketClientEvent):void
      {
         if (kind == 0) list(e.params.babys as Array || [], false);
      }

      private function onMatures(e:SocketClientEvent):void
      {
         if (kind == 1) list(e.params.matrues as Array || [], true);
      }

      private function list(items:Array, grown:Boolean):void
      {
         while (grid.numChildren) grid.removeChildAt(0);
         items.sortOn("raceId", Array.NUMERIC);
         for (var i:int = 0; i < items.length && i < 18; i++)
         {
            var o:Object = items[i];
            var cell:Sprite = cellFor(int(o.raceId), int(o.num), grown);
            cell.x = (i % 6) * 84;
            cell.y = int(i / 6) * 86;
            grid.addChild(cell);
         }
         if (said.text == "")
         {
            if (items.length == 0) said.text = grown ? "还没有成年动物。动物园里的动物长大后，收获就会放在这里。" : "没有动物幼仔。到生态园玩动物捕捉，就能捉到小动物！";
            else said.text = grown ? "点一下成年动物，就能把它卖掉，换成晶币。" : "点一下幼仔，就能把它放进动物园。";
         }
      }

      private function cellFor(race:int, num:int, grown:Boolean):Sprite
      {
         var cell:Sprite = new Sprite();
         cell.name = (grown ? "zooMature_" : "zooBaby_") + race;
         cell.buttonMode = true;
         cell.mouseChildren = false;
         cell.graphics.lineStyle(2, 0x7FBDE6);
         cell.graphics.beginFill(0xFFFFFF, 0.9);
         cell.graphics.drawRoundRect(0, 0, 76, 78, 14, 14);
         cell.graphics.endFill();
         var pic:Sprite = new Sprite();
         pic.x = 38;
         pic.y = 58;
         cell.addChild(pic);
         ZooData.picture(race, grown, 52, pic);
         var n:TextField = RUI.text(12, 0xC25A00, true);
         n.text = "×" + num;
         n.x = 72 - n.width;
         n.y = 58;
         cell.addChild(n);
         var an:Object = ZooData.animal(race);
         var tip:String = ZooData.nameOf(race, grown) + " " + ZooData.stars(race) + "\n" + (grown ? "卖出：" + (an ? an.price : 0) + " 晶币" : (an ? an.position + "，" + an.matureTime + "小时长大" : ""));
         try { TipsManager.getInstance().addTips(cell, tip); } catch (e:Error) {}
         cell.addEventListener(MouseEvent.CLICK, function(ev:MouseEvent):void
         {
            ev.stopPropagation();
            if (grown) ZooData.send("97_21", {raceId: race, num: 1});
            else ZooData.send("97_5", {raceId: race});
         });
         return cell;
      }

      private function onPutReply(e:SocketClientEvent):void
      {
         var r:int = int(e.params.res);
         said.text = r == 1 ? ZooData.nameOf(int(e.params.raceId)) + "住进动物园啦！" : r == -2 ? "动物园满了。动物园升级后可以养更多动物。" : "没有这只幼仔了。";
         if (r == 1 && onPut != null) onPut(e.params);
         if (kind == 0) ZooData.send("97_9");
      }

      private function onSold(e:SocketClientEvent):void
      {
         said.text = int(e.params.res) == 1 ? "卖掉了" + ZooData.nameOf(int(e.params.raceId), true) + "，得到 " + int(e.params.got) + " 晶币。" : "没有这只动物了。";
         if (kind == 1) ZooData.send("97_10");
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("97_9", onBabys);
         SocketClient.instance.removeEventListener("97_10", onMatures);
         SocketClient.instance.removeEventListener("97_5", onPutReply);
         SocketClient.instance.removeEventListener("97_21", onSold);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
