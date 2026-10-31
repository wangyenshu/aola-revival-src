package mmo.house.b020000
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.utils.getTimer;
   import mmo.common.utils.tips.TipsManager;
   import mmo.revival.RUI;

   /**
    * An animal of the zoo: its picture (young while it grows, grown once it
    * may be harvested), walking about the lawn (陆地), hovering over it
    * (天空) or swimming in its place in the tank (海洋). The 2013 zoo's own
    * animals and their walks are lost: RECONSTRUCTED.
    */
   public class ZooAnimal extends Sprite
   {
      public var id:int;
      public var race:int;
      public var mature:Boolean;
      public var left:int;
      public var rate:int;
      public var where:String;

      private var pic:Sprite;
      private var body:Sprite;
      private var badge:TextField;
      private var walkable:Function;
      private var tx:Number;
      private var ty:Number;
      private var restUntil:int;
      private var last:int;
      private var shownGrown:Boolean;
      private var baseY:Number;
      private var swim:Boolean;
      private var gotAt:int;

      /** walkable(x, y) says whether the lawn is there; null for a fish, which stays at its place. */
      public function ZooAnimal(data:Object, walkable:Function)
      {
         super();
         this.walkable = walkable;
         swim = walkable == null;
         name = "zooAnimal_" + int(data.id);
         buttonMode = true;
         mouseChildren = false;
         body = new Sprite();
         addChild(body);
         pic = new Sprite();
         body.addChild(pic);
         badge = RUI.text(12, 0xFFFFFF, true);
         badge.filters = [new GlowFilter(0xC25A00, 1, 3, 3, 6)];
         badge.mouseEnabled = false;
         addChild(badge);
         update(data);
         addEventListener(Event.ENTER_FRAME, onFrame);
         addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         restUntil = getTimer() + int(Math.random() * 2000);
         last = getTimer();
      }

      public function update(data:Object):void
      {
         id = int(data.id);
         race = int(data.raceId);
         mature = int(data.mature) == 1;
         left = int(data.left);
         rate = int(data.rate);
         gotAt = getTimer();
         var a:Object = ZooData.animal(race);
         where = a ? String(a.position) : "陆地";
         if (pic.numChildren == 0 || shownGrown != mature)
         {
            shownGrown = mature;
            ZooData.picture(race, mature, swim ? 40 : (mature ? 70 : 58), pic);
         }
         badge.text = mature ? "可以收获啦" : "";
         badge.x = -badge.width / 2;
         badge.y = (swim ? -52 : -86) - (where == "天空" ? 50 : 0);
         try { TipsManager.getInstance().addTips(this, tipText()); } catch (e:Error) {}
      }

      /** Seconds still to grow, counting down since the server said. */
      public function get secondsLeft():int
      {
         return Math.max(0, left - int((getTimer() - gotAt) / 1000));
      }

      private function tipText():String
      {
         return ZooData.nameOf(race, mature) + " " + ZooData.stars(race) + "\n" + (mature ? "已经长大了，可以收获！" : ZooData.hoursText(left) + "长大");
      }

      public function place(x0:Number, y0:Number):void
      {
         x = tx = x0;
         y = ty = baseY = y0;
         if (where == "天空") body.y = -50;
      }

      private function onFrame(e:Event):void
      {
         var now:int = getTimer();
         var dt:Number = Math.min(200, now - last) / 1000;
         last = now;
         // Flyers bob in the air, fish sway.
         if (where == "天空") body.y = -50 + Math.sin(now / 300) * 6;
         else if (swim) body.y = Math.sin(now / 500 + id) * 3;
         if (swim || walkable == null) return;
         if (now < restUntil) return;
         var dx:Number = tx - x;
         var dy:Number = ty - y;
         var d:Number = Math.sqrt(dx * dx + dy * dy);
         if (d < 2)
         {
            restUntil = now + 1500 + int(Math.random() * 4000);
            pickTarget();
            return;
         }
         var step:Number = Math.min(d, (where == "天空" ? 46 : 34) * dt);
         x += dx / d * step;
         y += dy / d * step;
         if (Math.abs(dx) > 1) body.scaleX = dx > 0 ? -1 : 1;
         // A little hop as it walks.
         if (where != "天空") body.y = -Math.abs(Math.sin(now / 110)) * 4;
      }

      private function pickTarget():void
      {
         for (var i:int = 0; i < 12; i++)
         {
            var nx:Number = x + (Math.random() - 0.5) * 240;
            var ny:Number = y + (Math.random() - 0.5) * 120;
            if (walkable(nx, ny))
            {
               tx = nx;
               ty = ny;
               return;
            }
         }
      }

      public function dispose():void
      {
         removeEventListener(Event.ENTER_FRAME, onFrame);
         if (parent) parent.removeChild(this);
      }
   }
}
