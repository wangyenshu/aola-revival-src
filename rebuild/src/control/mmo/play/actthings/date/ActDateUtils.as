package mmo.play.actthings.date
{
   /** REBUILT (later-engine helper): activity dates against the game clock (the computer's clock here). */
   public class ActDateUtils
   {
      public static function now():Date
      {
         return new Date();
      }

      public static function isAfterDate(d:Date):Boolean
      {
         return now().time >= d.time;
      }

      public static function isBeforeDate(d:Date):Boolean
      {
         return now().time < d.time;
      }

      public static function isBetweenDate(a:Date, b:Date):Boolean
      {
         var t:Number = now().time;
         return t >= a.time && t < b.time;
      }

      /** 0 before, 1 during, 2 after. */
      public static function getTodayState(a:Date, b:Date):int
      {
         var t:Number = now().time;
         return t < a.time ? 0 : (t < b.time ? 1 : 2);
      }

      public static function isToday(d:Date):Boolean
      {
         var n:Date = now();
         return n.fullYear == d.fullYear && n.month == d.month && n.date == d.date;
      }

      public static function getHourMinArr(s:String):Array
      {
         var p:Array = s.split(":");
         return [int(p[0]), int(p[1])];
      }

      public static function formatDate(d:Date):String
      {
         return d.fullYear + "-" + (d.month + 1) + "-" + d.date;
      }
   }
}
