package mmo.common.cachepool
{
   import flash.utils.Dictionary;
   
   public class CachePool
   {
      
      private var _size:int;
      
      private var _keyArr:Array;
      
      private var _cacheMap:Dictionary;
      
      private var _usageArr:Array;
      
      private var _pointer:int;
      
      public function CachePool(param1:int)
      {
         super();
         this._size = param1;
         this._keyArr = new Array(param1);
         this._usageArr = new Array(param1);
         var _loc2_:int = 0;
         while(_loc2_ < param1)
         {
            this._keyArr[_loc2_] = null;
            this._usageArr[_loc2_] = 0;
            _loc2_++;
         }
         this._cacheMap = new Dictionary();
         this._pointer = 0;
      }
      
      public function getObject(param1:String) : *
      {
         if(!this._cacheMap.hasOwnProperty(param1))
         {
            return null;
         }
         var _loc2_:int = this._keyArr.indexOf(param1);
         if(_loc2_ < 0)
         {
            return null;
         }
         this._usageArr[_loc2_] = 1;
         return this._cacheMap[param1];
      }
      
      public function addObject(param1:String, param2:*) : void
      {
         this.calcAvailableIndex();
         this._keyArr[this._pointer] = param1;
         this._usageArr[this._pointer] = 1;
         this._cacheMap[param1] = param2;
      }
      
      private function calcAvailableIndex() : void
      {
         var _loc1_:String = null;
         while(this._usageArr[this._pointer] != 0)
         {
            this._usageArr[this._pointer] = 0;
            ++this._pointer;
            if(this._pointer >= this._size)
            {
               this._pointer = 0;
            }
         }
         if(this._keyArr[this._pointer] != null)
         {
            _loc1_ = this._keyArr[this._pointer] as String;
            delete this._cacheMap[_loc1_];
            this._keyArr[this._pointer] = null;
         }
      }
   }
}

