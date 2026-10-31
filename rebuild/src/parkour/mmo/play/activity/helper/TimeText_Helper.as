package mmo.play.activity.helper
{
   import flash.text.TextField;

   /**
    * REVIVAL (aola-revival). The later engine's TimeText_Helper, as far as 酷跑星世界 uses it:
    * setShortTime(field, seconds) writes "mm:ss" (the time to the next 星星能量, ParkourMainLoveUI).
    */
   public class TimeText_Helper
   {
      public static function setShortTime(field:TextField, seconds:int):void
      {
         if (field != null) field.text = getShortTimeString(seconds);
      }

      public static function getShortTimeString(seconds:int):String
      {
         if (seconds < 0) seconds = 0;
         return two(int(seconds / 60)) + ":" + two(seconds % 60);
      }

      private static function two(n:int):String
      {
         return n < 10 ? "0" + n : String(n);
      }
   }
}
