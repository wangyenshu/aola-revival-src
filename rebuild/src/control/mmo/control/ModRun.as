package mmo.control
{
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   import flash.utils.setTimeout;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModRoom;

   /**
    * REVIVAL (not of 2013). The 沙盒's mods: SWFs written in ActionScript 3
    * against the API of mmo.revival.mod (docs/MODDING.md), loaded from a file
    * or from the site's mods/ folder. Several can be loaded at once (ModGame,
    * one each); the rooms of one are shown at a time.
    *
    * A mod's SWF is loaded with Loader.loadBytes into an application domain of
    * its own under the game's: its classes see the game's, the game sees the
    * mod's only through IMod and what it hands over (its 亚比's pictures are
    * given to the game's lookups by name, RDef). Two mods conflict when they
    * use the same 亚比 number: a mod that lists its numbers in info.yabi is
    * refused when loaded if another loaded mod has one of them; else the
    * second definition is refused. A mod with the id of one loaded replaces
    * it (a new build). A mod runs with the game's rights: only mods one
    * trusts should be loaded.
    *
    * The rooms are shown by the 沙盒 room (scene/sandboxroom), which asks here
    * for the room to show and hands itself (IModRoom) to the mod that owns
    * it; the fights are SandboxRun's; 亚比, data and gifts go through
    * SundriesExtension.revival_mod (server mods.ts).
    */
   public class ModRun
   {
      public static const ROOM:String = "sandboxroom";
      public static const API_VERSION:int = 3;
      /** The largest mod file. */
      public static const MAX_BYTES:int = 16000000;
      /** Mods' own 亚比 numbers. */
      public static const RACE_MIN:int = 900001;
      public static const RACE_MAX:int = 999999;
      /** Mods loaded at once, at most. */
      public static const MAX_MODS:int = 8;

      private static var _instance:ModRun;

      /** The mods loaded, in the order they were loaded. */
      private var games:Array = [];
      /** The mod whose room is shown (or to be shown), or null. */
      internal var shown:ModGame;
      /** Where leaving the mods goes back to. */
      private var back:String;
      private var loadSeq:int;
      /** enter waiting for a scene being loaded: {game, room, spawn}, or null. */
      private var pendingEnter:Object;
      private var talkSeq:int;
      /** Conversations open: n -> {game, fns, done}. */
      private var talks:Object = {};
      private var tagSeq:int;
      /** Replies awaited: "op:tag" -> {game, f}. */
      private var waiting:Object = {};
      private var listening:Boolean;

      public static function get instance():ModRun
      {
         if (_instance == null) _instance = new ModRun();
         return _instance;
      }

      /** The music file of the game the room shown plays (SandboxRun.music, SceneMusic), or "". */
      public static function get musicNow():String
      {
         var g:ModGame = _instance != null ? _instance.shown : null;
         var m:* = g != null ? g.musicAsSet() : "";
         if (!(m is String)) return "";
         return /^music\/[A-Za-z0-9_\/.-]+\.mp3$/.test(m) && String(m).indexOf("..") < 0 ? m : "";
      }

      /** The mod's own music for the room shown (SceneMusic), or null. */
      public static function get musicSoundNow():Sound
      {
         var g:ModGame = _instance != null ? _instance.shown : null;
         return g != null ? g.soundOf(g.musicAsSet()) : null;
      }

      // ---------------------------------------------------------------- the mods loaded

      /** The mods loaded: [{id, name, author, version, description, yabi}], in the order loaded. */
      public function get mods():Array
      {
         var out:Array = [];
         for each (var g:ModGame in games) out.push(g.info);
         return out;
      }

      /** The mod last loaded (or whose room is shown): its info, or null. */
      public function get loaded():Object
      {
         if (shown != null) return shown.info;
         return games.length > 0 ? ModGame(games[games.length - 1]).info : null;
      }

      private function gameOf(id:String):ModGame
      {
         for each (var g:ModGame in games) if (g.info.id == id) return g;
         return null;
      }

      /** The mod loaded that has defined (or listed in info.yabi) 亚比 race, or null. */
      internal function ownerOf(race:int):ModGame
      {
         for each (var g:ModGame in games)
         {
            if (g.races.indexOf(race) >= 0) return g;
            if (g.info.yabi is Array && (g.info.yabi as Array).indexOf(race) >= 0) return g;
         }
         return null;
      }

      /**
       * Load a mod from its SWF's bytes; done(error:String, info:Object): error null
       * when it loaded. Mods loaded before stay, but one with the same id is
       * replaced, and one that conflicts refuses this one.
       */
      public function load(bytes:ByteArray, done:Function):void
      {
         if (bytes == null || bytes.length < 8) { done("这不是模组文件。", null); return; }
         if (bytes.length > MAX_BYTES) { done("文件太大了（模组最多16 MB）。", null); return; }
         var sig:String = String.fromCharCode(bytes[0], bytes[1], bytes[2]);
         if (sig != "FWS" && sig != "CWS" && sig != "ZWS") { done("这不是模组文件（模组是 SWF 文件）。", null); return; }
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
            // A load given up (timed out) is not loaded after all.
            if (answered) { try { ld.unloadAndStop(); } catch (e1:Error) {} return; }
            var m:IMod = ld.content as IMod;
            if (m == null) { answer("这个 SWF 不是模组（它的主类没有实现 mmo.revival.mod.IMod）。", null); return; }
            var inf:Object = null;
            try { inf = m.info; } catch (err:Error) { RLog.error("mod info", err); }
            var id:String = inf ? String(inf.id || "") : "";
            if (!/^[A-Za-z0-9_-]{1,32}$/.test(id)) { answer("模组的 info.id 只能用英文字母、数字、_ 和 -（1–32个）。", null); return; }
            var yabi:Array = [];
            for each (var r:* in inf.yabi as Array || []) if (int(r) >= RACE_MIN && int(r) <= RACE_MAX && yabi.indexOf(int(r)) < 0) yabi.push(int(r));
            var info:Object = {id: id, name: String(inf.name || id).substr(0, 40), author: String(inf.author || "").substr(0, 40),
               version: String(inf.version || "").substr(0, 20), description: String(inf.description || "").substr(0, 300), yabi: yabi};
            // The same mod (a new build) replaces the one loaded; another one must not clash.
            var same:ModGame = gameOf(id);
            for each (var race:int in yabi)
            {
               var other:ModGame = ownerOf(race);
               if (other != null && other != same)
               {
                  answer("这个模组和已载入的模组「" + other.info.name + "」冲突：它们都用了亚比编号 " + race + "。先移除那个模组。", null);
                  return;
               }
            }
            if (same == null && games.length >= MAX_MODS) { answer("最多同时载入 " + MAX_MODS + " 个模组：先移除一个。", null); return; }
            if (same != null) unload(id);
            games.push(new ModGame(self, m, info, ld));
            RLog.log("mod: loaded " + id);
            answer(null, info);
         });
         ld.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { answer("模组读取失败。", null); });
         var self:ModRun = this;
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

      /**
       * Forget a mod loaded (by id; null: all of them): its rooms, pictures,
       * timers, sounds, conversations and replies. Leaves its room if it is shown.
       */
      public function unload(id:String = null):void
      {
         for each (var g:ModGame in games.concat())
         {
            if (id != null && g.info.id != id) continue;
            if (g == shown)
            {
               pendingEnter = null;
               var inf:Object = SceneManager.getInstance().loadedSceneInfo;
               if (inf != null && String(inf.sceneName) == ROOM) leaveMods();
               else
               {
                  g.leftRooms();
                  shown = null;
               }
            }
            if (pendingEnter != null && pendingEnter.game == g) pendingEnter = null;
            for (var n:String in talks) if (talks[n].game == g) delete talks[n];
            g.dispose();
            // Its saves are sent (dispose); other replies to it are dropped.
            for (var k:String in waiting) if (waiting[k].game == g && !waiting[k].keep) delete waiting[k];
            games.splice(games.indexOf(g), 1);
            RLog.log("mod: removed " + g.info.id);
         }
      }

      /** Start a mod loaded (by id; null: the one last loaded). */
      public function startMod(id:String = null):void
      {
         var g:ModGame = id != null ? gameOf(id) : (games.length > 0 ? games[games.length - 1] : null);
         if (g == null) return;
         listen();
         noteBack();
         g.start();
      }

      // ---------------------------------------------------------------- the room shown

      /** Where leaving goes back to: the scene the player was in (outdoors, from a home or a 副本). */
      private function noteBack():void
      {
         var sm:SceneManager = SceneManager.getInstance();
         var inf:Object = sm.loadedSceneInfo;
         if (inf != null && String(inf.sceneName) == ROOM) return;
         if (inf == null) back = "starland";
         else back = inf.inHouse || inf.isFB ? sm.lastOutdoorScene : String(inf.sceneName);
      }

      /** ModGame.enter: show a room of the mod g. */
      internal function enterRoom(g:ModGame, roomId:String, def:Object, spawn:String):void
      {
         var sm:SceneManager = SceneManager.getInstance();
         if (sm.isLoading)
         {
            // A scene is on its way (the room left when a mod was removed there): enter once it is
            // shown. One such wait at a time; leaving and removing the mod drop it.
            var self:ModRun = this;
            var mine:Object = pendingEnter = {game: g, room: roomId, spawn: spawn};
            var later:Function = function(e:Event):void
            {
               sm.removeEventListener(SceneManagerEvent.SCENE_INITED, later);
               if (pendingEnter != mine) return;
               pendingEnter = null;
               if (games.indexOf(g) >= 0 && g.roomFor(roomId) === def) self.enterRoom(g, roomId, def, spawn);
            };
            sm.addEventListener(SceneManagerEvent.SCENE_INITED, later);
            return;
         }
         pendingEnter = null;
         noteBack();
         if (shown != null && shown != g) shown.leftRooms();
         shown = g;
         g.willShow(roomId, def);
         SceneManager.sandboxRoom = teamRoom(g, roomId);
         sm.loadScene(ROOM, spawn || "start", true);
      }

      /**
       * REVIVAL 组队 in a mod: in a team, a mod's room is one server room for the team (the
       * leader's name, the mod's id and version, the room's id), so its members see each other
       * there, and the leader going into it takes them along (Social: revival_team_go). Alone:
       * null (the room of one's own).
       */
      internal static function teamRoom(g:ModGame, roomId:String):String
      {
         var t:Object = Social.team;
         if (t == null || !(t.members is Array) || t.members.length < 2) return null;
         return TEAM_ROOM + [t.leader, g.info.id, g.info.version, roomId].map(function(s:*, i:int, a:Array):String { return encodeURIComponent(String(s)); }).join("|");
      }

      public static const TEAM_ROOM:String = "sandboxroom|";

      /** A team's mod room ("sandboxroom|leader|mod|version|room"): {leader, mod, version, room}, or null. */
      public static function parseTeamRoom(name:String):Object
      {
         if (name == null || name.indexOf(TEAM_ROOM) != 0) return null;
         var p:Array = name.substr(TEAM_ROOM.length).split("|");
         if (p.length != 4) return null;
         try { return {leader: decodeURIComponent(p[0]), mod: decodeURIComponent(p[1]), version: decodeURIComponent(p[2]), room: decodeURIComponent(p[3])}; }
         catch (e:Error) {}
         return null;
      }

      /** Where a team's mod room is followed to: the mod, once started, enters it (ModGame.enter). */
      internal var follow:Object;

      /**
       * Into a team's mod room (following the leader, 找他): only with the same mod, of the same
       * version, loaded; it is started first if it was not. False if it is not loaded.
       */
      public function followInto(room:String):Boolean
      {
         var r:Object = parseTeamRoom(room);
         if (r == null) return false;
         var g:ModGame = gameOf(r.mod);
         if (g == null || String(g.info.version) != r.version) return false;
         if (g.roomFor(r.room) != null)
         {
            follow = null;
            noteBack();
            g.enter(r.room);
            return true;
         }
         // Not started yet: its start() defines the rooms and enters one; this one instead.
         follow = {game: g, room: r.room};
         startMod(g.info.id);
         return true;
      }

      /** Leave the mods' rooms: back to where the 沙盒 was started. */
      internal function leaveMods():void
      {
         pendingEnter = null;
         follow = null;
         SceneManager.sandboxRoom = null;
         if (shown != null) shown.leftRooms();
         shown = null;
         SandboxRun.reset();
         var to:String = back || "starland";
         back = null;
         SceneManager.getInstance().loadScene(to);
      }

      /** The room of a mod shown (by the room the 沙盒 room is): IModRoom, or null. */
      public function get currentRoom():IModRoom
      {
         return shown != null ? shown.currentRoom : null;
      }

      /** The room the 沙盒 room is to show: {id, def, mod, game}, or null (SandboxRoom asks as it is built). */
      public function roomToShow():Object
      {
         if (shown == null || shown.roomDef == null) return null;
         return {id: shown.roomName, def: shown.roomDef, mod: shown.info.name, game: shown};
      }

      /** For a 沙盒 room that has no mod of its own: hands itself to the mod shown. */
      public function attach(r:IModRoom):void
      {
         if (shown != null) shown.attach(r);
      }

      public function detach(r:IModRoom):void
      {
         if (shown != null) shown.detach(r);
      }

      public function leave():void
      {
         leaveMods();
      }

      // ---------------------------------------------------------------- the server and conversations

      private function listen():void
      {
         if (listening) return;
         listening = true;
         SocketClient.instance.addEventListener("revival_mod", function(e:SocketClientEvent):void
         {
            var p:Object = e.params;
            var k:String = String(p.op) + ":" + String(p.tag || "");
            var w:Object = waiting[k];
            delete waiting[k];
            if (w != null && w.f != null)
            {
               try { w.f(p); } catch (err:Error) { RLog.error("mod reply " + k, err); }
            }
         });
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, onTalkAction);
         // A team member's mod told the team something (ModGame.sendTeam, server social.ts).
         SocketClient.instance.addEventListener("revival_team_mod", function(e:SocketClientEvent):void
         {
            var p:Object = e.params;
            var g:ModGame = gameOf(String(p.mod));
            if (g != null && String(g.info.version) == String(p.ver)) g.teamEvent(String(p.from), String(p.event), String(p.data));
         });
      }

      /** A request of mod g to the server; then(reply). keep: answered even if g is removed meanwhile. */
      internal function ask(g:ModGame, params:Object, then:Function = null, keep:Boolean = false):void
      {
         listen();
         params.tag = String(++tagSeq);
         if (then != null) waiting[params.op + ":" + params.tag] = {game: g, f: then, keep: keep};
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_mod", params);
      }

      internal function newTalk(g:ModGame, done:Function):int
      {
         listen();
         var n:int = ++talkSeq;
         talks[n] = {game: g, fns: [], done: done};
         return n;
      }

      internal function talkChoices(n:int, fns:Array):void
      {
         if (talks[n] != null) talks[n].fns = fns;
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
   }
}
