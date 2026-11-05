package mmo.control
{
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.movable.strategy.PlayerFollowStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.loader.layer.LayerManager;
   import flash.utils.setTimeout;
   import flash.utils.getTimer;

   /**
    * REVIVAL. 好友 and 组队 on a shared server (server social.ts): what arrives without being asked
    * (a friend's or a team's invitation, the leader going to another room), and going where
    * another 奥拉 is (找他: a scene, or a home "<owner>_<house>_Home").
    *
    * A team's members follow its leader, as the 2013 game had them (the team service set the user
    * variable ft "1;<leader>" on each, and baseservice/follow then walked them after him instead
    * of the mouse): one walks after the leader in the room (PlayerFollowStrategy) and stands while
    * he is elsewhere, and goes only into the rooms he takes the team to (revival_team_go): the
    * leader alone chooses where. Out of the team, one's own way again.
    */
   public class Social
   {
      /** The team the server last told of: {leader, members} or null. */
      public static var team:Object;
      private static var started:Boolean;
      /** The room the leader last took the team to (revival_team_go). */
      private static var teamRoom:String;
      /** My player and the leader's as last followed, or null. */
      private static var followedMe:PlayerBase;
      private static var followedLead:PlayerBase;
      /** A scene holds my player still (the hot spring's pool): not moved to follow till refollow(). */
      public static var paused:Boolean;
      /** A friend ask or a team invite sent and not yet answered (getTimer() then; one at a time). */
      private static var asking:Object = {};

      /** In a team and not its leader. */
      public static function get follower():Boolean
      {
         return team != null && team.members is Array && (team.members as Array).length > 1 && team.leader != SocketClient.instance.myUserName;
      }

      public static function start():void
      {
         if (started) return;
         started = true;
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener("revival_friend_ask", onFriendAsk);
         sc.addEventListener("revival_friend_added", function(e:SocketClientEvent):void
         {
            NewDialog.showSucceedMessage(String(e.params.name) + "和你成为好友了！");
         });
         sc.addEventListener("revival_team_ask", onTeamAsk);
         sc.addEventListener("revival_team", function(e:SocketClientEvent):void
         {
            team = e.params.team;
            if (e.params.msg) NewDialog.showMessage(String(e.params.msg));
            if (TeamPanel.current != null) TeamPanel.current.refresh();
            follow();
         });
         // The same 奥拉 logged in elsewhere: this game's connection is closed (server.ts).
         sc.addEventListener("revival_replaced", function(e:SocketClientEvent):void
         {
            NewDialog.showMessage(String(e.params.msg || "你的奥拉在别的地方登录了，这里的连接已经断开。"));
         });
         sc.addEventListener("revival_team_go", function(e:SocketClientEvent):void
         {
            var room:String = String(e.params.room || "");
            teamRoom = room;
            if (room && room != currentRoom()) goTo(room);
         });
         // My player, or the leader's, comes into the room or leaves it.
         var pm:PlayerManager = PlayerManager.getInstance();
         pm.addEventListener(PlayerManagerEvent.ENTER_ROOM, function(e:PlayerManagerEvent):void { follow(); });
         pm.addEventListener(PlayerManagerEvent.LEAVE_ROOM, function(e:PlayerManagerEvent):void { follow(); });
         // A member goes nowhere but where the leader takes the team.
         SceneManager.getInstance().addEventListener(SceneManagerEvent.ON_LOADING_SCENE, function(e:SceneManagerEvent):void
         {
            if (!follower) return;
            var to:SceneInfo = e.params.SceneInfo as SceneInfo;
            var at:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
            if (to == null || at == null || to.roomName == at.roomName || to.roomName == teamRoom) return;
            e.params.cancel = true;
            NewDialog.showMessage("只有队长才能决定去哪里哦！");
         });
         // 亚比对战: another 奥拉 asks (duel.ts); a refusal or a fight that could not start.
         sc.addEventListener("revival_duel_ask", onDuelAsk);
         sc.addEventListener("revival_duel_said", function(e:SocketClientEvent):void
         {
            NewDialog.showMessage(String(e.params.msg));
         });
         sc.addEventListener("revival_duel_answer", function(e:SocketClientEvent):void
         {
            if (int(e.params.res) != 1 && e.params.msg) NewDialog.showFailMessage(String(e.params.msg));
         });
         // A line of the team's: over the speaker's head when he is here, as a notice that
         // goes by itself, and in the talk history (not a dialog to close for every line).
         sc.addEventListener("revival_team_said", function(e:SocketClientEvent):void
         {
            var who:String = String(e.params.name), text:String = String(e.params.text);
            try
            {
               var speaker:PlayerBase = PlayerManager.getInstance().getPlayer(who);
               if (speaker != null && !speaker.isDisposed && speaker.hasOwnProperty("say")) Object(speaker).say(text);
            }
            catch (err:Error) {}
            try { RNotice.show(LayerManager.getBaseTop().stage, "【队伍】" + who + "：" + text, 4); } catch (err2:Error) {}
            ServiceContainer.instance.tryGetService("SceneTalkService", function(svc:IService, o:Object):void
            {
               if (Object(svc).hasOwnProperty("addLine")) Object(svc).addLine(who, "【队伍】" + text);
            });
         });
         // The leader's room changes: the team follows.
         SceneManager.getInstance().addEventListener(SceneManagerEvent.TASK_SCENE_INITED, function(e:SceneManagerEvent):void
         {
            // A new room holds no one still (the hot spring's pool lets go on leaving it).
            if (paused)
            {
               paused = false;
               followedMe = followedLead = null;
               follow();
            }
            // A member who came where the team is not (the leader moved on while this room
            // loaded: a call to go then was not taken): after him.
            if (follower && teamRoom && teamRoom != currentRoom())
            {
               var go:String = teamRoom;
               setTimeout(function():void { if (follower && teamRoom == go && go != currentRoom()) goTo(go); }, 300);
            }
            if (team != null && team.leader == SocketClient.instance.myUserName && team.members && team.members.length > 1)
            {
               // A 副本 and 时空隧道 are played alone: the team does not follow there.
               var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
               if (info == null || !info.isFB) SocketClient.instance.sendXtMessage("TeamExtension", "revival_team_go", {room: currentRoom()});
            }
         });
      }

      /** As a member: after the leader where he is in my room (standing while he is not); else my own way. */
      private static function follow():void
      {
         var pm:PlayerManager = PlayerManager.getInstance();
         var me:PlayerBase = pm.myPlayer;
         if (me == null || me.isDisposed || paused) return;
         if (follower)
         {
            var lead:PlayerBase = pm.getPlayer(String(team.leader));
            if (me == followedMe && lead == followedLead) return;
            followedMe = me;
            followedLead = lead;
            // My place beside him: the first member on his left, the second on his right.
            var i:int = Math.max(1, (team.members as Array).indexOf(SocketClient.instance.myUserName));
            me.stop();
            // He is not here (a 副本 of his, or on his way): walk about the room while waiting.
            me.setStrategy(lead != null ? new PlayerFollowStrategy(lead as IMovable, i % 2 == 1 ? -45 : 45, 25) : new MouseControlStrategy());
            return;
         }
         if (followedMe == null) return;
         if (followedMe == me) me.setStrategy(new MouseControlStrategy());
         followedMe = followedLead = null;
      }

      /** Follow again (a scene that set my strategy itself, the hot spring, gives it back). */
      public static function refollow():void
      {
         followedMe = followedLead = null;
         if (follower) follow();
         else
         {
            var me:PlayerBase = PlayerManager.getInstance().myPlayer;
            if (me != null && !me.isDisposed) me.setStrategy(new MouseControlStrategy());
         }
      }

      /** One ask of a kind at a time (a second click while it waits is not sent again). */
      private static function oneAsk(kind:String):Boolean
      {
         if (asking[kind] != null && getTimer() - int(asking[kind]) < 8000) return false;
         asking[kind] = getTimer();
         return true;
      }

      public static function currentRoom():String
      {
         try { return SceneManager.getInstance().loadedSceneInfo.roomName; } catch (e:Error) {}
         return "";
      }

      private static function onFriendAsk(e:SocketClientEvent):void
      {
         var id:int = int(e.params.id);
         var name:String = String(e.params.name);
         NewDialog.getCofirmDialog(name + "想和你成为好友，同意吗？", function(d:ModalDialog):void
         {
            d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void { answer(id, true); });
            d.addEventListener(ModalDialogEvent.CANCEL, function(ev:ModalDialogEvent):void { answer(id, false); });
            d.show();
         });
      }

      public static function answer(id:int, ok:Boolean):void
      {
         SocketClient.instance.sendXtMessage("BuddyManagerExtension", "revival_friend_answer", {id: id, ok: ok});
      }

      private static function onDuelAsk(e:SocketClientEvent):void
      {
         var from:String = String(e.params.from);
         NewDialog.getCofirmDialog(from + "邀请你进行亚比对战，接受吗？", function(d:ModalDialog):void
         {
            var answer:Function = function(ok:Boolean):Function
            {
               return function(ev:ModalDialogEvent):void
               {
                  SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_duel_answer", {from: from, ok: ok});
               };
            };
            d.addEventListener(ModalDialogEvent.OK, answer(true));
            d.addEventListener(ModalDialogEvent.CANCEL, answer(false));
            d.show();
         });
      }

      private static function onTeamAsk(e:SocketClientEvent):void
      {
         var leader:String = String(e.params.leader);
         NewDialog.getCofirmDialog(leader + "邀请你加入队伍，一起去冒险吗？", function(d:ModalDialog):void
         {
            d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void
            {
               SocketClient.instance.sendXtMessage("TeamExtension", "revival_team_join", {leader: leader});
            });
            d.show();
         });
      }

      /** Where an 奥拉 is: a scene, or a home ("<owner>_<house>_Home": the owner's home). */
      public static function goTo(room:String):void
      {
         try
         {
            var m:Array = /^(.+)_(-?\d+)_Home$/.exec(room);
            if (m != null)
            {
               visitHome(m[1], int(m[2]));
               return;
            }
            if (room == currentRoom()) return;
            // A team's room of a mod: only with the same mod (and version) loaded.
            if (room.indexOf(ModRun.TEAM_ROOM) == 0)
            {
               if (!ModRun.instance.followInto(room))
               {
                  var r:Object = ModRun.parseTeamRoom(room);
                  NewDialog.showMessage("队伍在模组「" + (r ? r.mod + (r.version ? " " + r.version : "") : "?") + "」里。载入同一个模组（同一个版本），在沙盒里就能跟着队长一起玩了。");
               }
               return;
            }
            // One's own 沙盒 room: nobody else's to go into.
            if (room.indexOf("sandboxroom_") == 0)
            {
               NewDialog.showMessage("他正在沙盒里玩自己的关卡，组队以后才能一起玩哦。");
               return;
            }
            // A player's 副本 or 时空隧道 room ("fbaixi1@奥拉A"): his alone.
            if (room.indexOf("@") >= 0)
            {
               NewDialog.showMessage("他正在副本里，等他出来再去找他吧。");
               return;
            }
            SceneManager.getInstance().loadScene(room);
         }
         catch (err:Error) { RLog.error("social goTo " + room, err); }
      }

      /**
       * Someone's home: the 家园 (247, as one's own 回家), the 小屋 (the main house: its id, or -1)
       * or the 动物园 (20000). The rebuilt HouseLoader's visit; loadHouse (the 家园) otherwise.
       */
      public static function visitHome(owner:String, houseId:int = 247):void
      {
         var go:Function = function(loader:Object):void
         {
            try
            {
               if ("visit" in loader) loader.visit(owner, houseId);
               else loader.loadHouse(owner);
            }
            catch (e:Error) { RLog.error("social home", e); }
         };
         ServiceContainer.instance.tryGetService("HouseService", function(svc:IService, o:Object):void
         {
            var loader:Object = null;
            try { loader = Object(svc).houseLoader; } catch (e:Error) {}
            if (loader != null) go(loader);
            else ServiceContainer.instance.tryGetService("HouseLoader", function(l:IService, o2:Object):void { go(l); });
         });
      }

      /** 找他: where the 奥拉 is now, then there. */
      public static function find(name:String):void
      {
         var sc:SocketClient = SocketClient.instance;
         var onWhere:Function = function(e:SocketClientEvent):void
         {
            if (String(e.params.name) != name) return;
            sc.removeEventListener("revival_where", onWhere);
            if (!e.params.online) NewDialog.showMessage(name + "现在不在奥拉星上。");
            else if (!e.params.room) NewDialog.showMessage(name + "正在路上，等一下再找吧。");
            else goTo(String(e.params.room));
         };
         sc.addEventListener("revival_where", onWhere);
         sc.sendXtMessage("BuddyManagerExtension", "revival_where", {name: name});
      }

      public static function addFriend(name:String):void
      {
         var sc:SocketClient = SocketClient.instance;
         if (!oneAsk("friend")) return;
         var onAdd:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener("revival_friend_add", onAdd);
            delete asking["friend"];
            if (int(e.params.res) == 1) NewDialog.showSucceedMessage(String(e.params.msg));
            else NewDialog.showFailMessage(String(e.params.msg));
            if (FriendPanel.current != null) FriendPanel.current.refresh();
         };
         sc.addEventListener("revival_friend_add", onAdd);
         sc.sendXtMessage("BuddyManagerExtension", "revival_friend_add", {name: name});
      }

      public static function invite(name:String):void
      {
         var sc:SocketClient = SocketClient.instance;
         if (!oneAsk("invite")) return;
         var onInvite:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener("revival_team_invite", onInvite);
            delete asking["invite"];
            if (int(e.params.res) == 1) NewDialog.showSucceedMessage(String(e.params.msg));
            else NewDialog.showFailMessage(String(e.params.msg));
         };
         sc.addEventListener("revival_team_invite", onInvite);
         sc.sendXtMessage("TeamExtension", "revival_team_invite", {name: name});
      }
   }
}
