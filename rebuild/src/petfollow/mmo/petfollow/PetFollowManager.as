package mmo.petfollow
{
   import flash.display.DisplayObjectContainer;
   import mmo.socketserver.data.User;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.pet.follow.PetFollowEvent;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.strategy.FollowSlowlyStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT. Keeps a PetFollowAvatar behind every player whose user variable
    * "p" names a following 亚比 ("raceId,viewId,petId,dress,ind,indLv"; "0#0#0"
    * when none), and answers the room-wide replies of 54_8 (a player let a
    * 亚比 follow: {name, pRId, pVId, pId, dr, ind, indLv}) and 54_9 ({name}:
    * it went back into the bag).
    */
   public class PetFollowManager
   {
      private static var _instance:PetFollowManager;
      /** userName -> PetFollowAvatar */
      public static var pets:Object = {};
      public var petId:int;

      public static function get instance():PetFollowManager
      {
         if (_instance == null) _instance = new PetFollowManager();
         return _instance;
      }

      public function init():void
      {
         var pm:PlayerManager = PlayerManager.getInstance();
         pm.addEventListener(PlayerManagerEvent.ENTER_ROOM, onPlayerEnterRoom);
         pm.addEventListener(PlayerManagerEvent.LEAVE_ROOM, onPlayerLeaveRoom);
         pm.addEventListener(PlayerManagerEvent.AVATAR_SHOW, onAvatarShow);
         pm.addEventListener(PlayerManagerEvent.AVATAR_HIDE, onAvatarHide);
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener(PetClient2.cmdSetPetFollow, onSetFollow);
         sc.addEventListener(PetClient2.cmdSetPetBackPackage, onSetBack);
         sc.addEventListener(SocketClientEvent.onUserVariablesUpdate, onUserVarUpdate);
         // The players of the current scene were added before this module loaded.
         for (var name:String in pm.playerList) followFromVariable(name);
      }

      private function onPlayerEnterRoom(e:PlayerManagerEvent):void
      {
         if (e.userName == SocketClient.instance.myUserName)
         {
            // A new scene: the followers of the last one went with it.
            var old:Array = [];
            for (var n:String in pets) old.push(n);
            for each (n in old) setPetBack(n);
         }
         followFromVariable(e.userName);
      }

      private function userOf(name:String):User
      {
         var sc:SocketClient = SocketClient.instance;
         if (name == sc.myUserName && sc.currentUser != null) return sc.currentUser;
         return sc.activeRoom != null ? sc.activeRoom.getUser(name) : null;
      }

      private function followFromVariable(name:String):void
      {
         var u:User = userOf(name);
         if (u == null) return;
         var v:* = u.getVariable("p");
         if (v == undefined || v == null || v == "" || v == "0#0#0") return;
         var a:Array = String(v).split(",");
         var leader:IMovable = PlayerManager.getInstance().playerList[name] as IMovable;
         if (leader == null || int(a[0]) <= 0) return;
         setPetFollow(leader, name, int(a[0]), int(a[1]), int(a[2]), a[3], a[4]);
      }

      private function onUserVarUpdate(e:SocketClientEvent):void
      {
         var changed:Object = e.params.changedVars;
         if (changed == null || !changed.hasOwnProperty("p")) return;
         var u:User = e.params.user as User;
         if (u == null) return;
         var a:Array = String(u.getVariable("p") || "").split(",");
         var pet:PetFollowAvatar = pets[u.getName()] as PetFollowAvatar;
         if (pet != null && a.length > 3) pet.setPetView(a[3] || "");
      }

      private function setPetFollow(leader:IMovable, name:String, raceId:int, viewId:int, id:int, dress:String, ind:String):PetFollowAvatar
      {
         setPetBack(name);
         var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || info.scene == null) return null;
         var pet:PetFollowAvatar = new PetFollowAvatar("pet_" + name + "_" + raceId, raceId, viewId > 0 ? viewId : raceId, id, name, ind);
         pet.setPetView(dress);
         pets[name] = pet;
         var layer:DisplayObjectContainer = info.scene.playerLayer;
         layer.addChild(pet);
         pet.setStrategy(new FollowSlowlyStrategy(leader));
         if (leader is PlayerBase) pet.visible = PlayerBase(leader).visible;
         RLog.log("petfollow: " + name + " <- 亚比 " + raceId + " (view " + viewId + ")");
         return pet;
      }

      private function onSetFollow(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         var name:String = p.name;
         var leader:IMovable = PlayerManager.getInstance().playerList[name] as IMovable;
         if (leader == null) return;
         var pet:PetFollowAvatar = setPetFollow(leader, name, int(p.pRId), int(p.pVId), int(p.pId), p.dr, p.ind);
         var mine:Boolean = name == SocketClient.instance.myUserName;
         CommonEventDispatcher.instance.dispatchEvent(new PetFollowEvent(mine ? PetFollowEvent.SET_FOLLOW : PetFollowEvent.OTHER_SET_FOLLOW,
            {userName: name, id: int(p.pId), avatar: pet}));
      }

      private function onSetBack(e:SocketClientEvent):void
      {
         var name:String = e.params.name;
         setPetBack(name);
         if (name != SocketClient.instance.myUserName)
            CommonEventDispatcher.instance.dispatchEvent(new PetFollowEvent(PetFollowEvent.OTHER_SET_UNFOLLOW, {userName: name, id: -1, avatar: null}));
      }

      private function onPlayerLeaveRoom(e:PlayerManagerEvent):void
      {
         setPetBack(e.userName);
      }

      private function onAvatarShow(e:PlayerManagerEvent):void
      {
         var pet:PetFollowAvatar = pets[e.userName] as PetFollowAvatar;
         if (pet) pet.visible = true;
      }

      private function onAvatarHide(e:PlayerManagerEvent):void
      {
         var pet:PetFollowAvatar = pets[e.userName] as PetFollowAvatar;
         if (pet) pet.visible = false;
      }

      private function setPetBack(name:String):void
      {
         var pet:PetFollowAvatar = pets[name] as PetFollowAvatar;
         if (pet != null) pet.dispose();
         delete pets[name];
      }
   }
}
