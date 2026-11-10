package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   
   public dynamic class EndMovie extends MovieClip
   {
      
      public function EndMovie()
      {
         super();
         addFrameScript(250,this.frame251);
      }
      
      internal function frame251() : *
      {
         stop();
      }
   }
}

