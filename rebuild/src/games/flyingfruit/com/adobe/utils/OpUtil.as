package com.adobe.utils
{
   public class OpUtil
   {
      
      private static const op:String = "+-*%";
      
      public function OpUtil()
      {
         super();
      }
      
      public static function getValue(param1:Array, param2:String) : int
      {
         var _loc5_:String = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc3_:Array = param2.split(" ");
         var _loc4_:Array = [];
         while(_loc3_.length > 0)
         {
            _loc5_ = _loc3_.shift();
            if(_loc5_.indexOf("s") == 0)
            {
               _loc4_.push(param1[int(_loc5_.substr(1))]);
            }
            else if(op.indexOf(_loc5_) >= 0)
            {
               _loc6_ = _loc4_.pop();
               _loc7_ = _loc4_.pop();
               if(_loc5_ == "+")
               {
                  _loc8_ = _loc7_ + _loc6_;
               }
               if(_loc5_ == "-")
               {
                  _loc8_ = _loc7_ - _loc6_;
               }
               if(_loc5_ == "*")
               {
                  _loc8_ = _loc7_ * _loc6_;
               }
               if(_loc5_ == "%")
               {
                  _loc8_ = _loc7_ % _loc6_;
               }
               _loc4_.push(_loc8_);
            }
            else
            {
               _loc4_.push(_loc5_);
            }
         }
         return _loc4_.pop();
      }
   }
}

