package mmo.thinktower.interact
{
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   
   public class TimerInteract implements Iinteract
   {
      
      private var timer:Timer;
      
      private var second:int = 1000;
      
      private var fun:Function;
      
      public function TimerInteract()
      {
         super();
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         this.timer = new Timer(this.second,param1[0]);
         this.timer.addEventListener(TimerEvent.TIMER,this.onTimer);
         this.fun = param2;
         this.timer.start();
      }
      
      private function onTimer(param1:TimerEvent) : void
      {
         this.fun.apply(null,[this.timer.currentCount]);
      }
      
      public function dispose() : void
      {
         this.timer.stop();
         this.timer.removeEventListener(TimerEvent.TIMER,this.onTimer);
         this.timer = null;
      }
   }
}

