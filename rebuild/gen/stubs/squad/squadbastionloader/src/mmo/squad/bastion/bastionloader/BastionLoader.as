package mmo.squad.bastion.bastionloader
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.houseinterfaces.*;
   import mmo.houseinterfaces.IHouseLoader;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.play.scene.SceneExtInfo;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BastionLoader. Module squad/squadbastionloader.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.IHouseLoader) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BastionLoader extends EventDispatcher implements IHouseLoader
   {
      private var _house:*;
      private var _isMyHouse:Boolean = false;
      private var _houseInfo:*;
      public function BastionLoader()
      {
         super();
      }

      public function get house() : IHouse
      {
         RLog.stub("BastionLoader.house");
         return this._house as IHouse;
      }

      public function loadHouse(param1:String, param2:Boolean = false, param3:int = 0, param4:SceneExtInfo = null) : void
      {
         RLog.stub("BastionLoader.loadHouse");
      }

      public function loadSubHouse(param1:int, param2:String = "default", param3:String = "ld", param4:SceneExtInfo = null) : void
      {
         RLog.stub("BastionLoader.loadSubHouse");
      }

      public function leaveHouse() : void
      {
         RLog.stub("BastionLoader.leaveHouse");
      }

      public function get isMyHouse() : Boolean
      {
         RLog.stub("BastionLoader.isMyHouse");
         return this._isMyHouse;
      }

      public function get houseInfo() : HouseInfo
      {
         RLog.stub("BastionLoader.houseInfo");
         return this._houseInfo as HouseInfo;
      }

   }
}
