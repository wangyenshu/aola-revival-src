package mmo.revival.wnking
{
   import flash.display.Sprite;
   import mmo.activity130221.wolfandnightking.ChallengePanel0;
   import mmo.activity130221.wolfandnightking.ChallengePanel1;

   /**
    * The two kings' panels (wolfandnightkingchallenge0, of 2016, and 1, of 2016) bound to their art
    * alone: the later dialogs those files carry beside them (快速挑战, its 星币 confirm, and the
    * after-call panel of 2014, which need the later libraries) are left out.
    */
   public class DocWNKingRes extends Sprite
   {
      public function DocWNKingRes()
      {
         super();
      }

      private static function compileme():void
      {
         var c:Array = [ChallengePanel0, ChallengePanel1];
      }
   }
}
