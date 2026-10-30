package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public dynamic class BumpEffect6 extends MovieClip
   {
      
      public function BumpEffect6()
      {
         super();
         addFrameScript(8,this.frame9);
      }
      
      internal function frame9() : *
      {
         stop();
      }
   }
}

