package mmo.fbteam.common
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.loader.layer.LayerManager;
   
   public class HitObjectHelper
   {
      
      public function HitObjectHelper()
      {
         super();
      }
      
      public static function hitTestObject(param1:Sprite, param2:Point) : Boolean
      {
         if(null == param1)
         {
            return false;
         }
         param2.y = LayerManager.getCurrentLayer() == LayerManager.FIGHTING_LAYER ? param2.y + 1000 : param2.y;
         return param1.hitTestPoint(param2.x,param2.y,true);
      }
   }
}

