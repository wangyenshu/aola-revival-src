package mmo.game.parkour.config
{
   import mmo.game.parkour.data.dailytask.ParkourDailyTaskInfo;
   
   public class ParkourDailyTaskConfig
   {
      
      private static const TaskInfos:Array = [new ParkourDailyTaskInfo(0,8),new ParkourDailyTaskInfo(1,8),new ParkourDailyTaskInfo(2,8),new ParkourDailyTaskInfo(3,8),new ParkourDailyTaskInfo(4,8),new ParkourDailyTaskInfo(5,5),new ParkourDailyTaskInfo(6,5),new ParkourDailyTaskInfo(7,5),new ParkourDailyTaskInfo(8,5),new ParkourDailyTaskInfo(9,5)];
      
      public function ParkourDailyTaskConfig()
      {
         super();
      }
      
      public static function getTaskInfo(param1:int) : ParkourDailyTaskInfo
      {
         var _loc2_:ParkourDailyTaskInfo = null;
         for each(_loc2_ in TaskInfos)
         {
            if(_loc2_.id == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
   }
}

