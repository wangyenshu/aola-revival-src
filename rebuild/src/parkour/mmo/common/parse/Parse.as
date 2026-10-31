package mmo.common.parse
{
   /**
    * REVIVAL (aola-revival). The later common library's Parse, as far as 酷跑星世界 uses it:
    * parseIntToArray(flags, n) is [bit 0 set, bit 1 set, …] for n bits (the reward-taken
    * flags of its daily tasks, ParkourUserData and ParkourDailyTaskPanel).
    */
   public class Parse
   {
      public static function parseIntToArray(flags:int, count:int):Array
      {
         var out:Array = [];
         for (var i:int = 0; i < count; i++) out.push((flags & (1 << i)) != 0);
         return out;
      }
   }
}
