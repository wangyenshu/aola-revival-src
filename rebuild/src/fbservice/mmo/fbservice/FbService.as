package mmo.fbservice
{
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.text.TextField;
   import flash.utils.Timer;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbservice.common.tools.Tool;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceContainerEvent;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fb.IClearCondition;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.fb.IFbStepService;
   import mmo.interfaces.fly.IFlyService;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.pet.fight.IWildPet;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   public class FbService extends EventDispatcher implements IFbService
   {
      /**
       * The later IFbService's methods the 2013 interface lacks. Scenes compiled
       * against the later interface (suolide2, siwude4, yishuzhidu6 and
       * aixiscene4's 副本 entrances: IFbService.showChooseFbPanel) call them in
       * the interface's namespace; answered there as well as in public.
       */
      public namespace later = "mmo.interfaces.fb:IFbService";

      later function showChooseFbPanel(param1:int) : void
      {
         this.openChoosePanel(param1);
      }

      later function getPanelInfo(param1:int) : void
      {
         this.askPanelInfo(param1);
      }

      later function showBuyTimePanel(param1:int, param2:Function, param3:int) : void
      {
         this.openBuyTimePanel(param1,param2,param3);
      }

      /** FbEvent.ON_GET_PANEL_INFO and FbClient.cmdGetPanelInfo of the later libraries. */
      public static const ON_GET_PANEL_INFO:String = "onGetPanelInfo";
      private static const CMD_GET_PANEL_INFO:String = "fb_9";

      
      private var wildPetService:IWildPet;
      
      private var _isInFb:Boolean;
      
      private var _fbId:int;
      
      private var _fbName:String;
      
      private var _fbLevel:int;
      
      private var isJoining:Boolean;
      
      private var currentWildPets:Array;
      
      private var currentBossPet:Array;
      
      private var diePet:Array = [];
      
      private var COUNT_DOWN:int = 660000;
      
      private var startTime:int = 0;
      
      private var timer:Timer;
      
      private var textTime:TextField;
      
      private var dialog:ModalDialog;
      
      private var flyService:IFlyService = null;
      
      public function FbService()
      {
         super(null);
      }
      
      public function init() : void
      {
         ServiceContainer.instance.addEventListener(ServiceContainerEvent.onGetService,this.onGetService);
         ServiceContainer.instance.tryGetService(IWildPet);
         this.flyService = ServiceContainer.getService(IFlyService) as IFlyService;
         // REVIVAL: the later rooms lost their 副本 doors; put back here.
         FbEntrances.init();
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited,{}));
      }
      
      public function joinFb(param1:int, param2:String, param3:int, param4:Object) : void
      {
         var rideService:IRideService;
         var tempThis:FbService = null;
         var fun:Function = null;
         var fbId:int = param1;
         var fbName:String = param2;
         var level:int = param3;
         var param:Object = param4;
         if(this.isJoining)
         {
            return;
         }
         if(this._isInFb)
         {
            return;
         }
         this.isJoining = true;
         if(this.flyService != null)
         {
            this.flyService.banFly("奥拉战记的地形非常复杂，在这里不能飞行哦！");
            this.flyService.land(true);
         }
         // REVIVAL: the 2013 IRideService has neither isRideInFlyingState nor banneRideFly (later ones).
         rideService = ServiceContainer.getService(IRideService) as IRideService;
         try
         {
            var ride:Object = rideService;
            if(ride != null && ride.hasOwnProperty("isRideInFlyingState") && ride.isRideInFlyingState())
            {
               rideService.rideToWalk();
            }
            if(ride != null && ride.hasOwnProperty("banneRideFly"))
            {
               ride.banneRideFly("奥拉战记的地形非常复杂，在这里不能飞行哦！");
            }
         }
         catch(rideErr:Error)
         {
         }
         tempThis = this;
         this._fbId = fbId;
         this._fbLevel = level;
         this._fbName = fbName;
         fun = function(param1:SocketClientEvent):*
         {
            var _loc2_:int = 0;
            var _loc3_:Boolean = false;
            var _loc4_:Boolean = false;
            var _loc5_:String = null;
            SocketClient.instance.removeEventListener(FbClient.cmdJoinFb,fun);
            if(param1.params.succ == true)
            {
               tempThis._isInFb = true;
               tempThis.isJoining = false;
               SceneManager.getInstance().addEventListener(SceneManagerEvent.TASK_SCENE_INITED,onTaskSceneInited);
               SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE,onUnloadScene);
               FBButtonManager.instance.init(fbName);
               tempThis.dispatchEvent(new FbEvent(FbEvent.ENTER_FB,{
                  "fbId":this._fbId,
                  "fbName":this._fbName,
                  "fbLevel":this._fbLevel,
                  "succ":true
               }));
               _loc2_ = 1;
               if(param != null && param.sceneNum != null)
               {
                  _loc2_ = int(param.sceneNum);
                  _loc2_ = _loc2_ > 0 ? _loc2_ : 1;
               }
               SceneManager.getInstance().loadFB(tempThis._fbName + _loc2_,tempThis._fbName,"",Tool.getTeamKey());
            }
            else
            {
               tempThis._isInFb = false;
               tempThis.isJoining = false;
               tempThis._fbId = -1;
               tempThis._fbLevel = -1;
               tempThis._fbName = "";
               _loc3_ = param1.params.task as Boolean;
               _loc4_ = param1.params.score as Boolean;
               _loc5_ = "";
               if(_loc3_ == true)
               {
                  _loc5_ = "task";
               }
               else if(_loc4_ == true)
               {
                  _loc5_ = "score";
               }
               tempThis.dispatchEvent(new FbEvent(FbEvent.ENTER_FB,{
                  "succ":false,
                  "cause":_loc5_
               }));
            }
         };
         SocketClient.instance.addEventListener(FbClient.cmdJoinFb,fun);
         FbClient.instance.joinFb(fbId,level,fbName);
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
            this.resetHelloTalk();
         }
      }
      
      private function resetHelloTalk() : void
      {
         var _loc1_:IFbStepService = ServiceContainer.getService("FbStepService") as IFbStepService;
         _loc1_.helloTalkReset();
      }
      
      public function get currentFbId() : int
      {
         return this._fbId;
      }
      
      public function get currentFbLevel() : int
      {
         return this._fbLevel;
      }
      
      public function get currentFbName() : String
      {
         return this._fbName;
      }
      
      public function get isInFb() : Boolean
      {
         return this._isInFb;
      }
      
      public function registerCondition(param1:int, param2:Object) : IClearCondition
      {
         var _loc3_:IClearCondition = FbClearConditionFactory.instance.createClearCondition(param1,param2,this.currentWildPets);
         FbEventListener.instance.addCondition(_loc3_);
         return _loc3_;
      }
      
      public function removeCondition(param1:IClearCondition) : void
      {
         FbEventListener.instance.removeCondition(param1);
      }
      
      public function tryGetCaseAtCurrentScene(param1:Object) : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdGetCase,this.onGetCase);
         FbClient.instance.tryGetCase(param1);
      }
      
      public function addCurrentWildPets(param1:Array) : void
      {
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            _loc3_ = 0;
            while(_loc3_ < this.diePet.length)
            {
               if(param1[_loc2_] == this.diePet[_loc3_].raceId)
               {
                  this.currentWildPets.push(this.diePet[_loc3_]);
                  this.diePet.splice(_loc3_,1);
                  break;
               }
               _loc3_++;
            }
            _loc2_++;
         }
         this.onEnterFightFailed(null);
      }
      
      public function showBuyTimePanel(param1:int, param2:Function, param3:int) : void
      {
         this.openBuyTimePanel(param1,param2,param3);
      }

      private function openBuyTimePanel(param1:int, param2:Function, param3:int) : void
      {
         var fbid:int = param1;
         var callback:Function = param2;
         var buyedTimes:int = param3;
         var url:String = "fbservice/fbbuytimespanel";
         var cls:String = "mmo.fbpanels.buytimes.FBBuyTimesPanel";
         SimpleCustomLoader.loadSingleResource(url,cls,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"加载中，请稍候……",function(param1:IShowDataPanel):void
         {
            param1.showPanelByData({
               "callback":callback,
               "t":buyedTimes,
               "id":fbid
            });
         });
      }
      
      public function getPanelInfo(param1:int) : void
      {
         this.askPanelInfo(param1);
      }

      private function askPanelInfo(param1:int) : void
      {
         // REVIVAL: fb_9 (FbClient.cmdGetPanelInfo) came after the 2013 FbClient.
         SocketClient.instance.addEventListener(CMD_GET_PANEL_INFO,this.onGetPanelInfo);
         SocketClient.instance.sendXtMessage("FBExtension",CMD_GET_PANEL_INFO,{"id":param1});
      }
      
      public function showChooseFbPanel(param1:int) : void
      {
         this.openChoosePanel(param1);
      }

      private function openChoosePanel(param1:int) : void
      {
         var fbid:int = param1;
         var url:String = "fbservice/fbchoosepanel";
         var cls:String = "mmo.fbpanels.fbchoose.FbChoosePanel";
         SimpleCustomLoader.loadSingleResource(url,cls,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"加载中，请稍候……",function(param1:IShowDataPanel):void
         {
            param1.showPanelByData({"id":fbid});
         });
      }
      
      public function tryGetbestPraise(param1:int) : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdGetbestPraise,this.onGetbestPraise);
         FbClient.instance.tryGetbestPraise({"id":param1});
      }
      
      public function tryFinFb(param1:Object) : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdFinFb,this.onFinFb);
         FbClient.instance.tryFinFb(param1);
      }
      
      public function healHpAndPP(param1:Object) : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdHealHPAndPP,this.onHealHpAndPP);
         FbClient.instance.healHpAndMp(param1);
      }
      
      public function addFollower(param1:int) : DisplayObject
      {
         var _loc2_:ScenePlayer = new ScenePlayer("fb_temp");
         var _loc3_:AvatarInfo = new AvatarInfo();
         _loc3_.setAvatarInfoWithString(param1.toString());
         _loc2_.setAvatar(_loc3_);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc2_);
         var _loc4_:PlayerBase = PlayerManager.getInstance().myPlayer;
         _loc2_.x = _loc4_.x;
         _loc2_.y = _loc4_.y;
         _loc2_.setStrategy(new PlayerFollowStrategy(Object(_loc4_) as IMovable));
         return _loc2_;
      }
      
      private function onGetPanelInfo(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(CMD_GET_PANEL_INFO,this.onGetPanelInfo);
         this.dispatchEvent(new FbEvent(ON_GET_PANEL_INFO,param1.params));
      }
      
      private function onGetService(param1:ServiceContainerEvent) : void
      {
         if(param1.serviceName != "WildPetService")
         {
            return;
         }
         ServiceContainer.instance.removeEventListener(ServiceContainerEvent.onGetService,this.onGetService);
         this.wildPetService = param1.service as IWildPet;
      }
      
      private function getFbWildPetInfo() : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdGetFbWildPet,this.onGetFbWildPetInfo);
         FbClient.instance.getFbWildPet(null);
      }
      
      private function onGetFbWildPetInfo(param1:SocketClientEvent) : void
      {
         var _loc7_:int = 0;
         SocketClient.instance.removeEventListener(FbClient.cmdGetFbWildPet,this.onGetFbWildPetInfo);
         if(this.wildPetService == null)
         {
            return;
         }
         var _loc2_:Array = param1.params.pms as Array;
         this.currentWildPets = [];
         this.currentBossPet = [];
         var _loc3_:Array = [11001,10249,10999];
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            if(_loc3_.indexOf(_loc2_[_loc4_].raceId) < 0)
            {
               this.currentWildPets.push({
                  "raceId":_loc2_[_loc4_].raceId,
                  "id":_loc2_[_loc4_].id,
                  "lv":_loc2_[_loc4_].lv
               });
            }
            else
            {
               this.currentBossPet.push({"raceId":_loc2_[_loc4_].raceId});
            }
            _loc4_++;
         }
         var _loc5_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         var _loc6_:Array = FbWildPetLocationMap.instance.getLocation(_loc5_);
         if(_loc6_ != null)
         {
            _loc7_ = 0;
            while(_loc7_ < _loc6_.length)
            {
               if(this.currentWildPets[_loc7_] == null)
               {
                  break;
               }
               this.currentWildPets[_loc7_].point = _loc6_[_loc7_];
               _loc7_++;
            }
            if(this.currentWildPets.length > 0 && this.currentWildPets[0].point != null)
            {
               this.wildPetService.generatePetsAtCurrentScene(this.currentWildPets);
            }
         }
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFailed);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFail);
         FbEventListener.instance.startListen();
         this.dispatchEvent(new FbEvent(FbEvent.ON_GET_SCENE_PET_INFO,null));
      }
      
      private function onTaskSceneInited(param1:SceneManagerEvent) : void
      {
         if(SceneManager.getInstance().loadedSceneInfo.sceneName.indexOf("fb") < 0)
         {
            this.leaveFb(null);
            return;
         }
         this.getFbWildPetInfo();
      }
      
      private function onUnloadScene(param1:SceneManagerEvent) : void
      {
         if(!SceneManager.getInstance().loadedSceneInfo.isFB)
         {
            return;
         }
         if(this.wildPetService != null)
         {
            this.wildPetService.dispose();
         }
         this.diePet = [];
         FbEventListener.instance.clearConditionAndStopListen();
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFailed);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFail);
      }
      
      private function onLeaveFb(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdLeaveFb,this.onLeaveFb);
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.TASK_SCENE_INITED,this.onTaskSceneInited);
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.UNLOAD_SCENE,this.onUnloadScene);
         this._isInFb = false;
         this.isJoining = false;
         this._fbId = -1;
         this._fbLevel = -1;
         this._fbName = "";
         this.dispatchEvent(new FbEvent(FbEvent.LEAVE_FB,{"cause":"mapclick"}));
         FBButtonManager.instance.dispose();
         if(this.flyService != null)
         {
            this.flyService.cancelBan();
         }
         var _loc2_:Object = ServiceContainer.getService(IRideService);
         if(_loc2_ != null && _loc2_.hasOwnProperty("cancelBanneRideFly"))
         {
            _loc2_.cancelBanneRideFly();
         }
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         if(param1.isWin)
         {
            _loc2_ = int(param1.id);
            _loc3_ = 0;
            while(_loc3_ < this.currentWildPets.length)
            {
               if(this.currentWildPets[_loc3_].id == _loc2_)
               {
                  this.diePet.push(this.currentWildPets[_loc3_]);
                  this.currentWildPets.splice(_loc3_,1);
               }
               else
               {
                  _loc3_++;
               }
            }
            this.onEnterFightFailed(null);
            if(this.currentWildPets.length == 0)
            {
               this.dispatchEvent(new FbEvent(FbEvent.ON_KILL_ALL_MONSTER,{}));
            }
         }
         else if(param1.isEscape)
         {
            this.onEnterFightFailed(null);
         }
         else
         {
            this.leavFBonLost();
         }
      }
      
      private function leavFBonLost() : void
      {
         this.dialog = NewDialog.getMessageDialog("挑战失败，请带上强大的亚比再来吧！");
         this.dialog.addEventListener(ModalDialogEvent.CLOSE,this.onOuttingClose);
         this.dialog.show();
      }
      
      private function onOuttingClose(param1:ModalDialogEvent) : void
      {
         this.dialog.removeEventListener(ModalDialogEvent.CLOSE,this.onOuttingClose);
         this.leavFbOnBattleLose();
         this.dialog = null;
      }
      
      private function leavFbOnBattleLose() : void
      {
         SocketClient.instance.addEventListener(FbClient.cmdLeaveFb,this.onLeavFbOnBattleLose);
         FbClient.instance.leaveFb(null);
         this.resetHelloTalk();
      }
      
      private function onLeavFbOnBattleLose(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdLeaveFb,this.onLeavFbOnBattleLose);
         FBButtonManager.instance.dispose();
         this._isInFb = false;
         this.isJoining = false;
         this._fbId = -1;
         this._fbLevel = -1;
         this._fbName = "";
         this.dispatchEvent(new FbEvent(FbEvent.LEAVE_FB,{"cause":"lose"}));
         SceneManager.getInstance().loadPreviousScene("default",true);
      }
      
      private function onEnterFightFailed(param1:PetFightEvent) : void
      {
         if(this.wildPetService != null && this.currentWildPets.length >= 0)
         {
            this.wildPetService.dispose();
            this.wildPetService.generatePetsAtCurrentScene(this.currentWildPets);
         }
      }
      
      private function onEnterFightFail(param1:PetFightEvent) : void
      {
         this.leaveFBonBattleFail();
      }
      
      private function leaveFBonBattleFail() : void
      {
         this.dialog = NewDialog.getMessageDialog("你不满足继续战斗的条件，现在把你传送出副本！");
         this.dialog.addEventListener(ModalDialogEvent.CLOSE,this.onOuttingClose);
         this.dialog.show();
      }
      
      private function onGetCase(param1:SocketClientEvent) : void
      {
         var _loc5_:Object = null;
         SocketClient.instance.removeEventListener(FbClient.cmdGetCase,this.onGetCase);
         var _loc2_:Boolean = param1.params.succ as Boolean;
         var _loc3_:Array = param1.params.bn as Array;
         var _loc4_:Array = [];
         if(_loc2_ && _loc3_ != null && _loc3_.length > 0)
         {
            for each(_loc5_ in _loc3_)
            {
               _loc4_.push({
                  "type":_loc5_.type,
                  "id":_loc5_.id,
                  "num":_loc5_.num
               });
            }
         }
         this.dispatchEvent(new FbEvent(FbEvent.ON_TRYGET_CASE,{
            "succ":_loc2_,
            "bonus":_loc4_
         }));
      }
      
      private function onFinFb(param1:SocketClientEvent) : void
      {
         var _loc7_:Object = null;
         SocketClient.instance.removeEventListener(FbClient.cmdFinFb,this.onFinFb);
         var _loc2_:Boolean = param1.params.fin as Boolean;
         var _loc3_:Array = param1.params.bn as Array;
         var _loc4_:Array = [];
         if(_loc2_ && _loc3_ != null)
         {
            for each(_loc7_ in _loc3_)
            {
               _loc4_.push({
                  "type":_loc7_.type,
                  "id":_loc7_.id,
                  "num":_loc7_.num
               });
            }
         }
         var _loc5_:String = param1.params.gr as String;
         var _loc6_:int = param1.params.tm as int;
         this.dispatchEvent(new FbEvent(FbEvent.ON_FIN_FB,{
            "succ":_loc2_,
            "bonus":_loc4_,
            "gr":_loc5_,
            "tm":_loc6_
         }));
      }
      
      private function onGetbestPraise(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdGetbestPraise,this.onGetbestPraise);
         var _loc2_:String = param1.params.gr as String;
         var _loc3_:Array = [];
         if(_loc2_ != null)
         {
            _loc3_ = _loc2_.split(";");
         }
         this.dispatchEvent(new FbEvent(FbEvent.ON_GET_BEST_PRAISE,{"gr":_loc3_}));
      }
      
      private function onHealHpAndPP(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FbClient.cmdHealHPAndPP,this.onHealHpAndPP);
         var _loc2_:Boolean = param1.params.res as Boolean;
         this.dispatchEvent(new FbEvent(FbEvent.ON_HEAL_HP_AND_PP,{"result":_loc2_}));
      }
   }
}

