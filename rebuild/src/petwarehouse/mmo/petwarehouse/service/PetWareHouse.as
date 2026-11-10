package mmo.petwarehouse.service
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.utils.getDefinitionByName;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.interfaces.pet.ui.IPetUIService;
   import mmo.interfaces.pet.ui.PetUIServiceEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RArt;
   import mmo.revival.RLog;
   import mmo.revival.RTraining;
   import mmo.revival.RNotice;
   import mmo.revival.RTimeline;
   import mmo.revival.RUI;

   /**
    * REBUILT pet/petwarehouse (service PetWareHouse, IShowPanel): the 亚比仓库, in its 2012
    * look. The 2012 and 2013 modules are lost (the captured file is a rework of years after);
    * the January 2012 tutorial house/houseteachmovie/houseteachpetstore shows the panel, as a
    * picture of the whole screen (its frame 26), and tells what each part does (frame 36):
    *   亚比仓库 / 精英仓库 / 放生仓库   the 亚比 by 系 (ALL and the fifteen 系 icons), the 精英,
    *                                  those let go ("放生的亚比一段时间后就无法找回")
    *   按时间顺序 / 按等级顺序         by when they were got, by level
    *   展示     the 亚比 shown in the 家园 ("可以将可爱的亚比展示出来")
    *   训练     the HELLO's 亚比训练 ("接受训练的亚比会被送到科学院亚比研究中心的二楼"), as 开始训练
    *   设为精英 / 取消精英, 放入背包, 放生
    * Here that picture is the panel: its sample 吉拉, its counts and its page are rubbed out
    * (each row filled from the colours on its two sides), and the 亚比 of the 仓库 drawn on it;
    * the 技能 / 能力 / 信息 page under the picture is redrawn for the 亚比 chosen. The ovals on
    * the two sides of its name pick the one before and after; the pen by them (the later
    * 背包's "点击修改亚比昵称") gives it a 昵称; the HELLO with its book shows the tutorial's page.
    *
    * Commands (pets.ts): viewPMInLocation 1213 {pmType 系, page (from 1), loc 1 仓库 / 4 精英 / 3 放生, order, asc, size}
    * -> 2213, sendPmToFromStorage 1224 {id, loc 0} -> 2224 (a 亚比 of the 放生仓库 comes back so),
    * setExcellentPM 1225 {id, e} -> 2225, viewSinglePM 1211 -> 2211, and the revival's
    * revival_release (into the 放生仓库), revival_nick, revival_show.
    */
   public class PetWareHouse extends EventDispatcher implements IShowPanel
   {
      private static const ART:String = "house/houseteachmovie/houseteachpetstore";
      private static const ART_CLASS:String = "mmo.houseteachmovie.Petstore";
      private static const PER_PAGE:int = 9;
      /** The 系 icons of the picture, two rows of eight from ALL: their 属性. */
      private static const FILTER:Array = [0, 9, 10, 14, 8, 11, 5, 7, 15, 4, 12, 2, 13, 1, 16, 18];
      private static const ATTR_NAMES:Array = ["普通", "格斗", "飞行", "毒", "爬行", "土", "虫", "数码", "机械", "火", "水", "木", "电", "神秘", "冰", "上古", "暗黑", "", "光明", "龙", "圣灵", "神兵", "王"];
      /** The slots of the picture: left x of each column, top y of each row, their size. */
      private static const SLOT_X:Array = [192, 251, 311];
      private static const SLOT_Y:Array = [281, 341, 400];
      private static const SLOT_W:int = 53;
      /** The 技能 / 能力 / 信息 page of the picture (inside its cyan line). */
      private static const PAGE:Rectangle = new Rectangle(557, 283, 271, 199);
      /** The four skill cards: left x; their top and bottom. */
      private static const CARD_X:Array = [563, 630, 697, 763];

      private var root:Sprite;
      private var art:BitmapData;
      private var pageSkill:BitmapData;
      private var pageBlank:BitmapData;
      private var pageView:Bitmap;
      private var pageText:Sprite;
      private var loc:int = 1;
      private var type:int = 0;
      private var order:int = 1;
      private var asc:Boolean = true;
      private var page:int;
      private var pages:int = 1;
      private var total:int;
      private var list:Array = [];
      private var sel:int;
      private var detail:Object;
      private var skills:Array = [];
      private var tab:String = "skill";
      private var busy:Boolean;
      /** 亚比替换: the 亚比 to come into the full bag once the one chosen has gone to the 仓库. */
      private var swapIn:Object;
      private var slots:Array = [];
      private var marks:Shape;
      private var countText:TextField;
      private var pageNo:TextField;
      private var petPic:Sprite;
      private var eliteLabel:Sprite;
      private var showLabel:Sprite;
      private var shades:Object = {};
      private var dialog:Sprite;

      public function PetWareHouse()
      {
         super();
      }

      public function showPanel():void
      {
         if (root != null && root.parent != null) return;
         if (ApplicationDomain.currentDomain.hasDefinition(ART_CLASS)) open();
         // Without a class name: a missing one would leave the 2013 ResScheduler's loader taken.
         else ResScheduler.getResource(ART, function(d:* = null):void { open(); }, "", function(e:* = null):void
         {
            RNotice.show(LayerManager.getBaseTop(), "亚比仓库打不开了。");
         });
      }

      private var opening:Boolean;

      private function open():void
      {
         if (root != null && root.parent != null || opening) return;
         if (!ApplicationDomain.currentDomain.hasDefinition(ART_CLASS))
         {
            RNotice.show(LayerManager.getBaseTop(), "亚比仓库打不开了。");
            return;
         }
         opening = true;
         RTimeline.frame(ART_CLASS, 26, LayerManager.getBaseTop(), function(mc:MovieClip):Boolean { return shotOf(mc) != null; }, function(mc:MovieClip):void
         {
            opening = false;
            if (mc == null)
            {
               RNotice.show(LayerManager.getBaseTop(), "亚比仓库打不开了。");
               return;
            }
            try { build(picture(mc)); }
            catch (e:Error)
            {
               RLog.error("warehouse build", e);
               close();
               return;
            }
            listen();
         });
      }

      private function listen():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener("2213", onList);
         sc.addEventListener("2224", onMoved);
         sc.addEventListener("2225", onElite);
         sc.addEventListener("2211", onDetail);
         sc.addEventListener("revival_release", onReleased);
         sc.addEventListener("revival_nick", onNick);
         sc.addEventListener("revival_show", onShow);
         ask();
      }

      // ---------------------------------------------------------------- the picture

      /** The tutorial's picture of the panel: the whole-screen shape over its dimmed 家园. */
      private static function shotOf(mc:MovieClip):DisplayObject
      {
         var shot:DisplayObject;
         for (var i:int = 2; i < mc.numChildren; i++)
         {
            var d:DisplayObject = mc.getChildAt(i);
            if (d is Shape && d.width >= 900 && d.height >= 500) shot = d;
         }
         return shot;
      }

      private static function picture(mc:MovieClip):BitmapData
      {
         var shot:DisplayObject = shotOf(mc);
         var bd:BitmapData = new BitmapData(960, 560, true, 0);
         if (shot != null) bd.draw(shot, shot.transform.matrix, null, null, null, true);
         return bd;
      }

      /** Rubs out r: each row filled from the colour left of it to the colour right of it. */
      private static function rub(bd:BitmapData, r:Rectangle):void
      {
         var x0:int = Math.max(0, int(r.x) - 1);
         var x1:int = Math.min(bd.width - 1, int(r.right));
         for (var y:int = int(r.y); y < int(r.bottom); y++)
         {
            var a:uint = bd.getPixel32(x0, y);
            var b:uint = bd.getPixel32(x1, y);
            for (var x:int = x0 + 1; x < x1; x++)
            {
               var k:Number = (x - x0) / (x1 - x0);
               bd.setPixel32(x, y, mix(a, b, k));
            }
         }
      }

      private static function mix(a:uint, b:uint, k:Number):uint
      {
         var out:uint = 0;
         for (var s:int = 0; s <= 24; s += 8)
         {
            var ca:Number = (a >>> s) & 0xFF;
            var cb:Number = (b >>> s) & 0xFF;
            out |= (uint(Math.round(ca + (cb - ca) * k)) & 0xFF) << s;
         }
         return out;
      }

      private function build(pic0:BitmapData):void
      {
         art = pic0;
         // The tutorial's 吉拉 in the first slot, its 共 1 只亚比 and its page 1/1.
         // (the first slot takes the inside of the second, which the tutorial left empty)
         art.copyPixels(art, new Rectangle(SLOT_X[1] + 3, SLOT_Y[0] + 3, SLOT_W - 6, SLOT_W - 6), new Point(SLOT_X[0] + 3, SLOT_Y[0] + 3));
         rub(art, new Rectangle(244, 265, 22, 17));
         rub(art, new Rectangle(256, 454, 40, 19));
         root = new Sprite();
         root.name = "petWarehouse";
         root.addChild(RUI.dim(null));
         var pic:Bitmap = new Bitmap(art, "auto", true);
         pic.name = "warehouseArt";
         root.addChild(pic);
         buildPages();
         marks = new Shape();
         root.addChild(marks);
         for (var i:int = 0; i < PER_PAGE; i++)
         {
            var slot:Sprite = new Sprite();
            slot.name = "storePet" + i;
            slot.x = SLOT_X[i % 3] + SLOT_W / 2;
            slot.y = SLOT_Y[int(i / 3)] + SLOT_W / 2;
            slot.graphics.beginFill(0xFFFFFF, 0);
            slot.graphics.drawRect(-SLOT_W / 2, -SLOT_W / 2, SLOT_W, SLOT_W);
            slot.graphics.endFill();
            slot.buttonMode = true;
            slot.mouseChildren = false;
            slot.addEventListener(MouseEvent.CLICK, pick(i));
            root.addChild(slot);
            slots.push(slot);
         }
         countText = label(13, 0xE60000, false, TextFormatAlign.CENTER);
         countText.x = 238;
         countText.y = 264;
         countText.width = 34;
         root.addChild(countText);
         pageNo = label(12, 0x47668C, true, TextFormatAlign.CENTER);
         pageNo.x = 252;
         pageNo.y = 455;
         pageNo.width = 48;
         root.addChild(pageNo);
         petPic = new Sprite();
         petPic.mouseEnabled = petPic.mouseChildren = false;
         petPic.x = 703;
         petPic.y = 158;
         root.addChild(petPic);
         // The left side: tabs, 系, sorting, pages, help, 开始训练.
         hit(129, 185, 30, 96, "tabStore", function():void { setLoc(1); }, "亚比仓库");
         hit(129, 283, 30, 96, "tabElite", function():void { setLoc(4); }, "精英仓库");
         hit(129, 381, 30, 96, "tabReleased", function():void { setLoc(3); }, "放生仓库");
         for (var f:int = 0; f < FILTER.length; f++)
            hit(174 + (f % 8) * 35, 200 + int(f / 8) * 33, 28, 28, "filter" + FILTER[f], setType(FILTER[f]), f == 0 ? "全部" : ATTR_NAMES[FILTER[f]] + "系");
         hit(406, 278, 26, 78, "sortTime", function():void { setOrder(1); }, "按时间顺序");
         hit(406, 370, 26, 78, "sortLevel", function():void { setOrder(2); }, "按等级顺序");
         hit(240, 452, 16, 22, "warehousePrev", function():void { if (page > 0) { page--; sel = 0; ask(); } });
         hit(297, 452, 16, 22, "warehouseNext", function():void { if (page < pages - 1) { page++; sel = 0; ask(); } });
         hit(375, 95, 40, 40, "warehouseHelp", help, "亚比仓库说明");
         hit(226, 481, 110, 34, "warehouseTrain", train, "开始训练");
         // The right side.
         hit(820, 38, 40, 40, "warehouseClose", close);
         hit(556, 54, 42, 54, "petShow", toggleShow, "展示");
         hit(556, 111, 42, 48, "petTrain", train, "训练");
         hit(552, 161, 68, 44, "petElite", toggleElite);
         hit(552, 205, 68, 44, "petToBag", toBag, "放入背包");
         hit(798, 200, 50, 50, "petRelease", askRelease, "放生");
         hit(556, 260, 52, 22, "pageSkill", function():void { setTab("skill"); }, "技能");
         hit(611, 260, 52, 22, "pageAbility", function():void { setTab("ability"); }, "能力");
         hit(664, 260, 52, 22, "pageInfo", function():void { setTab("info"); }, "信息");
         hit(590, 290, 20, 20, "petPrev", function():void { step(-1); }, "上一只");
         hit(745, 290, 20, 20, "petNext", function():void { step(1); }, "下一只");
         hit(720, 286, 26, 26, "petNick", askNick, "点击修改亚比昵称");
         eliteLabel = labelPatch(552, 186, 68, 19, "设为精英", 0x7A2BB0);
         showLabel = labelPatch(553, 89, 48, 19, "取消展示", 0xD9601A);
         for each (var n:String in ["petShow", "petTrain", "petElite", "petToBag", "petRelease"]) shades[n] = shade(n);
         LayerManager.getBaseTop().addChild(root);
         redraw();
      }

      /** The 技能 page of the picture without the tutorial's 吉拉, and the page with nothing. */
      private function buildPages():void
      {
         pageSkill = new BitmapData(PAGE.width, PAGE.height, true, 0);
         pageSkill.copyPixels(art, PAGE, new Point(0, 0));
         var at:Function = function(x:int, y:int, w:int, h:int):Rectangle { return new Rectangle(x - PAGE.x, y - PAGE.y, w, h); };
         rub(pageSkill, at(612, 288, 104, 22));   // its name
         rub(pageSkill, at(794, 283, 30, 30));    // its 属性
         rub(pageSkill, at(684, 312, 70, 17));    // 004(吉拉)
         rub(pageSkill, at(618, 335, 104, 15));   // 天赋: its sign and 千载难逢
         rub(pageSkill, at(650, 361, 50, 15));    // lv.14
         for each (var cx:int in CARD_X)
         {
            rub(pageSkill, at(cx + 4, 386, 54, 38));   // the skill's 属性
            rub(pageSkill, at(cx + 3, 426, 56, 16));   // its name
            rub(pageSkill, at(cx + 30, 446, 28, 12));  // 威力
            rub(pageSkill, at(cx + 24, 459, 34, 12));  // PP
         }
         pageBlank = new BitmapData(PAGE.width, PAGE.height, true, 0);
         pageBlank.copyPixels(art, PAGE, new Point(0, 0));
         rub(pageBlank, new Rectangle(0, 2, PAGE.width, PAGE.height - 4));
         // The picture's own page goes: the one drawn here lies over it.
         pageView = new Bitmap(pageSkill, "auto", true);
         pageView.x = PAGE.x;
         pageView.y = PAGE.y;
         root.addChild(pageView);
         pageText = new Sprite();
         pageText.mouseEnabled = pageText.mouseChildren = false;
         root.addChild(pageText);
      }

      private function hit(x:int, y:int, w:int, h:int, n:String, f:Function, tip:String = null):Sprite
      {
         var s:Sprite = new Sprite();
         s.name = n;
         s.graphics.beginFill(0xFFFFFF, 0);
         s.graphics.drawRect(0, 0, w, h);
         s.graphics.endFill();
         s.x = x;
         s.y = y;
         s.buttonMode = true;
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (s.alpha < 1 || shadeOn(n)) return;
            f();
         });
         if (tip) try { TipsManager.getInstance().addTips(s, tip); } catch (err:Error) {}
         root.addChild(s);
         return s;
      }

      /** A dark veil over a button of the picture, for when it does nothing. */
      private function shade(n:String):Shape
      {
         var h:DisplayObject = root.getChildByName(n);
         var s:Shape = new Shape();
         s.graphics.beginFill(0x0A1440, 0.55);
         s.graphics.drawRoundRect(h.x, h.y, h.width, h.height, 12, 12);
         s.graphics.endFill();
         s.visible = false;
         root.addChildAt(s, root.getChildIndex(h));
         return s;
      }

      private function shadeOn(n:String):Boolean
      {
         return shades[n] != null && Shape(shades[n]).visible;
      }

      /** A word written over a word of the picture (取消精英 -> 设为精英), in its look. */
      private function labelPatch(x:int, y:int, w:int, h:int, text:String, edge:uint):Sprite
      {
         var s:Sprite = new Sprite();
         s.mouseEnabled = s.mouseChildren = false;
         var back:BitmapData = art.clone();
         var r:Rectangle = new Rectangle(x, y, w, h);
         rub(back, r);
         var bm:Bitmap = new Bitmap(new BitmapData(w, h, true, 0), "auto", true);
         bm.bitmapData.copyPixels(back, r, new Point(0, 0));
         back.dispose();
         bm.x = x;
         bm.y = y;
         s.addChild(bm);
         var t:TextField = label(13, 0xFFFFFF, true, TextFormatAlign.CENTER);
         t.width = w + 10;
         t.x = x - 5;
         t.y = y;
         t.text = text;
         t.filters = [new GlowFilter(edge, 1, 3, 3, 8), new GlowFilter(0xFFFFFF, 1, 2, 2, 4)];
         s.addChild(t);
         s.visible = false;
         root.addChild(s);
         return s;
      }

      private static function label(size:int, color:uint, bold:Boolean, align:String = "left"):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold, null, null, null, null, align);
         t.selectable = false;
         t.mouseEnabled = false;
         t.height = size + 8;
         t.width = 100;
         return t;
      }

      // ---------------------------------------------------------------- the list

      private function ask():void
      {
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1213", {pmType: type, page: page + 1, loc: loc, order: order, asc: asc, size: PER_PAGE});
      }

      private function setLoc(n:int):void
      {
         if (loc == n) return;
         loc = n;
         page = 0;
         sel = 0;
         ask();
         redraw();
      }

      private function setType(t:int):Function
      {
         return function():void
         {
            type = t;
            page = 0;
            sel = 0;
            ask();
            redraw();
         };
      }

      /** A sort the first time newest / highest first; again, the other way. */
      private function setOrder(n:int):void
      {
         if (order == n) asc = !asc;
         else
         {
            order = n;
            asc = false;
         }
         page = 0;
         sel = 0;
         ask();
         redraw();
      }

      private function onList(e:SocketClientEvent):void
      {
         if (root == null) return;
         var o:Object = e.params;
         if (int(o.loc) != loc) return;
         list = ((o.pmList as Array) || []).map(function(raw:Object, i:int, a:Array):Object { return raw.pmSView || {}; });
         skills = ((o.pmList as Array) || []).map(function(raw:Object, i:int, a:Array):Array { return (raw.skills as Array) || []; });
         page = Math.max(0, int(o.page) - 1);
         pages = Math.max(1, int(o.totalPage));
         total = int(o.total);
         if (sel >= list.length) sel = Math.max(0, list.length - 1);
         for (var i:int = 0; i < slots.length; i++)
         {
            var s:Sprite = slots[i];
            while (s.numChildren) s.removeChildAt(0);
            var p:Object = list[i];
            s.visible = p != null;
            if (p == null) continue;
            var pic:Sprite = new Sprite();
            s.addChild(pic);
            RArt.pet(pic, int(p.r), 44);
            var lv:TextField = label(10, 0xFFFFFF, true, TextFormatAlign.RIGHT);
            lv.text = loc == 3 ? "剩" + int(p.rl) + "天" : "Lv" + int(p.lv);
            lv.width = SLOT_W - 4;
            lv.x = -SLOT_W / 2;
            lv.y = SLOT_W / 2 - 15;
            lv.filters = [new GlowFilter(0x1B4F8A, 1, 3, 3, 6)];
            s.addChild(lv);
            if (int(p.el) == 1 && loc != 2) s.addChild(badge("精", 0xF2A11A, -SLOT_W / 2 + 8, -SLOT_W / 2 + 8));
            if (int(p.sh) == 1) s.addChild(badge("展", 0x2E9E3A, SLOT_W / 2 - 8, -SLOT_W / 2 + 8));
         }
         choose(sel);
      }

      private static function badge(text:String, color:uint, x:int, y:int):Sprite
      {
         var b:Sprite = new Sprite();
         b.graphics.lineStyle(1, 0xFFFFFF);
         b.graphics.beginFill(color);
         b.graphics.drawCircle(0, 0, 7);
         b.graphics.endFill();
         var t:TextField = label(10, 0xFFFFFF, true, TextFormatAlign.CENTER);
         t.text = text;
         t.width = 16;
         t.x = -8;
         t.y = -8;
         b.addChild(t);
         b.x = x;
         b.y = y;
         return b;
      }

      private function pick(i:int):Function
      {
         return function(e:MouseEvent):void
         {
            e.stopPropagation();
            choose(i);
         };
      }

      private function choose(i:int):void
      {
         sel = i;
         detail = null;
         var p:Object = list[sel];
         RArt.pet(petPic, p ? int(p.r) : 0, 120, "_L");
         redraw();
         if (p != null) PetClient.instance.viewSinglePM(int(p.i));
      }

      /** The one before or after: on this page, then the page before or after. */
      private function step(d:int):void
      {
         if (list.length == 0) return;
         var n:int = sel + d;
         if (n >= 0 && n < list.length) choose(n);
         else if (d < 0 && page > 0) { page--; sel = PER_PAGE - 1; ask(); }
         else if (d > 0 && page < pages - 1) { page++; sel = 0; ask(); }
         else choose(d < 0 ? list.length - 1 : 0);
      }

      private function onDetail(e:SocketClientEvent):void
      {
         var v:Object = e.params.pm ? e.params.pm.pmPView : null;
         var p:Object = list[sel];
         if (root == null || v == null || p == null || int(v.i) != int(p.i)) return;
         detail = v;
         skills[sel] = (e.params.pm.skills as Array) || skills[sel];
         redraw();
      }

      // ---------------------------------------------------------------- drawing

      private function redraw():void
      {
         if (root == null) return;
         var g:* = marks.graphics;
         g.clear();
         // The tab, the 系 and the sorting chosen.
         var tabY:Array = [185, 283, 381];
         g.lineStyle(3, 0xFFB400, 1);
         g.beginFill(0xFFFFFF, 0.25);
         g.drawRoundRect(130, tabY[loc - 1] + 2, 28, 92, 10, 10);
         g.endFill();
         var f:int = FILTER.indexOf(type);
         g.lineStyle(2.5, 0xFFD400, 1);
         g.drawRoundRect(173 + (f % 8) * 35, 199 + int(f / 8) * 33, 30, 30, 10, 10);
         g.lineStyle(2.5, 0xFFD400, 1);
         g.drawRoundRect(406, order == 1 ? 278 : 370, 26, 78, 10, 10);
         g.lineStyle();
         g.beginFill(0xFFD400);
         var ay:int = order == 1 ? 276 : 368;
         if (asc) { g.moveTo(419, ay - 8); g.lineTo(425, ay); g.lineTo(413, ay); }
         else { g.moveTo(413, ay - 8); g.lineTo(425, ay - 8); g.lineTo(419, ay); }
         g.endFill();
         // The 亚比 chosen.
         if (list[sel] != null)
         {
            g.lineStyle(3, 0xFF9C00, 1);
            g.drawRoundRect(SLOT_X[sel % 3] - 1, SLOT_Y[int(sel / 3)] - 1, SLOT_W + 2, SLOT_W + 2, 12, 12);
         }
         countText.text = String(total);
         pageNo.text = (page + 1) + "/" + pages;
         var p:Object = list[sel];
         var none:Boolean = p == null;
         var gone:Boolean = loc == 3;
         Shape(shades["petShow"]).visible = none || gone;
         Shape(shades["petTrain"]).visible = gone;
         Shape(shades["petElite"]).visible = none || gone;
         Shape(shades["petToBag"]).visible = none;
         Shape(shades["petRelease"]).visible = none || gone;
         eliteLabel.visible = !none && !gone && int(detail ? detail.el : p.el) != 1;
         showLabel.visible = !none && !gone && int(detail ? detail.sh : p.sh) == 1;
         drawPage();
      }

      private function setTab(t:String):void
      {
         tab = t;
         drawPage();
      }

      private function drawPage():void
      {
         while (pageText.numChildren) pageText.removeChildAt(0);
         var g:* = pageText.graphics;
         g.clear();
         // The tab chosen, lighter.
         var tx:int = tab == "skill" ? 557 : tab == "ability" ? 612 : 665;
         g.beginFill(0xFFFFFF, 0.3);
         g.drawRoundRect(tx, 262, 50, 19, 8, 8);
         g.endFill();
         pageView.bitmapData = tab == "skill" ? pageSkill : pageBlank;
         var p:Object = list[sel];
         if (p == null)
         {
            if (tab == "skill") pageView.bitmapData = pageBlank;
            var empty:TextField = text(loc == 4 ? "精英仓库里还没有亚比。\n在亚比仓库里把亚比设为精英吧！" : loc == 3 ? "放生仓库里没有亚比。" : "亚比仓库里没有亚比。\n背包里的亚比可以放回仓库。", 13, 0xFFFFFF, PAGE.x + 10, 340, PAGE.width - 20, true);
            empty.filters = [new GlowFilter(0x123A80, 1, 3, 3, 6)];
            return;
         }
         var v:Object = detail || {};
         var name:String = String(p.nick || p.nm || "");
         var race:int = int(p.r);
         var lv:int = int(p.lv);
         if (tab == "skill")
         {
            var n:TextField = text(name, 14, 0xFFFFFF, 612, 290, 104, true, TextFormatAlign.CENTER);
            n.filters = [new GlowFilter(0x2B3A9C, 1, 2, 2, 4)];
            var attr:Sprite = new Sprite();
            attr.x = 809;
            attr.y = 298;
            pageText.addChild(attr);
            RArt.attribute(attr, int(v.t != undefined ? v.t : p.t), 24);
            text((race < 10 ? "00" : race < 100 ? "0" : "") + race + "(" + String(p.nm || "") + ")", 12, 0xF2DF9A, 684, 312, 90);
            text(genius(v), 12, 0xBFE8FF, 618, 335, 104, false, TextFormatAlign.CENTER);
            text("lv." + lv, 13, 0xFFFFFF, 652, 360, 48);
            // The bar of experience, as the picture's.
            var cur:int = int(v.curExp);
            var need:int = cur + int(v.nx);
            g.beginFill(0xFDFFB5);
            g.drawRect(703, 363, 100, 11);
            g.endFill();
            if (need > 0 || lv >= 100)
            {
               g.beginFill(0x7ED957);
               g.drawRect(703, 363, lv >= 100 ? 100 : Math.round(100 * Math.min(1, cur / Math.max(1, need))), 11);
               g.endFill();
            }
            text(detail == null ? "" : lv >= 100 ? "已满级" : cur + "/" + need, 11, 0xA0522D, 703, 361, 100, false, TextFormatAlign.CENTER);
            var list2:Array = (skills[sel] as Array) || [];
            for (var k:int = 0; k < 4; k++)
            {
               var s:Object = list2[k];
               if (s == null) continue;
               var cx:int = CARD_X[k];
               var icon:Sprite = new Sprite();
               icon.x = cx + 30;
               icon.y = 405;
               pageText.addChild(icon);
               RArt.attribute(icon, int(s.t), 34);
               text(String(s.name || ""), 12, 0x1E50B4, cx + 1, 427, 60, false, TextFormatAlign.CENTER);
               // A skill that does no damage has no 威力 (its pw -1 or 0).
               text(int(s.pw) > 0 ? String(int(s.pw)) : "--", 11, 0xFFFFFF, cx + 30, 445, 28, false, TextFormatAlign.RIGHT);
               text(String(s.pp || ""), 11, 0xFFFFFF, cx + 22, 458, 36, false, TextFormatAlign.RIGHT);
            }
            return;
         }
         var x0:int = PAGE.x + 16;
         var y0:int = PAGE.y + 10;
         var head:TextField = text(name + "  Lv." + lv + (int(v.el) == 1 ? "  （精英）" : ""), 14, 0xFFFFFF, x0, y0, PAGE.width - 30, true);
         head.filters = [new GlowFilter(0x2B3A9C, 1, 2, 2, 4)];
         var rows:Array;
         if (tab == "ability")
         {
            var hp:String = String(v.s0 || p.s0 || "").split("#")[0];
            rows = [["体力", (int(v.c0) || int(p.c0)) + "/" + hp], ["攻击", int(v.curAtt)], ["防御", int(v.curDef)], ["特攻", int(v.curSAtt)],
               ["特防", int(v.curSDef)], ["速度", int(v.curSpd)], ["种族值总和", int(v.totalRace)]];
         }
         else
         {
            rows = [["亚比序号", (race < 10 ? "00" : race < 100 ? "0" : "") + race + "（" + String(p.nm || "") + "）"], ["性格", String(v.ch || p.ch || "")],
               ["天赋", genius(v)], ["获得时间", String(v.d || "")], ["属性", (ATTR_NAMES[int(v.t != undefined ? v.t : p.t)] || "") + "系"],
               ["经验", lv >= 100 ? "已满级" : int(v.curExp) + "/" + (int(v.curExp) + int(v.nx))]];
            if (loc == 3) rows.push(["放生仓库", "还能留" + int(p.rl) + "天"]);
            else if (int(v.sh) == 1) rows.push(["展示", "正在家园里展示"]);
         }
         for (var r:int = 0; r < rows.length; r++)
         {
            var a:TextField = text(String(rows[r][0]) + "：", 13, 0xFFE34D, x0, y0 + 28 + r * 22, 100, true);
            a.filters = [new GlowFilter(0x1A2F7A, 1, 2, 2, 4)];
            text(String(rows[r][1]), 13, 0xFFFFFF, x0 + 100, y0 + 28 + r * 22, PAGE.width - 130);
         }
      }

      /** 天赋, as the 2013 interfaces' GeniusHelper rates the 个体值 (on their scale of 62: twice ours). */
      private static function genius(v:Object):String
      {
         if (v == null || v.i0 == undefined) return "";
         var stars:int = 0;
         for (var i:int = 0; i < 6; i++)
         {
            var iv:int = int(v["i" + i]) * 2;
            stars += iv <= 10 ? 1 : iv <= 20 ? 2 : iv <= 30 ? 3 : iv <= 50 ? 4 : 5;
         }
         return stars <= 9 ? "一无是处" : stars <= 14 ? "十分常见" : stars <= 19 ? "百里挑一" : stars <= 24 ? "千载难逢" : stars <= 29 ? "万众瞩目" : "王者无敌";
      }

      private function text(s:String, size:int, color:uint, x:int, y:int, w:int, bold:Boolean = false, align:String = "left"):TextField
      {
         var t:TextField = label(size, color, bold, align);
         t.multiline = t.wordWrap = s.indexOf("\n") >= 0;
         t.width = w;
         t.height = (size + 6) * (s.split("\n").length) + 4;
         t.x = x;
         t.y = y;
         t.text = s;
         pageText.addChild(t);
         return t;
      }

      // ---------------------------------------------------------------- the buttons

      private function current():Object
      {
         return list[sel];
      }

      private function nameOf(p:Object):String
      {
         return p ? String(p.nick || p.nm || "亚比") : "亚比";
      }

      private function toBag():void
      {
         var p:Object = current();
         if (p == null || busy) return;
         // A full bag (6): 亚比替换, as the game's 亚比仓库 did it (its ExchangePMFuns): the bag's
         // 亚比 in PetUIService's chooser (the 2012 modules' panel), the one chosen goes to the
         // 仓库 and this one into the bag in its place. (From the 放生仓库 it goes to the 仓库.)
         if (loc != 3 && bagPets().length >= 6)
         {
            exchange(p);
            return;
         }
         busy = true;
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1224", {id: int(p.i), loc: 0});
      }

      private static function bagPets():Array
      {
         try { return (ServiceContainer.getService(IPetDataService) as IPetDataService).getMyPets() || []; }
         catch (e:Error) { RLog.error("warehouse bag", e); }
         return [];
      }

      private function exchange(p:Object):void
      {
         ServiceContainer.instance.tryGetService(IPetUIService, function(ui:IPetUIService, o:Object = null):void
         {
            var ok:Function, closed:Function;
            ok = function(e:PetUIServiceEvent):void
            {
               ui.removeEventListener(PetUIServiceEvent.SELECTPANEL_OK, ok);
               ui.removeEventListener(PetUIServiceEvent.SELECTPANEL_CLOSE, closed);
               var out:PetBriefInfo = e.params.pbi as PetBriefInfo;
               if (out == null || root == null || busy) return;
               // The one going to the 仓库 gets off and stops following first.
               try
               {
                  var ride:IRideService = ServiceContainer.getService("RideService") as IRideService;
                  if (ride != null && ride.getMyRidePetId == out.id) ride.rideToWalk();
               }
               catch (err:Error) {}
               swapIn = p;
               busy = true;
               SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1224", {id: out.id, loc: 1});
            };
            closed = function(e:PetUIServiceEvent):void
            {
               ui.removeEventListener(PetUIServiceEvent.SELECTPANEL_OK, ok);
               ui.removeEventListener(PetUIServiceEvent.SELECTPANEL_CLOSE, closed);
            };
            ui.addEventListener(PetUIServiceEvent.SELECTPANEL_OK, ok);
            ui.addEventListener(PetUIServiceEvent.SELECTPANEL_CLOSE, closed);
            var title:TextField = new TextField();
            title.text = "亚比替换";
            ui.showPackagePetSelectPanel(title);
         });
      }

      private function onMoved(e:SocketClientEvent):void
      {
         if (root == null) return;
         busy = false;
         var r:int = int(e.params.result);
         var p:Object = current();
         if (r == -2 && loc == 3 && p != null && int(e.params.loc) == 0)
         {
            // The bag is full: the one taken back from the 放生仓库 goes to the 仓库.
            RNotice.show(root, "背包已经满了，" + nameOf(p) + "回到了亚比仓库。");
            busy = true;
            SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1224", {id: int(p.i), loc: 1});
            return;
         }
         if (swapIn != null)
         {
            // 亚比替换: the chosen one is in the 仓库 now; the other comes into the bag.
            var into:Object = swapIn;
            swapIn = null;
            if (r == 1 && int(e.params.loc) == 1)
            {
               busy = true;
               SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1224", {id: int(into.i), loc: 0});
               return;
            }
         }
         if (r == -2 && loc != 3 && int(e.params.loc) == 0 && p != null) { exchange(p); return; }
         if (r == -2) RNotice.show(root, "背包里已经有6只亚比了，先把一只放回仓库吧！");
         else if (r == -3) RNotice.show(root, "背包里至少要留一只亚比哦！");
         else if (r == -4 && e.params.msg) RNotice.show(root, String(e.params.msg));
         if (r != 1) return;
         if (int(e.params.loc) == 0) RNotice.show(root, nameOf(p) + "放进背包了！");
         ask();
         // The bag (PetDataService) reads the list again, so the 亚比背包 and battles see the change.
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("warehouse refresh", err); }
      }

      private function toggleElite():void
      {
         var p:Object = current();
         if (p == null || busy) return;
         busy = true;
         var on:Boolean = int(detail ? detail.el : p.el) != 1;
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1225", {id: int(p.i), e: on});
      }

      private function onElite(e:SocketClientEvent):void
      {
         if (root == null) return;
         busy = false;
         if (int(e.params.result) != 1) return;
         var on:Boolean = e.params.e === true || String(e.params.e) == "true";
         var p:Object = current();
         if (p != null && int(p.i) == int(e.params.id)) p.el = on ? 1 : 0;
         if (detail != null && int(detail.i) == int(e.params.id)) detail.el = on ? 1 : 0;
         RNotice.show(root, nameOf(p) + (on ? "成为了精英亚比，在精英仓库里也能找到它。" : "不再是精英亚比了。"));
         ask();
      }

      private function toggleShow():void
      {
         var p:Object = current();
         if (p == null || busy) return;
         busy = true;
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_show", {id: int(p.i)});
      }

      private function onShow(e:SocketClientEvent):void
      {
         if (root == null) return;
         busy = false;
         if (int(e.params.result) != 1) return;
         var p:Object = current();
         var id:int = int(e.params.id);
         RNotice.show(root, id > 0 ? nameOf(p) + "正在你的家园里展示，大家都能看到它！" : nameOf(p) + "不再展示了。");
         if (detail != null) detail.sh = detail.i == id ? 1 : 0;
         ask();
      }

      /** 训练 and 开始训练: the HELLO's 亚比训练 (the 亚比 in training first, else the lessons). */
      private function train():void
      {
         close();
         RTraining.open();
      }

      /** 放生: 是否放生该亚比？ 是 lets it go into the 放生仓库; 否 does nothing. */
      private function askRelease():void
      {
         var p:Object = current();
         if (p == null || busy) return;
         var box:Sprite = RUI.panel(320, 170, "放生", hideDialog, "releaseClose");
         box.x = (960 - 320) / 2;
         box.y = (560 - 170) / 2 - 10;
         var q:TextField = RUI.text(15, RUI.BLUE, true);
         q.text = "是否放生" + nameOf(p) + "？";
         q.x = (320 - q.width) / 2;
         q.y = 52;
         box.addChild(q);
         var w:TextField = RUI.text(12, 0xD9452B, false);
         w.text = "放生的亚比一段时间后就无法找回了！";
         w.x = (320 - w.width) / 2;
         w.y = 80;
         box.addChild(w);
         var yes:Sprite = RUI.button("是", function():void
         {
            hideDialog();
            busy = true;
            SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_release", {id: int(p.i)});
         }, 80, 28, 0xF5A08C, 0xD9452B, "releaseYes");
         yes.x = 60;
         yes.y = 116;
         box.addChild(yes);
         var no:Sprite = RUI.button("否", hideDialog, 80, 28, 0x8ED0FA, 0x3C96DC, "releaseNo");
         no.x = 180;
         no.y = 116;
         box.addChild(no);
         showDialog(box);
      }

      private function onReleased(e:SocketClientEvent):void
      {
         if (root == null) return;
         busy = false;
         var r:int = int(e.params.result);
         if (r == -3) RNotice.show(root, "背包里至少要留一只亚比哦！");
         // -4: a mod's 亚比 that must stay in the bag (server mods.ts party), its words.
         if (r == -4 && e.params.msg) RNotice.show(root, String(e.params.msg));
         if (r != 1) return;
         RNotice.show(root, nameOf(current()) + "被放生了，在放生仓库里还能找回它。");
         ask();
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("warehouse refresh", err); }
      }

      /** The pen: a 昵称 of up to six characters (empty: its own name again). */
      private function askNick():void
      {
         var p:Object = current();
         if (p == null || busy || loc == 3) return;
         var box:Sprite = RUI.panel(320, 160, "修改亚比昵称", hideDialog, "nickClose");
         box.x = (960 - 320) / 2;
         box.y = (560 - 160) / 2 - 10;
         var q:TextField = RUI.text(13, RUI.BLUE, true);
         q.text = "给" + String(p.nm || "亚比") + "起个昵称（最多6个字）：";
         q.x = 24;
         q.y = 50;
         box.addChild(q);
         var input:TextField = RUI.input(180, String(p.nick || ""), null, 6, "nickInput");
         input.x = 70;
         input.y = 76;
         box.addChild(input);
         var ok:Sprite = RUI.button("确定", function():void
         {
            hideDialog();
            busy = true;
            SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_nick", {id: int(p.i), nick: input.text});
         }, 80, 28, 0xFFC45A, 0xF07812, "nickOk");
         ok.x = 60;
         ok.y = 112;
         box.addChild(ok);
         var no:Sprite = RUI.button("取消", hideDialog, 80, 28, 0x8ED0FA, 0x3C96DC, "nickCancel");
         no.x = 180;
         no.y = 112;
         box.addChild(no);
         showDialog(box);
         if (root.stage) root.stage.focus = input;
      }

      private function onNick(e:SocketClientEvent):void
      {
         if (root == null) return;
         busy = false;
         var r:int = int(e.params.result);
         if (r == -2) RNotice.show(root, "昵称最多6个字，也不能有特殊符号哦。");
         if (r != 1) return;
         ask();
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("warehouse refresh", err); }
      }

      /** The HELLO with its book: the tutorial's page telling what each part does (a click closes it). */
      private function help():void
      {
         RTimeline.frame(ART_CLASS, 36, root, function(mc:MovieClip):Boolean { return mc.getChildByName("btnNext") != null; }, function(mc:MovieClip):void
         {
            if (mc != null && root != null) helpPage(mc);
         });
      }

      private function helpPage(mc:MovieClip):void
      {
         var page:Sprite = new Sprite();
         page.name = "warehouseHelpPage";
         // From its picture of the panel to its last tip (not its 家园, HELLO and close).
         var from:int = -1;
         for (var i:int = 2; i < mc.numChildren; i++)
         {
            var d:DisplayObject = mc.getChildAt(i);
            if (from < 0 && d is Shape && d.width >= 900) from = i;
         }
         if (from < 0) return;
         var to:int = mc.numChildren - 5;
         for (var k:int = from; k <= to; k++) page.addChild(mc.getChildAt(from));
         var next:DisplayObject = page.getChildByName("btnNext");
         if (next != null) page.removeChild(next);
         page.mouseChildren = false;
         page.buttonMode = true;
         var holder:Sprite = new Sprite();
         holder.addChild(page);
         holder.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); hideDialog(); });
         showDialog(holder);
      }

      private function showDialog(d:Sprite):void
      {
         hideDialog();
         dialog = new Sprite();
         dialog.addChild(RUI.dim(null));
         dialog.addChild(d);
         root.addChild(dialog);
      }

      private function hideDialog():void
      {
         if (dialog != null && dialog.parent != null) dialog.parent.removeChild(dialog);
         dialog = null;
      }

      private function close():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.removeEventListener("2213", onList);
         sc.removeEventListener("2224", onMoved);
         sc.removeEventListener("2225", onElite);
         sc.removeEventListener("2211", onDetail);
         sc.removeEventListener("revival_release", onReleased);
         sc.removeEventListener("revival_nick", onNick);
         sc.removeEventListener("revival_show", onShow);
         if (root != null && root.parent != null) root.parent.removeChild(root);
         root = null;
         slots = [];
         shades = {};
         busy = false;
         dialog = null;
         if (art != null) art.dispose();
         if (pageSkill != null) pageSkill.dispose();
         if (pageBlank != null) pageBlank.dispose();
         art = pageSkill = pageBlank = null;
      }
   }
}
