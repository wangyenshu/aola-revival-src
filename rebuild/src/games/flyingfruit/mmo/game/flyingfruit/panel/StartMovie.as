package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   
   public dynamic class StartMovie extends MovieClip
   {
      
      public function StartMovie()
      {
         super();
         addFrameScript(60,this.frame61);
      }
      
      internal function frame61() : *
      {
         stop();
      }
   }
}

