package mmo.game.parkour
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import mmo.game.parkour.panel.ParkourMainPanel;
   
   public class ParkourGame extends MovieClip
   {
      
      public function ParkourGame()
      {
         var _loc1_:ParkourMainPanel = null;
         super();
         addEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
      }
      
      private function onAddToStage(param1:Event) : void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
         new ParkourMainPanel().showPanel();
      }
   }
}

