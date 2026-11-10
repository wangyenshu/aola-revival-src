package mmo.common
{
   import flash.utils.getTimer;
   
   public class DateUtil
   {
      
      private static var initServerMs:Number;
      
      private static var initTime:Number;
      
      private static var dayCountOfMonth:Array = [31,29,31,30,31,30,31,31,30,31,30,31];
      
      private static var timezoneOffset:* = -480;
      
      public function DateUtil()
      {
         super();
      }
      
      public static function init(param1:Number) : *
      {
         initServerMs = param1;
         initTime = getTimer();
      }
      
      public static function getServerTimeOnServerTimeZone() : Date
      {
         var _loc1_:Number = initServerMs + getTimer() - initTime;
         return new Date(_loc1_);
      }
      
      public static function getServerTime() : Date
      {
         var _loc1_:Number = initServerMs + getTimer() - initTime;
         _loc1_ += (new Date().timezoneOffset - timezoneOffset) * 60 * 1000;
         return new Date(_loc1_);
      }
      
      public static function isToday(param1:int, param2:int, param3:int) : Boolean
      {
         var _loc4_:Date = getServerTime();
         return _loc4_.getFullYear() == param1 && _loc4_.getMonth() == param2 && _loc4_.getDate() == param3;
      }
      
      public static function isAfterToday(param1:int, param2:int, param3:int) : Boolean
      {
         var _loc4_:Date = new Date(param1,param2,param3);
         if(_loc4_.getTime() > initServerMs && !isToday(param1,param2,param3))
         {
            return true;
         }
         return false;
      }
      
      public static function isBeforeToday(param1:int, param2:int, param3:int) : Boolean
      {
         return !isToday(param1,param2,param3) && !isAfterToday(param1,param2,param3);
      }
      
      public static function formatDateYMD(param1:Date = null) : String
      {
         var _loc2_:Date = param1 != null ? param1 : getServerTime();
         return _loc2_.getFullYear() + "-" + (_loc2_.getMonth() + 1) + "-" + _loc2_.getDate();
      }
      
      public static function getAstro(param1:int, param2:int) : String
      {
         var _loc3_:String = "摩羯水瓶双鱼牧羊金牛双子巨蟹狮子处女天秤天蝎射手摩羯";
         var _loc4_:Array = new Array(20,19,21,21,21,22,23,23,23,23,22,22);
         return _loc3_.substr(param1 * 2 - (param2 < _loc4_[param1 - 1] ? 2 : 0),2);
      }
      
      public static function validateYMD(param1:String, param2:String, param3:String) : Boolean
      {
         var intYear:* = undefined;
         var intMonth:* = undefined;
         var intDay:* = undefined;
         var date:Date = null;
         var year:String = param1;
         var month:String = param2;
         var day:String = param3;
         try
         {
            if(year == null || month == null || day == null || year.length == 0 || month.length == 0 || day.length == 0)
            {
               return false;
            }
            intYear = parseInt(year);
            intMonth = parseInt(month);
            intDay = parseInt(day);
            date = new Date();
            if(intYear < 1900 || intYear > date.getFullYear() || intMonth < 1 || intMonth > 12 || intDay < 1 || intDay > 31)
            {
               return false;
            }
            if(intMonth != 2)
            {
               return intDay <= dayCountOfMonth[intMonth - 1];
            }
            if(intYear % 4 != 0)
            {
               return intDay <= 28;
            }
            if(intYear % 100 != 0)
            {
               return intDay <= 29;
            }
            if(intYear % 400 == 0)
            {
               return intDay <= 29;
            }
            if(intYear % 400 != 0)
            {
               return intDay <= 28;
            }
            if(intDay > 29)
            {
               return false;
            }
         }
         catch(err:Error)
         {
            return false;
         }
         return true;
      }
      
      public static function compileMe() : void
      {
      }
   }
}

