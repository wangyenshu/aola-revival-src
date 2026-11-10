package mmo.user.login
{
   import mmo.common.DateUtil;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.geom.Rectangle;
   import flash.events.Event;
   import flash.external.ExternalInterface;
   import flash.net.SharedObject;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import mmo.SSLEvent;
   import mmo.ServerClient;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.loader.LoaderFacade;
   import mmo.revival.RLog;

   /**
    * REBUILT. The January 2013 user/login.swf (v1301301) did not survive.
    *
    * This replacement keeps the original hand-off: it creates the socket
    * ServerClient, logs in to the zone, fills mmo.common.user.UserInfo and calls
    * LoaderFacade.loadPlay(), exactly where the original continued. Who plays: the
    * revival's screens (StartScreen: 单机 or 联机, and on a shared server the 奥拉's name
    * and password; RolesScreen: 单机模式's 选择奥拉), or the 奥拉 the page already chose
    * (web/boot.js aolaRevivalAccount: tests, a game the page came back to); without a
    * page, the name kept in a SharedObject. A login refused goes back to the screen.
    */
   public class Main extends Sprite
   {
      public static const SERVER_HOST:String = "127.0.0.1";
      public static const SERVER_PORT:int = 9339;
      public static const ZONE:String = "aola";

      private var status:TextField;
      private var start:StartScreen;
      private var roles:RolesScreen;

      public function Main()
      {
         super();
         addEventListener(Event.ADDED_TO_STAGE, onAdded);
      }

      private function onAdded(e:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE, onAdded);
         graphics.beginFill(0x0B1B3A);
         graphics.drawRect(0, 0, 960, 560);
         graphics.endFill();
         status = new TextField();
         status.defaultTextFormat = new TextFormat("SimSun", 14, 0xFFFFFF, true);
         status.width = 960;
         status.y = 500;
         status.selectable = false;
         addChild(status);
         say("正在连接奥拉星……");
         if (ServerClient.instance == null)
         {
            new ServerClient();
         }
         RLog.log("login: connecting to", SERVER_HOST + ":" + SERVER_PORT, "zone", ZONE);
         installTestHook();
         connect();
      }

      /** The page's 奥拉, or the start screen when the page leaves it to the player. */
      private function connect():void
      {
         var acc:Object = pageAccount();
         if (acc != null && acc.choose)
         {
            say("");
            start = new StartScreen(function(mode:String, name:String, pass:String):void
            {
               if (mode == "server") login(name, pass);
               else if (roles != null) roles.again("");
               else addChild(roles = new RolesScreen(function(n:String):void { login(n, ""); }, function():void
               {
                  // 返回: the start screen again, for 联机模式 or 单机模式.
                  if (roles != null && roles.parent != null) roles.parent.removeChild(roles);
                  roles = null;
                  start.again("");
               }));
            });
            addChild(start);
            return;
         }
         login(acc ? String(acc.name) : localName(), acc && acc.pass ? String(acc.pass) : "");
      }

      private function login(name:String, pass:String):void
      {
         try
         {
            say("正在连接奥拉星……");
            ServerClient.instance.addEventListener(SSLEvent.onLogin, onLogin);
            ServerClient.instance.login(SERVER_HOST, SERVER_PORT, ZONE, name, pass);
         }
         catch (err:Error)
         {
            RLog.error("login.connect", err);
            refused("连接失败：" + err.message);
         }
      }

      /** A login that did not go through: back to the screen it came from, else the reason. */
      private function refused(why:String):void
      {
         // The next login connects again (to another server, perhaps).
         try { ServerClient.instance.socketServerClient.disconnect(); } catch (e:Error) {}
         if (roles != null) { say(""); roles.again(why); }
         else if (start != null) { say(""); start.again(why); }
         else say(why);
      }

      /**
       * The 奥拉 the page's start screen chose (web/boot.js aolaRevivalAccount: {name, pass}): a
       * name for the one-player page too, and on a shared server its password. null without one.
       */
      private static function pageAccount():Object
      {
         try
         {
            if (!ExternalInterface.available) return null;
            var a:Object = ExternalInterface.call("aolaRevivalAccount");
            return a != null && (a.name || a.choose) ? a : null;
         }
         catch (err:Error) {}
         return null;
      }

      private function localName():String
      {
         var name:String = "小奥拉";
         try
         {
            var so:SharedObject = SharedObject.getLocal("aolaRevivalPlayer", "/");
            if (so.data.name)
            {
               name = so.data.name;
            }
            else
            {
               so.data.name = name;
               so.flush();
            }
         }
         catch (err:Error)
         {
         }
         return name;
      }

      private function onLogin(e:SSLEvent):void
      {
         try
         {
            enter(e.params);
         }
         catch (err:Error)
         {
            RLog.error("login.onLogin", err);
            say("进入失败：" + err.message);
         }
      }

      private function enter(p:Object):void
      {
         RLog.log("login: reply success=" + p.success, "name=" + p.name, "error=" + p.error);
         ServerClient.instance.removeEventListener(SSLEvent.onLogin, onLogin);
         if (!p.success)
         {
            refused("登录失败：" + p.error);
            return;
         }
         // The server's clock (logOK lastLoginTime) for DateUtil.getServerTime, which
         // era modules read for dates and hours.
         if (!isNaN(ServerClient.instance.lastLoginTime) && ServerClient.instance.lastLoginTime > 0)
            DateUtil.init(ServerClient.instance.lastLoginTime);
         UserInfo.userId = ServerClient.instance.socketServerClient.myUserId;
         UserInfo.userName = p.name;
         UserInfo.isGuest = false;
         LoaderFacade.userName = p.name;
         SocketClient.instance.init();
         // 晶币: the bag and shops read UserInfo.score, filled by ScoreManager.getTotalScore.
         SocketClient.instance.getTotalScore(UserInfo.userId);
         say("正在进入奥拉星……");
         RLog.log("login: user #" + UserInfo.userId, "-> LoaderFacade.loadPlay()");
         LoaderFacade.loadPlay();
      }

      /**
       * The automated walk-throughs' hook while the login is up (tests/e2e; the control module's
       * replaces it in the game): where a shown object of that name is, a text field's text.
       */
      private function installTestHook():void
      {
         try
         {
            if (!ExternalInterface.available) return;
            ExternalInterface.addCallback("revival", function(cmd:String, arg:String = null):String
            {
               var d:DisplayObject = stage ? find(stage, String(arg)) : null;
               if (cmd == "where")
               {
                  if (d == null) return "none";
                  var r:Rectangle = d.getBounds(stage);
                  return int(r.x + r.width / 2) + "," + int(r.y + r.height / 2);
               }
               if (cmd == "text") return d is TextField ? TextField(d).text : "none";
               return cmd == "scene" || cmd == "busy" ? "" : "none";
            });
         }
         catch (e:Error) {}
      }

      private static function find(c:DisplayObjectContainer, name:String):DisplayObject
      {
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var d:DisplayObject = c.getChildAt(i);
            if (!d.visible) continue;
            if (d.name == name) return d;
            if (d is DisplayObjectContainer)
            {
               var f:DisplayObject = find(DisplayObjectContainer(d), name);
               if (f != null) return f;
            }
         }
         return null;
      }

      private function say(text:String):void
      {
         status.text = text;
         status.x = (960 - status.textWidth) / 2;
      }
   }
}
