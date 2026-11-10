package mmo.play.player
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.events.EventDispatcher;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
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

      /** A picture of my player (the later engine's; 倒立金字塔's balance puts it on a scale). */
      public function getPlayerBitmap():Bitmap
      {
         var me:PlayerBase = myPlayer;
         var w:int = me ? Math.max(1, int(me.width * 1.3)) : 1, h:int = me ? Math.max(1, int(me.height + 50)) : 1;
         var bd:BitmapData = new BitmapData(w, h, true, 0);
         if (me) bd.draw(me, new Matrix(1, 0, 0, 1, me.width / 2, me.height));
         return new Bitmap(bd);
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
         if (name == SocketClient.instance.myUserName)
         {
            _myPlayer = p;
            standIn(p);
         }
         else p.visible = _visible;
         if (u != null) applyMoving(p, u.getVariable("ms"));
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

      /** A picture of my avatar as it last stood, shown on my new player until its own is drawn. */
      private var lastLook:Object;

      /** My player's avatar (the avatar service's SkinProxyContainer), if it has one. */
      private static function skinOf(p:PlayerBase):DisplayObject
      {
         for (var i:int = 0; p != null && i < p.numChildren; i++)
         {
            var c:DisplayObject = p.getChildAt(i);
            if (getQualifiedClassName(c).indexOf("SkinProxyContainer") >= 0) return c;
         }
         return null;
      }

      /**
       * REVIVAL. A new room builds my player anew, and the avatar service draws its avatar a
       * moment later (frames after the room is shown): the player stood as a bare name, then
       * appeared. A picture of the avatar taken as the last room was left stands in for it
       * (SceneManager asks for it as a room starts loading).
       */
      public function keepLook():void
      {
         if (lastLook != null) BitmapData(lastLook.bd).dispose();
         lastLook = null;
         var skin:DisplayObject = skinOf(_myPlayer);
         if (skin == null || !skin.visible)
         {
            RLog.log("players: no look to keep (" + (skin == null ? "no avatar" : "hidden") + ")");
            return;
         }
         try
         {
            var r:Rectangle = skin.getBounds(_myPlayer);
            if (r.width < 4 || r.height < 4 || r.width > 600 || r.height > 600)
            {
               RLog.log("players: no look to keep (" + r + ")");
               return;
            }
            var bd:BitmapData = new BitmapData(Math.ceil(r.width), Math.ceil(r.height), true, 0);
            var m:Matrix = skin.transform.matrix.clone();
            m.translate(-r.x, -r.y);
            bd.draw(skin, m);
            lastLook = {bd: bd, x: r.x, y: r.y};
         }
         catch (e:Error)
         {
            RLog.log("players: no look to keep (" + e.message + ")");
            lastLook = null;
         }
      }

      private function standIn(p:PlayerBase):void
      {
         var look:Object = lastLook;
         lastLook = null;
         var skin:DisplayObject = skinOf(p);
         if (look == null || skin == null) return;
         var shown:Bitmap = new Bitmap(look.bd as BitmapData);
         shown.name = "revivalLastLook";
         shown.x = look.x;
         shown.y = look.y;
         p.addChildAt(shown, Math.min(p.numChildren, p.getChildIndex(skin) + 1));
         var since:int = getTimer();
         var check:Function = function(e:Event):void
         {
            var ready:Boolean = false;
            try { ready = skin.width >= 4 && skin.height >= 4; } catch (err:Error) {}
            if (!ready && p.stage != null && getTimer() - since < 4000) return;
            p.removeEventListener(Event.ENTER_FRAME, check);
            if (shown.parent) shown.parent.removeChild(shown);
            shown.bitmapData.dispose();
         };
         p.addEventListener(Event.ENTER_FRAME, check);
      }

      public function clear():void
      {
         // The look is kept when a room starts loading (SceneManager), before anything
         // else hears of it; else here.
         if (_myPlayer != null && lastLook == null) keepLook();
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
         sc.addEventListener(SocketClientEvent.onMovingStateChanged, onMovingState);
      }

      /**
       * The way of moving in a "ms" user variable ("ride;<speed>", "walk"; none: walking): the
       * player's rows, and another player's walk at his 坐骑's speed (mine: pet/petride's).
       */
      private function applyMoving(p:PlayerBase, ms:*):void
      {
         var a:Array = ms == null ? ["walk"] : String(ms).split(";");
         if (p is Player) Player(p).setMovingState(String(a[0]));
         if (ms != null && p != _myPlayer) p.walkSpeed = Math.round(PlayerBase.WALK_SPEED * (a[0] == "ride" && Number(a[1]) > 0 ? Number(a[1]) : 1));
      }

      /** Someone (or I) got on a 坐骑 or off it ("ms", the 2013 SocketClient's onMovingStateChanged). */
      private function onMovingState(e:SocketClientEvent):void
      {
         var u:User = e.params.user as User;
         var p:PlayerBase = u ? _playerList[u.getName()] as PlayerBase : null;
         if (p) applyMoving(p, e.params.ms);
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
         // Another player walks the way round the obstruction too (his client sends where to).
         if (e.type == SocketClientEvent.onUserMove) p.walkTo(pt.x, pt.y);
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
