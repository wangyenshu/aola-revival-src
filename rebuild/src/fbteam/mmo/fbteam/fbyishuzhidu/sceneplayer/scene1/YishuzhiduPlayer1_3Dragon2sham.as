package mmo.fbteam.fbyishuzhidu.sceneplayer.scene1
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class YishuzhiduPlayer1_3Dragon2sham extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const dragon2shamData1:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":Scene1TempTypes.dragon_sham
      };
      
      private const dragon2shamData2:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":Scene1TempTypes.dragon_sham
      };
      
      private var dragon2shamCounter:int = 0;
      
      private var mcCounter:int = 0;
      
      private var btnDragon1:SimpleButton = null;
      
      private var btnDragon2:SimpleButton = null;
      
      private var btnDragon3:SimpleButton = null;
      
      private var mcBackground:MovieClip = null;
      
      private var mcDragon2sham:MovieClip = null;
      
      private var btnCard:SimpleButton = null;
      
      private var dragonStone:Sprite = null;
      
      private var white:MovieClip = null;
      
      private var ipf:IPetFight = null;
      
      public function YishuzhiduPlayer1_3Dragon2sham()
      {
         super();
         this.btnDragon1 = this.sceneInfo.scene.container.getChildByName("btndragon1") as SimpleButton;
         this.btnDragon2 = this.sceneInfo.scene.container.getChildByName("btndragon2") as SimpleButton;
         this.btnDragon3 = this.sceneInfo.scene.container.getChildByName("btndragon3") as SimpleButton;
         this.mcBackground = this.sceneInfo.scene.backGround.getChildByName("mc_background") as MovieClip;
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnDragon1.addEventListener(MouseEvent.CLICK,this.onTryFighting);
         this.btnDragon2.addEventListener(MouseEvent.CLICK,this.onTryFighting);
         this.btnDragon3.addEventListener(MouseEvent.CLICK,this.onTryFighting);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.addEventListener("teamReadyFight",this.onEnterFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
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
         if(FBTeamCommonTypes.TYPE_START == _loc4_ && Scene1TempTypes.dragon_sham == _loc5_)
         {
            this.fightEndFinish();
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene1TempTypes.dragon_sham == _loc5_)
         {
            this.stepFinish();
         }
      }
      
      private function onTryFighting(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.ipf.fightInCopy(1);
      }
      
      private function onEnterFail(param1:Event) : void
      {
         this.isClicking = false;
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         if(param1.isWin)
         {
            this.removePetFightListener();
            this.btnDragon1.addEventListener(MouseEvent.CLICK,this.onContinus);
            this.btnDragon2.addEventListener(MouseEvent.CLICK,this.onContinus);
            this.btnDragon3.addEventListener(MouseEvent.CLICK,this.onContinus);
            this.fightEndFinish();
            TeamSynchronizedClient.notify(this.dragon2shamData1);
         }
      }
      
      private function onContinus(param1:MouseEvent) : void
      {
         this.check2showmc();
      }
      
      private function check2showmc() : void
      {
         if(TeamHelper.checkCount(this.mcCounter))
         {
            this.remove3dragon();
            this.showDragon2sham();
            this.mcCounter = 0;
         }
      }
      
      private function fightEndFinish() : void
      {
         ++this.mcCounter;
         this.check2showmc();
      }
      
      private function showDragon2sham() : void
      {
         var _loc1_:String = "mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.Dragon2sham";
         var _loc2_:Class = FBConfig.instence.getClass(_loc1_) as Class;
         this.mcDragon2sham = new _loc2_() as MovieClip;
         this.mcDragon2sham.name = "mcdragon2sham";
         this.mcDragon2sham.addFrameScript(this.mcDragon2sham.totalFrames - 1,this.dragon2shamEnd);
         this.sceneInfo.scene.foreGround.addChild(this.mcDragon2sham);
      }
      
      private function dragon2shamEnd() : void
      {
         this.btnCard = this.mcDragon2sham.getChildByName("btnCard") as SimpleButton;
         this.dragonStone = this.mcDragon2sham.getChildByName("dragonstone") as Sprite;
         this.sceneInfo.scene.foreGround.addChild(this.dragonStone);
         this.sceneInfo.scene.foreGround.addChild(this.btnCard);
         TipsManager.getInstance().addTips(this.btnCard,"通行卡片");
         DisplayUtil.stopAndRemove(this.mcDragon2sham);
         this.mcBackground.gotoAndStop(2);
         this.showWhite();
      }
      
      private function showWhite() : void
      {
         var _loc1_:String = "mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.White";
         var _loc2_:Class = FBConfig.instence.getClass(_loc1_) as Class;
         this.white = new _loc2_() as MovieClip;
         this.white.addFrameScript(this.white.totalFrames - 1,this.onWhiteEnd);
         this.sceneInfo.scene.foreGround.addChild(this.white);
      }
      
      private function onWhiteEnd() : void
      {
         DisplayUtil.stopAndRemove(this.white);
         this.tryStepFinish();
      }
      
      private function tryStepFinish() : void
      {
         this.stepFinish();
         TeamSynchronizedClient.finishBack(this.dragon2shamData2);
      }
      
      private function stepFinish() : void
      {
         ++this.dragon2shamCounter;
         if(TeamHelper.checkCount(this.dragon2shamCounter))
         {
            this.movieFinish();
            this.dragon2shamCounter = 0;
         }
      }
      
      private function remove3dragon() : void
      {
         DisplayUtil.stopAndRemove(this.btnDragon1);
         DisplayUtil.stopAndRemove(this.btnDragon2);
         DisplayUtil.stopAndRemove(this.btnDragon3);
         this.btnDragon1.removeEventListener(MouseEvent.CLICK,this.onContinus);
         this.btnDragon2.removeEventListener(MouseEvent.CLICK,this.onContinus);
         this.btnDragon3.removeEventListener(MouseEvent.CLICK,this.onContinus);
      }
      
      private function removePetFightListener() : void
      {
         this.btnDragon1.removeEventListener(MouseEvent.CLICK,this.onTryFighting);
         this.btnDragon2.removeEventListener(MouseEvent.CLICK,this.onTryFighting);
         this.btnDragon3.removeEventListener(MouseEvent.CLICK,this.onTryFighting);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         SocketClient.instance.removeEventListener("teamReadyFight",this.onEnterFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
      }
      
      public function dispose() : void
      {
         this.removePetFightListener();
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
      }
   }
}

