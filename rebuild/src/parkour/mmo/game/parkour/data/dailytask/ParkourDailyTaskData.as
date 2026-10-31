package mmo.game.parkour.data.dailytask
{
   public class ParkourDailyTaskData
   {
      
      private var _info:ParkourDailyTaskInfo;
      
      private var _progress:int = 0;
      
      private var _hadGet:Boolean = false;
      
      public function ParkourDailyTaskData(param1:ParkourDailyTaskInfo)
      {
         super();
         this._info = param1;
      }
      
      public function parseObj(param1:Object) : void
      {
      }
      
      public function get info() : ParkourDailyTaskInfo
      {
         return this._info;
      }
      
      public function get progress() : int
      {
         return this._progress;
      }
      
      public function get hadGet() : Boolean
      {
         return this._hadGet;
      }
      
      public function get hadFinish() : Boolean
      {
         return this.progress >= this.info.maxProgress;
      }
      
      public function set hadGet(param1:Boolean) : void
      {
         this._hadGet = param1;
      }
      
      public function set progress(param1:int) : void
      {
         this._progress = param1;
      }
   }
}

