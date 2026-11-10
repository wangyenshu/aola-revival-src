package mmo.util.quadtree
{
   public class QuadTreeNode
   {
      
      public var parent:QuadTreeNode;
      
      public var proxyList:QuadTreeProxy;
      
      public var xmin:int;
      
      public var xmax:int;
      
      public var ymin:int;
      
      public var ymax:int;
      
      public function QuadTreeNode()
      {
         super();
      }
      
      public function insert(param1:QuadTreeProxy) : void
      {
         param1.prevInNode = null;
         param1.nextInNode = this.proxyList;
         if(this.proxyList)
         {
            this.proxyList.prevInNode = param1;
         }
         this.proxyList = param1;
         param1.node = this;
      }
   }
}

