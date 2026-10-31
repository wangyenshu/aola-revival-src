package mmo.fbteam.fbsiwude.sceneplayer.scene11
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
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   
   public class FBSiwude11_8GetBonus extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const getBonusData:Object = {"what":FBSiwude_Scene11TempTypes.FBAIXI11_8GETBONUS};
      
      private var fbTeamService:IFBTeamService = null;
      
      private var tryAddBoxMouseListenerCounter:int = 0;
      
      private var tryFinishCounter:int = 0;
      
      private var params:Object = null;
      
      private var boxMc:MovieClip = null;
      
      public function FBSiwude11_8GetBonus()
      {
         super();
         this.fbTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.init();
      }
      
      private function init() : void
      {
         this.fbTeamService.addEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.showBonusBoxAppear();
      }
      
      private function showBonusBoxAppear() : void
      {
         var cls:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.GiftBox") as Class;
         this.boxMc = new cls() as MovieClip;
         this.boxMc.addFrameScript(this.boxMc.totalFrames - 1,function():void
         {
            boxMc.stop();
            addClickBoxEvent();
         });
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.boxMc);
      }
      
      private function addClickBoxEvent() : void
      {
         this.boxMc.buttonMode = true;
         this.boxMc.mouseChildren = false;
         this.boxMc.addEventListener(MouseEvent.CLICK,this.onClickBox);
      }
      
      private function onClickBox(param1:MouseEvent) : void
      {
         this.boxMc.removeEventListener(MouseEvent.CLICK,this.onClickBox);
         this.boxMc.mouseEnabled = false;
         this.boxMc.buttonMode = false;
         this.fbTeamService.finishFB(null);
      }
      
      private function fbFinish(param1:FbEvent) : void
      {
         this.fbTeamService.removeEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
         this.boxMc.removeEventListener(MouseEvent.CLICK,this.onClickBox);
         DisplayUtil.stopAndRemove(this.boxMc);
         this.params = param1.param;
         this.showWinPanel();
      }
      
      private function showWinPanel() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("fbservice/fbaixiend",function(param1:*):void
         {
            ProgressFullSprite.close();
            showWaitingItem();
            showPanel();
         });
      }
      
      private function showPanel() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.fbpanels.fbsiwude.FbSiwudeWin") as Class;
         var _loc2_:Sprite = new _loc1_(this.fbTeamService.currentFBInfo.fbLevel,this.params,this.panelCloseFun) as Sprite;
         ModalDialogManager.getInstance().addModalDialog(_loc2_);
      }
      
      private function showWaitingItem() : void
      {
         var _loc1_:Class = null;
         var _loc2_:MovieClip = null;
         if(TeamHelper.isInMulMemberTeam())
         {
            _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsiwude.FBsiwude11.WaitingItem") as Class;
            _loc2_ = new _loc1_() as MovieClip;
            _loc2_.mouseChildren = false;
            _loc2_.mouseEnabled = false;
            sceneInfo.scene.foreGround.addChild(_loc2_);
         }
      }
      
      private function panelCloseFun() : void
      {
         FBTeamSynchronizedClient.finishBack(getBonusData);
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(FBSiwude_Scene11TempTypes.FBAIXI11_8GETBONUS == param1.what)
         {
            ++this.tryFinishCounter;
            this.tryFinish();
         }
      }
      
      private function tryFinish() : void
      {
         if(TeamHelper.checkCount(this.tryFinishCounter))
         {
            this.movieFinish();
            FBCommonHelper.leaveFB();
         }
      }
      
      public function dispose() : void
      {
         this.boxMc.removeEventListener(MouseEvent.CLICK,this.onClickBox);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.fbTeamService.removeEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
      }
   }
}

