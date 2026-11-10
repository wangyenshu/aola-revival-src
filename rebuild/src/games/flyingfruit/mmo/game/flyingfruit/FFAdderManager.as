package mmo.game.flyingfruit
{
   import mmo.game.flyingfruit.fruit.FruitBase;
   
   public class FFAdderManager
   {
      
      private var curTime:int = 0;
      
      private var diskObj:Object;
      
      public var isDoubleScore:Boolean = false;
      
      private var curDoubleTime:int = 0;
      
      private var doubleScoreDiskObj:Object;
      
      public var isAddTime:Boolean = false;
      
      private var addTimeDiskObj:Object;
      
      public function FFAdderManager()
      {
         super();
      }
      
      public function startAdd() : void
      {
         this.diskObj = FFAdderConfig.DISK_CONFIG;
         this.curTime = 0;
         this.onAdderDisk();
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onAdderDisk,25);
      }
      
      private function onAdderDisk() : void
      {
         var _loc1_:String = null;
         var _loc3_:Array = null;
         var _loc5_:* = undefined;
         if(this.isDoubleScore)
         {
            if(this.curDoubleTime == 0)
            {
               _loc5_ = Math.floor(Math.random() * FFAdderConfig.DOUBLE_SCORE_TYPE) + 1;
               this.doubleScoreDiskObj = FFAdderConfig["DOUBLE_SCORE_CONFIG" + _loc5_];
            }
            ++this.curDoubleTime;
            _loc1_ = this.doubleScoreDiskObj[this.curDoubleTime];
         }
         else if(this.isAddTime)
         {
            this.isAddTime = false;
            this.addTimeDiskObj = FFAdderConfig.TIME_ADD_CONFIG;
            _loc1_ = this.addTimeDiskObj[1];
         }
         else
         {
            ++this.curTime;
            FFInstanceManager.instance().mainPanel.refreshTime(this.curTime);
            if(this.checkTimeEnd())
            {
               return;
            }
            _loc1_ = this.diskObj[this.curTime];
         }
         if(_loc1_ == null)
         {
            return;
         }
         var _loc2_:Array = _loc1_.split(";");
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc3_ = _loc2_[_loc4_].split("_");
            this.addOneTypeDisk(_loc3_[0],_loc3_[1],_loc3_[2]);
            _loc4_++;
         }
      }
      
      private function checkTimeEnd() : Boolean
      {
         if(this.curTime >= FFAdderConfig.GAME_TIME)
         {
            FFInstanceManager.instance().enterFrameManager.removeFun(this.onAdderDisk);
            FFInstanceManager.instance().enterFrameManager.pause();
            FlyingFruitManager.instance.showGameOverPanel();
            return true;
         }
         if(this.curTime >= 50)
         {
            FFInstanceManager.instance().mainPanel.playEndMovie();
         }
         return false;
      }
      
      private function addOneTypeDisk(param1:int, param2:int, param3:int) : void
      {
         var _loc6_:FruitBase = null;
         if(param2 + param3 == 0)
         {
            return;
         }
         var _loc4_:int = Math.random() * (param3 - param2 + 1) + param2;
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc6_ = FFInstanceManager.instance().diskManager.getDiskById(param1);
            FFInstanceManager.instance().mainPanel.backGround.addChild(_loc6_);
            if(Math.random() < 0.5)
            {
               _loc6_.x = 100 + Math.random() * 300;
            }
            else
            {
               _loc6_.x = 500 + Math.random() * 350;
            }
            _loc6_.y = 560;
            _loc6_.startFly();
            _loc5_++;
         }
      }
      
      public function setAddTimeState(param1:int) : void
      {
         this.isAddTime = true;
         this.curTime -= param1;
         FFInstanceManager.instance().mainPanel.refreshTime(this.curTime);
         FFInstanceManager.instance().mainPanel.refresEndMovie(param1);
      }
      
      public function setDoubleScoreTrue() : void
      {
         this.isDoubleScore = true;
         this.curDoubleTime = 0;
      }
      
      public function setDoubleScoreFalse() : void
      {
         this.isDoubleScore = false;
         this.curDoubleTime = 0;
      }
      
      public function dispose() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onAdderDisk);
      }
   }
}

