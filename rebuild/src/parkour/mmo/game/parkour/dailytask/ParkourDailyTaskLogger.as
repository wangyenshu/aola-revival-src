package mmo.game.parkour.dailytask
{
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   
   public class ParkourDailyTaskLogger
   {
      
      private static const DailyTaskIdOfHitProp:Object = {};
      
      private static const DailyTaskIdOfMap:Object = {};
      
      private static const DailyTaskIdOfUpEveluate:Object = {};
      
      public static const instance:ParkourDailyTaskLogger = new ParkourDailyTaskLogger();
      
      DailyTaskIdOfHitProp[ParkourGameMapConfig.PropFly] = 0;
      DailyTaskIdOfHitProp[ParkourGameMapConfig.PropAbsore] = 1;
      DailyTaskIdOfHitProp[ParkourGameMapConfig.PropGoldCoin] = 2;
      DailyTaskIdOfHitProp[ParkourGameMapConfig.PropPower] = 3;
      DailyTaskIdOfMap[1] = 8;
      DailyTaskIdOfMap[2] = 7;
      DailyTaskIdOfUpEveluate[ParkourGameConfig.EveluateA] = 9;
      DailyTaskIdOfUpEveluate[ParkourGameConfig.EveluateS] = 5;
      
      public function ParkourDailyTaskLogger()
      {
         super();
      }
      
      public function logHitProp(param1:int) : void
      {
         var _loc2_:int = int(DailyTaskIdOfHitProp[param1]);
         this.addOneTaskProgress(_loc2_);
      }
      
      public function logEveluate(param1:int) : void
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc2_:Array = [];
         for(_loc3_ in DailyTaskIdOfUpEveluate)
         {
            _loc4_ = parseInt(_loc3_);
            _loc5_ = int(DailyTaskIdOfUpEveluate[_loc3_]);
            if(param1 >= _loc4_)
            {
               _loc2_.push(_loc5_);
            }
         }
         this.addMutiTaskProgress(_loc2_);
      }
      
      public function logPlayMap(param1:int) : void
      {
         var _loc2_:int = int(DailyTaskIdOfMap[param1]);
         this.addOneTaskProgress(_loc2_);
      }
      
      public function logRelive() : void
      {
         this.addOneTaskProgress(6);
      }
      
      public function logJumpMissile() : void
      {
         this.addOneTaskProgress(4);
      }
      
      private function addOneTaskProgress(param1:int) : void
      {
         ParkourClient.addProgDailyTask(param1.toString());
      }
      
      private function addMutiTaskProgress(param1:Array) : void
      {
         ParkourClient.addProgDailyTask(param1.join(","));
      }
   }
}

