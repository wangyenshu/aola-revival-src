package mmo.scene.sandbox
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.filters.GlowFilter;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.common.utils.tips.TipsManager;
   import mmo.play.player.sceneplayer.ScenePetAvatar;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.play.scene.revival;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * A room of a 沙盒 关卡 pack (format version 2, docs/SANDBOX.md), drawn
    * from the pack's pictures: the background (its size: 560 high, 960 wide
    * or wider, scrolled like the wide rooms of the game), props behind or in
    * front of the players, an overlay over them (at 0, 0, scaled as the
    * background is), the walk mask (stretched over the room; black wall,
    * white or transparent floor), the doors (clicked: walked to, then gone
    * through) and the opponents (clicked: walked up to, then fought).
    *
    * The room asks mmo.control.SandboxRun (the control module) for what to
    * show and hands it the doors and opponents; by name, so that this file
    * needs nothing of the control module to be built.
    */
   public class SandboxRoom extends SceneBase
   {
      private static const H:int = 560;

      private var run:Class;
      private var cur:Object;
      private var roomW:int = 960;
      private var mask:BitmapData;
      private var maskSX:Number = 1;
      private var maskSY:Number = 1;

      private var bg:Sprite;
      private var fg:Sprite;
      private var ui:Sprite;
      private var doorViews:Array = [];
      private var foes:Array = [];

      public function SandboxRoom()
      {
         super(480, 470);
         // The layers SceneBase looks for, by name: obstruction (empty: the mask answers
         // isBlocked, but the path finder wants one), background, overlap (players), foreground.
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
            run = getDefinitionByName("mmo.control.SandboxRun") as Class;
            cur = run ? run["current"]() : null;
         }
         catch (e:Error) { RLog.error("sandbox room", e); }
         if (cur == null || cur.room == null)
         {
            drawEmpty();
            return;
         }
         try { draw(); } catch (e2:Error) { RLog.error("sandbox room " + cur.room.id, e2); }
      }

      // ---------------------------------------------------------------- pictures

      private function picture(id:*):BitmapData
      {
         if (id == null || cur.pictures == null) return null;
         return cur.pictures[String(id)] as BitmapData;
      }

      private function draw():void
      {
         var room:Object = cur.room;
         var b:BitmapData = picture(room.background);
         // The background's scale (1 for a picture 560 high and 960 to 2880 wide): the overlay
         // is scaled as it is.
         var kx:Number = 1, ky:Number = 1;
         if (b != null)
         {
            var s:Number = H / b.height;
            roomW = Math.max(960, Math.min(2880, Math.round(b.width * s)));
            kx = roomW / b.width;
            ky = s;
            var bm:Bitmap = new Bitmap(b, "auto", true);
            bm.width = roomW;
            bm.height = H;
            bg.addChild(bm);
         }
         else
         {
            bg.graphics.beginFill(0x2A3B4E);
            bg.graphics.drawRect(0, 0, 960, H);
            bg.graphics.endFill();
         }
         mask = picture(room.mask);
         if (mask != null)
         {
            maskSX = mask.width / roomW;
            maskSY = mask.height / H;
         }
         for each (var p:Object in room.props is Array ? room.props : [])
         {
            var pb:BitmapData = p ? picture(p.image) : null;
            if (pb == null || !(p.at is Array)) continue;
            var pm:Bitmap = new Bitmap(pb, "auto", true);
            pm.x = Number(p.at[0]);
            pm.y = Number(p.at[1]);
            (p.front ? fg : bg).addChild(pm);
         }
         var ob:BitmapData = picture(room.overlay);
         if (ob != null)
         {
            var om:Bitmap = new Bitmap(ob, "auto", true);
            om.scaleX = kx;
            om.scaleY = ky;
            fg.addChild(om);
         }
         var spawns:Object = room.spawns || {};
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
         // The whole width is there from the start: SceneBase measures the room by its background.
         if (bg.width < roomW)
         {
            bg.graphics.beginFill(0, 0);
            bg.graphics.drawRect(0, 0, roomW, H);
            bg.graphics.endFill();
         }
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

      /** Off the room, or on the mask's wall (alpha 128 or more and dark). */
      override public function isBlocked(x:Number, y:Number):Boolean
      {
         if (x < 0 || y < 0 || x >= roomW || y >= H) return true;
         if (mask == null) return false;
         var c:uint = mask.getPixel32(int(x * maskSX), int(y * maskSY));
         if ((c >>> 24) < 128) return false;
         var lum:Number = 0.299 * ((c >> 16) & 0xFF) + 0.587 * ((c >> 8) & 0xFF) + 0.114 * (c & 0xFF);
         return lum < 128;
      }

      // ---------------------------------------------------------------- the room's things

      override protected function onJoinRoom():void
      {
         addUi();
         if (cur == null || cur.room == null)
         {
            var t:TextField = RUI.text(16, 0xFFFFFF, true, 600);
            t.text = "沙盒里还没有开始的关卡。请打开控制栏上的「沙盒」，导入关卡包后点「开始」。";
            t.x = 180;
            t.y = 250;
            ui.addChild(t);
            return;
         }
         var room:Object = cur.room;
         for each (var d:Object in room.doors is Array ? room.doors : [])
         {
            if (d != null && d.rect is Array && d.rect.length >= 4) addDoor(d);
         }
         for each (var e:Object in room.enemies is Array ? room.enemies : [])
         {
            if (e == null || !(e.at is Array) || !(e.team is Array) || e.team.length == 0) continue;
            if (run["isBeaten"](String(e.id))) continue;
            addFoe(e);
         }
         refreshDoors();
         addEventListener(Event.ENTER_FRAME, keepUi);
      }

      override protected function onLeaveRoom():void
      {
         removeEventListener(Event.ENTER_FRAME, keepUi);
         for each (var f:Object in foes)
         {
            try { ClickAndHitHelper.instance.remove(f.view); } catch (e:Error) {}
         }
         foes = [];
         doorViews = [];
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
         var lv:Object = cur ? cur.level : null;
         var rm:Object = cur ? cur.room : null;
         title.text = lv ? String(lv.name || lv.id) + (rm ? " · " + String(rm.name || rm.id) : "") : "沙盒";
         if (title.width > 210) title.width = 210;
         title.x = 20;
         title.y = 18;
         ui.addChild(title);
         var leave:Sprite = RUI.button("离开沙盒", function():void
         {
            if (run != null) run["exit"]();
         }, 88, 28, 0x6CC0F5, 0x2E86D6, "sandboxLeave");
         leave.x = 244;
         leave.y = 14;
         ui.addChild(leave);
      }

      /** The room's buttons stay put while a wide room scrolls under them. */
      private function keepUi(e:Event):void
      {
         if (ui != null) ui.x = -x;
      }

      private function addDoor(d:Object):void
      {
         var rx:Number = Number(d.rect[0]), ry:Number = Number(d.rect[1]);
         var rw:Number = Math.max(10, Number(d.rect[2])), rh:Number = Math.max(10, Number(d.rect[3]));
         var look:Shape = new Shape();
         look.x = rx;
         look.y = ry;
         bg.addChild(look);
         var label:TextField = RUI.text(13, 0xFFFFFF, true);
         label.filters = [new GlowFilter(0x0B2440, 1, 3, 3, 6)];
         label.text = doorLabel(d);
         label.x = rx + (rw - label.width) / 2;
         label.y = ry + Math.max(0, (rh - label.height) / 2);
         fg.addChild(label);
         // The hit area: invisible (SceneBase makes it so), walked to when clicked.
         var area:Sprite = new Sprite();
         area.name = "sandboxDoor_" + doorViews.length;
         area.graphics.beginFill(0xFFFFFF);
         area.graphics.drawRect(0, 0, rw, rh);
         area.graphics.endFill();
         area.x = rx;
         area.y = ry;
         bg.addChild(area);
         addEntranceAction(area, function():void
         {
            if (run != null) run["door"](d);
         });
         try { TipsManager.getInstance().addTips(area, label.text); } catch (e:Error) {}
         doorViews.push({door: d, look: look, label: label, w: rw, h: rh, text: label.text});
      }

      private function doorLabel(d:Object):String
      {
         if (d.label) return String(d.label);
         var to:String = String(d.to || "");
         if (to == "#finish") return "通关";
         if (to == "#exit") return "离开";
         var lv:Object = cur.level;
         var roomId:String = to;
         var slash:int = to.indexOf("/");
         var prefix:String = "";
         if (slash >= 0)
         {
            // A room of another 关卡: named with its 关卡.
            lv = null;
            for each (var l:Object in cur.pack && cur.pack.levels is Array ? cur.pack.levels : []) if (l != null && String(l.id) == to.substring(0, slash)) lv = l;
            roomId = to.substr(slash + 1);
            prefix = lv ? String(lv.name || lv.id) + " · " : to.substring(0, slash) + " · ";
         }
         var target:String = roomId;
         for each (var r:Object in lv && lv.rooms is Array ? lv.rooms : []) if (r != null && String(r.id) == roomId) target = String(r.name || r.id);
         var label:String = prefix + target;
         return "→ " + (label.length > 16 ? label.substr(0, 15) + "…" : label);
      }

      /** Doors that open once the room is cleared look shut until then. */
      private function refreshDoors():void
      {
         var cleared:Boolean = run != null && run["cleared"]();
         for each (var v:Object in doorViews)
         {
            var shut:Boolean = v.door.open == "cleared" && !cleared;
            var g:Shape = v.look;
            g.graphics.clear();
            g.graphics.lineStyle(3, shut ? 0x8C96A0 : (v.door.to == "#finish" ? 0xFFD24A : 0x7FE0FF), 0.95);
            g.graphics.beginFill(shut ? 0x30363C : 0xFFFFFF, shut ? 0.45 : 0.18);
            g.graphics.drawRoundRect(0, 0, v.w, v.h, 12, 12);
            g.graphics.endFill();
            TextField(v.label).text = v.text + (shut ? "（未开启）" : "");
            TextField(v.label).x = v.look.x + (v.w - TextField(v.label).width) / 2;
         }
      }

      private function addFoe(e:Object):void
      {
         var race:int = int(e.team[0].race);
         var at:Point = new Point(Number(e.at[0]), Number(e.at[1]));
         var view:ScenePetAvatar = new ScenePetAvatar(race, null);
         view.name = "sandboxFoe_" + String(e.id);
         view.x = at.x;
         view.y = at.y;
         if (e.boss)
         {
            view.scaleX = view.scaleY = 1.5;
         }
         playerLayer.addChild(view);
         var tag:TextField = RUI.text(12, e.boss ? 0xFFE27A : 0xFFFFFF, true);
         tag.filters = [new GlowFilter(0x40140A, 1, 3, 3, 6)];
         var n:int = e.team.length;
         tag.text = (e.name ? String(e.name) : (e.boss ? "首领" : "对手")) + (n > 1 ? "（" + n + "只亚比）" : "") + " Lv" + int(e.team[0].level || 1);
         tag.x = at.x - tag.width / 2;
         tag.y = at.y + 6;
         fg.addChild(tag);
         try { TipsManager.getInstance().addTips(view, "点击挑战"); } catch (e1:Error) {}
         ClickAndHitHelper.instance.registerTarget(view, true, 90);
         var foe:Object = {enemy: e, view: view, tag: tag};
         view.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT, function(ev:ClickAndHitEvent):void { fight(foe); });
         foes.push(foe);
      }

      private function fight(foe:Object):void
      {
         if (run == null || run["fighting"]) return;
         run["fightEnemy"](foe.enemy, function(win:Boolean):void
         {
            if (!win) return;
            try { ClickAndHitHelper.instance.remove(foe.view); } catch (e:Error) {}
            var v:DisplayObject = foe.view as DisplayObject;
            if (v != null && v.parent) v.parent.removeChild(v);
            if (foe.tag && foe.tag.parent) foe.tag.parent.removeChild(foe.tag);
            var i:int = foes.indexOf(foe);
            if (i >= 0) foes.splice(i, 1);
            refreshDoors();
         });
      }
   }
}
