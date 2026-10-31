package mmo.spacetime.common
{
   import mmo.play.scene.SceneManager;
   
   public class JumpSceneHelper
   {
      
      public function JumpSceneHelper()
      {
         super();
      }
      
      public static function loadNextScene(param1:Boolean, param2:String) : void
      {
         var _loc3_:String = null;
         if(param1)
         {
            _loc3_ = ConstType.CASE_SCENE;
         }
         else
         {
            _loc3_ = SceneManager.getInstance().loadedSceneInfo.sceneName != ConstType.COMMON_SCENE1 ? ConstType.COMMON_SCENE1 : ConstType.COMMON_SCENE2;
         }
         SceneManager.getInstance().loadTempScene(_loc3_,ConstType.FB_NAME,param2,TeamHelper.getTeamKey());
      }
      
      public static function loadPreviousScene() : void
      {
         SceneManager.getInstance().loadPreviousScene();
      }
   }
}

