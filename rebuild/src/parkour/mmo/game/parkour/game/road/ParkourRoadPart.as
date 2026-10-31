package mmo.game.parkour.game.road
{
   import flash.display.MovieClip;
   import flash.geom.Rectangle;
   import mmo.game.parkour.game.data.mapitem.ParkourRoadInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public class ParkourRoadPart extends ParkourAbstractMapItem
   {
      
      public static const Location_Head:int = 0;
      
      public static const Location_Middle:int = 1;
      
      public static const Location_End:int = 2;
      
      public static const Location_Single:int = 3;
      
      private static const RoadDatas:Object = {};
      
      private static const Empty:uint = 16777215;
      
      private var location:int;
      
      public function ParkourRoadPart(param1:ParkourRoadInfo, param2:MovieClip)
      {
         super(param1,param2);
      }
      
      public function get width() : Number
      {
         return view.width;
      }
      
      public function setLocation(param1:int) : void
      {
         this.location = param1;
         (this.view as MovieClip).gotoAndStop(param1 + 1);
      }
      
      public function isInThisRoad(param1:int) : Boolean
      {
         var _loc2_:Rectangle = getRect();
         return param1 >= _loc2_.left && param1 < _loc2_.right;
      }
      
      public function getRoadTop() : int
      {
         return getRect().top + 3;
      }
   }
}

