package mmo.play.scene
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.play.player.movable.MovableEvent;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.helper.player.IPlayerGenerator;
   import mmo.revival.RLog;

   /**
    * REBUILT. Base class of every scene, written to the API the surviving
    * 2012/13 scenes use (see tools/engine_census.py): super(x, y),
    * addInitLocation, addEntrances, addWalkTarget, cacheLayer; the hooks they
    * override with these exact signatures: onJoinRoom(), onLeaveRoom(),
    * cacheSceneLayers(), onUserEnterRoom(PlayerManagerEvent),
    * getPlayerGenerator():IPlayerGenerator, arridable(Number, Number):Boolean;
    * and setMapArray() / addCommand(...) they call.
    *
    * My player is moved by its MouseControlStrategy; the scene only answers
    * where it may go (obstruction layer, arridable) and handles entrances.
    */
   public class SceneBase extends AbstractScene
   {
      private var _defaultLocation:Point;
      private var _initPoints:Object = {};
      private var _entrances:Array = [];
      /** Inside the walkTo of a walk-target click (onMoveBegin takes its end point). */
      private var _ownWalk:Boolean = false;
      private var _walkTargets:Array = [];
      private var _pendingEntrance:Object;
      private var _pendingPoint:Point;
      private var _sceneWidth:int = 960;
      private var _sceneHeight:int = 560;
      private var _entered:Boolean;
      private var _commands:Array = [];

      public function SceneBase(x:int, y:int)
      {
         super();
         _defaultLocation = new Point(x, y);
         addInitLocation("default", _defaultLocation);
      }

      // ───── API used by scene subclasses ─────

      protected function addInitLocation(key:String, point:Point):void
      {
         _initPoints[key] = point;
      }

      protected function addEntrances(area:DisplayObject, sceneName:String, locationKey:String = "default", button:DisplayObject = null, face:String = "ld"):void
      {
         if (area == null)
         {
            RLog.log("scene: entrance to " + sceneName + " has no hotspot");
            return;
         }
         var clickable:DisplayObject = button != null ? button : area;
         if (clickable is Sprite) Sprite(clickable).buttonMode = true;
         if (button != null)
         {
            area.visible = false;
         }
         else
         {
            area.visible = true;
            area.alpha = 0;
         }
         _entrances.push({area: area, scene: sceneName, key: locationKey, face: face});
         addWalkTarget(clickable, area);
      }

      /**
       * An entrance that runs action() once my player has walked into it
       * instead of loading a scene (the doors between a home's rooms:
       * HouseBase.addHouseEntrances).
       */
      protected function addEntranceAction(area:DisplayObject, action:Function, button:DisplayObject = null):void
      {
         if (area == null) return;
         var clickable:DisplayObject = button != null ? button : area;
         if (clickable is Sprite) Sprite(clickable).buttonMode = true;
         if (button != null) area.visible = false;
         else
         {
            area.visible = true;
            area.alpha = 0;
         }
         _entrances.push({area: area, action: action});
         addWalkTarget(clickable, area);
      }

      /** Switch every walk target and entrance on or off (a home being decorated). */
      protected function setWalkTargetsEnabled(v:Boolean):void
      {
         for each (var w:Object in _walkTargets)
         {
            var io:InteractiveObject = w.clickable as InteractiveObject;
            if (io == null) continue;
            io.mouseEnabled = v;
            if (io is DisplayObjectContainer) DisplayObjectContainer(io).mouseChildren = v;
         }
      }

      protected function addWalkTarget(clickable:DisplayObject, target:DisplayObject = null):void
      {
         if (clickable == null) return;
         _walkTargets.push({clickable: clickable, target: target || clickable});
         if (clickable is InteractiveObject)
         {
            InteractiveObject(clickable).addEventListener(MouseEvent.CLICK, onWalkTargetClick);
         }
      }

      /** Later scenes' click shortcut: a tooltip and a click handler. */
      final protected function initClick(target:InteractiveObject, tips:String, handler:Function):void
      {
         if (target == null) return;
         if (tips != null && tips != "")
         {
            try { TipsManager.getInstance().addTips(target, tips); } catch (e:Error) {}
         }
         target.addEventListener(MouseEvent.CLICK, handler);
      }

      final protected function initClickByParent(parent:DisplayObjectContainer, name:String, tips:String, handler:Function):void
      {
         initClick(parent ? parent.getChildByName(name) as InteractiveObject : null, tips, handler);
      }

      protected function cacheSceneLayers():void
      {
      }

      protected function onJoinRoom():void
      {
      }

      protected function onLeaveRoom():void
      {
      }

      /** Another player came into the room. */
      protected function onUserEnterRoom(e:PlayerManagerEvent):void
      {
      }

      /** Scenes with their own kind of player (the arenas) return a generator. */
      public function getPlayerGenerator():IPlayerGenerator
      {
         return null;
      }

      /** May my player walk to this stage point? (volcano refuses its VIP pool to non-members.) */
      public function arridable(stageX:Number, stageY:Number):Boolean
      {
         return true;
      }

      /** The 2013 path finder's grid; the rebuilt engine walks straight and stops at the obstruction. */
      public function setMapArray():void
      {
      }

      /** Steps run around scene changes (SceneCommandStep); kept, not yet run by the rebuilt engine. */
      public function addCommand(command:*, step:String):void
      {
         _commands.push({command: command, step: step});
      }

      /**
       * The 2013 vision service (scene lighting) is not rebuilt. Big and
       * instance scenes call these on entry; the 2013 bytecode calls them in
       * the public namespace.
       */
      public function startVisionService():void
      {
      }

      public function stopVisionService():void
      {
      }

      public function getDefaultLocation():Point
      {
         return _defaultLocation;
      }

      public function getSceneWidth():int
      {
         return _sceneWidth;
      }

      public function getSceneHeight():int
      {
         return _sceneHeight;
      }

      /** Stage point -> player layer (scene) coordinates. */
      public function localPointToScene(stagePoint:Point):Point
      {
         return playerLayer.globalToLocal(stagePoint);
      }

      /** Last point on the straight line from (x0, y0) to (x1, y1) before the obstruction layer. */
      public function lastFreePoint(x0:Number, y0:Number, x1:Number, y1:Number):Point
      {
         if (obStruction == null) return new Point(x1, y1);
         var free:Point = new Point(x0, y0);
         var dist:Number = Point.distance(free, new Point(x1, y1));
         var steps:int = Math.max(1, Math.ceil(dist / 6));
         // A player standing on the obstruction (placed there by a scene) may walk out of it.
         var inside:Boolean = isBlocked(x0, y0);
         for (var i:int = 1; i <= steps; i++)
         {
            var px:Number = x0 + (x1 - x0) * i / steps;
            var py:Number = y0 + (y1 - y0) * i / steps;
            if (isBlocked(px, py))
            {
               if (!inside) break;
               continue;
            }
            inside = false;
            free = new Point(px, py);
         }
         return free;
      }

      private var _pathGrid:PathGrid;

      /**
       * The way from (x0, y0) to (x1, y1) round the obstruction: waypoints,
       * the last the destination (or the free point nearest it); null when
       * there is none (or no obstruction). The grid is made on the first walk
       * in the scene and made again when the obstruction has changed under a
       * way found on it.
       */
      public function findPath(x0:Number, y0:Number, x1:Number, y1:Number):Array
      {
         if (obStruction == null) return null;
         for (var attempt:int = 0; attempt < 2; attempt++)
         {
            if (_pathGrid == null) _pathGrid = new PathGrid(_sceneWidth, _sceneHeight, isBlocked);
            var path:Array = _pathGrid.find(x0, y0, x1, y1);
            if (path == null || attempt == 1 || stillFree(x0, y0, path)) return path;
            _pathGrid = null;
         }
         return null;
      }

      /** Does each leg of the way still miss the obstruction as it is now? */
      private function stillFree(x0:Number, y0:Number, path:Array):Boolean
      {
         var px:Number = x0, py:Number = y0;
         var startInside:Boolean = isBlocked(x0, y0);
         for each (var p:Point in path)
         {
            var dist:Number = Point.distance(new Point(px, py), p);
            var steps:int = Math.max(1, Math.ceil(dist / 8));
            for (var i:int = 1; i <= steps; i++)
            {
               var blocked:Boolean = isBlocked(px + (p.x - px) * i / steps, py + (p.y - py) * i / steps);
               if (blocked && !startInside) return false;
               if (!blocked) startInside = false;
            }
            px = p.x;
            py = p.y;
         }
         return true;
      }

      /** Is this scene point on the obstruction layer? */
      public function isBlocked(x:Number, y:Number):Boolean
      {
         if (obStruction == null) return false;
         var g:Point = playerLayer.localToGlobal(new Point(x, y));
         return obStruction.hitTestPoint(g.x, g.y, true);
      }

      /** True when a mouse event belongs to one of this scene's walk targets or entrances. */
      public function isWalkTargetEvent(e:MouseEvent):Boolean
      {
         var d:DisplayObject = e.target as DisplayObject;
         while (d != null && d != this)
         {
            for each (var w:Object in _walkTargets)
            {
               if (w.clickable == d) return true;
            }
            d = d.parent;
         }
         return false;
      }

      // ───── driven by SceneManager ─────

      revival function get measuresOwnWidth():Boolean
      {
         return false;
      }

      internal function locationFor(key:String):Point
      {
         var p:Point = key ? _initPoints[key] as Point : null;
         return p || _defaultLocation;
      }

      internal function enter(width:int, height:int):void
      {
         if (width <= 960 && revival::measuresOwnWidth && backGround != null)
         {
            width = Math.floor(backGround.getBounds(this).right);
         }
         else if (width > 960 && backGround != null)
         {
            // config.xml's width can exceed the art (服装店: 1475 vs its background): never scroll past the art.
            var artRight:int = Math.floor(backGround.getBounds(this).right);
            if (artRight > 960 && artRight < width) width = artRight;
         }
         _sceneWidth = Math.max(width, 960);
         _sceneHeight = Math.max(height, 560);
         arrangeLayers();
         if (obStruction) obStruction.alpha = 0;
         cacheSceneLayers();
         addEventListener(Event.ENTER_FRAME, onFrame);
         PlayerManager.getInstance().addEventListener(PlayerManagerEvent.ENTER_ROOM, onPlayerEnter);
         onJoinRoom();
         _entered = true;
         follow();
      }

      internal function leave():void
      {
         if (!_entered) return;
         _entered = false;
         cancelPending();
         removeEventListener(Event.ENTER_FRAME, onFrame);
         PlayerManager.getInstance().removeEventListener(PlayerManagerEvent.ENTER_ROOM, onPlayerEnter);
         for each (var w:Object in _walkTargets)
         {
            if (w.clickable is InteractiveObject) InteractiveObject(w.clickable).removeEventListener(MouseEvent.CLICK, onWalkTargetClick);
         }
         onLeaveRoom();
         // The 2013 SceneBase had no dispose(): scenes that need one declare their own (homes: IDispose).
         if (this is IDispose) IDispose(this).dispose();
      }

      /**
       * Scene art is authored with the layers at any depth (starlandcopy has
       * background above overlap); players live in overlap, so stack the
       * layers bottom-up: obstruction (invisible), background, overlap,
       * foreground, topground.
       */
      private function arrangeLayers():void
      {
         var order:Array = [obStruction, backGround, container, foreGround, topGround];
         var at:int = 0;
         for each (var layer:DisplayObject in order)
         {
            if (layer == null || layer.parent != this) continue;
            setChildIndex(layer, at++);
            // A layer is never a click target itself (what it holds still is):
            // art its author made click-through (mouseEnabled = false, as the
            // counter of 道具店 copy over 米娜) then lets the click reach what
            // lies below, NPCs and players included, instead of stopping at the
            // layer; a click on plain art still walks (the scene takes it).
            if (layer is InteractiveObject && layer != obStruction) InteractiveObject(layer).mouseEnabled = false;
         }
      }

      private function onPlayerEnter(e:PlayerManagerEvent):void
      {
         if (e.player != PlayerManager.getInstance().myPlayer) onUserEnterRoom(e);
      }

      // ───── walk targets and entrances ─────

      private function get me():PlayerBase
      {
         return PlayerManager.getInstance().myPlayer;
      }

      private function centreOf(d:DisplayObject):Point
      {
         var b:Rectangle = d.getBounds(d);
         return localPointToScene(d.localToGlobal(new Point(b.x + b.width / 2, b.y + b.height / 2)));
      }

      private function onWalkTargetClick(e:MouseEvent):void
      {
         if (me == null || SceneManager.getInstance().isSuspend) return;
         for each (var w:Object in _walkTargets)
         {
            if (w.clickable != e.currentTarget) continue;
            var c:Point = centreOf(w.target as DisplayObject);
            cancelPending();
            _pendingEntrance = entranceFor(w.target as DisplayObject);
            _pendingPoint = new Point(int(c.x), int(c.y));
            me.addEventListener(MovableEvent.ARRIVED, onArrived);
            me.addEventListener(MovableEvent.MOVE_BEGIN, onMoveBegin);
            // The walk this click starts may end short of the centre (a door
            // drawn over the obstruction: the nearest walkable point instead).
            _ownWalk = true;
            var path:* = me.walkTo(_pendingPoint.x, _pendingPoint.y);
            _ownWalk = false;
            if (path == null) onArrived(null);
            return;
         }
      }

      private function entranceFor(area:DisplayObject):Object
      {
         for each (var en:Object in _entrances)
         {
            if (en.area == area) return en;
         }
         return null;
      }

      /** A later click elsewhere cancels the pending entrance. */
      private function onMoveBegin(e:MovableEvent):void
      {
         if (_pendingPoint == null) return;
         if (_ownWalk)
         {
            _pendingPoint = new Point(int(e.params.x), int(e.params.y));
            return;
         }
         if (Math.abs(e.params.x - _pendingPoint.x) > 2 || Math.abs(e.params.y - _pendingPoint.y) > 2) cancelPending();
      }

      private function cancelPending():void
      {
         _pendingEntrance = null;
         _pendingPoint = null;
         if (me)
         {
            me.removeEventListener(MovableEvent.ARRIVED, onArrived);
            me.removeEventListener(MovableEvent.MOVE_BEGIN, onMoveBegin);
         }
      }

      private function onArrived(e:Event):void
      {
         var en:Object = _pendingEntrance;
         cancelPending();
         if (en == null) return;
         if (en.action is Function) en.action();
         else SceneManager.getInstance().loadScene(en.scene, en.key);
      }

      private function onFrame(e:Event):void
      {
         follow();
         PlayerManager.getInstance().sortDepths();
      }

      /** Horizontal camera for scenes wider than the 960 px stage. */
      private function follow():void
      {
         if (me == null || _sceneWidth <= 960) return;
         var tx:Number = 480 - me.x;
         x = Math.round(Math.max(960 - _sceneWidth, Math.min(0, tx)));
      }
   }
}
