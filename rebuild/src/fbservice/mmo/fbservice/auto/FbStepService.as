package mmo.fbservice.auto
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbSceneMovieEvent;
   import mmo.interfaces.fb.FbSceneMovieEventDispatcher;
   import mmo.interfaces.fb.IFbSceneService;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.fb.IFbStepService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.LoaderContainer;
   import mmo.play.scene.SceneManager;
   
   public class FbStepService extends EventDispatcher implements IFbStepService
   {
      
      private static var hasHelloInfoShowed:Boolean = false;
      
      private var isLock:Boolean = true;
      
      private var isPause:Boolean = false;
      
      private var currentFbName:String = "";
      
      private var currentSceneName:String = "";
      
      private var step:int = -1;
      
      private var currentStepInfo:String = null;
      
      private var stepManager:FbStepManager = null;
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var fbService:IFbService = null;
      
      private var fbSceneService:IFbSceneService = null;
      
      public function FbStepService(param1:IEventDispatcher = null)
      {
         super(param1);
      }
      
      public function init() : void
      {
      }
      
      public function get pauseKey() : Boolean
      {
         return this.isPause;
      }
      
      public function set pauseKey(param1:Boolean) : void
      {
         this.isPause = param1;
      }
      
      public function get lock() : Boolean
      {
         return this.isLock;
      }
      
      public function set lock(param1:Boolean) : void
      {
         if(this.isLock == param1)
         {
            return;
         }
         this.isLock = param1;
         if(this.isLock)
         {
            this.release();
         }
         else
         {
            this.taskNpcService = ServiceContainer.getService("TaskNpcService") as ITaskNpcService;
            this.fbService = ServiceContainer.getService(IFbService) as IFbService;
            this.fbSceneService = ServiceContainer.getService("FbSceneService") as IFbSceneService;
            TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
            FbSceneMovieEventDispatcher.instence.addEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_PLAYER_INITED,this.onSceneMoviePlayerInited);
            FbSceneMovieEventDispatcher.instence.addEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,this.onSceneMovieStop);
         }
      }
      
      private function release() : void
      {
         hasHelloInfoShowed = false;
         this.step = -1;
         this.currentFbName = null;
         this.currentSceneName = null;
         this.currentStepInfo = null;
         this.stepManager = null;
         this.fbService = null;
         this.taskNpcService = null;
         this.fbSceneService = null;
         FbSceneMovieEventDispatcher.instence.removeEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_PLAYER_INITED,this.onSceneMoviePlayerInited);
         FbSceneMovieEventDispatcher.instence.removeEventListener(FbSceneMovieEvent.FB_SCENE_MOVIE_EVENT_END,this.onSceneMovieStop);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
      }
      
      private function dataInit() : void
      {
         this.step = 0;
         this.stepManager = FbStepManager.instence;
         this.currentFbName = this.fbService.currentFbName;
         this.currentSceneName = SceneManager.getInstance().loadedSceneInfo.sceneName;
         this.currentStepInfo = this.stepManager.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
      }
      
      private function onSceneMoviePlayerInited(param1:FbSceneMovieEvent) : void
      {
         this.dataInit();
         if(FBHelloTalkMap.instence.checkCanHelloTalk())
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
         else
         {
            this.onStepFun();
         }
      }
      
      private function onSceneMovieStop(param1:FbSceneMovieEvent) : void
      {
         var onEnterFrame:Function = null;
         var e:FbSceneMovieEvent = param1;
         onEnterFrame = function(param1:Event):void
         {
            LoaderContainer.instance.removeEventListener(Event.ENTER_FRAME,onEnterFrame);
            onStepStart(e);
         };
         LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,onEnterFrame);
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
         if(this.isLock || this.isPause)
         {
            return;
         }
         var _loc1_:Array = this.currentStepInfo.split(":");
         switch(_loc1_[0])
         {
            case "talk":
               this.taskNpcService.showNpcPanelFreely(_loc1_[1],1);
               break;
            case "movie":
               this.fbSceneService.updataSceneElement(_loc1_[1],true);
               break;
            default:
               NewDialog.showFailMessage("打错字：" + _loc1_[0]);
         }
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         var _loc4_:IPetFight = null;
         var _loc2_:String = param1.params.action;
         if("fb_hellotalk_end" == _loc2_)
         {
            this.onStepFun();
            return;
         }
         if(_loc2_.indexOf("nextStep") != -1)
         {
            this.nextStep();
            return;
         }
         var _loc3_:Array = null;
         if(_loc2_.indexOf("disable:") != -1)
         {
            _loc3_ = _loc2_.split(":");
            this.fbSceneService.updataSceneElement(_loc3_[1],false);
            return;
         }
         if(_loc2_.indexOf("jumpStep:") != -1)
         {
            _loc3_ = _loc2_.split(":");
            this.jumpStep(_loc3_[1]);
            return;
         }
         if(_loc2_.indexOf("fight:") != -1)
         {
            _loc3_ = _loc2_.split(":");
            _loc4_ = ServiceContainer.getService(IPetFight) as IPetFight;
            _loc4_.fightInCopy(_loc3_[2]);
            return;
         }
      }
      
      public function get currentStep() : int
      {
         return this.step;
      }
      
      public function nextStep() : void
      {
         ++this.step;
         this.currentStepInfo = this.stepManager.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
         this.onStepFun();
      }
      
      public function jumpStep(param1:int) : void
      {
         this.step = param1;
         this.currentStepInfo = this.stepManager.getCurrentStepInfo(this.currentFbName,this.currentSceneName,this.step);
         this.onStepFun();
      }
      
      public function pause() : void
      {
         this.isPause = true;
      }
      
      public function play() : void
      {
         this.isPause = false;
         this.onStepFun();
      }
      
      public function dispose() : void
      {
      }
      
      public function helloTalkReset() : void
      {
         hasHelloInfoShowed = false;
      }
   }
}

