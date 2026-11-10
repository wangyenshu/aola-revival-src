package mmo.game.flyingfruit.fruit
{
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   
   public class FruitManager
   {
      
      private var diskLiveArray:Array = new Array(50);
      
      public var curLiveNum:int = 0;
      
      private var diskArray1:Array = new Array(50);
      
      private var diskArray2:Array = new Array(50);
      
      private var diskArray3:Array = new Array(50);
      
      private var diskArray4:Array = new Array(10);
      
      private var diskArray5:Array = new Array(10);
      
      private var diskArray6:Array = new Array(10);
      
      private var diskArray7:Array = new Array(10);
      
      private var diskArray8:Array = new Array(20);
      
      private var diskArrayIndex:Array = [this.diskArray1,this.diskArray2,this.diskArray3,this.diskArray4,this.diskArray5,this.diskArray6,this.diskArray7,this.diskArray8];
      
      private var diskNumPointer:Array = [0,0,0,0,0,0,0,0];
      
      public function FruitManager()
      {
         super();
      }
      
      public function getDiskById(param1:int) : FruitBase
      {
         var _loc3_:Class = null;
         var _loc2_:FruitBase = this.popOutOfStack(param1 - 1) as FruitBase;
         if(_loc2_ == null)
         {
            _loc3_ = getDefinitionByName("mmo.game.flyingfruit.fruit.fruit.Fruit" + param1) as Class;
            _loc2_ = new _loc3_() as FruitBase;
            _loc2_.mouseChildren = false;
            _loc2_.mouseEnabled = false;
         }
         this.pushIntoLiveArray(_loc2_);
         return _loc2_;
      }
      
      private function pushIntoStack(param1:FruitBase) : void
      {
         var _loc2_:Array = this.diskArrayIndex[param1.id - 1];
         _loc2_[this.diskNumPointer[param1.id - 1]] = param1;
         ++this.diskNumPointer[param1.id - 1];
      }
      
      private function popOutOfStack(param1:int) : FruitBase
      {
         var _loc3_:FruitBase = null;
         var _loc2_:Array = this.diskArrayIndex[param1];
         if(this.diskNumPointer[param1] == 0)
         {
            return null;
         }
         --this.diskNumPointer[param1];
         _loc3_ = _loc2_[this.diskNumPointer[param1]];
         _loc2_[this.diskNumPointer[param1]] = null;
         return _loc3_;
      }
      
      public function removeDisk(param1:FruitBase) : void
      {
         this.popOutOfLiveArray(param1);
         this.pushIntoStack(param1);
         param1.reSetDiskState();
         DisplayUtil.stopAndRemove(param1);
      }
      
      private function pushIntoLiveArray(param1:FruitBase) : void
      {
         this.diskLiveArray[this.curLiveNum] = param1;
         ++this.curLiveNum;
      }
      
      private function popOutOfLiveArray(param1:FruitBase) : void
      {
         var _loc3_:FruitBase = null;
         var _loc2_:* = int(this.diskLiveArray.length - 1);
         while(_loc2_ >= 0)
         {
            _loc3_ = this.diskLiveArray[_loc2_] as FruitBase;
            if(_loc3_ == param1)
            {
               --this.curLiveNum;
               this.diskLiveArray[_loc2_] = this.diskLiveArray[this.curLiveNum];
               this.diskLiveArray[this.curLiveNum] = null;
               return;
            }
            _loc2_--;
         }
      }
      
      public function get getDiskLiveArray() : Array
      {
         return this.diskLiveArray;
      }
      
      public function allDiskesBombWithScore() : void
      {
         var _loc1_:FruitBase = null;
         var _loc2_:* = int(this.curLiveNum - 1);
         while(_loc2_ >= 0)
         {
            _loc1_ = this.diskLiveArray[_loc2_];
            if(_loc1_.state == "normal")
            {
               _loc1_.beHitted(true);
            }
            _loc2_--;
         }
      }
      
      public function allDiskesBombNoScore(param1:FruitBase) : void
      {
         var _loc2_:FruitBase = null;
         var _loc3_:* = int(this.curLiveNum - 1);
         while(_loc3_ >= 0)
         {
            _loc2_ = this.diskLiveArray[_loc3_];
            if(!(_loc2_ == param1 || _loc2_.state != "normal"))
            {
               _loc2_.bomb();
            }
            _loc3_--;
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:FruitBase = null;
         var _loc2_:* = int(this.curLiveNum - 1);
         while(_loc2_ >= 0)
         {
            _loc1_ = this.diskLiveArray[_loc2_];
            if(_loc1_ != null)
            {
               _loc1_.dispose();
            }
            _loc2_--;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.diskArrayIndex.length)
         {
            this.disposeArray(this.diskArrayIndex[_loc3_],_loc3_);
            _loc3_++;
         }
         this.diskLiveArray = null;
         this.diskArray1 = null;
         this.diskArray2 = null;
         this.diskArray3 = null;
         this.diskArray4 = null;
         this.diskArray5 = null;
         this.diskArray6 = null;
         this.diskArray7 = null;
         this.diskArray8 = null;
         this.diskArrayIndex = null;
         this.diskNumPointer = null;
      }
      
      private function disposeArray(param1:Array, param2:*) : void
      {
         var _loc3_:FruitBase = null;
         var _loc4_:* = int(this.diskNumPointer[param2] - 1);
         while(_loc4_ >= 0)
         {
            _loc3_ = param1[_loc4_];
            if(_loc3_ != null)
            {
               _loc3_.dispose();
            }
            _loc4_--;
         }
      }
   }
}

