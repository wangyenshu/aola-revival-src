package mmo.util.quadtree
{
   public class QuadTreeProxy
   {
      
      public static const NULL_PROXY:int = 65535;
      
      public var id:int;
      
      public var shape:QuadTreeDisplayObject;
      
      public var overlapCount:int;
      
      public var nextInNode:QuadTreeProxy;
      
      public var prevInNode:QuadTreeProxy;
      
      public var nextInTree:QuadTreeProxy;
      
      public var prevInTree:QuadTreeProxy;
      
      public var node:QuadTreeNode;
      
      public var xl1:int;
      
      public var xl2:int;
      
      public var yl1:int;
      
      public var yl2:int;
      
      private var _next:int;
      
      public function QuadTreeProxy()
      {
         super();
      }
      
      public function remove() : void
      {
         if(this.prevInNode != null)
         {
            this.prevInNode.nextInNode = this.nextInNode;
         }
         if(this.nextInNode != null)
         {
            this.nextInNode.prevInNode = this.prevInNode;
         }
         if(this == this.node.proxyList)
         {
            this.node.proxyList = this.nextInNode;
         }
         this.prevInNode = null;
         this.nextInNode = null;
         this.node = null;
      }
      
      public function setNext(param1:int) : void
      {
         this._next = param1;
      }
      
      public function getNext() : int
      {
         return this._next;
      }
      
      public function reset() : void
      {
         this.nextInNode = null;
         this.prevInNode = null;
         this.nextInTree = null;
         this.prevInTree = null;
         this.node = null;
         this.xl1 = int.MIN_VALUE;
         this.yl1 = int.MIN_VALUE;
         this.xl2 = int.MIN_VALUE;
         this.yl2 = int.MIN_VALUE;
         this.overlapCount = 0;
         this.shape = null;
      }
   }
}

