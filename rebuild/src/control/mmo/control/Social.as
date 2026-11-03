package mmo.control
{
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;

   /**
    * REVIVAL. 好友 and 组队 on a shared server (server social.ts): what arrives without being asked
    * (a friend's or a team's invitation, the leader going to another room), and going where
    * another 奥拉 is (找他: a scene, or a home "<owner>_<house>_Home").
    */
   public class Social
   {
      /** The team the server last told of: {leader, members} or null. */
      public static var team:Object;
      private static var started:Boolean;

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
         });
         sc.addEventListener("revival_team_go", function(e:SocketClientEvent):void
         {
            var room:String = String(e.params.room || "");
            if (room && room != currentRoom()) goTo(room);
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
         sc.addEventListener("revival_team_said", function(e:SocketClientEvent):void
         {
            NewDialog.showMessage("【队伍】" + e.params.name + "：" + e.params.text);
         });
         // The leader's room changes: the team follows.
         SceneManager.getInstance().addEventListener(SceneManagerEvent.TASK_SCENE_INITED, function(e:SceneManagerEvent):void
         {
            if (team != null && team.leader == SocketClient.instance.myUserName && team.members && team.members.length > 1)
            {
               // A 副本 and 时空隧道 are played alone: the team does not follow there.
               var info:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
               if (info == null || !info.isFB) SocketClient.instance.sendXtMessage("TeamExtension", "revival_team_go", {room: currentRoom()});
            }
         });
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
         var onAdd:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener("revival_friend_add", onAdd);
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
         var onInvite:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener("revival_team_invite", onInvite);
            if (int(e.params.res) == 1) NewDialog.showSucceedMessage(String(e.params.msg));
            else NewDialog.showFailMessage(String(e.params.msg));
         };
         sc.addEventListener("revival_team_invite", onInvite);
         sc.sendXtMessage("TeamExtension", "revival_team_invite", {name: name});
      }
   }
}
