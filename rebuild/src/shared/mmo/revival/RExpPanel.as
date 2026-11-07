package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.StaticText;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REBUILT: the 经验分配器 (the 家园's, and the HELLO's 经验分配). The HELLO keeps the
    * experience tasks reward (麦哲伦: "HELLO会帮你把奖励的经验分给亚比"); here it goes to a
    * 亚比 of the bag. The 2012 module is lost, but its panel is not: the January 2012
    * tutorial house/houseteachmovie/houseteachexp (mmo.houseteachmovie.Exp) holds a copy of
    * it, with its own instance names (peticontainer1–6, infopanel, exp, delBtn, addBtn,
    * shareExpbtn, cancelBtn, dragMC; the 确认 box: closeBtn, cancelPanel, btnNext, expText,
    * nameText; the LEVEL UP box: a1–a7 / f1–f7 / b1–b7, nameTxt, c1, tlevel, btnNext,
    * iconcontainer, tuopanel). Its frames are taken apart here: frame 43 the panel, 95 the
    * 确认 box, 107 the LEVEL UP box, without the tutorial's sample 吉拉, hand and tips.
    *
    * The commands are the era RobotClient's: getExp (RobotExtension 2-12 -> {exp}) and
    * giveExp (2-13 {pi, e} -> {res, exp}); the 亚比 grows as in a battle, its PM_LEVELUP
    * (2242, abilityChange old/new) fill the LEVEL UP box, PM_GAIN_NEW_SKILL (2234) are told after.
    */
   public class RExpPanel extends Sprite
   {
      private static const ART:String = "house/houseteachmovie/houseteachexp";
      private static const ART_CLASS:String = "mmo.houseteachmovie.Exp";
      private static var current:RExpPanel;

      private var panel:Sprite;
      private var slots:Array = [];
      private var pics:Array = [];
      private var pets:Array = [];
      private var chosen:int = -1;
      private var detail:Object;
      private var pool:int;
      private var amount:TextField;
      private var info:MovieClip;
      private var bigPic:Sprite;
      private var typePic:Sprite;
      private var expText:TextField;
      private var dialog:Sprite;
      private var waiting:Boolean;
      private var ups:Array = [];
      private var learnt:Array = [];
      private var repeat:Timer;
      private var step:int;

      public static function show():void
      {
         if (current != null) current.close();
         if (ApplicationDomain.currentDomain.hasDefinition(ART_CLASS)) open();
         // Without a class name: a missing one would leave the 2013 ResScheduler's loader taken.
         else ResScheduler.getResource(ART, function(d:* = null):void { open(); }, "", function(e:* = null):void
         {
            RNotice.show(LayerManager.getBaseTop(), "经验分配器打不开了。");
         });
      }

      private static function open():void
      {
         if (!ApplicationDomain.currentDomain.hasDefinition(ART_CLASS))
         {
            RNotice.show(LayerManager.getBaseTop(), "经验分配器打不开了。");
            return;
         }
         if (current != null) current.close();
         current = new RExpPanel();
         LayerManager.getBaseTop().addChild(current);
         current.init();
      }

      /** Frame n of the tutorial with its children built (named `part` among them), then done(clip). */
      private function frame(n:int, part:String, done:Function):void
      {
         RTimeline.frame(ART_CLASS, n, this, function(mc:MovieClip):Boolean { return mc.getChildByName(part) != null; }, function(mc:MovieClip):void
         {
            if (parent == null) return;
            if (mc == null)
            {
               RNotice.show(LayerManager.getBaseTop(), "经验分配器打不开了。");
               return;
            }
            done(mc);
         });
      }

      /** Moves mc's children from..to (display order) into a new sprite, where they keep their places. */
      private static function take(mc:MovieClip, from:int, to:int):Sprite
      {
         var s:Sprite = new Sprite();
         for (var i:int = from; i <= to && from < mc.numChildren; i++) s.addChild(mc.getChildAt(from));
         return s;
      }

      private static function named(c:DisplayObjectContainer, n:String):DisplayObject
      {
         for (var i:int = 0; i < c.numChildren; i++) if (c.getChildAt(i).name == n) return c.getChildAt(i);
         return null;
      }

      /** A sprite named `n` over a part of the art (timeline names cannot be changed), clicks calling f. */
      private static function wrap(into:Sprite, d:DisplayObject, n:String, f:Function):Sprite
      {
         var w:Sprite = new Sprite();
         w.name = n;
         var i:int = d.parent == into ? into.getChildIndex(d) : into.numChildren;
         into.addChildAt(w, i);
         w.addChild(d);
         w.buttonMode = true;
         w.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
         return w;
      }

      public function RExpPanel()
      {
         super();
         name = "expPanel";
         addChild(RUI.dim(close));
      }

      private function init():void
      {
         frame(43, "iconcontainer", buildPanel);
      }

      private function start():void
      {
         SocketClient.instance.addEventListener("2-12", onExp);
         SocketClient.instance.addEventListener("2-13", onGiven);
         SocketClient.instance.addEventListener("2211", onDetail);
         SocketClient.instance.addEventListener("2242", onLevelUp);
         SocketClient.instance.addEventListener("2234", onLearnt);
         SocketClient.instance.sendXtMessage("RobotExtension", "2-12", {});
         readPets();
      }

      // ---------------------------------------------------------------- the panel (frame 43)

      private function buildPanel(mc:MovieClip):void
      {
         // The panel's parts lie between the separator before 积累经验 and its big picture's box.
         var from:int = mc.getChildIndex(mc.getChildByName("delBtn")) - 9;
         var to:int = mc.getChildIndex(mc.getChildByName("iconcontainer"));
         panel = take(mc, from, to);
         panel.name = "expArt";
         addChild(panel);
         // The tutorial's 0 in the amount box is a still text: a field to type in takes its place.
         var still:DisplayObject = named(panel, "exp");
         var after:DisplayObject = still ? panel.getChildAt(panel.getChildIndex(still) + 1) : null;
         if (after is StaticText) panel.removeChild(after);
         expText = named(panel, "exp") as TextField;
         info = named(panel, "infopanel") as MovieClip;
         amount = new TextField();
         amount.name = "expAmount";
         amount.type = TextFieldType.INPUT;
         amount.restrict = "0-9";
         amount.maxChars = 7;
         amount.defaultTextFormat = new TextFormat("SimSun", 12, 0x333333, true, null, null, null, null, TextFormatAlign.CENTER);
         amount.x = 527;
         amount.y = 381;
         amount.width = 84;
         amount.height = 19;
         amount.text = "0";
         amount.addEventListener(Event.CHANGE, function(e:Event):void { setAmount(int(amount.text), false); });
         amount.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { amount.setSelection(0, amount.length); });
         panel.addChild(amount);
         for (var i:int = 1; i <= 6; i++)
         {
            var slot:MovieClip = named(panel, "peticoncontainer" + i) as MovieClip;
            if (slot == null) continue;
            var b:Rectangle = slot.getBounds(panel);
            var pic:Sprite = new Sprite();
            pic.name = "expPet" + (i - 1);
            pic.x = b.x + b.width / 2;
            pic.y = b.y + b.height / 2;
            pic.mouseChildren = false;
            pic.buttonMode = true;
            pic.graphics.beginFill(0xFFFFFF, 0);
            pic.graphics.drawRect(-b.width / 2, -b.height / 2, b.width, b.height);
            pic.graphics.endFill();
            pic.addEventListener(MouseEvent.CLICK, choose(i - 1));
            panel.addChild(pic);
            slots.push(slot);
            pics.push(pic);
         }
         var box:DisplayObject = named(panel, "iconcontainer");
         var bb:Rectangle = box.getBounds(panel);
         bigPic = new Sprite();
         bigPic.mouseEnabled = bigPic.mouseChildren = false;
         bigPic.x = bb.x + bb.width / 2;
         bigPic.y = bb.y + bb.height / 2;
         panel.addChild(bigPic);
         var tc:DisplayObject = info ? named(info, "typeiconcontainer") : null;
         typePic = new Sprite();
         typePic.mouseEnabled = typePic.mouseChildren = false;
         if (tc != null)
         {
            var tb:Rectangle = tc.getBounds(info);
            typePic.x = tb.width > 2 ? tb.x + tb.width / 2 : tc.x + 10;
            typePic.y = tb.height > 2 ? tb.y + tb.height / 2 : tc.y + 10;
            if (tc is DisplayObjectContainer) while (DisplayObjectContainer(tc).numChildren) DisplayObjectContainer(tc).removeChildAt(0);
            info.addChild(typePic);
         }
         holdButton(named(panel, "delBtn"), -1);
         holdButton(named(panel, "addBtn"), 1);
         var share:DisplayObject = named(panel, "shareExpbtn");
         if (share) wrap(panel, share, "expShare", askShare);
         var cancel:DisplayObject = named(panel, "cancelBtn");
         if (cancel) wrap(panel, cancel, "expCancel", close);
         // The panel's X (unnamed in the art: the button just before dragMC).
         var drag:DisplayObject = named(panel, "dragMC");
         if (drag != null)
         {
            var x:DisplayObject = panel.getChildAt(panel.getChildIndex(drag) - 1);
            if (x is InteractiveObject && !(x is TextField)) wrap(panel, x, "expClose", close);
            drag = named(panel, "dragMC");
            drag.alpha = 0;
            drag.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { panel.startDrag(false, new Rectangle(-230, -91, 960 - 501, 560 - 380)); });
            drag.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { panel.stopDrag(); });
            addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { panel.stopDrag(); });
         }
         showInfo();
         start();
      }

      /** -/+: a click steps 1; held down it goes on, faster and faster. */
      private function holdButton(d:DisplayObject, dir:int):void
      {
         if (d == null) return;
         var w:Sprite = wrap(panel, d, dir < 0 ? "expDec" : "expAdd", function():void {});
         w.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
         {
            e.stopPropagation();
            step = 0;
            setAmount(int(amount.text) + dir, true);
            stopRepeat();
            repeat = new Timer(70);
            var t0:int = 0;
            repeat.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void
            {
               if (++t0 < 6) return;
               step++;
               setAmount(int(amount.text) + dir * (step < 15 ? 1 : step < 35 ? 10 : step < 60 ? 100 : 1000), true);
            });
            repeat.start();
         });
         w.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void { stopRepeat(); });
         w.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { stopRepeat(); });
      }

      private function stopRepeat():void
      {
         if (repeat != null) repeat.stop();
         repeat = null;
      }

      /** The amount, between 0 and what the HELLO keeps. */
      private function setAmount(n:int, write:Boolean):void
      {
         var m:int = Math.max(0, Math.min(n, pool));
         if (write || m != n || amount.text == "") amount.text = String(m);
      }

      private function readPets():void
      {
         pets = [];
         try
         {
            var svc:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
            if (svc) pets = (svc.getMyPets() || []).slice(0, 6);
         }
         catch (e:Error) { RLog.error("exp pets", e); }
         for (var i:int = 0; i < pics.length; i++)
         {
            var p:PetBriefInfo = pets[i] as PetBriefInfo;
            RArt.pet(pics[i], p ? (p.viewId > 0 ? p.viewId : p.raceId) : 0, 44);
            pics[i].visible = p != null;
         }
         if (chosen < 0 || chosen >= pets.length) chosen = pets.length > 0 ? 0 : -1;
         select(chosen);
      }

      private function choose(i:int):Function
      {
         return function(e:MouseEvent):void
         {
            e.stopPropagation();
            select(i);
         };
      }

      private function select(i:int):void
      {
         chosen = i;
         for (var k:int = 0; k < slots.length; k++) slots[k].filters = k == i ? [new GlowFilter(0xFFCC00, 1, 8, 8, 4)] : [];
         detail = null;
         var p:PetBriefInfo = pets[i] as PetBriefInfo;
         RArt.pet(bigPic, p ? (p.viewId > 0 ? p.viewId : p.raceId) : 0, 96, "_L");
         showInfo();
         if (p != null) PetClient.instance.viewSinglePM(p.id);
      }

      private function onDetail(e:SocketClientEvent):void
      {
         var v:Object = e.params.pm ? e.params.pm.pmPView : null;
         var p:PetBriefInfo = pets[chosen] as PetBriefInfo;
         if (v == null || p == null || int(v.i) != p.id) return;
         detail = v;
         showInfo();
      }

      private function setText(n:String, s:String):void
      {
         var t:TextField = info ? named(info, n) as TextField : null;
         if (t == null) return;
         t.text = s;
         fit(t);
      }

      private function showInfo():void
      {
         if (expText) expText.text = String(pool);
         var p:PetBriefInfo = pets[chosen] as PetBriefInfo;
         var v:Object = detail;
         var race:int = v ? int(v.r) : p ? p.raceId : 0;
         setText("tpetraceid", race > 0 ? (race < 10 ? "00" : race < 100 ? "0" : "") + race : "");
         setText("tpetname", p ? (p.nickname || p.name) : "");
         setText("tpetlevel", v ? String(v.lv) : p ? String(p.level) : "");
         setText("tpetchar", v ? String(v.ch || "") : p ? p.character : "");
         setText("tpetowntime", v && v.d ? String(v.d) : "");
         var cur:int = v ? int(v.curExp) : 0;
         var need:int = v ? cur + int(v.nx) : 0;
         var top:Boolean = v != null && int(v.lv) >= 100;
         setText("tpetlvshow", v ? (top ? "已满级" : cur + "/" + need) : "");
         setText("texptolvup", v ? (top ? "0" : String(Math.max(0, need - cur))) : "");
         var bar:DisplayObject = info ? named(info, "tpetlvsh") : null;
         if (bar != null) bar.scaleX = v == null ? 0 : top ? 1 : Math.max(0, Math.min(1, need > 0 ? cur / need : 0));
         if (v != null) RArt.attribute(typePic, int(v.t), 20);
         else while (typePic.numChildren) typePic.removeChildAt(0);
      }

      private function onExp(e:SocketClientEvent):void
      {
         pool = int(e.params.exp);
         setAmount(int(amount.text), false);
         showInfo();
      }

      // ---------------------------------------------------------------- 分配 and its 确认 (frame 95)

      private function askShare():void
      {
         var p:PetBriefInfo = pets[chosen] as PetBriefInfo;
         var n:int = int(amount.text);
         var no:String = p == null ? "背包里没有亚比。"
            : pool <= 0 ? "完成任务时 HELLO 会得到经验，再来这里分给亚比吧。"
            : n <= 0 ? "先输入要分给亚比的经验值吧。"
            : detail != null && int(detail.lv) >= 100 ? (p.nickname || p.name) + "已经满级了。" : null;
         if (no != null)
         {
            RNotice.show(this, no);
            return;
         }
         frame(95, "nameText", function(mc:MovieClip):void { confirm(mc, p, n); });
      }

      private function confirm(mc:MovieClip, p:PetBriefInfo, n:int):void
      {
         var close:DisplayObject = mc.getChildByName("closeBtn");
         var box:Sprite = take(mc, mc.getChildIndex(close) - 1, mc.numChildren - 5);
         showDialog(box);
         // The sentence is three fields laid out for one font: one line in its place.
         for each (var f:String in ["expText", "nameText"]) if (named(box, f)) named(box, f).visible = false;
         var left:DisplayObject = named(box, "expText") ? box.getChildAt(box.getChildIndex(named(box, "expText")) - 1) : null;
         if (left is TextField) left.visible = false;
         var line:TextField = new TextField();
         line.name = "expAsk";
         line.selectable = false;
         line.mouseEnabled = false;
         line.defaultTextFormat = new TextFormat("SimSun", 14, 0x333333, false, null, null, null, null, TextFormatAlign.CENTER);
         line.width = 300;
         line.height = 22;
         line.x = 492 - 150;
         line.y = 283;
         line.htmlText = "确认要将<font color='#E60000'>" + n + "</font>经验值分配给<font color='#E60000'>" + (p.nickname || p.name) + "</font>吗？";
         box.addChild(line);
         wrap(box, named(box, "closeBtn"), "expAskClose", hideDialog);
         wrap(box, named(box, "cancelPanel"), "expAskCancel", hideDialog);
         wrap(box, named(box, "btnNext"), "expAskOk", function():void { give(p, n); });
      }

      private function showDialog(box:Sprite):void
      {
         hideDialog();
         dialog = new Sprite();
         dialog.addChild(RUI.dim(null));
         dialog.addChild(box);
         addChild(dialog);
      }

      private function hideDialog():void
      {
         if (dialog != null && dialog.parent != null) dialog.parent.removeChild(dialog);
         dialog = null;
      }

      private function give(p:PetBriefInfo, n:int):void
      {
         hideDialog();
         if (waiting) return;
         waiting = true;
         ups = [];
         learnt = [];
         SocketClient.instance.sendXtMessage("RobotExtension", "2-13", {pi: p.id, e: n});
      }

      private function onLevelUp(e:SocketClientEvent):void
      {
         if (waiting) ups.push(e.params);
      }

      private function onLearnt(e:SocketClientEvent):void
      {
         if (waiting) learnt.push(String(e.params.name || ""));
      }

      private function onGiven(e:SocketClientEvent):void
      {
         waiting = false;
         pool = int(e.params.exp);
         var r:int = int(e.params.res);
         var p:PetBriefInfo = pets[chosen] as PetBriefInfo;
         var who:String = p ? (p.nickname || p.name) : "亚比";
         if (r != 1)
         {
            RNotice.show(this, r == -2 ? "HELLO 没有那么多经验。" : "背包里没有这只亚比。");
            showInfo();
            return;
         }
         amount.text = "0";
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("exp refresh", err); }
         if (ups.length > 0) levelUp(p, int(e.params.e));
         else
         {
            RNotice.show(this, who + "获得了" + int(e.params.e) + "点经验！");
            tellLearnt();
         }
         // The bag's list comes again (viewAllPM); its pictures and the 亚比's page after it.
         var t:Timer = new Timer(600, 1);
         t.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void { if (parent != null) readPets(); });
         t.start();
      }

      private function tellLearnt():void
      {
         var p:PetBriefInfo = pets[chosen] as PetBriefInfo;
         var names:Array = learnt.filter(function(s:String, i:int, a:Array):Boolean { return s != ""; });
         if (names.length > 0) RNotice.show(this, (p ? (p.nickname || p.name) : "亚比") + "学会了新技能：" + names.join("、") + "！");
         learnt = [];
      }

      // ---------------------------------------------------------------- LEVEL UP (frame 107)

      private function levelUp(p:PetBriefInfo, given:int):void
      {
         var data:Array = ups.slice();
         frame(107, "tuopanel", function(mc:MovieClip):void { levelBox(mc, p, given, data); });
      }

      private function levelBox(mc:MovieClip, p:PetBriefInfo, given:int, ups:Array):void
      {
         var first:Object = ups[0];
         var last:Object = ups[ups.length - 1];
         var o:Object = first.abilityChange || {};
         var n:Object = last.abilityChange || {};
         // After the tutorial's leftovers of the 确认 box (its a1 is the first of that name).
         var from:int = mc.getChildIndex(mc.getChildByName("a1")) + 1;
         var to:int = mc.getChildIndex(mc.getChildByName("tuopanel"));
         var box:Sprite = take(mc, from, to);
         showDialog(box);
         var lv1:int = int(last.lv);
         var lv0:int = lv1 - ups.length;
         // Rows: a before, f the gain, b after (等级 1, 攻击 a3/f2/b3, 防御 4/4/4, 特攻 5/3/5, 特防 6/5/6, 体力 2/6/2, 速度 7/7/7).
         var rows:Array = [[1, 1, 1, lv0, lv1], [3, 2, 3, int(o.oldAtt), int(n.newAtt)], [4, 4, 4, int(o.oldDef), int(n.newDef)],
            [5, 3, 5, int(o.oldSAtt), int(n.newSAtt)], [6, 5, 6, int(o.oldSDef), int(n.newSDef)], [2, 6, 2, int(o.oldHP), int(n.newHP)],
            [7, 7, 7, int(o.oldSpd), int(n.newSpd)]];
         for each (var row:Array in rows)
         {
            put(box, "a" + row[0], String(row[3]));
            put(box, "f" + row[1], "+" + (row[4] - row[3]));
            put(box, "b" + row[2], String(row[4]));
         }
         // Its name now (grown into its next form, the form's name), unless it has a 昵称.
         var now:String = p ? (p.nickname || p.name) : "";
         if (p != null && !p.nickname && int(last.raceId) > 0 && int(last.raceId) != p.raceId)
         {
            try
            {
               var mes:Object = ServiceContainer.getService("PetSkillMesService");
               if (mes != null) now = String(Object(mes).getPetMes(int(last.raceId)).pname || now);
            }
            catch (err:Error) {}
         }
         put(box, "nameTxt", now);
         put(box, "c1", String(given));
         put(box, "tlevel", String(lv1));
         var ic:DisplayObject = named(box, "iconcontainer");
         if (ic != null)
         {
            var b:Rectangle = ic.getBounds(box);
            var pic:Sprite = new Sprite();
            pic.mouseEnabled = pic.mouseChildren = false;
            pic.x = b.x + b.width / 2;
            pic.y = b.y + b.height / 2;
            box.addChildAt(pic, box.getChildIndex(ic) + 1);
            RArt.pet(pic, int(last.raceId) > 0 ? int(last.raceId) : p ? p.raceId : 0, Math.min(b.width, b.height) - 20, "_L");
         }
         var done:Function = function():void { hideDialog(); tellLearnt(); };
         wrap(box, named(box, "btnNext"), "expLvOk", done);
         // Its X (unnamed): the button the tutorial placed before its 知道了 rows.
         for (var i:int = 0; i < box.numChildren; i++)
         {
            var d:DisplayObject = box.getChildAt(i);
            if (d.name.indexOf("instance") == 0 && d is InteractiveObject && !(d is TextField) && !(d is MovieClip) && d.getBounds(box).width < 50 && d.y < 120)
            {
               wrap(box, d, "expLvClose", done);
               break;
            }
         }
         var drag:DisplayObject = named(box, "tuopanel");
         if (drag != null) drag.alpha = 0;
      }

      private static function put(c:DisplayObjectContainer, n:String, s:String):void
      {
         var t:TextField = named(c, n) as TextField;
         if (t == null) return;
         t.text = s;
         fit(t);
      }

      /** A field of the art laid out for the tutorial's sample grows to its text (吉拉 -> 兔小子, 14 -> 31). */
      private static function fit(t:TextField):void
      {
         if (t.textWidth + 5 <= t.width) return;
         var align:String = String(t.getTextFormat().align);
         t.wordWrap = false;
         t.autoSize = align == TextFormatAlign.CENTER ? TextFieldAutoSize.CENTER : align == TextFormatAlign.RIGHT ? TextFieldAutoSize.RIGHT : TextFieldAutoSize.LEFT;
      }

      public function close():void
      {
         stopRepeat();
         SocketClient.instance.removeEventListener("2-12", onExp);
         SocketClient.instance.removeEventListener("2-13", onGiven);
         SocketClient.instance.removeEventListener("2211", onDetail);
         SocketClient.instance.removeEventListener("2242", onLevelUp);
         SocketClient.instance.removeEventListener("2234", onLearnt);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
