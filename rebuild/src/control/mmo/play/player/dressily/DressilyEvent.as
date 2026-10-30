package mmo.play.player.dressily
{
   import flash.events.Event;

   /** REBUILT. Avatar notifications (2013 names and values). */
   public class DressilyEvent extends Event
   {
      public static const ACTION_BEGIN:String = "onActionBegin";
      public static const ACTION_END:String = "onActionEnd";
      public static const DRESS_COMPLETED:String = "onDressCompleted";
      public static const onRender:String = "onRender";

      private var _params:Object;

      public function DressilyEvent(type:String, params:Object = null)
      {
         super(type);
         _params = params || {};
      }

      public function get params():Object
      {
         return _params;
      }

      override public function clone():Event
      {
         return new DressilyEvent(type, _params);
      }
   }
}
