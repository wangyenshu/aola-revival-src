package mmo.play.player.movable.strategy
{
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.MovableEvent;

   /** REBUILT. Follows a leader (a player) and stands behind it; subclasses set the offset. */
   public class StandBehindStrategy extends AbstractMovingStrategy implements IMovingStrategy
   {
      protected var _leader:IMovable;

      public function StandBehindStrategy(leader:IMovable)
      {
         super();
         _leader = leader;
      }

      override public function setControlItem(item:IMovable):void
      {
         super.setControlItem(item);
         if (_leader != null)
         {
            _leader.addEventListener(MovableEvent.MOVE_BEGIN, onLeaderMove, false, 0, true);
            _leader.addEventListener(MovableEvent.JUMPED, onLeaderMove, false, 0, true);
            follow();
         }
      }

      protected function getFollowingOffset():Point
      {
         return new Point(40, 30);
      }

      private function onLeaderMove(e:Event):void
      {
         follow();
      }

      private function follow():void
      {
         if (_controlItem == null || _leader == null) return;
         var off:Point = getFollowingOffset();
         var tx:int = _leader.destX + (_leader.destX < _controlItem.x ? off.x : -off.x);
         var ty:int = _leader.destY - off.y;
         _controlItem.moveTo(tx, ty);
      }

      override public function dispose():void
      {
         if (_leader != null)
         {
            _leader.removeEventListener(MovableEvent.MOVE_BEGIN, onLeaderMove);
            _leader.removeEventListener(MovableEvent.JUMPED, onLeaderMove);
         }
         _leader = null;
         super.dispose();
      }
   }
}
