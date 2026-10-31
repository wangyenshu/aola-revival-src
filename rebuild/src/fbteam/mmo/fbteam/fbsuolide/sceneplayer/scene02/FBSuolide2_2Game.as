package mmo.fbteam.fbsuolide.sceneplayer.scene02
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.player.PlayerManager;
   
   public class FBSuolide2_2Game extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private static const initPoint:Point = new Point(230,350);
      
      private var sysData:Object = {"what":FBSuolide_Scene2TempTypes.FBSuolide2_2Game};
      
      private var sysData2:Object = {"what":FBSuolide_Scene2TempTypes.FBSuolide2_2Game_1};
      
      private var sysData3:Object = {"what":FBSuolide_Scene2TempTypes.FBSuolide2_2Game_2};
      
      private var petId:int = 1;
      
      private var flagsKey:Array = null;
      
      private var flagsObj:Array = null;
      
      private var floorObj:Array = null;
      
      private var currentFightX:int = -1;
      
      private var currentFightY:int = -1;
      
      private var resetX:int;
      
      private var resetY:int;
      
      public function FBSuolide2_2Game()
      {
         super();
         this.gameDataInit();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.flagstoneGame,this.sysData,"fb_suolide2_talk_1_end");
         this.setNotify(this.killOneBoss,this.sysData2);
         this.setNotify(this.tryGameReset,this.sysData3);
      }
      
      private function getPars() : void
      {
      }
      
      private function gameDataInit() : void
      {
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         var _loc4_:Sprite = null;
         this.flagsKey = [[1,1,3,3],[1,1,1,1],[2,3,1,2],[3,1,1,3]];
         this.flagsObj = [];
         this.floorObj = [];
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            this.flagsObj[_loc1_] = [];
            this.floorObj[_loc1_] = [];
            _loc2_ = 0;
            while(_loc2_ < 4)
            {
               _loc3_ = this.sceneInfo.scene.container.getChildByName("mc_flagstone" + _loc1_ + _loc2_) as MovieClip;
               _loc4_ = this.getObstruction().getChildByName("floor" + _loc1_ + _loc2_) as Sprite;
               _loc3_.gotoAndStop(1);
               this.flagsObj[_loc1_][_loc2_] = _loc3_;
               this.floorObj[_loc1_][_loc2_] = _loc4_;
               _loc2_++;
            }
            _loc1_++;
         }
      }
      
      private function flagstoneGame() : void
      {
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         var _loc4_:SimpleButton = null;
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            _loc2_ = 0;
            while(_loc2_ < 4)
            {
               _loc3_ = this.flagsObj[_loc1_][_loc2_] as MovieClip;
               _loc4_ = _loc3_.btn_flag as SimpleButton;
               if(null != _loc4_)
               {
                  _loc4_.addEventListener(MouseEvent.CLICK,this.onClickFlagsObj);
                  _loc3_.mouseChildren = true;
               }
               _loc2_++;
            }
            _loc1_++;
         }
      }
      
      private function disableButton() : void
      {
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         var _loc4_:SimpleButton = null;
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            _loc2_ = 0;
            while(_loc2_ < 4)
            {
               _loc3_ = this.flagsObj[_loc1_][_loc2_] as MovieClip;
               _loc4_ = _loc3_.btn_flag as SimpleButton;
               if(null != _loc4_)
               {
                  _loc4_.removeEventListener(MouseEvent.CLICK,this.onClickFlagsObj);
                  _loc3_.mouseChildren = false;
               }
               _loc2_++;
            }
            _loc1_++;
         }
      }
      
      private function onClickFlagsObj(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         var _loc2_:SimpleButton = param1.target as SimpleButton;
         if(null == _loc2_ || _loc2_.name != "btn_flag")
         {
            this.isClicking = false;
            return;
         }
         param1.stopImmediatePropagation();
         var _loc3_:MovieClip = _loc2_.parent as MovieClip;
         var _loc4_:String = _loc3_.name;
         var _loc5_:int = int(_loc4_.substr(12,1));
         var _loc6_:int = int(_loc4_.substr(13,1));
         if(this.checkClickable(_loc5_,_loc6_))
         {
            switch(this.flagsKey[_loc5_][_loc6_])
            {
               case 1:
                  this.tryFight(_loc5_,_loc6_);
                  break;
               case 2:
                  this.revealAllHp(_loc5_,_loc6_);
                  break;
               case 3:
                  this.addNotifyParams(this.sysData3,{
                     "x":_loc5_,
                     "y":_loc6_
                  });
                  this.notify(this.sysData3);
            }
         }
         else
         {
            this.isClicking = false;
         }
      }
      
      private function checkClickable(param1:int, param2:int) : Boolean
      {
         if(param1 == 0)
         {
            return true;
         }
         if(this.checkKeyClickable(param1 - 1,param2) || this.checkKeyClickable(param1 + 1,param2) || this.checkKeyClickable(param1,param2 - 1) || this.checkKeyClickable(param1,param2 + 1))
         {
            return true;
         }
         return false;
      }
      
      private function tryFight(param1:int, param2:int) : void
      {
         var mc:MovieClip;
         var timer:Timer = null;
         var onTimerEnd:Function = null;
         var x:int = param1;
         var y:int = param2;
         this.currentFightX = x;
         this.currentFightY = y;
         mc = this.flagsObj[x][y];
         if(mc.currentFrame == 1)
         {
            timer = new Timer(3600,1);
            onTimerEnd = function(param1:TimerEvent):void
            {
               timer.removeEventListener(TimerEvent.TIMER,onTimerEnd);
               timer.stop();
               fight();
            };
            mc.gotoAndPlay("turn");
            timer.addEventListener(TimerEvent.TIMER,onTimerEnd);
            timer.start();
         }
         else
         {
            this.fight();
         }
      }
      
      private function fight() : void
      {
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onStartFightFail);
         _loc1_.fightInCopy(this.petId);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onStartFightFail);
         if(param1.isWin)
         {
            this.addNotifyParams(this.sysData2,{
               "x":this.currentFightX,
               "y":this.currentFightY
            });
            this.notify(this.sysData2);
         }
         else
         {
            this.isClicking = false;
         }
      }
      
      private function killOneBoss(param1:Object) : void
      {
         var mc:MovieClip = null;
         var params:Object = param1;
         ++this.petId;
         mc = this.flagsObj[params.x][params.y];
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            mc.stop();
            removeFlagAt(params.x,params.y);
            isClicking = false;
         });
         mc.gotoAndPlay("disappear");
      }
      
      private function onStartFightFail(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onStartFightFail);
         this.isClicking = false;
      }
      
      private function removeFlagAt(param1:int, param2:int) : void
      {
         this.flagsKey[param1][param2] = 0;
         this.sceneInfo.scene.container.removeChild(this.flagsObj[param1][param2]);
         this.getObstruction().removeChild(this.floorObj[param1][param2]);
         this.isClicking = false;
         this.sceneInfo.scene.setMapArray();
         if(3 == param1)
         {
            this.disableButton();
            this.finishStep();
         }
      }
      
      private function revealAllHp(param1:int, param2:int) : void
      {
         var mc:MovieClip = null;
         var x:int = param1;
         var y:int = param2;
         var onRevealHP:Function = function():void
         {
            isClicking = false;
            NewDialog.showSucceedMessage("你所携带的亚比得到了恢复！");
         };
         mc = this.flagsObj[x][y] as MovieClip;
         var fbteam:IFBTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         PetClient2.instance.pmRevealAllHpFree();
         mc.addFrameScript(mc.totalFrames - 1,function():*
         {
            mc.stop();
            sceneInfo.scene.container.removeChild(mc);
            getObstruction().removeChild(floorObj[x][y]);
            sceneInfo.scene.setMapArray();
            onRevealHP();
         });
         mc.gotoAndPlay(2);
         this.flagsKey[x][y] = 0;
      }
      
      private function tryGameReset(param1:Object) : void
      {
         var mc:MovieClip = null;
         var params:Object = param1;
         mc = this.flagsObj[params.x][params.y];
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            mc.stop();
            gameReset();
            isClicking = false;
         });
         mc.gotoAndPlay(2);
      }
      
      private function checkKeyClickable(param1:int, param2:int) : Boolean
      {
         if(param1 < 0 || param1 > 3 || param2 < 0 || param2 > 3)
         {
            return false;
         }
         if(this.flagsKey[param1][param2] == 0)
         {
            return true;
         }
         return false;
      }
      
      private function gameReset() : void
      {
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         this.flagsKey = [[1,1,3,3],[1,1,1,1],[2,3,1,2],[3,1,1,3]];
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            _loc2_ = 0;
            while(_loc2_ < 4)
            {
               _loc3_ = this.flagsObj[_loc1_][_loc2_] as MovieClip;
               _loc3_.gotoAndStop(1);
               this.sceneInfo.scene.container.addChild(_loc3_);
               this.getObstruction().addChild(this.floorObj[_loc1_][_loc2_]);
               _loc2_++;
            }
            _loc1_++;
         }
         PlayerManager.getInstance().myPlayer.jumpTo(initPoint.x,initPoint.y);
         this.sceneInfo.scene.setMapArray();
         SocketClient.instance.addEventListener(FbClient.cmdResetScene,this.onResetSuccess);
         FbClient.instance.resetScenePet();
      }
      
      private function onResetSuccess(param1:SocketClientEvent) : void
      {
         this.petId = 1;
         SocketClient.instance.removeEventListener(FbClient.cmdResetScene,this.onResetSuccess);
         var _loc2_:Boolean = Boolean(param1.params.res);
         if(_loc2_)
         {
            if(TeamHelper.isCaptain())
            {
               NewDialog.showFailMessage("石像迷阵被重置了！");
            }
            this.isClicking = false;
            return;
         }
         throw new Error("石像重置错误！");
      }
      
      public function dispose() : void
      {
         this.isClicking = false;
         this.flagsKey = null;
         this.flagsObj = null;
         this.floorObj = null;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onStartFightFail);
         SocketClient.instance.removeEventListener(FbClient.cmdResetScene,this.onResetSuccess);
         super.disposeEvt();
      }
   }
}

