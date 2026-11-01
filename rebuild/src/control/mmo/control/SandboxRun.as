package mmo.control
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.TimerEvent;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RBase64;
   import mmo.revival.RJson;
   import mmo.revival.RLog;

   /**
    * The revival's 沙盒 at work (not of 2013): the fights of a 关卡 and the
    * rooms of a 关卡 pack (format version 2, docs/SANDBOX.md).
    *
    * Fights (both versions): a team of opponents fought one after another
    * through SundriesExtension.revival_sandbox (sandbox.ts), the next once
    * the battle screen has gone; a loss ends the team.
    *
    * Packs: the pictures are decoded once (data: URLs, Loader.loadBytes);
    * a 关卡 starts in its start room. The rooms are shown by the 沙盒 room
    * (scene/sandboxroom, mmo.scene.sandbox.SandboxRoom), which asks here for
    * the room, its pictures and what is beaten, and hands back its doors and
    * its opponents. Beaten opponents stay beaten for the run of the pack.
    */
   public class SandboxRun
   {
      public static const ROOM:String = "sandboxroom";

      // ---------------------------------------------------------------- fights

      /** The team being fought: {lv (JSON of a version-1 关卡), name, i, n, race, done}. */
      private static var run:Object;
      private static var watching:Boolean;

      /**
       * Fight `lv` (a version-1 关卡 object: {name, heal, enemies}) one opponent
       * after another; done(win, reached) once it ends (reached: the opponent
       * it ended at, from 0).
       */
      public static function fight(lv:Object, done:Function):void
      {
         watch();
         var n:int = lv && lv.enemies is Array ? lv.enemies.length : 0;
         if (n == 0) return;
         var o:Object = {format: "aola-revival-level", version: 1, name: String(lv.name || ""), heal: lv.heal !== false, enemies: lv.enemies};
         // between: no battle of the team is on (before the first, and from the end of one to
         // the start of the next): a FIGHT_END then is not ours (the battle screen may tell
         // its end more than once as it closes).
         run = {lv: RJson.encode(o), name: o.name, i: 0, n: n, race: 0, done: done, between: true};
         next();
      }

      public static function get fighting():Boolean
      {
         return run != null;
      }

      private static function watch():void
      {
         if (watching) return;
         watching = true;
         SocketClient.instance.addEventListener("revival_sandbox", function(e:SocketClientEvent):void
         {
            if (run == null) return;
            if (e.params.res != 1)
            {
               // Not a 关卡 (its reason), or a start refused (msg "": the battle's 2303 said why).
               var r:Object = run;
               run = null;
               if (e.params.msg) NewDialog.showMessage(String(e.params.msg));
               if (r.done is Function) r.done(false, r.i, true);
               return;
            }
            run.race = int(e.params.race);
            run.between = false;
         });
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onFightEnd);
      }

      private static function next():void
      {
         if (run == null) return;
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_sandbox", {lv: run.lv, i: run.i});
      }

      private static function onFightEnd(e:PetFightEvent):void
      {
         if (run == null || run.between || (e.raceId != 0 && int(run.race) != 0 && e.raceId != int(run.race))) return;
         var r:Object = run;
         r.between = true;
         if (!e.isWin || r.i + 1 >= r.n)
         {
            run = null;
            if (r.done is Function) r.done(e.isWin, r.i, false);
            return;
         }
         r.i++;
         r.race = 0;
         // The next opponent once the battle screen has gone.
         var t:Timer = new Timer(1500, 1);
         t.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void { if (run == r) next(); });
         t.start();
      }

      // ---------------------------------------------------------------- packs

      private static var pack:Object;
      private static var levelObj:Object;
      private static var roomObj:Object;
      private static var pictures:Object = {};
      private static var beaten:Object = {};
      private static var back:String;
      private static var decoding:Boolean;

      /** A pack (version 2) read from its file: the object, or the reason it is not one. */
      public static function check(o:Object):String
      {
         if (o == null || o.format != "aola-revival-level") return "这不是奥拉星的关卡文件";
         if (!(o.levels is Array) || o.levels.length == 0) return "关卡包里还没有关卡";
         for each (var l:Object in o.levels)
         {
            if (l == null || !(l.rooms is Array) || l.rooms.length == 0) return "关卡「" + (l ? l.name || l.id : "?") + "」里还没有房间";
            if (roomOf(l, String(l.start)) == null) return "关卡「" + (l.name || l.id) + "」的起点房间不存在";
            for each (var r:Object in l.rooms) if (r == null || !r.background || o.images == null || o.images[r.background] == null) return "房间「" + (r ? r.name || r.id : "?") + "」没有背景图片";
         }
         return null;
      }

      /** Start the 关卡 levelId of pack p (its pictures decoded first); said(text) tells how it goes. */
      public static function start(p:Object, levelId:String, said:Function = null):void
      {
         var why:String = check(p);
         if (why != null)
         {
            if (said != null) said(why);
            return;
         }
         var l:Object = levelOf(p, levelId);
         if (l == null) return;
         if (decoding) return;
         var info:* = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || String(info.sceneName) != ROOM) back = info ? String(info.sceneName) : "starland";
         if (pack != p)
         {
            pack = p;
            pictures = {};
            beaten = {};
         }
         var ids:Array = [];
         for (var id:String in p.images) if (pictures[id] == null) ids.push(id);
         if (ids.length == 0)
         {
            enterLevel(l, null);
            return;
         }
         decoding = true;
         if (said != null) said("正在读取图片（" + ids.length + "张）……");
         var left:int = ids.length;
         for each (var pid:String in ids)
         {
            decodePicture(pid, String(p.images[pid]), function():void
            {
               if (--left > 0) return;
               decoding = false;
               if (pack == p) enterLevel(l, null);
            });
         }
      }

      private static function decodePicture(id:String, url:String, then:Function):void
      {
         var bytes:ByteArray = RBase64.fromDataUrl(url);
         if (bytes == null || bytes.length == 0)
         {
            RLog.log("sandbox: picture " + id + " is not a data: URL");
            then();
            return;
         }
         var ld:Loader = new Loader();
         ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            try { pictures[id] = Bitmap(ld.content).bitmapData; } catch (err:Error) { RLog.error("sandbox picture " + id, err); }
            then();
         });
         ld.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void
         {
            RLog.log("sandbox: picture " + id + " could not be read");
            then();
         });
         try { ld.loadBytes(bytes); }
         catch (err2:Error)
         {
            RLog.error("sandbox picture " + id, err2);
            then();
         }
      }

      private static function levelOf(p:Object, id:String):Object
      {
         for each (var l:Object in p ? p.levels : []) if (l != null && String(l.id) == id) return l;
         return null;
      }

      private static function roomOf(l:Object, id:String):Object
      {
         for each (var r:Object in l ? l.rooms : []) if (r != null && String(r.id) == id) return r;
         return null;
      }

      private static function enterLevel(l:Object, roomId:String, spawn:String = null):void
      {
         levelObj = l;
         var r:Object = roomOf(l, roomId || String(l.start)) || l.rooms[0];
         goRoom(r, spawn);
      }

      private static function goRoom(r:Object, spawn:String):void
      {
         roomObj = r;
         if (!spawn || r.spawns == null || !(r.spawns[spawn] is Array)) spawn = "start";
         // Loaded again even from the 沙盒 room itself: another room is the same scene.
         SceneManager.getInstance().loadScene(ROOM, spawn, true);
      }

      /** The music of the room shown (a music file of the game), or "" (SceneMusic asks). */
      public static function get music():String
      {
         var m:String = roomObj && roomObj.music ? String(roomObj.music) : "";
         return /^music\/[A-Za-z0-9_\/.-]+\.mp3$/.test(m) && m.indexOf("..") < 0 ? m : "";
      }

      // ---------------------------------------------------------------- what the 沙盒 room asks

      /** The room to show: {room, level, pack, pictures (image id -> BitmapData)}; null outside a run. */
      public static function current():Object
      {
         if (pack == null || roomObj == null) return null;
         return {room: roomObj, level: levelObj, pack: pack, pictures: pictures};
      }

      private static function key(enemyId:String):String
      {
         return String(levelObj ? levelObj.id : "") + "/" + String(roomObj ? roomObj.id : "") + "/" + enemyId;
      }

      public static function isBeaten(enemyId:String):Boolean
      {
         return beaten[key(enemyId)] == true;
      }

      /** Every opponent of the room shown is beaten. */
      public static function cleared():Boolean
      {
         for each (var e:Object in roomObj ? roomObj.enemies : []) if (e != null && !isBeaten(String(e.id))) return false;
         return true;
      }

      /** Fight an opponent of the room; done(win) after its team. */
      public static function fightEnemy(e:Object, done:Function):void
      {
         if (run != null || e == null || !(e.team is Array) || e.team.length == 0) return;
         var k:String = key(String(e.id));
         fight({name: e.name || "", heal: levelObj == null || levelObj.heal !== false, enemies: e.team}, function(win:Boolean, at:int, refused:Boolean = false):void
         {
            if (win) beaten[k] = true;
            else if (!refused) NewDialog.showMessage("挑战失败（第" + (at + 1) + "个对手，共" + e.team.length + "个）。治疗亚比后再来吧！");
            if (done is Function) done(win);
         });
      }

      /** A door walked into: to a room, to another 关卡's room, to the end of the 关卡, or out. */
      public static function door(d:Object):void
      {
         if (d == null || run != null) return;
         if (d.open == "cleared" && !cleared())
         {
            NewDialog.showMessage("先打败这个房间里的所有对手，这扇门才会打开。");
            return;
         }
         var to:String = String(d.to || "");
         if (to == "#exit")
         {
            exit();
            return;
         }
         if (to == "#finish")
         {
            finish();
            return;
         }
         var slash:int = to.indexOf("/");
         if (slash >= 0)
         {
            var l:Object = levelOf(pack, to.substring(0, slash));
            if (l == null) return;
            enterLevel(l, to.substr(slash + 1), d.spawn);
            return;
         }
         var r:Object = roomOf(levelObj, to);
         if (r != null) goRoom(r, d.spawn);
      }

      private static function finish():void
      {
         var l:Object = levelObj;
         var nextLevel:Object = l && l.next ? levelOf(pack, String(l.next)) : null;
         if (nextLevel == null)
         {
            sayOnArrival("恭喜你通过了关卡「" + (l.name || l.id) + "」！");
            exit();
            return;
         }
         sayOnArrival("恭喜你通过了关卡「" + (l.name || l.id) + "」！下一关：「" + (nextLevel.name || nextLevel.id) + "」");
         enterLevel(nextLevel, null);
      }

      /** A message shown once the next room is there (leaving a room closes the panels open in it). */
      private static function sayOnArrival(text:String):void
      {
         var sm:SceneManager = SceneManager.getInstance();
         var shown:Function = function(e:SceneManagerEvent):void
         {
            sm.removeEventListener(SceneManagerEvent.SCENE_INITED, shown);
            NewDialog.showSucceedMessage(text);
         };
         sm.addEventListener(SceneManagerEvent.SCENE_INITED, shown);
      }

      /** Out of the 沙盒, to where it was started from. */
      public static function exit():void
      {
         roomObj = null;
         levelObj = null;
         var to:String = back || "starland";
         back = null;
         SceneManager.getInstance().loadScene(to);
      }

      /** Forget the pack (its pictures) once it is no longer wanted. */
      public static function reset():void
      {
         pack = null;
         pictures = {};
         beaten = {};
      }
   }
}
