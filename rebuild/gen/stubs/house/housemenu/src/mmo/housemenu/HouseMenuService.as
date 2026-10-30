package mmo.housemenu
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.operate.*;
   import mmo.houseinterfaces.operate.IHouseMenuService;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HouseMenuService. Module house/housemenu.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.operate.IHouseMenuService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HouseMenuService extends EventDispatcher implements IHouseMenuService
   {
      private var _enabled:Boolean = false;
      private var _visiable:Boolean = false;
      private var _editable:*;
      private var _menu:*;
      public function HouseMenuService()
      {
         super();
      }

      public function preDecorate(param1:IHouse) : void
      {
         RLog.stub("HouseMenuService.preDecorate");
      }

      public function get enabled() : Boolean
      {
         RLog.stub("HouseMenuService.enabled");
         return this._enabled;
      }

      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
      }

      public function get visiable() : Boolean
      {
         RLog.stub("HouseMenuService.visiable");
         return this._visiable;
      }

      public function set visiable(param1:Boolean) : void
      {
         this._visiable = param1;
      }

      public function close() : void
      {
         RLog.stub("HouseMenuService.close");
      }

      public function set editable(param1:Boolean) : void
      {
         this._editable = param1;
      }

      public function decorate() : void
      {
         RLog.stub("HouseMenuService.decorate");
      }

      public function get menu() : Sprite
      {
         RLog.stub("HouseMenuService.menu");
         return this._menu as Sprite;
      }

   }
}
