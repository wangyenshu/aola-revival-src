package mmo.play.player.movable
{
   import flash.events.Event;

   /** REBUILT. Movement notifications of players and other movables (2013 names and values). */
   public class MovableEvent extends Event
   {
      public static const JUMPED:String = "onMovableJumped";
      public static const MOVE_PREPARED:String = "onMovePrepared";
      public static const MOVE_BEGIN:String = "onMoveBegin";
      public static const ARRIVED:String = "onMovableArrived";
      public static const CHANGED_DIRECTION:String = "onMovableChangedDirection";
      public static const CHANGED_SPEED:String = "onMovableChangedSpeed";

      private var _params:Object;
      private var _canceled:Boolean;

      public function MovableEvent(type:String, params:Object = null, cancelable:Boolean = false)
      {
         super(type, false, cancelable);
         _params = params || {};
      }

      public function get params():Object
      {
         return _params;
      }

      public function set canceled(v:Boolean):void
      {
         _canceled = v;
      }

      public function get canceled():Boolean
      {
         return _canceled;
      }

      override public function clone():Event
      {
         return new MovableEvent(type, _params, cancelable);
      }
   }
}
