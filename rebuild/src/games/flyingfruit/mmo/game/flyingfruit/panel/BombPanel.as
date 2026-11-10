package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   
   public dynamic class BombPanel extends MovieClip
   {
      
      public function BombPanel()
      {
         super();
         addFrameScript(17,this.frame18);
      }
      
      internal function frame18() : *
      {
         stop();
      }
   }
}

