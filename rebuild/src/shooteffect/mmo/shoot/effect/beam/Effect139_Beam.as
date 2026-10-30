package mmo.shoot.effect.beam
{
   import flash.display.MovieClip;
   
   public dynamic class Effect139_Beam extends MovieClip
   {
      
      public function Effect139_Beam()
      {
         super();
         addFrameScript(0,this.frame1);
      }
      
      internal function frame1() : *
      {
         mouseChildren = mouseEnabled = false;
      }
   }
}

