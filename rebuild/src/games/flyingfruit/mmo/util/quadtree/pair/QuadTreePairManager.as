package mmo.util.quadtree.pair
{
   import flash.utils.Dictionary;
   import mmo.util.quadtree.QuadTree;
   import mmo.util.quadtree.QuadTreeConstants;
   
   public class QuadTreePairManager
   {
      
      private var _callback:IPairHandler;
      
      private var _quadTree:QuadTree;
      
      private var _pairTable:Dictionary;
      
      private var _pairCount:int;
      
      private var _pairPool:Vector.<QuadTreePair>;
      
      private var _poolMask:int;
      
      private var _readIndex:int;
      
      private var _writeIndex:int;
      
      public function QuadTreePairManager(param1:IPairHandler, param2:QuadTree)
      {
         super();
         this._callback = param1;
         this._quadTree = param2;
         this._pairTable = new Dictionary();
         var _loc3_:int = QuadTreeConstants.MAX_PAIRS;
         this._pairPool = new Vector.<QuadTreePair>(_loc3_,true);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            this._pairPool[_loc4_] = new QuadTreePair();
            _loc4_++;
         }
         this._poolMask = _loc3_ - 1;
      }
      
      public function addPair(param1:int, param2:int) : Boolean
      {
         var _loc3_:int = this.getKey(param1,param2);
         if(this._pairTable[_loc3_])
         {
            return false;
         }
         var _loc4_:QuadTreePair = this._pairPool[this._readIndex];
         this._readIndex = this._readIndex + 1 & this._poolMask;
         _loc4_.proxyId1 = param1;
         _loc4_.proxyId2 = param2;
         this._callback.handle(param1,param2);
         ++this._pairCount;
         this._pairTable[_loc3_] = _loc4_;
         return true;
      }
      
      public function removePair(param1:int, param2:int) : Boolean
      {
         var _loc3_:int = this.getKey(param1,param2);
         var _loc4_:QuadTreePair = this._pairTable[_loc3_];
         if(_loc4_ == null)
         {
            return false;
         }
         this._callback.remove(param1,param2);
         this._pairPool[this._writeIndex] = _loc4_;
         this._writeIndex = this._writeIndex + 1 & this._poolMask;
         --this._pairCount;
         delete this._pairTable[_loc3_];
         return true;
      }
      
      private function getKey(param1:int, param2:int) : int
      {
         if(param1 > param2)
         {
            return param2 << 16 | param1;
         }
         return param1 << 16 | param2;
      }
   }
}

