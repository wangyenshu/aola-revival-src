package mmo.tasknpc
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT NPC conversation panel (the 2013 one was in the lost
    * task/tasknpc.swf; drawn here). It follows the 2013 conversation XML:
    *
    *   <config><context npcId iconId str action taskId starterId>
    *              <choice str action taskId starterId type> nested <context>s </choice>
    *           </context> ...more contexts shown one after another... </config>
    *
    * A context with no choices continues to the next context (click), or
    * closes after the last one. A choice with nested contexts goes on to them;
    * a choice without them closes the panel. Choice and context actions are
    * sent as TaskEvent.ON_TASK_ACTION {action}, task steps as ON_CLIENT_STEP /
    * ON_CLIENT_START, the end as ON_END_NPC_TALK {npcId}, as in 2013.
    */
   public class NpcTalkPanel extends Sprite
   {
      private static const W:int = 660;
      private static const H:int = 168;
      private static var current:NpcTalkPanel;

      private var blocker:Sprite;
      private var bg:Shape;
      private var boxH:Number = 0;
      private var box:Sprite;
      private var portrait:Sprite;
      private var nameField:TextField;
      private var textField:TextField;
      private var choiceBox:Sprite;
      private var hint:TextField;
      private var nodes:XMLList;
      private var index:int;
      private var npcId:int;
      private var iconId:int;
      private var shownIconKey:String;

      public static function get isOpen():Boolean
      {
         return current != null;
      }

      public static function show(xml:XML, npcId:int, iconId:int = 1):void
      {
         closeCurrent();
         if (xml == null) return;
         if (xml.name() != null && xml.name().toString() != "config")
         {
            var c:XMLList = xml..config;
            if (c.length() > 0) xml = c[0];
         }
         current = new NpcTalkPanel(npcId, iconId);
         current.start(xml.context);
      }

      /** Test hook (tests/e2e, through the control's "talk" command): the open conversation. */
      public static function debugText():String
      {
         if (current == null || current.node == null) return "";
         var n:XML = current.node;
         var out:String = TaskNpcService.npcName(current.npcId) + ": " + String(n.@str);
         var i:int = 0;
         for each (var c:XML in n.choice) out += " | [" + (i++) + "] " + String(c.@str);
         return out;
      }

      /** Test hook: pick choice i, or go on when the words have no choices. */
      public static function debugChoose(i:int):String
      {
         if (current == null || current.node == null) return "none";
         var choices:XMLList = current.node.choice;
         if (choices.length() > 0) current.onChoice(choices[Math.min(i, choices.length() - 1)]);
         else current.onBoxClick(null);
         return debugText() || "closed";
      }

      public static function closeCurrent():void
      {
         if (current != null) current.remove();
         current = null;
      }

      public function NpcTalkPanel(npcId:int, iconId:int)
      {
         super();
         this.npcId = npcId;
         this.iconId = iconId;
         build();
         // Under whatever is already open on top (a 购买成功 message box …),
         // so that can still be closed.
         LayerManager.getBaseTop().addChildAt(this, 0);
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_START_NPC_TALK, {npcId: npcId}));
      }

      private function build():void
      {
         blocker = new Sprite();
         blocker.graphics.beginFill(0x000000, 0.01);
         blocker.graphics.drawRect(0, 0, 960, 560);
         blocker.graphics.endFill();
         blocker.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         addChild(blocker);

         box = new Sprite();
         box.x = (960 - W) / 2;
         box.y = 560 - H - 14;
         bg = new Shape();
         box.addChild(bg);
         box.filters = [new DropShadowFilter(3, 90, 0x000000, 0.4, 8, 8)];

         portrait = new Sprite();
         portrait.x = 18;
         portrait.y = H - 12;
         box.addChild(portrait);

         nameField = field(15, 0x1A5FA8, true);
         nameField.x = 150;
         nameField.y = 12;
         box.addChild(nameField);

         textField = field(14, 0x333333, false);
         textField.x = 150;
         textField.y = 36;
         textField.width = W - 170;
         textField.wordWrap = true;
         textField.multiline = true;
         box.addChild(textField);

         choiceBox = new Sprite();
         choiceBox.x = 160;
         box.addChild(choiceBox);

         hint = field(12, 0x3A8FD9, true);
         hint.x = W - 70;
         hint.y = H - 26;
         box.addChild(hint);

         var close:Sprite = new Sprite();
         close.name = "talkClose";
         close.buttonMode = true;
         close.graphics.lineStyle(2, 0xFFFFFF);
         close.graphics.beginFill(0x3A8FD9);
         close.graphics.drawCircle(0, 0, 11);
         close.graphics.endFill();
         close.graphics.lineStyle(2.5, 0xFFFFFF);
         close.graphics.moveTo(-4, -4); close.graphics.lineTo(4, 4);
         close.graphics.moveTo(4, -4); close.graphics.lineTo(-4, 4);
         close.x = W - 8;
         close.y = 8;
         close.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); finish(null); });
         box.addChild(close);

         redrawBox(H);
         box.addEventListener(MouseEvent.CLICK, onBoxClick);
         addChild(box);
      }

      private function redrawBox(h:Number):void
      {
         if (h == boxH) return;
         boxH = h;
         var m:Matrix = new Matrix();
         m.createGradientBox(W, h, Math.PI / 2);
         bg.graphics.clear();
         bg.graphics.lineStyle(3, 0x3A8FD9);
         bg.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xE4F4FF], [0.97, 0.97], [0, 255], m);
         bg.graphics.drawRoundRect(0, 0, W, h, 24, 24);
         bg.graphics.endFill();
         bg.graphics.lineStyle(1, 0xFFFFFF, 0.9);
         bg.graphics.drawRoundRect(4, 4, W - 8, h - 8, 20, 20);
         box.y = 560 - h - 14;
         portrait.y = h - 12;
         hint.y = h - 26;
      }

      private static function field(size:int, color:uint, bold:Boolean):TextField
      {
         var tf:TextField = new TextField();
         tf.defaultTextFormat = new TextFormat("SimSun", size, color, bold, null, null, null, null, null, null, null, null, 4);
         tf.autoSize = TextFieldAutoSize.LEFT;
         tf.selectable = false;
         return tf;
      }

      private function start(list:XMLList):void
      {
         nodes = list;
         index = 0;
         if (nodes == null || nodes.length() == 0)
         {
            finish(null);
            return;
         }
         showNode();
      }

      private function get node():XML
      {
         return nodes[index];
      }

      private function showNode():void
      {
         var n:XML = node;
         if (n == null) { finish(null); return; }
         if (String(n.@str) == "")
         {
            // A context without words only carries an action (2013: isNoTalk).
            var a:String = String(n.@action);
            finish(null);
            if (a) action(a);
            return;
         }
         if (String(n.@npcId) != "") npcId = int(n.@npcId);
         if (String(n.@iconId) != "") iconId = int(n.@iconId);
         nameField.text = npcId > 0 ? TaskNpcService.npcName(npcId) : "";
         textField.htmlText = "<font face='SimSun'>" + personalise(String(n.@str)) + "</font>";
         showPortrait();
         while (choiceBox.numChildren) choiceBox.removeChildAt(0);
         var y:Number = textField.y + textField.height + 6;
         choiceBox.y = y;
         var cy:Number = 0;
         for each (var c:XML in n.choice)
         {
            var b:Sprite = choiceButton(c);
            b.y = cy;
            cy += 22;
            choiceBox.addChild(b);
         }
         // Grow upwards when the words and choices need more room than the panel.
         var need:Number = Math.max(H, choiceBox.y + cy + 16);
         redrawBox(need);
         var hasChoices:Boolean = n.choice.length() > 0;
         hint.text = hasChoices ? "" : (index < nodes.length() - 1 ? "继续 ▶" : "离开 ✖");
      }

      private function choiceButton(c:XML):Sprite
      {
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         var tf:TextField = field(14, 0x0D6EC6, true);
         tf.htmlText = "<font face='SimSun'>◆ <u>" + personalise(String(c.@str)) + "</u></font>";
         b.addChild(tf);
         b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { tf.textColor = 0xFF6600; });
         b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tf.textColor = 0x0D6EC6; });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            onChoice(c);
         });
         return b;
      }

      private function onBoxClick(e:MouseEvent):void
      {
         var n:XML = node;
         if (n == null) return;
         var choices:XMLList = n.choice;
         if (choices.length() == 1) { onChoice(choices[0]); return; }
         if (choices.length() > 1) return;
         if (index < nodes.length() - 1)
         {
            fireNode(n);
            index++;
            showNode();
         }
         else
         {
            finish(n);
         }
      }

      private function onChoice(c:XML):void
      {
         var nested:XMLList = c.context;
         if (nested.length() > 0)
         {
            if (String(nested[0].@str) == "")
            {
               var silent:String = String(nested[0].@action);
               finish(null);
               if (silent) action(silent);
               fireChoice(c);
               return;
            }
            fireChoice(c);
            start(nested);
            return;
         }
         finish(node);
         fireChoice(c);
      }

      private function fireChoice(c:XML):void
      {
         var a:String = String(c.@action);
         if (a) action(a);
         goScene(String(c.@nextScene));
         if (String(c.@starterId) != "") TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_START, {taskId: int(c.@starterId)}));
         if (String(c.@taskId) != "") TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP, {taskId: int(c.@taskId)}));
      }

      private function fireNode(n:XML):void
      {
         if (n == null) return;
         var a:String = String(n.@action);
         if (a) action(a);
         goScene(String(n.@nextScene));
         if (String(n.@starterId) != "") TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_START, {taskId: int(n.@starterId)}));
         if (String(n.@taskId) != "") TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP, {taskId: int(n.@taskId)}));
      }

      /** nextScene="…" on a choice or context: go there once the panel is closed (as the later task configs do). */
      private static function goScene(name:String):void
      {
         if (name == null || name == "") return;
         var t:Timer = new Timer(50, 1);
         t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { SceneManager.getInstance().loadScene(name); });
         t.start();
      }

      private static function action(a:String):void
      {
         RLog.log("tasknpc: action " + a);
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_TASK_ACTION, {action: a}));
      }

      /** Close; the shown context's own action follows (2013 NpcTalkPanel.handleOperation). */
      private function finish(last:XML):void
      {
         var id:int = npcId;
         if (current == this) current = null;
         remove();
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_END_NPC_TALK, {npcId: id}));
         fireNode(last);
      }

      private function remove():void
      {
         if (parent) parent.removeChild(this);
      }

      private function personalise(s:String):String
      {
         var me:Object = PlayerManager.getInstance().myPlayer;
         var nick:String = "小奥拉";
         try { if (me && me.hasOwnProperty("nickName")) nick = me.nickName; } catch (e:Error) {}
         s = s.split("#username#").join("<font color='#66CC00'>" + nick + "</font>");
         var d:Date = new Date();
         s = s.split("#systime#").join(d.fullYear + "年" + (d.month + 1) + "月" + d.date + "日");
         return s;
      }

      /** NpcIcon<id>_<icon> of tasknpc/npc<id>.swf: the half-length picture of the speaker. */
      private function showPortrait():void
      {
         var key:String = npcId + "_" + iconId;
         if (key == shownIconKey) return;
         shownIconKey = key;
         while (portrait.numChildren) portrait.removeChildAt(0);
         if (npcId <= 0) return;
         var cls:String = "mmo.tasknpc.NpcIcon" + npcId + "_" + iconId;
         var target:Sprite = portrait;
         var put:Function = function(d:DisplayObject):void
         {
            if (shownIconKey != key || !ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            try
            {
               var C:Class = getDefinitionByName(cls) as Class;
               var pic:DisplayObject = new C() as DisplayObject;
               var b:Object = pic.getBounds(pic);
               var s:Number = Math.min(1, 150 / Math.max(1, b.height), 128 / Math.max(1, b.width));
               pic.scaleX = pic.scaleY = s;
               pic.x = -b.left * s;
               pic.y = -b.bottom * s;
               target.addChild(pic);
            }
            catch (e:Error) {}
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put(null);
         else ResScheduler.getResource("tasknpc/npc" + npcId, put, cls, function(e:*):void {});
      }
   }
}
