package com.adobe.utils
{
   public class StringUtil
   {
      
      private static const f:int = 20000;
      
      private static const wordList:Array = ["亍亍亏乎亃亏亍亍亏于乎亅亖亅于五乎乣亏亄亅互乴亅亓五","争于亓五亁于亃亅","亁亄亄乥亖亅于五乬争亓五亅于亅互","亍亍亏乎亃亏亍亍亏于乎亅亖亅于五乎乣亏亄亅互乴亅亓五","亏于乧亅五乣亏亄亅","亐于","亐亁互亁亍","互亅亓井二五","争亄","亓乐乀乘乓乀久乀亓乑乀乘乙乀久乀之乀乒乀之","亓乐乀亓乑乀乊乀乑乀之乀乙乙乙乙乙乙乑乀久","亓争"];
      
      public function StringUtil()
      {
         super();
      }
      
      public static function stringsAreEqual(param1:String, param2:String, param3:Boolean) : Boolean
      {
         if(param3)
         {
            return param1 == param2;
         }
         return param1.toUpperCase() == param2.toUpperCase();
      }
      
      public static function trim(param1:String) : String
      {
         return StringUtil.ltrim(StringUtil.rtrim(param1));
      }
      
      public static function ltrim(param1:String) : String
      {
         var _loc2_:Number = param1.length;
         var _loc3_:Number = 0;
         while(_loc3_ < _loc2_)
         {
            if(param1.charCodeAt(_loc3_) > 32)
            {
               return param1.substring(_loc3_);
            }
            _loc3_++;
         }
         return "";
      }
      
      public static function rtrim(param1:String) : String
      {
         var _loc2_:Number = param1.length;
         var _loc3_:Number = _loc2_;
         while(_loc3_ > 0)
         {
            if(param1.charCodeAt(_loc3_ - 1) > 32)
            {
               return param1.substring(0,_loc3_);
            }
            _loc3_--;
         }
         return "";
      }
      
      public static function beginsWith(param1:String, param2:String) : Boolean
      {
         return param2 == param1.substring(0,param2.length);
      }
      
      public static function endsWith(param1:String, param2:String) : Boolean
      {
         return param2 == param1.substring(param1.length - param2.length);
      }
      
      public static function remove(param1:String, param2:String) : String
      {
         return StringUtil.replace(param1,param2,"");
      }
      
      public static function replace(param1:String, param2:String, param3:String) : String
      {
         var _loc9_:Number = NaN;
         var _loc4_:String = new String();
         var _loc5_:Boolean = false;
         var _loc6_:Number = param1.length;
         var _loc7_:Number = param2.length;
         var _loc8_:Number = 0;
         for(; _loc8_ < _loc6_; _loc8_++)
         {
            if(param1.charAt(_loc8_) == param2.charAt(0))
            {
               _loc5_ = true;
               _loc9_ = 0;
               while(_loc9_ < _loc7_)
               {
                  if(param1.charAt(_loc8_ + _loc9_) != param2.charAt(_loc9_))
                  {
                     _loc5_ = false;
                     break;
                  }
                  _loc9_++;
               }
               if(_loc5_)
               {
                  _loc4_ += param3;
                  _loc8_ += _loc7_ - 1;
                  continue;
               }
            }
            _loc4_ += param1.charAt(_loc8_);
         }
         return _loc4_;
      }
      
      public static function isNullOrEmpty(param1:String) : Boolean
      {
         if(param1 == null || param1 == "")
         {
            return true;
         }
         return false;
      }
      
      public static function getHashCode(param1:String) : int
      {
         var _loc2_:int = param1.length;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_)
         {
            _loc3_ = 31 * _loc3_ + param1.charCodeAt(_loc4_);
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function split(param1:String, param2:String = ",") : Array
      {
         if(isNullOrEmpty(param1))
         {
            return [];
         }
         return param1.split(param2);
      }
      
      public static function splitToIntArray(param1:String, param2:String = ",") : Array
      {
         var _loc5_:String = null;
         if(isNullOrEmpty(param1))
         {
            return [];
         }
         var _loc3_:Array = [];
         var _loc4_:Array = param1.split(param2);
         for each(_loc5_ in _loc4_)
         {
            _loc3_.push(int(_loc5_));
         }
         return _loc3_;
      }
      
      public static function splitToNumberArray(param1:String, param2:String = ",") : Array
      {
         var _loc5_:String = null;
         if(isNullOrEmpty(param1))
         {
            return [];
         }
         var _loc3_:Array = [];
         var _loc4_:Array = param1.split(param2);
         for each(_loc5_ in _loc4_)
         {
            _loc3_.push(Number(_loc5_));
         }
         return _loc3_;
      }
      
      public static function fromJpWordByCode(param1:int) : String
      {
         return getCnWord(wordList[param1]);
      }
      
      private static function getCnWord(param1:String) : String
      {
         var _loc4_:int = 0;
         var _loc2_:String = "";
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1.charCodeAt(_loc3_);
            _loc4_ = _loc4_ - f;
            _loc2_ += String.fromCharCode(_loc4_);
            _loc3_++;
         }
         return _loc2_;
      }
   }
}

