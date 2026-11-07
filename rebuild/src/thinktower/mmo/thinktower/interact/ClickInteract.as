package mmo.thinktower.interact
{
   import flash.display.MovieClip;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class ClickInteract implements Iinteract
   {
      
      private var params:Array;
      
      private var fun:Function;
      
      public function ClickInteract()
      {
         super();
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         this.params = param1;
         ClickAndHitHelper.instance.registerTarget(param1[0]);
         MovieClip(param1[0]).addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClick);
         this.fun = param2;
      }
      
      private function onClick(param1:ClickAndHitEvent) : void
      {
         if(this.fun != null)
         {
            this.fun.apply();
         }
         if(this.params[1])
         {
            this.dispose();
         }
      }
      
      public function dispose() : void
      {
         ClickAndHitHelper.instance.remove(this.params[0]);
         MovieClip(this.params[0]).removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClick);
         this.params = null;
      }
   }
}

