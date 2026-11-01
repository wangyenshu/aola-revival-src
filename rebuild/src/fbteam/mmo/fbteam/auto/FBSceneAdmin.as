package mmo.fbteam.auto
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.play.scene.SceneManager;
   
   public class FBSceneAdmin
   {
      
      private static var _instance:FBSceneAdmin;
      
      private var fbName:String = null;
      
      private var _key:int = 0;
      
      private var scenePlayer:FBScenePlayerBase = null;
      
      private var fbTeamService:IFBTeamService = null;
      
      private var namespace:Object = null;
      
      public function FBSceneAdmin()
      {
         super();
         _instance = this;
         this.namespace = FBConfig.instence.namespace;
      }
      
      public static function get instance() : FBSceneAdmin
      {
         if(null == _instance)
         {
            _instance = new FBSceneAdmin();
         }
         return _instance;
      }
      
      private function initService() : void
      {
         if(null == this.fbTeamService)
         {
            this.fbTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         }
      }
      
      public function updataSceneElement(param1:String, param2:Function = null, param3:Object = null) : void
      {
         if(null == param1)
         {
            return;
         }
         var _loc4_:Array = param1.split("_");
         var _loc5_:int = int(_loc4_[0].substr(2));
         if(this._key == _loc5_)
         {
            FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_BEGIN,{"movieName":param1}));
            this.scenePlayer.updataInfo(param1,param2,param3);
         }
      }
      
      public function update() : void
      {
         StepSynManager.instance.synStep(this.updateAfterSyn,this,[]);
      }
      
      private function updateAfterSyn() : void
      {
         this.initService();
         this.updatePars();
         this.updatePlayer();
      }
      
      private function updatePars() : void
      {
         this.fbName = this.fbTeamService.currentFBInfo.fbName;
         this._key = SceneHelper.getSceneKey();
         if(-1 == this._key)
         {
            throw new Error("场景命名出错");
         }
         if(null == this.fbName)
         {
            throw new Error("副本名木有更新");
         }
         if(undefined == this.namespace[this.fbName])
         {
            throw new Error("未定义命名空间");
         }
      }
      
      /**
       * REVIVAL. The art of some 幻影冰宫 rooms places a layer twice, the same symbol at two depths
       * (fbaixi4, 7, 8, 9: background; fbaixi6: overlap). The engine stacks the layers it knows by
       * name (the first of each) and the second copy ends on top of the room: over the players,
       * the 亚比 and the doors, taking their clicks (fbaixi4's 变异库斯特 and its way out were not
       * to be seen). The copy is hidden, as the engine does with a second obstruction.
       */
      private function hideLayerCopies() : void
      {
         var scene:DisplayObjectContainer = SceneManager.getInstance().loadedSceneInfo.scene as DisplayObjectContainer;
         if(scene == null)
         {
            return;
         }
         for each(var layer:String in ["background","overlap","foreground","topground"])
         {
            var first:DisplayObject = scene.getChildByName(layer);
            for(var i:int = 0; i < scene.numChildren; i++)
            {
               var copy:DisplayObject = scene.getChildAt(i);
               if(copy.name != layer || copy == first)
               {
                  continue;
               }
               copy.visible = false;
               if(copy is InteractiveObject)
               {
                  InteractiveObject(copy).mouseEnabled = false;
               }
               if(copy is DisplayObjectContainer)
               {
                  DisplayObjectContainer(copy).mouseChildren = false;
               }
            }
         }
      }
      
      private function updatePlayer() : void
      {
         try
         {
            this.hideLayerCopies();
         }
         catch(err:Error)
         {
         }
         var _loc1_:Class = FBConfig.instence.getClass(this.namespace[this.fbName] + this._key) as Class;
         if(null != this.scenePlayer)
         {
            this.scenePlayer.dispose();
         }
         this.scenePlayer = new _loc1_() as FBScenePlayerBase;
         FbSceneMovieEventDispatcher.instence.dispatchEvent(new FbSceneMovieEvent(FbSceneMovieEvent.FB_SCENE_MOVIE_PLAYER_INITED,{}));
      }
      
      public function dispose() : void
      {
         this.disposeCurrentSceneStep();
         this.scenePlayer = null;
         this._key = 0;
      }
      
      public function disposeCurrentSceneStep() : void
      {
         if(null != this.scenePlayer)
         {
            this.scenePlayer.disposeStepPlayer();
         }
      }
   }
}

