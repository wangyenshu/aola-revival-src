package mmo.fbteam.fbyishuzhidu.sceneplayer.scene4
{
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class YishuzhiduPlayer4_2fightArcher extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const fightArcherData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene4TempTypes.fight_archer
      };
      
      private const fightArcherData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene4TempTypes.fight_archer
      };
      
      private var fightArcherCounter:int = 0;
      
      private const ON_ENTER_FAIL:String = "teamReadyFight";
      
      private var ipf:IPetFight = null;
      
      private var btnArcher:SimpleButton = null;
      
      public function YishuzhiduPlayer4_2fightArcher()
      {
         super();
         this.btnArcher = this.sceneInfo.scene.foreGround.getChildByName("btnarcher") as SimpleButton;
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnArcher.addEventListener(MouseEvent.CLICK,this.onbtnArcher);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.addEventListener(this.ON_ENTER_FAIL,this.onEnterFail);
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene4TempTypes.fight_archer == _loc5_)
         {
            this.tryFinish();
         }
      }
      
      private function onbtnArcher(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.ipf.fightInCopy(1);
      }
      
      private function onEnterFail(param1:SocketClientEvent) : void
      {
         this.isClicking = false;
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         if(param1.isWin)
         {
            this.btnArcher.removeEventListener(MouseEvent.CLICK,this.onbtnArcher);
            this.btnArcher.addEventListener(MouseEvent.CLICK,this.onContinue);
            this.tryFinish();
            TeamSynchronizedClient.finishBack(this.fightArcherData2);
            this.btnArcher.mouseEnabled = false;
         }
      }
      
      private function onContinue(param1:MouseEvent) : void
      {
         this.check2finish();
      }
      
      private function check2finish() : void
      {
         if(TeamHelper.checkCount(this.fightArcherCounter))
         {
            this.movieFinish();
            this.fightArcherCounter = 0;
            this.btnArcher.removeEventListener(MouseEvent.CLICK,this.onContinue);
         }
      }
      
      private function tryFinish() : void
      {
         ++this.fightArcherCounter;
         this.check2finish();
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.removeEventListener(this.ON_ENTER_FAIL,this.onEnterFail);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

