package mmo.robot.robotmes
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import mmo.common.DateUtil;
   import mmo.common.DisplayUtil;
   import mmo.common.Text;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.floatpanel.FloatPanelManager;
   import mmo.common.words.BadWordsFilter;
   import mmo.common.words.InputChecker;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.robotgame.RobotPotentialClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.IAlbumAvatarProxy;
   import mmo.interfaces.avatar.IAvatarService;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.robot.IRobotService;
   import mmo.interfaces.robot.RobotEvent;
   import mmo.interfaces.user.IUserNameManager;
   import mmo.revival.RLog;
   import mmo.robot.Robotskillicon;
   import mmo.util.component.page.PageComponent;
   import mmo.util.component.page.PageComponentEvent;

   /**
    * LATER robot/robotmes (November 2015, decompiled) on the 2013 libraries: the
    * 基本资料 card of one's own HELLO, on that copy's art (symbol 132). 昵称 (the
    * pen renames it: RobotClient.reName, 2-10), 主人, 星座 (from its birthday), 智商
    * (the best scores of the HELLO学院's games, RobotPotentialClient 2-20), its look
    * (the HELLO's clothes for a 蓝宝石 member, else the plain HELLO, as the era card
    * of another player's HELLO draws it) and the skills it has, seven a page.
    */
   public class RobotMesPanel extends Sprite implements IDispose
   {
      public var t0:TextField;
      public var t1:TextField;
      public var t2:TextField;
      public var t3:TextField;
      public var container:MovieClip;
      public var avatarContainer:MovieClip;
      public var a0:MovieClip;
      public var a1:MovieClip;
      public var a2:MovieClip;
      public var a3:MovieClip;
      public var a4:MovieClip;
      public var a5:MovieClip;
      public var a6:MovieClip;
      public var btnnext:SimpleButton;
      public var btnback:SimpleButton;
      public var btnClose:SimpleButton;
      public var tuopanel:MovieClip;
      public var btnSupHello:MovieClip;
      public var changeName:MovieClip;
      public var dragMC:MovieClip;

      private const NUMPERPAGE:int = 7;
      private var robotService:IRobotService;
      private var skillinfo:String = "";
      private var beforename:String = "";
      private var skills:Array = [];
      private var superSkills:Array = [];
      private var numary:Array = [];
      private var view:Array = [];
      private var viewSup:Array = [];
      private var pageComponent:PageComponent;
      private var icon:Robotskillicon;
      private var temptext:TextField;
      private var avatarProxy:IAlbumAvatarProxy;
      private var isMember:Boolean;
      private var dataObject:Object;

      public function RobotMesPanel(o:Object)
      {
         super();
         dataObject = o;
         isMember = MemberManager.instance.isMember();
         robotService = ServiceContainer.getService("RobotDataService") as IRobotService;
         dragMC = tuopanel;
         MovieClip(changeName).gotoAndStop(1);
         MovieClip(changeName).buttonMode = true;
         MovieClip(changeName).addEventListener(MouseEvent.CLICK, onChangeName);
         btnClose.addEventListener(MouseEvent.CLICK, onClickClose);
         if (!isMember) DisplayUtil.applyGray(btnSupHello);
         show(o);
         robotService.addEventListener(RobotEvent.USEITEM, onRobotChanged);
         SocketClient.instance.addEventListener(RobotPotentialClient.cmdGetHighestScore, onGetIntelligence);
         RobotPotentialClient.getHighestScore(UserInfo.userName);
      }

      private function show(o:Object):void
      {
         skillinfo = String(o.f || "");
         beforename = String(o.n);
         t0.text = beforename;
         t0.type = TextFieldType.DYNAMIC;
         t0.selectable = false;
         var names:IUserNameManager = ServiceContainer.getService("UserNameManager") as IUserNameManager;
         var me:String = SocketClient.instance.currentUser ? SocketClient.instance.currentUser.getName() : UserInfo.userName;
         // 主人: the owner's name (2-0's un; the nickname the name manager may know first).
         var owner:String = o.un ? String(o.un) : me;
         var nick:String = "";
         try { if (names) nick = String(names.getNickName(owner) || ""); } catch (e:Error) {}
         t1.text = nick || owner || "";
         var b:Array = String(o.b || "2012-08-15").split("-");
         try { t2.text = DateUtil.getAstro(int(b[1]), int(b[2])) + "座"; } catch (e2:Error) { t2.text = ""; }
         refreshHello(String(o.a || ""));
         robotskillinit();
      }

      private function onGetIntelligence(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(RobotPotentialClient.cmdGetHighestScore, onGetIntelligence);
         var n:int = 0;
         for each (var s:String in String(e.params.sc || "").split(",")) n += int(s);
         t3.text = String(n);
      }

      private function refreshHello(a:String):void
      {
         a = isMember ? (a == "" ? "40001" : a) : "23";
         try
         {
            var avatars:IAvatarService = ServiceContainer.getService("AvatarService") as IAvatarService;
            if (avatarProxy == null) avatarProxy = avatars.getAlbumAvatarProxy(false);
            var info:AvatarInfo = new AvatarInfo();
            info.setAvatarInfoWithString(a);
            avatarProxy.setAvatarInfo(info);
            var sp:Sprite = avatarProxy.getSprite();
            sp.name = "avatarSprite";
            sp.x = 45;
            sp.y = 120;
            if (sp.parent != avatarContainer) avatarContainer.addChild(sp);
         }
         catch (e:Error) { RLog.error("robotmes look", e); }
      }

      /** A 道具 used or clothes put on: the card follows (RobotEvent USEITEM / GETROBOT). */
      private function onRobotChanged(e:RobotEvent):void
      {
         var o:Object = e.params;
         if (o == null) return;
         if (o.f != null)
         {
            skillinfo = String(o.f);
            robotskillinit();
         }
         if (o.a != null) refreshHello(String(o.a));
      }

      private function robotskillinit():void
      {
         for each (var old:MovieClip in skills.concat(superSkills)) if (old.parent) old.parent.removeChild(old);
         icon = new Robotskillicon(skillinfo);
         skills = icon.iconarray;
         superSkills = icon.iconArraySuper;
         numary = [];
         for (var i:int = 0; i < skills.length; i++)
         {
            numary.push(i);
            container.addChild(skills[i]);
            MovieClip(skills[i]).visible = false;
         }
         for (var j:int = 0; j < superSkills.length; j++)
         {
            container.addChild(superSkills[j]);
            MovieClip(superSkills[j]).visible = false;
         }
         if (pageComponent == null)
         {
            pageComponent = new PageComponent(numary, NUMPERPAGE, btnback, btnnext, new TextField());
            pageComponent.addEventListener(PageComponentEvent.ON_PAGE_CHANGE, onPageChange);
         }
         else pageComponent.updateData(numary);
         refreshPage();
      }

      private function onPageChange(e:PageComponentEvent):void
      {
         refreshPage();
      }

      private function refreshPage():void
      {
         for each (var v:MovieClip in view.concat(viewSup)) v.visible = false;
         view = [];
         viewSup = [];
         var page:Array = pageComponent.getCurrentPageData();
         for (var i:int = 0; i < page.length; i++)
         {
            var m:MovieClip = skills[page[i]];
            m.visible = true;
            m.x = i * 30;
            m.y = 0;
            view.push(m);
         }
         var p:int = int(pageComponent.getCurrentPage);
         for (var k:int = NUMPERPAGE * (p - 1); k < NUMPERPAGE * p && k < superSkills.length; k++)
         {
            var s:MovieClip = superSkills[k];
            s.visible = true;
            s.x = (k - NUMPERPAGE * (p - 1)) * 30;
            s.y = 27;
            viewSup.push(s);
         }
      }

      private function onChangeName(e:MouseEvent):void
      {
         if (MovieClip(changeName).currentFrame == 1)
         {
            MovieClip(changeName).gotoAndStop(2);
            temptext = new TextField();
            temptext.type = TextFieldType.INPUT;
            temptext.x = t0.x;
            temptext.y = t0.y;
            temptext.text = t0.text;
            temptext.border = true;
            temptext.background = true;
            temptext.maxChars = 14;
            temptext.multiline = false;
            temptext.height = t0.height + 3;
            temptext.width = t0.width;
            addChild(temptext);
            temptext.setSelection(0, temptext.text.length);
            if (stage) stage.focus = temptext;
            t0.visible = false;
            return;
         }
         MovieClip(changeName).gotoAndStop(1);
         var name:String = temptext ? temptext.text : "";
         var ok:int = InputChecker.check(name, [InputChecker.RESULT_BAD_WORD, InputChecker.RESULT_BAN, InputChecker.RESULT_RUMOR]);
         if (Text.getLength(name) >= 1 && Text.getLength(name) <= 14 && name != beforename && ok == InputChecker.RESULT_OK && BadWordsFilter.checkWord(name))
         {
            beforename = name;
            t0.text = name;
            robotService.addEventListener(RobotEvent.RENAME, onRenamed);
            RobotClient.instance.reName(name);
         }
         else if (name != beforename)
         {
            NewDialog.showFailMessage("HELLO的名字要在1到14个字之间，不能有不文明的字哦！");
         }
         t0.visible = true;
         if (temptext && temptext.parent) removeChild(temptext);
         temptext = null;
      }

      private function onRenamed(e:RobotEvent):void
      {
         robotService.removeEventListener(RobotEvent.RENAME, onRenamed);
         RobotClient.instance.getRobot();
      }

      private function onClickClose(e:MouseEvent):void
      {
         FloatPanelManager.getInstance().removeFloatPanel(this);
         dispose();
         RobotMes.closed();
      }

      public function dispose():void
      {
         robotService.removeEventListener(RobotEvent.USEITEM, onRobotChanged);
         robotService.removeEventListener(RobotEvent.RENAME, onRenamed);
         SocketClient.instance.removeEventListener(RobotPotentialClient.cmdGetHighestScore, onGetIntelligence);
      }
   }
}
