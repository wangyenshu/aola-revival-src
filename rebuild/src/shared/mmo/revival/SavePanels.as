package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.KeyboardEvent;
   import flash.external.ExternalInterface;
   import flash.net.FileFilter;
   import flash.net.FileReference;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.ui.Keyboard;
   import flash.utils.ByteArray;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;

   /**
    * REVIVAL (not of 2013). The 工具箱's 导出存档 / 导入存档 and the 信息卡's 改名字 / 改密码, drawn
    * in the game (so they show in fullscreen) with Flash's own dialogs for the files. The data is
    * the page's (web/saves.js): aolaSaves(op, args, id), answered in revivalSaves(id, result).
    */
   public class SavePanels extends Sprite
   {
      private static const W:int = 420;
      private static const NO_PAGE:String = "这个页面不能这样做。";
      private static var current:SavePanels;
      private static var calls:Object = {};
      private static var nextCall:int;
      /** A page call not answered by then: the panel says so and offers its buttons again. */
      private static const WAIT_MS:int = 20000;

      private var box:Sprite;
      private var line:TextField;
      private var said:TextField;
      private var row:Sprite;
      private var inputs:Object = {};
      private var firstInput:TextField;
      private var first:Function;
      private var rowY:int;
      /** The file being saved or read (kept while its dialog is open). */
      private var file:FileReference;
      /** Closed: what was under way does nothing more (no import, no rename after it). */
      private var shut:Boolean;
      /**
       * An import or a rename sent to the page: it cannot be called back (the page ends the game
       * and comes back), so the panel stays till it is answered.
       */
      private var sealed:Boolean;
      /** The buttons to offer again when a page call gets no answer. */
      private var lastButtons:Array = [];

      // ---------------------------------------------------------------- the four panels

      public static function exportSave():void
      {
         var server:Boolean = session().mode == "server";
         var p:SavePanels = open("导出存档", server ? [["pass", "密码", true, 32]] : []);
         var fetch:Function = function():void
         {
            if (server && !p.value("pass")) { p.say("请输入密码。"); return; }
            p.say("正在准备……");
            p.wait(server ? [["确定", fetch]] : [["重试", fetch]]);
            p.ask("export", { pass: p.value("pass") }, false, function(r:Object):void
            {
               if (r.error || !r.text)
               {
                  p.say(r.error || "没有导出。");
                  p.buttons(server ? [["确定", fetch]] : [["重试", fetch]]);
                  return;
               }
               p.say("");
               p.setText("存档准备好了。");
               // A file is saved from a click (the browser's rule); once, till its dialog is done.
               var offer:Array = [["保存文件", function():void
               {
                  p.buttons([]);
                  p.save(String(r.text), String(r.file), function():void { p.buttons(offer); });
               }]];
               p.buttons(offer);
            });
         };
         if (server) p.buttons([["确定", fetch]]);
         else fetch();
      }

      public static function importSave():void
      {
         var s:Object = session();
         var server:Boolean = s.mode == "server";
         var p:SavePanels = open("导入存档", server ? [["pass", "密码", true, 32]] : []);
         var text:String;
         var pass:String;
         var choose:Function;
         var intro:String = "导入的存档会替换" + s.name + "现在的存档。";
         var send:Function = function(role:String):void
         {
            p.say("正在导入……");
            p.wait([["选择文件", choose]]);
            p.ask("import", { text: text, pass: pass, role: role }, true, function(r:Object):void
            {
               if (r.roles is Array)
               {
                  p.setText("选一个奥拉：");
                  p.say("");
                  var list:Array = [];
                  for each (var o:Object in r.roles) list.push([String(o.name), roleButton(send, String(o.key))]);
                  p.buttons(list);
                  return;
               }
               if (r.error)
               {
                  p.setText(intro);
                  p.say("导入失败：" + r.error);
                  p.buttons([["选择文件", choose]]);
                  return;
               }
               p.say("正在重新进入……");
            });
         };
         choose = function():void
         {
            pass = p.value("pass");
            if (server && !pass) { p.say("请输入密码。"); return; }
            p.read(function(t:String):void
            {
               text = t;
               send(null);
            });
         };
         p.setText(intro);
         if (!server) { p.buttons([["选择文件", choose]]); return; }
         p.say("正在连接……");
         p.wait([["选择文件", choose]]);
         p.ask("status", {}, false, function(r:Object):void
         {
            p.say("");
            if (r.imports === false) p.setText("这个服务器关闭了导入存档。");
            else p.buttons([["选择文件", choose]]);
         });
      }

      public static function rename():void
      {
         var s:Object = session();
         var server:Boolean = s.mode == "server";
         var p:SavePanels = open("改名字", server ? [["to", "新名字", false, 12], ["pass", "密码", true, 32]] : [["to", "新名字", false, 12]]);
         var go:Function = function():void
         {
            var to:String = p.value("to").replace(/^\s+|\s+$/g, "");
            if (!to) { p.say("请输入新名字。"); return; }
            if (to == s.name) { p.close(); return; }
            if (server && !p.value("pass")) { p.say("请输入密码。"); return; }
            p.say("正在改名……");
            p.wait([["确定", go]]);
            p.ask("rename", { to: to, pass: p.value("pass") }, true, function(r:Object):void
            {
               if (r.error) { p.say(r.error); p.buttons([["确定", go]]); return; }
               p.say("正在重新进入……");
            });
         };
         p.buttons([["确定", go]]);
      }

      public static function password():void
      {
         if (session().mode != "server")
         {
            open("改密码", []).setText("单机模式的奥拉没有密码。");
            return;
         }
         var p:SavePanels = open("改密码", [["pass", "现在的密码", true, 32], ["to", "新密码", true, 32], ["again", "再输一次新密码", true, 32]]);
         var go:Function = function():void
         {
            if (!p.value("pass")) { p.say("请输入现在的密码。"); return; }
            if (!p.value("to")) { p.say("请输入新密码。"); return; }
            if (p.value("to") != p.value("again")) { p.say("两次输入的新密码不一样。"); return; }
            p.say("正在改……");
            p.wait([["确定", go]]);
            p.ask("password", { pass: p.value("pass"), to: p.value("to") }, false, function(r:Object):void
            {
               p.buttons([["确定", go]]);
               p.say(r.error ? String(r.error) : "改好了。");
            });
         };
         p.buttons([["确定", go]]);
      }

      private static function roleButton(send:Function, key:String):Function
      {
         return function():void { send(key); };
      }

      // ---------------------------------------------------------------- the page

      /** The page's game: {mode: "inpage" | "server", name}. */
      private static function session():Object
      {
         try
         {
            var s:Object = ExternalInterface.available ? ExternalInterface.call("aolaSaves", "session") : null;
            if (s != null) return s;
         }
         catch (e:Error) { RLog.error("saves session", e); }
         return { mode: "", name: "" };
      }

      /**
       * A page call for this panel: then(result) once, unless the panel was closed first; no
       * answer in WAIT_MS, and the panel says so and offers the buttons wait() kept. seal: the
       * panel cannot be closed meanwhile (an import, a rename).
       */
      private function ask(op:String, args:Object, seal:Boolean, then:Function):void
      {
         var me:SavePanels = this;
         var id:String = String(++nextCall);
         var timer:uint;
         if (seal) setSealed(true);
         var done:Function = function(r:Object):void
         {
            clearTimeout(timer);
            delete calls[id];
            if (seal) me.setSealed(false);
            if (!me.shut) then(r || {});
         };
         try
         {
            if (ExternalInterface.available)
            {
               ExternalInterface.addCallback("revivalSaves", answer);
               calls[id] = done;
               timer = setTimeout(function():void
               {
                  if (calls[id] == null) return;
                  delete calls[id];
                  if (seal) me.setSealed(false);
                  if (me.shut) return;
                  me.say("没有回应，请再试一次。");
                  me.buttons(me.lastButtons);
               }, WAIT_MS);
               if (ExternalInterface.call("aolaSaves", op, args, id) === true) return;
               clearTimeout(timer);
               delete calls[id];
            }
         }
         catch (e:Error) { clearTimeout(timer); delete calls[id]; RLog.error("saves " + op, e); }
         done({ error: NO_PAGE });
      }

      private static function answer(id:String, r:Object):void
      {
         var f:Function = calls[id] as Function;
         if (f != null) f(r || {});
      }

      private function setSealed(on:Boolean):void
      {
         sealed = on;
         var c:DisplayObject = box.getChildByName("savesClose");
         if (c != null) c.visible = !on;
      }

      /** Waiting for the page: no buttons meanwhile; these again if it never answers. */
      private function wait(again:Array):void
      {
         buttons([]);
         lastButtons = again;
      }

      // ---------------------------------------------------------------- the panel

      /** inputs: [key, label, password, maxChars]. */
      private static function open(title:String, fields:Array):SavePanels
      {
         if (current != null) current.close(true);
         current = new SavePanels(title, fields);
         ModalDialogManager.getInstance().addModalDialog(current, AlignType.NONE, PanelEffect.NONE, false);
         // Typing (and Enter, its first button) goes to the panel: its first field, or the panel itself.
         if (current.stage != null) current.stage.focus = current.firstInput != null ? current.firstInput : current;
         return current;
      }

      public function SavePanels(title:String, fields:Array)
      {
         super();
         addChild(RUI.dim());
         var h:int = 56 + 44 + fields.length * 48 + 44 + 58 + 6;
         box = RUI.panel(W, h, title, close, "savesClose");
         box.x = (960 - W) / 2;
         box.y = (560 - h) / 2;
         addChild(box);
         line = centred(13, RUI.BLUE, W - 48);
         line.x = 24;
         line.y = 58;
         line.height = 40;
         box.addChild(line);
         var y:int = 100;
         for each (var f:Array in fields)
         {
            var label:TextField = RUI.text(12, RUI.BLUE, true);
            label.text = f[1];
            label.x = 100;
            label.y = y;
            box.addChild(label);
            var t:TextField = RUI.input(220, "", null, int(f[3]) || 32, "saves_" + f[0]);
            t.displayAsPassword = f[2] == true;
            t.x = 100;
            t.y = y + 18;
            box.addChild(t);
            inputs[f[0]] = t;
            if (firstInput == null) firstInput = t;
            y += 48;
         }
         rowY = y + 4;
         row = new Sprite();
         row.y = rowY;
         box.addChild(row);
         said = centred(13, 0x8A3B00, W - 40);
         said.x = 20;
         said.y = rowY + 42;
         said.height = 56;
         box.addChild(said);
         // Keys typed here are the panel's: Enter is its button, Esc closes it.
         addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
         {
            e.stopPropagation();
            if (e.keyCode == Keyboard.ENTER && first != null) first();
            else if (e.keyCode == Keyboard.ESCAPE) close();
         });
      }

      private static function centred(size:int, color:uint, w:int):TextField
      {
         var t:TextField = RUI.text(size, color, true, w);
         var fmt:TextFormat = t.defaultTextFormat;
         fmt.align = TextFormatAlign.CENTER;
         t.defaultTextFormat = fmt;
         return t;
      }

      private function value(key:String):String
      {
         var t:TextField = inputs[key] as TextField;
         return t ? t.text : "";
      }

      private function setText(s:String):void
      {
         line.text = s;
      }

      private function say(s:String):void
      {
         said.text = s;
      }

      /** The buttons: [label, fn]; the first is Enter's. */
      private function buttons(list:Array):void
      {
         while (row.numChildren > 0) row.removeChildAt(0);
         first = null;
         var x:int = 0;
         for (var i:int = 0; i < list.length; i++)
         {
            var w:int = Math.max(90, String(list[i][0]).length * 15 + 30);
            var b:Sprite = RUI.button(list[i][0], list[i][1], w, 30, 0xFFC45A, 0xF07812, "savesButton" + i);
            b.x = x;
            row.addChild(b);
            x += w + 12;
            if (first == null) first = list[i][1];
         }
         row.x = (W - (x - 12)) / 2;
      }

      /** Flash's save dialog for this text; after(), its dialog done (saved, failed or cancelled). */
      private function save(text:String, name:String, after:Function):void
      {
         var f:FileReference = file = new FileReference();
         var end:Function = function(m:String):void
         {
            if (shut || file != f) return;
            if (m != null) say(m);
            after();
         };
         f.addEventListener(Event.COMPLETE, function(e:Event):void { end("已保存。"); });
         f.addEventListener(Event.CANCEL, function(e:Event):void { end(null); });
         f.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { end("没有保存。"); });
         try { f.save(text, name); }
         catch (err:Error) { end("没有保存：" + err.message); }
      }

      /** Flash's open dialog: the chosen file's text to then. */
      private function read(then:Function):void
      {
         file = new FileReference();
         var f:FileReference = file;
         f.addEventListener(Event.SELECT, function(e:Event):void
         {
            if (shut || file != f) return;
            say("正在读取……");
            f.load();
         });
         f.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            if (shut || file != f) return;
            var b:ByteArray = f.data;
            b.position = 0;
            then(b.readUTFBytes(b.length));
         });
         f.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { if (!shut && file == f) say("导入失败：读不了这个文件"); });
         try { f.browse([new FileFilter("奥拉星存档 (*.json)", "*.json")]); }
         catch (err:Error) { say("打不开选文件的窗口：" + err.message); }
      }

      /** force: even while an import or a rename is under way (another panel takes its place). */
      public function close(force:Boolean = false):void
      {
         if (sealed && !force) return;
         shut = true;
         file = null;
         if (current == this) current = null;
         if (parent == null) return;
         if (!ModalDialogManager.getInstance().removeModalDialog(this, PanelEffect.NONE) && parent) parent.removeChild(this);
      }
   }
}
