package mmo.control
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import mmo.framework.comm.SocketClient;
   import mmo.socketserver.data.User;

   /**
    * REBUILT. What was said in the scene (the △ over the chat box): the last
    * lines SceneTalkService keeps (getTalkMessageRec), newest at the bottom.
    */
   public class TalkHistoryPanel extends Sprite
   {
      public function TalkHistoryPanel(record:Array)
      {
         super();
         BarSkin.panel(graphics, 0, 0, 280, 170, 14);
         var title:TextField = BarSkin.label("聊天记录", 12, 0x14467A, 0xFFFFFFFF, true);
         title.x = 12;
         title.y = 6;
         addChild(title);
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", 12, 0x1E3F66, null, null, null, null, null, null, null, null, null, 3);
         t.multiline = true;
         t.wordWrap = true;
         t.selectable = false;
         t.x = 10;
         t.y = 26;
         t.width = 260;
         t.height = 136;
         var html:String = "";
         for each (var r:Object in record)
         {
            html += "<font color='#0A62B8'>" + esc(nick(String(r.userName))) + "：</font>" + esc(String(r.message)) + "<br>";
         }
         t.htmlText = html == "" ? "<font color='#5B7C9A'>还没有人说话。</font>" : html;
         t.scrollV = t.maxScrollV;
         addChild(t);
      }

      private static function nick(userName:String):String
      {
         try
         {
            var u:User = SocketClient.instance.activeRoom.getUser(userName) as User;
            var nn:* = u ? u.getVariable("nn") : null;
            if (nn) return String(nn);
         }
         catch (e:Error) {}
         return userName;
      }

      private static function esc(s:String):String
      {
         return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
      }
   }
}
