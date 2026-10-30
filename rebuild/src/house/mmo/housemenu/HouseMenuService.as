package mmo.housemenu
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.decorate.HouseDecoratorEvent;
   import mmo.houseinterfaces.operate.HouseMenuEvent;
   import mmo.houseinterfaces.operate.IHouseMenuService;
   import mmo.interfaces.IService;

   /**
    * REBUILT house/housemenu (ServiceConfig "HouseMenuService"): the menu
    * in a home (我的家具 to decorate, 保存装扮, 购买手册, 最近访问). The 2013
    * code is lost; the menu is drawn by the later art of house/housemenu
    * (its buttons as named there), driven by this code.
    */
   public class HouseMenuService extends EventDispatcher implements IHouseMenuService
   {
      private var house:IHouse;
      private var houseMenu:HouseMenu;
      private var _editable:Boolean;

      public function HouseMenuService()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      public function preDecorate(h:IHouse):void
      {
         house = h;
         if (houseMenu != null) houseMenu.dispose();
         houseMenu = new HouseMenu();
         houseMenu.setUp(h.loader.houseInfo.owner, int(h.loader.houseInfo.extData.count), _editable);
         for each (var t:String in [HouseMenuEvent.onEdit, HouseMenuEvent.onExitEdit, HouseMenuEvent.onSave, HouseMenuEvent.onOpenStorage])
            houseMenu.addEventListener(t, relay);
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onPreDecorated, {}));
      }

      private function relay(e:HouseMenuEvent):void
      {
         dispatchEvent(e.clone());
      }

      public function set editable(v:Boolean):void
      {
         _editable = v;
         if (houseMenu != null) houseMenu.editable = v;
      }

      public function decorate():void
      {
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onDecorated, {}));
      }

      public function get menu():Sprite
      {
         return houseMenu;
      }

      public function get enabled():Boolean
      {
         return houseMenu != null && houseMenu.mouseChildren;
      }

      public function set enabled(v:Boolean):void
      {
         if (houseMenu == null) return;
         houseMenu.mouseEnabled = v;
         houseMenu.mouseChildren = v;
      }

      public function get visiable():Boolean
      {
         return houseMenu != null && houseMenu.parent != null;
      }

      public function set visiable(v:Boolean):void
      {
         if (houseMenu == null || house == null) return;
         var top:Sprite = Object(house).foreGround as Sprite;
         if (v && top != null) top.addChild(houseMenu);
         else if (!v && houseMenu.parent != null) houseMenu.parent.removeChild(houseMenu);
      }

      public function close():void
      {
         if (houseMenu != null) houseMenu.dispose();
         houseMenu = null;
         house = null;
      }
   }
}
