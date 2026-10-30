package mmo.revival.book
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
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
         if (material.maxQuantity <= 1 && service.hasMaterial(info.id))
         {
            message("你已经有" + material.name + "了！");
            if (done != null) done(false);
            return;
         }
         // Clothes carry only a buy-back value; config.xml's buyback percent 0.5 makes the price twice that.
         var unit:int = material.price > 0 ? material.price : material.sale * 2;
         if (unit <= 0 && material.rmb > 0)
         {
            message(material.name + "是要用真钱买的商品，复刻版里买不到哦。");
            if (done != null) done(false);
            return;
         }
         var price:int = unit * info.quantity;
         confirm(material, info, price, service, function(ok:Boolean):void
         {
            if (!ok) { if (done != null) done(false); return; }
            if (UserInfo.score >= 0 && UserInfo.score < price)
            {
               message("你的晶币不够哦！");
               if (done != null) done(false);
               return;
            }
            var onReply:Function = function(e:SocketClientEvent):void
            {
               SocketClient.instance.removeEventListener(MaterialClient.cmdBuyMaterial, onReply);
               var res:int = int(e.params.res);
               if (res == 1) message("购买成功！" + material.name + "已经放进你的" + (info.type == 0 ? "衣橱" : "背包") + "。");
               else if (res == -2) message("你的晶币不够哦！");
               else message("没有买成，请再试一次。");
               if (done != null) done(res == 1);
            };
            SocketClient.instance.addEventListener(MaterialClient.cmdBuyMaterial, onReply);
            MaterialClient.getInstance().buyMaterial(info.type, info.id, info.realQuantity);
         });
      }

      private static function confirm(m:Material, info:BuyMaterialInfo, price:int, service:IMaterialService, answer:Function):void
      {
         var box:Sprite = panel(360, 210);
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
         name.text = m.name + (info.realQuantity > 1 ? " ×" + info.realQuantity : "");
         name.x = 150;
         name.y = 66;
         box.addChild(name);
         var cost:TextField = text(14, 0xC77700, true);
         cost.text = price > 0 ? "价格：" + price + " 晶币" : "免费";
         cost.x = 150;
         cost.y = 96;
         box.addChild(cost);
         var have:TextField = text(12, 0x666666, false);
         have.text = "我的晶币：" + (UserInfo.score < 0 ? "…" : String(UserInfo.score));
         have.x = 150;
         have.y = 122;
         box.addChild(have);
         var ok:Sprite = pill("购 买", 0x40A93C, function():void { remove(box); answer(true); });
         ok.name = "buyOk";
         ok.x = 70;
         ok.y = 160;
         box.addChild(ok);
         var no:Sprite = pill("取 消", 0x8A8A8A, function():void { remove(box); answer(false); });
         no.name = "buyCancel";
         no.x = 200;
         no.y = 160;
         box.addChild(no);
         show(box);
      }

      public static function message(s:String):void
      {
         var box:Sprite = panel(320, 130);
         var t:TextField = text(14, 0x333333, true);
         t.wordWrap = true;
         t.width = 280;
         t.text = s;
         t.x = 20;
         t.y = 24;
         box.addChild(t);
         var ok:Sprite = pill("确 定", 0x3A8FD9, function():void { remove(box); });
         ok.name = "msgOk";
         ok.x = 115;
         ok.y = 84;
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
