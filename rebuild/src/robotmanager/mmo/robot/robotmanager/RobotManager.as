package mmo.robot.robotmanager
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.robot.IRobotService;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.strategy.StandBehindStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;
   import mmo.socketserver.data.User;

   /**
    * REBUILT init/robotmanager: the HELLO in scenes. The January 2013 module
    * (version 130103) is lost; the later copy (2025) does the same on later
    * services. As there, a player whose HELLO follows him has the user
    * variable "r" ("type,level,clothes,hellobaby"); every such player in the
    * room gets a RobotAvatar standing behind him (StandBehindStrategy), gone
    * when the variable goes or he leaves, hidden while he is hidden. On the
    * first scene the HELLO is asked for (RobotClient.getRobot; on each scene
    * until there is one) and, when it follows, told to follow
    * (RobotClient.follow), which sets the variable for this visit.
    *
    * Not rebuilt: the HELLO's free talk and task hints of the later copy
    * (RobotTalkHelper, RobotRecommendMgr), its stay in the home
    * (robot/robotdecorator), the HELLO baby.
    */
   public class RobotManager extends Sprite implements IInitService
   {
      private static const FOLLOW_KEY:String = "r";
      private static var _instance:RobotManager;

      /** userName -> RobotAvatar */
      public static var robots:Object = {};

      private var started:Boolean;
      private var known:Boolean;

      public static function get instance():RobotManager
      {
         if (_instance == null) _instance = new RobotManager();
         return _instance;
      }

      public function init():void
      {
         if (started) return;
         started = true;
         var pm:PlayerManager = PlayerManager.getInstance();
         pm.addEventListener(PlayerManagerEvent.ENTER_ROOM, onPlayerEnterRoom);
         pm.addEventListener(PlayerManagerEvent.LEAVE_ROOM, onPlayerLeaveRoom);
         pm.addEventListener(PlayerManagerEvent.AVATAR_SHOW, onAvatarShow);
         pm.addEventListener(PlayerManagerEvent.AVATAR_HIDE, onAvatarHide);
         SocketClient.instance.addEventListener(SocketClientEvent.onUserVariablesUpdate, onUserVarUpdate);
         SocketClient.instance.addEventListener(RobotClient.cmdGetRobot, onGetRobot);
         SocketClient.instance.addEventListener(RobotClient.cmdAddRobot, onGetRobot);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
         if (SceneManager.getInstance().loadedSceneInfo != null) onSceneInited(null);
         for (var name:String in pm.playerList) fromVariable(name);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /** Asked on each scene until there is a HELLO (a new player gets his in the newbie quest). */
      private function onSceneInited(e:SceneManagerEvent):void
      {
         if (!known) RobotClient.instance.getRobot();
      }

      private function onGetRobot(e:SocketClientEvent):void
      {
         var o:Object = e.params;
         // A HELLO card asks for someone else's (getOtherRobot, {un}): only mine here.
         if (o == null || int(o.has) != 1 || robotService() == null) return;
         known = true;
         robotService().setMyRobot(o);
         if (int(o.fl) == 1 && !robotService().getIsFollow())
         {
            robotService().setIsFollow(true);
            RobotClient.instance.follow();
         }
      }

      private static function robotService():IRobotService
      {
         return ServiceContainer.getService("RobotDataService") as IRobotService;
      }

      private function onPlayerEnterRoom(e:PlayerManagerEvent):void
      {
         if (e.userName == SocketClient.instance.myUserName)
         {
            // A new scene: the HELLOs of the last one went with it.
            var old:Array = [];
            for (var n:String in robots) old.push(n);
            for each (n in old) remove(n);
         }
         fromVariable(e.userName);
      }

      private function userOf(name:String):User
      {
         var sc:SocketClient = SocketClient.instance;
         if (name == sc.myUserName && sc.currentUser != null) return sc.currentUser;
         return sc.activeRoom != null ? sc.activeRoom.getUser(name) : null;
      }

      private function fromVariable(name:String):void
      {
         var u:User = userOf(name);
         if (u == null) return;
         var v:* = u.getVariable(FOLLOW_KEY);
         if (v == undefined || v == null || v == "")
         {
            remove(name);
            return;
         }
         var a:Array = String(v).split(",");
         var leader:IMovable = PlayerManager.getInstance().playerList[name] as IMovable;
         if (leader == null) return;
         var r:RobotAvatar = robots[name] as RobotAvatar;
         if (r != null)
         {
            r.setView(a[2], RobotAvatar.isMember(name));
            return;
         }
         var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null) return;
         r = new RobotAvatar(name);
         r.setView(a[2], RobotAvatar.isMember(name));
         robots[name] = r;
         var layer:DisplayObjectContainer = info.scene.playerLayer;
         layer.addChild(r);
         r.jumpTo(int(Object(leader).x) - 40, int(Object(leader).y) - 30);
         r.setStrategy(new StandBehindStrategy(leader));
         if (leader is PlayerBase) r.visible = PlayerBase(leader).visible;
         if (name == SocketClient.instance.myUserName && robotService() != null) robotService().setRobotFollowingPlayer(r);
         RLog.log("hello: " + name + "'s HELLO follows");
      }

      private function onUserVarUpdate(e:SocketClientEvent):void
      {
         var changed:Object = e.params.changedVars;
         if (changed == null || !changed.hasOwnProperty(FOLLOW_KEY)) return;
         var u:User = e.params.user as User;
         if (u != null) fromVariable(u.getName());
      }

      private function onPlayerLeaveRoom(e:PlayerManagerEvent):void
      {
         remove(e.userName);
      }

      private function onAvatarShow(e:PlayerManagerEvent):void
      {
         var r:RobotAvatar = robots[e.userName] as RobotAvatar;
         if (r) r.visible = true;
      }

      private function onAvatarHide(e:PlayerManagerEvent):void
      {
         var r:RobotAvatar = robots[e.userName] as RobotAvatar;
         if (r) r.visible = false;
      }

      private function remove(name:String):void
      {
         var r:RobotAvatar = robots[name] as RobotAvatar;
         if (r != null) r.dispose();
         delete robots[name];
      }
   }
}
