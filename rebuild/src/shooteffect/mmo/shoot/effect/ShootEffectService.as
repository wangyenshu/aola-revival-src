package mmo.shoot.effect
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Shape;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.Point;
   import flash.utils.getTimer;
   import mmo.interfaces.IService;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.effects.IShootEffectService;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;

   /**
    * REBUILT shoot/shooteffectservice (ServiceConfig "ShootEffectService"):
    * the beams a player sends at things. The 2013 module and its effect art
    * are lost; the effect is drawn (a pulsing beam from the player's hand to
    * the target) and the callbacks run as the 2013 interface promises:
    * collect() after `duration` ms (gathering), shoot() once the beam lands.
    */
   public class ShootEffectService extends EventDispatcher implements IShootEffectService
   {
      private var collecting:Object;

      public function ShootEffectService()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      public function collect(from:String, point:Point, cardId:int, duration:int, callback:Function = null, thisObj:* = null):void
      {
         cancelCollect();
         var job:Object = beam(from, point, Math.max(300, duration), function():void
         {
            if (collecting == job) collecting = null;
            if (callback != null) callback.apply(thisObj, []);
         });
         collecting = job;
      }

      public function cancelCollect():void
      {
         if (collecting != null) collecting.stop();
         collecting = null;
      }

      public function shoot(from:String, type:int, target:IShootEffectTarget, info:ShootInfo, callback:Function = null, thisObj:* = null):void
      {
         beam(from, new Point(target.x, target.y), 600, function():void
         {
            if (callback != null) callback.apply(thisObj, []);
         });
      }

      /** Draw a beam from the player to point for ms milliseconds, then done(). Returns {stop()}. */
      private function beam(from:String, point:Point, ms:int, done:Function):Object
      {
         var p:PlayerBase = PlayerManager.getInstance().getPlayer(from);
         var layer:DisplayObjectContainer = p ? p.parent : null;
         var s:Shape = new Shape();
         var t0:int = getTimer();
         var job:Object = {};
         var finish:Function = function(call:Boolean):void
         {
            s.removeEventListener(Event.ENTER_FRAME, frame);
            if (s.parent) s.parent.removeChild(s);
            if (call) done();
         };
         var frame:Function = function(e:Event):void
         {
            var k:Number = (getTimer() - t0) / ms;
            if (k >= 1 || p == null || p.parent == null)
            {
               finish(p != null);
               return;
            }
            var hx:Number = p.x, hy:Number = p.y - 50;
            s.graphics.clear();
            var a:Number = 0.45 + 0.35 * Math.sin(getTimer() / 80);
            s.graphics.lineStyle(6, 0x66CCFF, a * 0.5);
            s.graphics.moveTo(hx, hy);
            s.graphics.lineTo(point.x, point.y);
            s.graphics.lineStyle(2, 0xFFFFFF, a);
            s.graphics.moveTo(hx, hy);
            s.graphics.lineTo(point.x, point.y);
            s.graphics.lineStyle();
            s.graphics.beginFill(0xCCF2FF, a);
            s.graphics.drawCircle(point.x, point.y, 6 + 4 * Math.sin(getTimer() / 60));
            s.graphics.endFill();
         };
         job.stop = function():void { finish(false); };
         if (layer != null) layer.addChild(s);
         s.addEventListener(Event.ENTER_FRAME, frame);
         return job;
      }
   }
}
