package mmo.fbservice.auto
{
   import flash.events.EventDispatcher;
   import flash.utils.getDefinitionByName;
   import mmo.fbservice.fbsuolide.fbsceneplayer.*;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.interfaces.fb.IFbSceneService;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.fb.IFbStepService;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   public class FbSceneService extends EventDispatcher implements IFbSceneService
   {
      
      private static const namespace:Object = {
         "fbsuolide":"mmo.fbservice.fbsuolide.fbsceneplayer.SuolideScenePlayer",
         "fbsiwude":"mmo.fbservice.fbsiwude.fbsceneplayer.SiwudeScenePlayer"
      };
      
      private var _taskMode:Boolean = false;
      
      private var _difficulty:int = 0;
      
      private var fbName:String = null;
      
      private var sceneName:String = null;
      
      private var _key:int = 0;
      
      private var fbService:IFbService = null;
      
      private var scenePlayer:FBScenePlayerBase = null;
      
      public function FbSceneService()
      {
         super();
      }
      
      public function get taskMode() : Boolean
      {
         return this._taskMode;
      }
      
      public function set taskMode(param1:Boolean) : void
      {
         this._taskMode = param1;
         var _loc2_:IFbStepService = ServiceContainer.getService("FbStepService") as IFbStepService;
         if(this._taskMode)
         {
            this.difficulty = 0;
            _loc2_.lock = true;
         }
         else
         {
            _loc2_.lock = false;
         }
         this.init();
      }
      
      public function init() : void
      {
         this.fbService = ServiceContainer.getService(IFbService) as IFbService;
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
      }
      
      private function onSceneInited(param1:SceneManagerEvent) : void
      {
         var _loc2_:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if(!this.fbService.isInFb || !_loc2_.isFB)
         {
            this.dispose();
            return;
         }
         this.updataPars();
         if("fbaixi" == this.fbName)
         {
            this.dispose();
            return;
         }
         this.updataPlayer();
      }
      
      private function updataPars() : void
      {
         this.fbName = this.fbService.currentFbName;
         this.sceneName = SceneManager.getInstance().loadedSceneInfo.sceneName;
         this._key = this.getSceneKey();
         if(-1 == this._key)
         {
            throw new Error("场景命名出错");
         }
         if(undefined == namespace[this.fbName])
         {
            throw new Error("未定义命名空间");
         }
      }
      
      private function updataPlayer() : void
      {
         var _loc1_:Class = getDefinitionByName(namespace[this.fbName] + this._key) as Class;
         if(null != this.scenePlayer)
         {
            this.scenePlayer.dispose();
         }
         this.scenePlayer = new _loc1_() as FBScenePlayerBase;
         FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_PLAYER_INITED,{}));
      }
      
      private function getSceneKey() : int
      {
         var _loc2_:Number = NaN;
         var _loc1_:int = 0;
         while(_loc1_ < this.sceneName.length)
         {
            _loc2_ = this.sceneName.charCodeAt(_loc1_);
            if(_loc2_ >= 48 && _loc2_ <= 57)
            {
               return int(this.sceneName.substring(_loc1_));
            }
            _loc1_++;
         }
         return -1;
      }
      
      public function get difficulty() : int
      {
         return this._difficulty;
      }
      
      public function set difficulty(param1:int) : void
      {
         if(!this._taskMode)
         {
            this._difficulty = param1;
         }
      }
      
      public function updataSceneElement(param1:String, param2:Boolean = true, param3:Function = null, param4:Object = null) : void
      {
         if(null == param1)
         {
            return;
         }
         var _loc5_:Array = param1.split("_");
         var _loc6_:int = int(_loc5_[0].substr(2));
         if(this._key == _loc6_)
         {
            FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_BEGIN,{"movieName":param1}));
            this.scenePlayer.updataInfo(param1,param2,param3,param4);
         }
      }
      
      public function dispose() : void
      {
         if(null != this.scenePlayer)
         {
            this.scenePlayer.dispose();
         }
         this.scenePlayer = null;
         this._key = 0;
         this.fbService = null;
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
      }
      
      private function compileme() : void
      {
         var _loc1_:ScenePlayerList = null;
      }
   }
}

