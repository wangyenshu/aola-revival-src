package mmo.play.player.movable.strategy
{
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.play.player.movable.IMovable;

   /** REBUILT. Wanders around a point: new RoundPointStrategy(center, radius, minDelay, maxDelay). */
   public class RoundPointStrategy extends AbstractMovingStrategy implements IMovingStrategy
   {
      private var center:Point;
      private var radius:int;
      private var minDelay:int;
      private var maxDelay:int;
      private var timer:Timer;

      public function RoundPointStrategy(center:Point, radius:int = 40, minDelay:int = 1000, maxDelay:int = 3000)
      {
         super();
         this.center = center;
         this.radius = radius;
         this.minDelay = minDelay;
         this.maxDelay = Math.max(minDelay, maxDelay);
      }

      override public function setControlItem(item:IMovable):void
      {
         super.setControlItem(item);
         timer = new Timer(delay(), 1);
         timer.addEventListener(TimerEvent.TIMER, onTimer);
         timer.start();
      }

      private function delay():int
      {
         return minDelay + Math.random() * (maxDelay - minDelay);
      }

      private function onTimer(e:TimerEvent):void
      {
         if (_controlItem == null) return;
         var a:Number = Math.random() * Math.PI * 2;
         var r:Number = Math.random() * radius;
         _controlItem.moveTo(int(center.x + Math.cos(a) * r), int(center.y + Math.sin(a) * r * 0.6));
         timer.delay = delay();
         timer.reset();
         timer.start();
      }

      override public function dispose():void
      {
         if (timer) timer.stop();
         timer = null;
         super.dispose();
      }
   }
}
