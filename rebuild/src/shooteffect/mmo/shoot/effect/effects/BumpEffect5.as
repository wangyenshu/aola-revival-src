package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public dynamic class BumpEffect5 extends MovieClip
   {
      
      public function BumpEffect5()
      {
         super();
         addFrameScript(21,this.frame22);
      }
      
      internal function frame22() : *
      {
         stop();
      }
   }
}

