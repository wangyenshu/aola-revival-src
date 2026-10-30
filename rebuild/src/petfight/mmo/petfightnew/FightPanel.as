package mmo.petfightnew
{
   import com.greensock.TweenLite;
   import flash.display.DisplayObject;
   import flash.display.FrameLabel;
   import flash.display.Graphics;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;
   import mmo.loader.layer.HangUpLevel;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT. The battle screen of a 1v1 亚比 fight, laid out as the official
    * screenshots of December 2011 – November 2012 show it
    * (refs/battle-ui-2011-2012): the wild 亚比 facing us at the upper left,
    * with "Lv16 小花蝶" and a small HP bar under it; mine, seen from behind,
    * near the camera at the lower right; along the right edge my 亚比's HP
    * bar, name plate, LV badge and portrait, the command wheel (道具 捕捉 战斗
    * 亚比 逃跑), the page the wheel opens (four green skills with 威力 and PP
    * and the attribute matchup 强效 / 普通 / 弱效; the balls; the items; the
    * bag), and the 对战 log at the bottom.
    *
    * It runs on the fighting layer of the 2013 LayerManager (the scene and its
    * control bar are hidden meanwhile), over the scene's battle background
    * (petfightbackground/, BackgroundMap). The 亚比 are their battle sprites
    * (FightPetView) at the places of the era pet/fightpreview (myPetHolder
    * 238,242 for the far side, VSPetHolder 626,368 for the near side); skill
    * effects are fightassets/effect<skillId> (mmo.petfight.effect<id>; labels
    * "move" and "all" placed as the preview places them, mirrored for the far
    * side). Server messages queue and play one after another; the commands
    * open when a turn starts (START_BATTLE, BATTLE_NEXT_TURN).
    */
   public class FightPanel extends Sprite
   {
      /** [class, file] set through IPetFight.changeBackgroundRes. */
      public static var backgroundOverride:Array;

      public static const ATTR_NAMES:Array = ["普通", "格斗", "飞行", "毒", "爬行", "土", "虫", "数码", "机械", "火", "水", "木", "电", "神秘", "冰", "上古", "暗黑", "未知", "光明", "龙"];
      private static const DEFAULT_BACK:Array = ["mmo.petfight.FightSpace", "petfightbackground/fightspace"];
      private static const BALL_IDS:Object = {32: 1, 64: 1, 67: 1, 68: 1};
      /** The places of the era pet/fightpreview: myPetHolder (far) and VSPetHolder (near). */
      private static const FAR:Array = [238, 242];
      private static const NEAR:Array = [626, 368];
      private static const PANEL_X:int = 816;
      private static const PANEL_Y:int = 118;

      private var svc:LoginPetFightService;
      private var bgLayer:Sprite = new Sprite();
      private var petLayer:Sprite = new Sprite();
      private var fxLayer:Sprite = new Sprite();
      private var ui:Sprite = new Sprite();
      private var page:Sprite = new Sprite();
      private var popupLayer:Sprite = new Sprite();
      private var floatLayer:Sprite = new Sprite();

      private var me:Object;
      private var vs:Object;
      private var myView:FightPetView;
      private var vsView:FightPetView;
      private var hpShown:Array = [{v: 0}, {v: 0}];

      // my HUD (top right) and the wild one's label
      private var myBar:Shape = new Shape();
      private var myHpText:TextField;
      private var myName:TextField;
      private var myLv:Sprite;
      private var myPortrait:Sprite = new Sprite();
      private var vsTag:Sprite = new Sprite();
      private var vsBar:Shape = new Shape();
      private var vsName:TextField;
      private var vsIcon:Sprite = new Sprite();
      private var portraitRace:int;

      private var wheel:Object = {};
      private var current:String = "fight";
      private var log:TextField;
      private var catchTip:Sprite;
      private var tooltip:Sprite;

      private var queue:Array = [];
      private var busy:Boolean = true;
      private var closed:Boolean;
      private var canCatch:Boolean;
      private var canEscape:Boolean;
      private var canSwitch:Boolean;
      private var catchStars:int;
      /** From what part of its HP a ball works (the revival server's chp; a fifth otherwise). */
      private var catchHp:Number = 0.2;
      private var commandsOn:Boolean;
      private var forcedSwitch:Boolean;
      private var turn:int = 1;
      private var results:Array = [];
      private var caught:Object;

      public function FightPanel(svc:LoginPetFightService, join:Object)
      {
         super();
         this.svc = svc;
         canEscape = join.esc != false;
         canSwitch = join.sw != false;
         canCatch = join.ch == true;
         catchStars = Math.max(1, Math.min(5, int(join.cd) || 1));
         if (join.chp != null && Number(join.chp) > 0) catchHp = Number(join.chp);
         takeViews(join.pmmList as Array);
         build();
         LayerManager.switchLayer(LayerManager.FIGHTING_LAYER, HangUpLevel.HIDE);
         LayerManager.getFightingScene().addChild(this);
         loadBackground();
         loadSounds();
         var waiting:int = 2;
         var ready:Function = function():void
         {
            if (--waiting == 0) onReady();
         };
         myView = makePetView(true, ready);
         vsView = makePetView(false, ready);
         refresh(false);
         showPage("fight");
         setCommands(false);
         addLog("野生的<font color='#FFE66A'>" + petName(vs) + "</font>出现了！");
      }

      // ---------------------------------------------------------------- data

      private function takeViews(list:Array):void
      {
         for each (var o:Object in list || [])
         {
            if (o == null || o.battleView == null) continue;
            if (int(o.battleView.slotId) == 0) me = o;
            else vs = o;
         }
      }

      private static function brief(v:Object):Object
      {
         try { return v.battleView.pmList[0]; } catch (e:Error) {}
         return null;
      }

      private static function view(v:Object):Object
      {
         var b:Object = brief(v);
         return b ? b.pmSView : {};
      }

      private static function petName(v:Object):String
      {
         var s:Object = view(v);
         return s.nick ? String(s.nick) : String(s.nm || "亚比");
      }

      private static function hpOf(v:Object):int
      {
         return int(view(v).c0);
      }

      private static function maxHpOf(v:Object):int
      {
         var a:Array = String(view(v).s0 || "1#0").split("#");
         return Math.max(1, int(a[0]) + int(a[1]));
      }

      private function sideView(slot:int):Object
      {
         return slot == 0 ? me : vs;
      }

      private function petViewOf(slot:int):FightPetView
      {
         return slot == 0 ? myView : vsView;
      }

      private static function holder(mine:Boolean):Array
      {
         return mine ? NEAR : FAR;
      }

      // ---------------------------------------------------------------- screen

      private function build():void
      {
         addChild(bgLayer);
         addChild(petLayer);
         addChild(fxLayer);
         addChild(ui);
         addChild(popupLayer);
         addChild(floatLayer);
         floatLayer.mouseEnabled = floatLayer.mouseChildren = false;
         buildHud();
         buildWheel();
         buildPanel();
         buildLog();
         buildVsTag();
      }

      /** Top right: HP bar with "cur/max", the name plate, LV badge and the portrait ring. */
      private function buildHud():void
      {
         myBar.x = 548;
         myBar.y = 4;
         ui.addChild(myBar);
         myHpText = FightSkin.label("", 11, 0xFFFFFF, 0x8A3A00, true, TextFormatAlign.CENTER, "Arial");
         myHpText.y = 4;
         ui.addChild(myHpText);
         var plate:Shape = new Shape();
         var g:Graphics = plate.graphics;
         g.lineStyle(1.5, 0x5AA7D6);
         FightSkin.vgrad(g, 98, 17, 0xF4FCFF, 0xBFE4F8, 21);
         g.drawRoundRect(624, 21, 98, 17, 14, 14);
         g.endFill();
         ui.addChild(plate);
         myName = FightSkin.label("", 12, 0x1D4F7A, 0xFFFFFFFF, true, TextFormatAlign.CENTER);
         myName.y = 21;
         ui.addChild(myName);
         var ring:Shape = new Shape();
         g = ring.graphics;
         g.lineStyle(2, 0x1E6FA8);
         FightSkin.vgrad(g, 76, 76, 0xC9F0FF, 0x3D9AD2, -7);
         g.drawCircle(779, 31, 38);
         g.endFill();
         g.lineStyle(2, 0xFFFFFF, 0.9);
         FightSkin.vgrad(g, 60, 60, 0xFFF7D8, 0xF2C66A, 1);
         g.drawCircle(779, 31, 30);
         g.endFill();
         ui.addChild(ring);
         myPortrait.x = 779;
         myPortrait.y = 31;
         myPortrait.mouseEnabled = myPortrait.mouseChildren = false;
         ui.addChild(myPortrait);
         // The LV badge sits on the ring's edge, over it.
         myLv = FightSkin.lvBadge(1);
         myLv.x = 731;
         myLv.y = 34;
         ui.addChild(myLv);
      }

      /** The command wheel: 道具 捕捉 战斗 亚比 逃跑 around a glass ring. */
      private function buildWheel():void
      {
         var base:Shape = new Shape();
         var g:Graphics = base.graphics;
         g.lineStyle(2, 0x5AA7D6);
         FightSkin.vgrad(g, 124, 124, 0xEFFAFF, 0x9ED4F1, 0);
         g.drawCircle(891, 61, 58);
         g.endFill();
         g.lineStyle(3, 0x48A6DE);
         g.drawCircle(891, 61, 40);
         g.lineStyle();
         // the little arrows between the bubbles
         g.beginFill(0x48A6DE);
         for each (var a:Array in [[891, 14, 0], [891, 108, 180], [844, 61, 270], [938, 61, 90]])
         {
            var c:Number = Math.cos(a[2] * Math.PI / 180), s:Number = Math.sin(a[2] * Math.PI / 180);
            g.moveTo(a[0] + s * 0 - c * 6, a[1] - c * 0 - s * 6);
            g.lineTo(a[0] + s * 7, a[1] - c * 7);
            g.lineTo(a[0] + c * 6, a[1] + s * 6);
         }
         g.endFill();
         ui.addChild(base);
         var defs:Array = [["item", "道具", 846, 25, 22], ["catch", "捕捉", 936, 25, 22], ["pet", "亚比", 846, 98, 22], ["escape", "逃跑", 936, 98, 22], ["fight", "战斗", 891, 61, 29]];
         for each (var d:Array in defs)
         {
            var b:WheelButton = new WheelButton(d[0], d[1], d[4], d[0] == "fight");
            b.x = d[2];
            b.y = d[3];
            b.addEventListener(MouseEvent.CLICK, onWheel);
            wheel[d[0]] = b;
            ui.addChild(b);
         }
      }

      /** The glass panel under the wheel, joined to it by a short neck. */
      private function buildPanel():void
      {
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         FightSkin.frame(g, PANEL_X, PANEL_Y, 142, 316, 18);
         g.lineStyle(2, 0x5AA7D6);
         FightSkin.vgrad(g, 30, 12, 0xEFFAFF, 0xD6EEFA, PANEL_Y - 6);
         g.drawRoundRect(876, PANEL_Y - 6, 30, 14, 8, 8);
         g.endFill();
         g.lineStyle();
         ui.addChildAt(s, 0);
         page.x = 0;
         page.y = 0;
         ui.addChild(page);
      }

      /** Bottom right: the 对战 / 聊天 log and the chat line under it. */
      private function buildLog():void
      {
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         FightSkin.darkPanel(g, 688, 438, 270, 96, 14);
         // the two tabs down the left side
         g.lineStyle(1, 0x7FC6F0);
         FightSkin.vgrad(g, 20, 44, 0x6FC4F2, 0x2A78C6, 442);
         g.drawRoundRectComplex(690, 442, 20, 44, 8, 0, 8, 0);
         g.endFill();
         FightSkin.vgrad(g, 20, 42, 0x2A5FB0, 0x173E86, 488);
         g.drawRoundRectComplex(690, 488, 20, 42, 8, 0, 8, 0);
         g.endFill();
         // the chat line
         g.lineStyle(1.5, 0x5AA7D6);
         FightSkin.vgrad(g, 270, 22, 0xD6EFFC, 0x9CD0EE, 536);
         g.drawRoundRect(688, 536, 270, 22, 12, 12);
         g.endFill();
         g.lineStyle(1, 0x7FB8DA);
         g.beginFill(0xFFFFFF);
         g.drawRoundRect(724, 539, 196, 16, 8, 8);
         g.endFill();
         ui.addChild(s);
         var t1:TextField = FightSkin.label("对\n战", 11, 0xFFFFFF, 0x15457A, true);
         t1.x = 693;
         t1.y = 448;
         ui.addChild(t1);
         var t2:TextField = FightSkin.label("聊\n天", 11, 0xA9CBEF, 0x0F2C74, true);
         t2.x = 693;
         t2.y = 492;
         ui.addChild(t2);
         var cur:TextField = FightSkin.label("当前", 11, 0x1D4F7A, 0xFFFFFFFF, true);
         cur.x = 694;
         cur.y = 540;
         ui.addChild(cur);
         log = new TextField();
         log.defaultTextFormat = new TextFormat("宋体", 12, 0xFFFFFF);
         log.multiline = log.wordWrap = true;
         log.selectable = false;
         log.x = 714;
         log.y = 442;
         log.width = 238;
         log.height = 88;
         ui.addChild(log);
      }

      /** The wild 亚比's label: HP bar, attribute icon and "Lv3小冰犬". */
      private function buildVsTag():void
      {
         vsTag.x = FAR[0];
         vsTag.y = FAR[1] + 12;
         vsTag.mouseEnabled = vsTag.mouseChildren = false;
         vsBar.x = -42;
         vsTag.addChild(vsBar);
         vsIcon.x = -50;
         vsIcon.y = 20;
         vsTag.addChild(vsIcon);
         vsName = FightSkin.label("", 12, 0xFFFFFF, 0x1A2A40, true, TextFormatAlign.LEFT);
         vsName.x = -40;
         vsName.y = 11;
         vsTag.addChild(vsName);
         ui.addChild(vsTag);
      }

      private function makePetView(mine:Boolean, ready:Function):FightPetView
      {
         var v:FightPetView = new FightPetView(int(view(mine ? me : vs).r), !mine);
         var at:Array = holder(mine);
         v.x = at[0];
         v.y = at[1];
         // The far 亚比 stands behind the near one.
         if (mine) petLayer.addChild(v);
         else petLayer.addChildAt(v, 0);
         v.load(ready);
         return v;
      }

      private function loadBackground():void
      {
         var si:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         var b:Array = backgroundOverride || BackgroundMap.get(si ? si.sceneName : "") || DEFAULT_BACK;
         var put:Function = function(... a):void
         {
            if (closed || !ApplicationDomain.currentDomain.hasDefinition(b[0])) return;
            var C:Class = getDefinitionByName(b[0]) as Class;
            var d:DisplayObject = new C() as DisplayObject;
            if (d) bgLayer.addChild(d);
         };
         bgLayer.graphics.beginFill(0x0B2F33);
         bgLayer.graphics.drawRect(0, 0, 960, 560);
         bgLayer.graphics.endFill();
         if (ApplicationDomain.currentDomain.hasDefinition(b[0])) put();
         else ResScheduler.getResource(b[1], put, b[0], function(e:* = null):void { RLog.log("fight: no background " + b[1]); });
      }

      // ---------------------------------------------------------------- sounds (pet/petfightmusic: sounds/fightsounds x7001–x7011)

      private var music:Object;

      private function loadSounds():void
      {
         try
         {
            ServiceContainer.instance.tryGetService("PetFightMusicService", function(s:IService, o:Object):void
            {
               music = s;
               try { Object(s).loadPetFightMusicInit(); } catch (e:Error) {}
            });
         }
         catch (e:Error) {}
      }

      private function sound(id:String):void
      {
         try
         {
            var s:Sound = music ? Object(music).getMusicByName({other: id}) as Sound : null;
            if (s) s.play();
         }
         catch (e:Error) {}
      }

      // ---------------------------------------------------------------- HUD

      private function refresh(animate:Boolean):void
      {
         refreshSide(0, animate);
         refreshSide(1, animate);
         if (current == "fight") showPage("fight");
      }

      private function refreshSide(slot:int, animate:Boolean):void
      {
         var v:Object = sideView(slot);
         var s:Object = view(v);
         var hp:int = hpOf(v), max:int = maxHpOf(v);
         var st:String = s.st ? " [" + String(s.st).split(",").join("][") + "]" : "";
         if (slot == 0)
         {
            myName.text = petName(v) + st;
            myName.x = 673 - myName.width / 2;
            TextField(myLv.getChildByName("lv")).text = String(int(s.lv));
            TextField(myLv.getChildByName("lv")).x = -TextField(myLv.getChildByName("lv")).width / 2;
            myHpText.text = hp + "/" + max;
            myHpText.x = 645 - myHpText.width / 2;
            if (portraitRace != int(s.r))
            {
               portraitRace = int(s.r);
               FightSkin.petIcon(myPortrait, portraitRace, 52);
            }
         }
         else
         {
            vsName.text = "Lv" + int(s.lv) + petName(v) + st;
            FightSkin.attributeIcon(vsIcon, attrOf(v), 16);
         }
         var shown:Object = hpShown[slot];
         TweenLite.killTweensOf(shown);
         if (animate && shown.v != hp)
         {
            TweenLite.to(shown, 0.6, {v: hp, onUpdate: function():void { drawBar(slot, shown.v, max); }});
         }
         else
         {
            shown.v = hp;
            drawBar(slot, hp, max);
         }
      }

      private function drawBar(slot:int, hp:Number, max:int):void
      {
         if (slot == 0) FightSkin.hpBar(myBar.graphics, 195, 15, hp / max, true);
         else FightSkin.hpBar(vsBar.graphics, 84, 9, hp / max, false);
      }

      /** The 亚比's first attribute (pmSView.t, which the revival server adds to PetBriefInfo's fields). */
      private static function attrOf(v:Object):int
      {
         var s:Object = view(v);
         return s.t != undefined ? int(s.t) : 0;
      }

      private function addLog(html:String):void
      {
         if (html == null || html == "") return;
         log.htmlText = log.htmlText + "<font face='宋体' size='12' color='#FFFFFF'>" + html + "</font>";
         log.scrollV = log.maxScrollV;
      }

      /** A server line: "吉拉使用了背摔！" reads "[吉拉] 使用了 背摔" in green and blue, as in 2011. */
      private function addServerLine(line:String):void
      {
         if (line == null || line == "") return;
         var m:Array = line.match(/^(.+?)使用了(.+?)！$/);
         if (m) addLog("<font color='#7CFF6A'>[" + esc(m[1]) + "]</font> 使用了 <font color='#66E0FF'>" + esc(m[2]) + "</font>");
         else addLog(esc(line));
      }

      private function addLines(desc:*, from:int = 0):void
      {
         var a:Array = String(desc || "").split("\n");
         for (var i:int = from; i < a.length; i++) addServerLine(a[i]);
      }

      private static function esc(s:String):String
      {
         return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
      }

      /** Damage and healing numbers over a 亚比: "-23", "克制-112", "暴击-40", "+40", "MISS". */
      private function float(slot:int, value:String, color:uint, big:Boolean = false):void
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("Arial Black", big ? 34 : 28, color, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.text = value;
         t.filters = [new GlowFilter(0xFFFFFF, 1, 3, 3, 10), new GlowFilter(0x5A0A00, 1, 2, 2, 6)];
         var at:Array = holder(slot == 0);
         t.x = at[0] - t.width / 2 - (slot == 0 ? 0 : 20);
         t.y = at[1] - 150;
         floatLayer.addChild(t);
         TweenLite.to(t, 1.3, {y: t.y - 40, alpha: 0, delay: 0.3, onComplete: function():void { if (t.parent) t.parent.removeChild(t); }});
      }

      /** The skill's name called out by the 亚比 that uses it ("龙牙剑!!"). */
      private function callout(slot:int, text:String):void
      {
         var t:TextField = FightSkin.label(text + "!!", 16, 0xFFFFFF, 0x173F7A, true);
         var at:Array = holder(slot == 0);
         t.x = slot == 0 ? at[0] - 140 : at[0] + 30;
         t.y = at[1] - (slot == 0 ? 190 : 170);
         floatLayer.addChild(t);
         TweenLite.to(t, 0.4, {alpha: 0, delay: 1.1, onComplete: function():void { if (t.parent) t.parent.removeChild(t); }});
      }

      // ---------------------------------------------------------------- the wheel and its pages

      private function setCommands(on:Boolean):void
      {
         commandsOn = on;
         applyCommandState();
      }

      private function applyCommandState():void
      {
         var on:Boolean = commandsOn && !forcedSwitch;
         WheelButton(wheel.fight).enabled = on || current != "fight";
         WheelButton(wheel.item).enabled = on;
         WheelButton(wheel.catch).enabled = on && canCatch;
         WheelButton(wheel.pet).enabled = (on && canSwitch) || forcedSwitch;
         WheelButton(wheel.escape).enabled = on && canEscape;
         for (var i:int = 0; i < page.numChildren; i++)
         {
            var c:DisplayObject = page.getChildAt(i);
            if (c is SkillRow) SkillRow(c).enabled = on && SkillRow(c).pp > 0;
            else if (c is SlotButton) SlotButton(c).enabled = on;
            else if (c is PetRow) PetRow(c).enabled = (on || forcedSwitch) && PetRow(c).data.pick == true;
         }
      }

      private function onWheel(e:MouseEvent):void
      {
         var n:String = DisplayObject(e.currentTarget).name;
         if (n == "escape")
         {
            if (!commandsOn) return;
            setCommands(false);
            addLog("你选择了逃跑……");
            PetClient.instance.escape();
            return;
         }
         showPage(n);
      }

      private function showPage(n:String):void
      {
         current = n;
         for each (var key:String in ["fight", "item", "catch", "pet"]) WheelButton(wheel[key]).selected = key == n;
         while (page.numChildren) page.removeChildAt(0);
         hideTooltip();
         if (catchTip && catchTip.parent) catchTip.parent.removeChild(catchTip);
         if (n == "fight") fightPage();
         else if (n == "catch") itemPage(true);
         else if (n == "item") itemPage(false);
         else if (n == "pet") petPage();
         applyCommandState();
      }

      /** 战斗: the four skills and, under them, how my attribute fares against theirs. */
      private function fightPage():void
      {
         var b:Object = brief(me);
         var skills:Array = b ? (b.skills as Array) || [] : [];
         for (var i:int = 0; i < 4; i++)
         {
            var row:SkillRow = new SkillRow(skills[i]);
            row.x = PANEL_X + 5;
            row.y = PANEL_Y + 20 + i * 50;
            if (skills[i])
            {
               row.addEventListener(MouseEvent.CLICK, onSkill);
               row.addEventListener(MouseEvent.ROLL_OVER, onSkillOver);
               row.addEventListener(MouseEvent.ROLL_OUT, hideTooltip);
            }
            page.addChild(row);
         }
         var mult:Number = matchup();
         var y:int = PANEL_Y + 238;
         var mineIcon:Sprite = new Sprite();
         mineIcon.x = PANEL_X + 116;
         mineIcon.y = y + 12;
         page.addChild(mineIcon);
         FightSkin.attributeIcon(mineIcon, attrOf(me), 24);
         var theirIcon:Sprite = new Sprite();
         theirIcon.x = PANEL_X + 26;
         theirIcon.y = y + 12;
         page.addChild(theirIcon);
         FightSkin.attributeIcon(theirIcon, attrOf(vs), 24);
         var pill:Shape = new Shape();
         var g:Graphics = pill.graphics;
         g.lineStyle(1.5, 0xB24A00);
         FightSkin.vgrad(g, 46, 20, 0xFFD27A, 0xF07A12, y + 2);
         g.drawRoundRect(PANEL_X + 48, y + 2, 46, 20, 18, 18);
         g.endFill();
         g.lineStyle(2, 0xF07A12);
         g.moveTo(PANEL_X + 40, y + 12);
         g.lineTo(PANEL_X + 48, y + 12);
         g.moveTo(PANEL_X + 94, y + 12);
         g.lineTo(PANEL_X + 102, y + 12);
         g.beginFill(0xF07A12);
         g.lineStyle();
         g.moveTo(PANEL_X + 38, y + 12);
         g.lineTo(PANEL_X + 44, y + 7);
         g.lineTo(PANEL_X + 44, y + 17);
         g.endFill();
         page.addChild(pill);
         var t:TextField = FightSkin.label(mult > 1 ? "强效" : (mult < 1 ? (mult == 0 ? "无效" : "弱效") : "普通"), 12, 0xFFFFFF, 0x9A3A00, true, TextFormatAlign.CENTER);
         t.x = PANEL_X + 71 - t.width / 2;
         t.y = y + 3;
         page.addChild(t);
         var tip:TextField = FightSkin.label("我方属性对敌方", 10, 0x2A6F9A, 0xFFFFFFFF, false, TextFormatAlign.CENTER, "宋体");
         tip.x = PANEL_X + 71 - tip.width / 2;
         tip.y = y + 28;
         page.addChild(tip);
      }

      /** How my 亚比's own attribute does against the wild one's (battleView.mu, from the attribute table of pmdata). */
      private function matchup():Number
      {
         return me && me.battleView && me.battleView.mu != undefined ? Number(me.battleView.mu) : 1;
      }

      private function onSkillOver(e:MouseEvent):void
      {
         var row:SkillRow = e.currentTarget as SkillRow;
         var s:Object = row.data;
         var kinds:Array = ["物理攻击", "特殊攻击", "属性攻击"];
         showTooltip(String(s.name) + "（" + (ATTR_NAMES[int(s.t)] || "") + "·" + (kinds[int(s.k)] || "") + "）", String(s.d || ""), row.x - 196, row.y);
      }

      private function showTooltip(title:String, body:String, x:Number, y:Number):void
      {
         hideTooltip();
         tooltip = new Sprite();
         tooltip.mouseEnabled = tooltip.mouseChildren = false;
         var t1:TextField = FightSkin.label(title, 12, 0xFFFFFF, 0xFFFFFFFF, true, TextFormatAlign.LEFT, "宋体");
         t1.x = 8;
         t1.y = 5;
         var t2:TextField = new TextField();
         t2.defaultTextFormat = new TextFormat("宋体", 12, 0xFFE66A);
         t2.multiline = t2.wordWrap = true;
         t2.width = 172;
         t2.autoSize = TextFieldAutoSize.LEFT;
         t2.selectable = false;
         t2.text = body;
         t2.x = 8;
         t2.y = 24;
         var g:Graphics = tooltip.graphics;
         g.lineStyle(1, 0x6FB6E8);
         g.beginFill(0x123A7A, 0.92);
         g.drawRoundRect(0, 0, 190, t2.y + t2.height + 8, 8, 8);
         g.endFill();
         tooltip.addChild(t1);
         tooltip.addChild(t2);
         tooltip.x = x;
         tooltip.y = y;
         popupLayer.addChild(tooltip);
      }

      private function hideTooltip(e:MouseEvent = null):void
      {
         if (tooltip && tooltip.parent) tooltip.parent.removeChild(tooltip);
         tooltip = null;
      }

      /** 捕捉 (balls) and 道具 (体力糖, 活力豆): the items of IItemService in squares with their counts. */
      private function itemPage(balls:Boolean):void
      {
         var list:Array = [];
         var items:IItemService;
         try
         {
            items = ServiceContainer.getService("ItemService") as IItemService;
            for each (var u:UserItem in items.getMyItemsByType(balls ? 6 : 5))
            {
               if (u.quantity <= 0 || balls != (BALL_IDS[u.materialId] == 1)) continue;
               list.push(u);
            }
         }
         catch (err:Error)
         {
            RLog.error("fight items", err);
         }
         for (var i:int = 0; i < 6; i++)
         {
            var u2:UserItem = list[i] as UserItem;
            var slot:SlotButton = new SlotButton(u2 ? u2.materialId : 0, u2 ? u2.quantity : 0, u2 ? {id: u2.materialId, ball: balls, item: u2.material} : null);
            slot.name = "fightSlot" + i;
            slot.x = PANEL_X + 10 + (i % 2) * 66;
            slot.y = PANEL_Y + 22 + int(i / 2) * 64;
            if (u2)
            {
               slot.addEventListener(MouseEvent.CLICK, onSlot);
               slot.addEventListener(MouseEvent.ROLL_OVER, onSlotOver);
               slot.addEventListener(MouseEvent.ROLL_OUT, hideTooltip);
            }
            page.addChild(slot);
         }
         if (list.length == 0)
         {
            var none:TextField = FightSkin.label(balls ? "你没有亚比球了" : "没有可以使用的道具", 12, 0x2A6F9A, 0xFFFFFFFF, false, TextFormatAlign.CENTER, "宋体");
            none.x = PANEL_X + 71 - none.width / 2;
            none.y = PANEL_Y + 220;
            page.addChild(none);
         }
         if (balls) showCatchTip();
      }

      private function onSlotOver(e:MouseEvent):void
      {
         var s:SlotButton = e.currentTarget as SlotButton;
         var it:Item = s.data.item as Item;
         if (it) showTooltip(it.name, it.description, s.x - 196, s.y);
      }

      private function onSlot(e:MouseEvent):void
      {
         var s:SlotButton = e.currentTarget as SlotButton;
         if (!commandsOn || s.data == null) return;
         hideTooltip();
         setCommands(false);
         if (s.data.ball) PetClient.instance.catchPM(1, int(s.data.id));
         else PetClient.instance.useItem(int(s.data.id), 0);
      }

      /** By the wild 亚比: "捕捉难度: ★★" and whether now is the time. */
      private function showCatchTip():void
      {
         catchTip = new Sprite();
         catchTip.mouseEnabled = catchTip.mouseChildren = false;
         var g:Graphics = catchTip.graphics;
         FightSkin.frame(g, 0, 0, 216, 54, 12);
         g.lineStyle(1, 0x2C7FC0);
         g.beginFill(0x2C7FC0);
         g.drawRoundRect(6, 5, 86, 18, 8, 8);
         g.endFill();
         var head:TextField = FightSkin.label("捕捉难度:", 12, 0xFFFFFF, 0x15457A, true);
         head.x = 10;
         head.y = 5;
         catchTip.addChild(head);
         var stars:TextField = FightSkin.label("★★★★★".substr(0, catchStars), 13, 0xFFE24A, 0x9A6A00, true, TextFormatAlign.LEFT, "宋体");
         stars.x = 96;
         stars.y = 5;
         catchTip.addChild(stars);
         var weak:Boolean = hpOf(vs) <= maxHpOf(vs) * catchHp;
         var msg:TextField = FightSkin.label(!canCatch ? "这只亚比不能捕捉。" : (weak ? "最好的机会，快扔亚比球！" : "现在很难捕捉，先把它打得没力气吧！"), 12, 0x1D4F7A, 0xFFFFFFFF, false, TextFormatAlign.LEFT, "宋体");
         msg.x = 10;
         msg.y = 29;
         catchTip.addChild(msg);
         catchTip.x = FAR[0] - 160;
         catchTip.y = FAR[1] + 44;
         ui.addChild(catchTip);
      }

      /** 亚比: the bag, to change the 亚比 that fights (or must, after one fell). */
      private function petPage():void
      {
         var list:Array = me && me.battleView ? (me.battleView.pmList as Array) || [] : [];
         var activeId:int = int(view(me).i);
         for (var i:int = 0; i < list.length && i < 6; i++)
         {
            var s:Object = list[i].pmSView;
            var row:PetRow = new PetRow(s, int(s.i) == activeId);
            s.pick = int(s.c0) > 0 && int(s.i) != activeId;
            row.x = PANEL_X + 5;
            row.y = PANEL_Y + 14 + i * 48;
            row.addEventListener(MouseEvent.CLICK, onPetRow);
            page.addChild(row);
         }
         if (forcedSwitch)
         {
            var t:TextField = FightSkin.label("请选择出战的亚比", 12, 0xD0281E, 0xFFFFFF, true, TextFormatAlign.CENTER, "宋体");
            t.x = PANEL_X + 71 - t.width / 2;
            t.y = PANEL_Y + 14 + 6 * 48 - 2;
            page.addChild(t);
         }
      }

      private function onPetRow(e:MouseEvent):void
      {
         var row:PetRow = e.currentTarget as PetRow;
         if ((!commandsOn && !forcedSwitch) || row.data.pick != true) return;
         setCommands(false);
         PetClient.instance.switchPM(int(row.data.i));
      }

      private function onSkill(e:MouseEvent):void
      {
         var row:SkillRow = e.currentTarget as SkillRow;
         if (!commandsOn || row.data == null || row.pp <= 0) return;
         hideTooltip();
         setCommands(false);
         PetClient.instance.useSkill(int(row.data.id), 1);
      }

      // ---------------------------------------------------------------- messages

      public function push(c:int, p:Object):void
      {
         queue.push([c, p]);
         if (!busy) next();
      }

      private function onReady():void
      {
         sound("x7005");
         later(0.2);
      }

      private function next():void
      {
         if (closed) return;
         busy = false;
         if (queue.length == 0) return;
         var m:Array = queue.shift();
         busy = true;
         try
         {
            handle(int(m[0]), m[1]);
         }
         catch (err:Error)
         {
            RLog.error("fight message " + m[0], err);
            later(0.1);
         }
      }

      private function later(seconds:Number = 0.35):void
      {
         TweenLite.delayedCall(seconds, next);
      }

      private function handle(c:int, p:Object):void
      {
         switch (c)
         {
            case 2401:
               sound("x7011");
               addLog("<font color='#FFE66A'>第1回合</font>");
               setCommands(true);
               later(0);
               break;
            case 2411:
               useSkill(p);
               break;
            case 2412:
               addLines(p.desc);
               if (p.refused) { setCommands(true); later(0); break; }
               takeViews(p.pmmList as Array);
               if (int(p.hpInc) > 0) float(0, "+" + int(p.hpInc), 0x3CC21E);
               refresh(true);
               later(0.8);
               break;
            case 2413:
               switchPet(p);
               break;
            case 2414:
               addLines(p.desc ? String(p.desc) : "成功逃跑了！");
               TweenLite.delayedCall(1.2, function():void { close({isEscape: true, isWin: false}); });
               break;
            case 2415:
               catchPet(p);
               break;
            case 2421:
               addLines(p.desc);
               takeViews(p.pmmList as Array);
               if (int(p.hpInc) < 0) float(int(p.slotId), String(int(p.hpInc)), 0xE8301E);
               refresh(true);
               faintIfDown(int(p.slotId));
               later(0.8);
               break;
            case 2402:
               takeViews(p.pmmList as Array);
               refresh(true);
               turn++;
               addLog("<font color='#FFE66A'>第" + turn + "回合</font>");
               setCommands(hpOf(me) > 0);
               if (current == "catch") showPage("catch");
               later(0);
               break;
            case 2422:
               takeViews(p.pmmList as Array);
               addLines(p.desc);
               forcedSwitch = true;
               setCommands(false);
               showPage("pet");
               later(0);
               break;
            case 2241:
               results.push(petName(me) + "获得了" + int(p.exp) + "点经验值。");
               later(0);
               break;
            case 2242:
               results.push(int(p.evolve) > 0 ? petName(me) + "升到了" + int(p.lv) + "级，进化了！" : petName(me) + "升到了" + int(p.lv) + "级！");
               later(0);
               break;
            case 2234:
               results.push("学会了新技能「" + p.name + "」！" + (p.used ? "" : "（可以在亚比背包里更换技能）"));
               later(0);
               break;
            case 2403:
               finish(p);
               break;
            default:
               later(0);
         }
      }

      private function faintIfDown(slot:int):void
      {
         if (hpOf(sideView(slot)) <= 0) petViewOf(slot).faint();
      }

      private function useSkill(p:Object):void
      {
         var att:int = int(p.reqSId);
         var tar:int = att == 0 ? 1 : 0;
         var attView:FightPetView = petViewOf(att);
         var tarView:FightPetView = petViewOf(tar);
         var lines:Array = String(p.desc || "").split("\n");
         var srt:int = int(p.srt);
         if (srt == 3)
         {
            addLines(p.desc);
            takeViews(p.pmmList as Array);
            refresh(true);
            faintIfDown(att);
            later(0.8);
            return;
         }
         var used:int = 0;
         while (used < lines.length && String(lines[used]).indexOf("使用了") < 0) used++;
         for (var i:int = 0; i <= used && i < lines.length; i++) addServerLine(lines[i]);
         if (p.name) callout(att, String(p.name));
         var pending:int = 2;
         var step:Function = function():void
         {
            if (--pending > 0) return;
            faintIfDown(0);
            faintIfDown(1);
            later(0.5);
         };
         var impact:Function = function():void
         {
            addLines(p.desc, used + 1);
            takeViews(p.pmmList as Array);
            var eff:Number = p.eff != undefined ? Number(p.eff) : 1;
            if (srt == 2) float(tar, "MISS", 0xFFFFFF);
            else if (int(p.hpInc) < 0) float(tar, (p.cri ? "暴击" : (eff > 1 ? "克制" : (eff < 1 ? "微弱" : ""))) + int(p.hpInc), p.cri ? 0xFFB01E : 0xE8301E, p.cri || eff > 1);
            if (int(p.selfHpInc) > 0) float(att, "+" + int(p.selfHpInc), 0x3CC21E);
            else if (int(p.selfHpInc) < 0) float(att, String(int(p.selfHpInc)), 0xE8301E);
            refresh(true);
            if (srt != 2 && int(p.hpInc) < 0) tarView.hurt(step);
            else step();
         };
         attView.attack(int(p.k), function():void
         {
            playEffect(int(p.id), att == 0, p.self == true, impact);
         }, step);
      }

      private function playEffect(skillId:int, mine:Boolean, selfTarget:Boolean, done:Function):void
      {
         var cls:String = "mmo.petfight.effect" + skillId;
         var finished:Boolean = false;
         var fx:MovieClip;
         var guard:Timer = new Timer(5000, 1);
         var end:Function = function(... a):void
         {
            if (finished) return;
            finished = true;
            guard.stop();
            if (fx)
            {
               fx.stop();
               if (fx.parent) fx.parent.removeChild(fx);
            }
            done();
         };
         guard.addEventListener(TimerEvent.TIMER_COMPLETE, end);
         guard.start();
         var go:Function = function(... a):void
         {
            if (finished || closed) return;
            if (skillId <= 0 || !ApplicationDomain.currentDomain.hasDefinition(cls)) { end(); return; }
            var C:Class = getDefinitionByName(cls) as Class;
            fx = new C() as MovieClip;
            if (fx == null || fx.totalFrames < 2) { end(); return; }
            // Effects are drawn for the near 亚比 attacking the far one, and mirrored for the far side.
            var A:Array = holder(mine), T:Array = holder(!mine);
            var labels:Array = fx.currentLabels;
            var isMove:Boolean = labelFrame("move", labels) > 0;
            var isAll:Boolean = labelFrame("all", labels) > 0;
            if (isAll)
            {
               fx.x = mine ? 0 : 960;
               fx.y = 0;
            }
            else if (isMove || selfTarget)
            {
               fx.x = A[0];
               fx.y = A[1];
               if (isMove)
               {
                  var p1:int = labelFrame("p1", labels), p2:int = labelFrame("p2", labels);
                  if (p1 > 0 && p2 > p1) fx.addFrameScript(p1 - 1, function():void
                  {
                     TweenLite.to(fx, p2 - p1, {x: T[0], y: T[1], useFrames: true});
                  });
               }
            }
            else
            {
               fx.x = T[0];
               fx.y = T[1];
            }
            if (!mine) fx.scaleX = -1;
            fxLayer.addChild(fx);
            fx.addFrameScript(fx.totalFrames - 1, end);
            fx.gotoAndPlay(1);
         };
         if (skillId <= 0) end();
         else if (ApplicationDomain.currentDomain.hasDefinition(cls)) go();
         else ResScheduler.getResource("fightassets/effect" + skillId, go, cls, function(e:* = null):void { end(); });
      }

      private static function labelFrame(name:String, labels:Array):int
      {
         for each (var l:FrameLabel in labels) if (l.name == name) return l.frame;
         return 0;
      }

      private function switchPet(p:Object):void
      {
         var ext:Object = p.extInfo || {};
         addLines(ext.desc);
         if (ext.refused)
         {
            if (forcedSwitch) showPage("pet");
            else setCommands(true);
            later(0);
            return;
         }
         var wasForced:Boolean = forcedSwitch || ext.forced == true;
         forcedSwitch = false;
         me = p.playerInfo;
         var old:FightPetView = myView;
         myView = makePetView(true, function():void
         {
            old.dispose();
            refresh(false);
            showPage("fight");
            sound("x7005");
            if (wasForced) setCommands(true);
            later(0.4);
         });
         myView.alpha = 0;
         TweenLite.to(myView, 0.4, {alpha: 1});
      }

      private function catchPet(p:Object):void
      {
         addLines(p.desc);
         if (p.refused)
         {
            setCommands(true);
            later(0);
            return;
         }
         var ok:Boolean = int(p.pmId) > 0;
         if (ok) caught = p;
         var from:Array = holder(true), to:Array = holder(false);
         var ball:Sprite = new Sprite();
         var pic:Sprite = new Sprite();
         ball.addChild(pic);
         FightSkin.itemIcon(pic, int(p.itemId), 40);
         ball.x = from[0] - 30;
         ball.y = from[1] - 80;
         fxLayer.addChild(ball);
         TweenLite.to(ball, 0.6, {x: to[0], y: to[1] - 60, onComplete: function():void
         {
            if (ok)
            {
               sound("x7006");
               TweenLite.to(vsView, 0.5, {alpha: 0, scaleX: 0.2, scaleY: 0.2, onComplete: function():void
               {
                  TweenLite.to(ball, 0.15, {rotation: 20, onComplete: function():void
                  {
                     TweenLite.to(ball, 0.15, {rotation: -20, onComplete: function():void
                     {
                        TweenLite.to(ball, 0.15, {rotation: 0, onComplete: function():void { later(0.6); }});
                     }});
                  }});
               }});
            }
            else
            {
               sound("x7007");
               TweenLite.to(ball, 0.4, {alpha: 0, scaleX: 1.6, scaleY: 1.6, onComplete: function():void
               {
                  if (ball.parent) ball.parent.removeChild(ball);
                  later(0.3);
               }});
            }
         }});
      }

      // ---------------------------------------------------------------- the end

      private function finish(p:Object):void
      {
         setCommands(false);
         var win:Boolean = p.isWin == true;
         sound(win ? "x7009" : "x7010");
         var done:Function = function():void { close({isWin: win, isCatched: p.isCatched == true, raceId: int(p.raceId), isEscape: false}); };
         if (p.isCatched && caught)
         {
            showCaught(caught, done);
            return;
         }
         var title:String = win ? "战斗胜利" : "战斗失败";
         var lines:Array = results.length ? results : (win ? ["战斗胜利！"] : ["你的亚比都倒下了……", "快打开亚比背包，带它们恢复体力吧！"]);
         showResult(title, lines, done);
      }

      /** A dialog in the style of the 2011 panels: blue frame, orange title, 知道了. */
      private function dialog(title:String, w:int, h:int):Sprite
      {
         var box:Sprite = new Sprite();
         var g:Graphics = box.graphics;
         g.lineStyle(3, 0x2C7FC0);
         FightSkin.vgrad(g, w, h, 0x9ED8F6, 0x5DB0E2);
         g.drawRoundRect(0, 0, w, h, 26, 26);
         g.endFill();
         g.lineStyle(2, 0xFFFFFF, 0.9);
         FightSkin.vgrad(g, w - 20, h - 64, 0xEEF8FF, 0xCFE9F8, 52);
         g.drawRoundRect(10, 52, w - 20, h - 64, 16, 16);
         g.endFill();
         var t:TextField = FightSkin.label(title, 26, 0xFFE24A, 0xB2400A, true, TextFormatAlign.CENTER);
         t.filters = [new GlowFilter(0xB2400A, 1, 4, 4, 12), new GlowFilter(0xFFFFFF, 1, 3, 3, 6)];
         t.x = (w - t.width) / 2;
         t.y = 10;
         box.addChild(t);
         box.x = (960 - w) / 2;
         box.y = (560 - h) / 2 - 20;
         return box;
      }

      private function okButton(box:Sprite, w:int, h:int, onOk:Function):void
      {
         var ok:FightButton = new FightButton("知道了", 96, 32, 15, null, -1, true);
         ok.x = (w - 96) / 2;
         ok.y = h - 46;
         ok.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { onOk(); });
         box.addChild(ok);
      }

      private function showResult(title:String, lines:Array, onOk:Function):void
      {
         var w:int = 360, h:int = 150 + lines.length * 22;
         var box:Sprite = dialog(title, w, h);
         var body:TextField = new TextField();
         body.defaultTextFormat = new TextFormat("宋体", 14, 0x1D4F7A, false, null, null, null, null, TextFormatAlign.CENTER);
         body.multiline = body.wordWrap = true;
         body.selectable = false;
         body.width = w - 40;
         body.x = 20;
         body.y = 66;
         body.height = lines.length * 22 + 8;
         body.text = lines.join("\n");
         box.addChild(body);
         okButton(box, w, h, onOk);
         box.alpha = 0;
         popupLayer.addChild(box);
         TweenLite.to(box, 0.3, {alpha: 1});
      }

      /** 捕捉成功, after the 2011 panel: where it went, picture, name, level, 性格, stats. */
      private function showCaught(p:Object, onOk:Function):void
      {
         var w:int = 390, h:int = 330;
         var box:Sprite = dialog("捕捉成功", w, h);
         var pet:Object = p.pet && p.pet.pmSView ? p.pet.pmSView : {};
         var where:TextField = new TextField();
         where.defaultTextFormat = new TextFormat("宋体", 13, 0x7A3A00, true, null, null, null, null, TextFormatAlign.CENTER);
         where.width = w - 40;
         where.x = 20;
         where.y = 62;
         where.selectable = false;
         where.htmlText = "恭喜，你捕捉到的亚比已经放入 <font color='#E8301E'>" + (int(p.lc) == 1 ? "亚比背包" : "亚比仓库") + "</font> 中。";
         box.addChild(where);
         var picBox:Shape = new Shape();
         picBox.graphics.lineStyle(2, 0x7CB9D8);
         picBox.graphics.beginFill(0xFFFFFF);
         picBox.graphics.drawRoundRect(24, 92, 150, 150, 16, 16);
         picBox.graphics.endFill();
         box.addChild(picBox);
         var pic:Sprite = new Sprite();
         pic.x = 99;
         pic.y = 167;
         box.addChild(pic);
         FightSkin.petIcon(pic, int(p.raceId), 130, true);
         var s0:Array = String(pet.s0 || "0#0").split("#");
         var info:Array = [["名字", pet.nm || ""], ["等级", pet.lv || ""], ["性格", pet.ch || ""], ["体力", int(s0[0]) + int(s0[1])]];
         for (var i:int = 0; i < info.length; i++)
         {
            var row:TextField = new TextField();
            row.defaultTextFormat = new TextFormat("宋体", 14, 0x1D4F7A, true);
            row.selectable = false;
            row.width = 190;
            row.x = 188;
            row.y = 100 + i * 34;
            row.htmlText = info[i][0] + "：<font color='#E8301E'>" + info[i][1] + "</font>";
            box.addChild(row);
         }
         okButton(box, w, h, onOk);
         box.alpha = 0;
         popupLayer.addChild(box);
         TweenLite.to(box, 0.3, {alpha: 1});
      }

      public function close(result:Object = null):void
      {
         if (closed) return;
         closed = true;
         TweenLite.killDelayedCallsTo(next);
         if (myView) myView.dispose();
         if (vsView) vsView.dispose();
         if (parent) parent.removeChild(this);
         LayerManager.switchLayer(LayerManager.BASE_LAYER, HangUpLevel.REMOVE);
         svc.onPanelClosed(result || {isEscape: true});
      }
   }
}
