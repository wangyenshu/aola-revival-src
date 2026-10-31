package mmo.fbteam.fbyishuzhidu.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   
   public class YishuzhiduPlayer4_1showArcher extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var mcbtnArcher:MovieClip = null;
      
      private var btnArcher:SimpleButton = null;
      
      private const showArcherData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene4TempTypes.show_archer
      };
      
      private const showArcherData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene4TempTypes.show_archer
      };
      
      private var showArcherCounter:int = 0;
      
      public function YishuzhiduPlayer4_1showArcher()
      {
         super();
         this.mcbtnArcher = this.sceneInfo.scene.foreGround.getChildByName("mcbtn_archer") as MovieClip;
         this.mcbtnArcher.addFrameScript(this.mcbtnArcher.totalFrames - 1,this.mcbtnArcherEnd);
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.mcbtnArcher.addEventListener(MouseEvent.CLICK,this.onMcbtnArcher);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
      
      private function onNotify(param1:SocketClientEvent) : void
      {
         var _loc6_:Boolean = false;
         var _loc7_:int = 0;
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         var _loc5_:int = int(param1.params.obj.what);
         if(TeamHelper.getTeamKey() != _loc3_ || TeamSynchronizedClient.cmdNotify != _loc2_)
         {
            return;
         }
         if(FBTeamCommonTypes.TYPE_START == _loc4_ && Scene4TempTypes.show_archer == _loc5_)
         {
            _loc6_ = Boolean(param1.params.obj.isPlay);
            _loc7_ = int(param1.params.obj.aimF);
            this.nextStart(_loc6_,_loc7_);
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene4TempTypes.show_archer == _loc5_)
         {
            this.tryFinish();
         }
      }
      
      private function onMcbtnArcher(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         var _loc2_:SimpleButton = param1.target as SimpleButton;
         if(null == _loc2_)
         {
            this.isClicking = false;
            return;
         }
         param1.stopImmediatePropagation();
         var _loc3_:String = _loc2_.name;
         var _loc4_:Array = _loc3_.split("_");
         var _loc5_:Boolean = false;
         if(3 == _loc4_.length)
         {
            _loc5_ = true;
         }
         this.showArcherData1.aimF = _loc4_[1];
         this.showArcherData1.isPlay = _loc5_;
         this.nextStart(_loc5_,_loc4_[1]);
         TeamSynchronizedClient.notify(this.showArcherData1);
      }
      
      private function nextStart(param1:Boolean, param2:int) : void
      {
         if(param1)
         {
            this.mcbtnArcher.removeEventListener(MouseEvent.CLICK,this.onMcbtnArcher);
            this.mcbtnArcher.gotoAndPlay(param2);
         }
         else
         {
            this.mcbtnArcher.gotoAndStop(param2);
         }
         this.isClicking = false;
      }
      
      private function mcbtnArcherEnd() : void
      {
         this.btnArcher = this.mcbtnArcher.getChildByName("btnarcher") as SimpleButton;
         this.sceneInfo.scene.foreGround.addChild(this.btnArcher);
         DisplayUtil.stopAndRemove(this.mcbtnArcher);
         this.tryFinish();
         TeamSynchronizedClient.finishBack(this.showArcherData2);
      }
      
      private function tryFinish() : void
      {
         ++this.showArcherCounter;
         if(TeamHelper.checkCount(this.showArcherCounter))
         {
            this.movieFinish();
            this.showArcherCounter = 0;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

