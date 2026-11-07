package mmo.zoo.revival
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;

   /** REBUILT (the era FodderIconContainer's art): a thing that turns into 饲料, with how many one has. */
   public class FodderIcon extends MovieClip
   {
      public var itemIcon:MovieClip;
      public var select:MovieClip;
      public var txtCount:TextField;
      public var txtName:TextField;

      public var item:UserItem;

      public function FodderIcon()
      {
         super();
         stop();
         if (select != null) select.visible = false;
         for each (var t:TextField in [txtCount, txtName]) if (t != null) t.mouseEnabled = false;
      }

      public function set selected(v:Boolean):void
      {
         if (select != null) select.visible = v && item != null;
      }

      public function show(u:UserItem):void
      {
         item = u;
         selected = false;
         while (itemIcon != null && itemIcon.numChildren > 0) itemIcon.removeChildAt(0);
         TipsManager.getInstance().removeTips(this);
         buttonMode = u != null;
         txtCount.text = u ? String(u.available) : "";
         txtName.text = u ? u.material.name : "";
         if (u == null) return;
         TipsManager.getInstance().addTips(this, u.material.name + "：每个可以转化为" + FeederPanel.POINTS[u.materialId] + "点饲料");
         var s:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         if (s == null) return;
         var id:int = u.materialId;
         var put:Function = function(v:DisplayObject):void
         {
            if (v == null || item == null || item.materialId != id || itemIcon == null) return;
            DisplayUtil.scaleDisplay(v, 46, 46);
            itemIcon.addChild(v);
         };
         var got:Function = function(e:MaterialServiceEvent):void
         {
            if (int(e.params.id) != id) return;
            s.removeEventListener(MaterialServiceEvent.onGetView, got);
            put(e.params.view as DisplayObject);
         };
         s.addEventListener(MaterialServiceEvent.onGetView, got);
         var v0:DisplayObject = s.getView(id);
         if (v0 != null)
         {
            s.removeEventListener(MaterialServiceEvent.onGetView, got);
            put(v0);
         }
      }
   }
}
