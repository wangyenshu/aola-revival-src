package starcoin_fla
{
   import flash.display.MovieClip;

   /** The art's timeline class (fortunemanager/starcoin): it stops on frame 1. */
   public dynamic class Pic480 extends MovieClip
   {

      public function Pic480()
      {
         super();
         addFrameScript(0, this.stopHere);
      }

      internal function stopHere():*
      {
         stop();
      }
   }
}
