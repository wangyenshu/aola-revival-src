package mmo.treemanager.treepanel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.material.plantitem.IPlantItemService;
   import mmo.interfaces.material.plantitem.PlantItem;
   import mmo.interfaces.material.plantitem.UserPlantItem;

   /**
    * REBUILT 盆栽道具 (yz/panel_res of April 2012, its code on its art, symbol 91): the seven
    * 道具 of PlantItemData, those one has first with how many, the others grey; 使用 the one
    * chosen (铲子 asks first, and only on one's own tree); 购买 the 种植手册's page of them.
    * pick(id): the 道具 to use (-1: none).
    */
   public class SelectPlantToolPanel extends MovieClip
   {
      private static const SQUARES:int = 12;

      public var kuang0:MovieClip;
      public var kuang1:MovieClip;
      public var kuang2:MovieClip;
      public var kuang3:MovieClip;
      public var kuang4:MovieClip;
      public var kuang5:MovieClip;
      public var kuang6:MovieClip;
      public var kuang7:MovieClip;
      public var kuang8:MovieClip;
      public var kuang9:MovieClip;
      public var kuang10:MovieClip;
      public var kuang11:MovieClip;
      public var btnBuy:SimpleButton;
      public var btnOk:SimpleButton;
      public var btnClose:SimpleButton;
      public var _btnNext:SimpleButton;
      public var _btnPrev:SimpleButton;
      public var _pagetxt:TextField;

      private var service:IPlantItemService;
      private var mine:Boolean;
      private var pick:Function;
      private var items:Array = [];
      private var have:Object = {};
      private var chosen:int = -1;
      private var page:int;

      public function SelectPlantToolPanel(mine:Boolean = true, pick:Function = null)
      {
         super();
         name = "plantToolPanel";
         this.mine = mine;
         this.pick = pick;
         service = ServiceContainer.getService(IPlantItemService) as IPlantItemService;
         for (var i:int = 0; i < SQUARES; i++)
         {
            var k:MovieClip = square(i);
            if (k == null) continue;
            k.buttonMode = true;
            k.addEventListener(MouseEvent.CLICK, onSquare);
         }
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { done(-1); });
         btnOk.addEventListener(MouseEvent.CLICK, onOk);
         btnBuy.addEventListener(MouseEvent.CLICK, onBuy);
         _btnPrev.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if (page > 0) { page--; draw(); } });
         _btnNext.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if ((page + 1) * SQUARES < items.length) { page++; draw(); } });
         // A purchase in the 种植手册 while this is open shows at once.
         SocketClient.instance.addEventListener("onAmountUpdated", onAmount);
         // Taken away by other means (another panel clearing the modals): as closed.
         addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void
         {
            SocketClient.instance.removeEventListener("onAmountUpdated", onAmount);
            done(-1);
         });
         collect();
         draw();
      }

      private function square(i:int):MovieClip
      {
         return getChildByName("kuang" + i) as MovieClip;
      }

      /** Those one has first, then the rest (the 2012 panel's order). */
      private function collect():void
      {
         var mineList:Array = [], rest:Array = [];
         have = {};
         if (service != null)
         {
            for each (var u:UserPlantItem in service.getMyMaterials()) if (u.quantity > 0) have[u.materialId] = u.quantity;
            var all:Array = [];
            for each (var p:PlantItem in service.getMaterialsMap()) all.push(p);
            all.sortOn("id", Array.NUMERIC);
            for each (p in all) (have[p.id] ? mineList : rest).push(p);
         }
         items = mineList.concat(rest);
      }

      private function draw():void
      {
         var pages:int = Math.max(1, Math.ceil(items.length / SQUARES));
         page = Math.min(page, pages - 1);
         if (_pagetxt != null) _pagetxt.text = (page + 1) + "/" + pages;
         for (var i:int = 0; i < SQUARES; i++)
         {
            var k:MovieClip = square(i);
            if (k == null) continue;
            var old:Object = k.getChildByName("item");
            if (old != null) k.removeChild(old as Sprite);
            TipsManager.getInstance().removeTips(k);
            var sel:Object = k.getChildByName("selectMc");
            var cnt:TextField = k.getChildByName("_cnt") as TextField;
            var p:PlantItem = items[page * SQUARES + i] as PlantItem;
            if (sel != null) sel.visible = p != null && p.id == chosen;
            if (cnt != null) cnt.visible = p != null;
            if (p == null) continue;
            var v:PlantItemView = new PlantItemView(p);
            v.name = "item";
            k.addChildAt(v, Math.min(1, k.numChildren));
            TipsManager.getInstance().addComplexTips(k, p.name, p.description);
            if (cnt != null) cnt.text = String(int(have[p.id]));
            if (!have[p.id]) DisplayUtil.applyGray(v);
         }
      }

      private function onSquare(e:MouseEvent):void
      {
         var i:int = int(String(MovieClip(e.currentTarget).name).substr(5));
         var p:PlantItem = items[page * SQUARES + i] as PlantItem;
         if (p == null) return;
         chosen = p.id;
         draw();
      }

      private function onOk(e:MouseEvent):void
      {
         if (chosen < 0)
         {
            NewDialog.showMessage("你还没有选择使用的道具！");
            return;
         }
         if (!have[chosen])
         {
            NewDialog.showFailMessage("你还没有这个道具，快去商城购买吧！");
            return;
         }
         if (chosen == 7 && !mine)
         {
            NewDialog.showFailMessage("你不能铲走别人的树哦！");
            return;
         }
         if (chosen != 7)
         {
            done(chosen);
            return;
         }
         var d:ModalDialog = NewDialog.getCofirmDialog("把树铲了就再也拿不回来了，你确定吗？", null, null, NewDialog.getSucceedIcon());
         d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void { done(7); });
         d.show();
      }

      private function onBuy(e:MouseEvent):void
      {
         ServiceContainer.instance.tryGetService("SellBookService", function(svc:IBookClubService, o:Object = null):void
         {
            svc.showPageBy2Index("catalog201102", 2, 2);
         });
      }

      private function onAmount(e:SocketClientEvent):void
      {
         if (String(e.params.amount || "").indexOf("10_") < 0) return;
         // The service adds the purchase on the same event: count after it.
         addEventListener(Event.ENTER_FRAME, function later(ev:Event):void
         {
            removeEventListener(Event.ENTER_FRAME, later);
            collect();
            draw();
         });
      }

      private function done(id:int):void
      {
         var f:Function = pick;
         pick = null;
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (f != null) f(id);
      }
   }
}
