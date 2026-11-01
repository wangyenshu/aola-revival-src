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
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import flash.utils.setTimeout;
   import mmo.common.dialog.NewDialog;
   import mmo.interfaces.ServiceContainer;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.layer.LayerManager;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RDef;
   import mmo.revival.RJson;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModRoom;

   /**
    * REVIVAL (not of 2013). The 沙盒's mods: SWFs written in ActionScript 3
    * against the API of mmo.revival.mod (docs/MODDING.md), loaded from a file
    * or from the site's mods/ folder, one at a time.
    *
    * A mod's SWF is loaded with Loader.loadBytes into an application domain of
    * its own under the game's: its classes see the game's, the game sees the
    * mod's only through IMod and what it hands over (its 亚比's pictures are
    * given to the game's lookups by name, RDef). A mod runs with the game's
    * rights: only mods one trusts should be loaded.
    *
    * Its rooms are shown by the 沙盒 room (scene/sandboxroom), which asks here
    * for the room's definition and hands back itself (IModRoom); its fights
    * are SandboxRun's; its 亚比, data and gifts go through
    * SundriesExtension.revival_mod (server mods.ts).
    */
   public class ModRun implements IModGame
   {
      public static const ROOM:String = "sandboxroom";
      public static const API_VERSION:int = 2;
      /** The largest mod file. */
      public static const MAX_BYTES:int = 16000000;
      /** Mods' own 亚比 numbers. */
      public static const RACE_MIN:int = 900001;
      public static const RACE_MAX:int = 999999;

      private static var _instance:ModRun;

      private var mod:IMod;
      private var info:Object;
      /** The Loader holding the mod (kept, so its domain stays). */
      private var holder:Loader;
      private var rooms:Object = {};
      private var roomDef:Object;
      private var roomName:String;
      private var _room:IModRoom;
      private var back:String;
      private var data:Object = {};
      private var dataSaver:Timer;
      /** The music music() set for the room shown (null: the room's own). */
      private var musicSet:* = null;
      /** A class of the mod -> its Sound (made once). */
      private var sounds:Dictionary = new Dictionary();
      private var talkSeq:int;
      private var loadSeq:int;
      /** enter() waiting for a scene being loaded: {room, spawn}, or null. */
      private var pendingEnter:Object;
      /** after() asked for before a room was shown: [{seconds, f}]. */
      private var afters:Array = [];
      private var talks:Object = {};
      private var races:Array = [];
      private var waiting:Object = {};
      private var listening:Boolean;

      public static function get instance():ModRun
      {
         if (_instance == null) _instance = new ModRun();
         return _instance;
      }

      /** The room's music as set: music() or the room's def (a Sound, a class, a path or ""). */
      private function musicAsSet():*
      {
         if (roomDef == null) return "";
         return musicSet != null ? musicSet : roomDef.music;
      }

      /** The music file of the game the room shown plays (SandboxRun.music, SceneMusic), or "". */
      public static function get musicNow():String
      {
         var r:ModRun = _instance;
         var m:* = r != null ? r.musicAsSet() : "";
         if (!(m is String)) return "";
         return /^music\/[A-Za-z0-9_\/.-]+\.mp3$/.test(m) && String(m).indexOf("..") < 0 ? m : "";
      }

      /** The mod's own music for the room shown (SceneMusic), or null. */
      public static function get musicSoundNow():Sound
      {
         var r:ModRun = _instance;
         var m:* = r != null ? r.musicAsSet() : null;
         if (m is Sound) return m as Sound;
         if (!(m is Class)) return null;
         if (r.sounds[m] === undefined)
         {
            var made:Sound = null;
            try { made = new m() as Sound; } catch (e:Error) { RLog.error("mod music", e); }
            r.sounds[m] = made;
         }
         return r.sounds[m] as Sound;
      }

      // ---------------------------------------------------------------- loading

      /** The mod loaded: its info, or null. */
      public function get loaded():Object
      {
         return info;
      }

      /**
       * Load a mod from its SWF's bytes; done(error:String, info:Object): error null
       * when it loaded. The mod before it is forgotten.
       */
      public function load(bytes:ByteArray, done:Function):void
      {
         if (bytes == null || bytes.length < 8) { done("这不是模组文件。", null); return; }
         if (bytes.length > MAX_BYTES) { done("文件太大了（模组最多16 MB）。", null); return; }
         var sig:String = String.fromCharCode(bytes[0], bytes[1], bytes[2]);
         if (sig != "FWS" && sig != "CWS" && sig != "ZWS") { done("这不是模组文件（模组是 SWF 文件）。", null); return; }
         unload();
         var ld:Loader = new Loader();
         var seq:int = ++loadSeq;
         var answered:Boolean = false;
         var answer:Function = function(err:String, inf:Object):void
         {
            if (answered) return;
            answered = true;
            if (err != null) try { ld.unloadAndStop(); } catch (e0:Error) {}
            done(err, inf);
         };
         ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            // A load given up (timed out) or followed by another is not the mod loaded.
            if (answered || seq != loadSeq) { try { ld.unloadAndStop(); } catch (e1:Error) {} return; }
            var m:IMod = ld.content as IMod;
            if (m == null) { answer("这个 SWF 不是模组（它的主类没有实现 mmo.revival.mod.IMod）。", null); return; }
            var inf:Object = null;
            try { inf = m.info; } catch (err:Error) { RLog.error("mod info", err); }
            var id:String = inf ? String(inf.id || "") : "";
            if (!/^[A-Za-z0-9_-]{1,32}$/.test(id)) { answer("模组的 info.id 只能用英文字母、数字、_ 和 -（1–32个）。", null); return; }
            holder = ld;
            mod = m;
            info = {id: id, name: String(inf.name || id).substr(0, 40), author: String(inf.author || "").substr(0, 40),
               version: String(inf.version || "").substr(0, 20), description: String(inf.description || "").substr(0, 300)};
            RLog.log("mod: loaded " + id);
            answer(null, info);
         });
         ld.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { answer("模组读取失败。", null); });
         try
         {
            ld.loadBytes(bytes, new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain)));
         }
         catch (err:Error)
         {
            RLog.error("mod load", err);
            answer("模组读取失败：" + err.message, null);
         }
         setTimeout(function():void { answer("模组读取超时。", null); }, 20000);
      }

      /** Forget the mod loaded (its rooms, its 亚比's pictures, its timers and sounds). */
      public function unload():void
      {
         saveNow();
         pendingEnter = null;
         if (roomDef != null && SceneManager.getInstance().loadedSceneInfo != null && SceneManager.getInstance().loadedSceneInfo.sceneName == ROOM) leave();
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
         mod = null;
         info = null;
         if (holder != null) try { holder.unloadAndStop(); } catch (e:Error) {}
         holder = null;
         data = {};
         sounds = new Dictionary();
         talks = {};
         afters = [];
         // Replies still to come for the mod before are dropped.
         waiting = {};
      }

      /** Start the mod loaded: its saved data first, then IMod.start. */
      public function startMod():void
      {
         if (mod == null) return;
         var self:ModRun = this;
         listen();
         ask({op: "data", mod: info.id}, function(p:Object):void
         {
            data = {};
            try { if (p.data) data = RJson.decode(String(p.data)) || {}; } catch (e:Error) { data = {}; }
            if (mod == null) return;
            noteBack();
            musicSet = null;
            try { mod.start(self); }
            catch (err:Error)
            {
               RLog.error("mod start " + info.id, err);
               NewDialog.showMessage("模组出错了：" + err.message);
            }
         });
      }

      // ---------------------------------------------------------------- the server

      private function listen():void
      {
         if (listening) return;
         listening = true;
         SocketClient.instance.addEventListener("revival_mod", function(e:SocketClientEvent):void
         {
            var p:Object = e.params;
            var k:String = String(p.op) + ":" + String(p.tag || "");
            var f:Function = waiting[k] as Function;
            delete waiting[k];
            if (f != null)
            {
               try { f(p); } catch (err:Error) { RLog.error("mod reply " + k, err); }
            }
         });
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, onTalkAction);
      }

      private var tagSeq:int;

      private function ask(params:Object, then:Function = null):void
      {
         params.tag = String(++tagSeq);
         if (then != null) waiting[params.op + ":" + params.tag] = then;
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_mod", params);
      }

      // ---------------------------------------------------------------- IModGame

      public function get apiVersion():int
      {
         return API_VERSION;
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

      /** Where 离开沙盒 goes back to: the scene the player was in (outdoors, from a home or a 副本). */
      private function noteBack():void
      {
         var sm:SceneManager = SceneManager.getInstance();
         var inf:Object = sm.loadedSceneInfo;
         if (inf != null && String(inf.sceneName) == ROOM) return;
         if (inf == null) back = "starland";
         else back = inf.inHouse || inf.isFB ? sm.lastOutdoorScene : String(inf.sceneName);
      }

      public function room(id:String, def:Object):void
      {
         if (id == null || def == null) return;
         rooms[id] = def;
      }

      public function enter(roomId:String, spawn:String = null):void
      {
         var def:Object = rooms[roomId];
         if (def == null)
         {
            RLog.log("mod: no room " + roomId);
            return;
         }
         var sm:SceneManager = SceneManager.getInstance();
         if (sm.isLoading)
         {
            // A scene is on its way (the room left when another mod was started there): enter
            // once it is shown. One such wait at a time; leave() and unload() drop it.
            var self:ModRun = this;
            var mine:Object = pendingEnter = {room: roomId, spawn: spawn};
            var later:Function = function(e:Event):void
            {
               sm.removeEventListener(SceneManagerEvent.SCENE_INITED, later);
               if (pendingEnter != mine) return;
               pendingEnter = null;
               if (rooms[roomId] === def) self.enter(roomId, spawn);
            };
            sm.addEventListener(SceneManagerEvent.SCENE_INITED, later);
            return;
         }
         pendingEnter = null;
         noteBack();
         roomDef = def;
         roomName = roomId;
         musicSet = null;
         sm.loadScene(ROOM, spawn || "start", true);
      }

      public function leave():void
      {
         pendingEnter = null;
         roomDef = null;
         roomName = null;
         musicSet = null;
         SandboxRun.reset();
         var to:String = back || "starland";
         back = null;
         SceneManager.getInstance().loadScene(to);
      }

      public function get currentRoom():IModRoom
      {
         return _room;
      }

      /** The room the 沙盒 room is to show: {id, def}, or null (SandboxRoom asks as it is built). */
      public function roomToShow():Object
      {
         return roomDef != null ? {id: roomName, def: roomDef, mod: info ? info.name : ""} : null;
      }

      /** The 沙盒 room is shown: its build function (SandboxRoom calls this from onJoinRoom). */
      public function attach(r:IModRoom):void
      {
         _room = r;
         // after() asked for before a room was shown: counted from now.
         var waitingAfters:Array = afters;
         afters = [];
         for each (var a:Object in waitingAfters) startAfter(a.seconds, a.f, r);
         if (roomDef == null || !(roomDef.build is Function)) return;
         try { roomDef.build(r); }
         catch (err:Error)
         {
            RLog.error("mod room " + roomName, err);
            NewDialog.showMessage("模组的房间出错了：" + err.message);
         }
      }

      public function detach(r:IModRoom):void
      {
         if (_room == r) _room = null;
      }

      public function talk(speaker:Object, pages:Array, done:Function = null):void
      {
         if (pages == null || pages.length == 0)
         {
            if (done != null) done();
            return;
         }
         var n:int = ++talkSeq;
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
         talks[n] = {fns: fns, done: done};
         var pic:DisplayObject = picture(speaker ? speaker.picture : null);
         try
         {
            var panel:Object = getDefinitionByName("mmo.tasknpc.NpcTalkPanel");
            panel.showAs(xml, speaker && speaker.name ? String(speaker.name) : "", pic);
         }
         catch (err:Error) { RLog.error("mod talk", err); }
      }

      private function onTalkAction(e:TaskEvent):void
      {
         var a:String = e.params ? String(e.params.action) : "";
         if (a.indexOf("revival_mod:") != 0) return;
         var parts:Array = a.split(":");
         var t:Object = talks[int(parts[1])];
         if (t == null) return;
         delete talks[int(parts[1])];
         var f:Function = parts[2] == "done" ? t.done as Function : t.fns[int(parts[2])] as Function;
         if (f == null) return;
         try { f(); } catch (err:Error) { RLog.error("mod talk choice", err); }
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

      public function fight(team:Array, done:Function = null, heal:Boolean = true):void
      {
         if (team == null || team.length == 0 || SandboxRun.fighting)
         {
            RLog.log("mod: fight refused (" + (SandboxRun.fighting ? "a fight is on" : "no team") + ")");
            return;
         }
         SandboxRun.fight({name: info ? info.name : "", heal: heal, enemies: team.slice(0, 10)}, function(win:Boolean, at:int, refused:Boolean = false):void
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
         if (race < RACE_MIN || race > RACE_MAX)
         {
            RLog.log("mod: a 亚比's id is " + RACE_MIN + "–" + RACE_MAX);
            if (done != null) done(false);
            return;
         }
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
         listen();
         ask({op: "species", mod: info ? info.id : "", def: RJson.encode(sent)}, function(p:Object):void
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
         listen();
         ask({op: "give", mod: info ? info.id : "", race: race, level: level}, function(p:Object):void
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
         if (info == null) return;
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

      /** Send the mod's data now if a save is waiting (with the mod's own id). */
      private function saveNow():void
      {
         if (dataSaver == null || !dataSaver.running) return;
         dataSaver.stop();
         if (info == null) return;
         var id:String = info.id;
         ask({op: "save", mod: id, data: RJson.encode(data)}, function(p:Object):void
         {
            if (p.res != 1) RLog.log("mod " + id + ": its data was not saved (" + (p.msg || "?") + "; at most 64 KB)");
         });
      }

      public function message(text:String):void
      {
         NewDialog.showMessage(String(text));
      }

      public function music(music:*):void
      {
         musicSet = music == null ? "" : music;
         // Played when the room is shown (it may be called before, from start()).
         var inf:Object = SceneManager.getInstance().loadedSceneInfo;
         if (inf == null || String(inf.sceneName) != ROOM) return;
         try
         {
            var sm:Object = getDefinitionByName("mmo.sceneinit.SceneMusic");
            if (sm != null && sm.hasOwnProperty("instance") && sm.instance != null) sm.instance.playSceneMusic(ROOM);
         }
         catch (e:Error) {}
      }

      public function after(seconds:Number, f:Function):void
      {
         if (f == null) return;
         // Asked for before a room is shown (in start(), a door's handler): counted once it is.
         if (_room == null || SceneManager.getInstance().isLoading)
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
            if (_room != r) return;
            try { f(); } catch (err:Error) { RLog.error("mod after", err); }
         }, Math.max(0, seconds) * 1000);
      }

      public function log(... parts):void
      {
         RLog.log("mod " + (info ? info.id : "?") + ": " + parts.join(" "));
      }
   }
}
