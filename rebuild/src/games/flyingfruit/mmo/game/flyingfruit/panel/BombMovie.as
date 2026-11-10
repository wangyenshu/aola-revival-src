package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   
   public dynamic class BombMovie extends MovieClip
   {
      
      public function BombMovie()
      {
         super();
         addFrameScript(32,this.frame33);
      }
      
      internal function frame33() : *
      {
         stop();
      }
   }
}

