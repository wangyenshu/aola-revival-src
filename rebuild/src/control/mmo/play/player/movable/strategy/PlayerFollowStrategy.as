package mmo.play.player.movable.strategy
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   import mmo.play.player.movable.IMovable;

   /**
    * REBUILT. A team member walks after the team's leader (the later baseservice/follow's
    * PlayerFollowStrategy of the same name, set for the user variable ft "1;<leader>"): it heads
    * for where the leader is going, at its place beside him (ox, oy), and stops once within
    * NEAR of it while he stands. Written against the rebuilt engine's IMovable (walkTo finds
    * the way); a new way is asked only when the leader's goal has moved.
    */
   public class PlayerFollowStrategy extends AbstractMovingStrategy implements IMovingStrategy
   {
      /** Close enough (the later strategy's 50 px). */
      private static const NEAR:int = 50;
      /** The leader's goal moved this far: a new way. */
      private static const MOVED:int = 20;
      /** Looked at every this many frames. */
      private static const EVERY:int = 5;

      private var _target:IMovable;
      private var _ox:int;
      private var _oy:int;
      private var _goX:int = int.MIN_VALUE;
      private var _goY:int = int.MIN_VALUE;
      private var _frames:int;

      public function PlayerFollowStrategy(target:IMovable, ox:int = 0, oy:int = 0)
      {
         super();
         _target = target;
         _ox = ox;
         _oy = oy;
      }

      public function get target():IMovable
      {
         return _target;
      }

      override public function setControlItem(item:IMovable):void
      {
         super.setControlItem(item);
         if (item is DisplayObject) DisplayObject(item).addEventListener(Event.ENTER_FRAME, onFrame, false, 0, true);
      }

      override public function dispose():void
      {
         if (_controlItem is DisplayObject) DisplayObject(_controlItem).removeEventListener(Event.ENTER_FRAME, onFrame);
         _target = null;
         super.dispose();
      }

      private function onFrame(e:Event):void
      {
         if (_controlItem == null || _target == null || ++_frames % EVERY != 0) return;
         var moving:Boolean = _target.isMoving();
         var tx:int = int(moving ? _target.destX : _target.x) + _ox;
         var ty:int = int(moving ? _target.destY : _target.y) + _oy;
         var dx:Number = _controlItem.x - tx, dy:Number = _controlItem.y - ty;
         if (dx * dx + dy * dy < NEAR * NEAR)
         {
            if (!moving && _controlItem.isMoving() && Math.abs(_goX - tx) >= MOVED) _controlItem.stop();
            return;
         }
         if (_controlItem.isMoving() && Math.abs(tx - _goX) < MOVED && Math.abs(ty - _goY) < MOVED) return;
         _goX = tx;
         _goY = ty;
         _controlItem.walkTo(tx, ty);
      }
   }
}
