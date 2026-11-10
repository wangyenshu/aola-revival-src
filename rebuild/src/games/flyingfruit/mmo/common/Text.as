package mmo.common
{
   import flash.events.FocusEvent;
   import flash.events.TextEvent;
   import flash.system.Capabilities;
   import flash.system.IME;
   import flash.text.TextField;
   import flash.text.TextFormat;
   
   public class Text
   {
      
      public function Text()
      {
         super();
      }
      
      public static function trim(param1:String) : String
      {
         return param1.replace(/(^\s*)|(\s*$)/g,"");
      }
      
      public static function SBCtoDBC(param1:String) : String
      {
         var _loc5_:int = 0;
         var _loc2_:String = "";
         var _loc3_:int = param1.length;
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc5_ = param1.charCodeAt(_loc4_);
            if(_loc5_ == 12288)
            {
               _loc2_ += String.fromCharCode(32);
            }
            else if(_loc5_ == 12290)
            {
               _loc2_ += String.fromCharCode(46);
            }
            else if(_loc5_ > 65280 && _loc5_ < 65375)
            {
               _loc2_ += String.fromCharCode(_loc5_ - 65248);
            }
            else
            {
               _loc2_ += String.fromCharCode(_loc5_);
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function getString(param1:String) : String
      {
         return trim(SBCtoDBC(param1));
      }
      
      public static function getLength(param1:String) : int
      {
         var _loc2_:int = param1.length;
         var _loc3_:int = param1.length;
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            if(param1.charCodeAt(_loc4_) >= 255)
            {
               _loc2_++;
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function format(param1:String, ... rest) : String
      {
         var _loc5_:RegExp = null;
         var _loc3_:String = param1.concat();
         var _loc4_:int = 0;
         while(_loc4_ < rest.length)
         {
            _loc5_ = new RegExp("%" + (_loc4_ + 1),"g");
            _loc3_ = _loc3_.replace(_loc5_,rest[_loc4_].toString());
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function setPasswordTextField(param1:TextField, param2:Boolean = true) : void
      {
         param1.displayAsPassword = param2;
         param1.addEventListener(TextEvent.TEXT_INPUT,checkCharacter);
         param1.addEventListener(FocusEvent.FOCUS_IN,stopIME);
         param1.addEventListener(FocusEvent.FOCUS_OUT,openIME);
      }
      
      private static function checkCharacter(param1:TextEvent) : void
      {
         if(getLength(param1.text) > 1)
         {
            param1.preventDefault();
         }
      }
      
      private static function stopIME(param1:FocusEvent) : void
      {
         if(Capabilities.hasIME)
         {
            IME.enabled = false;
         }
      }
      
      private static function openIME(param1:FocusEvent) : void
      {
         if(Capabilities.hasIME)
         {
            IME.enabled = true;
         }
      }
      
      public static function setTextRedColor(param1:TextField) : void
      {
         var _loc2_:TextFormat = param1.getTextFormat();
         _loc2_.color = 13369344;
         param1.setTextFormat(_loc2_);
      }
      
      public static function setTextDefaultColor(param1:TextField) : void
      {
         var _loc2_:TextFormat = param1.getTextFormat();
         _loc2_.color = 0;
         param1.setTextFormat(_loc2_);
      }
   }
}

