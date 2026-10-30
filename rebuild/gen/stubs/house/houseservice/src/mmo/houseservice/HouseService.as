package mmo.houseservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.houseinterfaces.*;
   import mmo.houseinterfaces.IHouseService;
   import mmo.houseinterfaces.decorate.IFurnitureDecorator;
   import mmo.houseinterfaces.operate.IHouseMenuService;
   import mmo.houseinterfaces.operate.IHouseStorageService;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HouseService. Module house/houseservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.IHouseService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HouseService extends EventDispatcher implements IHouseService
   {
      private var _house:*;
      private var _inHouse:Boolean = false;
      private var _houseLoader:*;
      private var _isMyHouse:Boolean = false;
      private var _furniturDecorators:*;
      private var _isEditing:Boolean = false;
      private var _decorators:*;
      private var _storage:*;
      private var _owner:String;
      private var _menu:*;
      public function HouseService()
      {
         super();
      }

      public function get house() : IHouse
      {
         RLog.stub("HouseService.house");
         return this._house as IHouse;
      }

      public function get inHouse() : Boolean
      {
         RLog.stub("HouseService.inHouse");
         return this._inHouse;
      }

      public function set houseLoader(param1:IHouseLoader) : void
      {
         this._houseLoader = param1;
      }

      public function get isMyHouse() : Boolean
      {
         RLog.stub("HouseService.isMyHouse");
         return this._isMyHouse;
      }

      public function get furniturDecorators() : IFurnitureDecorator
      {
         RLog.stub("HouseService.furniturDecorators");
         return this._furniturDecorators as IFurnitureDecorator;
      }

      public function decorate() : void
      {
         RLog.stub("HouseService.decorate");
      }

      public function get isEditing() : Boolean
      {
         RLog.stub("HouseService.isEditing");
         return this._isEditing;
      }

      public function set decorators(param1:Array) : void
      {
         this._decorators = param1;
      }

      public function get houseLoader() : IHouseLoader
      {
         RLog.stub("HouseService.houseLoader");
         return this._houseLoader as IHouseLoader;
      }

      public function set storage(param1:IHouseStorageService) : void
      {
         this._storage = param1;
      }

      public function preDecorate() : void
      {
         RLog.stub("HouseService.preDecorate");
      }

      public function get decorators() : Array
      {
         RLog.stub("HouseService.decorators");
         return this._decorators as Array;
      }

      public function get owner() : String
      {
         RLog.stub("HouseService.owner");
         return this._owner;
      }

      public function get storage() : IHouseStorageService
      {
         RLog.stub("HouseService.storage");
         return this._storage as IHouseStorageService;
      }

      public function set menu(param1:IHouseMenuService) : void
      {
         this._menu = param1;
      }

      public function get menu() : IHouseMenuService
      {
         RLog.stub("HouseService.menu");
         return this._menu as IHouseMenuService;
      }

      public function init() : void
      {
         RLog.stub("HouseService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
