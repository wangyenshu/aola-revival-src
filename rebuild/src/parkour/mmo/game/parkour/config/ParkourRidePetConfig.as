package mmo.game.parkour.config
{
   import mmo.game.parkour.data.ridepet.ParkourRidePetAbility;
   import mmo.game.parkour.data.ridepet.ParkourRidePetInfo;
   import mmo.game.parkour.game.effect.impl.ParkourPlayerFlyByFlyMeterEffect;
   
   public class ParkourRidePetConfig
   {
      
      private static const RidePetInfos:Array = [new ParkourRidePetInfo(1,0,new ParkourRidePetAbility(0,0,0,0,0,0),new ParkourRidePetAbility(100,5,100,100,1,1),"蓄满能量后按空格键冲刺600米",ParkourPlayerFlyByFlyMeterEffect,{"flyMeter":600})];
      
      public function ParkourRidePetConfig()
      {
         super();
      }
      
      public static function get numOfRidePet() : int
      {
         return RidePetInfos.length;
      }
      
      public static function getRidePetInfoById(param1:int) : ParkourRidePetInfo
      {
         var _loc2_:ParkourRidePetInfo = null;
         for each(_loc2_ in RidePetInfos)
         {
            if(_loc2_.id == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public static function getRidePetInfos(param1:int, param2:int) : Array
      {
         return RidePetInfos.slice(param1,param1 + param2);
      }
   }
}

