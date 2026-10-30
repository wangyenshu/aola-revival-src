package mmo.play.scene.helper.cilckandhit
{
   import flash.events.Event;

   /** REBUILT. Dispatched on a registered target once my player has walked up to it. */
   public class ClickAndHitEvent extends Event
   {
      public static const ON_CLICK_AND_HIT:String = "onClickAndHit";

      public var params:Object;

      public function ClickAndHitEvent(type:String, params:Object = null)
      {
         super(type);
         this.params = params || {};
      }

      override public function clone():Event
      {
         return new ClickAndHitEvent(type, params);
      }
   }
}
