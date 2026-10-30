package mmo.house.b000247
{
   import flash.display.DisplayObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.plant.Plant;
   import mmo.interfaces.material.plant.PlantLevel;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REBUILT: the 植树盆 of the 家园. The 2012 tree panel (yz/treemanager)
    * and shop (the 种植手册) are lost; the commands are the 2013 TreeClient's
    * (PlantExtension 80_3 雨露, 80_4 养料, 80_5 采摘) and, for planting and
    * digging up, the revival's SundriesExtension.revival_garden. Drawn in the
    * look of the rebuilt panels: an empty pot offers the eight trees of
    * PlantData; a tree shows its picture, level, 健康值 and 营养值, the care
    * left today and its fruit.
    */
   public class PlantPanel extends Sprite
   {
      private static const W:int = 560;
      private static const H:int = 380;
      private static var current:PlantPanel;

      private var owner:String;
      private var mine:Boolean;
      private var onChange:Function;
      private var box:Sprite;
      private var body:Sprite;
      private var said:TextField;
      private var chosen:int = 1;
      private var digAsked:Boolean;
      private var tree:Object;

      /** Open the panel for the tree of owner's 植树盆 (tree: the server's plant, or null). */
      public static function show(owner:String, mine:Boolean, tree:Object, onChange:Function):void
      {
         if (current != null) current.close();
         current = new PlantPanel(owner, mine, tree, onChange);
         LayerManager.getBaseTop().addChild(current);
      }

      public function PlantPanel(owner:String, mine:Boolean, tree:Object, onChange:Function)
      {
         super();
         name = "plantPanel";
         this.owner = owner;
         this.mine = mine;
         this.onChange = onChange;
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "植树盆", close, "plantClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         body = new Sprite();
         box.addChild(body);
         said = RUI.text(13, 0x8A3B00, true, W - 40);
         said.height = 40;
         said.x = 20;
         said.y = H - 46;
         box.addChild(said);
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener("80_3", onCare);
         sc.addEventListener("80_4", onCare);
         sc.addEventListener("80_5", onPick);
         sc.addEventListener("revival_garden", onGarden);
         setTree(tree);
      }

      private function setTree(t:Object):void
      {
         tree = t != null && int(t.id) > 0 ? t : null;
         digAsked = false;
         while (body.numChildren) body.removeChildAt(0);
         if (tree == null) drawShop();
         else drawTree();
      }

      // ───── an empty pot: the eight trees ─────

      private function drawShop():void
      {
         if (!mine)
         {
            say("这个植树盆里还没有种树。");
            return;
         }
         body.addChild(RUI.well(16, 54, W - 32, 216));
         var cols:int = 4;
         for (var i:int = 0; i < TreeArt.IDS.length; i++)
         {
            var id:int = TreeArt.IDS[i];
            var card:Sprite = new Sprite();
            card.name = "plantKind" + id;
            card.x = 28 + (i % cols) * 128;
            card.y = 62 + int(i / cols) * 102;
            card.buttonMode = true;
            card.mouseChildren = false;
            frame(card, id == chosen);
            var picHolder:Sprite = new Sprite();
            picHolder.x = 58;
            picHolder.y = 70;
            card.addChild(picHolder);
            smallPicture(picHolder, id);
            var p:Plant = TreeArt.plant(id);
            var n:TextField = RUI.text(12, RUI.BLUE, true);
            n.text = p ? p.name : "树";
            n.x = 58 - n.width / 2;
            n.y = 74;
            card.addChild(n);
            card.addEventListener(MouseEvent.CLICK, choose(id));
            body.addChild(card);
         }
         var price:TextField = RUI.text(13, RUI.BLUE, true);
         price.name = "plantPrice";
         price.x = 28;
         price.y = 280;
         body.addChild(price);
         var plantBtn:Sprite = RUI.button("种下", buy, 86, 30, 0xFFC45A, 0xF07812, "plantBuy");
         plantBtn.x = W - 120;
         plantBtn.y = 280;
         body.addChild(plantBtn);
         describe();
      }

      private function frame(card:Sprite, on:Boolean):void
      {
         card.graphics.clear();
         card.graphics.lineStyle(on ? 3 : 2, on ? 0xF07812 : 0xF2A23A);
         card.graphics.beginFill(on ? 0xFFF1C9 : 0xFFF8E8);
         card.graphics.drawRoundRect(0, 0, 116, 94, 14, 14);
         card.graphics.endFill();
      }

      private function choose(id:int):Function
      {
         return function(e:MouseEvent):void
         {
            e.stopPropagation();
            chosen = id;
            for (var i:int = 0; i < body.numChildren; i++)
            {
               var c:Sprite = body.getChildAt(i) as Sprite;
               if (c != null && c.name.indexOf("plantKind") == 0) frame(c, c.name == "plantKind" + id);
            }
            describe();
         };
      }

      private function describe():void
      {
         var p:Plant = TreeArt.plant(chosen);
         var price:TextField = body.getChildByName("plantPrice") as TextField;
         if (p == null || price == null) return;
         price.text = p.name + "    " + p.price + " 晶币    （你有 " + UserInfo.score + " 晶币）";
         say(p.description);
      }

      private function smallPicture(into:Sprite, id:int):void
      {
         TreeArt.load(id, "_B", function(C:Class):void
         {
            var pic:DisplayObject = new C() as DisplayObject;
            if (pic != null) into.addChild(TreeArt.fit(pic, 96, 64, true));
         });
      }

      private function buy():void
      {
         var p:Plant = TreeArt.plant(chosen);
         if (p != null && UserInfo.score < p.price)
         {
            say("晶币不够哦，种一棵" + p.name + "要 " + p.price + " 晶币。");
            return;
         }
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_garden", {op: "buy", plantId: chosen});
      }

      // ───── a tree ─────

      private function drawTree():void
      {
         var id:int = int(tree.plantId);
         var p:Plant = TreeArt.plant(id);
         var lv:Array = TreeArt.levels(id);
         var maxLevel:int = lv.length - 1;
         var level:int = int(tree.level);
         var l:PlantLevel = lv[level] as PlantLevel;
         body.addChild(RUI.well(16, 54, 200, 270));
         body.addChild(RUI.well(228, 54, W - 244, 270));
         var picHolder:Sprite = new Sprite();
         picHolder.x = 116;
         picHolder.y = 306;
         body.addChild(picHolder);
         TreeArt.load(id, "_C", function(C:Class):void
         {
            var pic:DisplayObject = TreeArt.picture(C, TreeArt.pictureIndex(id, level, int(tree.remainFruit) > 0));
            if (pic != null) picHolder.addChild(TreeArt.fit(pic, 180, 240, true));
         });
         var x0:int = 246;
         var t:TextField = RUI.text(16, RUI.BLUE, true);
         t.text = (p ? p.name : "树") + "    Lv" + level + " / " + maxLevel;
         t.x = x0;
         t.y = 66;
         body.addChild(t);
         if (level < maxLevel && l != null)
         {
            bar(x0, 102, "健康值", int(tree.health), l.maxHealth, 0x3FA9F5);
            bar(x0, 136, "营养值", int(tree.nutrition), l.maxNutrition, 0x7BC043);
         }
         else
         {
            var top:TextField = RUI.text(13, 0x335577, true);
            top.text = "已经长到最高级了！";
            top.x = x0;
            top.y = 110;
            body.addChild(top);
         }
         var info:TextField = RUI.text(12, 0x335577, false, W - 244 - 36);
         info.height = 60;
         info.x = x0;
         info.y = 168;
         info.text = fruitText(id, level, p);
         body.addChild(info);
         var y:int = 238;
         if (level < maxLevel)
         {
            addButton("雨露（" + Math.max(0, int(tree.rainLeft)) + "）", function():void { send("80_3"); }, x0, y, 0x6CC0F5, 0x2E86D6, "plantRain");
            addButton("养料（" + Math.max(0, int(tree.fatLeft)) + "）", function():void { send("80_4"); }, x0 + 92, y, 0x9AD86A, 0x4FA22A, "plantFat");
         }
         var pick:Sprite = addButton(int(tree.remainFruit) > 0 ? "采摘（" + int(tree.remainFruit) + "）" : "采摘", function():void { send("80_5"); }, x0 + 184, y, 0xFFC45A, 0xF07812, "plantPick");
         if (int(tree.remainFruit) <= 0) pick.alpha = 0.5;
         if (mine) addButton("铲除", dig, x0 + 92, y + 40, 0xC9A27A, 0x8C5A2B, "plantDig");
         if (!said.text) say(mine ? "每天可以给小树添加两次雨露和两次养料，健康值和营养值都满了就会长大一级。" : "");
      }

      private function fruitText(id:int, level:int, p:Plant):String
      {
         var fruit:String = fruitName(p);
         var mature:int = p ? p.matruelev : 3;
         if (level < mature) return "小树还没有成熟，长到 " + mature + " 级就会结出" + fruit + "。";
         if (int(tree.remainFruit) > 0) return "树上结了 " + int(tree.remainFruit) + " 个" + fruit + "，快摘下来吧！";
         if (int(tree.remainProductTime) <= 0)
         {
            return level < TreeArt.levels(id).length - 1 ? "在长到下一级之前，这棵树都不会结果啦！" : "这棵树已经耗尽了营养，结不出果实了！";
         }
         var next:Date = new Date(Number(tree.nextFruitTime));
         var now:Date = new Date();
         return "下次结果时间为" + (next.date == now.date ? "今" : "明") + "天" + next.hours + "：00，还可以结果 " + int(tree.remainProductTime) + " 次。";
      }

      private static function fruitName(p:Plant):String
      {
         if (p == null) return "果实";
         try
         {
            var items:IItemService = ServiceContainer.getService(IItemService) as IItemService;
            var it:Object = items.getItemById(p.fruitId);
            if (it != null) return it.name;
         }
         catch (e:Error) {}
         return "果实";
      }

      private function bar(x:int, y:int, label:String, v:int, max:int, color:uint):void
      {
         var t:TextField = RUI.text(13, RUI.BLUE, true);
         t.text = label;
         t.x = x;
         t.y = y;
         body.addChild(t);
         var w:int = 180;
         var s:Shape = new Shape();
         s.graphics.lineStyle(1, 0x5FA8E0);
         s.graphics.beginFill(0xFFFFFF);
         s.graphics.drawRoundRect(0, 0, w, 16, 16, 16);
         s.graphics.endFill();
         s.graphics.lineStyle();
         var f:Number = max > 0 ? Math.min(1, v / max) : 1;
         if (f > 0)
         {
            s.graphics.beginFill(color);
            s.graphics.drawRoundRect(1, 1, Math.max(14, (w - 2) * f), 14, 14, 14);
            s.graphics.endFill();
         }
         s.x = x + 60;
         s.y = y + 1;
         body.addChild(s);
         var n:TextField = RUI.text(12, 0x335577, true);
         n.text = Math.min(v, max) + "/" + max;
         n.x = x + 60 + w + 6;
         n.y = y;
         body.addChild(n);
      }

      private function addButton(label:String, f:Function, x:int, y:int, top:uint, bottom:uint, name:String):Sprite
      {
         var b:Sprite = RUI.button(label, f, 86, 30, top, bottom, name);
         b.x = x;
         b.y = y;
         body.addChild(b);
         return b;
      }

      private function send(cmd:String):void
      {
         if (tree == null) return;
         SocketClient.instance.sendXtMessage("PlantExtension", cmd, {owner: owner, userPlantId: int(tree.id)});
      }

      private function dig():void
      {
         if (!digAsked)
         {
            digAsked = true;
            say("铲除以后这棵树就没有了，再点一次「铲除」确定。");
            return;
         }
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_garden", {op: "dig", userPlantId: int(tree.id)});
      }

      // ───── replies ─────

      private static const WRONG:Object = {
         "-1": "树上的果实已经被摘光了！",
         "-2": "很抱歉，你的晶币余额不足。",
         "-5": "今天已经照顾过两次了，明天再来吧！",
         "-9": "这棵树已经达到最高级了呀",
         "-16": "你身上已经拥有很多果实了！",
         "-17": "在到达下一等级之前已经不能增加了！",
         "-19": "这棵植物可能已经被铲走了呀！",
         "-21": "植树盆里已经种着一棵树了。"
      };

      private function onCare(e:SocketClientEvent):void
      {
         var r:Object = e.params.result || {};
         var code:int = int(r.result);
         var text:String = code == 1 ? "小树长大了一级！" : code == 0 ? (e.type == "80_3" ? "添加了雨露，健康值增加了！" : "添加了养料，营养值增加了！") : WRONG[String(code)] || "没有成功。";
         if (r.userPlant) setTree(r.userPlant);
         say(text);
         if (onChange != null) onChange(tree);
      }

      private function onPick(e:SocketClientEvent):void
      {
         var r:Object = e.params.result || {};
         var code:int = int(r.result);
         if (r.userPlant) setTree(r.userPlant);
         var p:Plant = tree ? TreeArt.plant(int(tree.plantId)) : null;
         say(code == 0 ? "你成功收获了 " + int(r.extData) + " 个" + fruitName(p) + "！" : WRONG[String(code)] || "没有成功。");
         if (onChange != null) onChange(tree);
      }

      private function onGarden(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (p.op == "info") return;
         var code:int = int(p.result);
         setTree(p.plant);
         if (code != 0) say(WRONG[String(code)] || "没有成功。");
         else if (p.op == "buy") say("种下了一棵小树！每天记得给它添加雨露和养料哦。");
         else if (p.op == "dig") say("树已经铲除了，植树盆空了出来。");
         if (onChange != null) onChange(tree);
      }

      private function say(text:String):void
      {
         said.text = text || "";
      }

      public function close():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.removeEventListener("80_3", onCare);
         sc.removeEventListener("80_4", onCare);
         sc.removeEventListener("80_5", onPick);
         sc.removeEventListener("revival_garden", onGarden);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }

      public static function closeIfOpen():void
      {
         if (current != null) current.close();
      }
   }
}
