package mmo.zoo.revival
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.revival.RLog;

   /**
    * REBUILT 动物园信息: the era ZooInfoPanel (zoo/zoores, 2011–12) on its art: the owner and
    * picture, 养殖等级 and its 经验值, the 称号 of the level (the era titles), and 扩建动物园,
    * which here is the room the next level gives (可养动物数; the server's zoo grows with its
    * level, the 饲料机 has no limit). Its numbers are ZooExtension 97_1's.
    */
   public class InfoPanel extends MovieClip
   {
      public var btnClose:SimpleButton;
      public var txtOwner:TextField;
      public var txtLevel:TextField;
      public var txtTitle:TextField;
      public var txtExp:TextField;
      public var expMovie:MovieClip;
      public var size:MovieClip;
      public var size1:MovieClip;
      public var head:MovieClip;
      public var nextExpend:MovieClip;
      public var nextLevelMC:MovieClip;
      public var fullTips:MovieClip;
      public var txtFeedPetCountOld:TextField;
      public var txtFeedCountOld:TextField;

      private static const TITLES:Array = ["动物园学徒", "动物园新秀", "动物园高手", "动物园达人", "动物园精英", "动物园大师"];
      private static const TITLE_LEVELS:Array = [1, 6, 11, 16, 21, 26];
      /** The zoo's room by level (server zoo.ts zooRoom). */
      private static function room(lv:int):int
      {
         return Math.min(20, 6 + 2 * lv);
      }

      /** info: 97_1's {un, lv, exp, next, cap, n}; who: the name shown. */
      public static function show(info:Object, who:String):void
      {
         ModalDialogManager.getInstance().addModalDialog(new InfoPanel(info, who));
      }

      public function InfoPanel(info:Object, who:String)
      {
         super();
         stop();
         var lv:int = int(info.lv), exp:int = int(info.exp), next:int = Math.max(int(info.next), exp, 1);
         btnClose.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { ModalDialogManager.getInstance().removeModalDialog(InfoPanel(MovieClip(e.currentTarget).parent)); });
         txtOwner.text = who;
         txtLevel.text = String(lv);
         var t:int = 0;
         for (var i:int = 0; i < TITLE_LEVELS.length; i++) if (lv >= TITLE_LEVELS[i]) t = i;
         txtTitle.text = TITLES[t];
         txtExp.text = exp + "/" + next;
         if (expMovie != null) expMovie.gotoAndStop(int(expMovie.totalFrames * exp / next) + 1);
         if (size != null) size.gotoAndStop(1);
         ZooKit.hide(size1);
         txtFeedPetCountOld.text = String(int(info.cap) || room(lv));
         txtFeedCountOld.text = "-";
         var more:Boolean = room(lv + 1) > room(lv);
         nextExpend.visible = nextLevelMC.visible = more;
         fullTips.visible = !more;
         if (more)
         {
            ZooKit.hide(nextExpend.getChildByName("size2"));
            text(nextExpend, "txtFeedPetCountNew", String(room(lv + 1)));
            text(nextExpend, "txtFeedCountNew", "-");
            text(nextLevelMC, "levelNext", String(lv + 1));
         }
         var holder:MovieClip = head ? head.getChildByName("head") as MovieClip : null;
         if (holder != null)
         {
            ServiceContainer.instance.tryGetService("UserAvatarService", function(s:Object, o:Object = null):void
            {
               try { s.showUserAvatar(String(info.un), holder, 0.5, 0.5, 0, 0); } catch (e:Error) { RLog.error("zoo info avatar", e); }
            });
         }
      }

      private static function text(mc:MovieClip, name:String, s:String):void
      {
         var t:TextField = mc ? mc.getChildByName(name) as TextField : null;
         if (t != null) t.text = s;
      }
   }
}
