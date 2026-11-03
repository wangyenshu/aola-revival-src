package mmo.control
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.revival.RUI;

   /**
    * REVIVAL 组队 (the bar's 组队 button): the 2013 team panel is lost (the copy of 2016 does
    * not run on the 2013 libraries). A team of up to three: the leader invites 奥拉 who are on
    * 奥拉星 (a name, or the 邀请组队 of their 信息卡); the members follow the leader from room to
    * room (Social: revival_team_go); 队伍聊天 says a line to the team only. Server: social.ts.
    */
   public class TeamPanel extends Sprite
   {
      public static var current:TeamPanel;

      private var box:Sprite;
      private var rows:Sprite = new Sprite();
      private var nameInput:TextField;
      private var sayInput:TextField;
      private var state:TextField;

      public static function show():void
      {
         if (current != null) current.close();
         current = new TeamPanel();
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      public function TeamPanel()
      {
         super();
         box = RUI.panel(400, 360, "我的队伍", close, "teamClose");
         addChild(box);
         box.addChild(RUI.well(18, 52, 364, 160));
         rows.x = 30;
         rows.y = 60;
         box.addChild(rows);
         state = RUI.text(12, 0x5A7FA3, false, 360);
         state.x = 22;
         state.y = 218;
         box.addChild(state);
         var l1:TextField = RUI.text(13, 0x1A5FA8, true);
         l1.text = "邀请：";
         l1.x = 22;
         l1.y = 252;
         box.addChild(l1);
         nameInput = RUI.input(150, "", null, 12, "teamName");
         nameInput.x = 70;
         nameInput.y = 248;
         box.addChild(nameInput);
         var inv:Sprite = RUI.button("邀请组队", function():void
         {
            var n:String = nameInput.text.replace(/^\s+|\s+$/g, "");
            if (n) Social.invite(n);
         }, 90, 28, 0xFFC45A, 0xF07812, "teamInvite");
         inv.x = 232;
         inv.y = 246;
         box.addChild(inv);
         var l2:TextField = RUI.text(13, 0x1A5FA8, true);
         l2.text = "说：";
         l2.x = 22;
         l2.y = 292;
         box.addChild(l2);
         sayInput = RUI.input(150, "", null, 40, "teamSay");
         sayInput.x = 70;
         sayInput.y = 288;
         box.addChild(sayInput);
         var say:Sprite = RUI.button("队伍聊天", function():void
         {
            var t:String = sayInput.text.replace(/^\s+|\s+$/g, "");
            if (!t) return;
            SocketClient.instance.sendXtMessage("TeamExtension", "revival_team_say", {text: t});
            sayInput.text = "";
         }, 90, 28, 0x8FE3FF, 0x1E8FE0, "teamSayGo");
         say.x = 232;
         say.y = 286;
         box.addChild(say);
         var leave:Sprite = RUI.smallButton("离开队伍", function():void
         {
            SocketClient.instance.sendXtMessage("TeamExtension", "revival_team_leave", {});
         }, 80, 26, "teamLeave");
         leave.x = 296;
         leave.y = 324;
         box.addChild(leave);
         refresh();
         SocketClient.instance.sendXtMessage("TeamExtension", "revival_team", {});
      }

      public function refresh():void
      {
         while (rows.numChildren > 0) rows.removeChildAt(0);
         var t:Object = Social.team;
         var me:String = SocketClient.instance.myUserName;
         if (t == null || !t.members)
         {
            state.text = "你还没有队伍。写上一个在线奥拉的名字，点「邀请组队」就能组成队伍。";
            return;
         }
         var members:Array = t.members as Array;
         for (var i:int = 0; i < members.length; i++)
         {
            var n:TextField = RUI.text(14, members[i] == me ? 0xE8641B : 0x1A5FA8, true);
            n.text = (members[i] == t.leader ? "★ " : "· ") + members[i] + (members[i] == t.leader ? "（队长）" : "");
            n.y = i * 34;
            rows.addChild(n);
            if (members[i] != me)
            {
               var go:Sprite = RUI.smallButton("找他", findFn(String(members[i])), 50, 24, "teamFind" + i);
               go.x = 250;
               go.y = i * 34;
               rows.addChild(go);
            }
         }
         state.text = t.leader == me ? "你是队长：你去哪里，队员就跟到哪里。" : "队员会跟着队长走。";
      }

      private function findFn(name:String):Function
      {
         return function():void
         {
            close();
            Social.find(name);
         };
      }

      public function close():void
      {
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }
   }
}
