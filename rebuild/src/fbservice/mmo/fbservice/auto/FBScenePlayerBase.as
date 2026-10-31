package mmo.fbservice.auto
{
   import flash.display.Sprite;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   
   public class FBScenePlayerBase
   {
      
      protected var isClicking:Boolean = false;
      
      protected var sceneInfo:SceneInfo = null;
      
      protected var playerStep:IScenePlayerStep = null;
      
      public function FBScenePlayerBase()
      {
         super();
         this.init();
      }
      
      public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
      }
      
      public function init() : void
      {
         this.sceneInfo = SceneManager.getInstance().loadedSceneInfo;
      }
      
      public function dispose() : void
      {
         throw new Error("dispose没有重写！");
      }
      
      protected function getObstruction() : Sprite
      {
         return Sprite(this.sceneInfo.scene.getChildByName("obstruction"));
      }
      
      protected function checkScene(param1:String) : Boolean
      {
         var _loc2_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         if(param1 == _loc2_)
         {
            return true;
         }
         return false;
      }
      
      protected function disposeStepPlayer() : void
      {
         if(this.playerStep != null)
         {
            this.playerStep.dispose();
         }
      }
      
      protected function movieFinish(param1:int = -1, param2:String = "") : void
      {
         FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,{
            "next":param1,
            "str":param2
         }));
      }
   }
}

