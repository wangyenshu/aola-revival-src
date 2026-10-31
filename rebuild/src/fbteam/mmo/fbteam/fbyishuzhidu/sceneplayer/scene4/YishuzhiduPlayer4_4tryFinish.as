package mmo.fbteam.fbyishuzhidu.sceneplayer.scene4
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.FBCommonHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.loader.scheduler.ResScheduler;
   
   public class YishuzhiduPlayer4_4tryFinish extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const getBonusData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene4TempTypes.try_finish
      };
      
      private var tryFinishCounter:int = 0;
      
      private var btnBox:SimpleButton = null;
      
      private var fbTeamService:IFBTeamService = null;
      
      private var param:Object = null;
      
      public function YishuzhiduPlayer4_4tryFinish()
      {
         super();
         this.btnBox = this.sceneInfo.scene.container.getChildByName("btnbox") as SimpleButton;
         this.fbTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnBox.addEventListener(MouseEvent.CLICK,this.onBtnBox);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         this.fbTeamService.addEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
      }
      
      private function onFinishBack(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         var _loc5_:int = int(param1.params.obj.what);
         if(TeamHelper.getTeamKey() != _loc3_ || TeamSynchronizedClient.cmdFinishBack != _loc2_)
         {
            return;
         }
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene4TempTypes.try_finish == _loc5_)
         {
            this.tryFinish();
         }
      }
      
      private function fbFinish(param1:FbEvent) : void
      {
         this.isClicking = false;
         this.btnBox.removeEventListener(MouseEvent.CLICK,this.onBtnBox);
         this.fbTeamService.removeEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
         this.param = param1.param;
         this.getWinPanelRes();
      }
      
      private function onBtnBox(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.btnBox.removeEventListener(MouseEvent.CLICK,this.onBtnBox);
         this.fbTeamService.finishFB(null);
      }
      
      private function getWinPanelRes() : void
      {
         if(ApplicationDomain.currentDomain.hasDefinition("mmo.fbpanels.fbyishuzhidu.FbYishuzhiduWin"))
         {
            this.showPanel();
         }
         else
         {
            ResScheduler.getResource("fbservice/fbaixiend",function(param1:*):void
            {
               showPanel();
            });
         }
      }
      
      private function showPanel() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.fbpanels.fbyishuzhidu.FbYishuzhiduWin") as Class;
         var _loc2_:Sprite = new _loc1_(this.fbTeamService.currentFBInfo.fbLevel,this.param,this.panelCloseFun) as Sprite;
         ModalDialogManager.getInstance().addModalDialog(_loc2_);
      }
      
      private function panelCloseFun() : void
      {
         DisplayUtil.stopAndRemove(this.btnBox);
         this.tryFinish();
         TeamSynchronizedClient.finishBack(this.getBonusData2);
      }
      
      private function tryFinish() : void
      {
         ++this.tryFinishCounter;
         this.check2finish();
      }
      
      private function check2finish() : void
      {
         if(TeamHelper.checkCount(this.tryFinishCounter))
         {
            this.movieFinish();
            this.tryFinishCounter = 0;
            FBCommonHelper.leaveFB();
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         this.fbTeamService.removeEventListener(FbEvent.ON_FIN_FB,this.fbFinish);
      }
   }
}

