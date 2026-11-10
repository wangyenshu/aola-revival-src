package mmo.util.quadtree
{
   import flash.display.DisplayObject;
   import flash.geom.Point;
   
   public class QuadTreeDisplayObject
   {
      
      public var proxyId:int;
      
      public var content:DisplayObject;
      
      public var offset:Point;
      
      public function QuadTreeDisplayObject()
      {
         super();
      }
      
      public function get xmin() : Number
      {
         return this.content.x + this.offset.x;
      }
      
      public function get ymin() : Number
      {
         return this.content.y + this.offset.y;
      }
      
      public function get xmax() : Number
      {
         return this.content.x + this.content.width + this.offset.x;
      }
      
      public function get ymax() : Number
      {
         return this.content.y + this.content.height + this.offset.y;
      }
   }
}

