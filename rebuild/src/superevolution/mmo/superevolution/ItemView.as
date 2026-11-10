package mmo.superevolution
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;
   import mmo.revival.RMaterialView;

   /**
    * One material of a 超进化 (the 2015 module's ItemView on the 2013 libraries): its picture
    * (the 2013 item view), name, and owned / needed; mc 1 未拥有, 2 不足, 3 足够.
    */
   public class ItemView extends Sprite
   {
      public var nameText:TextField;
      public var viewHolder:MovieClip;
      public var numText:TextField;
      public var mc:MovieClip;

      private var view:DisplayObject;
      private var _num:int;
      private var _id:int;
      private var _ifEnough:Boolean = true;

      public function ItemView()
      {
         super();
         nameText.mouseEnabled = false;
         numText.mouseEnabled = false;
      }

      public function get num():int
      {
         return _num;
      }

      public function get id():int
      {
         return _id;
      }

      public function get ifEnough():Boolean
      {
         return _ifEnough;
      }

      public function setView(itemObj:Object):void
      {
         if (view != null && view.parent != null)
         {
            if (view is InteractiveObject) TipsManager.getInstance().removeTips(InteractiveObject(view));
            view.parent.removeChild(view);
         }
         view = null;
         _num = 0;
         _id = 0;
         _ifEnough = true;
         nameText.text = "";
         numText.text = "";
         DisplayUtil.clearFilters(this);
         mc.visible = true;
         if (itemObj == null)
         {
            DisplayUtil.applyGray(this);
            mc.visible = false;
            return;
         }
         var items:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         var mine:UserItem = items.getMyItemById(itemObj.id);
         _num = mine == null ? 0 : mine.quantity;
         _id = itemObj.id;
         var item:Item = items.getItemById(_id);
         // The 2013 item picture, 40 across in the middle of its square (once loaded).
         var v:DisplayObject = RMaterialView.of(IMaterialService(items), _id);
         var holder:Sprite = new Sprite();
         holder.graphics.beginFill(0, 0);
         holder.graphics.drawRect(5, 5, 40, 40);
         holder.graphics.endFill();
         viewHolder.addChild(holder);
         RMaterialView.into(v, holder, 0);
         view = holder;
         if (item != null) TipsManager.getInstance().addComplexTips(holder, item.name, item.description);
         nameText.text = item != null ? item.name : "";
         numText.text = _num + "/" + itemObj.num;
         _ifEnough = _num >= itemObj.num;
         mc.gotoAndStop(_num == 0 ? 1 : _ifEnough ? 3 : 2);
      }
   }
}
