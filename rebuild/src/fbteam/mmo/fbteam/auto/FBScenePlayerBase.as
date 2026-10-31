package mmo.fbteam.auto
{
   import flash.display.Sprite;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.play.scene.SceneManager;
   
   public class FBScenePlayerBase
   {
      
      protected var isClicking:Boolean = false;
      
      protected var playerStep:IScenePlayerStep = null;
      
      protected var type:String = "";
      
      public function FBScenePlayerBase()
      {
         super();
         this.init();
      }
      
      public function updataInfo(param1:String, param2:Function = null, param3:Object = null) : void
      {
      }
      
      public function init() : void
      {
      }
      
      public function dispose() : void
      {
         throw new Error("dispose没有重写！");
      }
      
      protected function getObstruction() : Sprite
      {
         return Sprite(SceneManager.getInstance().loadedSceneInfo.scene.getChildByName("obstruction"));
      }
      
      public function disposeStepPlayer() : void
      {
         if(this.playerStep != null)
         {
            this.playerStep.dispose();
            this.playerStep = null;
         }
      }
      
      protected function currentMovieFinish(param1:int = -1, param2:String = null) : void
      {
         if(null != param2)
         {
            this.type = param2;
         }
         FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,{
            "next":param1,
            "movieName":this.type
         }));
      }
   }
}

