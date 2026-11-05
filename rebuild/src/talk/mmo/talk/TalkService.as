package mmo.talk
{
   import flash.events.EventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IMessageLayout;
   import mmo.interfaces.ITalk;
   import mmo.interfaces.talk.PrivateTalkEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RNotice;

   /**
    * REBUILT talk/talk (ServiceConfig "TalkService", ITalk): 私聊 between friends. The January 2013
    * module is lost (the later copy needs later libraries). Sent as the 2013 SocketClient does
    * (sendPrivateMessage: BuddyManagerExtension privateMsg {to, msg: "[1]" + text}); a line from
    * a friend comes as onPrivateMsg {from, msg}; a line not delivered is answered privateMsg
    * {res: 0, to, msg}. Lines are kept for this game only, MAX_LINES a friend.
    */
   public class TalkService extends EventDispatcher implements ITalk
   {
      public static const MAX_TEXT:int = 100;
      public static const MAX_LINES:int = 50;
      private static const PREFIX:String = "[1]";

      private static var _instance:TalkService;
      private var started:Boolean;
      /** name -> [{from, text, at, mine, note}] */
      private var lines:Object = {};
      private var unread:Object = {};
      /** Friends talked with, the latest first. */
      private var order:Array = [];

      public static function get instance():TalkService
      {
         if (_instance == null) _instance = new TalkService();
         return _instance;
      }

      public function TalkService()
      {
         super();
      }

      public function start():void
      {
         if (started) return;
         started = true;
         SocketClient.instance.addEventListener(SocketClientEvent.onPrivateMessage, onMessage);
         SocketClient.instance.addEventListener("privateMsg", onAnswer);
      }

      /** Send a line to a friend. */
      public function send(name:String, text:String):void
      {
         text = text.replace(/^\s+|\s+$/g, "").substr(0, MAX_TEXT);
         if (!name || !text) return;
         add(name, {from: SocketClient.instance.myUserName, text: text, mine: true});
         SocketClient.instance.sendPrivateMessage(text, name);
      }

      private function onMessage(e:SocketClientEvent):void
      {
         var from:String = String(e.params.from || "");
         var text:String = String(e.params.msg || "");
         if (text.indexOf(PREFIX) == 0) text = text.substr(PREFIX.length);
         if (!from || !text) return;
         // Counted before it is drawn: the window open on another friend shows the dot on its tab.
         var seen:Boolean = PrivateTalkPanel.showing == from;
         if (!seen) unread[from] = int(unread[from]) + 1;
         add(from, {from: from, text: text});
         if (seen) return;
         var shown:String = text.length > 24 ? text.substr(0, 24) + "…" : text;
         try { RNotice.show(LayerManager.getBaseTop(), "【私聊】" + from + "：" + shown, 4); } catch (err:Error) {}
         dispatchEvent(new PrivateTalkEvent(PrivateTalkEvent.NEW_UNREAD_MSG, from));
      }

      /** A line the server could not deliver: said in that friend's talk. */
      private function onAnswer(e:SocketClientEvent):void
      {
         if (int(e.params.res) == 1 || !e.params.to) return;
         add(String(e.params.to), {text: String(e.params.msg || "没有发出去。"), note: true});
      }

      private function add(name:String, line:Object):void
      {
         var now:Date = new Date();
         line.at = (now.hours < 10 ? "0" : "") + now.hours + ":" + (now.minutes < 10 ? "0" : "") + now.minutes;
         var list:Array = lines[name] as Array;
         if (list == null) lines[name] = list = [];
         list.push(line);
         if (list.length > MAX_LINES) list.shift();
         var i:int = order.indexOf(name);
         if (i >= 0) order.splice(i, 1);
         order.unshift(name);
         PrivateTalkPanel.changed(name);
      }

      public function unreadOf(name:String):int
      {
         return int(unread[name]);
      }

      /** Friends talked with, the latest first. */
      public function partners():Array
      {
         return order.concat();
      }

      /** The panel shows this friend's talk: what came is read. */
      internal function read(name:String):void
      {
         if (!unread[name]) return;
         delete unread[name];
         dispatchEvent(new PrivateTalkEvent(PrivateTalkEvent.UNREAD_MSG_READ, name));
      }

      // ITalk (the 2013 interface).

      public function getMessage(name:String, type:int = 0):Array
      {
         return (lines[name] || []).concat();
      }

      public function hasRegister(name:String, type:int = 0):Boolean
      {
         return PrivateTalkPanel.showing == name;
      }

      public function push(name:String, text:String, type:int):void
      {
         add(name, {from: name, text: text});
      }

      public function showTalkPanel(name:String, type:int = 0):void
      {
         PrivateTalkPanel.show(name);
      }

      public function registerMessageLayout(name:String, type:int, layout:IMessageLayout):void
      {
      }

      public function removeMessageLayout(name:String, type:int):void
      {
      }
   }
}
