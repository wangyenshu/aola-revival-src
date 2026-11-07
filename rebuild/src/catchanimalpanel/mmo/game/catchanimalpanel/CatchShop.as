package mmo.game.catchanimalpanel
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.viewloader.ViewLoader;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.BuyMaterialInfo;
   import mmo.interfaces.catalog.IBuyMaterial;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.Material;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * REVIVAL 购买道具 of 动物捕捉: the seven things of the game (items 424–430), their pictures
    * (item/view<id>), names and prices from the 2013 material data, each bought through
    * BuyMaterialService (type 2, its 2013 dialog with how many). In their place the panel's
    * button opened the 动物乐园购买册 (catalog201108), which is lost.
    */
   public class CatchShop extends Sprite
   {
      private static const FIRST:int = 424;
      private static const W:int = 520;
      private static const H:int = 330;
      private static var current:CatchShop;

      private var start:StartPanel;
      private var busy:Boolean;

      public static function show(from:StartPanel):void
      {
         if (current != null) current.close();
         current = new CatchShop(from);
         LayerManager.getBaseTop().addChild(current);
      }

      public function CatchShop(from:StartPanel)
      {
         super();
         name = "catchShop";
         start = from;
         addChild(RUI.dim(close));
         var box:Sprite = RUI.panel(W, H, "购买道具", close, "catchShopClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2;
         addChild(box);
         var service:IMaterialService = null;
         try { service = (ServiceContainer.getService(IMaterialFactory) as IMaterialFactory).getService(2); } catch (e:Error) {}
         for (var i:int = 0; i < StartPanel.NAMES.length; i++) box.addChild(row(i, service));
      }

      private function row(i:int, service:IMaterialService):Sprite
      {
         var id:int = FIRST + i;
         var r:Sprite = new Sprite();
         r.name = "catchShopRow" + id;
         r.x = 22 + (i % 2) * 244;
         r.y = 56 + int(i / 2) * 64;
         r.addChild(RUI.well(0, 0, 232, 56));
         var pic:DisplayObject = ViewLoader.instance.getViewCustom("mmo.item.view" + id, "item/view" + id, 44, 44);
         pic.x = 6;
         pic.y = 6;
         r.addChild(pic);
         var m:Material = null;
         try { if (service != null) m = service.getMaterialById(id); } catch (e:Error) {}
         var n:TextField = RUI.text(13, RUI.BLUE, true);
         n.text = m != null ? m.name : StartPanel.NAMES[i];
         n.x = 58;
         n.y = 7;
         r.addChild(n);
         var p:TextField = RUI.text(12, 0x8A5A00, false);
         p.text = m == null ? "" : m.price > 0 ? m.price + " 晶币" : m.rmb > 0 ? m.rmb + " 星币" : "";
         p.x = 58;
         p.y = 30;
         r.addChild(p);
         var b:Sprite = RUI.button("购买", function():void { buy(id); }, 60, 28, 0xFFC45A, 0xF07812, "catchBuy" + id);
         b.x = 164;
         b.y = 14;
         r.addChild(b);
         try
         {
            var it:Item = (ServiceContainer.getService(IItemService) as IItemService).getItemById(id);
            if (it != null && it.description) TipsManager.getInstance().addTips(r, it.description);
         }
         catch (e:Error) {}
         return r;
      }

      private function buy(id:int):void
      {
         if (busy) return;
         busy = true;
         ServiceContainer.instance.tryGetBuyMaterialService(2, function(svc:IBuyMaterial, o:Object):void
         {
            svc.buy(new BuyMaterialInfo(2, id, 1, 1), function(ok:Boolean):void
            {
               busy = false;
               if (ok && start != null) start.ask();
            });
         });
      }

      public function close():void
      {
         if (parent != null) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
