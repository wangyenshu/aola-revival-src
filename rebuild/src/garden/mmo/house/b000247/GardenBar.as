package mmo.house.b000247
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.utils.Timer;
   import mmo.common.DateUtil;
   import mmo.common.sound.SoundManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RAvatar;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REBUILT: the 家园's bar, the strip under the garden of the January 2012 tutorial picture
    * (house/houseteachmovie/houseteachgarden): the owner's plate, three figures (★ ☺ ♥), the
    * friends' cards between ◀ ⏪ and ▶ ⏩, the green 刷新, the cart of the 商城, the sound
    * switch and the clock. The 2012 garden's code is lost; the later garden lists the player and
    * the player's friends to go to their homes. Drawn over the picture here: the figures over
    * its "100"s, the cards on a copy of its one sample card (a place in a circle, a star with a
    * figure, a picture, the name), the clock over its "00:33".
    *
    *   ★ 徽章分数 (我的荣誉), ☺ 人气 (visits of the home, 足迹), ♥ 好友 (how many friends):
    *   the owner's. The cards: the player and the player's friends by 徽章分数, a card goes to
    *   that one's 家园. SundriesExtension revival_gardenbar (server garden.ts).
    */
   public class GardenBar
   {
      private static const CMD:String = "revival_gardenbar";
      /** Cards a page, the first one's left edge and the step. */
      private static const PER_PAGE:int = 7;
      private static const CARD_X:int = 161;
      private static const CARD_STEP:int = 100;
      /** The sample card in the picture (its frame is copied): left, top, width, height. */
      private static const CARD:Rectangle = new Rectangle(154, 448, 100, 108);
      /** The three figures' boxes (dark green), their middles. */
      private static const STAT_X:int = 42, STAT_W:int = 56;
      private static const STAT_Y:Array = [484, 508, 533];
      private static const STAT_H:int = 12;
      private static const STAT_TIPS:Array = ["徽章分数", "人气", "好友"];

      private var hud:Sprite;
      private var owner:Function;
      private var visit:Function;
      private var press:Function;
      private var layer:Sprite = new Sprite();
      private var cards:Sprite = new Sprite();
      private var stats:Array = [];
      private var clock:TextField;
      private var clockTimer:Timer;
      private var mute:Shape;
      private var picture:BitmapData;
      private var list:Array = [];
      private var page:int;

      /** owner(): whose garden; visit(name): to that one's 家园; press(name): the control bar's button. */
      public function GardenBar(hud:Sprite, owner:Function, visit:Function, press:Function)
      {
         this.hud = hud;
         this.owner = owner;
         this.visit = visit;
         this.press = press;
         layer.name = "gardenBar";
         hud.addChild(layer);
         layer.addChild(cards);
         buildStats();
         buildButtons();
         buildClock();
         SocketClient.instance.addEventListener(CMD, onBar);
         refresh();
      }

      /** The picture, once it is there: the cards are drawn on a copy of its sample card. */
      public function setPicture(pic:DisplayObject):void
      {
         try
         {
            picture = new BitmapData(CARD.width, CARD.height, true, 0);
            picture.draw(pic, new Matrix(1, 0, 0, 1, -CARD.x, -CARD.y));
         }
         catch (e:Error)
         {
            RLog.error("garden bar picture", e);
            picture = null;
         }
         showPage();
      }

      public function dispose():void
      {
         SocketClient.instance.removeEventListener(CMD, onBar);
         if (clockTimer != null) clockTimer.stop();
         if (layer.parent != null) layer.parent.removeChild(layer);
         if (picture != null) picture.dispose();
         picture = null;
      }

      private function refresh():void
      {
         SocketClient.instance.sendXtMessage("SundriesExtension", CMD, {un: owner()});
      }

      private function onBar(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         setStat(0, int(p.score));
         setStat(1, int(p.visits));
         setStat(2, int(p.friends));
         list = (p.list as Array) || [];
         page = Math.max(0, Math.min(page, pages() - 1));
         showPage();
      }

      // ───── the figures ─────

      private function buildStats():void
      {
         for (var i:int = 0; i < 3; i++)
         {
            var box:Sprite = new Sprite();
            box.name = "gardenStat" + i;
            box.graphics.beginFill(0x2F4A00);
            box.graphics.drawRoundRect(STAT_X + 1, STAT_Y[i], STAT_W - 2, STAT_H, 8, 8);
            box.graphics.endFill();
            // The icon to the left takes the tip too.
            box.graphics.beginFill(0xFFFFFF, 0);
            box.graphics.drawRect(14, STAT_Y[i] - 6, STAT_X - 14, STAT_H + 12);
            box.graphics.endFill();
            var t:TextField = text(12, 0xC0EC5A, false, STAT_W, TextFormatAlign.CENTER);
            t.x = STAT_X;
            t.y = STAT_Y[i] + STAT_H / 2 - 9;
            t.text = "0";
            box.addChild(t);
            try { TipsManager.getInstance().addTips(box, STAT_TIPS[i]); } catch (err:Error) {}
            layer.addChild(box);
            stats.push(t);
         }
      }

      private function setStat(i:int, n:int):void
      {
         TextField(stats[i]).text = String(n);
      }

      // ───── the buttons: arrows, 刷新, cart, sound ─────

      private function buildButtons():void
      {
         hot("gardenBarPrev", 128, 461, 25, 45, "上一页", function():void { turn(page - 1); });
         hot("gardenBarFirst", 128, 507, 25, 23, "第一页", function():void { turn(0); });
         hot("gardenBarNext", 863, 461, 27, 45, "下一页", function():void { turn(page + 1); });
         hot("gardenBarLast", 861, 507, 27, 23, "最后一页", function():void { turn(pages() - 1); });
         hot("gardenBarRefresh", 909, 464, 29, 29, "刷新", refresh);
         hot("gardenBarMall", 918, 495, 42, 42, "商城", function():void { press("mall"); });
         hot("gardenBarSound", 889, 512, 25, 41, "音乐开关", switchSound);
         mute = new Shape();
         mute.graphics.lineStyle(2.4, 0xE02020);
         mute.graphics.drawCircle(902, 541, 10);
         mute.graphics.moveTo(895, 534);
         mute.graphics.lineTo(909, 548);
         layer.addChild(mute);
         var off:Boolean = false;
         try { off = SoundManager.instance.isClose; } catch (e:Error) {}
         mute.visible = off;
      }

      private function switchSound():void
      {
         var off:Boolean = !mute.visible;
         try { SoundManager.instance.switchMusic(off); } catch (e:Error) { RLog.error("garden sound", e); return; }
         mute.visible = off;
      }

      private function hot(n:String, x:int, y:int, w:int, h:int, tip:String, act:Function):void
      {
         var b:Sprite = new Sprite();
         b.name = n;
         b.buttonMode = true;
         b.graphics.beginFill(0xFFFFFF, 0);
         b.graphics.drawRect(x, y, w, h);
         b.graphics.endFill();
         b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            act();
         });
         try { TipsManager.getInstance().addTips(b, tip); } catch (err:Error) {}
         layer.addChild(b);
      }

      // ───── the clock (the server's time, as the control bar's) ─────

      private function buildClock():void
      {
         var box:Shape = new Shape();
         var m:Matrix = new Matrix();
         m.createGradientBox(36, 11, 0, 918, 541);
         box.graphics.beginGradientFill(GradientType.LINEAR, [0xE0287E, 0x9A3AB0, 0xC8DC28], [1, 1, 1], [0, 140, 255], m);
         box.graphics.drawRoundRect(918, 541, 36, 11, 8, 8);
         box.graphics.endFill();
         layer.addChild(box);
         clock = text(11, 0xFFFFFF, true, 40, TextFormatAlign.CENTER);
         clock.name = "gardenClock";
         clock.x = 916;
         clock.y = 538;
         clock.filters = [new GlowFilter(0x3A1030, 1, 3, 3, 6)];
         layer.addChild(clock);
         clockTimer = new Timer(10000);
         clockTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { tick(); });
         clockTimer.start();
         tick();
      }

      private function tick():void
      {
         var d:Date;
         try { d = DateUtil.getServerTime(); } catch (e:Error) {}
         if (d == null || isNaN(d.time)) d = new Date();
         clock.text = two(d.hours) + ":" + two(d.minutes);
      }

      private static function two(n:int):String
      {
         return n < 10 ? "0" + n : String(n);
      }

      // ───── the cards ─────

      private function pages():int
      {
         return Math.max(1, Math.ceil(list.length / PER_PAGE));
      }

      private function turn(to:int):void
      {
         to = Math.max(0, Math.min(to, pages() - 1));
         if (to == page) return;
         page = to;
         showPage();
      }

      private function showPage():void
      {
         while (cards.numChildren) cards.removeChildAt(0);
         if (picture == null) return;
         for (var i:int = 0; i < PER_PAGE; i++)
         {
            var at:int = page * PER_PAGE + i;
            if (at >= list.length) break;
            var c:Sprite = card(list[at], at + 1);
            c.x = CARD_X + i * CARD_STEP - (CARD_X - CARD.x);
            c.y = CARD.y;
            cards.addChild(c);
         }
      }

      /** One card: a copy of the sample's frame, its place, 徽章分数, picture and name drawn anew. */
      private function card(o:Object, place:int):Sprite
      {
         var un:String = String(o.un);
         var s:Sprite = new Sprite();
         s.name = "gardenCard_" + un;
         s.buttonMode = true;
         s.mouseChildren = false;
         s.addChild(new Bitmap(picture));
         // Card coordinates: the picture's minus CARD's corner.
         var dx:int = -CARD.x, dy:int = -CARD.y;
         var over:Shape = new Shape();
         // The figure on the green band (after the star) and the name strip, in their colours.
         fill(over, picture.getPixel(244 + dx, 462 + dy), 205 + dx, 455 + dy, 42, 14);
         fill(over, picture.getPixel(236 + dx, 545 + dy), 166 + dx, 537 + dy, 80, 14);
         // The picture's ground, light.
         var m:Matrix = new Matrix();
         m.createGradientBox(76, 65, Math.PI / 2, 169 + dx, 471 + dy);
         over.graphics.beginGradientFill(GradientType.LINEAR, [0xEEF8FC, 0xBFE0EC], [1, 1], [0, 255], m);
         over.graphics.drawRect(169 + dx, 471 + dy, 76, 65);
         over.graphics.endFill();
         // The sample's place (500) runs out of its circle onto the band: the band there, then the circle.
         fill(over, picture.getPixel(244 + dx, 462 + dy), 176 + dx, 455 + dy, 11, 14);
         // The place: the middle of its circle, mint.
         over.graphics.beginFill(picture.getPixel(164 + dx, 471 + dy));
         over.graphics.drawCircle(168 + dx, 462 + dy, 13);
         over.graphics.endFill();
         s.addChild(over);
         // The 亚比 of the frame's own: the player's avatar, head and shoulders.
         var pic:Sprite = new Sprite();
         var mask:Shape = new Shape();
         mask.graphics.beginFill(0);
         mask.graphics.drawRect(169 + dx, 471 + dy, 76, 65);
         mask.graphics.endFill();
         s.addChild(mask);
         pic.mask = mask;
         s.addChild(pic);
         RAvatar.show(un, pic, function(sp:Sprite, b:Rectangle):Boolean
         {
            // The top of the avatar fills the picture: its head and shoulders.
            var k:Number = Math.min(65 / (b.height * 0.42), 76 / (b.width * 0.9));
            sp.scaleX = sp.scaleY = k;
            sp.x = 169 + dx + 38 - (b.left + b.width / 2) * k;
            sp.y = 471 + dy + 2 - b.top * k;
            return false;
         });
         var placeText:TextField = text(place >= 100 ? 10 : 13, 0xFFE83D, true, 26, TextFormatAlign.CENTER);
         placeText.text = String(place);
         placeText.x = 155 + dx;
         placeText.y = 462 + dy - 10;
         placeText.filters = [new GlowFilter(0xA53800, 1, 3, 3, 8)];
         s.addChild(placeText);
         var score:TextField = text(13, 0xFFFFFF, false, 44, TextFormatAlign.CENTER);
         score.text = String(int(o.score));
         score.x = 204 + dx;
         score.y = 453 + dy;
         s.addChild(score);
         var name:TextField = text(12, 0x2E5A4A, false, 86, TextFormatAlign.CENTER);
         name.text = un;
         name.x = 163 + dx;
         name.y = 535 + dy;
         s.addChild(name);
         var here:Boolean = un == owner();
         try { TipsManager.getInstance().addTips(s, here ? "第" + place + "名" : "第" + place + "名，去" + un + "的家园"); } catch (err:Error) {}
         s.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (un == owner()) RNotice.show(LayerManager.getBaseTop(), "这里就是" + (un == SocketClient.instance.myUserName ? "你" : un) + "的家园哦！");
            else visit(un);
         });
         return s;
      }

      private static function fill(s:Shape, color:uint, x:Number, y:Number, w:Number, h:Number):void
      {
         s.graphics.beginFill(color);
         s.graphics.drawRect(x, y, w, h);
         s.graphics.endFill();
      }

      private static function text(size:int, color:uint, bold:Boolean, width:Number, align:String):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold, null, null, null, null, align);
         t.selectable = false;
         t.mouseEnabled = false;
         t.width = width;
         t.height = size + 8;
         return t;
      }
   }
}
