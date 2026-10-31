package mmo.fbteam.fbyishuzhidu.sceneplayer.scene2
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.dialog.NewDialog;
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
   
   public class Scene2_2Fight extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var tempBack:MovieClip;
      
      private var mcWing:MovieClip;
      
      private var mcFish:MovieClip;
      
      private var mcLong:MovieClip;
      
      private var mcChips:Sprite;
      
      private var petFight:IPetFight;
      
      private var wingStep:uint = 0;
      
      private var fishStep:uint = 0;
      
      private var wingCounter:uint;
      
      private var fishCounter:uint;
      
      private var commEndCounter:uint;
      
      private var fightCounter:uint;
      
      private var wingClicking:Boolean = false;
      
      private var fishClicking:Boolean = false;
      
      private var longClicking:Boolean = false;
      
      private var isFighting:Boolean = false;
      
      private var wingWin:Boolean = false;
      
      private var fishWin:Boolean = false;
      
      private var longWin:Boolean = false;
      
      private var wingBoss:uint = 30402;
      
      private var fishBoss:uint = 30403;
      
      private var longBoss:uint = 30401;
      
      private var tempType:String;
      
      public function Scene2_2Fight()
      {
         super();
         this.tempBack = this.sceneInfo.scene.backGround.getChildByName("tempback") as MovieClip;
         this.mcWing = this.tempBack.getChildByName("dinosaur_1") as MovieClip;
         this.mcFish = this.tempBack.getChildByName("dinosaur_2") as MovieClip;
         this.mcLong = this.tempBack.getChildByName("dinosaur_3") as MovieClip;
         this.mcWing.buttonMode = true;
         this.mcFish.buttonMode = true;
         this.mcLong.buttonMode = true;
         this.petFight = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.tempType = param1;
         this.mcWing.addEventListener(MouseEvent.CLICK,this.onClickWing);
         this.mcFish.addEventListener(MouseEvent.CLICK,this.onClickFish);
         this.mcLong.addEventListener(MouseEvent.CLICK,this.onClickLong);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         SocketClient.instance.addEventListener("teamReadyFight",this.teamNotReady);
      }
      
      private function onClickWing(param1:MouseEvent) : void
      {
         if(this.wingClicking)
         {
            return;
         }
         this.wingClicking = true;
         var _loc2_:Object = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_START
         };
         if(this.wingStep == 0)
         {
            ++this.wingStep;
            _loc2_.action = Scene2TempTypes.wing_appear_1;
            TeamSynchronizedClient.notify(_loc2_);
            this.showWingAppear("cloud1",20);
         }
         else if(this.wingStep == 1)
         {
            ++this.wingStep;
            _loc2_.action = Scene2TempTypes.wing_appear_2;
            TeamSynchronizedClient.notify(_loc2_);
            this.showWingAppear("cloud2",35);
         }
         else
         {
            this.petFight.fightInCopy(2);
         }
      }
      
      private function showWingAppear(param1:String, param2:uint) : void
      {
         var action:String = param1;
         var frame:uint = param2;
         this.mcWing.gotoAndPlay(action);
         this.mcWing.addFrameScript(frame,function():void
         {
            mcWing.stop();
            wingClicking = false;
         });
      }
      
      private function onClickFish(param1:MouseEvent) : void
      {
         if(this.fishClicking)
         {
            return;
         }
         this.fishClicking = true;
         var _loc2_:Object = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_START,
            "action":Scene2TempTypes.fish_appear
         };
         if(this.fishStep == 0)
         {
            ++this.fishStep;
            TeamSynchronizedClient.notify(_loc2_);
            this.showFishAppear("fishup",22);
         }
         else
         {
            this.petFight.fightInCopy(3);
         }
      }
      
      private function showFishAppear(param1:String, param2:uint) : void
      {
         var action:String = param1;
         var frame:uint = param2;
         this.mcFish.gotoAndPlay(action);
         this.mcFish.addFrameScript(frame,function():void
         {
            mcFish.stop();
            fishClicking = false;
         });
      }
      
      private function onClickLong(param1:MouseEvent) : void
      {
         if(this.longClicking)
         {
            return;
         }
         this.longClicking = true;
         this.petFight.fightInCopy(1);
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
         switch(_loc5_)
         {
            case Scene2TempTypes.wing_appear_1:
               this.showWingAppear("cloud1",20);
               break;
            case Scene2TempTypes.wing_appear_2:
               this.showWingAppear("cloud2",35);
               break;
            case Scene2TempTypes.wing_disappear:
               this.bossFightDown(this.mcWing);
               break;
            case Scene2TempTypes.fish_appear:
               this.showFishAppear("fishup",23);
               break;
            case Scene2TempTypes.fish_disappear:
               this.bossFightDown(this.mcFish);
               break;
            case Scene2TempTypes.long_down:
               this.bossFightDown(this.mcLong);
               break;
            case Scene2TempTypes.change_background:
               this.bossEndChangeBack();
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
         if(FBTeamCommonTypes.TYPE_END == _loc4_ && Scene2TempTypes.change_background == _loc5_)
         {
            this.commFinish();
         }
      }
      
      private function onEnterFail(param1:PetFightEvent) : void
      {
         NewDialog.showFailMessage("进入战斗失败");
         this.isFighting = false;
         this.resetClicking(param1.raceId);
      }
      
      private function resetClicking(param1:uint = 0) : void
      {
         this.wingClicking = false;
         this.fishClicking = false;
         this.longClicking = false;
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:Object = null;
         this.isFighting = false;
         this.resetClicking(param1.raceId);
         if(param1.isWin)
         {
            _loc2_ = {
               "teamkey":TeamHelper.getTeamKey(),
               "type":FBTeamCommonTypes.TYPE_START
            };
            switch(param1.raceId)
            {
               case this.wingBoss:
                  this.wingWin = true;
                  this.bossFightDown(this.mcWing);
                  break;
               case this.fishBoss:
                  this.fishWin = true;
                  this.bossFightDown(this.mcFish);
                  break;
               case this.longBoss:
                  this.longWin = true;
                  this.bossFightDown(this.mcLong);
            }
            this.checkFinish();
         }
      }
      
      private function bossFightDown(param1:MovieClip) : void
      {
         var _loc2_:uint = parseInt(param1.name.split("_")[1]);
         this.tempBack.getChildByName("chips_" + _loc2_).visible = true;
         param1.gotoAndStop(param1.totalFrames);
         param1.mouseChildren = false;
         param1.mouseEnabled = false;
      }
      
      private function checkFinish() : void
      {
         if(this.wingWin && this.fishWin && this.longWin)
         {
            this.bossEndChangeBack();
         }
      }
      
      private function bossEndChangeBack() : void
      {
         this.tempBack.gotoAndStop(2);
         var _loc1_:Object = {
            "teamkey":TeamHelper.getTeamKey(),
            "type":FBTeamCommonTypes.TYPE_END,
            "action":Scene2TempTypes.change_background
         };
         TeamSynchronizedClient.finishBack(_loc1_);
         this.commFinish();
         this.mcChips = this.tempBack.getChildByName("mcchips") as Sprite;
         this.mcChips.buttonMode = true;
         this.mcChips.addEventListener(MouseEvent.CLICK,this.onClickChips);
      }
      
      private function onClickChips(param1:MouseEvent) : void
      {
         if(TeamHelper.checkCount(this.commEndCounter))
         {
            this.mcChips.removeEventListener(MouseEvent.CLICK,this.onClickChips);
            this.movieFinish();
            this.commEndCounter = 0;
         }
      }
      
      private function commFinish() : void
      {
         ++this.commEndCounter;
         if(TeamHelper.checkCount(this.commEndCounter))
         {
            this.movieFinish(-1,this.tempType);
            this.commEndCounter = 0;
         }
      }
      
      private function teamNotReady(param1:SocketClientEvent) : void
      {
         this.resetClicking();
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onNotify);
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onFinishBack);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFail);
         SocketClient.instance.removeEventListener("teamReadyFight",this.teamNotReady);
         if(this.mcChips != null)
         {
            this.mcChips.removeEventListener(MouseEvent.CLICK,this.onClickChips);
            this.mcChips = null;
         }
      }
   }
}

