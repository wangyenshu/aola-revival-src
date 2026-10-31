package mmo.game.parkour
{
   import flash.display.DisplayObject;
   import mmo.play.scene.DocGameBase;
   
   [SWF(width="960", height="560", backgroundColor="#333333", frameRate="24")]
   public class DocParkourGame extends DocGameBase
   {
      
      public function DocParkourGame()
      {
         super();
      }
      
      override public function get game() : DisplayObject
      {
         return new ParkourGame();
      }
   }
}

