package mmo.fortunemanager
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;

   /**
    * REBUILT 财富小管家 (FortuneManagerService, fortunemanager/fortunemanager):
    * the bank machine of 奥拉广场 where idle 晶币 are put away for 1 to 7 days
    * and come back with interest (百田's guide of 5 January 2012: 500,000 晶币
    * for 7 days earn 24,500). The 2013 module is lost and the later one
    * (fortunemanager/starcoin, 2026) keeps 晶豆 on later classes; this panel,
    * drawn in the look of the rebuilt panels, speaks the later client's
    * ScoreManager commands, which the revival's server answers:
    *
    *   getAccount {}                  -> {al: [{id (0-4), sc, sd (ms), d}]}
    *   despositAccount {ai, sc, d}    -> {b}
    *   takeAwawyAccount {ai}          -> {res: 晶币 back (-1 none), interest}
    *
    * Five boxes; taken out when the days are up, the 晶币 come back with their
    * interest, sooner with less (none in the first day). The limits and the
    * interest of less than seven days are RECONSTRUCTED (server).
    */
   public class FortuneManagerService extends EventDispatcher implements IShowPanel
   {
      private static const EXT:String = "ScoreManager";
      private static const W:int = 560;
      private static const H:int = 400;
      private static const DAY:Number = 24 * 3600 * 1000;

      private var top:Sprite;
      private var box:Sprite;
      private var rows:Sprite;
      private var said:TextField;
      private var money:TextField;
      private var accounts:Array = [];
      private var serverOffset:Number = 0;

      public function FortuneManagerService()
      {
         super();
      }

      public function showPanel():void
      {
         close();
         top = new Sprite();
         top.name = "fortuneManager";
         top.addChild(RUI.dim(close));
         box = RUI.panel(W, H, "财富小管家", close, "fortuneClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         top.addChild(box);
         var intro:TextField = RUI.text(13, RUI.BLUE, false, W - 40);
         intro.x = 20;
         intro.y = 52;
         intro.text = "把暂时不用的晶币存进财富小管家，存1到7天，到期取出时会多出利息！存得越久，利息越多。";
         box.addChild(intro);
         money = RUI.text(13, 0xC25A00, true);
         money.x = 20;
         money.y = 92;
         box.addChild(money);
         box.addChild(RUI.well(16, 116, W - 32, 220));
         rows = new Sprite();
         rows.x = 26;
         rows.y = 124;
         box.addChild(rows);
         said = RUI.text(12, 0x8A3B00, true, W - 40);
         said.x = 20;
         said.y = 346;
         box.addChild(said);
         LayerManager.getBaseTop().addChild(top);
         SocketClient.instance.addEventListener("getAccount", onAccounts);
         SocketClient.instance.addEventListener("despositAccount", onDeposited);
         SocketClient.instance.addEventListener("takeAwawyAccount", onTaken);
         refresh();
      }

      private function refresh():void
      {
         said.text = "正在查看你的存款……";
         SocketClient.instance.sendXtMessage(EXT, "getAccount", {});
      }

      private function onAccounts(e:SocketClientEvent):void
      {
         accounts = [];
         for each (var a:Object in (e.params.al as Array) || []) accounts[int(a.id)] = a;
         if (e.params.now != null) serverOffset = Number(e.params.now) - new Date().time;
         draw();
         said.text = "";
      }

      private function now():Number
      {
         return new Date().time + serverOffset;
      }

      private function draw():void
      {
         money.text = "身上的晶币：" + Math.max(0, UserInfo.score);
         while (rows.numChildren) rows.removeChildAt(0);
         for (var i:int = 0; i < 5; i++)
         {
            var row:Sprite = new Sprite();
            row.y = i * 42;
            row.graphics.lineStyle(1.5, 0xF2C27A);
            row.graphics.beginFill(0xFFFFFF, 0.9);
            row.graphics.drawRoundRect(0, 0, W - 52, 36, 12, 12);
            row.graphics.endFill();
            var t:TextField = RUI.text(13, RUI.BLUE, true, W - 200);
            t.x = 10;
            t.y = 8;
            row.addChild(t);
            var a:Object = accounts[i];
            if (a == null)
            {
               t.text = "存款箱 " + (i + 1) + "：空着";
               row.addChild(place(RUI.button("存入", deposit(i), 70, 26, 0x6CC0F5, 0x2E86D6, "fortuneStore" + i), W - 140, 5));
            }
            else
            {
               var end:Number = Number(a.sd) + int(a.d) * DAY;
               var left:Number = end - now();
               var interest:int = int(Number(a.sc) * int(a.d) * int(a.d) / 1000);
               t.text = "存款箱 " + (i + 1) + "：" + a.sc + " 晶币，存 " + a.d + " 天，" +
                  (left <= 0 ? "已到期（利息 " + interest + "）" : "还有 " + countdown(left) + "到期");
               row.addChild(place(RUI.button(left <= 0 ? "取出" : "提前取出", takeOut(i, left), 84, 26, 0xFFC45A, 0xF07812, "fortuneTake" + i), W - 154, 5));
            }
            rows.addChild(row);
         }
      }

      private static function countdown(ms:Number):String
      {
         var h:int = Math.ceil(ms / 3600000);
         return h >= 24 ? int(h / 24) + "天" + (h % 24 ? h % 24 + "小时" : "") : h + "小时";
      }

      private static function place(s:Sprite, x:Number, y:Number):Sprite
      {
         s.x = x;
         s.y = y;
         return s;
      }

      private function deposit(i:int):Function
      {
         return function():void { askDeposit(i); };
      }

      private function askDeposit(slot:int):void
      {
         var p:Sprite = new Sprite();
         p.name = "fortuneStorePanel";
         p.addChild(RUI.dim(function():void { if (p.parent) p.parent.removeChild(p); }));
         var b:Sprite = RUI.panel(380, 230, "存入晶币", function():void { if (p.parent) p.parent.removeChild(p); }, "fortuneStoreClose");
         b.x = (960 - 380) / 2;
         b.y = (560 - 230) / 2;
         p.addChild(b);
         var l1:TextField = RUI.text(14, RUI.BLUE, true);
         l1.text = "存入晶币";
         l1.x = 30;
         l1.y = 62;
         b.addChild(l1);
         var amount:TextField = RUI.input(120, String(Math.min(Math.max(1000, UserInfo.score), 1000000)), "0-9", 7, "fortuneAmount");
         amount.x = 120;
         amount.y = 60;
         b.addChild(amount);
         var l2:TextField = RUI.text(14, RUI.BLUE, true);
         l2.text = "存几天";
         l2.x = 30;
         l2.y = 100;
         b.addChild(l2);
         var days:int = 7;
         var dayText:TextField = RUI.text(14, 0xC25A00, true);
         dayText.x = 160;
         dayText.y = 100;
         b.addChild(dayText);
         var hint:TextField = RUI.text(12, 0x557799, false, 330);
         hint.x = 30;
         hint.y = 136;
         b.addChild(hint);
         var update:Function = function():void
         {
            dayText.text = days + " 天";
            var sc:int = int(amount.text);
            hint.text = "到期可得利息约 " + int(sc * days * days / 1000) + " 晶币（存1000到1000000晶币）";
         };
         b.addChild(place(RUI.smallButton("－", function():void { days = Math.max(1, days - 1); update(); }, 30, 24, "fortuneDayLess"), 120, 98));
         b.addChild(place(RUI.smallButton("＋", function():void { days = Math.min(7, days + 1); update(); }, 30, 24, "fortuneDayMore"), 210, 98));
         amount.addEventListener("change", function(e:*):void { update(); });
         update();
         b.addChild(place(RUI.button("确定", function():void
         {
            var sc:int = int(amount.text);
            if (sc < 1000) { hint.text = "要存入1000晶币以上才行哦！"; return; }
            if (sc > 1000000) { hint.text = "每个存款箱最多存1000000晶币哦！"; return; }
            if (sc > UserInfo.score) { hint.text = "你身上的晶币不够哦！"; return; }
            SocketClient.instance.sendXtMessage(EXT, "despositAccount", {ai: slot, sc: sc, d: days});
            if (p.parent) p.parent.removeChild(p);
            said.text = "正在存入……";
         }, 90, 30, 0xFFC45A, 0xF07812, "fortuneStoreOk"), 145, 180));
         LayerManager.getBaseTop().addChild(p);
      }

      private function onDeposited(e:SocketClientEvent):void
      {
         said.text = e.params.b ? "存好啦！到期以后来取，利息会一起给你。" : "存款失败！";
         refresh();
      }

      private function takeOut(i:int, left:Number):Function
      {
         return function():void
         {
            var a:Object = accounts[i];
            if (a == null) return;
            if (left > 0)
            {
               var elapsed:int = int((now() - Number(a.sd)) / DAY);
               said.text = elapsed < 1
                  ? "存了不到一天，提前取出没有利息哦。再点一次「提前取出」就取出。"
                  : "提前取出只能得到 " + int(Number(a.sc) * elapsed * 0.001) + " 晶币利息。再点一次「提前取出」就取出。";
               if (confirmed != i) { confirmed = i; return; }
            }
            confirmed = -1;
            SocketClient.instance.sendXtMessage(EXT, "takeAwawyAccount", {ai: i});
         };
      }

      private var confirmed:int = -1;

      private function onTaken(e:SocketClientEvent):void
      {
         var back:int = int(e.params.res);
         said.text = back < 0 ? "没有取到。" : "取出了 " + back + " 晶币" + (int(e.params.interest) > 0 ? "（其中利息 " + int(e.params.interest) + "）" : "") + "！";
         refresh();
      }

      private function close():void
      {
         SocketClient.instance.removeEventListener("getAccount", onAccounts);
         SocketClient.instance.removeEventListener("despositAccount", onDeposited);
         SocketClient.instance.removeEventListener("takeAwawyAccount", onTaken);
         if (top != null && top.parent) top.parent.removeChild(top);
         top = null;
      }
   }
}
