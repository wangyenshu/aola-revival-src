package mmo.pet.petitem
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.viewloader.ViewLoader;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;

   /**
    * One square of the 亚比道具 page (the later copy's art, symbol 706): the item's
    * picture (item/view<id>), how many the bag holds, its name and description as
    * the tip. A click uses it (PetItemUse) on the 亚比 the pet bag shows. Without an item
    * (PetItem.createSquare), the square alone.
    */
   public class ItemView extends Sprite
   {
      public var txtNum:TextField;
      public var mcRedDot:MovieClip;

      private var item:UserItem;
      private var onUse:Function;

      public function ItemView(u:UserItem, onClick:Function)
      {
         super();
         item = u;
         onUse = onClick;
         if (u == null)
         {
            if (txtNum) txtNum.text = "";
            if (mcRedDot) mcRedDot.visible = false;
            return;
         }
         var id:int = u.materialId;
         name = "petItem" + id;
         // The whole square answers the pointer, before (and around) the picture.
         graphics.beginFill(0, 0);
         graphics.drawRect(0, 0, 55, 55);
         graphics.endFill();
         var v:DisplayObject = ViewLoader.instance.getViewCustom("mmo.item.view" + id, "item/view" + id, 45, 45);
         v.x = 5;
         v.y = 3;
         addChildAt(v, 0);
         if (txtNum) txtNum.text = String(u.quantity);
         if (mcRedDot)
         {
            mcRedDot.visible = false;
            mcRedDot.mouseEnabled = false;
         }
         var desc:String = "";
         try
         {
            var it:Item = (ServiceContainer.getService(IItemService) as IItemService).getItemById(id);
            if (it != null) desc = it.description;
         }
         catch (e:Error) {}
         TipsManager.getInstance().addComplexTips(this, u.material ? u.material.name : "", desc);
         buttonMode = true;
         mouseChildren = false;
         addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onUse(item); });
      }
   }
}
