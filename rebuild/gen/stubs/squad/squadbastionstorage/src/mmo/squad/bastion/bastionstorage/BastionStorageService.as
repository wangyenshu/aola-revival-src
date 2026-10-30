package mmo.squad.bastion.bastionstorage
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.operate.*;
   import mmo.houseinterfaces.operate.IHouseStorageService;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BastionStorageService. Module squad/squadbastionstorage.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.operate.IHouseStorageService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BastionStorageService extends EventDispatcher implements IHouseStorageService
   {
      private var _enabled:Boolean = false;
      private var _visiable:Boolean = false;
      private var _storage:*;
      public function BastionStorageService()
      {
         super();
      }

      public function preDecorate(param1:IHouse, param2:Array) : void
      {
         RLog.stub("BastionStorageService.preDecorate");
      }

      public function get enabled() : Boolean
      {
         RLog.stub("BastionStorageService.enabled");
         return this._enabled;
      }

      public function set enabled(param1:Boolean) : void
      {
         this._enabled = param1;
      }

      public function get visiable() : Boolean
      {
         RLog.stub("BastionStorageService.visiable");
         return this._visiable;
      }

      public function set visiable(param1:Boolean) : void
      {
         this._visiable = param1;
      }

      public function close() : void
      {
         RLog.stub("BastionStorageService.close");
      }

      public function refresh() : void
      {
         RLog.stub("BastionStorageService.refresh");
      }

      public function get storage() : Sprite
      {
         RLog.stub("BastionStorageService.storage");
         return this._storage as Sprite;
      }

      public function decorate() : void
      {
         RLog.stub("BastionStorageService.decorate");
      }

   }
}
