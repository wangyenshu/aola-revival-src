package mmo.game.parkour.data.signup
{
   import mmo.common.DateUtil;
   import mmo.common.utils.bit.BitUtil;
   import mmo.game.parkour.config.ParkourConfig;
   
   public class ParkourDailySignUpData
   {
      
      private static const FlagIndexByDay:Array = [5,6,0,1,2,3,4];
      
      private var flags:Array = [];
      
      public function ParkourDailySignUpData()
      {
         super();
      }
      
      public function parseFlag(param1:int) : void
      {
         this.flags = BitUtil.splitIntoIntArray(param1,ParkourConfig.TotalSignUpDay);
      }
      
      public function hadSignUpToday() : Boolean
      {
         return this.checkSignUpByIndex(this.todaySignIndex);
      }
      
      public function signUpToday() : void
      {
         this.flags[this.todaySignIndex] = true;
      }
      
      public function checkSignUpByIndex(param1:int) : Boolean
      {
         return this.flags[param1];
      }
      
      public function get todaySignIndex() : int
      {
         var _loc1_:Date = DateUtil.getServerTime();
         return FlagIndexByDay.indexOf(_loc1_.day);
      }
   }
}

