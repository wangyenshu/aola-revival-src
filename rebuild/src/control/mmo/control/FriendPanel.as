package mmo.control
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.talk.PrivateTalkEvent;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REVIVAL 好友 (the bar's 好友 button): the 2013 buddy list is lost (the copy of 2025 does
    * not run on the 2013 libraries). Friends with whether they are on 奥拉星 and where;
    * 找他 goes there, 他家 to his 家园, 删除; a name to ask to be friends; the asks not answered.
    * Server: social.ts (BuddyManagerExtension revival_*).
    */
   public class FriendPanel extends Sprite
   {
      public static var current:FriendPanel;
      private static const PER_PAGE:int = 7;

      private var box:Sprite;
      private var rows:Sprite = new Sprite();
      private var list:Array = [];
      private var asks:Array = [];
      /** 私聊 (talk/talk's TalkService): what each friend said that is not read. */
      private var talk:Object;
      private var shut:Boolean;
      private var page:int;
      private var nameInput:TextField;
      private var pageText:TextField;

      public static function show():void
      {
         if (current != null) current.close();
         current = new FriendPanel();
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      public function FriendPanel()
      {
         super();
         box = RUI.panel(470, 400, "我的好友", close, "friendClose");
         addChild(box);
         // Taken away with the room left (SceneManager clears the dialogs): closed as well.
         addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
         box.addChild(RUI.well(18, 52, 434, 270));
         rows.x = 26;
         rows.y = 58;
         box.addChild(rows);
         pageText = RUI.text(12, 0x335577, false);
         pageText.x = 210;
         pageText.y = 326;
         box.addChild(pageText);
         var prev:Sprite = RUI.smallButton("◀", function():void { page--; draw(); }, 30, 22, "friendPrev");
         prev.x = 170;
         prev.y = 324;
         box.addChild(prev);
         var next:Sprite = RUI.smallButton("▶", function():void { page++; draw(); }, 30, 22, "friendNext");
         next.x = 262;
         next.y = 324;
         box.addChild(next);
         var label:TextField = RUI.text(13, 0x1A5FA8, true);
         label.text = "奥拉的名字：";
         label.x = 22;
         label.y = 362;
         box.addChild(label);
         nameInput = RUI.input(150, "", null, 12, "friendName");
         nameInput.x = 108;
         nameInput.y = 358;
         box.addChild(nameInput);
         var add:Sprite = RUI.button("加为好友", function():void
         {
            var n:String = nameInput.text.replace(/^\s+|\s+$/g, "");
            if (n) Social.addFriend(n);
         }, 90, 28, 0xFFC45A, 0xF07812, "friendAdd");
         add.x = 270;
         add.y = 356;
         box.addChild(add);
         var again:Sprite = RUI.smallButton("刷新", refresh, 50, 26, "friendRefresh");
         again.x = 372;
         again.y = 357;
         box.addChild(again);
         SocketClient.instance.addEventListener("revival_friends", onList);
         ServiceContainer.instance.tryGetService("TalkService", function(svc:IService, o:Object):void
         {
            if (shut || !Object(svc).hasOwnProperty("unreadOf")) return;
            talk = svc;
            svc.addEventListener(PrivateTalkEvent.NEW_UNREAD_MSG, onTalk);
            svc.addEventListener(PrivateTalkEvent.UNREAD_MSG_READ, onTalk);
            draw();
         });
         refresh();
      }

      private function onTalk(e:Event):void
      {
         draw();
      }

      public function refresh():void
      {
         SocketClient.instance.sendXtMessage("BuddyManagerExtension", "revival_friends", {});
      }

      private function onList(e:SocketClientEvent):void
      {
         list = (e.params.list as Array) || [];
         asks = (e.params.asks as Array) || [];
         draw();
      }

      private function draw():void
      {
         while (rows.numChildren > 0) rows.removeChildAt(0);
         // The asks first (同意 / 拒绝), then the friends.
         var all:Array = asks.map(function(a:Object, i:int, x:Array):Object { return {ask: true, id: a.id, name: a.name}; }).concat(list);
         var pages:int = Math.max(1, Math.ceil(all.length / PER_PAGE));
         page = Math.max(0, Math.min(pages - 1, page));
         pageText.text = (page + 1) + "/" + pages;
         if (all.length == 0)
         {
            var none:TextField = RUI.text(13, 0x5A7FA3, false, 400);
            none.text = "还没有好友。在下面写上奥拉的名字，或者在别人的信息卡上点「加为好友」。";
            none.y = 10;
            rows.addChild(none);
            return;
         }
         for (var i:int = 0; i < PER_PAGE && page * PER_PAGE + i < all.length; i++)
         {
            var f:Object = all[page * PER_PAGE + i];
            var y:int = i * 37;
            // The name opens his 名片 (as a click on him in a scene does).
            var name:TextField = RUI.text(14, f.ask ? 0xE8641B : 0x1A5FA8, true);
            name.text = String(f.name);
            name.y = y + 6;
            name.mouseEnabled = false;
            var card:Sprite = new Sprite();
            card.name = "friendCard" + i;
            card.buttonMode = true;
            card.graphics.beginFill(0xFFFFFF, 0);
            card.graphics.drawRect(0, y + 4, Math.max(40, name.width), 24);
            card.graphics.endFill();
            card.addChild(name);
            card.addEventListener(MouseEvent.CLICK, cardFn(String(f.name)));
            rows.addChild(card);
            var state:TextField = RUI.text(12, f.online ? 0x2A8A2A : 0x8A9AAA, false);
            state.text = f.ask ? "想加你为好友" : f.online ? "在线" + (f.room ? "：" + place(String(f.room)) : "") : "离线";
            state.x = 120;
            state.y = y + 8;
            if (state.width > 108)
            {
               state.autoSize = "none";
               state.width = 108;
            }
            rows.addChild(state);
            if (f.ask)
            {
               rows.addChild(at(RUI.smallButton("同意", answerFn(int(f.id), true), 48, 26, "friendYes" + i), 300, y + 3));
               rows.addChild(at(RUI.smallButton("拒绝", answerFn(int(f.id), false), 48, 26, "friendNo" + i), 352, y + 3));
               continue;
            }
            if (f.online || (talk && talk.unreadOf(String(f.name)) > 0))
            {
               var pm:Sprite = at(RUI.smallButton("私聊", talkFn(String(f.name)), 42, 26, "friendTalk" + i), 232, y + 3);
               if (talk && talk.unreadOf(String(f.name)) > 0)
               {
                  pm.graphics.beginFill(0xE8341B);
                  pm.graphics.drawCircle(40, 2, 5);
                  pm.graphics.endFill();
               }
               rows.addChild(pm);
            }
            if (f.online) rows.addChild(at(RUI.smallButton("找他", findFn(String(f.name)), 42, 26, "friendFind" + i), 278, y + 3));
            rows.addChild(at(RUI.smallButton("他家", homeFn(String(f.name)), 42, 26, "friendHome" + i), 324, y + 3));
            rows.addChild(at(RUI.smallButton("删除", delFn(int(f.id)), 42, 26, "friendDel" + i), 370, y + 3));
         }
      }

      /** A room's name to show: a home's room ("<owner>_<house>_Home") by its kind; a scene by config.xml's desc. */
      public static function place(room:String):String
      {
         var m:Array = /^(.+)_(-?\d+)_Home$/.exec(room);
         if (m != null) return m[1] + (int(m[2]) == 247 ? "的家园" : int(m[2]) == 20000 ? "的动物园" : "的小屋");
         var mr:Object = ModRun.parseTeamRoom(room);
         if (mr != null) return "模组「" + mr.mod + "」";
         if (room.indexOf("sandboxroom_") == 0) return "沙盒";
         try
         {
            var r:XMLList = ConfigReader.instance.xmlDocument..r.(attribute("rm") == room || attribute("nm") == room);
            if (r.length() > 0 && String(r[0].@desc)) return String(r[0].@desc);
         }
         catch (e:Error) {}
         return room;
      }

      private static function at(s:Sprite, x:Number, y:Number):Sprite
      {
         s.x = x;
         s.y = y;
         return s;
      }

      private function answerFn(id:int, ok:Boolean):Function
      {
         return function():void
         {
            Social.answer(id, ok);
            refreshSoon();
         };
      }

      private function findFn(name:String):Function
      {
         return function():void
         {
            close();
            Social.find(name);
         };
      }

      private function talkFn(name:String):Function
      {
         return function():void
         {
            close();
            if (talk) talk.showTalkPanel(name);
         };
      }

      private function cardFn(name:String):Function
      {
         return function(e:MouseEvent):void
         {
            close();
            try
            {
               ServiceContainer.instance.tryGetService("UserCardService", function(svc:IService, o:Object):void
               {
                  Object(svc).showUserCard(name, 1);
               });
            }
            catch (err:Error)
            {
               RLog.error("friend card", err);
            }
         };
      }

      private function homeFn(name:String):Function
      {
         return function():void
         {
            close();
            Social.visitHome(name);
         };
      }

      private function delFn(id:int):Function
      {
         return function():void
         {
            SocketClient.instance.sendXtMessage("BuddyManagerExtension", "revival_friend_del", {id: id});
            refreshSoon();
         };
      }

      private function refreshSoon():void
      {
         var self:FriendPanel = this;
         var t:Function = function(e:SocketClientEvent):void
         {
            SocketClient.instance.removeEventListener("revival_friend_answer", t);
            SocketClient.instance.removeEventListener("revival_friend_del", t);
            if (current == self) refresh();
         };
         SocketClient.instance.addEventListener("revival_friend_answer", t);
         SocketClient.instance.addEventListener("revival_friend_del", t);
      }

      private function onRemoved(e:Event):void
      {
         if (current == this) close();
      }

      public function close():void
      {
         // Forgotten first: taking it away below tells onRemoved, which must not close it again.
         shut = true;
         if (current == this) current = null;
         removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
         SocketClient.instance.removeEventListener("revival_friends", onList);
         if (talk)
         {
            talk.removeEventListener(PrivateTalkEvent.NEW_UNREAD_MSG, onTalk);
            talk.removeEventListener(PrivateTalkEvent.UNREAD_MSG_READ, onTalk);
         }
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}
