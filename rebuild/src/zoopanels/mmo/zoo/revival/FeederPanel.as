package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;

   /**
    * REBUILT 饲料机 of the zoo: the era FeedingMachinePanel (zoo/zoores_5, 2011–12) on its art,
    * with the era's rules (server zoo.ts): the machine holds at most 800 points of 饲料, each
    * animal still growing eats 6 an hour, and with it empty they are hungry and stop growing.
    * 预计可用 is the hours it lasts; the things one gathers (炎冰, 蓝晶, 金块 … of the era
    * FeedingCommonConfig) go in, four a page (AddFodderPanel, how many); 快速添加饲料 fills it
    * for 晶币 (QuickAddPanel). The NPC tells one where 饲料 comes from when one has none.
    */
   public class FeederPanel extends MovieClip
   {
      public var FodderMovie:MovieClip;
      public var btnClose:SimpleButton;
      public var btnNext:SimpleButton;
      public var btnPrev:SimpleButton;
      public var fodderMC:MovieClip;
      public var ic0:MovieClip;
      public var ic1:MovieClip;
      public var ic2:MovieClip;
      public var ic3:MovieClip;
      public var mcNpc:MovieClip;
      public var mcQuickAdd:MovieClip;
      public var txtFodderCount:TextField;
      public var txtPageTotal:TextField;
      public var txtTime:TextField;

      /** era FeedingCommonConfig: item id -> points (server FODDER_POINTS). */
      public static const POINTS:Object = {38: 31, 39: 31, 40: 30, 84: 28, 85: 29, 86: 71, 87: 69, 90: 32, 91: 71, 93: 71, 122: 32, 124: 71, 133: 70, 165: 32, 167: 70, 198: 28, 211: 31, 212: 29, 213: 72};

      private var owner:String;
      private var mine:Boolean;
      private var growing:int;
      private var fodder:int;
      private var max:int;
      private var cost:int;
      private var items:Array = [];
      private var page:int;
      private var onChange:Function;

      /** info: 97_1's (fodder, fodderMax, fillCost); growing: how many animals eat; onChange(): the machine was filled. */
      public static function show(owner:String, mine:Boolean, info:Object, growing:int, onChange:Function):void
      {
         ModalDialogManager.getInstance().addModalDialog(new FeederPanel(owner, mine, info, growing, onChange));
      }

      public function FeederPanel(owner:String, mine:Boolean, info:Object, growing:int, onChange:Function)
      {
         super();
         stop();
         name = "feederPanel";
         this.owner = owner;
         this.mine = mine;
         this.growing = growing;
         this.onChange = onChange;
         fodder = int(info.fodder);
         max = Math.max(1, int(info.fodderMax));
         cost = int(info.fillCost);
         if (fodderMC != null) fodderMC.gotoAndStop(1);
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         btnPrev.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if (page > 0) { page--; draw(); } });
         btnNext.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { if ((page + 1) * 4 < items.length) { page++; draw(); } });
         mcQuickAdd.buttonMode = true;
         mcQuickAdd.addEventListener(MouseEvent.CLICK, onQuick);
         var how:SimpleButton = mcNpc ? mcNpc.getChildByName("btnHow") as SimpleButton : null;
         if (how != null) how.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { ModalDialogManager.getInstance().addModalDialog(new FodderHow()); });
         for (var i:int = 0; i < 4; i++)
         {
            var ic:MovieClip = this["ic" + i] as MovieClip;
            ic.addEventListener(MouseEvent.CLICK, onItem);
         }
         collect();
         fresh();
      }

      /** The things one has that turn into 饲料. */
      private function collect():void
      {
         items = [];
         try
         {
            var s:IItemService = ServiceContainer.getService(IItemService) as IItemService;
            for each (var u:UserItem in s.getMyItemsByType(2)) if (POINTS[u.materialId] && u.available > 0) items.push(u);
         }
         catch (e:Error) {}
         if (mcNpc != null)
         {
            mcNpc.visible = items.length == 0;
            if (mcNpc.visible) mcNpc.gotoAndPlay(1);
            else mcNpc.gotoAndStop(1);
         }
         page = Math.min(page, Math.max(0, Math.ceil(items.length / 4) - 1));
         draw();
      }

      private function draw():void
      {
         for (var i:int = 0; i < 4; i++) FodderIcon(this["ic" + i]).show(items[page * 4 + i] as UserItem);
         if (txtPageTotal != null) txtPageTotal.text = (page + 1) + "/" + Math.max(1, Math.ceil(items.length / 4));
      }

      private function fresh():void
      {
         txtTime.text = growing > 0 ? String(int(fodder / (growing * 6))) : "----";
         txtFodderCount.text = fodder + "/" + max;
         if (FodderMovie != null) FodderMovie.gotoAndStop(Math.min(FodderMovie.totalFrames, int(fodder * 8 / max) + 1));
      }

      private function refused():Boolean
      {
         if (!mine) ModalDialogManager.getInstance().addModalDialog(new FodderFull(2));
         else if (fodder >= max) ModalDialogManager.getInstance().addModalDialog(new FodderFull(1));
         else return false;
         return true;
      }

      private function onItem(e:MouseEvent):void
      {
         var ic:FodderIcon = e.currentTarget as FodderIcon;
         if (ic == null || ic.item == null) return;
         for (var i:int = 0; i < 4; i++) FodderIcon(this["ic" + i]).selected = this["ic" + i] == ic;
         if (refused()) return;
         var points:int = int(POINTS[ic.item.materialId]);
         ModalDialogManager.getInstance().addModalDialog(new FodderAdd(ic.item, points, Math.ceil((max - fodder) / points), function(n:int):void { fill(ic.item.materialId, n); }));
      }

      private function onQuick(e:MouseEvent):void
      {
         if (refused()) return;
         ModalDialogManager.getInstance().addModalDialog(new FodderQuick(cost, function():void { fill(-1, 0); }));
      }

      private function fill(item:int, n:int):void
      {
         ZooKit.ask("97_12", {name: owner, itemId: item, num: n}, function(p:Object):void
         {
            var r:int = int(p.res);
            if (r == -2)
            {
               NewDialog.showFailMessage("很抱歉，你的晶币不够了。");
               return;
            }
            if (r != 1)
            {
               NewDialog.showFailMessage(r == -3 ? "饲料已经满了哦~" : "没有这么多可以加了。");
               return;
            }
            fodder = int(p.fodder);
            cost = int(p.fillCost);
            if (fodderMC != null) fodderMC.gotoAndPlay(1);
            fresh();
            collect();
            if (item == -1) NewDialog.showSucceedMessage("饲料已经添加满了哦~");
            if (onChange != null) onChange();
         });
      }

      private function close():void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}
