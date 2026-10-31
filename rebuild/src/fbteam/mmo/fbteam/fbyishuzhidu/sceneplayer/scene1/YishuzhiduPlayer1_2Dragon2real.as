package mmo.fbteam.fbyishuzhidu.sceneplayer.scene1
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class YishuzhiduPlayer1_2Dragon2real extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const dragon2realData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene1TempTypes.dragon_real
      };
      
      private const dragon2realData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene1TempTypes.dragon_real
      };
      
      private var dragon2realCounter:int = 0;
      
      private var mcDragon:MovieClip = null;
      
      private var btnDragon1:SimpleButton = null;
      
      private var btnDragon2:SimpleButton = null;
      
      private var btnDragon3:SimpleButton = null;
      
      public function YishuzhiduPlayer1_2Dragon2real()
      {
         super();
         this.mcDragon = this.sceneInfo.scene.container.getChildByName("mc_dragon") as MovieClip;
         this.mcDragon.addFrameScript(this.mcDragon.totalFrames - 1,this.mcDragonEnd);
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         this.dragon2real();
         TeamSynchronizedClient.notify(this.dragon2realData1);
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
         if(FBTeamCommonTypes.TYPE_START == _loc4_ && Scene1TempTypes.dragon_real == _loc5_)
         {
            this.dragon2real();
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene1TempTypes.dragon_real == _loc5_)
         {
            this.finishDragon2real();
         }
      }
      
      private function dragon2real() : void
      {
         this.mcDragon.gotoAndPlay(2);
      }
      
      private function mcDragonEnd() : void
      {
         this.btnDragon1 = this.mcDragon.getChildByName("btndragon1") as SimpleButton;
         this.btnDragon2 = this.mcDragon.getChildByName("btndragon2") as SimpleButton;
         this.btnDragon3 = this.mcDragon.getChildByName("btndragon3") as SimpleButton;
         this.sceneInfo.scene.container.addChild(this.btnDragon1);
         this.sceneInfo.scene.container.addChild(this.btnDragon2);
         this.sceneInfo.scene.container.addChild(this.btnDragon3);
         DisplayUtil.stopAndRemove(this.mcDragon);
         this.finishDragon2real();
         TeamSynchronizedClient.finishBack(this.dragon2realData2);
      }
      
      private function finishDragon2real() : void
      {
         ++this.dragon2realCounter;
         if(TeamHelper.checkCount(this.dragon2realCounter))
         {
            this.movieFinish();
            this.dragon2realCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

