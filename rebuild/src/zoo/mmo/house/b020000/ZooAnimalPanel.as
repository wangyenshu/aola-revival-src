package mmo.house.b020000
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * One animal of the zoo: how long it still grows, what it may turn into,
    * and, in one's own zoo, 喂食 (the 饲料机's free feed), the 饲料 sold for
    * 晶币 (ZooItemData; used at once), 收获 when grown, 放生. The 2013 panels
    * of the zoo are lost; drawn in the look of the rebuilt panels.
    */
   public class ZooAnimalPanel extends Sprite
   {
      private static const W:int = 520;
      private static const H:int = 390;
      private static var current:ZooAnimalPanel;

      private var a:ZooAnimal;
      private var mine:Boolean;
      private var onChange:Function;
      private var box:Sprite;
      private var pic:Sprite;
      private var info:TextField;
      private var said:TextField;
      private var buttons:Sprite;

      /** onChange(reply) is told of every 97_12 / 97_7 / 97_6 reply. */
      public static function show(a:ZooAnimal, mine:Boolean, onChange:Function):void
      {
         closeIfOpen();
         current = new ZooAnimalPanel(a, mine, onChange);
         LayerManager.getBaseTop().addChild(current);
      }

      public static function closeIfOpen():void
      {
         if (current != null) current.close();
      }

      public function ZooAnimalPanel(a:ZooAnimal, mine:Boolean, onChange:Function)
      {
         super();
         this.a = a;
         this.mine = mine;
         this.onChange = onChange;
         name = "zooAnimalPanel";
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, ZooData.nameOf(a.race, a.mature), close, "zooAnimalClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         box.addChild(RUI.well(18, 54, 130, 130));
         pic = new Sprite();
         pic.x = 83;
         pic.y = 166;
         box.addChild(pic);
         info = RUI.text(13, RUI.BLUE, false, W - 186);
         info.x = 162;
         info.y = 54;
         box.addChild(info);
         buttons = new Sprite();
         buttons.x = 18;
         buttons.y = 196;
         box.addChild(buttons);
         said = RUI.text(13, 0x8A3B00, true, W - 140);
         said.x = 18;
         said.y = H - 40;
         box.addChild(said);
         SocketClient.instance.addEventListener("97_12", onFed);
         SocketClient.instance.addEventListener("97_7", onHarvest);
         SocketClient.instance.addEventListener("97_6", onDropped);
         draw();
      }

      private function draw():void
      {
         ZooData.picture(a.race, a.mature, 100, pic);
         var an:Object = ZooData.animal(a.race);
         var lines:Array = [];
         lines.push((a.mature ? ZooData.nameOf(a.race, true) : ZooData.nameOf(a.race) + "（长大后是" + ZooData.nameOf(a.race, true) + "）") + "  " + ZooData.stars(a.race));
         lines.push("生活在：" + a.where + (an ? "    成长时间：" + an.matureTime + "小时" : ""));
         lines.push(a.mature ? "已经长大了，可以收获！" : "成长：" + ZooData.hoursText(a.secondsLeft) + "长大。");
         lines.push("变异：" + ZooData.mutations(a.race, a.rate));
         if (an && an.dec) lines.push(String(an.dec));
         info.text = lines.join("\n");
         while (buttons.numChildren) buttons.removeChildAt(0);
         if (!mine)
         {
            said.text = "这是别人的动物园，只能看看哦。";
            return;
         }
         var row:int = 0;
         var put:Function = function(b:Sprite, col:int):void
         {
            b.x = col * 124;
            b.y = row * 36;
            buttons.addChild(b);
         };
         if (a.mature)
         {
            put(RUI.button("收获", function():void { ZooData.send("97_7", {id: a.id}); }, 116, 30, 0xFFC45A, 0xF07812, "zooHarvest"), 0);
         }
         else
         {
            put(RUI.button("喂食", function():void { ZooData.send("97_12", {id: a.id, itemId: 0}); }, 116, 30, 0x9BE07A, 0x3E9E2A, "zooFeed"), 0);
            row = 1;
            var col:int = 0;
            for each (var f:Array in ZooData.FODDER)
            {
               var b:Sprite = RUI.button(String(f[1]).replace("饲料", "") + " " + f[2], fodder(int(f[0])), 116, 28, 0x9FD8FF, 0x3A8FD8, "zooFodder_" + f[0]);
               put(b, col);
               col++;
               if (col == 4)
               {
                  col = 0;
                  row++;
               }
            }
         }
         var free:Sprite = RUI.button("放生", function():void { ZooData.send("97_6", {id: a.id}); }, 76, 26, 0xD8D8D8, 0x8A8A8A, "zooDrop");
         free.x = W - 76 - 18 - buttons.x;
         free.y = H - 42 - buttons.y;
         buttons.addChild(free);
         if (!said.text) said.text = a.mature ? "收获后，动物园会得到经验。" : "喂食可以让它早1小时长大（每半小时可以喂一次）。饲料按钮上是晶币价格。";
      }

      private function fodder(item:int):Function
      {
         return function():void { ZooData.send("97_12", {id: a.id, itemId: item}); };
      }

      private function onFed(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (int(p.id) != a.id) return;
         var r:int = int(p.res);
         if (r == 1)
         {
            a.update(p);
            said.text = int(p.itemId) == 0 ? "喂饱了！它长得更快了。" : "用了饲料。";
         }
         else said.text = r == -2 ? "晶币不够哦。" : r == -3 ? (int(p.itemId) == 0 ? "它刚吃饱，过一会儿再喂吧。" : "这只幼仔不能再用这种饲料了。") : r == -4 ? "它已经长大了。" : "这只动物不在了。";
         if (onChange != null) onChange(p);
         draw();
      }

      private function onHarvest(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (int(p.id) != a.id) return;
         if (onChange != null) onChange(p);
         if (int(p.res) != 1)
         {
            said.text = int(p.res) == -2 ? "它还没长大。" : "这只动物不在了。";
            return;
         }
         close();
      }

      private function onDropped(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (int(p.id) != a.id) return;
         if (onChange != null) onChange(p);
         close();
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("97_12", onFed);
         SocketClient.instance.removeEventListener("97_7", onHarvest);
         SocketClient.instance.removeEventListener("97_6", onDropped);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
