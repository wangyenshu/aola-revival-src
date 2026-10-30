package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public dynamic class EffectMovie1 extends MovieClip
   {
      
      public function EffectMovie1()
      {
         super();
         addFrameScript(71,this.frame72);
      }
      
      internal function frame72() : *
      {
         stop();
      }
   }
}

