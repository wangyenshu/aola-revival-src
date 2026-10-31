package mmo.fbteam.service
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.fbteam.dataobject.FBDataObject;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fb.IFbStepService;
   import mmo.interfaces.fbteam.IFBLoaderService;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.icon.IIconService;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   public class FBLoaderService extends EventDispatcher implements IFBLoaderService
   {
      
      private var isJoining:Boolean;
      
      private var _isInFb:Boolean;
      
      private var fbInfo:FBDataObject = new FBDataObject();
      
      private var serviceInitCount:int = 0;
      
      private var preSceneIsFbScene:Boolean = false;
      
      public function FBLoaderService(param1:IEventDispatcher = null)
      {
         super(param1);
      }
      
      public function reset() : void
      {
         this.isJoining = false;
         this._isInFb = false;
      }
      
      public function init() : void
      {
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onScInit);
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited,{}));
      }
      
      private function onScInit(param1:SceneManagerEvent) : void
      {
         var _loc2_:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:Boolean = FBConfig.instence.isTeamFBScene(_loc2_.sceneName);
         if(this.preSceneIsFbScene && !_loc3_)
         {
            this.showHud();
            this.hideHero(false);
            this.preSceneIsFbScene = false;
         }
         if(FBConfig.instence.isTeamFBScene(_loc2_.sceneName))
         {
            this.hideHud();
            this.hideHero(true);
            this.preSceneIsFbScene = true;
         }
      }
      
      private function hideHero(param1:Boolean) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("hide_hero_chapters",{"isHide":param1}));
      }
      
      public function joinFb(param1:int, param2:String, param3:int, param4:Object) : void
      {
         if(this.isJoining || this._isInFb)
         {
            return;
         }
         this.isJoining = true;
         this.fbInfo.fbId = param1;
         this.fbInfo.fbName = param2;
         this.fbInfo.fbLevel = param3;
         this.fbInfo.param = param4;
         SocketClient.instance.addEventListener(FbClient.cmdJoinFb,this.onJoinFB);
         FbClient.instance.joinFb(param1,param3,param2);
         var _loc5_:IFbStepService = ServiceContainer.getService("FbStepService") as IFbStepService;
         _loc5_.lock = true;
      }
      
      public function leaveFb(param1:Object) : void
      {
         if(param1 != null && param1.force == true)
         {
            this.leavFbOnBattleLose();
         }
         else
         {
            SocketClient.instance.addEventListener(FbClient.cmdLeaveFb,this.onLeaveFb);
            FbClient.instance.leaveFb(param1);
         }
      }
      
      private function onJoinFB(param1:SocketClientEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:* = undefined;
         var _loc4_:Boolean = false;
         var _loc5_:Boolean = false;
         var _loc6_:String = null;
         SocketClient.instance.removeEventListener(FbClient.cmdJoinFb,this.onJoinFB);
         if(param1.params.succ == true)
         {
            this._isInFb = true;
            _loc2_ = 1;
            _loc3_ = this.fbInfo.param;
            if(_loc3_ != null && _loc3_.sceneNum != null)
            {
               _loc2_ = int(_loc3_.sceneNum);
               _loc2_ = _loc2_ > 0 ? _loc2_ : 1;
            }
            this.fbInfo.sceneNum = _loc2_;
            this.notifyInitService();
         }
         else
         {
            this._isInFb = false;
            this.isJoining = false;
            this.fbInfo.reset();
            _loc4_ = param1.params.task as Boolean;
            _loc5_ = param1.params.score as Boolean;
            _loc6_ = "";
            if(_loc4_ == true)
            {
               _loc6_ = "task";
            }
            else if(_loc5_ == true)
            {
               _loc6_ = "score";
            }
            this.dispatchEvent(new FbEvent(FbEvent.ENTER_FB,{
               "succ":false,
               "cause":_loc6_,
               "nn":param1.params.nn
            }));
         }
      }
      
      private function hideHud() : void
      {
         var _loc1_:IIconService = ServiceContainer.getService("IconServiceRightTop") as IIconService;
         var _loc2_:IIconService = ServiceContainer.getService("IconServiceLeftTop") as IIconService;
         _loc2_.setAllVisable(false);
         _loc1_.setAllVisable(false);
      }
      
      private function showHud() : void
      {
         var _loc1_:IIconService = ServiceContainer.getService("IconServiceRightTop") as IIconService;
         var _loc2_:IIconService = ServiceContainer.getService("IconServiceLeftTop") as IIconService;
         _loc2_.setAllVisable(true);
         _loc1_.setAllVisable(true);
      }
      
      private function onLeaveFb(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdLeaveFb,this.onLeaveFb);
         this._isInFb = false;
         this.isJoining = false;
         this.fbInfo.reset();
         this.dispatchEvent(new FbEvent(FbEvent.LEAVE_FB,{"cause":"mapclick"}));
      }
      
      private function leavFbOnBattleLose() : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdLeaveFb,this.onLeavFbOnBattleLose);
         FbClient.instance.leaveFb(null);
      }
      
      private function onLeavFbOnBattleLose(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdLeaveFb,this.onLeavFbOnBattleLose);
         this._isInFb = false;
         this.isJoining = false;
         this.fbInfo.reset();
         this.dispatchEvent(new FbEvent(FbEvent.LEAVE_FB,{"cause":"lose"}));
         this.hideHero(false);
         SceneManager.getInstance().loadPreviousScene("default",true);
      }
      
      private function notifyInitService() : void
      {
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotifyBack);
         var _loc1_:Object = {
            "teamkey":TeamHelper.getTeamKey(),
            "what":FBTeamCommonTypes.FB_TEAM_SERVICE,
            "type":FBTeamCommonTypes.TYPE_START,
            "fbInfo":this.fbInfo.toObject()
         };
         TeamSynchronizedClient.notify(_loc1_);
         this.funNotifyBack();
      }
      
      private function onNotify(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:String = param1.params.obj.what;
         var _loc5_:int = int(param1.params.obj.type);
         var _loc6_:Object = param1.params.obj.fbInfo;
         if(TeamSynchronizedClient.cmdNotify != _loc2_ || TeamHelper.getTeamKey() != _loc3_ || FBTeamCommonTypes.FB_TEAM_SERVICE != _loc4_ || FBTeamCommonTypes.TYPE_START != _loc5_)
         {
            return;
         }
         this.fbInfo.setPar(param1.params.obj.fbInfo);
         this.initTeamService();
         TeamSynchronizedClient.notifyBack({
            "teamkey":_loc3_,
            "what":_loc4_,
            "type":_loc5_
         });
      }
      
      private function onNotifyBack(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:String = param1.params.obj.what;
         var _loc5_:int = int(param1.params.obj.type);
         if(TeamSynchronizedClient.cmdNotifyBack != _loc2_ || TeamHelper.getTeamKey() != _loc3_ || FBTeamCommonTypes.FB_TEAM_SERVICE != _loc4_ || FBTeamCommonTypes.TYPE_START != _loc5_)
         {
            return;
         }
         this.funNotifyBack();
      }
      
      private function funNotifyBack() : void
      {
         ++this.serviceInitCount;
         if(TeamHelper.checkCount(this.serviceInitCount))
         {
            this.isJoining = false;
            this.dispatchEvent(new FbEvent(FbEvent.ENTER_FB,{
               "fbId":this.fbInfo.fbId,
               "fbName":this.fbInfo.fbName,
               "fbLevel":this.fbInfo.fbLevel,
               "succ":true
            }));
            SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotifyBack);
            this.serviceInitCount = 0;
            this.initTeamService();
            if(TeamHelper.isCaptain())
            {
               SceneManager.getInstance().loadFB(this.fbInfo.fbName + this.fbInfo.sceneNum,this.fbInfo.fbName,"",TeamHelper.getTeamKey());
            }
         }
      }
      
      private function initTeamService() : void
      {
         SundriesClient.logEvent(18688);
         var _loc1_:IFBTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         if(!_loc1_.isRunning)
         {
            _loc1_.currentFBInfo = this.fbInfo;
            _loc1_.startup();
         }
      }
   }
}

