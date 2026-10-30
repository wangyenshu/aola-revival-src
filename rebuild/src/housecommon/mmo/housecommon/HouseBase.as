package mmo.housecommon
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import mmo.houseinterfaces.HouseEvent;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.IHouseLoader;
   import mmo.houseinterfaces.berth.BerthInfo;
   import mmo.houseinterfaces.berth.BerthTypes;
   import mmo.houseinterfaces.material.HouseItemTypes;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT house/housecommon: the base class of every home SWF
    * (furniture/b<id>, "extends HouseBase"; super(x, y), addHouseEntrances,
    * loader, enterEditMode). The January 2013 module is lost; this is written
    * against the 2013 IHouse and the members the surviving home SWFs use.
    *
    * A home's "houseInside" clip holds the areas furniture may stand on
    * (mcFloor, mcLeft / mcMid / mcRight walls, mcCeiling) and mcOutsideArea,
    * where a dropped item goes back to the storage.
    */
   public class HouseBase extends SceneBase implements IHouse
   {
      /** HouseInfo.GARDENHOUSEID: the 家园 (rebuilt furniture/b000247). The zoo (20000+) is not rebuilt yet. */
      public static const GARDEN_ID:int = 247;

      private static var _currentHouse:HouseBase;

      private var _loader:IHouseLoader;
      private var houseInside:Sprite;
      private var _floor:Sprite;
      private var _leftWall:Sprite;
      private var _midWall:Sprite;
      private var _rightWall:Sprite;
      private var _ceiling:Sprite;
      private var _outsideArea:Sprite;
      private var _berthes:Array = [];
      private var _itemInitPoints:Object = {};
      private var _isEditMode:Boolean;

      public function HouseBase(x:int, y:int)
      {
         _currentHouse = this;
         super(x, y);
         initBerthes();
         initItemPoints();
      }

      public static function get currentHouse():HouseBase
      {
         return _currentHouse;
      }

      private function initBerthes():void
      {
         houseInside = getChildByName("houseInside") as Sprite;
         if (houseInside == null) return;
         // The areas are coloured shapes for hit tests only (in 2013 they sat under the scene).
         houseInside.alpha = 0;
         houseInside.mouseEnabled = false;
         houseInside.mouseChildren = false;
         _floor = houseInside.getChildByName("mcFloor") as Sprite;
         _outsideArea = houseInside.getChildByName("mcOutsideArea") as Sprite;
         _leftWall = houseInside.getChildByName("mcLeft") as Sprite;
         _midWall = houseInside.getChildByName("mcMid") as Sprite;
         _rightWall = houseInside.getChildByName("mcRight") as Sprite;
         _ceiling = houseInside.getChildByName("mcCeiling") as Sprite;
         addBerth(new BerthInfo(BerthTypes.FLOOR, _floor));
         addBerth(new BerthInfo(BerthTypes.OUTSIDE, _outsideArea));
         addBerth(new BerthInfo(BerthTypes.LEFT_WALL, _leftWall));
         addBerth(new BerthInfo(BerthTypes.MID_WALL, _midWall));
         addBerth(new BerthInfo(BerthTypes.RIGHT_WALL, _rightWall));
         addBerth(new BerthInfo(BerthTypes.CEILING, _ceiling));
      }

      /** Where a new item of each kind first appears: the middle of the floor, the back wall, the ceiling. */
      protected function initItemPoints():void
      {
         if (_floor != null)
         {
            _itemInitPoints[HouseItemTypes.FLOOR] = centreOf(_floor);
            _itemInitPoints[HouseItemTypes.NON_LIMITED] = centreOf(_floor);
         }
         if (_midWall != null) _itemInitPoints[HouseItemTypes.WALL_ORNAMENT] = centreOf(_midWall);
         if (_ceiling != null) _itemInitPoints[HouseItemTypes.CEILING_ORNAMENT] = centreOf(_ceiling);
      }

      private function centreOf(d:DisplayObject):Point
      {
         var r:Rectangle = d.getBounds(this);
         return new Point(int(r.x + r.width / 2), int(r.y + r.height / 2));
      }

      public function set loader(v:IHouseLoader):void
      {
         _loader = v;
      }

      public function get loader():IHouseLoader
      {
         return _loader;
      }

      public function get isEditMode():Boolean
      {
         return _isEditMode;
      }

      /**
       * A door to another room of the home (loader.loadSubHouse); the door
       * to the garden comes out in front of 我的家 there. The zoo is not
       * rebuilt yet, so its door leads back outside.
       */
      protected function addHouseEntrances(area:DisplayObject, houseId:int, locationKey:String = "default", button:DisplayObject = null):*
      {
         addEntranceAction(area, function():void
         {
            if (houseId >= 20000 || _loader == null) leaveHome();
            else if (houseId == GARDEN_ID) _loader.loadSubHouse(GARDEN_ID, "fromHouse");
            else _loader.loadSubHouse(houseId, locationKey);
         }, button);
      }

      /** Back to the scene the player came from. */
      protected function leaveHome():void
      {
         var sm:SceneManager = SceneManager.getInstance();
         sm.loadScene(sm.lastOutdoorScene, "default");
      }

      protected function get floor():Sprite { return _floor; }
      protected function get leftWall():Sprite { return _leftWall; }
      protected function get midWall():Sprite { return _midWall; }
      protected function get rightWall():Sprite { return _rightWall; }
      protected function get ceiling():Sprite { return _ceiling; }
      protected function get outsideArea():Sprite { return _outsideArea; }

      public function get berthes():Array
      {
         return _berthes.concat();
      }

      public function addBerth(b:BerthInfo):void
      {
         if (b != null && b.berth != null) _berthes.push(b);
      }

      public function getBerthByType(type:int):BerthInfo
      {
         for each (var b:BerthInfo in _berthes)
         {
            if (b.type == type) return b;
         }
         return null;
      }

      public function removeBerth(b:BerthInfo):Boolean
      {
         var i:int = _berthes.indexOf(b);
         if (i < 0) return false;
         _berthes.splice(i, 1);
         return true;
      }

      protected function setItemInitPoint(type:int, p:Point):void
      {
         _itemInitPoints[type] = p;
      }

      public function getItemInitPoint(type:int):Point
      {
         return _itemInitPoints[type] as Point;
      }

      public function get defaultInitPoint():Point
      {
         var p:Point = _itemInitPoints[HouseItemTypes.FLOOR] as Point;
         return p != null ? p : new Point(480, 380);
      }

      public function berthable(type:int):Boolean
      {
         return type == HouseItemTypes.HOUSE_BACKGROUND || _itemInitPoints.hasOwnProperty(type);
      }

      /** Decorating: players are hidden and stand still, doors stop working. */
      public function enterEditMode():void
      {
         setEditMode(true);
      }

      public function exitEditMode():void
      {
         setEditMode(false);
      }

      private function setEditMode(v:Boolean):void
      {
         _isEditMode = v;
         var pm:PlayerManager = PlayerManager.getInstance();
         for each (var p:PlayerBase in pm.playerList) p.visible = !v;
         var me:PlayerBase = pm.myPlayer;
         if (me != null)
         {
            me.stop();
            me.setStrategy(v ? null : new MouseControlStrategy());
         }
         setWalkTargetsEnabled(!v);
      }

      override protected function onLeaveRoom():void
      {
         dispatchEvent(new HouseEvent(HouseEvent.onLeaveRoom));
         super.onLeaveRoom();
      }

      public function dispose():void
      {
         if (_currentHouse == this) _currentHouse = null;
         _loader = null;
         _berthes = [];
         houseInside = _floor = _leftWall = _midWall = _rightWall = _ceiling = _outsideArea = null;
      }
   }
}
