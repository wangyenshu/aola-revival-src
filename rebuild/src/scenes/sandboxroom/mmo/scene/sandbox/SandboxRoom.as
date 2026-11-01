package mmo.scene.sandbox
{
   import com.greensock.TweenLite;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.common.utils.tips.TipsManager;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.ScenePetAvatar;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.play.scene.revival;
   import mmo.revival.RDef;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.revival.mod.IModNpc;
   import mmo.revival.mod.IModRoom;

   /**
    * REVIVAL. The 沙盒 room (scene/sandboxroom, not of 2013): shows a room of
    * the mod loaded (mmo.control.ModRun, docs/MODDING.md). Built, it asks the
    * mod's run for the room's definition (background, walk mask, size, spawns)
    * and draws it; shown, it hands itself (IModRoom) to the room's build
    * function, which puts the NPCs, opponents, doors and pictures. Rooms are
    * 560 high and 960 to 2880 wide, scrolled as the wide rooms of the game.
    *
    * It asks for the run by name, so that this file needs nothing of the
    * control module to be built.
    */
   public class SandboxRoom extends SceneBase implements IModRoom
   {
      private static const H:int = 560;

      private var run:Object;
      private var shown:Object;
      private var roomW:int = 960;
      private var mask:BitmapData;
      private var maskSX:Number = 1;
      private var maskSY:Number = 1;
      private var wallTest:Function;

      private var bg:Sprite;
      private var fg:Sprite;
      private var ui:Sprite;
      private var screen:Sprite;
      private var leaveFns:Array = [];
      private var people:Array = [];

      public function SandboxRoom()
      {
         super(480, 470);
         // The layers SceneBase looks for, by name: obstruction (empty: isBlocked answers, but
         // the path finder wants one), background, overlap (players), foreground.
         var obs:Sprite = new Sprite();
         obs.name = "obstruction";
         addChild(obs);
         bg = new Sprite();
         bg.name = "background";
         addChild(bg);
         var players:Sprite = new Sprite();
         players.name = "overlap";
         addChild(players);
         fg = new Sprite();
         fg.name = "foreground";
         addChild(fg);
         var top:Sprite = new Sprite();
         top.name = "topground";
         addChild(top);
         try
         {
            var C:Object = getDefinitionByName("mmo.control.ModRun");
            run = C ? C.instance : null;
            shown = run ? run.roomToShow() : null;
         }
         catch (e:Error) { RLog.error("sandbox room", e); }
         if (shown == null)
         {
            drawEmpty();
            return;
         }
         try { draw(shown.def); } catch (e2:Error) { RLog.error("sandbox room " + shown.id, e2); }
      }

      // ---------------------------------------------------------------- drawing

      private static function display(p:*):DisplayObject
      {
         if (p is DisplayObject) return DisplayObject(p);
         if (p is BitmapData) return new Bitmap(BitmapData(p), "auto", true);
         if (p is Class)
         {
            try
            {
               var o:* = new p();
               if (o is BitmapData) return new Bitmap(BitmapData(o), "auto", true);
               return o as DisplayObject;
            }
            catch (e:Error) { RLog.error("sandbox room picture", e); }
         }
         return null;
      }

      private function draw(def:Object):void
      {
         var b:DisplayObject = display(def.background);
         if (b != null)
         {
            var r:Object = b.getBounds(b);
            var s:Number = H / Math.max(1, r.height);
            roomW = Math.max(960, Math.min(2880, Math.round(r.width * s)));
            b.scaleX = roomW / Math.max(1, r.width);
            b.scaleY = s;
            b.x = -r.x * b.scaleX;
            b.y = -r.y * s;
            bg.addChild(b);
         }
         else
         {
            roomW = Math.max(960, Math.min(2880, int(def.width) || 960));
            bg.graphics.beginFill(0x2A3B4E);
            bg.graphics.drawRect(0, 0, roomW, H);
            bg.graphics.endFill();
         }
         if (def.walk is Function) wallTest = def.walk as Function;
         else if (def.walk is BitmapData) mask = BitmapData(def.walk);
         else
         {
            var w:DisplayObject = display(def.walk);
            if (w != null)
            {
               // A walk mask drawn as a picture: made a bitmap of the room's size (one per two pixels).
               var wr:Object = w.getBounds(w);
               mask = new BitmapData(Math.ceil(roomW / 2), H / 2, true, 0);
               var m:Matrix = new Matrix();
               m.translate(-wr.x, -wr.y);
               m.scale(roomW / Math.max(1, wr.width) / 2, H / Math.max(1, wr.height) / 2);
               mask.draw(w, m);
            }
         }
         if (mask != null)
         {
            maskSX = mask.width / roomW;
            maskSY = mask.height / H;
         }
         var spawns:Object = def.spawns || {};
         var first:Point = null;
         for (var k:String in spawns)
         {
            var sp:Array = spawns[k] as Array;
            if (sp == null || sp.length < 2) continue;
            var pt:Point = new Point(Number(sp[0]), Number(sp[1]));
            addInitLocation(k, pt);
            if (first == null || k == "start") first = pt;
         }
         addInitLocation("start", first || new Point(Math.min(480, roomW / 2), 470));
         // The whole width is there from the start: SceneBase measures the room by its background
         // as the room is entered (what a room's build function puts later does not widen it).
         var full:Shape = new Shape();
         full.graphics.beginFill(0, 0);
         full.graphics.drawRect(0, 0, roomW, H);
         full.graphics.endFill();
         bg.addChildAt(full, 0);
      }

      private function drawEmpty():void
      {
         bg.graphics.beginFill(0x2A3B4E);
         bg.graphics.drawRect(0, 0, 960, H);
         bg.graphics.endFill();
      }

      // ---------------------------------------------------------------- walking

      override revival function get measuresOwnWidth():Boolean
      {
         return true;
      }

      /** Off the room, or a wall: the mod's test, or the mask's (alpha 128 or more and dark). */
      override public function isBlocked(x:Number, y:Number):Boolean
      {
         if (x < 0 || y < 0 || x >= roomW || y >= H) return true;
         if (wallTest != null)
         {
            try { return Boolean(wallTest(x, y)); } catch (e:Error) { wallTest = null; RLog.error("mod walk", e); }
            return false;
         }
         if (mask == null) return false;
         var c:uint = mask.getPixel32(int(x * maskSX), int(y * maskSY));
         if ((c >>> 24) < 128) return false;
         var lum:Number = 0.299 * ((c >> 16) & 0xFF) + 0.587 * ((c >> 8) & 0xFF) + 0.114 * (c & 0xFF);
         return lum < 128;
      }

      // ---------------------------------------------------------------- shown

      override protected function onJoinRoom():void
      {
         addUi();
         if (shown == null)
         {
            var t:TextField = RUI.text(16, 0xFFFFFF, true, 600);
            t.text = "沙盒里没有开始的模组。请打开控制栏上的「沙盒」，在「模组」页导入或选择一个模组后点「开始」。";
            t.x = 180;
            t.y = 250;
            ui.addChild(t);
            return;
         }
         addEventListener(Event.ENTER_FRAME, keepUi);
         if (run != null) run.attach(this);
      }

      override protected function onLeaveRoom():void
      {
         removeEventListener(Event.ENTER_FRAME, keepUi);
         for each (var p:ModPerson in people) p.dispose();
         people = [];
         var fns:Array = leaveFns;
         leaveFns = [];
         for each (var f:Function in fns)
         {
            try { f(); } catch (e:Error) { RLog.error("mod onLeave", e); }
         }
         if (run != null) run.detach(this);
      }

      private function addUi():void
      {
         ui = new Sprite();
         ui.name = "sandboxUi";
         topGround.addChild(ui);
         var plate:Shape = new Shape();
         plate.graphics.beginFill(0x0B2440, 0.6);
         plate.graphics.drawRoundRect(0, 0, 330, 40, 14, 14);
         plate.graphics.endFill();
         plate.x = 10;
         plate.y = 8;
         ui.addChild(plate);
         var title:TextField = RUI.text(14, 0xFFFFFF, true);
         var def:Object = shown ? shown.def : null;
         title.text = shown ? String(shown.mod || "") + (def && def.name ? " · " + String(def.name) : "") : "沙盒";
         if (title.width > 210) title.width = 210;
         title.x = 20;
         title.y = 18;
         ui.addChild(title);
         var leave:Sprite = RUI.button("离开沙盒", function():void
         {
            if (run != null) run.leave();
         }, 88, 28, 0x6CC0F5, 0x2E86D6, "sandboxLeave");
         leave.x = 244;
         leave.y = 14;
         ui.addChild(leave);
         screen = new Sprite();
         screen.name = "modScreen";
         ui.addChildAt(screen, 0);
      }

      /** The room's buttons stay put while a wide room scrolls under them. */
      private function keepUi(e:Event):void
      {
         if (ui != null) ui.x = -x;
      }

      // ---------------------------------------------------------------- IModRoom

      public function get id():String
      {
         return shown ? String(shown.id) : "";
      }

      public function get roomWidth():int
      {
         return roomW;
      }

      public function add(d:DisplayObject, x:Number = 0, y:Number = 0, layer:String = "back"):DisplayObject
      {
         if (d == null) return null;
         d.x = x;
         d.y = y;
         var into:DisplayObjectContainer = layer == "front" ? fg : layer == "players" ? playerLayer : layer == "screen" ? screen : bg;
         if (into == null) into = bg;
         into.addChild(d);
         return d;
      }

      public function remove(d:DisplayObject):void
      {
         if (d != null && d.parent != null) d.parent.removeChild(d);
      }

      public function door(x:Number, y:Number, w:Number, h:Number, label:String, onEnter:Function, drawn:Boolean = true):Sprite
      {
         w = Math.max(10, w);
         h = Math.max(10, h);
         if (drawn)
         {
            var look:Shape = new Shape();
            look.graphics.lineStyle(3, 0x7FE0FF, 0.95);
            look.graphics.beginFill(0xFFFFFF, 0.18);
            look.graphics.drawRoundRect(0, 0, w, h, 12, 12);
            look.graphics.endFill();
            look.x = x;
            look.y = y;
            bg.addChild(look);
         }
         if (label)
         {
            var t:TextField = RUI.text(13, 0xFFFFFF, true);
            t.filters = [new GlowFilter(0x0B2440, 1, 3, 3, 6)];
            t.text = label;
            t.x = x + (w - t.width) / 2;
            t.y = y + Math.max(0, (h - t.height) / 2);
            fg.addChild(t);
         }
         // The hit area: invisible (SceneBase makes it so), walked to when clicked.
         var area:Sprite = new Sprite();
         area.name = "modDoor_" + (label || bg.numChildren);
         area.graphics.beginFill(0xFFFFFF);
         area.graphics.drawRect(0, 0, w, h);
         area.graphics.endFill();
         area.x = x;
         area.y = y;
         bg.addChild(area);
         addEntranceAction(area, function():void
         {
            if (onEnter == null) return;
            try { onEnter(); } catch (e:Error) { RLog.error("mod door", e); }
         });
         if (label) try { TipsManager.getInstance().addTips(area, label); } catch (e2:Error) {}
         return area;
      }

      public function npc(def:Object):IModNpc
      {
         return person(def, false);
      }

      public function foe(def:Object):IModNpc
      {
         return person(def, true);
      }

      private function person(def:Object, foe:Boolean):IModNpc
      {
         if (def == null) return null;
         var view:DisplayObject = lookOf(def.look);
         var p:ModPerson = new ModPerson(this, def, view, foe, run);
         people.push(p);
         return p;
      }

      /** A look: a DisplayObject, a Class, or a race (the mod's 亚比: its figure; the game's: dressed as it). */
      private static function lookOf(look:*):DisplayObject
      {
         if (look is DisplayObject || look is Class) return display(look);
         var race:int = int(look);
         if (race <= 0) race = 1;
         if (RDef.has("mmo.revival.modwalk" + race))
         {
            var d:DisplayObject = RDef.make("mmo.revival.modwalk" + race) as DisplayObject;
            if (d != null)
            {
               var holder:Sprite = new Sprite();
               var b:Object = d.getBounds(d);
               var k:Number = Math.min(1, 110 / Math.max(1, b.height));
               d.scaleX = d.scaleY = k;
               d.x = -(b.left + b.width / 2) * k;
               d.y = -b.bottom * k;
               holder.addChild(d);
               return holder;
            }
         }
         var pet:ScenePetAvatar = new ScenePetAvatar(race, null);
         pet.mouseEnabled = pet.mouseChildren = false;
         return pet;
      }

      /** Called by ModPerson: put it among the players and make it clickable (walked up to first). */
      internal function place(p:ModPerson):void
      {
         playerLayer.addChild(p);
         ClickAndHitHelper.instance.registerTarget(p, true, 90);
         p.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, function(ev:ClickAndHitEvent):void { p.clicked(); });
      }

      internal function unplace(p:ModPerson):void
      {
         try { ClickAndHitHelper.instance.remove(p); } catch (e:Error) {}
         if (p.parent != null) p.parent.removeChild(p);
         var i:int = people.indexOf(p);
         if (i >= 0) people.splice(i, 1);
      }

      internal function labelLayer():Sprite
      {
         return fg;
      }

      public function say(d:DisplayObject, text:String, seconds:Number = 3):void
      {
         if (d == null || text == null) return;
         var bubble:Sprite = Bubble.make(text);
         var at:Point = fg.globalToLocal(d.localToGlobal(new Point(0, d.getBounds(d).top)));
         bubble.x = at.x;
         bubble.y = at.y - 6;
         fg.addChild(bubble);
         TweenLite.delayedCall(Math.max(0.5, seconds), function():void { if (bubble.parent) bubble.parent.removeChild(bubble); });
      }

      public function get player():Point
      {
         var me:Object = PlayerManager.getInstance().myPlayer;
         return me ? new Point(me.x, me.y) : new Point(0, 0);
      }

      public function walkTo(x:Number, y:Number, then:Function = null):void
      {
         var me:Object = PlayerManager.getInstance().myPlayer;
         if (me == null) return;
         try { me.walkTo(x, y); } catch (e:Error) { RLog.error("mod walkTo", e); }
         if (then == null) return;
         var self:SandboxRoom = this;
         var tries:int = 0;
         var check:Function = function(ev:Event):void
         {
            var moving:Boolean = false;
            try { moving = me.isMoving(); } catch (e2:Error) {}
            if (moving && ++tries < 25 * 30) return;
            self.removeEventListener(Event.ENTER_FRAME, check);
            if (self.stage == null) return;
            try { then(); } catch (e3:Error) { RLog.error("mod walkTo then", e3); }
         };
         addEventListener(Event.ENTER_FRAME, check);
      }

      public function onLeave(f:Function):void
      {
         if (f != null) leaveFns.push(f);
      }
   }
}
