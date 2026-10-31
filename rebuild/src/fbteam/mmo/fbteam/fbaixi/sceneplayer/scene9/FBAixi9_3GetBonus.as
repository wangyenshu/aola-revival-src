package mmo.fbteam.fbaixi.sceneplayer.scene9
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.FBCommonHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi9_3GetBonus extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var fbTeamService:IFBTeamService;
      
      private var tryAddBoxMouseListenerCounter:int = 0;
      
      private var tryFinishCounter:int = 0;
      
      private var params:Object = null;
      
      private var boxAppearData:Object = {"what":FBAixi_Scene9TempTypes.FBAIXI9_3_0BOXAPPEAR};
      
      private var getBonusData:Object = {"what":FBAixi_Scene9TempTypes.FBAIXI9_3GETBONUS};
      
      private var boxMc:MovieClip;
      
      public function FBAixi9_3GetBonus()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.init();
      }
      
      private function init() : void
      {
         var cls:Class;
         this.fbTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         this.fbTeamService.addEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         cls = FBConfig.instence.getClass("mmo.scene.fbaixi.fbaixi9.GiftBox") as Class;
         this.boxMc = new cls() as MovieClip;
         this.boxMc.addFrameScript(this.boxMc.totalFrames - 1,function():void
         {
            boxMc.stop();
            FBTeamSynchronizedClient.notifyBack(boxAppearData);
         });
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.boxMc);
         this.boxMc.gotoAndPlay(1);
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(FBAixi_Scene9TempTypes.FBAIXI9_3_0BOXAPPEAR == param1.what)
         {
            this.tryAddBoxMouseListener();
         }
      }
      
      private function tryAddBoxMouseListener() : void
      {
         ++this.tryAddBoxMouseListenerCounter;
         if(TeamHelper.checkCount(this.tryAddBoxMouseListenerCounter))
         {
            this.boxMc.addEventListener(MouseEvent.CLICK,this.onClickBox);
         }
      }
      
      private function onClickBox(param1:MouseEvent) : void
      {
         this.fbTeamService.finishFB(null);
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(FBAixi_Scene9TempTypes.FBAIXI9_3GETBONUS == param1.what)
         {
            this.tryFinish();
         }
      }
      
      private function fbFinish(param1:FbEvent) : void
      {
         this.fbTeamService.removeEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
         this.boxMc.removeEventListener(MouseEvent.CLICK,this.onClickBox);
         this.params = param1.param;
         this.getWinPanel();
      }
      
      private function getWinPanel() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("fbservice/fbaixiend",function(param1:*):void
         {
            ProgressFullSprite.close();
            DisplayUtil.stopAndRemove(boxMc);
            showWaitingItem();
            showPanel();
         });
      }
      
      private function showWaitingItem() : void
      {
         var _loc3_:Class = null;
         var _loc4_:MovieClip = null;
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         var _loc2_:TeamInfo = _loc1_.getMyTeam();
         if(_loc2_ != null && _loc2_.teamLength > 1)
         {
            _loc3_ = FBConfig.instence.getClass("mmo.scene.fbaixi.WaitingItem") as Class;
            _loc4_ = new _loc3_() as MovieClip;
            SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(_loc4_);
         }
      }
      
      private function showPanel() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.fbpanels.fbaixi.Fbaixiwin") as Class;
         var _loc2_:Sprite = new _loc1_(this.fbTeamService.currentFBInfo.fbLevel,this.params,this.panelCloseFun) as Sprite;
         ModalDialogManager.getInstance().addModalDialog(_loc2_);
      }
      
      private function panelCloseFun() : void
      {
         FBTeamSynchronizedClient.finishBack(this.getBonusData);
      }
      
      private function tryFinish() : void
      {
         ++this.tryFinishCounter;
         if(TeamHelper.checkCount(this.tryFinishCounter))
         {
            this.movieFinish();
            this.tryFinishCounter = 0;
            FBCommonHelper.leaveFB();
         }
      }
      
      public function dispose() : void
      {
         this.boxMc.removeEventListener(MouseEvent.CLICK,this.onClickBox);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         this.fbTeamService.removeEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
      }
   }
}

