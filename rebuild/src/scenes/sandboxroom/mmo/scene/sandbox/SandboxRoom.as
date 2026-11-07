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
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.utils.tips.TipsManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.ScenePetAvatar;
   import mmo.interfaces.pet.data.PetClothesMap;
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
    * a mod loaded (mmo.control.ModRun, docs/MODDING.md). Built, it asks the
    * mods' run for the room to show and its definition (background, walk mask, size, spawns)
    * and draws it; shown, it hands itself (IModRoom) to the room's build
    * function, which puts the NPCs, opponents, doors and pictures. Rooms are
    * 560 high and 960 to 2880 wide, scrolled as the wide rooms of the game.
    *
    * It asks for the run by name, so that this file needs nothing of the
    * control module to be built.
    *
    * API 4: a room on a scene of the game (def.scene): the scene is built anew
    * from its document (loaded by ModRun before the room is shown); its
    * background, foreground and topground are drawn in the room's layers, the
    * pieces of its overlap among the players, its obstruction is the room's
    * walls; nothing of it answers the mouse and its own code (onJoinRoom) does
    * not run. NPCs of the game ("npc:<id>") and the player's look
    * (IModGame.playerLook).
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
      /** A room on a scene of the game: the scene, its obstruction, and its layers as they were. */
      private var sceneArt:Object;
      private var sceneObs:DisplayObject;
      private var sceneParts:Array = [];
      /** The player's look put on (IModGame.playerLook), what it was made of, and the avatar hidden. */
      private var myLook:DisplayObject;
      private var myLookOf:* = undefined;
      private var myNameOf:String;
      private var myLabel:TextField;
      private var hiddenAvatar:DisplayObject;
      private var modRun:Object;
      private var freeTries:int;

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
            modRun = run;
            shown = run ? run.roomToShow() : null;
            // The mod whose room this is (several may be loaded): it gets the room, the fights, the talks.
            if (shown != null && shown.game != null) run = shown.game;
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
         if (def.scene is String && drawScene(String(def.scene), def)) return;
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

      /** A room on a scene of the game; false when the scene is not there (the room is drawn as usual). */
      private function drawScene(name:String, def:Object):Boolean
      {
         var D:Class = null;
         try { D = modRun ? modRun.sceneDoc(name) as Class : null; } catch (e:Error) {}
         if (D == null) return false;
         var scene:Object;
         try { scene = Object(new D()).scene; } catch (e2:Error) { RLog.error("mod scene " + name, e2); return false; }
         if (scene == null) return false;
         sceneArt = scene;
         var layer:Function = function(n:String):DisplayObjectContainer
         {
            try { return scene.getChildByName(n) as DisplayObjectContainer; } catch (e3:Error) {}
            return null;
         };
         var quiet:Function = function(d:DisplayObject):void
         {
            if (d is Sprite) Sprite(d).mouseEnabled = false;
            if (d is DisplayObjectContainer) DisplayObjectContainer(d).mouseChildren = false;
            if (d is Sprite) Sprite(d).buttonMode = false;
         };
         var back:DisplayObjectContainer = layer("background");
         if (back != null) { quiet(back); bg.addChildAt(back, 0); sceneParts.push(back); }
         var front:DisplayObjectContainer = layer("foreground");
         if (front != null)
         {
            quiet(front);
            fg.addChild(front);
            sceneParts.push(front);
            // Its doors' areas (et1 …), drawn for the editor: unseen, as the scene's own doors are.
            for (var ei:int = 0; ei < front.numChildren; ei++) if (/^et\d*$/.test(front.getChildAt(ei).name)) front.getChildAt(ei).alpha = 0;
         }
         var top:DisplayObjectContainer = layer("topground");
         if (top != null) { quiet(top); fg.addChild(top); sceneParts.push(top); }
         var over:DisplayObjectContainer = layer("overlap");
         if (over != null)
         {
            sceneParts.push(over);
            while (over.numChildren > 0)
            {
               var piece:DisplayObject = over.getChildAt(0);
               var at:Point = new Point(piece.x + over.x, piece.y + over.y);
               quiet(piece);
               playerLayer.addChild(piece);
               piece.x = at.x;
               piece.y = at.y;
               sceneParts.push(piece);
            }
         }
         var obs:DisplayObject = layer("obstruction");
         if (obs != null)
         {
            quiet(obs);
            var mine:DisplayObjectContainer = obStruction as DisplayObjectContainer;
            if (mine != null) { mine.addChild(obs); sceneObs = obs; }
         }
         var r:Object = back != null ? back.getBounds(back.parent) : null;
         roomW = Math.max(960, Math.min(2880, r ? Math.floor(r.right) : 960));
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
         var own:Point = null;
         try { own = Object(scene).revival::defaultPoint as Point; } catch (e4:Error) {}
         addInitLocation("start", first || own || new Point(Math.min(480, roomW / 2), 470));
         return true;
      }

      /**
       * A room on a scene's art: a player put on its walls (a spawn the scene does not leave free)
       * is moved to the nearest free spot, once the room is shown.
       */
      private function freeSpot(e:Event):void
      {
         if (++freeTries < 3) return;
         removeEventListener(Event.ENTER_FRAME, freeSpot);
         var me:Object = PlayerManager.getInstance().myPlayer;
         if (me == null || !isBlocked(me.x, me.y)) return;
         var p:Point = freeNear(me.x, me.y, 500);
         if (p != null) try { me.jumpTo(int(p.x), int(p.y)); } catch (e2:Error) {}
      }

      /** The nearest point off the walls within radius of x, y, or null. */
      private function freeNear(x:Number, y:Number, radius:int):Point
      {
         for (var r:int = 10; r <= radius; r += 10)
         {
            for (var a:int = 0; a < 24; a++)
            {
               var px:Number = x + r * Math.cos(a * Math.PI / 12);
               var py:Number = y + r * Math.sin(a * Math.PI / 12);
               if (!isBlocked(px, py)) return new Point(px, py);
            }
         }
         return null;
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
         if (sceneObs != null) return super.isBlocked(x, y);
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
         if (sceneObs != null) addEventListener(Event.ENTER_FRAME, freeSpot);
         if (run != null) run.attach(this);
      }

      override protected function onLeaveRoom():void
      {
         removeEventListener(Event.ENTER_FRAME, keepUi);
         removeEventListener(Event.ENTER_FRAME, freeSpot);
         dropLook();
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
         // A mod played as a game of its own (ModRun.standalone): there is nowhere to leave to.
         try { if (getDefinitionByName("mmo.control.ModRun").standalone) leave.visible = false; } catch (e:Error) {}
         screen = new Sprite();
         screen.name = "modScreen";
         ui.addChildAt(screen, 0);
      }

      /** The room's buttons stay put while a wide room scrolls under them. */
      private function keepUi(e:Event):void
      {
         if (ui != null) ui.x = -x;
         keepLook();
      }

      // ---------------------------------------------------------------- the player's look

      /** ModGame.playerLook: the look changed. */
      public function lookChanged():void
      {
         keepLook();
      }

      /** The player shown as the mod says (each frame: the game may draw the avatar anew). */
      private function keepLook():void
      {
         var want:* = null;
         var wantName:String = null;
         try
         {
            want = run != null && "lookOfPlayer" in run ? run.lookOfPlayer : null;
            wantName = run != null && "nameOfPlayer" in run ? run.nameOfPlayer : null;
         }
         catch (e:Error) {}
         var me:Object = PlayerManager.getInstance().myPlayer;
         if (want !== myLookOf || wantName != myNameOf || (myLook != null && me != null && myLook.parent != me))
         {
            dropLook();
            myLookOf = want;
            myNameOf = wantName;
            if (want != null && me is DisplayObjectContainer)
            {
               myLook = lookOf(want);
               if (myLook != null)
               {
                  myLook.name = "modPlayerLook";
                  DisplayObjectContainer(me).addChildAt(myLook, Math.min(1, DisplayObjectContainer(me).numChildren));
               }
            }
            // The mod's name for the player, under the player, the player's own hidden.
            if (wantName && me is DisplayObjectContainer)
            {
               myLabel = RUI.text(12, 0xFFFFFF, true);
               myLabel.filters = [new GlowFilter(0x0B2440, 1, 3, 3, 6)];
               myLabel.text = wantName;
               myLabel.x = -myLabel.width / 2;
               myLabel.y = 6;
               myLabel.mouseEnabled = false;
               DisplayObjectContainer(me).addChild(myLabel);
               try { me.setNickNameVisible(false); } catch (e4:Error) {}
            }
         }
         if (myLook == null || me == null) return;
         var av:DisplayObject = null;
         try { av = me.avatarSprite as DisplayObject; } catch (e2:Error) {}
         if (av != hiddenAvatar && hiddenAvatar != null) hiddenAvatar.visible = true;
         hiddenAvatar = av;
         if (av != null) av.visible = false;
         // Facing as the player walks.
         try { myLook.scaleX = Math.abs(myLook.scaleX) * (String(me.directionCode).indexOf("r") >= 0 ? -1 : 1); } catch (e3:Error) {}
      }

      private function dropLook():void
      {
         if (myLook != null && myLook.parent != null) myLook.parent.removeChild(myLook);
         myLook = null;
         if (myLabel != null)
         {
            if (myLabel.parent != null) myLabel.parent.removeChild(myLabel);
            myLabel = null;
            try { Object(PlayerManager.getInstance().myPlayer).setNickNameVisible(true); } catch (e:Error) {}
         }
         myNameOf = null;
         if (hiddenAvatar != null) hiddenAvatar.visible = true;
         hiddenAvatar = null;
         myLookOf = undefined;
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
         // On a scene's art: one put on its walls stands on the nearest floor (it could not be walked up to).
         if (sceneObs != null && stage != null && isBlocked(p.x, p.y))
         {
            var near:Point = freeNear(p.x, p.y, 160);
            if (near != null) { p.x = near.x; p.y = near.y; }
         }
         return p;
      }

      /** "npc:<id>[:view]": an NPC of the game, its art (tasknpc/npc<id>, mmo.tasknpc.Npc<id>_<view>) when loaded. */
      private static function npcLook(look:String):DisplayObject
      {
         var m:Array = /^npc:(\d+)(?::(\d+))?/.exec(look);
         if (m == null) return null;
         var id:int = int(m[1]);
         var cls:String = "mmo.tasknpc.Npc" + id + "_" + (m[2] ? int(m[2]) : 1);
         var holder:Sprite = new Sprite();
         holder.mouseChildren = false;
         var put:Function = function(d:*):void
         {
            if (holder.numChildren > 0 || !ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            try { holder.addChild(new (getDefinitionByName(cls) as Class)() as DisplayObject); } catch (e:Error) { RLog.error("mod npc look " + look, e); }
         };
         try { ResScheduler.getResource("tasknpc/npc" + id, put, cls); } catch (e2:Error) { RLog.error("mod npc look " + look, e2); }
         return holder;
      }

      /** A look: a DisplayObject, a Class, "npc:<id>", or a race (the mod's 亚比: its figure; the game's: dressed as it). */
      private static function lookOf(look:*):DisplayObject
      {
         if (look is DisplayObject || look is Class) return display(look);
         if (look is String && String(look).indexOf("npc:") == 0) return npcLook(String(look));
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
         // A 亚比 of the game with no scene clothes: its picture (not the stand-in clothes).
         if (PetClothesMap.getClothesId(race % 10000) <= 0) return petPicture(race);
         var pet:ScenePetAvatar = new ScenePetAvatar(race, null);
         pet.mouseEnabled = pet.mouseChildren = false;
         return pet;
      }

      /** A 亚比's large picture (peticon<race>_L), at most 110 high, its feet at 0, 0. */
      private static function petPicture(race:int):DisplayObject
      {
         var holder:Sprite = new Sprite();
         holder.mouseChildren = false;
         var cls:String = "mmo.pet.peticon" + race + "_L";
         var put:Function = function(... a):void
         {
            if (holder.numChildren > 0 || !RDef.has(cls)) return;
            var d:DisplayObject = RDef.make(cls) as DisplayObject;
            if (d == null) return;
            var b:Object = d.getBounds(d);
            var k:Number = Math.min(1, 110 / Math.max(1, b.height));
            d.scaleX = d.scaleY = k;
            d.x = -(b.left + b.width / 2) * k;
            d.y = -b.bottom * k;
            holder.addChild(d);
         };
         if (RDef.has(cls)) put();
         else try { ResScheduler.getResource("peticon/peticon" + race, put, cls, function(e:* = null):void {}); } catch (e2:Error) {}
         return holder;
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

      public function blocked(x:Number, y:Number):Boolean
      {
         return isBlocked(x, y);
      }

      public function part(name:String):DisplayObject
      {
         if (name == null) return null;
         for each (var d:DisplayObject in sceneParts)
         {
            if (d.name == name) return d;
            var found:DisplayObject = find(d as DisplayObjectContainer, name, 3);
            if (found != null) return found;
         }
         return null;
      }

      private static function find(c:DisplayObjectContainer, name:String, depth:int):DisplayObject
      {
         if (c == null || depth <= 0) return null;
         var direct:DisplayObject = c.getChildByName(name);
         if (direct != null) return direct;
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var f:DisplayObject = find(c.getChildAt(i) as DisplayObjectContainer, name, depth - 1);
            if (f != null) return f;
         }
         return null;
      }
   }
}
