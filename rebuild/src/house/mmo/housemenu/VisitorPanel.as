package mmo.housemenu
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REVIVAL 足迹 (the home menu's 最近访问): who came into this home lately, latest first, and
    * 去他家 to theirs. The era panel is lost; HouseExtension 62_3 {userName} answers
    * {userName, count, visitors: [{un, t}], now} (server house.ts).
    */
   public class VisitorPanel extends Sprite
   {
      private static var current:VisitorPanel;
      private static const PER_PAGE:int = 8;

      private var owner:String;
      private var box:Sprite;
      private var rows:Sprite = new Sprite();
      private var list:Array = [];
      private var page:int;
      private var pageText:TextField;
      private var countText:TextField;
      /** The server's time of the list (the visits' times are its own). */
      private var now:Number = 0;

      public static function show(owner:String):void
      {
         if (current != null) current.close();
         current = new VisitorPanel(owner);
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      public function VisitorPanel(owner:String)
      {
         super();
         this.owner = owner;
         var mine:Boolean = owner == SocketClient.instance.myUserName;
         box = RUI.panel(400, 400, mine ? "我家的足迹" : owner + "家的足迹", close, "visitorsClose");
         addChild(box);
         box.addChild(RUI.well(18, 52, 364, 300));
         rows.x = 28;
         rows.y = 60;
         box.addChild(rows);
         countText = RUI.text(12, 0x335577, false, 200);
         countText.x = 22;
         countText.y = 362;
         box.addChild(countText);
         pageText = RUI.text(12, 0x335577, false);
         pageText.x = 300;
         pageText.y = 362;
         box.addChild(pageText);
         var prev:Sprite = RUI.smallButton("◀", function():void { page--; draw(); }, 30, 22, "visitorsPrev");
         prev.x = 262;
         prev.y = 360;
         box.addChild(prev);
         var next:Sprite = RUI.smallButton("▶", function():void { page++; draw(); }, 30, 22, "visitorsNext");
         next.x = 340;
         next.y = 360;
         box.addChild(next);
         SocketClient.instance.addEventListener("62_3", onList);
         SocketClient.instance.sendXtMessage("HouseExtension", "62_3", {userName: owner});
         draw();
      }

      private function onList(e:SocketClientEvent):void
      {
         if (String(e.params.userName) != owner) return;
         list = (e.params.visitors as Array) || [];
         now = Number(e.params.now);
         countText.text = "来过的客人：" + int(e.params.count) + "人次";
         draw();
      }

      private function draw():void
      {
         while (rows.numChildren > 0) rows.removeChildAt(0);
         var pages:int = Math.max(1, Math.ceil(list.length / PER_PAGE));
         page = Math.max(0, Math.min(pages - 1, page));
         pageText.text = (page + 1) + "/" + pages;
         if (list.length == 0)
         {
            var none:TextField = RUI.text(13, 0x5A7FA3, false, 340);
            none.text = "还没有客人来过哦。";
            none.y = 10;
            rows.addChild(none);
            return;
         }
         var me:String = SocketClient.instance.myUserName;
         for (var i:int = 0; i < PER_PAGE && page * PER_PAGE + i < list.length; i++)
         {
            var v:Object = list[page * PER_PAGE + i];
            var y:int = i * 36;
            var n:TextField = RUI.text(14, 0x1A5FA8, true);
            n.text = String(v.un);
            n.y = y + 5;
            rows.addChild(n);
            var t:TextField = RUI.text(12, 0x7A8A9A, false);
            t.text = ago(now - Number(v.t));
            t.x = 130;
            t.y = y + 7;
            rows.addChild(t);
            if (String(v.un) == me) continue;
            var go:Sprite = RUI.smallButton("去他家", homeFn(String(v.un)), 60, 26, "visitorsHome" + i);
            go.x = 266;
            go.y = y + 2;
            rows.addChild(go);
         }
      }

      /** How long ago, as the server's clock goes (the game's own date, not the computer's). */
      private static function ago(ms:Number):String
      {
         if (isNaN(ms)) return "";
         var min:int = Math.max(0, Math.floor(ms / 60000));
         if (min < 1) return "刚刚来过";
         if (min < 60) return min + "分钟前";
         if (min < 24 * 60) return Math.floor(min / 60) + "小时前";
         return Math.floor(min / 1440) + "天前";
      }

      private function homeFn(name:String):Function
      {
         return function():void
         {
            close();
            try { Object(ServiceContainer.getService("HouseService")).houseLoader.loadHouse(name); }
            catch (e:Error) { RLog.error("visitors: home of " + name, e); }
         };
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("62_3", onList);
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }
   }
}
