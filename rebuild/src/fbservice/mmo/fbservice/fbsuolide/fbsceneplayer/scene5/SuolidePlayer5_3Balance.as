package mmo.fbservice.fbsuolide.fbsceneplayer.scene5
{
   import flash.display.Bitmap;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.common.DisplayUtil;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.data.UserTask;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class SuolidePlayer5_3Balance extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const yDown:Number = 402.5;
      
      private static const yUp:Number = 487.5;
      
      private var type:String = null;
      
      private var lCounter:int = 0;
      
      private var rCounter:int = 0;
      
      private var aimScene:int = -1;
      
      private var nextSceneName:String = null;
      
      private var mcBalance:MovieClip = null;
      
      private var mcGo:MovieClip = null;
      
      private var lContainer:Sprite = null;
      
      private var rContainer:Sprite = null;
      
      private var mcYardL:MovieClip = null;
      
      private var isLYardOn:int = 0;
      
      private var mcYardR:MovieClip = null;
      
      private var isRYardOn:int = 0;
      
      private var lBalance:MovieClip = null;
      
      private var btnReset:SimpleButton = null;
      
      private var obsBalance:Sprite = null;
      
      private var mcPoint1:Sprite = null;
      
      private var mcPoint2:Sprite = null;
      
      private var mc133appear:MovieClip = null;
      
      private var cat:ScenePlayer = null;
      
      private var timer:Timer = null;
      
      private var bitMap:Bitmap = null;
      
      public function SuolidePlayer5_3Balance()
      {
         super();
         this.resInit();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.balance(param2,param3,param4);
      }
      
      private function resInit() : void
      {
         this.mcBalance = this.sceneInfo.scene.container.getChildByName("mc_balance") as MovieClip;
         this.mcYardL = this.sceneInfo.scene.container.getChildByName("mc_yardL") as MovieClip;
         this.mcYardR = this.sceneInfo.scene.container.getChildByName("mc_yardR") as MovieClip;
         this.mcGo = this.mcBalance.getChildByName("mc_go") as MovieClip;
         this.lContainer = this.mcGo.getChildByName("containerL") as Sprite;
         this.rContainer = this.mcGo.getChildByName("containerR") as Sprite;
         this.lBalance = this.mcGo.getChildByName("lObj") as MovieClip;
         this.btnReset = this.mcGo.getChildByName("btn_reset") as SimpleButton;
         this.mc133appear = this.sceneInfo.scene.container.getChildByName("mc_133appear") as MovieClip;
         this.obsBalance = this.getObstruction().getChildByName("obs_balance") as Sprite;
         this.mcPoint1 = this.getObstruction().getChildByName("point1") as Sprite;
         this.mcPoint2 = this.getObstruction().getChildByName("point2") as Sprite;
         this.removeBalanceUngoArea();
         this.cat = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("cat_Follower") as ScenePlayer;
      }
      
      private function removeBalanceUngoArea() : void
      {
         DisplayUtil.stopAndRemove(this.obsBalance);
         this.sceneInfo.scene.setMapArray();
      }
      
      private function addBalanceUngoArea() : void
      {
         this.getObstruction().addChild(this.obsBalance);
         this.sceneInfo.scene.setMapArray();
      }
      
      private function balance(param1:Boolean, param2:Function = null, param3:Object = null) : void
      {
         if(param1)
         {
            this.addYardFrameScript();
            ClickAndHitHelper.instance.registerTarget(this.lBalance,false,140);
            this.lBalance.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onWalkToGo);
            this.mcYardL.addEventListener(MouseEvent.CLICK,this.onYardClick);
            this.mcYardL.buttonMode = true;
            this.mcYardR.addEventListener(MouseEvent.CLICK,this.onYardClick);
            this.mcYardR.buttonMode = true;
            this.btnReset.addEventListener(MouseEvent.CLICK,this.onReset);
         }
         else
         {
            ClickAndHitHelper.instance.remove(this.lBalance);
            this.lBalance.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onWalkToGo);
            this.mcYardL.removeEventListener(MouseEvent.CLICK,this.onYardClick);
            this.mcYardL.buttonMode = false;
            this.mcYardR.removeEventListener(MouseEvent.CLICK,this.onYardClick);
            this.mcYardR.buttonMode = false;
            this.btnReset.removeEventListener(MouseEvent.CLICK,this.onReset);
         }
      }
      
      private function addYardFrameScript() : void
      {
         this.mcYardL.addFrameScript(this.mcYardL.totalFrames - 1,function():void
         {
            mcYardL.stop();
            isLYardOn = 0;
            checkFinish();
         });
         this.mcYardL.addFrameScript(20 - 1,function():void
         {
            mcYardL.stop();
            isLYardOn = 2;
            checkFinish();
         });
         this.mcYardR.addFrameScript(this.mcYardR.totalFrames - 1,function():void
         {
            mcYardR.stop();
            isRYardOn = 0;
            checkFinish();
         });
         this.mcYardR.addFrameScript(20 - 1,function():void
         {
            mcYardR.stop();
            isRYardOn = 2;
            checkFinish();
         });
         this.mcGo.addFrameScript(this.mcGo.totalFrames - 1 - 1,function():void
         {
            mcGo.stop();
            mcYardR.mouseEnabled = false;
            mcYardL.mouseEnabled = false;
            isClicking = false;
            checkLoadScene();
         });
      }
      
      private function checkLoadScene() : void
      {
         var _loc1_:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         var _loc2_:Boolean = false;
         if(Boolean(_loc1_.isUserTaskDoing(567)) && Boolean(_loc1_.isUserTaskDoing(573)))
         {
            _loc2_ = true;
         }
         else
         {
            _loc2_ = false;
         }
         switch(this.aimScene)
         {
            case 1:
               if(_loc2_)
               {
                  this.nextSceneName = "fbsuolide8";
                  TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_USER_TASK_ADD,this.onTaskAdd574);
                  TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":573}));
                  this.movieFinish(-1,this.type);
               }
               else
               {
                  SceneManager.getInstance().loadFB("fbsuolide8","fbsuolide");
                  this.movieFinish(-1,this.type);
               }
               break;
            case 2:
               if(_loc2_)
               {
                  this.nextSceneName = "fbsuolide6";
                  TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_USER_TASK_ADD,this.onTaskAdd574);
                  TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":573}));
                  this.movieFinish(-1,this.type);
               }
               else
               {
                  SceneManager.getInstance().loadFB("fbsuolide6","fbsuolide");
                  this.movieFinish(-1,this.type);
               }
         }
      }
      
      private function onTaskAdd574(param1:TaskEvent) : *
      {
         var _loc2_:UserTask = param1.params.t as UserTask;
         var _loc3_:int = int(_loc2_.taskId);
         if(574 == _loc3_)
         {
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_USER_TASK_ADD,this.onTaskAdd574);
            TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":574}));
            SceneManager.getInstance().loadFB(this.nextSceneName,"fbsuolide");
         }
      }
      
      private function checkFinish() : void
      {
         this.compute();
         if(this.lCounter > this.rCounter)
         {
            this.balanceGo();
         }
         else
         {
            this.isClicking = false;
         }
      }
      
      private function compute() : void
      {
         this.lCounter = this.isLYardOn;
         this.rCounter = this.isRYardOn;
         var _loc1_:PlayerBase = PlayerManager.getInstance().myPlayer;
         var _loc2_:MovieClip = this.mcGo.getChildByName("rObj") as MovieClip;
         this.aimScene = -1;
         if(this.checkLeftPlayerHitBalance(_loc1_.x,_loc1_.y))
         {
            ++this.lCounter;
            this.aimScene = 1;
            return;
         }
         if(_loc2_.hitTestObject(_loc1_))
         {
            ++this.rCounter;
            this.aimScene = 2;
            return;
         }
      }
      
      private function checkLeftPlayerHitBalance(param1:Number, param2:Number) : Boolean
      {
         var _loc6_:Number = NaN;
         var _loc3_:Point = this.mcPoint1.localToGlobal(new Point(0,0));
         var _loc4_:Point = this.mcPoint2.localToGlobal(new Point(0,0));
         var _loc5_:Number = (_loc4_.y - _loc3_.y) / (_loc4_.x - _loc3_.y);
         if(param2 > yDown && param2 < yUp)
         {
            _loc6_ = (_loc4_.y - _loc3_.y) / (_loc4_.x - _loc3_.x) * param1 + (_loc3_.x * _loc4_.y - _loc4_.x * _loc3_.y) / (_loc3_.x - _loc4_.x);
            if(param2 < _loc6_)
            {
               return true;
            }
         }
         return false;
      }
      
      private function balanceGo() : void
      {
         var _loc1_:Class = null;
         var _loc2_:Sprite = null;
         if(this.isLYardOn)
         {
            _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.fbsuolide5.LeftYard") as Class;
            _loc2_ = new _loc1_() as Sprite;
            this.lContainer.addChild(_loc2_);
            this.mcYardL.visible = false;
         }
         if(this.isRYardOn)
         {
            _loc1_ = Tool.instence.getClass("mmo.scene.fbsuolide.fbsuolide5.RigthYard") as Class;
            _loc2_ = new _loc1_() as Sprite;
            this.rContainer.addChild(_loc2_);
            this.mcYardR.visible = false;
         }
         this.addPlayerToBalance();
         this.addBalanceUngoArea();
         this.mcGo.play();
      }
      
      private function addPlayerToBalance() : void
      {
         var _loc1_:Sprite = null;
         if(this.aimScene == 1 || this.aimScene == 2)
         {
            PlayerManager.getInstance().myPlayer.visible = false;
            this.bitMap = this.getPlayer();
            this.cat.stop();
            this.cat.y = 0;
            _loc1_ = null;
            if(1 == this.aimScene)
            {
               _loc1_ = this.lContainer;
               this.cat.x = -50;
            }
            if(2 == this.aimScene)
            {
               _loc1_ = this.rContainer;
               this.cat.x = 50;
            }
            _loc1_.addChild(this.bitMap);
            _loc1_.addChild(this.cat);
            _loc1_ = null;
         }
      }
      
      private function getPlayer() : Bitmap
      {
         var _loc1_:Bitmap = PlayerManager.getInstance().getPlayerBitmap();
         _loc1_.x = -25;
         _loc1_.y = -100;
         return _loc1_;
      }
      
      private function onWalkToGo(param1:ClickAndHitEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.checkFinish();
      }
      
      private function onYardClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         var _loc3_:String = _loc2_.name;
         var _loc4_:String = _loc2_.currentFrameLabel;
         _loc2_.play();
      }
      
      private function onReset(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.timer = new Timer(10,0);
         this.timer.addEventListener(TimerEvent.TIMER,this.onTime);
         this.timer.start();
         this.mcGo.gotoAndStop(1);
         this.mcYardL.visible = true;
         this.mcYardL.gotoAndStop(1);
         this.mcYardR.visible = true;
         this.mcYardR.gotoAndStop(1);
         this.isLYardOn = 0;
         this.isRYardOn = 0;
         var _loc2_:int = 0;
         while(_loc2_ < this.lContainer.numChildren)
         {
            this.lContainer.removeChildAt(0);
            _loc2_++;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.rContainer.numChildren)
         {
            this.rContainer.removeChildAt(0);
            _loc3_++;
         }
         PlayerManager.getInstance().myPlayer.visible = true;
         if(this.bitMap != null && this.bitMap.parent != null)
         {
            this.bitMap.parent.removeChild(this.bitMap);
         }
         this.mcYardL.mouseEnabled = true;
         this.mcYardR.mouseEnabled = true;
         this.removeBalanceUngoArea();
      }
      
      private function onTime(param1:TimerEvent) : void
      {
         if(this.mcGo.currentFrame == 1 && this.mcYardL.currentFrame == 1 && this.mcYardR.currentFrame == 1)
         {
            this.timer.stop();
            this.timer.removeEventListener(TimerEvent.TIMER,this.onTime);
            this.isClicking = false;
         }
      }
      
      public function dispose() : void
      {
         if(null != this.lBalance)
         {
            this.lBalance.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onWalkToGo);
         }
         if(null != this.mcYardL)
         {
            this.mcYardL.removeEventListener(MouseEvent.CLICK,this.onYardClick);
         }
         if(null != this.mcYardR)
         {
            this.mcYardR.removeEventListener(MouseEvent.CLICK,this.onYardClick);
         }
         if(null != this.btnReset)
         {
            this.btnReset.removeEventListener(MouseEvent.CLICK,this.onReset);
         }
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_USER_TASK_ADD,this.onTaskAdd574);
         if(null != this.timer)
         {
            this.timer.stop();
            this.timer.removeEventListener(TimerEvent.TIMER,this.onTime);
         }
      }
   }
}

