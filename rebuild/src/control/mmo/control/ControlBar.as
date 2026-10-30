package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Graphics;
   import flash.display.InteractiveObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Rectangle;
   import mmo.common.sound.SoundManager;
   import mmo.revival.RLog;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.ui.Keyboard;
   import flash.utils.Timer;
   import flash.utils.getQualifiedClassName;
   import mmo.common.DateUtil;

   /**
    * REBUILT control bar ("controlBar" in LayerManager.getBaseControl(), as
    * the January 2013 modules look for it: btnMap in it, and "hello", the
    * place hellohelper/helloiconservice puts the HELLO on).
    *
    * The 2013 bar was in the lost control/control.swf. This one is laid out
    * after the official screenshot of the bar of December 2011
    * (refs/battle-ui-2011-2012/1324027054208_1.jpg, scaled to the 960×560
    * stage): 地图 (the ringed planet, original art from the era
    * newBieHelpSystem module) and the HELLO on its glowing stand at the left;
    * 发言 表情 动作 射击; the chat line (当前, the box, ↵, and the △ for what was
    * said); 信息卡 好友 组队 战队 背包 回家; the cart of the 商城, the sound
    * switch and the clock at the right. The icons are drawn (BarIcons).
    */
   public class ControlBar extends Sprite
   {
      /** Called with a button name: map phrase face action shoot card friend team squad pet home mall history toolbox. */
      public var onButton:Function;
      /** Called with the line typed into the chat box. */
      public var onSay:Function;

      private var chat:Sprite;
      private var input:TextField;
      private var _map:InteractiveObject;
      private var buttons:Object = {};
      private var clock:TextField;
      private var sound:Sprite;
      private var muted:Boolean;
      private var popup:DisplayObject;

      private static const LEFT:Array = [["phrase", "发言", 181], ["face", "表情", 232], ["action", "动作", 277], ["shoot", "射击", 320]];
      private static const RIGHT:Array = [["card", "信息卡", 582], ["friend", "好友", 632], ["team", "组队", 681], ["squad", "战队", 732], ["pet", "背包", 786], ["home", "回家", 838]];
      private static const ICON_Y:int = 526;
      private static const LABEL_DY:int = 15;

      public function ControlBar()
      {
         super();
         name = "controlBar";
         drawBand();
         drawStand();
         _map = addButton(new BarButton("btnMap", planet(), "地图", 0, 12, click), 35, 527);
         var hello:Sprite = new Sprite();
         hello.name = "hello";
         hello.x = 110;
         hello.y = 536;
         addChild(hello);
         for each (var l:Array in LEFT) addButton(new BarButton("btn_" + l[0], BarIcons.make(l[0]), l[1], 0, LABEL_DY, click), l[2], ICON_Y);
         for each (var r:Array in RIGHT) addButton(new BarButton("btn_" + r[0], BarIcons.make(r[0]), r[1], 0, LABEL_DY, click), r[2], ICON_Y);
         var mall:BarButton = new BarButton("btn_mall", BarIcons.make("mall"), null, 0, 0, click);
         mall.scaleX = mall.scaleY = 1.15;
         addButton(mall, 938, 512);
         // The revival's 工具箱 (not of 2013), under the task icon.
         addButton(new BarButton("btn_toolbox", BarIcons.make("toolbox"), "工具箱", 0, 20, click), 936, 114);
         buildChat();
         buildSound();
         buildClock();
         addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { if (e.target != input) e.stopPropagation(); });
         addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
      }

      private function click(btnName:String):void
      {
         var n:String = btnName == "btnMap" ? "map" : btnName.replace("btn_", "");
         if (onButton != null) onButton(n);
      }

      private function addButton(b:BarButton, x:Number, y:Number):BarButton
      {
         b.x = x;
         b.y = y;
         addChild(b);
         buttons[b.name] = b;
         return b;
      }

      /** The ringed planet of the era newBieHelpSystem module (BarPlanet), centred on (0, 0). */
      private static function planet():Sprite
      {
         var s:Sprite = new Sprite();
         var p:DisplayObject = new BarPlanet();
         var b:Rectangle = p.getBounds(p);
         if (b.width < 2)
         {
            // The transplanted art is missing: a drawn planet.
            var g:Graphics = s.graphics;
            BarSkin.ball(g, 0, 0, 16, 0x6FC8FF, 0x1A62C8, 0xFFFFFF, 1.5);
            g.lineStyle(3, 0xFFD34A);
            g.drawEllipse(-28, -6, 56, 12);
            g.lineStyle();
            return s;
         }
         var k:Number = Math.min(1, 66 / b.width);
         p.scaleX = p.scaleY = k;
         p.x = -(b.left + b.width / 2) * k;
         p.y = -(b.top + b.height / 2) * k;
         s.addChild(p);
         return s;
      }

      /** The light blue glass band under the buttons. */
      private function drawBand():void
      {
         var band:Shape = new Shape();
         var g:Graphics = band.graphics;
         g.lineStyle(1, 0x2C78B8, 0.9);
         BarSkin.vgrad(g, 760, 34, [0xE2F8FF, 0x9ADBF7, 0x4FA9E0], 534, [0.96, 0.96, 0.96]);
         g.drawRoundRect(147, 534, 760, 40, 28, 28);
         g.endFill();
         g.lineStyle(1.5, 0xFFFFFF, 0.85);
         g.drawRoundRect(150, 537, 754, 36, 24, 24);
         g.lineStyle();
         BarSkin.shine(g, 527, 540, 740, 8, 0.55);
         band.name = "band";
         addChild(band);
      }

      /** The glowing stand the HELLO sits on. */
      private function drawStand():void
      {
         var st:Shape = new Shape();
         var g:Graphics = st.graphics;
         g.lineStyle(1, 0x1F6FAE);
         BarSkin.vgrad(g, 56, 22, [0x58C2EE, 0x1E6FB8], 540);
         g.drawRect(78, 540, 56, 22);
         g.endFill();
         g.lineStyle(1.5, 0xFFFFFF, 0.9);
         BarSkin.vgrad(g, 56, 16, [0xC8FBFF, 0x46CDF2], 532);
         g.drawEllipse(78, 532, 56, 16);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.55);
         g.drawEllipse(88, 535, 36, 8);
         g.endFill();
         st.filters = [new GlowFilter(0x7FE8FF, 0.7, 10, 10, 2)];
         addChild(st);
      }

      /** The chat line: 当前, the box, ↵ (send), and △ above it for the lines heard. */
      private function buildChat():void
      {
         chat = new Sprite();
         chat.name = "mctalkbar";
         var g:Graphics = chat.graphics;
         g.lineStyle(1, 0x15508F);
         BarSkin.vgrad(g, 34, 19, [0x3A93D8, 0x17599F], 538);
         g.drawRoundRect(360, 538, 34, 19, 8, 8);
         g.endFill();
         g.lineStyle(1.2, 0x5EA8D8);
         g.beginFill(0xFFFFFF);
         g.drawRoundRect(397, 538, 124, 19, 8, 8);
         g.endFill();
         var cur:TextField = BarSkin.label("当前", 12, 0xFFFFFF, 0x0E3D73);
         cur.x = 377 - cur.width / 2;
         cur.y = 539;
         chat.addChild(cur);
         input = new TextField();
         input.type = TextFieldType.INPUT;
         input.defaultTextFormat = new TextFormat("SimSun", 12, 0x333333);
         input.maxChars = 40;
         input.x = 401;
         input.y = 539;
         input.width = 117;
         input.height = 18;
         input.name = "chatInput";
         input.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
         {
            e.stopPropagation();
            if (e.keyCode == Keyboard.ENTER) send();
         });
         input.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent):void { e.stopPropagation(); });
         chat.addChild(input);
         var enter:Sprite = smallButton("btnSend", 524, 538, 22, 19, function():void { send(); });
         var eg:Graphics = enter.graphics;
         eg.lineStyle(2, 0x2470B8);
         eg.moveTo(541, 542); eg.lineTo(541, 551); eg.lineTo(530, 551);
         eg.lineStyle();
         eg.beginFill(0x2470B8);
         eg.moveTo(528, 551); eg.lineTo(533, 547); eg.lineTo(533, 555); eg.lineTo(528, 551);
         eg.endFill();
         chat.addChild(enter);
         var hist:Sprite = smallButton("btnHistory", 436, 523, 26, 14, function():void { if (onButton != null) onButton("history"); }, true);
         var hg:Graphics = hist.graphics;
         hg.beginFill(0x2D87D4);
         hg.moveTo(449, 526); hg.lineTo(443, 534); hg.lineTo(455, 534); hg.lineTo(449, 526);
         hg.endFill();
         chat.addChild(hist);
         addChild(chat);
      }

      private function smallButton(n:String, x:Number, y:Number, w:Number, h:Number, f:Function, topOnly:Boolean = false):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = n;
         var g:Graphics = b.graphics;
         g.lineStyle(1.2, 0x4E9DD3);
         BarSkin.vgrad(g, w, h, [0xF4FCFF, 0xA9DDF6], y);
         g.drawRoundRect(x, y, w, topOnly ? h + 8 : h, 8, 8);
         g.endFill();
         g.lineStyle();
         b.buttonMode = true;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            f();
         });
         return b;
      }

      /**
       * The music switch: a green ball with a note, crossed out when the music
       * is off. It is the 2013 SoundManager's (common library): switchMusic
       * stops the scene music or has it played again (init/sceneinit), and
       * the choice is kept per player (LocalStore "u_s").
       */
      private function buildSound():void
      {
         sound = new Sprite();
         sound.name = "btnSound";
         sound.x = 904;
         sound.y = 547;
         sound.buttonMode = true;
         try { muted = SoundManager.instance.isClose; } catch (err:Error) {}
         drawSound();
         sound.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            muted = !muted;
            try { SoundManager.instance.switchMusic(muted); } catch (err:Error) { RLog.error("music switch", err); }
            drawSound();
         });
         addChild(sound);
      }

      private function drawSound():void
      {
         var g:Graphics = sound.graphics;
         g.clear();
         BarSkin.ball(g, 0, 0, 8, 0x9BEA6A, 0x2E9E34, 0xFFFFFF, 1.2);
         g.lineStyle(1.6, 0xFFFFFF);
         g.moveTo(1.5, 3); g.lineTo(1.5, -5); g.lineTo(5, -3.5);
         g.lineStyle();
         g.beginFill(0xFFFFFF);
         g.drawEllipse(-3, 1.5, 5, 3.6);
         g.endFill();
         if (muted)
         {
            g.lineStyle(2.4, 0xE02020);
            g.drawCircle(0, 0, 8.5);
            g.moveTo(-6, -6); g.lineTo(6, 6);
            g.lineStyle();
         }
      }

      /** The clock (server time), bottom right. */
      private function buildClock():void
      {
         var box:Shape = new Shape();
         var g:Graphics = box.graphics;
         g.lineStyle(1, 0x7FC6F0);
         g.beginFill(0x0F2F66, 0.88);
         g.drawRoundRect(916, 539, 42, 17, 10, 10);
         g.endFill();
         addChild(box);
         clock = BarSkin.label("00:00", 11, 0xFFFFFF, 0xFFFFFFFF, true, "Arial");
         clock.name = "clock";
         clock.y = 539;
         addChild(clock);
         var t:Timer = new Timer(10000);
         t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { tick(); });
         t.start();
         tick();
      }

      private function tick():void
      {
         var d:Date;
         try { d = DateUtil.getServerTime(); } catch (e:Error) {}
         if (d == null || isNaN(d.time)) d = new Date();
         clock.text = two(d.hours) + ":" + two(d.minutes);
         clock.x = 937 - clock.width / 2;
      }

      private static function two(n:int):String
      {
         return n < 10 ? "0" + n : String(n);
      }

      private function send():void
      {
         var text:String = input.text;
         input.text = "";
         if (onSay != null && text.replace(/\s/g, "") != "") onSay(text);
      }

      /**
       * Show a pop-up of a button (phrases, faces, actions, what was said)
       * over the bar; the same one again closes it, and so does the mouse
       * leaving the pop-up and its button.
       */
      public function togglePopup(p:DisplayObject, x:Number, bottom:Number, anchor:DisplayObject = null):void
      {
         var same:Boolean = popup != null && p != null && popup.parent == this && getQualifiedClassName(popup) == getQualifiedClassName(p);
         closePopup();
         if (same || p == null) return;
         popup = p;
         popupAnchor = anchor;
         p.x = Math.max(4, Math.min(956 - p.width, x));
         p.y = bottom - p.height;
         addChild(p);
         if (stage) stage.addEventListener(MouseEvent.MOUSE_MOVE, watchPopup);
      }

      private var popupAnchor:DisplayObject;

      private function watchPopup(e:MouseEvent):void
      {
         if (popup == null || popup.parent != this) { closePopup(); return; }
         if (popup.hitTestPoint(e.stageX, e.stageY, false)) return;
         if (popupAnchor != null)
         {
            var r:Rectangle = popupAnchor.getBounds(stage);
            r.inflate(8, 8);
            if (r.contains(e.stageX, e.stageY)) return;
            // The gap between the button and the pop-up.
            var pr:Rectangle = popup.getBounds(stage);
            var gap:Rectangle = new Rectangle(Math.min(r.left, pr.left), pr.bottom - 4, Math.max(r.right, pr.right) - Math.min(r.left, pr.left), r.top - pr.bottom + 8);
            if (gap.height > 0 && gap.contains(e.stageX, e.stageY)) return;
         }
         closePopup();
      }

      public function closePopup():void
      {
         if (stage) stage.removeEventListener(MouseEvent.MOUSE_MOVE, watchPopup);
         if (popup != null && popup.parent == this) removeChild(popup);
         popup = null;
         popupAnchor = null;
      }

      public function get popupShown():DisplayObject
      {
         return popup;
      }

      public function get mapButton():InteractiveObject
      {
         return _map;
      }

      public function button(n:String):DisplayObject
      {
         return buttons["btn_" + n];
      }

      public function setMode(mode:String):void
      {
         closePopup();
         for (var k:String in buttons)
         {
            if (k != "btnMap") buttons[k].visible = (mode == "common");
         }
         if (chat) chat.visible = mode != "spacetime";
      }
   }
}
