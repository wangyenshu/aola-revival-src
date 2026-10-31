package mmo.fbteam.fbyishuzhidu.sceneplayer.scene1
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class YishuzhiduPlayer1_1Openlight extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var mcSwitch:MovieClip = null;
      
      private var mcOpenScene:MovieClip = null;
      
      private const openLightData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene1TempTypes.open_light
      };
      
      private const openLightData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene1TempTypes.open_light
      };
      
      private var opentLightCounter:int = 0;
      
      public function YishuzhiduPlayer1_1Openlight()
      {
         super();
         this.mcSwitch = this.sceneInfo.scene.container.getChildByName("mc_switch") as MovieClip;
         this.mcOpenScene = this.sceneInfo.scene.foreGround.getChildByName("mc_openscene") as MovieClip;
         this.mcOpenScene.mouseEnabled = false;
         this.mcOpenScene.mouseChildren = false;
         this.mcOpenScene.addFrameScript(this.mcOpenScene.totalFrames - 1,this.openSceneEnd);
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.mcSwitch.addEventListener(MouseEvent.CLICK,this.onSwitch);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
      
      private function onSwitch(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         TeamSynchronizedClient.notify(this.openLightData1);
         this.openLight();
      }
      
      private function onNotify(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         var _loc5_:int = int(param1.params.obj.what);
         if(TeamHelper.getTeamKey() != _loc3_ || TeamSynchronizedClient.cmdNotify != _loc2_)
         {
            return;
         }
         if(FBTeamCommonTypes.TYPE_START == _loc4_ && Scene1TempTypes.open_light == _loc5_)
         {
            this.openLight();
         }
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene1TempTypes.open_light == _loc5_)
         {
            this.finishOpenLight();
         }
      }
      
      private function openSceneEnd() : void
      {
         this.isClicking = false;
         DisplayUtil.stopAndRemove(this.mcOpenScene);
         this.finishOpenLight();
         TeamSynchronizedClient.finishBack(this.openLightData2);
      }
      
      private function openLight() : void
      {
         this.mcSwitch.removeEventListener(MouseEvent.CLICK,this.onSwitch);
         this.mcSwitch.gotoAndStop(2);
         this.mcOpenScene.play();
      }
      
      private function finishOpenLight() : void
      {
         ++this.opentLightCounter;
         if(TeamHelper.checkCount(this.opentLightCounter))
         {
            this.movieFinish();
            this.opentLightCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         this.mcSwitch.removeEventListener(MouseEvent.CLICK,this.onSwitch);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

