package mmo.fbteam.fbyishuzhidu.sceneplayer.scene2
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.play.scene.SceneManager;
   
   public class Scene2_1BackGround extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var btnHandle:SimpleButton;
      
      private var mcPurdah:MovieClip;
      
      private var tempBack:MovieClip;
      
      private var purdahCounter:int = 0;
      
      private var tempType:String;
      
      public function Scene2_1BackGround()
      {
         super();
         this.tempBack = this.sceneInfo.scene.backGround.getChildByName("tempback") as MovieClip;
         this.btnHandle = this.tempBack.getChildByName("btnhandle") as SimpleButton;
         this.mcPurdah = this.tempBack.getChildByName("purdah") as MovieClip;
         var _loc1_:uint = 1;
         while(_loc1_ <= 3)
         {
            this.tempBack.getChildByName("chips_" + _loc1_).visible = false;
            _loc1_++;
         }
         var _loc2_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.foreGround.getChildByName("et2") as Sprite;
         _loc2_.mouseEnabled = false;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.tempType = param1;
         this.btnHandle.addEventListener(MouseEvent.CLICK,this.onClickHandle);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
      
      private function onClickHandle(param1:MouseEvent) : void
      {
         var _loc2_:Object = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_START,
            "action":Scene2TempTypes.open_background
         };
         TeamSynchronizedClient.notify(_loc2_);
         this.showPurdahMovie();
      }
      
      private function showPurdahMovie() : void
      {
         var endData:Object;
         this.btnHandle.removeEventListener(MouseEvent.CLICK,this.onClickHandle);
         DisplayUtil.stopAndRemove(this.btnHandle);
         this.mcPurdah.gotoAndPlay(2);
         endData = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_END,
            "action":Scene2TempTypes.open_background
         };
         TeamSynchronizedClient.finishBack(endData);
         this.mcPurdah.addFrameScript(this.mcPurdah.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(mcPurdah);
            commFinish();
         });
      }
      
      private function onNotify(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         if(TeamHelper.getTeamKey() != _loc3_ || TeamSynchronizedClient.cmdNotify != _loc2_ || FBTeamCommonTypes.TYPE_START != _loc4_)
         {
            return;
         }
         var _loc5_:int = int(param1.params.obj.action);
         if(_loc5_ == Scene2TempTypes.open_background)
         {
            this.showPurdahMovie();
         }
      }
      
      private function onFinishBack(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         var _loc5_:int = int(param1.params.obj.action);
         if(TeamHelper.getTeamKey() != _loc3_ || TeamSynchronizedClient.cmdFinishBack != _loc2_)
         {
            return;
         }
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene2TempTypes.open_background == _loc5_)
         {
            this.commFinish();
         }
      }
      
      private function commFinish() : void
      {
         ++this.purdahCounter;
         if(TeamHelper.checkCount(this.purdahCounter))
         {
            this.movieFinish(-1,this.tempType);
            this.purdahCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

