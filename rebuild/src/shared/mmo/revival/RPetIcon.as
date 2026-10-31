package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;

   /**
    * The pictures of peticon/peticon<id>.swf (mmo.pet.peticon<id>_S small,
    * _L large, _F face). For the 亚比 one could not get in 2012 (迅猛龙 400 and
    * others, now given by the 工具箱) the small one is an empty sprite: the
    * large one of the same file stands in, scaled down by the caller.
    */
   public class RPetIcon
   {
      public static function make(cls:String):DisplayObject
      {
         var d:DisplayObject = inst(cls);
         if (d != null && !empty(d)) return d;
         var base:String = cls.replace(/_[SLF]$/, "");
         for each (var alt:String in ["_L", "_F", "_S"])
         {
            if (base + alt == cls) continue;
            var a:DisplayObject = inst(base + alt);
            if (a != null && !empty(a)) return a;
         }
         return d;
      }

      private static function inst(cls:String):DisplayObject
      {
         try
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return null;
            var C:Class = getDefinitionByName(cls) as Class;
            return new C() as DisplayObject;
         }
         catch (e:Error) {}
         return null;
      }

      private static function empty(d:DisplayObject):Boolean
      {
         var b:Object = d.getBounds(d);
         return b.width < 2 || b.height < 2;
      }
   }
}
