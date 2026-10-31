package mmo.fbservice
{
   import flash.geom.Point;
   
   public class FbWildPetLocationMap
   {
      
      private static var _instance:FbWildPetLocationMap;
      
      private var loc:Array = [];
      
      public function FbWildPetLocationMap()
      {
         super();
         this.loc["fbaixi1"] = [new Point(610,190),new Point(410,340),new Point(610,385)];
         this.loc["fbaixi2"] = [new Point(475,315),new Point(310,265),new Point(395,380),new Point(575,285),new Point(610,390)];
         this.loc["fbaixi3"] = [new Point(600,120),new Point(730,100),new Point(670,180),new Point(410,380),new Point(390,435),new Point(320,400)];
         this.loc["fbaixi6"] = [new Point(534,200),new Point(550,270),new Point(470,300),new Point(380,292),new Point(360,260)];
      }
      
      public static function get instance() : FbWildPetLocationMap
      {
         if(_instance == null)
         {
            _instance = new FbWildPetLocationMap();
         }
         return _instance;
      }
      
      public function getLocation(param1:String) : Array
      {
         return this.loc[param1];
      }
   }
}

