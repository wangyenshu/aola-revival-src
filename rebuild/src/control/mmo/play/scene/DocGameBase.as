package mmo.play.scene
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;

   /** REBUILT. Document class of mini-game SWFs (game/*): subclasses return the game from get game(). */
   public class DocGameBase extends MovieClip
   {
      public function DocGameBase()
      {
         super();
      }

      public function get game():DisplayObject
      {
         return null;
      }
   }
}
