package mmo.util.quadtree
{
   import flash.geom.Rectangle;
   import flash.system.System;
   import mmo.util.quadtree.pair.IPairHandler;
   import mmo.util.quadtree.pair.QuadTreePairManager;
   
   public class QuadTree
   {
      
      private var _nodes:Vector.<QuadTreeNode>;
      
      private var _offsets:Vector.<int>;
      
      private var _depth:int;
      
      private var _xScale:Number;
      
      private var _yScale:Number;
      
      private var _xmin:Number;
      
      private var _xmax:Number;
      
      private var _ymin:Number;
      
      private var _ymax:Number;
      
      private var _xOffset:Number;
      
      private var _yOffset:Number;
      
      private var _proxyList:QuadTreeProxy;
      
      private var _proxyPool:Vector.<QuadTreeProxy>;
      
      private var _freeProxy:int;
      
      private var _pairManager:QuadTreePairManager;
      
      private var _proxyCount:int;
      
      public function QuadTree(param1:int)
      {
         super();
         this._depth = param1;
      }
      
      public function deconstruct() : void
      {
         var _loc1_:QuadTreeProxy = null;
         var _loc2_:QuadTreeProxy = null;
         var _loc5_:QuadTreeNode = null;
         var _loc3_:int = int(this._nodes.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc5_ = this._nodes[_loc4_];
            _loc5_.parent = null;
            _loc2_ = _loc5_.proxyList;
            while(_loc2_ != null)
            {
               _loc1_ = _loc2_;
               _loc2_ = _loc2_.nextInNode;
               _loc1_.prevInNode = null;
               _loc1_.nextInNode = null;
            }
            _loc4_++;
         }
         _loc2_ = this._proxyList;
         while(_loc2_ != null)
         {
            _loc1_ = _loc2_;
            _loc2_ = _loc2_.nextInTree;
            _loc1_.nextInTree = null;
            _loc1_.prevInTree = null;
            _loc1_.shape = null;
         }
         this._proxyList = null;
         this._proxyPool = null;
         this._pairManager = null;
      }
      
      public function init(param1:Rectangle) : void
      {
         this._xmin = param1.x;
         this._ymin = param1.y;
         this._xmax = param1.x + param1.width;
         this._ymax = param1.y + param1.height;
         var _loc2_:int = this._xmax - this._xmin;
         var _loc3_:int = this._ymax - this._ymin;
         this._xOffset = this._xmin < 0 ? -this._xmin : 0;
         this._yOffset = this._ymin < 0 ? -this._ymin : 0;
         this.initialize(_loc2_,_loc3_);
      }
      
      public function setPairHandler(param1:IPairHandler) : void
      {
         this._pairManager = new QuadTreePairManager(param1,this);
      }
      
      public function createProxy(param1:QuadTreeDisplayObject) : int
      {
         var _loc2_:int = this._freeProxy;
         var _loc3_:QuadTreeProxy = this._proxyPool[_loc2_];
         this._freeProxy = _loc3_.getNext();
         _loc3_.shape = param1;
         _loc3_.nextInTree = this._proxyList;
         if(this._proxyList)
         {
            this._proxyList.prevInTree = _loc3_;
         }
         this._proxyList = _loc3_;
         _loc3_.xl1 = int.MIN_VALUE;
         _loc3_.yl1 = int.MIN_VALUE;
         _loc3_.xl2 = int.MIN_VALUE;
         _loc3_.yl2 = int.MIN_VALUE;
         _loc3_.shape = param1;
         this.getNodeContaining(_loc3_.id).insert(_loc3_);
         ++this._proxyCount;
         return _loc2_;
      }
      
      public function destroyProxy(param1:int) : void
      {
         var _loc3_:QuadTreeProxy = null;
         var _loc5_:QuadTreeDisplayObject = null;
         if(param1 == QuadTreeProxy.NULL_PROXY)
         {
            return;
         }
         var _loc2_:QuadTreeProxy = this._proxyPool[param1];
         var _loc4_:QuadTreeDisplayObject = _loc2_.shape;
         var _loc6_:Number = _loc4_.xmin;
         var _loc7_:Number = _loc4_.xmax;
         var _loc8_:Number = _loc4_.ymin;
         var _loc9_:Number = _loc4_.ymax;
         _loc3_ = this._proxyList;
         while(_loc3_ != null)
         {
            if(_loc2_ == _loc3_)
            {
               _loc3_ = _loc3_.nextInTree;
            }
            else
            {
               _loc5_ = _loc3_.shape;
               if(_loc6_ > _loc5_.xmax || _loc7_ < _loc5_.xmin || _loc8_ > _loc5_.ymax || _loc9_ < _loc5_.ymin)
               {
                  _loc3_ = _loc3_.nextInTree;
               }
               else
               {
                  if(this._pairManager.removePair(_loc2_.id,_loc3_.id))
                  {
                     --_loc3_.overlapCount;
                  }
                  _loc3_ = _loc3_.nextInTree;
               }
            }
         }
         _loc2_.remove();
         if(_loc2_.prevInTree)
         {
            _loc2_.prevInTree.nextInTree = _loc2_.nextInTree;
         }
         if(_loc2_.nextInTree)
         {
            _loc2_.nextInTree.prevInTree = _loc2_.prevInTree;
         }
         if(_loc2_ == this._proxyList)
         {
            this._proxyList = _loc2_.nextInTree;
         }
         _loc2_.setNext(this._freeProxy);
         this._freeProxy = param1;
         _loc2_.reset();
         --this._proxyCount;
      }
      
      public function moveProxy(param1:int) : void
      {
         var _loc2_:QuadTreeProxy = this._proxyPool[param1];
         var _loc3_:QuadTreeDisplayObject = _loc2_.shape;
         var _loc4_:int = _loc3_.xmin;
         var _loc5_:int = _loc3_.ymin;
         if(_loc2_.xl1 == _loc4_ && _loc2_.yl1 == _loc5_)
         {
            return;
         }
         _loc2_.xl1 = _loc4_;
         _loc2_.yl1 = _loc5_;
         var _loc6_:int = (_loc3_.xmin + this._xOffset) * this._xScale;
         var _loc7_:int = (_loc3_.ymin + this._yOffset) * this._yScale;
         var _loc8_:int = _loc6_ ^ int((_loc3_.xmax + this._xOffset) * this._xScale);
         var _loc9_:int = _loc7_ ^ int((_loc3_.ymax + this._yOffset) * this._yScale);
         var _loc10_:* = this._depth;
         while(_loc8_ + _loc9_ != 0)
         {
            _loc8_ >>= 1;
            _loc9_ >>= 1;
            _loc10_--;
         }
         var _loc11_:int = this._depth - _loc10_;
         _loc6_ >>= _loc11_;
         _loc7_ >>= _loc11_;
         if(_loc6_ == _loc2_.xl2 && _loc7_ == _loc2_.yl2)
         {
            return;
         }
         _loc2_.xl2 = _loc6_;
         _loc2_.yl2 = _loc7_;
         _loc2_.remove();
         var _loc12_:QuadTreeNode = _loc2_.node = this._nodes[int(this._offsets[_loc10_] + (_loc7_ << _loc10_ - 1) + _loc6_)];
         _loc12_.insert(_loc2_);
      }
      
      public function findParisByProxyId(param1:int) : void
      {
         var _loc2_:QuadTreeProxy = this.getProxy(param1);
         this.findParisForCustomProxy(_loc2_);
      }
      
      public function findPairs() : void
      {
         var _loc1_:QuadTreeProxy = this._proxyList;
         while(_loc1_ != null)
         {
            this.findParisForCustomProxy(_loc1_);
            _loc1_ = _loc1_.nextInTree;
         }
      }
      
      public function getNodeLevel(param1:QuadTreeProxy) : int
      {
         var _loc2_:QuadTreeDisplayObject = param1.shape;
         var _loc3_:int = int(_loc2_.xmin * this._xScale + this._xOffset) ^ int(_loc2_.xmax * this._xScale + this._xOffset);
         var _loc4_:int = int(_loc2_.ymin * this._yScale + this._yOffset) ^ int(_loc2_.ymax * this._yScale + this._yOffset);
         var _loc5_:* = this._depth;
         while(_loc3_ + _loc4_ != 0)
         {
            _loc3_ >>= 1;
            _loc4_ >>= 1;
            _loc5_--;
         }
         return _loc5_;
      }
      
      public function getNodeContaining(param1:int) : QuadTreeNode
      {
         var _loc2_:QuadTreeProxy = this._proxyPool[param1];
         var _loc3_:QuadTreeDisplayObject = _loc2_.shape;
         var _loc4_:int = (_loc3_.xmin + this._xOffset) * this._xScale;
         var _loc5_:int = (_loc3_.ymin + this._yOffset) * this._yScale;
         var _loc6_:int = (_loc3_.xmax + this._xOffset) * this._xScale;
         var _loc7_:int = (_loc3_.ymax + this._yOffset) * this._yScale;
         var _loc8_:int = _loc4_ ^ _loc6_;
         var _loc9_:int = _loc5_ ^ _loc7_;
         var _loc10_:* = this._depth;
         while(_loc8_ > 0 || _loc9_ > 0)
         {
            _loc8_ >>= 1;
            _loc9_ >>= 1;
            _loc10_--;
         }
         var _loc11_:int = this._depth - _loc10_;
         _loc4_ >>= _loc11_;
         _loc5_ >>= _loc11_;
         return this._nodes[int(this._offsets[_loc10_] + (_loc5_ << _loc10_ - 1) + _loc4_)];
      }
      
      public function getProxy(param1:int) : QuadTreeProxy
      {
         return this._proxyPool[param1];
      }
      
      public function getProxyList() : Vector.<QuadTreeProxy>
      {
         var _loc2_:* = 0;
         var _loc1_:Vector.<QuadTreeProxy> = new Vector.<QuadTreeProxy>(this._proxyCount,true);
         var _loc3_:QuadTreeProxy = this._proxyList;
         while(_loc3_ != null)
         {
            var _loc4_:Number;
            _loc1_[_loc4_ = _loc2_++] = _loc3_;
            _loc3_ = _loc3_.nextInTree;
         }
         return _loc1_;
      }
      
      private function initialize(param1:int, param2:int) : void
      {
         var _loc4_:* = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:QuadTreeNode = null;
         var _loc15_:QuadTreeProxy = null;
         var _loc3_:uint = System.totalMemory;
         _loc9_ = 1 << this._depth - 1;
         this._xScale = _loc9_ / param1;
         this._yScale = _loc9_ / param2;
         _loc4_ = 0;
         _loc11_ = -1;
         while(_loc4_ < this._depth)
         {
            _loc11_ += 1 << (_loc4_ << 1);
            _loc4_++;
         }
         _loc4_ = int(_loc11_ + 1);
         this._nodes = new Vector.<QuadTreeNode>(_loc4_,true);
         this._offsets = new Vector.<int>(this._depth + 1,true);
         this._offsets[0] = -1;
         _loc11_ = -1;
         _loc4_ = 0;
         while(_loc4_ < this._depth)
         {
            _loc10_ = 1 << _loc4_;
            this._offsets[int(_loc4_ + 1)] = _loc11_ + 1;
            _loc7_ = _loc8_ = _loc9_ >> _loc4_;
            _loc7_ = _loc7_ * (param1 / _loc9_);
            _loc8_ *= param2 / _loc9_;
            _loc6_ = 0;
            while(_loc6_ < _loc10_)
            {
               _loc5_ = 0;
               while(_loc5_ < _loc10_)
               {
                  _loc13_ = new QuadTreeNode();
                  _loc13_.xmin = _loc5_ * _loc7_ + this._xmin;
                  _loc13_.ymin = _loc6_ * _loc8_ + this._ymin;
                  _loc13_.xmax = _loc13_.xmin + _loc7_;
                  _loc13_.ymax = _loc13_.ymin + _loc8_;
                  this._nodes[int(_loc11_ + 1 + (_loc6_ * _loc10_ + _loc5_))] = _loc13_;
                  _loc5_++;
               }
               _loc6_++;
            }
            _loc11_ += 1 << (_loc4_ << 1);
            _loc4_++;
         }
         _loc4_ = this._depth;
         while(_loc4_ > 1)
         {
            _loc10_ = 1 << _loc4_ - 1;
            _loc11_ = this._offsets[_loc4_];
            _loc12_ = this._offsets[int(_loc4_ - 1)];
            _loc6_ = 0;
            while(_loc6_ < _loc10_)
            {
               _loc5_ = 0;
               while(_loc5_ < _loc10_)
               {
                  this._nodes[int(_loc11_ + _loc6_ * _loc10_ + _loc5_)].parent = this._nodes[int(_loc12_ + (_loc6_ >> 1) * (_loc10_ >> 1) + (_loc5_ >> 1))];
                  _loc5_++;
               }
               _loc6_++;
            }
            _loc4_--;
         }
         var _loc14_:int = QuadTreeConstants.MAX_PROXIES;
         this._proxyPool = new Vector.<QuadTreeProxy>(_loc14_,true);
         _loc4_ = 0;
         while(_loc4_ < _loc14_ - 1)
         {
            _loc15_ = new QuadTreeProxy();
            _loc15_.id = _loc4_;
            _loc15_.setNext(_loc4_ + 1);
            this._proxyPool[_loc4_] = _loc15_;
            _loc4_++;
         }
         _loc15_ = new QuadTreeProxy();
         _loc15_.setNext(QuadTreeProxy.NULL_PROXY);
         _loc15_.id = _loc14_ - 1;
         this._proxyPool[_loc14_ - 1] = _loc15_;
         this._freeProxy = 0;
      }
      
      private function findParisForCustomProxy(param1:QuadTreeProxy) : void
      {
         var _loc2_:QuadTreeNode = null;
         var _loc4_:QuadTreeProxy = null;
         var _loc5_:QuadTreeDisplayObject = null;
         var _loc6_:QuadTreeDisplayObject = null;
         var _loc3_:QuadTreeProxy = param1;
         _loc5_ = _loc3_.shape;
         _loc4_ = _loc3_.nextInNode;
         while(_loc4_ != null)
         {
            _loc6_ = _loc4_.shape;
            if(_loc5_.xmin > _loc6_.xmax || _loc5_.xmax < _loc6_.xmin || _loc5_.ymin > _loc6_.ymax || _loc5_.ymax < _loc6_.ymin)
            {
               if((_loc3_.overlapCount | _loc4_.overlapCount) > 0)
               {
                  if(this._pairManager.removePair(_loc3_.id,_loc4_.id))
                  {
                     --_loc3_.overlapCount;
                     --_loc4_.overlapCount;
                  }
               }
            }
            else if(this._pairManager.addPair(_loc3_.id,_loc4_.id))
            {
               ++_loc3_.overlapCount;
               ++_loc4_.overlapCount;
            }
            _loc4_ = _loc4_.nextInNode;
         }
         _loc2_ = _loc3_.node.parent;
         while(_loc2_ != null)
         {
            _loc4_ = _loc2_.proxyList;
            while(_loc4_ != null)
            {
               _loc6_ = _loc4_.shape;
               if(_loc5_.xmin > _loc6_.xmax || _loc5_.xmax < _loc6_.xmin || _loc5_.ymin > _loc6_.ymax || _loc5_.ymax < _loc6_.ymin)
               {
                  if((_loc3_.overlapCount | _loc4_.overlapCount) > 0)
                  {
                     if(this._pairManager.removePair(_loc3_.id,_loc4_.id))
                     {
                        --_loc3_.overlapCount;
                        --_loc4_.overlapCount;
                     }
                  }
               }
               else if(this._pairManager.addPair(_loc3_.id,_loc4_.id))
               {
                  ++_loc3_.overlapCount;
                  ++_loc4_.overlapCount;
               }
               _loc4_ = _loc4_.nextInNode;
            }
            _loc2_ = _loc2_.parent;
         }
      }
   }
}

