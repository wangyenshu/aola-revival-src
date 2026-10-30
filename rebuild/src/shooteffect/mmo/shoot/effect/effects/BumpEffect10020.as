package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public dynamic class BumpEffect10020 extends MovieClip
   {
      
      public function BumpEffect10020()
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

