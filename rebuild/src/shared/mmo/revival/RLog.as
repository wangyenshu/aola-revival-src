package mmo.revival
{
   import flash.external.ExternalInterface;
   import flash.utils.getDefinitionByName;

   /**
    * REBUILT helper (not an original class). Writes rebuilt-module diagnostics
    * to the browser console through ExternalInterface, and to trace().
    */
   public class RLog
   {
      public static function log(... parts):void
      {
         var text:String = "[rebuilt] " + parts.join(" ");
         trace(text);
         try
         {
            if (ExternalInterface.available)
            {
               ExternalInterface.call("console.log", text);
            }
         }
         catch (e:Error)
         {
         }
      }

      private static var stubbed:Object = {};

      /** First call of a stand-in method: logged once, so the console lists what to rebuild. */
      public static function stub(name:String):void
      {
         // A player asked for something (a panel, a game) that is still a stand-in: say so on screen.
         var method:String = name.substr(name.lastIndexOf(".") + 1);
         if (/^(show|open|start|enter|play|begin|join|load(?!Res))/i.test(method)) deadClick(name);
         if (stubbed[name])
         {
            return;
         }
         stubbed[name] = true;
         log("stub called: " + name);
      }

      private static var lastNotice:Number = 0;

      private static function deadClick(name:String):void
      {
         var now:Number = new Date().time;
         if (now - lastNotice < 1500) return;
         lastNotice = now;
         try
         {
            var LM:Class = getDefinitionByName("mmo.loader.layer.LayerManager") as Class;
            RNotice.show(LM.getBaseTop(), "这个功能还在修复中哦！");
            log("dead click: " + name);
         }
         catch (e:Error)
         {
         }
      }

      public static function error(where:String, e:*):void
      {
         var detail:String = e is Error ? (Error(e).getStackTrace() || Error(e).message) : String(e);
         log("ERROR in " + where + ": " + detail);
      }
   }
}
