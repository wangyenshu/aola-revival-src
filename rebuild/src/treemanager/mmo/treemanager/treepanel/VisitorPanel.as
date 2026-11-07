package mmo.treemanager.treepanel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TextEvent;
   import flash.text.TextField;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.usercard.IUserCardService;
   import mmo.revival.RLog;

   /**
    * REBUILT 植物心声 (the later copy's code on its art, symbol 15): the last five who gave the
    * owner's tree 雨露 or 养料 ("name|name#…"); a name opens his card, its button his home.
    */
   public class VisitorPanel extends Sprite
   {
      private static const COUNT:int = 5;

      public var _visitor0:MovieClip;
      public var _visitor1:MovieClip;
      public var _visitor2:MovieClip;
      public var _visitor3:MovieClip;
      public var _visitor4:MovieClip;
      public var _txtThanks:TextField;

      private var names:Array = [];
      private var visit:Function;

      /** visit(name): to that player's home. */
      public function VisitorPanel(visitors:String, visit:Function)
      {
         super();
         name = "treeVisitors";
         this.visit = visit;
         var list:Array = visitors ? visitors.split("#") : [];
         for (var i:int = 0; i < COUNT; i++)
         {
            var row:MovieClip = getChildByName("_visitor" + i) as MovieClip;
            if (row == null) continue;
            var who:Array = i < list.length ? String(list[i]).split(String(list[i]).indexOf("|") >= 0 ? "|" : "_") : null;
            row.visible = who != null;
            if (who == null) continue;
            names[i] = String(who[0]);
            var t:TextField = row.getChildByName("_visitorname") as TextField;
            if (t != null)
            {
               t.htmlText = "<a href=\"event:" + who[0] + "\">" + (who.length > 1 ? who[1] : who[0]) + "</a>";
               t.addEventListener(TextEvent.LINK, onName);
            }
            var help:Object = row.getChildByName("btnHelp");
            if (help != null) help.addEventListener(MouseEvent.CLICK, onHelp);
         }
         if (_txtThanks != null) _txtThanks.visible = list.length == 0;
      }

      private function onName(e:TextEvent):void
      {
         e.stopPropagation();
         var who:String = e.text;
         ServiceContainer.instance.tryGetService(IUserCardService, function(svc:IUserCardService, o:Object = null):void
         {
            try { svc.showUserCard(who); } catch (err:Error) { RLog.error("tree visitor card", err); }
         });
      }

      private function onHelp(e:MouseEvent):void
      {
         e.stopPropagation();
         var i:int = int(String(e.currentTarget.parent.name).charAt(8));
         if (names[i] && visit != null) visit(names[i]);
      }
   }
}
