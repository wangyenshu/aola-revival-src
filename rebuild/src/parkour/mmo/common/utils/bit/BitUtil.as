package mmo.common.utils.bit
{
   /**
    * REVIVAL (aola-revival). The later common library's BitUtil, as far as 酷跑星世界 uses it:
    * splitIntoIntArray(flags, n) is [bit 0, bit 1, …] as 0/1 for n bits (the days signed,
    * ParkourDailySignUpData).
    */
   public class BitUtil
   {
      public static function splitIntoIntArray(flags:int, count:int):Array
      {
         var out:Array = [];
         for (var i:int = 0; i < count; i++) out.push((flags >> i) & 1);
         return out;
      }

      public static function isFlagSet(flags:int, bit:int):Boolean
      {
         return (flags & (1 << bit)) != 0;
      }
   }
}
