package mmo.fbservice.fbsuolide.fbsceneplayer.scene2
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.framework.comm.FbClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer2_2Game extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const initPoint:Point = new Point(230,350);
      
      private var type:String = null;
      
      private var petId:int = 1;
      
      private var flagsKey:Array = null;
      
      private var flagsObj:Array = null;
      
      private var floorObj:Array = null;
      
      private var currentFightX:int = -1;
      
      private var currentFightY:int = -1;
      
      private var cat:DisplayObject = null;
      
      public function SuolidePlayer2_2Game()
      {
         super();
         this.gameDataInit();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.flagstoneGame();
      }
      
      private function getPars() : void
      {
         this.cat = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("cat_follower") as DisplayObject;
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
                  this.tryGameReset(_loc5_,_loc6_);
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
         var mc:MovieClip = null;
         var e:PetFightEvent = param1;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onStartFightFail);
         if(e.isWin)
         {
            ++this.petId;
            mc = this.flagsObj[this.currentFightX][this.currentFightY];
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               mc.stop();
               removeFlagAt(currentFightX,currentFightY);
               isClicking = false;
            });
            mc.gotoAndPlay("disappear");
         }
         else
         {
            this.isClicking = false;
         }
      }
      
      private function onStartFightFail(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onStartFightFail);
         this.isClicking = false;
      }
      
      private function removeFlagAt(param1:int, param2:int) : void
      {
         var _loc3_:ITaskService = null;
         this.flagsKey[param1][param2] = 0;
         this.sceneInfo.scene.container.removeChild(this.flagsObj[param1][param2]);
         this.getObstruction().removeChild(this.floorObj[param1][param2]);
         this.isClicking = false;
         this.sceneInfo.scene.setMapArray();
         if(3 == param1)
         {
            this.movieFinish(-1,this.type);
            this.disableButton();
            _loc3_ = ServiceContainer.getService(ITaskService) as ITaskService;
            if(Boolean(_loc3_.isUserTaskDoing(567)) && Boolean(_loc3_.isUserTaskDoing(570)))
            {
               TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":570}));
            }
            _loc3_ = null;
         }
      }
      
      private function revealAllHp(param1:int, param2:int) : void
      {
         var mc:MovieClip = null;
         var fbService:IFbService = null;
         var onSocket:Function = null;
         var x:int = param1;
         var y:int = param2;
         mc = this.flagsObj[x][y] as MovieClip;
         fbService = ServiceContainer.getService(IFbService) as IFbService;
         onSocket = function(param1:FbEvent):void
         {
            fbService.removeEventListener(FbEvent.ON_HEAL_HP_AND_PP,onSocket);
            NewDialog.showSucceedMessage("你所携带的亚比得到了恢复！");
            isClicking = false;
         };
         mc.addFrameScript(mc.totalFrames - 1,function():*
         {
            mc.stop();
            fbService.addEventListener(FbEvent.ON_HEAL_HP_AND_PP,onSocket);
            sceneInfo.scene.container.removeChild(mc);
            getObstruction().removeChild(floorObj[x][y]);
            fbService.healHpAndPP({});
            sceneInfo.scene.setMapArray();
         });
         mc.gotoAndPlay(2);
         this.flagsKey[x][y] = 0;
      }
      
      private function tryGameReset(param1:int, param2:int) : void
      {
         var mc:MovieClip = null;
         var x:int = param1;
         var y:int = param2;
         mc = this.flagsObj[x][y];
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
         this.cat.x = initPoint.x;
         this.cat.y = initPoint.y;
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
            NewDialog.showFailMessage("石像迷阵被重置了！");
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
      }
   }
}

