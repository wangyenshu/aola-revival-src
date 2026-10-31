package mmo.fbteam.configure
{
   import com.adobe.utils.ArrayUtil;
   import flash.geom.Point;
   
   public class FbWildPetConfig
   {
      
      private static const loc:Object = {
         "fbaixi1":[new Point(450,200),new Point(450,350),new Point(650,430)],
         "fbaixi2":[new Point(475,315),new Point(310,265),new Point(395,380),new Point(575,285),new Point(610,390)],
         "fbaixi3":[new Point(600,120),new Point(730,100),new Point(670,180),new Point(410,380),new Point(390,435),new Point(320,400)],
         "fbaixi6":[new Point(534,200),new Point(550,270),new Point(470,300),new Point(380,292),new Point(360,260)]
      };
      
      private static const unautoScenes:Array = ["fbaixi2","fbaixi6"];
      
      public function FbWildPetConfig()
      {
         super();
      }
      
      public static function get DEFINITION_LOC() : Object
      {
         return loc;
      }
      
      public static function get PETS_LOCATION_CLONE() : Object
      {
         var _loc2_:String = null;
         var _loc3_:Array = null;
         var _loc4_:Array = null;
         var _loc1_:Object = {};
         for(_loc2_ in loc)
         {
            _loc3_ = loc[_loc2_] as Array;
            _loc4_ = ArrayUtil.copyArray(_loc3_);
            _loc1_[_loc2_] = _loc4_;
         }
         return _loc1_;
      }
      
      public static function get UNAUTO_SCENES_CLONE() : Array
      {
         return ArrayUtil.copyArray(unautoScenes);
      }
   }
}

