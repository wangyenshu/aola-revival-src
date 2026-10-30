package mmo.houseloader
{
   import flash.events.EventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.house.HouseClient;
   import mmo.houseinterfaces.HouseInfo;
   import mmo.houseinterfaces.HouseServiceEvent;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.IHouseLoader;
   import mmo.houseinterfaces.IHouseService;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT house/houseloader (ServiceConfig "HouseLoader", injected into
    * HouseService as houseLoader): takes a player into a home. The 2013
    * module is lost; written against the 2013 IHouseLoader and HouseClient:
    * 62_1 {un} answers {un, hid, nn, count} (the owner's main house id, nick
    * name and visitor count), then the house SWF furniture/b<hid> is loaded
    * as the scene "home" in the room "<owner>_<hid>_Home".
    *
    * In 2013 loadHouse() opened the garden (b000247) first; the garden is not
    * rebuilt yet, so it goes straight into the main house.
    */
   public class HouseLoader extends EventDispatcher implements IHouseLoader
   {
      private var _houseInfo:HouseInfo;
      private var _sceneInfo:SceneInfo;
      private var loading:Boolean;
      private var pendingKey:String = "default";

      public function HouseLoader()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      public function get houseInfo():HouseInfo
      {
         return _houseInfo ? _houseInfo.clone() : null;
      }

      public function get house():IHouse
      {
         return _sceneInfo ? _sceneInfo.scene as IHouse : null;
      }

      public function get isMyHouse():Boolean
      {
         return _houseInfo != null && _houseInfo.owner == SocketClient.instance.myUserName;
      }

      public function loadHouse(owner:String, reset:Boolean = false, loadType:int = 0, ext:SceneExtInfo = null):void
      {
         var loaded:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (loading || owner == null) return;
         if (!reset && loaded != null && loaded.inHouse && _houseInfo != null && _houseInfo.owner == owner) return;
         loading = true;
         var sc:SocketClient = SocketClient.instance;
         var onInfo:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(HouseClient.onGetUserHouseInfo, onInfo);
            loading = false;
            var p:Object = e.params;
            if (p.hid == undefined || int(p.hid) <= 0)
            {
               RLog.log("house: no house for " + owner);
               return;
            }
            _houseInfo = new HouseInfo(p.un || owner, int(p.hid), p.nn || owner);
            _houseInfo.extData = {count: int(p.count)};
            loadSubHouse(_houseInfo.mainHouseId, "default", "ld", ext);
         };
         sc.addEventListener(HouseClient.onGetUserHouseInfo, onInfo);
         HouseClient.instance.getUserHouseInfo(owner);
      }

      /** Enter another room of the home being visited (-1: its main house). */
      public function loadSubHouse(houseId:int, locationKey:String = "default", face:String = "ld", ext:SceneExtInfo = null):void
      {
         if (_houseInfo == null) return;
         if (houseId == -1) houseId = _houseInfo.mainHouseId;
         _houseInfo.currentHouseId = houseId;
         _houseInfo.roomName = _houseInfo.owner + "_" + houseId + "_Home";
         var info:SceneInfo = new SceneInfo("home", _houseInfo.roomName, houseSwf(houseId));
         info.locationKey = locationKey || "default";
         info.inHouse = true;
         info.inMyHouse = isMyHouse;
         info.sceneDesc = _houseInfo.desc;
         info.faceDirection = face;
         info.extInfo = ext;
         var self:HouseLoader = this;
         SceneManager.getInstance().loadSceneWith(info, {
            desc: "正在进入" + _houseInfo.desc + "的家……",
            prepare: function(built:SceneInfo, go:Function):void
            {
               _sceneInfo = built;
               var hs:IHouseService = houseService();
               if (hs == null)
               {
                  go();
                  return;
               }
               var ready:Function = function(e:HouseServiceEvent):void
               {
                  hs.removeEventListener(HouseServiceEvent.onPreDecorated, ready);
                  go();
               };
               hs.addEventListener(HouseServiceEvent.onPreDecorated, ready);
               hs.preDecorate();
            },
            entered: function(shown:SceneInfo):void
            {
               var hs:IHouseService = houseService();
               if (hs != null) hs.decorate();
            }
         });
      }

      private function houseService():IHouseService
      {
         try
         {
            return ServiceContainer.getService("HouseService") as IHouseService;
         }
         catch (err:Error)
         {
            RLog.error("house: HouseService", err);
         }
         return null;
      }

      private static function houseSwf(id:int):String
      {
         var s:String = String(id);
         while (s.length < 6) s = "0" + s;
         return "furniture/b" + s;
      }

      public function leaveHouse():void
      {
         _sceneInfo = null;
      }
   }
}
