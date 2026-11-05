package mmo.talk
{
   import flash.display.Sprite;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import mmo.framework.comm.SocketClient;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * REBUILT. The 私聊 window: one friend's talk at a time, a tab for each friend talked with
    * (a dot: lines not read), a line to write. Over the game, not modal (it stays across maps);
    * dragged by its title.
    */
   public class PrivateTalkPanel extends Sprite
   {
      private static const W:int = 420;
      private static const H:int = 330;
      private static const TABS:int = 4;
      private static var current:PrivateTalkPanel;

      private var who:String;
      private var box:Sprite;
      private var tabs:Sprite = new Sprite();
      private var log:TextField;
      private var input:TextField;

      /** The friend whose talk is shown, or null. */
      public static function get showing():String
      {
         return current != null ? current.who : null;
      }

      public static function show(name:String):void
      {
         if (!name) return;
         if (current == null)
         {
            current = new PrivateTalkPanel();
            LayerManager.getBaseTop().addChild(current);
         }
         current.open(name);
      }

      /** A line came or went in this friend's talk. */
      internal static function changed(name:String):void
      {
         if (current == null) return;
         current.drawTabs();
         if (current.who == name) current.drawLog();
      }

      public function PrivateTalkPanel()
      {
         super();
         name = "privateTalkPanel";
         box = RUI.panel(W, H, "私聊", close, "talkClose");
         box.x = 960 - W - 20;
         box.y = 90;
         addChild(box);
         var drag:Sprite = new Sprite();
         drag.graphics.beginFill(0xFFFFFF, 0);
         drag.graphics.drawRect(12, 10, W - 48, 34);
         drag.graphics.endFill();
         drag.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
         {
            box.startDrag(false, new Rectangle(-W + 80, 0, 960 + W - 160, 520));
            stage.addEventListener(MouseEvent.MOUSE_UP, stopDragging);
         });
         box.addChildAt(drag, box.numChildren - 1);
         tabs.x = 18;
         tabs.y = 50;
         box.addChild(tabs);
         box.addChild(RUI.well(16, 80, W - 32, 176));
         log = new TextField();
         log.multiline = log.wordWrap = true;
         log.selectable = false;
         log.x = 24;
         log.y = 86;
         log.width = W - 48;
         log.height = 164;
         box.addChild(log);
         input = RUI.input(W - 128, "", null, TalkService.MAX_TEXT, "talkInput");
         input.x = 18;
         input.y = 268;
         input.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
         {
            // Typing here is not the game's (its chat line, its keys).
            e.stopPropagation();
            if (e.keyCode == Keyboard.ENTER) send();
         });
         box.addChild(input);
         var go:Sprite = RUI.button("发送", send, 80, 28, 0xFFC45A, 0xF07812, "talkSend");
         go.x = W - 100;
         go.y = 265;
         box.addChild(go);
      }

      private function stopDragging(e:MouseEvent):void
      {
         if (e.currentTarget) e.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, stopDragging);
         box.stopDrag();
      }

      private function open(name:String):void
      {
         who = name;
         TalkService.instance.read(name);
         drawTabs();
         drawLog();
         if (stage) stage.focus = input;
      }

      private function send():void
      {
         if (who == null || !input.text.replace(/\s/g, "")) return;
         TalkService.instance.send(who, input.text);
         input.text = "";
      }

      private function drawTabs():void
      {
         while (tabs.numChildren) tabs.removeChildAt(0);
         var names:Array = TalkService.instance.partners();
         if (who != null && names.indexOf(who) < 0) names.unshift(who);
         // The one shown always has its tab.
         names = names.slice(0, TABS);
         if (who != null && names.indexOf(who) < 0) names[TABS - 1] = who;
         var x:int = 0;
         for each (var n:String in names) x += tab(n, x) + 6;
      }

      private function tab(n:String, x:int):int
      {
         var on:Boolean = n == who;
         var t:Sprite = new Sprite();
         t.name = "talkTab_" + n;
         t.buttonMode = true;
         t.mouseChildren = false;
         var label:TextField = RUI.text(12, on ? 0xFFFFFF : RUI.BLUE, true);
         label.text = n.length > 5 ? n.substr(0, 5) + "…" : n;
         label.x = 8;
         label.y = 3;
         var w:int = label.width + 16;
         t.graphics.beginFill(on ? 0x2E86D6 : 0xDDEFFF);
         t.graphics.drawRoundRect(0, 0, w, 24, 12, 12);
         t.graphics.endFill();
         if (TalkService.instance.unreadOf(n) > 0)
         {
            t.graphics.beginFill(0xE8341B);
            t.graphics.drawCircle(w - 3, 3, 4);
            t.graphics.endFill();
         }
         t.addChild(label);
         t.x = x;
         t.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { open(n); });
         tabs.addChild(t);
         return w;
      }

      private function drawLog():void
      {
         var me:String = SocketClient.instance.myUserName;
         var html:String = "";
         for each (var l:Object in TalkService.instance.getMessage(who))
         {
            if (l.note) html += "<font face='SimSun' size='12' color='#8A9AAA'>" + esc(String(l.text)) + "</font><br>";
            else html += "<font face='SimSun' size='12' color='" + (l.mine ? "#E8641B" : "#1A5FA8") + "'><b>" + esc(String(l.mine ? me : l.from)) + "</b> " + l.at + "</font><br>"
               + "<font face='SimSun' size='13' color='#1A3A5A'>" + esc(String(l.text)) + "</font><br>";
         }
         log.htmlText = html || "<font face='SimSun' size='12' color='#8A9AAA'>和" + esc(who) + "说点什么吧。</font>";
         log.scrollV = log.maxScrollV;
      }

      private static function esc(s:String):String
      {
         return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
      }

      public function close():void
      {
         if (stage) stage.removeEventListener(MouseEvent.MOUSE_UP, stopDragging);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
