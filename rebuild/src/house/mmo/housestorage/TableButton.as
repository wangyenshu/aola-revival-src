package mmo.housestorage
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;

   /** REBUILT. One storage tab: frame 1 normal, frame 2 chosen. */
   public dynamic class TableButton extends MovieClip
   {
      public static const onSelected:String = "onSelected";

      public function TableButton()
      {
         super();
         gotoAndStop(1);
         mouseChildren = false;
         buttonMode = true;
         addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { selected = true; });
      }

      public function get selected():Boolean
      {
         return currentFrame == 2;
      }

      public function set selected(v:Boolean):void
      {
         if (selected == v) return;
         gotoAndStop(v ? 2 : 1);
         if (v) dispatchEvent(new Event(onSelected));
      }
   }
}
