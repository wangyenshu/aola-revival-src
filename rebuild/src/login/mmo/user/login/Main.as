package mmo.user.login
{
   import mmo.common.DateUtil;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.external.ExternalInterface;
   import flash.net.SharedObject;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.setTimeout;
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
    * LoaderFacade.loadPlay(), exactly where the original continued. The account
    * and password form is the page's (web/boot.js, its start screen: 单机 or 联机, the
    * 奥拉's name and, on a shared server, its password), asked for through
    * ExternalInterface; without one (an old page) the name kept in a SharedObject. In
    * 单机模式 the page shows its 选择奥拉 screen (web/accounts.js) here, after 开始: until
    * one is chosen its answer is {wait: true}, and the login asks again.
    */
   public class Main extends Sprite
   {
      public static const SERVER_HOST:String = "127.0.0.1";
      public static const SERVER_PORT:int = 9339;
      public static const ZONE:String = "aola";

      private var status:TextField;

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
         ServerClient.instance.addEventListener(SSLEvent.onLogin, onLogin);
         RLog.log("login: connecting to", SERVER_HOST + ":" + SERVER_PORT, "zone", ZONE);
         connect();
      }

      /** Logs in as the page's 奥拉; while the page's 选择奥拉 screen is up, asks again a moment later. */
      private function connect():void
      {
         try
         {
            var acc:Object = pageAccount();
            if (acc != null && acc.wait)
            {
               say("请选择一个奥拉……");
               setTimeout(connect, 300);
               return;
            }
            say("正在连接奥拉星……");
            ServerClient.instance.login(SERVER_HOST, SERVER_PORT, ZONE, acc ? String(acc.name) : localName(), acc && acc.pass ? String(acc.pass) : "");
         }
         catch (err:Error)
         {
            RLog.error("login.connect", err);
            say("连接失败：" + err.message);
         }
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
            return a != null && (a.name || a.wait) ? a : null;
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
            say("登录失败：" + p.error);
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

      private function say(text:String):void
      {
         status.text = text;
         status.x = (960 - status.textWidth) / 2;
      }
   }
}
