package mmo.game.parkour.view.game
{
   import flash.display.MovieClip;
   
   public dynamic class FullPowerMovie extends MovieClip
   {
      
      public function FullPowerMovie()
      {
         super();
         addFrameScript(9,this.frame10);
      }
      
      internal function frame10() : *
      {
         stop();
      }
   }
}

