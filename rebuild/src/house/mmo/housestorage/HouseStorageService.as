package mmo.housestorage
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.decorate.HouseDecoratorEvent;
   import mmo.houseinterfaces.operate.HouseStorageEvent;
   import mmo.houseinterfaces.operate.IHouseStorageService;
   import mmo.interfaces.IService;

   /**
    * REBUILT house/housestorage (ServiceConfig "HouseStorageService"): the
    * storage shown while decorating, with the items not yet placed, by
    * kind (所有 / 家具 / 装饰 / 摆设 / 房型 / 其他). The 2013 code is lost;
    * it is drawn by the later art of house/housestorage. Clicking an item
    * puts it at its usual spot; dragging it out carries it into the room.
    */
   public class HouseStorageService extends EventDispatcher implements IHouseStorageService
   {
      private var house:IHouse;
      private var panel:HouseStorage;

      public function HouseStorageService()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      public function preDecorate(h:IHouse, decorators:Array):void
      {
         house = h;
         if (panel != null) panel.dispose();
         panel = new HouseStorage();
         panel.setUp(h, decorators);
         panel.addEventListener(HouseStorageEvent.onDragMaterial, relay);
         panel.addEventListener(HouseStorageEvent.onChooseMaterial, relay);
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onPreDecorated, {}));
      }

      private function relay(e:HouseStorageEvent):void
      {
         dispatchEvent(e.clone());
      }

      public function decorate():void
      {
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onDecorated, {}));
      }

      public function get storage():Sprite
      {
         return panel;
      }

      public function get enabled():Boolean
      {
         return panel != null && panel.mouseChildren;
      }

      public function set enabled(v:Boolean):void
      {
         if (panel == null) return;
         panel.mouseEnabled = v;
         panel.mouseChildren = v;
      }

      public function get visiable():Boolean
      {
         return panel != null && panel.parent != null && panel.visible;
      }

      public function set visiable(v:Boolean):void
      {
         if (panel == null) return;
         if (v) panel.show();
         else panel.hide();
      }

      public function refresh():void
      {
         if (panel) panel.refresh();
      }

      public function close():void
      {
         if (panel != null)
         {
            panel.removeEventListener(HouseStorageEvent.onDragMaterial, relay);
            panel.removeEventListener(HouseStorageEvent.onChooseMaterial, relay);
            panel.dispose();
         }
         panel = null;
         house = null;
      }
   }
}
