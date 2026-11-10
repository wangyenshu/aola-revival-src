package mmo.usercard
{
   import flash.utils.getTimer;
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.external.ExternalInterface;
   import flash.utils.Timer;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetEggClient;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.IAlbumAvatarProxy;
   import mmo.interfaces.avatar.IAvatarService;
   import mmo.interfaces.material.IMaterialFactory;
   import mmo.interfaces.material.IMaterialService;
   import mmo.interfaces.material.Material;
   import mmo.interfaces.material.UserMaterial;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.interfaces.material.clothes.UserClothes;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RAvatar;
   import mmo.revival.RLog;
   import mmo.revival.RMaterialView;
   import mmo.revival.RUI;
   import mmo.revival.SavePanels;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClientEvent;

   /**
    * REBUILT 人物信息卡, laid out as the 2012 one (百田's 游戏帮助 of January 2012, 人物信息卡: the
    * card's art is lost with usercard/usercardservice, so it is drawn after that picture). Left, the
    * 奥拉形象 on its stand, the name plate (奥拉名字, 多多号), 晶币数 and 星币数. Right, the panel with
    * its tabs on top (显示奥拉信息; 勋章, "展示和介绍你所获得的勋章": UserCardBadgeService's page, as the
    * card held it) and, on one's own card, the buttons at its right edge: 人物信息 ("可查看和修改人物
    * 信息"), 服装 ("可查看拥有的服装": a click puts a piece on or takes it off, ClothesService
    * .wearMyOwnClothesById), 道具 ("可查看拥有的道具": what the revival's 物品 shows, by kind) and VIP物品
    * ("可查看拥有的VIP物品": the things of 蓝宝石 one has). Another 奥拉's card has his actions down the
    * panel's left edge (加为好友, 邀请亚比对战, 邀请组队, 他的HELLO, 参观空间舱) and 查看TA的资料.
    */
   public class UserCardPanel extends Sprite
   {
      private static const W:int = 540;
      private static const H:int = 340;
      /** The right panel. */
      private static const PX:int = 206, PY:int = 40, PW:int = 274, PH:int = 278;
      /** The grid inside it. */
      private static const COLS:int = 4;
      private static const ROWS:int = 3;
      private static const CELL:int = 54;
      private static const GX:int = PX + 24, GY:int = PY + 52;
      /** [label, material type] of the 道具 kinds. */
      private static const KINDS:Array = [["道具", 2], ["亚比蛋", 5], ["种植", 10], ["射击卡", 4]];

      private var userName:String;
      private var own:Boolean;
      private var box:Sprite;
      private var stand:Sprite;
      private var avatar:IAlbumAvatarProxy;
      private var content:Sprite;
      private var clothes:IClothesService;
      private var view:String;
      private var page:int;
      private var kind:int;
      private var eggs:Array;
      private var tabs:Object = {};
      private var sideButtons:Object = {};
      private var scoreText:TextField;
      private var coinText:TextField;

      public function UserCardPanel(userName:String, tab:int)
      {
         super();
         name = "userCard";
         this.userName = userName;
         own = userName == SocketClient.instance.myUserName;
         try { clothes = ServiceContainer.getService(IClothesService) as IClothesService; } catch (e:Error) { RLog.error("usercard clothes", e); }
         build();
         LayerManager.getBaseTop().addChild(this);
         showAvatar();
         if (own)
         {
            SocketClient.instance.addEventListener(PetEggClient.cmdGetEggs, onEggs);
            try { PetEggClient.instance.getEggs(); } catch (e2:Error) { RLog.error("usercard eggs", e2); }
         }
         show(own ? "clothes" : "other");
      }

      // ------------------------------------------------------------------ frame

      private function build():void
      {
         addChild(RUI.dim(close));
         box = new Sprite();
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 16;
         box.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         box.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         addChild(box);
         var g:Graphics = box.graphics;
         var m:Matrix = new Matrix();
         // The blue frame with its light rim.
         m.createGradientBox(W, H, Math.PI / 2);
         g.lineStyle(3, 0x1B5FA8);
         g.beginGradientFill(GradientType.LINEAR, [0x7FD3FA, 0x2F8FE0], [1, 1], [0, 255], m);
         g.drawRoundRect(0, 0, W, H, 34, 34);
         g.endFill();
         g.lineStyle(2, 0xC9F0FF, 0.9);
         g.drawRoundRect(5, 5, W - 10, H - 10, 28, 28);
         box.filters = [new DropShadowFilter(4, 90, 0, 0.45, 10, 10)];

         // Left: the 奥拉 on its stand.
         var left:Shape = new Shape();
         var lg:Graphics = left.graphics;
         m.createGradientBox(180, 70, Math.PI / 2, 14, 236);
         lg.beginFill(0x0E5BAE, 0.35);
         lg.drawRoundRect(14, 18, 180, H - 36, 24, 24);
         lg.endFill();
         lg.lineStyle(2, 0xBFF2FF, 0.9);
         lg.beginGradientFill(GradientType.LINEAR, [0x9BE8FF, 0x2C9BE6], [1, 1], [0, 255], m);
         lg.drawEllipse(44, 226, 120, 30);
         lg.endFill();
         box.addChild(left);
         stand = new Sprite();
         stand.x = 104;
         stand.y = 240;
         box.addChild(stand);
         // The name plate (奥拉名字, 多多号).
         var plate:Shape = new Shape();
         m.createGradientBox(150, 38, Math.PI / 2, 29, 256);
         plate.graphics.lineStyle(2, 0xDDF6FF);
         plate.graphics.beginGradientFill(GradientType.LINEAR, [0x2E7FD0, 0x16539A], [1, 1], [0, 255], m);
         plate.graphics.drawRoundRect(29, 256, 150, 38, 16, 16);
         plate.graphics.endFill();
         box.addChild(plate);
         var nm:TextField = text(14, 0xFFFFFF, true);
         nm.text = nickName();
         nm.x = 104 - nm.width / 2;
         nm.y = 258;
         box.addChild(nm);
         var num:TextField = text(11, 0xBFEFFF, false);
         num.text = own ? "(" + UserInfo.userId + ")" : "";
         num.x = 104 - num.width / 2;
         num.y = 276;
         box.addChild(num);
         if (own)
         {
            // 晶币数 and 星币数.
            scoreText = counter(26, 300, 0xF6C531, "晶币");
            coinText = counter(108, 300, 0xE8473A, "星币");
            showMoney();
         }

         // Right: the panel.
         var panel:Shape = new Shape();
         m.createGradientBox(PW, PH, Math.PI / 2, PX, PY);
         panel.graphics.lineStyle(3, 0x1E78CC);
         panel.graphics.beginGradientFill(GradientType.LINEAR, [0xF4FCFF, 0xC8EBFB], [1, 1], [0, 255], m);
         panel.graphics.drawRoundRect(PX, PY, PW, PH, 22, 22);
         panel.graphics.endFill();
         box.addChild(panel);
         content = new Sprite();
         box.addChild(content);
         // Its tabs on top: 显示奥拉信息, 勋章.
         tab("info", own ? "显示奥拉信息" : "查看TA的资料", PX + 80, PY, drawPerson);
         tab("badge", "展示和介绍" + (own ? "你" : "TA") + "所获得的勋章", PX + 194, PY, drawMedal);
         if (own)
         {
            var side:Array = [["mine", "可查看和修改人物信息", drawNote], ["clothes", "可查看拥有的服装", drawShirt],
               ["items", "可查看拥有的道具", drawBag], ["vip", "可查看拥有的VIP物品", drawVip]];
            for (var i:int = 0; i < side.length; i++)
               sideButtons[side[i][0]] = roundButton("card_" + side[i][0], side[i][1], PX + PW + 2, PY + 50 + i * 54, 19, side[i][2], showFn(side[i][0]));
         }
         else otherButtons();

         var x:Sprite = roundButton("cardClose", "", W - 14, 14, 15, drawCross, close, 0xE2492F, 0xB52A15);
         box.addChild(x);
      }

      private function showFn(v:String):Function
      {
         return function():void { show(v); };
      }

      /** A tab on the panel's top edge. */
      private function tab(v:String, tip:String, x:int, y:int, icon:Function):void
      {
         tabs[v] = roundButton("cardTab_" + v, tip, x, y, 18, icon, showFn(v), 0xFFE07A, 0xF2A20C);
      }

      /** A round button with a drawn icon (and its tip). */
      private function roundButton(name:String, tip:String, x:Number, y:Number, r:Number, icon:Function, f:Function, top:uint = 0x9FE6FF, bottom:uint = 0x2B8EE0):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = name;
         b.buttonMode = true;
         b.mouseChildren = false;
         var m:Matrix = new Matrix();
         m.createGradientBox(r * 2, r * 2, Math.PI / 2, -r, -r);
         b.graphics.lineStyle(2.5, 0xFFFFFF);
         b.graphics.beginGradientFill(GradientType.LINEAR, [top, bottom], [1, 1], [0, 255], m);
         b.graphics.drawCircle(0, 0, r);
         b.graphics.endFill();
         var ic:Shape = new Shape();
         icon(ic.graphics, r);
         b.addChild(ic);
         b.x = x;
         b.y = y;
         b.filters = [new DropShadowFilter(2, 90, 0x0A3D78, 0.5, 3, 3)];
         if (tip) TipsManager.getInstance().addTips(b, tip);
         b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { b.filters = [new GlowFilter(0xFFFFFF, 1, 8, 8, 3)]; });
         b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { b.filters = [new DropShadowFilter(2, 90, 0x0A3D78, 0.5, 3, 3)]; });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
         box.addChild(b);
         return b;
      }

      /** 晶币数 / 星币数: a coin and its number in a small bar. */
      private function counter(x:int, y:int, coin:uint, tip:String):TextField
      {
         var bar:Sprite = new Sprite();
         bar.graphics.lineStyle(1.5, 0xDDF6FF);
         bar.graphics.beginFill(0x0F4F95, 0.85);
         bar.graphics.drawRoundRect(0, 0, 76, 20, 18, 18);
         bar.graphics.endFill();
         bar.graphics.lineStyle(1.5, 0xFFFFFF);
         bar.graphics.beginFill(coin);
         bar.graphics.drawCircle(10, 10, 7);
         bar.graphics.endFill();
         bar.x = x;
         bar.y = y;
         box.addChild(bar);
         TipsManager.getInstance().addTips(bar, tip);
         var t:TextField = text(11, 0xFFFFFF, true);
         t.x = x + 20;
         t.y = y + 2;
         box.addChild(t);
         return t;
      }

      private function showMoney():void
      {
         if (scoreText) scoreText.text = UserInfo.score < 0 ? "…" : String(UserInfo.score);
         if (coinText) coinText.text = String(UserInfo.xingbi);
      }

      // ------------------------------------------------------------------ views

      private function clear():void
      {
         while (content.numChildren) content.removeChildAt(0);
      }

      /** The panel's page: clothes, items, vip, mine, info, badge, other. */
      private function show(v:String):void
      {
         if (v != view) { page = 0; }
         view = v;
         clear();
         for (var k:String in sideButtons) sideButtons[k].alpha = k == v ? 1 : 0.75;
         for (k in tabs) tabs[k].alpha = (k == v || (k == "info" && v != "badge")) ? 1 : 0.7;
         switch (v)
         {
            case "clothes": showClothes(); break;
            case "items": showItems(); break;
            case "vip": showVip(); break;
            case "badge": showBadges(); break;
            case "info": if (own) showClothes(); else showOther(); break;
            case "mine": showMine(); break;
            default: showOther();
         }
      }

      private function heading(s:String):void
      {
         var t:TextField = text(14, 0x1A5FA8, true);
         t.text = s;
         t.x = PX + PW / 2 - t.width / 2;
         t.y = PY + 24;
         content.addChild(t);
      }

      /** Cells of a grid page; things: [{id, qty, material, worn}], cellFn(thing):Sprite. */
      private function grid(things:Array, cellFn:Function, empty:String):void
      {
         var per:int = COLS * ROWS;
         var pages:int = Math.max(1, Math.ceil(things.length / per));
         page = Math.max(0, Math.min(page, pages - 1));
         for (var i:int = 0; i < per; i++)
         {
            var x:int = GX + (i % COLS) * (CELL + 4), y:int = GY + int(i / COLS) * (CELL + 4);
            var t:Object = page * per + i < things.length ? things[page * per + i] : null;
            var c:Sprite = t != null ? cellFn(t) : slot();
            c.x = x;
            c.y = y;
            content.addChild(c);
         }
         if (things.length == 0)
         {
            var e:TextField = text(12, 0x557799, false);
            e.text = empty;
            e.x = PX + PW / 2 - e.width / 2;
            e.y = GY + ROWS * (CELL + 4) / 2 - 8;
            content.addChild(e);
         }
         // ◀ 1/4 ▶
         var pt:TextField = text(12, 0x1A5FA8, true);
         pt.text = (page + 1) + "/" + pages;
         pt.x = PX + PW / 2 - pt.width / 2;
         pt.y = PY + PH - 30;
         content.addChild(pt);
         var prev:Sprite = arrow(-1, PX + PW / 2 - 34, PY + PH - 22);
         var next:Sprite = arrow(1, PX + PW / 2 + 34, PY + PH - 22);
         content.addChild(prev);
         content.addChild(next);
      }

      private function arrow(dir:int, x:int, y:int):Sprite
      {
         var a:Sprite = new Sprite();
         a.name = dir < 0 ? "cardPrev" : "cardNext";
         a.buttonMode = true;
         a.graphics.beginFill(0x2B8EE0);
         a.graphics.moveTo(7 * dir, 0);
         a.graphics.lineTo(-6 * dir, -7);
         a.graphics.lineTo(-6 * dir, 7);
         a.graphics.endFill();
         a.x = x;
         a.y = y;
         a.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            page += dir;
            show(view);
         });
         return a;
      }

      private function slot(worn:Boolean = false):Sprite
      {
         var c:Sprite = new Sprite();
         c.graphics.lineStyle(2, worn ? 0xFF9900 : 0x8CC8EE);
         c.graphics.beginFill(0xFFFFFF, 0.95);
         c.graphics.drawRoundRect(0, 0, CELL, CELL, 10, 10);
         c.graphics.endFill();
         return c;
      }

      /** A thing's cell: its picture, how many, its name and description in the tip. */
      private function thingCell(svc:IMaterialService, id:int, qty:int, m:Material, worn:Boolean = false):Sprite
      {
         var c:Sprite = slot(worn);
         c.name = "cardThing_" + id;
         var square:Sprite = new Sprite();
         square.graphics.beginFill(0, 0);
         square.graphics.drawRect(5, 5, CELL - 10, CELL - 10);
         square.graphics.endFill();
         square.mouseEnabled = square.mouseChildren = false;
         c.addChild(square);
         RMaterialView.into(RMaterialView.of(svc, id), square, 0);
         if (qty > 1)
         {
            var n:TextField = text(11, 0xC25A00, true);
            n.text = "×" + qty;
            n.x = CELL - 3 - n.width;
            n.y = CELL - 17;
            c.addChild(n);
         }
         if (worn)
         {
            var tick:TextField = text(13, 0xFF7700, true);
            tick.text = "✔";
            tick.x = CELL - 16;
            tick.y = -1;
            c.addChild(tick);
         }
         var nm:String = m ? m.name : String(id);
         var desc:String = "";
         try { if (m && m.hasOwnProperty("description")) desc = String(Object(m).description || ""); } catch (e2:Error) {}
         try { TipsManager.getInstance().addTips(c, nm + (desc ? "\n" + desc : ""), 160); } catch (e3:Error) {}
         return c;
      }

      // 服装
      private function showClothes():void
      {
         heading("我的服装");
         var list:Array = [];
         if (clothes != null)
         {
            for each (var u:* in clothes.getMyClothesInfos())
               if (u is UserClothes && UserClothes(u).materialId > 22) list.push(u); // 1-22 are the body itself
            list.sortOn("materialId", Array.NUMERIC | Array.DESCENDING);
         }
         grid(list, function(uc:UserClothes):Sprite
         {
            var c:Sprite = thingCell(IMaterialService(clothes), uc.materialId, 1, uc.material, uc.isWearing());
            c.buttonMode = true;
            c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               e.stopPropagation();
               try
               {
                  clothes.wearMyOwnClothesById(uc.materialId);
                  redrawAvatar();
               }
               catch (err:Error) { RLog.error("usercard wear " + uc.materialId, err); }
               show("clothes");
            });
            return c;
         }, "还没有服装哦。");
      }

      private static function service(type:int):IMaterialService
      {
         try
         {
            var f:IMaterialFactory = ServiceContainer.getService(IMaterialFactory) as IMaterialFactory;
            return f ? f.getService(type) : null;
         }
         catch (e:Error) { RLog.error("usercard service " + type, e); }
         return null;
      }

      /** What one has of a kind: [{id, qty, material}]; the 亚比蛋 as the server listed them. */
      private function things(type:int):Array
      {
         var svc:IMaterialService = service(type);
         var list:Array = [];
         if (type == 5 && eggs != null)
         {
            for each (var eg:Object in eggs)
            {
               var em:Material = null;
               try { em = svc ? svc.getMaterialById(eg.id) : null; } catch (e1:Error) {}
               list.push({id: eg.id, qty: eg.qty, material: em, type: type});
            }
         }
         else if (svc != null)
         {
            try
            {
               for each (var u:* in svc.getMyMaterials())
                  if (u is UserMaterial && UserMaterial(u).quantity > 0)
                     list.push({id: UserMaterial(u).materialId, qty: UserMaterial(u).quantity, material: UserMaterial(u).material, type: type});
            }
            catch (e:Error) { RLog.error("usercard items", e); }
         }
         list.sortOn("id", Array.NUMERIC);
         return list;
      }

      private function onEggs(e:SocketClientEvent):void
      {
         var count:Object = {};
         var order:Array = [];
         for each (var o:Object in (e.params.es as Array) || [])
         {
            var ri:int = int(o.ri);
            if (count[ri] == null) { count[ri] = 0; order.push(ri); }
            count[ri]++;
         }
         eggs = [];
         for each (var id:int in order) eggs.push({id: id, qty: count[id]});
         if (view == "items" && int(KINDS[kind][1]) == 5) show(view);
      }

      // 道具 (the revival's 物品, by kind)
      private function showItems():void
      {
         for (var i:int = 0; i < KINDS.length; i++)
         {
            var on:Boolean = i == kind;
            var b:Sprite = RUI.button(KINDS[i][0], kindFn(i), 56, 22, on ? 0xFFC45A : 0x9FD8FF, on ? 0xF07812 : 0x3A8FD8, "cardKind" + i);
            b.x = PX + 18 + i * 60;
            b.y = PY + 22;
            content.addChild(b);
         }
         var type:int = int(KINDS[kind][1]);
         var svc:IMaterialService = service(type);
         grid(things(type), function(t:Object):Sprite { return thingCell(svc, t.id, t.qty, t.material); },
            type == 5 && eggs == null ? "正在读取……" : "这里还没有东西。");
      }

      private function kindFn(i:int):Function
      {
         return function():void
         {
            kind = i;
            page = 0;
            show("items");
         };
      }

      // VIP物品: the things of 蓝宝石 one has (clothes and the kinds of 道具).
      private function showVip():void
      {
         heading("我的VIP物品");
         var list:Array = [];
         for each (var k:Array in [[0, null]].concat(KINDS.map(function(x:Array, i:int, a:Array):Array { return [x[1], null]; })))
         {
            var type:int = int(k[0]);
            var source:Array = type == 0 ? clothesThings() : things(type);
            for each (var t:Object in source) if (t.material && Object(t.material).hasOwnProperty("vip") && Object(t.material).vip) list.push(t);
         }
         grid(list, function(t:Object):Sprite { return thingCell(service(int(t.type)), t.id, t.qty, t.material); }, "还没有VIP物品哦。");
      }

      private function clothesThings():Array
      {
         var list:Array = [];
         if (clothes == null) return list;
         for each (var u:* in clothes.getMyClothesInfos())
            if (u is UserClothes && UserClothes(u).materialId > 22) list.push({id: UserClothes(u).materialId, qty: 1, material: UserClothes(u).material, type: 0});
         return list;
      }

      // 人物信息
      private function showMine():void
      {
         heading("人物信息");
         var member:Boolean = false;
         try { member = MemberManager.instance.isMember(); } catch (e:Error) {}
         var lines:Array = [["奥拉名字", nickName()], ["多多号", String(UserInfo.userId)], ["晶币", UserInfo.score < 0 ? "…" : String(UserInfo.score)],
            ["星币", String(UserInfo.xingbi)], ["蓝宝石", member ? "是" : "否"]];
         for (var i:int = 0; i < lines.length; i++)
         {
            var t:TextField = text(13, 0x1A3A5A, false);
            t.htmlText = "<b>" + lines[i][0] + "：</b>" + lines[i][1];
            t.x = PX + 40;
            t.y = PY + 60 + i * 28;
            content.addChild(t);
         }
         accountButtons();
      }

      /**
       * One's own card: 改名字 (both modes) and, on a shared server, 改密码 (SavePanels; the data is
       * the page's, web/saves.js): a rename ends the game, and the page logs in again with the new name.
       */
      private function accountButtons():void
      {
         var acts:Array = [["改名字", SavePanels.rename]];
         if (pageMode() == "server") acts.push(["改密码", SavePanels.password]);
         for (var i:int = 0; i < acts.length; i++)
         {
            var b:Sprite = RUI.button(acts[i][0], closeThen(acts[i][1]), 80, 26, 0x8FE3FF, 0x1E8FE0, "cardAccount" + i);
            b.x = PX + (acts.length == 1 ? PW / 2 - 40 : PW / 2 - 86 + i * 92);
            b.y = PY + PH - 50;
            content.addChild(b);
         }
      }

      // 勋章: UserCardBadgeService's page, fitted into the panel.
      private function showBadges():void
      {
         var mine:String = view;
         ServiceContainer.instance.tryGetService("UserCardBadgeService", function(svc:IService, o:Object):void
         {
            if (view != mine || parent == null) return;
            var p:Sprite = null;
            try { p = Object(svc).getBadgePanel(userName) as Sprite; } catch (e:Error) { RLog.error("usercard badges", e); }
            if (p == null) return;
            var holder:Sprite = new Sprite();
            holder.addChild(p);
            var b:Rectangle = p.getBounds(p);
            var k:Number = Math.min(1, (PW - 16) / Math.max(1, b.width), (PH - 34) / Math.max(1, b.height));
            p.scaleX = p.scaleY = k;
            p.x = PX + (PW - b.width * k) / 2 - b.left * k;
            p.y = PY + 26 + (PH - 34 - b.height * k) / 2 - b.top * k;
            content.addChild(holder);
         });
      }

      // Another 奥拉's card.
      private function showOther():void
      {
         var big:Sprite = new Sprite();
         big.name = "cardOtherInfo";
         var r:int = 34;
         var m:Matrix = new Matrix();
         m.createGradientBox(r * 2, r * 2, Math.PI / 2, -r, -r);
         big.graphics.lineStyle(3, 0xFFFFFF);
         big.graphics.beginGradientFill(GradientType.LINEAR, [0xFFE07A, 0xF2A20C], [1, 1], [0, 255], m);
         big.graphics.drawCircle(0, 0, r);
         big.graphics.endFill();
         var ic:Shape = new Shape();
         drawPerson(ic.graphics, r);
         big.addChild(ic);
         big.x = PX + PW / 2 + 16;
         big.y = PY + PH / 2 - 20;
         content.addChild(big);
         var t:TextField = text(13, 0x1A5FA8, true);
         t.text = nickName();
         t.x = big.x - t.width / 2;
         t.y = big.y + r + 10;
         content.addChild(t);
         var s:TextField = text(12, 0x557799, false);
         s.text = "查看TA的资料";
         s.x = big.x - s.width / 2;
         s.y = t.y + 22;
         content.addChild(s);
      }

      /**
       * Another 奥拉's actions down the panel's left edge, as the 2012 card had them (a shared
       * server): 加为好友, 邀请亚比对战 (duel.ts), 邀请组队, 他的HELLO (robot/robotanothermes) and 参观空间舱
       * (HouseLoader.loadHouse). Server: social.ts.
       */
      private function otherButtons():void
      {
         var acts:Array = [
            ["加为好友", drawPlus, function():void { ask("BuddyManagerExtension", "revival_friend_add", "revival_friend_add"); }],
            ["邀请TA进行亚比对战", drawSwords, function():void { ask("PocketMonsterExtension", "revival_duel_invite", "revival_duel_invite"); }],
            ["邀请TA组队", drawTeam, function():void { ask("TeamExtension", "revival_team_invite", "revival_team_invite"); }],
            ["TA的HELLO", drawHello, function():void
            {
               close();
               try { Object(ServiceContainer.getService("RobotDataService")).setSelectRobotId(userName); } catch (e:Error) {}
               ServiceContainer.instance.tryGetService("RobotAnotherMes", function(svc:*, o:Object = null):void
               {
                  try { Object(svc).showPanel(); } catch (e:Error) { RLog.error("usercard hello", e); }
               });
            }],
            ["参观TA的空间舱", drawHouse, function():void
            {
               close();
               ServiceContainer.instance.tryGetService("HouseService", function(svc:*, o:Object = null):void
               {
                  try { Object(svc).houseLoader.loadHouse(userName); } catch (e:Error) { RLog.error("usercard home", e); }
               });
            }]
         ];
         for (var i:int = 0; i < acts.length; i++)
            roundButton("cardAct" + i, acts[i][0], PX + 2, PY + 44 + i * 50, 17, acts[i][1], acts[i][2]);
      }

      // ------------------------------------------------------------------ icons (drawn about 0,0 in a circle of r)

      private static function drawPerson(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.5 * k, 0x8A4B00);
         g.beginFill(0xFFF3C4);
         g.drawCircle(0, -4 * k, 6 * k);
         g.endFill();
         g.beginFill(0xFF8A1E);
         g.drawRoundRect(-9 * k, 3 * k, 18 * k, 10 * k, 9 * k, 9 * k);
         g.endFill();
      }

      private static function drawMedal(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.2 * k, 0xA03000);
         g.beginFill(0xE8473A);
         g.moveTo(-6 * k, -12 * k); g.lineTo(-1 * k, -2 * k); g.lineTo(-5 * k, -2 * k); g.lineTo(-9 * k, -10 * k); g.lineTo(-6 * k, -12 * k);
         g.moveTo(6 * k, -12 * k); g.lineTo(1 * k, -2 * k); g.lineTo(5 * k, -2 * k); g.lineTo(9 * k, -10 * k); g.lineTo(6 * k, -12 * k);
         g.endFill();
         g.lineStyle(1.5 * k, 0x8A5A00);
         g.beginFill(0xFFD23A);
         g.drawCircle(0, 4 * k, 7 * k);
         g.endFill();
         g.beginFill(0xFFF3A0);
         g.drawCircle(0, 4 * k, 3 * k);
         g.endFill();
      }

      private static function drawNote(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.5 * k, 0x1A5FA8);
         g.beginFill(0xFFFFFF);
         g.drawRoundRect(-7 * k, -9 * k, 14 * k, 18 * k, 3 * k, 3 * k);
         g.endFill();
         for (var i:int = 0; i < 3; i++) { g.moveTo(-4 * k, (-4 + i * 4) * k); g.lineTo(4 * k, (-4 + i * 4) * k); }
         g.lineStyle(2.5 * k, 0xFF8A1E);
         g.moveTo(3 * k, 9 * k); g.lineTo(10 * k, 1 * k);
      }

      private static function drawShirt(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.5 * k, 0x8A1E4B);
         g.beginFill(0xFF7FB0);
         g.moveTo(-4 * k, -9 * k); g.lineTo(-11 * k, -5 * k); g.lineTo(-8 * k, 1 * k); g.lineTo(-6 * k, 0); g.lineTo(-6 * k, 9 * k);
         g.lineTo(6 * k, 9 * k); g.lineTo(6 * k, 0); g.lineTo(8 * k, 1 * k); g.lineTo(11 * k, -5 * k); g.lineTo(4 * k, -9 * k);
         g.curveTo(0, -5 * k, -4 * k, -9 * k);
         g.endFill();
      }

      private static function drawBag(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.5 * k, 0x6A3A00);
         g.beginFill(0xF2A54A);
         g.drawRoundRect(-9 * k, -4 * k, 18 * k, 13 * k, 5 * k, 5 * k);
         g.endFill();
         g.beginFill(0, 0);
         g.drawRoundRect(-5 * k, -9 * k, 10 * k, 8 * k, 6 * k, 6 * k);
         g.endFill();
         g.beginFill(0xFFE07A);
         g.drawRect(-2 * k, 0, 4 * k, 3 * k);
         g.endFill();
      }

      private static function drawVip(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.2 * k, 0x0B3D7A);
         g.beginFill(0x3FB6FF);
         g.moveTo(0, -11 * k); g.lineTo(10 * k, -3 * k); g.lineTo(0, 10 * k); g.lineTo(-10 * k, -3 * k); g.lineTo(0, -11 * k);
         g.endFill();
         g.lineStyle(1 * k, 0xFFFFFF, 0.9);
         g.moveTo(-10 * k, -3 * k); g.lineTo(10 * k, -3 * k);
         g.moveTo(-4 * k, -3 * k); g.lineTo(0, 10 * k); g.lineTo(4 * k, -3 * k);
      }

      private static function drawCross(g:Graphics, r:Number):void
      {
         g.lineStyle(3, 0xFFFFFF);
         g.moveTo(-r * 0.35, -r * 0.35); g.lineTo(r * 0.35, r * 0.35);
         g.moveTo(r * 0.35, -r * 0.35); g.lineTo(-r * 0.35, r * 0.35);
      }

      private static function drawPlus(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         drawPerson(g, r * 0.85);
         g.lineStyle(3 * k, 0x2DBE3C);
         g.moveTo(8 * k, -10 * k); g.lineTo(8 * k, -2 * k);
         g.moveTo(4 * k, -6 * k); g.lineTo(12 * k, -6 * k);
      }

      private static function drawSwords(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(3 * k, 0xE0E8F0);
         g.moveTo(-9 * k, -9 * k); g.lineTo(9 * k, 9 * k);
         g.moveTo(9 * k, -9 * k); g.lineTo(-9 * k, 9 * k);
         g.lineStyle(3 * k, 0x8A4B00);
         g.moveTo(5 * k, 9 * k); g.lineTo(9 * k, 5 * k);
         g.moveTo(-5 * k, 9 * k); g.lineTo(-9 * k, 5 * k);
      }

      private static function drawTeam(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.2 * k, 0x0B3D7A);
         g.beginFill(0xFFF3C4); g.drawCircle(-5 * k, -4 * k, 4 * k); g.drawCircle(5 * k, -4 * k, 4 * k); g.endFill();
         g.beginFill(0x3FB6FF); g.drawRoundRect(-11 * k, 1 * k, 11 * k, 9 * k, 6 * k, 6 * k); g.drawRoundRect(0, 1 * k, 11 * k, 9 * k, 6 * k, 6 * k); g.endFill();
      }

      private static function drawHello(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.2 * k, 0x2A5A2A);
         g.beginFill(0xF4FFF4); g.drawEllipse(-9 * k, -8 * k, 18 * k, 15 * k); g.endFill();
         g.beginFill(0x2A5A2A); g.drawCircle(-3 * k, -1 * k, 1.6 * k); g.drawCircle(3 * k, -1 * k, 1.6 * k); g.endFill();
         g.moveTo(0, -8 * k); g.lineTo(0, -12 * k);
         g.beginFill(0x7ED957); g.drawCircle(0, -12 * k, 2 * k); g.endFill();
      }

      private static function drawHouse(g:Graphics, r:Number):void
      {
         var k:Number = r / 18;
         g.lineStyle(1.2 * k, 0x6A3A00);
         g.beginFill(0xE8473A);
         g.moveTo(-10 * k, -1 * k); g.lineTo(0, -10 * k); g.lineTo(10 * k, -1 * k); g.lineTo(-10 * k, -1 * k);
         g.endFill();
         g.beginFill(0xFFF3C4); g.drawRect(-7 * k, -1 * k, 14 * k, 10 * k); g.endFill();
         g.beginFill(0x8A4B00); g.drawRect(-2 * k, 3 * k, 4 * k, 6 * k); g.endFill();
      }

      // ------------------------------------------------------------------ the rest

      /** The page's mode: "inpage" (单机模式) or "server" (联机模式); "" without a page. */
      private static function pageMode():String
      {
         try { if (ExternalInterface.available) return String(ExternalInterface.call("aolaRevivalMode") || ""); } catch (e:Error) {}
         return "";
      }

      /** The card closes, then f. */
      private function closeThen(f:Function):Function
      {
         return function():void
         {
            close();
            f();
         };
      }

      /** Requests sent and not yet answered, by their answer (getTimer() then): one at a time. */
      private static var waiting:Object = {};

      /** A request to the server whose reply {res, msg} is shown. */
      private function ask(ext:String, cmd:String, answer:String):void
      {
         var sc:SocketClient = SocketClient.instance;
         // A second click while the first waits is not sent again (its answer would be shown twice).
         if (waiting[answer] != null && getTimer() - int(waiting[answer]) < 8000) return;
         waiting[answer] = getTimer();
         var onReply:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(answer, onReply);
            delete waiting[answer];
            if (int(e.params.res) == 1) NewDialog.showSucceedMessage(String(e.params.msg));
            else NewDialog.showFailMessage(String(e.params.msg));
         };
         sc.addEventListener(answer, onReply);
         sc.sendXtMessage(ext, cmd, {name: userName});
      }

      private function nickName():String
      {
         if (own)
         {
            try
            {
               var me:Object = PlayerManagerRef.myPlayer();
               if (me && me.hasOwnProperty("nickName")) return me.nickName;
            }
            catch (e:Error) {}
         }
         return userName;
      }

      private function showAvatar():void
      {
         if (clothes == null) return;
         try
         {
            var svc:IAvatarService = ServiceContainer.getService(IAvatarService) as IAvatarService;
            avatar = svc.getAlbumAvatarProxy();
            var sprite:Sprite = avatar.getSprite();
            stand.addChild(sprite);
            // The album avatar draws at its own size and origin: fit it on the stand once it has drawn.
            var fitAvatar:Function = function(e:Event = null):void
            {
               if (sprite.parent == null) { stand.removeEventListener(Event.ENTER_FRAME, fitAvatar); return; }
               sprite.scaleX = sprite.scaleY = 1;
               var b:Object = sprite.getBounds(sprite);
               if (b.height <= 1) return;
               var k:Number = Math.min(210 / b.height, 160 / b.width, 1.4);
               sprite.scaleX = sprite.scaleY = k;
               sprite.x = -(b.left + b.width / 2) * k;
               sprite.y = -b.bottom * k + 6;
            };
            stand.addEventListener(Event.ENTER_FRAME, fitAvatar);
            var mine:IAlbumAvatarProxy = avatar;
            var dress:Function = function(info:AvatarInfo):void
            {
               RAvatar.drawable(info, function(shown:AvatarInfo):void { if (avatar == mine && shown != null) avatar.setAvatarInfo(shown); });
            };
            if (own) dress(clothes.getMyAvatarInfo());
            else clothes.getOthersAvatarInfo(userName, dress);
         }
         catch (e:Error)
         {
            RLog.error("usercard avatar", e);
         }
      }

      private var redraw:Timer;

      /**
       * After a change of clothes the stand's figure is drawn anew from a new
       * album avatar once the change has settled: setting the clothes on the
       * same album avatar twice in a row (put on, take off) could leave it
       * blank while its pieces were still loading.
       */
      private function redrawAvatar():void
      {
         if (redraw == null)
         {
            redraw = new Timer(350, 1);
            redraw.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void
            {
               if (parent == null) return;
               if (avatar != null)
               {
                  try { avatar.dispose(); } catch (err:Error) {}
                  avatar = null;
               }
               while (stand.numChildren > 0) stand.removeChildAt(0);
               showAvatar();
            });
         }
         redraw.reset();
         redraw.start();
      }

      private static function text(size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         return t;
      }

      public function close():void
      {
         if (redraw != null) redraw.stop();
         SocketClient.instance.removeEventListener(PetEggClient.cmdGetEggs, onEggs);
         if (avatar != null)
         {
            try { avatar.dispose(); } catch (e:Error) {}
            avatar = null;
         }
         if (parent) parent.removeChild(this);
      }
   }
}
