package mmo.play.player.movable.strategy
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.MovableEvent;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT. A follower that trails its leader slowly (the following 亚比):
    * it heads for a point behind the leader's destination, 30 px across and
    * 60 px along the leader's walking line, at 2/3 of the leader's speed, and
    * only sets off once it is more than 40 px from where it should be. These
    * numbers are those of the later FollowSlowlyStrategy of the same name; the
    * code is written against the rebuilt engine's IMovable (no path finder).
    */
   public class FollowSlowlyStrategy extends AbstractMovingStrategy implements IMovingStrategy
   {
      private var _target:IMovable;
      private var _dest:Point;

      public function FollowSlowlyStrategy(target:IMovable)
      {
         super();
         _target = target;
      }

      override public function setControlItem(item:IMovable):void
      {
         super.setControlItem(item);
         if (item == null || _target == null) return;
         _target.addEventListener(MovableEvent.MOVE_BEGIN, onTargetMoved, false, 0, true);
         _target.addEventListener(MovableEvent.ARRIVED, onTargetMoved, false, 0, true);
         _target.addEventListener(MovableEvent.JUMPED, onTargetJumped, false, 0, true);
         _target.addEventListener(Event.REMOVED_FROM_STAGE, onTargetRemoved, false, 0, true);
         item.addEventListener(MovableEvent.ARRIVED, onArrived, false, 0, true);
         _dest = new Point(_target.x + 30, _target.y - 10);
         item.jumpTo(_dest.x, _dest.y);
      }

      private function onTargetMoved(e:Event):void
      {
         var tx:Number = _target.destX, ty:Number = _target.destY;
         var dx:Number = _target.x - tx, dy:Number = _target.y - ty;
         var d:Number = Math.sqrt(dx * dx + dy * dy);
         if (d > 2) _dest = new Point(tx + 30 * dx / d, ty + 60 * dy / d);
         else if (_controlItem != null)
         {
            // Stopped: stay on the side the follower is on.
            dx = _controlItem.x - tx;
            dy = _controlItem.y - ty;
            d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
            _dest = new Point(tx + 30 * dx / d, ty + 60 * dy / d);
         }
         keepWalkable(tx, ty);
         move();
      }

      private function onTargetJumped(e:Event):void
      {
         if (_controlItem == null) return;
         _dest = new Point(_target.x + 30, _target.y - 10);
         keepWalkable(_target.x, _target.y);
         _controlItem.jumpTo(_dest.x, _dest.y);
      }

      private function onArrived(e:Event):void
      {
         move();
      }

      private function onTargetRemoved(e:Event):void
      {
         var d:DisplayObject = _controlItem as DisplayObject;
         if (d != null && d.parent != null) d.parent.removeChild(d);
      }

      /** A point behind the leader that lies on the obstruction is replaced by the leader's own spot. */
      private function keepWalkable(tx:Number, ty:Number):void
      {
         var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (info != null && info.scene != null && info.scene.isBlocked(_dest.x, _dest.y)) _dest = new Point(tx, ty);
      }

      private function move():void
      {
         if (_controlItem == null || _dest == null || SceneManager.getInstance().isSuspend) return;
         var dx:Number = _controlItem.x - _dest.x, dy:Number = _controlItem.y - _dest.y;
         if (dx * dx + dy * dy > 1600) _controlItem.moveTo(int(_dest.x), int(_dest.y), Math.max(1, int(_target.walkSpeed * 0.66)));
      }

      override public function dispose():void
      {
         if (_target != null)
         {
            _target.removeEventListener(MovableEvent.MOVE_BEGIN, onTargetMoved);
            _target.removeEventListener(MovableEvent.ARRIVED, onTargetMoved);
            _target.removeEventListener(MovableEvent.JUMPED, onTargetJumped);
            _target.removeEventListener(Event.REMOVED_FROM_STAGE, onTargetRemoved);
         }
         if (_controlItem != null) _controlItem.removeEventListener(MovableEvent.ARRIVED, onArrived);
         _target = null;
         super.dispose();
      }
   }
}
