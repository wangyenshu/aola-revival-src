package mmo.houseloader
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
    * REBUILT STUB for HouseLoader. Module house/houseloader.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.IHouseLoader) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HouseLoader extends EventDispatcher implements IHouseLoader
   {
      private var _house:*;
      private var _isMyHouse:Boolean = false;
      private var _houseInfo:*;
      public function HouseLoader()
      {
         super();
      }

      public function get house() : IHouse
      {
         RLog.stub("HouseLoader.house");
         return this._house as IHouse;
      }

      public function loadHouse(param1:String, param2:Boolean = false, param3:int = 0, param4:SceneExtInfo = null) : void
      {
         RLog.stub("HouseLoader.loadHouse");
      }

      public function loadSubHouse(param1:int, param2:String = "default", param3:String = "ld", param4:SceneExtInfo = null) : void
      {
         RLog.stub("HouseLoader.loadSubHouse");
      }

      public function leaveHouse() : void
      {
         RLog.stub("HouseLoader.leaveHouse");
      }

      public function get isMyHouse() : Boolean
      {
         RLog.stub("HouseLoader.isMyHouse");
         return this._isMyHouse;
      }

      public function get houseInfo() : HouseInfo
      {
         RLog.stub("HouseLoader.houseInfo");
         return this._houseInfo as HouseInfo;
      }

   }
}
