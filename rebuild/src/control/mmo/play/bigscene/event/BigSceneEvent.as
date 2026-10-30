package mmo.play.bigscene.event
{
   import flash.events.Event;

   /** REBUILT (later-engine event): a wide scene scrolled. */
   public class BigSceneEvent extends Event
   {
      public static const SCROLLRECT_CHANGE:String = "scrollRectChange";
      public var params:Object;

      public function BigSceneEvent(type:String, params:Object = null)
      {
         super(type);
         this.params = params;
      }
   }
}
