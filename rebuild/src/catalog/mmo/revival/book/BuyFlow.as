package mmo.revival.book
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.FocusEvent;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.MaterialClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.Material;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;

   /**
    * REBUILT buying (the 2013 confirm dialog was in the lost
    * catalog/catalogservice; drawn here). Shows the item's picture, name and
    * price from the 2013 material data, then sends MaterialClient.buyMaterial
    * (MaterialExtension "buyMaterial" {tp, mi, qt}) and waits for the reply
    * {res, tp, mi, qt}; the server also pushes onAmountUpdated (the original
    * AmountUpdateService adds the item) and onScoreUpdated (晶币).
    *
    * Goods of real money (rmb, priced in 星币 on the era pages, "原价" and
    * the half "蓝宝石价") are bought with 星币 (UserInfo.xingbi, which the
    * revival's 工具箱 adds): buyMaterial with ed = true, the server takes
    * the 星币 and pushes onXingBiUpdate.
    *
    * How many: the 2013 dialog's count, as the 2013 library's UseNumericComponent
    * works it (mc_usenum: btnFirst, btnDec, txtValue for digits, btnAdd, btnEnd;
    * from 1 to the most one may have, a plant one), the price following it.
    */
   public class BuyFlow
   {
      public static function buy(info:BuyMaterialInfo, done:Function):void
      {
         var service:IMaterialService = null;
         var material:Material = null;
         try
         {
            var factory:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            service = factory.getService(info.type);
            material = service.getMaterialById(info.id);
         }
         catch (e:Error)
         {
            RLog.error("buy " + info, e);
         }
         if (material == null)
         {
            message("这件商品现在买不到哦。");
            if (done != null) done(false);
            return;
         }
         // A tree is bought as a 树苗, kept until it is planted (several may be had).
         if (material.maxQuantity <= 1 && info.type != 9 && service.hasMaterial(info.id))
         {
            message("你已经有" + material.name + "了！");
            if (done != null) done(false);
            return;
         }
         // How many more may be had (the server refuses more): packs of unitage each.
         var owned:int = 0;
         try
         {
            var mine:Object = service.getMyMaterialById(info.id);
            if (mine != null) owned = int(mine.quantity);
         }
         catch (e:Error) {}
         var room:int = Math.max(0, Math.max(1, material.maxQuantity) - owned);
         var packs:int = info.type == 9 ? 1 : Math.min(9999, int(room / Math.max(1, info.unitage)));
         if (packs < 1)
         {
            message("你的" + material.name + "已经满了，不能再买了哦！");
            if (done != null) done(false);
            return;
         }
         // Clothes carry only a buy-back value; config.xml's buyback percent 0.5 makes the price twice that.
         var unit:int = material.price > 0 ? material.price : material.sale * 2;
         var member:Boolean = isMember();
         // The 魂石 of 魔龙之战 (636–638): "星币获取", a price the 2013 table does not have (the server's, RECONSTRUCTED).
         var rmb:int = material.rmb > 0 ? material.rmb : (info.type == 2 && info.id >= 636 && info.id <= 638 ? 100 : 0);
         var starCoins:Boolean = unit <= 0 && rmb > 0;
         if (starCoins) unit = member ? Math.ceil(rmb / 2) : rmb;
         if (material.vip && !member)
         {
            message("只有蓝宝石才能购买" + material.name + "哦！（工具箱里可以成为蓝宝石）");
            if (done != null) done(false);
            return;
         }
         // What is sent (realQuantity: packs × their size, a book's "×n" button) is what the server charges for.
         info.quantity = Math.max(1, Math.min(info.quantity, packs));
         confirm(material, info, unit, packs, service, starCoins, member, function(ok:Boolean):void
         {
            if (!ok) { if (done != null) done(false); return; }
            var price:int = unit * Math.max(1, info.realQuantity);
            if (!starCoins && UserInfo.score >= 0 && UserInfo.score < price)
            {
               message("你的晶币不够哦！");
               if (done != null) done(false);
               return;
            }
            if (starCoins && UserInfo.xingbi < price)
            {
               message("你的星币不够哦！（工具箱里可以增加星币）");
               if (done != null) done(false);
               return;
            }
            var onReply:Function = function(e:SocketClientEvent):void
            {
               SocketClient.instance.removeEventListener(MaterialClient.cmdBuyMaterial, onReply);
               var res:int = int(e.params.res);
               if (e.params.xingbi != undefined) UserInfo.xingbi = int(e.params.xingbi);
               // A 礼包 is opened at once: got says what it held (server giftbags.ts).
               if (res == 1 && e.params.got != undefined) message("购买成功！打开了" + material.name + "，得到：" + String(e.params.got) + "。" + (String(e.params.got).indexOf("经验") >= 0 ? "经验放进了家园的经验分配器。" : ""));
               else if (res == 1 && info.type == 9) message("购买成功！到家园点一下植树盆，就可以种下" + material.name + "。");
               else if (res == 1) message("购买成功！" + material.name + "已经放进你的" + (info.type == 0 ? "衣橱" : info.type == 1 ? "家具仓库" : "背包") + "。");
               else if (res == -2) message("你的晶币不够哦！");
               else if (res == -5) message("你的星币不够哦！（工具箱里可以增加星币）");
               else if (res == -6) message("只有蓝宝石才能购买哦！");
               else if (res == -4 && info.type == 9) message("你的" + material.name + "树苗已经满了，不能再买了哦！");
               else if (res == -4) message("你已经有" + material.name + "了！");
               else message("没有买成，请再试一次。");
               if (done != null) done(res == 1);
            };
            SocketClient.instance.addEventListener(MaterialClient.cmdBuyMaterial, onReply);
            MaterialClient.getInstance().buyMaterial(info.type, info.id, info.realQuantity, starCoins);
         });
      }

      private static function isMember():Boolean
      {
         try { return MemberManager.instance.isMember(); } catch (e:Error) {}
         return false;
      }

      private static function confirm(m:Material, info:BuyMaterialInfo, unit:int, packs:int, service:IMaterialService, starCoins:Boolean, member:Boolean, answer:Function):void
      {
         var counted:Boolean = packs > 1;
         var h:int = counted ? 250 : 210;
         var box:Sprite = panel(360, h);
         var title:TextField = text(16, 0x1A5FA8, true);
         title.text = "确认购买";
         title.x = (360 - title.width) / 2;
         title.y = 12;
         box.addChild(title);
         var pic:Sprite = new Sprite();
         pic.x = 30;
         pic.y = 50;
         box.addChild(pic);
         try
         {
            var view:DisplayObject = service.getView(info.id);
            if (view != null)
            {
               var b:Object = view.getBounds(view);
               var s:Number = Math.min(1, 100 / Math.max(1, b.width), 100 / Math.max(1, b.height));
               view.scaleX = view.scaleY = s;
               view.x = -b.left * s + (100 - b.width * s) / 2;
               view.y = -b.top * s + (100 - b.height * s) / 2;
               pic.addChild(view);
            }
         }
         catch (e:Error) {}
         var name:TextField = text(15, 0x333333, true);
         name.text = m.name + (info.unitage > 1 ? "（每份" + info.unitage + "个）" : "");
         name.x = 150;
         name.y = 58;
         box.addChild(name);
         var cost:TextField = text(14, 0xC77700, true);
         cost.x = 150;
         cost.y = 86;
         box.addChild(cost);
         var each:TextField = text(12, 0x666666, false);
         each.x = 150;
         each.y = 108;
         box.addChild(each);
         var have:TextField = text(12, 0x666666, false);
         have.text = starCoins ? "我的星币：" + UserInfo.xingbi : "我的晶币：" + (UserInfo.score < 0 ? "…" : String(UserInfo.score));
         have.x = 150;
         have.y = 126;
         box.addChild(have);
         var showPrice:Function = function():void
         {
            var price:int = unit * Math.max(1, info.realQuantity);
            cost.text = price <= 0 ? "免费" : starCoins ? "价格：" + price + " 星币" + (member ? "（蓝宝石价）" : "") : "价格：" + price + " 晶币";
            each.text = counted && unit > 0 ? "单价：" + unit + (starCoins ? " 星币" : " 晶币") : "";
         };
         showPrice();
         if (counted) box.addChild(counter(info, packs, showPrice));
         var ok:Sprite = pill("购 买", 0x40A93C, function():void { remove(box); answer(true); });
         ok.name = "buyOk";
         ok.x = 70;
         ok.y = h - 50;
         box.addChild(ok);
         var no:Sprite = pill("取 消", 0x8A8A8A, function():void { remove(box); answer(false); });
         no.name = "buyCancel";
         no.x = 200;
         no.y = h - 50;
         box.addChild(no);
         show(box);
      }

      /**
       * 购买数量: |< − [n] + >| and the most, as UseNumericComponent: digits only, an empty or 0
       * field goes back to 1, more than the most becomes the most; each change sets info.quantity.
       */
      private static function counter(info:BuyMaterialInfo, most:int, changed:Function):Sprite
      {
         var row:Sprite = new Sprite();
         row.name = "buyCount";
         row.x = 30;
         row.y = 158;
         var label:TextField = text(14, 0x333333, true);
         label.text = "购买数量：";
         label.y = 4;
         row.addChild(label);
         var field:TextField = new TextField();
         field.name = "txtValue";
         field.type = TextFieldType.INPUT;
         field.defaultTextFormat = new TextFormat("Arial", 14, 0x333333, true, null, null, null, null, "center");
         field.restrict = "0-9";
         field.maxChars = 4;
         field.border = true;
         field.borderColor = 0x3A8FD9;
         field.background = true;
         field.backgroundColor = 0xFFFFFF;
         field.width = 52;
         field.height = 22;
         field.x = 136;
         field.y = 3;
         var buttons:Array = [];
         var put:Function = function(n:int):void
         {
            info.quantity = Math.max(1, Math.min(most, n));
            field.text = String(info.quantity);
            for each (var bt:Object in buttons) bt.b.alpha = bt.on() ? 1 : 0.4;
            changed();
         };
         var button:Function = function(caption:String, x:int, to:Function, on:Function, name:String):void
         {
            var b:Sprite = new Sprite();
            b.name = name;
            b.buttonMode = true;
            b.mouseChildren = false;
            b.graphics.lineStyle(1, 0xFFFFFF);
            b.graphics.beginFill(0x3A8FD9);
            b.graphics.drawRoundRect(0, 0, 24, 22, 8, 8);
            b.graphics.endFill();
            var t:TextField = text(13, 0xFFFFFF, true);
            t.text = caption;
            t.x = (24 - t.width) / 2;
            t.y = 2;
            b.addChild(t);
            b.x = x;
            b.y = 3;
            b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); if (on()) put(to()); });
            row.addChild(b);
            buttons.push({b: b, on: on});
         };
         button("|<", 78, function():int { return 1; }, function():Boolean { return info.quantity > 1; }, "btnFirst");
         button("-", 106, function():int { return info.quantity - 1; }, function():Boolean { return info.quantity > 1; }, "btnDec");
         row.addChild(field);
         button("+", 192, function():int { return info.quantity + 1; }, function():Boolean { return info.quantity < most; }, "btnAdd");
         button(">|", 220, function():int { return most; }, function():Boolean { return info.quantity < most; }, "btnEnd");
         var max:TextField = text(12, 0x666666, false);
         max.text = "最多" + most;
         max.x = 252;
         max.y = 6;
         row.addChild(max);
         field.addEventListener(Event.CHANGE, function(e:Event):void
         {
            if (field.text == "") return;
            var n:int = int(field.text);
            if (n < 1 || n > most) put(n);
            else
            {
               info.quantity = n;
               for each (var bt:Object in buttons) bt.b.alpha = bt.on() ? 1 : 0.4;
               changed();
            }
         });
         field.addEventListener(FocusEvent.FOCUS_OUT, function(e:FocusEvent):void { put(int(field.text)); });
         // A click into the field takes all of it, so that the number typed replaces it.
         var fresh:Boolean = false;
         field.addEventListener(FocusEvent.FOCUS_IN, function(e:FocusEvent):void { fresh = true; });
         field.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
         {
            if (fresh) field.setSelection(0, field.length);
            fresh = false;
         });
         put(info.quantity);
         return row;
      }

      public static function message(s:String):void
      {
         var t:TextField = text(14, 0x333333, true);
         t.wordWrap = true;
         t.width = 280;
         t.text = s;
         t.x = 20;
         t.y = 24;
         // As tall as the text needs (a 礼包's list runs to several lines).
         var okY:int = Math.max(84, int(t.y + t.height + 14));
         var box:Sprite = panel(320, okY + 46);
         box.addChild(t);
         var ok:Sprite = pill("确 定", 0x3A8FD9, function():void { remove(box); });
         ok.name = "msgOk";
         ok.x = 115;
         ok.y = okY;
         box.addChild(ok);
         show(box);
      }

      private static function show(box:Sprite):void
      {
         var layer:Sprite = new Sprite();
         layer.graphics.beginFill(0x000000, 0.25);
         layer.graphics.drawRect(0, 0, 960, 560);
         layer.graphics.endFill();
         layer.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         box.x = Math.round((960 - box.width) / 2);
         box.y = Math.round((560 - box.height) / 2);
         layer.addChild(box);
         LayerManager.getBaseTop().addChild(layer);
      }

      private static function remove(box:Sprite):void
      {
         if (box.parent && box.parent.parent) box.parent.parent.removeChild(box.parent);
      }

      private static function panel(w:int, h:int):Sprite
      {
         var s:Sprite = new Sprite();
         var m:Matrix = new Matrix();
         m.createGradientBox(w, h, Math.PI / 2);
         s.graphics.lineStyle(3, 0x3A8FD9);
         s.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xDDF0FF], [1, 1], [0, 255], m);
         s.graphics.drawRoundRect(0, 0, w, h, 22, 22);
         s.graphics.endFill();
         s.filters = [new DropShadowFilter(3, 90, 0, 0.4, 8, 8)];
         return s;
      }

      private static function pill(label:String, color:uint, f:Function):Sprite
      {
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginFill(color);
         b.graphics.drawRoundRect(0, 0, 90, 30, 26, 26);
         b.graphics.endFill();
         var t:TextField = text(14, 0xFFFFFF, true);
         t.text = label;
         t.x = (90 - t.width) / 2;
         t.y = 5;
         b.addChild(t);
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
         return b;
      }

      private static function text(size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         return t;
      }
   }
}
