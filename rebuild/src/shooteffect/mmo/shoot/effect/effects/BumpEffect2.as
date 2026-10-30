package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public dynamic class BumpEffect2 extends MovieClip
   {
      
      public function BumpEffect2()
      {
         super();
         addFrameScript(28,this.frame29);
      }
      
      internal function frame29() : *
      {
         stop();
      }
   }
}

