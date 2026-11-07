package starcoin_fla
{
   import flash.display.MovieClip;

   /** The art's timeline class (fortunemanager/starcoin): it stops on frame 53. */
   public dynamic class BubbleMovie extends MovieClip
   {

      public function BubbleMovie()
      {
         super();
         addFrameScript(52, this.stopHere);
      }

      internal function stopHere():*
      {
         stop();
      }
   }
}
