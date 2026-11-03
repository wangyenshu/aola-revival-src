package mmo.pet.petitem
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.TextField;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.ItemTypes;
   import mmo.interfaces.material.item.UserItem;
   import mmo.revival.RLog;
   import mmo.util.component.page.PageComponent;
   import mmo.util.component.page.PageComponentEvent;

   /**
    * The 亚比道具 page of the pet bag, on the later copy's art (symbol 668, its frame
    * 5: twenty squares p_0..p_19 and the pager). It lists the bag's items of the
    * 2013 types PET (5) and ONLY_NOT_BATTLE (7), in the order of ORDER (HP, uses, the
    * cures, experience, 学习力, 性格, the stones), and redraws when an item is used.
    */
   public class PetItemPanel extends MovieClip implements IDispose
   {
      public var prevBtn:SimpleButton;
      public var nextBtn:SimpleButton;
      public var pageTxt:TextField;
      // The squares of the art (frame 1–4 have five, frame 5 twenty), for where the items go.
      public var p_0:MovieClip;
      public var p_1:MovieClip;
      public var p_2:MovieClip;
      public var p_3:MovieClip;
      public var p_4:MovieClip;
      public var p_5:MovieClip;
      public var p_6:MovieClip;
      public var p_7:MovieClip;
      public var p_8:MovieClip;
      public var p_9:MovieClip;
      public var p_10:MovieClip;
      public var p_11:MovieClip;
      public var p_12:MovieClip;
      public var p_13:MovieClip;
      public var p_14:MovieClip;
      public var p_15:MovieClip;
      public var p_16:MovieClip;
      public var p_17:MovieClip;
      public var p_18:MovieClip;
      public var p_19:MovieClip;

      /** The order the page lists items in; the others after them. */
      private static const ORDER:Array = [30, 60, 61, 102, 263, 390, 354, 355, 31, 103, 104, 391, 94, 95, 96, 97, 98, 99, 100, 101,
         233, 234, 235, 236, 237, 238, 239, 240, 241, 419, 664, 665, 43, 120, 499, 378, 62, 189, 663, 44,
         524, 525, 526, 527, 528, 529, 154, 155, 156, 157, 158, 159, 523, 63, 65, 193, 220, 66, 414, 415, 416, 417, 418,
         381, 382, 383, 384, 385, 614, 615, 616, 620, 621, 645, 646, 647, 648, 617, 618, 619, 622, 623, 631, 632, 642, 649, 650, 651, 652, 657];
      /** Used in their own machines (亚比克隆仪, 亚比重组仪), not here. */
      private static const ELSEWHERE:Array = [34, 35];
      private static const PER_PAGE:int = 20;

      private var page:PageComponent;
      private var box:Sprite = new Sprite();
      private var itemUse:PetItemUse;

      public function PetItemPanel()
      {
         super();
         gotoAndStop(5);
         addChild(box);
      }

      public function init(petId:Function):void
      {
         itemUse = new PetItemUse(petId, refresh);
         page = new PageComponent(sorted(), PER_PAGE, prevBtn, nextBtn, pageTxt);
         page.addEventListener(PageComponentEvent.ON_PAGE_CHANGE, onPage);
         SocketClient.instance.addEventListener("onAmountUpdated", onAmount);
         addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
         draw();
      }

      private function sorted():Array
      {
         var list:Array = [];
         try
         {
            var svc:IItemService = ServiceContainer.getService(IItemService) as IItemService;
            list = svc.getMyItemsByType(ItemTypes.PET).concat(svc.getMyItemsByType(ItemTypes.ONLY_NOT_BATTLE));
         }
         catch (e:Error) { RLog.error("petitem list", e); }
         list = list.filter(function(u:UserItem, i:int, a:Array):Boolean
         {
            return u != null && u.quantity > 0 && ELSEWHERE.indexOf(u.materialId) < 0;
         });
         list.sort(function(a:UserItem, b:UserItem):int
         {
            var x:int = ORDER.indexOf(a.materialId), y:int = ORDER.indexOf(b.materialId);
            if (x < 0) x = int.MAX_VALUE;
            if (y < 0) y = int.MAX_VALUE;
            return x != y ? (x < y ? -1 : 1) : a.materialId - b.materialId;
         });
         return list;
      }

      public function refresh():void
      {
         if (page == null) return;
         page.updateData(sorted(), false);
         draw();
      }

      private function onPage(e:PageComponentEvent):void
      {
         draw();
      }

      private function onAmount(e:SocketClientEvent):void
      {
         // The item counts change before the use's reply (and when items come from elsewhere).
         refresh();
      }

      private function draw():void
      {
         while (box.numChildren > 0) box.removeChildAt(0);
         var shown:Array = page.getCurrentPageData();
         for (var i:int = 0; i < shown.length && i < PER_PAGE; i++)
         {
            var slot:DisplayObject = getChildByName("p_" + i);
            var v:ItemView = new ItemView(shown[i] as UserItem, itemUse.useItem);
            v.x = slot ? slot.x : (i % 5) * 67;
            v.y = slot ? slot.y : int(i / 5) * 59;
            box.addChild(v);
         }
      }

      private function onRemoved(e:Event):void
      {
         dispose();
      }

      public function dispose():void
      {
         removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
         SocketClient.instance.removeEventListener("onAmountUpdated", onAmount);
         if (page != null)
         {
            page.removeEventListener(PageComponentEvent.ON_PAGE_CHANGE, onPage);
            page.disposeComponent();
            page = null;
         }
         if (itemUse != null) itemUse.dispose();
         itemUse = null;
      }
   }
}
