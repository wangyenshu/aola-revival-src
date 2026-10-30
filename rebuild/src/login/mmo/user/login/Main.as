package mmo.user.login
{
   import mmo.common.DateUtil;
   import flash.display.Sprite;
   import flash.events.Event;
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
    * LoaderFacade.loadPlay(), exactly where the original continued. The account
    * and password form is skipped: an offline copy has one local player, whose
    * name is kept in a SharedObject.
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
         try
         {
            ServerClient.instance.login(SERVER_HOST, SERVER_PORT, ZONE, localName(), "");
         }
         catch (err:Error)
         {
            RLog.error("login.connect", err);
            say("连接失败：" + err.message);
         }
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
