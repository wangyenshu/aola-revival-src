package mmo.fbteam.fbyishuzhidu.sceneplayer.scene2
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class Scene2_3Chips extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var tempBack:MovieClip;
      
      private var mcChips:MovieClip;
      
      private var chipsClicking:Boolean = false;
      
      private var isClicked:Boolean = false;
      
      private var mixCounter:uint = 0;
      
      private var tempType:String;
      
      public function Scene2_3Chips()
      {
         super();
         this.tempBack = this.sceneInfo.scene.backGround.getChildByName("tempback") as MovieClip;
         this.mcChips = this.tempBack.getChildByName("mcchips") as MovieClip;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.tempType = param1;
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         this.mcChips.buttonMode = true;
         this.mcChips.addEventListener(MouseEvent.CLICK,this.onClickChips);
      }
      
      private function onClickChips(param1:MouseEvent) : void
      {
         var _loc2_:Object = null;
         if(this.chipsClicking)
         {
            return;
         }
         if(!this.isClicked)
         {
            this.chipsClicking = true;
            _loc2_ = {
               "teamkey":TeamHelper.getTeamKey(),
               "type":FBTeamCommonTypes.TYPE_START,
               "action":Scene2TempTypes.chips_mix
            };
            TeamSynchronizedClient.notify(_loc2_);
            this.showChipsMovie("showmix",53);
         }
         else if(TeamHelper.checkCount(this.mixCounter))
         {
            this.movieFinish();
            this.mixCounter = 0;
         }
      }
      
      private function showChipsMovie(param1:String, param2:uint) : void
      {
         var endData:Object;
         var action:String = param1;
         var frame:uint = param2;
         this.isClicked = true;
         this.mcChips.gotoAndPlay(action);
         endData = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_END,
            "action":Scene2TempTypes.chips_mix
         };
         TeamSynchronizedClient.finishBack(endData);
         this.mcChips.addFrameScript(frame,function():void
         {
            mcChips.stop();
            chipsClicking = false;
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
         if(_loc5_ == Scene2TempTypes.chips_mix)
         {
            this.showChipsMovie("showmix",53);
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene2TempTypes.chips_mix == _loc5_)
         {
            this.commFinish();
         }
      }
      
      private function commFinish() : void
      {
         ++this.mixCounter;
         if(TeamHelper.checkCount(this.mixCounter))
         {
            this.movieFinish(-1,this.tempType);
            this.mixCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         if(this.mcChips != null)
         {
            this.mcChips.removeEventListener(MouseEvent.CLICK,this.onClickChips);
            this.mcChips = null;
         }
      }
   }
}

