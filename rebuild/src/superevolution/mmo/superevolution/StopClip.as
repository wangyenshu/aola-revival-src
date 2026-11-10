package mmo.superevolution
{
   import flash.display.MovieClip;

   /** The ItemView's state clip (its frame script was a stop()): 1 未拥有, 2 不足, 3 足够. */
   public dynamic class StopClip extends MovieClip
   {
      public function StopClip()
      {
         super();
         stop();
      }
   }
}
