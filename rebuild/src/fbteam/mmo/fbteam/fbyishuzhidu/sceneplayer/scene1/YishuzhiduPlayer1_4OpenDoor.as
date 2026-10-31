package mmo.fbteam.fbyishuzhidu.sceneplayer.scene1
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class YishuzhiduPlayer1_4OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const openDoorData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene1TempTypes.open_door
      };
      
      private const openDoorData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene1TempTypes.open_door
      };
      
      private var openDoorCounter:int = 0;
      
      private var btnCard:SimpleButton = null;
      
      private var balk1:Sprite = null;
      
      private var mcOpenDoor:MovieClip = null;
      
      private var gogo:MovieClip = null;
      
      public function YishuzhiduPlayer1_4OpenDoor()
      {
         super();
         this.btnCard = this.sceneInfo.scene.foreGround.getChildByName("btnCard") as SimpleButton;
         this.balk1 = this.getObstruction().getChildByName("balk1") as Sprite;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnCard.addEventListener(MouseEvent.CLICK,this.onCard);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
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
         if(FBTeamCommonTypes.TYPE_START == _loc4_ && Scene1TempTypes.open_door == _loc5_)
         {
            this.openDoor();
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
         if(Boolean(FBTeamCommonTypes.TYPE_END) && Scene1TempTypes.open_door == _loc5_)
         {
            this.tryEnd();
         }
      }
      
      private function onCard(param1:MouseEvent) : void
      {
         TeamSynchronizedClient.notify(this.openDoorData1);
         this.openDoor();
      }
      
      private function openDoor() : void
      {
         TipsManager.getInstance().removeTips(this.btnCard);
         this.btnCard.removeEventListener(MouseEvent.CLICK,this.onCard);
         DisplayUtil.stopAndRemove(this.btnCard);
         var _loc1_:String = "mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.OpenDoor";
         var _loc2_:Class = FBConfig.instence.getClass(_loc1_) as Class;
         this.mcOpenDoor = new _loc2_() as MovieClip;
         this.mcOpenDoor.addFrameScript(this.mcOpenDoor.totalFrames - 1,this.openDoorEnd);
         this.sceneInfo.scene.foreGround.addChild(this.mcOpenDoor);
      }
      
      private function openDoorEnd() : void
      {
         this.gogo = this.mcOpenDoor.getChildByName("gogo") as MovieClip;
         this.sceneInfo.scene.foreGround.addChild(this.gogo);
         DisplayUtil.stopAndRemove(this.mcOpenDoor);
         this.setCanGo();
         this.tryEnd();
         TeamSynchronizedClient.finishBack(this.openDoorData2);
      }
      
      private function tryEnd() : void
      {
         ++this.openDoorCounter;
         if(TeamHelper.checkCount(this.openDoorCounter))
         {
            this.movieFinish();
            this.openDoorCounter = 0;
         }
      }
      
      private function setCanGo() : void
      {
         DisplayUtil.stopAndRemove(this.balk1);
         this.sceneInfo.scene.setMapArray();
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

