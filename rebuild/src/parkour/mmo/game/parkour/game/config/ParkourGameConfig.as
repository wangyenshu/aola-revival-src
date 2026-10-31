package mmo.game.parkour.game.config
{
   import flash.geom.Rectangle;
   
   public class ParkourGameConfig
   {
      
      public static const Width:int = 960;
      
      public static const Height:int = 560;
      
      public static const MapRect:Rectangle = new Rectangle(0,0,Width,Height);
      
      public static const MeterToPixel:Number = Width / 200;
      
      public static const FrameRate:int = 25;
      
      public static const MaxPower:int = 100;
      
      public static const EveluateC:int = 0;
      
      public static const EveluateB:int = 1;
      
      public static const EveluateA:int = 2;
      
      public static const EveluateS:int = 3;
      
      public static const EveluateSS:int = 4;
      
      public static const EveluateSSS:int = 5;
      
      private static const EveluateDes:Array = ["C","B","A","S","SS","SSS"];
      
      private static const EveluateMeter:Array = [500,1500,5000,10000,20000,int.MAX_VALUE];
      
      private static const LogsMeter:Array = [500,1000,2000,5000,8000,int.MAX_VALUE];
      
      private static const LogButtons:Array = [6200,6201,6202,6203,6204,6205];
      
      public function ParkourGameConfig()
      {
         super();
      }
      
      public static function getEveluateDes(param1:int) : String
      {
         var _loc2_:int = getEveluateIndex(param1);
         return EveluateDes[_loc2_];
      }
      
      public static function getEveluateIndex(param1:int) : int
      {
         var _loc2_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < EveluateMeter.length)
         {
            _loc4_ = int(EveluateMeter[_loc3_]);
            if(param1 < _loc4_)
            {
               _loc2_ = _loc3_;
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function getLogButton(param1:int) : int
      {
         var _loc2_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < LogsMeter.length)
         {
            _loc4_ = int(LogsMeter[_loc3_]);
            if(param1 < _loc4_)
            {
               _loc2_ = _loc3_;
               break;
            }
            _loc3_++;
         }
         return LogButtons[_loc2_];
      }
   }
}

