package mmo.revival
{
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;

   /**
    * REVIVAL. Classes looked up by name, as the game's modules look up their
    * pictures (mmo.pet.peticon<race>_L, mmo.petfight.pet<race>_1 …): those of
    * the main application domain, and those a mod gives under a game name
    * (a mod's own classes live in a domain of their own). Shared by every
    * module: the first module loaded defines it, the others use that one.
    */
   public class RDef
   {
      private static var named:Object = {};

      /** Answer `name` with class c (null: forget it). */
      public static function define(name:String, c:Class):void
      {
         if (c == null) delete named[name];
         else named[name] = c;
      }

      /** Forget every name starting with prefix (a mod unloaded). */
      public static function forget(prefix:String):void
      {
         for (var n:String in named) if (n.indexOf(prefix) == 0) delete named[n];
      }

      public static function has(name:String):Boolean
      {
         if (named[name] != null) return true;
         try { return ApplicationDomain.currentDomain.hasDefinition(name); } catch (e:Error) {}
         return false;
      }

      public static function get(name:String):Class
      {
         var c:Class = named[name] as Class;
         if (c != null) return c;
         try
         {
            if (ApplicationDomain.currentDomain.hasDefinition(name)) return getDefinitionByName(name) as Class;
         }
         catch (e:Error) {}
         return null;
      }

      /** A new instance of the class answering name, or null. */
      public static function make(name:String):*
      {
         var c:Class = get(name);
         if (c == null) return null;
         try { return new c(); } catch (e:Error) { RLog.error("RDef " + name, e); }
         return null;
      }
   }
}
