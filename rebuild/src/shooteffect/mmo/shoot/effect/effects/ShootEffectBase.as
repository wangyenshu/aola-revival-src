package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   
   public class ShootEffectBase extends MovieClip
   {
      
      private var callback:Function;
      
      private var thisObject:*;
      
      public function ShootEffectBase()
      {
         super();
      }
      
      public function show(param1:Function, param2:*) : void
      {
         var onPlayed:Function;
         var callback:Function = param1;
         var thisObject:* = param2;
         this.callback = callback;
         this.thisObject = thisObject;
         onPlayed = function():*
         {
            callback.apply(thisObject);
         };
         this.addFrameScript(this.totalFrames - 1,onPlayed);
         this.gotoAndPlay(1);
      }
   }
}

