package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public dynamic class BumpEffect3 extends MovieClip
   {
      
      public function BumpEffect3()
      {
         super();
         addFrameScript(12,this.frame13);
      }
      
      internal function frame13() : *
      {
         stop();
      }
   }
}

