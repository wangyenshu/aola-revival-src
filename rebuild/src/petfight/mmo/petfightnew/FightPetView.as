package mmo.petfightnew
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import flash.display.FrameLabel;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.TimerEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;

   /**
    * REBUILT. One 亚比 on the battle screen, played as the 2013 battle sprites
    * expect (the contract the era pet/fightpreview shows):
    * fightassets/pet<race>.swf holds mmo.petfight.pet<race>_1 (facing the
    * viewer, for the far side: the wild 亚比) and _2 (seen from behind, for the
    * near side: mine); frame 1 stands, 2 is hurt, 3 special
    * attack, 4 physical attack, 5 status skill. In frames 2–5 a child "mc" plays
    * the move; its labels "att", "eff" (start the skill effect), "move" with
    * p1–p4 (step towards the other side: +320,+90 from the far side, -340,-100
    * from the near side, and back) drive the rest. A 亚比 without a battle sprite stands in as its
    * large icon (peticon<race>_L).
    */
   public class FightPetView extends Sprite
   {
      private var raceId:int;
      /** The far side: the sprite faces the viewer (_1); the near side shows its back (_2). */
      private var front:Boolean;
      private var mc:MovieClip;
      private var still:DisplayObject;
      private var guard:Timer;

      public function FightPetView(raceId:int, front:Boolean)
      {
         super();
         this.raceId = raceId;
         this.front = front;
         mouseEnabled = mouseChildren = false;
      }

      public function get race():int
      {
         return raceId;
      }

      /** Load the battle sprite; onReady() either way. */
      public function load(onReady:Function):void
      {
         var cls:String = "mmo.petfight.pet" + raceId + (front ? "_1" : "_2");
         var make:Function = function(... a):void
         {
            if (ApplicationDomain.currentDomain.hasDefinition(cls))
            {
               var C:Class = getDefinitionByName(cls) as Class;
               mc = new C() as MovieClip;
               if (mc != null)
               {
                  addChild(mc);
                  mc.gotoAndStop(1);
                  onReady();
                  return;
               }
            }
            useIcon(onReady);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) make();
         else ResScheduler.getResource("fightassets/pet" + raceId, make, cls, function(e:* = null):void
         {
            RLog.log("fight: no battle sprite for 亚比 " + raceId);
            useIcon(onReady);
         });
      }

      private function useIcon(onReady:Function):void
      {
         var cls:String = "mmo.pet.peticon" + raceId + "_L";
         var put:Function = function(... a):void
         {
            if (ApplicationDomain.currentDomain.hasDefinition(cls))
            {
               var C:Class = getDefinitionByName(cls) as Class;
               still = new C() as DisplayObject;
               var b:Object = still.getBounds(still);
               var k:Number = Math.min(1.4, 150 / Math.max(1, b.height));
               still.scaleX = k;
               still.scaleY = k;
               still.x = -(b.left + b.width / 2) * k;
               still.y = -b.bottom * k;
               addChild(still);
            }
            onReady();
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("peticon/peticon" + raceId, put, cls, function(e:* = null):void { onReady(); });
      }

      public function normal():void
      {
         if (mc) mc.gotoAndStop(1);
      }

      /** kind: 0 physical, 1 special, 2 status. onEffect when the skill effect should start, onDone at the end. */
      public function attack(kind:int, onEffect:Function, onDone:Function):void
      {
         var once:Object = {eff: false, done: false};
         var fireEffect:Function = function():void
         {
            if (once.eff) return;
            once.eff = true;
            onEffect();
         };
         var finish:Function = function():void
         {
            if (once.done) return;
            once.done = true;
            stopGuard();
            fireEffect();
            normal();
            onDone();
         };
         startGuard(4000, finish);
         if (mc == null || mc.totalFrames < 5)
         {
            // A still picture: a short hop towards the other side.
            var self:FightPetView = this;
            var dx:int = front ? 40 : -40;
            var x0:Number = x;
            TweenLite.to(self, 0.15, {x: x0 + dx, onComplete: function():void
            {
               fireEffect();
               TweenLite.to(self, 0.2, {x: x0, onComplete: finish});
            }});
            return;
         }
         var frame:int = kind == 1 ? 3 : (kind == 2 ? 5 : 4);
         mc.addFrameScript(frame - 1, function():void
         {
            mc.addFrameScript(frame - 1, null);
            var inner:MovieClip = mc.getChildByName("mc") as MovieClip;
            if (inner == null)
            {
               TweenLite.delayedCall(0.4, finish);
               return;
            }
            var scripts:Object = {};
            var at:Function = function(f:int, fn:Function):void
            {
               if (f < 1) return;
               (scripts[f] ||= []).push(fn);
            };
            var labels:Array = inner.currentLabels;
            var moving:Boolean = false;
            for each (var l:FrameLabel in labels)
            {
               if (l.name == "eff") at(l.frame, fireEffect);
               else if (l.name == "move") moving = true;
            }
            if (moving)
            {
               var p1:int = labelFrame("p1", labels), p2:int = labelFrame("p2", labels);
               var p3:int = labelFrame("p3", labels), p4:int = labelFrame("p4", labels);
               at(p1, function():void { step(inner, p2 - p1, true); });
               at(p3, function():void { step(inner, p4 - p3, false); });
            }
            at(inner.totalFrames, function():void { inner.stop(); finish(); });
            for (var f:String in scripts) setFns(inner, int(f) - 1, scripts[f] as Array);
            inner.gotoAndPlay(1);
         });
         mc.gotoAndStop(frame);
      }

      /** addFrameScript with a closure per frame (AS3 closures share loop variables). */
      private static function setFns(inner:MovieClip, index:int, list:Array):void
      {
         inner.addFrameScript(index, function():void
         {
            for each (var fn:Function in list) fn();
         });
      }

      private function step(inner:MovieClip, frames:int, towards:Boolean):void
      {
         var sx:int = front ? 320 : -340, sy:int = front ? 90 : -100;
         if (!towards)
         {
            sx = -sx;
            sy = -sy;
         }
         TweenLite.to(inner, Math.max(1, frames), {x: inner.x + sx, y: inner.y + sy, useFrames: true});
      }

      private static function labelFrame(name:String, labels:Array):int
      {
         for each (var l:FrameLabel in labels) if (l.name == name) return l.frame;
         return 0;
      }

      public function hurt(onDone:Function):void
      {
         var finished:Boolean = false;
         var finish:Function = function():void
         {
            if (finished) return;
            finished = true;
            stopGuard();
            normal();
            onDone();
         };
         startGuard(2500, finish);
         if (mc == null || mc.totalFrames < 2)
         {
            var me:FightPetView = this;
            var hx:Number = x;
            TweenLite.to(me, 0.05, {x: hx + 8, onComplete: function():void
            {
               TweenLite.to(me, 0.1, {x: hx - 8, onComplete: function():void
               {
                  TweenLite.to(me, 0.05, {x: hx, onComplete: finish});
               }});
            }});
            return;
         }
         mc.addFrameScript(1, function():void
         {
            mc.addFrameScript(1, null);
            var inner:MovieClip = mc.getChildByName("mc") as MovieClip;
            if (inner == null || inner.totalFrames < 2)
            {
               TweenLite.delayedCall(0.5, finish);
               return;
            }
            inner.addFrameScript(inner.totalFrames - 1, function():void { inner.stop(); finish(); });
            inner.gotoAndPlay(1);
         });
         mc.gotoAndStop(2);
      }

      public function faint(onDone:Function = null):void
      {
         normal();
         TweenLite.to(this, 0.6, {alpha: 0, y: y + 10, onComplete: onDone});
      }

      private function startGuard(ms:int, fn:Function):void
      {
         stopGuard();
         guard = new Timer(ms, 1);
         guard.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void { fn(); });
         guard.start();
      }

      private function stopGuard():void
      {
         if (guard) guard.stop();
         guard = null;
      }

      public function dispose():void
      {
         stopGuard();
         TweenLite.killTweensOf(this);
         if (mc) mc.stop();
         if (parent) parent.removeChild(this);
      }
   }
}
