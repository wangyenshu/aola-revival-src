package mmo.user.login
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.KeyboardEvent;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import mmo.revival.RUI;

   /**
    * REVIVAL. 注册 (联机模式, from the start screen's 注册): a new 奥拉 of a shared server, its
    * address, the name and the password written twice. The server makes it (web/start.js
    * "register": /__api/register); 登录 does not sign a name up. done({server, name, pass}) once
    * it is made, back() on 返回.
    */
   public class RegisterScreen extends Sprite
   {
      private static const W:int = 440;
      private static const PASS_MIN:int = 6;
      private static const PASS_MAX:int = 32;

      private var done:Function;
      private var back:Function;
      private var panel:Sprite;
      private var serverIn:TextField;
      private var nameIn:TextField;
      private var passIn:TextField;
      private var pass2In:TextField;
      private var msg:TextField;
      private var go:Sprite;
      private var busy:Boolean;

      public function RegisterScreen(server:String, done:Function, back:Function)
      {
         super();
         this.done = done;
         this.back = back;
         addChild(StartPage.backdrop());
         panel = new Sprite();
         addChild(panel);
         var part:Sprite = new Sprite();
         part.y = 70;
         panel.addChild(part);
         serverIn = field(part, "服务器地址", server, 0, 64, "reg_server");
         nameIn = field(part, "奥拉的名字", "", 50, 12, "reg_name");
         passIn = field(part, "密码", "", 100, PASS_MAX, "reg_pass");
         passIn.displayAsPassword = true;
         pass2In = field(part, "再输一次密码", "", 150, PASS_MAX, "reg_pass2");
         pass2In.displayAsPassword = true;
         msg = StartPage.centred(12, 0xC8401A, false, W - 48);
         msg.name = "regMsg";
         msg.x = 24;
         msg.y = 270;
         msg.height = 36;
         panel.addChild(msg);
         var ret:Sprite = RUI.button("返  回", function():void { if (!busy) back(); }, 120, 38, 0x8FE3FF, 0x1E8FE0, "regBack");
         ret.x = 60;
         ret.y = 304;
         panel.addChild(ret);
         go = RUI.button("注  册", submit, 180, 38, 0xFFD56A, 0xF08A12, "regGo");
         go.x = W - 60 - 180;
         go.y = 304;
         panel.addChild(go);
         var bg:Sprite = RUI.panel(W, 360, "注册奥拉", null);
         var c:DisplayObject = bg.getChildByName("panelClose");
         if (c != null) c.visible = false;
         panel.addChildAt(bg, 0);
         panel.x = (960 - W) / 2;
         panel.y = (560 - 360) / 2;

         // Enter: 注册; Esc: 返回. Kept here (the start screen under it has its own).
         addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
         {
            e.stopPropagation();
            if (e.keyCode == Keyboard.ENTER) submit();
            else if (e.keyCode == Keyboard.ESCAPE && !busy) back();
         });
      }

      /** The first field to write in (the address when there is none yet). */
      public function focus():void
      {
         if (stage != null) stage.focus = trim(serverIn.text) ? nameIn : serverIn;
      }

      private function field(part:Sprite, label:String, value:String, y:int, max:int, name:String):TextField
      {
         var l:TextField = RUI.text(12, 0x12406F, true);
         l.text = label;
         l.x = 70;
         l.y = y;
         part.addChild(l);
         var t:TextField = RUI.input(300, value, null, max, name);
         t.x = 70;
         t.y = y + 18;
         part.addChild(t);
         return t;
      }

      private function say(text:String, ok:Boolean = false):void
      {
         msg.textColor = ok ? 0x2A8A2A : 0xC8401A;
         msg.text = text || "";
      }

      private function submit():void
      {
         if (busy) return;
         var server:String = trim(serverIn.text);
         var name:String = trim(nameIn.text);
         var pass:String = passIn.text;
         if (!server) { say("请填写服务器地址。"); return; }
         if (!name) { say("请输入奥拉的名字。"); return; }
         if (pass.length < PASS_MIN) { say("密码最少" + PASS_MIN + "个字。"); return; }
         if (pass != pass2In.text) { say("两次输入的密码不一样。"); return; }
         busy = true;
         go.alpha = 0.6;
         say("正在注册……", true);
         StartPage.ask("register", { server: server, name: name, pass: pass }, function(r:Object):void
         {
            busy = false;
            go.alpha = 1;
            if (r.error) { say(String(r.error)); return; }
            done({ server: server, name: name, pass: pass });
         });
      }

      private static function trim(s:String):String
      {
         return String(s || "").replace(/^\s+|\s+$/g, "");
      }
   }
}
