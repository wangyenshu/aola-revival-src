package mmo.game.flyingfruit
{
   import mmo.common.HitTest;
   import mmo.game.flyingfruit.fruit.FruitBase;
   
   public class FFHitManager
   {
      
      private var hittedDiskArr:Array = new Array(20);
      
      private var curHitNum:int = 0;
      
      private var bombDisk:FruitBase;
      
      public function FFHitManager()
      {
         super();
      }
      
      public function startCheck() : void
      {
         FFInstanceManager.instance().enterFrameManager.registerFun(this.doCheck);
      }
      
      private function doCheck() : void
      {
         var _loc1_:Array = null;
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         var _loc4_:FruitBase = null;
         var _loc5_:int = 0;
         if(FFInstanceManager.instance().mainPanel.mcGun.currentLabel == "shoot")
         {
            _loc1_ = FFInstanceManager.instance().diskManager.getDiskLiveArray;
            this.curHitNum = 0;
            _loc2_ = false;
            _loc3_ = 0;
            while(_loc3_ < FFInstanceManager.instance().diskManager.curLiveNum)
            {
               _loc4_ = _loc1_[_loc3_];
               if(_loc4_.state == "normal")
               {
                  if(HitTest.complexHitTestObject(FFInstanceManager.instance().mainPanel.mcGun,_loc4_))
                  {
                     if(_loc4_.id == 6)
                     {
                        _loc2_ = true;
                        this.bombDisk = _loc4_;
                     }
                     this.hittedDiskArr[this.curHitNum] = _loc4_;
                     ++this.curHitNum;
                  }
               }
               _loc3_++;
            }
            if(_loc2_ && this.bombDisk != null)
            {
               this.bombDisk.beHitted();
               FFInstanceManager.instance().mainPanel.refreshBombNum();
            }
            else
            {
               this.rankDiskArray();
               _loc5_ = 0;
               while(_loc5_ < this.curHitNum)
               {
                  this.hittedDiskArr[_loc5_].beHitted(false,_loc5_ + 1);
                  FFInstanceManager.instance().mainPanel.refreshBombNum();
                  _loc5_++;
               }
               if(this.curHitNum > 1)
               {
                  FFInstanceManager.instance().mainPanel.refreshAnger(this.curHitNum);
               }
            }
         }
      }
      
      private function rankDiskArray() : void
      {
         var _loc1_:FruitBase = null;
         var _loc2_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:* = int(this.curHitNum - 1);
         while(_loc3_ >= 0)
         {
            _loc1_ = this.hittedDiskArr[_loc3_] as FruitBase;
            _loc2_ = _loc3_;
            _loc4_ = 0;
            while(_loc4_ < _loc3_)
            {
               if(this.hittedDiskArr[_loc4_].y < _loc1_.y)
               {
                  _loc1_ = this.hittedDiskArr[_loc4_] as FruitBase;
                  _loc2_ = _loc4_;
               }
               _loc4_++;
            }
            this.hittedDiskArr[_loc2_] = this.hittedDiskArr[_loc3_];
            this.hittedDiskArr[_loc3_] = _loc1_;
            _loc3_--;
         }
      }
      
      public function dispose() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doCheck);
         var _loc1_:int = 0;
         while(_loc1_ < this.curHitNum)
         {
            this.hittedDiskArr[_loc1_] = null;
            _loc1_++;
         }
         this.hittedDiskArr = null;
      }
   }
}

