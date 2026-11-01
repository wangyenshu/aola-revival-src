package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
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
   import mmo.play.scene.SceneManager;
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
      public static const API_VERSION:int = 1;
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
      private var musicPath:String;
      private var talkSeq:int;
      private var talks:Object = {};
      private var races:Array = [];
      private var waiting:Object = {};
      private var listening:Boolean;

      public static function get instance():ModRun
      {
         if (_instance == null) _instance = new ModRun();
         return _instance;
      }

      /** The music of the room shown (SandboxRun.music, SceneMusic). */
      public static function get musicNow():String
      {
         var r:ModRun = _instance;
         if (r == null || r.roomDef == null) return "";
         var m:String = r.musicPath != null ? r.musicPath : String(r.roomDef.music || "");
         return /^music\/[A-Za-z0-9_\/.-]+\.mp3$/.test(m) && m.indexOf("..") < 0 ? m : "";
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
         var answered:Boolean = false;
         var answer:Function = function(err:String, inf:Object):void
         {
            if (answered) return;
            answered = true;
            done(err, inf);
         };
         ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
         {
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

      /** Forget the mod loaded (its rooms, its 亚比's pictures). */
      public function unload():void
      {
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
         holder = null;
         data = {};
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
            var inf:Object = SceneManager.getInstance().loadedSceneInfo;
            if (inf == null || String(inf.sceneName) != ROOM) back = inf ? String(inf.sceneName) : "starland";
            musicPath = null;
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

      public function get playerName():String
      {
         return SocketClient.instance.myUserName;
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
         if (sm.isLoading) return;
         var inf:Object = sm.loadedSceneInfo;
         if (inf == null || String(inf.sceneName) != ROOM) back = inf ? String(inf.sceneName) : "starland";
         roomDef = def;
         roomName = roomId;
         musicPath = null;
         sm.loadScene(ROOM, spawn || "start", true);
      }

      public function leave():void
      {
         roomDef = null;
         roomName = null;
         musicPath = null;
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
         if (p is DisplayObject) return DisplayObject(p);
         if (p is Class)
         {
            try { return new p() as DisplayObject; } catch (e:Error) { RLog.error("mod picture", e); }
         }
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
         clip.addEventListener(Event.COMPLETE, end);
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
         if (team == null || team.length == 0 || SandboxRun.fighting) return;
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
            // The panels that read the 亚比 tables (PMService, rebuilt pet/pmservice) find it too.
            else try
            {
               var pm:Object = ServiceContainer.getService("PMService");
               if (pm != null && pm.hasOwnProperty("addPM")) pm.addPM(race, sent.name, sent.attr[0], sent.attr[1], sent.stats, learnOf(def.skills), sent.exp);
            }
            catch (err:Error) { RLog.error("mod PMService", err); }
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
         // Saved a moment later (one request for many changes).
         if (dataSaver == null)
         {
            dataSaver = new Timer(500, 1);
            dataSaver.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
            {
               if (info != null) ask({op: "save", mod: info.id, data: RJson.encode(data)});
            });
         }
         dataSaver.reset();
         dataSaver.start();
      }

      public function message(text:String):void
      {
         NewDialog.showMessage(String(text));
      }

      public function music(path:String):void
      {
         musicPath = path == null ? "" : path;
         try
         {
            var sm:Object = getDefinitionByName("mmo.sceneinit.SceneMusic");
            if (sm != null && sm.hasOwnProperty("instance") && sm.instance != null) sm.instance.playSceneMusic(ROOM);
         }
         catch (e:Error) {}
      }

      public function after(seconds:Number, f:Function):void
      {
         var r:IModRoom = _room;
         setTimeout(function():void
         {
            if (_room != r || f == null) return;
            try { f(); } catch (err:Error) { RLog.error("mod after", err); }
         }, Math.max(0, seconds) * 1000);
      }

      public function log(... parts):void
      {
         RLog.log("mod " + (info ? info.id : "?") + ": " + parts.join(" "));
      }
   }
}
