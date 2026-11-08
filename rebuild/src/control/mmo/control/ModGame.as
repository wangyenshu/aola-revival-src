package mmo.control
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.media.Sound;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import flash.utils.setTimeout;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RDef;
   import mmo.revival.RJson;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModRoom;

   /**
    * REVIVAL (not of 2013). One loaded mod, and the game as that mod sees it
    * (IModGame, docs/MODDING.md): its rooms, conversations, films, fights, 亚比,
    * gifts, saved data and music. ModRun keeps the mods loaded and which one's
    * room is shown.
    */
   public class ModGame implements IModGame
   {
      private var run:ModRun;
      internal var mod:IMod;
      /** {id, name, author, version, description, yabi}. */
      internal var info:Object;
      /** The Loader holding the mod (kept, so its domain stays). */
      internal var holder:Loader;
      /** 亚比 numbers this mod has defined. */
      internal var races:Array = [];
      private var rooms:Object = {};
      private var roomOrder:Array = [];
      internal var roomDef:Object;
      internal var roomName:String;
      private var _room:IModRoom;
      private var data:Object = {};
      private var dataSaver:Timer;
      /** The music music() set for the room shown (null: the room's own). */
      private var musicSet:* = null;
      /** A class of the mod -> its Sound (made once). */
      private var sounds:Dictionary = new Dictionary();
      /** after() asked for before a room was shown: [{seconds, f}]. */
      private var afters:Array = [];
      private var gone:Boolean;
      /** A room's build function is running (after() then counts from now: the room is shown). */
      private var building:Boolean;
      /** playerLook: how the player is shown in this mod's rooms (null: as the player is). */
      public var lookOfPlayer:* = null;
      /** playerLook's name: shown under the player in this mod's rooms (null: the player's own). */
      public var nameOfPlayer:String = null;
      /** The party's def as sent (for its words), while it is out. */
      private var partyDef:Object;

      public function ModGame(run:ModRun, mod:IMod, info:Object, holder:Loader)
      {
         this.run = run;
         this.mod = mod;
         this.info = info;
         this.holder = holder;
      }

      // ---------------------------------------------------------------- for ModRun

      /** Start it: its saved data first, then IMod.start. */
      internal function start():void
      {
         var self:ModGame = this;
         run.ask(this, {op: "data", mod: info.id}, function(p:Object):void
         {
            data = {};
            try { if (p.data) data = RJson.decode(String(p.data)) || {}; } catch (e:Error) { data = {}; }
            musicSet = null;
            // Started again: its start() listens anew.
            teamHandlers = {};
            try { mod.start(self); }
            catch (err:Error)
            {
               RLog.error("mod start " + info.id, err);
               NewDialog.showMessage("模组出错了：" + err.message);
            }
         });
      }

      /** Forget it: its pictures, timers and sounds (ModRun.unload). */
      internal function dispose():void
      {
         saveNow();
         gone = true;
         teamHandlers = {};
         for each (var race:int in races)
         {
            RDef.forget("mmo.pet.peticon" + race + "_");
            RDef.forget("mmo.petfight.pet" + race + "_");
            RDef.forget("mmo.revival.modwalk" + race);
         }
         races = [];
         rooms = {};
         roomDef = null;
         roomName = null;
         afters = [];
         sounds = new Dictionary();
         if (holder != null) try { holder.unloadAndStop(); } catch (e:Error) {}
         holder = null;
         mod = null;
      }

      /** The room's music as set: music() or the room's def (a Sound, a class, a path or ""). */
      internal function musicAsSet():*
      {
         if (roomDef == null) return "";
         return musicSet != null ? musicSet : roomDef.music;
      }

      internal function soundOf(m:*):Sound
      {
         if (m is Sound) return m as Sound;
         if (!(m is Class)) return null;
         if (sounds[m] === undefined)
         {
            var made:Sound = null;
            try { made = new m() as Sound; } catch (e:Error) { RLog.error("mod music", e); }
            sounds[m] = made;
         }
         return sounds[m] as Sound;
      }

      /** The 沙盒 room is shown with a room of this mod: its build function (SandboxRoom). */
      public function attach(r:IModRoom):void
      {
         run.readyOnce();
         _room = r;
         // after() asked for before a room was shown: counted from now.
         var waitingAfters:Array = afters;
         afters = [];
         for each (var a:Object in waitingAfters) startAfter(a.seconds, a.f, r);
         if (roomDef == null || !(roomDef.build is Function)) return;
         building = true;
         try { roomDef.build(r); }
         catch (err:Error)
         {
            RLog.error("mod room " + roomName, err);
            NewDialog.showMessage("模组的房间出错了：" + err.message);
         }
         building = false;
      }

      public function detach(r:IModRoom):void
      {
         if (_room == r) _room = null;
      }

      /** No room of it is shown any more (another mod's is, or the 沙盒 is left). */
      internal function leftRooms():void
      {
         roomDef = null;
         roomName = null;
         musicSet = null;
         _room = null;
      }

      // ---------------------------------------------------------------- IModGame

      public function get apiVersion():int
      {
         return ModRun.API_VERSION;
      }

      /** The name the player is shown by (as #username# in conversations). */
      public function get playerName():String
      {
         try
         {
            var me:Object = PlayerManager.getInstance().myPlayer;
            if (me != null && me.hasOwnProperty("nickName") && me.nickName) return String(me.nickName);
         }
         catch (e:Error) {}
         return SocketClient.instance.myUserName;
      }

      public function room(id:String, def:Object):void
      {
         if (id == null || def == null || gone) return;
         if (rooms[id] == null) roomOrder.push(id);
         rooms[id] = def;
      }

      public function enter(roomId:String, spawn:String = null):void
      {
         if (gone) return;
         // Following the team into a room of this mod (ModRun.followInto): that room, not the start's.
         var f:Object = run.follow;
         if (f != null && f.game == this && rooms[f.room] != null)
         {
            run.follow = null;
            roomId = f.room;
            spawn = null;
         }
         var def:Object = rooms[roomId];
         if (def == null)
         {
            RLog.log("mod: no room " + roomId);
            return;
         }
         run.enterRoom(this, roomId, def, spawn);
      }

      /** ModRun.enterRoom: this room is the one to show. */
      internal function willShow(roomId:String, def:Object):void
      {
         roomDef = def;
         roomName = roomId;
         musicSet = null;
      }

      internal function roomFor(roomId:String):Object
      {
         return rooms[roomId];
      }

      /** The ids of the rooms it has defined, in the order defined. */
      internal function roomIds():Array
      {
         return roomOrder.concat();
      }

      /**
       * What the mod says it uses, for tools/mod-sdk/export.mjs: the answer of its optional
       * public uses() ({races, npcs, items, files}), or null.
       */
      internal function uses():Object
      {
         var m:Object = mod;
         if (m == null || gone) return null;
         try
         {
            if ("uses" in m && m.uses is Function) return m.uses();
         }
         catch (e:Error) { RLog.error("mod uses " + info.id, e); }
         return null;
      }

      public function leave():void
      {
         run.leaveMods();
      }

      public function get currentRoom():IModRoom
      {
         return _room;
      }

      public function talk(speaker:Object, pages:Array, done:Function = null):void
      {
         if (pages == null || pages.length == 0)
         {
            if (done != null) done();
            return;
         }
         var n:int = run.newTalk(this, done);
         var fns:Array = [];
         var xml:XML = <config/>;
         for (var i:int = 0; i < pages.length; i++)
         {
            var p:Object = pages[i];
            var text:String = p is String ? String(p) : String(p.text || "");
            var ctx:XML = <context/>;
            ctx.@str = text || " ";
            var choices:Array = p is String ? null : p.choices as Array;
            for each (var c:Array in choices || [])
            {
               if (c == null || c.length == 0) continue;
               var ch:XML = <choice/>;
               ch.@str = String(c[0]);
               ch.@action = "revival_mod:" + n + ":" + fns.length;
               fns.push(c.length > 1 ? c[1] : null);
               ctx.appendChild(ch);
            }
            if (i == pages.length - 1 && (choices == null || choices.length == 0)) ctx.@action = "revival_mod:" + n + ":done";
            xml.appendChild(ctx);
         }
         run.talkChoices(n, fns);
         var who:String = speaker && speaker.name ? String(speaker.name) : "";
         var show:Function = function(pic:DisplayObject, npcId:int):void
         {
            try
            {
               var panel:Object = getDefinitionByName("mmo.tasknpc.NpcTalkPanel");
               panel.showAs(xml, who, pic, npcId);
            }
            catch (err:Error) { RLog.error("mod talk", err); }
         };
         // "pet:<race>": the 亚比's large picture (loaded first: the panel sizes it as it opens).
         var race:int = speaker ? petOf(speaker.picture) : 0;
         if (race > 0)
         {
            var cls:String = "mmo.pet.peticon" + race + "_L";
            var shown:Boolean = false;
            var go:Function = function(... a):void
            {
               if (shown) return;
               shown = true;
               var d:DisplayObject = null;
               try { if (RDef.has(cls)) d = RDef.make(cls) as DisplayObject; } catch (e1:Error) {}
               // Drawn as large as the panel's NPC pictures (it only ever makes pictures smaller).
               if (d != null)
               {
                  var b:Rectangle = d.getBounds(d);
                  var k:Number = Math.min(2.5, 140 / Math.max(1, b.height), 128 / Math.max(1, b.width));
                  d.scaleX = d.scaleY = k;
                  var holder:Sprite = new Sprite();
                  holder.addChild(d);
                  d = holder;
               }
               show(d, 0);
            };
            if (RDef.has(cls)) go();
            else
            {
               try { ResScheduler.getResource("peticon/peticon" + race, go, cls, function(e:* = null):void { go(); }); }
               catch (e2:Error) { go(); }
            }
            return;
         }
         var npcId:int = speaker ? npcOf(speaker.picture) : 0;
         show(npcId > 0 ? null : picture(speaker ? speaker.picture : null), npcId);
      }

      /** "pet:<race>" (a 亚比's picture): its race, else 0. */
      public static function petOf(p:*):int
      {
         if (!(p is String)) return 0;
         var m:Array = /^pet:(\d+)/.exec(String(p));
         return m ? int(m[1]) : 0;
      }

      /** "npc:<id>" (an NPC of the game): its id, else 0. */
      public static function npcOf(p:*):int
      {
         if (!(p is String)) return 0;
         var m:Array = /^npc:(\d+)/.exec(String(p));
         return m ? int(m[1]) : 0;
      }

      /** A DisplayObject from a DisplayObject or a Class (or null). */
      public static function picture(p:*):DisplayObject
      {
         // One already shown (an NPC's view) stays where it is: a picture of it is used.
         if (p is DisplayObject && DisplayObject(p).parent != null) return snapshot(DisplayObject(p));
         if (p is DisplayObject) return DisplayObject(p);
         if (p is Class)
         {
            try { return new p() as DisplayObject; } catch (e:Error) { RLog.error("mod picture", e); }
         }
         return null;
      }

      private static function snapshot(d:DisplayObject):DisplayObject
      {
         try
         {
            var b:Rectangle = d.getBounds(d);
            if (b.width < 1 || b.height < 1) return null;
            var k:Number = Math.min(1, 400 / Math.max(b.width, b.height));
            var bd:BitmapData = new BitmapData(Math.ceil(b.width * k), Math.ceil(b.height * k), true, 0);
            bd.draw(d, new Matrix(k, 0, 0, k, -b.left * k, -b.top * k), null, null, null, true);
            var bm:Bitmap = new Bitmap(bd, "auto", true);
            bm.x = b.left;
            bm.y = b.top;
            bm.scaleX = bm.scaleY = 1 / k;
            var s:Sprite = new Sprite();
            s.addChild(bm);
            return s;
         }
         catch (e:Error) { RLog.error("mod picture", e); }
         return null;
      }

      public function film(clip:DisplayObject, done:Function = null, seconds:Number = 0):void
      {
         if (clip == null)
         {
            if (done != null) done();
            return;
         }
         var layer:Sprite = new Sprite();
         layer.name = "modFilm";
         layer.graphics.beginFill(0x000000, 0.85);
         layer.graphics.drawRect(0, 0, 960, 560);
         layer.graphics.endFill();
         layer.addChild(clip);
         var mc:MovieClip = clip as MovieClip;
         var frames:Boolean = mc != null && mc.totalFrames > 1;
         var ended:Boolean = false;
         var started:Boolean = false;
         var frame:Function = function(e:Event):void
         {
            if (mc.currentFrame > 1) started = true;
            if (started && mc.currentFrame >= mc.totalFrames) end();
         };
         var end:Function = function(... a):void
         {
            if (ended) return;
            ended = true;
            clip.removeEventListener(Event.ENTER_FRAME, frame);
            clip.removeEventListener(Event.COMPLETE, end);
            if (mc != null) mc.stop();
            if (layer.parent) layer.parent.removeChild(layer);
            if (done != null)
            {
               try { done(); } catch (err:Error) { RLog.error("mod film", err); }
            }
         };
         if (frames) clip.addEventListener(Event.ENTER_FRAME, frame);
         if ("movieClipData" in clip)
         {
            // A whole embedded SWF (mx.core.MovieClipLoaderAsset): its COMPLETE says it has loaded;
            // its own timeline, once there, is watched instead.
            clip.addEventListener(Event.COMPLETE, function(e:Event):void
            {
               var ldr:Loader = DisplayObjectContainer(clip).numChildren > 0 ? DisplayObjectContainer(clip).getChildAt(0) as Loader : null;
               var inner:MovieClip = ldr != null ? ldr.content as MovieClip : null;
               if (inner == null || inner.totalFrames <= 1 || ended) return;
               mc = inner;
               frames = true;
               clip.addEventListener(Event.ENTER_FRAME, frame);
               inner.gotoAndPlay(1);
            });
         }
         else clip.addEventListener(Event.COMPLETE, end);
         if (seconds > 0) setTimeout(end, seconds * 1000);
         var skip:Sprite = RUI.button("跳过", end, 64, 26, 0x6CC0F5, 0x2E86D6, "modFilmSkip");
         skip.x = 960 - 80;
         skip.y = 10;
         layer.addChild(skip);
         layer.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         LayerManager.getBaseTop().addChild(layer);
         if (frames) mc.gotoAndPlay(1);
      }

      public function fight(team:Array, done:Function = null, heal:Boolean = true, together:Boolean = false):void
      {
         if (team == null || team.length == 0 || SandboxRun.fighting)
         {
            RLog.log("mod: fight refused (" + (SandboxRun.fighting ? "a fight is on" : "no team") + ")");
            return;
         }
         SandboxRun.fight({name: info ? info.name : "", heal: heal, together: together, enemies: team.slice(0, 10)}, function(win:Boolean, at:int, refused:Boolean = false):void
         {
            if (done != null)
            {
               try { done(win && !refused); } catch (err:Error) { RLog.error("mod fight", err); }
            }
         });
      }

      public function species(def:Object, done:Function = null):void
      {
         var race:int = def ? int(def.id) : 0;
         var refuse:Function = function(why:String):void
         {
            RLog.log("mod " + info.id + ": 亚比 " + race + " refused: " + why);
            if (done != null) done(false);
         };
         if (gone) return;
         if (race < ModRun.RACE_MIN || race > ModRun.RACE_MAX) { refuse("its id is " + ModRun.RACE_MIN + "–" + ModRun.RACE_MAX); return; }
         // Another mod loaded has this number: its pictures stay.
         var other:ModGame = run.ownerOf(race);
         if (other != null && other != this) { refuse("模组「" + other.info.name + "」已经用了这个编号"); return; }
         // Its pictures, under the names the game's modules look for.
         var icon:Class = def.icon as Class;
         var front:Class = def.fight as Class;
         RDef.define("mmo.pet.peticon" + race + "_L", icon);
         RDef.define("mmo.pet.peticon" + race + "_S", icon);
         RDef.define("mmo.pet.peticon" + race + "_F", icon);
         RDef.define("mmo.petfight.pet" + race + "_1", front);
         RDef.define("mmo.petfight.pet" + race + "_2", def.back as Class);
         RDef.define("mmo.revival.modwalk" + race, (def.walk as Class) || icon);
         if (races.indexOf(race) < 0) races.push(race);
         var attr:Array = def.attr is Array ? def.attr : [def.attr, def.attr];
         var sent:Object = {id: race, name: String(def.name || ""), attr: [int(attr[0]), int(attr.length > 1 ? attr[1] : attr[0])],
            stats: def.stats, skills: def.skills, exp: String(def.exp || "2")};
         run.ask(this, {op: "species", mod: info.id, def: RJson.encode(sent)}, function(p:Object):void
         {
            if (p.res != 1) RLog.log("mod: 亚比 " + race + " refused: " + p.msg);
            else
            {
               // The panels that read the 亚比 tables (PMService, rebuilt pet/pmservice) find it too,
               // as the server keeps it.
               var kept:Object = sent;
               try { if (p.def) kept = RJson.decode(String(p.def)) || sent; } catch (e1:Error) {}
               try
               {
                  var pm:Object = ServiceContainer.getService("PMService");
                  if (pm != null && pm.hasOwnProperty("addPM")) pm.addPM(race, kept.name, kept.attr[0], kept.attr[1], kept.stats, learnOf(kept.skills), kept.exp);
               }
               catch (err:Error) { RLog.error("mod PMService", err); }
               // 亚比 of it put aside at login are back: the bag shows them.
               if (int(p.back) > 0) try { PetClient.instance.viewAllPM(); } catch (e2:Error) {}
            }
            if (done != null) done(p.res == 1);
         });
      }

      /** A mod's skills as [[level, skill], …] (it may give plain skill ids: learnt at level 1). */
      private static function learnOf(skills:*):Array
      {
         var out:Array = [];
         for each (var s:* in skills as Array || []) out.push(s is Array ? [int(s[0]), int(s[1])] : [1, int(s)]);
         return out;
      }

      public function givePet(race:int, level:int = 1, done:Function = null):void
      {
         if (gone) return;
         run.ask(this, {op: "give", mod: info.id, race: race, level: level}, function(p:Object):void
         {
            if (p.res == 1)
            {
               try { PetClient.instance.viewAllPM(); } catch (e:Error) {}
            }
            else if (p.msg) RLog.log("mod: give " + race + ": " + p.msg);
            if (done != null) done(p.res == 1);
         });
      }

      public function getData(key:String):*
      {
         return data.hasOwnProperty(key) ? data[key] : undefined;
      }

      public function setData(key:String, value:*):void
      {
         if (gone) return;
         if (value === undefined) delete data[key];
         else data[key] = value;
         // Saved a moment later (one request for the changes of half a second).
         if (dataSaver == null)
         {
            dataSaver = new Timer(500, 1);
            dataSaver.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { saveNow(); });
         }
         if (!dataSaver.running) dataSaver.start();
      }

      /** Send the mod's data now if a save is waiting. */
      internal function saveNow():void
      {
         if (dataSaver == null || !dataSaver.running) return;
         dataSaver.stop();
         var id:String = info.id;
         run.ask(this, {op: "save", mod: id, data: RJson.encode(data)}, function(p:Object):void
         {
            if (p.res != 1) RLog.log("mod " + id + ": its data was not saved (" + (p.msg || "?") + "; at most 64 KB)");
         }, true);
      }

      public function message(text:String):void
      {
         NewDialog.showMessage(String(text));
      }

      public function music(music:*):void
      {
         musicSet = music == null ? "" : music;
         // Played when one of its rooms is shown (it may be called before, from start()).
         if (run.shown != this) return;
         var inf:Object = SceneManager.getInstance().loadedSceneInfo;
         if (inf == null || String(inf.sceneName) != ModRun.ROOM) return;
         try
         {
            var sm:Object = getDefinitionByName("mmo.sceneinit.SceneMusic");
            if (sm != null && sm.hasOwnProperty("instance") && sm.instance != null) sm.instance.playSceneMusic(ModRun.ROOM);
         }
         catch (e:Error) {}
      }

      public function after(seconds:Number, f:Function):void
      {
         if (f == null || gone) return;
         // Asked for before a room of it is shown (in start(), a door's handler): counted once it is.
         if (_room == null || (SceneManager.getInstance().isLoading && !building))
         {
            afters.push({seconds: seconds, f: f});
            return;
         }
         startAfter(seconds, f, _room);
      }

      private function startAfter(seconds:Number, f:Function, r:IModRoom):void
      {
         setTimeout(function():void
         {
            if (_room != r || gone) return;
            try { f(); } catch (err:Error) { RLog.error("mod after", err); }
         }, Math.max(0, seconds) * 1000);
      }

      // ---------------------------------------------------------------- 组队 (API 3)

      /** Team events this mod listens to: event -> [function(from:String, data:*)]. */
      private var teamHandlers:Object = {};

      /** The team's members (the leader first), or [] when one plays alone. */
      public function get team():Array
      {
         var t:Object = Social.team;
         if (t == null || !(t.members is Array) || t.members.length < 2) return [];
         var out:Array = [String(t.leader)];
         for each (var m:String in t.members) if (m != t.leader) out.push(m);
         return out;
      }

      /** The team's leader, or "" when one plays alone. */
      public function get teamLeader():String
      {
         var t:Array = team;
         return t.length > 0 ? String(t[0]) : "";
      }

      /** Whether this player leads the team (or plays alone). */
      public function get isLeader():Boolean
      {
         var l:String = teamLeader;
         return l == "" || l == SocketClient.instance.myUserName;
      }

      /** The other players in this room (in a team, the members who are here). */
      public function get playersHere():Array
      {
         var out:Array = [];
         var me:String = SocketClient.instance.myUserName;
         try { for (var n:String in PlayerManager.getInstance().playerList) if (n != me) out.push(n); } catch (e:Error) {}
         return out.sort();
      }

      /**
       * Tell the other members of the team who run this mod (the same id and version) that
       * something happened: their onTeam(event) functions get (this player's name, data).
       * data: JSON-like, at most 4 KB as JSON. Alone, nobody hears it.
       */
      public function sendTeam(event:String, data:* = null):void
      {
         if (gone || !event || team.length == 0) return;
         var text:String = data === undefined ? "null" : RJson.encode(data);
         if (text.length > 4096)
         {
            RLog.log("mod " + info.id + ": sendTeam " + event + " too big (" + text.length + " characters), not sent");
            return;
         }
         SocketClient.instance.sendXtMessage("TeamExtension", "revival_team_mod", {mod: info.id, ver: String(info.version), event: String(event).substr(0, 64), data: text});
      }

      /** f(from:String, data:*) when another member sends event (sendTeam). Several may listen. */
      public function onTeam(event:String, f:Function):void
      {
         if (gone || !event || f == null) return;
         (teamHandlers[event] ||= []).push(f);
      }

      /** ModRun: a member's sendTeam to this mod. */
      internal function teamEvent(from:String, event:String, text:String):void
      {
         var fns:Array = teamHandlers[event] as Array;
         if (fns == null || gone) return;
         var data:* = null;
         try { data = RJson.decode(text); } catch (e:Error) { data = null; }
         for each (var f:Function in fns.concat())
         {
            try { f(from, data); } catch (err:Error) { RLog.error("mod " + info.id + " onTeam " + event, err); }
         }
      }

      // ---------------------------------------------------------------- API 4

      public function party(def:Object, done:Function = null):void
      {
         if (gone || def == null)
         {
            RLog.log("mod: party refused: " + (gone ? "the mod was removed" : "no def"));
            if (done != null) done(null);
            return;
         }
         var self:ModGame = this;
         var sent:Object = {pets: def.pets, items: def.items, noHeal: def.noHeal ? String(def.noHeal) : "", keepText: def.keepText ? String(def.keepText) : "", fresh: def.fresh === true, vip: def.vip === true};
         run.ask(this, {op: "party", mod: info.id, def: RJson.encode(sent)}, function(p:Object):void
         {
            if (p.res != 1)
            {
               // The server's reason (a shared server that lets no mod bring its own 亚比 …) is the player's to see.
               if (p.msg)
               {
                  RLog.log("mod: party refused: " + p.msg);
                  NewDialog.showMessage(String(p.msg));
               }
               if (done != null) done(null);
               return;
            }
            partyDef = sent;
            run.partyOut(self, sent.noHeal);
            // def.vip: a 蓝宝石 while it is out (the HELLO's 远程亚比仓库 …).
            if (p.vip != null) ToolboxPanel.setMember(p.vip == true);
            try { PetClient.instance.viewAllPM(); } catch (e:Error) {}
            if (done != null) done({party: true, pets: p.pets, items: p.items});
         });
      }

      public function endParty(done:Function = null):void
      {
         if (run.partyGame == this) run.endParty();
         if (done != null) setTimeout(done, 0);
      }

      /** ModRun.endParty: no party of this mod is out any more. */
      internal function partyEnded():void
      {
         partyDef = null;
      }

      public function partyState(done:Function):void
      {
         if (gone || done == null) return;
         run.ask(this, {op: "state", mod: info.id}, function(p:Object):void
         {
            done({party: Boolean(p.party), pets: p.pets || [], items: p.items || {}});
         });
      }

      public function giveItem(id:int, n:int = 1, done:Function = null, shown:Boolean = true):void
      {
         if (gone) return;
         run.ask(this, {op: "item", mod: info.id, id: id, n: n}, function(p:Object):void
         {
            if (p.res != 1 && p.msg) RLog.log("mod: item " + id + ": " + p.msg);
            // What was got, in the game's own window (the one of a boss's 亚比蛋: "n 个 …").
            if (p.res == 1 && n > 0 && shown)
            {
               try
               {
                  var panel:IMaterialGetPanel = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
                  if (panel != null) panel.showPanel(2, id, n);
               }
               catch (e:Error) { RLog.error("mod item window", e); }
            }
            if (done != null) done(p.res == 1 ? int(p.count) : -1);
         });
      }

      public function gameArt(file:String, className:String, done:Function):void
      {
         if (done == null || !file || !className || gone) return;
         var give:Function = function(d:* = null):void
         {
            var shown:DisplayObject = null;
            try
            {
               if (ApplicationDomain.currentDomain.hasDefinition(className))
                  shown = new (getDefinitionByName(className) as Class)() as DisplayObject;
            }
            catch (e:Error) { RLog.error("mod game art " + className, e); }
            if (gone) return;
            try { done(shown); } catch (e2:Error) { RLog.error("mod game art", e2); }
         };
         if (ApplicationDomain.currentDomain.hasDefinition(className)) { give(); return; }
         try { ResScheduler.getResource(file, give, className); }
         catch (e3:Error) { RLog.error("mod game art " + file, e3); done(null); }
      }

      public function playerLook(look:*, name:String = null):void
      {
         lookOfPlayer = look;
         nameOfPlayer = name;
         // The room shown puts it on at once (SandboxRoom keeps it on).
         if (_room != null && "lookChanged" in Object(_room)) try { Object(_room).lookChanged(); } catch (e:Error) {}
      }

      public function log(... parts):void
      {
         RLog.log("mod " + (info ? info.id : "?") + ": " + parts.join(" "));
      }
   }
}
