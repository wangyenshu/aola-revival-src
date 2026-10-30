package mmo.play.player
{
   import flash.display.DisplayObjectContainer;
   import flash.events.EventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.data.UserPoint;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.helper.player.DefaultPlayerGenerator;
   import mmo.play.scene.helper.player.IPlayerGenerator;
   import mmo.revival.RLog;
   import mmo.socketserver.data.Room;
   import mmo.socketserver.data.User;

   /**
    * REBUILT. The players of the current room, keyed by user name
    * (playerList[userName]), kept in step with the original 2013
    * SocketClient: users entering and leaving, positions in the "pt" user
    * variable, avatar changes. A scene can build its own players by returning
    * a generator from getPlayerGenerator().
    */
   public class PlayerManager extends EventDispatcher
   {
      private static var _instance:PlayerManager;

      private var _myPlayer:PlayerBase;
      private var _playerList:Object = {};
      private var layer:DisplayObjectContainer;
      private var generator:IPlayerGenerator;
      private var _visible:Boolean = true;
      private var listening:Boolean;

      public static function getInstance():PlayerManager
      {
         if (_instance == null) _instance = new PlayerManager();
         return _instance;
      }

      public function get myPlayer():PlayerBase
      {
         return _myPlayer;
      }

      public function get playerList():Object
      {
         return _playerList;
      }

      public function get playeresVisible():Boolean
      {
         return _visible;
      }

      public function set playeresVisible(v:Boolean):void
      {
         _visible = v;
         for each (var p:PlayerBase in _playerList)
         {
            if (p != _myPlayer) p.visible = v;
         }
      }

      /** Called by SceneManager once the room is joined. */
      public function populate(room:Room, container:DisplayObjectContainer, myX:int, myY:int, gen:IPlayerGenerator = null):void
      {
         listen();
         clear();
         layer = container;
         generator = gen || new DefaultPlayerGenerator();
         var sc:SocketClient = SocketClient.instance;
         var me:String = sc.myUserName;
         for each (var u:User in room.getUserList())
         {
            if (u == null) continue;
            if (u.getName() == me)
            {
               add(u, myX, myY);
            }
            else
            {
               var pt:UserPoint = UserPoint.getUserPoint(u);
               add(u, pt ? pt.x : myX, pt ? pt.y : myY);
            }
         }
         if (_myPlayer == null)
         {
            RLog.log("players: I am not in the user list of " + room.getName() + "; adding myself");
            add(null, myX, myY, me);
         }
         sc.setUserInitLocation(myX, myY);
      }

      private function add(u:User, x:int, y:int, nameIfNoUser:String = null):PlayerBase
      {
         var name:String = u ? u.getName() : nameIfNoUser;
         var p:PlayerBase;
         try
         {
            p = generator.generatePlayer(name, u, x, y);
         }
         catch (err:Error)
         {
            RLog.error("players: generatePlayer " + name, err);
            p = new DefaultPlayerGenerator().generatePlayer(name, u, x, y);
         }
         if (name == SocketClient.instance.myUserName) _myPlayer = p;
         else p.visible = _visible;
         _playerList[name] = p;
         if (layer) layer.addChild(p);
         dispatchEvent(new PlayerManagerEvent(PlayerManagerEvent.ENTER_ROOM, name, p));
         RLog.log("players: + " + name + " at " + p.x + "," + p.y + (p == _myPlayer ? " (me)" : "") + " layer=" + (layer ? layer.name : null) + " bounds=" + p.getBounds(p));
         return p;
      }

      public function getPlayer(userName:String):PlayerBase
      {
         return _playerList[userName] as PlayerBase;
      }

      public function deletePlayer(p:PlayerBase):void
      {
         if (p == null) return;
         delete _playerList[p.getName()];
         dispatchEvent(new PlayerManagerEvent(PlayerManagerEvent.LEAVE_ROOM, p.getName(), p));
         p.dispose();
      }

      public function clear():void
      {
         for each (var p:PlayerBase in _playerList)
         {
            p.dispose();
         }
         _playerList = {};
         _myPlayer = null;
      }

      /** Keeps players sorted by y so nearer ones are drawn in front. */
      public function sortDepths():void
      {
         if (layer == null) return;
         var list:Array = [];
         for (var i:int = 0; i < layer.numChildren; i++) list.push(layer.getChildAt(i));
         list.sortOn("y", Array.NUMERIC);
         for (i = 0; i < list.length; i++)
         {
            if (layer.getChildIndex(list[i]) != i) layer.setChildIndex(list[i], i);
         }
      }

      private function listen():void
      {
         if (listening) return;
         listening = true;
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener(SocketClientEvent.onUserEnterRoom, onEnter);
         sc.addEventListener(SocketClientEvent.onUserLeaveRoom, onLeave);
         sc.addEventListener(SocketClientEvent.onInitUserPosition, onPoint);
         sc.addEventListener(SocketClientEvent.onUserMove, onPoint);
         sc.addEventListener(SocketClientEvent.onUserJump, onPoint);
         sc.addEventListener(SocketClientEvent.onUserAvatarChange, onAvatar);
         sc.addEventListener(SocketClientEvent.onAction, onAction);
      }

      /** Someone else's "[Action]" (sitting …): play it on their avatar. */
      private function onAction(e:SocketClientEvent):void
      {
         var u:User = e.params.sender as User;
         var p:Player = u ? _playerList[u.getName()] as Player : null;
         if (p == null || p == _myPlayer || e.params.action == null) return;
         p.stop();
         p.action(String(e.params.action));
      }

      private function onEnter(e:SocketClientEvent):void
      {
         var u:User = e.params.user as User;
         if (u == null || _playerList[u.getName()] != null || layer == null) return;
         var pt:UserPoint = UserPoint.getUserPoint(u);
         add(u, pt ? pt.x : 480, pt ? pt.y : 400);
      }

      private function onLeave(e:SocketClientEvent):void
      {
         var name:String = e.params.userName;
         if (name == null && e.params.user is User) name = User(e.params.user).getName();
         deletePlayer(_playerList[name] as PlayerBase);
      }

      private function onPoint(e:SocketClientEvent):void
      {
         var u:User = e.params.user as User;
         var pt:UserPoint = e.params.point as UserPoint;
         if (u == null || pt == null) return;
         var p:PlayerBase = _playerList[u.getName()] as PlayerBase;
         if (p == null || p == _myPlayer) return;
         if (e.type == SocketClientEvent.onUserMove) p.moveTo(pt.x, pt.y, pt.walkSpeed);
         else p.jumpTo(pt.x, pt.y);
      }

      private function onAvatar(e:SocketClientEvent):void
      {
         var u:User = e.params.user as User;
         var p:Player = u ? _playerList[u.getName()] as Player : null;
         if (p) p.setAvatar(e.params.avatar != null ? e.params.avatar : u.getVariable("avatar"));
      }
   }
}
