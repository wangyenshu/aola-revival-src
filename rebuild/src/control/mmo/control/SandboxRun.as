package mmo.control
{
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.revival.RJson;
   import mmo.revival.RLog;

   /**
    * The revival's 沙盒 fights (not of 2013): a team of opponents fought one
    * after another through SundriesExtension.revival_sandbox (sandbox.ts),
    * the next once the battle screen has gone; a loss ends the team. The
    * 对手关卡 page and the mods (ModRun) fight this way. The mods' rooms are
    * shown by the 沙盒 room (ROOM, scene/sandboxroom).
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

      /** A fight that never ended (its module failed) must not block the next ones. */
      public static function reset():void
      {
         run = null;
      }

      /** The music of the 沙盒 room shown (SceneMusic asks): the mod's. */
      public static function get music():String
      {
         return ModRun.musicNow;
      }
   }
}
