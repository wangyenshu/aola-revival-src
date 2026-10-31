package mmo.fbteam.auto
{
   import flash.events.Event;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.loader.LoaderContainer;
   import mmo.play.scene.SceneManager;
   
   public class FBStepAdmin
   {
      
      private static var _instance:FBStepAdmin;
      
      private static var hasHelloInfoShowed:Boolean = false;
      
      public var isPause:Boolean = false;
      
      public var step:int = -1;
      
      private var isRunning:Boolean = false;
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var fbTeamService:IFBTeamService = null;
      
      private var fbSceneAdmin:FBSceneAdmin = null;
      
      private var currentFbName:String = null;
      
      private var currentSceneName:String = null;
      
      private var currentStepInfo:String = null;
      
      public function FBStepAdmin()
      {
         super();
         _instance = this;
      }
      
      public static function get instance() : FBStepAdmin
      {
         if(null == _instance)
         {
            _instance = new FBStepAdmin();
         }
         return _instance;
      }
      
      public function run() : void
      {
         this.isRunning = true;
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         this.fbTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         this.fbSceneAdmin = FBSceneAdmin.instance;
         FbSceneMovieEventDispatcher.instence.addEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_PLAYER_INITED,this.onSceneMoviePlayerInited);
         FbSceneMovieEventDispatcher.instence.addEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,this.onSceneMovieStop);
         StepSynManager.instance.init();
      }
      
      public function stop() : void
      {
         this.isRunning = false;
         this.taskNpcService = null;
         this.fbTeamService = null;
         FbSceneMovieEventDispatcher.instence.removeEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,this.onSceneMovieStop);
         FbSceneMovieEventDispatcher.instence.removeEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_PLAYER_INITED,this.onSceneMoviePlayerInited);
         StepSynManager.instance.dispose();
      }
      
      public function pause() : void
      {
         if(!this.isRunning || this.isPause)
         {
            return;
         }
         this.isPause = true;
      }
      
      public function play() : void
      {
         if(!this.isRunning || !this.isPause)
         {
            return;
         }
         this.isPause = false;
         this.onStepFun();
      }
      
      private function dataInit() : void
      {
         this.step = 0;
         this.currentFbName = this.fbTeamService.currentFBInfo.fbName;
         this.currentSceneName = SceneManager.getInstance().loadedSceneInfo.sceneName;
         this.currentStepInfo = FBConfig.instence.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
      }
      
      private function onStepStart(param1:FbSceneMovieEvent) : void
      {
         var _loc2_:int = int(param1.pars.next);
         if(-1 == _loc2_)
         {
            this.nextStep();
         }
         else
         {
            this.jumpStep(_loc2_);
         }
      }
      
      private function onStepFun() : void
      {
         if(null == this.currentStepInfo || this.currentStepInfo == "")
         {
            return;
         }
         if(!this.isRunning || this.isPause)
         {
            return;
         }
         this.currentStepInfo = FBConfig.instence.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
         var _loc1_:Array = this.currentStepInfo.split(":");
         switch(_loc1_[0])
         {
            case "talk":
               if(TeamHelper.isCaptain())
               {
                  this.taskNpcService.showNpcPanelFreely(_loc1_[1],1);
               }
               if(_loc1_.length >= 3 && _loc1_[2] == "stop")
               {
                  return;
               }
               this.nextStep();
               break;
            case "movie":
               this.fbSceneAdmin.updataSceneElement(_loc1_[1]);
               break;
            default:
               NewDialog.showFailMessage("打错字：" + _loc1_[0]);
         }
      }
      
      private function onSceneMoviePlayerInited(param1:FbSceneMovieEvent) : void
      {
         this.dataInit();
         if(FBConfig.instence.checkCanHelloTalk())
         {
            if(MemberManager.instance.isMember())
            {
               this.taskNpcService.showNpcPanelFreely("1_member_hello_talk",1);
            }
            else
            {
               this.taskNpcService.showNpcPanelFreely("1_notmember_hello_talk",1);
            }
         }
         this.onStepFun();
      }
      
      private function onSceneMovieStop(param1:FbSceneMovieEvent) : void
      {
         var thisObj:Object = null;
         var onEnterFrame:Function = null;
         var e:FbSceneMovieEvent = param1;
         this.fbSceneAdmin.disposeCurrentSceneStep();
         thisObj = this;
         onEnterFrame = function(param1:Event):void
         {
            LoaderContainer.instance.removeEventListener(Event.ENTER_FRAME,onEnterFrame);
            StepSynManager.instance.synStep(onStepStart,thisObj,[e]);
         };
         LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,onEnterFrame);
      }
      
      public function nextStep() : void
      {
         ++this.step;
         this.currentStepInfo = FBConfig.instence.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
         this.onStepFun();
      }
      
      public function jumpStep(param1:int) : void
      {
         this.step = param1;
         this.currentStepInfo = FBConfig.instence.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
         this.onStepFun();
      }
   }
}

