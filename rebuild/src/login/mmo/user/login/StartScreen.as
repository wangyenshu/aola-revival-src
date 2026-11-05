package mmo.user.login
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Sprite;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import mmo.revival.RUI;

   /**
    * REVIVAL. 进入奥拉星: 单机模式 (the game in this page, the saves in this browser; its 奥拉 are
    * chosen next, RolesScreen) or 联机模式 (a shared server: its address, the 奥拉's name and its
    * password, which registers the name the first time). The page remembers what was written
    * (web/start.js) and starts the game chosen; done(mode, name, pass) then.
    */
   public class StartScreen extends Sprite
   {
      private static const W:int = 440;

      private var done:Function;
      private var mode:String;
      private var names:Object;
      private var panel:Sprite;
      private var bg:Sprite;
      private var inpageBtn:Sprite;
      private var serverBtn:Sprite;
      private var hint:TextField;
      private var serverIn:TextField;
      private var nameIn:TextField;
      private var passIn:TextField;
      private var newNameIn:TextField;
      private var remember:Sprite;
      private var serverPart:Sprite;
      private var renameLink:Sprite;
      private var renamePart:Sprite;
      private var msg:TextField;
      private var go:Sprite;
      private var busy:Boolean;

      public function StartScreen(done:Function)
      {
         super();
         this.done = done;
         var s:Object = StartPage.saved();
         mode = s.mode == "server" ? "server" : "inpage";
         // Each mode's 奥拉: 联机模式's name as written there before (单机模式's come next).
         names = { server: String(s.serverName || "") };
         addChild(StartPage.backdrop());
         panel = new Sprite();
         addChild(panel);

         inpageBtn = modeButton("单机模式", "inpage");
         serverBtn = modeButton("联机模式", "server");
         hint = RUI.text(12, 0x5A7FA3, false, W - 48);
         hint.height = 36;
         hint.x = 24;
         panel.addChild(hint);

         serverPart = new Sprite();
         panel.addChild(serverPart);
         serverIn = field("服务器地址", String(s.server || ""), 0, 64, "start_server");
         nameIn = field("奥拉的名字", names.server, 50, 12, "start_name");
         passIn = field("密码", String(s.pass || ""), 100, 32, "start_pass");
         passIn.displayAsPassword = true;
         remember = StartPage.tick("记住密码", !!s.pass, "startRemember");
         remember.x = 70;
         remember.y = 146;
         serverPart.addChild(remember);
         var check:Sprite = StartPage.link("检查服务器", checkServer, 0x1D6FC1, "startCheck");
         check.x = W - 70 - check.width;
         check.y = 144;
         serverPart.addChild(check);
         renameLink = StartPage.link("改名字", function():void { renamePart.visible = true; renameLink.visible = false; layout(); stage.focus = newNameIn; }, 0x1D6FC1, "startRenameLink");
         renameLink.x = 70;
         renameLink.y = 168;
         serverPart.addChild(renameLink);
         renamePart = new Sprite();
         renamePart.y = 166;
         renamePart.visible = false;
         serverPart.addChild(renamePart);
         var nl:TextField = RUI.text(12, 0x12406F, true);
         nl.text = "新名字";
         nl.x = 70;
         renamePart.addChild(nl);
         newNameIn = RUI.input(300, "", null, 12, "start_newname");
         newNameIn.x = 70;
         newNameIn.y = 18;
         renamePart.addChild(newNameIn);
         var rgo:Sprite = StartPage.link("确定改名", renameNow, 0x1D6FC1, "startRenameGo");
         rgo.x = 70;
         rgo.y = 44;
         renamePart.addChild(rgo);
         var rno:Sprite = StartPage.link("取消", function():void { renamePart.visible = false; renameLink.visible = true; layout(); }, 0x1D6FC1, "startRenameCancel");
         rno.x = W - 70 - rno.width;
         rno.y = 44;
         renamePart.addChild(rno);

         msg = StartPage.centred(12, 0xC8401A, false, W - 48);
         msg.name = "startMsg";
         msg.x = 24;
         msg.height = 36;
         panel.addChild(msg);
         go = RUI.button("进  入", enter, W - 120, 38, 0xFFD56A, 0xF08A12, "startGo");
         go.x = 60;
         panel.addChild(go);

         // Enter: 进入 (in 新名字: 确定改名).
         addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
         {
            e.stopPropagation();
            if (e.keyCode != Keyboard.ENTER) return;
            if (e.target == newNameIn) renameNow();
            else enter();
         });
         show();
      }

      private function modeButton(label:String, m:String):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = m == "server" ? "startServer" : "startInpage";
         b.buttonMode = true;
         b.mouseChildren = false;
         var t:TextField = StartPage.centred(15, 0x2A628F, true, 186);
         t.text = label;
         t.y = 7;
         b.addChild(t);
         b.x = m == "server" ? W / 2 + 4 : 24;
         b.y = 56;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (m == mode || busy) return;
            if (mode == "server") names.server = nameIn.text;
            mode = m;
            show();
         });
         panel.addChild(b);
         return b;
      }

      private function drawMode(b:Sprite, on:Boolean):void
      {
         var m:Matrix = new Matrix();
         m.createGradientBox(186, 34, Math.PI / 2);
         b.graphics.clear();
         b.graphics.lineStyle(2, on ? 0xE07A12 : 0x8CC8EF);
         if (on) b.graphics.beginGradientFill(GradientType.LINEAR, [0xFFD56A, 0xF39A1E], [1, 1], [0, 255], m);
         else b.graphics.beginFill(0xDFF1FD);
         b.graphics.drawRoundRect(0, 0, 186, 34, 22, 22);
         b.graphics.endFill();
         TextField(b.getChildAt(0)).textColor = on ? 0xFFFFFF : 0x2A628F;
      }

      private function field(label:String, value:String, y:int, max:int, name:String):TextField
      {
         var l:TextField = RUI.text(12, 0x12406F, true);
         l.text = label;
         l.x = 70;
         l.y = y;
         serverPart.addChild(l);
         var t:TextField = RUI.input(300, value, null, max, name);
         t.x = 70;
         t.y = y + 18;
         serverPart.addChild(t);
         return t;
      }

      private function show():void
      {
         drawMode(inpageBtn, mode == "inpage");
         drawMode(serverBtn, mode == "server");
         serverPart.visible = mode == "server";
         nameIn.text = String(names.server || "");
         hint.text = mode == "server"
            ? "和别的奥拉一起玩：存档在服务器上。第一次用这个名字登录，就会用这个密码注册。"
            : "一个人玩：游戏在这个页面里运行，存档留在这个浏览器里。";
         say("");
         layout();
      }

      /** Places the parts for the mode and draws the panel around them. */
      private function layout():void
      {
         var y:int = 98;
         hint.y = y;
         y += 40;
         if (mode == "server")
         {
            serverPart.y = y;
            y += renamePart.visible ? 236 : 192;
         }
         msg.y = y;
         y += 34;
         go.y = y;
         y += 56;
         if (bg != null) panel.removeChild(bg);
         bg = RUI.panel(W, y, "进入奥拉星", null);
         var c:DisplayObject = bg.getChildByName("panelClose");
         if (c != null) c.visible = false;
         panel.addChildAt(bg, 0);
         panel.x = (960 - W) / 2;
         panel.y = Math.max(10, (560 - y) / 2);
      }

      public function say(text:String, ok:Boolean = false):void
      {
         msg.textColor = ok ? 0x2A8A2A : 0xC8401A;
         msg.text = text || "";
      }

      /** Back after a login the server refused: the screen as it was, with why. */
      public function again(why:String):void
      {
         busy = false;
         go.alpha = 1;
         visible = true;
         say(why);
      }

      private function checkServer():void
      {
         if (!serverIn.text.replace(/\s/g, "")) { say("请先填写服务器地址。"); return; }
         say("正在连接服务器……", true);
         StartPage.ask("check", { server: serverIn.text }, function(r:Object):void
         {
            if (r.error) say(r.error);
            else say("服务器正常，现在有 " + int(r.online) + " 个奥拉在线。", true);
         });
      }

      private function renameNow():void
      {
         var to:String = trim(newNameIn.text);
         if (!to) { say("请输入新名字。"); return; }
         StartPage.ask("rename", { server: serverIn.text, name: trim(nameIn.text), pass: passIn.text, to: to }, function(r:Object):void
         {
            if (r.error) { say(r.error); return; }
            nameIn.text = names.server = to;
            newNameIn.text = "";
            renamePart.visible = false;
            renameLink.visible = true;
            layout();
            say("名字改好了！", true);
         });
      }

      private function enter():void
      {
         if (busy) return;
         var server:Boolean = mode == "server";
         var name:String = trim(nameIn.text);
         if (server && !trim(serverIn.text)) { say("请填写服务器地址。"); return; }
         if (server && !passIn.text) { say("请输入密码。"); return; }
         if (server && !name) { say("请输入奥拉的名字。"); return; }
         busy = true;
         go.alpha = 0.6;
         say("正在进入……", true);
         StartPage.ask("begin", { mode: mode, server: trim(serverIn.text), name: name, pass: passIn.text, remember: StartPage.ticked(remember) }, function(r:Object):void
         {
            if (r.error) { again(String(r.error)); return; }
            visible = false;
            done(mode, name, server ? passIn.text : "");
         });
      }

      private static function trim(s:String):String
      {
         return String(s || "").replace(/^\s+|\s+$/g, "");
      }
   }
}
