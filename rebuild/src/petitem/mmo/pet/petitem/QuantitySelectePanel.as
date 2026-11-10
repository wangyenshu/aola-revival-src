package mmo.pet.petitem
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.uicomponent.UIComponentEvent;
   import mmo.interfaces.uicomponent.UseNumericComponent;
   import mmo.revival.RMaterialView;

   /**
    * 我要使用 (the later pet/petitem's QuantitySelectePanel on its own art, written again for the 2013
    * libraries, whose UseNumericComponent it works with): the item, what one gives (增加学习力 /
    * 增加经验) times how many, 我拥有, and 使用 / 不使用. callback(n) on 使用.
    */
   public class QuantitySelectePanel extends Sprite
   {
      public var btncancel:SimpleButton;
      public var btnclose:SimpleButton;
      public var btnok:SimpleButton;
      public var mc_usenum:MovieClip;
      public var mc_viewcontainer:MovieClip;
      public var txt_effect:TextField;
      public var txt_mycount:TextField;
      public var txt_name:TextField;
      public var txt_title:TextField;
      public var txtlimit:TextField;

      private var callback:Function;
      private var userItem:UserItem;
      private var baseEffect:int;
      private var canAddEffect:int;
      private var ulstring:String;
      private var usenum:UseNumericComponent = new UseNumericComponent();

      public function QuantitySelectePanel(callback:Function, title:String, userItem:UserItem, baseEffect:int, canAddEffect:int, ulstring:String = null)
      {
         super();
         this.callback = callback;
         this.userItem = userItem;
         this.baseEffect = Math.max(1, baseEffect);
         this.canAddEffect = canAddEffect;
         this.ulstring = ulstring;
         txtlimit.visible = false;
         btnclose.addEventListener(MouseEvent.CLICK, onClose);
         btncancel.addEventListener(MouseEvent.CLICK, onClose);
         btnok.addEventListener(MouseEvent.CLICK, onOk);
         usenum.registerComponent(mc_usenum);
         usenum.addEventListener(UIComponentEvent.UPDATE, onUpdate);
         usenum.addEventListener(UIComponentEvent.UPPER_LIMIT, onUpperLimit);
         txt_title.text = title;
         txt_name.text = userItem.material ? userItem.material.name : "";
         txt_mycount.text = String(userItem.quantity);
         txt_effect.text = String(this.baseEffect);
         usenum.setLimit(1, Math.max(1, Math.min(Math.ceil(canAddEffect / this.baseEffect), userItem.quantity, 999)));
         RMaterialView.into(RMaterialView.of(IMaterialService(ServiceContainer.getService(IItemService)), userItem.materialId), mc_viewcontainer, 20);
      }

      private function onUpdate(e:UIComponentEvent):void
      {
         txt_effect.text = String(baseEffect * usenum.value);
         txtlimit.visible = false;
      }

      private function onUpperLimit(e:UIComponentEvent):void
      {
         if (usenum.value == userItem.quantity)
         {
            txtlimit.visible = true;
            txtlimit.text = "你已经使用了全部的" + (userItem.material ? userItem.material.name : "道具") + "了。";
         }
         if (ulstring != null && usenum.value * baseEffect >= canAddEffect)
         {
            txtlimit.visible = true;
            txtlimit.text = ulstring;
         }
      }

      private function onOk(e:MouseEvent):void
      {
         var n:int = usenum.value;
         closePanel();
         callback(n);
      }

      private function onClose(e:MouseEvent):void
      {
         closePanel();
      }

      private function closePanel():void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         usenum.removeEventListener(UIComponentEvent.UPDATE, onUpdate);
         usenum.removeEventListener(UIComponentEvent.UPPER_LIMIT, onUpperLimit);
         usenum.dispose();
      }

      public function showPanel():void
      {
         ModalDialogManager.getInstance().addModalDialog(this);
      }
   }
}
