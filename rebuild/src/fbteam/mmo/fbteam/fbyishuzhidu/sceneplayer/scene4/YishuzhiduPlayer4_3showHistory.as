package mmo.fbteam.fbyishuzhidu.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class YishuzhiduPlayer4_3showHistory extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const showHistoryData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene4TempTypes.show_history
      };
      
      private const showHistoryData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene4TempTypes.show_history
      };
      
      private var showHistoryCounter:int = 0;
      
      private const clsName:String = "mmo.fbteam.fbyishuzhidu.sceneplayer.scene4.History";
      
      private const showboxClsName:String = "mmo.fbteam.fbyishuzhidu.sceneplayer.scene4.ShowBox";
      
      private var mcHistroy:MovieClip = null;
      
      private var mcShowbox:MovieClip = null;
      
      private var btnBox:SimpleButton = null;
      
      private var btnClose:SimpleButton = null;
      
      private var mcBackground:MovieClip = null;
      
      public function YishuzhiduPlayer4_3showHistory()
      {
         super();
         var _loc1_:Class = FBConfig.instence.getClass(this.clsName) as Class;
         this.mcHistroy = new _loc1_() as MovieClip;
         this.mcHistroy.addFrameScript(this.mcHistroy.totalFrames - 1,this.mcHistroyEnd);
         this.btnClose = this.mcHistroy.getChildByName("btnclose") as SimpleButton;
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onClose);
         this.mcBackground = this.sceneInfo.scene.backGround.getChildByName("mcbackground") as MovieClip;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         ModalDialogManager.getInstance().addModalDialog(this.mcHistroy,AlignType.NONE);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene4TempTypes.show_history == _loc5_)
         {
            this.tryFinish();
         }
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.mcHistroyEnd();
      }
      
      private function mcHistroyEnd() : void
      {
         this.btnClose.removeEventListener(MouseEvent.CLICK,this.onClose);
         ModalDialogManager.getInstance().removeModalDialog(this.mcHistroy);
         this.mcBackground.gotoAndStop(2);
         this.showBox();
      }
      
      private function showBox() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass(this.showboxClsName) as Class;
         this.mcShowbox = new _loc1_() as MovieClip;
         this.mcShowbox.addFrameScript(this.mcShowbox.totalFrames - 1,this.onShowBoxEnd);
         this.sceneInfo.scene.foreGround.addChild(this.mcShowbox);
      }
      
      private function onShowBoxEnd() : void
      {
         this.btnBox = this.mcShowbox.getChildByName("btnbox") as SimpleButton;
         this.sceneInfo.scene.container.addChild(this.btnBox);
         DisplayUtil.stopAndRemove(this.mcShowbox);
         this.tryFinish();
         TeamSynchronizedClient.finishBack(this.showHistoryData2);
      }
      
      private function tryFinish() : void
      {
         ++this.showHistoryCounter;
         this.check2finish();
      }
      
      private function check2finish() : void
      {
         if(TeamHelper.checkCount(this.showHistoryCounter))
         {
            this.movieFinish();
            this.showHistoryCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

