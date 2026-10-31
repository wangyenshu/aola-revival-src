package mmo.housemenu
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.houseinterfaces.operate.HouseMenuEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RNotice;

   /**
    * REBUILT. The home menu, bound to the menu symbol of the later
    * house/housemenu art; the public names are those of the art's buttons.
    */
   public class HouseMenu extends Sprite
   {
      public var btnCatalog:BtnCatalog;
      public var btnEdit:SimpleButton;
      public var btnPackage:SimpleButton;
      public var btnPetWarehouse:SimpleButton;
      public var btnSave:SimpleButton;
      public var btnVisitors:SimpleButton;
      public var container:MovieClip;
      public var mcVisitors:MovieClip;
      public var visitorTxtCount:MovieClip;

      private var _editable:Boolean;
      private var editing:Boolean;
      private var visitorCount:int;

      public function HouseMenu()
      {
         super();
      }

      public function setUp(owner:String, visitors:int, editable:Boolean):void
      {
         _editable = editable;
         visitorCount = visitors;
         if (mcVisitors) mcVisitors.stop();
         var amount:TextField = visitorTxtCount ? visitorTxtCount.getChildByName("amount") as TextField : null;
         if (amount) amount.text = String(visitors);
         // The 亚比 buttons belong to the zoo.
         if (btnPackage) btnPackage.visible = false;
         if (btnPetWarehouse) btnPetWarehouse.visible = false;
         tips(btnVisitors, "最近访问");
         tips(btnSave, "保存装扮");
         tips(btnEdit, "我的家具");
         if (btnCatalog && btnCatalog.btnAll) tips(btnCatalog.btnAll, "购买手册");
         show(false);
         addEventListener(MouseEvent.CLICK, onClick);
      }

      private static function tips(d:DisplayObject, s:String):void
      {
         if (d == null) return;
         try { TipsManager.getInstance().addTips(d as InteractiveObject, s); } catch (e:Error) {}
      }

      public function set editable(v:Boolean):void
      {
         _editable = v;
         show(editing);
      }

      private function show(edit:Boolean):void
      {
         editing = edit;
         if (btnSave) btnSave.visible = edit;
         if (btnCatalog) btnCatalog.visible = edit;
         if (btnEdit) btnEdit.visible = !edit && _editable;
         // 足迹: the moving footprints (mcVisitors) stand over the button when
         // someone has called since; with nobody, the button alone (both at
         // once drew two footprints over each other).
         if (mcVisitors) mcVisitors.visible = !edit && visitorCount > 0;
         if (btnVisitors) btnVisitors.visible = !edit;
         if (visitorTxtCount) visitorTxtCount.visible = !edit;
      }

      private function onClick(e:MouseEvent):void
      {
         var name:String = DisplayObject(e.target).name;
         switch (name)
         {
            case "btnEdit":
               e.stopImmediatePropagation();
               show(true);
               dispatchEvent(new HouseMenuEvent(HouseMenuEvent.onEdit));
               break;
            case "btnSave":
               e.stopImmediatePropagation();
               show(false);
               dispatchEvent(new HouseMenuEvent(HouseMenuEvent.onSave));
               break;
            case "btnVisitors":
            case "mcVisitors":
               RNotice.show(LayerManager.getBaseTop(), "最近访问还在修复中哦！");
               break;
         }
      }

      public function dispose():void
      {
         removeEventListener(MouseEvent.CLICK, onClick);
         if (btnCatalog) btnCatalog.dispose();
         if (parent) parent.removeChild(this);
      }
   }
}
