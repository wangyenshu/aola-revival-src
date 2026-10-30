package mmo.play.player.sceneplayer
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.MovableEvent;
   import mmo.play.player.movable.strategy.IMovingStrategy;
   import mmo.play.player.sceneplayer.observer.IPlayerObserver;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT. Base of everything that stands and walks in a scene, keyed by
    * user name (PlayerManager.playerList[userName]). Movement as the 2013
    * code drives it: walkTo (stops at the scene's obstruction layer), moveTo
    * (straight), jumpTo, stop, with MovableEvent notifications; observers
    * (IPlayerObserver) and a moving strategy (IMovingStrategy) attach here.
    */
   public class PlayerBase extends Sprite
   {
      public static const WALK_SPEED:int = 5;
      /** 8 directions, clockwise from up; the codes are the avatar sheet's. */
      public static const DIRECTIONS:Array = ["uu", "ru", "rr", "rd", "dd", "ld", "ll", "lu"];

      private var _userName:String;
      private var _observers:Array = [];
      private var _strategy:IMovingStrategy;
      private var _properties:Object = {};
      private var _walkSpeed:int = WALK_SPEED;
      private var _destX:Number = 0;
      private var _destY:Number = 0;
      private var _speed:Number = WALK_SPEED;
      private var _moving:Boolean;
      private var _direction:int = 5;
      private var _movable:Boolean = true;
      private var _disposed:Boolean;

      public function PlayerBase(userName:String)
      {
         super();
         _userName = userName;
         name = userName;
      }

      public function getName():String
      {
         return _userName;
      }

      public function isMovable():Boolean
      {
         return _movable;
      }

      public function setMovable(v:Boolean):void
      {
         _movable = v;
      }

      public function getProperty(key:String):Object
      {
         return _properties[key];
      }

      public function setProperty(key:String, value:Object):void
      {
         _properties[key] = value;
      }

      public function delProperty(key:String):void
      {
         delete _properties[key];
      }

      // ───── observers and strategy ─────

      public function registerObserver(o:IPlayerObserver):void
      {
         if (o == null) return;
         removeObserver(o.getName());
         _observers.push(o);
         for each (var type:String in o.getEventList())
         {
            addEventListener(type, o.onPlayerEvent, false, o.getPriority());
         }
      }

      public function removeObserver(name:String):void
      {
         for (var i:int = _observers.length - 1; i >= 0; i--)
         {
            var o:IPlayerObserver = _observers[i];
            if (o.getName() != name) continue;
            for each (var type:String in o.getEventList())
            {
               removeEventListener(type, o.onPlayerEvent);
            }
            o.dispose();
            _observers.splice(i, 1);
         }
      }

      public function getObserver(name:String):IPlayerObserver
      {
         for each (var o:IPlayerObserver in _observers)
         {
            if (o.getName() == name) return o;
         }
         return null;
      }

      public function setStrategy(s:IMovingStrategy):void
      {
         if (_strategy != null) _strategy.dispose();
         _strategy = s;
         if (s != null) s.setControlItem(this as IMovable);
      }

      // ───── movement ─────

      public function get walkSpeed():int
      {
         return _walkSpeed;
      }

      public function set walkSpeed(v:int):void
      {
         _walkSpeed = v > 0 ? v : WALK_SPEED;
      }

      public function get direction():int
      {
         return _direction;
      }

      public function get directionCode():String
      {
         return DIRECTIONS[_direction];
      }

      public function get destX():int
      {
         return int(_moving ? _destX : x);
      }

      public function get destY():int
      {
         return int(_moving ? _destY : y);
      }

      /** Later scenes read where a player stands as currentX / currentY. */
      final public function get currentX():int
      {
         return int(x);
      }

      final public function get currentY():int
      {
         return int(y);
      }

      public function get targetSymbol():Sprite
      {
         return this;
      }

      public function isMoving():Boolean
      {
         return _moving;
      }

      /** Walk towards (x, y), stopping where the scene's obstruction begins. */
      public function walkTo(x:int, y:int):Object
      {
         var p:Point = new Point(x, y);
         var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (info != null && info.scene != null && parent == info.scene.playerLayer)
         {
            p = info.scene.lastFreePoint(this.x, this.y, x, y);
         }
         return moveTo(int(p.x), int(p.y));
      }

      public function moveTo(x:int, y:int, speed:int = -1):Object
      {
         if (_disposed) return null;
         var dx:Number = x - this.x;
         var dy:Number = y - this.y;
         if (dx * dx + dy * dy < 4)
         {
            if (_moving) stop();
            return null;
         }
         _destX = x;
         _destY = y;
         _speed = speed > 0 ? speed : _walkSpeed;
         _direction = directionOf(dx, dy);
         var wasMoving:Boolean = _moving;
         _moving = true;
         if (!wasMoving) addEventListener(Event.ENTER_FRAME, step);
         onMoveStateChanged();
         var params:Object = {x: x, y: y, speed: int(_speed)};
         dispatchEvent(new MovableEvent(MovableEvent.MOVE_BEGIN, params));
         return params;
      }

      public function jumpTo(x:int, y:int):Object
      {
         halt();
         this.x = x;
         this.y = y;
         _destX = x;
         _destY = y;
         onMoveStateChanged();
         var params:Object = {x: x, y: y};
         dispatchEvent(new MovableEvent(MovableEvent.JUMPED, params));
         return params;
      }

      public function stop():Object
      {
         var was:Boolean = _moving;
         halt();
         if (was) onMoveStateChanged();
         return {x: int(x), y: int(y)};
      }

      /** Turn to a direction code ("ld", "rd", …) without moving. */
      public function face(code:String):void
      {
         var i:int = DIRECTIONS.indexOf(code);
         if (i < 0) return;
         _direction = i;
         onMoveStateChanged();
      }

      private function halt():void
      {
         if (!_moving) return;
         _moving = false;
         removeEventListener(Event.ENTER_FRAME, step);
      }

      private function step(e:Event):void
      {
         var dx:Number = _destX - x;
         var dy:Number = _destY - y;
         var dist:Number = Math.sqrt(dx * dx + dy * dy);
         if (dist <= _speed)
         {
            x = _destX;
            y = _destY;
            halt();
            onMoveStateChanged();
            dispatchEvent(new MovableEvent(MovableEvent.ARRIVED, {x: int(x), y: int(y)}));
            return;
         }
         x += dx / dist * _speed;
         y += dy / dist * _speed;
      }

      /** Subclasses update the avatar here (walking or standing, facing direction). */
      protected function onMoveStateChanged():void
      {
      }

      public static function directionOf(dx:Number, dy:Number):int
      {
         var a:Number = Math.atan2(dy, dx) * 180 / Math.PI; // 0 = right, 90 = down
         var i:int = Math.round((a + 90) / 45);
         return ((i % 8) + 8) % 8;
      }

      public function get isDisposed():Boolean
      {
         return _disposed;
      }

      public function dispose():void
      {
         if (_disposed) return;
         _disposed = true;
         halt();
         setStrategy(null);
         while (_observers.length > 0) removeObserver(IPlayerObserver(_observers[0]).getName());
         if (parent) parent.removeChild(this);
      }
   }
}
