package mmo.game.parkour.data.dailytask
{
   public class ParkourDailyTaskInfo
   {
      
      private var _id:int;
      
      private var _maxProgress:int;
      
      public function ParkourDailyTaskInfo(param1:int, param2:int)
      {
         super();
         this._id = param1;
         this._maxProgress = param2;
      }
      
      public function get id() : int
      {
         return this._id;
      }
      
      public function get maxProgress() : int
      {
         return this._maxProgress;
      }
   }
}

