package mmo.fbteam.common
{
   import flash.display.Sprite;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   
   public class SceneHelper
   {
      
      private static const stageW:int = 960;
      
      private static const stageH:int = 560;
      
      private static var transparency:Sprite = null;
      
      private static var isLocking:Boolean = false;
      
      public function SceneHelper()
      {
         super();
      }
      
      public static function lockScene(param1:Number = 0.01) : void
      {
         if(isLocking)
         {
            return;
         }
         if(null == transparency)
         {
            transparency = new Sprite();
            transparency.graphics.beginFill(16777215,param1);
            transparency.graphics.drawRect(0,0,stageW,stageH);
            transparency.graphics.endFill();
         }
         LayerManager.getBaseTop().addChild(transparency);
      }
      
      public static function unlockScene() : void
      {
         if(isLocking)
         {
            LayerManager.getBaseTop().removeChild(transparency);
         }
      }
      
      public static function getSceneKey() : int
      {
         var _loc3_:Number = NaN;
         var _loc1_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_.length)
         {
            _loc3_ = _loc1_.charCodeAt(_loc2_);
            if(_loc3_ >= 48 && _loc3_ <= 57)
            {
               return int(_loc1_.substring(_loc2_));
            }
            _loc2_++;
         }
         return -1;
      }
      
      public static function checkScene(param1:String) : Boolean
      {
         var _loc2_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         if(param1 == _loc2_)
         {
            return true;
         }
         return false;
      }
   }
}

