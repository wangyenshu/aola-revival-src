package mmo.fbteam.service
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.FBSceneAdmin;
   import mmo.fbteam.auto.FBStepAdmin;
   import mmo.fbteam.common.BonusPraiseHelper;
   import mmo.fbteam.common.FBButtonManager;
   import mmo.fbteam.common.FBCommonHelper;
   import mmo.fbteam.common.FbWildPetManager;
   import mmo.fbteam.common.TalkHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.dataobject.FBDataObject;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fbteam.IFBLoaderService;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.fly.IFlyService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamServiceEvent;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   public class FBTeamService extends EventDispatcher implements IFBTeamService
   {
      
      private var sceneAdmin:FBSceneAdmin = FBSceneAdmin.instance;
      
      private var stepAdmin:FBStepAdmin = FBStepAdmin.instance;
      
      private var _isRunning:Boolean = false;
      
      private var _currentFBInfo:Object = new FBDataObject();
      
      private var fbLoaderService:IFBLoaderService = null;
      
      private var flyService:IFlyService = null;
      
      private var teamService:ITeamService = null;
      
      private var ipf:IPetFight = null;
      
      private var canFight:Boolean = false;
      
      public function FBTeamService(param1:IEventDispatcher = null)
      {
         super(param1);
         this.fbLoaderService = ServiceContainer.getService(IFBLoaderService) as IFBLoaderService;
         this.flyService = ServiceContainer.getService(IFlyService) as IFlyService;
         this.teamService = ServiceContainer.getService(ITeamService) as ITeamService;
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function get isRunning() : Boolean
      {
         return this._isRunning;
      }
      
      public function set currentFBInfo(param1:Object) : void
      {
         this._currentFBInfo.setPar(param1);
      }
      
      public function get currentFBInfo() : Object
      {
         return this._currentFBInfo;
      }
      
      public function init() : void
      {
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited,{}));
      }
      
      public function startup() : void
      {
         this._isRunning = true;
         if(this.flyService != null)
         {
            this.flyService.banFly("奥拉战记的地形非常复杂，在这里不能飞行哦！");
            this.flyService.land(true);
         }
         // REVIVAL: isRideInFlyingState and banneRideFly are later IRideService methods.
         var _loc1_:Object = ServiceContainer.getService(IRideService);
         try
         {
            if(_loc1_ != null && _loc1_.hasOwnProperty("isRideInFlyingState") && _loc1_.isRideInFlyingState())
            {
               _loc1_.rideToWalk();
            }
            if(_loc1_ != null && _loc1_.hasOwnProperty("banneRideFly"))
            {
               _loc1_.banneRideFly("奥拉战记的地形非常复杂，在这里不能飞行哦！");
            }
         }
         catch(rideErr:Error)
         {
         }
         FBTeamSynchronizedEventDispatcher.instance.initListener();
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.addEventListener(FbClient.cmdGetCase,BonusPraiseHelper.onGetCase);
         SocketClient.instance.addEventListener(FbClient.cmdFinFb,BonusPraiseHelper.onFinFb);
         SocketClient.instance.addEventListener(FbClient.cmdGetbestPraise,BonusPraiseHelper.onGetbestPraise);
         this.teamService.addEventListener(TeamServiceEvent.onLeaveTeam,this.onLeaveTeam);
         TalkHelper.openFBtalkMode();
         this.stepAdmin.run();
         FbWildPetManager.instance.init();
         FBButtonManager.instance.init(this._currentFBInfo.fbName);
         this.canFight = this.ipf.canFight;
         this.ipf.canFight = false;
      }
      
      public function stop() : void
      {
         this._isRunning = false;
         if(this.flyService != null)
         {
            this.flyService.cancelBan();
         }
         var _loc1_:Object = ServiceContainer.getService(IRideService);
         if(_loc1_ != null && _loc1_.hasOwnProperty("cancelBanneRideFly"))
         {
            _loc1_.cancelBanneRideFly();
         }
         FBTeamSynchronizedEventDispatcher.instance.dispose();
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.removeEventListener(FbClient.cmdGetCase,BonusPraiseHelper.onGetCase);
         SocketClient.instance.removeEventListener(FbClient.cmdFinFb,BonusPraiseHelper.onFinFb);
         SocketClient.instance.removeEventListener(FbClient.cmdGetbestPraise,BonusPraiseHelper.onGetbestPraise);
         this.teamService.removeEventListener(TeamServiceEvent.onLeaveTeam,this.onLeaveTeam);
         TalkHelper.closeFBtalkMode();
         FbClient.instance.leaveFb(null);
         this.fbLoaderService.reset();
         this.stepAdmin.stop();
         this.sceneAdmin.dispose();
         FbWildPetManager.instance.dispose();
         FBButtonManager.instance.dispose();
         this.ipf.canFight = this.canFight;
      }
      
      public function pause() : void
      {
         this.stepAdmin.pause();
      }
      
      public function play() : void
      {
         this.stepAdmin.play();
      }
      
      public function get currentStep() : int
      {
         return this.stepAdmin.step;
      }
      
      public function set currentStep(param1:int) : void
      {
         this.stepAdmin.step = param1;
      }
      
      public function finishFB(param1:Object) : void
      {
         if(TeamHelper.isCaptain())
         {
            FbClient.instance.tryFinFb(param1);
         }
      }
      
      public function tryGetbestPraise(param1:int) : void
      {
         FbClient.instance.tryGetbestPraise(param1);
      }
      
      public function tryGetCurrentCase(param1:Object) : void
      {
         FbClient.instance.tryGetCase(param1);
      }
      
      private function onLeaveTeam(param1:TeamServiceEvent) : void
      {
         this.stop();
         SceneManager.getInstance().loadedSceneInfo.scene.needValidateLeave = false;
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.afterOut);
         SceneManager.getInstance().loadPreviousScene();
      }
      
      private function onSceneInited(param1:SceneManagerEvent) : void
      {
         var _loc2_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         if(!FBConfig.instence.isTeamFBScene(_loc2_))
         {
            this.stop();
            return;
         }
         this.sceneAdmin.update();
         FbWildPetManager.instance.updatePetInfo();
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         if(Boolean(param1.isWin) || Boolean(param1.isEscape) || param1.raceId < 10000)
         {
            return;
         }
         FBCommonHelper.leavFBonLost();
      }
      
      private function afterOut(param1:SceneManagerEvent) : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.afterOut);
         NewDialog.showSucceedMessage("你因离开队伍被传出了副本！");
      }
      
      override public function toString() : String
      {
         return "[FBTeamService]: " + this._isRunning + " " + this._currentFBInfo;
      }
   }
}

