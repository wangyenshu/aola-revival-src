package mmo.scene.hotspringscene
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.scene.SceneBase;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.revival.RUI;

   /**
    * LATER scene/summerhotspring (欢乐岛): the January 2013 scene is lost;
    * the live one (2020) needs the hot-spring services and effects of later
    * years (HotSpringSeason, BitmapMovieCacher, scene commands). This is its
    * code cut down to the 2013 engine, on its own art, with the hot spring
    * itself rebuilt after the later hotspring/hotspringservice and its
    * HotSpringExtension commands (in the water one may walk about the spring,
    * the art's "pool", as the later service let one; clicks outside it are
    * refused):
    *
    * 更衣室 offers the five costumes of December 2012 (effect/hotspring_avatar1–5,
    * mmo.hotspring.Avatar<n>: a crab, a sausage … floating in the water); in
    * one, the player sits in the spring (HotSpringConfig's spring join point)
    * for the time left today (15 minutes, HotSpringConfig.DefaultLeftTime,
    * 100_10), gathering experience every 3 seconds; 离开温泉, or the time
    * running out, hands it to the HELLO's 经验分配器 (100_12) and steps out.
    * 增效道具 sells the two HotSpringPropConfig goods for 星币 (甜甜牛奶 +5
    * minutes, 3 a day; 章鱼烧 double experience for the day). The experience
    * per 3 seconds is the server's (RECONSTRUCTED).
    */
   public class SummerHotSpringRevived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      private static const EXT:String = "HotSpringExtension";
      private static const STEP_EXP:int = 20;
      private static const JOIN_X:int = 352, JOIN_Y:int = 399;
      private static const OUT_X:int = 777, OUT_Y:int = 415;

      private var panel:Sprite;
      private var hud:Sprite;
      private var hudText:TextField;
      private var costume:MovieClip;
      private var hidden:DisplayObject;
      private var soaking:Boolean;
      private var startedAt:int;
      private var leftAtStart:int;
      private var exp:int;
      private var doubled:Boolean;
      private var lastStep:int;
      private var wantedCostume:int;
      private var pool:DisplayObject;

      public function SummerHotSpringRevived()
      {
         super(750, 390);
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         clickable(backGround.getChildByName("btnChangeClothes"), "更衣室", openChange);
         clickable(background ? background.getChildByName("btnSale") : null, "增效道具", openShop);
         SocketClient.instance.addEventListener("100_10", onIn);
         SocketClient.instance.addEventListener("100_12", onOut);
         SocketClient.instance.addEventListener("100_20", onBought);
      }

      override protected function onLeaveRoom():void
      {
         if (soaking) leave(false);
         closePanel();
         SocketClient.instance.removeEventListener("100_10", onIn);
         SocketClient.instance.removeEventListener("100_12", onOut);
         SocketClient.instance.removeEventListener("100_20", onBought);
         removeEventListener(Event.ENTER_FRAME, onTick);
         if (hud != null && hud.parent) hud.parent.removeChild(hud);
         super.onLeaveRoom();
      }

      private static function clickable(d:*, tip:String, act:Function):void
      {
         var io:InteractiveObject = d as InteractiveObject;
         if (io == null) return;
         TipsManager.getInstance().addTips(io, tip);
         io.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         io.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            act();
         });
      }

      // ---------------------------------------------------------------- 更衣室

      private function openChange():void
      {
         if (soaking)
         {
            RNotice.show(LayerManager.getBaseTop(), "已经在泡温泉啦！点上面的「离开温泉」就可以出来。");
            return;
         }
         var W:int = 520, H:int = 270;
         var box:Sprite = makePanel(W, H, "更衣室", "hotSpringChangeClose");
         var said:TextField = RUI.text(13, RUI.BLUE, false, W - 40);
         said.x = 20;
         said.y = 54;
         said.text = "换上一套泳装，就能下水泡温泉了！泡温泉得到的经验会放进亚比经验分配器。";
         box.addChild(said);
         for (var n:int = 1; n <= 5; n++)
         {
            var cell:Sprite = new Sprite();
            cell.name = "hotSpringCostume" + n;
            cell.buttonMode = true;
            cell.mouseChildren = false;
            cell.graphics.lineStyle(2, 0x7FBDE6);
            cell.graphics.beginFill(0xFFFFFF, 0.9);
            cell.graphics.drawRoundRect(0, 0, 88, 110, 14, 14);
            cell.graphics.endFill();
            cell.x = 22 + (n - 1) * 96;
            cell.y = 100;
            var pic:Sprite = new Sprite();
            pic.x = 44;
            pic.y = 90;
            cell.addChild(pic);
            loadCostume(n, function(mc:MovieClip, into:Sprite):void
            {
               mc.gotoAndStop(1);
               var b:Object = mc.getBounds(mc);
               var k:Number = Math.min(1, 80 / Math.max(1, b.width), 84 / Math.max(1, b.height));
               mc.scaleX = mc.scaleY = k;
               into.addChild(mc);
            }, pic);
            cell.addEventListener(MouseEvent.CLICK, wear(n));
            box.addChild(cell);
         }
      }

      private function wear(n:int):Function
      {
         return function(e:MouseEvent):void
         {
            e.stopPropagation();
            wantedCostume = n;
            closePanel();
            SocketClient.instance.sendXtMessage(EXT, "100_10", {id: n});
         };
      }

      private static function loadCostume(n:int, put:Function, into:Sprite):void
      {
         var cls:String = "mmo.hotspring.Avatar" + n;
         var make:Function = function(... a):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var mc:MovieClip = new C() as MovieClip;
            if (mc != null) put(mc, into);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) make();
         else ResScheduler.getResource("effect/hotspring_avatar" + n, make, "", function(e:* = null):void { RLog.log("hotspring: no costume " + n); });
      }

      // ---------------------------------------------------------------- soaking

      private function onIn(e:SocketClientEvent):void
      {
         var lt:int = int(e.params.lt);
         if (int(e.params.res) != 1 || lt <= 0)
         {
            RNotice.show(LayerManager.getBaseTop(), "今天泡温泉的时间用完了，明天再来吧！也可以去增效道具买甜甜牛奶加时间。");
            return;
         }
         var me:Player = PlayerManager.getInstance().myPlayer as Player;
         if (me == null) return;
         soaking = true;
         leftAtStart = lt;
         doubled = int(e.params.db) == 1;
         startedAt = getTimer();
         lastStep = 0;
         exp = 0;
         me.stop();
         me.setStrategy(null);
         me.x = JOIN_X;
         me.y = JOIN_Y;
         loadCostume(wantedCostume, function(mc:MovieClip, into:Sprite):void
         {
            if (!soaking) return;
            costume = mc;
            costume.name = "hotSpringCostume";
            costume.mouseEnabled = costume.mouseChildren = false;
            costume.play();
            hidden = me.avatarSprite;
            if (hidden != null) hidden.visible = false;
            me.addChild(costume);
         }, null);
         showHud();
         addEventListener(Event.ENTER_FRAME, onTick);
         pool = findNamed(this, "pool");
         addEventListener(MouseEvent.MOUSE_DOWN, onSoakClick);
      }

      private static function findNamed(c:DisplayObjectContainer, name:String):DisplayObject
      {
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var d:DisplayObject = c.getChildAt(i);
            if (d.name == name) return d;
            if (d is DisplayObjectContainer)
            {
               var f:DisplayObject = findNamed(DisplayObjectContainer(d), name);
               if (f != null) return f;
            }
         }
         return null;
      }

      /** In the water: walk where one clicks, as long as it is in the spring. */
      private function onSoakClick(e:MouseEvent):void
      {
         if (!soaking) return;
         var me:Player = PlayerManager.getInstance().myPlayer as Player;
         if (me == null || me.parent == null) return;
         var at:Point = me.parent.globalToLocal(new Point(e.stageX, e.stageY));
         var inside:Boolean = pool != null
            ? pool.hitTestPoint(e.stageX, e.stageY, true)
            : Point.distance(at, new Point(JOIN_X, JOIN_Y)) < 160;
         if (!inside)
         {
            RNotice.show(LayerManager.getBaseTop(), "泡温泉的时候只能在温泉里走动哦，点上面的「离开温泉」就可以出来。");
            return;
         }
         me.moveTo(int(at.x), int(at.y));
      }

      private function showHud():void
      {
         if (hud == null)
         {
            hud = new Sprite();
            hud.name = "hotSpringHud";
            hud.graphics.lineStyle(2, 0x2E86D6);
            hud.graphics.beginFill(0xEAF7FF, 0.92);
            hud.graphics.drawRoundRect(0, 0, 360, 44, 18, 18);
            hud.graphics.endFill();
            hud.x = 300;
            hud.y = 8;
            hudText = RUI.text(14, RUI.BLUE, true);
            hudText.x = 14;
            hudText.y = 12;
            hud.addChild(hudText);
            var out:Sprite = RUI.button("离开温泉", function():void { leave(true); }, 96, 30, 0xFFC45A, 0xF07812, "hotSpringLeave");
            out.x = 254;
            out.y = 7;
            hud.addChild(out);
         }
         LayerManager.getBaseTop().addChild(hud);
         updateHud();
      }

      private function get elapsed():int
      {
         return int((getTimer() - startedAt) / 1000);
      }

      private function updateHud():void
      {
         var left:int = Math.max(0, leftAtStart - elapsed);
         var m:int = int(left / 60), s:int = left % 60;
         hudText.text = "泡温泉中  " + m + ":" + (s < 10 ? "0" : "") + s + "    经验 " + exp + (doubled ? "（双倍）" : "");
      }

      private function onTick(e:Event):void
      {
         if (!soaking) return;
         var sec:int = elapsed;
         if (sec >= leftAtStart)
         {
            leave(true);
            return;
         }
         var steps:int = int(sec / 3);
         if (steps > lastStep)
         {
            var add:int = (steps - lastStep) * STEP_EXP * (doubled ? 2 : 1);
            lastStep = steps;
            exp += add;
            floatText("+" + add);
         }
         updateHud();
      }

      private function floatText(s:String):void
      {
         var me:Player = PlayerManager.getInstance().myPlayer as Player;
         if (me == null || me.parent == null) return;
         var t:TextField = RUI.text(14, 0xFFE24A, true);
         t.text = s;
         t.x = me.x - t.width / 2;
         t.y = me.y - 90;
         me.parent.addChild(t);
         var born:int = getTimer();
         t.addEventListener(Event.ENTER_FRAME, function(ev:Event):void
         {
            var age:int = getTimer() - born;
            t.y -= 0.6;
            t.alpha = 1 - age / 1200;
            if (age > 1200)
            {
               t.removeEventListener(Event.ENTER_FRAME, arguments.callee);
               if (t.parent) t.parent.removeChild(t);
            }
         });
      }

      /** Out of the water: the experience to the 经验分配器 (unless the scene is being left), the player as before. */
      private function leave(tell:Boolean):void
      {
         if (!soaking) return;
         soaking = false;
         removeEventListener(Event.ENTER_FRAME, onTick);
         removeEventListener(MouseEvent.MOUSE_DOWN, onSoakClick);
         var sec:int = Math.min(leftAtStart, elapsed);
         SocketClient.instance.sendXtMessage(EXT, "100_12", {exp: exp, sec: sec});
         if (hud != null && hud.parent) hud.parent.removeChild(hud);
         var me:Player = PlayerManager.getInstance().myPlayer as Player;
         if (costume != null && costume.parent) costume.parent.removeChild(costume);
         costume = null;
         if (hidden != null) hidden.visible = true;
         hidden = null;
         if (me != null && tell)
         {
            me.x = OUT_X;
            me.y = OUT_Y;
            me.setStrategy(new MouseControlStrategy());
         }
         else if (me != null) me.setStrategy(new MouseControlStrategy());
      }

      private function onOut(e:SocketClientEvent):void
      {
         var got:int = int(e.params.exp);
         RNotice.show(LayerManager.getBaseTop(), got > 0 ? "此次泡温泉共获得" + got + "经验，已经将经验放入亚比经验分配器。" : "泡了一会儿温泉，真舒服！", 5);
      }

      // ---------------------------------------------------------------- 增效道具

      private function openShop():void
      {
         var W:int = 460, H:int = 250;
         var box:Sprite = makePanel(W, H, "增效道具", "hotSpringShopClose");
         var goods:Array = [[1, "甜甜牛奶", "泡温泉的时间增加5分钟（每天3次）", 2], [2, "章鱼烧", "今天泡温泉得到双倍经验（每天1次）", 11]];
         for (var i:int = 0; i < goods.length; i++)
         {
            var g:Array = goods[i];
            var t:TextField = RUI.text(14, 0x8A3B00, true);
            t.text = g[1] + "    " + g[3] + " 星币";
            t.x = 24;
            t.y = 62 + i * 64;
            box.addChild(t);
            var d:TextField = RUI.text(12, 0x557799, false, 280);
            d.text = g[2];
            d.x = 24;
            d.y = 84 + i * 64;
            box.addChild(d);
            var b:Sprite = RUI.button("购买", buy(int(g[0])), 80, 30, 0xFFC45A, 0xF07812, "hotSpringBuy" + g[0]);
            b.x = W - 110;
            b.y = 66 + i * 64;
            box.addChild(b);
         }
         var said:TextField = RUI.text(12, 0x8A3B00, true, W - 40);
         said.name = "hotSpringShopSaid";
         said.x = 20;
         said.y = H - 44;
         box.addChild(said);
      }

      private function buy(id:int):Function
      {
         return function():void { SocketClient.instance.sendXtMessage(EXT, "100_20", {id: id}); };
      }

      private function onBought(e:SocketClientEvent):void
      {
         var r:int = int(e.params.res);
         var msg:String = r == 1 ? (int(e.params.id) == 1 ? "买好了！今天还能泡 " + int(int(e.params.lt) / 60) + " 分钟。" : "买好了！今天泡温泉得到双倍经验。")
            : r == -5 ? "星币不够哦。" : "今天已经买够了。";
         if (r == 1 && soaking)
         {
            if (int(e.params.id) == 1) leftAtStart += 300;
            else doubled = true;
            updateHud();
         }
         var said:TextField = panel != null ? findSaid(panel) : null;
         if (said != null) said.text = msg;
         else RNotice.show(LayerManager.getBaseTop(), msg);
      }

      private static function findSaid(p:Sprite):TextField
      {
         for (var i:int = 0; i < p.numChildren; i++)
         {
            var c:Sprite = p.getChildAt(i) as Sprite;
            if (c == null) continue;
            var t:TextField = c.getChildByName("hotSpringShopSaid") as TextField;
            if (t != null) return t;
         }
         return null;
      }

      // ---------------------------------------------------------------- panels

      private function makePanel(W:int, H:int, title:String, closeName:String):Sprite
      {
         closePanel();
         panel = new Sprite();
         panel.name = "hotSpringPanel";
         panel.addChild(RUI.dim(closePanel));
         var box:Sprite = RUI.panel(W, H, title, closePanel, closeName);
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 20;
         panel.addChild(box);
         LayerManager.getBaseTop().addChild(panel);
         return box;
      }

      private function closePanel():void
      {
         if (panel != null && panel.parent != null) panel.parent.removeChild(panel);
         panel = null;
      }
   }
}
