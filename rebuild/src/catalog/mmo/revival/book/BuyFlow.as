package mmo.revival.book
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.catalog.dialogs.ConfirmBuy;
   import mmo.catalog.dialogs.ConfirmBuyClothes;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
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
   import mmo.interfaces.material.clothes.ClothesSuit;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.interfaces.avatar.IAvatarService;
   import flash.geom.Rectangle;
   import flash.utils.setTimeout;
   import mmo.revival.RMaterialView;
   import mmo.revival.RLog;

   /**
    * REBUILT buying, in catalog/catalogservice only (the book modules buy through its
    * BuyMaterialService<type>). The dialogs are those of the catalogservice art under the 2013 URL
    * (mmo.catalog.dialogs: ConfirmBuy, ConfirmBuyClothes; the 2013 copy is lost): the
    * item's picture, name and price from the 2013 material data, 购买数量 with the 2013 library's
    * UseNumericComponent (from 1 to the most one may have, a plant one), then
    * MaterialClient.buyMaterial (MaterialExtension "buyMaterial" {tp, mi, qt}) and its reply
    * {res, tp, mi, qt}; the server also pushes onAmountUpdated (the original AmountUpdateService
    * adds the item) and onScoreUpdated (晶币). What was bought, or what went wrong, is said with the
    * 2013 NewDialog (a purchase with the thing's picture large in it).
    *
    * Goods of real money (rmb, priced in 星币 on the era pages, "原价" and the half "蓝宝石价") are
    * bought with 星币 (UserInfo.xingbi, which the revival's 工具箱 adds): buyMaterial with ed = true,
    * the server takes the 星币 and pushes onXingBiUpdate.
    *
    * 购买全套 (buySet): a 套装's clothes in one buyBatchMaterial, in the clothes' dialog.
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
            fail("你已经有" + material.name + "了！");
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
            fail("你的" + material.name + "已经满了，不能再买了哦！");
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
            message("只有蓝宝石才能购买" + material.name + "哦！");
            if (done != null) done(false);
            return;
         }
         // What is sent (realQuantity: packs × their size, a book's "×n" button) is what the server charges for.
         info.quantity = Math.max(1, Math.min(info.quantity, packs));
         // What 蓝宝石 saves (its half price of goods of real money), shown in the dialog.
         var saving:int = starCoins ? rmb - Math.ceil(rmb / 2) : 0;
         confirm(material, info, unit, packs, service, starCoins, member, saving, function(ok:Boolean):void
         {
            if (!ok) { if (done != null) done(false); return; }
            var price:int = unit * Math.max(1, info.realQuantity);
            if (!starCoins && UserInfo.score >= 0 && UserInfo.score < price)
            {
               fail("你的晶币不够哦！");
               if (done != null) done(false);
               return;
            }
            if (starCoins && UserInfo.xingbi < price)
            {
               fail("你的星币不够哦！");
               if (done != null) done(false);
               return;
            }
            var onReply:Function = function(e:SocketClientEvent):void
            {
               SocketClient.instance.removeEventListener(MaterialClient.cmdBuyMaterial, onReply);
               var res:int = int(e.params.res);
               if (e.params.xingbi != undefined) UserInfo.xingbi = int(e.params.xingbi);
               // A 礼包 is opened at once: got says what it held (server giftbags.ts).
               var place:String = info.type == 0 ? "衣橱" : info.type == 1 ? "家具仓库" : "背包";
               var n:int = Math.max(1, info.realQuantity);
               if (res == 1 && e.params.got != undefined) message("购买成功！打开了" + material.name + "，得到：" + String(e.params.got) + "。");
               else if (res == 1 && info.type == 9) bought(material.name + "的树苗已经放入你的背包中。", view(service, info.id, info.type));
               else if (res == 1) bought(n + (info.type == 0 ? "件" : "个") + material.name + "已经放入你的" + place + "中。", view(service, info.id, info.type));
               else if (res == -2) fail("你的晶币不够哦！");
               else if (res == -5) fail("你的星币不够哦！");
               else if (res == -6) fail("只有蓝宝石才能购买哦！");
               else if (res == -4 && info.type == 9) fail("你的" + material.name + "树苗已经满了，不能再买了哦！");
               else if (res == -4) fail("你已经有" + material.name + "了！");
               else fail("没有买成，请再试一次。");
               if (done != null) done(res == 1);
            };
            SocketClient.instance.addEventListener(MaterialClient.cmdBuyMaterial, onReply);
            MaterialClient.getInstance().buyMaterial(info.type, info.id, info.realQuantity, starCoins);
         });
      }

      /**
       * 购买全套 (a page's btnSetBuy_<套装>): the clothes of the 2013 ClothesSuit one has not yet, at
       * their prices added up, in one MaterialClient.buyBatchMaterial (61_4, "tp,mi,qt;…").
       */
      public static function buySet(suitId:int, done:Function):void
      {
         var suit:ClothesSuit = null;
         var service:IMaterialService = null;
         try
         {
            suit = (ServiceContainer.getService(IClothesService) as IClothesService).getSuitDataById(suitId);
            service = (ServiceContainer.getService(IMaterialFactory) as IMaterialFactory).getService(0);
         }
         catch (e:Error) { RLog.error("buy set " + suitId, e); }
         if (suit == null || service == null)
         {
            message("这套服装现在买不到哦。");
            if (done != null) done(false);
            return;
         }
         var member:Boolean = isMember();
         var want:Array = [];
         var names:Array = [];
         var score:int = 0;
         var coins:int = 0;
         var saved:int = 0;
         var had:int = 0;
         var firstId:int = 0;
         for each (var id:int in suit.clothesList)
         {
            var m:Material = null;
            try { m = service.getMaterialById(id); } catch (e1:Error) {}
            if (m == null) continue;
            if (service.hasMaterial(id)) { had++; continue; }
            if (m.vip && !member)
            {
               message("只有蓝宝石才能购买" + m.name + "哦！");
               if (done != null) done(false);
               return;
            }
            var unit:int = m.price > 0 ? m.price : m.sale * 2;
            if (unit <= 0 && m.rmb > 0)
            {
               coins += member ? Math.ceil(m.rmb / 2) : m.rmb;
               saved += m.rmb - Math.ceil(m.rmb / 2);
            }
            else score += unit;
            if (firstId == 0) firstId = id;
            want.push("0," + id + ",1");
            names.push(m.name);
         }
         if (want.length == 0)
         {
            message("你已经有全套" + suit.suitName + "了！");
            if (done != null) done(false);
            return;
         }
         var answer:Function = function(ok:Boolean):void
         {
            if (!ok) { if (done != null) done(false); return; }
            if (UserInfo.score >= 0 && UserInfo.score < score) { fail("你的晶币不够哦！"); if (done != null) done(false); return; }
            if (UserInfo.xingbi < coins) { fail("你的星币不够哦！"); if (done != null) done(false); return; }
            var onReply:Function = function(e:SocketClientEvent):void
            {
               SocketClient.instance.removeEventListener(MaterialClient.cmdBuyBatchMateriaal, onReply);
               var res:int = int(e.params.res);
               if (e.params.xingbi != undefined) UserInfo.xingbi = int(e.params.xingbi);
               if (res == 1) bought(want.length + "件" + suit.suitName + "已经放入你的衣橱中。", view(service, firstId, 0));
               else if (res == -2) fail("你的晶币不够哦！");
               else if (res == -5) fail("你的星币不够哦！");
               else if (res == -6) fail("只有蓝宝石才能购买哦！");
               else if (res == -4) fail("你已经有全套" + suit.suitName + "了！");
               else fail("没有买成，请再试一次。");
               if (done != null) done(res == 1);
            };
            SocketClient.instance.addEventListener(MaterialClient.cmdBuyBatchMateriaal, onReply);
            MaterialClient.getInstance().buyBatchMaterial(want.join(";"));
         };
         // The clothes' dialog: the 套装 (how many pieces, how many one has) at its prices added up,
         // in 晶币 or, for clothes of real money, 星币 (half for 蓝宝石).
         var name:String = suit.suitName;
         // (a 套装 of both 晶币 and 星币 clothes: the 晶币 part said beside it)
         if (score > 0 && coins > 0) name += " +" + score + "晶币";
         ask(new ConfirmBuyClothes(new BuyMaterialInfo(0, firstId, 1, 1), view(service, firstId, 0), name, coins > 0 ? coins : score, coins > 0, member, coins > 0 ? saved : 0), answer);
      }

      private static function isMember():Boolean
      {
         try { return MemberManager.instance.isMember(); } catch (e:Error) {}
         return false;
      }

      private static function confirm(m:Material, info:BuyMaterialInfo, unit:int, packs:int, service:IMaterialService, starCoins:Boolean, member:Boolean, saving:int, answer:Function):void
      {
         var name:String = m.name;
         if (info.type == 0) ask(new ConfirmBuyClothes(info, view(service, info.id, info.type), name, unit, starCoins, member, saving), answer);
         else ask(new ConfirmBuy(info, view(service, info.id, info.type), name, unit, packs, starCoins, member, saving), answer);
      }

      public static function message(s:String):void
      {
         NewDialog.showMessage(s);
      }

      private static function fail(s:String):void
      {
         NewDialog.showFailMessage(s);
      }

      /**
       * 购买成功: what was bought and where it went, with its picture in the 2013 message dialog's
       * picture square (NewDialog.showMessage's icon, fitted large in the middle of the dialog), once
       * the picture has loaded.
       */
      private static function bought(s:String, view:DisplayObject):void
      {
         if (view == null)
         {
            NewDialog.showSucceedMessage(s);
            return;
         }
         var tries:int = 0;
         var go:Function = function():void
         {
            var own:Rectangle = view.getBounds(view);
            var ready:Boolean = own.width > 0 && own.height > 0;
            if (!ready && ++tries < 60)
            {
               setTimeout(go, 50);
               return;
            }
            if (!ready)
            {
               NewDialog.showSucceedMessage(s);
               return;
            }
            // IconDialogBase fits a picture drawn from its top left.
            var pic:Sprite = new Sprite();
            view.scaleX = view.scaleY = 1;
            view.x = -own.x;
            view.y = -own.y;
            pic.addChild(view);
            NewDialog.showMessage(s, pic);
         };
         go();
      }

      /** A dialog of the art (DialogBase): answer(true) on 购买, answer(false) on 取消 or the close. */
      private static function ask(dialog:Sprite, answer:Function):void
      {
         var md:ModalDialog = ModalDialog.getCustomDialog(dialog);
         var done:Boolean = false;
         md.addEventListener(ModalDialogEvent.OK, function(e:ModalDialogEvent):void { if (!done) { done = true; answer(true); } });
         md.addEventListener(ModalDialogEvent.CANCEL, function(e:ModalDialogEvent):void { if (!done) { done = true; answer(false); } });
         md.show();
      }

      private static function view(service:IMaterialService, id:int, type:int):DisplayObject
      {
         if (type == 0) return clothesView(id);
         return RMaterialView.of(service, id);
      }

      /** A piece of clothes' picture (IAvatarService.getClothesIcon, as the later dialog has it), about its middle, 56 across. */
      private static function clothesView(id:int):DisplayObject
      {
         var s:Sprite = new Sprite();
         try
         {
            (ServiceContainer.getService(IAvatarService) as IAvatarService).getClothesIcon(id, -1, -1, function(i:int, icon:Sprite):void
            {
               if (icon == null) return;
               var b:Rectangle = icon.getBounds(icon);
               var k:Number = Math.min(1.5, 56 / Math.max(1, b.width), 56 / Math.max(1, b.height));
               icon.scaleX = icon.scaleY = k;
               icon.x = -(b.x + b.width / 2) * k;
               icon.y = -(b.y + b.height / 2) * k;
               s.addChild(icon);
            });
         }
         catch (e:Error) { RLog.error("buy: clothes icon " + id, e); }
         return s;
      }
   }
}
