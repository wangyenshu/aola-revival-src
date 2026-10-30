package mmo.shoot.effect.helper
{
   public class DirectionHelper
   {
      
      public function DirectionHelper()
      {
         super();
      }
      
      public static function getDirection(param1:Number, param2:Number) : String
      {
         var _loc3_:String = "dd";
         if(param2 < 0)
         {
            if(Math.abs(param1) < Math.abs(param2))
            {
               _loc3_ = "uu";
            }
            else if(param1 > 0)
            {
               _loc3_ = "ru";
            }
            else
            {
               _loc3_ = "lu";
            }
         }
         else if(Math.abs(param1) < Math.abs(param2))
         {
            _loc3_ = "dd";
         }
         else if(param1 > 0)
         {
            _loc3_ = "rd";
         }
         else
         {
            _loc3_ = "ld";
         }
         return _loc3_;
      }
   }
}

